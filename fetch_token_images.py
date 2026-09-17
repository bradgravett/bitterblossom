#!/usr/bin/env python3
"""
fetch_token_images.py — download all token images from Scryfall for rehosting.

Run this LOCALLY (it needs internet). It reads the CSV, downloads each image
to ./token_images/<id>.jpg, throttled and resumable.

Usage:
    python3 fetch_token_images.py all-cards-20260730092617.csv

- Resumable: re-running skips files already downloaded (non-empty). A failed
  or interrupted run can just be re-run.
- Throttled to ~10 req/s with a descriptive User-Agent, per Scryfall's API
  guidelines (https://scryfall.com/docs/api). Don't lower the delay.
- ~899 images, a few hundred KB each → ~150 MB, ~2 minutes.

After it finishes, see REHOST_README.md for the git + jsDelivr steps.
"""

import csv
import os
import sys
import time
import urllib.request

OUT_DIR   = "token_images"
DELAY_S   = 0.1          # 100 ms between requests (~10 req/s)
TIMEOUT_S = 30
UA = "MTGTokenSpawner/1.0 (TTS mod image rehost; contact: you@example.com)"


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: python3 fetch_token_images.py <cards.csv>")
    src = sys.argv[1]

    os.makedirs(OUT_DIR, exist_ok=True)

    rows = []
    with open(src, encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))

    total = len(rows)
    done = skipped = failed = 0
    failures = []

    for i, r in enumerate(rows, 1):
        tid = r["id"].strip()
        url = (r.get("image") or "").strip()
        if not url:
            print(f"[{i}/{total}] {tid}: no URL, skipping")
            skipped += 1
            continue

        dest = os.path.join(OUT_DIR, f"{tid}.jpg")
        if os.path.exists(dest) and os.path.getsize(dest) > 0:
            skipped += 1
            continue

        try:
            req = urllib.request.Request(url, headers={
                "User-Agent": UA,
                "Accept": "image/jpeg,image/*",
            })
            with urllib.request.urlopen(req, timeout=TIMEOUT_S) as resp:
                data = resp.read()
            if not data or len(data) < 100:
                raise ValueError(f"suspiciously small ({len(data)} bytes)")
            with open(dest, "wb") as out:
                out.write(data)
            done += 1
            if done % 25 == 0:
                print(f"[{i}/{total}] downloaded {done} so far…")
            time.sleep(DELAY_S)
        except Exception as e:
            failed += 1
            failures.append((tid, url, str(e)))
            print(f"[{i}/{total}] {tid}: FAILED — {e}")
            time.sleep(DELAY_S)

    print("\n" + "=" * 50)
    print(f"downloaded: {done}   skipped(existing/none): {skipped}   failed: {failed}")
    if failures:
        print("\nFailures (re-run to retry, or investigate):")
        for tid, url, err in failures:
            print(f"  {tid}: {err}")
        print("\nRe-running will retry only the failed/missing ones.")
    else:
        print("All images present. Next: REHOST_README.md")


if __name__ == "__main__":
    main()
