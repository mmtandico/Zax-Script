--[[
    Quantum Script Hub - Bundled Standalone Distribution
    Generated: 2026-08-23T10:58:15.010Z
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
        Sends notifications via Roblox CoreGui StarterGui or executor notification libraries.
    ]]
    
    local StarterGui = game:GetService("StarterGui")
    
    local Notifications = {}
    
    function Notifications.Send(title: string, text: string, duration: number?, icon: string?)
        title = title or "Script Hub"
        text = text or ""
        duration = duration or 5
    
        -- Try UI Library notification if registered in environment
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
        Quantum Hub - Built-in Modern UI Library
        Fully self-contained, executor-compatible (Solara, Wave, Celery, Synapse Z, Delta)
        Supports: Draggable Window, Floating Toggle Button, Tabs, Toggles, Sliders, Dropdowns, Inputs, Buttons, Colorpickers, Keybinds.
    ]]
    
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    
    local Utils = require_module("utils")
    local Config = require_module("config")
    local Notifications = require_module("notifications")
    
    local UI = {
        ScreenGui = nil,
        MainFrame = nil,
        FloatingToggle = nil,
        TabButtonsContainer = nil,
        TabPagesContainer = nil,
        Tabs = {},
        CurrentTab = nil,
        IsVisible = true
    }
    
    -- Safe Parent Resolver for Executor Compatibility
    local function GetGuiParent()
        if gethui then
            local success, hui = pcall(gethui)
            if success and hui then return hui end
        end
    
        local canUseCoreGui = false
        pcall(function()
            local test = Instance.new("Folder")
            test.Parent = CoreGui
            test:Destroy()
            canUseCoreGui = true
        end)
    
        if canUseCoreGui then
            return CoreGui
        end
    
        local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
        return lp:WaitForChild("PlayerGui", 10) or CoreGui
    end
    
    -- Make GUI Object Draggable
    local function MakeDraggable(guiObject, dragHandle)
        dragHandle = dragHandle or guiObject
        local dragging = false
        local dragInput, dragStart, startPos
    
        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = guiObject.Position
    
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
    
        dragHandle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
    
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                guiObject.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end
    
    function UI.Init(hubTitle, hubSubtitle)
        hubTitle = hubTitle or "Quantum Hub"
        hubSubtitle = hubSubtitle or ("v1.0.0 | " .. Utils.GetExecutor())
    
        local parent = GetGuiParent()
        
        -- Cleanup any existing instance
        local existing = parent:FindFirstChild("QuantumHubGui")
        if existing then existing:Destroy() end
    
        -- Create ScreenGui
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "QuantumHubGui"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 999999
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Enabled = true
    
        if syn and syn.protect_gui then
            pcall(function() syn.protect_gui(screenGui) end)
        end
    
        screenGui.Parent = parent
        UI.ScreenGui = screenGui
    
        -- Main Container Frame
        local main = Instance.new("Frame")
        main.Name = "MainFrame"
        main.Size = UDim2.new(0, 600, 0, 420)
        main.Position = UDim2.new(0.5, -300, 0.5, -210)
        main.BackgroundColor3 = Color3.fromRGB(20, 21, 27)
        main.BorderSizePixel = 0
        main.ClipsDescendants = true
        main.Visible = true
        main.Parent = screenGui
        UI.MainFrame = main
    
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 8)
        mainCorner.Parent = main
    
        local mainStroke = Instance.new("UIStroke")
        mainStroke.Color = Color3.fromRGB(0, 180, 255)
        mainStroke.Thickness = 1
        mainStroke.Transparency = 0.4
        mainStroke.Parent = main
    
        -- Topbar
        local topbar = Instance.new("Frame")
        topbar.Name = "Topbar"
        topbar.Size = UDim2.new(1, 0, 0, 42)
        topbar.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
        topbar.BorderSizePixel = 0
        topbar.Parent = main
        MakeDraggable(main, topbar)
    
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(0, 190, 1, 0)
        titleLabel.Position = UDim2.new(0, 14, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = "⚡ " .. hubTitle
        titleLabel.TextColor3 = Color3.fromRGB(0, 210, 255)
        titleLabel.TextSize = 15
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = topbar
    
        local subtitleLabel = Instance.new("TextLabel")
        subtitleLabel.Name = "Subtitle"
        subtitleLabel.Size = UDim2.new(0, 200, 1, 0)
        subtitleLabel.Position = UDim2.new(0, 180, 0, 0)
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Font = Enum.Font.Gotham
        subtitleLabel.Text = hubSubtitle
        subtitleLabel.TextColor3 = Color3.fromRGB(140, 145, 160)
        subtitleLabel.TextSize = 11
        subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        subtitleLabel.Parent = topbar
    
        -- Minimize Button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseBtn"
        closeBtn.Size = UDim2.new(0, 28, 0, 28)
        closeBtn.Position = UDim2.new(1, -34, 0, 7)
        closeBtn.BackgroundColor3 = Color3.fromRGB(38, 41, 52)
        closeBtn.Text = "—"
        closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 14
        closeBtn.Parent = topbar
    
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 5)
        closeCorner.Parent = closeBtn
    
        closeBtn.MouseButton1Click:Connect(function()
            UI.Toggle()
        end)
    
        -- Floating Open/Close Toggle Button (always visible on screen)
        local floatToggle = Instance.new("TextButton")
        floatToggle.Name = "FloatingToggle"
        floatToggle.Size = UDim2.new(0, 120, 0, 32)
        floatToggle.Position = UDim2.new(0, 20, 0, 20)
        floatToggle.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
        floatToggle.Font = Enum.Font.GothamBold
        floatToggle.Text = "⚡ Quantum Hub"
        floatToggle.TextColor3 = Color3.fromRGB(0, 210, 255)
        floatToggle.TextSize = 12
        floatToggle.Parent = screenGui
        MakeDraggable(floatToggle, floatToggle)
        UI.FloatingToggle = floatToggle
    
        local ftCorner = Instance.new("UICorner")
        ftCorner.CornerRadius = UDim.new(0, 6)
        ftCorner.Parent = floatToggle
    
        local ftStroke = Instance.new("UIStroke")
        ftStroke.Color = Color3.fromRGB(0, 180, 255)
        ftStroke.Thickness = 1
        ftStroke.Parent = floatToggle
    
        floatToggle.MouseButton1Click:Connect(function()
            UI.Toggle()
        end)
    
        -- Sidebar for Tabs
        local sidebar = Instance.new("ScrollingFrame")
        sidebar.Name = "Sidebar"
        sidebar.Size = UDim2.new(0, 140, 1, -42)
        sidebar.Position = UDim2.new(0, 0, 0, 42)
        sidebar.BackgroundColor3 = Color3.fromRGB(23, 24, 31)
        sidebar.BorderSizePixel = 0
        sidebar.ScrollBarThickness = 2
        sidebar.ScrollBarImageColor3 = Color3.fromRGB(60, 65, 80)
        sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
        sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sidebar.Parent = main
        UI.TabButtonsContainer = sidebar
    
        local sidebarLayout = Instance.new("UIListLayout")
        sidebarLayout.Padding = UDim.new(0, 4)
        sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
        sidebarLayout.Parent = sidebar
    
        local sidebarPadding = Instance.new("UIPadding")
        sidebarPadding.PaddingTop = UDim.new(0, 8)
        sidebarPadding.PaddingBottom = UDim.new(0, 8)
        sidebarPadding.PaddingLeft = UDim.new(0, 6)
        sidebarPadding.PaddingRight = UDim.new(0, 6)
        sidebarPadding.Parent = sidebar
    
        -- Pages Container
        local pages = Instance.new("Frame")
        pages.Name = "Pages"
        pages.Size = UDim2.new(1, -140, 1, -42)
        pages.Position = UDim2.new(0, 140, 0, 42)
        pages.BackgroundTransparency = 1
        pages.Parent = main
        UI.TabPagesContainer = pages
    
        -- Notification helper
        getgenv().HubNotify = function(options)
            Notifications.Send(options.Title or "Hub", options.Content or "", options.Duration or 4)
        end
    
        -- Keybind to Toggle GUI (RightControl)
        UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == Enum.KeyCode.RightControl then
                UI.Toggle()
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
        UI.SelectTab(UI.Tabs.Home)
    
        print("[Quantum Hub] UI initialized successfully!")
        return UI
    end
    
    function UI.Toggle()
        UI.IsVisible = not UI.IsVisible
        UI.MainFrame.Visible = UI.IsVisible
    end
    
    function UI.SelectTab(tabObj)
        if not tabObj then return end
        UI.CurrentTab = tabObj
    
        for _, otherTab in pairs(UI.Tabs) do
            if otherTab and otherTab.Page and otherTab.Button then
                otherTab.Page.Visible = (otherTab == tabObj)
                if otherTab == tabObj then
                    otherTab.Button.BackgroundColor3 = Color3.fromRGB(0, 160, 240)
                    otherTab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    otherTab.Button.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
                    otherTab.Button.TextColor3 = Color3.fromRGB(160, 165, 180)
                end
            end
        end
    end
    
    function UI.CreateTab(name)
        local tab = { Name = name }
    
        -- Tab Button
        local btn = Instance.new("TextButton")
        btn.Name = "Tab_" .. name
        btn.Size = UDim2.new(1, -4, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
        btn.Font = Enum.Font.GothamSemibold
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(160, 165, 180)
        btn.TextSize = 12
        btn.Parent = UI.TabButtonsContainer
    
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
    
        btn.MouseButton1Click:Connect(function()
            UI.SelectTab(tab)
        end)
        tab.Button = btn
    
        -- Tab Page
        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. name
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = Color3.fromRGB(50, 55, 70)
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = UI.TabPagesContainer
        tab.Page = page
    
        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 6)
        pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page
    
        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingTop = UDim.new(0, 10)
        pagePadding.PaddingBottom = UDim.new(0, 10)
        pagePadding.PaddingLeft = UDim.new(0, 10)
        pagePadding.PaddingRight = UDim.new(0, 10)
        pagePadding.Parent = page
    
        -- Tab Components
        function tab:AddParagraph(options)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -4, 0, 52)
            frame.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
            frame.Parent = page
    
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame
    
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -16, 0, 18)
            title.Position = UDim2.new(0, 8, 0, 5)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamBold
            title.Text = options.Title or ""
            title.TextColor3 = Color3.fromRGB(0, 200, 255)
            title.TextSize = 12
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = frame
    
            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, -16, 0, 24)
            desc.Position = UDim2.new(0, 8, 0, 24)
            desc.BackgroundTransparency = 1
            desc.Font = Enum.Font.Gotham
            desc.Text = options.Content or options.Description or ""
            desc.TextColor3 = Color3.fromRGB(180, 185, 200)
            desc.TextSize = 11
            desc.TextWrapped = true
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Parent = frame
            return frame
        end
    
        function tab:AddToggle(id, options)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -4, 0, 36)
            frame.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
            frame.Parent = page
    
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame
    
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -55, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamSemibold
            label.Text = options.Title or id
            label.TextColor3 = Color3.fromRGB(220, 225, 235)
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
    
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0, 38, 0, 20)
            toggleBtn.Position = UDim2.new(1, -46, 0.5, -10)
            toggleBtn.BackgroundColor3 = options.Default and Color3.fromRGB(0, 190, 255) or Color3.fromRGB(45, 48, 60)
            toggleBtn.Text = options.Default and "ON" or "OFF"
            toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggleBtn.Font = Enum.Font.GothamBold
            toggleBtn.TextSize = 9
            toggleBtn.Parent = frame
    
            local tbCorner = Instance.new("UICorner")
            tbCorner.CornerRadius = UDim.new(0, 10)
            tbCorner.Parent = toggleBtn
    
            local isToggled = options.Default or false
            toggleBtn.MouseButton1Click:Connect(function()
                isToggled = not isToggled
                toggleBtn.BackgroundColor3 = isToggled and Color3.fromRGB(0, 190, 255) or Color3.fromRGB(45, 48, 60)
                toggleBtn.Text = isToggled and "ON" or "OFF"
                if options.Callback then
                    options.Callback(isToggled)
                end
            end)
    
            return frame
        end
    
        function tab:AddButton(options)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -4, 0, 34)
            btn.BackgroundColor3 = Color3.fromRGB(32, 35, 46)
            btn.Font = Enum.Font.GothamSemibold
            btn.Text = options.Title or "Button"
            btn.TextColor3 = Color3.fromRGB(220, 230, 250)
            btn.TextSize = 12
            btn.Parent = page
    
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = btn
    
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(50, 55, 75)
            stroke.Thickness = 1
            stroke.Parent = btn
    
            btn.MouseButton1Click:Connect(function()
                if options.Callback then
                    options.Callback()
                end
            end)
    
            return btn
        end
    
        function tab:AddSlider(id, options)
            local minVal = options.Min or 0
            local maxVal = options.Max or 100
            local currentVal = options.Default or minVal
    
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -4, 0, 48)
            frame.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
            frame.Parent = page
    
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame
    
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 0, 20)
            label.Position = UDim2.new(0, 10, 0, 4)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamSemibold
            label.Text = options.Title or id
            label.TextColor3 = Color3.fromRGB(220, 225, 235)
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
    
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0, 45, 0, 20)
            valueLabel.Position = UDim2.new(1, -55, 0, 4)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.Text = tostring(currentVal)
            valueLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
            valueLabel.TextSize = 12
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = frame
    
            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -20, 0, 6)
            barBg.Position = UDim2.new(0, 10, 0, 30)
            barBg.BackgroundColor3 = Color3.fromRGB(40, 43, 56)
            barBg.Parent = frame
    
            local barCorner = Instance.new("UICorner")
            barCorner.CornerRadius = UDim.new(0, 3)
            barCorner.Parent = barBg
    
            local fill = Instance.new("Frame")
            local initialScale = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
            fill.Size = UDim2.new(initialScale, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(0, 190, 255)
            fill.BorderSizePixel = 0
            fill.Parent = barBg
    
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 3)
            fillCorner.Parent = fill
    
            local dragging = false
            local function UpdateFromInput(input)
                local pos = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                local newVal = math.floor(minVal + (maxVal - minVal) * pos)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                valueLabel.Text = tostring(newVal)
                if options.Callback then
                    options.Callback(newVal)
                end
            end
    
            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateFromInput(input)
                end
            end)
    
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
    
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateFromInput(input)
                end
            end)
    
            return frame
        end
    
        function tab:AddDropdown(id, options)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -4, 0, 36)
            frame.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
            frame.Parent = page
    
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame
    
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 130, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamSemibold
            label.Text = options.Title or id
            label.TextColor3 = Color3.fromRGB(220, 225, 235)
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
    
            local cycleBtn = Instance.new("TextButton")
            cycleBtn.Size = UDim2.new(1, -150, 0, 24)
            cycleBtn.Position = UDim2.new(0, 140, 0.5, -12)
            cycleBtn.BackgroundColor3 = Color3.fromRGB(38, 42, 54)
            cycleBtn.Font = Enum.Font.Gotham
            cycleBtn.Text = tostring(options.Default or options.Values[1])
            cycleBtn.TextColor3 = Color3.fromRGB(0, 210, 255)
            cycleBtn.TextSize = 11
            cycleBtn.Parent = frame
    
            local dCorner = Instance.new("UICorner")
            dCorner.CornerRadius = UDim.new(0, 5)
            dCorner.Parent = cycleBtn
    
            local currentIdx = 1
            for i, v in ipairs(options.Values) do
                if v == options.Default then currentIdx = i break end
            end
    
            cycleBtn.MouseButton1Click:Connect(function()
                currentIdx = (currentIdx % #options.Values) + 1
                local selected = options.Values[currentIdx]
                cycleBtn.Text = tostring(selected)
                if options.Callback then
                    options.Callback(selected)
                end
            end)
    
            return frame
        end
    
        function tab:AddInput(id, options)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -4, 0, 36)
            frame.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
            frame.Parent = page
    
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame
    
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 120, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamSemibold
            label.Text = options.Title or id
            label.TextColor3 = Color3.fromRGB(220, 225, 235)
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
    
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -140, 0, 24)
            box.Position = UDim2.new(0, 130, 0.5, -12)
            box.BackgroundColor3 = Color3.fromRGB(38, 42, 54)
            box.Font = Enum.Font.Gotham
            box.Text = options.Default or ""
            box.TextColor3 = Color3.fromRGB(255, 255, 255)
            box.PlaceholderText = "Enter text..."
            box.TextSize = 11
            box.Parent = frame
    
            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 5)
            bCorner.Parent = box
    
            box.FocusLost:Connect(function()
                if options.Callback then
                    options.Callback(box.Text)
                end
            end)
    
            return frame
        end
    
        function tab:AddColorpicker(id, options)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -4, 0, 36)
            frame.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
            frame.Parent = page
    
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame
    
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -55, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamSemibold
            label.Text = options.Title or id
            label.TextColor3 = Color3.fromRGB(220, 225, 235)
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
    
            local colorBtn = Instance.new("TextButton")
            colorBtn.Size = UDim2.new(0, 30, 0, 20)
            colorBtn.Position = UDim2.new(1, -40, 0.5, -10)
            colorBtn.BackgroundColor3 = options.Default or Color3.fromRGB(255, 60, 60)
            colorBtn.Text = ""
            colorBtn.Parent = frame
    
            local cbCorner = Instance.new("UICorner")
            cbCorner.CornerRadius = UDim.new(0, 5)
            cbCorner.Parent = colorBtn
    
            local colors = {
                Color3.fromRGB(255, 60, 60),
                Color3.fromRGB(60, 255, 60),
                Color3.fromRGB(60, 120, 255),
                Color3.fromRGB(255, 255, 60),
                Color3.fromRGB(255, 60, 255),
                Color3.fromRGB(0, 255, 255),
                Color3.fromRGB(255, 255, 255),
            }
            local colIdx = 1
    
            colorBtn.MouseButton1Click:Connect(function()
                colIdx = (colIdx % #colors) + 1
                local chosen = colors[colIdx]
                colorBtn.BackgroundColor3 = chosen
                if options.Callback then
                    options.Callback(chosen)
                end
            end)
    
            return frame
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
            Title = "Quantum Script Hub",
            Description = "Place ID: " .. tostring(game.PlaceId) .. " | " .. Utils.GetExecutor() .. "\nClick [⚡ Quantum Hub] button or press [Right-Ctrl] to hide."
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
        Roblox Script Hub - Main Entry Point
        Initializes core services, modules, game router, and user interface.
    ]]
    
    -- Cleanup previous execution instance if exists
    if getgenv and getgenv().QuantumHubCleanup then
        pcall(getgenv().QuantumHubCleanup)
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
        local gameModuleNameKey = "games/" .. gameModuleName
        local gameModule = __modules[gameModuleNameKey] and gameModuleNameKey or "games/universal"
    
        if gameModule then
            local success, mod = pcall(function()
                return require_module(gameModule)
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
    
end
