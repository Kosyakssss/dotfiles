import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerShortcut("shift+tab", {
    description: "Toggle GPT-5.6 reasoning between low and high",
    handler: async (ctx) => {
      const modelId = ctx.model?.id ?? "";
      if (!modelId.includes("gpt-5.6")) {
        ctx.ui.notify("Low/high reasoning toggle is configured only for GPT-5.6.", "info");
        return;
      }

      const next = pi.getThinkingLevel() === "low" ? "high" : "low";
      pi.setThinkingLevel(next);
      ctx.ui.notify(`Reasoning → ${next}`, "info");
    },
  });
}
