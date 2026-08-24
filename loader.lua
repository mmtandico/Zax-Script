--[[
    Zxscript - Official Remote Loader
    Supports direct execution via loadstring across all supported games.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(0.5)

local RAW_DIST_URL = "https://raw.githubusercontent.com/mmtandico/Zax-Script/main/dist/hub.lua"

local ok, source = pcall(function()
    return game:HttpGet(RAW_DIST_URL .. "?t=" .. tostring(os.time()))
end)

if ok and source and #source > 100 then
    local compiled, err = loadstring(source)
    if compiled then
        compiled()
    else
        warn("[Zxscript Loader Error] Failed to compile distribution bundle: " .. tostring(err))
    end
else
    warn("[Zxscript Loader Error] Failed to fetch script from repository. Check internet connection or URL.")
end
