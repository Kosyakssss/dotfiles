import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const changeReasoning = async (ctx: ExtensionContext, direction: -1 | 1) => {
    const modelId = ctx.model?.id ?? "";
    if (!modelId.includes("gpt-5.6")) {
      ctx.ui.notify("Reasoning controls are configured only for GPT-5.6.", "info");
      return;
    }

    const levels = modelId.includes("luna")
      ? (["medium", "high", "xhigh"] as const)
      : (["low", "medium", "high"] as const);
    const currentIndex = levels.indexOf(pi.getThinkingLevel() as (typeof levels)[number]);
    const nextIndex = Math.max(0, Math.min(levels.length - 1, currentIndex + direction));
    const next = levels[nextIndex];
    pi.setThinkingLevel(next);
    ctx.ui.notify(`Reasoning → ${next}`, "info");
  };

  pi.registerShortcut("alt+,", {
    description: "Lower GPT-5.6 reasoning level",
    handler: (ctx) => changeReasoning(ctx, -1),
  });
  pi.registerShortcut("alt+.", {
    description: "Raise GPT-5.6 reasoning level",
    handler: (ctx) => changeReasoning(ctx, 1),
  });
}
