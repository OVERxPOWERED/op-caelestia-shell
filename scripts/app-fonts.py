#!/usr/bin/env python3
"""Default fonts for apps, behind Nexus > Look & feel > App fonts.

    app-fonts.py status           JSON: whether it is on, the chosen fonts, which fonts are available
    app-fonts.py set SANS MONO [SANS_SCALE MONO_SCALE]
                                  map sans-serif and monospace (fontconfig) and the GTK fonts;
                                  the scales (1 = as designed) make a font with small letters bigger
    app-fonts.py off              undo that, restoring the GTK fonts that were there before
    app-fonts.py add PATH         copy a .ttf/.otf/.ttc into our own fonts folder
    app-fonts.py remove FILE      delete a font we added (by file name, only from that folder)

Files we own: ~/.config/fontconfig/conf.d/60-caelestia-app-fonts.conf (carries a marker, and
`off` refuses to delete a file without it), ~/.local/share/fonts/caelestia/ (fonts you added),
and ~/.local/state/caelestia/app-fonts-restore.json (the GTK fonts to put back).
"""
import json
import os
import re
import subprocess
import sys
import shutil
from pathlib import Path
from xml.sax.saxutils import escape

CONF = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "fontconfig/conf.d/60-caelestia-app-fonts.conf"
FONTS = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "fonts/caelestia"
RESTORE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "caelestia/app-fonts-restore.json"
EXTS = {".ttf", ".otf", ".ttc"}
MARKER = "<!-- caelestia-app-fonts -->"
SANS = ["Adwaita Sans", "Liberation Sans", "Noto Sans"]  # built-in choices; fonts you add join them
MONO = ["JetBrains Mono", "Adwaita Mono", "Liberation Mono", "CaskaydiaCove Nerd Font Mono"]


def families_in(path):
    out = subprocess.run(["fc-scan", "--format", "%{family[0]}\\n", str(path)], capture_output=True, text=True).stdout
    return sorted({l.strip() for l in out.splitlines() if l.strip()})


def added():
    """[{file, family}] for fonts in our own folder."""
    if not FONTS.is_dir():
        return []
    return [{"file": f.name, "family": fam} for f in sorted(FONTS.iterdir()) if f.suffix.lower() in EXTS
            for fam in families_in(f)[:1]]


def installed():
    out = subprocess.run(["fc-list", ":", "family"], capture_output=True, text=True).stdout
    fams = {f.strip() for line in out.splitlines() for f in line.split(",")}
    return fams


def gsettings(*args):
    r = subprocess.run(["gsettings", *args], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def set_gtk(sans, mono):
    if not RESTORE.exists():  # remember the user's own values once
        RESTORE.parent.mkdir(parents=True, exist_ok=True)
        RESTORE.write_text(json.dumps({"font": gsettings("get", "org.gnome.desktop.interface", "font-name"),
                                       "mono": gsettings("get", "org.gnome.desktop.interface", "monospace-font-name")}))
    gsettings("set", "org.gnome.desktop.interface", "font-name", f"{sans} 11")
    gsettings("set", "org.gnome.desktop.interface", "monospace-font-name", f"{mono} 11")


def restore_gtk():
    if RESTORE.exists():
        old = json.loads(RESTORE.read_text())
        if old.get("font"):
            gsettings("set", "org.gnome.desktop.interface", "font-name", old["font"].strip("'"))
        if old.get("mono"):
            gsettings("set", "org.gnome.desktop.interface", "monospace-font-name", old["mono"].strip("'"))
        RESTORE.unlink()


def current():
    if not CONF.exists() or MARKER not in CONF.read_text():
        return None
    fams = re.findall(r"<family>([^<]+)</family>", CONF.read_text())
    # order in the file: sans-serif, its font, monospace, its font
    return {"sans": fams[1], "mono": fams[3]} if len(fams) >= 4 else None


def size_rule(family, scale):
    """Scale a family's pixel size wherever fontconfig is asked to match it (skipped at 1x)."""
    if abs(scale - 1) < 0.01:
        return ""
    return (f'  <match target="font"><test name="family" qual="any"><string>{escape(family)}</string></test>'
            f'<edit name="pixelsize" mode="assign"><times><name>pixelsize</name><double>{scale:.3f}</double></times></edit></match>\n')


def match(generic):
    return subprocess.run(["fc-match", "-f", "%{family[0]}", generic], capture_output=True, text=True).stdout


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    have = installed()
    if cmd == "status":
        cur = current()
        mine = added()
        extra = [a["family"] for a in mine]
        print(json.dumps({"enabled": cur is not None, "sans": cur and cur["sans"], "mono": cur and cur["mono"],
                          "added": mine,
                          "sansChoices": [f for f in SANS if f in have] + extra, "monoChoices": [f for f in MONO if f in have] + extra,
                          "nowSans": match("sans-serif"), "nowMono": match("monospace")}))
    elif cmd == "set" and len(sys.argv) in (4, 6):
        sans, mono = sys.argv[2], sys.argv[3]
        try:
            # Clamped so a bad value can never make text unreadably tiny or huge
            sans_scale, mono_scale = [min(2.0, max(0.5, float(v))) for v in sys.argv[4:6]] or [1.0, 1.0]
        except ValueError:
            sans_scale = mono_scale = 1.0
        extra = [a["family"] for a in added()]
        if sans not in SANS + extra or mono not in MONO + extra or sans not in have or mono not in have:
            sys.exit("font not available")
        CONF.parent.mkdir(parents=True, exist_ok=True)
        CONF.write_text(f"""<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
{MARKER}
<fontconfig>
  <alias binding="same"><family>sans-serif</family><prefer><family>{escape(sans)}</family></prefer></alias>
  <alias binding="same"><family>monospace</family><prefer><family>{escape(mono)}</family></prefer></alias>
{size_rule(sans, sans_scale)}{size_rule(mono, mono_scale) if mono != sans else ""}</fontconfig>
""")
        set_gtk(sans, mono)
        print(json.dumps({"ok": True}))
    elif cmd == "off":
        if CONF.exists() and MARKER in CONF.read_text():
            CONF.unlink()
        restore_gtk()
        print(json.dumps({"ok": True}))
    elif cmd == "add" and len(sys.argv) == 3:
        src = Path(sys.argv[2]).expanduser()
        if src.suffix.lower() not in EXTS or not src.is_file():
            print(json.dumps({"ok": False, "message": "Choose a .ttf, .otf or .ttc font file"}))
            return
        if not os.access(src, os.R_OK):
            # Zip extractors sometimes leave files with no permissions at all. We own the file,
            # so give ourselves read access (and nothing else) rather than refuse it.
            try:
                os.chmod(src, src.stat().st_mode | 0o400)
            except OSError:
                print(json.dumps({"ok": False, "message": "That file is not readable and its permissions can't be changed"}))
                return
        fams = families_in(src)
        if not fams:
            print(json.dumps({"ok": False, "message": "That file is not a usable font"}))
            return
        FONTS.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, FONTS / src.name)
        subprocess.run(["fc-cache", "-f", str(FONTS)], capture_output=True)
        print(json.dumps({"ok": True, "message": f"Added {fams[0]}"}))
    elif cmd == "remove" and len(sys.argv) == 3:
        target = FONTS / Path(sys.argv[2]).name  # a bare file name, never a path
        if target.is_file() and target.parent == FONTS:
            target.unlink()
            subprocess.run(["fc-cache", "-f", str(FONTS)], capture_output=True)
        print(json.dumps({"ok": True, "message": "Removed"}))
    else:
        sys.exit("usage: app-fonts.py status | set SANS MONO | off | add PATH | remove FILE")


if __name__ == "__main__":
    main()
