-- FlyTimes Options Panel
-- Flat dark look in the style of the client's own settings window
-- (sidebar with sections on the left, content on the right).
--
-- Emberveil client notes, all handled here:
--   * frames anchored by two points collapse: one anchor + fixed size only
--   * StartMoving() snaps back on release: the window is moved by hand
--   * SetTextColor on template fonts recolours the shared font object:
--     only own fonts (CreateFontString without template + SetFont)
--   * CheckButton lacks SetCheckedTexture: checkboxes are plain Buttons

FlyTimes = FlyTimes or {}
local FTT = FlyTimes
local L = FTT.L or {}

local optionsFrame = nil
local styleButtons = {}
local generalChecks = {}
local pages = {}
local navItems = {}

local FONT = "Fonts\\FRIZQT__.TTF"
local FLAT = "Interface\\Tooltips\\UI-Tooltip-Background" -- plain fill, known to load here

local W, H = 600, 400          -- window
local NAV_W = 160              -- sidebar width
local HEAD_H = 48              -- header height
local FOOT_H = 44              -- footer height
local PAGE_W = W - NAV_W - 24
local PAGE_H = H - HEAD_H - FOOT_H - 8

-- colours
local GOLD = { 1, 0.78, 0.1 }
local TEXT = { 0.92, 0.9, 0.84 }
local MUTED = { 0.55, 0.57, 0.6 }

-- =====================================================
--  SMALL HELPERS
-- =====================================================

local function text(parent, size, color, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont(FONT, size or 12)
    fs:SetJustifyH("LEFT")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    local c = color or TEXT
    fs:SetTextColor(c[1], c[2], c[3])
    return fs
end

-- flat coloured rectangle, one anchor + size
local function rect(parent, layer, point, rel, relPoint, x, y, w, h, r, g, b, a)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(FLAT)
    t:SetVertexColor(r, g, b, a or 1)
    t:SetPoint(point, rel, relPoint, x, y)
    t:SetWidth(w)
    t:SetHeight(h)
    return t
end

local function panel(frame, r, g, b, a, br, bg, bb)
    frame:SetBackdrop({
        bgFile = FLAT,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(r, g, b, a)
    frame:SetBackdropBorderColor(br or 0.22, bg or 0.26, bb or 0.3, 1)
end

-- =====================================================
--  CHECKBOX (plain Button: dark square with a gold check)
-- =====================================================

local function CreateCheckbox(parent, x, y, labelText, onClickFunc)
    local cb = CreateFrame("Button", nil, parent)
    cb:SetWidth(PAGE_W - 40)
    cb:SetHeight(22)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    -- the box
    local box = CreateFrame("Frame", nil, cb)
    box:SetWidth(18)
    box:SetHeight(18)
    box:SetPoint("LEFT", cb, "LEFT", 0, 0)
    panel(box, 0.03, 0.04, 0.05, 1, 0.35, 0.37, 0.4)
    box:EnableMouse(false)

    cb.mark = box:CreateTexture(nil, "OVERLAY")
    cb.mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cb.mark:SetWidth(24)
    cb.mark:SetHeight(24)
    cb.mark:SetPoint("CENTER", box, "CENTER", 1, 1)
    cb.mark:Hide()

    local label = text(cb, 12, TEXT)
    label:SetPoint("LEFT", cb, "LEFT", 28, 0)
    label:SetText(labelText)

    -- hover: label turns gold
    cb:SetScript("OnEnter", function() label:SetTextColor(GOLD[1], GOLD[2], GOLD[3]) end)
    cb:SetScript("OnLeave", function() label:SetTextColor(TEXT[1], TEXT[2], TEXT[3]) end)

    cb.SetChecked = function(self, checked)
        self.checked = checked and 1 or nil
        if self.checked then self.mark:Show() else self.mark:Hide() end
    end
    cb.GetChecked = function(self) return self.checked end

    cb:SetScript("OnClick", function()
        this:SetChecked(not this.checked)
        onClickFunc()
    end)
    return cb, label
end

-- client-styled button (the client draws UIPanelButtonTemplate in its own look)
local function CreateButton(parent, label, w, point, rel, relPoint, x, y, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(w)
    b:SetHeight(24)
    b:SetPoint(point, rel, relPoint, x, y)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

local function sectionHeader(parent, y, label)
    local h = text(parent, 14, { 1, 1, 1 })
    h:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    h:SetText(label)
    rect(parent, "ARTWORK", "TOPLEFT", parent, "TOPLEFT", 16, y - 20, PAGE_W - 40, 1, 0.3, 0.33, 0.37, 0.8)
    return h
end

-- =====================================================
--  STYLE PREVIEW BUTTON
-- =====================================================

local function CreateStylePreviewButton(parent, styleKey, x, y, width, height)
    local LABEL_H = 16
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    panel(btn, 0.04, 0.05, 0.06, 1)

    local style = FTT.BarStyles and FTT.BarStyles.styles and FTT.BarStyles.styles[styleKey]

    -- mini bar background + bar (one anchor + size)
    local bh = height - LABEL_H - 10
    local bw = width - 12
    local bgc = style and style.barBgColor or { 0.15, 0.15, 0.15, 0.9 }
    rect(btn, "ARTWORK", "TOPLEFT", btn, "TOPLEFT", 6, -5, bw, bh, bgc[1], bgc[2], bgc[3], bgc[4] or 1)
    local bar = CreateFrame("StatusBar", nil, btn)
    bar:SetPoint("TOPLEFT", btn, "TOPLEFT", 6, -5)
    bar:SetWidth(bw)
    bar:SetHeight(bh)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(70)
    if style then bar:SetStatusBarColor(style.barColor[1], style.barColor[2], style.barColor[3]) end

    local label = text(btn, 10, TEXT)
    label:SetPoint("BOTTOM", btn, "BOTTOM", 0, 4)
    label:SetJustifyH("CENTER")
    label:SetText(style and style.name or styleKey)
    btn.label = label

    -- selected: gold frame + gold name
    btn.selected = CreateFrame("Frame", nil, btn)
    btn.selected:SetWidth(width + 4)
    btn.selected:SetHeight(height + 4)
    btn.selected:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.selected:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    btn.selected:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
    btn.selected:Hide()

    btn:SetScript("OnClick", function()
        FlyTimesDB.barStyle = styleKey
        local frame = FTT.timerFrame or getglobal("FlyTimesFrame")
        if FTT.BarStyles and frame then
            FTT.BarStyles:ApplyStyle(styleKey, frame)
        end
        FTT.Options_UpdateSelection()
    end)
    btn:SetScript("OnEnter", function()
        if not btn.isSelected then label:SetTextColor(GOLD[1], GOLD[2], GOLD[3]) end
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        if style then
            GameTooltip:SetText(style.name, 1, 0.82, 0)
            GameTooltip:AddLine(style.description or "", 1, 1, 1, 1)
        else
            GameTooltip:SetText(styleKey, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        if not btn.isSelected then label:SetTextColor(TEXT[1], TEXT[2], TEXT[3]) end
        GameTooltip:Hide()
    end)
    return btn
end

-- =====================================================
--  MOVING BY HAND (StartMoving snaps back on this client)
-- =====================================================

local drag

local function cursorScale(f, cx, cy)
    local ok, s = pcall(UIParent.GetEffectiveScale, UIParent)
    if not ok or not s or s <= 0 then s = 1 end
    local l, r, t, b = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
    if l and r and t and b then
        local cands = { s, 1 }
        for i = 1, 2 do
            local x, y = cx / cands[i], cy / cands[i]
            if x >= l - 4 and x <= r + 4 and y >= b - 4 and y <= t + 4 then return cands[i] end
        end
    end
    return s
end

local function place(f, x, y)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

local function startDrag(f)
    if not GetCursorPosition then return end
    local cx, cy = GetCursorPosition()
    if not cx then return end
    local x, y = f:GetCenter()
    local ux, uy = UIParent:GetCenter()
    drag = { f = f, sx = cx, sy = cy, x = (x or 0) - (ux or 0), y = (y or 0) - (uy or 0), s = cursorScale(f, cx, cy) }
end

local function updateDrag()
    if not drag then return end
    local cx, cy = GetCursorPosition()
    if not cx then return end
    drag.cx = drag.x + (cx - drag.sx) / drag.s
    drag.cy = drag.y + (cy - drag.sy) / drag.s
    place(drag.f, drag.cx, drag.cy)
end

local function stopDrag()
    if not drag then return end
    place(drag.f, math.floor((drag.cx or drag.x) + 0.5), math.floor((drag.cy or drag.y) + 0.5))
    drag = nil
end

-- =====================================================
--  NAVIGATION
-- =====================================================

local function showPage(key)
    for k, p in pairs(pages) do
        if k == key then p:Show() else p:Hide() end
    end
    for k, item in pairs(navItems) do
        local on = (k == key)
        if on then
            item.label:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
            item.accent:Show()
            item.bg:Show()
        else
            item.label:SetTextColor(TEXT[1], TEXT[2], TEXT[3])
            item.accent:Hide()
            item.bg:Hide()
        end
        item.on = on
    end
    if key == "styles" then FTT.Options_UpdateSelection() end
end

local function navItem(nav, key, label, index)
    local b = CreateFrame("Button", nil, nav)
    b:SetWidth(NAV_W - 12)
    b:SetHeight(26)
    b:SetPoint("TOPLEFT", nav, "TOPLEFT", 6, -10 - (index - 1) * 28)
    b.bg = rect(b, "BACKGROUND", "TOPLEFT", b, "TOPLEFT", 0, 0, NAV_W - 12, 26, 1, 0.78, 0.1, 0.08)
    b.accent = rect(b, "ARTWORK", "TOPLEFT", b, "TOPLEFT", 0, 0, 3, 26, GOLD[1], GOLD[2], GOLD[3], 1)
    b.label = text(b, 13, TEXT)
    b.label:SetPoint("LEFT", b, "LEFT", 14, 0)
    b.label:SetText(label)
    b:SetScript("OnClick", function() showPage(key) end)
    b:SetScript("OnEnter", function() if not b.on then b.label:SetTextColor(1, 1, 1) end end)
    b:SetScript("OnLeave", function() if not b.on then b.label:SetTextColor(TEXT[1], TEXT[2], TEXT[3]) end end)
    navItems[key] = b
    return b
end

-- =====================================================
--  BUILD OPTIONS FRAME
-- =====================================================

local function BuildOptionsFrame()
    if optionsFrame then return end

    local f = CreateFrame("Frame", "FlyTimesOptionsFrame", UIParent)
    f:SetWidth(W)
    f:SetHeight(H)
    place(f, 0, 0)
    panel(f, 0.07, 0.085, 0.1, 0.97, 0.28, 0.32, 0.36)
    f:EnableMouse(true)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetScript("OnHide", stopDrag)
    f:Hide()
    table.insert(UISpecialFrames, "FlyTimesOptionsFrame") -- Esc closes it

    -- header (drag handle): addon name + version, like "Unreal UI v0.12.0"
    local head = CreateFrame("Button", nil, f)
    head:SetWidth(W - 16)
    head:SetHeight(HEAD_H - 8)
    head:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
    head:SetScript("OnMouseDown", function()
        if drag then stopDrag() return end -- release got lost: next press drops
        startDrag(f)
    end)
    head:SetScript("OnMouseUp", stopDrag)
    head:SetScript("OnUpdate", updateDrag)

    local icon = head:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\FlyTimes\\gryphon2")
    icon:SetWidth(26)
    icon:SetHeight(26)
    icon:SetPoint("LEFT", head, "LEFT", 6, 0)

    local title = text(head, 18, { 1, 1, 1 })
    title:SetPoint("LEFT", head, "LEFT", 40, 0)
    title:SetText("FlyTimes")
    local ver = text(head, 14, MUTED)
    ver:SetPoint("LEFT", title, "RIGHT", 8, -1)
    ver:SetText("v" .. (FTT.VERSION or "?"))
    local author = text(head, 11, MUTED)
    author:SetPoint("RIGHT", head, "RIGHT", -8, 0)
    author:SetJustifyH("RIGHT")
    author:SetText((L["OPT_AUTHOR"] or "Author") .. ": " .. (FTT.AUTHOR or "?"))

    rect(f, "ARTWORK", "TOPLEFT", f, "TOPLEFT", 6, -HEAD_H, W - 12, 1, 0.28, 0.32, 0.36, 1)

    -- sidebar
    local nav = CreateFrame("Frame", nil, f)
    nav:SetWidth(NAV_W)
    nav:SetHeight(H - HEAD_H - FOOT_H)
    nav:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -HEAD_H - 1)
    rect(nav, "BACKGROUND", "TOPLEFT", nav, "TOPLEFT", 0, 0, NAV_W, H - HEAD_H - FOOT_H, 0.035, 0.045, 0.055, 0.9)
    rect(nav, "ARTWORK", "TOPRIGHT", nav, "TOPRIGHT", 0, 0, 1, H - HEAD_H - FOOT_H, 0.28, 0.32, 0.36, 1)
    navItem(nav, "general", L["OPTIONS_TAB_GENERAL"] or "General", 1)
    navItem(nav, "styles", L["OPT_STYLE_LABEL"] or "Bar style", 2)

    -- pages (one anchor + size)
    local function newPage(key)
        local p = CreateFrame("Frame", nil, f)
        p:SetWidth(PAGE_W)
        p:SetHeight(PAGE_H)
        p:SetPoint("TOPLEFT", f, "TOPLEFT", NAV_W + 12, -HEAD_H - 6)
        p:Hide()
        pages[key] = p
        return p
    end

    -- ---------------- General ----------------
    local g = newPage("general")
    sectionHeader(g, -6, L["OPT_HEADER_GENERAL"] or "General Options")

    generalChecks.enabled = CreateCheckbox(g, 18, -36, L["OPT_ENABLE"] or "Enable addon", function()
        FlyTimesDB.enabled = this:GetChecked() and true or false
    end)
    generalChecks.learning = CreateCheckbox(g, 18, -62, L["OPT_LEARNING"] or "Auto-learning (measure flight times)", function()
        FlyTimesDB.learningEnabled = this:GetChecked() and true or false
    end)
    generalChecks.estimate = CreateCheckbox(g, 18, -88, L["OPT_ESTIMATE"] or "Show chat estimate messages", function()
        FlyTimesDB.showEstimate = this:GetChecked() and true or false
    end)

    sectionHeader(g, -128, L["OPT_HEADER_APPEARANCE"] or "Appearance")

    local resetBtn = CreateButton(g, L["OPT_RESET_POS"] or "Reset bar position", 190,
        "TOPLEFT", g, "TOPLEFT", 18, -160, function()
            local frame = FTT.timerFrame or getglobal("FlyTimesFrame")
            if frame then
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
            end
            FlyTimesDB.posX = 0
            FlyTimesDB.posY = 200
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00FlyTimes:|r " .. (L["POSITION_RESET"] or "Position reset"))
        end)
    CreateButton(g, L["OPT_CLEAR_MEASURED"] or "Clear measured data", 190,
        "LEFT", resetBtn, "RIGHT", 10, 0, function() FTT.ClearMeasured() end)

    local hint = text(g, 11, MUTED)
    hint:SetPoint("TOPLEFT", g, "TOPLEFT", 18, -198)
    hint:SetWidth(PAGE_W - 40)
    hint:SetText(L["OPT_CMD_HINT"] or "All settings are also available via /ft commands.")

    -- ---------------- Bar style ----------------
    local s = newPage("styles")
    sectionHeader(s, -6, L["OPT_STYLE_LABEL"] or "Bar style")
    local sh = text(s, 11, MUTED)
    sh:SetPoint("TOPLEFT", s, "TOPLEFT", 16, -32)
    sh:SetText(L["OPT_STYLE_CLICK"] or "Click a style below to preview and apply")

    local styleOrder = {
        "classic", "minimalist", "modern", "glass", "fantasy",
        "neon", "cyberpunk", "glowing", "retro", "dragonball",
    }
    local bw, bh, gap = 74, 54, 8
    for index, key in ipairs(styleOrder) do
        local col = (index - 1) - math.floor((index - 1) / 5) * 5
        local row = math.floor((index - 1) / 5)
        styleButtons[key] = CreateStylePreviewButton(s, key,
            16 + col * (bw + gap), -54 - row * (bh + gap), bw, bh)
    end

    -- footer
    rect(f, "ARTWORK", "BOTTOMLEFT", f, "BOTTOMLEFT", 6, FOOT_H, W - 12, 1, 0.28, 0.32, 0.36, 1)
    CreateButton(f, L["OPT_CLOSE"] or "Close", 110, "BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 10,
        function() f:Hide() end)

    optionsFrame = f
    showPage("general")
end

-- =====================================================
--  UPDATE STATE
-- =====================================================

function FTT.Options_UpdateSelection()
    if not optionsFrame then return end

    if generalChecks.enabled then generalChecks.enabled:SetChecked(FlyTimesDB.enabled) end
    if generalChecks.learning then generalChecks.learning:SetChecked(FlyTimesDB.learningEnabled) end
    if generalChecks.estimate then generalChecks.estimate:SetChecked(FlyTimesDB.showEstimate) end

    for key, btn in pairs(styleButtons) do
        local on = (key == FlyTimesDB.barStyle)
        btn.isSelected = on
        if on then
            btn.selected:Show()
            btn.label:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
        else
            btn.selected:Hide()
            btn.label:SetTextColor(TEXT[1], TEXT[2], TEXT[3])
        end
    end
end

-- =====================================================
--  TOGGLE OPTIONS PANEL
-- =====================================================

function FTT.Options_Toggle()
    if not optionsFrame then BuildOptionsFrame() end
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        FTT.Options_UpdateSelection()
        optionsFrame:Show()
    end
end

-- =====================================================
--  BUILD AFTER ADDON_LOADED (BarStyles must be loaded)
-- =====================================================

local evFrame = CreateFrame("Frame")
evFrame:RegisterEvent("ADDON_LOADED")
evFrame:SetScript("OnEvent", function()
    if arg1 == "FlyTimes" then
        local delay = CreateFrame("Frame")
        local t = 0
        delay:SetScript("OnUpdate", function()
            t = t + (arg1 or 0)
            if t > 0.1 then
                delay:SetScript("OnUpdate", nil)
                BuildOptionsFrame()
            end
        end)
    end
end)
