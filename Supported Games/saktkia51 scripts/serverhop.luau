game:GetService("ReplicatedStorage")["Remote Events"].TeleportToMenu:FireServer()
print("joining lobby...")

queue_on_teleport([[
repeat task.wait() until game:IsLoaded()
print("joined lobby")

queue_on_teleport([[
if reload then
    queue_on_teleport([[
        loadstring(readfile("Celestial/Loader.luau"))()
    )
end
)

game:GetService("ReplicatedStorage").TeleportEvents.TeleportRequested:FireServer("Classic mode")
print("joining classic mode..")
]])