-- FlyTimes Core
-- Shows a progress bar during flight paths
-- Emberveil (1.12.1) compatible
-- With auto-learning flight time measurement

FlyTimes = FlyTimes or {}
local FTT = FlyTimes
local L = FTT.L or {}

-- =====================================================
--  SAVED VARIABLES
-- =====================================================

local function InitDB()
    if not FlyTimesDB then
        FlyTimesDB = {
            enabled = true,
            showEstimate = true,
            barWidth = 300,
            barHeight = 30,
            posX = 0,
            posY = 200,
            barStyle = "classic",
            learningEnabled = true,
            measured = {},
        }
    end
    if not FlyTimesDB.measured then
        FlyTimesDB.measured = {}
    end
    if FlyTimesDB.learningEnabled == nil then
        FlyTimesDB.learningEnabled = true
    end
end

InitDB()

-- Local variables
local flightStartTime = nil
local flightDuration = nil
local sourceNode = nil
local destNode = nil
local updateTimer = 0
local lastStartTime = 0

-- Measurement tracking
local measureStartTime = nil
local measureFrom = nil
local measureTo = nil
local measureActive = false

-- =====================================================
--  VERSION & FACTION
-- =====================================================

local function GetGameVersion()
    local _, _, _, tocversion = GetBuildInfo()
    if not tocversion then return "CLASSIC" end
    if tocversion >= 110000 then return "RETAIL"
    elseif tocversion >= 100000 then return "RETAIL"
    else return "CLASSIC" end
end

local function GetPlayerFaction()
    return UnitFactionGroup("player")
end

-- =====================================================
--  MEASUREMENT SYSTEM
-- =====================================================

local function GetMeasurementKey(fromName, toName)
    -- Strip the zone part (everything after the comma)
    local fromShort = string.gsub(fromName, "(%,.*)", "")
    local toShort = string.gsub(toName, "(%,.*)", "")
    return fromShort .. "_to_" .. toShort
end

local function GetMeasuredTime(fromName, toName)
    if not FlyTimesDB.measured then return nil end

    local key = GetMeasurementKey(fromName, toName)
    local entry = FlyTimesDB.measured[key]

    -- At least 2 measurements required before using average
    if not entry or entry.count < 2 then
        return nil
    end

    return entry.total / entry.count
end

local function SaveMeasurement(fromName, toName, seconds)
    -- Sanity check: only save measurements between 5 sec and 30 min
    if not seconds or seconds < 5 or seconds > 1800 then
        return false
    end

    if not FlyTimesDB.measured then FlyTimesDB.measured = {} end

    local key = GetMeasurementKey(fromName, toName)
    local entry = FlyTimesDB.measured[key]

    if not entry then
        entry = { total = 0, count = 0, last = 0, min = seconds, max = seconds }
        FlyTimesDB.measured[key] = entry
    end

    entry.total = entry.total + seconds
    entry.count = entry.count + 1
    entry.last = seconds
    if seconds < entry.min then entry.min = seconds end
    if seconds > entry.max then entry.max = seconds end

    return true, entry
end

-- =====================================================
--  FLIGHT TIME LOOKUP (measurements first, then static DB)
-- =====================================================

function FTT:GetFlightTime(fromName, toName)
    -- 1. First check our own measurements
    local measured = GetMeasuredTime(fromName, toName)
    if measured then
        return measured
    end

    -- 2. Fall back to the static database
    local version = GetGameVersion()
    local faction = GetPlayerFaction()

    if not self.FlightDB or not self.FlightDB[version] then
        return nil
    end

    local versionDB = self.FlightDB[version]
    if not versionDB[faction] then
        return nil
    end

    -- 2a. Exact match
    if versionDB[faction][fromName] and versionDB[faction][fromName][toName] then
        return versionDB[faction][fromName][toName]
    end

    -- 2b. Reverse exact match
    if versionDB[faction][toName] and versionDB[faction][toName][fromName] then
        return versionDB[faction][toName][fromName]
    end

    -- 2c. Fuzzy match (partial name)
    local fromKey, toKey
    for k, v in pairs(versionDB[faction]) do
        if not fromKey and string.find(k, fromName, 1, true) then
            fromKey = k
        end
        if not toKey and string.find(k, toName, 1, true) then
            toKey = k
        end
    end

    if fromKey and toKey then
        if versionDB[faction][fromKey] and versionDB[faction][fromKey][toKey] then
            return versionDB[faction][fromKey][toKey]
        end
        if versionDB[faction][toKey] and versionDB[faction][toKey][fromKey] then
            return versionDB[faction][toKey][fromKey]
        end
    end

    return nil
end

-- =====================================================
--  CREATE TIMER FRAME
-- =====================================================

local timerFrame = CreateFrame("Frame", "FlyTimesFrame", UIParent)
timerFrame:SetWidth(300)
timerFrame:SetHeight(30)
timerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
timerFrame:Hide()

timerFrame:SetMovable(true)
timerFrame:EnableMouse(true)
timerFrame:RegisterForDrag("LeftButton")

timerFrame:SetScript("OnDragStart", function()
    this:StartMoving()
end)

timerFrame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, _, x, y = this:GetPoint()
    FlyTimesDB.posX = x
    FlyTimesDB.posY = y
end)

-- Background
timerFrame.bg = timerFrame:CreateTexture(nil, "BACKGROUND")
timerFrame.bg:SetAllPoints()
timerFrame.bg:SetTexture(0, 0, 0, 0.8)

-- Border
timerFrame.border = timerFrame:CreateTexture(nil, "BORDER")
timerFrame.border:SetTexture(0.3, 0.3, 0.3, 1)
timerFrame.border:SetPoint("TOPLEFT", 1, -1)
timerFrame.border:SetPoint("BOTTOMRIGHT", -1, 1)

-- Progress bar
timerFrame.bar = CreateFrame("StatusBar", nil, timerFrame)
timerFrame.bar:SetPoint("TOPLEFT", 4, -4)
timerFrame.bar:SetPoint("BOTTOMRIGHT", -4, 4)
timerFrame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
timerFrame.bar:SetStatusBarColor(0.2, 0.6, 1.0)
timerFrame.bar:SetMinMaxValues(0, 100)
timerFrame.bar:SetValue(0)

timerFrame.bar.bg = timerFrame.bar:CreateTexture(nil, "BACKGROUND")
timerFrame.bar.bg:SetAllPoints(timerFrame.bar)
timerFrame.bar.bg:SetTexture(0.1, 0.1, 0.1, 0.5)

-- Text overlay
timerFrame.text = timerFrame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
timerFrame.text:SetPoint("CENTER")
timerFrame.text:SetTextColor(1, 1, 1)

-- Route label (above bar)
timerFrame.routeLabel = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timerFrame.routeLabel:SetPoint("BOTTOM", timerFrame, "TOP", 0, 4)
timerFrame.routeLabel:SetTextColor(1, 1, 1)
timerFrame.routeLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

-- Learning indicator
timerFrame.learningLabel = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
timerFrame.learningLabel:SetPoint("TOP", timerFrame, "BOTTOM", 0, -4)
timerFrame.learningLabel:SetTextColor(0.5, 1, 0.5)
timerFrame.learningLabel:Hide()

-- Spark effect
timerFrame.bar.spark = timerFrame.bar:CreateTexture(nil, "OVERLAY")
timerFrame.bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
timerFrame.bar.spark:SetBlendMode("ADD")
timerFrame.bar.spark:SetWidth(20)
timerFrame.bar.spark:SetHeight(timerFrame.bar:GetHeight() * 2.5)

-- =====================================================
--  TIME FORMATTER
-- =====================================================

local function FormatTime(seconds)
    if not seconds then return "??:??" end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

-- =====================================================
--  START / STOP TIMER
-- =====================================================

function FTT:StartFlightTimer(duration, fromNode, toNode)
    if not FlyTimesDB or not FlyTimesDB.enabled then return end

    -- Duplicate-start protection: don't restart within 1 second
    local now = GetTime()
    if (now - lastStartTime) < 1 then
        return
    end
    lastStartTime = now

    flightStartTime = now
    flightDuration = duration
    sourceNode = fromNode
    destNode = toNode

    timerFrame.bar:SetMinMaxValues(0, duration)
    timerFrame.routeLabel:SetText(string.format("%s > %s", fromNode or "?", toNode or "?"))
    timerFrame:Show()

    -- Show learning indicator if we have measured data
    local measured = GetMeasuredTime(fromNode, toNode)
    if measured then
        timerFrame.learningLabel:SetText("|cff88ff88" .. (L["MEASURED_LABEL"] or "[measured]") .. "|r")
        timerFrame.learningLabel:Show()
    else
        timerFrame.learningLabel:Hide()
    end

    if FlyTimesDB.showEstimate then
        local source = measured and (L["FLIGHT_TIME_SOURCE_MEASURED"] or "measured")
                              or (L["FLIGHT_TIME_SOURCE_DB"] or "database")
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r %s (|cff808080%s|r)",
            L["ADDON_NAME"] or "FlyTimes",
            string.format(L["FLIGHT_TIME"] or "Estimated flight time: %s", FormatTime(duration)),
            source))
    end
end

function FTT:StopFlightTimer()
    flightStartTime = nil
    flightDuration = nil
    sourceNode = nil
    destNode = nil
    timerFrame:Hide()
    timerFrame.learningLabel:Hide()
end

-- =====================================================
--  ONUPDATE
-- =====================================================

timerFrame:SetScript("OnUpdate", function()
    local elapsed = arg1 or 0

    if not flightStartTime or not flightDuration then
        return
    end

    -- Throttle updates to every 0.05 seconds
    updateTimer = updateTimer + elapsed
    if updateTimer < 0.05 then return end
    updateTimer = 0

    local currentTime = GetTime()
    local elapsedTime = currentTime - flightStartTime
    local remaining = flightDuration - elapsedTime

    if remaining <= 0 then
        FTT:StopFlightTimer()
        return
    end

    this.bar:SetValue(elapsedTime)

    local percentage = (elapsedTime / flightDuration) * 100
    this.text:SetText(string.format(L["REMAINING"] or "%s remaining (%d%%)", FormatTime(remaining), percentage))

    -- Move spark along the bar
    local progress = elapsedTime / flightDuration
    local width = this.bar:GetWidth()
    this.bar.spark:SetPoint("CENTER", this.bar, "LEFT", width * progress, 0)
end)

-- =====================================================
--  HELPER: CURRENT TAXI NODE NAME
-- =====================================================

local function GetCurrentTaxiNodeName()
    if not NumTaxiNodes or not TaxiNodeGetType or not TaxiNodeName then
        return nil
    end
    local numNodes = NumTaxiNodes()
    for i = 1, numNodes do
        local nodeType = TaxiNodeGetType(i)
        -- Emberveil may return "CURRENT" or 2 depending on the client
        if nodeType == "CURRENT" or nodeType == 2 then
            return TaxiNodeName(i)
        end
    end
    return nil
end

-- =====================================================
--  HOOK: TakeTaxiNode
-- =====================================================

local originalTakeTaxiNode = TakeTaxiNode
function TakeTaxiNode(destinationSlot)
    local fromName = GetCurrentTaxiNodeName()
    local destName = TaxiNodeName and TaxiNodeName(destinationSlot)

    local result = originalTakeTaxiNode(destinationSlot)

    if fromName and destName then
        local duration = FTT:GetFlightTime(fromName, destName)
        if duration then
            FTT:StartFlightTimer(duration, fromName, destName)
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r %s",
                L["ADDON_NAME"] or "FlyTimes",
                string.format(L["ROUTE_NOT_IN_DB"] or "Route not in DB: %s -> %s", fromName, destName)))
        end

        -- Start measurement if auto-learning is enabled
        if FlyTimesDB.learningEnabled then
            measureFrom = fromName
            measureTo = destName
            measureStartTime = nil
            measureActive = false
        end
    end

    return result
end

-- =====================================================
--  FALLBACK HOOK: TaxiButton OnClick
-- =====================================================

local function HookTaxiButton(btn)
    if not btn or btn.fttHooked then return end
    btn.fttHooked = true

    local originalOnClick = btn:GetScript("OnClick")
    btn:SetScript("OnClick", function()
        local id = this:GetID()
        if id then
            local fromName = GetCurrentTaxiNodeName()
            local destName = TaxiNodeName and TaxiNodeName(id)

            if fromName and destName then
                local duration = FTT:GetFlightTime(fromName, destName)
                if duration then
                    FTT:StartFlightTimer(duration, fromName, destName)
                end

                if FlyTimesDB.learningEnabled then
                    measureFrom = fromName
                    measureTo = destName
                    measureStartTime = nil
                    measureActive = false
                end
            end
        end
        if originalOnClick then
            originalOnClick()
        end
    end)
end

local taxiHookFrame = CreateFrame("Frame")
taxiHookFrame:RegisterEvent("TAXIMAP_OPENED")
taxiHookFrame:SetScript("OnEvent", function()
    for i = 1, 20 do
        local btn = _G["TaxiButton"..i]
        if btn then HookTaxiButton(btn) end
    end
end)

-- =====================================================
--  MAIN EVENT FRAME
-- =====================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TAXIMAP_OPENED")
eventFrame:RegisterEvent("TAXIMAP_CLOSED")
eventFrame:RegisterEvent("PLAYER_CONTROL_LOST")
eventFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
eventFrame:RegisterEvent("ADDON_LOADED")

local addonLoadedShown = false

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        local addonName = arg1
        if addonName == "FlyTimes" and not addonLoadedShown then
            addonLoadedShown = true

            -- Re-init because SavedVariables may have overwritten the defaults
            InitDB()

            -- Restore timer bar size and position
            timerFrame:SetWidth(FlyTimesDB.barWidth or 300)
            timerFrame:SetHeight(FlyTimesDB.barHeight or 30)
            timerFrame:ClearAllPoints()
            timerFrame:SetPoint("CENTER", UIParent, "CENTER", FlyTimesDB.posX or 0, FlyTimesDB.posY or 200)

            -- Single "loaded" message
            local msgL = FTT.L or {}
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s|r by %s ver. %s %s",
                msgL["ADDON_NAME"] or "FlyTimes",
                FTT.AUTHOR or "Unknown",
                FTT.VERSION or "?",
                msgL["LOADED"] or "loaded! Use /ft for options."))

            -- Apply saved style
            if FlyTimesDB.barStyle and FTT.BarStyles then
                FTT.BarStyles:ApplyStyle(FlyTimesDB.barStyle, timerFrame)
            end
        end

    elseif event == "TAXIMAP_OPENED" then
        -- Hook all taxi buttons whenever the taxi map opens
        for i = 1, 20 do
            local btn = _G["TaxiButton"..i]
            if btn then HookTaxiButton(btn) end
        end

    elseif event == "PLAYER_CONTROL_LOST" then
        -- Flight is starting: begin measurement after a short delay
        if measureFrom and measureTo and FlyTimesDB.learningEnabled then
            local delayFrame = CreateFrame("Frame")
            local delayTime = 0
            delayFrame:SetScript("OnUpdate", function()
                delayTime = delayTime + (arg1 or 0)
                if delayTime >= 0.3 then
                    delayFrame:SetScript("OnUpdate", nil)
                    if UnitOnTaxi("player") then
                        measureStartTime = GetTime()
                        measureActive = true
                        -- Update the learning indicator
                        if timerFrame:IsShown() then
                            timerFrame.learningLabel:SetText("|cffffcc00" .. (L["LEARNING_LABEL"] or "[measuring...]") .. "|r")
                            timerFrame.learningLabel:Show()
                        end
                    end
                end
            end)
        end

    elseif event == "PLAYER_CONTROL_GAINED" then
        -- Flight has ended: stop timer and save measurement
        if flightStartTime then
            FTT:StopFlightTimer()
        end

        if measureActive and measureStartTime and measureFrom and measureTo then
            local elapsed = GetTime() - measureStartTime
            local saved, entry = SaveMeasurement(measureFrom, measureTo, elapsed)

            if saved and entry then
                local avg = entry.total / entry.count
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r " .. (L["MEASURED_SAVED"] or "Measured %s -> %s: %s (%d db, avg: %s)"),
                    L["ADDON_NAME"] or "FlyTimes",
                    measureFrom, measureTo, FormatTime(elapsed), entry.count, FormatTime(avg)))
            end
        end

        -- Reset measurement state
        measureActive = false
        measureStartTime = nil
        measureFrom = nil
        measureTo = nil
    end
end)

-- =====================================================
--  TOOLTIP HOOK (Emberveil: no |T...|t inline textures)
-- =====================================================

if TaxiNodeOnButtonEnter then
    local originalTaxiNodeOnButtonEnter = TaxiNodeOnButtonEnter
    TaxiNodeOnButtonEnter = function(button)
        -- Emberveil: button param may be nil, fall back to `this`
        if not button then button = this end
        originalTaxiNodeOnButtonEnter(button)

        if not button or not GameTooltip then return end
        local buttonID = button:GetID()
        if not buttonID then return end

        local fromName = GetCurrentTaxiNodeName()
        local toName = TaxiNodeName and TaxiNodeName(buttonID)

        if fromName and toName then
            local duration = FTT:GetFlightTime(fromName, toName)
            if duration then
                local measured = GetMeasuredTime(fromName, toName)
                local label = measured and (L["TOOLTIP_FLIGHT_TIME_MEASURED"] or "Flight time (measured):")
                                      or (L["TOOLTIP_FLIGHT_TIME"] or "Flight time:")
                GameTooltip:AddLine("|cffFFD700" .. label .. "|r " .. FormatTime(duration), 1, 1, 1)
                GameTooltip:Show()
            end
        end
    end
end

-- =====================================================
--  SLASH COMMANDS  ( /ft )
-- =====================================================

SLASH_FLYTIMES1 = "/ft"
SLASH_FLYTIMES2 = "/flytimes"

SlashCmdList["FLYTIMES"] = function(msg)
    msg = string.lower(msg or "")

    -- Style subcommands
    if msg:match("^style") then
        local styleName = msg:match("^style%s+(.+)")

        if styleName == "list" then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. "|r " .. (L["STYLE_AVAILABLE_HEADER"] or "Available bar styles:"))
            local styles = FTT.BarStyles:GetStyleList()
            for _, style in ipairs(styles) do
                local current = (FlyTimesDB.barStyle == style.key) and (" |cff00ff00" .. (L["STYLE_CURRENT"] or " (current)") .. "|r") or ""
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["STYLE_ENTRY"] or "  %s - %s%s", style.name, style.description, current))
            end
            DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["STYLE_USAGE"] or "Usage: /ft style <name> or /ft style list"))
            return

        elseif styleName then
            if FTT.BarStyles.styles[styleName] then
                FlyTimesDB.barStyle = styleName
                FTT.BarStyles:ApplyStyle(styleName, timerFrame)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r " .. (L["STYLE_CHANGED"] or "Bar style changed to %s"),
                    L["ADDON_NAME"] or "FlyTimes", styleName))
            else
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r " .. (L["STYLE_UNKNOWN"] or "Unknown style '%s'"),
                    L["ADDON_NAME"] or "FlyTimes", styleName))
            end
            return
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. "|r " .. (L["STYLE_USAGE"] or "Usage: /ft style <name> or /ft style list"))
            return
        end
    end

    if msg == "toggle" then
        FlyTimesDB.enabled = not FlyTimesDB.enabled
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. ":|r " .. (FlyTimesDB.enabled and (L["ENABLED"] or "Enabled") or (L["DISABLED"] or "Disabled")))

    elseif msg == "learning" then
        FlyTimesDB.learningEnabled = not FlyTimesDB.learningEnabled
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r " .. (L["AUTO_LEARNING_TOGGLE"] or "Auto-learning %s"),
            L["ADDON_NAME"] or "FlyTimes",
            FlyTimesDB.learningEnabled and ("|cff88ff88" .. (L["ENABLED"] or "Enabled") .. "|r") or ("|cffff8888" .. (L["DISABLED"] or "Disabled") .. "|r")))

    elseif msg == "measured" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. ":|r " .. (L["MEASURED_ROUTES_HEADER"] or "Measured routes:"))
        local count = 0
        for key, entry in pairs(FlyTimesDB.measured or {}) do
            if entry.count >= 2 then
                local avg = entry.total / entry.count
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["MEASURED_ROUTE_ENTRY"] or "  %s: avg=%s, n=%d, last=%s",
                    key, FormatTime(avg), entry.count, FormatTime(entry.last)))
                count = count + 1
            end
        end
        if count == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("  |cff808080" .. (L["NO_MEASURED_ROUTES"] or "(no measured routes yet)") .. "|r")
        end

    elseif msg == "clearmeasured" then
        local count = 0
        for _ in pairs(FlyTimesDB.measured or {}) do count = count + 1 end
        FlyTimesDB.measured = {}
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r " .. (L["MEASURED_ROUTES_CLEARED"] or "Cleared %d measured routes"),
            L["ADDON_NAME"] or "FlyTimes", count))

    elseif msg == "estimate" then
        FlyTimesDB.showEstimate = not FlyTimesDB.showEstimate
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. ":|r " .. (FlyTimesDB.showEstimate and (L["ESTIMATE_ON"] or "Estimate messages enabled") or (L["ESTIMATE_OFF"] or "Estimate messages disabled")))

    elseif msg == "test" then
        FTT:StartFlightTimer(120, "Test Location A", "Test Location B")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. ":|r " .. (L["TESTING"] or "Testing 2 minute flight"))

    elseif msg == "reset" then
        timerFrame:ClearAllPoints()
        timerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        FlyTimesDB.posX = 0
        FlyTimesDB.posY = 200
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. ":|r " .. (L["POSITION_RESET"] or "Position reset"))

    elseif msg == "debug" then
        local measuredCount = 0
        for _ in pairs(FlyTimesDB.measured or {}) do measuredCount = measuredCount + 1 end

        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["DEBUG_HEADER"] or "FlyTimes DEBUG:") .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_CURRENT_NODE"] or "  Current node: %s", tostring(GetCurrentTaxiNodeName())))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_NUM_NODES"] or "  NumTaxiNodes: %s", tostring(NumTaxiNodes and NumTaxiNodes() or "?")))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_ON_TAXI"] or "  UnitOnTaxi: %s", tostring(UnitOnTaxi("player"))))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_LEARNING"] or "  Learning: %s", tostring(FlyTimesDB.learningEnabled)))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_MEASURED_COUNT"] or "  Measured routes: %d", measuredCount))

    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. "|r " .. (L["CMD_HEADER"] or "commands:"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_TOGGLE"] or "/ft toggle - Enable/disable addon"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_LEARNING"] or "/ft learning - Toggle auto-learning of flight times"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_MEASURED"] or "/ft measured - List measured routes"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_CLEARMEASURED"] or "/ft clearmeasured - Clear measured data"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_ESTIMATE"] or "/ft estimate - Toggle estimate messages"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_TEST"] or "/ft test - Test the timer bar"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_RESET"] or "/ft reset - Reset bar position"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_STYLE"] or "/ft style <name> - Change bar style"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_STYLE_LIST"] or "/ft style list - Show all available styles"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_DEBUG"] or "/ft debug - Show taxi debug info"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_HELP"] or "Drag the bar to move it"))
    end
end