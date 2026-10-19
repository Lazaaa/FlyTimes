-- FlyTimes Core
-- Shows a progress bar during flight paths
-- Emberveil (1.12.1) compatible
-- With auto-learning flight time measurement (UnitOnTaxi-based polling)
-- + Multi-hop route support via FlightRoutes.lua
-- + Waypoint dots indicator
-- + Leg-time measurement via zone changes

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
            measured_legs = {}, -- ÚJ: szakaszidők
        }
    end
    if not FlyTimesDB.measured then FlyTimesDB.measured = {} end
    if not FlyTimesDB.measured_legs then FlyTimesDB.measured_legs = {} end
    if FlyTimesDB.learningEnabled == nil then FlyTimesDB.learningEnabled = true end
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
local measurePending = false
local measureTimeout = 0

-- Leg measurement tracking
local legWaypoints = {}
local legZones = {}
local legTimesMeasured = {}
local currentLegIndex = 1
local lastZone = ""

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
--  MEASUREMENT SYSTEM (TELJES ÚTVONAL)
-- =====================================================

local function GetMeasurementKey(fromName, toName)
    local fromShort = string.gsub(fromName, "(%,.*)", "")
    local toShort = string.gsub(toName, "(%,.*)", "")
    return fromShort .. "_to_" .. toShort
end

local function GetMeasuredTime(fromName, toName)
    if not FlyTimesDB.measured then return nil end
    local key = GetMeasurementKey(fromName, toName)
    local entry = FlyTimesDB.measured[key]
    if not entry or entry.count < 2 then return nil end
    return entry.total / entry.count
end

local function SaveMeasurement(fromName, toName, seconds)
    if not seconds or seconds < 5 or seconds > 1800 then return false end
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
--  LEG MEASUREMENT SYSTEM (SZAKASZIDŐK)
-- =====================================================

local function GetLegKey(fromName, toName)
    local fromShort = string.gsub(fromName, "(%,.*)", "")
    local toShort = string.gsub(toName, "(%,.*)", "")
    return fromShort .. "_to_" .. toShort
end

local function GetMeasuredLegTime(fromName, toName)
    if not FlyTimesDB.measured_legs then return nil end
    local key = GetLegKey(fromName, toName)
    local entry = FlyTimesDB.measured_legs[key]
    if not entry or entry.count < 2 then return nil end
    return entry.total / entry.count
end

local function SaveLegMeasurement(fromName, toName, seconds)
    if not seconds or seconds < 3 or seconds > 1800 then return false end
    if not FlyTimesDB.measured_legs then FlyTimesDB.measured_legs = {} end
    local key = GetLegKey(fromName, toName)
    local entry = FlyTimesDB.measured_legs[key]
    if not entry then
        entry = { total = 0, count = 0, last = 0, min = seconds, max = seconds }
        FlyTimesDB.measured_legs[key] = entry
    end
    entry.total = entry.total + seconds
    entry.count = entry.count + 1
    entry.last = seconds
    if seconds < entry.min then entry.min = seconds end
    if seconds > entry.max then entry.max = seconds end
    return true, entry
end

-- =====================================================
--  FLIGHT ROUTES HELPER (multi-hop support)
-- =====================================================

function FTT:GetRouteStops(fromName, toName)
    if not self.FlightRoutes then return nil end
    if not self.FlightRoutes["CLASSIC"] then return nil end
    local faction = GetPlayerFaction()
    local factionRoutes = self.FlightRoutes["CLASSIC"][faction]
    if not factionRoutes then return nil end

    if factionRoutes[fromName] and factionRoutes[fromName][toName] then
        return factionRoutes[fromName][toName]
    end

    local fromShort = string.gsub(fromName, "(%,.*)", "")
    local toShort = string.gsub(toName, "(%,.*)", "")

    for k, v in pairs(factionRoutes) do
        local kShort = string.gsub(k, "(%,.*)", "")
        if kShort == fromShort then
            for toK, toV in pairs(v) do
                local toKShort = string.gsub(toK, "(%,.*)", "")
                if toK == toName or toKShort == toShort then
                    return toV
                end
            end
        end
    end
    return nil
end

function FTT:FormatRouteStops(fromName, toName)
    local stops = self:GetRouteStops(fromName, toName)
    if not stops or #stops == 0 then return nil end
    local parts = {}
    for _, stop in ipairs(stops) do
        table.insert(parts, (string.gsub(stop, "(%,.*)", "")))
    end
    return table.concat(parts, " > ")
end

-- =====================================================
--  FLIGHT TIME LOOKUP
-- =====================================================

function FTT:GetFlightTime(fromName, toName)
    local measured = GetMeasuredTime(fromName, toName)
    if measured then return measured end

    local version = GetGameVersion()
    local faction = GetPlayerFaction()
    if not self.FlightDB or not self.FlightDB[version] then return nil end
    local versionDB = self.FlightDB[version]
    if not versionDB[faction] then return nil end

    if versionDB[faction][fromName] and versionDB[faction][fromName][toName] then
        return versionDB[faction][fromName][toName]
    end
    if versionDB[faction][toName] and versionDB[faction][toName][fromName] then
        return versionDB[faction][toName][fromName]
    end

    local multiHop = self:GetMultiHopFlightTime(fromName, toName)
    if multiHop then return multiHop end

    local fromKey, toKey
    for k, v in pairs(versionDB[faction]) do
        if not fromKey and string.find(k, fromName, 1, true) then fromKey = k end
        if not toKey and string.find(k, toName, 1, true) then toKey = k end
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

function FTT:GetMultiHopFlightTime(fromName, toName)
    local stops = self:GetRouteStops(fromName, toName)
    if not stops or #stops == 0 then return nil end

    local version = GetGameVersion()
    local faction = GetPlayerFaction()
    if not self.FlightDB or not self.FlightDB[version] then return nil end
    local db = self.FlightDB[version][faction]
    if not db then return nil end

    local path = { fromName }
    for _, s in ipairs(stops) do table.insert(path, s) end
    table.insert(path, toName)

    local function findLeg(from, to)
        if db[from] and db[from][to] then return db[from][to] end
        if db[to] and db[to][from] then return db[to][from] end
        local fromShort = string.gsub(from, "(%,.*)", "")
        local toShort = string.gsub(to, "(%,.*)", "")
        for k, v in pairs(db) do
            if string.gsub(k, "(%,.*)", "") == fromShort then
                for k2, v2 in pairs(v) do
                    if string.gsub(k2, "(%,.*)", "") == toShort then return v2 end
                end
            end
        end
        return nil
    end

    local total = 0
    local legsFound = 0
    for i = 1, #path - 1 do
        local t = findLeg(path[i], path[i + 1])
        if t then
            total = total + t
            legsFound = legsFound + 1
        end
    end
    if legsFound == #path - 1 then return total end
    return nil
end

-- Kiszámolja két pont közötti KÖZVETLEN szakasz idejét (mért, majd DB)
function FTT:GetLegTime(fromName, toName)
    local measured = GetMeasuredLegTime(fromName, toName)
    if measured then return measured end
    
    local version = GetGameVersion()
    local faction = GetPlayerFaction()
    if not self.FlightDB or not self.FlightDB[version] or not self.FlightDB[version][faction] then
        return nil
    end
    local db = self.FlightDB[version][faction]
    if db[fromName] and db[fromName][toName] then return db[fromName][toName] end
    if db[toName] and db[toName][fromName] then return db[toName][fromName] end
    
    local fromShort = string.gsub(fromName, "(%,.*)", "")
    local toShort = string.gsub(toName, "(%,.*)", "")
    for k, v in pairs(db) do
        if string.gsub(k, "(%,.*)", "") == fromShort then
            for k2, v2 in pairs(v) do
                if string.gsub(k2, "(%,.*)", "") == toShort then
                    return v2
                end
            end
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

timerFrame:SetScript("OnDragStart", function() this:StartMoving() end)
timerFrame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, _, x, y = this:GetPoint()
    FlyTimesDB.posX = x
    FlyTimesDB.posY = y
end)

timerFrame.bg = timerFrame:CreateTexture(nil, "BACKGROUND")
timerFrame.bg:SetAllPoints()
timerFrame.bg:SetTexture(0, 0, 0, 0.8)

timerFrame.border = timerFrame:CreateTexture(nil, "BORDER")
timerFrame.border:SetTexture(0.3, 0.3, 0.3, 1)
timerFrame.border:SetPoint("TOPLEFT", 1, -1)
timerFrame.border:SetPoint("BOTTOMRIGHT", -1, 1)

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

timerFrame.text = timerFrame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
timerFrame.text:SetPoint("CENTER")
timerFrame.text:SetTextColor(1, 1, 1)

timerFrame.routeLabel = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timerFrame.routeLabel:SetPoint("BOTTOM", timerFrame, "TOP", 0, 4)
timerFrame.routeLabel:SetTextColor(1, 1, 1)
timerFrame.routeLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

timerFrame.waypointLabel = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timerFrame.waypointLabel:SetPoint("BOTTOM", timerFrame.routeLabel, "TOP", 0, 2)
timerFrame.waypointLabel:SetTextColor(1, 1, 1)
timerFrame.waypointLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
timerFrame.waypointLabel:Hide()

timerFrame.learningLabel = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
timerFrame.learningLabel:SetPoint("TOP", timerFrame, "BOTTOM", 0, -4)
timerFrame.learningLabel:SetTextColor(0.5, 1, 0.5)
timerFrame.learningLabel:Hide()

timerFrame.bar.spark = timerFrame.bar:CreateTexture(nil, "OVERLAY")
timerFrame.bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
timerFrame.bar.spark:SetBlendMode("ADD")
timerFrame.bar.spark:SetWidth(20)
timerFrame.bar.spark:SetHeight(timerFrame.bar:GetHeight() * 2.5)

FTT.timerFrame = timerFrame

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
--  UPDATE WAYPOINTS
-- =====================================================

function FTT:UpdateWaypoints(elapsedTime)
    if not timerFrame.waypoints or not timerFrame.waypointTimes then return end
    local count = #timerFrame.waypoints
    if count <= 1 then
        timerFrame.waypointLabel:Hide()
        return
    end

    local text = {}
    for i = 1, count do
        local targetTime = timerFrame.waypointTimes[i]
        if targetTime and elapsedTime >= targetTime then
            table.insert(text, "|cff555555o|r")
        else
            table.insert(text, "|cff00ff00o|r")
        end
    end
    timerFrame.waypointLabel:SetText(table.concat(text, " |cff808080-|r "))
end

-- =====================================================
--  START / STOP TIMER
-- =====================================================

function FTT:StartFlightTimer(duration, fromNode, toNode)
    if not FlyTimesDB or not FlyTimesDB.enabled then return end

    local now = GetTime()
    if (now - lastStartTime) < 1 then return end
    lastStartTime = now

    flightStartTime = now
    flightDuration = duration
    sourceNode = fromNode
    destNode = toNode

    timerFrame.bar:SetMinMaxValues(0, duration)
    timerFrame.routeLabel:SetText(string.format("%s > %s", fromNode or "?", toNode or "?"))
    timerFrame:Show()

    -- Waypoint dots inicializálása
    local stops = FTT:GetRouteStops(fromNode, toNode)
    local waypoints = { fromNode }
    if stops then for _, s in ipairs(stops) do table.insert(waypoints, s) end end
    table.insert(waypoints, toNode)

    timerFrame.waypoints = waypoints
    
    -- Szakaszidők kiszámítása (először mért, aztán DB)
    local legTimes = {}
    local totalCalculatedTime = 0
    local current = fromNode
    for i = 1, #waypoints - 1 do
        local leg = FTT:GetLegTime(waypoints[i], waypoints[i+1]) or 0
        table.insert(legTimes, leg)
        totalCalculatedTime = totalCalculatedTime + leg
    end

    -- Arányosítás a teljes időhöz, ha szükséges
    local ratio = 1
    if totalCalculatedTime > 0 and duration > 0 then
        ratio = duration / totalCalculatedTime
    end

    timerFrame.waypointTimes = { 0 } -- Kezdőpont rögtön kialszik
    local accum = 0
    for _, leg in ipairs(legTimes) do
        accum = accum + (leg * ratio)
        table.insert(timerFrame.waypointTimes, accum)
    end

    timerFrame.waypointLabel:Show()
    FTT:UpdateWaypoints(0)

    -- Leg measurement inicializálás
    legWaypoints = waypoints
    legZones = {}
    for _, wp in ipairs(waypoints) do
        local zone = string.match(wp, "%,%s*(.+)$") or wp
        table.insert(legZones, zone)
    end
    legTimesMeasured = {}
    currentLegIndex = 1
    lastZone = GetZoneText()

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

        local stopsStr = FTT:FormatRouteStops(fromNode, toNode)
        local routeDisplay = string.format("%s > %s", fromNode or "?", toNode or "?")
        if stopsStr then
            routeDisplay = string.format("%s > %s > %s", fromNode or "?", stopsStr, toNode or "?")
        end

        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r %s (|cff808080%s|r)",
            L["ADDON_NAME"] or "FlyTimes",
            string.format(L["FLIGHT_TIME"] or "Estimated flight time: %s", FormatTime(duration)),
            source))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cff808080%s|r", routeDisplay))
    end
end

function FTT:StopFlightTimer()
    flightStartTime = nil
    flightDuration = nil
    sourceNode = nil
    destNode = nil
    timerFrame:Hide()
    timerFrame.learningLabel:Hide()
    timerFrame.waypointLabel:Hide()
    timerFrame.waypoints = nil
    timerFrame.waypointTimes = nil
end

-- =====================================================
--  ONUPDATE (timer bar)
-- =====================================================

timerFrame:SetScript("OnUpdate", function()
    local elapsed = arg1 or 0
    if not flightStartTime or not flightDuration then return end

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

    local progress = elapsedTime / flightDuration
    if progress < 0 then progress = 0 end
    if progress > 1 then progress = 1 end
    FTT:UpdateWaypoints(elapsedTime)

    local width = this.bar:GetWidth()
    this.bar.spark:SetPoint("CENTER", this.bar, "LEFT", width * progress, 0)
end)

-- =====================================================
--  MEASUREMENT POLLING FRAME
-- =====================================================

local measureFrame = CreateFrame("Frame")
measureFrame:Hide()
measureFrame.elapsed = 0

measureFrame:SetScript("OnUpdate", function()
    local elapsed = arg1 or 0
    this.elapsed = this.elapsed + elapsed

    if this.elapsed < 0.25 then return end
    this.elapsed = 0

    local onTaxi = UnitOnTaxi and UnitOnTaxi("player") or false

    if measurePending and not measureActive and measureFrom and measureTo then
        if onTaxi then
            measureActive = true
            measureStartTime = GetTime()
            measureTimeout = 0
            lastZone = GetZoneText()
            legTimesMeasured = {}
            currentLegIndex = 1
            if timerFrame:IsShown() then
                timerFrame.learningLabel:SetText("|cffffcc00" .. (L["LEARNING_LABEL"] or "[measuring...]") .. "|r")
                timerFrame.learningLabel:Show()
            end
        else
            measureTimeout = measureTimeout + 0.25
            if measureTimeout > 5 then
                measurePending = false
                measureFrom = nil
                measureTo = nil
                measureTimeout = 0
            end
        end
    end

    if measureActive then
        measureTimeout = measureTimeout + 0.25

        -- Zónaváltás figyelése a szakaszidőkhöz
        if legWaypoints and #legWaypoints > 0 then
            local currentZone = GetZoneText()
            if currentZone and currentZone ~= lastZone then
                -- Megnézzük, hogy ez a zóna egy következő waypoint zónája-e
                for i = currentLegIndex + 1, #legWaypoints do
                    if legZones[i] == currentZone then
                        local legStart = (i == 2) and measureStartTime or nil
                        if i == 2 then legStart = measureStartTime end
                        -- Az előző szakasz idejének kiszámítása
                        if i > 1 then
                            local prevTime = legTimesMeasured[i-1] and (measureStartTime + legTimesMeasured[i-1]) or measureStartTime
                            -- Ez így nem jó, mert a legTimesMeasured csak az eltelt időt tárolja
                        end
                        -- Egyszerűbb: az eltelt időt elmentjük
                        local elapsedTotal = GetTime() - measureStartTime
                        table.insert(legTimesMeasured, elapsedTotal)
                        
                        -- Elmentjük a szakaszidőt (a különbséget)
                        local prevTotal = 0
                        if #legTimesMeasured > 1 then
                            prevTotal = legTimesMeasured[#legTimesMeasured - 1]
                        end
                        local legDuration = elapsedTotal - prevTotal
                        
                        if legDuration > 3 and legDuration < 1800 then
                            local fromWp = legWaypoints[i-1]
                            local toWp = legWaypoints[i]
                            SaveLegMeasurement(fromWp, toWp, legDuration)
                            
                            if FlyTimesDB.showEstimate then
                                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff808080  [leg] %s -> %s: %s|r", 
                                    string.gsub(fromWp, "(%,.*)", ""), 
                                    string.gsub(toWp, "(%,.*)", ""), 
                                    FormatTime(legDuration)))
                            end
                        end
                        
                        currentLegIndex = i
                        break
                    end
                end
                lastZone = currentZone
            end
        end

        if not onTaxi then
            local duration = GetTime() - (measureStartTime or GetTime())
            local saved, entry = SaveMeasurement(measureFrom, measureTo, duration)

            if saved and entry then
                local avg = entry.total / entry.count
                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    "|cff00ff00%s:|r " .. (L["MEASURED_SAVED"] or "Measured %s -> %s: %s (%d db, avg: %s)"),
                    L["ADDON_NAME"] or "FlyTimes",
                    measureFrom, measureTo,
                    FormatTime(duration), entry.count, FormatTime(avg)))
            end

            measureActive = false
            measurePending = false
            measureStartTime = nil
            measureFrom = nil
            measureTo = nil
            measureTimeout = 0
            legWaypoints = {}
            legZones = {}

            if timerFrame.learningLabel then timerFrame.learningLabel:Hide() end
        elseif measureTimeout > 1800 then
            measureActive = false
            measurePending = false
            measureStartTime = nil
            measureFrom = nil
            measureTo = nil
            measureTimeout = 0
            legWaypoints = {}
            legZones = {}
        end
    end

    if not measurePending and not measureActive then
        this:Hide()
    end
end)

function FTT:StartMeasurement(fromName, toName)
    if not FlyTimesDB or not FlyTimesDB.learningEnabled then return end
    if not fromName or not toName then return end

    measureFrom = fromName
    measureTo = toName
    measurePending = true
    measureActive = false
    measureStartTime = nil
    measureTimeout = 0

    measureFrame.elapsed = 0
    measureFrame:Show()
end

-- =====================================================
--  HELPER: CURRENT TAXI NODE NAME
-- =====================================================

local function GetCurrentTaxiNodeName()
    if not NumTaxiNodes or not TaxiNodeGetType or not TaxiNodeName then return nil end
    local numNodes = NumTaxiNodes()
    for i = 1, numNodes do
        local nodeType = TaxiNodeGetType(i)
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
        FTT:StartMeasurement(fromName, destName)
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
                FTT:StartMeasurement(fromName, destName)
            end
        end
        if originalOnClick then originalOnClick() end
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
            InitDB()

            timerFrame:SetWidth(FlyTimesDB.barWidth or 300)
            timerFrame:SetHeight(FlyTimesDB.barHeight or 30)
            timerFrame:ClearAllPoints()
            timerFrame:SetPoint("CENTER", UIParent, "CENTER", FlyTimesDB.posX or 0, FlyTimesDB.posY or 200)

            local msgL = FTT.L or {}
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s|r by %s ver. %s %s",
                msgL["ADDON_NAME"] or "FlyTimes",
                FTT.AUTHOR or "Unknown",
                FTT.VERSION or "?",
                msgL["LOADED"] or "loaded! Use /ft for options."))

            if FlyTimesDB.barStyle and FTT.BarStyles then
                FTT.BarStyles:ApplyStyle(FlyTimesDB.barStyle, timerFrame)
            end
        end

    elseif event == "TAXIMAP_OPENED" then
        for i = 1, 20 do
            local btn = _G["TaxiButton"..i]
            if btn then HookTaxiButton(btn) end
        end

    elseif event == "PLAYER_CONTROL_LOST" then
        -- Nem csinálunk semmit

    elseif event == "PLAYER_CONTROL_GAINED" then
        if flightStartTime then
            FTT:StopFlightTimer()
        end
    end
end)

-- =====================================================
--  TOOLTIP HOOK
-- =====================================================

if TaxiNodeOnButtonEnter then
    local originalTaxiNodeOnButtonEnter = TaxiNodeOnButtonEnter
    TaxiNodeOnButtonEnter = function(button)
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

                local stops = FTT:GetRouteStops(fromName, toName)
                if stops and #stops > 0 then
                    local parts = {}
                    for _, stop in ipairs(stops) do
                        table.insert(parts, (string.gsub(stop, "(%,.*)", "")))
                    end
                    local stopsLine = table.concat(parts, " > ")
                    GameTooltip:AddLine("|cff808080" .. (L["TOOLTIP_STOPS"] or "Stops:") .. "|r " .. stopsLine, 1, 1, 1)
                end
                GameTooltip:Show()
            end
        end
    end
end

-- =====================================================
--  SLASH COMMANDS
-- =====================================================

SLASH_FLYTIMES1 = "/ft"
SLASH_FLYTIMES2 = "/flytimes"

SlashCmdList["FLYTIMES"] = function(msg)
    msg = string.lower(msg or "")

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

    if msg:match("^route") then
        local routeName = msg:match("^route%s+(.+)")
        if not routeName then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. "|r " .. (L["ROUTE_USAGE"] or "Usage: /ft route <partial name>"))
            return
        end
        routeName = string.lower(routeName)
        local found = 0
        local faction = GetPlayerFaction()
        if FTT.FlightRoutes and FTT.FlightRoutes["CLASSIC"] and FTT.FlightRoutes["CLASSIC"][faction] then
            local headerPrinted = false
            for fromK, v in pairs(FTT.FlightRoutes["CLASSIC"][faction]) do
                for toK, stops in pairs(v) do
                    local combined = fromK .. " > " .. toK
                    if string.find(string.lower(combined), routeName, 1, true) then
                        if not headerPrinted then
                            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. ":|r " .. (L["ROUTE_HEADER"] or "Matching routes:"))
                            headerPrinted = true
                        end
                        local parts = {}
                        for _, s in ipairs(stops) do table.insert(parts, s) end
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cffcceeff%s|r |cff808080%s|r |cffffd700%s|r",
                            combined, L["ROUTE_VIA"] or "via", table.concat(parts, " > ")))
                        found = found + 1
                    end
                end
            end
        end
        if found == 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r " .. (L["ROUTE_NO_MATCH"] or "No matching route for '%s'"),
                L["ADDON_NAME"] or "FlyTimes", routeName))
        end
        return
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
    elseif msg == "measuredlegs" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. ":|r Measured legs:")
        local count = 0
        for key, entry in pairs(FlyTimesDB.measured_legs or {}) do
            if entry.count >= 2 then
                local avg = entry.total / entry.count
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: avg=%s, n=%d", key, FormatTime(avg), entry.count))
                count = count + 1
            end
        end
        if count == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("  |cff808080(no measured legs yet)|r")
        end
    elseif msg == "clearmeasured" then
        local count = 0
        for _ in pairs(FlyTimesDB.measured or {}) do count = count + 1 end
        FlyTimesDB.measured = {}
        FlyTimesDB.measured_legs = {}
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
        local legCount = 0
        for _ in pairs(FlyTimesDB.measured_legs or {}) do legCount = legCount + 1 end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["DEBUG_HEADER"] or "FlyTimes DEBUG:") .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_CURRENT_NODE"] or "  Current node: %s", tostring(GetCurrentTaxiNodeName())))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_NUM_NODES"] or "  NumTaxiNodes: %s", tostring(NumTaxiNodes and NumTaxiNodes() or "?")))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_ON_TAXI"] or "  UnitOnTaxi: %s", tostring(UnitOnTaxi("player"))))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_LEARNING"] or "  Learning: %s", tostring(FlyTimesDB.learningEnabled)))
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["DEBUG_MEASURED_COUNT"] or "  Measured routes: %d", measuredCount))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Measured legs: %d", legCount))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Pending: %s, Active: %s", tostring(measurePending), tostring(measureActive)))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. (L["ADDON_NAME"] or "FlyTimes") .. "|r " .. (L["CMD_HEADER"] or "commands:"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_TOGGLE"] or "/ft toggle - Enable/disable addon"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_LEARNING"] or "/ft learning - Toggle auto-learning of flight times"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_MEASURED"] or "/ft measured - List measured routes"))
        DEFAULT_CHAT_FRAME:AddMessage("  /ft measuredlegs - List measured legs")
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_CLEARMEASURED"] or "/ft clearmeasured - Clear measured data"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_ESTIMATE"] or "/ft estimate - Toggle estimate messages"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_TEST"] or "/ft test - Test the timer bar"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_RESET"] or "/ft reset - Reset bar position"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_STYLE"] or "/ft style <name> - Change bar style"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_STYLE_LIST"] or "/ft style list - Show all available styles"))
        DEFAULT_CHAT_FRAME:AddMessage("  /ft route <partial> - Show route with stops")
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_DEBUG"] or "/ft debug - Show taxi debug info"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_HELP"] or "Drag the bar to move it"))
    end
end