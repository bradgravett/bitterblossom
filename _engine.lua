
}

------------------------------------------------------------------- state --

local filtered    = {}
local page        = 0
local uiReady     = false
local injectTries = 0
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

  local data = cardJSON(t.name, descFor(t), t.img)

  -- Alternate printings -> selectable object States. State 1 is the default
  -- face (t.img, original art); each variant URL becomes states 2, 3, ...
  -- Players switch printings via the state menu / number keys in TTS.
  if t.variants and #t.variants > 0 then
    data.States = {}
    for i, url in ipairs(t.variants) do
      data.States[tostring(i + 1)] = cardJSON(t.name, descFor(t), url)
    end
  end

  spawnObjectJSON({
    json = JSON.encode(data),
    position = spawnPosFor(playerColor),
    rotation = { 0, 180, 0 },
  })

  local n = 1 + (t.variants and #t.variants or 0)
  local extra = (n > 1) and ("  (" .. n .. " printings)") or ""
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

local function updateFilterButtons()
  for _, fid in ipairs(FILTER_IDS) do
    local on = (FILTER_CAT[fid] == activeCat)
    self.UI.setAttribute(fid, "color", on and "#5B21B6" or "#333344")
  end
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
    updateFilterButtons()
    applyFilters()
  end, 0.3)
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
  injectRows()
end
