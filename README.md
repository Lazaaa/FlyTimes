# FlyTimes

An Emberveil WoW addon that displays a progress bar showing the remaining time during flight paths. Includes an auto-learning system that measures real flight times on your server and remembers them.

## Features

- ✈️ **Real-time Flight Timer** – Shows exact remaining time on your flight
- 📊 **Progress Bar** – Visual bar that fills as you fly
- 🧠 **Auto-Learning** – Measures and remembers real flight times on your server
- 🎨 **10 Bar Styles** – Classic, Modern, Neon, Cyberpunk, Retro, and more
- ⚙️ **Full Options Panel** – In-game settings with live style previews
- 🗺️ **Minimap Icon** – Quick access to settings from the minimap
- 🌍 **Multi-Language Support** – English, German, French, Spanish, Russian, Chinese, Korean
- 🔄 **Faction Support** – Works for both Horde and Alliance
- 📍 **Movable Bar** – Drag the bar anywhere on your screen
- 💾 **Saves Position** – Remembers where you placed it
- 🎯 **Emberveil Compatible** – Built for the 1.12.1 client

## Installation

1. Download the `FlyTimes` folder
2. Place it in your World of Warcraft AddOns directory:
   - **Windows**: `\Interface\AddOns\`
   - **Mac**: `/Interface/AddOns/`
3. Restart WoW or reload UI (`/reload`)

## Usage

### Basic Usage
Just take a flight! The timer will automatically appear when you start flying.

### Minimap Icon
- **Left-click** – Open the settings panel
- **Ctrl + drag** – Move the icon around the minimap
- **Ctrl + right-click** – Reset icon position

### Options Panel
The in-game settings panel has two tabs:

**General Tab:**
- Enable/disable addon
- Auto-learning (measure flight times)
- Show chat estimate messages
- Reset bar position
- Clear measured data

**Styles Tab:**
- Visual preview of all 10 bar styles
- Click any style to preview and apply

### Commands

- `/ft` or `/flytimes` – Show help
- `/ft toggle` – Enable/disable the addon
- `/ft learning` – Toggle auto-learning on/off
- `/ft measured` – List all measured routes with averages
- `/ft clearmeasured` – Clear all measured data
- `/ft estimate` – Toggle chat estimate messages
- `/ft test` – Test the timer bar (2 minute demo)
- `/ft reset` – Reset bar position to center
- `/ft style <name>` – Change bar style
- `/ft style list` – Show all available styles
- `/ft debug` – Show taxi node debug info

### Moving the Bar
Left-click and drag the timer bar to move it anywhere on your screen. Your position will be saved.

## How It Works

### Initial State
The addon comes with a **static flight path database** extracted from RXP Guides. This covers:

- **Classic (Vanilla)**: 61 locations, 754 routes

When you start a flight, the addon looks up the flight time from this database and shows a progress bar with the countdown.

### Auto-Learning System
Over time, the addon **measures the actual flight times on your server**:

1. When a flight starts, the addon records the start timestamp
2. When the flight ends, it calculates the elapsed time
3. The measurement is saved to `FlyTimesDB.measured`
4. After **2 or more measurements** on the same route, the addon uses **your own measured average** instead of the static database
5. The chat and tooltip indicate the source: `(database)` or `(measured)`

This means the more you fly, the more accurate the timer becomes — perfect for private servers that may have different flight times than retail.

### Measurement Flow

```
Take flight -> PLAYER_CONTROL_LOST -> 0.3s delay -> UnitOnTaxi check
    |
Recording: [measuring...] shown
    |
Landing -> PLAYER_CONTROL_GAINED -> Save measurement
    |
Chat: "Measured Orgrimmar -> Crossroads: 2:18 (1 db, avg: 2:18)"
```

### Sanity Checks
- Measurements outside 5 seconds – 30 minutes are discarded
- Minimum 2 measurements required before using average
- 1-second minimum between timer starts (prevents duplicate hook triggers)

## Bar Styles

10 built-in styles:

| Style | Description |
|-------|-------------|
| **Classic** | Traditional WoW interface (blue) |
| **Minimalist** | Clean light gray |
| **Modern** | Clean modern teal |
| **Glass** | Transparent glassy effect |
| **Fantasy** | Magical arcane purple |
| **Neon** | Glowing cyberpunk cyan |
| **Cyberpunk** | Hot pink and purple |
| **Glowing** | Bright green glow |
| **Retro** | Old-school magenta + green |
| **DragonBall** | Golden Super Saiyan energy |

Each style has its own bar color, background, border, text color, and optional glow effect.

## Flight Time Data

The static database contains:

- **Classic (Vanilla)**: 61 locations, 754 routes
- **Horde**: 27 flight master locations
- **Alliance**: 26 flight master locations

Data sourced from RXP Guides (RestedXP).

## Customization

### In-Game
Use the **Options Panel** (via minimap icon or `/ft`).

### Via Lua

Run these commands in-game:

```
/run FlyTimesDB.barWidth = 400
/run FlyTimesDB.barHeight = 40
/run FlyTimesDB.enabled = false
/run FlyTimesDB.learningEnabled = false
/reload
```

### Saved Variables

The addon stores its data in `WTF/Account/<account>/SavedVariables/FlyTimes.lua`:

```
FlyTimesDB = {
    enabled = true,
    showEstimate = true,
    barWidth = 300,
    barHeight = 30,
    posX = 0,
    posY = 200,
    barStyle = "classic",
    learningEnabled = true,
    minimapAngle = 220,
    minimapRadius = 80,
    measured = {
        ["Orgrimmar_to_Crossroads"] = { total = 276, count = 2, last = 138, min = 136, max = 140 },
    },
}
```

## Emberveil Compatibility Notes

This addon is specifically built for the **Emberveil 1.12.1 client**. Key adaptations:

- Uses `this` + `arg1` in script handlers (not `self, elapsed`)
- Uses `SetTexture(r, g, b, a)` instead of `SetColorTexture`
- Uses `SetWidth` + `SetHeight` instead of `SetSize`
- Manual hooks instead of `hooksecurefunc`
- No `C_Timer`, `GetAddOnMetadata`, or `SecureButton_GetUnit`
- Vanilla-compatible textures (`SpellShadow\GenericGlow64`)
- No inline `|T...|t` texture codes in tooltips

## Credits

- **Author**: Kharon
- **Version**: 1.0.0
- **Flight time data**: Sourced from RXP Guides (RestedXP)

## Support

For issues or suggestions, the addon is provided as-is. Feel free to modify the code for your needs!

## License

Free to use and modify.