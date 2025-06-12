local entityLib = loadstring(readfile("Celestial/Libraries/Entity Library.lua"))()
local utils = loadstring(readfile("Celestial/Libraries/Core Utilities.lua"))()
local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart

local remoteEvents = game:GetService("ReplicatedStorage")["Remote Events"]
local remoteFunctions = game:GetService("ReplicatedStorage")["Remote Functions"]

local displayLabel = game:GetService("Workspace").AREA51.TeleporterRoom.Teleporter["Control Panels"].Middle.Displayer.SurfaceGui.Frame.TextLabel

--utils.fireTouchEvent(hrp, game.Workspace.Weapons["AK-47"].Hitbox)
--remoteFunctions["PAP Weapon"]:InvokeServer("AK-47")
--remoteEvents.PAPFinished:FireServer()

--[[
local function getTeleporterState()
    local door = game:GetService("Workspace").AREA51.TeleporterRoom.Teleporter.Teleporter.Inside
    local openY = 329.900665
    local closedY = 320.000061
    local tolerance = 0.1

    local currentY = door.CFrame.Position.Y

    if math.abs(currentY - openY) < tolerance then
        return "Open"
    elseif math.abs(currentY - closedY) < tolerance then
        return "Closed"
    else
        return "Unknown"
    end
end

local function collectKey()
    if game:GetService("Workspace"):FindFirstChild("Key") then
        utils.fireProxPrompt(game:GetService("Workspace").Key)
    end
end
]]

local function teleport(cframe)
    local newHRP = game.Players.LocalPlayer.Character.HumanoidRootPart

    newHRP.CFrame = cframe
end

local function teleporterInUse()
    local teleportSmoke = game:GetService("Workspace").AREA51.TeleporterRoom.Teleporter.Teleporter.Collision.Smoke

    if string.find(displayLabel.Text, "Teleporting") or teleportSmoke.Enabled then
        return true
    end

    return false
end



if teleporterInUse() then
    warn("The teleport is currently in use. Please try again later.")
    return
end






--[[   teleport to teleporter     ]] teleport(CFrame.new(110.864708, 313.499969, 72.9767151, 0.999984086, -2.85284294e-08, -0.00564495847, 2.80977517e-08, 1, -7.6373631e-08, 0.00564495847, 7.62138015e-08, 0.999984086))
task.wait(1)
--[[   firing prox prompt     ]] utils.fireProxPrompt(game:GetService("Workspace").AREA51.TeleporterRoom.Teleporter["Control Panels"].Middle.Teleport)

-- Success check

task.wait(0.5)
if not string.find(displayLabel.Text, "Teleporting") then
    return
end

local teleportContainer = game:GetService("Workspace").AREA51.TeleporterRoom.Teleporter.Teleporter.Inside

teleportContainer.CanCollide = false
task.wait(0.2)
teleportContainer.CanCollide = false
entityLib.teleport(CFrame.new(111.216148, 315.700012, 41.9078827, 0.99998349, 2.02579571e-08, -0.00574891455, -2.0241858e-08, 1, 2.85857316e-09, 0.00574891455, -2.74215717e-09, 0.99998349)) -- teleport into teleporter

local newHRP = game.Players.LocalPlayer.Character.HumanoidRootPart
local cframeTarget = CFrame.new(109.300003, 335.499969, 62, 1, 0, 0, 0, 1, 0, 0, 0, 1)

repeat task.wait() until entityLib.checkTeleport(newHRP, cframeTarget, 5)

print("teleported")

workspace.PACKAPUNCH.PAPStarted:FireServer("M14")
workspace.PACKAPUNCH.PAPFinished:FireServer()

print("punched")

-- workspace.AREA51.SecretTeleportRoom