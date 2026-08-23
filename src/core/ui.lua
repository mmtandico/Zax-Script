--[[
    UI Manager Module
    Integrates a modern UI library (Fluent/Rayfield) with structured tabs for all modules.
]]

local Utils = require(script.Parent.utils)
local Config = require(script.Parent.config)
local Notifications = require(script.Parent.notifications)

local UI = {
    Window = nil,
    Tabs = {},
    Library = nil
}

function UI.Init(hubTitle, hubSubtitle)
    hubTitle = hubTitle or "Roblox Script Hub"
    hubSubtitle = hubSubtitle or "v1.0.0 | " .. Utils.GetExecutor()

    -- Try loading Fluent UI Library
    local success, Fluent = pcall(function()
        return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)

    if success and Fluent then
        UI.Library = Fluent

        local Window = Fluent:CreateWindow({
            Title = hubTitle,
            SubTitle = hubSubtitle,
            TabWidth = 160,
            Size = UDim2.fromOffset(580, 460),
            Acrylic = true,
            Theme = "Dark",
            MinimizeKey = Enum.KeyCode.RightControl
        })

        UI.Window = Window

        -- Create Standard Tabs
        UI.Tabs.Home = Window:AddTab({ Title = "Home", Icon = "home" })
        UI.Tabs.Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" })
        UI.Tabs.Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" })
        UI.Tabs.Movement = Window:AddTab({ Title = "Movement", Icon = "footprints" })
        UI.Tabs.Game = Window:AddTab({ Title = "Game Specific", Icon = "gamepad-2" })
        UI.Tabs.Utility = Window:AddTab({ Title = "Utilities", Icon = "wrench" })
        UI.Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

        -- Setup Notifications bridge
        getgenv().HubNotify = function(options)
            Fluent:Notify({
                Title = options.Title or "Hub",
                Content = options.Content or "",
                Duration = options.Duration or 5
            })
        end

        UI.BuildStandardUI()
        Window:SelectTab(1)
        return UI
    end

    -- Fallback: Rayfield or CoreGui Window
    Notifications.Warn("Fluent UI could not be fetched remotely. Using local fallback.")
    return UI
end

function UI.BuildStandardUI()
    if not UI.Library or not UI.Window then return end

    local VisualsModule = require(script.Parent.Parent.modules.visuals)
    local CombatModule = require(script.Parent.Parent.modules.combat)
    local MovementModule = require(script.Parent.Parent.modules.movement)
    local UtilityModule = require(script.Parent.Parent.modules.utility)

    local tabs = UI.Tabs

    ----------------------------------------------------------------------
    -- HOME TAB
    ----------------------------------------------------------------------
    tabs.Home:AddParagraph({
        Title = "Welcome to " .. UI.Window.Title,
        Content = "Place: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. "\nPlace ID: " .. tostring(game.PlaceId) .. "\nExecutor: " .. Utils.GetExecutor()
    })

    tabs.Home:AddButton({
        Title = "Join Discord Community",
        Description = "Copies invite link to clipboard",
        Callback = function()
            Utils.SetClipboard("https://discord.gg/example")
            Notifications.Success("Discord invite copied!")
        end
    })

    ----------------------------------------------------------------------
    -- COMBAT TAB
    ----------------------------------------------------------------------
    local aimToggle = tabs.Combat:AddToggle("AimbotToggle", {
        Title = "Enable Aimbot",
        Default = Config.CurrentConfig.Combat.AimbotEnabled,
        Callback = function(val)
            Config.CurrentConfig.Combat.AimbotEnabled = val
        end
    })

    tabs.Combat:AddDropdown("AimPart", {
        Title = "Aim Target Part",
        Values = {"Head", "HumanoidRootPart", "UpperTorso"},
        Default = Config.CurrentConfig.Combat.AimPart,
        Callback = function(val)
            Config.CurrentConfig.Combat.AimPart = val
        end
    })

    tabs.Combat:AddSlider("AimbotFOV", {
        Title = "FOV Radius",
        Description = "Aimbot detection radius",
        Default = Config.CurrentConfig.Combat.FOV,
        Min = 20,
        Max = 500,
        Rounding = 0,
        Callback = function(val)
            Config.CurrentConfig.Combat.FOV = val
        end
    })

    tabs.Combat:AddToggle("ShowFOV", {
        Title = "Draw FOV Circle",
        Default = Config.CurrentConfig.Combat.ShowFOV,
        Callback = function(val)
            Config.CurrentConfig.Combat.ShowFOV = val
        end
    })

    tabs.Combat:AddSlider("Smoothness", {
        Title = "Aim Smoothness",
        Description = "Higher = smoother camera lock",
        Default = Config.CurrentConfig.Combat.Smoothness,
        Min = 1,
        Max = 20,
        Rounding = 0,
        Callback = function(val)
            Config.CurrentConfig.Combat.Smoothness = val
        end
    })

    tabs.Combat:AddToggle("CombatTeamCheck", {
        Title = "Team Check",
        Default = Config.CurrentConfig.Combat.TeamCheck,
        Callback = function(val)
            Config.CurrentConfig.Combat.TeamCheck = val
        end
    })

    tabs.Combat:AddToggle("HitboxExpander", {
        Title = "Hitbox Expander",
        Default = Config.CurrentConfig.Combat.HitboxExpander,
        Callback = function(val)
            Config.CurrentConfig.Combat.HitboxExpander = val
            if not val then
                CombatModule.ResetHitboxes()
            end
        end
    })

    tabs.Combat:AddSlider("HitboxSize", {
        Title = "Hitbox Size",
        Default = Config.CurrentConfig.Combat.HitboxSize,
        Min = 2,
        Max = 25,
        Rounding = 0,
        Callback = function(val)
            Config.CurrentConfig.Combat.HitboxSize = val
        end
    })

    ----------------------------------------------------------------------
    -- VISUALS TAB
    ----------------------------------------------------------------------
    tabs.Visuals:AddToggle("ESPEnabled", {
        Title = "Master ESP Toggle",
        Default = Config.CurrentConfig.Visuals.ESPEnabled,
        Callback = function(val)
            Config.CurrentConfig.Visuals.ESPEnabled = val
        end
    })

    tabs.Visuals:AddToggle("ESPBoxes", {
        Title = "Box 2D ESP",
        Default = Config.CurrentConfig.Visuals.Boxes,
        Callback = function(val)
            Config.CurrentConfig.Visuals.Boxes = val
        end
    })

    tabs.Visuals:AddToggle("ESPNames", {
        Title = "Player Names",
        Default = Config.CurrentConfig.Visuals.Names,
        Callback = function(val)
            Config.CurrentConfig.Visuals.Names = val
        end
    })

    tabs.Visuals:AddToggle("ESPDistance", {
        Title = "Distance Display",
        Default = Config.CurrentConfig.Visuals.Distance,
        Callback = function(val)
            Config.CurrentConfig.Visuals.Distance = val
        end
    })

    tabs.Visuals:AddToggle("ESPHealth", {
        Title = "Health Bars",
        Default = Config.CurrentConfig.Visuals.Health,
        Callback = function(val)
            Config.CurrentConfig.Visuals.Health = val
        end
    })

    tabs.Visuals:AddToggle("ESPTracers", {
        Title = "Tracers (Lines)",
        Default = Config.CurrentConfig.Visuals.Tracers,
        Callback = function(val)
            Config.CurrentConfig.Visuals.Tracers = val
        end
    })

    tabs.Visuals:AddToggle("ESPChams", {
        Title = "Highlight Chams",
        Default = Config.CurrentConfig.Visuals.HighlightChams,
        Callback = function(val)
            Config.CurrentConfig.Visuals.HighlightChams = val
        end
    })

    tabs.Visuals:AddColorpicker("ESPColor", {
        Title = "ESP Color",
        Default = Color3.fromRGB(Config.CurrentConfig.Visuals.BoxColor[1], Config.CurrentConfig.Visuals.BoxColor[2], Config.CurrentConfig.Visuals.BoxColor[3]),
        Callback = function(color)
            Config.CurrentConfig.Visuals.BoxColor = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
        end
    })

    ----------------------------------------------------------------------
    -- MOVEMENT TAB
    ----------------------------------------------------------------------
    tabs.Movement:AddToggle("FlyToggle", {
        Title = "Fly Hack",
        Default = Config.CurrentConfig.Movement.Fly,
        Callback = function(val)
            Config.CurrentConfig.Movement.Fly = val
            MovementModule.SetFly(val)
        end
    })

    tabs.Movement:AddSlider("FlySpeed", {
        Title = "Fly Speed",
        Default = Config.CurrentConfig.Movement.FlySpeed,
        Min = 10,
        Max = 250,
        Rounding = 0,
        Callback = function(val)
            Config.CurrentConfig.Movement.FlySpeed = val
        end
    })

    tabs.Movement:AddToggle("NoclipToggle", {
        Title = "Noclip",
        Default = Config.CurrentConfig.Movement.Noclip,
        Callback = function(val)
            Config.CurrentConfig.Movement.Noclip = val
        end
    })

    tabs.Movement:AddToggle("SpeedToggle", {
        Title = "Speed Hack",
        Default = Config.CurrentConfig.Movement.SpeedEnabled,
        Callback = function(val)
            Config.CurrentConfig.Movement.SpeedEnabled = val
        end
    })

    tabs.Movement:AddSlider("WalkSpeed", {
        Title = "WalkSpeed Value",
        Default = Config.CurrentConfig.Movement.WalkSpeed,
        Min = 16,
        Max = 250,
        Rounding = 0,
        Callback = function(val)
            Config.CurrentConfig.Movement.WalkSpeed = val
        end
    })

    tabs.Movement:AddToggle("JumpToggle", {
        Title = "High Jump Hack",
        Default = Config.CurrentConfig.Movement.JumpEnabled,
        Callback = function(val)
            Config.CurrentConfig.Movement.JumpEnabled = val
        end
    })

    tabs.Movement:AddSlider("JumpPower", {
        Title = "JumpPower Value",
        Default = Config.CurrentConfig.Movement.JumpPower,
        Min = 50,
        Max = 350,
        Rounding = 0,
        Callback = function(val)
            Config.CurrentConfig.Movement.JumpPower = val
        end
    })

    tabs.Movement:AddToggle("InfiniteJump", {
        Title = "Infinite Jump",
        Default = Config.CurrentConfig.Movement.InfiniteJump,
        Callback = function(val)
            Config.CurrentConfig.Movement.InfiniteJump = val
        end
    })

    ----------------------------------------------------------------------
    -- UTILITY TAB
    ----------------------------------------------------------------------
    tabs.Utility:AddToggle("AntiAFK", {
        Title = "Anti-AFK (20m Kick Bypass)",
        Default = Config.CurrentConfig.Utility.AntiAFK,
        Callback = function(val)
            Config.CurrentConfig.Utility.AntiAFK = val
        end
    })

    tabs.Utility:AddToggle("Fullbright", {
        Title = "Fullbright (No Shadows / Clear Vision)",
        Default = Config.CurrentConfig.Utility.Fullbright,
        Callback = function(val)
            Config.CurrentConfig.Utility.Fullbright = val
            UtilityModule.SetFullbright(val)
        end
    })

    tabs.Utility:AddButton({
        Title = "Rejoin Current Server",
        Callback = function()
            UtilityModule.Rejoin()
        end
    })

    tabs.Utility:AddButton({
        Title = "Server Hop (Switch to New Server)",
        Callback = function()
            UtilityModule.ServerHop()
        end
    })

    tabs.Utility:AddButton({
        Title = "Copy PlaceId",
        Callback = function()
            UtilityModule.CopyPlaceId()
        end
    })

    tabs.Utility:AddButton({
        Title = "Copy JobId",
        Callback = function()
            UtilityModule.CopyJobId()
        end
    })

    ----------------------------------------------------------------------
    -- SETTINGS / CONFIGS TAB
    ----------------------------------------------------------------------
    local configInput = "default"
    tabs.Settings:AddInput("ConfigNameInput", {
        Title = "Config Name",
        Default = "default",
        Callback = function(val)
            configInput = val
        end
    })

    tabs.Settings:AddButton({
        Title = "Save Config",
        Callback = function()
            local success, msg = Config.Save(configInput)
            if success then
                Notifications.Success(msg)
            else
                Notifications.Error(msg)
            end
        end
    })

    tabs.Settings:AddButton({
        Title = "Load Config",
        Callback = function()
            local success, msg = Config.Load(configInput)
            if success then
                Notifications.Success(msg)
            else
                Notifications.Error(msg)
            end
        end
    })
end

return UI
