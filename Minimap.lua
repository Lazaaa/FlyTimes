-- FlyTimes Minimap Button
-- Left-click: open settings
-- Drag: move icon around the minimap (no Ctrl needed — same method as oneclick-heal)
-- Right-click: open settings (alternate)

FlyTimes = FlyTimes or {}
local FTT = FlyTimes
local L = FTT.L or {}

local BUTTON_SIZE = 31
local ICON_TEXTURE = "Interface\\AddOns\\FlyTimes\\FlyTimes"

-- =====================================================
--  CREATE MINIMAP BUTTON  (oneclick-heal style)
-- =====================================================

local minimapButton = CreateFrame("Button", "FlyTimesMinimapButton", Minimap)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:SetWidth(BUTTON_SIZE)
minimapButton:SetHeight(BUTTON_SIZE)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Circular background (vanilla tracking border)
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetWidth(54)
border:SetHeight(54)
border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT")

-- Icon (the owl/clock mask)
local icon = minimapButton:CreateTexture(nil, "ARTWORK")
icon:SetTexture(ICON_TEXTURE)
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- =====================================================
--  POSITIONING (angle-based, like oneclick-heal)
-- =====================================================

local angle = (FlyTimesDB and FlyTimesDB.minimapAngle) or 210

local atan2 = math.atan2 or function(y, x)
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + math.pi end
    return (y >= 0) and (math.pi / 2) or -(math.pi / 2)
end

local function place()
    local mw = Minimap:GetWidth()  or 160
    local mh = Minimap:GetHeight() or mw
    local R  = mw / 2 + 5
    local a  = math.rad(angle)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT",
        mw / 2 + math.cos(a) * R - 15,
        -mh / 2 + math.sin(a) * R + 15)
end

-- =====================================================
--  DRAG HANDLER  (cursor-delta -> angle, oneclick-heal style)
-- =====================================================

local dragging, moved = false, false
local lastCX, lastCY, baseCX, baseCY
local vx = math.cos(math.rad(angle)) * 80
local vy = math.sin(math.rad(angle)) * 80

minimapButton:SetScript("OnMouseDown", function()
    dragging, moved = true, false
    local cx, cy
    if GetCursorPosition then cx, cy = GetCursorPosition() end
    lastCX, lastCY = cx, cy
    baseCX, baseCY = cx, cy
end)

minimapButton:SetScript("OnMouseUp", function()
    if not dragging then return end
    dragging = false
    lastCX, lastCY = nil, nil
    if moved then
        FlyTimesDB.minimapAngle = angle
        place()
    end
end)

minimapButton:SetScript("OnUpdate", function()
    if not dragging or not GetCursorPosition then return end
    local cx, cy = GetCursorPosition()
    if not cx then return end
    if lastCX then
        vx = vx + (cx - lastCX)
        vy = vy + (cy - lastCY)
        if baseCX and math.abs(cx - baseCX) + math.abs(cy - baseCY) > 8 then
            moved = true
        end
    end
    lastCX, lastCY = cx, cy
    if moved and (vx ~= 0 or vy ~= 0) then
        local a2 = math.deg(atan2(vy, vx))
        if a2 < 0 then a2 = a2 + 360 end
        angle = a2
        place()
    end
end)

-- =====================================================
--  CLICK HANDLER
-- =====================================================

minimapButton:SetScript("OnClick", function(a, b)
    -- If the mouse moved, this was a drag, not a click.
    if moved then moved = false; return end

    -- Robust button resolution (arg1 fallback for older clients)
    local btn = a
    if type(btn) ~= "string" then btn = b end
    if type(btn) ~= "string" then btn = arg1 end
    if type(btn) ~= "string" then btn = "LeftButton" end

    if btn == "LeftButton" then
        if FTT.Options_Toggle then FTT.Options_Toggle() end
    elseif btn == "RightButton" then
        -- Alternate: also open settings on right-click
        if FTT.Options_Toggle then FTT.Options_Toggle() end
    end
end)

-- =====================================================
--  TOOLTIP
-- =====================================================

minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
    GameTooltip:SetText(L["MINIMAP_TOOLTIP_TITLE"] or "FlyTimes Settings", 1, 0.82, 0)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_LEFTCLICK"] or "Left-click to open the settings.", 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_DRAG"]      or "Drag to move the icon around the minimap.", 1, 1, 1)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- =====================================================
--  VISIBILITY
-- =====================================================

local function UpdateVisibility()
    if FlyTimesDB and FlyTimesDB.minimapHidden then
        minimapButton:Hide()
    else
        minimapButton:Show()
    end
end

FTT.UpdateMinimapVisibility = UpdateVisibility
FTT.MinimapButton = minimapButton
FTT.MinimapPlace  = place   -- expose for /reset commands

-- Initial placement
place()

-- Hook into ADDON_LOADED for early visibility update
local evFrame = CreateFrame("Frame")
evFrame:RegisterEvent("ADDON_LOADED")
evFrame:SetScript("OnEvent", function()
    if arg1 == "FlyTimes" then
        UpdateVisibility()
        -- re-read angle after DB load (in case FlyTimesDB wasn't ready yet)
        if FlyTimesDB and FlyTimesDB.minimapAngle then
            angle = FlyTimesDB.minimapAngle
            vx = math.cos(math.rad(angle)) * 80
            vy = math.sin(math.rad(angle)) * 80
        end
        place()
    end
end)
