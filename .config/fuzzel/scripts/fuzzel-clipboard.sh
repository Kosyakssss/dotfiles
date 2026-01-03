#!/usr/bin/env bash
cliphist list | \
    fuzzel --dmenu --prompt="📋 Clipboard: " | \
    cliphist decode | \
    wl-copy
