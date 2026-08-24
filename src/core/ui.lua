--[[
    Zxscript - Rayfield Gen2 UI Integration
    Uses Sirius Rayfield Gen2 for a polished, themed, saveable interface.
    Docs: https://docs.sirius.menu/rayfield-gen2
]]

local UserInputService = game:GetService("UserInputService")

local Utils = require(script.Parent.utils)
local Config = require(script.Parent.config)
local Notifications = require(script.Parent.notifications)

local UI = {
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    CurrentTab = nil,
    IsVisible = true,
}

function UI.Init(hubTitle, hubSubtitle)
    hubTitle = hubTitle or "Zxscript"
    hubSubtitle = hubSubtitle or ("v1.0.0 | " .. Utils.GetExecutor())

    -- Load Rayfield Gen2
    local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
    UI.Rayfield = Rayfield

    -- Create Window
    local window = Rayfield:CreateWindow({
        name = hubTitle,
        subtitle = hubSubtitle,
        theme = "cobalt",
        configuration = {
            autoSave = true,
            autoLoad = true,
            fileName = "Zxscript",
        },
    })
    UI.Window = window

    -- Register Rayfield Notify into global environment for notifications module
    if getgenv then
        getgenv().HubNotify = function(options)
            window:Notify({
                title = options.Title or "Hub",
                content = options.Content or "",
                duration = options.Duration or 4,
            })
        end
    end

    -- Keybind to Toggle GUI (RightControl)
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightControl then
            window:ToggleHide()
        end
    end)

    -- Initialize Standard Tabs
    UI.Tabs.Home = UI.CreateTab("Home")
    UI.Tabs.Combat = UI.CreateTab("Combat")
    UI.Tabs.Visuals = UI.CreateTab("Visuals")
    UI.Tabs.Movement = UI.CreateTab("Movement")
    UI.Tabs.Game = UI.CreateTab("Game Specific")
    UI.Tabs.Utility = UI.CreateTab("Utilities")
    UI.Tabs.Settings = UI.CreateTab("Settings")

    UI.BuildStandardUI()

    print("[Zxscript] UI initialized successfully with Rayfield Gen2!")
    return UI
end

function UI.Toggle()
    if UI.Window then
        UI.Window:ToggleHide()
    end
end

function UI.SelectTab(tabObj)
    if tabObj and tabObj._rayfieldTab then
        tabObj._rayfieldTab:Select()
    end
end

function UI.CreateTab(name)
    local rfTab = UI.Window:CreateTab({ name = name })

    local tab = {
        Name = name,
        _rayfieldTab = rfTab,
    }

    -- Paragraph / Text element
    function tab:AddParagraph(options)
        return rfTab:CreateText({
            title = options.Title or "",
            content = options.Content or options.Description or "",
        })
    end

    -- Toggle element
    function tab:AddToggle(id, options)
        return rfTab:CreateToggle({
            name = options.Title or id,
            flag = id,
            value = options.Default or false,
            callback = options.Callback or function() end,
        })
    end

    -- Button element
    function tab:AddButton(options)
        return rfTab:CreateButton({
            name = options.Title or "Button",
            callback = options.Callback or function() end,
        })
    end

    -- Slider element
    function tab:AddSlider(id, options)
        local minVal = options.Min or 0
        local maxVal = options.Max or 100
        local defaultVal = options.Default or minVal

        return rfTab:CreateSlider({
            name = options.Title or id,
            flag = id,
            range = { minVal, maxVal },
            value = defaultVal,
            callback = options.Callback or function() end,
        })
    end

    -- Dropdown element
    function tab:AddDropdown(id, options)
        local defaultValue = options.Default or (options.Values and options.Values[1])

        return rfTab:CreateDropdown({
            name = options.Title or id,
            flag = id,
            options = options.Values or {},
            value = { tostring(defaultValue) },
            callback = function(selected)
                -- Rayfield dropdown .value is always a table; pass first element for compatibility
                if options.Callback then
                    if type(selected) == "table" then
                        options.Callback(selected[1])
                    else
                        options.Callback(selected)
                    end
                end
            end,
        })
    end

    -- Input element
    function tab:AddInput(id, options)
        return rfTab:CreateInput({
            name = options.Title or id,
            flag = id,
            value = options.Default or "",
            callback = options.Callback or function() end,
        })
    end

    -- Colorpicker element
    function tab:AddColorpicker(id, options)
        return rfTab:CreateColorPicker({
            name = options.Title or id,
            flag = id,
            value = options.Default or Color3.fromRGB(255, 60, 60),
            callback = options.Callback or function() end,
        })
    end

    -- Section element
    function tab:AddSection(name)
        return rfTab:CreateSection({ name = name })
    end

    return tab
end

function UI.BuildStandardUI()
    local VisualsModule = require(script.Parent.Parent.modules.visuals)
    local CombatModule = require(script.Parent.Parent.modules.combat)
    local MovementModule = require(script.Parent.Parent.modules.movement)
    local UtilityModule = require(script.Parent.Parent.modules.utility)

    local tabs = UI.Tabs

    ----------------------------------------------------------------------
    -- HOME TAB
    ----------------------------------------------------------------------
    tabs.Home:AddParagraph({
        Title = "Zxscript",
        Description = "Place ID: " .. tostring(game.PlaceId) .. " | " .. Utils.GetExecutor() .. "\nPress [Right-Ctrl] to hide/show the window."
    })

    tabs.Home:AddButton({
        Title = "Copy GitHub Repository Link",
        Callback = function()
            Utils.SetClipboard("https://github.com/mmtandico/Zax-Script")
            Notifications.Success("GitHub link copied to clipboard!")
        end
    })

    ----------------------------------------------------------------------
    -- COMBAT TAB
    ----------------------------------------------------------------------
    tabs.Combat:AddToggle("AimbotToggle", {
        Title = "Enable Aimbot (Hold Right-Click)",
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
        Default = Config.CurrentConfig.Combat.FOV,
        Min = 20,
        Max = 500,
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
        Default = Config.CurrentConfig.Combat.Smoothness,
        Min = 1,
        Max = 20,
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
        Title = "2D Box ESP",
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
        Title = "Highlight Chams (Wallhack)",
        Default = Config.CurrentConfig.Visuals.HighlightChams,
        Callback = function(val)
            Config.CurrentConfig.Visuals.HighlightChams = val
        end
    })

    tabs.Visuals:AddColorpicker("ESPColor", {
        Title = "ESP Accent Color",
        Default = Color3.fromRGB(Config.CurrentConfig.Visuals.BoxColor[1], Config.CurrentConfig.Visuals.BoxColor[2], Config.CurrentConfig.Visuals.BoxColor[3]),
        Callback = function(color)
            Config.CurrentConfig.Visuals.BoxColor = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
        end
    })

    ----------------------------------------------------------------------
    -- MOVEMENT TAB
    ----------------------------------------------------------------------
    tabs.Movement:AddToggle("FlyToggle", {
        Title = "Fly Hack (WASD + Space/Shift)",
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
        Callback = function(val)
            Config.CurrentConfig.Movement.FlySpeed = val
        end
    })

    tabs.Movement:AddToggle("NoclipToggle", {
        Title = "Noclip (Walk Through Walls)",
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
        Title = "Anti-AFK (Bypass 20m Disconnect)",
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
        Title = "Rejoin Server",
        Callback = function()
            UtilityModule.Rejoin()
        end
    })

    tabs.Utility:AddButton({
        Title = "Server Hop",
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
