--[[
    Zxscript - Official Remote Loader
    Architecture modeled directly after BFLoader reference.
    Supports 40+ game routes, key handling, cache-busting, and state management.
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

-- Primary distribution payload URL
local BASE_PAYLOAD_URL = "https://raw.githubusercontent.com/mmtandico/Zax-Script/main/dist/hub.lua"

local routes = {
    [9910245722] = { "Iron Soul", BASE_PAYLOAD_URL },
    [7856269159] = { "Anime Overload", BASE_PAYLOAD_URL },
    [97365843755210] = { "Cut Grass For Brainrots", BASE_PAYLOAD_URL },
    [124473577469410] = { "Be a Lucky Block", BASE_PAYLOAD_URL },
    [82397737462020] = { "Shrink for Brainrot", BASE_PAYLOAD_URL },
    [7798947148] = { "Anime Final Quest", BASE_PAYLOAD_URL },
    [77393318863643] = { "Aura Ascension Ahh game", BASE_PAYLOAD_URL },
    [105626692504093] = { "Be a Brainrot", BASE_PAYLOAD_URL },
    [8966502575] = { "Anime Reversal", BASE_PAYLOAD_URL },
    [112259901434347] = { "+1 Speed be a Lucky Block!", BASE_PAYLOAD_URL },
    [9802644580] = { "Summon Heroes", BASE_PAYLOAD_URL },
    [8937254139] = { "Dungeon Hunters", BASE_PAYLOAD_URL },
    [9833422940] = { "Unbox a Factory", BASE_PAYLOAD_URL },
    [9073513091] = { "Anime Apocalypse", BASE_PAYLOAD_URL },
    [7395930870] = { "Sell Lemons", BASE_PAYLOAD_URL },
    [10032271327] = { "Anime World Fighters", BASE_PAYLOAD_URL },
    [138064211947107] = { "Unbox a Car", BASE_PAYLOAD_URL },
    [9610561918] = { "Knife Farm", BASE_PAYLOAD_URL },
    [10004244222] = { "Kick a Lucky Block", BASE_PAYLOAD_URL },
    [9792947201] = { "Slime RNG", BASE_PAYLOAD_URL },
    [10016841656] = { "Noob Tower Defense", BASE_PAYLOAD_URL },
    [6409513651] = { "Anime Warrior III", BASE_PAYLOAD_URL },
    [10039338037] = { "Build A Ring Farm", BASE_PAYLOAD_URL },
    [9348272796] = { "SZA", BASE_PAYLOAD_URL },
    [7585079192] = { "Anime Story 2", BASE_PAYLOAD_URL },
    [10093833731] = { "Broken Blade", BASE_PAYLOAD_URL },
    [10148434559] = { "Lucky Block Rush", BASE_PAYLOAD_URL },
    [10168229420] = { "My Gaming Cafe", BASE_PAYLOAD_URL },
    [102072869879193] = { "Anime Astral", BASE_PAYLOAD_URL },
    [8356066619] = { "Anime Squadron", BASE_PAYLOAD_URL },
    [10200395747] = { "Grow a Garden 2", BASE_PAYLOAD_URL },
    [9826885587] = { "Evomon", BASE_PAYLOAD_URL },
    [10204207151] = { "Catch a Brainrot", BASE_PAYLOAD_URL },
    [7613921865] = { "Anime Expedition", BASE_PAYLOAD_URL },
    [10131390815] = { "Throw a Coin", BASE_PAYLOAD_URL },
    [8841437826] = { "Capybara vs Plants", BASE_PAYLOAD_URL },
    [8959257868] = { "Unscathed", BASE_PAYLOAD_URL },
    [10563114921] = { "Steal an Egg", BASE_PAYLOAD_URL },
    [107778070777162] = { "Steal an Egg", BASE_PAYLOAD_URL },
    [8946565814] = { "Anime Origins", BASE_PAYLOAD_URL },
    [286090429] = { "Arsenal", BASE_PAYLOAD_URL },
    [2753915549] = { "Blox Fruits (Sea 1)", BASE_PAYLOAD_URL },
    [4442272183] = { "Blox Fruits (Sea 2)", BASE_PAYLOAD_URL },
    [7449423635] = { "Blox Fruits (Sea 3)", BASE_PAYLOAD_URL },
}

local route = routes[game.PlaceId] or routes[game.GameId] or { "Universal Hub", BASE_PAYLOAD_URL }

setKey(pick("script_key", "SCRIPT_KEY"))

local state = (genv and genv.ZxscriptLoaderState) or { loaded = {} }
if genv then
    genv.ZxscriptLoaderState = state
end

if state.loaded[route[1]] then
    pcall(function()
        if genv and genv.ZxscriptCleanup then
            genv.ZxscriptCleanup()
        end
    end)
end
state.loaded[route[1]] = true

local targetUrl = route[2] .. "?t=" .. tostring(os.time())
local ok, src = pcall(game.HttpGet, game, targetUrl)
if ok and src and pcall(loadstring(src)) then
    return
end
state.loaded[route[1]] = nil
