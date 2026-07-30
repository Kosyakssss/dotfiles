import type {
  ExtensionAPI,
  ExtensionContext,
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

function contextText(ctx: ExtensionContext): {
  text: string;
  color: "dim" | "warning" | "error";
} {
  const percent = ctx.getContextUsage()?.percent;
  if (percent === null || percent === undefined) {
    return { text: "ctx —", color: "dim" };
  }

  const rounded = Math.round(percent);
  const color = rounded >= 90 ? "error" : rounded >= 70 ? "warning" : "dim";
  return { text: `ctx ${rounded}%`, color };
}

function thinkingColor(
  level: string,
):
  | "thinkingOff"
  | "thinkingMinimal"
  | "thinkingLow"
  | "thinkingMedium"
  | "thinkingHigh"
  | "thinkingXhigh"
  | "thinkingMax" {
  switch (level) {
    case "off":
      return "thinkingOff";
    case "minimal":
      return "thinkingMinimal";
    case "low":
      return "thinkingLow";
    case "high":
      return "thinkingHigh";
    case "xhigh":
      return "thinkingXhigh";
    case "max":
      return "thinkingMax";
    default:
      return "thinkingMedium";
  }
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

export default function (pi: ExtensionAPI) {
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
          const effortColor = thinkingColor(thinking);
          const context = contextText(ctx);
          const statuses = [...footerData.getExtensionStatuses().values()];

          const leftParts = [
            theme.fg(effortColor, theme.bold(` ${PI_SYMBOL}`)),
            theme.fg("text", path),
          ];
          if (branch) leftParts.push(theme.fg("muted", branch));

          const rightParts = [
            theme.fg(effortColor, model),
            theme.fg(effortColor, thinking),
            theme.fg(context.color, context.text),
          ];
          for (const status of statuses) {
            rightParts.push(theme.fg("muted", status));
          }

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
