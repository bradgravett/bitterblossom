
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
