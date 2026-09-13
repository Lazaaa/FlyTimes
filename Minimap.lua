-- FlyTimes Minimap Button
-- Left-click: open settings
-- Ctrl+Left-drag: move icon around minimap
-- Ctrl+Right-click: reset icon position

FlyTimes = FlyTimes or {}
local FTT = FlyTimes
local L = FTT.L or {}

local BUTTON_SIZE = 32
local ICON_TEXTURE = "Interface\\Icons\\INV_Misc_PocketWatch_02"

-- =====================================================
--  CREATE MINIMAP BUTTON
-- =====================================================

local minimapButton = CreateFrame("Button", "FlyTimesMinimapButton", Minimap)
minimapButton:SetWidth(BUTTON_SIZE)
minimapButton:SetHeight(BUTTON_SIZE)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:EnableMouse(true)
minimapButton:SetMovable(true)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton")

-- Circular background (vanilla minimap background)
minimapButton.bg = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapButton.bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
minimapButton.bg:SetWidth(BUTTON_SIZE + 8)
minimapButton.bg:SetHeight(BUTTON_SIZE + 8)
minimapButton.bg:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)

-- Icon
minimapButton.icon = minimapButton:CreateTexture(nil, "ARTWORK")
minimapButton.icon:SetTexture(ICON_TEXTURE)
minimapButton.icon:SetWidth(20)
minimapButton.icon:SetHeight(20)
minimapButton.icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- Highlight (on hover)
minimapButton.highlight = minimapButton:CreateTexture(nil, "HIGHLIGHT")
minimapButton.highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapButton.highlight:SetWidth(BUTTON_SIZE + 8)
minimapButton.highlight:SetHeight(BUTTON_SIZE + 8)
minimapButton.highlight:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapButton.highlight:SetBlendMode("ADD")

-- =====================================================
--  POSITIONING (radius/angle system, like other minimap addons)
-- =====================================================

local function UpdatePosition()
    local angle = FlyTimesDB.minimapAngle or 220
    local radius = FlyTimesDB.minimapRadius or 80

    local x = math.cos(math.rad(angle)) * radius
    local y = math.sin(math.rad(angle)) * radius

    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

UpdatePosition()

-- =====================================================
--  DRAG HANDLER (Ctrl+Left-drag)
-- =====================================================

local function OnDragStart()
    if IsControlKeyDown() then
        minimapButton:SetScript("OnUpdate", function()
            -- Get minimap center and cursor position
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale

            -- Convert to polar coordinates
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            local radius = math.sqrt((cx - mx) ^ 2 + (cy - my) ^ 2)

            -- Clamp radius to keep the button near the minimap
            if radius < 60 then radius = 60 end
            if radius > 120 then radius = 120 end

            FlyTimesDB.minimapAngle = angle
            FlyTimesDB.minimapRadius = radius

            UpdatePosition()
        end)
    end
end

local function OnDragStop()
    minimapButton:SetScript("OnUpdate", nil)
end

minimapButton:SetScript("OnDragStart", OnDragStart)
minimapButton:SetScript("OnDragStop", OnDragStop)

-- =====================================================
--  CLICK HANDLER
-- =====================================================

minimapButton:SetScript("OnClick", function()
    if arg1 == "LeftButton" then
        -- Left click (with or without Ctrl) opens the settings panel
        if FTT.Options_Toggle then
            FTT.Options_Toggle()
        end
    elseif arg1 == "RightButton" and IsControlKeyDown() then
        -- Ctrl+Right-click: reset icon position
        FlyTimesDB.minimapAngle = 220
        FlyTimesDB.minimapRadius = 80
        UpdatePosition()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00FlyTimes:|r Minimap icon position reset.")
    end
end)

-- =====================================================
--  TOOLTIP
-- =====================================================

minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
    GameTooltip:SetText(L["MINIMAP_TOOLTIP_TITLE"] or "FlyTimes Settings", 1, 0.82, 0)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_LEFTCLICK"] or "Left-click to open the settings.", 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_DRAG"] or "Hold control and drag to move.", 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_RESET"] or "Hold control and right-click to reset position.", 1, 1, 1)
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

-- Hook into ADDON_LOADED for early visibility update
local evFrame = CreateFrame("Frame")
evFrame:RegisterEvent("ADDON_LOADED")
evFrame:SetScript("OnEvent", function()
    if arg1 == "FlyTimes" then
        UpdateVisibility()
    end
end)