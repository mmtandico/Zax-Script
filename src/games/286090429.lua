--[[
    Arsenal Module (PlaceId: 286090429)
    Game-specific features for Arsenal.
]]

local Arsenal = {
    InfiniteAmmo = false,
    RapidFire = false,
    NoRecoil = false,
    Wallbang = false
}

function Arsenal.Init(UI, Config, Notifications)
    local gameTab = UI.Tabs.Game
    if not gameTab then return end

    gameTab:AddParagraph({
        Title = "Arsenal Module Active",
        Content = "PlaceId: 286090429\nCustom features specifically tailored for Arsenal."
    })

    gameTab:AddToggle("ArsenalInfiniteAmmo", {
        Title = "Infinite Ammo",
        Default = false,
        Callback = function(val)
            Arsenal.InfiniteAmmo = val
            Notifications.Send("Arsenal", "Infinite Ammo: " .. (val and "ON" or "OFF"))
        end
    })

    gameTab:AddToggle("ArsenalNoRecoil", {
        Title = "No Recoil / Spread",
        Default = false,
        Callback = function(val)
            Arsenal.NoRecoil = val
            Notifications.Send("Arsenal", "No Recoil: " .. (val and "ON" or "OFF"))
        end
    })

    gameTab:AddToggle("ArsenalRapidFire", {
        Title = "Rapid Fire",
        Default = false,
        Callback = function(val)
            Arsenal.RapidFire = val
            Notifications.Send("Arsenal", "Rapid Fire: " .. (val and "ON" or "OFF"))
        end
    })
end

return Arsenal
