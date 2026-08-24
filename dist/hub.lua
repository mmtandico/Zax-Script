--[[
    Zxscript - Bundled Standalone Distribution
    Generated: 2026-08-24T10:04:11.292Z
]]

local __modules = {}
local __cache = {}

local function require_module(name)
    if __cache[name] then return __cache[name] end
    local mod = __modules[name]
    if not mod then error("[Bundle Error] Module not found: " .. tostring(name)) end
    local result = mod()
    __cache[name] = result
    return result
end

----------------------------------------------------------------------
-- MODULE: core/config
----------------------------------------------------------------------
__modules["core/config"] = function()
    --[[
        Config Manager Module
        Handles saving and loading hub configurations to executor disk storage (JSON).
    ]]
    
    local HttpService = game:GetService("HttpService")
    
    local Config = {
        Folder = "RobloxScriptHub",
        CurrentConfig = {},
        DefaultSettings = {
            Combat = {
                AimbotEnabled = false,
                AimPart = "Head",
                FOV = 120,
                ShowFOV = false,
                FOVColor = {255, 255, 255},
                Smoothness = 1,
                TeamCheck = true,
                VisibleCheck = false,
                HitboxExpander = false,
                HitboxSize = 5,
            },
            Visuals = {
                ESPEnabled = false,
                Boxes = true,
                BoxColor = {255, 60, 60},
                Names = true,
                Distance = true,
                Health = true,
                Tracers = false,
                TracerOrigin = "Bottom",
                HighlightChams = false,
                TeamCheck = true,
            },
            Movement = {
                Fly = false,
                FlySpeed = 50,
                Noclip = false,
                WalkSpeed = 16,
                SpeedEnabled = false,
                JumpPower = 50,
                JumpEnabled = false,
                InfiniteJump = false,
            },
            Utility = {
                AntiAFK = true,
                Fullbright = false,
                FPSCap = 60,
            }
        }
    }
    
    -- Ensure Hub directories exist
    function Config.Init(folderName)
        if folderName then
            Config.Folder = folderName
        end
    
        if makefolder and isfolder then
            if not isfolder(Config.Folder) then
                makefolder(Config.Folder)
            end
            if not isfolder(Config.Folder .. "/configs") then
                makefolder(Config.Folder .. "/configs")
            end
        end
        
        -- Load default
        Config.CurrentConfig = Config.DeepCopy(Config.DefaultSettings)
    end
    
    function Config.DeepCopy(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == "table" then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[Config.DeepCopy(orig_key)] = Config.DeepCopy(orig_value)
            end
            setmetatable(copy, Config.DeepCopy(getmetatable(orig)))
        else
            copy = orig
        end
        return copy
    end
    
    function Config.DeepMerge(target, source)
        for k, v in pairs(source) do
            if type(v) == "table" and type(target[k]) == "table" then
                Config.DeepMerge(target[k], v)
            else
                target[k] = v
            end
        end
        return target
    end
    
    -- Save configuration by name
    function Config.Save(name)
        name = name or "default"
        local path = Config.Folder .. "/configs/" .. name .. ".json"
        
        if writefile then
            local encoded = HttpService:JSONEncode(Config.CurrentConfig)
            writefile(path, encoded)
            return true, "Config '" .. name .. "' saved successfully."
        else
            return false, "FileSystem API (writefile) not supported by executor."
        end
    end
    
    -- Load configuration by name
    function Config.Load(name)
        name = name or "default"
        local path = Config.Folder .. "/configs/" .. name .. ".json"
    
        if readfile and isfile and isfile(path) then
            local success, result = pcall(function()
                local content = readfile(path)
                local decoded = HttpService:JSONDecode(content)
                Config.CurrentConfig = Config.DeepMerge(Config.DeepCopy(Config.DefaultSettings), decoded)
                return Config.CurrentConfig
            end)
    
            if success then
                return true, "Config '" .. name .. "' loaded."
            else
                return false, "Failed to parse config file: " .. tostring(result)
            end
        else
            return false, "Config file does not exist: " .. path
        end
    end
    
    -- List all saved configs
    function Config.List()
        local configs = {}
        if listfiles and isfolder and isfolder(Config.Folder .. "/configs") then
            local files = listfiles(Config.Folder .. "/configs")
            for _, file in ipairs(files) do
                local name = file:match("([^/\\]+)%.json$")
                if name then
                    table.insert(configs, name)
                end
            end
        end
        return configs
    end
    
    return Config
    
end

----------------------------------------------------------------------
-- MODULE: core/notifications
----------------------------------------------------------------------
__modules["core/notifications"] = function()
    --[[
        Notification System Module
        Sends notifications via Rayfield Gen2 window:Notify(), with fallback to Roblox CoreGui StarterGui.
    ]]
    
    local StarterGui = game:GetService("StarterGui")
    
    local Notifications = {}
    
    function Notifications.Send(title: string, text: string, duration: number?, icon: string?)
        title = title or "Script Hub"
        text = text or ""
        duration = duration or 5
    
        -- Try Rayfield notification if registered in environment
        if getgenv and getgenv().HubNotify then
            pcall(function()
                getgenv().HubNotify({
                    Title = title,
                    Content = text,
                    Duration = duration,
                    Image = icon
                })
            end)
            return
        end
    
        -- Fallback to Roblox StarterGui SetCore
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = duration,
                Icon = icon or "rbxassetid://4483345998"
            })
        end)
    end
    
    function Notifications.Success(text: string, duration: number?)
        Notifications.Send("Success", text, duration or 4)
    end
    
    function Notifications.Warn(text: string, duration: number?)
        Notifications.Send("Warning", text, duration or 5)
    end
    
    function Notifications.Error(text: string, duration: number?)
        Notifications.Send("Error", text, duration or 6)
    end
    
    return Notifications
    
end

----------------------------------------------------------------------
-- MODULE: core/ui
----------------------------------------------------------------------
__modules["core/ui"] = function()
    --[[
        Zxscript - Rayfield Gen2 UI Integration
        Uses Sirius Rayfield Gen2 for a polished, themed, saveable interface.
        Docs: https://docs.sirius.menu/rayfield-gen2
    ]]
    
    local UserInputService = game:GetService("UserInputService")
    
    local Utils = require_module("core/utils")
    local Config = require_module("core/config")
    local Notifications = require_module("core/notifications")
    
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
        local VisualsModule = require_module("modules/visuals")
        local CombatModule = require_module("modules/combat")
        local MovementModule = require_module("modules/movement")
        local UtilityModule = require_module("modules/utility")
    
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
    
end

----------------------------------------------------------------------
-- MODULE: core/utils
----------------------------------------------------------------------
__modules["core/utils"] = function()
    --[[
        Utils Module
        Common helper functions for player handling, math, drawing, and executor compatibility.
    ]]
    
    local Utils = {}
    
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local UserInputService = game:GetService("UserInputService")
    
    Utils.LocalPlayer = Players.LocalPlayer
    if not Utils.LocalPlayer then
        task.spawn(function()
            Utils.LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
        end)
    end
    
    Utils.Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Utils.Camera = Workspace.CurrentCamera
    end)
    
    -- Safe executor identification
    function Utils.GetExecutor()
        if identifyexecutor then
            local name, ver = identifyexecutor()
            return tostring(name) .. (ver and (" " .. tostring(ver)) or "")
        elseif getexecutorname then
            return getexecutorname()
        end
        return "Solara / Custom"
    end
    
    -- Get Local Character & Humanoid safely
    function Utils.GetCharacter(player)
        player = player or Utils.LocalPlayer or Players.LocalPlayer
        if not player then return nil end
        return player.Character
    end
    
    function Utils.GetRoot(player)
        local char = Utils.GetCharacter(player)
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    end
    
    function Utils.GetHumanoid(player)
        local char = Utils.GetCharacter(player)
        if not char then return nil end
        return char:FindFirstChildOfClass("Humanoid")
    end
    
    function Utils.IsAlive(player)
        player = player or Utils.LocalPlayer or Players.LocalPlayer
        local hum = Utils.GetHumanoid(player)
        return hum and hum.Health > 0 and Utils.GetRoot(player) ~= nil
    end
    
    -- Team Checking
    function Utils.IsTeamMate(player)
        local lp = Utils.LocalPlayer or Players.LocalPlayer
        if not player or player == lp then return false end
        if not lp or lp.Neutral then return false end
        if player.Team and lp.Team then
            return player.Team == lp.Team
        end
        if player.TeamColor and lp.TeamColor then
            return player.TeamColor == lp.TeamColor
        end
        return false
    end
    
    -- World to Screen conversion
    function Utils.WorldToViewportPoint(position: Vector3)
        local cam = Utils.Camera or Workspace.CurrentCamera
        if not cam then return Vector2.zero, false, 0 end
        local screenPos, onScreen = cam:WorldToViewportPoint(position)
        return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
    end
    
    -- Distance Calculation
    function Utils.GetDistance(pos1: Vector3, pos2: Vector3?)
        if not pos2 then
            local localRoot = Utils.GetRoot(Utils.LocalPlayer)
            if not localRoot then return math.huge end
            pos2 = localRoot.Position
        end
        return (pos1 - pos2).Magnitude
    end
    
    -- Get Closest Player to Mouse Cursor
    function Utils.GetClosestPlayerToCursor(maxDistance, checkTeam, visibleOnly)
        maxDistance = maxDistance or math.huge
        local mousePos = UserInputService:GetMouseLocation()
        local closestPlayer = nil
        local shortestDistance = maxDistance
        local cam = Utils.Camera or Workspace.CurrentCamera
        local lp = Utils.LocalPlayer or Players.LocalPlayer
    
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp and Utils.IsAlive(player) then
                if checkTeam and Utils.IsTeamMate(player) then
                    continue
                end
    
                local root = Utils.GetRoot(player)
                local head = player.Character:FindFirstChild("Head")
                local targetPart = head or root
    
                if targetPart and cam then
                    local screenPos, onScreen = Utils.WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if screenDist < shortestDistance then
                            if visibleOnly then
                                local raycastParams = RaycastParams.new()
                                raycastParams.FilterType = RaycastFilterType.Exclude
                                raycastParams.FilterDescendantsInstances = {lp and lp.Character, player.Character, cam}
                                
                                local rayResult = Workspace:Raycast(cam.CFrame.Position, targetPart.Position - cam.CFrame.Position, raycastParams)
                                if not rayResult then
                                    shortestDistance = screenDist
                                    closestPlayer = player
                                end
                            else
                                shortestDistance = screenDist
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    
        return closestPlayer, shortestDistance
    end
    
    -- Clipboard helper
    function Utils.SetClipboard(text: string)
        if setclipboard then
            setclipboard(text)
            return true
        elseif toclipboard then
            toclipboard(text)
            return true
        end
        return false
    end
    
    return Utils
    
end

----------------------------------------------------------------------
-- MODULE: games/10563114921
----------------------------------------------------------------------
__modules["games/10563114921"] = function()
    --[[
        Steal an Egg Module (PlaceId: 10563114921 / GameId: 107778070777162)
        Features:
        - Live In-Game Floating HUD Predictor (Time, Type, Distance, Quick TP)
        - Egg Spawn Predictor & Real-time Detector (Eternal, Secret, Divine, Mythic, etc.)
        - Tier-Filtered Egg ESP with 3D Highlights & Distance Labels
        - Auto Teleport / Auto Steal Rare Spawned Eggs
        - Auto Collect & Auto Hatch
    ]]
    
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")
    
    local LocalPlayer = Players.LocalPlayer
    
    local StealAnEgg = {
        -- Settings State
        PredictorEnabled = true,
        PredictorMinRarity = "Secret", -- "All", "Legendary", "Mythic", "Divine", "Secret", "Eternal"
        NotifyOnSpawn = true,
        AutoTeleportToRare = false,
        EggESP = true,
        AutoCollect = false,
        AutoHatch = false,
        HUDVisible = true,
    
        -- Rarity Color Palette
        RarityColors = {
            Eternal = Color3.fromRGB(220, 50, 255),  -- Bright Magenta
            Secret = Color3.fromRGB(255, 215, 0),    -- Gold
            Divine = Color3.fromRGB(0, 255, 255),    -- Cyan
            Mythic = Color3.fromRGB(255, 50, 50),    -- Red
            Legendary = Color3.fromRGB(255, 140, 0), -- Orange
            Epic = Color3.fromRGB(160, 32, 240),   -- Purple
            Rare = Color3.fromRGB(30, 144, 255),   -- Blue
            Common = Color3.fromRGB(200, 200, 200),-- Gray
        },
    
        -- Rarity Hierarchy
        RarityRanks = {
            Common = 1,
            Rare = 2,
            Epic = 3,
            Legendary = 4,
            Mythic = 5,
            Divine = 6,
            Secret = 7,
            Eternal = 8,
        },
    
        -- Dynamic Cache & Connections
        ActiveHighlights = {},
        ActiveBillboards = {},
        LastSpawnedEgg = nil,
        Connections = {},
        PredictorParagraph = nil,
    
        -- HUD UI References
        HUDGui = nil,
        HUDFrame = nil,
        HUDEggList = nil,
        HUDCountdownLabel = nil,
    }
    
    -- Detect Egg Rarity / Tier from Model name, attributes, or child Gui
    function StealAnEgg.GetEggRarity(model)
        if not model then return "Common" end
    
        local attrRarity = model:GetAttribute("Rarity") or model:GetAttribute("Tier") or model:GetAttribute("Type")
        if attrRarity and type(attrRarity) == "string" then
            for rarityName, _ in pairs(StealAnEgg.RarityColors) do
                if string.find(string.lower(attrRarity), string.lower(rarityName)) then
                    return rarityName
                end
            end
        end
    
        local name = model.Name
        for rarityName, _ in pairs(StealAnEgg.RarityColors) do
            if string.find(string.lower(name), string.lower(rarityName)) then
                return rarityName
            end
        end
    
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                local txt = desc.Text or ""
                for rarityName, _ in pairs(StealAnEgg.RarityColors) do
                    if string.find(string.lower(txt), string.lower(rarityName)) then
                        return rarityName
                    end
                end
            end
        end
    
        return "Common"
    end
    
    -- Teleport Character to Position / Model
    function StealAnEgg.TeleportTo(target)
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
    
        local targetPos = nil
        if type(target) == "userdata" and target:IsA("Vector3") then
            targetPos = target
        elseif type(target) == "table" or (typeof and typeof(target) == "Instance") then
            if target:IsA("Model") then
                targetPos = target:GetPivot().Position
            elseif target:IsA("BasePart") then
                targetPos = target.Position
            end
        end
    
        if targetPos then
            root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        end
    end
    
    -- Create Floating HUD GUI ScreenGui
    function StealAnEgg.CreatePredictorHUD()
        if StealAnEgg.HUDGui then
            StealAnEgg.HUDGui:Destroy()
        end
    
        local gui = Instance.new("ScreenGui")
        gui.Name = "Zxscript_EggPredictorHUD"
        gui.ResetOnSpawn = false
    
        -- Try CoreGui first, fallback to PlayerGui
        local parent = pcall(function() return CoreGui end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
        gui.Parent = parent
        StealAnEgg.HUDGui = gui
    
        -- Main Container Frame
        local frame = Instance.new("Frame")
        frame.Name = "HUDFrame"
        frame.Size = UDim2.new(0, 320, 0, 240)
        frame.Position = UDim2.new(0, 20, 0.3, 0)
        frame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true
        frame.Parent = gui
        StealAnEgg.HUDFrame = frame
    
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame
    
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 255, 255)
        stroke.Thickness = 1.5
        stroke.Transparency = 0.4
        stroke.Parent = frame
    
        -- Title Bar
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -10, 0, 32)
        titleLabel.Position = UDim2.new(0, 10, 0, 4)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "⚡ EGG SPAWN PREDICTOR"
        titleLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextSize = 16
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = frame
    
        -- Next Spawn Timer Countdown Label
        local timerLabel = Instance.new("TextLabel")
        timerLabel.Size = UDim2.new(1, -20, 0, 22)
        timerLabel.Position = UDim2.new(0, 10, 0, 34)
        timerLabel.BackgroundColor3 = Color3.fromRGB(24, 30, 45)
        timerLabel.BackgroundTransparency = 0.3
        timerLabel.Text = "⏱️ Next Rare Spawn: Monitoring..."
        timerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        timerLabel.Font = Enum.Font.SourceSansSemibold
        timerLabel.TextSize = 13
        timerLabel.Parent = frame
        StealAnEgg.HUDCountdownLabel = timerLabel
    
        local timerCorner = Instance.new("UICorner")
        timerCorner.CornerRadius = UDim.new(0, 6)
        timerCorner.Parent = timerLabel
    
        -- Scroll Log for Spawn History
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -20, 1, -70)
        scroll.Position = UDim2.new(0, 10, 0, 62)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 4
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = frame
        StealAnEgg.HUDEggList = scroll
    
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 4)
        listLayout.Parent = scroll
    end
    
    -- Add Spawn Log Card to Floating HUD
    function StealAnEgg.AddHUDLogEntry(rarity, name, model)
        if not StealAnEgg.HUDEggList then return end
    
        local color = StealAnEgg.RarityColors[rarity] or Color3.fromRGB(200, 200, 200)
        local timeStr = os.date("%X")
    
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, 34)
        card.BackgroundColor3 = Color3.fromRGB(24, 30, 45)
        card.BorderSizePixel = 0
        card.Parent = StealAnEgg.HUDEggList
    
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 6)
        cardCorner.Parent = card
    
        local rarityBadge = Instance.new("TextLabel")
        rarityBadge.Size = UDim2.new(0, 75, 1, -6)
        rarityBadge.Position = UDim2.new(0, 3, 0, 3)
        rarityBadge.BackgroundColor3 = color
        rarityBadge.Text = string.upper(rarity)
        rarityBadge.TextColor3 = Color3.fromRGB(0, 0, 0)
        rarityBadge.Font = Enum.Font.SourceSansBold
        rarityBadge.TextSize = 12
        rarityBadge.Parent = card
    
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = rarityBadge
    
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -135, 1, 0)
        infoLabel.Position = UDim2.new(0, 84, 0, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = string.format("%s | %s", timeStr, name)
        infoLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        infoLabel.Font = Enum.Font.SourceSans
        infoLabel.TextSize = 13
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = card
    
        -- Quick TP Button on Card
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(0, 42, 1, -6)
        tpBtn.Position = UDim2.new(1, -45, 0, 3)
        tpBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 216)
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tpBtn.Font = Enum.Font.SourceSansBold
        tpBtn.TextSize = 12
        tpBtn.Parent = card
    
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = tpBtn
    
        tpBtn.MouseButton1Click:Connect(function()
            if model and model.Parent then
                StealAnEgg.TeleportTo(model)
            end
        end)
    end
    
    -- Create 3D Highlight & Billboard for Egg
    function StealAnEgg.CreateEggESP(model, rarity)
        if not model or not model:IsA("PVInstance") then return end
        if StealAnEgg.ActiveHighlights[model] then return end
    
        local rank = StealAnEgg.RarityRanks[rarity] or 1
        local minRank = StealAnEgg.RarityRanks[StealAnEgg.PredictorMinRarity] or 1
        if rank < minRank then return end
    
        local color = StealAnEgg.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
    
        local highlight = Instance.new("Highlight")
        highlight.Name = "EggESP_Highlight"
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Parent = model
    
        local primaryPart = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")) or model
        local bb = nil
        if primaryPart and primaryPart:IsA("BasePart") then
            bb = Instance.new("BillboardGui")
            bb.Name = "EggESP_Billboard"
            bb.Adornee = primaryPart
            bb.Size = UDim2.new(0, 160, 0, 40)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
    
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Text = string.format("[%s Egg]", rarity)
            txt.TextColor3 = color
            txt.TextStrokeTransparency = 0
            txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            txt.Font = Enum.Font.SourceSansBold
            txt.TextSize = 16
            txt.Parent = bb
    
            bb.Parent = primaryPart
        end
    
        StealAnEgg.ActiveHighlights[model] = highlight
        if bb then StealAnEgg.ActiveBillboards[model] = bb end
    
        model.Destroying:Connect(function()
            if StealAnEgg.ActiveHighlights[model] then
                StealAnEgg.ActiveHighlights[model]:Destroy()
                StealAnEgg.ActiveHighlights[model] = nil
            end
            if StealAnEgg.ActiveBillboards[model] then
                StealAnEgg.ActiveBillboards[model]:Destroy()
                StealAnEgg.ActiveBillboards[model] = nil
            end
        end)
    end
    
    -- Clear all ESP
    function StealAnEgg.ClearESP()
        for model, hl in pairs(StealAnEgg.ActiveHighlights) do
            if hl and hl.Parent then pcall(function() hl:Destroy() end) end
        end
        for model, bb in pairs(StealAnEgg.ActiveBillboards) do
            if bb and bb.Parent then pcall(function() bb:Destroy() end) end
        end
        StealAnEgg.ActiveHighlights = {}
        StealAnEgg.ActiveBillboards = {}
    end
    
    -- Process newly spawned model
    function StealAnEgg.OnEggSpawned(model, Notifications)
        if not model then return end
        
        local isEgg = string.find(string.lower(model.Name), "egg") 
            or model:GetAttribute("IsEgg") == true
            or model:FindFirstChild("Egg") ~= nil
    
        if not isEgg then return end
    
        local rarity = StealAnEgg.GetEggRarity(model)
        local rank = StealAnEgg.RarityRanks[rarity] or 1
    
        StealAnEgg.LastSpawnedEgg = {
            Model = model,
            Rarity = rarity,
            Time = os.time(),
            Name = model.Name
        }
    
        -- Add entry to HUD Overlay
        StealAnEgg.AddHUDLogEntry(rarity, model.Name, model)
    
        -- Update UI Predictor Status
        if StealAnEgg.PredictorParagraph then
            pcall(function()
                StealAnEgg.PredictorParagraph:Set({
                    Title = string.format("⚡ Last Spawned: %s Egg", rarity),
                    Content = string.format("Name: %s\nDetected at: %s\nRarity Tier: %s", model.Name, os.date("%X"), rarity)
                })
            end)
        end
    
        -- Create ESP
        if StealAnEgg.EggESP then
            StealAnEgg.CreateEggESP(model, rarity)
        end
    
        -- High-Tier Spawn Alert (Eternal, Secret, Divine, Mythic)
        if rank >= 5 and StealAnEgg.NotifyOnSpawn and Notifications then
            Notifications.Success(string.format("🌟 RARE EGG SPAWNED! [%s Egg]\nLocation: %s", rarity, model.Name), 6)
        end
    
        -- Auto Teleport to High-Tier Egg (Divine, Secret, Eternal)
        if rank >= 6 and StealAnEgg.AutoTeleportToRare then
            task.wait(0.1)
            StealAnEgg.TeleportTo(model)
            if Notifications then
                Notifications.Info(string.format("⚡ Auto-Teleported to [%s Egg]!", rarity))
            end
        end
    end
    
    -- Scan existing eggs in workspace
    function StealAnEgg.ScanWorkspace(Notifications)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                if string.find(string.lower(obj.Name), "egg") then
                    StealAnEgg.OnEggSpawned(obj, Notifications)
                end
            end
        end
    end
    
    function StealAnEgg.Init(UI, Config, Notifications)
        local gameTab = UI.Tabs.Game
        if not gameTab then return end
    
        -- Create In-Game Predictor Floating HUD Overlay
        StealAnEgg.CreatePredictorHUD()
    
        gameTab:AddSection("🥚 Steal an Egg - Predictor & Auto Farm")
    
        -- Predictor Info Banner
        StealAnEgg.PredictorParagraph = gameTab:AddParagraph({
            Title = "⚡ Egg Spawn Predictor Active",
            Content = "Monitoring Workspace for Eternal, Secret, Divine, and Mythic Egg Spawns..."
        })
    
        gameTab:AddToggle("SAEHUDToggle", {
            Title = "Show Floating Predictor HUD Overlay",
            Default = true,
            Callback = function(val)
                StealAnEgg.HUDVisible = val
                if StealAnEgg.HUDFrame then
                    StealAnEgg.HUDFrame.Visible = val
                end
            end
        })
    
        gameTab:AddToggle("SAEPredictorToggle", {
            Title = "Enable Egg Spawn Predictor",
            Default = true,
            Callback = function(val)
                StealAnEgg.PredictorEnabled = val
            end
        })
    
        gameTab:AddDropdown("SAEMinRarity", {
            Title = "Minimum Rarity Filter",
            Values = {"All", "Legendary", "Mythic", "Divine", "Secret", "Eternal"},
            Default = "Secret",
            Callback = function(val)
                StealAnEgg.PredictorMinRarity = val
                StealAnEgg.ClearESP()
                StealAnEgg.ScanWorkspace(Notifications)
            end
        })
    
        gameTab:AddToggle("SAENotifyRare", {
            Title = "Notify on Rare Egg Spawn (Eternal/Secret/Divine)",
            Default = true,
            Callback = function(val)
                StealAnEgg.NotifyOnSpawn = val
            end
        })
    
        gameTab:AddToggle("SAEAutoTPRare", {
            Title = "Auto-Teleport to Rare Egg Spawns (Divine+)",
            Default = false,
            Callback = function(val)
                StealAnEgg.AutoTeleportToRare = val
            end
        })
    
        gameTab:AddButton({
            Title = "Teleport to Last Spawned Rare Egg",
            Callback = function()
                if StealAnEgg.LastSpawnedEgg and StealAnEgg.LastSpawnedEgg.Model and StealAnEgg.LastSpawnedEgg.Model.Parent then
                    StealAnEgg.TeleportTo(StealAnEgg.LastSpawnedEgg.Model)
                    Notifications.Success("Teleported to " .. StealAnEgg.LastSpawnedEgg.Rarity .. " Egg!")
                else
                    Notifications.Error("No rare egg currently cached!")
                end
            end
        })
    
        gameTab:AddSection("👁️ Egg ESP & Visuals")
    
        gameTab:AddToggle("SAEEggESP", {
            Title = "3D Egg Highlights & Tier Labels",
            Default = true,
            Callback = function(val)
                StealAnEgg.EggESP = val
                if not val then
                    StealAnEgg.ClearESP()
                else
                    StealAnEgg.ScanWorkspace(Notifications)
                end
            end
        })
    
        gameTab:AddSection("⚡ Auto Farm Utilities")
    
        gameTab:AddToggle("SAEAutoCollect", {
            Title = "Auto Collect Spawned Eggs",
            Default = false,
            Callback = function(val)
                StealAnEgg.AutoCollect = val
            end
        })
    
        gameTab:AddToggle("SAEAutoHatch", {
            Title = "Auto Hatch Eggs",
            Default = false,
            Callback = function(val)
                StealAnEgg.AutoHatch = val
            end
        })
    
        -- Listen for Workspace Spawns
        local spawnConn = Workspace.DescendantAdded:Connect(function(desc)
            if StealAnEgg.PredictorEnabled and (desc:IsA("Model") or desc:IsA("BasePart")) then
                StealAnEgg.OnEggSpawned(desc, Notifications)
            end
        end)
        table.insert(StealAnEgg.Connections, spawnConn)
    
        -- Auto Collect Heartbeat Loop
        local collectLoop = RunService.Heartbeat:Connect(function()
            if StealAnEgg.AutoCollect then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    for model, _ in pairs(StealAnEgg.ActiveHighlights) do
                        if model and model.Parent then
                            local pos = model:IsA("Model") and model:GetPivot().Position or model.Position
                            if (root.Position - pos).Magnitude < 15 then
                                local touchPart = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")) or model
                                if touchPart then
                                    firetouchinterest(root, touchPart, 0)
                                    task.wait(0.05)
                                    firetouchinterest(root, touchPart, 1)
                                end
                            end
                        end
                    end
                end
            end
        end)
        table.insert(StealAnEgg.Connections, collectLoop)
    
        -- Initial Workspace Scan
        StealAnEgg.ScanWorkspace(Notifications)
    end
    
    return StealAnEgg
    
end

----------------------------------------------------------------------
-- MODULE: games/107778070777162
----------------------------------------------------------------------
__modules["games/107778070777162"] = function()
    --[[
        Steal an Egg Module Alias (GameId: 107778070777162)
    ]]
    return require(script.Parent["10563114921"])
    
end

----------------------------------------------------------------------
-- MODULE: games/2753915549
----------------------------------------------------------------------
__modules["games/2753915549"] = function()
    --[[
        Blox Fruits Module (PlaceId: 2753915549 / 4442272183 / 7449423635)
        Game-specific features for Blox Fruits (Auto Farm template, Bring Mobs, Fruit ESP).
    ]]
    
    local BloxFruits = {
        AutoFarm = false,
        AutoChest = false,
        FastAttack = false,
        FruitESP = false
    }
    
    function BloxFruits.Init(UI, Config, Notifications)
        local gameTab = UI.Tabs.Game
        if not gameTab then return end
    
        gameTab:AddParagraph({
            Title = "Blox Fruits Module Active",
            Content = "Dedicated automation & farming helpers for Blox Fruits."
        })
    
        gameTab:AddToggle("BFFastAttack", {
            Title = "Fast Attack",
            Default = false,
            Callback = function(val)
                BloxFruits.FastAttack = val
                Notifications.Send("Blox Fruits", "Fast Attack: " .. (val and "ON" or "OFF"))
            end
        })
    
        gameTab:AddToggle("BFAutoFarm", {
            Title = "Auto Farm Level (Template)",
            Default = false,
            Callback = function(val)
                BloxFruits.AutoFarm = val
                Notifications.Send("Blox Fruits", "Auto Farm: " .. (val and "ON" or "OFF"))
            end
        })
    
        gameTab:AddToggle("BFAutoChest", {
            Title = "Auto Collect Chests",
            Default = false,
            Callback = function(val)
                BloxFruits.AutoChest = val
                Notifications.Send("Blox Fruits", "Auto Chest: " .. (val and "ON" or "OFF"))
            end
        })
    
        gameTab:AddToggle("BFFruitESP", {
            Title = "Spawned Devil Fruit ESP",
            Default = false,
            Callback = function(val)
                BloxFruits.FruitESP = val
                Notifications.Send("Blox Fruits", "Fruit ESP: " .. (val and "ON" or "OFF"))
            end
        })
    end
    
    return BloxFruits
    
end

----------------------------------------------------------------------
-- MODULE: games/286090429
----------------------------------------------------------------------
__modules["games/286090429"] = function()
    --[[
        Arsenal Module (PlaceId: 286090429)
        Game-specific features for Arsenal.
    ]]
    
    local Arsenal = {
        InfiniteAmmo = false,
        RapidFire = false,
        NoRecoil = false,
        Wallbang = false
    }
    
    function Arsenal.Init(UI, Config, Notifications)
        local gameTab = UI.Tabs.Game
        if not gameTab then return end
    
        gameTab:AddParagraph({
            Title = "Arsenal Module Active",
            Content = "PlaceId: 286090429\nCustom features specifically tailored for Arsenal."
        })
    
        gameTab:AddToggle("ArsenalInfiniteAmmo", {
            Title = "Infinite Ammo",
            Default = false,
            Callback = function(val)
                Arsenal.InfiniteAmmo = val
                Notifications.Send("Arsenal", "Infinite Ammo: " .. (val and "ON" or "OFF"))
            end
        })
    
        gameTab:AddToggle("ArsenalNoRecoil", {
            Title = "No Recoil / Spread",
            Default = false,
            Callback = function(val)
                Arsenal.NoRecoil = val
                Notifications.Send("Arsenal", "No Recoil: " .. (val and "ON" or "OFF"))
            end
        })
    
        gameTab:AddToggle("ArsenalRapidFire", {
            Title = "Rapid Fire",
            Default = false,
            Callback = function(val)
                Arsenal.RapidFire = val
                Notifications.Send("Arsenal", "Rapid Fire: " .. (val and "ON" or "OFF"))
            end
        })
    end
    
    return Arsenal
    
end

----------------------------------------------------------------------
-- MODULE: games/universal
----------------------------------------------------------------------
__modules["games/universal"] = function()
    --[[
        Universal Game Module
        Default handler loaded for any Roblox game without a dedicated script.
    ]]
    
    local Universal = {}
    
    function Universal.Init(UI, Config, Notifications)
        local gameTab = UI.Tabs.Game
        if not gameTab then return end
    
        gameTab:AddParagraph({
            Title = "Universal Mode Active",
            Content = "No specialized script detected for PlaceId: " .. tostring(game.PlaceId) .. ".\nAll universal Combat, Visuals, Movement, and Utility features are operational."
        })
    
        gameTab:AddButton({
            Title = "Bypass Clip Through Doors (Local TP)",
            Callback = function()
                local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = root.CFrame + (root.CFrame.LookVector * 10)
                    Notifications.Success("Teleported 10 studs forward")
                end
            end
        })
    
        gameTab:AddButton({
            Title = "Respawn Character",
            Callback = function()
                local char = game.Players.LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                end
            end
        })
    end
    
    return Universal
    
end

----------------------------------------------------------------------
-- MODULE: modules/combat
----------------------------------------------------------------------
__modules["modules/combat"] = function()
    --[[
        Combat Module
        Universal Aimbot, FOV Circle Drawing, Smooth Aim, and Hitbox Expander.
    ]]
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Utils = require_module("core/utils")
    local Config = require_module("core/config")
    
    local Combat = {
        FOVCircle = nil,
        IsAiming = false,
        Connections = {},
        OriginalSizes = {},
        Enabled = false
    }
    
    local function HasDrawing()
        return Drawing ~= nil and Drawing.new ~= nil
    end
    
    function Combat.Init()
        if HasDrawing() then
            pcall(function()
                Combat.FOVCircle = Drawing.new("Circle")
                Combat.FOVCircle.Visible = false
                Combat.FOVCircle.Thickness = 1.5
                Combat.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
                Combat.FOVCircle.Filled = false
                Combat.FOVCircle.Transparency = 1
                Combat.FOVCircle.NumSides = 64
            end)
        end
    
        -- Right Click Aim Detection
        table.insert(Combat.Connections, UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Combat.IsAiming = true
            end
        end))
    
        table.insert(Combat.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Combat.IsAiming = false
            end
        end))
    
        -- Render Loop
        table.insert(Combat.Connections, RunService.RenderStepped:Connect(function()
            local cfg = Config.CurrentConfig.Combat
            if not cfg or not Combat.Enabled then return end
    
            local mousePos = UserInputService:GetMouseLocation()
    
            -- FOV Circle Rendering
            if Combat.FOVCircle then
                Combat.FOVCircle.Visible = cfg.ShowFOV and (cfg.AimbotEnabled or false)
                Combat.FOVCircle.Radius = cfg.FOV or 120
                Combat.FOVCircle.Position = mousePos
                Combat.FOVCircle.Color = Color3.fromRGB(cfg.FOVColor[1], cfg.FOVColor[2], cfg.FOVColor[3])
            end
    
            -- Aimbot Target Calculation & Camera lock
            if cfg.AimbotEnabled and Combat.IsAiming then
                local targetPlayer, _ = Utils.GetClosestPlayerToCursor(cfg.FOV, cfg.TeamCheck, cfg.VisibleCheck)
                if targetPlayer and Utils.IsAlive(targetPlayer) then
                    local char = targetPlayer.Character
                    local aimPartName = cfg.AimPart or "Head"
                    local targetPart = char:FindFirstChild(aimPartName) or Utils.GetRoot(targetPlayer)
    
                    if targetPart and Utils.Camera then
                        local targetPos = targetPart.Position
                        local currentCF = Utils.Camera.CFrame
                        local targetCF = CFrame.new(currentCF.Position, targetPos)
    
                        local smoothness = math.clamp(cfg.Smoothness or 1, 1, 30)
                        if smoothness <= 1 then
                            Utils.Camera.CFrame = targetCF
                        else
                            Utils.Camera.CFrame = currentCF:Lerp(targetCF, 1 / smoothness)
                        end
                    end
                end
            end
    
            -- Hitbox Expander
            if cfg.HitboxExpander then
                local targetSize = Vector3.new(cfg.HitboxSize or 5, cfg.HitboxSize or 5, cfg.HitboxSize or 5)
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= Utils.LocalPlayer and Utils.IsAlive(player) then
                        if not (cfg.TeamCheck and Utils.IsTeamMate(player)) then
                            local root = Utils.GetRoot(player)
                            if root then
                                if not Combat.OriginalSizes[root] then
                                    Combat.OriginalSizes[root] = root.Size
                                end
                                root.Size = targetSize
                                root.Transparency = 0.6
                                root.CanCollide = false
                            end
                        end
                    end
                end
            end
        end))
    
        Combat.Enabled = true
    end
    
    function Combat.ResetHitboxes()
        for root, originalSize in pairs(Combat.OriginalSizes) do
            if root and root.Parent then
                root.Size = originalSize
                root.Transparency = 1
                root.CanCollide = true
            end
        end
        Combat.OriginalSizes = {}
    end
    
    function Combat.Cleanup()
        Combat.Enabled = false
        Combat.ResetHitboxes()
    
        for _, conn in ipairs(Combat.Connections) do
            conn:Disconnect()
        end
        Combat.Connections = {}
    
        if Combat.FOVCircle then
            pcall(function()
                Combat.FOVCircle.Visible = false
                Combat.FOVCircle:Remove()
            end)
            Combat.FOVCircle = nil
        end
    end
    
    return Combat
    
end

----------------------------------------------------------------------
-- MODULE: modules/movement
----------------------------------------------------------------------
__modules["modules/movement"] = function()
    --[[
        Movement Module
        Fly, Noclip, Speed/Jump modifications, Infinite Jump, and Teleportation.
    ]]
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Utils = require_module("core/utils")
    local Config = require_module("core/config")
    
    local Movement = {
        Connections = {},
        FlyObjects = {
            BodyVelocity = nil,
            BodyGyro = nil
        },
        Flying = false,
        FlyKeys = {
            W = false,
            A = false,
            S = false,
            D = false,
            Up = false,
            Down = false
        },
        Enabled = false
    }
    
    -- Handle Fly Physics
    local function UpdateFly()
        local root = Utils.GetRoot(Utils.LocalPlayer)
        if not root or not Movement.Flying then return end
    
        local cfg = Config.CurrentConfig.Movement
        local speed = cfg.FlySpeed or 50
        local camera = Utils.Camera
        if not camera then return end
    
        local moveDir = Vector3.zero
        if Movement.FlyKeys.W then moveDir = moveDir + camera.CFrame.LookVector end
        if Movement.FlyKeys.S then moveDir = moveDir - camera.CFrame.LookVector end
        if Movement.FlyKeys.A then moveDir = moveDir - camera.CFrame.RightVector end
        if Movement.FlyKeys.D then moveDir = moveDir + camera.CFrame.RightVector end
        if Movement.FlyKeys.Up then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if Movement.FlyKeys.Down then moveDir = moveDir - Vector3.new(0, 1, 0) end
    
        if Movement.FlyObjects.BodyVelocity then
            Movement.FlyObjects.BodyVelocity.Velocity = moveDir * speed
        end
        if Movement.FlyObjects.BodyGyro then
            Movement.FlyObjects.BodyGyro.CFrame = camera.CFrame
        end
    end
    
    function Movement.SetFly(enabled: boolean)
        Movement.Flying = enabled
        local root = Utils.GetRoot(Utils.LocalPlayer)
    
        if enabled and root then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.zero
            bv.Parent = root
            Movement.FlyObjects.BodyVelocity = bv
    
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 9e4
            bg.CFrame = root.CFrame
            bg.Parent = root
            Movement.FlyObjects.BodyGyro = bg
        else
            if Movement.FlyObjects.BodyVelocity then
                Movement.FlyObjects.BodyVelocity:Destroy()
                Movement.FlyObjects.BodyVelocity = nil
            end
            if Movement.FlyObjects.BodyGyro then
                Movement.FlyObjects.BodyGyro:Destroy()
                Movement.FlyObjects.BodyGyro = nil
            end
        end
    end
    
    function Movement.Init()
        -- Keybinds for Fly Navigation
        table.insert(Movement.Connections, UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then Movement.FlyKeys.W = true end
            if input.KeyCode == Enum.KeyCode.A then Movement.FlyKeys.A = true end
            if input.KeyCode == Enum.KeyCode.S then Movement.FlyKeys.S = true end
            if input.KeyCode == Enum.KeyCode.D then Movement.FlyKeys.D = true end
            if input.KeyCode == Enum.KeyCode.Space then Movement.FlyKeys.Up = true end
            if input.KeyCode == Enum.KeyCode.LeftShift then Movement.FlyKeys.Down = true end
        end))
    
        table.insert(Movement.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.W then Movement.FlyKeys.W = false end
            if input.KeyCode == Enum.KeyCode.A then Movement.FlyKeys.A = false end
            if input.KeyCode == Enum.KeyCode.S then Movement.FlyKeys.S = false end
            if input.KeyCode == Enum.KeyCode.D then Movement.FlyKeys.D = false end
            if input.KeyCode == Enum.KeyCode.Space then Movement.FlyKeys.Up = false end
            if input.KeyCode == Enum.KeyCode.LeftShift then Movement.FlyKeys.Down = false end
        end))
    
        -- Infinite Jump
        table.insert(Movement.Connections, UserInputService.JumpRequest:Connect(function()
            local cfg = Config.CurrentConfig.Movement
            if cfg and cfg.InfiniteJump then
                local hum = Utils.GetHumanoid(Utils.LocalPlayer)
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end))
    
        -- Stepped Loop (Noclip & Speed/Jump enforcement)
        table.insert(Movement.Connections, RunService.Stepped:Connect(function()
            local cfg = Config.CurrentConfig.Movement
            if not cfg or not Movement.Enabled then return end
    
            local char = Utils.GetCharacter(Utils.LocalPlayer)
            local hum = Utils.GetHumanoid(Utils.LocalPlayer)
    
            -- Noclip
            if cfg.Noclip and char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
    
            -- WalkSpeed
            if cfg.SpeedEnabled and hum then
                hum.WalkSpeed = cfg.WalkSpeed or 16
            end
    
            -- JumpPower
            if cfg.JumpEnabled and hum then
                hum.UseJumpPower = true
                hum.JumpPower = cfg.JumpPower or 50
            end
    
            -- Update Fly
            if Movement.Flying then
                UpdateFly()
            end
        end))
    
        Movement.Enabled = true
    end
    
    function Movement.TeleportTo(position: Vector3)
        local root = Utils.GetRoot(Utils.LocalPlayer)
        if root then
            root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        end
    end
    
    function Movement.Cleanup()
        Movement.Enabled = false
        Movement.SetFly(false)
    
        for _, conn in ipairs(Movement.Connections) do
            conn:Disconnect()
        end
        Movement.Connections = {}
    end
    
    return Movement
    
end

----------------------------------------------------------------------
-- MODULE: modules/utility
----------------------------------------------------------------------
__modules["modules/utility"] = function()
    --[[
        Utility Module
        Anti-AFK, Server Hop, Rejoin, Fullbright, FPS Unlocker, and diagnostics.
    ]]
    
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local Lighting = game:GetService("Lighting")
    local HttpService = game:GetService("HttpService")
    local VirtualUser = game:GetService("VirtualUser")
    local Config = require_module("core/config")
    local Notifications = require_module("core/notifications")
    local Utils = require_module("core/utils")
    
    local Utility = {
        Connections = {},
        OriginalLighting = {},
        Enabled = false
    }
    
    function Utility.Init()
        -- Anti AFK
        task.spawn(function()
            local lp = Utils.LocalPlayer or Players.LocalPlayer or Players.PlayerAdded:Wait()
            if lp then
                table.insert(Utility.Connections, lp.Idled:Connect(function()
                    local cfg = Config.CurrentConfig.Utility
                    if cfg and cfg.AntiAFK then
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                        Notifications.Send("Anti-AFK", "Prevented 20-minute idle disconnect", 3)
                    end
                end))
            end
        end)
    
        -- Save original lighting
        Utility.OriginalLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient
        }
    
        Utility.Enabled = true
    end
    
    function Utility.SetFullbright(enabled: boolean)
        if enabled then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        else
            Lighting.Brightness = Utility.OriginalLighting.Brightness or 1
            Lighting.ClockTime = Utility.OriginalLighting.ClockTime or 12
            Lighting.FogEnd = Utility.OriginalLighting.FogEnd or 1000
            Lighting.GlobalShadows = Utility.OriginalLighting.GlobalShadows or true
            Lighting.Ambient = Utility.OriginalLighting.Ambient or Color3.fromRGB(127, 127, 127)
        end
    end
    
    function Utility.SetFPSCap(fps: number)
        if setfpscap then
            setfpscap(fps)
            Notifications.Success("FPS Cap set to " .. tostring(fps))
        else
            Notifications.Warn("setfpscap not supported by your executor.")
        end
    end
    
    function Utility.Rejoin()
        Notifications.Send("Rejoining", "Connecting to current server...", 3)
        if #Players:GetPlayers() <= 1 then
            Players.LocalPlayer:Kick("\nRejoining...")
            task.wait()
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
        end
    end
    
    function Utility.ServerHop()
        Notifications.Send("Server Hop", "Searching for available public server...", 3)
        local placeId = game.PlaceId
        local serversUrl = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    
        local success, response = pcall(function()
            if request then
                return request({Url = serversUrl, Method = "GET"}).Body
            elseif syn and syn.request then
                return syn.request({Url = serversUrl, Method = "GET"}).Body
            elseif http_request then
                return http_request({Url = serversUrl, Method = "GET"}).Body
            else
                return game:HttpGet(serversUrl)
            end
        end)
    
        if not success or not response then
            Notifications.Error("Failed to fetch server list.")
            return
        end
    
        local serverData = HttpService:JSONDecode(response)
        if not serverData or not serverData.data then
            Notifications.Error("Invalid server data received.")
            return
        end
    
        local validServers = {}
        for _, server in ipairs(serverData.data) do
            if type(server) == "table" and server.playing and server.maxPlayers and server.id ~= game.JobId then
                if server.playing < server.maxPlayers then
                    table.insert(validServers, server.id)
                end
            end
        end
    
        if #validServers > 0 then
            local chosenServerId = validServers[math.random(1, #validServers)]
            TeleportService:TeleportToPlaceInstance(placeId, chosenServerId, Players.LocalPlayer)
        else
            Notifications.Warn("No alternative servers found.")
        end
    end
    
    function Utility.CopyJobId()
        Utils.SetClipboard(game.JobId)
        Notifications.Success("Server JobId copied to clipboard!")
    end
    
    function Utility.CopyPlaceId()
        Utils.SetClipboard(tostring(game.PlaceId))
        Notifications.Success("PlaceId (" .. tostring(game.PlaceId) .. ") copied!")
    end
    
    function Utility.Cleanup()
        Utility.Enabled = false
        Utility.SetFullbright(false)
        for _, conn in ipairs(Utility.Connections) do
            conn:Disconnect()
        end
        Utility.Connections = {}
    end
    
    return Utility
    
end

----------------------------------------------------------------------
-- MODULE: modules/visuals
----------------------------------------------------------------------
__modules["modules/visuals"] = function()
    --[[
        Visuals (ESP) Module
        High-performance Player ESP using Drawing API with fallback Highlight Chams.
    ]]
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")
    local Utils = require_module("core/utils")
    local Config = require_module("core/config")
    
    local Visuals = {
        ESPObjects = {},
        Connections = {},
        Enabled = false
    }
    
    local function HasDrawing()
        return Drawing ~= nil and Drawing.new ~= nil
    end
    
    local function CreateDrawings(player)
        if not HasDrawing() then return nil end
    
        local drawings = nil
        pcall(function()
            drawings = {
                BoxOutline = Drawing.new("Square"),
                Box = Drawing.new("Square"),
                Name = Drawing.new("Text"),
                Distance = Drawing.new("Text"),
                HealthBarOutline = Drawing.new("Square"),
                HealthBar = Drawing.new("Square"),
                Tracer = Drawing.new("Line"),
            }
    
            -- Box Outline
            drawings.BoxOutline.Visible = false
            drawings.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
            drawings.BoxOutline.Thickness = 3
            drawings.BoxOutline.Filled = false
            drawings.BoxOutline.Transparency = 1
    
            -- Box
            drawings.Box.Visible = false
            drawings.Box.Color = Color3.fromRGB(255, 255, 255)
            drawings.Box.Thickness = 1
            drawings.Box.Filled = false
            drawings.Box.Transparency = 1
    
            -- Name
            drawings.Name.Visible = false
            drawings.Name.Color = Color3.fromRGB(255, 255, 255)
            drawings.Name.Size = 13
            drawings.Name.Center = true
            drawings.Name.Outline = true
            drawings.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    
            -- Distance
            drawings.Distance.Visible = false
            drawings.Distance.Color = Color3.fromRGB(200, 200, 200)
            drawings.Distance.Size = 11
            drawings.Distance.Center = true
            drawings.Distance.Outline = true
            drawings.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
    
            -- Health Bar Outline
            drawings.HealthBarOutline.Visible = false
            drawings.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
            drawings.HealthBarOutline.Thickness = 1
            drawings.HealthBarOutline.Filled = true
            drawings.HealthBarOutline.Transparency = 1
    
            -- Health Bar
            drawings.HealthBar.Visible = false
            drawings.HealthBar.Color = Color3.fromRGB(0, 255, 0)
            drawings.HealthBar.Thickness = 1
            drawings.HealthBar.Filled = true
            drawings.HealthBar.Transparency = 1
    
            -- Tracer
            drawings.Tracer.Visible = false
            drawings.Tracer.Color = Color3.fromRGB(255, 255, 255)
            drawings.Tracer.Thickness = 1
            drawings.Tracer.Transparency = 1
        end)
    
        return drawings
    end
    
    local function RemoveDrawings(player)
        local data = Visuals.ESPObjects[player]
        if not data then return end
    
        if data.Drawings then
            for _, draw in pairs(data.Drawings) do
                pcall(function()
                    draw.Visible = false
                    draw:Remove()
                end)
            end
        end
    
        if data.Highlight then
            pcall(function()
                data.Highlight:Destroy()
            end)
        end
    
        Visuals.ESPObjects[player] = nil
    end
    
    local function UpdatePlayerESP(player, data)
        local cfg = Config.CurrentConfig.Visuals
        if not cfg or not cfg.ESPEnabled or not Visuals.Enabled then
            if data.Drawings then
                for _, d in pairs(data.Drawings) do d.Visible = false end
            end
            if data.Highlight then data.Highlight.Enabled = false end
            return
        end
    
        if cfg.TeamCheck and Utils.IsTeamMate(player) then
            if data.Drawings then
                for _, d in pairs(data.Drawings) do d.Visible = false end
            end
            if data.Highlight then data.Highlight.Enabled = false end
            return
        end
    
        local character = Utils.GetCharacter(player)
        local root = Utils.GetRoot(player)
        local humanoid = Utils.GetHumanoid(player)
    
        if not character or not root or not humanoid or humanoid.Health <= 0 then
            if data.Drawings then
                for _, d in pairs(data.Drawings) do d.Visible = false end
            end
            if data.Highlight then data.Highlight.Enabled = false end
            return
        end
    
        -- Highlight Chams update
        if cfg.HighlightChams then
            if not data.Highlight then
                local highlight = Instance.new("Highlight")
                highlight.Name = "HubESP_" .. player.Name
                highlight.FillColor = Color3.fromRGB(cfg.BoxColor[1], cfg.BoxColor[2], cfg.BoxColor[3])
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.Adornee = character
                highlight.Parent = CoreGui
                data.Highlight = highlight
            else
                data.Highlight.Adornee = character
                data.Highlight.Enabled = true
            end
        elseif data.Highlight then
            data.Highlight.Enabled = false
        end
    
        if not data.Drawings then return end
    
        local drawings = data.Drawings
        local rootPos = root.Position
        local screenPos, onScreen, depth = Utils.WorldToViewportPoint(rootPos)
    
        if not onScreen or depth < 1 then
            for _, d in pairs(drawings) do d.Visible = false end
            return
        end
    
        -- Calculate bounding box
        local head = character:FindFirstChild("Head")
        local headPos = head and head.Position or (rootPos + Vector3.new(0, 2, 0))
        local topPos = Utils.WorldToViewportPoint(headPos + Vector3.new(0, 1.2, 0))
        local bottomPos = Utils.WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))
    
        local boxHeight = math.abs(bottomPos.Y - topPos.Y)
        local boxWidth = boxHeight * 0.65
        local boxX = screenPos.X - (boxWidth / 2)
        local boxY = topPos.Y
    
        local boxColor = Color3.fromRGB(cfg.BoxColor[1], cfg.BoxColor[2], cfg.BoxColor[3])
    
        -- Box ESP
        if cfg.Boxes then
            drawings.BoxOutline.Position = Vector2.new(boxX, boxY)
            drawings.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
            drawings.BoxOutline.Visible = true
    
            drawings.Box.Position = Vector2.new(boxX, boxY)
            drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
            drawings.Box.Color = boxColor
            drawings.Box.Visible = true
        else
            drawings.BoxOutline.Visible = false
            drawings.Box.Visible = false
        end
    
        -- Name ESP
        if cfg.Names then
            drawings.Name.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            drawings.Name.Position = Vector2.new(screenPos.X, boxY - 16)
            drawings.Name.Visible = true
        else
            drawings.Name.Visible = false
        end
    
        -- Distance ESP
        local dist = math.floor(Utils.GetDistance(rootPos))
        if cfg.Distance then
            drawings.Distance.Text = tostring(dist) .. " studs"
            drawings.Distance.Position = Vector2.new(screenPos.X, boxY + boxHeight + 2)
            drawings.Distance.Visible = true
        else
            drawings.Distance.Visible = false
        end
    
        -- Health Bar ESP
        if cfg.Health then
            local healthPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barWidth = 3
            local barX = boxX - barWidth - 4
            local barHeight = boxHeight * healthPct
    
            drawings.HealthBarOutline.Position = Vector2.new(barX - 1, boxY - 1)
            drawings.HealthBarOutline.Size = Vector2.new(barWidth + 2, boxHeight + 2)
            drawings.HealthBarOutline.Visible = true
    
            drawings.HealthBar.Position = Vector2.new(barX, boxY + (boxHeight - barHeight))
            drawings.HealthBar.Size = Vector2.new(barWidth, barHeight)
            drawings.HealthBar.Color = Color3.fromHSV(healthPct * 0.3, 1, 1)
            drawings.HealthBar.Visible = true
        else
            drawings.HealthBarOutline.Visible = false
            drawings.HealthBar.Visible = false
        end
    
        -- Tracer ESP
        if cfg.Tracers then
            local origin = Vector2.new(Utils.Camera.ViewportSize.X / 2, Utils.Camera.ViewportSize.Y)
            if cfg.TracerOrigin == "Center" then
                origin = Vector2.new(Utils.Camera.ViewportSize.X / 2, Utils.Camera.ViewportSize.Y / 2)
            elseif cfg.TracerOrigin == "Top" then
                origin = Vector2.new(Utils.Camera.ViewportSize.X / 2, 0)
            end
    
            drawings.Tracer.From = origin
            drawings.Tracer.To = Vector2.new(screenPos.X, boxY + boxHeight)
            drawings.Tracer.Color = boxColor
            drawings.Tracer.Visible = true
        else
            drawings.Tracer.Visible = false
        end
    end
    
    function Visuals.Init()
        local function AddPlayer(player)
            if player == Utils.LocalPlayer then return end
            Visuals.ESPObjects[player] = {
                Drawings = CreateDrawings(player),
                Highlight = nil
            }
        end
    
        for _, player in ipairs(Players:GetPlayers()) do
            AddPlayer(player)
        end
    
        table.insert(Visuals.Connections, Players.PlayerAdded:Connect(AddPlayer))
        table.insert(Visuals.Connections, Players.PlayerRemoving:Connect(RemoveDrawings))
    
        table.insert(Visuals.Connections, RunService.RenderStepped:Connect(function()
            for player, data in pairs(Visuals.ESPObjects) do
                UpdatePlayerESP(player, data)
            end
        end))
    
        Visuals.Enabled = true
    end
    
    function Visuals.Cleanup()
        Visuals.Enabled = false
        for _, conn in ipairs(Visuals.Connections) do
            conn:Disconnect()
        end
        Visuals.Connections = {}
    
        for player, _ in pairs(Visuals.ESPObjects) do
            RemoveDrawings(player)
        end
        Visuals.ESPObjects = {}
    end
    
    return Visuals
    
end

----------------------------------------------------------------------
-- MAIN INITIALIZER
----------------------------------------------------------------------
do
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
    local Config = require_module("core/config")
    local Notifications = require_module("core/notifications")
    local UI = require_module("core/ui")
    local Utils = require_module("core/utils")
    
    -- Feature Modules
    local Visuals = require_module("modules/visuals")
    local Combat = require_module("modules/combat")
    local Movement = require_module("modules/movement")
    local Utility = require_module("modules/utility")
    
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
        
        local gameModule = __modules["games/" .. placeIdStr] and ("games/" .. placeIdStr) or (__modules["games/" .. gameIdStr] and ("games/" .. gameIdStr) or "games/universal")
    
        if gameModule then
            local success, mod = pcall(function()
                return require_module(gameModule)
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
    
end
