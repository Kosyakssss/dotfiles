import type {
  ExtensionAPI,
  ExtensionContext,
  Model,
} from "@earendil-works/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const STATUS_ID = "fast-mode";
const CONFIG_PATH = join(dirname(fileURLToPath(import.meta.url)), "fast-mode.json");
const SUPPORTED_APIS = new Set(["openai-responses", "openai-codex-responses"]);

type Config = {
  enabled: boolean;
  models: string[];
};

const defaults: Config = {
  enabled: false,
  models: [
    "openai-codex/gpt-5.6-sol",
    "openai-codex/gpt-5.6-luna",
  ],
};

function modelKey(model: Model): string {
  return `${model.provider}/${model.id}`;
}

function isEligible(model: Model | undefined, config: Config): boolean {
  return Boolean(
    model &&
    config.models.includes(modelKey(model)) &&
    SUPPORTED_APIS.has(model.api),
  );
}

async function loadConfig(): Promise<Config> {
  try {
    const value = JSON.parse(await readFile(CONFIG_PATH, "utf8")) as Partial<Config>;
    return {
      enabled: typeof value.enabled === "boolean" ? value.enabled : defaults.enabled,
      models: Array.isArray(value.models)
        ? value.models.filter((model): model is string => typeof model === "string")
        : defaults.models,
    };
  } catch {
    return defaults;
  }
}

export default function fastMode(pi: ExtensionAPI): void {
  let config = defaults;
  let enabled = false;

  const updateStatus = (ctx: ExtensionContext): void => {
    ctx.ui.setStatus(
      STATUS_ID,
      enabled && isEligible(ctx.model, config) ? "fast" : undefined,
    );
  };

  const notifyState = (ctx: ExtensionContext): void => {
    const model = ctx.model;
    if (!enabled) {
      ctx.ui.notify("Fast mode is off.", "info");
    } else if (isEligible(model, config)) {
      ctx.ui.notify(`Fast mode is on for ${model?.name ?? model?.id}.`, "info");
    } else {
      ctx.ui.notify("Fast mode is on, but inactive for the current model.", "warning");
    }
  };

  pi.registerFlag("fast", {
    description: "Start with fast mode enabled",
    type: "boolean",
    default: false,
  });

  pi.registerCommand("fast", {
    description: "Toggle fast mode for configured OpenAI models",
    handler: async (args, ctx) => {
      const command = args.trim().toLowerCase();
      if (command === "") enabled = !enabled;
      else if (command === "on") enabled = true;
      else if (command === "off") enabled = false;
      else if (command !== "status") {
        ctx.ui.notify("Usage: /fast [on|off|status]", "warning");
        return;
      }
      updateStatus(ctx);
      notifyState(ctx);
    },
  });

  pi.registerShortcut("ctrl+f", {
    description: "Toggle OpenAI fast mode",
    handler: async (ctx) => {
      enabled = !enabled;
      updateStatus(ctx);
      notifyState(ctx);
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    config = await loadConfig();
    enabled = pi.getFlag("fast") === true || config.enabled;
    updateStatus(ctx);
  });

  pi.on("model_select", (_event, ctx) => updateStatus(ctx));

  pi.on("before_provider_request", (event, ctx) => {
    const model = ctx.model;
    if (
      !enabled ||
      !isEligible(model, config) ||
      !model ||
      !event.payload ||
      typeof event.payload !== "object" ||
      Array.isArray(event.payload) ||
      event.payload.model !== model.id ||
      "service_tier" in event.payload
    ) {
      return;
    }

    return { ...event.payload, service_tier: "priority" };
  });

  pi.on("session_shutdown", (_event, ctx) => {
    ctx.ui.setStatus(STATUS_ID, undefined);
  });
}
