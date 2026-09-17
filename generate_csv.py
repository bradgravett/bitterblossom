#!/usr/bin/env python3
"""
generate_csv.py — build the deduped token CSV from a Scryfall bulk-data dump.

Python port of tokens.main.kts. Reads a Scryfall "all cards" JSONL dump,
keeps English tokens / emblems / and a hand-picked set of helper cards,
dedupes by mechanical identity (keeping the newest printing), and writes
the CSV the rest of the Bitterblossom pipeline consumes.

Usage:
    python3 generate_csv.py all-cards-20260730092617.jsonl \
                            all-cards-20260730092617.csv

Input is JSONL (one JSON object per line), as produced by concatenating
Scryfall's bulk "Oracle"/"Default" cards, or the .json bulk file converted
to line-delimited. Stdlib only — no dependencies.
"""

import csv
import json
import sys

# Layouts that are token-like.
TOKEN_LAYOUTS = {"token", "double_faced_token", "emblem"}

# Type lines containing any of these are kept.
TYPE_MARKERS = ("Token", "Emblem", "Dungeon", "Cyberman")

# Named helper cards kept regardless of type line (monarch, city's blessing,
# the various "you get an emblem"-adjacent designations, DFC helper faces).
NAME_ALLOWLIST = {
    "City's Blessing",
    "Energy Reserve",
    "Foretell",
    "On an Adventure",
    "Plot",
    "Radiation",
    "The Monarch",
    "Day // Night",
    "Start Your Engines! // Max Speed",
    "City's Blessing // Elemental",
    "A Mysterious Creature",
    "Manifest",
    "Morph",
}

STAR = "\u2605"  # ★ — marks special/promo collector numbers we skip


def node_str(obj, *path):
    """Follow a path of dict keys / list indices; '' if missing or null."""
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


def make_id(set_code, collector_number):
    """Mirror the Kotlin id logic."""
    if set_code == "plst":
        # PLST collector number already encodes origin set, e.g. "M19-123".
        base = collector_number
    elif set_code.startswith("t"):
        # Token set codes are the base set prefixed with 't' (e.g. tmom -> mom).
        base = f"{set_code[1:]}-{collector_number}"
    else:
        base = f"{set_code}-{collector_number}"
    return base.lower()


def main():
    if len(sys.argv) < 3:
        sys.exit("usage: python3 generate_csv.py <input.jsonl> <output.csv>")
    in_path, out_path = sys.argv[1], sys.argv[2]

    # key (mechanical identity) -> chosen row dict
    seen = {}

    with open(in_path, encoding="utf-8") as f:
        for line in f:
            if not line.strip():
                continue
            c = json.loads(line)

            if node_str(c, "lang") != "en":
                continue

            if node_str(c, "layout") not in TOKEN_LAYOUTS:
                continue

            type_line = node_str(c, "type_line")
            name = node_str(c, "name")

            valid = any(m in type_line for m in TYPE_MARKERS) \
                or name in NAME_ALLOWLIST
            if not valid:
                continue

            image = node_str(c, "image_uris", "normal") \
                or node_str(c, "card_faces", 0, "image_uris", "normal")
            if not image:
                continue

            collector_number = node_str(c, "collector_number")
            if STAR in collector_number:
                continue

            set_code = node_str(c, "set")
            tid = make_id(set_code, collector_number)

            power = node_str(c, "power")
            toughness = node_str(c, "toughness")
            colors_node = c.get("colors")
            colors = "".join(colors_node) if isinstance(colors_node, list) else ""
            oracle_text = node_str(c, "oracle_text").replace("\n", " ")
            released = node_str(c, "released_at")

            key = "\u0000".join(
                [name, type_line, power, toughness, colors, oracle_text]
            )

            row = {
                "id": tid,
                "name": name,
                "type_line": type_line,
                "power": power,
                "toughness": toughness,
                "colors": colors,
                "text": oracle_text,
                "image": image,
                "_released": released,
            }

            existing = seen.get(key)
            # Keep the newest printing for a given mechanical identity.
            if existing is None or released > existing["_released"]:
                seen[key] = row

    cols = ["id", "name", "type_line", "power", "toughness",
            "colors", "text", "image"]
    with open(out_path, "w", encoding="utf-8", newline="") as f:
        f.write("\ufeff")            # BOM, matching the Kotlin output
        f.write(",".join(cols) + "\n")  # bare header, matching the Kotlin output
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore",
                           quoting=csv.QUOTE_ALL)
        for row in seen.values():
            w.writerow(row)

    print(f"wrote {len(seen)} tokens", file=sys.stderr)


if __name__ == "__main__":
    main()
