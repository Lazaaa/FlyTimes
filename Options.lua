-- FlyTimes Options Panel
-- Classic WoW style with live style previews

FlyTimes = FlyTimes or {}
local FTT = FlyTimes
local L = FTT.L or {}

local optionsFrame = nil
local styleButtons = {}
local generalChecks = {}

-- =====================================================
--  CHECKBOX HELPER
-- =====================================================

local function CreateCheckbox(parent, x, y, labelText, onClickFunc)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(24)
    cb:SetHeight(24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetScript("OnClick", onClickFunc)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    label:SetText(labelText)
    label:SetTextColor(0.9, 0.9, 0.9)
    label:SetJustifyH("LEFT")

    return cb, label
end

-- =====================================================
--  STYLE PREVIEW BUTTON
-- =====================================================

local function CreateStylePreviewButton(parent, styleKey, x, y, width, height)
    -- Height reserved for the style name label at the bottom
    local LABEL_HEIGHT = 16

    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    -- Outer dark background (button frame)
    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetTexture(0.05, 0.05, 0.05, 0.9)

    -- Inner area (mini bar background)
    local inner = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
    inner:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    inner:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    inner:SetTexture(0.15, 0.15, 0.15, 0.9)

    -- Mini progress bar, only fills the TOP part of the button
    local bar = CreateFrame("StatusBar", nil, btn)
    bar:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
    bar:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -3)
    bar:SetHeight(height - LABEL_HEIGHT - 6)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(70)

    -- Style name at the BOTTOM of the button
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
    label:SetTextColor(1, 1, 1)
    label:SetShadowOffset(1, -1)
    label:SetShadowColor(0, 0, 0, 1)

    -- Selection overlay (shown when this is the current style)
    btn.selected = btn:CreateTexture(nil, "OVERLAY")
    btn.selected:SetAllPoints(btn)
    btn.selected:SetTexture(1, 0.82, 0, 0.5)
    btn.selected:Hide()

    -- Hover highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(btn)
    highlight:SetTexture(1, 0.82, 0, 0.3)

    -- Apply the style's colors to the preview
    local style = FTT.BarStyles and FTT.BarStyles.styles and FTT.BarStyles.styles[styleKey]
    if style then
        bar:SetStatusBarColor(style.barColor[1], style.barColor[2], style.barColor[3])
        if style.barBgColor then
            inner:SetTexture(style.barBgColor[1], style.barBgColor[2], style.barBgColor[3], style.barBgColor[4] or 1)
        end
        label:SetText(style.name or styleKey)
    else
        label:SetText(styleKey)
    end

    -- On click: apply the style
    btn:SetScript("OnClick", function()
        FlyTimesDB.barStyle = styleKey
        local frame = FTT.timerFrame or _G["FlyTimesFrame"]
        if FTT.BarStyles and frame then
            FTT.BarStyles:ApplyStyle(styleKey, frame)
        end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r " ..
            (L["STYLE_CHANGED"] or "Bar style changed to %s"),
            L["ADDON_NAME"] or "FlyTimes", styleKey))
        FTT.Options_UpdateSelection()
    end)

    -- Tooltip with style name and description
    btn:SetScript("OnEnter", function()
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
        GameTooltip:Hide()
    end)

    return btn
end

-- =====================================================
--  TAB HELPER
-- =====================================================

local function CreateTab(parent, labelText, width, anchorTo, anchorPoint, xOffset)
    local tab = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    tab:SetWidth(width)
    tab:SetHeight(22)
    if anchorTo then
        tab:SetPoint(anchorPoint, anchorTo, "RIGHT", xOffset or 2, 0)
    else
        tab:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -32)
    end
    tab:SetText(labelText)

    return tab
end

-- =====================================================
--  BUILD OPTIONS FRAME
-- =====================================================

local function BuildOptionsFrame()
    if optionsFrame then return end

    local f = CreateFrame("Frame", "FlyTimesOptionsFrame", UIParent)
    f:SetWidth(520)
    f:SetHeight(350)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    f:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    f:Hide()

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText(L["OPTIONS_TITLE"] or "FlyTimes - Settings")
    title:SetTextColor(1, 0.82, 0)

    -- Author / Version
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -2)
    sub:SetText(string.format("%s: %s | %s: %s",
        L["OPT_AUTHOR"] or "Author", FTT.AUTHOR or "?",
        L["OPT_VERSION"] or "Version", FTT.VERSION or "?"))
    sub:SetTextColor(0.6, 0.6, 0.6)

    -- Tabs
    local generalTab = CreateTab(f, L["OPTIONS_TAB_GENERAL"] or "General", 90, nil, nil, 0)
    local stylesTab = CreateTab(f, L["OPTIONS_TAB_STYLES"] or "Styles", 90, generalTab, "LEFT", 4)

    -- Content frames
    local generalContent = CreateFrame("Frame", nil, f)
    generalContent:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -62)
    generalContent:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 44)

    local stylesContent = CreateFrame("Frame", nil, f)
    stylesContent:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -62)
    stylesContent:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 44)
    stylesContent:Hide()

    f.generalContent = generalContent
    f.stylesContent = stylesContent

    -- Tab click handlers
    generalTab:SetScript("OnClick", function()
        generalContent:Show()
        stylesContent:Hide()
    end)
    stylesTab:SetScript("OnClick", function()
        generalContent:Hide()
        stylesContent:Show()
        FTT.Options_UpdateSelection()
    end)

    -- =====================================================
    --  GENERAL TAB CONTENT
    -- =====================================================

    local generalHeader = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    generalHeader:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 16, -8)
    generalHeader:SetText(L["OPT_HEADER_GENERAL"] or "General Options")
    generalHeader:SetTextColor(1, 0.82, 0)

    -- Checkboxes
    local cb1 = CreateCheckbox(generalContent, 20, -34,
        L["OPT_ENABLE"] or "Enable addon",
        function()
            FlyTimesDB.enabled = this:GetChecked() and true or false
        end)
    generalChecks.enabled = cb1

    local cb2 = CreateCheckbox(generalContent, 20, -62,
        L["OPT_LEARNING"] or "Auto-learning (measure flight times)",
        function()
            FlyTimesDB.learningEnabled = this:GetChecked() and true or false
        end)
    generalChecks.learning = cb2

    local cb3 = CreateCheckbox(generalContent, 20, -90,
        L["OPT_ESTIMATE"] or "Show chat estimate messages",
        function()
            FlyTimesDB.showEstimate = this:GetChecked() and true or false
        end)
    generalChecks.estimate = cb3

    -- Appearance section header
    local appHeader = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    appHeader:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 16, -130)
    appHeader:SetText(L["OPT_HEADER_APPEARANCE"] or "Appearance")
    appHeader:SetTextColor(1, 0.82, 0)

    -- Reset position button
    local resetPosBtn = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
    resetPosBtn:SetWidth(220)
    resetPosBtn:SetHeight(24)
    resetPosBtn:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 20, -158)
    resetPosBtn:SetText(L["OPT_RESET_POS"] or "Reset bar position")
    resetPosBtn:SetScript("OnClick", function()
        local frame = FTT.timerFrame or _G["FlyTimesFrame"]
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        end
        FlyTimesDB.posX = 0
        FlyTimesDB.posY = 200
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00FlyTimes:|r " .. (L["POSITION_RESET"] or "Position reset"))
    end)

    -- Clear measured data button (directly below the reset button)
    local clearBtn = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
    clearBtn:SetWidth(220)
    clearBtn:SetHeight(24)
    clearBtn:SetPoint("TOPLEFT", resetPosBtn, "BOTTOMLEFT", 0, -8)
    clearBtn:SetText(L["OPT_CLEAR_MEASURED"] or "Clear measured data")
    clearBtn:SetScript("OnClick", function()
        local count = 0
        for _ in pairs(FlyTimesDB.measured or {}) do count = count + 1 end
        FlyTimesDB.measured = {}
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00FlyTimes:|r " ..
            (L["MEASURED_ROUTES_CLEARED"] or "Cleared %d measured routes"), count))
    end)

    -- Command hint (directly below the two buttons)
    local hint = generalContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", clearBtn, "BOTTOMLEFT", 0, -10)
    hint:SetText(L["OPT_CMD_HINT"] or "All settings are also available via /ft commands.")
    hint:SetTextColor(0.6, 0.6, 0.6)
    hint:SetWidth(480)
    hint:SetJustifyH("LEFT")

    -- =====================================================
    --  STYLES TAB CONTENT
    -- =====================================================

    local stylesHeader = stylesContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stylesHeader:SetPoint("TOPLEFT", stylesContent, "TOPLEFT", 16, -8)
    stylesHeader:SetText(L["OPT_STYLE_LABEL"] or "Bar style")
    stylesHeader:SetTextColor(1, 0.82, 0)

    local stylesHint = stylesContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stylesHint:SetPoint("TOPLEFT", stylesContent, "TOPLEFT", 16, -26)
    stylesHint:SetText(L["OPT_STYLE_CLICK"] or "Click a style below to preview and apply")
    stylesHint:SetTextColor(0.6, 0.6, 0.6)

    -- Style preview grid: 5 columns x 2 rows = 10 styles
    local styleOrder = {
        "classic", "minimalist", "modern", "glass", "fantasy",
        "neon", "cyberpunk", "glowing", "retro", "dragonball",
    }

    local buttonW = 84
    local buttonH = 56
    local spacingX = 6
    local spacingY = 8
    local startX = 16
    local startY = -48

    for index, key in ipairs(styleOrder) do
        local col = (index - 1) % 5
        local row = math.floor((index - 1) / 5)
        local x = startX + col * (buttonW + spacingX)
        local y = startY - row * (buttonH + spacingY)

        local btn = CreateStylePreviewButton(stylesContent, key, x, y, buttonW, buttonH)
        styleButtons[key] = btn
    end

    -- =====================================================
    --  CLOSE BUTTON (bottom, always visible on both tabs)
    -- =====================================================

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetWidth(100)
    closeBtn:SetHeight(24)
    closeBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    closeBtn:SetText(L["OPT_CLOSE"] or "Close")
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)

    optionsFrame = f
end

-- =====================================================
--  UPDATE SELECTION HIGHLIGHT
-- =====================================================

function FTT.Options_UpdateSelection()
    if not optionsFrame then return end

    -- Update checkbox states
    if generalChecks.enabled then
        generalChecks.enabled:SetChecked(FlyTimesDB.enabled and true or false)
    end
    if generalChecks.learning then
        generalChecks.learning:SetChecked(FlyTimesDB.learningEnabled and true or false)
    end
    if generalChecks.estimate then
        generalChecks.estimate:SetChecked(FlyTimesDB.showEstimate and true or false)
    end

    -- Highlight the currently active style
    for key, btn in pairs(styleButtons) do
        if key == FlyTimesDB.barStyle then
            btn.selected:Show()
        else
            btn.selected:Hide()
        end
    end
end

-- =====================================================
--  TOGGLE OPTIONS PANEL
-- =====================================================

function FTT.Options_Toggle()
    if not optionsFrame then
        BuildOptionsFrame()
    end

    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        FTT.Options_UpdateSelection()
        optionsFrame:Show()
    end
end

-- =====================================================
--  HOOK INTO ADDON_LOADED
-- =====================================================

local evFrame = CreateFrame("Frame")
evFrame:RegisterEvent("ADDON_LOADED")
evFrame:SetScript("OnEvent", function()
    if arg1 == "FlyTimes" then
        -- Delay build until BarStyles is fully loaded
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