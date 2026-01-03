#!/usr/bin/env bash
 options="🔍 Web Search
😀 Emoji Picker
📋 Clipboard History
⚙️ Power Menu"

 selected=$(echo "$options" | fuzzel --dmenu --prompt="🚀 Menu: " --lines=5)

 case "$selected" in
     "😀 Emoji Picker") ~/.config/fuzzel/scripts/fuzzel-emoji.sh ;;
     "🔍 Web Search") ~/.config/fuzzel/scripts/fuzzel-web-search.sh ;;
     "📋 Clipboard History") ~/.config/fuzzel/scripts/fuzzel-clipboard.sh ;;
     "⚙️ Power Menu") ~/.config/fuzzel/scripts/fuzzel-logout.sh ;;
 esac
