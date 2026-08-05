import type {
  ExtensionAPI,
  ExtensionContext,
  Theme,
} from "@earendil-works/pi-coding-agent";
import {
  truncateToWidth,
  visibleWidth,
} from "@earendil-works/pi-tui";
import { homedir } from "node:os";
import { isAbsolute, sep } from "node:path";

const PI_SYMBOL = "π";
const SEPARATOR = " · ";

type FooterTheme = ExtensionContext["ui"]["theme"];
type ContextColor = "muted" | "warning" | "error";

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

function join(theme: FooterTheme, parts: string[]): string {
  return parts.join(theme.fg("dim", SEPARATOR));
}

export default function statusline(pi: ExtensionAPI): void {
  let requestRender: (() => void) | undefined;

  const render = () => requestRender?.();

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    ctx.ui.setFooter((tui, theme, footerData) => {
      requestRender = () => tui.requestRender();
      const unsubscribe = footerData.onBranchChange(requestRender);

      return {
        dispose() {
          unsubscribe();
          requestRender = undefined;
        },
        invalidate() {},
        render(width: number): string[] {
          const branch = footerData.getGitBranch();
          const path = compactPath(ctx.cwd);
          const model = ctx.model?.id ?? "no model";
          const thinking = pi.getThinkingLevel();
          const effort = (text: string) => effortText(theme, thinking, text);
          const context = contextText(ctx);
          const statuses = footerData.getExtensionStatuses();
          const stashStatus = statuses.get("prompt-stash");

          const leftParts = [
            effort(theme.bold(` ${PI_SYMBOL}`)),
            theme.fg("text", path),
          ];
          if (stashStatus) leftParts.push(theme.fg("muted", stashStatus));
          if (branch) leftParts.push(theme.fg("muted", branch));

          const rightParts = [
            effort(model),
            effort(thinking),
            theme.fg(context.color, context.text),
            ...[...statuses.entries()]
              .filter(([id]) => id !== "prompt-stash")
              .map(([, status]) => theme.fg("muted", status)),
          ];

          let left = join(theme, leftParts);
          const right = join(theme, rightParts);
          let gap = width - visibleWidth(left) - visibleWidth(right);

          if (gap < 1 && branch) {
            left = join(theme, leftParts.slice(0, 2));
            gap = width - visibleWidth(left) - visibleWidth(right);
          }
          if (gap < 1) {
            left = leftParts[0]!;
            gap = width - visibleWidth(left) - visibleWidth(right);
          }
          if (gap < 1) {
            return [truncateToWidth(`${left}${theme.fg("dim", " ")}${right}`, width)];
          }

          return [`${left}${" ".repeat(gap)}${right}`];
        },
      };
    });
  });

  pi.on("model_select", render);
  pi.on("thinking_level_select", render);
  pi.on("session_compact", render);

  pi.on("session_shutdown", () => {
    requestRender = undefined;
  });
}
