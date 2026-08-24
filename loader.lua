--[[
    Zxscript - Official Universal Loader
    Supports game routing (PlaceId & GameId), key passing, cache-busting,
    and double-execution prevention.
    
    Usage:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/mmtandico/Zax-Script/main/loader.lua"))()
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(math.random())

local function trim(v)
    return tostring(v or ""):match("^%s*(.-)%s*$") or ""
end

local function envOf(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, env = pcall(fn, ...)
    return ok and type(env) == "table" and env or nil
end

local genv = envOf(getgenv)
local cenv = envOf(getfenv, 1)

local function pick(...)
    for _, key in ipairs({...}) do
        if cenv and cenv[key] ~= nil then
            return cenv[key]
        end
        if rawget(_G, key) ~= nil then
            return rawget(_G, key)
        end
        if genv and genv[key] ~= nil then
            return genv[key]
        end
    end
end

local function setKey(key)
    key = trim(key)
    if key == "" then
        return
    end
    script_key, SCRIPT_KEY = key, key
    _G.script_key, _G.SCRIPT_KEY = key, key
    if genv then
        genv.script_key, genv.SCRIPT_KEY = key, key
    end
end

-- Base Repository URL for distribution payload
local BASE_PAYLOAD_URL = "https://raw.githubusercontent.com/mmtandico/Zax-Script/main/dist/hub.lua"

-- Route table for supported games (checks PlaceId or GameId)
local routes = {
    [286090429] = { "Arsenal", BASE_PAYLOAD_URL },
    [2753915549] = { "Blox Fruits (Sea 1)", BASE_PAYLOAD_URL },
    [4442272183] = { "Blox Fruits (Sea 2)", BASE_PAYLOAD_URL },
    [7449423635] = { "Blox Fruits (Sea 3)", BASE_PAYLOAD_URL },
    [10563114921] = { "Steal an Egg", BASE_PAYLOAD_URL },
    [107778070777162] = { "Steal an Egg", BASE_PAYLOAD_URL },
}

-- Resolve route by PlaceId or GameId, or default to Universal
local route = routes[game.PlaceId] or routes[game.GameId] or { "Universal Hub", BASE_PAYLOAD_URL }

-- Handle script keys if passed
setKey(pick("script_key", "SCRIPT_KEY"))

-- Prevent double execution using global loader state
local state = (genv and genv.ZxscriptLoaderState) or { loaded = {} }
if genv then
    genv.ZxscriptLoaderState = state
end

-- If already running this route name, clear old state if re-executing
if state.loaded[route[1]] then
    pcall(function()
        if genv and genv.ZxscriptCleanup then
            genv.ZxscriptCleanup()
        end
    end)
end
state.loaded[route[1]] = true

-- Fetch and execute distribution bundle with cache busting
local targetUrl = route[2] .. "?t=" .. tostring(os.time())
local ok, src = pcall(game.HttpGet, game, targetUrl)

if ok and src and #src > 100 then
    local compiled, loadErr = loadstring(src)
    if compiled then
        local runOk, runErr = pcall(compiled)
        if not runOk then
            warn("[Zxscript] Runtime error: " .. tostring(runErr))
            state.loaded[route[1]] = nil
        end
    else
        warn("[Zxscript] Compilation error: " .. tostring(loadErr))
        state.loaded[route[1]] = nil
    end
else
    warn("[Zxscript] Failed to download script hub from: " .. tostring(route[2]))
    state.loaded[route[1]] = nil
end
