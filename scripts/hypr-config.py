#!/usr/bin/env python3
"""Hyprland integration for OP-Caelestia Shell, with a full undo.

    hypr-config.py status                  what is set up, and which backups exist
    hypr-config.py plan  [--keybinds]      show exactly what `apply` would change
    hypr-config.py apply [--keybinds] [-y] do it (backs up first, checks the result, rolls back on errors)
    hypr-config.py restore [--from-backup] undo it

It never rewrites your Hyprland config. It adds one marked block (an include line) to your main file,
and puts the autostart line and keybinds in a file of its own, ~/.config/hypr/op-caelestia.{lua,conf}.
The format (Lua or the older hyprlang .conf) is detected, never converted.

`restore` removes the marked block and the file we created. `restore --from-backup` instead copies
back the original of every file we modified (anything you changed in it since is lost).
Backups live in ~/.local/state/op-caelestia/backups/.
"""
import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "op-caelestia"
HYPR = CONFIG / "hypr"
MANIFEST = STATE / "hypr-setup.json"
BACKUPS = STATE / "backups"

LAUNCH = "op-caelestia"
MARK = "op-caelestia"  # appears in every marker, so a block is easy to find by hand

# (keys, shortcut, locked): locked binds also work while the screen is locked (media and brightness keys)
KEYBINDS = [
    ("SUPER + Space", "launcher", False),
    ("SUPER + Tab", "overview", False),
    ("SUPER + I", "nexus", False),
    ("SUPER + L", "lock", False),
    ("XF86MonBrightnessUp", "brightnessUp", True),
    ("XF86MonBrightnessDown", "brightnessDown", True),
    ("XF86AudioPlay", "mediaToggle", True),
    ("XF86AudioNext", "mediaNext", True),
    ("XF86AudioPrev", "mediaPrev", True),
]


# ---------------------------------------------------------------- detection

def main_config():
    """(format, path) of the user's main Hyprland config. Lua wins, as it does in Hyprland."""
    for fmt, name in (("lua", "hyprland.lua"), ("conf", "hyprland.conf")):
        if (HYPR / name).is_file():
            return fmt, HYPR / name
    return "none", None


def hyprland_version():
    try:
        out = subprocess.run(["Hyprland", "--version"], capture_output=True, text=True, timeout=10).stdout
    except (OSError, subprocess.TimeoutExpired):
        return None
    m = re.search(r"v?(\d+)\.(\d+)\.(\d+)", out)
    return tuple(int(x) for x in m.groups()) if m else None


def verify(path):
    """(ok, output) of Hyprland's own config check; (None, '') where it cannot run."""
    try:
        r = subprocess.run(["Hyprland", "--verify-config", "-c", str(path)], capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.TimeoutExpired):
        return None, ""
    out = r.stdout + r.stderr
    # Hyprland prints a lot of debug noise first; the verdict follows this heading
    out = out.split("Config parsing result:", 1)[-1]
    return r.returncode == 0, out.strip()


def existing_autostart():
    """Files under the Hyprland config that already start the shell."""
    hits = []
    if HYPR.is_dir():
        for p in HYPR.rglob("*"):
            if p.is_file() and p.suffix in (".lua", ".conf") and p.name not in ("op-caelestia.lua", "op-caelestia.conf"):
                try:
                    text = p.read_text(errors="replace")
                except OSError:
                    continue
                if re.search(r"op-caelestia|startup-shell\.sh", text):
                    hits.append(p)
    return hits


def uses_variables():
    for p in HYPR.rglob("*") if HYPR.is_dir() else []:
        if p.is_file() and p.suffix in (".lua", ".conf") and not p.name.startswith("op-caelestia."):
            try:
                if re.search(r"hl\.bind\(\s*(?!\")|^\s*bind\w*\s*=\s*\$", p.read_text(errors="replace"), re.M):
                    return True
            except OSError:
                pass
    return False


def norm_keys(spec):
    parts = [p for p in re.split(r"[\s+,]+", spec.strip()) if p]
    if not parts:
        return None
    return (frozenset(p.upper() for p in parts[:-1]), parts[-1].lower())


def bound_keys():
    """Key combinations the user's config binds, where they can be read (variables cannot be)."""
    used = set()
    if not HYPR.is_dir():
        return used
    for p in HYPR.rglob("*"):
        if not (p.is_file() and p.suffix in (".lua", ".conf")) or p.name.startswith("op-caelestia."):
            continue
        try:
            text = p.read_text(errors="replace")
        except OSError:
            continue
        for m in re.finditer(r'hl\.bind\(\s*"([^"]+)"', text):
            k = norm_keys(m.group(1))
            if k:
                used.add(k)
        for m in re.finditer(r"^\s*bind\w*\s*=\s*([^,\n]*),\s*([^,\n]+),", text, re.M):
            k = norm_keys(m.group(1) + " " + m.group(2))
            if k:
                used.add(k)
    return used


# ---------------------------------------------------------------- what we write

def owned_path(fmt):
    return HYPR / f"op-caelestia.{fmt}"


def render_owned(fmt, autostart, binds):
    head = ("-- " if fmt == "lua" else "# ") + f"{MARK}: written by `op-caelestia config apply`. Edit freely; `op-caelestia config restore` removes this file.\n"
    lines = [head]
    if autostart:
        if fmt == "lua":
            lines.append(f'hl.on("hyprland.start", function() hl.exec_cmd("{LAUNCH}") end)\n')
        else:
            lines.append(f"exec-once = {LAUNCH}\n")
    for keys, name, locked in binds:
        if fmt == "lua":
            extra = ", { locked = true }" if locked else ""
            lines.append(f'hl.bind("{keys}", hl.dsp.global("caelestia:{name}"){extra})\n')
        else:
            mods, _, key = keys.rpartition(" + ")
            kind = "bindl" if locked else "bind"
            lines.append(f"{kind} = {mods}, {key}, global, caelestia:{name}\n")
    return "".join(lines)


def block(fmt):
    if fmt == "lua":
        return (f"-- >>> {MARK} (added by `op-caelestia config apply`; `op-caelestia config restore` removes it) >>>\n"
                f'do local f = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/op-caelestia.lua"; '
                f'local h = io.open(f, "r"); if h then h:close(); dofile(f) end end\n'
                f"-- <<< {MARK} <<<\n")
    return (f"# >>> {MARK} (added by `op-caelestia config apply`; `op-caelestia config restore` removes it) >>>\n"
            f"source = ~/.config/hypr/op-caelestia.conf\n"
            f"# <<< {MARK} <<<\n")


BLOCK_RE = re.compile(rf"(?:\n)?^(?:--|#) >>> {MARK}.*?^(?:--|#) <<< {MARK} <<<\n", re.S | re.M)


def has_block(text):
    return BLOCK_RE.search(text) is not None


def choose(want_keys):
    """Split the wanted keybinds into those we can add and those the user's config already uses."""
    if not want_keys:
        return [], []
    used = bound_keys()
    add, skipped = [], []
    for item in KEYBINDS:
        (skipped if norm_keys(item[0]) in used else add).append(item)
    return add, skipped


def make_plan(want_keys):
    fmt, main = main_config()
    autostart_hits = existing_autostart()
    add, skipped = choose(want_keys)
    return {
        "fmt": fmt, "main": main, "owned": owned_path(fmt) if main else None,
        "autostart": not autostart_hits, "autostart_hits": autostart_hits,
        "binds": add, "skipped": skipped,
        "already": bool(main) and has_block(main.read_text(errors="replace")),
    }


# ---------------------------------------------------------------- commands

def cmd_status(_args):
    fmt, main = main_config()
    ver = hyprland_version()
    print(f"Hyprland config: {main if main else 'none found'} ({fmt})")
    print(f"Hyprland version: {'.'.join(map(str, ver)) if ver else 'not found'}")
    if ver and ver < (0, 55, 0):
        print("  Display and Look & feel features need Hyprland 0.55 or newer with a hyprland.lua config.")
    elif fmt == "conf":
        print("  Display and Look & feel features need a hyprland.lua config; the shell itself works with this one.")
    on = bool(main) and has_block(main.read_text(errors="replace"))
    print(f"Integration: {'set up' if on else 'not set up'}")
    if existing_autostart():
        print("Autostart already present in: " + ", ".join(str(p) for p in existing_autostart()))
    backups = sorted(BACKUPS.iterdir()) if BACKUPS.is_dir() else []
    print(f"Backups: {len(backups)}" + (f" (latest {backups[-1].name})" if backups else ""))
    return 0


def print_plan(plan):
    if plan["fmt"] == "none":
        print("No Hyprland config was found in", HYPR)
        print("Start Hyprland once so it creates one, then run this again.")
        return
    print(f"Your {plan['fmt']} config: {plan['main']}")
    if plan["already"]:
        print("  Already set up: the marked block is present. Nothing to add there.")
    else:
        print("  One block will be appended to it (nothing else in the file changes):\n")
        print("".join("      " + l + "\n" for l in block(plan["fmt"]).splitlines()))
    print(f"A new file will hold the rest: {plan['owned']}\n")
    if plan["autostart_hits"]:
        print("  Autostart: already present in " + ", ".join(str(p) for p in plan["autostart_hits"]) + "; not added again.")
    else:
        print(f"  Autostart: starts the shell with Hyprland ({LAUNCH}).")
    for keys, name, locked in plan["binds"]:
        print(f"  Keybind: {keys:<24} -> caelestia:{name}" + ("  (works when locked)" if locked else ""))
    for keys, name, _ in plan["skipped"]:
        print(f"  Skipped: {keys} is already bound in your config (caelestia:{name} not bound).")
    if plan["binds"] and uses_variables():
        print("\n  Note: some of your own binds use variables, which can't be checked here. If one of the keys above is\n"
              "  already taken that way, edit the new file; both actions would otherwise run.")
    print("\nA backup of your config is made first. Undo any time with: op-caelestia config restore")


def cmd_plan(args):
    print_plan(make_plan(args.keybinds))
    return 0


def backup_dir():
    d = BACKUPS / datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    d.mkdir(parents=True, exist_ok=True)
    return d


def cmd_apply(args):
    plan = make_plan(args.keybinds)
    print_plan(plan)
    if plan["fmt"] == "none":
        return 1
    if plan["already"] and plan["owned"].exists():
        print("\nAlready set up.")
        return 0
    if not args.yes:
        if not sys.stdin.isatty():
            print("\nNot a terminal: pass --yes to apply.", file=sys.stderr)
            return 1
        if input("\nApply these changes? [y/N] ").strip().lower() not in ("y", "yes"):
            print("Nothing changed.")
            return 0

    fmt, main, owned = plan["fmt"], plan["main"], plan["owned"]
    if owned.exists() and MARK not in owned.read_text(errors="replace").splitlines()[0]:
        print(f"{owned} exists and is not ours; not touching it.", file=sys.stderr)
        return 1

    before_ok, _ = verify(main)
    bdir = backup_dir()
    created, modified = [], []

    original = main.read_text(errors="replace")
    shutil.copy2(main, bdir / main.name)
    if owned.exists():
        shutil.copy2(owned, bdir / owned.name)
    else:
        created.append(str(owned))

    owned.write_text(render_owned(fmt, plan["autostart"], plan["binds"]))
    if not plan["already"]:
        modified.append({"path": str(main), "backup": str(bdir / main.name)})
        sep = "" if original.endswith("\n") or not original else "\n"
        main.write_text(original + sep + "\n" + block(fmt))

    after_ok, out = verify(main)
    if before_ok and after_ok is False:
        print("\nHyprland rejected the result, so everything was put back:\n" + out, file=sys.stderr)
        main.write_text(original)
        if str(owned) in created:
            owned.unlink(missing_ok=True)
        return 1

    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps({"time": bdir.name, "format": fmt, "created": created, "modified": modified}, indent=2))
    print(f"\nDone. Backup: {bdir}")
    if after_ok is None:
        print("(Hyprland's config check is not available here, so the result was not verified.)")
    print("Reload Hyprland (or log out and in) for it to take effect.")
    return 0


def cmd_restore(args):
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    fmt, main = main_config()
    changed = []

    targets = [Path(m["path"]) for m in manifest.get("modified", [])] or ([main] if main else [])
    backups = {m["path"]: m["backup"] for m in manifest.get("modified", [])}
    for path in targets:
        if not path.is_file():
            continue
        if args.from_backup and str(path) in backups and Path(backups[str(path)]).is_file():
            shutil.copy2(backups[str(path)], path)
            changed.append(f"restored {path} from its backup")
            continue
        text = path.read_text(errors="replace")
        new = BLOCK_RE.sub("", text)
        if new != text:
            path.write_text(new)
            changed.append(f"removed our block from {path}")

    for name in (f"op-caelestia.{f}" for f in ("lua", "conf")):
        p = HYPR / name
        if p.is_file() and MARK in (p.read_text(errors="replace").splitlines() or [""])[0]:
            p.unlink()
            changed.append(f"removed {p}")

    if MANIFEST.exists():
        MANIFEST.rename(MANIFEST.with_suffix(".undone.json"))
    if not changed:
        print("Nothing to undo: no OP-Caelestia setup was found in your Hyprland config.")
    else:
        print("\n".join(changed))
        print("Reload Hyprland (or log out and in) for it to take effect.")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Hyprland integration for OP-Caelestia Shell")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status")
    for name in ("plan", "apply"):
        p = sub.add_parser(name)
        p.add_argument("--keybinds", action="store_true", help="also add suggested keybinds (never overriding existing ones)")
        if name == "apply":
            p.add_argument("-y", "--yes", action="store_true")
    r = sub.add_parser("restore")
    r.add_argument("--from-backup", action="store_true")
    args = ap.parse_args()
    sys.exit({"status": cmd_status, "plan": cmd_plan, "apply": cmd_apply, "restore": cmd_restore}[args.cmd](args))


if __name__ == "__main__":
    main()
