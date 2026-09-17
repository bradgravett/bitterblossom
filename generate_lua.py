#!/usr/bin/env python3
"""
generate_lua.py — build TokenSpawner.lua with rehosted image URLs.

After you've pushed token_images/ to a public GitHub repo, run this to
produce a TokenSpawner.lua whose img fields point at your rehosted copies
(via jsDelivr by default — a CDN that fronts GitHub and is TTS-friendly).

Usage:
    python3 generate_lua.py all-cards-20260730092617.csv \
        --base-url "https://cdn.jsdelivr.net/gh/USER/REPO@main/token_images/"

The base URL must end with a slash. Each token's image becomes
    <base-url><id>.jpg

Output: TokenSpawner.lua in the current directory.
"""

import csv, io, os, sys, argparse

def lua_escape(s):
    if s is None: s = ""
    s = s.replace("\\", "\\\\").replace('"', '\\"')
    s = s.replace("\r", "").replace("\n", "\\n").replace("\t", " ")
    return s

HEADER = r'''--[[
  MTG Token Spawner — Object Script (static data, paginated)
  ----------------------------------------------------------
  Attach to any object. Paste this into the object's Lua tab; paste the
  companion TokenSpawner.xml into its UI tab.

  Data:
  - TOKENS below is generated from Brad's deduped CSV export. One entry
    per mechanically distinct token. Regenerate via generate_lua.py; do
    not hand-edit rows.
  - Images are rehosted (see img URLs) because TTS's image fetcher could
    not load them directly from Scryfall (Scryfall serves TTS's Unity
    client an unparseable response; browsers are unaffected). TTS caches
    each rehosted image locally on first spawn.

  UI:
  - NO scrollview, NO layout group. PAGE_SIZE rows show at once as
    absolutely-positioned buttons injected directly into #tokenPanel;
    prev/next page through the filtered list. Only placement that renders
    reliably in TTS object UI. Do not reintroduce VerticalScrollView /
    VerticalLayout.
]]

------------------------------------------------------------------ config --

local CARD_BACK = ""     -- "" reuses the face as the back

local PAGE_SIZE = 8
local ROW_H     = 44
local ROW_Y0    = -104
local ROW_STEP  = 48

-------------------------------------------------------------- token data --

local TOKENS = {
'''

# The engine below is identical to the shipped version.
ENGINE = open(os.path.join(os.path.dirname(__file__), "_engine.lua"),
              encoding="utf-8").read() if os.path.exists(
              os.path.join(os.path.dirname(__file__), "_engine.lua")) else None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--base-url", required=True,
                    help="rehost prefix ending in / , e.g. "
                         "https://cdn.jsdelivr.net/gh/USER/REPO@main/token_images/")
    ap.add_argument("--out", default="TokenSpawner.lua")
    args = ap.parse_args()

    base = args.base_url
    if not base.endswith("/"):
        base += "/"

    if ENGINE is None:
        sys.exit("ERROR: _engine.lua not found next to this script.")

    with open(args.csv, encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))

    body = io.StringIO()
    for r in rows:
        tid   = r["id"].strip()
        name  = lua_escape(r["name"])
        tline = lua_escape(r["type_line"])
        pow_  = (r.get("power") or "").strip()
        tou   = (r.get("toughness") or "").strip()
        cols  = lua_escape((r.get("colors") or "").strip() or "c")
        text  = lua_escape((r.get("text") or "").strip())
        img   = lua_escape(base + tid + ".jpg")

        parts = [f'id="{lua_escape(tid)}"', f'name="{name}"', f'colors="{cols}"']
        if pow_ != "" and tou != "":
            parts.append(f'pow="{lua_escape(pow_)}"')
            parts.append(f'tou="{lua_escape(tou)}"')
        parts.append(f'types="{tline}"')
        parts.append(f'text="{text}"')
        parts.append(f'img="{img}"')
        body.write("  { " + ", ".join(parts) + " },\n")

    with open(args.out, "w", encoding="utf-8") as f:
        f.write(HEADER + body.getvalue().rstrip("\n") + "\n" + ENGINE)

    print(f"wrote {args.out} — {len(rows)} tokens, base URL:\n  {base}")

if __name__ == "__main__":
    main()
