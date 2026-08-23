--[[
    Blox Fruits Module (PlaceId: 2753915549 / 4442272183 / 7449423635)
    Game-specific features for Blox Fruits (Auto Farm template, Bring Mobs, Fruit ESP).
]]

local BloxFruits = {
    AutoFarm = false,
    AutoChest = false,
    FastAttack = false,
    FruitESP = false
}

function BloxFruits.Init(UI, Config, Notifications)
    local gameTab = UI.Tabs.Game
    if not gameTab then return end

    gameTab:AddParagraph({
        Title = "Blox Fruits Module Active",
        Content = "Dedicated automation & farming helpers for Blox Fruits."
    })

    gameTab:AddToggle("BFFastAttack", {
        Title = "Fast Attack",
        Default = false,
        Callback = function(val)
            BloxFruits.FastAttack = val
            Notifications.Send("Blox Fruits", "Fast Attack: " .. (val and "ON" or "OFF"))
        end
    })

    gameTab:AddToggle("BFAutoFarm", {
        Title = "Auto Farm Level (Template)",
        Default = false,
        Callback = function(val)
            BloxFruits.AutoFarm = val
            Notifications.Send("Blox Fruits", "Auto Farm: " .. (val and "ON" or "OFF"))
        end
    })

    gameTab:AddToggle("BFAutoChest", {
        Title = "Auto Collect Chests",
        Default = false,
        Callback = function(val)
            BloxFruits.AutoChest = val
            Notifications.Send("Blox Fruits", "Auto Chest: " .. (val and "ON" or "OFF"))
        end
    })

    gameTab:AddToggle("BFFruitESP", {
        Title = "Spawned Devil Fruit ESP",
        Default = false,
        Callback = function(val)
            BloxFruits.FruitESP = val
            Notifications.Send("Blox Fruits", "Fruit ESP: " .. (val and "ON" or "OFF"))
        end
    })
end

return BloxFruits
