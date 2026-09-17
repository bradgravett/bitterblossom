--[[
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
  { id="soc-6", name="Spirit", colors="W", pow="1", tou="1", types="Token Creature — Spirit", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-6.jpg" },
  { id="otj-7", name="Bird", colors="U", pow="1", tou="1", types="Token Creature — Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-7.jpg" },
  { id="vow-11", name="Wolf", colors="R", pow="3", tou="2", types="Token Creature — Wolf", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/vow-11.jpg" },
  { id="hob-4", name="Goblin Army Token", colors="B", pow="0", tou="0", types="Token Creature — Goblin Army", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hob-4.jpg" },
  { id="msc-1", name="Copy", colors="c", types="Token", text="(This token can be used to represent a token that's a copy of a permanent.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-1.jpg" },
  { id="msh-12", name="Insect", colors="G", pow="1", tou="1", types="Token Creature — Insect", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-12.jpg" },
  { id="fin-26", name="Hero", colors="c", pow="1", tou="1", types="Token Creature — Hero", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-26.jpg" },
  { id="soc-18", name="Saproling", colors="G", pow="1", tou="1", types="Token Creature — Saproling", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-18.jpg" },
  { id="msc-13", name="Rhino", colors="G", pow="4", tou="4", types="Token Creature — Rhino", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-13.jpg" },
  { id="blb-10", name="Bat", colors="B", pow="1", tou="1", types="Token Creature — Bat", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-10.jpg" },
  { id="otj-12", name="Elemental", colors="G", pow="*", tou="*", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-12.jpg" },
  { id="big-3", name="Construct", colors="c", pow="0", tou="0", types="Token Artifact Creature — Construct", text="This creature gets +1/+1 for each artifact you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/big-3.jpg" },
  { id="msh-17", name="Clue", colors="c", types="Token Artifact — Clue", text="{2}, Sacrifice this token: Draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-17.jpg" },
  { id="pca-12", name="Hellion", colors="R", pow="4", tou="4", types="Token Creature — Hellion", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pca-12.jpg" },
  { id="otj-17", name="Meteorite", colors="c", types="Token Artifact", text="When Meteorite enters the battlefield, it deals 2 damage to any target. {T}: Add one mana of any color.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-17.jpg" },
  { id="eoe-1", name="Sliver", colors="c", pow="1", tou="1", types="Token Creature — Sliver", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoe-1.jpg" },
  { id="blc-26", name="Cat", colors="G", pow="2", tou="2", types="Token Creature — Cat", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-26.jpg" },
  { id="fdn-9", name="Faerie", colors="U", pow="1", tou="1", types="Token Creature — Faerie", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-9.jpg" },
  { id="soc-30", name="Manifest", colors="c", pow="2", tou="2", types="Creature", text="(You can cover a face-down manifested creature with this reminder card. A manifested creature card can be turned face up any time for its mana cost. A face-down card can also be turned face up for its morph cost.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-30.jpg" },
  { id="sld-2549", name="Food", colors="c", types="Token Artifact — Food", text="{2}, {T}, Sacrifice this token: You gain 3 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-2549.jpg" },
  { id="tla-8", name="Ally", colors="W", pow="1", tou="1", types="Token Creature — Ally", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tla-8.jpg" },
  { id="msc-16", name="The Monarch", colors="c", types="Card", text="At the beginning of your end step, draw a card. Whenever a creature deals combat damage to you, its controller becomes the monarch.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-16.jpg" },
  { id="med-g4", name="Elspeth, Knight-Errant Emblem", colors="c", types="Emblem — Elspeth", text="Artifacts, creatures, enchantments, and lands you control have indestructible.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/med-g4.jpg" },
  { id="ecl-5", name="Faerie", colors="BU", pow="1", tou="1", types="Token Creature — Faerie", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-5.jpg" },
  { id="tdc-25", name="Spider", colors="G", pow="1", tou="2", types="Token Creature — Spider", text="Reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-25.jpg" },
  { id="inr-24", name="Chandra, Dressed to Kill Emblem", colors="c", types="Emblem", text="Whenever you cast a red spell, this emblem deals X damage to any target, where X is the amount of mana spent to cast that spell.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-24.jpg" },
  { id="soc-16", name="Frog Lizard", colors="G", pow="3", tou="3", types="Token Creature — Frog Lizard", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-16.jpg" },
  { id="tsr-7", name="Giant", colors="R", pow="4", tou="4", types="Token Creature — Giant", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsr-7.jpg" },
  { id="scd-7", name="Pegasus", colors="W", pow="1", tou="1", types="Token Creature — Pegasus", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/scd-7.jpg" },
  { id="cmm-32", name="Elf Druid", colors="G", pow="1", tou="1", types="Token Creature — Elf Druid", text="{T}: Add {G}.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-32.jpg" },
  { id="blb-11", name="Darkstar Augur", colors="B", pow="1", tou="1", types="Token Creature — Bat Warlock", text="Flying At the beginning of your upkeep, reveal the top card of your library and put that card into your hand. You lose life equal to its mana value. (This token's mana cost is {2}{B}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-11.jpg" },
  { id="msc-11", name="Beast", colors="G", pow="3", tou="3", types="Token Creature — Beast", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-11.jpg" },
  { id="fdn-31", name="Phyrexian Goblin", colors="R", pow="1", tou="1", types="Token Creature — Phyrexian Goblin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-31.jpg" },
  { id="twoc-11", name="Faerie Rogue", colors="B", pow="1", tou="1", types="Token Creature — Faerie Rogue", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/twoc-11.jpg" },
  { id="cmm-78", name="Chandra, Awakened Inferno Emblem", colors="c", types="Emblem", text="At the beginning of your upkeep, this emblem deals 1 damage to you.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-78.jpg" },
  { id="fic-4", name="Bird", colors="U", pow="1", tou="1", types="Token Creature — Bird", text="Flying, vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fic-4.jpg" },
  { id="sld-7170", name="Elf Warrior", colors="G", pow="1", tou="1", types="Token Creature — Elf Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-7170.jpg" },
  { id="mkm-5", name="Skeleton", colors="B", pow="2", tou="1", types="Token Creature — Skeleton", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkm-5.jpg" },
  { id="tmc-1", name="Ooze", colors="G", pow="2", tou="2", types="Token Creature — Ooze", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmc-1.jpg" },
  { id="pip-8", name="Settlement", colors="G", types="Token Enchantment — Aura", text="Enchant Land Enchanted land has \"{T}: Add one mana of any color.\"", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pip-8.jpg" },
  { id="neo-14", name="Mechtitan", colors="BGRUW", pow="10", tou="10", types="Token Legendary Artifact Creature — Construct", text="Mechtitan is all colors. Flying, vigilance, trample, lifelink, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-14.jpg" },
  { id="tdc-14", name="Dragon", colors="R", pow="5", tou="5", types="Token Creature — Dragon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-14.jpg" },
  { id="scd-27", name="Sarkhan, the Dragonspeaker Emblem", colors="c", types="Emblem — Sarkhan", text="At the beginning of your draw step, draw two additional cards. At the beginning of your end step, discard your hand.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/scd-27.jpg" },
  { id="inr-18", name="Wolf", colors="G", pow="2", tou="2", types="Token Creature — Wolf", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-18.jpg" },
  { id="tmt-6", name="Rat", colors="B", pow="1", tou="1", types="Token Creature — Rat", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmt-6.jpg" },
  { id="msc-12", name="Elephant", colors="G", pow="3", tou="3", types="Token Creature — Elephant", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-12.jpg" },
  { id="fin-24", name="Sephiroth, One-Winged Angel Emblem", colors="c", types="Emblem", text="Whenever a creature dies, target opponent loses 1 life and you gain 1 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-24.jpg" },
  { id="msc-6", name="Goat", colors="W", pow="0", tou="1", types="Token Creature — Goat", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-6.jpg" },
  { id="pl25-2", name="Snake", colors="G", pow="1", tou="1", types="Token Creature — Snake", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pl25-2.jpg" },
  { id="big-7", name="Map", colors="c", types="Token Artifact — Map", text="{1}, {T}, Sacrifice this artifact: Target creature you control explores. Activate only as a sorcery. (Reveal the top card of your library. Put that card into your hand if it's a land. Otherwise, put a +1/+1 counter on that creature, then put the card back or put it into your graveyard.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/big-7.jpg" },
  { id="c15-23", name="Spirit", colors="BW", pow="*", tou="*", types="Token Enchantment Creature — Spirit", text="This creature's power and toughness are each equal to the number of experience counters you have.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c15-23.jpg" },
  { id="grn-7", name="Ral, Izzet Viceroy Emblem", colors="c", types="Emblem — Ral", text="Whenever you cast an instant or sorcery spell, this emblem deals 4 damage to any target and you draw two cards.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/grn-7.jpg" },
  { id="ecc-3", name="Zombie", colors="B", pow="2", tou="2", types="Token Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecc-3.jpg" },
  { id="tuma-11", name="Soldier", colors="R", pow="1", tou="1", types="Token Creature — Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tuma-11.jpg" },
  { id="txln-1", name="Vampire", colors="W", pow="1", tou="1", types="Token Creature — Vampire", text="Lifelink (Damage dealt by this creature also causes you to gain that much life.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/txln-1.jpg" },
  { id="otc-4", name="Bird Illusion", colors="U", pow="1", tou="1", types="Token Creature — Bird Illusion", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otc-4.jpg" },
  { id="dsc-22", name="Insect", colors="BG", pow="1", tou="1", types="Token Creature — Insect", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-22.jpg" },
  { id="tdm-11", name="Dragon", colors="R", pow="4", tou="4", types="Token Creature — Dragon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-11.jpg" },
  { id="bfz-5", name="Knight Ally", colors="W", pow="2", tou="2", types="Token Creature — Knight Ally", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bfz-5.jpg" },
  { id="msc-2", name="Shapeshifter", colors="c", pow="3", tou="2", types="Token Creature — Shapeshifter", text="Changeling (This token is every creature type.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-2.jpg" },
  { id="fin-35", name="Wizard", colors="B", pow="0", tou="1", types="Token Creature — Wizard", text="Whenever you cast a noncreature spell, this token deals 1 damage to each opponent.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-35.jpg" },
  { id="ecc-10", name="Elemental", colors="GW", pow="*", tou="*", types="Token Creature — Elemental", text="This creature's power and toughness are each equal to the number of creatures you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecc-10.jpg" },
  { id="m3c-24", name="Construct", colors="c", pow="6", tou="12", types="Token Artifact Creature — Construct", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-24.jpg" },
  { id="sld-1908", name="Shapeshifter", colors="U", pow="2", tou="2", types="Token Creature — Shapeshifter", text="Changeling (This token is every creature type.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-1908.jpg" },
  { id="fdn-28", name="Cat Beast", colors="W", pow="2", tou="2", types="Token Creature — Cat Beast", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-28.jpg" },
  { id="sos-5", name="Fractal", colors="GU", pow="0", tou="0", types="Token Creature — Fractal", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sos-5.jpg" },
  { id="acr-7", name="The Capitoline Triad Emblem", colors="c", types="Emblem", text="Creatures you control have base power and toughness 9/9.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/acr-7.jpg" },
  { id="hob-12", name="Treasure", colors="c", types="Token Artifact — Treasure", text="{T}, Sacrifice this token: Add one mana of any color.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hob-12.jpg" },
  { id="tdc-16", name="Elemental", colors="R", pow="1", tou="1", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-16.jpg" },
  { id="f17-10", name="Vampire // Treasure", colors="c", types="Token Creature — Vampire // Token Artifact — Treasure", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/f17-10.jpg" },
  { id="acr-3", name="Human Rogue", colors="W", pow="1", tou="1", types="Token Creature — Human Rogue", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/acr-3.jpg" },
  { id="dmr-3", name="Cat", colors="B", pow="2", tou="1", types="Token Creature — Cat", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmr-3.jpg" },
  { id="mkc-13", name="Lightning Rager", colors="R", pow="5", tou="1", types="Token Creature — Elemental", text="Trample, haste At the beginning of the end step, sacrifice this creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkc-13.jpg" },
  { id="wwk-1", name="Soldier Ally", colors="W", pow="1", tou="1", types="Token Creature — Soldier Ally", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/wwk-1.jpg" },
  { id="msc-21", name="Bird", colors="W", pow="1", tou="1", types="Token Creature — Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-21.jpg" },
  { id="msh-4", name="Soldier", colors="W", pow="1", tou="1", types="Token Creature — Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-4.jpg" },
  { id="khc-2", name="Kithkin Soldier", colors="W", pow="1", tou="1", types="Token Creature — Kithkin Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/khc-2.jpg" },
  { id="sld-2421", name="Goblin", colors="R", pow="1", tou="1", types="Token Creature — Goblin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-2421.jpg" },
  { id="tmh3-2", name="Eldrazi Spawn", colors="c", pow="0", tou="1", types="Token Creature — Eldrazi Spawn", text="Sacrifice this creature: Add {C}.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmh3-2.jpg" },
  { id="msc-9", name="Rogue", colors="B", pow="2", tou="2", types="Token Creature — Rogue", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-9.jpg" },
  { id="40k-13", name="Cherubael", colors="B", pow="4", tou="4", types="Token Legendary Creature — Demon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-13.jpg" },
  { id="mma-1", name="Giant Warrior", colors="W", pow="5", tou="5", types="Token Creature — Giant Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mma-1.jpg" },
  { id="tdc-5", name="Human", colors="W", pow="1", tou="1", types="Token Creature — Human", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-5.jpg" },
  { id="eoc-6", name="Beast", colors="G", pow="4", tou="4", types="Token Creature — Beast", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-6.jpg" },
  { id="cmm-63", name="Human Warrior", colors="W", pow="1", tou="1", types="Token Creature — Human Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-63.jpg" },
  { id="fdn-8", name="Drake", colors="U", pow="2", tou="2", types="Token Creature — Drake", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-8.jpg" },
  { id="soc-25", name="Spirit", colors="RW", pow="3", tou="2", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-25.jpg" },
  { id="dmu-17", name="Cat Warrior", colors="G", pow="2", tou="2", types="Token Creature — Cat Warrior", text="Forestwalk", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-17.jpg" },
  { id="sld-2180", name="Blood", colors="c", types="Token Artifact — Blood", text="{1}, {T}, Discard a card, Sacrifice this token: Draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-2180.jpg" },
  { id="woe-3", name="Knight", colors="W", pow="2", tou="2", types="Token Creature — Knight", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/woe-3.jpg" },
  { id="soc-26", name="Worm", colors="BG", pow="1", tou="1", types="Token Creature — Worm", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-26.jpg" },
  { id="cmm-38", name="Graveborn", colors="BR", pow="3", tou="1", types="Token Creature — Graveborn", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-38.jpg" },
  { id="akh-14", name="Unwavering Initiate", colors="W", pow="3", tou="2", types="Token Creature — Zombie Human Warrior", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-14.jpg" },
  { id="m3c-14", name="Ape", colors="G", pow="3", tou="3", types="Token Creature — Ape", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-14.jpg" },
  { id="sld-1852", name="Spirit", colors="c", pow="1", tou="1", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-1852.jpg" },
  { id="tmt-10", name="Robot", colors="c", pow="1", tou="1", types="Token Artifact Creature — Robot", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmt-10.jpg" },
  { id="scd-12", name="Demon", colors="B", pow="*", tou="*", types="Token Creature — Demon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/scd-12.jpg" },
  { id="bro-4", name="Construct", colors="c", pow="2", tou="2", types="Token Artifact Creature — Construct", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bro-4.jpg" },
  { id="pip-22", name="Radiation", colors="c", types="Card", text="At the beginning of your precombat main phase, if you have any rad counters, mill that many cards. For each nonland card milled this way, you lose 1 life and a rad counter.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pip-22.jpg" },
  { id="dsc-2", name="Angel", colors="W", pow="4", tou="4", types="Token Creature — Angel", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-2.jpg" },
  { id="tdc-11", name="Timeless Witness", colors="B", pow="4", tou="4", types="Token Creature — Zombie Human Shaman", text="When Timeless Witness enters the battlefield, return target card from your graveyard to your hand.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-11.jpg" },
  { id="msc-30", name="Construct", colors="c", pow="4", tou="4", types="Token Artifact Creature — Construct", text="Flying, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-30.jpg" },
  { id="moc-41", name="Replicated Ring", colors="c", types="Token Snow Artifact", text="{T}: Add one mana of any color.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-41.jpg" },
  { id="bbd-4", name="Zombie Giant", colors="B", pow="5", tou="5", types="Token Creature — Zombie Giant", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bbd-4.jpg" },
  { id="inr-27", name="Wrenn and Seven Emblem", colors="c", types="Emblem", text="You have no maximum hand size.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-27.jpg" },
  { id="30a-16", name="Wasp", colors="c", pow="1", tou="1", types="Token Artifact Creature — Insect", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/30a-16.jpg" },
  { id="eoc-3", name="Bird", colors="U", pow="2", tou="2", types="Token Creature — Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-3.jpg" },
  { id="bro-2", name="Bear", colors="G", pow="2", tou="2", types="Token Creature — Bear", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bro-2.jpg" },
  { id="cmm-62", name="Cleric", colors="W", pow="2", tou="1", types="Token Enchantment Creature — Cleric", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-62.jpg" },
  { id="otj-5", name="Spirit", colors="W", pow="2", tou="2", types="Token Creature — Spirit", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-5.jpg" },
  { id="bng-3", name="Soldier", colors="W", pow="1", tou="1", types="Token Enchantment Creature — Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bng-3.jpg" },
  { id="tmkc-12", name="Kobolds of Kher Keep", colors="R", pow="0", tou="1", types="Token Creature — Kobold", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmkc-12.jpg" },
  { id="cm2-13", name="Pentavite", colors="c", pow="1", tou="1", types="Token Artifact Creature — Pentavite", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cm2-13.jpg" },
  { id="mom-23", name="Wrenn and Realmbreaker Emblem", colors="c", types="Emblem", text="You may play lands and cast permanent spells from your graveyard.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mom-23.jpg" },
  { id="m3c-27", name="Garruk, Apex Predator Emblem", colors="c", types="Emblem — Garruk", text="Whenever a creature attacks you, it gets +5/+5 and gains trample until end of turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-27.jpg" },
  { id="tori-7", name="Ashaya, the Awoken World", colors="G", pow="4", tou="4", types="Token Legendary Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tori-7.jpg" },
  { id="eoc-7", name="Elemental", colors="G", pow="5", tou="3", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-7.jpg" },
  { id="2xm-28", name="Tuktuk the Returned", colors="c", pow="5", tou="5", types="Token Artifact Creature — Goblin Golem", text="Tuktuk the Returned is legendary.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/2xm-28.jpg" },
  { id="tla-13", name="Ballistic Boulder", colors="c", pow="2", tou="1", types="Token Artifact Creature — Construct", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tla-13.jpg" },
  { id="msh-14", name="Squirrel", colors="G", pow="1", tou="1", types="Token Creature — Squirrel", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-14.jpg" },
  { id="moc-21", name="Zombie Knight", colors="B", pow="2", tou="2", types="Token Creature — Zombie Knight", text="Menace (This creature can't be blocked except by two or more creatures.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-21.jpg" },
  { id="soc-28", name="Thopter", colors="c", pow="1", tou="1", types="Token Artifact Creature — Thopter", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-28.jpg" },
  { id="arb-3", name="Dragon", colors="GR", pow="1", tou="1", types="Token Creature — Dragon", text="Flying, devour 2", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/arb-3.jpg" },
  { id="drc-12", name="Construct", colors="c", pow="4", tou="4", types="Token Artifact Creature — Construct", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-12.jpg" },
  { id="shm-9", name="Elemental", colors="BR", pow="5", tou="5", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/shm-9.jpg" },
  { id="tdc-29", name="Gold", colors="c", types="Token Artifact — Gold", text="Sacrifice this token: Add one mana of any color.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-29.jpg" },
  { id="clb-9", name="Boo", colors="R", pow="1", tou="1", types="Token Legendary Creature — Hamster", text="Trample, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-9.jpg" },
  { id="fdn-4", name="Knight", colors="W", pow="3", tou="3", types="Token Creature — Knight", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-4.jpg" },
  { id="m21-16", name="Basri Ket Emblem", colors="c", types="Emblem", text="At the beginning of combat on your turn, create a 1/1 white Soldier creature token, then put a +1/+1 counter on each creature you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m21-16.jpg" },
  { id="lcc-6", name="Vampire", colors="B", pow="1", tou="1", types="Token Creature — Vampire", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lcc-6.jpg" },
  { id="neo-8", name="Goblin Shaman", colors="R", pow="2", tou="2", types="Token Creature — Goblin Shaman", text="Whenever this creature attacks, create a Treasure token.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-8.jpg" },
  { id="ecl-12", name="Oko, Shadowmoor Scion Emblem", colors="c", types="Emblem", text="Creatures you control of the chosen type get +3/+3 and have vigilance and hexproof.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-12.jpg" },
  { id="msc-4", name="Angel", colors="W", pow="4", tou="4", types="Token Creature — Angel", text="Flying, vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-4.jpg" },
  { id="ecc-5", name="Plant", colors="G", pow="0", tou="1", types="Token Creature — Plant", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecc-5.jpg" },
  { id="cmm-51", name="Daretti, Scrap Savant Emblem", colors="c", types="Emblem — Daretti", text="Whenever an artifact is put into your graveyard from the battlefield, return that card to the battlefield at the beginning of the next end step.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-51.jpg" },
  { id="cmm-81", name="Narset of the Ancient Way Emblem", colors="c", types="Emblem", text="Whenever you cast a noncreature spell, this emblem deals 2 damage to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-81.jpg" },
  { id="tdc-12", name="Dragon Egg", colors="R", pow="0", tou="2", types="Token Creature — Dragon Egg", text="Defender When this creature dies, create a 2/2 red Dragon creature token with flying and \"{R}: This creature gets +1/+0 until end of turn.\"", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-12.jpg" },
  { id="inr-13", name="Elemental", colors="R", pow="*", tou="*", types="Token Creature — Elemental", text="Trample This creature's power and toughness are each equal to the number of instant and sorcery cards in your graveyard plus the number of cards with flashback you own in exile.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-13.jpg" },
  { id="uma-13", name="Elemental", colors="G", pow="4", tou="4", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/uma-13.jpg" },
  { id="tdc-13", name="Dragon", colors="R", pow="2", tou="2", types="Token Creature — Dragon", text="Flying {R}: This creature gets +1/+0 until end of turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-13.jpg" },
  { id="cmm-42", name="Construct", colors="c", pow="*", tou="*", types="Token Artifact Creature — Construct", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-42.jpg" },
  { id="neo-11", name="Spirit", colors="G", pow="4", tou="5", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-11.jpg" },
  { id="cmm-74", name="Construct", colors="c", pow="1", tou="1", types="Token Artifact Creature — Construct", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-74.jpg" },
  { id="soc-29", name="City's Blessing", colors="c", types="Card", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-29.jpg" },
  { id="c20-17", name="Goblin Warrior", colors="GR", pow="1", tou="1", types="Token Creature — Goblin Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c20-17.jpg" },
  { id="txln-6", name="Plant", colors="G", pow="0", tou="2", types="Token Creature — Plant", text="Defender (This creature can't attack.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/txln-6.jpg" },
  { id="mid-14", name="Vampire", colors="BR", pow="3", tou="1", types="Token Creature — Vampire", text="Trample, lifelink, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mid-14.jpg" },
  { id="woe-5", name="Faerie", colors="U", pow="1", tou="1", types="Token Creature — Faerie", text="Flying This creature can block only creatures with flying.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/woe-5.jpg" },
  { id="tsr-11", name="Insect", colors="G", pow="6", tou="1", types="Token Creature — Insect", text="Shroud (This creature can't be the target of spells or abilities.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsr-11.jpg" },
  { id="ust-4", name="Faerie Spy", colors="U", pow="1", tou="1", types="Token Creature — Faerie Spy", text="Flying, haste Whenever this creature deals combat damage to a player, draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-4.jpg" },
  { id="mh3-12", name="Moonfolk", colors="U", pow="1", tou="2", types="Token Creature — Moonfolk", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-12.jpg" },
  { id="tle-1", name="Marit Lage", colors="B", pow="20", tou="20", types="Token Legendary Creature — Avatar", text="Flying, indestructible", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tle-1.jpg" },
  { id="m3c-19", name="Forest Dryad", colors="G", pow="1", tou="1", types="Token Land Creature — Forest Dryad", text="(This creature is affected by summoning sickness, and it has \"{T}: Add {G}.\")", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-19.jpg" },
  { id="c19-17", name="Plant", colors="G", pow="1", tou="1", types="Token Creature — Plant", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c19-17.jpg" },
  { id="cmm-26", name="Elemental", colors="R", pow="3", tou="1", types="Token Creature — Elemental", text="Trample, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-26.jpg" },
  { id="tdc-31", name="Servo", colors="c", pow="1", tou="1", types="Token Artifact Creature — Servo", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-31.jpg" },
  { id="m3c-3", name="Eldrazi Scion", colors="c", pow="1", tou="1", types="Token Creature — Eldrazi Scion", text="Sacrifice this creature: Add {C}.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-3.jpg" },
  { id="soc-2", name="Cat", colors="W", pow="2", tou="2", types="Token Creature — Cat", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-2.jpg" },
  { id="ltc-14", name="Dragon", colors="BR", pow="6", tou="6", types="Token Creature — Dragon", text="Flying, menace Whenever this creature deals combat damage to a player, gain control of target artifact that player controls.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ltc-14.jpg" },
  { id="soc-9", name="Phyrexian Germ", colors="B", pow="0", tou="0", types="Token Creature — Phyrexian Germ", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-9.jpg" },
  { id="inr-14", name="Human", colors="R", pow="1", tou="1", types="Token Creature — Human", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-14.jpg" },
  { id="inr-1", name="Eldrazi Horror", colors="c", pow="3", tou="2", types="Token Creature — Eldrazi Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-1.jpg" },
  { id="who-39", name="Human Noble", colors="W", pow="1", tou="1", types="Token Creature — Human Noble", text="Vanishing 3 Prevent all damage that would be dealt to this creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-39.jpg" },
  { id="ncc-32", name="Elemental", colors="RU", pow="5", tou="5", types="Token Creature — Elemental", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ncc-32.jpg" },
  { id="afr-7", name="Spider", colors="B", pow="2", tou="1", types="Token Creature — Spider", text="Menace, reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afr-7.jpg" },
  { id="m3c-23", name="Sand Warrior", colors="GRW", pow="1", tou="1", types="Token Creature — Sand Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-23.jpg" },
  { id="drc-8", name="Zombie Army", colors="B", pow="0", tou="0", types="Token Creature — Zombie Army", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-8.jpg" },
  { id="sld-1752", name="Warrior", colors="W", pow="1", tou="1", types="Token Creature — Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-1752.jpg" },
  { id="cm2-8", name="Elemental Shaman", colors="R", pow="3", tou="1", types="Token Creature — Elemental Shaman", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cm2-8.jpg" },
  { id="ima-4", name="Djinn Monk", colors="U", pow="2", tou="2", types="Token Creature — Djinn Monk", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ima-4.jpg" },
  { id="2x2-4", name="Aven Initiate", colors="W", pow="3", tou="2", types="Token Creature — Zombie Bird Warrior", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/2x2-4.jpg" },
  { id="soc-7", name="Illusion", colors="U", pow="*", tou="*", types="Token Creature — Illusion", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-7.jpg" },
  { id="clb-27", name="Kor Warrior", colors="W", pow="1", tou="1", types="Token Creature — Kor Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-27.jpg" },
  { id="sld-1018", name="Icingdeath, Frost Tongue", colors="W", types="Token Legendary Artifact — Equipment", text="Equipped creature gets +2/+0. Whenever equipped creature attacks, tap target creature defending player controls. Equip {2}", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-1018.jpg" },
  { id="cc2-9", name="Snake // Zombie", colors="c", types="Token Creature — Snake // Token Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cc2-9.jpg" },
  { id="inr-6", name="Demon", colors="B", pow="5", tou="5", types="Token Creature — Demon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-6.jpg" },
  { id="cmm-23", name="Dwarf Berserker", colors="R", pow="2", tou="1", types="Token Creature — Dwarf Berserker", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-23.jpg" },
  { id="mh3-18", name="Phyrexian Wurm", colors="B", pow="2", tou="1", types="Token Artifact Creature — Phyrexian Wurm", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-18.jpg" },
  { id="sld-2206", name="Cordyceps Infected", colors="B", pow="1", tou="1", types="Token Creature — Fungus Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-2206.jpg" },
  { id="tdc-23", name="Insect", colors="G", pow="1", tou="1", types="Token Creature — Insect", text="Flying, deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-23.jpg" },
  { id="neo-4", name="Ninja", colors="U", pow="1", tou="1", types="Token Creature — Ninja", text="This creature can't be blocked.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-4.jpg" },
  { id="dsc-7", name="Devil", colors="R", pow="1", tou="1", types="Token Creature — Devil", text="When this creature dies, it deals 1 damage to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-7.jpg" },
  { id="2x2-23", name="Liliana, the Last Hope Emblem", colors="c", types="Emblem — Liliana", text="At the beginning of your end step, create X 2/2 black Zombie creature tokens, where X is two plus the number of Zombies you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/2x2-23.jpg" },
  { id="c15-21", name="Snake", colors="GU", pow="1", tou="1", types="Token Creature — Snake", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c15-21.jpg" },
  { id="dsc-14", name="Ooze", colors="G", pow="*", tou="*", types="Token Creature — Ooze", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-14.jpg" },
  { id="spm-6", name="Robot", colors="c", pow="1", tou="1", types="Token Artifact Creature — Robot", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/spm-6.jpg" },
  { id="sld-2101", name="Myr", colors="c", pow="1", tou="1", types="Token Artifact Creature — Myr", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-2101.jpg" },
  { id="cmm-65", name="Ox", colors="W", pow="2", tou="4", types="Token Creature — Ox", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-65.jpg" },
  { id="m11-1", name="Avatar", colors="W", pow="*", tou="*", types="Token Creature — Avatar", text="This creature's power and toughness are each equal to your life total.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m11-1.jpg" },
  { id="rvr-20", name="Domri Rade Emblem", colors="c", types="Emblem — Domri", text="Creatures you control have double strike, trample, hexproof, and haste.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rvr-20.jpg" },
  { id="ecl-2", name="Elk", colors="G", pow="3", tou="3", types="Token Creature — Elk", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-2.jpg" },
  { id="uma-1", name="Citizen", colors="W", pow="1", tou="1", types="Token Creature — Citizen", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/uma-1.jpg" },
  { id="ltr-7", name="Smaug", colors="R", pow="6", tou="6", types="Token Legendary Creature — Dragon", text="Flying, haste When this creature dies, create fourteen Treasure tokens.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ltr-7.jpg" },
  { id="dft-2", name="Cat", colors="W", pow="1", tou="1", types="Token Creature — Cat", text="Lifelink (Damage dealt by this creature also causes you to gain that much life.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dft-2.jpg" },
  { id="ecc-2", name="Elemental", colors="W", pow="4", tou="4", types="Token Creature — Elemental", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecc-2.jpg" },
  { id="tgrn-2", name="Soldier", colors="W", pow="1", tou="1", types="Token Creature — Soldier", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tgrn-2.jpg" },
  { id="cmm-80", name="Elspeth, Sun's Champion Emblem", colors="c", types="Emblem — Elspeth", text="Creatures you control get +2/+2 and have flying.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-80.jpg" },
  { id="dsc-18", name="Wurm", colors="G", pow="5", tou="5", types="Token Creature — Wurm", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-18.jpg" },
  { id="znc-5", name="Goblin Rogue", colors="B", pow="1", tou="1", types="Token Creature — Goblin Rogue", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/znc-5.jpg" },
  { id="scd-26", name="Ob Nixilis Reignited Emblem", colors="c", types="Emblem — Nixilis", text="Whenever a player draws a card, you lose 2 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/scd-26.jpg" },
  { id="sld-2819", name="Ooze", colors="G", pow="2", tou="2", types="Token Creature — Ooze", text="When this creature dies, create two 1/1 green Ooze creature tokens.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-2819.jpg" },
  { id="dsc-4", name="Shark", colors="U", pow="*", tou="*", types="Token Creature — Shark", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-4.jpg" },
  { id="blc-14", name="Octopus", colors="U", pow="8", tou="8", types="Token Creature — Octopus", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-14.jpg" },
  { id="acr-4", name="Assassin", colors="B", pow="1", tou="1", types="Token Creature — Assassin", text="Menace (This creature can't be blocked except by two or more creatures.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/acr-4.jpg" },
  { id="dmu-3", name="Knight", colors="W", pow="2", tou="2", types="Token Creature — Knight", text="Protection from red", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-3.jpg" },
  { id="fin-20", name="Darkstar", colors="BW", pow="2", tou="2", types="Token Legendary Creature — Dog", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-20.jpg" },
  { id="tm3c-1", name="Eldrazi", colors="c", pow="10", tou="10", types="Token Creature — Eldrazi", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tm3c-1.jpg" },
  { id="mh3-17", name="Phyrexian Wurm", colors="B", pow="1", tou="2", types="Token Artifact Creature — Phyrexian Wurm", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-17.jpg" },
  { id="ecl-1", name="Shapeshifter", colors="c", pow="1", tou="1", types="Token Creature — Shapeshifter", text="Changeling", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-1.jpg" },
  { id="soc-15", name="Boar", colors="G", pow="2", tou="2", types="Token Creature — Boar", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-15.jpg" },
  { id="ecc-9", name="Elemental", colors="GR", pow="5", tou="5", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecc-9.jpg" },
  { id="a25-8", name="Skeleton", colors="B", pow="1", tou="1", types="Token Creature — Skeleton", text="{B}: Regenerate this creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/a25-8.jpg" },
  { id="soc-23", name="Pest", colors="BG", pow="1", tou="1", types="Token Creature — Pest", text="When this creature dies, you gain 1 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-23.jpg" },
  { id="akh-22", name="Hippo", colors="G", pow="3", tou="3", types="Token Creature — Hippo", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-22.jpg" },
  { id="dsk-11", name="Gremlin", colors="R", pow="1", tou="1", types="Token Creature — Gremlin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-11.jpg" },
  { id="fdn-20", name="Raccoon", colors="G", pow="3", tou="3", types="Token Creature — Raccoon", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-20.jpg" },
  { id="msh-24", name="Merfolk", colors="U", pow="1", tou="1", types="Token Creature — Merfolk", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-24.jpg" },
  { id="blb-13", name="Rat", colors="B", pow="1", tou="1", types="Token Creature — Rat", text="This creature gets +1/+1 for each other Rat you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-13.jpg" },
  { id="drc-17", name="Energy Reserve", colors="c", types="Card", text="(Place your energy counters in this area.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-17.jpg" },
  { id="m19-15", name="Ajani, Adversary of Tyrants Emblem", colors="c", types="Emblem — Ajani", text="At the beginning of your end step, create three 1/1 white Cat creature tokens with lifelink.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m19-15.jpg" },
  { id="rex-1", name="Dinosaur", colors="G", pow="3", tou="3", types="Token Creature — Dinosaur", text="Trample (This creature can deal excess combat damage to the player or planeswalker it's attacking.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rex-1.jpg" },
  { id="fdn-25", name="Vivien Reid Emblem", colors="c", types="Emblem — Vivien", text="Creatures you control get +2/+2 and have vigilance, trample, and indestructible.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-25.jpg" },
  { id="gk1-3", name="Weird // Goblin", colors="c", types="Token Creature — Weird // Token Creature — Goblin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-3.jpg" },
  { id="cmm-64", name="Kor Ally", colors="W", pow="1", tou="1", types="Token Creature — Kor Ally", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-64.jpg" },
  { id="takh-17", name="Warrior", colors="W", pow="1", tou="1", types="Token Creature — Warrior", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/takh-17.jpg" },
  { id="clb-34", name="Goblin", colors="R", pow="1", tou="1", types="Token Creature — Goblin", text="Creatures you control attack each combat if able.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-34.jpg" },
  { id="tla-12", name="Bear", colors="G", pow="4", tou="4", types="Token Creature — Bear", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tla-12.jpg" },
  { id="clb-31", name="Horror", colors="B", pow="1", tou="1", types="Token Creature — Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-31.jpg" },
  { id="drc-2", name="Vizier of Many Faces", colors="W", pow="0", tou="0", types="Token Creature — Zombie Shapeshifter Cleric", text="You may have Vizier of Many Faces enter the battlefield as a copy of any creature on the battlefield, except has no mana cost, it's white, and it's a Zombie in addition to its other types.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-2.jpg" },
  { id="twoe-7", name="Rat", colors="B", pow="1", tou="1", types="Token Creature — Rat", text="This token can't block.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/twoe-7.jpg" },
  { id="tstx-8", name="Lukka, Wayward Bonder Emblem", colors="c", types="Emblem", text="Whenever a creature enters the battlefield under your control, it deals damage equal to its power to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tstx-8.jpg" },
  { id="tdm-3", name="Monk", colors="W", pow="1", tou="1", types="Token Creature — Monk", text="Prowess", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-3.jpg" },
  { id="eoe-2", name="Human Soldier", colors="W", pow="1", tou="1", types="Token Creature — Human Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoe-2.jpg" },
  { id="lcc-7", name="Ragavan", colors="R", pow="2", tou="1", types="Token Legendary Creature — Monkey", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lcc-7.jpg" },
  { id="2xm-29", name="Wurm", colors="c", pow="3", tou="3", types="Token Artifact Creature — Wurm", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/2xm-29.jpg" },
  { id="mh3-10", name="Fish", colors="U", pow="3", tou="3", types="Token Creature — Fish", text="When this creature dies, create a 6/6 blue Whale creature token with \"When this creature dies, create a 9/9 blue Kraken creature token.\"", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-10.jpg" },
  { id="rvr-13", name="Wurm", colors="G", pow="6", tou="6", types="Token Creature — Wurm", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rvr-13.jpg" },
  { id="one-7", name="Phyrexian Horror", colors="G", pow="*", tou="*", types="Token Creature — Phyrexian Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/one-7.jpg" },
  { id="eoc-13", name="Golem", colors="c", pow="3", tou="3", types="Token Enchantment Artifact Creature — Golem", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-13.jpg" },
  { id="fin-16", name="Bird", colors="G", pow="2", tou="2", types="Token Creature — Bird", text="Whenever a land you control enters, this token gets +1/+0 until end of turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-16.jpg" },
  { id="40k-9", name="Tyranid Gargoyle", colors="U", pow="1", tou="1", types="Token Creature — Tyranid Gargoyle", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-9.jpg" },
  { id="rvr-15", name="Elf Knight", colors="GW", pow="2", tou="2", types="Token Creature — Elf Knight", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rvr-15.jpg" },
  { id="fic-10", name="Foretell", colors="c", types="Card", text="(After you foretell a card, you can place the exiled card here. You may cast it on a later turn for its foretell cost.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fic-10.jpg" },
  { id="fin-34", name="Moogle", colors="W", pow="1", tou="2", types="Token Creature — Moogle", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-34.jpg" },
  { id="eoc-4", name="Insect", colors="B", pow="1", tou="1", types="Token Creature — Insect", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-4.jpg" },
  { id="mkm-13", name="Voja Fenstalker", colors="GW", pow="5", tou="5", types="Token Legendary Creature — Wolf", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkm-13.jpg" },
  { id="40k-18", name="Tyranid", colors="G", pow="5", tou="5", types="Token Creature — Tyranid", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-18.jpg" },
  { id="ltc-13", name="Treefolk", colors="G", pow="*", tou="*", types="Token Creature — Treefolk", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ltc-13.jpg" },
  { id="40k-17", name="Tyranid", colors="G", pow="1", tou="1", types="Token Creature — Tyranid", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-17.jpg" },
  { id="f17-11", name="Dinosaur // Treasure", colors="c", types="Token Creature — Dinosaur // Token Artifact — Treasure", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/f17-11.jpg" },
  { id="soc-21", name="Elemental", colors="RU", pow="1", tou="1", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-21.jpg" },
  { id="blb-4", name="Wall", colors="W", pow="0", tou="4", types="Token Creature — Wall", text="Defender", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-4.jpg" },
  { id="mkm-19", name="Thopter", colors="c", pow="0", tou="0", types="Token Artifact Creature — Thopter", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkm-19.jpg" },
  { id="fdn-5", name="Rabbit", colors="W", pow="1", tou="1", types="Token Creature — Rabbit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-5.jpg" },
  { id="ecc-6", name="Rhino Warrior", colors="G", pow="4", tou="4", types="Token Creature — Rhino Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecc-6.jpg" },
  { id="moc-25", name="Gremlin", colors="R", pow="0", tou="0", types="Token Artifact Creature — Gremlin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-25.jpg" },
  { id="acr-8", name="A Mysterious Creature", colors="c", pow="2", tou="2", types="Creature", text="You can cover a face-down creature with this reminder card. A face-down creature that was cloaked or cast with disguise has ward {2}. (Whenever that creature becomes the target of a spell or ability an opponent controls, counter it unless that player pays {2}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/acr-8.jpg" },
  { id="akh-19", name="Insect", colors="B", pow="1", tou="1", types="Token Creature — Insect", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-19.jpg" },
  { id="dmu-26", name="Jaya, Fiery Negotiator Emblem", colors="c", types="Emblem", text="Whenever you cast a red instant or sorcery spell, copy it twice. You may choose new targets for the copies.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-26.jpg" },
  { id="tdm-14", name="Elephant", colors="G", pow="5", tou="5", types="Token Creature — Elephant", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-14.jpg" },
  { id="m3c-5", name="Spirit", colors="c", pow="2", tou="2", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-5.jpg" },
  { id="cmr-10", name="Horror", colors="c", pow="*", tou="*", types="Token Artifact Creature — Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmr-10.jpg" },
  { id="who-48", name="Alien Salamander", colors="G", pow="2", tou="2", types="Token Creature — Alien Salamander", text="Islandwalk", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-48.jpg" },
  { id="ncc-25", name="Ooze", colors="G", pow="1", tou="1", types="Token Creature — Ooze", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ncc-25.jpg" },
  { id="msc-31", name="Vibranium", colors="c", types="Token Artifact — Vibranium", text="Indestructible {T}: Add {C}. This mana can't be spent to cast a nonartifact spell.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-31.jpg" },
  { id="m15-11", name="Treefolk Warrior", colors="G", pow="*", tou="*", types="Token Creature — Treefolk Warrior", text="This creature's power and toughness are each equal to the number of Forests you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m15-11.jpg" },
  { id="trk-1", name="Human", colors="W", pow="0", tou="1", types="Token Creature — Human", text="Permanents can't phase in.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/trk-1.jpg" },
  { id="soc-17", name="Fungus Beast", colors="G", pow="4", tou="4", types="Token Creature — Fungus Beast", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-17.jpg" },
  { id="mh3-28", name="Spirit", colors="BW", pow="1", tou="1", types="Token Creature — Spirit", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-28.jpg" },
  { id="inr-17", name="Treefolk", colors="G", pow="*", tou="*", types="Token Creature — Treefolk", text="Reach This creature's power and toughness are each equal to the number of lands you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-17.jpg" },
  { id="ths-6", name="Harpy", colors="B", pow="1", tou="1", types="Token Creature — Harpy", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ths-6.jpg" },
  { id="fdn-13", name="Scion of the Deep", colors="U", pow="8", tou="8", types="Token Legendary Creature — Octopus", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-13.jpg" },
  { id="ptdmu-2", name="Angel", colors="W", pow="*", tou="*", types="Token Creature — Angel", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ptdmu-2.jpg" },
  { id="med-g3", name="Construct", colors="c", pow="1", tou="1", types="Token Artifact Creature — Construct", text="Defender", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/med-g3.jpg" },
  { id="cmr-5", name="Thrull", colors="B", pow="0", tou="1", types="Token Creature — Thrull", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmr-5.jpg" },
  { id="tdc-32", name="Soldier", colors="c", pow="1", tou="1", types="Token Artifact Creature — Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-32.jpg" },
  { id="ugl-93", name="Sheep", colors="G", pow="2", tou="2", types="Token Creature — Sheep", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ugl-93.jpg" },
  { id="gk1-11", name="Voja // Saproling", colors="c", types="Token Legendary Creature — Wolf // Token Creature — Saproling", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-11.jpg" },
  { id="brc-9", name="Mishra's Warform", colors="c", pow="4", tou="4", types="Token Artifact Creature — Construct", text="(This token has the abilities and other types of the copied artifact.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/brc-9.jpg" },
  { id="fdn-1", name="Cat", colors="W", pow="1", tou="1", types="Token Creature — Cat", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-1.jpg" },
  { id="hou-9", name="Sunscourge Champion", colors="B", pow="4", tou="4", types="Token Creature — Zombie Human Wizard", text="When Sunscourge Champion enters the battlefield, you gain life equal to its power.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-9.jpg" },
  { id="afr-16", name="Ellywick Tumblestrum Emblem", colors="c", types="Emblem — Ellywick", text="Creatures you control have trample and haste and get +2/+2 for each differently named dungeon you've completed.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afr-16.jpg" },
  { id="tblb-7", name="Fish", colors="U", pow="1", tou="1", types="Token Creature — Fish", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tblb-7.jpg" },
  { id="akh-21", name="Beast", colors="G", pow="4", tou="2", types="Token Creature — Beast", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-21.jpg" },
  { id="m21-13", name="Weird", colors="RU", pow="*", tou="*", types="Token Creature — Weird", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m21-13.jpg" },
  { id="cm2-4", name="Knight", colors="W", pow="2", tou="2", types="Token Creature — Knight", text="First strike", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cm2-4.jpg" },
  { id="ptbro-3", name="Artifact Zombie", colors="c", pow="*", tou="*", types="Token Artifact Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ptbro-3.jpg" },
  { id="tori-13", name="Liliana, Defiant Necromancer Emblem", colors="c", types="Emblem — Liliana", text="Whenever a creature dies, return it to the battlefield under your control at the beginning of the next end step.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tori-13.jpg" },
  { id="soc-22", name="Inkling", colors="BW", pow="2", tou="1", types="Token Creature — Inkling", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-22.jpg" },
  { id="khm-20", name="Kaya the Inexorable Emblem", colors="c", types="Emblem", text="At the beginning of your upkeep, you may cast a legendary spell from your hand, from your graveyard, or from among cards you own in exile without paying its mana cost.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/khm-20.jpg" },
  { id="lci-10", name="Dinosaur", colors="G", pow="3", tou="3", types="Token Creature — Dinosaur", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lci-10.jpg" },
  { id="m14-12", name="Liliana of the Dark Realms Emblem", colors="c", types="Emblem — Liliana", text="Swamps you control have '{T}: Add {B}{B}{B}{B}.'", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m14-12.jpg" },
  { id="mom-11", name="Phyrexian Hydra", colors="GW", pow="3", tou="3", types="Token Creature — Phyrexian Hydra", text="Reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mom-11.jpg" },
  { id="blb-30", name="Ral, Crackling Wit Emblem", colors="c", types="Emblem", text="Instant and sorcery spells you cast have storm.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-30.jpg" },
  { id="eoc-15", name="Incubator // Phyrexian", colors="c", types="Token Artifact — Incubator // Token Artifact Creature — Phyrexian", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-15.jpg" },
  { id="clb-20", name="Undercity // The Initiative", colors="c", types="Dungeon — Undercity", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-20.jpg" },
  { id="tsr-15", name="Metallic Sliver", colors="c", pow="1", tou="1", types="Token Artifact Creature — Sliver", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsr-15.jpg" },
  { id="fic-5", name="Squid", colors="U", pow="1", tou="1", types="Token Creature — Squid", text="Islandwalk (This creature can't be blocked as long as defending player controls an Island.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fic-5.jpg" },
  { id="cmm-60", name="Avacyn", colors="W", pow="8", tou="8", types="Token Legendary Creature — Angel", text="Flying, vigilance, indestructible", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-60.jpg" },
  { id="who-34", name="Alien", colors="W", pow="2", tou="2", types="Token Creature — Alien", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-34.jpg" },
  { id="lcc-5", name="Pirate", colors="B", pow="2", tou="2", types="Token Creature — Pirate", text="Menace (This creature can't be blocked except by two or more creatures.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lcc-5.jpg" },
  { id="tsr-6", name="Spider", colors="B", pow="2", tou="4", types="Token Creature — Spider", text="Reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsr-6.jpg" },
  { id="ust-6", name="Thopter // Thopter", colors="c", types="Token Artifact Creature — Thopter // Token", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-6.jpg" },
  { id="eoc-14", name="Golem", colors="c", pow="9", tou="9", types="Token Artifact Creature — Golem", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-14.jpg" },
  { id="m3c-10", name="Beast", colors="B", pow="3", tou="3", types="Token Creature — Beast", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-10.jpg" },
  { id="tla-11", name="Soldier", colors="R", pow="2", tou="2", types="Token Creature — Soldier", text="Firebending 1 (Whenever this token attacks, add {R}. This mana lasts until end of combat.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tla-11.jpg" },
  { id="drc-9", name="Zombie Warrior", colors="B", pow="4", tou="4", types="Token Creature — Zombie Warrior", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-9.jpg" },
  { id="f18-1", name="Merfolk // Treasure", colors="c", types="Token Creature — Merfolk // Token Artifact — Treasure", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/f18-1.jpg" },
  { id="tm21-3", name="Griffin", colors="W", pow="2", tou="2", types="Token Creature — Griffin", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tm21-3.jpg" },
  { id="dsc-15", name="Phyrexian Beast", colors="G", pow="4", tou="4", types="Token Creature — Phyrexian Beast", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-15.jpg" },
  { id="lci-8", name="Skeleton Pirate", colors="B", pow="2", tou="2", types="Token Creature — Skeleton Pirate", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lci-8.jpg" },
  { id="ecl-7", name="Kithkin", colors="GW", pow="1", tou="1", types="Token Creature — Kithkin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-7.jpg" },
  { id="blb-12", name="Iridescent Vinelasher", colors="B", pow="1", tou="1", types="Token Creature — Lizard Assassin", text="Landfall — Whenever a land you control enters, this creature deals 1 damage to target opponent. (This token's mana cost is {B}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-12.jpg" },
  { id="ltr-5", name="Orc Army", colors="B", pow="0", tou="0", types="Token Creature — Orc Army", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ltr-5.jpg" },
  { id="tmkc-21", name="Tiny", colors="G", pow="2", tou="2", types="Token Legendary Creature — Dog Detective", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmkc-21.jpg" },
  { id="lci-15", name="Vampire Demon", colors="BW", pow="4", tou="3", types="Token Creature — Vampire Demon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lci-15.jpg" },
  { id="m15-12", name="Land Mine", colors="c", types="Token Artifact", text="{R}, Sacrifice this artifact: This artifact deals 2 damage to target attacking creature without flying.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m15-12.jpg" },
  { id="ema-15", name="Goblin Soldier", colors="RW", pow="1", tou="1", types="Token Creature — Goblin Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ema-15.jpg" },
  { id="mkm-10", name="Detective", colors="UW", pow="2", tou="2", types="Token Creature — Detective", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkm-10.jpg" },
  { id="eoc-2", name="Shapeshifter", colors="c", pow="*", tou="*", types="Token Creature — Shapeshifter", text="Changeling (This token is every creature type.) Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-2.jpg" },
  { id="who-37", name="Human", colors="W", pow="1", tou="1", types="Token Creature — Human", text="Doctor spells you cast cost {1} less to cast.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-37.jpg" },
  { id="uma-7", name="Wurm", colors="B", pow="6", tou="6", types="Token Creature — Wurm", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/uma-7.jpg" },
  { id="tdc-8", name="Salamander Warrior", colors="U", pow="4", tou="3", types="Token Creature — Salamander Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-8.jpg" },
  { id="cmm-79", name="Chandra, Torch of Defiance Emblem", colors="c", types="Emblem — Chandra", text="Whenever you cast a spell, this emblem deals 5 damage to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-79.jpg" },
  { id="40k-23", name="Robot", colors="c", pow="4", tou="4", types="Token Artifact Creature — Robot", text="This creature can't block.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-23.jpg" },
  { id="blb-1", name="Flowerfoot Swordmaster", colors="W", pow="1", tou="1", types="Token Creature — Mouse Soldier", text="Valiant — Whenever this creature becomes the target of a spell or ability you control for the first time each turn, Mice you control get +1/+0 until end of turn. (This token's mana cost is {W}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-1.jpg" },
  { id="otj-2", name="Angel", colors="W", pow="3", tou="3", types="Token Creature — Angel", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-2.jpg" },
  { id="lcc-16", name="Sorin, Lord of Innistrad Emblem", colors="c", types="Emblem — Sorin", text="Creatures you control get +1/+0.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lcc-16.jpg" },
  { id="blc-18", name="Storm Crow", colors="U", pow="1", tou="2", types="Token Creature — Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-18.jpg" },
  { id="otj-11", name="Scorpion Dragon", colors="R", pow="4", tou="4", types="Token Creature — Scorpion Dragon", text="Flying, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-11.jpg" },
  { id="rvr-14", name="Beast", colors="GR", pow="4", tou="4", types="Token Creature — Beast", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rvr-14.jpg" },
  { id="lci-13", name="Golem", colors="UW", pow="4", tou="4", types="Token Artifact Creature — Golem", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lci-13.jpg" },
  { id="mom-22", name="Teferi Akosa of Zhalfir Emblem", colors="c", types="Emblem", text="Knights you control get +1/+0 and have ward {1}.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mom-22.jpg" },
  { id="mh3-24", name="Spellgorger Weird", colors="R", pow="2", tou="2", types="Token Creature — Weird", text="Whenever you cast a noncreature spell, put a +1/+1 counter on this creature. (This token's mana cost is {2}{R}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-24.jpg" },
  { id="dsc-19", name="Wurm", colors="G", pow="5", tou="5", types="Token Creature — Wurm", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-19.jpg" },
  { id="who-52", name="Dinosaur", colors="RW", pow="2", tou="2", types="Token Creature — Dinosaur", text="Flying, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-52.jpg" },
  { id="dft-13", name="Chandra, Spark Hunter Emblem", colors="c", types="Emblem", text="Whenever an artifact you control enters, this emblem deals 3 damage to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dft-13.jpg" },
  { id="bro-1", name="Spirit", colors="U", pow="2", tou="2", types="Token Creature — Spirit", text="Vigilance Whenever you draw a card, put a +1/+1 counter on this creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bro-1.jpg" },
  { id="ddt-2", name="Wall", colors="U", pow="5", tou="5", types="Token Creature — Wall", text="Defender", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ddt-2.jpg" },
  { id="ala-2", name="Homunculus", colors="U", pow="0", tou="1", types="Token Artifact Creature — Homunculus", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ala-2.jpg" },
  { id="2x2-24", name="Wrenn and Six Emblem", colors="c", types="Emblem — Wrenn", text="Instant and sorcery cards in your graveyard have retrace. (You may cast instant and sorcery cards from your graveyard by discarding a land card in addition to paying their other costs.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/2x2-24.jpg" },
  { id="eld-9", name="Boar", colors="G", pow="1", tou="1", types="Token Creature — Boar", text="When this creature dies, create a Food token.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eld-9.jpg" },
  { id="dsk-10", name="Horror", colors="B", pow="2", tou="2", types="Token Enchantment Creature — Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-10.jpg" },
  { id="drc-11", name="Beast", colors="c", pow="6", tou="6", types="Token Artifact Creature — Beast", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-11.jpg" },
  { id="fdn-11", name="Koma's Coil", colors="U", pow="3", tou="3", types="Token Creature — Serpent", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-11.jpg" },
  { id="tdc-19", name="Karox Bladewing", colors="R", pow="4", tou="4", types="Token Legendary Creature — Dragon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-19.jpg" },
  { id="znc-4", name="Germ", colors="B", pow="0", tou="0", types="Token Creature — Germ", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/znc-4.jpg" },
  { id="fdn-21", name="Insect", colors="BG", pow="1", tou="1", types="Token Creature — Insect", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-21.jpg" },
  { id="tla-10", name="Monk", colors="R", pow="1", tou="1", types="Token Creature — Monk", text="Prowess (Whenever you cast a noncreature spell, this creature gets +1/+1 until end of turn.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tla-10.jpg" },
  { id="who-56", name="Cyberman", colors="c", pow="2", tou="2", types="Artifact Creature — Cyberman", text="(You can cover a face-down creature that has become a Cyberman with this reminder card. It's a 2/2 Cyberman artifact creature.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-56.jpg" },
  { id="war-17", name="Voja, Friend to Elves", colors="GW", pow="3", tou="3", types="Token Legendary Creature — Wolf", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/war-17.jpg" },
  { id="spm-4", name="Human Citizen", colors="GW", pow="1", tou="1", types="Token Creature — Human Citizen", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/spm-4.jpg" },
  { id="ecl-4", name="Elf", colors="BG", pow="2", tou="2", types="Token Creature — Elf", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-4.jpg" },
  { id="otc-7", name="Assassin", colors="B", pow="1", tou="1", types="Token Creature — Assassin", text="Deathtouch, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otc-7.jpg" },
  { id="who-13", name="Human Rogue", colors="B", pow="2", tou="2", types="Token Creature — Human Rogue", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-13.jpg" },
  { id="f12-1a", name="Human // Wolf", colors="c", types="Token Creature — Human // Token Creature — Wolf", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/f12-1a.jpg" },
  { id="tkhm-21", name="Tibalt, Cosmic Impostor Emblem", colors="c", types="Emblem", text="You may play cards exiled with Tibalt, Cosmic Impostor, and you may spend mana as though it were mana of any color to cast those spells.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tkhm-21.jpg" },
  { id="dmr-12", name="Sheep", colors="G", pow="0", tou="1", types="Token Creature — Sheep", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmr-12.jpg" },
  { id="blb-2", name="Intrepid Rabbit", colors="W", pow="1", tou="1", types="Token Creature — Rabbit Soldier", text="When this creature enters, target creature you control gets +1/+1 until end of turn. (This token's mana cost is {2}{W}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-2.jpg" },
  { id="snc-4", name="Fish", colors="U", pow="1", tou="1", types="Token Creature — Fish", text="This creature can't be blocked.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/snc-4.jpg" },
  { id="who-32", name="Osgood, Operation Double", colors="U", pow="2", tou="2", types="Token Creature — Human Alien Shapeshifter", text="{T}: Add {C}. Spend this mana only to cast an artifact spell or activate an ability of an artifact. Paradox — Whenever you cast a spell from anywhere other than your hand, investigate. (This token's mana cost is {2}{U}{U}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-32.jpg" },
  { id="clb-32", name="Warrior", colors="B", pow="2", tou="1", types="Token Creature — Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-32.jpg" },
  { id="clb-25", name="Angel Warrior", colors="W", pow="4", tou="4", types="Token Creature — Angel Warrior", text="Flying, vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-25.jpg" },
  { id="eld-10", name="Giant", colors="G", pow="7", tou="7", types="Token Creature — Giant", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eld-10.jpg" },
  { id="snc-6", name="Ogre Warrior", colors="B", pow="4", tou="3", types="Token Creature — Ogre Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/snc-6.jpg" },
  { id="med-g7", name="Teferi, Hero of Dominaria Emblem", colors="c", types="Emblem — Teferi", text="Whenever you draw a card, exile target permanent an opponent controls.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/med-g7.jpg" },
  { id="inr-9", name="Wolf", colors="B", pow="1", tou="1", types="Token Creature — Wolf", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-9.jpg" },
  { id="soc-20", name="Elemental", colors="RU", pow="4", tou="4", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-20.jpg" },
  { id="ecl-11", name="Mutavault", colors="c", types="Token Land", text="{T}: Add {C}. {1}: This token becomes a 2/2 creature with all creature types until end of turn. It's still a land.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-11.jpg" },
  { id="cn2-3", name="Soldier", colors="W", pow="1", tou="2", types="Token Creature — Soldier", text="Defender", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cn2-3.jpg" },
  { id="mkc-9", name="Tentacle", colors="U", pow="1", tou="1", types="Token Creature — Tentacle", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkc-9.jpg" },
  { id="khm-17", name="Icy Manalith", colors="c", types="Token Snow Artifact", text="{T}: Add one mana of any color.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/khm-17.jpg" },
  { id="clb-50", name="Will Kenrith Emblem", colors="c", types="Emblem — Will", text="Whenever you cast an instant or sorcery spell, copy it. You may choose new targets for the copy.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-50.jpg" },
  { id="tdc-26", name="Citizen", colors="GW", pow="1", tou="1", types="Token Creature — Citizen", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-26.jpg" },
  { id="soc-11", name="Snake", colors="B", pow="1", tou="1", types="Token Creature — Snake", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-11.jpg" },
  { id="eoe-3", name="Drone", colors="c", pow="1", tou="1", types="Token Artifact Creature — Drone", text="Flying This token can block only creatures with flying.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoe-3.jpg" },
  { id="eoc-12", name="Golem", colors="c", pow="3", tou="3", types="Token Artifact Creature — Golem", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-12.jpg" },
  { id="sos-9", name="Pest", colors="BG", pow="1", tou="1", types="Token Creature — Pest", text="Whenever this token attacks, you gain 1 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sos-9.jpg" },
  { id="drc-14", name="Golem", colors="c", pow="3", tou="3", types="Token Artifact Creature — Golem", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-14.jpg" },
  { id="sld-1835", name="Shrine", colors="c", pow="1", tou="1", types="Token Enchantment Creature — Shrine", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-1835.jpg" },
  { id="ust-3", name="Spirit // Spirit", colors="c", types="Token Creature — Spirit // Token", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-3.jpg" },
  { id="clb-37", name="Pirate", colors="R", pow="1", tou="1", types="Token Creature — Pirate", text="This creature can't block. Creatures you control attack each combat if able.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-37.jpg" },
  { id="msc-3", name="Wall", colors="c", pow="0", tou="3", types="Token Creature — Wall", text="Defender, reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-3.jpg" },
  { id="afc-3", name="Illusion", colors="U", pow="1", tou="1", types="Token Creature — Illusion", text="This creature gets +1/+0 for each other Illusion you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afc-3.jpg" },
  { id="dsk-17", name="Kaito, Bane of Nightmares Emblem", colors="c", types="Emblem", text="Ninjas you control get +1/+1.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-17.jpg" },
  { id="sos-7", name="Inkling", colors="BW", pow="1", tou="1", types="Token Creature — Inkling", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sos-7.jpg" },
  { id="c19-9", name="Assassin", colors="B", pow="1", tou="1", types="Token Creature — Assassin", text="Whenever this creature deals combat damage to a player, that player loses the game.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c19-9.jpg" },
  { id="tdm-15", name="Reliquary Dragon", colors="BGRUW", pow="4", tou="4", types="Token Creature — Dragon", text="This token is all colors. Flying, lifelink When this token enters, it deals 3 damage to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-15.jpg" },
  { id="c18-14", name="Beast", colors="G", pow="5", tou="5", types="Token Creature — Beast", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c18-14.jpg" },
  { id="rna-13", name="Domri, Chaos Bringer Emblem", colors="c", types="Emblem — Domri", text="At the beginning of each end step, create a 4/4 red and green Beast creature token with trample.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rna-13.jpg" },
  { id="bro-7", name="Powerstone", colors="c", types="Token Artifact — Powerstone", text="{T}: Add {C}. This mana can't be spent to cast a nonartifact spell.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bro-7.jpg" },
  { id="acr-5", name="Phobos", colors="R", pow="3", tou="2", types="Token Legendary Creature — Horse", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/acr-5.jpg" },
  { id="soc-13", name="Dragon Illusion", colors="R", pow="*", tou="*", types="Token Creature — Dragon Illusion", text="Flying, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-13.jpg" },
  { id="moc-13", name="Spirit", colors="U", pow="1", tou="1", types="Token Creature — Spirit", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-13.jpg" },
  { id="und-4", name="Dragon", colors="c", pow="4", tou="4", types="Token Creature — Dragon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/und-4.jpg" },
  { id="msh-18", name="Doombot", colors="c", pow="3", tou="3", types="Token Artifact Creature — Robot Villain", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-18.jpg" },
  { id="inr-12", name="Zombie", colors="B", pow="*", tou="*", types="Token Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-12.jpg" },
  { id="tori-12", name="Jace, Telepath Unbound Emblem", colors="c", types="Emblem — Jace", text="Whenever you cast a spell, target opponent puts the top five cards of their library into their graveyard.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tori-12.jpg" },
  { id="blc-38", name="Phyrexian Golem", colors="c", pow="3", tou="3", types="Token Artifact Creature — Phyrexian Golem", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-38.jpg" },
  { id="teld-7", name="Dwarf", colors="R", pow="1", tou="1", types="Token Creature — Dwarf", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/teld-7.jpg" },
  { id="f17-12", name="Pirate // Treasure", colors="c", types="Token Creature — Pirate // Token Artifact — Treasure", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/f17-12.jpg" },
  { id="soc-8", name="Phyrexian Myr", colors="U", pow="2", tou="1", types="Token Artifact Creature — Phyrexian Myr", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-8.jpg" },
  { id="one-13", name="Koth, Fire of Resistance Emblem", colors="c", types="Emblem", text="Whenever a Mountain enters the battlefield under your control, this emblem deals 4 damage to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/one-13.jpg" },
  { id="bro-6", name="Golem", colors="c", pow="*", tou="*", types="Token Artifact Creature — Golem", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bro-6.jpg" },
  { id="dsk-4", name="Glimmer", colors="W", pow="1", tou="1", types="Token Enchantment Creature — Glimmer", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-4.jpg" },
  { id="mkm-7", name="Imp", colors="R", pow="2", tou="2", types="Token Creature — Imp", text="When this creature dies, it deals 2 damage to each opponent.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkm-7.jpg" },
  { id="bot-1", name="Laserbeak", colors="U", pow="2", tou="2", types="Token Legendary Artifact Creature — Robot", text="Flying, hexproof", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bot-1.jpg" },
  { id="2xm-7", name="Myr", colors="U", pow="2", tou="1", types="Token Artifact Creature — Myr", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/2xm-7.jpg" },
  { id="tdmc-8", name="Egg", colors="G", pow="0", tou="1", types="Token Creature — Egg", text="Defender", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdmc-8.jpg" },
  { id="eoe-6", name="Lander", colors="c", types="Token Artifact — Lander", text="{2}, {T}, Sacrifice this token: Search your library for a basic land card, put it onto the battlefield tapped, then shuffle.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoe-6.jpg" },
  { id="tshm-12", name="Elf Warrior", colors="GW", pow="1", tou="1", types="Token Creature — Elf Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tshm-12.jpg" },
  { id="ltc-9", name="Human Knight", colors="R", pow="2", tou="2", types="Token Creature — Human Knight", text="Trample, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ltc-9.jpg" },
  { id="mkc-14", name="Ogre", colors="R", pow="3", tou="3", types="Token Creature — Ogre", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkc-14.jpg" },
  { id="otp-2", name="Human Rogue", colors="RW", pow="1", tou="2", types="Token Creature — Human Rogue", text="Haste When this creature enters the battlefield, it deals 1 damage to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otp-2.jpg" },
  { id="cmm-29", name="Satyr", colors="R", pow="1", tou="1", types="Token Creature — Satyr", text="This creature can't block.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-29.jpg" },
  { id="tsr-3", name="Cloud Sprite", colors="U", pow="1", tou="1", types="Token Creature — Faerie", text="Flying Cloud Sprite can block only creatures with flying.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsr-3.jpg" },
  { id="40k-20", name="Blue Horror", colors="RU", pow="2", tou="2", types="Token Creature — Demon Horror", text="Whenever you cast an instant or sorcery spell, this creature deals 1 damage to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-20.jpg" },
  { id="spm-3", name="Spider", colors="G", pow="2", tou="1", types="Token Creature — Spider", text="Reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/spm-3.jpg" },
  { id="msh-9", name="Villain", colors="B", pow="2", tou="1", types="Token Creature — Villain", text="Menace", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-9.jpg" },
  { id="dtk-8", name="Narset Transcendent Emblem", colors="c", types="Emblem — Narset", text="Your opponents can't cast noncreature spells.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dtk-8.jpg" },
  { id="tori-14", name="Chandra, Roaring Flame Emblem", colors="c", types="Emblem — Chandra", text="At the beginning of your upkeep, this emblem deals 3 damage to you.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tori-14.jpg" },
  { id="c19-1", name="Bird", colors="W", pow="3", tou="4", types="Token Creature — Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c19-1.jpg" },
  { id="unf-9", name="Teddy Bear", colors="c", pow="2", tou="2", types="Token Creature — Teddy Bear", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/unf-9.jpg" },
  { id="sld-152", name="Walker", colors="B", pow="2", tou="2", types="Token Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-152.jpg" },
  { id="ust-7", name="Rogue", colors="B", pow="2", tou="2", types="Token Creature — Rogue", text="Menace", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-7.jpg" },
  { id="dsk-6", name="Spirit", colors="W", pow="3", tou="1", types="Token Creature — Spirit", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-6.jpg" },
  { id="cmm-52", name="Ob Nixilis of the Black Oath Emblem", colors="c", types="Emblem — Nixilis", text="{1}{B}, Sacrifice a creature: You gain X life and draw X cards, where X is the sacrificed creature's power.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-52.jpg" },
  { id="tsr-4", name="Bat", colors="B", pow="1", tou="2", types="Token Creature — Bat", text="Flying {1}{B}, Sacrifice this creature: Return an exiled card named Sengir Nosferatu to the battlefield under its owner's control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsr-4.jpg" },
  { id="ecl-8", name="Merfolk", colors="UW", pow="1", tou="1", types="Token Creature — Merfolk", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-8.jpg" },
  { id="soc-3", name="Contract", colors="W", types="Token Enchantment — Aura", text="Enchant creature Whenever enchanted creature attacks, it gets +2/+0 until end of turn if it's attacking one of your opponents. Otherwise, its controller loses 2 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-3.jpg" },
  { id="unf-7", name="Balloon", colors="R", pow="1", tou="1", types="Token Creature — Balloon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/unf-7.jpg" },
  { id="msh-15", name="The Tiger God", colors="G", pow="4", tou="4", types="Token Legendary Creature — Cat God", text="The Tiger God can't be blocked by more than one creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-15.jpg" },
  { id="dom-6", name="Nightmare Horror", colors="B", pow="*", tou="*", types="Token Creature — Nightmare Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dom-6.jpg" },
  { id="drc-3", name="Zombie", colors="W", pow="1", tou="1", types="Token Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-3.jpg" },
  { id="msc-7", name="Ox", colors="W", pow="2", tou="2", types="Token Creature — Ox", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-7.jpg" },
  { id="cmm-71", name="Wizard", colors="R", pow="1", tou="1", types="Token Creature — Wizard", text="{T}: Add {R}. Spend this mana only to cast a planeswalker spell.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-71.jpg" },
  { id="l16-5", name="Servo // Thopter", colors="c", types="Token Artifact Creature — Servo // Token Artifact Creature — Thopter", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/l16-5.jpg" },
  { id="dmu-15", name="Badger", colors="G", pow="3", tou="3", types="Token Creature — Badger", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-15.jpg" },
  { id="pemn-1z", name="Zombie // Zombie", colors="c", types="Token Creature — Zombie // Token Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pemn-1z.jpg" },
  { id="tmkm-1", name="Dog", colors="W", pow="1", tou="1", types="Token Creature — Dog", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmkm-1.jpg" },
  { id="dsk-12", name="Spider", colors="G", pow="2", tou="2", types="Token Creature — Spider", text="Reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-12.jpg" },
  { id="fin-10", name="Knight", colors="W", pow="2", tou="2", types="Token Creature — Knight", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-10.jpg" },
  { id="tc17-3", name="Rat", colors="B", pow="1", tou="1", types="Token Creature — Rat", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tc17-3.jpg" },
  { id="mom-7", name="Dinosaur", colors="G", pow="*", tou="*", types="Token Creature — Dinosaur", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mom-7.jpg" },
  { id="ncc-18", name="Elemental", colors="R", pow="0", tou="1", types="Token Creature — Elemental", text="At the beginning of your upkeep, sacrifice this creature and return target card named Rekindling Phoenix from your graveyard to the battlefield. It gains haste until end of turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ncc-18.jpg" },
  { id="hou-7", name="Sinuous Striker", colors="B", pow="4", tou="4", types="Token Creature — Zombie Naga Warrior", text="{U}: Sinuous Striker gets +1/-1 until end of turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-7.jpg" },
  { id="mh3-14", name="Whale", colors="U", pow="6", tou="6", types="Token Creature — Whale", text="When this creature dies, create a 9/9 blue Kraken creature token.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-14.jpg" },
  { id="tmt-7", name="Mutant", colors="R", pow="2", tou="2", types="Token Creature — Mutant", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmt-7.jpg" },
  { id="vow-4", name="Spirit Cleric", colors="W", pow="*", tou="*", types="Token Creature — Spirit Cleric", text="This creature's power and toughness are each equal to the number of Spirits you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/vow-4.jpg" },
  { id="mh3-13", name="Thopter", colors="U", pow="1", tou="1", types="Token Artifact Creature — Thopter", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-13.jpg" },
  { id="lrw-4", name="Merfolk Wizard", colors="U", pow="1", tou="1", types="Token Creature — Merfolk Wizard", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lrw-4.jpg" },
  { id="inr-19", name="Human Cleric", colors="BW", pow="1", tou="1", types="Token Creature — Human Cleric", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-19.jpg" },
  { id="blb-8", name="Splash Lasher", colors="U", pow="1", tou="1", types="Token Creature — Frog Wizard", text="When this creature enters, tap up to one target creature and put a stun counter on it. (This token's mana cost is {3}{U}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-8.jpg" },
  { id="khm-22", name="Tyvar Kell Emblem", colors="c", types="Emblem", text="Whenever you cast an Elf spell, it gains haste until end of turn and you draw two cards.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/khm-22.jpg" },
  { id="dtk-4", name="Zombie Horror", colors="B", pow="*", tou="*", types="Token Creature — Zombie Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dtk-4.jpg" },
  { id="blb-15", name="Starscape Cleric", colors="B", pow="1", tou="1", types="Token Creature — Bat Cleric", text="Flying This creature can't block. Whenever you gain life, each opponent loses 1 life. (This token's mana cost is {1}{B}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-15.jpg" },
  { id="cmm-13", name="Zombie", colors="U", pow="*", tou="*", types="Token Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-13.jpg" },
  { id="tsnc-10", name="Dog", colors="G", pow="3", tou="1", types="Token Creature — Dog", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsnc-10.jpg" },
  { id="blb-16", name="Thornplate Intimidator", colors="B", pow="1", tou="1", types="Token Creature — Rat Rogue", text="When this creature enters, target opponent loses 3 life unless they sacrifice a nonland permanent or discard a card. (This token's mana cost is {3}{B}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-16.jpg" },
  { id="40k-14", name="Necron Warrior", colors="B", pow="2", tou="2", types="Token Artifact Creature — Necron Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-14.jpg" },
  { id="mkc-30", name="Morph", colors="c", pow="2", tou="2", types="Creature", text="(You can cover a face-down creature with this reminder card. A card with morph can be turned face up any time for its morph cost.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkc-30.jpg" },
  { id="fin-19", name="Angelo", colors="GW", pow="1", tou="1", types="Token Legendary Creature — Dog", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-19.jpg" },
  { id="pip-2", name="Human Knight", colors="W", pow="2", tou="2", types="Token Creature — Human Knight", text="This creature gets +2/+2 as long as an artifact entered the battlefield under your control this turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pip-2.jpg" },
  { id="sos-13", name="Professor Dellian Fel Emblem", colors="c", types="Emblem", text="Whenever you gain life, target opponent loses that much life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sos-13.jpg" },
  { id="inr-5", name="Human Wizard", colors="U", pow="1", tou="1", types="Token Creature — Human Wizard", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-5.jpg" },
  { id="kld-11", name="Nissa, Vital Force Emblem", colors="c", types="Emblem — Nissa", text="Whenever a land enters the battlefield under your control, you may draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/kld-11.jpg" },
  { id="mkm-8", name="Ooze", colors="G", pow="0", tou="0", types="Token Creature — Ooze", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkm-8.jpg" },
  { id="unf-2", name="Clown Robot", colors="W", pow="1", tou="1", types="Token Artifact Creature — Clown Robot", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/unf-2.jpg" },
  { id="one-9", name="The Hollow Sentinel", colors="c", pow="3", tou="3", types="Token Legendary Artifact Creature — Phyrexian Golem", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/one-9.jpg" },
  { id="dde-1", name="Hornet", colors="c", pow="1", tou="1", types="Token Artifact Creature — Insect", text="Flying, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dde-1.jpg" },
  { id="bfz-14", name="Kiora, Master of the Depths Emblem", colors="c", types="Emblem — Kiora", text="Whenever a creature enters the battlefield under your control, you may have it fight target creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bfz-14.jpg" },
  { id="otj-8", name="Vampire Rogue", colors="B", pow="1", tou="1", types="Token Creature — Vampire Rogue", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-8.jpg" },
  { id="mma-13", name="Treefolk Shaman", colors="G", pow="2", tou="5", types="Token Creature — Treefolk Shaman", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mma-13.jpg" },
  { id="ltc-1", name="Bird", colors="W", pow="3", tou="3", types="Token Creature — Bird", text="Flying Whenever this creature attacks, target attacking creature gains flying until end of turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ltc-1.jpg" },
  { id="war-19", name="Nissa, Who Shakes the World Emblem", colors="c", types="Emblem — Nissa", text="Lands you control have indestructible.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/war-19.jpg" },
  { id="akh-10", name="Sacred Cat", colors="W", pow="1", tou="1", types="Token Creature — Zombie Cat", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-10.jpg" },
  { id="hou-11", name="Snake", colors="G", pow="5", tou="4", types="Token Creature — Snake", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-11.jpg" },
  { id="sos-2", name="Elemental", colors="RU", pow="3", tou="3", types="Token Creature — Elemental", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sos-2.jpg" },
  { id="msh-13", name="Moloid", colors="G", pow="1", tou="1", types="Token Creature — Minion", text="Whenever this token attacks, you may mill a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-13.jpg" },
  { id="tsnc-9", name="Cat", colors="G", pow="2", tou="2", types="Token Creature — Cat", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsnc-9.jpg" },
  { id="sld-1334", name="Hydra", colors="G", pow="0", tou="0", types="Token Creature — Hydra", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sld-1334.jpg" },
  { id="40k-8", name="Sicarian Infiltrator", colors="U", pow="1", tou="2", types="Token Artifact Creature — Human Soldier", text="When Sicarian Infiltrator enters the battlefield, draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-8.jpg" },
  { id="jou-6", name="Snake", colors="BG", pow="1", tou="1", types="Token Enchantment Creature — Snake", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/jou-6.jpg" },
  { id="onc-16", name="Phyrexian Wurm", colors="G", pow="*", tou="*", types="Token Creature — Phyrexian Wurm", text="Trample Toxic 1 (Players dealt combat damage by this creature also get a poison counter.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/onc-16.jpg" },
  { id="c19-2", name="Bird", colors="W", pow="3", tou="3", types="Token Creature — Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c19-2.jpg" },
  { id="moc-18", name="Demon", colors="B", pow="6", tou="6", types="Token Creature — Demon", text="Flying, trample At the beginning of your upkeep, sacrifice another creature. If you can't, this creature deals 6 damage to you.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-18.jpg" },
  { id="cmm-46", name="Stoneforged Blade", colors="c", types="Token Artifact — Equipment", text="Indestructible Equipped creature gets +5/+5 and has double strike. Equip {0}", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-46.jpg" },
  { id="big-1", name="Bat", colors="B", pow="2", tou="1", types="Token Creature — Bat", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/big-1.jpg" },
  { id="ust-9", name="Zombie // Zombie", colors="c", types="Token Creature — Zombie // Token", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-9.jpg" },
  { id="akh-12", name="Temmet, Vizier of Naktamun", colors="W", pow="2", tou="2", types="Token Creature — Zombie Human Cleric", text="Temmet, Vizier of Naktamun is legendary. At the beginning of combat on your turn, target creature token you control gets +1/+1 until end of turn and can't be blocked this turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-12.jpg" },
  { id="onc-15", name="Phyrexian Insect", colors="G", pow="1", tou="1", types="Token Creature — Phyrexian Insect", text="Infect (This creature deals damage to creatures in the form of -1/-1 counters and to players in the form of poison counters.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/onc-15.jpg" },
  { id="clb-49", name="Rowan Kenrith Emblem", colors="c", types="Emblem — Rowan", text="Whenever you activate an ability that isn't a mana ability, copy it. You may choose new targets for the copy.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-49.jpg" },
  { id="cmm-18", name="Thrull", colors="B", pow="1", tou="1", types="Token Creature — Thrull", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-18.jpg" },
  { id="tm21-20", name="Cat", colors="G", pow="1", tou="1", types="Token Creature — Cat", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tm21-20.jpg" },
  { id="soc-5", name="Pegasus", colors="W", pow="2", tou="2", types="Token Creature — Pegasus", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-5.jpg" },
  { id="blb-5", name="Warren Warleader", colors="W", pow="1", tou="1", types="Token Creature — Rabbit Knight", text="Whenever you attack, choose one — • Create a 1/1 white Rabbit creature token that's tapped and attacking. • Attacking creatures you control get +1/+1 until end of turn. (This token's mana cost is {2}{W}{W}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-5.jpg" },
  { id="f18-3", name="Illusion // Saproling", colors="c", types="Token Creature — Illusion // Token Creature — Saproling", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/f18-3.jpg" },
  { id="jou-3", name="Minotaur", colors="R", pow="2", tou="3", types="Token Creature — Minotaur", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/jou-3.jpg" },
  { id="inr-7", name="Vampire", colors="B", pow="1", tou="1", types="Token Creature — Vampire", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-7.jpg" },
  { id="ust-8", name="Vampire // Vampire", colors="c", types="Token Creature — Vampire // Token", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-8.jpg" },
  { id="znc-8", name="Elemental", colors="G", pow="2", tou="2", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/znc-8.jpg" },
  { id="zen-4", name="Illusion", colors="U", pow="2", tou="2", types="Token Creature — Illusion", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/zen-4.jpg" },
  { id="who-4", name="Horse", colors="W", pow="2", tou="2", types="Token Creature — Horse", text="Doctors you control have horsemanship. (They can't be blocked except by creatures with horsemanship.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-4.jpg" },
  { id="khc-6", name="Elemental", colors="G", pow="7", tou="7", types="Token Creature — Elemental", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/khc-6.jpg" },
  { id="dsk-7", name="Toy", colors="W", pow="1", tou="1", types="Token Artifact Creature — Toy", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-7.jpg" },
  { id="nec-6", name="Smoke Blessing", colors="R", types="Token Enchantment — Aura", text="Enchant creature When enchanted creature dies, it deals 1 damage to its controller and you create a Treasure token.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/nec-6.jpg" },
  { id="otj-10", name="Mercenary", colors="R", pow="1", tou="1", types="Token Creature — Mercenary", text="{T}: Target creature you control gets +1/+0 until end of turn. Activate only as a sorcery.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-10.jpg" },
  { id="aer-4", name="Tezzeret the Schemer Emblem", colors="c", types="Emblem — Tezzeret", text="At the beginning of combat on your turn, target artifact you control becomes an artifact creature with base power and toughness 5/5.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/aer-4.jpg" },
  { id="inr-20", name="Human Soldier", colors="GW", pow="1", tou="1", types="Token Creature — Human Soldier", text="Training (Whenever this creature attacks with another creature with greater power, put a +1/+1 counter on this creature.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-20.jpg" },
  { id="m19-2", name="Avatar", colors="W", pow="4", tou="4", types="Token Creature — Avatar", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m19-2.jpg" },
  { id="rvr-10", name="Centaur", colors="G", pow="3", tou="3", types="Token Creature — Centaur", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rvr-10.jpg" },
  { id="inr-8", name="Vampire", colors="B", pow="2", tou="2", types="Token Creature — Vampire", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-8.jpg" },
  { id="thb-8", name="Elemental", colors="R", pow="*", tou="1", types="Token Creature — Elemental", text="Trample, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/thb-8.jpg" },
  { id="who-19", name="Alien Insect", colors="GW", pow="1", tou="1", types="Token Creature — Alien Insect", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-19.jpg" },
  { id="f18-2", name="City's Blessing // Elemental", colors="c", types="Card // Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/f18-2.jpg" },
  { id="ncc-14", name="Champion of Wits", colors="B", pow="4", tou="4", types="Token Creature — Zombie Naga Wizard", text="When Champion of Wits enters the battlefield, you may draw cards equal to its power. If you do, discard two cards.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ncc-14.jpg" },
  { id="ust-13", name="Beast // Beast", colors="c", types="Token Creature — Beast // Token", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-13.jpg" },
  { id="ecl-6", name="Goblin", colors="BR", pow="1", tou="1", types="Token Creature — Goblin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-6.jpg" },
  { id="who-14", name="Alien Warrior", colors="R", pow="2", tou="2", types="Token Creature — Alien Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-14.jpg" },
  { id="blc-35", name="Wolf", colors="BG", pow="2", tou="2", types="Token Creature — Wolf", text="When this creature dies, put a loyalty counter on each Garruk you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-35.jpg" },
  { id="onc-18", name="Golem", colors="c", pow="*", tou="*", types="Token Artifact Creature — Golem", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/onc-18.jpg" },
  { id="mh3-11", name="Kraken", colors="U", pow="9", tou="9", types="Token Creature — Kraken", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-11.jpg" },
  { id="soi-8", name="Ooze", colors="G", pow="3", tou="3", types="Token Creature — Ooze", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soi-8.jpg" },
  { id="und-5", name="Giant Teddy Bear", colors="c", pow="5", tou="5", types="Token Creature — Giant Teddy Bear", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/und-5.jpg" },
  { id="pip-15", name="Junk", colors="c", types="Token Artifact — Junk", text="{T}, Sacrifice this artifact: Exile the top card of your library. You may play that card this turn. Activate only as a sorcery.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pip-15.jpg" },
  { id="soc-12", name="Zombie", colors="B", pow="2", tou="2", types="Token Creature — Zombie", text="Decayed (This creature can't block. When it attacks, sacrifice it at end of combat.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-12.jpg" },
  { id="gk1-4", name="Goblin // Soldier", colors="c", types="Token Creature — Goblin // Token Creature — Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-4.jpg" },
  { id="tmt-9", name="Mutagen", colors="c", types="Token Artifact — Mutagen", text="{1}, {T}, Sacrifice this token: Put a +1/+1 counter on target creature. Activate only as a sorcery.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmt-9.jpg" },
  { id="blb-19", name="Steampath Charger", colors="R", pow="1", tou="1", types="Token Creature — Lizard Warlock", text="When this creature dies, it deals 1 damage to target player. (This token's mana cost is {1}{R}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-19.jpg" },
  { id="who-38", name="Human", colors="W", pow="1", tou="1", types="Token Creature — Human", text="Ward {2} (Whenever this creature becomes the target of a spell or ability an opponent controls, counter it unless that player pays {2}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-38.jpg" },
  { id="afr-5", name="The Atropal", colors="B", pow="4", tou="4", types="Token Legendary Creature — God Horror", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afr-5.jpg" },
  { id="moc-40", name="Phyrexian Horror", colors="c", pow="*", tou="*", types="Token Artifact Creature — Phyrexian Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-40.jpg" },
  { id="cmr-11", name="Rock", colors="c", types="Token Artifact — Equipment", text="Equipped creature has \"{1}, {T}, Sacrifice Rock: This creature deals 2 damage to any target.\" Equip {1}", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmr-11.jpg" },
  { id="clb-13", name="Ox", colors="G", pow="4", tou="4", types="Token Creature — Ox", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-13.jpg" },
  { id="blb-17", name="Coruscation Mage", colors="R", pow="1", tou="1", types="Token Creature — Otter Wizard", text="Whenever you cast a noncreature spell, this creature deals 1 damage to each opponent. (This token's mana cost is {1}{R}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-17.jpg" },
  { id="tm20-1", name="Ajani's Pridemate", colors="W", pow="2", tou="2", types="Token Creature — Cat Soldier", text="Whenever you gain life, put a +1/+1 counter on Ajani's Pridemate.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tm20-1.jpg" },
  { id="who-3", name="Alien Rhino", colors="W", pow="4", tou="4", types="Token Creature — Alien Rhino", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-3.jpg" },
  { id="tdc-17", name="Elemental", colors="R", pow="1", tou="1", types="Token Creature — Elemental", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-17.jpg" },
  { id="40k-19", name="Tyranid Warrior", colors="G", pow="3", tou="3", types="Token Creature — Tyranid Warrior", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-19.jpg" },
  { id="neo-5", name="Rat Rogue", colors="B", pow="1", tou="1", types="Token Creature — Rat Rogue", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-5.jpg" },
  { id="dsk-2", name="Shard", colors="c", types="Token Enchantment — Shard", text="{2}, Sacrifice this enchantment: Scry 1, then draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-2.jpg" },
  { id="ecc-8", name="Snake", colors="G", pow="1", tou="1", types="Token Creature — Snake", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecc-8.jpg" },
  { id="fic-7", name="Rebel", colors="R", pow="2", tou="2", types="Token Creature — Rebel", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fic-7.jpg" },
  { id="afr-13", name="Guenhwyvar", colors="G", pow="4", tou="1", types="Token Legendary Creature — Cat", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afr-13.jpg" },
  { id="dsk-16", name="Everywhere", colors="c", types="Token Land", text="This land is a Plains, Island, Swamp, Mountain, and Forest. ({T}: Add {W}, {U}, {B}, {R}, or {G}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-16.jpg" },
  { id="moc-31", name="Insect", colors="RU", pow="1", tou="1", types="Token Creature — Insect", text="Flying, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-31.jpg" },
  { id="ptbro-2", name="Urzan Automaton", colors="c", pow="*", tou="*", types="Token Creature — Urzan Automaton", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ptbro-2.jpg" },
  { id="akh-11", name="Tah-Crop Skirmisher", colors="W", pow="2", tou="1", types="Token Creature — Zombie Naga Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-11.jpg" },
  { id="mm3-19", name="Soldier", colors="RW", pow="1", tou="1", types="Token Creature — Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mm3-19.jpg" },
  { id="eoc-11", name="Gnome", colors="c", pow="1", tou="1", types="Token Artifact Creature — Gnome", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoc-11.jpg" },
  { id="vow-6", name="Slug", colors="B", pow="1", tou="1", types="Token Creature — Slug", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/vow-6.jpg" },
  { id="c19-7", name="Heart-Piercer Manticore", colors="W", pow="4", tou="3", types="Token Creature — Zombie Manticore", text="When Heart-Piercer Manticore enters the battlefield, you may sacrifice another creature. When you do, Heart-Piercer Manticore deals damage equal to that creature's power to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c19-7.jpg" },
  { id="mh3-15", name="Fanatic of Rhonas", colors="B", pow="4", tou="4", types="Token Creature — Zombie Snake Druid", text="{T}: Add {G}. Ferocious — {T}: Add {G}{G}{G}{G}. Activate only if you control a creature with power 4 or greater.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-15.jpg" },
  { id="clb-6", name="Faerie Dragon", colors="U", pow="1", tou="1", types="Token Creature — Faerie Dragon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-6.jpg" },
  { id="otp-3", name="Human Warrior", colors="RW", pow="3", tou="1", types="Token Creature — Human Warrior", text="Trample, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otp-3.jpg" },
  { id="mm3-17", name="Giant Warrior", colors="GR", pow="4", tou="4", types="Token Creature — Giant Warrior", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mm3-17.jpg" },
  { id="who-18", name="Mutant", colors="G", pow="3", tou="3", types="Token Creature — Mutant", text="Deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-18.jpg" },
  { id="cn2-9", name="Lizard", colors="R", pow="8", tou="8", types="Token Creature — Lizard", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cn2-9.jpg" },
  { id="tdc-18", name="First Mate Ragavan", colors="R", pow="2", tou="1", types="Token Legendary Creature — Monkey Pirate", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-18.jpg" },
  { id="tone-2", name="Samurai", colors="W", pow="2", tou="2", types="Token Creature — Samurai", text="Double strike", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tone-2.jpg" },
  { id="ust-17", name="Elemental // Elemental", colors="c", types="Token Creature — Elemental // Token", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-17.jpg" },
  { id="blc-22", name="Hamster", colors="R", pow="1", tou="1", types="Token Creature — Hamster", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-22.jpg" },
  { id="msh-5", name="Leviathan", colors="U", pow="6", tou="5", types="Token Creature — Leviathan", text="Hexproof (This token can't be the target of spells or abilities your opponents control.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-5.jpg" },
  { id="hou-1", name="Adorned Pouncer", colors="B", pow="4", tou="4", types="Token Creature — Zombie Cat", text="Double strike", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-1.jpg" },
  { id="ltr-h13", name="The Ring // The Ring Tempts You", colors="c", types="Emblem // Card", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ltr-h13.jpg" },
  { id="gk2-6", name="Goblin", colors="R", pow="2", tou="1", types="Token Creature — Goblin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk2-6.jpg" },
  { id="cmr-17", name="Illusion", colors="U", pow="1", tou="1", types="Token Creature — Illusion", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmr-17.jpg" },
  { id="cmm-53", name="Teferi, Temporal Archmage Emblem", colors="c", types="Emblem — Teferi", text="You may activate loyalty abilities of planeswalkers you control on any player's turn any time you could cast an instant.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-53.jpg" },
  { id="akh-7", name="Honored Hydra", colors="W", pow="6", tou="6", types="Token Creature — Zombie Snake Hydra", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-7.jpg" },
  { id="lci-7", name="Fungus", colors="B", pow="1", tou="1", types="Token Creature — Fungus", text="This creature can't block.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lci-7.jpg" },
  { id="dom-4", name="Cleric", colors="B", pow="0", tou="1", types="Token Creature — Cleric", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dom-4.jpg" },
  { id="2x2-19", name="Cat Dragon", colors="BGR", pow="3", tou="3", types="Token Creature — Cat Dragon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/2x2-19.jpg" },
  { id="otj-15", name="Zombie Rogue", colors="BU", pow="2", tou="2", types="Token Creature — Zombie Rogue", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-15.jpg" },
  { id="mkm-11", name="Spider", colors="BG", pow="2", tou="1", types="Token Creature — Spider", text="Menace, reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mkm-11.jpg" },
  { id="akh-8", name="Labyrinth Guardian", colors="W", pow="2", tou="3", types="Token Creature — Zombie Illusion Warrior", text="When Labyrinth Guardian becomes the target of a spell, sacrifice it.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-8.jpg" },
  { id="m3c-20", name="Hydra", colors="G", pow="*", tou="*", types="Token Creature — Hydra", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-20.jpg" },
  { id="pip-16", name="Robot", colors="c", pow="3", tou="3", types="Token Artifact Creature — Robot", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pip-16.jpg" },
  { id="c19-24", name="Sculpture", colors="c", pow="*", tou="*", types="Token Artifact Creature — Sculpture", text="This creature's power and toughness are each equal to the number of Sculptures you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c19-24.jpg" },
  { id="lcc-14", name="Vampire", colors="BW", pow="1", tou="1", types="Token Creature — Vampire", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lcc-14.jpg" },
  { id="ptdmu-1", name="Soldier", colors="W", pow="*", tou="*", types="Token Creature — Human", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ptdmu-1.jpg" },
  { id="rvr-9", name="Goblin", colors="R", pow="2", tou="1", types="Token Creature — Goblin", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rvr-9.jpg" },
  { id="gtc-5", name="Horror", colors="BU", pow="1", tou="1", types="Token Creature — Horror", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gtc-5.jpg" },
  { id="jou-5", name="Spider", colors="G", pow="1", tou="3", types="Token Enchantment Creature — Spider", text="Reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/jou-5.jpg" },
  { id="who-15", name="Mark of the Rani", colors="R", types="Token Enchantment — Aura", text="Enchant creature Enchanted creature gets +2/+2 and is goaded.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-15.jpg" },
  { id="dsc-23", name="Scarecrow", colors="c", pow="4", tou="4", types="Token Artifact Creature — Scarecrow", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-23.jpg" },
  { id="inr-25", name="Jace, Unraveler of Secrets Emblem", colors="c", types="Emblem — Jace", text="Whenever an opponent casts their first spell each turn, counter that spell.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-25.jpg" },
  { id="war-5", name="Wizard", colors="U", pow="2", tou="2", types="Token Creature — Wizard", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/war-5.jpg" },
  { id="afr-18", name="Mordenkainen Emblem", colors="c", types="Emblem — Mordenkainen", text="You have no maximum hand size.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afr-18.jpg" },
  { id="rvr-7", name="Dragon", colors="R", pow="6", tou="6", types="Token Creature — Dragon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rvr-7.jpg" },
  { id="hou-5", name="Proven Combatant", colors="B", pow="4", tou="4", types="Token Creature — Zombie Human Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-5.jpg" },
  { id="blb-21", name="Pawpatch Recruit", colors="G", pow="1", tou="1", types="Token Creature — Rabbit Warrior", text="Trample Whenever a creature you control becomes the target of a spell or ability an opponent controls, put a +1/+1 counter on target creature you control other than that creature. (This token's mana cost is {G}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-21.jpg" },
  { id="mb2-513", name="Essence of Ajani", colors="W", types="Emblem", text="(As this spell resolves, put it into the command zone.) Whenever you cast a spell, you gain 1 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mb2-513.jpg" },
  { id="mh2-12", name="Golem", colors="RW", pow="4", tou="4", types="Token Artifact Creature — Golem", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh2-12.jpg" },
  { id="tdm-5", name="Soldier", colors="W", pow="2", tou="2", types="Token Creature — Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-5.jpg" },
  { id="tdm-13", name="Warrior", colors="R", pow="1", tou="1", types="Token Creature — Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-13.jpg" },
  { id="mh2-2", name="Crab", colors="U", pow="0", tou="3", types="Token Creature — Crab", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh2-2.jpg" },
  { id="clb-18", name="Volo's Journal", colors="c", types="Token Legendary Artifact", text="Hexproof Whenever you cast a creature spell, note one of its creature types that hasn't been noted for this artifact.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-18.jpg" },
  { id="clb-30", name="Wizard", colors="U", pow="1", tou="1", types="Token Creature — Wizard", text="{1}, Sacrifice this creature: Counter target noncreature spell unless its controller pays {1}.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-30.jpg" },
  { id="msc-24", name="Council of Reeds", colors="c", pow="2", tou="2", types="Token Legendary Creature — Human Scientist Hero", text="The \"legend rule\" doesn't apply to creatures you control. At the beginning of combat on your turn, if you've cast a noncreature spell this turn, create a token that's a copy of Council of Reeds. (This token's mana cost is {2}{U}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-24.jpg" },
  { id="blb-9", name="Thundertrap Trainer", colors="U", pow="1", tou="1", types="Token Creature — Otter Wizard", text="When this creature enters, look at the top four cards of your library. You may reveal a noncreature, nonland card from among them and put it into your hand. Put the rest on the bottom of your library in a random order. (This token's mana cost is {1}{U}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-9.jpg" },
  { id="scd-5", name="Cat Bird", colors="W", pow="1", tou="1", types="Token Creature — Cat Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/scd-5.jpg" },
  { id="tdft-14", name="Start Your Engines! // Max Speed", colors="c", types="Card // Card", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdft-14.jpg" },
  { id="med-g8", name="Vraska, Golgari Queen Emblem", colors="c", types="Emblem — Vraska", text="Whenever a creature you control deals combat damage to a player, that player loses the game.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/med-g8.jpg" },
  { id="msh-1", name="Wall", colors="c", pow="0", tou="4", types="Token Creature — Wall", text="Defender", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-1.jpg" },
  { id="ecl-3", name="Treefolk", colors="G", pow="3", tou="4", types="Token Creature — Treefolk", text="Reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecl-3.jpg" },
  { id="clb-46", name="Satyr", colors="GR", pow="2", tou="2", types="Token Creature — Satyr", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-46.jpg" },
  { id="tle-2", name="Soldier", colors="R", pow="2", tou="2", types="Token Creature — Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tle-2.jpg" },
  { id="arb-2", name="Lizard", colors="G", pow="2", tou="2", types="Token Creature — Lizard", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/arb-2.jpg" },
  { id="drc-13", name="Golem", colors="c", pow="3", tou="3", types="Token Artifact Creature — Golem", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-13.jpg" },
  { id="2x2-15", name="Boar", colors="G", pow="3", tou="3", types="Token Creature — Boar", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/2x2-15.jpg" },
  { id="ema-7", name="Carnivore", colors="R", pow="3", tou="1", types="Token Creature — Beast", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ema-7.jpg" },
  { id="woe-6", name="Nightmare", colors="B", pow="1", tou="1", types="Token Creature — Nightmare", text="At the beginning of combat on your turn, if a card was put into exile this turn, put a +1/+1 counter on this creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/woe-6.jpg" },
  { id="rix-5", name="Huatli, Radiant Champion Emblem", colors="c", types="Emblem — Huatli", text="Whenever a creature enters the battlefield under your control, you may draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rix-5.jpg" },
  { id="som-4", name="Insect", colors="G", pow="1", tou="1", types="Token Creature — Insect", text="Infect (This creature deals damage to creatures in the form of -1/-1 counters and to players in the form of poison counters.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/som-4.jpg" },
  { id="dft-1", name="Pilot", colors="c", pow="1", tou="1", types="Token Creature — Pilot", text="This token saddles Mounts and crews Vehicles as though its power were 2 greater.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dft-1.jpg" },
  { id="afr-8", name="Vecna", colors="B", pow="8", tou="8", types="Token Legendary Creature — Zombie God", text="Indestructible", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afr-8.jpg" },
  { id="neo-10", name="Human Monk", colors="G", pow="1", tou="1", types="Token Creature — Human Monk", text="{T}: Add {G}.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-10.jpg" },
  { id="tmt-4", name="Insect Warrior", colors="B", pow="1", tou="1", types="Token Creature — Insect Warrior", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmt-4.jpg" },
  { id="hou-8", name="Steadfast Sentinel", colors="B", pow="4", tou="4", types="Token Creature — Zombie Human Cleric", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-8.jpg" },
  { id="sos-10", name="Spirit", colors="RW", pow="2", tou="2", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/sos-10.jpg" },
  { id="mh1-20", name="Serra the Benevolent Emblem", colors="c", types="Emblem — Serra", text="If you control a creature, damage that would reduce your life total to less than 1 reduces it to 1 instead.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh1-20.jpg" },
  { id="mom-10", name="Knight", colors="UW", pow="2", tou="2", types="Token Creature — Knight", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mom-10.jpg" },
  { id="khm-16", name="Troll Warrior", colors="G", pow="4", tou="4", types="Token Creature — Troll Warrior", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/khm-16.jpg" },
  { id="gk1-2", name="Soldier // Soldier", colors="c", types="Token Creature — Soldier // Token Creature — Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-2.jpg" },
  { id="gk2-4", name="Cleric", colors="BW", pow="1", tou="1", types="Token Creature — Cleric", text="{3}{W}{B}{B}, {T}, Sacrifice this creature: Return a card named Deathpact Angel from your graveyard to the battlefield.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk2-4.jpg" },
  { id="40k-7", name="Zephyrim", colors="W", pow="3", tou="3", types="Token Creature — Human Warrior", text="Flying, vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-7.jpg" },
  { id="blb-24", name="Tender Wildguide", colors="G", pow="1", tou="1", types="Token Creature — Possum Druid", text="{T}: Add one mana of any color. {T}: Put a +1/+1 counter on this creature. (This token's mana cost is {1}{G}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-24.jpg" },
  { id="inr-23", name="Arlinn, Embraced by the Moon Emblem", colors="c", types="Emblem — Arlinn", text="Creatures you control have haste and \"{T}: This creature deals damage equal to its power to any target.\"", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-23.jpg" },
  { id="cmm-8", name="Kor Soldier", colors="W", pow="1", tou="1", types="Token Creature — Kor Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-8.jpg" },
  { id="moc-20", name="Vampire Knight", colors="B", pow="1", tou="1", types="Token Creature — Vampire Knight", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-20.jpg" },
  { id="ddi-2", name="Koth of the Hammer Emblem", colors="c", types="Emblem — Koth", text="Mountains you control have '{T}: This land deals 1 damage to any target.'", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ddi-2.jpg" },
  { id="hou-3", name="Dreamstealer", colors="B", pow="4", tou="4", types="Token Creature — Zombie Human Wizard", text="Menace Whenever Dreamstealer deals combat damage to a player, that player discards that many cards.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-3.jpg" },
  { id="ust-14", name="Saproling // Saproling", colors="c", types="Token Creature — Saproling // Token", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-14.jpg" },
  { id="e01-3", name="Horror", colors="B", pow="3", tou="3", types="Token Creature — Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/e01-3.jpg" },
  { id="dmu-6", name="Bird", colors="B", pow="1", tou="1", types="Token Creature — Bird", text="Flying This creature can't block.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-6.jpg" },
  { id="tdm-9", name="Spirit", colors="W", pow="*", tou="*", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-9.jpg" },
  { id="msh-20", name="Robot Villain", colors="c", pow="2", tou="2", types="Token Artifact Creature — Robot Villain", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-20.jpg" },
  { id="ktk-13", name="Sorin, Solemn Visitor Emblem", colors="c", types="Emblem — Sorin", text="At the beginning of each opponent's upkeep, that player sacrifices a creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ktk-13.jpg" },
  { id="drc-16", name="Nalaar Aetherjet", colors="c", pow="*", tou="*", types="Token Artifact — Vehicle", text="Flying Crew 2 (Tap any number of creatures you control with total power 2 or more: This token becomes an artifact creature until end of turn.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-16.jpg" },
  { id="med-r4", name="Jaya Ballard Emblem", colors="c", types="Emblem — Jaya", text="You may cast instant and sorcery spells from your graveyard. If a spell cast this way would be put into your graveyard, exile it instead.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/med-r4.jpg" },
  { id="who-44", name="Dalek", colors="B", pow="3", tou="3", types="Token Artifact Creature — Dalek", text="Menace", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-44.jpg" },
  { id="msh-16", name="Zabu", colors="G", pow="2", tou="2", types="Token Legendary Creature — Cat", text="Landfall — Whenever a land you control enters, put a +1/+1 counter on Zabu.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-16.jpg" },
  { id="bro-12", name="Saheeli, Filigree Master Emblem", colors="c", types="Emblem", text="Artifact creatures you control get +1/+1. Artifact spells you cast cost {1} less to cast.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bro-12.jpg" },
  { id="lci-5", name="Merfolk", colors="U", pow="1", tou="1", types="Token Creature — Merfolk", text="Hexproof (This creature can't be the target of spells or abilities your opponents control.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lci-5.jpg" },
  { id="msh-7", name="Redwing", colors="U", pow="1", tou="1", types="Token Legendary Creature — Bird Scout", text="Flying Whenever Redwing attacks, surveil 1.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-7.jpg" },
  { id="dsk-8", name="Spirit", colors="U", pow="*", tou="*", types="Token Creature — Spirit", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-8.jpg" },
  { id="znr-1", name="Angel Warrior", colors="W", pow="4", tou="4", types="Token Creature — Angel Warrior", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/znr-1.jpg" },
  { id="blc-20", name="Agate Instigator", colors="R", pow="1", tou="1", types="Token Creature — Lizard Rogue", text="Whenever another creature you control enters, this creature deals 1 damage to each opponent. (This token's mana cost is {1}{R}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-20.jpg" },
  { id="one-6", name="Phyrexian Beast", colors="G", pow="3", tou="3", types="Token Creature — Phyrexian Beast", text="Toxic 1 (Players dealt combat damage by this creature also get a poison counter.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/one-6.jpg" },
  { id="tbng-2", name="Cat Soldier", colors="W", pow="1", tou="1", types="Token Creature — Cat Soldier", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tbng-2.jpg" },
  { id="dft-4", name="Dinosaur Dragon", colors="R", pow="4", tou="4", types="Token Creature — Dinosaur Dragon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dft-4.jpg" },
  { id="40k-12", name="Astartes Warrior", colors="B", pow="2", tou="2", types="Token Creature — Astartes Warrior", text="Menace", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-12.jpg" },
  { id="stx-1", name="Avatar", colors="BR", pow="3", tou="6", types="Token Creature — Avatar", text="Haste Whenever this creature attacks, it deals 3 damage to each opponent.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/stx-1.jpg" },
  { id="msc-32", name="Robot Hero", colors="c", pow="2", tou="1", types="Token Artifact Creature — Robot Hero", text="Flying (This token can't be blocked except by creatures with flying or reach.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-32.jpg" },
  { id="aer-3", name="Etherium Cell", colors="c", types="Token Artifact", text="{T}, Sacrifice this artifact: Add one mana of any color.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/aer-3.jpg" },
  { id="m21-18", name="Liliana, Waker of the Dead Emblem", colors="c", types="Emblem", text="At the beginning of combat on your turn, put target creature card from a graveyard onto the battlefield under your control. It gains haste.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m21-18.jpg" },
  { id="zen-6", name="Vampire", colors="B", pow="*", tou="*", types="Token Creature — Vampire", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/zen-6.jpg" },
  { id="one-11", name="Phyrexian Mite", colors="c", pow="1", tou="1", types="Token Artifact Creature — Phyrexian Mite", text="Toxic 1 (Players dealt combat damage by this creature also get a poison counter.) This creature can't block.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/one-11.jpg" },
  { id="vow-12", name="Boar", colors="G", pow="3", tou="1", types="Token Creature — Boar", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/vow-12.jpg" },
  { id="bng-7", name="Elemental", colors="R", pow="3", tou="1", types="Token Enchantment Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bng-7.jpg" },
  { id="bng-8", name="Centaur", colors="G", pow="3", tou="3", types="Token Enchantment Creature — Centaur", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bng-8.jpg" },
  { id="akh-2", name="Anointer Priest", colors="W", pow="1", tou="3", types="Token Creature — Zombie Human Cleric", text="Whenever a creature token enters the battlefield under your control, you gain 1 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-2.jpg" },
  { id="tmt-3", name="Ninja Turtle Spirit", colors="W", pow="1", tou="1", types="Token Creature — Ninja Turtle Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmt-3.jpg" },
  { id="neo-16", name="Tamiyo's Notebook", colors="c", types="Token Legendary Artifact", text="Spells you cast cost {2} less to cast. {T}: Draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-16.jpg" },
  { id="tdm-8", name="Spirit", colors="W", pow="3", tou="3", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-8.jpg" },
  { id="ecc-11", name="Scarecrow", colors="c", pow="2", tou="2", types="Token Artifact Creature — Scarecrow", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ecc-11.jpg" },
  { id="40k-22", name="Insect", colors="c", pow="1", tou="1", types="Token Artifact Creature — Insect", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-22.jpg" },
  { id="ltc-7", name="Wraith", colors="B", pow="3", tou="3", types="Token Creature — Wraith", text="Menace", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ltc-7.jpg" },
  { id="ust-18", name="Clue // Clue", colors="c", types="Token Artifact — Clue // Token", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-18.jpg" },
  { id="tdc-7", name="Wall", colors="W", pow="1", tou="3", types="Token Creature — Wall", text="Defender", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdc-7.jpg" },
  { id="blc-23", name="Prosperous Bandit", colors="R", pow="1", tou="1", types="Token Creature — Raccoon Rogue", text="First strike Whenever this creature deals combat damage to a player, create that many tapped Treasure tokens. (This token's mana cost is {2}{R}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-23.jpg" },
  { id="und-1", name="Beeble", colors="U", pow="1", tou="1", types="Token Creature — Beeble", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/und-1.jpg" },
  { id="vow-21", name="Day // Night", colors="c", types="Card // Card", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/vow-21.jpg" },
  { id="lcc-11", name="Dinosaur Beast", colors="G", pow="*", tou="*", types="Token Creature — Dinosaur Beast", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lcc-11.jpg" },
  { id="c20-10", name="Elemental", colors="R", pow="3", tou="1", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c20-10.jpg" },
  { id="hob-6", name="Dwarf Token", colors="c", pow="2", tou="2", types="Token Creature — Dwarf", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hob-6.jpg" },
  { id="gk1-1", name="Copy // Horror", colors="c", types="Token // Token Creature — Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-1.jpg" },
  { id="woc-16", name="Faerie Rogue", colors="BU", pow="1", tou="1", types="Token Creature — Faerie Rogue", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/woc-16.jpg" },
  { id="c21-8", name="Horror", colors="B", pow="4", tou="4", types="Token Creature — Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c21-8.jpg" },
  { id="mid-3", name="Bird", colors="U", pow="1", tou="1", types="Token Creature — Bird", text="Flying This creature can block only creatures with flying.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mid-3.jpg" },
  { id="mom-8", name="Phyrexian Saproling", colors="G", pow="1", tou="1", types="Token Creature — Phyrexian Saproling", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mom-8.jpg" },
  { id="xln-2", name="Illusion", colors="U", pow="2", tou="2", types="Token Creature — Illusion", text="When this creature becomes the target of a spell, sacrifice it.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/xln-2.jpg" },
  { id="unf-1", name="Cat", colors="W", pow="2", tou="2", types="Token Creature — Cat", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/unf-1.jpg" },
  { id="eoe-9", name="Munitions", colors="c", types="Token Artifact", text="When this token leaves the battlefield, it deals 2 damage to any target.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoe-9.jpg" },
  { id="drc-1", name="Angel of Sanctions", colors="W", pow="3", tou="4", types="Token Creature — Zombie Angel", text="Flying When Angel of Sanctions enters the battlefield, you may exile target nonland permanent an opponent controls until Angel of Sanctions leaves the battlefield.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-1.jpg" },
  { id="mom-12", name="Phyrexian Hydra", colors="GW", pow="3", tou="3", types="Token Creature — Phyrexian Hydra", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mom-12.jpg" },
  { id="moc-44", name="Teferi's Talent Emblem", colors="c", types="Emblem", text="You may activate loyalty abilities of planeswalkers you control on any player's turn any time you could cast an instant.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-44.jpg" },
  { id="med-r5", name="Tamiyo, the Moon Sage Emblem", colors="c", types="Emblem — Tamiyo", text="You have no maximum hand size. Whenever a card is put into your graveyard from anywhere, you may return it to your hand.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/med-r5.jpg" },
  { id="mom-15", name="Warrior", colors="RW", pow="3", tou="2", types="Token Creature — Warrior", text="Whenever this creature and at least one other creature token attack, put a +1/+1 counter on this creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mom-15.jpg" },
  { id="clb-23", name="Shapeshifter", colors="c", pow="2", tou="2", types="Token Creature — Shapeshifter", text="Changeling", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-23.jpg" },
  { id="dft-12", name="Vehicle", colors="c", pow="3", tou="2", types="Token Artifact — Vehicle", text="Crew 1 (Tap any number of creatures you control with total power 1 or more: This token becomes an artifact creature until end of turn.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dft-12.jpg" },
  { id="khm-6", name="Giant Wizard", colors="U", pow="4", tou="4", types="Token Creature — Giant Wizard", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/khm-6.jpg" },
  { id="neo-7", name="Dragon Spirit", colors="R", pow="5", tou="5", types="Token Creature — Dragon Spirit", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-7.jpg" },
  { id="m20-4", name="Elemental Bird", colors="U", pow="4", tou="4", types="Token Creature — Elemental Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m20-4.jpg" },
  { id="otc-13", name="Dragon Elemental", colors="R", pow="4", tou="4", types="Token Creature — Dragon Elemental", text="Flying Prowess (Whenever you cast a noncreature spell, this creature gets +1/+1 until end of turn.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otc-13.jpg" },
  { id="dmu-22", name="Ornithopter", colors="c", pow="0", tou="2", types="Token Artifact Creature — Thopter", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-22.jpg" },
  { id="2xm-30", name="Wurm", colors="c", pow="3", tou="3", types="Token Artifact Creature — Wurm", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/2xm-30.jpg" },
  { id="ala-10", name="Beast", colors="GRW", pow="8", tou="8", types="Token Creature — Beast", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ala-10.jpg" },
  { id="kld-12", name="Dovin Baan Emblem", colors="c", types="Emblem — Dovin", text="Your opponents can't untap more than two permanents during their untap steps.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/kld-12.jpg" },
  { id="pip-10", name="Soldier", colors="RW", pow="1", tou="1", types="Token Creature — Soldier", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pip-10.jpg" },
  { id="rix-4", name="Golem", colors="c", pow="4", tou="4", types="Token Artifact Creature — Golem", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rix-4.jpg" },
  { id="tmt-5", name="Ninja", colors="B", pow="1", tou="1", types="Token Creature — Ninja", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmt-5.jpg" },
  { id="lci-11", name="Dinosaur Egg", colors="G", pow="0", tou="1", types="Token Creature — Dinosaur Egg", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lci-11.jpg" },
  { id="gk2-1", name="Bird", colors="UW", pow="1", tou="1", types="Token Creature — Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk2-1.jpg" },
  { id="woe-18", name="On an Adventure", colors="c", types="Card", text="After an Adventure resolves, you can place the exiled card here. You may cast the creature from exile.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/woe-18.jpg" },
  { id="akh-4", name="Aven Wind Guide", colors="W", pow="2", tou="3", types="Token Creature — Zombie Bird Warrior", text="Flying, vigilance Creature tokens you control have flying and vigilance.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-4.jpg" },
  { id="mid-17", name="Teferi, Who Slows the Sunset Emblem", colors="c", types="Emblem", text="Untap all permanents you control during each opponent's untap step. You draw a card during each opponent's draw step.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mid-17.jpg" },
  { id="dde-2", name="Minion", colors="B", pow="*", tou="*", types="Token Creature — Minion", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dde-2.jpg" },
  { id="moc-23", name="Feather", colors="R", types="Token Artifact", text="{1}, Sacrifice Feather: Return target Phoenix card from your graveyard to the battlefield tapped.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-23.jpg" },
  { id="bng-6", name="Zombie", colors="B", pow="2", tou="2", types="Token Enchantment Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bng-6.jpg" },
  { id="akh-9", name="Oketra's Attendant", colors="W", pow="3", tou="3", types="Token Creature — Zombie Bird Soldier", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-9.jpg" },
  { id="40k-5", name="Space Marine Devastator", colors="W", pow="3", tou="3", types="Token Creature — Astartes Warrior", text="When Space Marine Devastator enters the battlefield, destroy up to one target artifact or enchantment.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-5.jpg" },
  { id="thb-5", name="Reflection", colors="U", pow="3", tou="2", types="Token Creature — Reflection", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/thb-5.jpg" },
  { id="40k-11", name="Arco-Flagellant", colors="B", pow="3", tou="1", types="Token Creature — Human", text="Arco-Flagellant can't block. Pay 3 life: Arco-Flagellant gains indestructible until end of turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-11.jpg" },
  { id="pip-20", name="Wasteland Survival Guide", colors="c", types="Token Artifact — Equipment", text="Equipped creature gets +1/+1 for each quest counter among permanents you control. Equip {1}", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pip-20.jpg" },
  { id="ddt-1", name="Elemental", colors="U", pow="1", tou="0", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ddt-1.jpg" },
  { id="dmu-25", name="Ajani, Sleeper Agent Emblem", colors="c", types="Emblem", text="Whenever you cast a creature or planeswalker spell, target opponent gets two poison counters.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-25.jpg" },
  { id="fdn-12", name="Ninja", colors="U", pow="2", tou="1", types="Token Creature — Ninja", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-12.jpg" },
  { id="ust-10", name="Brainiac", colors="R", pow="1", tou="1", types="Token Creature — Brainiac", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-10.jpg" },
  { id="fic-8", name="The Blackjack", colors="c", pow="3", tou="3", types="Token Legendary Artifact — Vehicle", text="Flying, crew 2", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fic-8.jpg" },
  { id="c19-22", name="Gargoyle", colors="c", pow="3", tou="4", types="Token Artifact Creature — Gargoyle", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c19-22.jpg" },
  { id="rvr-19", name="Voja", colors="GW", pow="2", tou="2", types="Token Legendary Creature — Wolf", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rvr-19.jpg" },
  { id="msc-26", name="Ape Villain", colors="R", pow="3", tou="3", types="Token Creature — Ape Villain", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msc-26.jpg" },
  { id="gs1-t1", name="Mowu // Mowu", colors="c", types="Token Legendary Creature — Dog // Token Legendary Creature — Dog", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gs1-t1.jpg" },
  { id="uma-12", name="Spark Elemental", colors="R", pow="3", tou="1", types="Token Creature — Elemental", text="Trample, haste At the beginning of the end step, sacrifice Spark Elemental.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/uma-12.jpg" },
  { id="40k-15", name="Plaguebearer of Nurgle", colors="B", pow="1", tou="3", types="Token Creature — Demon", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-15.jpg" },
  { id="c18-4", name="Mask", colors="W", types="Token Enchantment — Aura", text="Enchant permanent Totem armor (If enchanted permanent would be destroyed, instead remove all damage from it and destroy this Aura.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c18-4.jpg" },
  { id="znr-11", name="Goblin Construct", colors="c", pow="0", tou="1", types="Token Artifact Creature — Goblin Construct", text="This creature can't block. At the beginning of your upkeep, this creature deals 1 damage to you.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/znr-11.jpg" },
  { id="bot-2", name="Ravage", colors="B", pow="3", tou="3", types="Token Legendary Artifact Creature — Robot", text="Menace, deathtouch", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bot-2.jpg" },
  { id="p03-7", name="Rukh", colors="R", pow="4", tou="4", types="Token Creature — Rukh", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/p03-7.jpg" },
  { id="m21-17", name="Garruk, Unleashed Emblem", colors="c", types="Emblem", text="At the beginning of your end step, you may search your library for a creature card, put it onto the battlefield, then shuffle your library.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m21-17.jpg" },
  { id="cm2-14", name="Triskelavite", colors="c", pow="1", tou="1", types="Token Artifact Creature — Triskelavite", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cm2-14.jpg" },
  { id="vow-3", name="Spirit", colors="W", pow="4", tou="4", types="Token Creature — Spirit", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/vow-3.jpg" },
  { id="30a-7", name="Skeleton", colors="B", pow="1", tou="1", types="Token Creature — Skeleton", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/30a-7.jpg" },
  { id="rtr-12", name="Elemental", colors="GW", pow="8", tou="8", types="Token Creature — Elemental", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rtr-12.jpg" },
  { id="who-11", name="Alien Angel", colors="B", pow="2", tou="2", types="Token Artifact Creature — Alien Angel", text="First strike, vigilance Whenever an opponent casts a creature spell, this permanent isn't a creature until end of turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/who-11.jpg" },
  { id="q07-t12", name="Goblin // Blood", colors="c", types="Token Creature — Goblin // Token Artifact — Blood", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/q07-t12.jpg" },
  { id="jou-1", name="Sphinx", colors="U", pow="4", tou="4", types="Token Creature — Sphinx", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/jou-1.jpg" },
  { id="arb-1", name="Bird Soldier", colors="W", pow="1", tou="1", types="Token Creature — Bird Soldier", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/arb-1.jpg" },
  { id="war-6", name="Assassin", colors="B", pow="1", tou="1", types="Token Creature — Assassin", text="Deathtouch Whenever this creature deals damage to a planeswalker, destroy that planeswalker.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/war-6.jpg" },
  { id="dsk-5", name="Insect", colors="W", pow="2", tou="1", types="Token Creature — Insect", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-5.jpg" },
  { id="tdm-7", name="Spirit", colors="W", pow="2", tou="2", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-7.jpg" },
  { id="eoe-11", name="Tezzeret, Cruel Captain Emblem", colors="c", types="Emblem", text="At the beginning of combat on your turn, put three +1/+1 counters on target artifact you control. If it's not a creature, it becomes a 0/0 Robot artifact creature.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoe-11.jpg" },
  { id="cmm-68", name="Sliver Army", colors="B", pow="0", tou="0", types="Token Creature — Sliver Army", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-68.jpg" },
  { id="afc-9", name="Dragon Spirit", colors="GR", pow="5", tou="4", types="Token Creature — Dragon Spirit", text="When this creature deals damage, sacrifice it.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afc-9.jpg" },
  { id="drc-15", name="Golem", colors="c", pow="3", tou="3", types="Token Artifact Creature — Golem", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-15.jpg" },
  { id="dmu-8", name="Phyrexian", colors="B", pow="2", tou="2", types="Token Creature — Phyrexian", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-8.jpg" },
  { id="pip-7", name="Zombie Mutant", colors="B", pow="2", tou="2", types="Token Creature — Zombie Mutant", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pip-7.jpg" },
  { id="ths-9", name="Satyr", colors="GR", pow="2", tou="2", types="Token Creature — Satyr", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ths-9.jpg" },
  { id="blb-28", name="Sword", colors="c", types="Token Artifact — Equipment", text="Equipped creature gets +1/+1 Equip {2}", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-28.jpg" },
  { id="dsk-9", name="Demon", colors="B", pow="6", tou="6", types="Token Creature — Demon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-9.jpg" },
  { id="ltc-3", name="Halfling", colors="W", pow="1", tou="1", types="Token Creature — Halfling", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ltc-3.jpg" },
  { id="40k-16", name="Spawn", colors="R", pow="3", tou="3", types="Token Creature — Spawn", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-16.jpg" },
  { id="neo-19", name="Tezzeret, Betrayer of Flesh Emblem", colors="c", types="Emblem", text="Whenever an artifact you control becomes tapped, draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-19.jpg" },
  { id="arb-4", name="Zombie Wizard", colors="BU", pow="1", tou="1", types="Token Creature — Zombie Wizard", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/arb-4.jpg" },
  { id="neo-1", name="Pilot", colors="c", pow="1", tou="1", types="Token Creature — Pilot", text="This creature crews Vehicles as though its power were 2 greater.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-1.jpg" },
  { id="otp-1", name="Human Cleric", colors="RW", pow="2", tou="1", types="Token Creature — Human Cleric", text="Lifelink, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otp-1.jpg" },
  { id="fdn-24", name="Kaito, Cunning Infiltrator Emblem", colors="c", types="Emblem", text="Whenever a player casts a spell, you create a 2/1 blue Ninja creature token.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fdn-24.jpg" },
  { id="gk1-5", name="Saproling // Insect", colors="c", types="Token Creature — Saproling // Token Creature — Insect", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-5.jpg" },
  { id="cma-18", name="Drake", colors="GU", pow="2", tou="2", types="Token Creature — Drake", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cma-18.jpg" },
  { id="drc-6", name="Timeless Dragon", colors="B", pow="4", tou="4", types="Token Creature — Zombie Dragon", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-6.jpg" },
  { id="hou-6", name="Resilient Khenra", colors="B", pow="4", tou="4", types="Token Creature — Zombie Jackal Wizard", text="When Resilient Khenra enters the battlefield, you may have target creature get +X/+X until end of turn, where X is Resilient Khenra's power.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-6.jpg" },
  { id="m3c-2", name="Eldrazi Angel", colors="c", pow="4", tou="4", types="Token Creature — Eldrazi Angel", text="Flying, vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-2.jpg" },
  { id="neo-9", name="Spirit", colors="R", pow="2", tou="2", types="Token Creature — Spirit", text="Menace (This creature can't be blocked except by two or more creatures.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-9.jpg" },
  { id="blb-20", name="Bushy Bodyguard", colors="G", pow="1", tou="1", types="Token Creature — Squirrel Warrior", text="When this creature enters, you may forage. If you do, put two +1/+1 counters on it. (This token's mana cost is {1}{G}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-20.jpg" },
  { id="fin-12", name="Robot Warrior", colors="U", pow="3", tou="3", types="Token Artifact Creature — Robot Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-12.jpg" },
  { id="inr-26", name="Tamiyo, Field Researcher Emblem", colors="c", types="Emblem — Tamiyo", text="You may cast nonland cards from your hand without paying their mana costs.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/inr-26.jpg" },
  { id="tsr-5", name="Knight", colors="B", pow="2", tou="2", types="Token Creature — Knight", text="Protection from white, haste Flanking (Whenever a creature without flanking blocks this creature, the blocking creature gets -1/-1 until end of turn.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsr-5.jpg" },
  { id="thb-4", name="Kraken", colors="U", pow="8", tou="8", types="Token Creature — Kraken", text="Hexproof (This creature can't be the target of spells or abilities your opponents control.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/thb-4.jpg" },
  { id="afr-17", name="Lolth, Spider Queen Emblem", colors="c", types="Emblem — Lolth", text="Whenever an opponent is dealt combat damage by one or more creatures you control, if that player lost less than 8 life this turn, they lose life equal to the difference.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afr-17.jpg" },
  { id="afr-19", name="Zariel, Archduke of Avernus Emblem", colors="c", types="Emblem — Zariel", text="At the end of the first combat phase on your turn, untap target creature you control. After this phase, there is an additional combat phase.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afr-19.jpg" },
  { id="eoe-10", name="Robot", colors="c", pow="2", tou="2", types="Token Artifact Creature — Robot", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eoe-10.jpg" },
  { id="hou-4", name="Earthshaker Khenra", colors="B", pow="4", tou="4", types="Token Creature — Zombie Jackal Warrior", text="Haste When Earthshaker Khenra enters the battlefield, target creature with power less than or equal to Earthshaker Khenra's power can't block this turn.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-4.jpg" },
  { id="thb-12", name="Nightmare", colors="BU", pow="2", tou="3", types="Token Creature — Nightmare", text="Whenever this creature attacks or blocks, each opponent exiles the top two cards of their library.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/thb-12.jpg" },
  { id="khm-10", name="Demon Berserker", colors="R", pow="2", tou="3", types="Token Creature — Demon Berserker", text="Menace (This creature can't be blocked except by two or more creatures.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/khm-10.jpg" },
  { id="aer-1", name="Gremlin", colors="R", pow="2", tou="2", types="Token Creature — Gremlin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/aer-1.jpg" },
  { id="cn2-8", name="Goblin", colors="R", pow="1", tou="1", types="Token Creature — Goblin", text="This creature can't block.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cn2-8.jpg" },
  { id="dmu-11", name="Elemental", colors="R", pow="2", tou="1", types="Token Creature — Elemental", text="Trample, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-11.jpg" },
  { id="unf-6", name="Zombie Employee", colors="B", pow="2", tou="2", types="Token Creature — Zombie Employee", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/unf-6.jpg" },
  { id="otj-9", name="Dinosaur", colors="R", pow="3", tou="1", types="Token Creature — Dinosaur", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-9.jpg" },
  { id="blb-26", name="Cragflame", colors="c", types="Token Legendary Artifact — Equipment", text="Equipped creature gets +1/+1 and has vigilance, trample, and haste. Equip {2}", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-26.jpg" },
  { id="akh-13", name="Trueheart Duelist", colors="W", pow="2", tou="2", types="Token Creature — Zombie Human Warrior", text="Trueheart Duelist can block an additional creature each combat.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-13.jpg" },
  { id="med-r2", name="Dack Fayden Emblem", colors="c", types="Emblem — Dack", text="Whenever you cast a spell that targets one or more permanents, gain control of those permanents.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/med-r2.jpg" },
  { id="rvr-17", name="Sphinx", colors="UW", pow="4", tou="4", types="Token Creature — Sphinx", text="Flying, vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rvr-17.jpg" },
  { id="mh3-35", name="Tamiyo, Seasoned Scholar Emblem", colors="c", types="Emblem", text="You have no maximum hand size.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-35.jpg" },
  { id="blb-6", name="Finch Formation", colors="U", pow="1", tou="1", types="Token Creature — Bird Scout", text="Flying When this creature enters, target creature you control gains flying until end of turn. (This token's mana cost is {2}{U}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-6.jpg" },
  { id="dsc-5", name="Bird", colors="B", pow="2", tou="2", types="Token Creature — Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsc-5.jpg" },
  { id="ema-5", name="Serf", colors="B", pow="0", tou="1", types="Token Creature — Serf", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ema-5.jpg" },
  { id="soc-24", name="Primo, the Indivisible", colors="GU", pow="0", tou="0", types="Token Legendary Creature — Fractal", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-24.jpg" },
  { id="ddi-1", name="Venser, the Sojourner Emblem", colors="c", types="Emblem — Venser", text="Whenever you cast a spell, exile target permanent.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ddi-1.jpg" },
  { id="moc-1", name="Eldrazi", colors="c", pow="7", tou="7", types="Token Creature — Eldrazi", text="Annihilator 1 (Whenever this creature attacks, defending player sacrifices a permanent.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-1.jpg" },
  { id="onc-8", name="Soldier", colors="W", pow="2", tou="2", types="Token Creature — Soldier", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/onc-8.jpg" },
  { id="iko-6", name="Kraken", colors="U", pow="8", tou="8", types="Token Creature — Kraken", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/iko-6.jpg" },
  { id="bng-4", name="Bird", colors="U", pow="2", tou="2", types="Token Enchantment Creature — Bird", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bng-4.jpg" },
  { id="mom-4", name="Kraken", colors="U", pow="1", tou="1", types="Token Creature — Kraken", text="Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mom-4.jpg" },
  { id="c20-16", name="Dinosaur Cat", colors="RW", pow="2", tou="2", types="Token Creature — Dinosaur Cat", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c20-16.jpg" },
  { id="neo-6", name="Construct", colors="R", pow="3", tou="1", types="Token Artifact Creature — Construct", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-6.jpg" },
  { id="tsr-12", name="Llanowar Elves", colors="G", pow="1", tou="1", types="Token Creature — Elf Druid", text="{T}: Add {G}.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsr-12.jpg" },
  { id="lci-3", name="Gnome Soldier", colors="W", pow="*", tou="*", types="Token Artifact Creature — Gnome Soldier", text="This creature's power and toughness are each equal to the number of artifacts and/or creatures you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lci-3.jpg" },
  { id="akh-25", name="Gideon of the Trials Emblem", colors="c", types="Emblem — Gideon", text="As long as you control a Gideon planeswalker, you can't lose the game and your opponents can't win the game.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-25.jpg" },
  { id="stx-9", name="Rowan, Scholar of Sparks Emblem", colors="c", types="Emblem", text="Whenever you cast an instant or sorcery spell, you may pay {2}. If you do, copy that spell. You may choose new targets for the copy.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/stx-9.jpg" },
  { id="gk1-8", name="Saproling // Elf Knight", colors="c", types="Token Creature — Saproling // Token Creature — Elf Knight", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-8.jpg" },
  { id="rna-2", name="Illusion", colors="U", pow="0", tou="2", types="Token Creature — Illusion", text="Whenever this creature blocks a creature, that creature doesn't untap during its controller's next untap step.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/rna-2.jpg" },
  { id="pip-6", name="Alien", colors="U", pow="0", tou="0", types="Token Creature — Alien", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/pip-6.jpg" },
  { id="bfz-12", name="Gideon, Ally of Zendikar Emblem", colors="c", types="Emblem — Gideon", text="Creatures you control get +1/+1.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bfz-12.jpg" },
  { id="m20-12", name="Mu Yanling, Sky Dancer Emblem", colors="c", types="Emblem", text="Islands you control have \"{T}: Draw a card.\"", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m20-12.jpg" },
  { id="tla-9", name="Dragon", colors="R", pow="4", tou="4", types="Token Creature — Dragon", text="Flying, firebending 4 (Whenever this token attacks, add {R}{R}{R}{R} to your mana pool. This mana lasts until end of combat.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tla-9.jpg" },
  { id="afr-3", name="Dog Illusion", colors="U", pow="*", tou="*", types="Token Creature — Dog Illusion", text="This creature's power and toughness are each equal to twice the number of cards in your hand.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/afr-3.jpg" },
  { id="mh3-5", name="Cat Warrior", colors="W", pow="2", tou="1", types="Token Creature — Cat Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-5.jpg" },
  { id="clb-8", name="Skeleton", colors="B", pow="4", tou="1", types="Token Creature — Skeleton", text="Menace (This creature can't be blocked except by two or more creatures.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-8.jpg" },
  { id="one-8", name="Drone", colors="c", pow="2", tou="2", types="Token Artifact Creature — Drone", text="Deathtouch When this creature leaves the battlefield, each opponent loses 2 life and you gain 2 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/one-8.jpg" },
  { id="cmm-67", name="Wall", colors="W", pow="0", tou="4", types="Token Creature — Wall", text="Defender, flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-67.jpg" },
  { id="gk1-9", name="Wurm // Saproling", colors="c", types="Token Creature — Wurm // Token Creature — Saproling", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-9.jpg" },
  { id="m14-13", name="Garruk, Caller of Beasts Emblem", colors="c", types="Emblem — Garruk", text="Whenever you cast a creature spell, you may search your library for a creature card, put it onto the battlefield, then shuffle your library.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m14-13.jpg" },
  { id="neo-12", name="Spirit", colors="G", pow="*", tou="*", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-12.jpg" },
  { id="gk1-10", name="Elemental // Centaur", colors="c", types="Token Creature — Elemental // Token Creature — Centaur", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-10.jpg" },
  { id="mh3-6", name="Fox", colors="W", pow="2", tou="2", types="Token Creature — Fox", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-6.jpg" },
  { id="mid-9", name="Insect", colors="G", pow="3", tou="3", types="Token Creature — Insect", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mid-9.jpg" },
  { id="woc-12", name="Pirate", colors="R", pow="4", tou="2", types="Token Creature — Pirate", text="This creature can't block.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/woc-12.jpg" },
  { id="msh-10", name="The Void", colors="B", pow="5", tou="5", types="Token Legendary Creature — Horror Villain", text="Flying, indestructible The Void attacks each combat if able.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-10.jpg" },
  { id="l17-1", name="Gremlin // Energy Reserve", colors="c", types="Token Creature — Gremlin // Card", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/l17-1.jpg" },
  { id="eld-19", name="Garruk, Cursed Huntsman Emblem", colors="c", types="Emblem", text="Creatures you control get +3/+3 and have trample.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/eld-19.jpg" },
  { id="clb-7", name="Demon", colors="B", pow="3", tou="3", types="Token Creature — Demon", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-7.jpg" },
  { id="moc-29", name="Butterfly", colors="G", pow="1", tou="1", types="Token Creature — Insect", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-29.jpg" },
  { id="woe-4", name="Mouse", colors="W", pow="1", tou="1", types="Token Creature — Mouse", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/woe-4.jpg" },
  { id="msh-8", name="Galactus", colors="B", pow="16", tou="16", types="Token Legendary Creature — Elder Alien", text="Flying, trample Whenever Galactus attacks, destroy target land.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-8.jpg" },
  { id="drc-5", name="Champion of Wits", colors="B", pow="4", tou="4", types="Token Creature — Zombie Snake Wizard", text="When this token enters, you may draw cards equal to its power. If you do, discard two cards.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/drc-5.jpg" },
  { id="40k-1", name="Astartes Warrior", colors="W", pow="2", tou="2", types="Token Creature — Astartes Warrior", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-1.jpg" },
  { id="blb-14", name="Snail", colors="B", pow="1", tou="1", types="Token Creature — Snail", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-14.jpg" },
  { id="one-4", name="Phyrexian Horror", colors="R", pow="*", tou="1", types="Token Creature — Phyrexian Horror", text="Trample, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/one-4.jpg" },
  { id="msh-21", name="Sturdy Shield", colors="c", types="Token Artifact — Equipment", text="Equipped creature gets +1/+2. Equip {2} ({2}: Attach to target creature you control. Equip only as a sorcery.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-21.jpg" },
  { id="thb-14", name="Wall", colors="c", pow="0", tou="4", types="Token Artifact Creature — Wall", text="Defender", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/thb-14.jpg" },
  { id="otj-4", name="Sheep", colors="W", pow="1", tou="1", types="Token Creature — Sheep", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-4.jpg" },
  { id="clb-39", name="Centaur", colors="G", pow="3", tou="3", types="Token Creature — Centaur", text="Protection from black", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/clb-39.jpg" },
  { id="otj-14", name="Varmint", colors="G", pow="2", tou="1", types="Token Creature — Varmint", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-14.jpg" },
  { id="unf-4", name="Contortionist // Contortionist", colors="c", types="Token Creature — Octopus Performer // Token Creature — Octopus Performer", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/unf-4.jpg" },
  { id="fin-13", name="Horror", colors="B", pow="2", tou="2", types="Token Creature — Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-13.jpg" },
  { id="war-16", name="Citizen", colors="BGRUW", pow="2", tou="2", types="Token Creature — Citizen", text="This creature is all colors.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/war-16.jpg" },
  { id="neo-18", name="Kaito Shizuki Emblem", colors="c", types="Emblem", text="Whenever a creature you control deals combat damage to a player, search your library for a blue or black creature card, put it onto the battlefield, then shuffle.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-18.jpg" },
  { id="uma-4", name="Homunculus", colors="U", pow="2", tou="2", types="Token Creature — Homunculus", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/uma-4.jpg" },
  { id="ust-1", name="Angel // Angel", colors="c", types="Token Creature — Angel // Token", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ust-1.jpg" },
  { id="blb-22", name="Rust-Shield Rampager", colors="G", pow="1", tou="1", types="Token Creature — Raccoon Warrior", text="This creature can't be blocked by creatures with power 2 or less. (This token's mana cost is {3}{G}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-22.jpg" },
  { id="fin-18", name="Frog", colors="G", pow="1", tou="1", types="Token Creature — Frog", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-18.jpg" },
  { id="blc-10", name="Steelburr Champion", colors="W", pow="1", tou="1", types="Token Creature — Mouse Soldier", text="Vigilance Whenever an opponent casts a noncreature spell, put a +1/+1 counter on this creature. (This token's mana cost is {2}{W}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-10.jpg" },
  { id="akh-5", name="Glyph Keeper", colors="W", pow="5", tou="3", types="Token Creature — Zombie Sphinx", text="Flying Whenever Glyph Keeper becomes the target of a spell or ability for the first time each turn, counter that spell or ability.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/akh-5.jpg" },
  { id="bng-11", name="Kiora, the Crashing Wave Emblem", colors="c", types="Emblem — Kiora", text="At the beginning of your end step, create a 9/9 blue Kraken creature token.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bng-11.jpg" },
  { id="msh-2", name="Hero", colors="W", pow="3", tou="2", types="Token Creature — Hero", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-2.jpg" },
  { id="cmm-25", name="Elemental", colors="R", pow="3", tou="1", types="Token Creature — Elemental", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-25.jpg" },
  { id="khm-9", name="Zombie Berserker", colors="B", pow="2", tou="2", types="Token Creature — Zombie Berserker", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/khm-9.jpg" },
  { id="moc-22", name="Elemental", colors="R", pow="1", tou="1", types="Token Creature — Elemental", text="Whenever this creature becomes tapped, it deals 1 damage to target player.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/moc-22.jpg" },
  { id="dmc-12", name="Kavu", colors="BGRUW", pow="3", tou="3", types="Token Creature — Kavu", text="This creature is all colors. Trample", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmc-12.jpg" },
  { id="40k-10", name="Vanguard Suppressor", colors="U", pow="3", tou="2", types="Token Creature — Astartes Warrior", text="Flying Whenever Vanguard Suppressor deals combat damage to a player, draw a card.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-10.jpg" },
  { id="blb-25", name="Otter", colors="RU", pow="1", tou="1", types="Token Creature — Otter", text="Prowess (Whenever you cast a noncreature spell, this creature gets +1/+1 until end of turn.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-25.jpg" },
  { id="voc-3", name="Spirit", colors="W", pow="3", tou="3", types="Token Creature — Spirit", text="Flying", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/voc-3.jpg" },
  { id="tsr-14", name="Assembly-Worker", colors="c", pow="2", tou="2", types="Token Artifact Creature — Assembly-Worker", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tsr-14.jpg" },
  { id="war-4", name="Wall", colors="W", pow="0", tou="3", types="Token Creature — Wall", text="Defender", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/war-4.jpg" },
  { id="otc-20", name="Plant Warrior", colors="G", pow="4", tou="2", types="Token Creature — Plant Warrior", text="Reach", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otc-20.jpg" },
  { id="cmm-77", name="Ajani Steadfast Emblem", colors="c", types="Emblem — Ajani", text="If a source would deal damage to you or a planeswalker you control, prevent all but 1 of that damage.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-77.jpg" },
  { id="mid-15", name="Zombie", colors="BU", pow="*", tou="*", types="Token Creature — Zombie", text="Menace (This creature can't be blocked except by two or more creatures.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mid-15.jpg" },
  { id="dmu-21", name="Stangg Twin", colors="GR", pow="3", tou="4", types="Token Legendary Creature — Human Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-21.jpg" },
  { id="vow-7", name="Vampire", colors="B", pow="2", tou="3", types="Token Creature — Vampire", text="Flying, lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/vow-7.jpg" },
  { id="msh-11", name="Alien", colors="R", pow="1", tou="1", types="Token Creature — Alien", text="Haste This token attacks each combat if able.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/msh-11.jpg" },
  { id="dmu-19", name="Wurm", colors="G", pow="4", tou="4", types="Token Creature — Wurm", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dmu-19.jpg" },
  { id="cns-4", name="Ogre", colors="R", pow="4", tou="4", types="Token Creature — Ogre", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cns-4.jpg" },
  { id="otj-20", name="Plot", colors="c", types="Card", text="After you plot a card, you may place the exiled card here. You may cast it as a sorcery on a later turn without paying its mana cost.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-20.jpg" },
  { id="tdm-10", name="Zombie Druid", colors="B", pow="2", tou="2", types="Token Creature — Zombie Druid", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-10.jpg" },
  { id="m3c-9", name="Aetherborn", colors="B", pow="*", tou="*", types="Token Creature — Aetherborn", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-9.jpg" },
  { id="otj-6", name="Beau", colors="U", pow="*", tou="*", types="Token Legendary Creature — Ox", text="This creature's power and toughness are each equal to the number of lands you control.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/otj-6.jpg" },
  { id="tdm-6", name="Spirit", colors="W", pow="1", tou="1", types="Token Creature — Spirit", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tdm-6.jpg" },
  { id="m3c-22", name="Tarmogoyf", colors="G", pow="*", tou="1+*", types="Token Creature — Lhurgoyf", text="Tarmogoyf's power is equal to the number of card types among cards in all graveyards and its toughness is equal to that number plus 1. (This token's mana cost is {1}{G}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m3c-22.jpg" },
  { id="znr-9", name="Hydra", colors="BG", pow="*", tou="*", types="Token Creature — Hydra", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/znr-9.jpg" },
  { id="mh3-19", name="Rat", colors="B", pow="1", tou="1", types="Token Creature — Rat", text="Lifelink", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mh3-19.jpg" },
  { id="brc-12", name="Scrap", colors="c", types="Token Artifact", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/brc-12.jpg" },
  { id="hou-10", name="Horse", colors="W", pow="5", tou="5", types="Token Creature — Horse", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/hou-10.jpg" },
  { id="dsk-3", name="Beast", colors="W", pow="4", tou="4", types="Token Creature — Beast", text="This creature can't attack or block alone.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/dsk-3.jpg" },
  { id="c18-12", name="Survivor", colors="R", pow="1", tou="1", types="Token Creature — Survivor", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c18-12.jpg" },
  { id="cmm-44", name="Phyrexian Myr", colors="c", pow="1", tou="1", types="Token Artifact Creature — Phyrexian Myr", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/cmm-44.jpg" },
  { id="blb-18", name="Manifold Mouse", colors="R", pow="1", tou="1", types="Token Creature — Mouse Soldier", text="At the beginning of combat on your turn, target Mouse you control gains your choice of double strike or trample until end of turn. (This token's mana cost is {1}{R}.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blb-18.jpg" },
  { id="tla-3", name="Spirit", colors="c", pow="1", tou="1", types="Token Creature — Spirit", text="This token can't block or be blocked by non-Spirit creatures.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tla-3.jpg" },
  { id="spm-2", name="Illusion Villain", colors="U", pow="3", tou="3", types="Token Creature — Illusion Villain", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/spm-2.jpg" },
  { id="neo-3", name="Samurai", colors="W", pow="2", tou="2", types="Token Creature — Samurai", text="Vigilance", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-3.jpg" },
  { id="gk1-6", name="Soldier // Goblin", colors="c", types="Token Creature — Soldier // Token Creature — Goblin", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/gk1-6.jpg" },
  { id="40k-6", name="Ultramarines Honour Guard", colors="W", pow="2", tou="2", types="Token Creature — Astartes Warrior", text="Other creatures you control get +1/+1.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/40k-6.jpg" },
  { id="tmt-2", name="Dinosaur Soldier", colors="W", pow="2", tou="2", types="Token Creature — Dinosaur Soldier", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/tmt-2.jpg" },
  { id="iko-8", name="Dinosaur", colors="R", pow="1", tou="1", types="Token Creature — Dinosaur", text="Haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/iko-8.jpg" },
  { id="lci-12", name="Fungus Dinosaur", colors="G", pow="*", tou="*", types="Token Creature — Fungus Dinosaur", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/lci-12.jpg" },
  { id="blc-16", name="Shark", colors="U", pow="3", tou="3", types="Token Creature — Shark", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/blc-16.jpg" },
  { id="zen-8", name="Elemental", colors="R", pow="7", tou="1", types="Token Creature — Elemental", text="Trample, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/zen-8.jpg" },
  { id="mid-10", name="Ooze", colors="G", pow="*", tou="*+1", types="Token Creature — Ooze", text="This creature's power is equal to the number of card types among cards in your graveyard and its toughness is equal to that number plus 1.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/mid-10.jpg" },
  { id="m19-16", name="Tezzeret, Artifice Master Emblem", colors="c", types="Emblem — Tezzeret", text="At the beginning of your end step, search your library for a permanent card, put it onto the battlefield, then shuffle your library.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m19-16.jpg" },
  { id="c14-15", name="Horror", colors="B", pow="*", tou="*", types="Token Creature — Horror", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/c14-15.jpg" },
  { id="neo-13", name="Keimi", colors="BG", pow="3", tou="3", types="Token Legendary Creature — Frog", text="Whenever you cast an enchantment spell, each opponent loses 1 life and you gain 1 life.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/neo-13.jpg" },
  { id="roe-2", name="Elemental", colors="R", pow="*", tou="*", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/roe-2.jpg" },
  { id="m21-8", name="Goblin Wizard", colors="R", pow="1", tou="1", types="Token Creature — Goblin Wizard", text="Prowess (Whenever you cast a noncreature spell, this creature gets +1/+1 until end of turn.)", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/m21-8.jpg" },
  { id="soc-19", name="Elemental", colors="RU", pow="*", tou="*", types="Token Creature — Elemental", text="Flying, haste", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/soc-19.jpg" },
  { id="fin-21", name="Elemental", colors="BGRUW", pow="2", tou="2", types="Token Creature — Elemental", text="This token is all colors.", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/fin-21.jpg" },
  { id="ktk-10", name="Spirit Warrior", colors="BG", pow="*", tou="*", types="Token Creature — Spirit Warrior", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/ktk-10.jpg" },
  { id="bro-11", name="Zombie", colors="c", pow="3", tou="3", types="Token Artifact Creature — Zombie", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/bro-11.jpg" },
  { id="woe-9", name="Elemental", colors="UW", pow="4", tou="4", types="Token Creature — Elemental", text="", img="https://cdn.jsdelivr.net/gh/bradgravett/bitterblossom@main/token_images/woe-9.jpg" },

}

------------------------------------------------------------------- state --

local filtered  = {}
local page      = 0
local uiReady   = false
local injectTries = 0
local panelOpen = false

----------------------------------------------------------------- helpers --

local function buildIndex()
  for _, t in ipairs(TOKENS) do
    local pt = (t.pow and t.tou) and (t.pow .. "/" .. t.tou) or ""
    t._search = string.lower(table.concat({
      t.name, t.types or "", t.text or "", t.colors or "", pt, t.id,
    }, " "))
    -- Display type line without the leading "Token ".
    t._types = (t.types or ""):gsub("^Token ", "")
  end
end

local function ptString(t)
  if t.pow and t.tou then return t.pow .. "/" .. t.tou end
  return nil
end

local function trunc(s, n)
  if #s > n then return s:sub(1, n - 1) .. "…" end
  return s
end

local function rowLabel(t)
  local pt = ptString(t)
  local line1 = t.name .. (pt and ("  " .. pt) or "")
  if t.img == "" then line1 = line1 .. "   (no image)" end
  local line2 = t._types or ""
  if t.text and t.text ~= "" then
    line2 = line2 .. " · " .. t.text:gsub("%s+", " ")
  end
  return trunc(line1, 44) .. "\n" .. trunc(line2, 52)
end

local function descFor(t)
  local parts = { t._types or "" }
  if t.text and t.text ~= "" then parts[#parts + 1] = t.text end
  local pt = ptString(t)
  if pt then parts[#parts + 1] = pt end
  return table.concat(parts, "\n")
end

local function matches(t, terms)
  for _, term in ipairs(terms) do
    if not t._search:find(term, 1, true) then return false end
  end
  return true
end

local function splitTerms(text)
  local terms = {}
  for word in string.lower(text):gmatch("%S+") do
    terms[#terms + 1] = word
  end
  return terms
end

local function pageCount()
  return math.max(1, math.ceil(#filtered / PAGE_SIZE))
end

------------------------------------------------------------------- spawn --

local function cardJSON(nickname, description, faceUrl)
  return {
    Name = "CardCustom",
    Transform = {
      posX = 0, posY = 3, posZ = 0, rotX = 0, rotY = 180, rotZ = 0,
      scaleX = 1, scaleY = 1, scaleZ = 1,
    },
    Nickname = nickname or "", Description = description or "",
    Grid = true, Snap = true, Hands = true,
    CardID = 100, SidewaysCard = false,
    CustomDeck = {
      ["1"] = {
        FaceURL = faceUrl,
        BackURL = (CARD_BACK ~= "" and CARD_BACK) or faceUrl,
        NumWidth = 1, NumHeight = 1,
        BackIsHidden = true, UniqueBack = false, Type = 0,
      },
    },
  }
end

local function spawnPosFor(color)
  local ok, t = pcall(function()
    return Player[color] and Player[color].getHandTransform()
  end)
  if ok and t then
    return t.position + t.forward * 8 + Vector(0, 2, 0)
  end
  return self.getPosition() + Vector(0, 3, 0)
end

local function spawnToken(t, playerColor)
  if not t.img or t.img == "" then
    broadcastToColor("No image set for " .. t.name .. "  [" .. t.id .. "]",
      playerColor, { 1, 0.4, 0.4 })
    return
  end
  spawnObjectJSON({
    json = JSON.encode(cardJSON(t.name, descFor(t), t.img)),
    position = spawnPosFor(playerColor),
    rotation = { 0, 180, 0 },
  })
  broadcastToColor("Spawned " .. t.name, playerColor, { 0.6, 1, 0.6 })
end

---------------------------------------------------------------------- ui --

local function renderPage()
  local total = #filtered
  local pages = pageCount()
  if page >= pages then page = pages - 1 end
  if page < 0 then page = 0 end

  local base = page * PAGE_SIZE
  for i = 1, PAGE_SIZE do
    local id = "row" .. i
    local t = filtered[base + i]
    if t then
      self.UI.setValue(id, rowLabel(t))
      self.UI.setAttribute(id, "textColor",
        (t.img == "" and "#888888") or "#ffffff")
      self.UI.setAttribute(id, "active", true)
    else
      self.UI.setAttribute(id, "active", false)
    end
  end

  self.UI.setAttribute("prevBtn", "active", tostring(page > 0))
  self.UI.setAttribute("nextBtn", "active", tostring(page < pages - 1))

  local msg
  if total == 0 then
    msg = "No matches."
  else
    msg = total .. " token" .. (total == 1 and "" or "s")
    if pages > 1 then
      msg = msg .. "  ·  page " .. (page + 1) .. "/" .. pages
    end
  end
  self.UI.setValue("status", msg)
end

local function doSearch(text)
  text = (text or ""):match("^%s*(.-)%s*$")
  if text == "" then
    filtered = TOKENS
  else
    filtered = {}
    local terms = splitTerms(text)
    for _, t in ipairs(TOKENS) do
      if matches(t, terms) then filtered[#filtered + 1] = t end
    end
  end
  page = 0
  renderPage()
end

local function findById(nodes, id)
  for _, n in ipairs(nodes or {}) do
    if n.attributes and n.attributes.id == id then return n end
    local hit = findById(n.children, id)
    if hit then return hit end
  end
  return nil
end

local injectRows
injectRows = function()
  local xml = self.UI.getXmlTable()
  local panel = xml and findById(xml, "tokenPanel")
  if not panel then
    injectTries = injectTries + 1
    if injectTries > 20 then
      print("[TokenSpawner] gave up: no #tokenPanel in object UI XML")
      return
    end
    Wait.time(injectRows, 0.5)
    return
  end

  panel.children = panel.children or {}
  for i = 1, PAGE_SIZE do
    local yOff = ROW_Y0 - (i - 1) * ROW_STEP
    panel.children[#panel.children + 1] = {
      tag = "Button",
      attributes = {
        id = "row" .. i,
        active = false,
        onClick = "onResultClick",
        rectAlignment = "UpperCenter",
        offsetXY = "0 " .. yOff,
        width = 326, height = ROW_H,
        fontSize = 13,
        alignment = "MiddleLeft",
        colors = "#333333|#4a4a4a|#262626|#333333",
        textColor = "#ffffff",
      },
      value = "",
    }
  end

  self.UI.setXmlTable(xml)
  print("[TokenSpawner] injected " .. PAGE_SIZE .. " row slots, "
    .. #TOKENS .. " tokens loaded")

  Wait.time(function()
    uiReady = true
    doSearch("")
  end, 0.3)
end

------------------------------------------------------------ ui callbacks --

function onTogglePanel()
  panelOpen = not panelOpen
  self.UI.setAttribute("tokenPanel", "active", tostring(panelOpen))
end

function onSearchInput(player, value, id)
  if not uiReady then return end
  doSearch(value)
end

function onPrevPage()
  if page > 0 then page = page - 1; renderPage() end
end

function onNextPage()
  if page < pageCount() - 1 then page = page + 1; renderPage() end
end

function onResultClick(player, mouseButton, id)
  local i = tonumber(id:match("row(%d+)"))
  if not i then return end
  local t = filtered[page * PAGE_SIZE + i]
  if not t then return end
  spawnToken(t, player.color)
end

--------------------------------------------------------------------- tts --

function onLoad()
  buildIndex()
  injectRows()
end
