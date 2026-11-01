#!/usr/bin/env python3
"""Persistent state for the island emoji panel (recents + skin tone).

Commands:
  recent add <emoji>   remember an emoji as the most recently used one
  recent list          print [{"e": ..., "c": count, "t": unixtime}, ...]
  tone get             print the stored skin tone index (0 = none)
  tone set <0-5>       store the skin tone index

State lives in $XDG_STATE_HOME/quickshell/emoji.json (default
~/.local/state), created 0600 and replaced atomically.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
import time
from pathlib import Path

MAX_RECENT = 32
TONE_MAX = 5

USAGE = "usage: emoji_store.py recent add|list [emoji] | tone get|set [0-5]"


def state_path() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or os.path.join(
        os.path.expanduser("~"), ".local", "state"
    )
    return Path(base) / "quickshell" / "emoji.json"


def load(path: Path) -> dict:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"tone": 0, "recent": []}
    if not isinstance(raw, dict):
        return {"tone": 0, "recent": []}
    tone = raw.get("tone", 0)
    if not isinstance(tone, int) or not 0 <= tone <= TONE_MAX:
        tone = 0
    recent = []
    for item in raw.get("recent", []) if isinstance(raw.get("recent"), list) else []:
        if not isinstance(item, dict) or not isinstance(item.get("e"), str):
            continue
        recent.append({
            "e": item["e"],
            "c": item.get("c", 1) if isinstance(item.get("c", 1), int) else 1,
            "t": item.get("t", 0) if isinstance(item.get("t", 0), (int, float)) else 0,
        })
    return {"tone": tone, "recent": recent[:MAX_RECENT]}


def save(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        os.chmod(path.parent, 0o700)
    except OSError:
        pass
    fd, tmp = tempfile.mkstemp(prefix=".emoji-", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(data, fh, ensure_ascii=False)
            fh.write("\n")
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def recent_add(path: Path, emoji: str) -> None:
    if not emoji or len(emoji) > 32:
        raise SystemExit("recent add: expected one emoji")
    data = load(path)
    rest = [r for r in data["recent"] if r["e"] != emoji]
    prev = next((r for r in data["recent"] if r["e"] == emoji), None)
    count = (prev["c"] if prev else 0) + 1
    data["recent"] = [{"e": emoji, "c": count, "t": int(time.time())}] + rest
    data["recent"] = data["recent"][:MAX_RECENT]
    save(path, data)


def recent_list(path: Path) -> None:
    print(json.dumps(load(path)["recent"], ensure_ascii=False))


def tone_get(path: Path) -> None:
    print(load(path)["tone"])


def tone_set(path: Path, value: str) -> None:
    try:
        tone = int(value)
    except ValueError:
        raise SystemExit(f"tone set: not a number: {value}")
    if not 0 <= tone <= TONE_MAX:
        raise SystemExit(f"tone set: out of range 0-{TONE_MAX}: {tone}")
    data = load(path)
    data["tone"] = tone
    save(path, data)


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[0] not in ("recent", "tone"):
        raise SystemExit(USAGE)
    path = state_path()
    if argv[0] == "recent":
        if len(argv) == 2 and argv[1] == "list":
            recent_list(path)
        elif len(argv) == 3 and argv[1] == "add":
            recent_add(path, argv[2])
        else:
            raise SystemExit(USAGE)
    else:
        if len(argv) == 2 and argv[1] == "get":
            tone_get(path)
        elif len(argv) == 3 and argv[1] == "set":
            tone_set(path, argv[2])
        else:
            raise SystemExit(USAGE)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except BrokenPipeError:
        sys.exit(0)
