# Quantum Script Hub (Roblox Luau)

A modular, production-ready Roblox Script Hub built in Luau. Features automatic game detection, universal exploits (ESP, Aimbot, Movement, Utilities), JSON configuration saving, modern UI library integration, and an automated build/bundler system.

---

## ⚡ Quick Start / Execution

Run this one-line command inside any supported Roblox executor (e.g. Synapse Z, Wave, Solara, Celery, Delta, Codex, Hydrogen):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/mmtandico/Zax-Script/main/dist/hub.lua"))()
```

Or execute the local development build by copying the content of [`dist/hub.lua`](file:///c:/Users/Windows/OneDrive/Desktop/Roblox/dist/hub.lua) directly into your executor.

---

## 📂 Project Structure

```
Roblox/
├── .luaurc                 # Luau type checking and globals configuration
├── README.md               # Documentation & usage guide
├── package.json            # NPM scripts for building & development
├── build.js                # Node.js bundler script (src/ -> dist/hub.lua)
├── src/
│   ├── init.lua            # Main entry point & PlaceId game router
│   ├── loader.lua          # Remote bootstrapper for loadstring delivery
│   ├── core/
│   │   ├── config.lua      # JSON file system manager (save/load configs)
│   │   ├── notifications.lua # StarterGui / UI notification bridge
│   │   ├── ui.lua          # Fluent UI library wrapper with tabs & components
│   │   └── utils.lua       # World-to-screen, Raycasting, Target & math helpers
│   ├── modules/
│   │   ├── combat.lua      # Aimbot, FOV circle, smoothness, Hitbox expander
│   │   ├── movement.lua    # Fly, Noclip, Speed, High Jump, Infinite Jump
│   │   ├── visuals.lua     # Drawing API ESP (Boxes, Nametags, Tracers, Chams)
│   │   └── utility.lua     # Anti-AFK, Server Hop, Rejoin, Fullbright, FPS cap
│   └── games/
│       ├── universal.lua   # Default fallback for any unlisted Roblox game
│       ├── 286090429.lua   # Arsenal PlaceId script
│       └── 2753915549.lua  # Blox Fruits PlaceId script
└── dist/
    └── hub.lua             # Compiled standalone distribution (loadstring ready)
```

---

## 🛠️ Developer Guide

### Prerequisites
- [Node.js](https://nodejs.org/) installed on your machine.

### Build Commands
```bash
# Build dist/hub.lua once
npm run build

# Watch mode: automatically re-bundles whenever a file in src/ changes
npm run dev
```

---

## 🎮 Adding a New Game Script

To add specialized features for a game (e.g. Murder Mystery 2 or Doors):

1. Find the game's **PlaceId** (e.g., `142823291` for Murder Mystery 2).
2. Create a new file in `src/games/` named `<PlaceId>.lua` (e.g., [`src/games/142823291.lua`](file:///c:/Users/Windows/OneDrive/Desktop/Roblox/src/games/)):
   ```lua
   local MM2 = {}

   function MM2.Init(UI, Config, Notifications)
       local gameTab = UI.Tabs.Game
       if not gameTab then return end

       gameTab:AddParagraph({
           Title = "Murder Mystery 2",
           Content = "PlaceId: 142823291 active."
       })

       gameTab:AddToggle("AutoGrabGun", {
           Title = "Auto Grab Dropped Gun",
           Default = false,
           Callback = function(val)
               -- Custom logic here
           end
       })
   end

   return MM2
   ```
3. Run `npm run build`. The router will automatically detect and load your game script when you enter that game!

---

## 🛡️ Features Overview

### 1. Combat
- **Aimbot**: Smooth camera tracking with right-click activation, target part selection (Head, HumanoidRootPart, Torso).
- **FOV Circle**: Dynamic screen-space circle visualization with customizable radius and color.
- **Hitbox Expander**: Expands enemy hitboxes for easier hit registration.
- **Team Check & Visibility Check**: Target only active enemies.

### 2. Visuals (ESP)
- **Drawing API 2D Box ESP**: Render 2D bounding boxes around players.
- **Nametags & Distance**: Displays player names and stud distance in real-time.
- **Health Bars**: Dynamic color-graded health bars (green -> yellow -> red).
- **Tracers**: Snaplines from bottom, center, or top of screen.
- **Highlight Chams**: Highlight character models through walls.

### 3. Movement
- **Fly Hack**: Smooth 6-axis flight (WASD + Space/Shift).
- **Noclip**: Walk through walls and locked doors without collision.
- **Speed & Jump**: Dynamic WalkSpeed and JumpPower modifiers.
- **Infinite Jump**: Jump repeatedly in mid-air.

### 4. Utilities & Diagnostics
- **Anti-AFK**: Simulates input to bypass Roblox's 20-minute idle disconnect.
- **Server Hop**: Automatically finds and transfers to a different public server.
- **Rejoin Server**: Instantly reconnects to the current server instance.
- **Fullbright**: Removes darkness, fog, and shadows for maximum clarity.
- **FPS Unlocker**: Sets custom client FPS limit via `setfpscap`.

### 5. Config System
- Save and load individual settings profiles to disk using JSON (`workspace/QuantumHub/configs/<name>.json`).
