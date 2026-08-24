--[[
    Notification System Module
    Sends notifications via Rayfield Gen2 window:Notify(), with fallback to Roblox CoreGui StarterGui.
]]

local StarterGui = game:GetService("StarterGui")

local Notifications = {}

function Notifications.Send(title: string, text: string, duration: number?, icon: string?)
    title = title or "Script Hub"
    text = text or ""
    duration = duration or 5

    -- Try Rayfield notification if registered in environment
    if getgenv and getgenv().HubNotify then
        pcall(function()
            getgenv().HubNotify({
                Title = title,
                Content = text,
                Duration = duration,
                Image = icon
            })
        end)
        return
    end

    -- Fallback to Roblox StarterGui SetCore
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration,
            Icon = icon or "rbxassetid://4483345998"
        })
    end)
end

function Notifications.Success(text: string, duration: number?)
    Notifications.Send("Success", text, duration or 4)
end

function Notifications.Warn(text: string, duration: number?)
    Notifications.Send("Warning", text, duration or 5)
end

function Notifications.Error(text: string, duration: number?)
    Notifications.Send("Error", text, duration or 6)
end

return Notifications
