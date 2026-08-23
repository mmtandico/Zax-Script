--[[
    Universal Game Module
    Default handler loaded for any Roblox game without a dedicated script.
]]

local Universal = {}

function Universal.Init(UI, Config, Notifications)
    local gameTab = UI.Tabs.Game
    if not gameTab then return end

    gameTab:AddParagraph({
        Title = "Universal Mode Active",
        Content = "No specialized script detected for PlaceId: " .. tostring(game.PlaceId) .. ".\nAll universal Combat, Visuals, Movement, and Utility features are operational."
    })

    gameTab:AddButton({
        Title = "Bypass Clip Through Doors (Local TP)",
        Callback = function()
            local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = root.CFrame + (root.CFrame.LookVector * 10)
                Notifications.Success("Teleported 10 studs forward")
            end
        end
    })

    gameTab:AddButton({
        Title = "Respawn Character",
        Callback = function()
            local char = game.Players.LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
            end
        end
    })
end

return Universal
