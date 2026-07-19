import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";

/**
 * Native terminal notifications for Pi.
 *
 * - Notifies when Pi is fully settled and waiting for another prompt.
 * - Notifies as soon as the ask_user tool opens a decision prompt.
 * - Supports Ghostty/iTerm2/WezTerm (OSC 777), Kitty (OSC 99), and
 *   Windows Terminal/WSL (Windows toast).
 */

const TITLE = "Pi";

function clean(value: string): string {
  // OSC payloads must not contain control characters or field delimiters.
  return value
    .replace(/[;\x00-\x1f\x7f]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 240);
}

function writeTerminalSequence(sequence: string): void {
  if (!process.stdout.isTTY) return;

  if (process.env.TMUX) {
    // tmux requires DCS passthrough (and `set -g allow-passthrough on`).
    const escaped = sequence.replaceAll("\x1b", "\x1b\x1b");
    process.stdout.write(`\x1bPtmux;${escaped}\x1b\\`);
    return;
  }

  process.stdout.write(sequence);
}

function notifyOSC777(title: string, body: string): void {
  writeTerminalSequence(`\x1b]777;notify;${clean(title)};${clean(body)}\x07`);
}

function notifyOSC99(title: string, body: string): void {
  const id = "pi-agent";
  writeTerminalSequence(`\x1b]99;i=${id}:d=0;${clean(title)}\x1b\\`);
  writeTerminalSequence(`\x1b]99;i=${id}:p=body;${clean(body)}\x1b\\`);
}

function quotePowerShell(value: string): string {
  return `'${value.replaceAll("'", "''")}'`;
}

function notifyWindows(title: string, body: string): void {
  const type = "Windows.UI.Notifications";
  const script = [
    `[${type}.ToastNotificationManager, ${type}, ContentType = WindowsRuntime] > $null`,
    `$xml = [${type}.ToastNotificationManager]::GetTemplateContent([${type}.ToastTemplateType]::ToastText02)`,
    `$texts = $xml.GetElementsByTagName('text')`,
    `$texts[0].AppendChild($xml.CreateTextNode(${quotePowerShell(clean(title))})) > $null`,
    `$texts[1].AppendChild($xml.CreateTextNode(${quotePowerShell(clean(body))})) > $null`,
    `$toast = [${type}.ToastNotification]::new($xml)`,
    `[${type}.ToastNotificationManager]::CreateToastNotifier(${quotePowerShell(title)}).Show($toast)`,
  ].join("; ");

  const child = execFile(
    "powershell.exe",
    ["-NoProfile", "-NonInteractive", "-Command", script],
    { windowsHide: true },
    () => {},
  );
  child.unref();
}

function notify(title: string, body: string): void {
  if (process.env.WT_SESSION) {
    notifyWindows(title, body);
  } else if (process.env.KITTY_WINDOW_ID) {
    notifyOSC99(title, body);
  } else {
    // Ghostty, iTerm2, WezTerm, and rxvt-unicode support OSC 777.
    notifyOSC777(title, body);
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_execution_start", async (event, ctx) => {
    if (ctx.mode !== "tui" || event.toolName !== "ask_user") return;
    notify(TITLE, "Your decision is required");
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (ctx.mode !== "tui" || !ctx.isIdle()) return;
    notify(TITLE, "Turn complete — ready for input");
  });

  pi.registerCommand("notify-test", {
    description: "Send a delayed test notification (default: 3 seconds)",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") return;

      const requestedDelay = Number.parseFloat(args.trim());
      const delaySeconds = Number.isFinite(requestedDelay)
        ? Math.min(30, Math.max(1, requestedDelay))
        : 3;

      ctx.ui.notify(
        `Notification scheduled in ${delaySeconds}s — switch away from Ghostty now`,
        "info",
      );

      const timer = setTimeout(() => {
        // Include a timestamp so Ghostty's identical-notification rate limiter
        // does not suppress repeated tests within five seconds.
        notify(TITLE, `Terminal notifications are working (${new Date().toLocaleTimeString()})`);
      }, delaySeconds * 1000);
      timer.unref();
    },
  });
}
