--[[
    Quantum Hub - Built-in Modern UI Library
    Fully self-contained, executor-compatible (Solara, Wave, Celery, Synapse Z, Delta)
    Supports: Draggable Window, Floating Toggle Button, Tabs, Toggles, Sliders, Dropdowns, Inputs, Buttons, Colorpickers, Keybinds.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Utils = require(script.Parent.utils)
local Config = require(script.Parent.config)
local Notifications = require(script.Parent.notifications)

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
    local VisualsModule = require(script.Parent.Parent.modules.visuals)
    local CombatModule = require(script.Parent.Parent.modules.combat)
    local MovementModule = require(script.Parent.Parent.modules.movement)
    local UtilityModule = require(script.Parent.Parent.modules.utility)

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
