
}

------------------------------------------------------------------- state --

local filtered    = {}
local page        = 0
local uiReady     = false
local panelOpen   = false

local currentText = ""      -- live search box text
local activeCat   = "all"   -- active category filter

-- Quick-spawn buttons: button id -> exact card name to spawn.
local QUICK = {
  qs_treasure = "Treasure",
  qs_monarch  = "The Monarch",
  qs_clue     = "Clue",
  qs_food     = "Food",
  qs_map      = "Map",
  qs_blood    = "Blood",
}

-- Quick-spawn button icons, registered as custom UI assets at load.
-- Asset name -> image URL. Referenced by name from the <Image> overlays
-- in TokenSpawner.xml. Swap URLs here to change the icons.
local QUICK_ICONS = {
  { name = "ic_treasure", url = "https://steamusercontent-a.akamaihd.net/ugc/17018773522266152255/223000D86A0C8397FE121FDF7B23FE8FDBE6CCFD/" },
  { name = "ic_monarch",  url = "https://steamusercontent-a.akamaihd.net/ugc/12072374502928477656/40D67528C15F8CEDA2740D5AF8D4AD4E1F7CCAC9/" },
  { name = "ic_clue",     url = "https://steamusercontent-a.akamaihd.net/ugc/9327800001146064758/BAD80FD4224F0FB0A8A574F640E27ABCA8A00BA4/" },
  { name = "ic_food",     url = "https://steamusercontent-a.akamaihd.net/ugc/15154958424979900996/7672A745E52A8E6A016A1C6211EF4ED13D3BE2E4/" },
  { name = "ic_map",      url = "https://steamusercontent-a.akamaihd.net/ugc/14370504716232549440/85E15878018C244C58224DA72171D61AF98C5AAE/" },
  { name = "ic_blood",    url = "https://steamusercontent-a.akamaihd.net/ugc/15724273169658124758/9B5735256468328FC44AC01F064871C955E42FA8/" },
}

-- Register the icons as UI custom assets. Assets may live on the object UI
-- or the global UI depending on the TTS version, so apply to both (guarded);
-- merge by name so reloads don't duplicate entries.
local function registerIcons()
  local function apply(ui)
    if not ui or not ui.setCustomAssets then return end
    local assets = (ui.getCustomAssets and ui.getCustomAssets()) or {}
    local byName = {}
    for _, a in ipairs(assets) do byName[a.name] = a end
    for _, a in ipairs(QUICK_ICONS) do byName[a.name] = a end
    local merged = {}
    for _, a in pairs(byName) do merged[#merged + 1] = a end
    pcall(function() ui.setCustomAssets(merged) end)
  end
  apply(self.UI)
  apply(UI)
end

-- Category filter buttons: button id -> category tag (see buildIndex).
local FILTER_IDS = { "flt_all", "flt_tokens", "flt_emblems",
                     "flt_dungeon", "flt_helper" }
local FILTER_CAT = {
  flt_all     = "all",
  flt_tokens  = "tokens",
  flt_emblems = "emblems",
  flt_dungeon = "dungeon",
  flt_helper  = "helper",
}

----------------------------------------------------------------- helpers --

-- Category from the type line, priority Emblem > Dungeon > Token > Helper.
local function categoryOf(typeLine)
  local tl = typeLine or ""
  if tl:find("Emblem") then return "emblems" end
  if tl:find("Dungeon") then return "dungeon" end
  if tl:find("Token") then return "tokens" end
  return "helper"
end

local function buildIndex()
  for _, t in ipairs(TOKENS) do
    local pt = (t.pow and t.tou) and (t.pow .. "/" .. t.tou) or ""
    t._search = string.lower(table.concat({
      t.name, t.types or "", t.text or "", t.colors or "", pt, t.id,
    }, " "))
    -- Display type line without the leading "Token ".
    t._types = (t.types or ""):gsub("^Token ", "")
    t._cat = categoryOf(t.types)
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

local function cardJSON(nickname, description, faceUrl, backUrl)
  -- A real double-faced token passes its back face here: use it as the
  -- BackURL and DON'T hide it (it's a game side you flip to, not hidden
  -- info). Otherwise fall back to CARD_BACK, then the face itself.
  local isDFC = backUrl ~= nil and backUrl ~= ""
  local back = (isDFC and backUrl) or (CARD_BACK ~= "" and CARD_BACK) or faceUrl
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
        BackURL = back,
        NumWidth = 1, NumHeight = 1,
        BackIsHidden = not isDFC, UniqueBack = false, Type = 0,
      },
    },
  }
end

-- Spawn to the RIGHT of the tile, clear of the floating panel. Flip the
-- sign of SPAWN_RIGHT if tokens land on the left; raise SPAWN_UP if they
-- clip the table.
local SPAWN_RIGHT = 6
local SPAWN_UP    = 2

local function spawnPos()
  return self.getPosition()
    + self.getTransformRight() * SPAWN_RIGHT
    + Vector(0, SPAWN_UP, 0)
end

local function spawnToken(t, playerColor)
  if not t.img or t.img == "" then
    broadcastToColor("No image set for " .. t.name .. "  [" .. t.id .. "]",
      playerColor, { 1, 0.4, 0.4 })
    return
  end

  local data = cardJSON(t.name, descFor(t), t.img, t.back)

  -- Alternate printings -> selectable object States (single-faced tokens
  -- only; DFCs carry no variants, so this is skipped for them). State 1 is
  -- the original art; each variant URL becomes states 2, 3, ...
  if t.variants and #t.variants > 0 then
    data.States = {}
    for i, url in ipairs(t.variants) do
      data.States[tostring(i + 1)] = cardJSON(t.name, descFor(t), url)
    end
  end

  spawnObjectJSON({
    json = JSON.encode(data),
    position = spawnPos(),
    rotation = { 0, 180, 0 },
  })

  local n = 1 + (t.variants and #t.variants or 0)
  local extra = ""
  if t.back and t.back ~= "" then
    extra = "  (double-faced)"
  elseif n > 1 then
    extra = "  (" .. n .. " printings)"
  end
  broadcastToColor("Spawned " .. t.name .. extra, playerColor, { 0.6, 1, 0.6 })
end

-- Spawn the first token whose card name matches exactly (quick-spawn).
local function spawnByName(name, playerColor)
  for _, t in ipairs(TOKENS) do
    if t.name == name then
      spawnToken(t, playerColor)
      return
    end
  end
  broadcastToColor("Not in data: " .. name, playerColor, { 1, 0.4, 0.4 })
end

---------------------------------------------------------------------- ui --

local function renderPage()
  local total = #filtered
  local pages = pageCount()
  if page >= pages then page = pages - 1 end
  if page < 0 then page = 0 end

  -- Rows are STATIC in the XML (setValue works on those; injected buttons
  -- lose their text when active is toggled). Empty rows are blanked and
  -- made transparent rather than deactivated.
  local ROW_ON  = "#333333|#4a4a4a|#262626|#333333"
  local ROW_OFF = "#00000000|#00000000|#00000000|#00000000"
  local base = page * PAGE_SIZE
  for i = 1, PAGE_SIZE do
    local btn = "row" .. i        -- click target (Button)
    local txt = "row" .. i .. "txt"  -- label (Text overlay); setValue targets this
    local t = filtered[base + i]
    if t then
      self.UI.setValue(txt, rowLabel(t))
      self.UI.setAttribute(txt, "color",
        (t.img == "" and "#888888") or "#ffffff")
      self.UI.setAttribute(btn, "colors", ROW_ON)
    else
      self.UI.setValue(txt, "")
      self.UI.setAttribute(btn, "colors", ROW_OFF)
    end
  end

  self.UI.setAttribute("prevBtn", "active", tostring(page > 0))
  self.UI.setAttribute("prevBtn", "textColor", "#ffffff")
  self.UI.setAttribute("nextBtn", "active", tostring(page < pages - 1))
  self.UI.setAttribute("nextBtn", "textColor", "#ffffff")

  local msg
  if total == 0 then
    msg = "No matches."
  else
    msg = total .. " result" .. (total == 1 and "" or "s")
    if pages > 1 then
      msg = msg .. "  ·  page " .. (page + 1) .. "/" .. pages
    end
  end
  self.UI.setValue("status", msg)
end

-- Apply the active category filter AND the current search text together.
local function applyFilters()
  local terms = splitTerms(currentText)
  local hasText = currentText ~= ""
  filtered = {}
  for _, t in ipairs(TOKENS) do
    local catOk = (activeCat == "all") or (t._cat == activeCat)
    if catOk and (not hasText or matches(t, terms)) then
      filtered[#filtered + 1] = t
    end
  end
  page = 0
  renderPage()
end

-- Full 4-state colour blocks. Single `color` lets TTS derive the pressed
-- tint by darkening, which reads near-black on a dark base.
local FILTER_ON  = "#5B21B6|#6d34d6|#4a1a9c|#5B21B6"
local FILTER_OFF = "#333344|#404058|#2a2a38|#333344"

local function updateFilterButtons()
  for _, fid in ipairs(FILTER_IDS) do
    local on = (FILTER_CAT[fid] == activeCat)
    self.UI.setAttribute(fid, "colors", on and FILTER_ON or FILTER_OFF)
    self.UI.setAttribute(fid, "textColor", "#ffffff")
  end
end

------------------------------------------------------------ ui callbacks --

function onTogglePanel()
  panelOpen = not panelOpen
  self.UI.setAttribute("tokenPanel", "active", tostring(panelOpen))
end

function onSearchInput(player, value, id)
  if not uiReady then return end
  currentText = value or ""
  applyFilters()
end

function onFilter(player, mouseButton, id)
  local cat = FILTER_CAT[id]
  if not cat then return end
  activeCat = cat
  updateFilterButtons()
  applyFilters()
end

function onQuickSpawn(player, mouseButton, id)
  local name = QUICK[id]
  if name then spawnByName(name, player.color) end
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
  registerIcons()
  -- Let the pasted XML UI finish parsing, then populate the static rows.
  Wait.time(function()
    uiReady = true
    updateFilterButtons()
    applyFilters()
  end, 0.3)
end
