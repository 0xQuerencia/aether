#!/usr/bin/env python3
import json, sys, unicodedata


RANGES = [
    (0x1F600, 0x1F64F),  
    (0x1F300, 0x1F5FF),  
    (0x1F680, 0x1F6FF),  
    (0x1F900, 0x1F9FF),  
    (0x1FA70, 0x1FAFF),  
    (0x2600,  0x26FF),   
    (0x2700,  0x27BF),   
]

out = []
seen = set()
for lo, hi in RANGES:
    for cp in range(lo, hi + 1):
        ch = chr(cp)
        try:
            name = unicodedata.name(ch).lower()
        except ValueError:
            continue
        if ch in seen:
            continue
        seen.add(ch)
        out.append({"emoji": ch, "name": name})

print(json.dumps(out, ensure_ascii=False))
