--[[
    Steal an Egg Module (PlaceId: 10563114921)
    Game-specific features for Steal an Egg.
]]

local StealAnEgg = {
    AutoCollect = false,
    EggESP = false,
    AutoHatch = false,
    SpeedBoost = false,
}

function StealAnEgg.Init(UI, Config, Notifications)
    local gameTab = UI.Tabs.Game
    if not gameTab then return end

    gameTab:AddParagraph({
        Title = "Steal an Egg Module Active",
        Content = "PlaceId: 10563114921\nCustom features specifically tailored for Steal an Egg."
    })

    gameTab:AddToggle("SAEAutoCollect", {
        Title = "Auto Collect Eggs",
        Default = false,
        Callback = function(val)
            StealAnEgg.AutoCollect = val
            Notifications.Send("Steal an Egg", "Auto Collect: " .. (val and "ON" or "OFF"))
        end
    })

    gameTab:AddToggle("SAEEggESP", {
        Title = "Egg ESP",
        Default = false,
        Callback = function(val)
            StealAnEgg.EggESP = val
            Notifications.Send("Steal an Egg", "Egg ESP: " .. (val and "ON" or "OFF"))
        end
    })

    gameTab:AddToggle("SAEAutoHatch", {
        Title = "Auto Hatch",
        Default = false,
        Callback = function(val)
            StealAnEgg.AutoHatch = val
            Notifications.Send("Steal an Egg", "Auto Hatch: " .. (val and "ON" or "OFF"))
        end
    })

    gameTab:AddToggle("SAESpeedBoost", {
        Title = "Speed Boost",
        Default = false,
        Callback = function(val)
            StealAnEgg.SpeedBoost = val
            Notifications.Send("Steal an Egg", "Speed Boost: " .. (val and "ON" or "OFF"))
        end
    })
end

return StealAnEgg
