-- FlightRoutes.lua
-- Intermediate stops (multi-hop routes) for version 1.12.1
-- Source: Defaults.lua (DBC TaxiPathNode data) + Emberveil-specific corrections + Wowx5.ru data
-- Format: [start_point][destination] = { list_of_intermediate_stops }

FlyTimes = FlyTimes or {}
FlyTimes.FlightRoutes = FlyTimes.FlightRoutes or {}
FlyTimes.FlightRoutes["CLASSIC"] = FlyTimes.FlightRoutes["CLASSIC"] or {}

-- ============================================================
-- HORDE
-- ============================================================
FlyTimes.FlightRoutes["CLASSIC"]["Horde"] = {

    ["Marshal's Refuge, Un'Goro Crater"] = {
        ["Everlook, Winterspring"] = {"Gadgetzan, Tanaris", "Freewind Post, Thousand Needles", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Camp Taurajo, The Barrens"] = {"Gadgetzan, Tanaris", "Freewind Post, Thousand Needles"},
        ["Valormok, Azshara"] = {"Gadgetzan, Tanaris", "Thunder Bluff, Mulgore"},
        ["Shadowprey Village, Desolace"] = {"Cenarion Hold, Silithus", "Camp Mojache, Feralas"},
        ["Ratchet, The Barrens"] = {"Gadgetzan, Tanaris", "Crossroads, The Barrens"},
        ["Splintertree Post, Ashenvale"] = {"Gadgetzan, Tanaris", "Freewind Post, Thousand Needles", "Crossroads, The Barrens"},
        ["Bloodvenom Post, Felwood"] = {"Gadgetzan, Tanaris", "Freewind Post, Thousand Needles", "Crossroads, The Barrens"},
        ["Sun Rock Retreat, Stonetalon Mountains"] = {"Gadgetzan, Tanaris", "Freewind Post, Thousand Needles", "Crossroads, The Barrens"},
        ["Nighthaven, Moonglade"] = {"Gadgetzan, Tanaris", "Freewind Post, Thousand Needles", "Crossroads, The Barrens", "Bloodvenom Post, Felwood"},
        ["Orgrimmar, Durotar"] = {"Gadgetzan, Tanaris"},
        ["Crossroads, The Barrens"] = {"Gadgetzan, Tanaris", "Freewind Post, Thousand Needles"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Gadgetzan, Tanaris", "Freewind Post, Thousand Needles", "Crossroads, The Barrens"},
    },

    ["Everlook, Winterspring"] = {
        ["Marshal's Refuge, Un'Goro Crater"] = {"Valormok, Azshara", "Crossroads, The Barrens", "Freewind Post, Thousand Needles", "Gadgetzan, Tanaris"},
        ["Gadgetzan, Tanaris"] = {"Valormok, Azshara", "Orgrimmar, Durotar"},
        ["Thunder Bluff, Mulgore"] = {"Valormok, Azshara"},
        ["Camp Taurajo, The Barrens"] = {"Valormok, Azshara", "Crossroads, The Barrens"},
        ["Shadowprey Village, Desolace"] = {"Valormok, Azshara", "Thunder Bluff, Mulgore"},
        ["Ratchet, The Barrens"] = {"Valormok, Azshara", "Orgrimmar, Durotar", "Crossroads, The Barrens"},
        ["Freewind Post, Thousand Needles"] = {"Valormok, Azshara", "Crossroads, The Barrens", "Camp Taurajo, The Barrens"},
        ["Camp Mojache, Feralas"] = {"Valormok, Azshara", "Thunder Bluff, Mulgore"},
        ["Sun Rock Retreat, Stonetalon Mountains"] = {"Valormok, Azshara", "Thunder Bluff, Mulgore"},
        ["Brackenwall Village, Dustwallow Marsh"] = {"Valormok, Azshara", "Crossroads, The Barrens", "Camp Taurajo, The Barrens"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Valormok, Azshara", "Splintertree Post, Ashenvale"},
    },

    ["Gadgetzan, Tanaris"] = {
        ["Everlook, Winterspring"] = {"Freewind Post, Thousand Needles", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Thunder Bluff, Mulgore"] = {"Freewind Post, Thousand Needles", "Camp Taurajo, The Barrens"},
        ["Splintertree Post, Ashenvale"] = {"Freewind Post, Thousand Needles", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Bloodvenom Post, Felwood"] = {"Freewind Post, Thousand Needles", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Sun Rock Retreat, Stonetalon Mountains"] = {"Freewind Post, Thousand Needles", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Nighthaven, Moonglade"] = {"Freewind Post, Thousand Needles", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Orgrimmar, Durotar"] = {},
        ["Brackenwall Village, Dustwallow Marsh"] = {"Freewind Post, Thousand Needles", "Camp Taurajo, The Barrens"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Freewind Post, Thousand Needles", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Shadowprey Village, Desolace"] = {"Freewind Post, Thousand Needles", "Camp Taurajo, The Barrens", "Thunder Bluff, Mulgore"},
        ["Valormok, Azshara"] = {"Thunder Bluff, Mulgore"},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
    },

    ["Orgrimmar, Durotar"] = {
        ["Marshal's Refuge, Un'Goro Crater"] = {"Gadgetzan, Tanaris"},
        ["Everlook, Winterspring"] = {"Valormok, Azshara"},
        ["Thunder Bluff, Mulgore"] = {},
        ["Camp Mojache, Feralas"] = {"Thunder Bluff, Mulgore"},
        ["Shadowprey Village, Desolace"] = {"Thunder Bluff, Mulgore"},
        ["Freewind Post, Thousand Needles"] = {"Thunder Bluff, Mulgore"},
        ["Gadgetzan, Tanaris"] = {},
        ["Bloodvenom Post, Felwood"] = {},
        ["Sun Rock Retreat, Stonetalon Mountains"] = {"Thunder Bluff, Mulgore"},
        ["Nighthaven, Moonglade"] = {"Splintertree Post, Ashenvale", "Bloodvenom Post, Felwood"},
        ["Brackenwall Village, Dustwallow Marsh"] = {},
        ["Zoram'gar Outpost, Ashenvale"] = {"Crossroads, The Barrens"},
        ["Camp Taurajo, The Barrens"] = {"Thunder Bluff, Mulgore"},
        ["Cenarion Hold, Silithus"] = {"Gadgetzan, Tanaris"},
        ["Ratchet, The Barrens"] = {},
        ["Splintertree Post, Ashenvale"] = {"Crossroads, The Barrens"},
        ["Valormok, Azshara"] = {},
        ["Light's Hope Chapel, Eastern Plaguelands"] = {"Undercity, Tirisfal"},
    },

    ["Crossroads, The Barrens"] = {
        ["Marshal's Refuge, Un'Goro Crater"] = {"Gadgetzan, Tanaris", "Freewind Post, Thousand Needles"},
        ["Everlook, Winterspring"] = {"Valormok, Azshara"},
        ["Thunder Bluff, Mulgore"] = {"Camp Taurajo, The Barrens"},
        ["Camp Mojache, Feralas"] = {"Freewind Post, Thousand Needles"},
        ["Shadowprey Village, Desolace"] = {"Thunder Bluff, Mulgore"},
        ["Gadgetzan, Tanaris"] = {"Freewind Post, Thousand Needles"},
        ["Nighthaven, Moonglade"] = {"Bloodvenom Post, Felwood"},
        ["Brackenwall Village, Dustwallow Marsh"] = {"Camp Taurajo, The Barrens"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Splintertree Post, Ashenvale"},
        ["Valormok, Azshara"] = {},
    },

    ["Ratchet, The Barrens"] = {
        ["Everlook, Winterspring"] = {"Crossroads, The Barrens", "Orgrimmar, Durotar", "Valormok, Azshara"},
        ["Bloodvenom Post, Felwood"] = {"Crossroads, The Barrens"},
        ["Splintertree Post, Ashenvale"] = {"Crossroads, The Barrens"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Crossroads, The Barrens"},
        ["Sun Rock Retreat, Stonetalon Mountains"] = {"Crossroads, The Barrens"},
        ["Thunder Bluff, Mulgore"] = {"Crossroads, The Barrens"},
        ["Camp Taurajo, The Barrens"] = {"Crossroads, The Barrens"},
        ["Gadgetzan, Tanaris"] = {"Crossroads, The Barrens"},
        ["Freewind Post, Thousand Needles"] = {"Crossroads, The Barrens"},
        ["Marshal's Refuge, Un'Goro Crater"] = {"Crossroads, The Barrens", "Gadgetzan, Tanaris"},
        ["Cenarion Hold, Silithus"] = {"Crossroads, The Barrens", "Gadgetzan, Tanaris"},
        ["Camp Mojache, Feralas"] = {"Crossroads, The Barrens"},
        ["Shadowprey Village, Desolace"] = {"Crossroads, The Barrens", "Thunder Bluff, Mulgore"},
        ["Valormok, Azshara"] = {"Crossroads, The Barrens"},
        ["Nighthaven, Moonglade"] = {"Crossroads, The Barrens", "Bloodvenom Post, Felwood"},
        ["Orgrimmar, Durotar"] = {},
    },

    ["Splintertree Post, Ashenvale"] = {
        ["Marshal's Refuge, Un'Goro Crater"] = {"Crossroads, The Barrens", "Freewind Post, Thousand Needles", "Gadgetzan, Tanaris"},
        ["Everlook, Winterspring"] = {"Valormok, Azshara"},
        ["Thunder Bluff, Mulgore"] = {"Sun Rock Retreat, Stonetalon Mountains"},
        ["Camp Mojache, Feralas"] = {"Sun Rock Retreat, Stonetalon Mountains", "Freewind Post, Thousand Needles"},
        ["Shadowprey Village, Desolace"] = {"Sun Rock Retreat, Stonetalon Mountains"},
        ["Gadgetzan, Tanaris"] = {"Crossroads, The Barrens", "Freewind Post, Thousand Needles"},
        ["Nighthaven, Moonglade"] = {"Bloodvenom Post, Felwood"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Valormok, Azshara"},
        ["Valormok, Azshara"] = {},
        ["Orgrimmar, Durotar"] = {"Crossroads, The Barrens"},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
    },

    ["Valormok, Azshara"] = {
        ["Thunder Bluff, Mulgore"] = {},
        ["Camp Taurajo, The Barrens"] = {"Thunder Bluff, Mulgore"},
        ["Brackenwall Village, Dustwallow Marsh"] = {"Thunder Bluff, Mulgore", "Camp Taurajo, The Barrens"},
        ["Freewind Post, Thousand Needles"] = {"Thunder Bluff, Mulgore"},
        ["Cenarion Hold, Silithus"] = {"Thunder Bluff, Mulgore", "Gadgetzan, Tanaris"},
        ["Shadowprey Village, Desolace"] = {"Thunder Bluff, Mulgore"},
        ["Camp Mojache, Feralas"] = {"Thunder Bluff, Mulgore"},
        ["Sun Rock Retreat, Stonetalon Mountains"] = {"Thunder Bluff, Mulgore"},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
        ["Marshal's Refuge, Un'Goro Crater"] = {"Thunder Bluff, Mulgore", "Gadgetzan, Tanaris"},
        ["Orgrimmar, Durotar"] = {},
        ["Crossroads, The Barrens"] = {},
        ["Gadgetzan, Tanaris"] = {"Thunder Bluff, Mulgore"},
        ["Everlook, Winterspring"] = {},
        ["Zoram'gar Outpost, Ashenvale"] = {"Splintertree Post, Ashenvale"},
        ["Nighthaven, Moonglade"] = {"Everlook, Winterspring"},
    },

    ["Thunder Bluff, Mulgore"] = {
        ["Marshal's Refuge, Un'Goro Crater"] = {"Camp Taurajo, The Barrens", "Freewind Post, Thousand Needles", "Gadgetzan, Tanaris"},
        ["Everlook, Winterspring"] = {"Valormok, Azshara"},
        ["Camp Mojache, Feralas"] = {"Freewind Post, Thousand Needles"},
        ["Gadgetzan, Tanaris"] = {"Camp Taurajo, The Barrens", "Freewind Post, Thousand Needles"},
        ["Nighthaven, Moonglade"] = {"Valormok, Azshara", "Everlook, Winterspring"},
        ["Bloodvenom Post, Felwood"] = {"Crossroads, The Barrens"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Sun Rock Retreat, Stonetalon Mountains", "Splintertree Post, Ashenvale"},
        ["Cenarion Hold, Silithus"] = {"Camp Taurajo, The Barrens", "Freewind Post, Thousand Needles", "Gadgetzan, Tanaris", "Marshal's Refuge, Un'Goro Crater"},
        ["Orgrimmar, Durotar"] = {},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
        ["Splintertree Post, Ashenvale"] = {"Sun Rock Retreat, Stonetalon Mountains"},
        ["Valormok, Azshara"] = {},
    },

    ["Freewind Post, Thousand Needles"] = {
        ["Everlook, Winterspring"] = {"Camp Taurajo, The Barrens", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Nighthaven, Moonglade"] = {"Crossroads, The Barrens", "Bloodvenom Post, Felwood"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Crossroads, The Barrens", "Splintertree Post, Ashenvale"},
        ["Valormok, Azshara"] = {"Thunder Bluff, Mulgore"},
        ["Orgrimmar, Durotar"] = {"Thunder Bluff, Mulgore"},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
    },

    ["Camp Taurajo, The Barrens"] = {
        ["Everlook, Winterspring"] = {"Crossroads, The Barrens", "Valormok, Azshara"},
        ["Nighthaven, Moonglade"] = {"Crossroads, The Barrens", "Bloodvenom Post, Felwood"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Crossroads, The Barrens", "Splintertree Post, Ashenvale"},
        ["Valormok, Azshara"] = {"Thunder Bluff, Mulgore"},
        ["Orgrimmar, Durotar"] = {"Thunder Bluff, Mulgore"},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
    },

    ["Camp Mojache, Feralas"] = {
        ["Everlook, Winterspring"] = {"Thunder Bluff, Mulgore", "Valormok, Azshara"},
        ["Nighthaven, Moonglade"] = {"Thunder Bluff, Mulgore", "Crossroads, The Barrens", "Bloodvenom Post, Felwood"},
        ["Valormok, Azshara"] = {"Thunder Bluff, Mulgore"},
        ["Orgrimmar, Durotar"] = {"Thunder Bluff, Mulgore"},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
    },

    ["Shadowprey Village, Desolace"] = {
        ["Gadgetzan, Tanaris"] = {"Thunder Bluff, Mulgore", "Camp Taurajo, The Barrens", "Freewind Post, Thousand Needles"},
        ["Freewind Post, Thousand Needles"] = {"Thunder Bluff, Mulgore", "Camp Taurajo, The Barrens"},
        ["Camp Taurajo, The Barrens"] = {"Thunder Bluff, Mulgore"},
        ["Marshal's Refuge, Un'Goro Crater"] = {"Thunder Bluff, Mulgore", "Camp Taurajo, The Barrens", "Freewind Post, Thousand Needles", "Gadgetzan, Tanaris"},
        ["Cenarion Hold, Silithus"] = {"Thunder Bluff, Mulgore", "Camp Taurajo, The Barrens", "Freewind Post, Thousand Needles", "Gadgetzan, Tanaris", "Marshal's Refuge, Un'Goro Crater"},
        ["Thunder Bluff, Mulgore"] = {},
        ["Orgrimmar, Durotar"] = {"Thunder Bluff, Mulgore"},
        ["Crossroads, The Barrens"] = {"Thunder Bluff, Mulgore", "Camp Taurajo, The Barrens"},
        ["Ratchet, The Barrens"] = {"Thunder Bluff, Mulgore", "Crossroads, The Barrens"},
        ["Brackenwall Village, Dustwallow Marsh"] = {"Thunder Bluff, Mulgore", "Camp Taurajo, The Barrens"},
        ["Splintertree Post, Ashenvale"] = {"Thunder Bluff, Mulgore", "Camp Taurajo, The Barrens", "Crossroads, The Barrens"},
        ["Sun Rock Retreat, Stonetalon Mountains"] = {"Thunder Bluff, Mulgore"},
        ["Camp Mojache, Feralas"] = {"Thunder Bluff, Mulgore", "Freewind Post, Thousand Needles"},
        ["Everlook, Winterspring"] = {"Thunder Bluff, Mulgore", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Nighthaven, Moonglade"] = {"Thunder Bluff, Mulgore", "Crossroads, The Barrens", "Bloodvenom Post, Felwood"},
        ["Zoram'gar Outpost, Ashenvale"] = {"Thunder Bluff, Mulgore", "Crossroads, The Barrens", "Splintertree Post, Ashenvale"},
        ["Valormok, Azshara"] = {"Thunder Bluff, Mulgore"},
    },

    ["Brackenwall Village, Dustwallow Marsh"] = {
        ["Everlook, Winterspring"] = {"Camp Taurajo, The Barrens", "Crossroads, The Barrens", "Valormok, Azshara"},
        ["Nighthaven, Moonglade"] = {"Crossroads, The Barrens", "Bloodvenom Post, Felwood"},
        ["Valormok, Azshara"] = {"Camp Taurajo, The Barrens", "Thunder Bluff, Mulgore"},
        ["Orgrimmar, Durotar"] = {},
    },

    ["Bloodvenom Post, Felwood"] = {
        ["Marshal's Refuge, Un'Goro Crater"] = {"Crossroads, The Barrens", "Freewind Post, Thousand Needles", "Gadgetzan, Tanaris"},
        ["Everlook, Winterspring"] = {"Valormok, Azshara"},
        ["Thunder Bluff, Mulgore"] = {"Crossroads, The Barrens", "Camp Taurajo, The Barrens"},
        ["Gadgetzan, Tanaris"] = {"Crossroads, The Barrens", "Freewind Post, Thousand Needles"},
        ["Orgrimmar, Durotar"] = {},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
    },

    ["Sun Rock Retreat, Stonetalon Mountains"] = {
        ["Marshal's Refuge, Un'Goro Crater"] = {"Crossroads, The Barrens", "Freewind Post, Thousand Needles", "Gadgetzan, Tanaris"},
        ["Everlook, Winterspring"] = {"Thunder Bluff, Mulgore", "Valormok, Azshara"},
        ["Thunder Bluff, Mulgore"] = {},
        ["Gadgetzan, Tanaris"] = {"Crossroads, The Barrens", "Freewind Post, Thousand Needles"},
        ["Valormok, Azshara"] = {"Thunder Bluff, Mulgore"},
        ["Orgrimmar, Durotar"] = {"Thunder Bluff, Mulgore"},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
    },

    ["Zoram'gar Outpost, Ashenvale"] = {
        ["Marshal's Refuge, Un'Goro Crater"] = {"Splintertree Post, Ashenvale", "Crossroads, The Barrens", "Freewind Post, Thousand Needles", "Gadgetzan, Tanaris"},
        ["Everlook, Winterspring"] = {"Splintertree Post, Ashenvale", "Valormok, Azshara"},
        ["Thunder Bluff, Mulgore"] = {"Splintertree Post, Ashenvale", "Sun Rock Retreat, Stonetalon Mountains"},
        ["Gadgetzan, Tanaris"] = {"Splintertree Post, Ashenvale", "Crossroads, The Barrens", "Freewind Post, Thousand Needles"},
        ["Orgrimmar, Durotar"] = {"Crossroads, The Barrens"},
        ["Ratchet, The Barrens"] = {"Crossroads, The Barrens"},
    },

    ["Cenarion Hold, Silithus"] = {
        ["Valormok, Azshara"] = {"Gadgetzan, Tanaris", "Thunder Bluff, Mulgore"},
        ["Orgrimmar, Durotar"] = {"Gadgetzan, Tanaris"},
        ["Ratchet, The Barrens"] = {"Gadgetzan, Tanaris", "Crossroads, The Barrens"},
    },

    ["Nighthaven, Moonglade"] = {
        ["Ratchet, The Barrens"] = {"Bloodvenom Post, Felwood", "Crossroads, The Barrens"},
    },
}

-- ============================================================
-- ALLIANCE
-- ============================================================
FlyTimes.FlightRoutes["CLASSIC"]["Alliance"] = {

    ["Stormwind, Elwynn"] = {
        ["Refuge Pointe, Arathi"] = {"Ironforge, Dun Morogh", "Menethil Harbor, Wetlands"},
        ["Southshore, Hillsbrad"] = {"Ironforge, Dun Morogh", "Menethil Harbor, Wetlands"},
        ["Aerie Peak, The Hinterlands"] = {"Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad"},
        ["Chillwind Camp, Western Plaguelands"] = {"Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad"},
        ["Light's Hope Chapel, Eastern Plaguelands"] = {"Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad", "Chillwind Camp, Western Plaguelands"},
        ["Thorium Point, Searing Gorge"] = {"Ironforge, Dun Morogh"},
        ["Booty Bay, Stranglethorn"] = {"Darkshire, Duskwood"},
        ["Nethergarde Keep, Blasted Lands"] = {"Darkshire, Duskwood"},
        ["Darkshire, Duskwood"] = {},
        ["Ironforge, Dun Morogh"] = {},
        ["Lakeshire, Redridge"] = {},
        ["Morgan's Vigil, Burning Steppes"] = {"Lakeshire, Redridge"},
        ["Thelsamar, Loch Modan"] = {"Ironforge, Dun Morogh"},
    },

    ["Ironforge, Dun Morogh"] = {
        ["Booty Bay, Stranglethorn"] = {"Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Light's Hope Chapel, Eastern Plaguelands"] = {"Menethil Harbor, Wetlands", "Southshore, Hillsbrad", "Chillwind Camp, Western Plaguelands"},
        ["Nethergarde Keep, Blasted Lands"] = {"Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Refuge Pointe, Arathi"] = {"Menethil Harbor, Wetlands"},
        ["Sentinel Hill, Westfall"] = {"Stormwind, Elwynn"},
        ["Southshore, Hillsbrad"] = {"Menethil Harbor, Wetlands"},
        ["Aerie Peak, The Hinterlands"] = {"Menethil Harbor, Wetlands", "Southshore, Hillsbrad"},
        ["Chillwind Camp, Western Plaguelands"] = {"Menethil Harbor, Wetlands", "Southshore, Hillsbrad", "Aerie Peak, The Hinterlands"},
        ["Darkshire, Duskwood"] = {"Stormwind, Elwynn"},
        ["Lakeshire, Redridge"] = {"Stormwind, Elwynn"},
        ["Morgan's Vigil, Burning Steppes"] = {"Stormwind, Elwynn", "Lakeshire, Redridge"},
    },

    ["Menethil Harbor, Wetlands"] = {
        ["Booty Bay, Stranglethorn"] = {"Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Light's Hope Chapel, Eastern Plaguelands"] = {"Southshore, Hillsbrad", "Chillwind Camp, Western Plaguelands"},
        ["Nethergarde Keep, Blasted Lands"] = {"Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Sentinel Hill, Westfall"] = {"Ironforge, Dun Morogh", "Stormwind, Elwynn"},
        ["Stormwind, Elwynn"] = {"Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Ironforge, Dun Morogh"},
    },

    ["Darkshire, Duskwood"] = {
        ["Aerie Peak, The Hinterlands"] = {"Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad"},
        ["Ironforge, Dun Morogh"] = {"Stormwind, Elwynn"},
        ["Light's Hope Chapel, Eastern Plaguelands"] = {"Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad", "Chillwind Camp, Western Plaguelands"},
        ["Menethil Harbor, Wetlands"] = {"Stormwind, Elwynn", "Ironforge, Dun Morogh"},
        ["Refuge Pointe, Arathi"] = {"Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands"},
        ["Southshore, Hillsbrad"] = {"Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands"},
        ["Thelsamar, Loch Modan"] = {"Stormwind, Elwynn", "Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Stormwind, Elwynn", "Ironforge, Dun Morogh"},
    },

    ["Booty Bay, Stranglethorn"] = {
        ["Aerie Peak, The Hinterlands"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad"},
        ["Chillwind Camp, Western Plaguelands"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad"},
        ["Ironforge, Dun Morogh"] = {"Darkshire, Duskwood", "Stormwind, Elwynn"},
        ["Lakeshire, Redridge"] = {"Darkshire, Duskwood"},
        ["Light's Hope Chapel, Eastern Plaguelands"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad", "Chillwind Camp, Western Plaguelands"},
        ["Menethil Harbor, Wetlands"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh"},
        ["Morgan's Vigil, Burning Steppes"] = {"Darkshire, Duskwood"},
        ["Nethergarde Keep, Blasted Lands"] = {"Darkshire, Duskwood"},
        ["Refuge Pointe, Arathi"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands"},
        ["Sentinel Hill, Westfall"] = {"Darkshire, Duskwood", "Stormwind, Elwynn"},
        ["Southshore, Hillsbrad"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands"},
        ["Stormwind, Elwynn"] = {"Darkshire, Duskwood"},
        ["Thelsamar, Loch Modan"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh"},
    },

    ["Refuge Pointe, Arathi"] = {
        ["Booty Bay, Stranglethorn"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Light's Hope Chapel, Eastern Plaguelands"] = {"Southshore, Hillsbrad", "Chillwind Camp, Western Plaguelands"},
        ["Nethergarde Keep, Blasted Lands"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Sentinel Hill, Westfall"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn"},
        ["Stormwind, Elwynn"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
    },

    ["Southshore, Hillsbrad"] = {
        ["Booty Bay, Stranglethorn"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Nethergarde Keep, Blasted Lands"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Sentinel Hill, Westfall"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn"},
        ["Stormwind, Elwynn"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
    },

    ["Aerie Peak, The Hinterlands"] = {
        ["Booty Bay, Stranglethorn"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Nethergarde Keep, Blasted Lands"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Sentinel Hill, Westfall"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn"},
        ["Stormwind, Elwynn"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
    },

    ["Chillwind Camp, Western Plaguelands"] = {
        ["Booty Bay, Stranglethorn"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Nethergarde Keep, Blasted Lands"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Sentinel Hill, Westfall"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn"},
        ["Stormwind, Elwynn"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
    },

    ["Light's Hope Chapel, Eastern Plaguelands"] = {
        ["Booty Bay, Stranglethorn"] = {"Chillwind Camp, Western Plaguelands", "Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Nethergarde Keep, Blasted Lands"] = {"Chillwind Camp, Western Plaguelands", "Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Sentinel Hill, Westfall"] = {"Chillwind Camp, Western Plaguelands", "Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh", "Stormwind, Elwynn"},
        ["Stormwind, Elwynn"] = {"Chillwind Camp, Western Plaguelands", "Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Chillwind Camp, Western Plaguelands", "Southshore, Hillsbrad", "Menethil Harbor, Wetlands", "Ironforge, Dun Morogh"},
    },

    ["Morgan's Vigil, Burning Steppes"] = {
        ["Booty Bay, Stranglethorn"] = {"Lakeshire, Redridge", "Darkshire, Duskwood"},
        ["Nethergarde Keep, Blasted Lands"] = {"Lakeshire, Redridge", "Darkshire, Duskwood"},
        ["Sentinel Hill, Westfall"] = {"Lakeshire, Redridge", "Stormwind, Elwynn"},
        ["Thelsamar, Loch Modan"] = {"Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Ironforge, Dun Morogh"},
    },

    ["Nethergarde Keep, Blasted Lands"] = {
        ["Aerie Peak, The Hinterlands"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad"},
        ["Booty Bay, Stranglethorn"] = {"Darkshire, Duskwood"},
        ["Chillwind Camp, Western Plaguelands"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad"},
        ["Ironforge, Dun Morogh"] = {"Darkshire, Duskwood", "Stormwind, Elwynn"},
        ["Light's Hope Chapel, Eastern Plaguelands"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad", "Chillwind Camp, Western Plaguelands"},
        ["Menethil Harbor, Wetlands"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh"},
        ["Refuge Pointe, Arathi"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands"},
        ["Sentinel Hill, Westfall"] = {"Darkshire, Duskwood", "Stormwind, Elwynn"},
        ["Southshore, Hillsbrad"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh", "Menethil Harbor, Wetlands"},
        ["Stormwind, Elwynn"] = {"Darkshire, Duskwood"},
        ["Thelsamar, Loch Modan"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh"},
        ["Thorium Point, Searing Gorge"] = {"Darkshire, Duskwood", "Stormwind, Elwynn", "Ironforge, Dun Morogh"},
    },

    ["Thorium Point, Searing Gorge"] = {
        ["Booty Bay, Stranglethorn"] = {"Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Light's Hope Chapel, Eastern Plaguelands"] = {"Ironforge, Dun Morogh", "Menethil Harbor, Wetlands", "Southshore, Hillsbrad", "Chillwind Camp, Western Plaguelands"},
        ["Nethergarde Keep, Blasted Lands"] = {"Ironforge, Dun Morogh", "Stormwind, Elwynn", "Darkshire, Duskwood"},
        ["Sentinel Hill, Westfall"] = {"Ironforge, Dun Morogh", "Stormwind, Elwynn"},
    },
}