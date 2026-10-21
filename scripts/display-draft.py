#!/usr/bin/env python3
"""Edit a saved hyprmoncfg profile in place.

    display-draft.py PROFILE_NAME PATCHES_JSON

PATCHES_JSON maps output names to changes, using the names the Nexus Display
page uses: mode ("1920x1080@60.01"), x, y, scale, transform, disabled (bool)
and mirrorOf (output name, or "" for none).
"""

import json
import sys
from pathlib import Path

PROFILES = Path.home() / ".config" / "hyprmoncfg" / "profiles"


def find_profile(name: str) -> Path:
    for path in PROFILES.glob("*.json"):
        try:
            if json.loads(path.read_text()).get("name") == name:
                return path
        except (OSError, ValueError):
            continue
    sys.exit(f"profile {name!r} not found")


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)

    path = find_profile(sys.argv[1])
    profile = json.loads(path.read_text())
    patches = json.loads(sys.argv[2])
    outputs = {o["name"]: o for o in profile["outputs"]}

    for name, patch in patches.items():
        out = outputs.get(name)
        if out is None:
            continue

        if "disabled" in patch:
            out["enabled"] = not patch["disabled"]
        if "mode" in patch:
            size, _, rate = patch["mode"].partition("@")
            width, _, height = size.partition("x")
            out["width"], out["height"] = int(width), int(height)
            out["refresh"] = float(rate)
            out["mode"] = f"{patch['mode']}Hz"
        for field in ("x", "y", "scale", "transform"):
            if field in patch:
                out[field] = patch[field]
        if "mirrorOf" in patch:
            target = outputs.get(patch["mirrorOf"])
            if patch["mirrorOf"] and target:
                out["mirror_of"] = target["key"]
            else:
                out.pop("mirror_of", None)

    path.write_text(json.dumps(profile, indent=2) + "\n")


if __name__ == "__main__":
    main()
