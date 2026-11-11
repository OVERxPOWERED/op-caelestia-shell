#!/usr/bin/env python3
import sys
import io
import re
import json
import subprocess
from pathlib import Path
from PIL import Image

CACHE_DIR = Path.home() / ".cache" / "cliphist" / "thumbnails"
CACHE_DIR.mkdir(parents=True, exist_ok=True)

PINS_FILE = Path.home() / ".local" / "share" / "caelestia" / "clipboard" / "pins.json"
PINS_FILE.parent.mkdir(parents=True, exist_ok=True)

def load_pins():
    if PINS_FILE.exists():
        try:
            return json.loads(PINS_FILE.read_text())
        except Exception:
            return []
    return []

def save_pins(pins):
    try:
        PINS_FILE.write_text(json.dumps(pins, indent=2))
    except Exception:
        pass

def get_list(limit=60):
    try:
        raw_list = subprocess.check_output(["cliphist", "list"]).decode("utf-8", errors="replace").splitlines()
    except Exception:
        return []

    pinned_ids = {p.get("id") for p in load_pins() if "id" in p}
    items = []

    for line in raw_list[:limit]:
        parts = line.split("\t", 1)
        if len(parts) < 2:
            continue
        item_id, preview = parts[0].strip(), parts[1]
        is_img = preview.startswith("[[ binary data")

        if is_img:
            match = re.search(r"\[\[\s*binary\s+data\s+([^\]]+)\]\]", preview)
            raw_details = match.group(1).strip() if match else preview
            thumb_path = CACHE_DIR / f"{item_id}.png"
            
            # Ensure thumbnail is generated
            if not thumb_path.exists():
                try:
                    raw_bytes = subprocess.check_output(["cliphist", "decode", item_id], stderr=subprocess.DEVNULL)
                    with Image.open(io.BytesIO(raw_bytes)) as img:
                        img = img.convert("RGBA")
                        img.thumbnail((128, 128), Image.Resampling.LANCZOS)
                        canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
                        offset = ((128 - img.width) // 2, (128 - img.height) // 2)
                        canvas.paste(img, offset)
                        canvas.save(thumb_path, "PNG")
                except Exception:
                    pass

            # Prettify dimensions & size
            # e.g. "49 KiB png 512x170" -> "512 × 170 • 49 KiB PNG"
            dim_match = re.search(r"(\d+x\d+)", raw_details)
            size_match = re.search(r"([\d\.]+\s*[KMGT]?i?B)", raw_details, re.IGNORECASE)
            fmt_match = re.search(r"\b(png|jpe?g|webp|gif)\b", raw_details, re.IGNORECASE)

            dims = dim_match.group(1).replace("x", " × ") if dim_match else ""
            size = size_match.group(1) if size_match else ""
            fmt = fmt_match.group(1).upper() if fmt_match else "IMAGE"
            
            tags = [x for x in [dims, size, fmt] if x]
            details = " • ".join(tags) if tags else raw_details

            items.append({
                "id": item_id,
                "type": "image",
                "title": f"Image ({dims or size})",
                "details": details,
                "thumb": str(thumb_path) if thumb_path.exists() else "",
                "pinned": item_id in pinned_ids
            })
        else:
            text = preview.strip()
            is_url = text.startswith(("http://", "https://"))
            is_code = any(sym in text for sym in ["{", "}", "const ", "def ", "import ", "class ", "=>", "$ ", "sudo "]) and "\n" in text or len(text) > 40 and any(sym in text for sym in ["{", "}", ";", "()"])
            item_type = "url" if is_url else ("code" if is_code else "text")

            items.append({
                "id": item_id,
                "type": item_type,
                "title": text,
                "details": f"{len(text)} chars",
                "thumb": "",
                "pinned": item_id in pinned_ids
            })

    return items

def copy_item(item_id):
    try:
        decoded = subprocess.check_output(["cliphist", "decode", item_id])
        subprocess.run(["wl-copy"], input=decoded)
        return True
    except Exception as e:
        return False

def delete_item(item_id):
    try:
        subprocess.run(["cliphist", "delete"], input=f"{item_id}\t\n".encode(), check=True)
        thumb = CACHE_DIR / f"{item_id}.png"
        thumb.unlink(missing_ok=True)
        return True
    except Exception:
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] == "list":
        limit = int(sys.argv[2]) if len(sys.argv) > 2 else 60
        print(json.dumps(get_list(limit)))
    elif sys.argv[1] == "copy" and len(sys.argv) > 2:
        copy_item(sys.argv[2])
    elif sys.argv[1] == "delete" and len(sys.argv) > 2:
        delete_item(sys.argv[2])
