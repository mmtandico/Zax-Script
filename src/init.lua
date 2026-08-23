--[[
    Roblox Script Hub - Main Entry Point
    Initializes core services, modules, game router, and user interface.
]]

-- Cleanup previous execution instance if exists
if getgenv and getgenv().QuantumHubCleanup then
    pcall(getgenv().QuantumHubCleanup)
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
    Name = "Quantum Script Hub",
    Version = "1.0.0",
    SupportedGames = {
        [286090429] = "Arsenal",
        [2753915549] = "Blox Fruits (Sea 1)",
        [4442272183] = "Blox Fruits (Sea 2)",
        [7449423635] = "Blox Fruits (Sea 3)",
    }
}

function Hub.Start()
    print(string.format("[%s] Initializing %s (v%s) on %s...", Hub.Name, Hub.Name, Hub.Version, Utils.GetExecutor()))

    -- 1. Initialize Configuration
    pcall(function()
        Config.Init("QuantumHub")
    end)

    -- 2. Initialize Core Feature Modules safely
    pcall(function() Visuals.Init() end)
    pcall(function() Combat.Init() end)
    pcall(function() Movement.Init() end)
    pcall(function() Utility.Init() end)

    -- 3. Initialize User Interface
    local uiInstance = UI.Init(Hub.Name, "v" .. Hub.Version .. " | " .. Utils.GetExecutor())

    -- 4. Route Game-Specific Module
    local placeId = game.PlaceId
    local gameModuleName = tostring(placeId)
    local gameModule = script.games:FindFirstChild(gameModuleName) or script.games:FindFirstChild("universal")

    if gameModule then
        local success, mod = pcall(function()
            return require(gameModule)
        end)

        if success and mod and mod.Init then
            pcall(function()
                mod.Init(uiInstance, Config, Notifications)
            end)
            print(string.format("[%s] Loaded game module for PlaceId: %s", Hub.Name, tostring(placeId)))
        end
    end

    -- Register global cleanup
    if getgenv then
        getgenv().QuantumHubCleanup = function()
            pcall(function() Visuals.Cleanup() end)
            pcall(function() Combat.Cleanup() end)
            pcall(function() Movement.Cleanup() end)
            pcall(function() Utility.Cleanup() end)
            if UI.ScreenGui then
                UI.ScreenGui:Destroy()
            end
        end
    end

    -- 5. Welcome Notification
    Notifications.Success("Quantum Hub successfully loaded!", 4)
end

-- Start Hub
Hub.Start()

return Hub
