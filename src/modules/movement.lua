--[[
    Movement Module
    Fly, Noclip, Speed/Jump modifications, Infinite Jump, and Teleportation.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Utils = require(script.Parent.Parent.core.utils)
local Config = require(script.Parent.Parent.core.config)

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
