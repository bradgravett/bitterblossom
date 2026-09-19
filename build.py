#!/usr/bin/env python3
"""
build.py — Bitterblossom pipeline driver.

One entry point, four stages. Settings come from config.py.

    python3 build.py all       # csv -> images -> lua  (full rebuild)
    python3 build.py csv       # parse dump + merge manual -> tokens.csv
    python3 build.py images    # download images named by id  -> token_images/
    python3 build.py lua       # tokens.csv + rehost URLs     -> TokenSpawner.lua

Typical flows:
  - New set dropped:        edit config if needed, `build.py all`, push repo.
  - Just changed the repo:  `build.py lua` (no re-parse, no re-download).
  - Added a manual row:     `build.py csv` then `build.py images lua`.

Stages are independent so you never re-parse the huge dump or re-download
899 images just to regenerate the Lua. Stdlib only.
"""

import csv
import json
import os
import sys
import time
import urllib.request

import config as cfg


# ======================================================================= #
#  shared helpers                                                         #
# ======================================================================= #

CSV_COLS = ["id", "name", "type_line", "power", "toughness",
            "colors", "text", "image", "back", "variants"]


def node_str(obj, *path):
    """Follow dict keys / list indices; '' if missing or null."""
    n = obj
    for p in path:
        if isinstance(p, int):
            if isinstance(n, list) and 0 <= p < len(n):
                n = n[p]
            else:
                return ""
        else:
            if isinstance(n, dict) and p in n:
                n = n[p]
            else:
                return ""
    if n is None:
        return ""
    if isinstance(n, bool):
        return "true" if n else "false"
    return str(n)


def mechanical_key(name, type_line, power, toughness, colors, text):
    return "\u0000".join([name, type_line, power, toughness, colors, text])


def read_csv_rows(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def iter_cards(path):
    """Yield card dicts from a Scryfall dump, whether it's JSON Lines
    (one {...} per line) or a single JSON array (starts with '['). Both
    are streamed so a multi-GB bulk file doesn't have to fit in memory."""
    # Sniff the first non-space character.
    with open(path, encoding="utf-8") as f:
        head = f.read(256)
    first = head.lstrip()[:1]

    if first != "[":
        # JSON Lines.
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip().rstrip(",")
                if line and line not in ("[", "]"):
                    yield json.loads(line)
        return

    # JSON array — stream objects with raw_decode over a sliding buffer.
    dec = json.JSONDecoder()
    with open(path, encoding="utf-8") as f:
        buf = ""
        started = False
        while True:
            chunk = f.read(1 << 20)  # 1 MB
            if chunk:
                buf += chunk
            if not started:
                i = buf.find("[")
                if i == -1:
                    if not chunk:
                        return
                    continue
                buf = buf[i + 1:]
                started = True
            # Parse as many complete objects as the buffer holds.
            while True:
                buf = buf.lstrip().lstrip(",").lstrip()
                if not buf:
                    break
                if buf[0] == "]":
                    return
                try:
                    obj, end = dec.raw_decode(buf)
                except json.JSONDecodeError:
                    break  # incomplete object; need more data
                yield obj
                buf = buf[end:]
            if not chunk:
                return


# ======================================================================= #
#  stage: csv                                                             #
# ======================================================================= #

def make_id(set_code, collector_number):
    if set_code == "plst":
        base = collector_number                       # already "M19-123" style
    elif set_code.startswith("t"):
        base = f"{set_code[1:]}-{collector_number}"    # token set 'tmom' -> 'mom'
    else:
        base = f"{set_code}-{collector_number}"
    return base.lower()


def stage_csv():
    star = "\u2605"
    # mechanical key -> list of printings {id, image, released}
    groups = {}
    # first-seen shared fields per key (name/type/etc. are identical by key)
    fields = {}

    for c in iter_cards(cfg.INPUT_JSONL):
        if node_str(c, "lang") != "en":
            continue
        if node_str(c, "layout") not in cfg.TOKEN_LAYOUTS:
            continue

        type_line = node_str(c, "type_line")
        name = node_str(c, "name")
        keep = any(m in type_line for m in cfg.TYPE_MARKERS) \
            or name in cfg.NAME_ALLOWLIST
        if not keep:
            continue

        # Front face, and (for double-faced tokens) the distinct back face.
        image = node_str(c, "image_uris", "normal") \
            or node_str(c, "card_faces", 0, "image_uris", "normal")
        back = node_str(c, "card_faces", 1, "image_uris", "normal")
        if not image:
            continue

        cn = node_str(c, "collector_number")
        if star in cn:
            continue

        set_code = node_str(c, "set")
        tid = make_id(set_code, cn)
        power = node_str(c, "power")
        toughness = node_str(c, "toughness")
        colors_node = c.get("colors")
        colors = "".join(colors_node) if isinstance(colors_node, list) else ""
        text = node_str(c, "oracle_text").replace("\n", " ")
        released = node_str(c, "released_at")

        key = mechanical_key(name, type_line, power, toughness, colors, text)
        is_sld = set_code.lower() == "sld"
        groups.setdefault(key, []).append(
            {"id": tid, "image": image, "back": back,
             "released": released, "sld": is_sld})
        fields.setdefault(key, {
            "name": name, "type_line": type_line, "power": power,
            "toughness": toughness, "colors": colors, "text": text,
        })

    # Collapse each group into one row: oldest printing (original art) is the
    # primary/default (state 1); up to VARIANT_CAP-1 newest others become
    # variants (states 2+). Primary image downloads to <id>.jpg; each variant
    # to <id>-v<n>.jpg. The CSV stores variant SOURCE urls, pipe-joined.
    var_cap = getattr(cfg, "VARIANT_CAP", 4)
    sld_cap = getattr(cfg, "SLD_CAP", 3)
    seen = {}
    variant_total = 0
    sld_total = 0
    for key, printings in groups.items():
        printings.sort(key=lambda p: p["released"])       # oldest first
        primary = printings[0]                            # original art
        others = printings[1:]
        others.sort(key=lambda p: p["released"], reverse=True)  # newest first
        # Newest non-Secret-Lair, then newest Secret Lair, each capped.
        f = fields[key]
        is_dfc = bool(primary.get("back"))
        if is_dfc:
            # Double-faced token: front + real back face, no printing variants.
            extras = []
        else:
            non_sld = [p for p in others if not p["sld"]][:max(0, var_cap)]
            sld     = [p for p in others if p["sld"]][:max(0, sld_cap)]
            extras = non_sld + sld
            variant_total += len(non_sld)
            sld_total += len(sld)
        seen[key] = {
            "id": primary["id"], "name": f["name"], "type_line": f["type_line"],
            "power": f["power"], "toughness": f["toughness"],
            "colors": f["colors"], "text": f["text"],
            "image": primary["image"],
            "back": primary.get("back", ""),
            "variants": "|".join(e["image"] for e in extras),
            "_released": primary["released"],
        }

    dump_count = len(seen)

    # --- merge manual rows (always win on key collision) -----------------
    manual_count = 0
    overrides = 0
    if os.path.exists(cfg.MANUAL_CSV):
        for r in read_csv_rows(cfg.MANUAL_CSV):
            tid = (r.get("id") or "").strip()
            if not tid:
                continue  # skip blank/comment rows
            name = (r.get("name") or "").strip()
            type_line = (r.get("type_line") or "").strip()
            power = (r.get("power") or "").strip()
            toughness = (r.get("toughness") or "").strip()
            colors = (r.get("colors") or "").strip() or "c"
            text = (r.get("text") or "").strip()
            image = (r.get("image") or "").strip()
            back = (r.get("back") or "").strip()          # optional DFC back
            variants = (r.get("variants") or "").strip()  # optional, pipe-joined
            key = mechanical_key(name, type_line, power, toughness, colors, text)
            if key in seen:
                overrides += 1
            else:
                manual_count += 1
            seen[key] = {
                "id": tid, "name": name, "type_line": type_line,
                "power": power, "toughness": toughness, "colors": colors,
                "text": text, "image": image, "back": back,
                "variants": variants, "_released": "9999-99-99",
            }

    # --- id collision check (image filenames must be unique) -------------
    by_id = {}
    for row in seen.values():
        by_id.setdefault(row["id"], []).append(row["name"])
    dupes = {i: ns for i, ns in by_id.items() if len(ns) > 1}
    if dupes:
        print("  WARNING: duplicate ids (images will collide):")
        for i, ns in list(dupes.items())[:10]:
            print(f"    {i}: {ns}")

    with open(cfg.OUTPUT_CSV, "w", encoding="utf-8", newline="") as f:
        f.write("\ufeff")
        f.write(",".join(CSV_COLS) + "\n")
        w = csv.DictWriter(f, fieldnames=CSV_COLS, extrasaction="ignore",
                           quoting=csv.QUOTE_ALL)
        for row in seen.values():
            w.writerow(row)

    print(f"[csv] {len(seen)} tokens -> {cfg.OUTPUT_CSV}  "
          f"(dump {dump_count}, manual +{manual_count}, overrides {overrides}, "
          f"{variant_total} variants + {sld_total} SLD)")


# ======================================================================= #
#  stage: images                                                          #
# ======================================================================= #

_UA = "Bitterblossom/1.0 (TTS mod image rehost; contact: you@example.com)"


def variant_name(tid, n):
    """Filename stem for the n-th image of a token: n==1 -> <id>,
    n>=2 -> <id>-v<n>. Primary is n==1."""
    return tid if n == 1 else f"{tid}-v{n}"


def stage_images():
    delay, timeout = 0.1, 30
    os.makedirs(cfg.IMAGE_DIR, exist_ok=True)
    rows = read_csv_rows(cfg.OUTPUT_CSV)
    done = skipped = failed = 0
    failures = []

    def fetch(url, dest, label):
        nonlocal done, skipped, failed
        if os.path.exists(dest) and os.path.getsize(dest) > 0:
            skipped += 1
            return
        if not url:
            print(f"[images] {label}: no URL and no file — provide "
                  f"{dest} manually")
            skipped += 1
            return
        try:
            req = urllib.request.Request(url, headers={
                "User-Agent": _UA, "Accept": "image/jpeg,image/*"})
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                data = resp.read()
            if not data or len(data) < 100:
                raise ValueError(f"suspiciously small ({len(data)} bytes)")
            with open(dest, "wb") as out:
                out.write(data)
            done += 1
            if done % 25 == 0:
                print(f"[images] downloaded {done}…")
            time.sleep(delay)
        except Exception as e:
            failed += 1
            failures.append((label, str(e)))
            print(f"[images] {label}: FAILED — {e}")
            time.sleep(delay)

    for r in rows:
        tid = (r["id"] or "").strip()
        # primary (front face)
        fetch((r.get("image") or "").strip(),
              os.path.join(cfg.IMAGE_DIR, f"{tid}.jpg"), tid)
        # back face (double-faced tokens) -> <id>-back.jpg
        back = (r.get("back") or "").strip()
        if back:
            fetch(back, os.path.join(cfg.IMAGE_DIR, f"{tid}-back.jpg"),
                  f"{tid}-back")
        # variants (states 2+), pipe-joined source urls
        vs = (r.get("variants") or "").strip()
        if vs:
            for k, url in enumerate(vs.split("|"), start=2):
                url = url.strip()
                if not url:
                    continue
                fetch(url, os.path.join(cfg.IMAGE_DIR,
                      f"{variant_name(tid, k)}.jpg"), f"{tid}-v{k}")

    print(f"[images] downloaded {done}, skipped {skipped}, failed {failed}")
    if failures:
        print("  failures (re-run to retry just these):")
        for label, err in failures:
            print(f"    {label}: {err}")


# ======================================================================= #
#  stage: lua                                                             #
# ======================================================================= #

def lua_escape(s):
    if s is None:
        s = ""
    s = s.replace("\\", "\\\\").replace('"', '\\"')
    return s.replace("\r", "").replace("\n", "\\n").replace("\t", " ")


LUA_HEADER = '''--[[
  MTG Token Spawner (Bitterblossom) — Object Script, generated by build.py
  ------------------------------------------------------------------------
  Do not hand-edit rows below; regenerate with `python3 build.py lua`.
  Paste this into the object's Lua tab; TokenSpawner.xml into its UI tab.
  Images are rehosted (see BASE_URL in config.py) because TTS's fetcher
  cannot load them from Scryfall directly. `img` is the default face
  (original art); optional `variants` holds extra printing URLs that the
  engine spawns as selectable object States.
]]

------------------------------------------------------------------ config --

local CARD_BACK = "%%CARD_BACK%%"

local PAGE_SIZE = 8
local ROW_H     = 42
local ROW_Y0    = -150
local ROW_STEP  = 44

-------------------------------------------------------------- token data --

local TOKENS = {
'''


def stage_lua():
    with open(cfg.ENGINE_LUA, encoding="utf-8") as f:
        engine = f.read()

    base = cfg.BASE_URL if cfg.BASE_URL.endswith("/") else cfg.BASE_URL + "/"
    if "USER/REPO" in base:
        print("  WARNING: BASE_URL still has placeholder USER/REPO — "
              "edit config.py before publishing.")

    rows = read_csv_rows(cfg.OUTPUT_CSV)
    missing = []
    body = []
    for r in rows:
        tid = (r["id"] or "").strip()
        if not os.path.exists(os.path.join(cfg.IMAGE_DIR, f"{tid}.jpg")):
            missing.append(tid)

        name = lua_escape(r["name"])
        tline = lua_escape(r["type_line"])
        pow_ = (r.get("power") or "").strip()
        tou = (r.get("toughness") or "").strip()
        cols = lua_escape((r.get("colors") or "").strip() or "c")
        text = lua_escape((r.get("text") or "").strip())
        img = lua_escape(base + tid + ".jpg")
        back = (r.get("back") or "").strip()
        back_url = lua_escape(base + tid + "-back.jpg") if back else ""

        parts = [f'id="{lua_escape(tid)}"', f'name="{name}"', f'colors="{cols}"']
        if pow_ != "" and tou != "":
            parts.append(f'pow="{lua_escape(pow_)}"')
            parts.append(f'tou="{lua_escape(tou)}"')
        parts.append(f'types="{tline}"')
        parts.append(f'text="{text}"')
        parts.append(f'img="{img}"')
        if back_url:
            parts.append(f'back="{back_url}"')

        # Variants (states 2+): derive final jsDelivr URLs from id + -v<n>.
        vs = (r.get("variants") or "").strip()
        if vs:
            n_extra = len([u for u in vs.split("|") if u.strip()])
            vurls = [base + f"{tid}-v{k}.jpg" for k in range(2, 2 + n_extra)]
            vlua = ", ".join(f'"{lua_escape(u)}"' for u in vurls)
            parts.append(f"variants={{{vlua}}}")

        body.append("  { " + ", ".join(parts) + " },")

    header = LUA_HEADER.replace(
        "%%CARD_BACK%%", lua_escape(getattr(cfg, "CARD_BACK", "")))
    with open(cfg.OUTPUT_LUA, "w", encoding="utf-8") as f:
        f.write(header + "\n".join(body) + "\n" + engine)

    print(f"[lua] {len(rows)} tokens -> {cfg.OUTPUT_LUA}")
    if missing:
        print(f"  WARNING: {len(missing)} tokens have no image in "
              f"{cfg.IMAGE_DIR}/ (they'll 404 in TTS). Run `build.py images` "
              f"or drop the files. First few: {missing[:8]}")


# ======================================================================= #
#  driver                                                                 #
# ======================================================================= #

STAGES = {"csv": stage_csv, "images": stage_images, "lua": stage_lua}
ORDER = ["csv", "images", "lua"]


def main():
    args = sys.argv[1:] or ["all"]
    if "all" in args:
        args = ORDER
    unknown = [a for a in args if a not in STAGES]
    if unknown:
        sys.exit(f"unknown stage(s): {unknown}. "
                 f"choose from: all, {', '.join(ORDER)}")
    # Run in canonical order regardless of arg order.
    for stage in ORDER:
        if stage in args:
            STAGES[stage]()


if __name__ == "__main__":
    main()
