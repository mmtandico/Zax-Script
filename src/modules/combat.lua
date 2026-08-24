--[[
    Combat Module
    Universal Aimbot, FOV Circle Drawing, Smooth Aim, and Hitbox Expander.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Utils = require(script.Parent.Parent.core.utils)
local Config = require(script.Parent.Parent.core.config)

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
        -- Update Target HUD
        Combat.UpdateTargetHUD()
    end))

    Combat.CreateTargetHUD()
    Combat.Enabled = true
end

-- Target HUD Manager
Combat.TargetHUD = {
    ScreenGui = nil,
    OuterBox = nil,
    DisplayNameLabel = nil,
    EquippedItemLabel = nil,
    HealthBar = nil,
    HealthNumberLabel = nil,
    AvatarImage = nil,
    Enabled = false,
    MaxDistance = 15,
    BackgroundTransparency = 0.3,
    DefaultHealthColor = Color3.fromRGB(128, 0, 128)
}

-- Export global configuration table as reference snippet requested
getgenv().targethud = {
    enabled = false,
    maxDistance = 15,
    defaultHealthColor = Color3.fromRGB(128, 0, 128),
    backgroundTransparency = 0.3
}

function Combat.CreateTargetHUD()
    if Combat.TargetHUD.ScreenGui then
        pcall(function() Combat.TargetHUD.ScreenGui:Destroy() end)
    end

    local LocalPlayer = Players.LocalPlayer
    local CoreGui = game:GetService("CoreGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Zxscript_TargetHUD"
    screenGui.ResetOnSpawn = false
    
    local parent = pcall(function() return CoreGui end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    screenGui.Parent = parent
    Combat.TargetHUD.ScreenGui = screenGui

    local outerBox = Instance.new("Frame")
    outerBox.Size = UDim2.new(0, 220, 0, 125)
    outerBox.Position = UDim2.new(0.5, -110, 0.8, -140)
    outerBox.BackgroundColor3 = Color3.fromRGB(22, 22, 31)
    outerBox.BackgroundTransparency = getgenv().targethud.backgroundTransparency or Combat.TargetHUD.BackgroundTransparency
    outerBox.BorderColor3 = Color3.fromRGB(80, 80, 80)
    outerBox.BorderSizePixel = 1
    outerBox.Parent = screenGui
    outerBox.Visible = false
    Combat.TargetHUD.OuterBox = outerBox

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 20)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    header.BorderSizePixel = 0
    header.Parent = outerBox

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.Position = UDim2.new(0, 5, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎯 TARGET HUD"
    titleText.TextColor3 = Color3.fromRGB(200, 200, 255)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 11
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = header

    local displayNameLabel = Instance.new("TextLabel")
    displayNameLabel.Size = UDim2.new(1, -55, 0, 20)
    displayNameLabel.Position = UDim2.new(0, 5, 0, 22)
    displayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    displayNameLabel.BackgroundTransparency = 1
    displayNameLabel.Font = Enum.Font.GothamBold
    displayNameLabel.TextSize = 13
    displayNameLabel.Text = ""
    displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    displayNameLabel.Parent = outerBox
    Combat.TargetHUD.DisplayNameLabel = displayNameLabel

    local equippedItemLabel = Instance.new("TextLabel")
    equippedItemLabel.Size = UDim2.new(1, -55, 0, 20)
    equippedItemLabel.Position = UDim2.new(0, 5, 0, 42)
    equippedItemLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    equippedItemLabel.BackgroundTransparency = 1
    equippedItemLabel.Font = Enum.Font.Gotham
    equippedItemLabel.TextSize = 12
    equippedItemLabel.Text = "Equipped: None"
    equippedItemLabel.TextXAlignment = Enum.TextXAlignment.Left
    equippedItemLabel.Parent = outerBox
    Combat.TargetHUD.EquippedItemLabel = equippedItemLabel

    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(0, 40, 0, 40)
    avatarImage.Position = UDim2.new(1, -45, 0, 22)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = ""
    avatarImage.Parent = outerBox
    Combat.TargetHUD.AvatarImage = avatarImage

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 6)
    avatarCorner.Parent = avatarImage

    local healthBarBackground = Instance.new("Frame")
    healthBarBackground.Size = UDim2.new(0.9, 0, 0, 14)
    healthBarBackground.Position = UDim2.new(0.05, 0, 0, 72)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderColor3 = Color3.fromRGB(80, 80, 80)
    healthBarBackground.BorderSizePixel = 1
    healthBarBackground.Parent = outerBox

    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(0.5, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = getgenv().targethud.defaultHealthColor or Combat.TargetHUD.DefaultHealthColor
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBackground
    Combat.TargetHUD.HealthBar = healthBar

    local healthNumberLabel = Instance.new("TextLabel")
    healthNumberLabel.Size = UDim2.new(1, 0, 1, 0)
    healthNumberLabel.Position = UDim2.new(0, 0, 0, 0)
    healthNumberLabel.BackgroundTransparency = 1
    healthNumberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthNumberLabel.Font = Enum.Font.GothamBold
    healthNumberLabel.TextSize = 11
    healthNumberLabel.Text = "100%"
    healthNumberLabel.TextXAlignment = Enum.TextXAlignment.Center
    healthNumberLabel.TextYAlignment = Enum.TextYAlignment.Center
    healthNumberLabel.Parent = healthBarBackground
    Combat.TargetHUD.HealthNumberLabel = healthNumberLabel
end

function Combat.UpdateTargetHUD()
    local isEnabled = getgenv().targethud.enabled or Combat.TargetHUD.Enabled
    if not isEnabled or not Combat.TargetHUD.OuterBox then
        if Combat.TargetHUD.OuterBox then Combat.TargetHUD.OuterBox.Visible = false end
        return
    end

    local LocalPlayer = Players.LocalPlayer
    local mouse = LocalPlayer:GetMouse()
    if not mouse then return end

    local targetPlayer = nil
    local targetCharacter = nil
    local targetHumanoid = nil
    local maxDist = getgenv().targethud.maxDistance or Combat.TargetHUD.MaxDistance

    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer and otherPlayer.Character and otherPlayer.Character:FindFirstChild("Head") then
            local head = otherPlayer.Character.Head
            local distance = (mouse.Hit.p - head.Position).Magnitude

            if distance < maxDist then
                targetPlayer = otherPlayer
                targetCharacter = otherPlayer.Character
                targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
                break
            end
        end
    end

    if targetPlayer and targetHumanoid and Combat.TargetHUD.OuterBox then
        Combat.TargetHUD.OuterBox.Visible = true
        Combat.TargetHUD.DisplayNameLabel.Text = string.format("%s (%s)", targetPlayer.DisplayName, targetPlayer.Name)

        local equippedTool = targetPlayer.Character:FindFirstChildOfClass("Tool")
        if equippedTool then
            Combat.TargetHUD.EquippedItemLabel.Text = "Equipped: " .. equippedTool.Name
        else
            Combat.TargetHUD.EquippedItemLabel.Text = "Equipped: None"
        end

        local healthPercentage = math.clamp(targetHumanoid.Health / math.max(targetHumanoid.MaxHealth, 1), 0, 1)
        Combat.TargetHUD.HealthBar.Size = UDim2.new(healthPercentage, 0, 1, 0)
        Combat.TargetHUD.HealthNumberLabel.Text = string.format("%d%%", math.floor(healthPercentage * 100))

        pcall(function()
            local content = Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
            Combat.TargetHUD.AvatarImage.Image = content
        end)
    else
        if Combat.TargetHUD.OuterBox then
            Combat.TargetHUD.OuterBox.Visible = false
        end
    end
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

    if Combat.TargetHUD.ScreenGui then
        pcall(function() Combat.TargetHUD.ScreenGui:Destroy() end)
        Combat.TargetHUD.ScreenGui = nil
    end

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
