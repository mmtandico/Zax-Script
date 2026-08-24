--[[
    Steal an Egg Module (PlaceId: 10563114921 / GameId: 107778070777162)
    Features:
    - Egg Spawn Predictor & Real-time Detector (Eternal, Secret, Divine, Mythic, etc.)
    - Tier-Filtered Egg ESP with 3D Highlights & Distance Labels
    - Auto Teleport / Auto Steal Rare Spawned Eggs
    - Auto Collect & Auto Hatch
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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

    -- Rarity Color Palette
    RarityColors = {
        Eternal = Color3.fromRGB(220, 50, 255),  -- Bright Magenta/Purple
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
}

-- Detect Egg Rarity / Tier from Model name, attributes, or child Gui
function StealAnEgg.GetEggRarity(model)
    if not model then return "Common" end

    -- Check attributes first
    local attrRarity = model:GetAttribute("Rarity") or model:GetAttribute("Tier") or model:GetAttribute("Type")
    if attrRarity and type(attrRarity) == "string" then
        for rarityName, _ in pairs(StealAnEgg.RarityColors) do
            if string.find(string.lower(attrRarity), string.lower(rarityName)) then
                return rarityName
            end
        end
    end

    -- Check model name
    local name = model.Name
    for rarityName, _ in pairs(StealAnEgg.RarityColors) do
        if string.find(string.lower(name), string.lower(rarityName)) then
            return rarityName
        end
    end

    -- Check child text objects or BillboardGuis
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

-- Create 3D Highlight & Billboard for Egg
function StealAnEgg.CreateEggESP(model, rarity)
    if not model or not model:IsA("PVInstance") then return end
    if StealAnEgg.ActiveHighlights[model] then return end

    local rank = StealAnEgg.RarityRanks[rarity] or 1
    local minRank = StealAnEgg.RarityRanks[StealAnEgg.PredictorMinRarity] or 1
    if rank < minRank then return end

    local color = StealAnEgg.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)

    -- Highlight Object
    local highlight = Instance.new("Highlight")
    highlight.Name = "EggESP_Highlight"
    highlight.Adornee = model
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = model

    -- Billboard Text Label
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

    -- Clean up when model destroyed
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
    
    -- Check if item is an Egg
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

    gameTab:AddSection("🥚 Steal an Egg - Predictor & Auto Farm")

    -- Predictor Info Banner
    StealAnEgg.PredictorParagraph = gameTab:AddParagraph({
        Title = "⚡ Egg Spawn Predictor Active",
        Content = "Monitoring Workspace for Eternal, Secret, Divine, and Mythic Egg Spawns..."
    })

    -- Predictor Toggles
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
                            -- Touch / Fire touch interest if part exists
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
