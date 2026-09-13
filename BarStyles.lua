-- FlyTimes Bar Styles
-- 10 customizable bar themes

FlyTimes = FlyTimes or {}
FlyTimes.BarStyles = {}

-- Style definitions
FlyTimes.BarStyles.styles = {
    
    -- 1. NEON (Cyberpunk glowing style)
    ["neon"] = {
        name = "Neon",
        description = "Glowing cyberpunk style with neon colors",
        barColor = {0.3, 1.0, 1.0}, -- Cyan
        barBgColor = {0.0, 0.2, 0.3, 0.6},
        frameColor = {0.0, 0.0, 0.0, 0.9},
        borderColor = {0.3, 1.0, 1.0, 1.0}, -- Cyan border
        textColor = {0.3, 1.0, 1.0}, -- Cyan text
        glowColor = {0.3, 1.0, 1.0, 0.5}, -- Cyan glow
        sparkColor = {1.0, 1.0, 1.0},
        hasGlow = true,
        hasBorder = true,
    },
    
    -- 2. CLASSIC (Original WoW style)
    ["classic"] = {
        name = "Classic",
        description = "Traditional WoW interface style",
        barColor = {0.2, 0.6, 1.0}, -- Blue
        barBgColor = {0.1, 0.1, 0.1, 0.5},
        frameColor = {0.0, 0.0, 0.0, 0.8},
        borderColor = {0.3, 0.3, 0.3, 1.0},
        textColor = {1.0, 1.0, 1.0},
        glowColor = nil,
        sparkColor = {1.0, 1.0, 1.0},
        hasGlow = false,
        hasBorder = true,
    },
    
    -- 3. MINIMALIST (Clean and simple)
    ["minimalist"] = {
        name = "Minimalist",
        description = "Clean, simple design",
        barColor = {0.9, 0.9, 0.9}, -- Light gray
        barBgColor = {0.2, 0.2, 0.2, 0.3},
        frameColor = {0.0, 0.0, 0.0, 0.4},
        borderColor = {0.5, 0.5, 0.5, 0.6},
        textColor = {0.0, 0.0, 0.0}, -- Black text
        glowColor = nil,
        sparkColor = {1.0, 1.0, 1.0},
        hasGlow = false,
        hasBorder = false,
    },
    
    -- 4. DRAGON BALL (Golden energy style)
    ["dragonball"] = {
        name = "DragonBall",
        description = "Golden energy like Super Saiyan",
        barColor = {1.0, 0.84, 0.0}, -- Gold
        barBgColor = {0.5, 0.3, 0.0, 0.4},
        frameColor = {0.3, 0.15, 0.0, 0.9},
        borderColor = {1.0, 0.65, 0.0, 1.0}, -- Orange border
        textColor = {1.0, 1.0, 0.5}, -- Light yellow
        glowColor = {1.0, 0.84, 0.0, 0.6},
        sparkColor = {1.0, 1.0, 0.7},
        hasGlow = true,
        hasBorder = true,
    },
    
    -- 5. GLOWING (Bright glowing style)
    ["glowing"] = {
        name = "Glowing",
        description = "Bright glowing effect",
        barColor = {0.5, 1.0, 0.5}, -- Bright green
        barBgColor = {0.0, 0.2, 0.0, 0.5},
        frameColor = {0.0, 0.0, 0.0, 0.8},
        borderColor = {0.5, 1.0, 0.5, 1.0},
        textColor = {0.8, 1.0, 0.8},
        glowColor = {0.5, 1.0, 0.5, 0.7},
        sparkColor = {0.8, 1.0, 0.8},
        hasGlow = true,
        hasBorder = true,
    },
    
    -- 6. GLASS (Transparent glassy style)
    ["glass"] = {
        name = "Glass",
        description = "Transparent glass effect",
        barColor = {0.7, 0.9, 1.0}, -- Light blue
        barBgColor = {0.3, 0.5, 0.6, 0.2},
        frameColor = {0.2, 0.3, 0.4, 0.3},
        borderColor = {0.8, 0.9, 1.0, 0.5},
        textColor = {1.0, 1.0, 1.0},
        glowColor = {0.7, 0.9, 1.0, 0.3},
        sparkColor = {1.0, 1.0, 1.0},
        hasGlow = true,
        hasBorder = true,
    },
    
    -- 7. RETRO (Pixel/retro gaming style)
    ["retro"] = {
        name = "Retro",
        description = "Old-school pixel gaming style",
        barColor = {1.0, 0.0, 1.0}, -- Magenta
        barBgColor = {0.1, 0.0, 0.1, 0.7},
        frameColor = {0.0, 0.0, 0.0, 1.0},
        borderColor = {1.0, 0.0, 1.0, 1.0},
        textColor = {0.0, 1.0, 0.0}, -- Green text like old monitors
        glowColor = nil,
        sparkColor = {1.0, 1.0, 1.0},
        hasGlow = false,
        hasBorder = true,
    },
    
    -- 8. CYBERPUNK (Purple/pink cyberpunk)
    ["cyberpunk"] = {
        name = "Cyberpunk",
        description = "Purple and pink cyberpunk vibes",
        barColor = {1.0, 0.2, 0.8}, -- Hot pink
        barBgColor = {0.2, 0.0, 0.3, 0.6},
        frameColor = {0.1, 0.0, 0.2, 0.9},
        borderColor = {0.8, 0.0, 0.8, 1.0}, -- Purple
        textColor = {1.0, 0.5, 1.0},
        glowColor = {1.0, 0.2, 0.8, 0.5},
        sparkColor = {1.0, 0.7, 1.0},
        hasGlow = true,
        hasBorder = true,
    },
    
    -- 9. FANTASY (Magical purple/blue)
    ["fantasy"] = {
        name = "Fantasy",
        description = "Magical arcane energy",
        barColor = {0.6, 0.4, 1.0}, -- Purple
        barBgColor = {0.2, 0.1, 0.3, 0.5},
        frameColor = {0.1, 0.0, 0.2, 0.85},
        borderColor = {0.8, 0.6, 1.0, 0.9},
        textColor = {0.9, 0.8, 1.0},
        glowColor = {0.6, 0.4, 1.0, 0.4},
        sparkColor = {1.0, 0.9, 1.0},
        hasGlow = true,
        hasBorder = true,
    },
    
    -- 10. MODERN (Clean modern UI)
    ["modern"] = {
        name = "Modern",
        description = "Clean modern interface",
        barColor = {0.2, 0.8, 0.9}, -- Teal
        barBgColor = {0.15, 0.15, 0.15, 0.6},
        frameColor = {0.08, 0.08, 0.08, 0.9},
        borderColor = {0.3, 0.3, 0.3, 0.8},
        textColor = {1.0, 1.0, 1.0},
        glowColor = {0.2, 0.8, 0.9, 0.3},
        sparkColor = {0.8, 1.0, 1.0},
        hasGlow = true,
        hasBorder = true,
    },
}

-- Apply a style to the timer frame
function FlyTimes.BarStyles:ApplyStyle(styleName, timerFrame)
    local style = self.styles[styleName]
    if not style then
        print("|cff00ff00FlyTimes:|r Unknown style: " .. tostring(styleName))
        return false
    end
    
    -- Apply bar colors
    timerFrame.bar:SetStatusBarColor(style.barColor[1], style.barColor[2], style.barColor[3])
    timerFrame.bar.bg:SetTexture(style.barBgColor[1], style.barBgColor[2], style.barBgColor[3], style.barBgColor[4] or 1)
    
    -- Apply frame background
    timerFrame.bg:SetTexture(style.frameColor[1], style.frameColor[2], style.frameColor[3], style.frameColor[4] or 1)
    
    -- Apply border
    if style.hasBorder then
        timerFrame.border:Show()
        timerFrame.border:SetTexture(style.borderColor[1], style.borderColor[2], style.borderColor[3], style.borderColor[4] or 1)
    else
        timerFrame.border:Hide()
    end
    
    -- Apply text color
    timerFrame.text:SetTextColor(unpack(style.textColor))
    timerFrame.routeLabel:SetTextColor(unpack(style.textColor))
    
    -- Apply spark color
    if style.sparkColor then
        timerFrame.bar.spark:SetVertexColor(unpack(style.sparkColor))
    end
    
    -- Apply glow effect
    if style.hasGlow and style.glowColor then
        if not timerFrame.glow then
            timerFrame.glow = timerFrame:CreateTexture(nil, "BACKGROUND")
            timerFrame.glow:SetPoint("TOPLEFT", -10, 10)
            timerFrame.glow:SetPoint("BOTTOMRIGHT", 10, -10)
            timerFrame.glow:SetTexture("Interface\\SpellShadow\\GenericGlow64")
            timerFrame.glow:SetBlendMode("ADD")
        end
        timerFrame.glow:SetVertexColor(unpack(style.glowColor))
        timerFrame.glow:Show()
    else
        if timerFrame.glow then
            timerFrame.glow:Hide()
        end
    end
    
    return true
end

-- Get list of all styles
function FlyTimes.BarStyles:GetStyleList()
    local list = {}
    for key, style in pairs(self.styles) do
        table.insert(list, {
            key = key,
            name = style.name,
            description = style.description
        })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end
