import type {
  ExtensionAPI,
  ExtensionContext,
  KeybindingsManager,
  Theme,
} from "@earendil-works/pi-coding-agent";
import {
  Key,
  matchesKey,
  truncateToWidth,
  visibleWidth,
  type Component,
  type TUI,
} from "@earendil-works/pi-tui";
import { randomUUID } from "node:crypto";
import { watch, type FSWatcher } from "node:fs";
import {
  chmod,
  mkdir,
  open,
  readFile,
  readdir,
  rename,
  unlink,
} from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

const STATUS_ID = "prompt-stash";
const MAX_ENTRIES = 20;
const STORE_DIR = join(
  process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"),
  "pi",
  "prompt-stash-v1",
);

type StoredEntry = {
  version: 1;
  id: string;
  createdAt: string;
  prompt: string;
};

type StashEntry = StoredEntry & { fileName: string };

function validEntry(value: unknown): value is StoredEntry {
  if (!value || typeof value !== "object") return false;
  const entry = value as Partial<StoredEntry>;
  return (
    entry.version === 1 &&
    typeof entry.id === "string" &&
    typeof entry.createdAt === "string" &&
    typeof entry.prompt === "string" &&
    entry.prompt.length > 0
  );
}

async function ensureStore(): Promise<void> {
  await mkdir(STORE_DIR, { recursive: true, mode: 0o700 });
  await chmod(STORE_DIR, 0o700);
}

async function readEntries(): Promise<StashEntry[]> {
  await ensureStore();
  const names = await readdir(STORE_DIR);
  const entries: StashEntry[] = [];
  for (const fileName of names) {
    if (!fileName.endsWith(".json")) continue;
    try {
      const value: unknown = JSON.parse(await readFile(join(STORE_DIR, fileName), "utf8"));
      if (validEntry(value)) entries.push({ ...value, fileName });
    } catch {
      // Ignore malformed or concurrently removed entries.
    }
  }
  return entries.sort((left, right) => right.createdAt.localeCompare(left.createdAt));
}

async function writeEntry(prompt: string): Promise<StashEntry> {
  await ensureStore();
  const id = randomUUID();
  const createdAt = new Date().toISOString();
  const fileName = `${createdAt.replaceAll(":", "-")}-${id}.json`;
  const temporary = join(STORE_DIR, `.${fileName}.${randomUUID()}.tmp`);
  const destination = join(STORE_DIR, fileName);
  const value: StoredEntry = { version: 1, id, createdAt, prompt };
  const handle = await open(temporary, "wx", 0o600);
  try {
    await handle.writeFile(`${JSON.stringify(value)}\n`, "utf8");
    await handle.sync();
  } finally {
    await handle.close();
  }
  await rename(temporary, destination);

  const entries = await readEntries();
  for (const old of entries.slice(MAX_ENTRIES)) {
    await unlink(join(STORE_DIR, old.fileName)).catch(() => {});
  }
  return { ...value, fileName };
}

async function removeEntry(entry: StashEntry): Promise<void> {
  await unlink(join(STORE_DIR, entry.fileName));
}

function snippet(prompt: string): string {
  return prompt.replace(/\s+/g, " ").trim();
}

function relativeTime(createdAt: string): string {
  const elapsed = Math.max(0, Date.now() - Date.parse(createdAt));
  if (!Number.isFinite(elapsed)) return "";
  const minutes = Math.floor(elapsed / 60_000);
  if (minutes < 1) return "now";
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  return `${days}d`;
}

function framedLine(
  left: string,
  right: string,
  width: number,
  border: (text: string) => string,
): string {
  if (width < 2) return truncateToWidth(`${left}${right}`, width, "");
  const innerWidth = width - 2;
  const rightWidth = visibleWidth(right);
  const fittedLeft = truncateToWidth(left, Math.max(0, innerWidth - rightWidth), "");
  const gap = Math.max(0, innerWidth - visibleWidth(fittedLeft) - rightWidth);
  return `${border("│")}${fittedLeft}${" ".repeat(gap)}${right}${border("│")}`;
}

class StashPicker implements Component {
  private selected = 0;
  private busy = false;

  constructor(
    private entries: StashEntry[],
    private readonly tui: TUI,
    private readonly theme: Theme,
    private readonly keybindings: KeybindingsManager,
    private readonly done: (entry: StashEntry | null) => void,
    private readonly deleteEntry: (entry: StashEntry) => Promise<StashEntry[]>,
  ) {}

  render(width: number): string[] {
    if (width < 4) return [truncateToWidth("Stashed prompts", width, "")];
    const border = (text: string) => this.theme.fg("text", text);
    const innerWidth = width - 2;
    const title = this.theme.fg("accent", ` Stashed prompts · ${this.entries.length} `);
    const titleWidth = visibleWidth(title);
    const lines = [
      `${border("╭")}${title}${border("─".repeat(Math.max(0, innerWidth - titleWidth)))}${border("╮")}`,
    ];

    if (this.entries.length === 0) {
      lines.push(
        framedLine(
          this.theme.fg("muted", "  Nothing stashed"),
          "",
          width,
          border,
        ),
      );
    } else {
      for (const [index, entry] of this.entries.entries()) {
        const selected = index === this.selected;
        const prefix = selected
          ? this.theme.fg("accent", " → ")
          : "   ";
        const age = this.theme.fg("muted", ` ${relativeTime(entry.createdAt)} `);
        const available = Math.max(0, innerWidth - visibleWidth(prefix) - visibleWidth(age));
        const text = truncateToWidth(snippet(entry.prompt), available, "…");
        lines.push(
          framedLine(
            `${prefix}${selected ? this.theme.fg("text", text) : this.theme.fg("muted", text)}`,
            age,
            width,
            border,
          ),
        );
      }
    }

    const help = this.entries.length > 0
      ? " Enter restore · Ctrl+D delete · Esc close "
      : " Esc close ";
    const fittedHelp = truncateToWidth(this.theme.fg("muted", help), innerWidth, "");
    lines.push(
      `${border("╰")}${fittedHelp}${border("─".repeat(Math.max(0, innerWidth - visibleWidth(fittedHelp))))}${border("╯")}`,
    );
    return lines;
  }

  handleInput(data: string): void {
    if (this.busy) return;
    if (this.keybindings.matches(data, "tui.select.cancel")) {
      this.done(null);
      return;
    }
    if (this.keybindings.matches(data, "tui.select.up")) {
      if (this.entries.length > 0) {
        this.selected = (this.selected - 1 + this.entries.length) % this.entries.length;
        this.tui.requestRender();
      }
      return;
    }
    if (this.keybindings.matches(data, "tui.select.down")) {
      if (this.entries.length > 0) {
        this.selected = (this.selected + 1) % this.entries.length;
        this.tui.requestRender();
      }
      return;
    }
    if (this.keybindings.matches(data, "tui.select.confirm")) {
      const entry = this.entries[this.selected];
      if (entry) this.done(entry);
      return;
    }
    if (matchesKey(data, Key.ctrl("d"))) {
      const entry = this.entries[this.selected];
      if (!entry) return;
      this.busy = true;
      void this.deleteEntry(entry)
        .then((entries) => {
          this.entries = entries;
          this.selected = Math.min(this.selected, Math.max(0, entries.length - 1));
        })
        .finally(() => {
          this.busy = false;
          this.tui.requestRender();
        });
    }
  }

  invalidate(): void {}
}

export default function promptStash(pi: ExtensionAPI): void {
  let watcher: FSWatcher | undefined;
  let refreshTimer: ReturnType<typeof setTimeout> | undefined;
  let generation = 0;

  const stopWatcher = (): void => {
    generation += 1;
    watcher?.close();
    watcher = undefined;
    if (refreshTimer) clearTimeout(refreshTimer);
    refreshTimer = undefined;
  };

  const publishCount = async (ctx: ExtensionContext, expectedGeneration = generation): Promise<void> => {
    const count = (await readEntries()).length;
    if (expectedGeneration !== generation) return;
    ctx.ui.setStatus(STATUS_ID, count > 0 ? `stash ${count}` : undefined);
  };

  const scheduleRefresh = (ctx: ExtensionContext, expectedGeneration: number): void => {
    if (refreshTimer) clearTimeout(refreshTimer);
    refreshTimer = setTimeout(() => {
      refreshTimer = undefined;
      void publishCount(ctx, expectedGeneration).catch(() => {});
    }, 50);
    refreshTimer.unref?.();
  };

  const openPicker = async (ctx: ExtensionContext): Promise<void> => {
    if (ctx.mode !== "tui") return;
    const entries = await readEntries();
    const selected = await ctx.ui.custom<StashEntry | null>(
      (tui, theme, keybindings, done) =>
        new StashPicker(
          entries,
          tui,
          theme,
          keybindings,
          done,
          async (entry) => {
            try {
              await removeEntry(entry);
            } catch (error) {
              ctx.ui.notify(
                `Could not delete stashed prompt: ${error instanceof Error ? error.message : String(error)}`,
                "error",
              );
            }
            const remaining = await readEntries();
            await publishCount(ctx);
            return remaining;
          },
        ),
    );
    if (!selected) return;

    ctx.ui.setEditorText(selected.prompt);
    try {
      await removeEntry(selected);
    } catch (error) {
      ctx.ui.notify(
        `Prompt restored, but its stash entry could not be removed: ${error instanceof Error ? error.message : String(error)}`,
        "warning",
      );
    }
    await publishCount(ctx);
  };

  const stashEditor = async (ctx: ExtensionContext): Promise<void> => {
    const prompt = ctx.ui.getEditorText().trim();
    if (!prompt) {
      await openPicker(ctx);
      return;
    }

    try {
      await writeEntry(prompt);
      ctx.ui.setEditorText("");
      const count = (await readEntries()).length;
      ctx.ui.setStatus(STATUS_ID, `stash ${count}`);
      ctx.ui.notify(`Stashed prompt · ${count} saved`, "info");
    } catch (error) {
      ctx.ui.notify(
        `Could not stash prompt: ${error instanceof Error ? error.message : String(error)}`,
        "error",
      );
    }
  };

  pi.registerShortcut("alt+s", {
    description: "Stash prompt or open prompt stash",
    handler: stashEditor,
  });

  pi.registerCommand("stash", {
    description: "Open stashed prompts",
    handler: async (_args, ctx) => openPicker(ctx),
  });

  pi.on("session_start", async (_event, ctx) => {
    stopWatcher();
    if (ctx.mode !== "tui") return;
    const currentGeneration = generation;
    await ensureStore();
    await publishCount(ctx, currentGeneration);
    if (currentGeneration !== generation) return;
    watcher = watch(STORE_DIR, () => scheduleRefresh(ctx, currentGeneration));
  });

  pi.on("session_shutdown", (_event, ctx) => {
    stopWatcher();
    ctx.ui.setStatus(STATUS_ID, undefined);
  });
}
