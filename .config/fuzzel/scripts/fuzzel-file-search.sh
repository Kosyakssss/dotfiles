#!/usr/bin/env bash
 selected=$(fd --type f --hidden --follow --exclude .git . "$HOME" | \
            fuzzel --dmenu --prompt="📁 File: ")

 if [ -n "$selected" ]; then
     dir=$(dirname "$selected")
     ghostty -e yazi "$dir" --entry-file "$selected"
 fi
