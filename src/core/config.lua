--[[
    Config Manager Module
    Handles saving and loading hub configurations to executor disk storage (JSON).
]]

local HttpService = game:GetService("HttpService")

local Config = {
    Folder = "RobloxScriptHub",
    CurrentConfig = {},
    DefaultSettings = {
        Combat = {
            AimbotEnabled = false,
            AimPart = "Head",
            FOV = 120,
            ShowFOV = false,
            FOVColor = {255, 255, 255},
            Smoothness = 1,
            TeamCheck = true,
            VisibleCheck = false,
            HitboxExpander = false,
            HitboxSize = 5,
        },
        Visuals = {
            ESPEnabled = false,
            Boxes = true,
            BoxColor = {255, 60, 60},
            Names = true,
            Distance = true,
            Health = true,
            Tracers = false,
            TracerOrigin = "Bottom",
            HighlightChams = false,
            TeamCheck = true,
        },
        Movement = {
            Fly = false,
            FlySpeed = 50,
            Noclip = false,
            WalkSpeed = 16,
            SpeedEnabled = false,
            JumpPower = 50,
            JumpEnabled = false,
            InfiniteJump = false,
        },
        Utility = {
            AntiAFK = true,
            Fullbright = false,
            FPSCap = 60,
        }
    }
}

-- Ensure Hub directories exist
function Config.Init(folderName)
    if folderName then
        Config.Folder = folderName
    end

    if makefolder and isfolder then
        if not isfolder(Config.Folder) then
            makefolder(Config.Folder)
        end
        if not isfolder(Config.Folder .. "/configs") then
            makefolder(Config.Folder .. "/configs")
        end
    end
    
    -- Load default
    Config.CurrentConfig = Config.DeepCopy(Config.DefaultSettings)
end

function Config.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Config.DeepCopy(orig_key)] = Config.DeepCopy(orig_value)
        end
        setmetatable(copy, Config.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function Config.DeepMerge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            Config.DeepMerge(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end

-- Save configuration by name
function Config.Save(name)
    name = name or "default"
    local path = Config.Folder .. "/configs/" .. name .. ".json"
    
    if writefile then
        local encoded = HttpService:JSONEncode(Config.CurrentConfig)
        writefile(path, encoded)
        return true, "Config '" .. name .. "' saved successfully."
    else
        return false, "FileSystem API (writefile) not supported by executor."
    end
end

-- Load configuration by name
function Config.Load(name)
    name = name or "default"
    local path = Config.Folder .. "/configs/" .. name .. ".json"

    if readfile and isfile and isfile(path) then
        local success, result = pcall(function()
            local content = readfile(path)
            local decoded = HttpService:JSONDecode(content)
            Config.CurrentConfig = Config.DeepMerge(Config.DeepCopy(Config.DefaultSettings), decoded)
            return Config.CurrentConfig
        end)

        if success then
            return true, "Config '" .. name .. "' loaded."
        else
            return false, "Failed to parse config file: " .. tostring(result)
        end
    else
        return false, "Config file does not exist: " .. path
    end
end

-- List all saved configs
function Config.List()
    local configs = {}
    if listfiles and isfolder and isfolder(Config.Folder .. "/configs") then
        local files = listfiles(Config.Folder .. "/configs")
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    return configs
end

return Config
