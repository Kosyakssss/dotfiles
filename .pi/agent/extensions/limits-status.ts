import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
  truncateToWidth,
  visibleWidth,
  type Component,
} from "@earendil-works/pi-tui";
import {
  adapterForProvider,
  queryProviderUsage,
  resolveUsageAuth,
  type UsageBucket,
  type UsageReport,
} from "../npm/node_modules/@narumitw/pi-usage/src/index.ts";

const BAR_WIDTH = 12;

function resetTime(timestamp: number | undefined): string {
  if (!timestamp) return "";
  const date = new Date(timestamp * 1000);
  const now = new Date();
  const sameDay =
    date.getFullYear() === now.getFullYear() &&
    date.getMonth() === now.getMonth() &&
    date.getDate() === now.getDate();
  return sameDay
    ? date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
    : date.toLocaleString([], {
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
}

function windowLabel(bucket: UsageBucket): string {
  const minutes = bucket.windowMinutes;
  if (minutes === 10_080) return "Weekly";
  if (minutes && minutes % 1_440 === 0) return `${minutes / 1_440}d`;
  if (minutes && minutes % 60 === 0) return `${minutes / 60}h`;
  return bucket.label.replace(/\s+limit$/iu, "");
}

function selectedBuckets(report: UsageReport, modelId: string): UsageBucket[] {
  if (report.providerId !== "openai-codex") return report.buckets;
  const groups = [...new Set(report.buckets.map((bucket) => bucket.groupId ?? bucket.id))];
  const normalizedModel = modelId.toLowerCase().replace(/[^a-z0-9]+/g, "-");
  const matching = groups.find((group) => {
    const buckets = report.buckets.filter((bucket) => (bucket.groupId ?? bucket.id) === group);
    return buckets.some((bucket) =>
      [group, bucket.groupLabel, ...(bucket.modelKeys ?? [])]
        .filter((value): value is string => Boolean(value))
        .some((value) => normalizedModel.includes(value.toLowerCase().replace(/[^a-z0-9]+/g, "-"))),
    );
  });
  const group = matching ?? (groups.includes("codex") ? "codex" : groups[0]);
  return report.buckets.filter((bucket) => (bucket.groupId ?? bucket.id) === group);
}

function remainingPercent(bucket: UsageBucket): number {
  return Math.max(0, Math.min(100, bucket.remaining ?? 100 - (bucket.used ?? 0)));
}

function compactWindowLabel(bucket: UsageBucket): string {
  return bucket.windowMinutes === 10_080 ? "wk" : windowLabel(bucket).toLowerCase();
}

function formatLimitStatus(report: UsageReport, modelId: string): string | undefined {
  const buckets = selectedBuckets(report, modelId);
  if (buckets.length === 0) return undefined;
  return buckets
    .map((bucket) => `${compactWindowLabel(bucket)}=${remainingPercent(bucket).toFixed(0)}`)
    .join("|");
}

function formatLimits(report: UsageReport, modelId: string): string {
  const buckets = selectedBuckets(report, modelId);
  if (buckets.length === 0) return "No usage limits were returned.";
  const labels = buckets.map(windowLabel);
  const labelWidth = Math.max(...labels.map((label) => label.length));
  return buckets
    .map((bucket, index) => {
      const remaining = remainingPercent(bucket);
      const filled = Math.round((remaining / 100) * BAR_WIDTH);
      const bar = `${"█".repeat(filled)}${"░".repeat(BAR_WIDTH - filled)}`;
      const reset = resetTime(bucket.resetsAt);
      return `${labels[index]?.padEnd(labelWidth)}  [${bar}] ${remaining.toFixed(0)}% left${reset ? ` · ${reset}` : ""}`;
    })
    .join("\n");
}

class LimitsStatusComponent implements Component {
  constructor(
    private readonly text: string,
    private readonly color: (value: string) => string,
    private readonly border: (value: string) => string,
  ) {}

  render(width: number): string[] {
    if (width < 4) return this.text.split("\n").map((line) => truncateToWidth(line, width, ""));
    const innerWidth = width - 2;
    const body = this.text.split("\n").map((line) => {
      const content = truncateToWidth(this.color(line), innerWidth - 2, "");
      return `${this.border("│")} ${content}${" ".repeat(Math.max(0, innerWidth - 2 - visibleWidth(content)))} ${this.border("│")}`;
    });
    return [
      `${this.border("╭")}${this.border("─".repeat(innerWidth))}${this.border("╮")}`,
      ...body,
      `${this.border("╰")}${this.border("─".repeat(innerWidth))}${this.border("╯")}`,
    ];
  }

  invalidate(): void {}
}

export default function limitsStatus(pi: ExtensionAPI): void {
  let refreshTimer: ReturnType<typeof setInterval> | undefined;
  let refreshGeneration = 0;
  let lastRefreshAt = 0;
  let lastRefreshKey = "";

  const refreshStatus = async (ctx: ExtensionContext, force = false): Promise<void> => {
    const model = ctx.model;
    const refreshKey = model ? `${model.provider}/${model.id}` : "";
    if (!force && refreshKey === lastRefreshKey && Date.now() - lastRefreshAt < 5 * 60 * 1000) return;
    const generation = ++refreshGeneration;
    const adapter = adapterForProvider(model?.provider);
    if (!adapter || !model) {
      ctx.ui.setStatus("limits", undefined);
      return;
    }
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 15_000);
    timer.unref();
    try {
      const auth = await resolveUsageAuth(ctx, adapter);
      if (!auth || generation !== refreshGeneration) return;
      const report = await queryProviderUsage(adapter, auth, controller.signal, 15_000);
      if (generation !== refreshGeneration || ctx.model?.id !== model.id) return;
      lastRefreshAt = Date.now();
      lastRefreshKey = refreshKey;
      ctx.ui.setStatus("limits", formatLimitStatus(report, model.id));
    } catch {
      if (generation === refreshGeneration) ctx.ui.setStatus("limits", undefined);
    } finally {
      clearTimeout(timer);
    }
  };

  pi.registerEntryRenderer("limits-status", (entry, _options, theme) => {
    const data = entry.data as { text?: string };
    return new LimitsStatusComponent(
      data.text ?? "",
      (text) => theme.fg("customMessageText", text),
      (text) => theme.fg("borderMuted", text),
    );
  });

  pi.on("session_start", (_event, ctx) => {
    void refreshStatus(ctx);
    refreshTimer = setInterval(() => void refreshStatus(ctx, true), 5 * 60 * 1000);
    refreshTimer.unref();
  });

  pi.on("model_select", (_event, ctx) => void refreshStatus(ctx, true));
  pi.on("turn_start", (_event, ctx) => void refreshStatus(ctx));

  pi.on("session_shutdown", (_event, ctx) => {
    refreshGeneration += 1;
    if (refreshTimer) clearInterval(refreshTimer);
    refreshTimer = undefined;
    lastRefreshAt = 0;
    lastRefreshKey = "";
    ctx.ui.setStatus("limits", undefined);
  });

  pi.registerCommand("status", {
    description: "Show current account usage limits",
    handler: async (_args, ctx) => {
      const adapter = adapterForProvider(ctx.model?.provider);
      if (!adapter || !ctx.model) {
        ctx.ui.notify("Usage limits are not available for the current provider.", "warning");
        return;
      }
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 15_000);
      timer.unref();
      try {
        const auth = await resolveUsageAuth(ctx, adapter);
        if (!auth) {
          ctx.ui.notify("Usage authentication is not available.", "warning");
          return;
        }
        const report = await queryProviderUsage(adapter, auth, controller.signal, 15_000);
        lastRefreshAt = Date.now();
        lastRefreshKey = `${ctx.model.provider}/${ctx.model.id}`;
        ctx.ui.setStatus("limits", formatLimitStatus(report, ctx.model.id));
        pi.appendEntry("limits-status", { text: formatLimits(report, ctx.model.id) });
      } catch (error) {
        ctx.ui.notify(
          `Could not load usage limits: ${error instanceof Error ? error.message : String(error)}`,
          "error",
        );
      } finally {
        clearTimeout(timer);
      }
    },
  });
}
