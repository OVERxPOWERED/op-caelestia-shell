#!/usr/bin/env python3
"""Generate modules/nexus/SearchIndex.qml, the Nexus settings search index.

The index is derived from the page files themselves so it cannot drift:
every settings row (ToggleRow, StepperRow, SelectRow, ...) with a literal
label becomes one entry, and every page and sub-page becomes an entry.

    gen-nexus-search-index.py          rewrite the index
    gen-nexus-search-index.py --check  exit 1 if the index is out of date

Extra search keywords live in scripts/nexus-search-keywords.json.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NEXUS = ROOT / "modules" / "nexus"
OUT = NEXUS / "SearchIndex.qml"
KEYWORDS = Path(__file__).resolve().parent / "nexus-search-keywords.json"

ROW_TYPES = {
    "ToggleRow",
    "StepperRow",
    "SelectRow",
    "SliderRow",
    "TextFieldRow",
    "InfoRow",
    "WrapInfoRow",
    "NavRow",
    "RowButton",
    "ButtonRow",
    "DefaultRow",
}

# Sub-pages that only make sense with state chosen elsewhere (a selected
# device, network, app, ...), so they cannot be opened from search.
SKIP_SUBPAGES = {
    "AppInfo",
    "BtDeviceInfo",
    "BluetoothPairing",
    "NetworkDetailPage",
    "EthernetDetailPage",
    "WallpaperCategory",
}

TR_CALL = re.compile(r'(Tr\.trCtx|Tr\.tr|qsTr)\(\s*"((?:[^"\\]|\\.)*)"\s*(?:,\s*"((?:[^"\\]|\\.)*)"\s*)?\)')


def strip_comments(src: str) -> str:
    """Blank out // and /* */ comments, keeping strings and offsets intact."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == '"':
            j = i + 1
            while j < n and src[j] != '"':
                j += 2 if src[j] == "\\" else 1
            out.append(src[i : j + 1])
            i = j + 1
        elif src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif src.startswith("/*", i):
            j = src.find("*/", i)
            j = n if j < 0 else j + 2
            out.append("".join(ch if ch == "\n" else " " for ch in src[i:j]))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def block_end(src: str, open_idx: int) -> int:
    """Index just past the brace that closes the one at open_idx."""
    depth, i, n = 0, open_idx, len(src)
    while i < n:
        c = src[i]
        if c == '"':
            i += 1
            while i < n and src[i] != '"':
                i += 2 if src[i] == "\\" else 1
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return n


def own_properties(body: str) -> dict:
    """Literal-string properties declared directly in a block (depth 1)."""
    props = {}
    depth, i, n = 0, 0, len(body)
    line_start = 0
    while i < n:
        c = body[i]
        if c == '"':
            i += 1
            while i < n and body[i] != '"':
                i += 2 if body[i] == "\\" else 1
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        elif c == "\n":
            line_start = i + 1
        if depth == 1 and c == "\n":
            m = re.match(r"\s*(text|label|subtext|title)\s*:\s*", body[i + 1 :])
            if m:
                start = i + 1 + m.end()
                t = TR_CALL.match(body, start)
                if t:
                    after = body[t.end() : t.end() + 8]
                    if not after.lstrip().startswith("."):
                        props.setdefault(m.group(1), t)
        i += 1
    return props


def expr(match) -> str:
    return match.group(0)


def usable(match) -> bool:
    text = match.group(2)
    return bool(text.strip()) and "%" not in text and "\\n" not in text


def find_type(src: str, name: str):
    m = re.search(r"(?m)^\s*" + re.escape(name) + r"\s*\{", src)
    return m


def parse_registry():
    """Return (page label exprs, {label: description expr}, [sub-page type names per page])."""
    reg = strip_comments((NEXUS / "PageRegistry.qml").read_text())
    page_labels = re.findall(r'label:\s*(Tr\.tr\("(?:[^"\\]|\\.)*"\))', reg)
    descs = {}
    for m in re.finditer(
        r'label:\s*(Tr\.tr\("(?:[^"\\]|\\.)*"\)),\s*icon:\s*"[^"]+",\s*description:\s*(Tr\.tr\("(?:[^"\\]|\\.)*"\))', reg
    ):
        descs[m.group(1)] = m.group(2)

    comps = strip_comments((NEXUS / "PageCompRegistry.qml").read_text())
    list_open = comps.index("[", comps.index("pageComps"))
    depth, i = 0, list_open
    while True:  # find the matching ]
        c = comps[i]
        if c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                break
        i += 1
    list_body = comps[list_open + 1 : i]

    pages, pos = [], 0
    while True:
        m = re.compile(r"\bComponent\s*\{").search(list_body, pos)
        if not m:
            break
        end = block_end(list_body, m.end() - 1)
        body = list_body[m.end() : end - 1]
        types = re.findall(r"Component\s*\{\s*([A-Z][A-Za-z0-9]*)\s*\{\s*\}", body) if "StackPage" in body else []
        pages.append(types)
        pos = end
    return page_labels, descs, pages


def find_file(type_name: str):
    hits = list((NEXUS / "pages").rglob(f"{type_name}.qml"))
    return hits[0] if hits else None


def main() -> int:
    page_labels, descs, page_types = parse_registry()
    if len(page_labels) != len(page_types):
        sys.exit(f"page count mismatch: {len(page_labels)} labels vs {len(page_types)} components")

    extra = json.loads(KEYWORDS.read_text()) if KEYWORDS.exists() else {}
    page_kw = {k.lower(): v for k, v in extra.get("pages", {}).items()}
    row_kw = {k.lower(): v for k, v in extra.get("rows", {}).items()}

    entries = []

    def add(kind, page, sub, label, subtext, section, sub_title, kw):
        entries.append(
            {
                "kind": kind,
                "page": page,
                "sub": sub,
                "label": label,
                "subtext": subtext,
                "section": section,
                "subTitle": sub_title,
                "kw": kw,
            }
        )

    for page_idx, (page_label, types) in enumerate(zip(page_labels, page_types)):
        plain = TR_CALL.match(page_label).group(2)
        kws = page_kw.get(plain.lower(), [])
        desc = descs.get(page_label, "")
        add("page", page_idx, 0, page_label, desc or '""', '""', '""', [])

        for sub_idx, type_name in enumerate(types):
            if type_name in SKIP_SUBPAGES:
                continue
            path = find_file(type_name)
            if not path:
                continue
            src = strip_comments(path.read_text())
            root = re.search(r"(?m)^([A-Z][A-Za-z0-9]*)\s*\{", src)
            if not root:
                continue
            root_end = block_end(src, root.end() - 1)
            root_body = src[root.end() - 1 : root_end]
            sub_title = '""'
            title = own_properties(root_body).get("title")
            if title and usable(title):
                sub_title = expr(title)
                if sub_idx > 0:
                    add("page", page_idx, sub_idx, sub_title, '""', '""', sub_title, [])

            section = '""'
            for m in re.finditer(r"(?m)^\s*(SectionHeader|" + "|".join(sorted(ROW_TYPES)) + r")\s*\{", root_body):
                t = m.group(1)
                end = block_end(root_body, m.end() - 1)
                props = own_properties(root_body[m.end() - 1 : end])
                main = props.get("text") or props.get("label")
                if not main or not usable(main):
                    continue
                if t == "SectionHeader":
                    section = expr(main)
                    continue
                sub = props.get("subtext")
                row_extra = row_kw.get(main.group(2).lower(), [])
                add(
                    "row",
                    page_idx,
                    sub_idx,
                    expr(main),
                    expr(sub) if sub and usable(sub) else '""',
                    section,
                    sub_title,
                    row_extra,
                )

    # A row that only opens a sub-page is redundant next to the sub-page's own entry
    def plain_text(e):
        m = TR_CALL.match(e["label"])
        return m.group(2) if m else e["label"]

    sub_titles = {(e["page"], plain_text(e)) for e in entries if e["kind"] == "page" and e["sub"] > 0}
    entries = [e for e in entries if not (e["kind"] == "row" and (e["page"], plain_text(e)) in sub_titles)]

    lines = [
        "// Generated by scripts/gen-nexus-search-index.py, do not edit.",
        "// Regenerate after changing Nexus pages: scripts/gen-nexus-search-index.py",
        "pragma Singleton",
        "",
        "import QtQuick",
        "import Caelestia.I18n",
        "",
        "QtObject {",
        "    readonly property list<var> entries: [",
    ]
    for e in entries:
        kw = json.dumps(sorted({k.lower() for k in e["kw"]}))
        lines.append(
            f'        {{ kind: "{e["kind"]}", page: {e["page"]}, sub: {e["sub"]}, label: {e["label"]}, subtext: {e["subtext"]}, section: {e["section"]}, subTitle: {e["subTitle"]}, kw: {kw} }},'
        )
    lines += ["    ]", "", "    // Extra search keywords per page, indexed like PageRegistry.pages", "    readonly property list<var> pageKeywords: ["]
    for label in page_labels:
        plain = TR_CALL.match(label).group(2)
        lines.append("        " + json.dumps(sorted({k.lower() for k in page_kw.get(plain.lower(), [])})) + ",")
    lines += ["    ]", "}", ""]
    new = "\n".join(lines)

    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text() != new:
            print("modules/nexus/SearchIndex.qml is out of date; run scripts/gen-nexus-search-index.py", file=sys.stderr)
            return 1
        return 0

    OUT.write_text(new)
    rows = sum(e["kind"] == "row" for e in entries)
    print(f"wrote {OUT.relative_to(ROOT)}: {len(entries)} entries ({rows} settings, {len(entries) - rows} pages)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
