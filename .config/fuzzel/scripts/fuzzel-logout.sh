#!/usr/bin/env bash
options="🔒 Lock
💤 Sleep
🚪 Logout
🔄 Reboot
⚡ Shutdown"

selected=$(echo "$options" | fuzzel --dmenu --prompt="⚙️ Power: " --lines=5)

case "$selected" in
  "🔒 Lock") swaylock ;;
  "💤 Sleep") systemctl suspend ;;
  "🚪 Logout") niri msg action quit ;;
  "🔄 Reboot") systemctl reboot ;;
  "⚡ Shutdown") systemctl poweroff ;;
esac
