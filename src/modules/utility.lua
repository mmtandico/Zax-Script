--[[
    Utility Module
    Anti-AFK, Server Hop, Rejoin, Fullbright, FPS Unlocker, and diagnostics.
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Config = require(script.Parent.Parent.core.config)
local Notifications = require(script.Parent.Parent.core.notifications)
local Utils = require(script.Parent.Parent.core.utils)

local Utility = {
    Connections = {},
    OriginalLighting = {},
    Enabled = false
}

function Utility.Init()
    -- Anti AFK
    table.insert(Utility.Connections, Players.LocalPlayer.Idled:Connect(function()
        local cfg = Config.CurrentConfig.Utility
        if cfg and cfg.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            Notifications.Send("Anti-AFK", "Prevented 20-minute idle disconnect", 3)
        end
    end))

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
