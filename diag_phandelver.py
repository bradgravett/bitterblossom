#!/usr/bin/env python3
"""Diagnose why 'Phandelver' cards are missing. Run against your dump:
   python3 diag_phandelver.py your-bulk-file.jsonl
Prints every card whose name contains 'Phandelver' with the fields the
pipeline filters on, so we can see which gate drops it."""
import sys, json

def iter_cards(path):
    with open(path, encoding="utf-8") as f:
        head = f.read(256)
    if head.lstrip()[:1] != "[":
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip().rstrip(",")
                if line and line not in ("[", "]"):
                    yield json.loads(line)
        return
    dec = json.JSONDecoder()
    with open(path, encoding="utf-8") as f:
        buf, started = "", False
        while True:
            chunk = f.read(1 << 20)
            if chunk: buf += chunk
            if not started:
                i = buf.find("[")
                if i == -1:
                    if not chunk: return
                    continue
                buf = buf[i+1:]; started = True
            while True:
                buf = buf.lstrip().lstrip(",").lstrip()
                if not buf: break
                if buf[0] == "]": return
                try: obj, end = dec.raw_decode(buf)
                except json.JSONDecodeError: break
                yield obj; buf = buf[end:]
            if not chunk: return

path = sys.argv[1]
hits = 0
for c in iter_cards(path):
    name = c.get("name", "")
    if "Phandelver" not in name:
        continue
    hits += 1
    faces = c.get("card_faces") or []
    print("="*60)
    print("name    :", name)
    print("lang    :", c.get("lang"))
    print("layout  :", c.get("layout"))
    print("set     :", c.get("set"), " cn:", c.get("collector_number"))
    print("type    :", c.get("type_line"))
    print("has top image_uris:", bool(c.get("image_uris")))
    for i, f in enumerate(faces):
        print(f"  face[{i}] type:", f.get("type_line"),
              " img:", bool((f.get('image_uris') or {}).get('normal')))
print("="*60)
print(f"{hits} Phandelver card(s) found in dump")
if hits == 0:
    print("=> Not in the dump at all. Wrong bulk file? (Use 'Default Cards',")
    print("   which includes tokens. 'Oracle Cards' may omit token printings.)")
