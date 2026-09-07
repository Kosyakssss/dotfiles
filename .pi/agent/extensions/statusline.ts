import { execFile } from "node:child_process";
import { existsSync } from "node:fs";
import {
  CustomEditor,
  type ExtensionAPI,
  type ExtensionContext,
  type KeybindingsManager,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import {
  truncateToWidth,
  visibleWidth,
  type EditorTheme,
  type TUI,
} from "@earendil-works/pi-tui";
import { homedir } from "node:os";
import { basename, isAbsolute, resolve, sep } from "node:path";

const SEPARATOR = " · ";

type AppTheme = ExtensionContext["ui"]["theme"];
type ContextColor = "muted" | "warning" | "error";
type EditorPasteInternals = {
  pastes: Map<number, string>;
  pasteCounter: number;
  lastAction: string | null;
  pushUndoSnapshot(): void;
  insertTextAtCursorInternal(text: string): void;
};

const effortColors = {
  low: "thinkingLow",
  medium: "thinkingMedium",
  high: "thinkingHigh",
  xhigh: "thinkingXhigh",
  max: "thinkingMax",
} as const;

function effortText(theme: Theme, level: string, text: string): string {
  if (level === "off") return theme.fg("dim", text);
  if (level === "minimal") return theme.fg("muted", text);

  const color = effortColors[level as keyof typeof effortColors];
  return theme.fg(color ?? "accent", text);
}

function contextText(ctx: ExtensionContext): { text: string; color: ContextColor } {
  const percent = ctx.getContextUsage()?.percent;
  if (percent === null || percent === undefined) {
    return { text: "ctx —", color: "muted" };
  }

  const rounded = Math.round(percent);
  const color = rounded >= 90 ? "error" : rounded >= 70 ? "warning" : "muted";
  return { text: `ctx ${rounded}%`, color };
}

function limitStatusParts(theme: AppTheme, status: string): string[] {
  return status.split("|").flatMap((part) => {
    const match = /^([^=]+)=(\d+(?:\.\d+)?)$/u.exec(part);
    if (!match) return [];
    const percent = Number(match[2]);
    const color = percent < 10 ? "error" : percent < 30 ? "warning" : "success";
    return [theme.fg(color, `${match[1]}: ${Math.round(percent)}%`)];
  });
}

function shellWords(text: string): string[] | undefined {
  const words: string[] = [];
  let word = "";
  let quote = "";
  let escaped = false;
  for (const character of text.trim()) {
    if (escaped) {
      word += character;
      escaped = false;
    } else if (character === "\\" && quote !== "'") {
      escaped = true;
    } else if (quote) {
      if (character === quote) quote = "";
      else word += character;
    } else if (character === "'" || character === '"') {
      quote = character;
    } else if (/\s/u.test(character)) {
      if (word) words.push(word);
      word = "";
    } else {
      word += character;
    }
  }
  if (escaped) word += "\\";
  if (quote) return undefined;
  if (word) words.push(word);
  return words;
}

function absolutePath(value: string, cwd: string): string {
  const expanded = value === "~"
    ? homedir()
    : value.startsWith(`~${sep}`)
      ? `${homedir()}${value.slice(1)}`
      : value;
  return isAbsolute(expanded) ? expanded : resolve(cwd, expanded);
}

function pastedPaths(text: string, cwd: string): string[] | undefined {
  const value = text.trim();
  if (!value || value.includes("\n")) return undefined;
  if (existsSync(absolutePath(value, cwd))) return [value];
  const words = shellWords(value);
  return words?.length && words.every((word) => existsSync(absolutePath(word, cwd)))
    ? words
    : undefined;
}

function isImagePath(value: string): boolean {
  return /\.(?:avif|bmp|gif|jpe?g|png|webp)$/iu.test(value);
}

function compactSegment(segment: string): string {
  if (segment.startsWith(".") && segment.length > 1) {
    return `.${[...segment.slice(1)][0] ?? ""}`;
  }
  return [...segment][0] ?? segment;
}

function compactPath(cwd: string): string {
  const home = homedir();
  let prefix = "";
  let relative = cwd;

  if (cwd === home) return "~";
  if (cwd.startsWith(`${home}${sep}`)) {
    prefix = `~${sep}`;
    relative = cwd.slice(home.length + 1);
  } else if (isAbsolute(cwd)) {
    prefix = sep;
    relative = cwd.slice(1);
  }

  const segments = relative.split(sep).filter(Boolean);
  if (segments.length <= 1) return `${prefix}${segments.join(sep)}` || prefix;

  const compacted = segments.map((segment, index) =>
    index === segments.length - 1 ? segment : compactSegment(segment),
  );
  return `${prefix}${compacted.join(sep)}`;
}

function fitBorder(
  leftCorner: string,
  rightCorner: string,
  left: string,
  right: string,
  width: number,
  border: (text: string) => string,
): string {
  if (width <= 0) return "";
  if (width === 1) return border("─");

  const innerWidth = width - 2;
  let leftText = left;
  let rightText = right;
  const minimumGap = leftText && rightText ? 1 : 0;

  while (visibleWidth(leftText) + visibleWidth(rightText) + minimumGap > innerWidth) {
    if (visibleWidth(leftText) > visibleWidth(rightText)) {
      leftText = truncateToWidth(leftText, Math.max(0, visibleWidth(leftText) - 1), "");
    } else if (visibleWidth(rightText) > 0) {
      rightText = truncateToWidth(rightText, Math.max(0, visibleWidth(rightText) - 1), "");
    } else {
      break;
    }
  }

  const fillWidth = Math.max(0, innerWidth - visibleWidth(leftText) - visibleWidth(rightText));
  return `${border(leftCorner)}${leftText}${border("─".repeat(fillWidth))}${rightText}${border(rightCorner)}`;
}

function findBottomBorder(lines: string[]): number {
  for (let index = lines.length - 1; index >= 1; index--) {
    const plain = lines[index]
      ?.replace(/\x1b\[[0-9;]*[mGKHJ]/g, "")
      .replace(/\x1b_[^\x07\x1b]*(?:\x07|\x1b\\)/g, "")
      .replace(/\x1b\]8;;[^\x07]*\x07/g, "");
    if (plain?.startsWith("─")) return index;
  }
  return lines.length - 1;
}

function padLine(line: string, width: number): string {
  const clipped = truncateToWidth(line, width, "");
  return `${clipped}${" ".repeat(Math.max(0, width - visibleWidth(clipped)))}`;
}

type DiffCounts = {
  added: number;
  modified: number;
  deleted: number;
  moved: number;
  untracked: number;
  unmerged: number;
};

type VcsStatus = {
  revision: string | null;
  diff: string | null;
};

function diffCounts(): DiffCounts {
  return {
    added: 0,
    modified: 0,
    deleted: 0,
    moved: 0,
    untracked: 0,
    unmerged: 0,
  };
}

function addJjStatus(counts: DiffCounts, code: string): void {
  if (code === "A" || code === "C") counts.added += 1;
  else if (code === "M") counts.modified += 1;
  else if (code === "D") counts.deleted += 1;
  else if (code === "R") counts.moved += 1;
}

function addGitStatus(counts: DiffCounts, code: string): void {
  if (code === "?") counts.untracked += 1;
  else if (code === "A") counts.added += 1;
  else if (code === "D") counts.deleted += 1;
  else if (code === "U") counts.unmerged += 1;
  else if (["M", "R", "C", "m"].includes(code)) counts.modified += 1;
}

function formatDiffCounts(counts: DiffCounts): string {
  return [
    counts.untracked > 0 ? `?${counts.untracked}` : "",
    counts.added > 0 ? `+${counts.added}` : "",
    counts.modified > 0 ? `~${counts.modified}` : "",
    counts.deleted > 0 ? `-${counts.deleted}` : "",
    counts.moved > 0 ? `>${counts.moved}` : "",
    counts.unmerged > 0 ? `x${counts.unmerged}` : "",
  ].filter(Boolean).join(" ");
}

function formatGitDiffStatus(working: DiffCounts, staging: DiffCounts): string | null {
  const workingStatus = formatDiffCounts(working);
  const stagingStatus = formatDiffCounts(staging);
  if (!workingStatus) return stagingStatus || null;
  if (!stagingStatus) return workingStatus;
  return `${workingStatus} | ${stagingStatus}`;
}

function getJjStatus(cwd: string): Promise<VcsStatus | null> {
  return new Promise((resolveStatus) => {
    execFile(
      "jj",
      [
        "log",
        "--no-pager",
        "--color",
        "never",
        "-r",
        "latest(ancestors(@) & bookmarks(), 1) | @",
        "--no-graph",
        "-T",
        'if(current_working_copy, "change=" ++ change_id.shortest(8) ++ "\\n" ++ diff.summary() ++ "\\n", "") ++ if(bookmarks, "bookmark=" ++ bookmarks.join(",") ++ "\\n", "")',
      ],
      { cwd },
      (error, stdout) => {
        if (error) {
          resolveStatus(null);
          return;
        }
        const lines = stdout.trim().split("\n").filter(Boolean);
        const fields = new Map(
          lines
            .filter((line) => line.includes("="))
            .map((line) => line.split("=", 2) as [string, string]),
        );
        const counts = diffCounts();
        for (const line of lines) addJjStatus(counts, line[0] ?? "");
        const change = fields.get("change");
        const bookmark = fields.get("bookmark");
        resolveStatus({
          revision: change ? `${bookmark ? `(${bookmark}) ` : ""}${change}` : null,
          diff: formatDiffCounts(counts) || null,
        });
      },
    );
  });
}

function getGitStatus(cwd: string): Promise<string | null> {
  return new Promise((resolveStatus) => {
    execFile(
      "git",
      ["--no-optional-locks", "-c", "core.quotepath=false", "-c", "color.status=false", "status", "--untracked-files=normal", "--branch", "--porcelain=2"],
      { cwd },
      (error, stdout) => {
        if (error) {
          resolveStatus(null);
          return;
        }
        const working = diffCounts();
        const staging = diffCounts();
        for (const line of stdout.trim().split("\n").filter(Boolean)) {
          if (line.startsWith("? ")) {
            working.untracked += 1;
          } else if (line[0] === "1" || line[0] === "2" || line[0] === "u") {
            addGitStatus(staging, line[2] ?? "");
            addGitStatus(working, line[3] ?? "");
          }
        }
        resolveStatus(formatGitDiffStatus(working, staging));
      },
    );
  });
}

async function getVcsStatus(cwd: string): Promise<VcsStatus> {
  const jj = await getJjStatus(cwd);
  if (jj) return jj;
  return { revision: null, diff: await getGitStatus(cwd) };
}

export default function statusline(pi: ExtensionAPI): void {
  let requestRender: (() => void) | undefined;
  let vcsPoller: ReturnType<typeof setInterval> | undefined;
  let jjStatus: string | null = null;
  let vcsDiffStatus: string | null = null;
  let refreshPending = false;

  const render = () => requestRender?.();

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    const refreshVcs = async (): Promise<void> => {
      if (refreshPending) return;
      refreshPending = true;
      const next = await getVcsStatus(ctx.cwd);
      refreshPending = false;
      if (next.revision === jjStatus && next.diff === vcsDiffStatus) return;
      jjStatus = next.revision;
      vcsDiffStatus = next.diff;
      render();
    };

    void refreshVcs();
    vcsPoller = setInterval(() => void refreshVcs(), 1000);
    vcsPoller.unref();

    let getBranch: () => string | null = () => null;
    let getStatuses: () => ReadonlyMap<string, string> = () => new Map();

    ctx.ui.setFooter((tui, _theme, footerData) => {
      getBranch = () => footerData.getGitBranch();
      getStatuses = () => footerData.getExtensionStatuses();
      requestRender = () => tui.requestRender();
      const unsubscribe = footerData.onBranchChange(requestRender);

      return {
        dispose() {
          unsubscribe();
          requestRender = undefined;
        },
        invalidate() {},
        render(): string[] {
          return [];
        },
      };
    });

    ctx.ui.setEditorComponent(
      (tui: TUI, editorTheme: EditorTheme, keybindings: KeybindingsManager) => {
        requestRender = () => tui.requestRender();

        return new (class StatusEditor extends CustomEditor {
          constructor() {
            super(tui, editorTheme, keybindings);
          }

          private insertCollapsedPaths(text: string): boolean {
            const paths = pastedPaths(text, ctx.cwd);
            if (!paths) return false;
            const editor = this as unknown as EditorPasteInternals;
            editor.pushUndoSnapshot();
            for (const [index, path] of paths.entries()) {
              const pasteId = editor.pasteCounter + 1;
              editor.pasteCounter = pasteId;
              editor.pastes.set(pasteId, path);
              const marker = `[paste #${pasteId} ${path.length} chars]`;
              editor.insertTextAtCursorInternal(`${index > 0 ? " " : ""}${marker}`);
            }
            editor.lastAction = "insert";
            return true;
          }

          override insertTextAtCursor(text: string): void {
            if (!this.insertCollapsedPaths(text)) super.insertTextAtCursor(text);
          }

          override handleInput(data: string): void {
            if (
              data.startsWith("\x1b[200~") &&
              data.endsWith("\x1b[201~") &&
              this.insertCollapsedPaths(data.slice(6, -6))
            ) {
              return;
            }
            super.handleInput(data);
          }

          override render(width: number): string[] {
            const innerWidth = width - 2;
            if (innerWidth < 4) return super.render(width);

            const theme: AppTheme = ctx.ui.theme;
            const editor = this as unknown as EditorPasteInternals;
            const activeIds = [...this.getText().matchAll(/\[paste #(\d+)(?: (?:\+\d+ lines|\d+ chars))?\]/gu)]
              .map((match) => Number(match[1]));
            const imageIds = activeIds.filter((id) => {
              const value = editor.pastes.get(id);
              return value ? isImagePath(value) : false;
            });
            const imageRanks = new Map(imageIds.map((id, index) => [id, index + 1]));
            const lines = super.render(innerWidth).map((line) =>
              line.replace(/\[paste #(\d+)(?: (?:\+\d+ lines|\d+ chars))?\]/gu, (marker, rawId) => {
                const id = Number(rawId);
                const value = editor.pastes.get(id);
                if (!value || !pastedPaths(value, ctx.cwd)) return marker;
                const rank = imageRanks.get(id);
                const label = rank ? `[image #${rank}]` : `[${basename(value)}]`;
                return theme.fg(rank ? "accent" : "muted", label);
              }),
            );
            if (lines.length < 2) return lines;

            const branch = getBranch();
            const path = compactPath(ctx.cwd);
            const revision = jjStatus ?? (branch ? `(${branch})` : "");
            const topLeft =
              theme.fg("text", ` ${path}`) +
              (revision ? theme.fg("muted", ` ${revision}`) : "") +
              " ";

            const thinking = pi.getThinkingLevel();
            const effort = (text: string) => effortText(theme, thinking, text);
            const model = ctx.model?.id ?? "no model";
            const topRight = effort(
              ` ${model}${SEPARATOR}${thinking} `,
            );

            const context = contextText(ctx);
            const statuses = getStatuses();
            const stashStatus = statuses.get("prompt-stash");
            const bottomLeftParts: string[] = [];
            if (stashStatus) bottomLeftParts.push(theme.fg("muted", stashStatus));
            if (vcsDiffStatus) bottomLeftParts.push(theme.fg("warning", vcsDiffStatus));
            const bottomLeft = bottomLeftParts.length > 0
              ? ` ${bottomLeftParts.join(theme.fg("muted", SEPARATOR))} `
              : "";
            const bottomParts = [theme.fg(context.color, context.text)];
            for (const [id, status] of statuses) {
              if (id === "prompt-stash" || id === "usage" || status.startsWith("chrome:")) continue;
              if (id === "limits") {
                bottomParts.push(...limitStatusParts(theme, status));
                continue;
              }
              bottomParts.push(theme.fg("muted", status));
            }
            const bottomRight = ` ${bottomParts.join(theme.fg("muted", SEPARATOR))} `;
            const border = (text: string) => theme.fg("text", text);
            const bottomIndex = findBottomBorder(lines);
            const result = [
              fitBorder("╭", "╮", topLeft, topRight, width, border),
            ];

            for (let index = 1; index < bottomIndex; index++) {
              result.push(
                `${border("│")}${padLine(lines[index] ?? "", innerWidth)}${border("│")}`,
              );
            }

            const hasAutocomplete = bottomIndex + 1 < lines.length;
            result.push(
              fitBorder(
                hasAutocomplete ? "├" : "╰",
                hasAutocomplete ? "┤" : "╯",
                bottomLeft,
                bottomRight,
                width,
                border,
              ),
            );

            if (hasAutocomplete) {
              for (let index = bottomIndex + 1; index < lines.length; index++) {
                result.push(
                  `${border("│")}${padLine(lines[index] ?? "", innerWidth)}${border("│")}`,
                );
              }
              result.push(fitBorder("╰", "╯", "", "", width, border));
            }

            return result;
          }
        })();
      },
    );
  });

  pi.on("model_select", render);
  pi.on("thinking_level_select", render);
  pi.on("session_compact", render);

  pi.on("session_shutdown", () => {
    if (vcsPoller) clearInterval(vcsPoller);
    vcsPoller = undefined;
    jjStatus = null;
    vcsDiffStatus = null;
    refreshPending = false;
    requestRender = undefined;
  });
}
