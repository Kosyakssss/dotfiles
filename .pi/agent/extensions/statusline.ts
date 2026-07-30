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
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, sep } from "node:path";

const PI_SYMBOL = "π";
const SEPARATOR = " · ";

type AppTheme = ExtensionContext["ui"]["theme"];
type ContextColor = "muted" | "warning" | "error";

const effortVars = {
  low: "blue",
  medium: "cyan",
  high: "purple",
  xhigh: "magenta",
  max: "red",
} as const;
const themeVars = new WeakMap<Theme, Record<string, string>>();

function rgb(hex: string, text: string): string {
  const value = hex.startsWith("#") ? hex.slice(1) : hex;
  if (!/^[0-9a-f]{6}$/i.test(value)) return text;
  const red = Number.parseInt(value.slice(0, 2), 16);
  const green = Number.parseInt(value.slice(2, 4), 16);
  const blue = Number.parseInt(value.slice(4, 6), 16);
  return `\x1b[38;2;${red};${green};${blue}m${text}\x1b[39m`;
}

function effortText(theme: Theme, level: string, text: string): string {
  if (level === "off") return theme.fg("dim", text);
  if (level === "minimal") return theme.fg("muted", text);

  let vars = themeVars.get(theme);
  if (!vars) {
    vars = {};
    if (theme.sourcePath) {
      try {
        const source = JSON.parse(readFileSync(theme.sourcePath, "utf8")) as {
          vars?: Record<string, string>;
        };
        vars = source.vars ?? {};
      } catch {
        // Non-file and malformed themes fall back to the fixed UI accent.
      }
    }
    themeVars.set(theme, vars);
  }

  const variable = effortVars[level as keyof typeof effortVars];
  const color = variable ? vars[variable] : undefined;
  return color ? rgb(color, text) : theme.fg("accent", text);
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

export default function statusline(pi: ExtensionAPI): void {
  let requestRender: (() => void) | undefined;

  const render = () => requestRender?.();

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

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

          override render(width: number): string[] {
            const innerWidth = width - 2;
            if (innerWidth < 4) return super.render(width);

            const lines = super.render(innerWidth);
            if (lines.length < 2) return lines;

            const theme: AppTheme = ctx.ui.theme;
            const branch = getBranch();
            const path = compactPath(ctx.cwd);
            const topLeft =
              theme.fg("text", ` ${path}`) +
              (branch ? theme.fg("muted", ` (${branch})`) : "") +
              " ";

            const thinking = pi.getThinkingLevel();
            const effort = (text: string) => effortText(theme, thinking, text);
            const model = ctx.model?.id ?? "no model";
            const topRight = effort(
              ` ${PI_SYMBOL}${SEPARATOR}${model}${SEPARATOR}${thinking} `,
            );

            const context = contextText(ctx);
            const statuses = getStatuses();
            const stashStatus = statuses.get("prompt-stash");
            const bottomLeft = stashStatus
              ? theme.fg("muted", ` ${stashStatus} `)
              : "";
            const bottomParts = [theme.fg(context.color, context.text)];
            for (const [id, status] of statuses) {
              if (id === "prompt-stash") continue;
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
    requestRender = undefined;
  });
}
