#!/usr/bin/env python3
"""Generate docs/configuration.md from the plugin's config headers, so it cannot drift from the code.

Run from anywhere: python3 scripts/gen-config-docs.py   (add --check to fail if the file is stale)
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONF = ROOT / "plugin/src/Caelestia/Config"
OUT = ROOT / "docs/configuration.md"

HEADERS = [p for p in sorted(CONF.glob("*.hpp"))]
CLASS_RE = re.compile(r"class\s+(\w+)\s*:\s*public\s+[\w:]+\s*\{(.*?)\n\};", re.S)
PROP_RE = re.compile(r"CONFIG_(?:GLOBAL_)?PROPERTY\(\s*([\w:<>]+)\s*,\s*(\w+)\s*,\s*(.*?)\)\s*(?:/\*.*?\*/)?\s*$", re.M)
SUB_RE = re.compile(r"CONFIG_SUBOBJECT\(\s*(\w+)\s*,\s*(\w+)\s*\)")
LIST_RE = re.compile(r"CONFIG_LIST\(\s*(\w+)\s*,\s*(\w+)")

SKIP_ROOTS = {"appearance"}  # fonts, scales, curves: described by hand below, they are generated from many macros


def prettify(default: str) -> str:
    m = re.match(r'QStandardPaths::writableLocation\(QStandardPaths::(\w+)Location\)\s*\+\s*u?"(.*)"(?:_s)?', default.strip())
    if m:
        folder = {"Pictures": "Pictures", "Music": "Music", "Home": "", "Documents": "Documents"}.get(m.group(1), m.group(1))
        return ("~/" + folder + m.group(2)).replace("~//", "~/")
    d = re.sub(r'u"((?:[^"\\]|\\.)*)"_s', r'"\1"', default.strip())
    d = re.sub(r"\s*,\s*\.allowedTypes.*$", "", d)
    d = d.replace("{}", "empty").replace("QStringList", "").strip()
    d = re.sub(r"\s+", " ", d)
    return d.strip("{} ").strip() or "empty" if d not in ("true", "false") and not re.fullmatch(r"[\d.\-]+", d) else d


def load():
    classes = {}
    for h in HEADERS:
        text = h.read_text()
        for name, body in CLASS_RE.findall(text):
            props = [(t, n, prettify(d)) for t, n, d in PROP_RE.findall(body)]
            subs = SUB_RE.findall(body)
            lists = LIST_RE.findall(body)
            classes[name] = {"props": props, "subs": subs, "lists": lists}
    return classes


def walk(classes, cls, prefix, rows):
    c = classes.get(cls)
    if not c:
        return
    for t, n, d in c["props"]:
        rows.append((prefix + n, t.replace("QStringList", "list of strings").replace("QString", "string").replace("QVariant", "any").replace("qreal", "number"), d))
    for lst_type, n in c["lists"]:
        rows.append((prefix + n, "list", "built-in list"))
    for sub_type, n in c["subs"]:
        walk(classes, sub_type, prefix + n + ".", rows)


def main():
    classes = load()
    root = classes["ConfigRoot"]
    lines = ["# Configuration reference", "",
             "Settings live in `~/.config/caelestia/shell.json`. You rarely need to edit it by hand: **Nexus** (the settings app) changes",
             "most of them, and the file only contains what you changed. Anything missing falls back to the default shown here.", "",
             "Per-monitor overrides go in `~/.config/caelestia/monitors/<monitor name>/shell.json`; they use the same keys and only",
             "affect that display (Nexus uses this for Display > Interface size).", "",
             "> This page is generated from the plugin's source by `scripts/gen-config-docs.py`. Do not edit it by hand.", "",
             "Dotted names are nested objects: `dock.maxSlots` is `{ \"dock\": { \"maxSlots\": 5 } }`.", ""]
    for sub_type, name in root["subs"]:
        if name in SKIP_ROOTS:
            continue
        rows = []
        walk(classes, sub_type, name + ".", rows)
        if not rows:
            continue
        lines += [f"## `{name}`", "", "| Option | Type | Default |", "| --- | --- | --- |"]
        for opt, typ, dflt in rows:
            lines.append(f"| `{opt}` | {typ} | `{dflt}` |".replace("`empty`", "empty"))
        lines.append("")
    lines += ["## `appearance`", "",
              "Text, spacing, rounding and animation scales (`appearance.font.scale`, `appearance.padding.scale`,",
              "`appearance.spacing.scale`, `appearance.rounding.scale`, `appearance.anim.durations.scale`; all default to 1) and the",
              "font family and size of each text style (`appearance.font.body.family`, `appearance.font.body.medium.size`, ...).",
              "Nexus > Look & feel and Display > Interface size change these for you.", ""]
    out = "\n".join(lines)
    if "--check" in sys.argv:
        sys.exit(0 if OUT.exists() and OUT.read_text() == out else "docs/configuration.md is out of date; run scripts/gen-config-docs.py")
    OUT.write_text(out)
    print(f"wrote {OUT.relative_to(ROOT)}: {out.count(chr(10))} lines")


if __name__ == "__main__":
    main()
