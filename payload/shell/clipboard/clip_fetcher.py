#!/usr/bin/env python3
import subprocess
import json
import os
import sys
import threading

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import clip_pins  # noqa: E402

KEEP_ENTRIES = 300          


def cleanup_cache(all_lines, cache_dir):
    valid_ids = set()
    for line in all_lines[:KEEP_ENTRIES]:
        if '\t' in line:
            valid_ids.add(line.split('\t', 1)[0])
    try:
        for f in os.listdir(cache_dir):
            if f.endswith('.png'):
                iid = f.replace('.png', '')
                if iid not in valid_ids:
                    try:
                        os.remove(os.path.join(cache_dir, f))
                    except Exception:
                        pass
    except Exception:
        pass

def image_preview(clip_id, cache_dir):
    """Decode an image entry once into the private cache; return its path ('' on failure)."""
    if not clip_id.isdigit():
        return ""
    path = os.path.join(cache_dir, clip_id + ".png")
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return path
    tmp = path + ".part"
    try:
        with open(tmp, "wb") as f:
            subprocess.run(["cliphist", "decode", clip_id], stdout=f,
                           stderr=subprocess.DEVNULL, timeout=3, check=True)
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
        return path
    except Exception:
        try:
            os.remove(tmp)
        except OSError:
            pass
        return ""


def get_cliphist():
    offset    = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    limit     = int(sys.argv[2]) if len(sys.argv) > 2 else 50
    cache_dir = sys.argv[3] if len(sys.argv) > 3 else \
                os.environ.get("QS_CACHE_CLIPBOARD",
                               os.path.expanduser("~/.cache/quickshell/clipboard"))
    os.makedirs(cache_dir, mode=0o700, exist_ok=True)

    try:
        result    = subprocess.run(["cliphist", "list"], capture_output=True, text=True)
        all_lines = result.stdout.strip().split('\n') if result.stdout.strip() else []

        lines = all_lines[offset:offset + limit]

        if offset == 0:
            threading.Thread(target=cleanup_cache,
                             args=(all_lines, cache_dir), daemon=True).start()

        entries = []
        if offset == 0:
            for p in clip_pins._load():
                entries.append({
                    "id":      "p:" + p["id"],
                    "content": p["content"],
                    "type":    p["type"],
                    "image":   p["file"] if p["type"] == "image" else "",
                    "pinned":  True,
                })
        for line in lines:
            if not line.strip():
                continue
            if '\t' in line:
                clip_id, content = line.split('\t', 1)
            else:
                clip_id = line
                content = line

            # detect image entries
            clip_type = "image" if content.strip().startswith("[[") else "text"

            entry = {
                "id":      clip_id,
                "content": content[:200],   
                "type":    clip_type,
            }
            if clip_type == "image":
                entry["image"] = image_preview(clip_id, cache_dir)
            entries.append(entry)

        print(json.dumps(entries))

    except Exception as e:
        print("[]")

if __name__ == "__main__":
    get_cliphist()
