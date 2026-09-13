# Changelog
All notable changes to FlyTimes will be documented in this file.

## [1.0.0] - 2026-09-13
### Initial Release
- ✈️ **Real-time Flight Timer** – Shows exact remaining time during flight paths
- 📊 **Progress Bar** – Visual bar that fills as you fly, with animated spark effect
- 🧠 **Auto-Learning System** – Measures and remembers real flight times on your server
- 🎨 **10 Customizable Bar Styles** – Classic, Modern, Neon, Cyberpunk, Retro, and more
- ⚙️ **Full Options Panel** – In-game settings with live style previews
- 🗺️ **Minimap Icon** – Quick access to settings from the minimap
- 🌍 **Multi-Language Support** – English, German, French, Spanish, Russian, Chinese, Korean
- 🔄 **Faction Support** – Works for both Horde and Alliance
- 📍 **Movable Bar** – Drag the bar anywhere on your screen
- 💾 **Saves Position** – Remembers where you placed it
- 🎯 **Emberveil Compatible** – Built for the 1.12.1 client

### Features
#### Flight Timer
- Real-time countdown with minutes:seconds display
- Percentage progress indicator
- Route label above the progress bar
- Automatic flight detection (TakeTaxiNode + TaxiButton fallback)
- Automatic timer stop on landing
- Tooltip shows flight time on taxi map

#### Auto-Learning System
- Measures actual flight times on your server during real flights
- Uses static database for the first 2 flights on each route
- After 2+ measurements, uses your own measured average
- Chat indicator shows source: `(database)` or `(measured)`
- Tooltip indicator: `Flight time:` vs `Flight time (measured):`
- Sanity check: only 5 seconds – 30 minutes range accepted
- Clear measured data with `/ft clearmeasured`

#### Bar Styles (10 Total)
- **Classic** – Traditional WoW interface (blue)
- **Minimalist** – Clean light gray
- **Modern** – Clean modern teal
- **Glass** – Transparent glassy effect
- **Fantasy** – Magical arcane purple
- **Neon** – Glowing cyberpunk cyan
- **Cyberpunk** – Hot pink and purple
- **Glowing** – Bright green glow
- **Retro** – Old-school magenta + green
- **DragonBall** – Golden Super Saiyan energy

Each style has its own bar color, background, border, text color, and optional glow effect.

#### Minimap Icon
- **Left-click** – Open the settings panel
- **Ctrl + drag** – Move the icon around the minimap
- **Ctrl + right-click** – Reset icon position
- Fully localized tooltip

#### Options Panel
Two tabs with classic WoW styling:

**General Tab:**
- Enable/disable addon
- Auto-learning (measure flight times)
- Show chat estimate messages
- Reset bar position
- Clear measured data

**Styles Tab:**
- Visual preview of all 10 bar styles
- Each preview shows a mini bar with the style's colors
- Click any style to preview and apply
- Current style highlighted with golden border
- Tooltip shows style description

### Flight Path Database

- **Classic (Vanilla)**: 61 locations, 754 routes
- **Horde**: 27 flight master locations
- **Alliance**: 26 flight master locations
- Data sourced from RXP Guides (RestedXP)

### Commands

- `/ft` or `/flytimes` – Show help menu
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

### Supported Languages

- 🇬🇧 English
- 🇩🇪 German (Deutsch)
- 🇫🇷 French (Français)
- 🇪🇸 Spanish (Español)
- 🇷🇺 Russian (Русский)
- 🇨🇳 Chinese Simplified (简体中文)
- 🇰🇷 Korean (한국어)

All UI elements, chat messages, tooltips, and the options panel are fully localized.

### Emberveil (1.12.1) Compatibility
- Uses `this` + `arg1` in script handlers (not `self, elapsed`)
- Uses `SetTexture(r, g, b, a)` instead of `SetColorTexture`
- Uses `SetWidth` + `SetHeight` instead of `SetSize`
- Manual hooks instead of `hooksecurefunc`
- No `C_Timer`, `GetAddOnMetadata`, or `SecureButton_GetUnit`
- Vanilla-compatible textures (`SpellShadow\GenericGlow64`)
- No inline `|T...|t` texture codes in tooltips
- SavedVariables initialization runs at file load AND on `ADDON_LOADED`

### Technical Details
- **SavedVariables**: `FlyTimesDB` (with `measured` sub-table for auto-learning)
- **Flight detection**: `TakeTaxiNode` hook + `TaxiButton OnClick` fallback
- **Duplicate protection**: 1-second minimum between timer starts
- **Zero dependencies** – standalone addon
- **Lightweight** – minimal performance impact
- **Complete localization system** with 7 language files

### Credits
- **Author**: Kharon
- **Version**: 1.0.0
- **Flight data**: Sourced from RXP Guides (RestedXP)

### License
Free to use and modify.