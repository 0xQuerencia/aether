#!/usr/bin/env python3
"""Pinned clipboard entries: copies of cliphist entries that never expire.

  clip_pins.py pin <cliphist-id>   save the entry (text or image) as a pin
  clip_pins.py unpin <pin-id>      delete a pin
  clip_pins.py copy <pin-id>       put a pin back on the clipboard
  clip_pins.py list                JSON list, newest first

Pins live in $XDG_DATA_HOME/quickshell/clip-pins (0700, files 0600).
"""
import json
import os
import subprocess
import sys
import time

DATA_HOME = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
PIN_DIR = os.path.join(DATA_HOME, "quickshell", "clip-pins")
INDEX = os.path.join(PIN_DIR, "index.json")
PREVIEW_CHARS = 200


def _load():
    try:
        with open(INDEX) as f:
            return json.load(f)
    except (OSError, ValueError):
        return []


def _save(pins):
    tmp = INDEX + ".part"
    with open(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
        json.dump(pins, f)
    os.replace(tmp, INDEX)


def _image_mime(data):
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if data[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    if data[:4] == b"GIF8":
        return "image/gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return ""


def pin(clip_id):
    if not clip_id.isdigit():
        raise ValueError("bad id")
    data = subprocess.run(["cliphist", "decode", clip_id], capture_output=True, timeout=3, check=True).stdout
    if not data:
        raise ValueError("empty entry")
    pins = _load()
    pin_id = str(int(time.time() * 1000))
    mime = _image_mime(data)
    image = bool(mime)
    path = os.path.join(PIN_DIR, pin_id + (".img" if image else ".txt"))
    with open(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb") as f:
        f.write(data)
    preview = "" if image else data[:PREVIEW_CHARS * 4].decode("utf-8", "replace")[:PREVIEW_CHARS]
    pins.insert(0, {"id": pin_id, "type": "image" if image else "text",
                    "file": path, "mime": mime or "text/plain",
                    "content": preview or "[[ pinned image ]]"})
    _save(pins)


def unpin(pin_id):
    pins = _load()
    keep = [p for p in pins if p["id"] != pin_id]
    for p in pins:
        if p["id"] == pin_id:
            try:
                os.remove(p["file"])
            except OSError:
                pass
    _save(keep)


def copy(pin_id):
    for p in _load():
        if p["id"] == pin_id:
            args = ["wl-copy"] + (["--type", p.get("mime", "image/png")] if p["type"] == "image" else [])
            with open(p["file"], "rb") as f:
                subprocess.run(args, stdin=f, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3)
            return
    raise ValueError("no such pin")


def main(argv):
    os.makedirs(PIN_DIR, mode=0o700, exist_ok=True)
    cmd = argv[1] if len(argv) > 1 else "list"
    if cmd == "list":
        print(json.dumps(_load()))
    elif cmd in ("pin", "unpin", "copy") and len(argv) > 2:
        {"pin": pin, "unpin": unpin, "copy": copy}[cmd](argv[2])
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except (ValueError, OSError, subprocess.SubprocessError) as e:
        print(f"clip_pins: {e}", file=sys.stderr)
        sys.exit(1)
