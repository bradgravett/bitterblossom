"""
Bitterblossom pipeline configuration — the single file you edit.

Point it at your Scryfall dump and your image repo, and curate which
non-token cards get included. build.py reads everything from here.
"""

# --- Files ---------------------------------------------------------------
INPUT_JSONL = "all-cards-20260917211812.jsonl"   # Scryfall bulk dump (JSONL)
OUTPUT_CSV  = "tokens.csv"                       # generated; consumed downstream
MANUAL_CSV  = "manual_tokens.csv"                # hand-maintained extra rows
IMAGE_DIR   = "token_images"                     # downloaded images land here
ENGINE_LUA  = "_engine.lua"                      # UI/search/spawn engine (don't edit)
OUTPUT_LUA  = "TokenSpawner.lua"                 # final mod script

# --- Image rehost (public GitHub repo, served via jsDelivr) --------------
GH_USER   = "bradgravett"
GH_REPO   = "bitterblossom"
GH_BRANCH = "main"
# jsDelivr CDN in front of the public repo. Pin @<commit-sha> instead of
# @main if you ever need to defeat jsDelivr's cache after replacing an image.
BASE_URL = f"https://cdn.jsdelivr.net/gh/{GH_USER}/{GH_REPO}@{GH_BRANCH}/{IMAGE_DIR}/"

# --- What counts as an includable card -----------------------------------
# Layouts considered token-like.
TOKEN_LAYOUTS = {"token", "double_faced_token", "emblem"}

# A dump card is kept if its layout is token-like AND either its type line
# contains a marker below, or its exact name is in NAME_ALLOWLIST.
TYPE_MARKERS = ("Token", "Emblem", "Dungeon", "Cyberman")

# Extra printings kept per token, as selectable object States. State 1 is
# always the OLDEST printing (original art). On top of that:
#   VARIANT_CAP = up to N newest NON-Secret-Lair printings   (default 4)
#   SLD_CAP     = up to N newest Secret Lair printings        (set "sld")
# So a token holds at most 1 + VARIANT_CAP + SLD_CAP images. Set both to 0
# to disable variants entirely (original art only).
VARIANT_CAP = 4
SLD_CAP     = 3

# Non-token helper cards to include by exact name. ADD NEW ONES HERE as
# Wizards introduces them (new monarch-like designations, etc.) — this is
# the "manually add non-token cards" knob; no need to touch build.py.
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
