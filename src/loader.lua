--[[
    Quantum Script Hub - Universal Remote Loader / Bootstrapper
    This script is designed to be executed via loadstring in your Roblox Executor.
    
    Usage:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/mmtandico/Zax-Script/main/dist/hub.lua"))()
]]

local Loader = {
    Repository = "https://raw.githubusercontent.com/mmtandico/Zax-Script/main",
    Branch = "main",
    Version = "1.0.0"
}

local function Fetch(url: string)
    local success, result = pcall(function()
        if syn and syn.request then
            return syn.request({Url = url, Method = "GET"}).Body
        elseif request then
            return request({Url = url, Method = "GET"}).Body
        elseif http_request then
            return http_request({Url = url, Method = "GET"}).Body
        else
            return game:HttpGet(url)
        end
    end)
    return success and result or nil
end

local function Boot()
    print("[Quantum Hub] Bootstrapping loader...")
    
    local distUrl = Loader.Repository .. "/dist/hub.lua"
    local source = Fetch(distUrl)

    if not source then
        warn("[Quantum Hub] Failed to download script from repository. Check URL or internet connection.")
        if StarterGui then
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Quantum Hub Error",
                    Text = "Failed to load script hub from remote source.",
                    Duration = 6
                })
            end)
        end
        return
    end

    local executable, loadErr = loadstring(source)
    if not executable then
        warn("[Quantum Hub] Compilation error: " .. tostring(loadErr))
        return
    end

    local success, runErr = pcall(executable)
    if not success then
        warn("[Quantum Hub] Runtime error: " .. tostring(runErr))
    end
end

Boot()

return Loader
