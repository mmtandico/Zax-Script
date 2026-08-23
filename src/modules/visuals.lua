--[[
    Visuals (ESP) Module
    High-performance Player ESP using Drawing API with fallback Highlight Chams.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Utils = require(script.Parent.Parent.core.utils)
local Config = require(script.Parent.Parent.core.config)

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

    local drawings = {
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
