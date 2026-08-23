--[[
    Utils Module
    Common helper functions for player handling, math, drawing, and executor compatibility.
]]

local Utils = {}

-- Roblox Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

Utils.LocalPlayer = Players.LocalPlayer
Utils.Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Utils.Camera = Workspace.CurrentCamera
end)

-- Safe executor identification
function Utils.GetExecutor()
    if identifyexecutor then
        return identifyexecutor()
    elseif getexecutorname then
        return getexecutorname()
    end
    return "Unknown Executor"
end

-- Get Local Character & Humanoid safely
function Utils.GetCharacter(player)
    player = player or Utils.LocalPlayer
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
    player = player or Utils.LocalPlayer
    local hum = Utils.GetHumanoid(player)
    return hum and hum.Health > 0 and Utils.GetRoot(player) ~= nil
end

-- Team Checking
function Utils.IsTeamMate(player)
    if not player or player == Utils.LocalPlayer then return false end
    if Utils.LocalPlayer.Neutral then return false end
    if player.Team and Utils.LocalPlayer.Team then
        return player.Team == Utils.LocalPlayer.Team
    end
    if player.TeamColor and Utils.LocalPlayer.TeamColor then
        return player.TeamColor == Utils.LocalPlayer.TeamColor
    end
    return false
end

-- World to Screen conversion
function Utils.WorldToViewportPoint(position: Vector3)
    if not Utils.Camera then
        Utils.Camera = Workspace.CurrentCamera
    end
    local screenPos, onScreen = Utils.Camera:WorldToViewportPoint(position)
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

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Utils.LocalPlayer and Utils.IsAlive(player) then
            if checkTeam and Utils.IsTeamMate(player) then
                continue
            end

            local root = Utils.GetRoot(player)
            local head = player.Character:FindFirstChild("Head")
            local targetPart = head or root

            if targetPart then
                local screenPos, onScreen = Utils.WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if screenDist < shortestDistance then
                        if visibleOnly then
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterType = RaycastFilterType.Exclude
                            raycastParams.FilterDescendantsInstances = {Utils.LocalPlayer.Character, player.Character, Utils.Camera}
                            
                            local rayResult = Workspace:Raycast(Utils.Camera.CFrame.Position, targetPart.Position - Utils.Camera.CFrame.Position, raycastParams)
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
