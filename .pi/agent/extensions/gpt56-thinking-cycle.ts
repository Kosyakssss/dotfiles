import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const THINKING_LEVELS = [
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
] as const;
type ThinkingLevel = (typeof THINKING_LEVELS)[number];

function getAvailableLevels(ctx: ExtensionContext): ThinkingLevel[] {
  const model = ctx.model;
  if (!model?.reasoning) return ["off"];

  return THINKING_LEVELS.filter((level) => {
    const mapped = model.thinkingLevelMap?.[level];
    if (mapped === null) return false;
    if (level === "xhigh" || level === "max") return mapped !== undefined;
    return true;
  });
}

export default function (pi: ExtensionAPI) {
  const changeReasoning = async (ctx: ExtensionContext, direction: -1 | 1) => {
    const levels = getAvailableLevels(ctx);
    if (levels.length <= 1 && levels[0] === "off") {
      ctx.ui.notify("The current model does not support reasoning.", "info");
      return;
    }

    const currentIndex = levels.indexOf(pi.getThinkingLevel());
    const startIndex = currentIndex === -1 ? 0 : currentIndex;
    const nextIndex = Math.max(0, Math.min(levels.length - 1, startIndex + direction));
    const next = levels[nextIndex];
    pi.setThinkingLevel(next);
    ctx.ui.notify(`Reasoning → ${next}`, "info");
  };

  pi.registerShortcut("alt+,", {
    description: "Lower reasoning level",
    handler: (ctx) => changeReasoning(ctx, -1),
  });
  pi.registerShortcut("alt+.", {
    description: "Raise reasoning level",
    handler: (ctx) => changeReasoning(ctx, 1),
  });
}
