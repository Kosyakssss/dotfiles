#!/usr/bin/env bash
cliphist list | \
    fuzzel --dmenu --prompt="📋 Clipboard: " --with-nth=2 | \
    cliphist decode | \
    wl-copy
