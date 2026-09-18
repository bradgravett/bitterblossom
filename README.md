# Bitterblossom pipeline

One config file, one driver. `config.py` holds every setting; `build.py`
runs the stages.

```
python3 build.py all       # csv -> images -> lua  (full rebuild)
python3 build.py csv        # parse dump + merge manual -> tokens.csv
python3 build.py images     # download images by id  -> token_images/
python3 build.py lua        # tokens.csv + rehost URLs -> TokenSpawner.lua
```

Stages are independent, so you never re-parse the huge dump or re-download
899 images just to regenerate the Lua. You can pass several: `build.py images lua`.

## Files

| File                | Role                                             |
|---------------------|--------------------------------------------------|
| `config.py`         | **the file you edit** — paths, repo, allowlist   |
| `build.py`          | the driver (csv / images / lua / all)            |
| `manual_tokens.csv` | hand-maintained extra rows (merged in `csv`)     |
| `_engine.lua`       | UI/search/spawn engine, injected into the Lua    |
| `tokens.csv`        | generated intermediate                            |
| `token_images/`     | downloaded images, named `<id>.jpg`              |
| `TokenSpawner.lua`  | final mod script (paste into the object)         |
| `TokenSpawner.xml`  | mod UI (paste into the object; unchanged)        |

## Adding non-token cards

Two knobs, both outside the code:

1. **Cards in the Scryfall dump** (Plot, Monarch, Foretell, new monarch-like
   designations): add the exact card name to `NAME_ALLOWLIST` in `config.py`,
   then `build.py all`.

2. **Cards not in the dump, or hand-curated overrides**: add a row to
   `manual_tokens.csv` (same 8 columns). For its image, either:
   - put a source URL in the `image` column — `build.py images` fetches it to
     `token_images/<id>.jpg`, or
   - leave `image` blank and drop `token_images/<id>.jpg` in yourself.

   A manual row whose mechanical identity (name + type + P/T + colors + text)
   matches a dump token **replaces** that token — the way to override an image
   or wording. A manual row with new mechanics is simply added. Give every
   manual row a unique, URL-safe `id` (it becomes the image filename).

## First-time setup

1. Edit `config.py`: set `INPUT_JSONL` to your dump, and `GH_USER` / `GH_REPO`
   / `GH_BRANCH` to your public image repo.
2. `python3 build.py csv images` — builds the CSV and downloads images.
3. Create a public GitHub repo, push `token_images/`:
   ```
   cd token_images && git init && git add . \
     && git commit -m "token images" && git branch -M main \
     && git remote add origin https://github.com/USER/REPO.git \
     && git push -u origin main && cd ..
   ```
4. `python3 build.py lua` — writes `TokenSpawner.lua` pointing at jsDelivr.
5. Paste `TokenSpawner.lua` + `TokenSpawner.xml` into the object. Done.

## Updating for a new set

1. Download the fresh Scryfall bulk dump, update `INPUT_JSONL` if the filename
   changed.
2. `python3 build.py all` (downloads only the new ids — images is resumable).
3. `cd token_images && git add . && git commit -m "new set" && git push`
4. Repaste `TokenSpawner.lua`. If you pinned a commit in `BASE_URL`, bump it.

## Notes

- jsDelivr caches aggressively; for a fixed image set that's fine. To force a
  refresh after replacing an image at the same path, pin `@<commit-sha>`
  instead of `@main` in `config.py`'s `BASE_URL`.
- `raw.githubusercontent.com/USER/REPO/BRANCH/token_images/` is a fallback
  base URL if jsDelivr ever misbehaves.
- `build.py lua` warns if any token lacks an image file (would 404 in TTS) or
  if `BASE_URL` still has the `USER/REPO` placeholder.
