--[[
    Zxscript - Main Entry Point
    Initializes core services, modules, game router, and user interface.
]]

-- Wait for game to fully load before initializing
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(1)
-- Cleanup previous execution instance if exists
if getgenv and getgenv().ZxscriptCleanup then
    pcall(getgenv().ZxscriptCleanup)
end

-- Core Dependencies
local Config = require(script.core.config)
local Notifications = require(script.core.notifications)
local UI = require(script.core.ui)
local Utils = require(script.core.utils)

-- Feature Modules
local Visuals = require(script.modules.visuals)
local Combat = require(script.modules.combat)
local Movement = require(script.modules.movement)
local Utility = require(script.modules.utility)

local Hub = {
    Name = "Zxscript",
    Version = "1.0.0",
    SupportedGames = {
        [286090429] = "Arsenal",
        [2753915549] = "Blox Fruits (Sea 1)",
        [4442272183] = "Blox Fruits (Sea 2)",
        [7449423635] = "Blox Fruits (Sea 3)",
        [10563114921] = "Steal an Egg",
        [107778070777162] = "Steal an Egg",
        [9910245722] = "Iron Soul",
        [7856269159] = "Anime Overload",
        [97365843755210] = "Cut Grass For Brainrots",
        [124473577469410] = "Be a Lucky Block",
        [82397737462020] = "Shrink for Brainrot",
        [7798947148] = "Anime Final Quest",
        [77393318863643] = "Aura Ascension Ahh game",
        [105626692504093] = "Be a Brainrot",
        [8966502575] = "Anime Reversal",
        [112259901434347] = "+1 Speed be a Lucky Block!",
        [9802644580] = "Summon Heroes",
        [8937254139] = "Dungeon Hunters",
        [9833422940] = "Unbox a Factory",
        [9073513091] = "Anime Apocalypse",
        [7395930870] = "Sell Lemons",
        [10032271327] = "Anime World Fighters",
        [138064211947107] = "Unbox a Car",
        [9610561918] = "Knife Farm",
        [10004244222] = "Kick a Lucky Block",
        [9792947201] = "Slime RNG",
        [10016841656] = "Noob Tower Defense",
        [6409513651] = "Anime Warrior III",
        [10039338037] = "Build A Ring Farm",
        [9348272796] = "SZA",
        [7585079192] = "Anime Story 2",
        [10093833731] = "Broken Blade",
        [10148434559] = "Lucky Block Rush",
        [10168229420] = "My Gaming Cafe",
        [102072869879193] = "Anime Astral",
        [8356066619] = "Anime Squadron",
        [10200395747] = "Grow a Garden 2",
        [9826885587] = "Evomon",
        [10204207151] = "Catch a Brainrot",
        [7613921865] = "Anime Expedition",
        [10131390815] = "Throw a Coin",
        [8841437826] = "Capybara vs Plants",
        [8959257868] = "Unscathed",
        [8946565814] = "Anime Origins",
    }
}

function Hub.Start()
    print(string.format("[%s] Initializing %s (v%s) on %s...", Hub.Name, Hub.Name, Hub.Version, Utils.GetExecutor()))

    -- 1. Initialize Configuration
    pcall(function()
        Config.Init("Zxscript")
    end)

    -- 2. Initialize Core Feature Modules safely
    pcall(function() Visuals.Init() end)
    pcall(function() Combat.Init() end)
    pcall(function() Movement.Init() end)
    pcall(function() Utility.Init() end)

    -- 3. Initialize User Interface
    local uiInstance = UI.Init(Hub.Name, "v" .. Hub.Version .. " | " .. Utils.GetExecutor())

    -- 4. Route Game-Specific Module (checks PlaceId then GameId then universal)
    local placeIdStr = tostring(game.PlaceId)
    local gameIdStr = tostring(game.GameId)
    
    local gameModule = script.games:FindFirstChild(placeIdStr) 
        or script.games:FindFirstChild(gameIdStr) 
        or script.games:FindFirstChild("universal")

    if gameModule then
        local success, mod = pcall(function()
            return require(gameModule)
        end)

        if success and mod and mod.Init then
            pcall(function()
                mod.Init(uiInstance, Config, Notifications)
            end)
            print(string.format("[%s] Loaded game module for ID: %s (%s)", Hub.Name, placeIdStr, Hub.SupportedGames[game.PlaceId] or Hub.SupportedGames[game.GameId] or "Universal"))
        end
    end

    -- Register global cleanup
    if getgenv then
        getgenv().ZxscriptCleanup = function()
            pcall(function() Visuals.Cleanup() end)
            pcall(function() Combat.Cleanup() end)
            pcall(function() Movement.Cleanup() end)
            pcall(function() Utility.Cleanup() end)
            if UI.Window then
                pcall(function() UI.Window:Unload() end)
            end
        end
    end

    -- 5. Welcome Notification
    Notifications.Success("Zxscript successfully loaded!", 4)
end

-- Start Hub
Hub.Start()

return Hub
