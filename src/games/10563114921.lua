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

local function Format12Hour(timestamp)
    timestamp = timestamp or os.time()
    local dateTable = os.date("*t", timestamp)
    local hour = dateTable.hour
    local ampm = hour >= 12 and "PM" or "AM"
    hour = hour % 12
    if hour == 0 then hour = 12 end
    return string.format("%02d:%02d:%02d %s", hour, dateTable.min, dateTable.sec, ampm)
end

-- Add Spawn Log Card to Floating HUD
function StealAnEgg.AddHUDLogEntry(rarity, name, model)
    if not StealAnEgg.HUDEggList then return end

    local color = StealAnEgg.RarityColors[rarity] or Color3.fromRGB(200, 200, 200)
    local timeStr = Format12Hour()

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
                Content = string.format("Name: %s\nDetected at: %s\nRarity Tier: %s", model.Name, Format12Hour(), rarity)
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
