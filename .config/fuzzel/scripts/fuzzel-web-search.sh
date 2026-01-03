#!/usr/bin/env bash
query=$(echo "" | fuzzel --dmenu --prompt="🔍 Search: " --lines=0)
if [ -n "$query" ]; then
    encoded=$(echo "$query" | jq -sRr @uri)
    xdg-open "https://www.google.com/search?q=$encoded"
fi
