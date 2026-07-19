import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { basename } from "node:path";

/**
 * Keep the terminal tab compact and show when Pi is working.
 *
 * Name a session with `/name word`. Only the first word is displayed;
 * unnamed sessions fall back to the current directory name.
 */

const PI_SYMBOL = "π";
const USER_ACTION_FRAME = "✋";
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SPINNER_INTERVAL_MS = 120;
const MAX_NAME_LENGTH = 24;

function threadName(pi: ExtensionAPI, ctx: ExtensionContext): string {
  const source = pi.getSessionName()?.trim() || basename(ctx.cwd) || "pi";
  const firstWord = source.split(/\s+/u)[0] ?? "pi";

  return (
    firstWord
      .replace(/[\x00-\x1f\x7f]/g, "")
      .slice(0, MAX_NAME_LENGTH) || "pi"
  );
}

function title(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  indicator?: string,
): string {
  const prefix = indicator ? `${indicator} ` : "";
  return `${prefix}${PI_SYMBOL} - ${threadName(pi, ctx)}`;
}

export default function (pi: ExtensionAPI) {
  let spinner: ReturnType<typeof setInterval> | undefined;
  let frameIndex = 0;
  const userActionToolCalls = new Set<string>();

  const setTitle = (ctx: ExtensionContext, indicator?: string) => {
    if (ctx.mode !== "tui") return;
    ctx.ui.setTitle(title(pi, ctx, indicator));
  };

  const clearSpinner = () => {
    if (spinner) {
      clearInterval(spinner);
      spinner = undefined;
    }
    frameIndex = 0;
  };

  const showIdle = (ctx: ExtensionContext) => {
    clearSpinner();
    setTitle(ctx);
  };

  const showUserAction = (ctx: ExtensionContext) => {
    clearSpinner();
    setTitle(ctx, USER_ACTION_FRAME);
  };

  const startSpinner = (ctx: ExtensionContext) => {
    if (ctx.mode !== "tui" || spinner) return;
    if (userActionToolCalls.size > 0) {
      showUserAction(ctx);
      return;
    }

    setTitle(ctx, SPINNER_FRAMES[frameIndex]!);
    spinner = setInterval(() => {
      frameIndex = (frameIndex + 1) % SPINNER_FRAMES.length;
      setTitle(ctx, SPINNER_FRAMES[frameIndex]!);
    }, SPINNER_INTERVAL_MS);
    spinner.unref();
  };

  pi.on("session_start", async (_event, ctx) => {
    // Pi applies its built-in title after session_start. A timer makes this
    // extension's compact title the final startup update.
    const timer = setTimeout(() => {
      if (ctx.isIdle()) showIdle(ctx);
      else startSpinner(ctx);
    }, 0);
    timer.unref();
  });

  pi.on("session_info_changed", async (_event, ctx) => {
    // Reapply after Pi's own /name title update.
    const timer = setTimeout(() => {
      if (userActionToolCalls.size > 0) showUserAction(ctx);
      else if (spinner) setTitle(ctx, SPINNER_FRAMES[frameIndex]!);
      else setTitle(ctx);
    }, 0);
    timer.unref();
  });

  pi.on("agent_start", async (_event, ctx) => {
    startSpinner(ctx);
  });

  pi.on("tool_execution_start", async (event, ctx) => {
    if (event.toolName !== "ask_user") return;
    userActionToolCalls.add(event.toolCallId);
    showUserAction(ctx);
  });

  pi.on("tool_execution_end", async (event, ctx) => {
    if (event.toolName !== "ask_user") return;
    userActionToolCalls.delete(event.toolCallId);
    if (userActionToolCalls.size > 0) showUserAction(ctx);
    else if (ctx.isIdle()) showIdle(ctx);
    else startSpinner(ctx);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (!ctx.isIdle()) return;
    userActionToolCalls.clear();
    showIdle(ctx);
  });

  pi.on("session_shutdown", async () => {
    userActionToolCalls.clear();
    clearSpinner();
  });
}
