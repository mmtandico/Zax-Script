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
        Combat.FOVCircle = Drawing.new("Circle")
        Combat.FOVCircle.Visible = false
        Combat.FOVCircle.Thickness = 1.5
        Combat.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
        Combat.FOVCircle.Filled = false
        Combat.FOVCircle.Transparency = 1
        Combat.FOVCircle.NumSides = 64
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
