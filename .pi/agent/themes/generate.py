#!/usr/bin/env python3
"""Generate Pi themes from the canonical Stargazing palette."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

SCHEMA = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json"
FAMILY_NAMES = {
    "soft-parchment": "soft-parchment",
    "gallery-plaster": "gallery-plaster",
    "mineral-paper": "mineral-paper",
    "blue-hour": "blue-hour",
    "grey-fruit": "grey-fruit",
}


def hex_value(value: dict[str, object]) -> str:
    return str(value["hex"])


def make_theme(family: str, source: dict[str, object], mode: str) -> dict[str, object]:
    themes = source["themes"]
    accents = source["accents"]
    assert isinstance(themes, dict)
    assert isinstance(accents, dict)

    family_data = themes[family]
    assert isinstance(family_data, dict)
    dark = mode == "dark"
    accent_step = "400" if dark else "600"
    explicit = family_data.get("semantic")
    if isinstance(explicit, dict):
        roles = explicit[mode]
        assert isinstance(roles, dict)
        vars_ = {key: hex_value(value) for key, value in roles.items()}
    else:
        base = family_data["base"]
        assert isinstance(base, dict)
        vars_ = {
            "bg": hex_value(base["black" if dark else "paper"]),
            "bg2": hex_value(base["950" if dark else "50"]),
            "ui": hex_value(base["900" if dark else "100"]),
            "ui2": hex_value(base["850" if dark else "150"]),
            "ui3": hex_value(base["800" if dark else "200"]),
            "tx3": hex_value(base["700" if dark else "300"]),
            "tx2": hex_value(base["500" if dark else "600"]),
            "tx": hex_value(base["200" if dark else "black"]),
        }
    for name in ("red", "orange", "yellow", "green", "cyan", "blue", "purple", "magenta"):
        ramp = accents[name]
        assert isinstance(ramp, dict)
        vars_[name] = hex_value(ramp[accent_step])
    primary_accent = "blue" if family == "grey-fruit" else "cyan"
    return {
        "$schema": SCHEMA,
        "name": f"stargazing-{FAMILY_NAMES[family]}-{mode}",
        "vars": vars_,
        "colors": {
            "accent": primary_accent,
            "border": "ui2",
            "borderAccent": primary_accent,
            "borderMuted": "ui",
            "success": "green",
            "error": "red",
            "warning": "orange",
            "muted": "tx2",
            "dim": "tx3",
            "text": "tx",
            "thinkingText": "tx2",
            "selectedBg": "selection" if isinstance(explicit, dict) else "ui3",
            "userMessageBg": "bg2",
            "userMessageText": "tx",
            "customMessageBg": "bg2",
            "customMessageText": "tx",
            "customMessageLabel": primary_accent,
            "toolPendingBg": "bg2",
            "toolSuccessBg": "bg2",
            "toolErrorBg": "bg2",
            "toolTitle": primary_accent,
            "toolOutput": "tx",
            "mdHeading": "orange",
            "mdLink": primary_accent,
            "mdLinkUrl": "tx2",
            "mdCode": "magenta",
            "mdCodeBlock": "tx",
            "mdCodeBlockBorder": "ui2",
            "mdQuote": "tx",
            "mdQuoteBorder": "ui2",
            "mdHr": "ui",
            "mdListBullet": primary_accent,
            "toolDiffAdded": "green",
            "toolDiffRemoved": "red",
            "toolDiffContext": "tx2",
            "syntaxComment": "tx3",
            "syntaxKeyword": "green",
            "syntaxFunction": "orange",
            "syntaxVariable": "blue",
            "syntaxString": "cyan",
            "syntaxNumber": "purple",
            "syntaxType": "yellow",
            "syntaxOperator": "tx2",
            "syntaxPunctuation": "tx2",
            "thinkingOff": "tx3",
            "thinkingMinimal": "tx2",
            "thinkingLow": "blue",
            "thinkingMedium": "cyan",
            "thinkingHigh": "purple",
            "thinkingXhigh": "magenta",
            "thinkingMax": "red",
            "bashMode": "orange",
        },
        "export": {
            "pageBg": vars_["bg"],
            "cardBg": vars_["bg2"],
            "infoBg": vars_["ui"],
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "palette",
        nargs="?",
        type=Path,
        default=Path.home() / "Code/stargazing/dist/stargazing.json",
    )
    args = parser.parse_args()
    source = json.loads(args.palette.read_text())
    output_dir = Path(__file__).resolve().parent

    for family in FAMILY_NAMES:
        for mode in ("light", "dark"):
            theme = make_theme(family, source, mode)
            path = output_dir / f"{theme['name']}.json"
            path.write_text(json.dumps(theme, indent=2) + "\n")


if __name__ == "__main__":
    main()
