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

-- Lua 5.0 (1.12.1) has no "#", "%", string.match or string methods
local getn = table.getn

local function smatch(s, pattern)
    if not s then return nil end
    local _, _, c1, c2 = string.find(s, pattern)
    if c2 then return c1, c2 end
    return c1
end

local function shortName(name)
    return (string.gsub(name or "", "(%,.*)", ""))
end
FTT.ShortName = shortName

-- =====================================================
--  SAVED VARIABLES
-- =====================================================

local function InitDB()
    if not FlyTimesDB then
        FlyTimesDB = {
            enabled = true,
            showEstimate = false,
            barWidth = 300,
            barHeight = 30,
            posX = 0,
            posY = 200,
            barStyle = "classic",
            learningEnabled = true,
            measured = {},
        }
    end
    if not FlyTimesDB.measured then FlyTimesDB.measured = {} end
    -- leg times of older versions were measured at zone borders: discard them
    FlyTimesDB.measured_legs = nil
    if FlyTimesDB.learningEnabled == nil then FlyTimesDB.learningEnabled = true end
    -- 1.0.8: the flight time is no longer written to chat at take-off by
    -- default (switch it back on in the options or with /ft estimate)
    if not FlyTimesDB.estimateOff108 then
        FlyTimesDB.showEstimate = false
        FlyTimesDB.estimateOff108 = true
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
local measurePending = false
local measureTimeout = 0


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

-- true once the route has been flown and timed at least once
local function HasMeasurement(fromName, toName)
    if not (FlyTimesDB and FlyTimesDB.measured and fromName and toName) then return false end
    local entry = FlyTimesDB.measured[GetMeasurementKey(fromName, toName)]
    return entry ~= nil and (entry.count or 0) >= 1
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
--  FLIGHT ROUTES HELPER (multi-hop support)
-- =====================================================

-- The real hops, read from the client's flight map (the route lines it
-- draws): GetNumRoutes(i) segments, TaxiGetDestX/Y(i, j) the end of each
-- segment, matched to the nearest flight point. This follows the flight
-- points this character knows, so it beats the built-in table.
function FTT:ReadLiveRoutes()
    if not (NumTaxiNodes and TaxiNodeName and TaxiNodeGetType and TaxiNodePosition
            and GetNumRoutes and TaxiGetDestX and TaxiGetDestY) then return end
    local ok = pcall(function()
        local from
        local n = NumTaxiNodes() or 0
        local pos = {}
        for k = 1, n do
            local x, y = TaxiNodePosition(k)
            pos[k] = { x = x, y = y, name = TaxiNodeName(k) }
            if TaxiNodeGetType(k) == "CURRENT" then from = pos[k].name end
        end
        if not from then return end
        FlyTimesDB.liveRoutes = FlyTimesDB.liveRoutes or {}
        local known = FlyTimesDB.liveRoutes[from] or {}
        for i = 1, n do
            if TaxiNodeGetType(i) == "REACHABLE" then
                local hops = GetNumRoutes(i)
                if hops and hops >= 1 then
                    local stops, good = {}, true
                    for j = 1, hops - 1 do
                        local x, y = TaxiGetDestX(i, j), TaxiGetDestY(i, j)
                        local best, bestD
                        for k = 1, n do
                            if pos[k].x and x then
                                local d = (pos[k].x - x) * (pos[k].x - x) + (pos[k].y - y) * (pos[k].y - y)
                                if not bestD or d < bestD then best, bestD = k, d end
                            end
                        end
                        if not best or bestD > 0.0004 then good = false break end -- > 2% of the map away
                        table.insert(stops, pos[best].name)
                    end
                    if good then known[pos[i].name] = stops end
                end
            end
        end
        FlyTimesDB.liveRoutes[from] = known
    end)
    return ok
end

function FTT:GetRouteStops(fromName, toName)
    -- 1) what the flight map showed for this character
    local live = FlyTimesDB and FlyTimesDB.liveRoutes and fromName and FlyTimesDB.liveRoutes[fromName]
    if live and toName and live[toName] then
        FTT.routeFromMap = true
        return live[toName]
    end
    FTT.routeFromMap = false
    -- 2) built-in table
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
    if not stops or getn(stops) == 0 then return nil end
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
    if not stops or getn(stops) == 0 then return nil end

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
    for i = 1, getn(path) - 1 do
        local t = findLeg(path[i], path[i + 1])
        if t then
            total = total + t
            legsFound = legsFound + 1
        end
    end
    if legsFound == getn(path) - 1 then return total end
    return nil
end

-- Time of one direct leg, from the flight database. (The old zone-based leg
-- measurement recorded zone borders instead of stops, so it is not used.)
function FTT:GetLegTime(fromName, toName)

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
    -- StartMoving re-anchors the frame (e.g. to BOTTOMLEFT); store the offset
    -- of the frame's centre from the screen centre, which is how it is restored
    local cx, cy = this:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if cx and ux then
        local scale = this:GetEffectiveScale() / UIParent:GetEffectiveScale()
        FlyTimesDB.posX = math.floor(cx * scale - ux + 0.5)
        FlyTimesDB.posY = math.floor(cy * scale - uy + 0.5)
        this:ClearAllPoints()
        this:SetPoint("CENTER", UIParent, "CENTER", FlyTimesDB.posX, FlyTimesDB.posY)
    end
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

-- route track above the route name: a dot per flight point, lines between
-- them that fill up as you fly. Passed points gold, the next one green with
-- a soft pulse, the ones after it green rings.
-- (kept under the old name, so Show/Hide calls elsewhere still work)
local TRACK_TEX = "Interface\\AddOns\\FlyTimes\\"
local LINE_TEX = "Interface\\Tooltips\\UI-Tooltip-Background"
local TRACK_H = 16
local track = CreateFrame("Frame", nil, timerFrame)
track:SetWidth(200)
track:SetHeight(TRACK_H)
track:SetPoint("BOTTOM", timerFrame.routeLabel, "TOP", 0, 3)
track:Hide()
track.dots, track.lines = {}, {}
timerFrame.waypointLabel = track

local function trackTex(layer, file, size)
    local t = track:CreateTexture(nil, layer)
    t:SetTexture(file)
    t:SetWidth(size)
    t:SetHeight(size)
    return t
end

local function trackDot(i)
    local d = track.dots[i]
    if d then return d end
    d = {
        glow = trackTex("BACKGROUND", TRACK_TEX .. "route_glow", 26),
        fill = trackTex("OVERLAY", TRACK_TEX .. "route_dot", 10),
        ring = trackTex("OVERLAY", TRACK_TEX .. "route_ring", 12),
    }
    d.glow:SetVertexColor(0.2, 1, 0.3)
    -- mouse over a dot: name of the flight point and when you get there
    local hit = CreateFrame("Button", nil, track)
    hit:SetWidth(16)
    hit:SetHeight(16)
    hit:SetFrameLevel(track:GetFrameLevel() + 2)
    hit.index = i
    hit:SetScript("OnEnter", function()
        local wps, times = timerFrame.waypoints, timerFrame.waypointTimes
        local name = wps and wps[this.index]
        if not name then return end
        -- this client ignores ANCHOR_TOP and puts the tooltip at its default
        -- spot, so it is placed by hand just above the dot
        GameTooltip:SetOwner(this, "ANCHOR_NONE")
        GameTooltip:SetText(name, 1, 0.82, 0)
        local t = times and times[this.index]
        local elapsed = flightStartTime and (GetTime() - flightStartTime) or 0
        if this.index == 1 then
            GameTooltip:AddLine(L["TRACK_START"] or "Start", 0.7, 0.7, 0.7)
        elseif t and elapsed >= t then
            GameTooltip:AddLine(L["TRACK_PASSED"] or "Flown over", 0.7, 0.7, 0.7)
        elseif t then
            local left = math.floor(t - elapsed + 0.5)
            local m = math.floor(left / 60)
            GameTooltip:AddLine(string.format(L["TRACK_IN"] or "in %s", string.format("%d:%02d", m, left - m * 60)), 0.4, 1, 0.4)
        end
        if this.index > 1 and this.index < getn(wps) then
            GameTooltip:AddLine(L["TRACK_VIA"] or "Flown over, no landing", 0.6, 0.6, 0.6)
        end
        if this.index > 1 and this.index < getn(wps) and FTT.routeFromMap == false then
            GameTooltip:AddLine(L["TRACK_ESTIMATED"] or "(stop estimated, not read from the flight map)", 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("BOTTOM", this, "TOP", 0, 4)
    end)
    -- keep it there: a UI skin may move the tooltip back to its own anchor
    hit:SetScript("OnUpdate", function()
        if GameTooltip:IsVisible() and GameTooltip.IsOwned and GameTooltip:IsOwned(this) then
            local p, rel = GameTooltip:GetPoint(1)
            if p ~= "BOTTOM" or rel ~= this then
                GameTooltip:ClearAllPoints()
                GameTooltip:SetPoint("BOTTOM", this, "TOP", 0, 4)
            end
        end
    end)
    hit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    d.hit = hit
    track.dots[i] = d
    return d
end

local function trackLine(i)
    local l = track.lines[i]
    if l then return l end
    l = {}
    l.bg = track:CreateTexture(nil, "BORDER")
    l.bg:SetTexture(LINE_TEX)
    l.bg:SetVertexColor(0.35, 0.37, 0.4, 0.9)
    l.bg:SetHeight(2)
    l.fill = track:CreateTexture(nil, "ARTWORK")
    l.fill:SetTexture(LINE_TEX)
    l.fill:SetVertexColor(1, 0.8, 0.2, 1)
    l.fill:SetHeight(2)
    track.lines[i] = l
    return l
end

-- lay out the dots for the current route (one anchor + size everywhere)
local function layoutTrack(count)
    local gap = 44
    if count > 6 then gap = 32 end
    local width = (count - 1) * gap
    track:SetWidth(width + 20)
    track.gap = gap
    for i = 1, count do
        local d = trackDot(i)
        local x = 10 + (i - 1) * gap
        for _, t in pairs(d) do
            t:ClearAllPoints()
            t:SetPoint("CENTER", track, "LEFT", x, 0)
        end
        if i < count then
            local l = trackLine(i)
            l.bg:ClearAllPoints()
            l.bg:SetPoint("LEFT", track, "LEFT", x + 6, 0)
            l.bg:SetWidth(gap - 12)
            l.fill:ClearAllPoints()
            l.fill:SetPoint("LEFT", track, "LEFT", x + 6, 0)
            l.bg:Show()
        end
    end
    for i = count + 1, getn(track.dots) do
        for _, t in pairs(track.dots[i]) do t:Hide() end
    end
    for i = count, getn(track.lines) do
        track.lines[i].bg:Hide()
        track.lines[i].fill:Hide()
    end
    track.count = count
end

timerFrame.learningLabel = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
timerFrame.learningLabel:SetPoint("TOP", timerFrame, "BOTTOM", 0, -4)
timerFrame.learningLabel:SetTextColor(0.5, 1, 0.5)
timerFrame.learningLabel:Hide()

timerFrame.bar.spark = timerFrame.bar:CreateTexture(nil, "OVERLAY")
timerFrame.bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
timerFrame.bar.spark:SetBlendMode("ADD")
timerFrame.bar.spark:SetWidth(20)
timerFrame.bar.spark:SetHeight(60)
timerFrame.bar.spark:SetPoint("CENTER", timerFrame.bar, "LEFT", 0, 0)

local function SizeSpark()
    local h = (FlyTimesDB and FlyTimesDB.barHeight) or timerFrame:GetHeight() or 30
    if h < 10 then h = 30 end
    timerFrame.bar.spark:SetHeight((h - 8) * 2.5)
end
FTT.SizeSpark = SizeSpark

FTT.timerFrame = timerFrame

-- =====================================================
--  TIME FORMATTER
-- =====================================================

local function FormatTime(seconds)
    if not seconds then return "??:??" end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds - mins * 60)
    return string.format("%d:%02d", mins, secs)
end

-- =====================================================
--  UPDATE WAYPOINTS
-- =====================================================

function FTT:UpdateWaypoints(elapsedTime)
    local wps, times = timerFrame.waypoints, timerFrame.waypointTimes
    if not wps or not times then return end
    local count = getn(wps)
    if count <= 1 then
        track:Hide()
        return
    end
    if track.count ~= count then layoutTrack(count) end

    local nextIdx
    for i = 1, count do
        local t = times[i]
        local passed = t and elapsedTime >= t
        local d = trackDot(i)
        d.hit:Show()
        if passed then
            d.fill:SetVertexColor(1, 0.8, 0.2)
            d.fill:Show()
            d.ring:Hide()
            d.glow:Hide()
        elseif not nextIdx then
            nextIdx = i
            d.fill:SetVertexColor(0.25, 1, 0.35)
            d.fill:Show()
            d.ring:SetVertexColor(0.6, 1, 0.65)
            d.ring:Show()
            -- slow pulse
            local a = 0.45 + 0.35 * math.sin(GetTime() * 3)
            d.glow:SetAlpha(a)
            d.glow:Show()
        else
            d.fill:Hide()
            d.ring:SetVertexColor(0.25, 0.9, 0.35)
            d.ring:Show()
            d.glow:Hide()
        end
        -- line to the next point fills with the time flown on that leg
        if i < count then
            local l = trackLine(i)
            local t0, t1 = times[i] or 0, times[i + 1] or 0
            local f = 0
            if elapsedTime >= t1 then f = 1
            elseif t1 > t0 and elapsedTime > t0 then f = (elapsedTime - t0) / (t1 - t0) end
            local w = (track.gap - 12) * f
            if w >= 1 then
                l.fill:SetWidth(w)
                l.fill:Show()
            else
                l.fill:Hide()
            end
        end
    end
    track:Show()
end

-- =====================================================
--  START / STOP TIMER
-- =====================================================

function FTT:StartFlightTimer(duration, fromNode, toNode, startedAt)
    if not FlyTimesDB or not FlyTimesDB.enabled then return end

    local now = GetTime()
    if not startedAt then
        if (now - lastStartTime) < 1 then return end
        lastStartTime = now
    end

    -- startedAt: restoring a flight after /reload (GetTime keeps running)
    flightStartTime = startedAt or now
    if FTT.SaveActiveFlight then FTT:SaveActiveFlight(flightStartTime, duration, fromNode, toNode) end
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
    for i = 1, getn(waypoints) - 1 do
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

    SizeSpark()

    local measured = GetMeasuredTime(fromNode, toNode)
    -- no "[measured]" label: the bar shows nothing under it once a route
    -- is known; "[measuring...]" appears only for a route never timed
    timerFrame.learningLabel:Hide()

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
    if FTT.ClearActiveFlight then FTT:ClearActiveFlight() end
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
        -- estimate was too short: keep a full bar until we actually land
        if UnitOnTaxi and UnitOnTaxi("player") then
            this.bar:SetValue(flightDuration)
            this.text:SetText(L["ARRIVING"] or "Arriving...")
            FTT:UpdateWaypoints(elapsedTime)
            this.bar.spark:Hide()
            return
        end
        FTT:StopFlightTimer()
        return
    end
    this.bar.spark:Show()

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
            -- the route keeps being measured (the average gets better), but
            -- "[measuring...]" is only shown while it has no measured time yet
            if timerFrame:IsShown() and not HasMeasurement(measureFrom, measureTo) then
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

            if timerFrame.learningLabel then timerFrame.learningLabel:Hide() end
        elseif measureTimeout > 1800 then
            measureActive = false
            measurePending = false
            measureStartTime = nil
            measureFrom = nil
            measureTo = nil
            measureTimeout = 0
        end
    end

    if not measurePending and not measureActive then
        this:Hide()
    end
end)

function FTT.ClearMeasured()
    local count = 0
    for _ in pairs(FlyTimesDB.measured or {}) do count = count + 1 end
    FlyTimesDB.measured = {}
    FlyTimesDB.measured_legs = nil
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s:|r " .. (L["MEASURED_ROUTES_CLEARED"] or "Cleared %d measured routes"),
        L["ADDON_NAME"] or "FlyTimes", count))
end

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

            -- load line without the version (that is in the options window)
            local msgL = FTT.L or {}
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s|r by %s %s",
                msgL["ADDON_NAME"] or "FlyTimes",
                FTT.AUTHOR or "Unknown",
                msgL["LOADED"] or "loaded! Use /ft for options."))

            if FTT.BarStyles then
                if not (FlyTimesDB.barStyle and FTT.BarStyles.styles[FlyTimesDB.barStyle]) then
                    FlyTimesDB.barStyle = "classic"
                end
                FTT.BarStyles:ApplyStyle(FlyTimesDB.barStyle, timerFrame)
            end
            SizeSpark()
        end

    elseif event == "TAXIMAP_OPENED" then
        FTT:ReadLiveRoutes()
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
            local live = FlyTimesDB.liveRoutes and FlyTimesDB.liveRoutes[fromName]
            if not (live and live[toName]) then FTT:ReadLiveRoutes() end
            local duration = FTT:GetFlightTime(fromName, toName)
            if duration then
                local measured = GetMeasuredTime(fromName, toName)
                local label = measured and (L["TOOLTIP_FLIGHT_TIME_MEASURED"] or "Flight time (measured):")
                                      or (L["TOOLTIP_FLIGHT_TIME"] or "Flight time:")
                GameTooltip:AddLine("|cffFFD700" .. label .. "|r " .. FormatTime(duration), 1, 1, 1)

                local stops = FTT:GetRouteStops(fromName, toName)
                if stops and getn(stops) > 0 then
                    local parts = {}
                    for _, stop in ipairs(stops) do
                        table.insert(parts, (string.gsub(stop, "(%,.*)", "")))
                    end
                    local stopsLine = table.concat(parts, " > ")
                    if FTT.routeFromMap == false then
                        -- not read from this flight map: from the built-in table
                        stopsLine = stopsLine .. " |cff808080(" .. (L["TOOLTIP_STOPS_EST"] or "estimated") .. ")|r"
                    end
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

    if string.find(msg, "^style") then
        local styleName = smatch(msg, "^style%s+(.+)")
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

    if string.find(msg, "^route") then
        local routeName = smatch(msg, "^route%s+(.+)")
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
    elseif msg == "clearmeasured" then
        FTT.ClearMeasured()
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
        local nLive = 0
        if FlyTimesDB.liveRoutes then for _, v in pairs(FlyTimesDB.liveRoutes) do for _ in pairs(v) do nLive = nLive + 1 end end end
        local cv = "n/a"
        if FTT.cvarStatus then cv = FTT.cvarStatus() end
        DEFAULT_CHAT_FRAME:AddMessage("  Reload store: " .. cv)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Route API (GetNumRoutes/TaxiGetDestX): %s, routes read from flight maps: %d",
            (GetNumRoutes and TaxiGetDestX) and "yes" or "NO", nLive))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Pending: %s, Active: %s", tostring(measurePending), tostring(measureActive)))
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
        DEFAULT_CHAT_FRAME:AddMessage("  /ft route <partial> - Show route with stops")
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_DEBUG"] or "/ft debug - Show taxi debug info"))
        DEFAULT_CHAT_FRAME:AddMessage("  " .. (L["CMD_HELP"] or "Drag the bar to move it"))
    end
end


-- =====================================================
--  KEEP THE BAR OVER /reload
-- =====================================================
-- The flight is stored in a client variable (CVar): it survives a UI
-- reload, while SavedVariables on this client are only written on exit.
-- GetTime() keeps counting across a reload, so the bar resumes in place.

local CVAR = "FlyTimesActiveFlight"
local SEP = "~"
local hasCVar = false
do
    -- after a reload the CVar already exists: do not register it again,
    -- that could reset it to the default
    local ok, v = pcall(GetCVar, CVAR)
    if ok and v ~= nil then
        hasCVar = true
    elseif RegisterCVar then
        hasCVar = pcall(RegisterCVar, CVAR, "")
    end
end

-- the take-off is stored as wall-clock time (time()): GetTime() may start
-- again from zero after a reload on this client
function FTT:SaveActiveFlight(startedAt, duration, fromNode, toNode)
    -- without time() keep GetTime() ("g" marks it)
    local wall = time and (time() - (GetTime() - startedAt)) or nil
    if not wall then
        local v = string.format("g%.1f%s%d%s%s%s%s", startedAt, SEP, duration, SEP, fromNode or "?", SEP, toNode or "?")
        if hasCVar then FTT.cvarSaved = pcall(SetCVar, CVAR, v) end
        if FlyTimesDB then FlyTimesDB.activeFlight = v end
        return
    end
    local v = string.format("%d%s%d%s%s%s%s", wall, SEP, duration, SEP, fromNode or "?", SEP, toNode or "?")
    FTT.cvarSaved = false
    if hasCVar then
        FTT.cvarSaved = pcall(SetCVar, CVAR, v)
    end
    if FlyTimesDB then FlyTimesDB.activeFlight = v end
end

function FTT:ClearActiveFlight()
    if hasCVar then pcall(SetCVar, CVAR, "") end
    if FlyTimesDB then FlyTimesDB.activeFlight = nil end
end

local function readActiveFlight()
    local v
    if hasCVar then
        local ok, c = pcall(GetCVar, CVAR)
        if ok and c and c ~= "" then v = c end
    end
    v = v or (FlyTimesDB and FlyTimesDB.activeFlight)
    if not v then return nil end
    local _, _, g, wall, dur, from, to = string.find(v, "^(g?)([%d%.]+)~(%d+)~(.-)~(.*)$")
    if not wall then return nil end
    local st
    if g == "g" then
        st = tonumber(wall)
    elseif time then
        -- back to this session's GetTime() scale
        st = GetTime() - (time() - tonumber(wall))
    else
        return nil
    end
    return st, tonumber(dur), from, to
end
FTT.ReadActiveFlight = readActiveFlight

function FTT:RestoreFlight()
    if flightStartTime then return true end -- already running
    local st, dur, from, to = readActiveFlight()
    if not st then return true end
    local onTaxi = UnitOnTaxi and UnitOnTaxi("player")
    local now = GetTime()
    if now - st > dur + 120 then
        FTT:ClearActiveFlight() -- an old entry
        return true
    end
    if not onTaxi then return false end -- not (yet) reported on the taxi: try again
    FTT:StartFlightTimer(dur, from, to, st)
    -- keep measuring this flight too, from its real take-off time
    if FlyTimesDB.learningEnabled and from ~= "?" and to ~= "?" then
        measureFrom, measureTo = from, to
        measurePending, measureActive = false, true
        measureStartTime = st
        measureTimeout = 0
        measureFrame.elapsed = 0
        measureFrame:Show()
    end
    return true
end

local restoreFrame = CreateFrame("Frame")
restoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
restoreFrame:SetScript("OnEvent", function()
    -- after a reload UnitOnTaxi may need a while to report the taxi:
    -- check every half second for up to 15 seconds
    this.wait, this.tries = 0.5, 30
    this:SetScript("OnUpdate", function()
        this.wait = this.wait - (arg1 or 0)
        if this.wait > 0 then return end
        this.wait = 0.5
        this.tries = this.tries - 1
        local done = FTT:RestoreFlight()
        if done or flightStartTime or this.tries <= 0 then
            this:SetScript("OnUpdate", nil)
            if not done and not flightStartTime and readActiveFlight() then
                FTT:ClearActiveFlight() -- landed during the reload
            end
        end
    end)
end)

-- for /ft debug: can the flight be kept over a reload on this client?
function FTT.cvarStatus()
    local t = "RegisterCVar " .. (RegisterCVar and "yes" or "NO")
    t = t .. ", cvar " .. (hasCVar and "ok" or "FAILED")
    local ok, v = pcall(GetCVar, CVAR)
    t = t .. ", value '" .. tostring(ok and v or "?") .. "'"
    t = t .. ", GetTime " .. string.format("%.0f", GetTime())
    return t
end
