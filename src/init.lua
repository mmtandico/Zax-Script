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
