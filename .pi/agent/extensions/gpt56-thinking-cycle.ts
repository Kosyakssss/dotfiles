import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerShortcut("shift+tab", {
    description: "Cycle GPT-5.6 reasoning through low, medium, and high",
    handler: async (ctx) => {
      const modelId = ctx.model?.id ?? "";
      if (!modelId.includes("gpt-5.6")) {
        ctx.ui.notify("Reasoning cycle is configured only for GPT-5.6.", "info");
        return;
      }

      const levels = ["low", "medium", "high"] as const;
      const currentIndex = levels.indexOf(pi.getThinkingLevel() as (typeof levels)[number]);
      const next = levels[(currentIndex + 1) % levels.length];
      pi.setThinkingLevel(next);
      ctx.ui.notify(`Reasoning → ${next}`, "info");
    },
  });
}
