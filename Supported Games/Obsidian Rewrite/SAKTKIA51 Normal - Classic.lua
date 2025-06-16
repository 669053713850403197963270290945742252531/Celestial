while not game:IsLoaded() do
	task.wait()
end

local utils = loadstring(readfile("Celestial/Libraries/Core Utilities.lua"))()
local entityLib = loadstring(readfile("Celestial/Libraries/Entity Library.lua"))()

local library = loadstring(readfile("Celestial/Obsidian/Library.lua"))()
local themeManager = loadstring(readfile("Celestial/Obsidian/ThemeManager.lua"))()
local saveManager = loadstring(readfile("Celestial/Obsidian/SaveManager.lua"))()

local options = library.Options
local toggles = library.Toggles

library.ForceCheckbox = false
library.ShowToggleFrameInKeybinds = true

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local killersFolder = game.Workspace:FindFirstChild("Killers")
local area51 = game:GetService("Workspace").AREA51
local camera = game:GetService("Workspace").CurrentCamera

local window = library:CreateWindow({
    Title = "Celestial",
    Footer = "Survive and Kill the Killers in Area 51: " .. gameName .. " - v1.0.0",
    Center = true,
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.RightControl,
    NotifySide = "Right",
    ShowCustomCursor = false,
    Icon = 105046741702072,
    Resizable = true,
    MobileButtonsSide = "Left"
})

window.autoResetRainbowColor = true
window.rainbowSpeed = 0.1
window.alertVolume = 1
window.notifSoundEnabled = true
window.keybindFrameEnabled = true

library.KeybindFrame.Visible = window.keybindFrameEnabled

local tabs = {
    home = window:AddTab("Home", "info"),
	utils = window:AddTab("Utility", "wrench"),
    player = window:AddTab("Player", "circle-user-round"),
    visuals = window:AddTab("Visuals", "eye"),
    world = window:AddTab("World", "globe"),
    weapons = window:AddTab("Weapons", "swords"),
	misc = window:AddTab("Miscellaneous", "circle-ellipsis"),
	uiSettings = window:AddTab("UI Settings", "settings"),
}

local restrictedWeapons = {
    Crossbow = true,
    MG42 = true,
    FreezeGun = true
}

-- =================================================
--                   FUNCTIONS                   --
-- =================================================

local function notify(title, desc, duration)
	if typeof(title) ~= "string" then
        library:Notify("Error notifying", "Argument #1 (title) expected a string value but got a " .. typeof(title) .. " value.", 20)
        return
    end

    if typeof(desc) ~= "string" then
        library:Notify("Error notifying", "Argument #1 (desc) expected a string value but got a " .. typeof(desc) .. " value.", 20)
        return
    end

    if duration ~= nil and typeof(duration) ~= "number" then
        library:Notify("Error notifying", "Argument #2 (duration) expected a number value but got a " .. typeof(duration) .. " value.", 20)
        return
    end

    if duration == nil then
        duration = 5
    end

    if window.notifSoundEnabled then
		local sound = Instance.new("Sound", gethui())
		sound.PlayOnRemove = true
		sound.SoundId = "rbxassetid://4590662766"
		sound.Volume = window.alertVolume
		sound:Destroy()

        library:Notify({ Title = title, Description = desc, Time = duration--[[, SoundId = "rbxassetid://117667749029346"]] })
		return
    end

    library:Notify({ Title = title, Description = desc, Time = duration })
end

local function getHRP()
    return entityLib.getCharInstance("HumanoidRootPart") or nil
end

local function getHumanoid()
    return entityLib.getCharInstance("Humanoid") or nil
end

local function isAlive()
    if entityLib.isAlive() then
        return true
    end

    return false
    --if not entityLib.isAlive() then return end
end

local defaults = {
	killerESPColor_ColorPicker = Color3.fromRGB(255, 0, 0),
    killerNameTagColor_ColorPicker = Color3.fromRGB(255, 255, 255)
}

local rainbowConnections = {}
local hues = {}

local function toggleRainbow(enabled, colorPickerName)
	if enabled then
		if not rainbowConnections[colorPickerName] then
			hues[colorPickerName] = hues[colorPickerName] or 0
			rainbowConnections[colorPickerName] = runService.RenderStepped:Connect(function(deltaTime)
				hues[colorPickerName] = (hues[colorPickerName] + deltaTime * window.rainbowSpeed) % 1

				if not options[colorPickerName] or not defaults[colorPickerName] then
					window.notifSoundPath = getLib("assetLib").fetchAsset("Assets/Sounds/Notification Main.mp3")

					notify("Invalid colorpicker object and/or no valid default was found.", 99999)
					return
				else
					options[colorPickerName]:SetValueRGB(Color3.fromHSV(hues[colorPickerName], 1, 1))
				end
			end)
		end
	else
		if rainbowConnections[colorPickerName] then
			rainbowConnections[colorPickerName]:Disconnect()
			rainbowConnections[colorPickerName] = nil
		end

		if window.autoResetRainbowColor then
			if not options[colorPickerName] or not defaults[colorPickerName] then
				window.notifSoundPath = getLib("assetLib").fetchAsset("Assets/Sounds/Notification Main.mp3")

				notify("Invalid colorpicker object and/or no valid default was found.", 99999)
				return
			else
				options[colorPickerName]:SetValueRGB(defaults[colorPickerName])
			end
		end
	end
end

local function teleporterInUse()
    local displayLabel = area51.TeleporterRoom.Teleporter["Control Panels"].Middle.Displayer.SurfaceGui.Frame.TextLabel
    local teleportSmoke = area51.TeleporterRoom.Teleporter.Teleporter.Collision.Smoke

    if string.find(displayLabel.Text, "Teleporting") or teleportSmoke.Enabled then
        return true
    end

    return false
end

local function getTeleporterState()
    local door = area51.TeleporterRoom.Teleporter.Teleporter.Inside
    local teleportSmoke = area51.TeleporterRoom.Teleporter.Teleporter.Collision.Smoke
    local openY = 329.900665
    local closedY = 320.000061
    local tolerance = 0.1

    local currentY = door.CFrame.Position.Y

    if math.abs(currentY - openY) < tolerance then
        return "Open"
    elseif teleportSmoke.Enabled then
        return "Teleporting in Progress"
    elseif math.abs(currentY - closedY) < tolerance and not teleportSmoke.Enabled then
        return "Closed"
    else
        return "Moving"
    end
end

local function freeze(enabled)
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = enabled and 0 or 16
        hum.JumpPower = enabled and 0 or 50
    end
end

local function getSuffix(sliderObj, suffixString)
    if typeof(sliderObj) ~= "table" then
        notify("Error", "Argument #1 (sliderObj) did not return a table instance.", 1000)
        return
    end

    if typeof(suffixString) ~= "string" then
        notify("Error", "Argument #2 (suffixString) did not return a string value.", 1000)
        return
    end

    local val = sliderObj.Value
    return val == 1 and " " .. suffixString or " " .. suffixString .. "s"
end


-- =================================================
--                   TAB: HOME                   --
-- =================================================

local infoTabBox = tabs.home:AddLeftTabbox()
local playerTab = infoTabBox:AddTab("Player")

local respawnButton_Toggle = playerTab:AddToggle("toggleRespawn_Toggle", { Text = "Respawn Button", Tooltip = false, Default = true })

playerTab:AddLabel("Name: " .. localplayer.DisplayName .. " (@" .. localplayer.Name .. ")", true)
playerTab:AddLabel("UserId: " .. localplayer.UserId, true)
playerTab:AddLabel("Mouse Lock Permitted: true", true)
playerTab:AddLabel("Neutral: " .. tostring(localplayer.Neutral), true)
playerTab:AddLabel("Team: " .. tostring(localplayer.Team), true)

local gameTab = infoTabBox:AddTab("Game")

gameTab:AddLabel("Game Name: " .. gameName, true)
gameTab:AddLabel("Place ID: " .. game.PlaceId, true)
gameTab:AddLabel("Job ID: " .. game.JobId, true)
gameTab:AddLabel("Creator ID: " .. game.CreatorId, true)
gameTab:AddLabel("Creator Type: " .. game.CreatorType.Name, true)

local serverJoinScript = [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId..", '" .. game.JobId.."')"
gameTab:AddLabel("\nServer Join Script: " .. serverJoinScript, true)
gameTab:AddButton({ Text = "Copy Server Join Script", DoubleClick = false,
    Func = function()
        setclipboard(serverJoinScript)

		notify("Success", "The server join script has been copied to your clipboard.", 5)
    end,
})

if auth and executionLib then
    local whitelistTab = infoTabBox:AddTab("Whitelist")

    whitelistTab:AddLabel("Identifier: " .. auth.currentUser.Identifier, true)
    whitelistTab:AddLabel("Rank: " .. auth.currentUser.Rank, true)
    whitelistTab:AddLabel("Discord ID: " .. auth.currentUser.DiscordId, true)
    whitelistTab:AddLabel("Total Exections: " .. executionLib.fetchExecutions(), true)
end

respawnButton_Toggle:OnChanged(function(enabled)
	utils.setElementEnabled("Reset Button", enabled)
end)

-- =================================================
--                   TAB: UTILITY                   --
-- =================================================

local teleportGroup = tabs.utils:AddLeftGroupbox("Teleport")
local healingGroup = tabs.utils:AddRightGroupbox("Healing")
local soundsGroup = tabs.utils:AddLeftGroupbox("Sounds")
local otherGroup2 = tabs.utils:AddRightGroupbox("Other")

-------------------------------------
--      UTILITY: TELEPORT GROUP  --
-------------------------------------

teleportGroup:AddDropdown("regularLocationsList_Dropdown", { Text = "Teleport", Tooltip = false, Values = {"Surface", "Area 51", "Teleporter", "Alien", "Alien Code Input",
"Pack A Punch Machine", "Obtain Armor", "Ammo Box", "Zombie Morpher", "Radioactive Zone"}, Default = 1 })
teleportGroup:AddButton({ Text = "Teleport", Func = function()
        local cframeValues = {
            ["Surface"] = CFrame.new(326.087067, 511.699921, 392.975769, 0.999967098, 0, 0.00810976978, 0, 1, 0, -0.00810976978, 0, 0.999967098),
            ["Area 51"] = CFrame.new(327.146332, 313.499908, 369.922913, 0.0146765877, 0, 0.999892294, 0, 1, 0, -0.999892294, 0, 0.0146765877),
            ["Teleporter"] = CFrame.new(110.864708, 313.499969, 72.9767151, 0.999984086, -2.85284294e-08, -0.00564495847, 2.80977517e-08, 1, -7.6373631e-08, 0.00564495847, 7.62138015e-08, 0.999984086),
            ["Alien"] = CFrame.new(237.99556, 337.799927, 472.399994, 4.34290196e-05, 1.17440393e-07, -1, 3.82457843e-09, 1, 1.17440564e-07, 1, -3.8296788e-09, 4.34290196e-05),
            ["Alien Code Input"] = CFrame.new(137.72377, 333.499939, 525.566956, -0.999551415, 4.71232431e-09, 0.0299497657, 4.37261027e-09, 1, -1.14082894e-08, -0.0299497657, -1.12722134e-08, -0.999551415),
            ["Armor"] = CFrame.new(-167.243805, 293.500214, 316.368713, -0.0163577069, -1.04670743e-08, 0.999866188, 6.23807708e-08, 1, 1.14890186e-08, -0.999866188, 6.25603604e-08, -0.0163577069),
            ["Ammo Box"] = CFrame.new(184.26889, 314.102753, 437.041473, -0.999995649, 5.072752e-09, 0.00294528855, 5.24779331e-09, 1, 5.94231793e-08, -0.00294528855, 5.94383778e-08, -0.999995649),
            ["Zombie Morpher"] = CFrame.new(402.278748, 512.499817, 399.379395, 0.999998093, -4.97486283e-08, 0.00196264265, 4.98476567e-08, 1, -5.0407067e-08, -0.00196264265, 5.05048021e-08, 0.999998093),
            ["Radioactive Zone"] = CFrame.new(140.615601, 313.499969, 435.841766, -0.9997648, 3.54234375e-09, 0.0216868054, 6.39699493e-09, 1, 1.31561421e-07, -0.0216868054, 1.31669211e-07, -0.9997648),
        }

        if not isAlive() then return end

        local dropdown = options.regularLocationsList_Dropdown
        local cframeDestination = cframeValues[dropdown.Value]
        local hrp = getHRP()

        if dropdown.Value == "Pack A Punch Machine" then
            entityLib.teleport(game:GetService("Workspace").PACKAPUNCH.GUI)

            local papMachineCFrame = game:GetService("Workspace").PACKAPUNCH.GUI.CFrame

            if entityLib.checkTeleport(hrp, papMachineCFrame, 5) then
                notify("Success", "Successfully teleported to " .. dropdown.Value .. ".", 6)
            else
                notify("Error", "Failed to teleport to " .. dropdown.Value .. ".", 7)
            end

            return
        end

        entityLib.teleport(cframeDestination)

        if entityLib.checkTeleport(hrp, cframeDestination, 5) then
            notify("Success", "Successfully teleported to " .. dropdown.Value .. ".", 6)
        else
            notify("Error", "Failed to teleport to " .. dropdown.Value .. ".", 7)
        end
    end,
})

teleportGroup:AddButton({ Text = "Spawn Kill Teleport", Tooltip = "Teleports you to an area where you can kill the killers through the glass.",
    Func = function()
        if not isAlive() then return end

        local destination = CFrame.new(-52.6837997, 313.500305, 292.096558, 1, 1.49757151e-09, -4.17306546e-05, -1.49720991e-09, 1, 8.6659675e-09, 4.17306546e-05, -8.66590533e-09, 1)
        local hrp = getHRP()

        entityLib.teleport(destination)

        if entityLib.checkTeleport(hrp, destination, 5) then
            notify("Success", "Successfully teleported to the area.", 6)
        else
            notify("Error", "Failed to teleport  to the area.", 7)
        end
    end,
})

-------------------------------------
--      UTILITY: HEALING GROUP  --
-------------------------------------

local function getEnergyDrink()
    if not utils.fetchOwnership("Gamepass", 1182965) then
        return nil, "You do not own the gamepass."
    end

    local energyDrink = entityLib.getTool("Specific", "Energy")

    if not energyDrink then
        return nil, "Energy drink not found."
    end

    if energyDrink:FindFirstChild("Ammo") and energyDrink.Ammo.Value == 0 then
        return nil, "Energy drink has no more charges left."
    end

    return energyDrink, nil
end

local function refillEnergyDrink()

    local energyDrink = getEnergyDrink()
    local hrp = getHRP()

    if not energyDrink then return end

    local remainingCharges = energyDrink.Ammo.Value
    
    if remainingCharges ~= 0 then
        notify("Refill Failed", "You still have " .. remainingCharges .. " charges left.", 6, "Error")
        return
    end
    
    local origCFrame = entityLib.storeData(hrp, "CFrame")
    
    task.wait(0.01)
    
    entityLib.teleport(CFrame.new(178.023087, 333.499908, 597.890442, 0.0192538705, -8.12836092e-08, 0.99981463, 1.48566126e-09, 1, 8.12700662e-08, -0.99981463, -7.93774491e-11, 0.0192538705))
    
    task.wait(0.17)
    
    utils.fireProxPrompt(area51.CafeRoom["Coffee Machine"].Energy.Head)
    
    -- Restore original cframe / teleport back
    
    entityLib.restoreData(hrp, "CFrame")
    entityLib.clearData(hrp, "CFrame")
end

healingGroup:AddButton({ Text = "Drink Energy Drink", Func = function()
        local energyDrink, err = getEnergyDrink()
        local drinkAmount = options.energyDrinkAmount_Slider.Value

        if energyDrink then
            
            for _ = 1, drinkAmount do
                energyDrink.Drank:FireServer()
            end

        else

            notify("Error", err, 7)
        end
    end,
})

healingGroup:AddSlider("energyDrinkAmount_Slider", { Text = "Drink Amount", Tooltip = "How much to drink from the energy drink.", Default = 5, Min = 1, Max = 5, Rounding = 0 })
healingGroup:AddButton({ Text = "Drink All", Func = function()
        local energyDrink, err = getEnergyDrink()

        if energyDrink then
            local remainingCharges = energyDrink.Ammo.Value
            
            for _ = 1, remainingCharges do
                energyDrink.Drank:FireServer()
            end

        else

            notify("Error", err, 7)
        end
    end,
})

healingGroup:AddButton({ Text = "Refill", Func = function()
        local energyDrink, err = getEnergyDrink()

        if not energyDrink then
            notify("Error", err, 7)
            return
        else
            refillEnergyDrink()
        end
    end,
})

-----------------------
--    AUTO DRINK  --
-----------------------

local function getMaxThreshold()
    if utils.fetchOwnership("Gamepass", 1273854) then -- If the player owns the "Survivor pack" gamepass
        return 150
    else
        return 100
    end
end

local autoDrinkToggle
local autoDrinkThresholdSlider
local drinkLoopRunning = false

local function startAutoDrinkLoop()
    if drinkLoopRunning or not autoDrinkToggle.Value then return end
    drinkLoopRunning = true

    task.spawn(function()
        while autoDrinkToggle.Value do
            local humanoid = getHumanoid()

            if humanoid and humanoid.Health <= autoDrinkThresholdSlider.Value then
                local energyDrink, err = getEnergyDrink()

                if err then
                    notify("Error", err, 10)
                    return
                end

                if energyDrink then
                    local drankEvent = energyDrink:FindFirstChild("Drank")

                    if drankEvent then
                        for _ = 1, 5 do
                            drankEvent:FireServer()
                            task.wait(0.1)
                        end
                    end
                end
            end

            task.wait(0.2)
        end

        drinkLoopRunning = false
    end)
end

local function startAutoRefillLoop()
    if autoRefillLoopRunning or not autoRefillToggle.Value then return end
    autoRefillLoopRunning = true

    task.spawn(function()
        local wasOutOfAmmo = false

        local lastErrorMessage = nil
        local lastErrorNotifyTime = 0
        local notifyCooldown = 5

        while true do
            if not autoRefillToggle.Value then break end

            local now = tick()
            local energyDrink, err = getEnergyDrink()

            if energyDrink and energyDrink:FindFirstChild("Ammo") then
                local ammoValue = energyDrink.Ammo.Value

                if ammoValue == 0 and not wasOutOfAmmo then
                    refillEnergyDrink()

                    local hrp = getHRP()
                    entityLib.clearData(hrp, "CFrame")

                    wasOutOfAmmo = true
                elseif ammoValue > 0 then
                    wasOutOfAmmo = false
                end

                lastErrorMessage = nil
                lastErrorNotifyTime = 0
            elseif err then
                if not autoRefillToggle.Value then break end

                if err ~= lastErrorMessage then
                    notify("Error", err, 10)
                    lastErrorMessage = err
                    lastErrorNotifyTime = tick()
                end
            end

            task.wait(0.5)
        end

        autoRefillLoopRunning = false
    end)
end

autoDrinkToggle = healingGroup:AddToggle("autoDrink_Toggle", { Text = "Auto Drink", Tooltip = "Drinks the entire energy drink when you are below the threshold.", Default = false })

local autoDrinkDepbox = healingGroup:AddDependencyBox()

autoDrinkThresholdSlider = autoDrinkDepbox:AddSlider("autoDrinkThreshold_Slider", { Text = "Threshold", Tooltip = false, Default = 40, Min = 10, Max = getMaxThreshold(), Rounding = 0 })

autoDrinkDepbox:SetupDependencies({ { toggles.autoDrink_Toggle, true } })

autoRefillToggle = healingGroup:AddToggle("autoRefill_Toggle", { Text = "Auto Refill", Tooltip = "Refills your energy drink when it has no more charges left.", Default = false })

toggles.autoDrink_Toggle:OnChanged(function(enabled)
    if enabled then
        startAutoDrinkLoop()
    else
        drinkLoopRunning = false
    end
end)

toggles.autoRefill_Toggle:OnChanged(function(enabled)
    if enabled then
        startAutoRefillLoop()
    else
        autoRefillLoopRunning = false
    end
end)

-- Auto restart

localplayer.CharacterAdded:Connect(function()
    drinkLoopRunning = false
    task.wait(1)

    if autoDrinkToggle.Value then
        startAutoDrinkLoop()
    end
end)

-----------------------------
--    END OF AUTO DRINK  --
-----------------------------

-------------------------------------
--      UTILITY: SOUNDS GROUP  --
-------------------------------------

local disabledSounds = {
    Lightning = false,
    Thunder = false,
    Music = false
}

local runningLoops = {}

local function updateSoundLoop(soundName, isEnabled)
    if isEnabled and not runningLoops[soundName] then
        runningLoops[soundName] = true

        task.spawn(function()
            --print("Loop started for:", soundName)
            while not library.Unloaded and disabledSounds[soundName] do
                local sound

                if soundName == "Lightning" then
                    sound = game.Workspace:FindFirstChild("LightningSound")
                elseif soundName == "Thunder" then
                    sound = game.Workspace:FindFirstChild("ThunderSound")
                elseif soundName == "Music" then
                    sound = game.Workspace:FindFirstChild("Music")
                end

                if sound and sound:IsA("Sound") then
                    sound:Stop()
                    sound.Playing = false
                end

                task.wait(0.1)
            end

            runningLoops[soundName] = nil
            --print("Loop stopped for:", soundName)
        end)

    elseif not isEnabled and runningLoops[soundName] then
        --print("Stopping loop for:", soundName)
    end
end

soundsGroup:AddDropdown("disabledSoundsList_Dropdown", { Text = "Disabled Game Sounds", Tooltip = false, Values = { "Lightning", "Thunder", "Music" }, Default = 0, Multi = true,
    Callback = function(valueTable)
        for option in pairs(disabledSounds) do
            local newState = valueTable[option] or false
            
            if disabledSounds[option] ~= newState then
                disabledSounds[option] = newState
                updateSoundLoop(option, newState)
            end
        end
    end,
})

soundsGroup:AddButton({ Text = "Disable All Sounds",
    Func = function()
        options.disabledSoundsList_Dropdown:SetValue({
            Lightning = true,
            Thunder = true,
            Music = true
        })
    end,
})

-------------------------------------
--      UTILITY: SOUNDS GROUP  --
-------------------------------------

otherGroup2:AddToggle("promptReach_Toggle", { Text = "Prompt Reach", Tooltip = false, Default = false })
otherGroup2:AddToggle("instantInteract_Toggle", { Text = "Instant Interact", Tooltip = false, Default = false })

toggles.promptReach_Toggle:OnChanged(function(enabled) 
    for _, obj in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if enabled then
                entityLib.storeData(obj, "MaxActivationDistance", true)
                obj.MaxActivationDistance = 32
            else
                entityLib.restoreData(obj, "MaxActivationDistance")
            end
        end
    end
end)

toggles.instantInteract_Toggle:OnChanged(function(enabled) 
    for _, obj in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if enabled then
                entityLib.storeData(obj, "HoldDuration", true)
                obj.HoldDuration = 0
            else
                entityLib.restoreData(obj, "HoldDuration")
            end
        end
    end
end)

-- =================================================
--                   TAB: PLAYER                   --
-- =================================================

local movementGroup = tabs.player:AddLeftGroupbox("Movement")
local othersGroup3 = tabs.player:AddRightGroupbox("Other")

tabs.player:UpdateWarningBox({ Title = "Warning", Text = "Due to Roblox's physics limitations, high velocity speeds may cause unexpected falling on collisions.\n\nFly is NOT compatible when Speed Exploit's mode is set as Velocity and will be swapped.",
Visible = true })

-------------------------------------
--      PLAYER: MOVEMENT GROUP  --
-------------------------------------

movementGroup:AddToggle("speedExploit_Toggle", { Text = "Speed Exploit", Tooltip = false, Default = false })

local speedExploitDepbox = movementGroup:AddDependencyBox()

speedExploitDepbox:AddDropdown("speedExploitMethod_Dropdown", { Text = "Method", Tooltip = false, Values = { "WalkSpeed", "Velocity" }, Default = 1 })
speedExploitDepbox:AddSlider("speedExploitAmount_Slider", { Text = "Amount", Tooltip = false, Default = 20, Min = 16, Max = 100, Rounding = 0 })
speedExploitDepbox:AddDivider()

movementGroup:AddToggle("enableFly_Toggle", { Text = "Enable Fly" })

local flyDepbox = movementGroup:AddDependencyBox()

flyDepbox:AddToggle("toggleFly_Toggle", { Text = "Fly" })
:AddKeyPicker("fly_KeyPicker", { Text = "Fly", Default = "F", SyncToggleState = true, Mode = "Toggle", NoUI = false })
local flyHorizSpeed_Slider = flyDepbox:AddSlider("flyHorizSpeed_Slider", { Text = "Horizontal Speed", Tooltip = "The speed you normally go at.", Default = 100, Min = 30, Max = 1000, Rounding = 0 })
local flyVertSpeed_Slider = flyDepbox:AddSlider("flyVertSpeed_Slider", { Text = "Vertical Speed", Tooltip = "The speed you go when ascending/descending.", Default = 100, Min = 30, Max = 300, Rounding = 0 })
flyDepbox:AddDivider()

movementGroup:AddToggle("enableNoclip_Toggle", { Text = "Enable Noclip" })

local noclipDepbox = movementGroup:AddDependencyBox()

noclipDepbox:AddToggle("toggleNoclip_Toggle", { Text = "Noclip" })
:AddKeyPicker("noclip_KeyPicker", { Text = "Noclip", Default = "G", SyncToggleState = true, Mode = "Toggle", NoUI = false })
noclipDepbox:AddDivider()

movementGroup:AddToggle("enableJumpPower_Toggle", { Text = "Enable JumpPower" })

local jumpPowerDepbox = movementGroup:AddDependencyBox()

jumpPowerDepbox:AddSlider("jumpPowerValue_Slider", { Text = "Value", Tooltip = false, Default = 50, Min = 50, Max = 200, Rounding = 0 })

speedExploitDepbox:SetupDependencies({ { toggles.speedExploit_Toggle, true } })
flyDepbox:SetupDependencies({ { toggles.enableFly_Toggle, true } })
noclipDepbox:SetupDependencies({ { toggles.enableNoclip_Toggle, true } })
jumpPowerDepbox:SetupDependencies({ { toggles.enableJumpPower_Toggle, true } })

toggles.enableJumpPower_Toggle:OnChanged(function(enabled)
    if enabled then
        local hum = getHumanoid()
        entityLib.storeData(hum, "JumpPower", true)

        entityLib.modifyPlayer("JumpPower", options.jumpPowerValue_Slider.Value)
    else
        local hum = getHumanoid()
        entityLib.restoreData(hum, "JumpPower")
    end
end)

options.jumpPowerValue_Slider:OnChanged(function(val)
    local jumpPowerEnabled = toggles.enableJumpPower_Toggle.Value

    if jumpPowerEnabled then
        entityLib.modifyPlayer("JumpPower", val)
    end
end)

localplayer.CharacterAdded:Connect(function(char)
	if toggles.enableJumpPower_Toggle.Value then
		entityLib.modifyPlayer("JumpPower", options.jumpPowerValue_Slider.Value)
	end
end)

toggles.toggleFly_Toggle:OnChanged(function(flyToggleEnabled)
    local flyAllowed = toggles.enableFly_Toggle.Value

    if flyToggleEnabled and not flyAllowed then
        toggles.toggleFly_Toggle:SetValue(false)
        return
    end

    if flyToggleEnabled then
        if toggles.speedExploit_Toggle.Value == true and options.speedExploitMethod_Dropdown.Value == "Velocity" then
            options.speedExploitMethod_Dropdown:SetValue("WalkSpeed")
            options.speedExploitAmount_Slider:SetValue(options.speedExploitAmount_Slider.Max)

            notify("Fly is incompatible with Velocity", "Speed Exploit has been changed to WalkSpeed.", 10)
        end
    end

    if flyAllowed then

        entityLib.toggleFly(flyToggleEnabled)
        entityLib.setFlySpeed(flyHorizSpeed_Slider.Value, flyVertSpeed_Slider.Value)
        --entityLib.setFlySpeed(100, 100)
    else
        entityLib.toggleFly(false)
    end
end)

options.flyHorizSpeed_Slider:OnChanged(function()
    entityLib.setFlySpeed(flyHorizSpeed_Slider.Value, flyVertSpeed_Slider.Value)
end)

options.flyVertSpeed_Slider:OnChanged(function()
    entityLib.setFlySpeed(flyHorizSpeed_Slider.Value, flyVertSpeed_Slider.Value)
end)

toggles.toggleNoclip_Toggle:OnChanged(function(noclipToggleEnabled)
    local noclipAllowed = toggles.enableNoclip_Toggle.Value

    if noclipToggleEnabled and not noclipAllowed then
        toggles.toggleNoclip_Toggle:SetValue(false)
        return
    end

    if noclipAllowed then
        entityLib.toggleNoclip(noclipToggleEnabled)
    else
        entityLib.toggleNoclip(false)
    end
end)

local method = options.speedExploitMethod_Dropdown.Value
local slider = options.speedExploitAmount_Slider
slider:SetMin(1)

if method == "WalkSpeed" then
    slider:SetMax(20)
else
    slider:SetMax(100)
end

local char = localplayer.Character or localplayer.CharacterAdded:Wait()
local humanoid, rootPart, bodyVelocity, velocityConnection

-- Helpers

local function getCharacterParts()
	character = localplayer.Character or localplayer.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid", 5)
	rootPart = character:WaitForChild("HumanoidRootPart", 5)
end

local function enableVelocityMode(speed)
	if bodyVelocity then bodyVelocity:Destroy() end

	bodyVelocity = Instance.new("BodyVelocity", rootPart)
	bodyVelocity.Name = "SpeedExploitVelocity"
	bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	bodyVelocity.Velocity = Vector3.zero

	if velocityConnection then velocityConnection:Disconnect() end

	velocityConnection = runService.RenderStepped:Connect(function()
		local moveDir = humanoid.MoveDirection
		bodyVelocity.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * speed or Vector3.zero
	end)
end

local function disableVelocityMode()
	if velocityConnection then
		velocityConnection:Disconnect()
		velocityConnection = nil
	end

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
end

local function applySpeed()
	if not humanoid or not rootPart then getCharacterParts() end

	local enabled = toggles.speedExploit_Toggle.Value
	local method = options.speedExploitMethod_Dropdown.Value
	local speed = options.speedExploitAmount_Slider.Value

	if enabled then
		if method == "WalkSpeed" then
			disableVelocityMode()
			humanoid.WalkSpeed = speed
		else
			humanoid.WalkSpeed = 16
			enableVelocityMode(speed)
		end
	else
		disableVelocityMode()
		humanoid.WalkSpeed = 16
	end
end

toggles.speedExploit_Toggle:OnChanged(applySpeed)
options.speedExploitAmount_Slider:OnChanged(applySpeed)

options.speedExploitMethod_Dropdown:OnChanged(function()
	local method = options.speedExploitMethod_Dropdown.Value
	local slider = options.speedExploitAmount_Slider

    if method == "Velocity" and toggles.toggleFly_Toggle.Value then
        options.speedExploitMethod_Dropdown:SetValue("WalkSpeed")
        notify("Velocity Speed is incompatible with Fly", "Speed Exploit has been changed to WalkSpeed.", 10)
    end

	if method == "WalkSpeed" then
		slider:SetMin(1)
		slider:SetMax(20)
		if slider.Value > 20 then slider:SetValue(20) end
	else
		slider:SetMin(1)
		slider:SetMax(100)
	end

	applySpeed()
end)

-- Handling character respawns

local function onCharacterAdded(char)
	if not char then return end

	humanoid = char:WaitForChild("Humanoid", 5)
	rootPart = char:WaitForChild("HumanoidRootPart", 5)

	if humanoid and rootPart then
		character = char
		task.wait(0.1)
		applySpeed()
	end
end

localplayer.CharacterAdded:Connect(onCharacterAdded)

if localplayer.Character then
	onCharacterAdded(localplayer.Character)
else
	localplayer.CharacterAdded:Wait()
	onCharacterAdded(localplayer.Character)
end

-------------------------------------
--      PLAYER: OTHERS GROUP  --
-------------------------------------

othersGroup3:AddToggle("doorNoclip_Toggle", { Text = "Door Noclip" })

toggles.doorNoclip_Toggle:OnChanged(function(enabled)
    for _, part in ipairs(game.Workspace:GetDescendants()) do
        if part:IsA("Part") and part.Name == "Door" then
            if enabled then
                entityLib.storeData(part, "Transparency", true)
                part.CanCollide = false
                part.Transparency = 0.8
            else
                part.CanCollide = true
                entityLib.restoreData(part, "Transparency")
            end

            -- Handle decals for this Door part
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    if enabled then
                        entityLib.storeData(child, "Transparency", true)
                        child.Transparency = 0.8
                    else
                        entityLib.restoreData(child, "Transparency")
                    end
                end
            end
        end
    end
end)

-- =================================================
--                   TAB: VISUALS                   --
-- =================================================

local visualsGroup = tabs.visuals:AddLeftGroupbox("Visuals")

-------------------------------------
--      VISUALS: WORLD GROUP  --
-------------------------------------

visualsGroup:AddToggle("removeFog_Toggle", { Text = "Remove Fog", Tooltip = false, Default = false })
visualsGroup:AddToggle("killerESP_Toggle", { Text = "Killer ESP", Tooltip = false })

local killerESPDepbox = visualsGroup:AddDependencyBox()

excludedKillersDropdown = killerESPDepbox:AddDropdown("excludedKillers_Dropdown", { Text = "Excluded Killers", Tooltip = false, Values = { "Alien", "Ao Oni", "Captain Zombie",
"Chucky", "Eyeless Jack", "Fishface", "Freddy Krueger", "Ghostface", "Granny", "Jack Torrance", "Jane", "Jason", "Jeff", "Leatherface", "Michael Myers", "Pennywise", "Pinhead",
"Rake", "Robot", "Slenderman", "Smile Dog", "Sonic.exe", "Tails Doll", "Wendigo", "Yeti", "Zombie", "Fuwatti", "Giant", "Evil Lawn Mower" }, Default = { "Giant", "Jane" }, Multi = true, Searchable = true })
killerESPDepbox:AddSlider("killerESPDistance_Slider", { Text = "Range", Tooltip = "How far away to highlight killers", Default = 150, Min = 100, Max = 1000, Suffix = " Studs", Rounding = 0 })
killerESPDepbox:AddLabel("ESP Color"):AddColorPicker("killerESPColor_ColorPicker",{ Title = "ESP Color", Default = Color3.fromRGB(255, 0, 0), Transparency = 0.5 })
killerESPDepbox:AddCheckbox("rainbowESPColor_Toggle", { Text = "Rainbow ESP Color" })
killerESPDepbox:AddToggle("toggleKillersNametags_Toggle", { Text = "Enable Name Tags" })

local killerNametagDepbox = killerESPDepbox:AddDependencyBox()

killerNametagDepbox:AddLabel("Name Tag Color"):AddColorPicker("killerNameTagColor_ColorPicker",{ Title = "Name Tag Color", Default = Color3.fromRGB(255, 255, 255), Transparency = nil })

killerNametagDepbox:AddCheckbox("rainbowNameTagColor_Toggle", { Text = "Rainbow Name Tag Color" })
killerNametagDepbox:AddSlider("textSize_Slider", { Text = "Text Size", Tooltip = false, Default = 15, Min = 10, Max = 50, Rounding = 0 })

visualsGroup:AddToggle("enableFOV_Toggle", { Text = "Enable FOV" })

local fieldOfViewDepbox = visualsGroup:AddDependencyBox()

fieldOfViewDepbox:AddSlider("fieldOfViewValue_Slider", { Text = "Value", Tooltip = false, Default = 80, Min = 80, Max = 120, Rounding = 0 })

killerESPDepbox:SetupDependencies({ { toggles.killerESP_Toggle, true } })
killerNametagDepbox:SetupDependencies({ { toggles.toggleKillersNametags_Toggle, true } })
fieldOfViewDepbox:SetupDependencies({ { toggles.enableFOV_Toggle, true } })

local fogConnections = {}
toggles.removeFog_Toggle:OnChanged(function(enabled)
    if enabled then
        entityLib.storeData(lighting, "FogColor")
        entityLib.storeData(lighting, "FogEnd")
        entityLib.storeData(lighting, "FogStart")

        local function removeFog()
            lighting.FogEnd = math.huge
            lighting.FogStart = 0
        end

        removeFog()

        -- Connect to property changes

        fogConnections.FogEnd = lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
            if toggles.removeFog_Toggle.Value and lighting.FogEnd ~= math.huge then
                lighting.FogEnd = math.huge
            end
        end)

        fogConnections.FogStart = lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
            if toggles.removeFog_Toggle.Value and lighting.FogStart ~= 0 then
                lighting.FogStart = 0
            end
        end)

    else
        -- Disconnect all property change listeners

        for _, conn in pairs(fogConnections) do
            if conn.Connected then
                conn:Disconnect()
            end
        end

        fogConnections = {}

        entityLib.restoreData(lighting, "FogColor")
        entityLib.restoreData(lighting, "FogEnd")
        entityLib.restoreData(lighting, "FogStart")
        
        entityLib.clearData(lighting, "FogColor")
        entityLib.clearData(lighting, "FogEnd")
        entityLib.clearData(lighting, "FogStart")
    end
end)

local killerESPToggle = toggles.killerESP_Toggle
local killerESPRangeSlider = options.killerESPDistance_Slider
local killerColorPicker = options.killerESPColor_ColorPicker
local nameTagColorPicker = options.killerNameTagColor_ColorPicker
local sizeSlider = options.textSize_Slider
local excludedKillersDropdown = options.excludedKillers_Dropdown

local espConnections = {}
local excludedKillers = { Giant = true, Jane = true, Tinsel = true, Chipper = true, Yeti = true, Keeps = true, Destroido = true }

local defaultTextSize = 15

local function clearESPForModel(model)
    if model:IsA("Model") then
        local highlight = model:FindFirstChild("_CelestialKillerESP")
        if highlight then
            highlight:Destroy()
        end

        local head = model:FindFirstChild("Head")
        if head then
            local billboardGui = head:FindFirstChild("_CelestialBillboard")
            if billboardGui then
                billboardGui:Destroy()
            end
        end
    end
end

local function clearESP(folder)
    for _, child in ipairs(folder:GetChildren()) do
        clearESPForModel(child)
    end
end

local function applyESP(folder)
    local hrp = getHRP()

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and not excludedKillers[child.Name] then
            local root = child:FindFirstChild("HumanoidRootPart")
            if root then
                local distance = entityLib.getEntityDistance(hrp, root)
                local maxDistance = killerESPRangeSlider.Value

                if distance <= maxDistance then
                    -- Highlight
                    
                    if not child:FindFirstChild("_CelestialKillerESP") then
                        local highlight = Instance.new("Highlight", child)
                        highlight.Name = "_CelestialKillerESP"
                        highlight.FillColor = killerColorPicker.Value
                        highlight.OutlineColor = killerColorPicker.Value
                        highlight.FillTransparency = killerColorPicker.Transparency
                    end

                    -- BillboardGui

                    local head = child:FindFirstChild("Head")
                    if head and not head:FindFirstChild("_CelestialBillboard") and toggles.toggleKillersNametags_Toggle.Value then
                        local billboardGui = Instance.new("BillboardGui", head)
                        billboardGui.Name = "_CelestialBillboard"
                        billboardGui.Size = UDim2.new(4, 0, 1, 0)
                        billboardGui.StudsOffset = Vector3.new(0, 2, 0)
                        billboardGui.Adornee = head
                        billboardGui.AlwaysOnTop = true

                        local textLabel = Instance.new("TextLabel", billboardGui)
                        textLabel.Size = UDim2.new(1, 0, 1, 0)
                        textLabel.BackgroundTransparency = 1
                        textLabel.Text = child.Name
                        textLabel.TextScaled = false
                        textLabel.TextColor3 = nameTagColorPicker.Value
                        textLabel.Font = Enum.Font.GothamBold
                        textLabel.TextSize = defaultTextSize
                    end
                else
                    -- Remove Highlight and Billboard if they exist and out of range

                    local highlight = child:FindFirstChild("_CelestialKillerESP")
                    if highlight then
                        highlight:Destroy()
                    end

                    local head = child:FindFirstChild("Head")
                    if head then
                        local billboardGui = head:FindFirstChild("_CelestialBillboard")
                        if billboardGui then
                            billboardGui:Destroy()
                        end
                    end
                end
            else
                warn("Killer model missing HumanoidRootPart:", child.Name)
            end
        end
    end
end

local shouldRunLiveUpdate = false
toggles.killerESP_Toggle:OnChanged(function(enabled)
    if enabled then
        shouldRunLiveUpdate = true

        -- Clear & reapply

        if killersFolder then
            clearESP(killersFolder)
            applyESP(killersFolder)
        end

        -- Disconnect previous connections

        for _, connection in pairs(espConnections) do
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end
        table.clear(espConnections)

        -- Reapply on new killers

        if killersFolder then
            espConnections["ChildAdded"] = killersFolder.ChildAdded:Connect(function()
                applyESP(killersFolder)
            end)

            espConnections["HealthCheck"] = runService.Heartbeat:Connect(function()
                for _, killer in pairs(killersFolder:GetChildren()) do
                    local humanoid = killer:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health <= 0 then
                        clearESP(killer)
                    end
                end
            end)
        end

        -- Update

        espConnections["LiveUpdate"] = task.spawn(function()
            while shouldRunLiveUpdate do
                local hrp = getHRP()
                if not hrp then task.wait(0.1); continue end

                for _, killer in ipairs(killersFolder:GetChildren()) do
                    if killer:IsA("Model") and not excludedKillers[killer.Name] then
                        local root = killer:FindFirstChild("HumanoidRootPart")
                        local head = killer:FindFirstChild("Head")
                        local humanoid = killer:FindFirstChildOfClass("Humanoid")

                        -- Alive check

                        if not humanoid or humanoid.Health <= 0 then
                            clearESPForModel(killer)
                            continue
                        end

                        if root then
                            local distance = entityLib.getEntityDistance(hrp, root)
                            local inRange = distance <= killerESPRangeSlider.Value

                            -- Highlight

                            local highlight = killer:FindFirstChild("_CelestialKillerESP")
                            if inRange and not highlight then
                                highlight = Instance.new("Highlight", killer)
                                highlight.Name = "_CelestialKillerESP"
                                highlight.FillColor = killerColorPicker.Value
                                highlight.OutlineColor = killerColorPicker.Value
                                highlight.FillTransparency = killerColorPicker.Transparency
                            elseif not inRange and highlight then
                                highlight:Destroy()
                            elseif highlight then
                                highlight.FillColor = killerColorPicker.Value
                                highlight.OutlineColor = killerColorPicker.Value
                                highlight.FillTransparency = killerColorPicker.Transparency
                            end

                            -- Billboard

                            if head and toggles.toggleKillersNametags_Toggle.Value then
                                local billboard = head:FindFirstChild("_CelestialBillboard")
                                if inRange and not billboard then
                                    billboard = Instance.new("BillboardGui", head)
                                    billboard.Name = "_CelestialBillboard"
                                    billboard.Size = UDim2.new(4, 0, 1, 0)
                                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                                    billboard.Adornee = head
                                    billboard.AlwaysOnTop = true

                                    local label = Instance.new("TextLabel", billboard)
                                    label.Size = UDim2.new(1, 0, 1, 0)
                                    label.BackgroundTransparency = 1
                                    label.Text = killer.Name
                                    label.TextScaled = false
                                    label.TextColor3 = nameTagColorPicker.Value
                                    label.Font = Enum.Font.GothamBold
                                    label.TextSize = defaultTextSize
                                elseif not inRange and billboard then
                                    billboard:Destroy()
                                elseif billboard then
                                    local label = billboard:FindFirstChildOfClass("TextLabel")
                                    if label then
                                        label.TextColor3 = nameTagColorPicker.Value
                                        label.TextSize = defaultTextSize
                                    end
                                end
                            elseif head then
                                local existing = head:FindFirstChild("_CelestialBillboard")
                                if existing then existing:Destroy() end
                            end
                        end
                    end
                end

                task.wait(0.1)
            end
        end)
    else
        shouldRunLiveUpdate = false

        if killersFolder then clearESP(killersFolder) end

        for _, connection in pairs(espConnections) do
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end
        table.clear(espConnections)
    end
end)

toggles.toggleKillersNametags_Toggle:OnChanged(function()
    local hrp = getHRP()
    if not hrp then return end

    for _, child in ipairs(killersFolder:GetChildren()) do
        if child:IsA("Model") and not excludedKillers[child.Name] and killerESPToggle.Value then
            local killerRoot = child:FindFirstChild("HumanoidRootPart")
            if killerRoot then
                local distance = entityLib.getEntityDistance(hrp, killerRoot)
                if distance <= killerESPRangeSlider.Value then
                    -- Highlight

                    if not child:FindFirstChild("_CelestialKillerESP") then
                        local highlight = Instance.new("Highlight", child)
                        highlight.Name = "_CelestialKillerESP"
                        highlight.FillColor = killerColorPicker.Value
                        highlight.OutlineColor = killerColorPicker.Value
                        highlight.FillTransparency = killerColorPicker.Transparency
                    end

                    -- BillboardGui

                    local head = child:FindFirstChild("Head")
                    if head then
                        local existing = head:FindFirstChild("_CelestialBillboard")
                        if toggles.toggleKillersNametags_Toggle.Value then
                            if not existing then
                                local billboardGui = Instance.new("BillboardGui", head)
                                billboardGui.Name = "_CelestialBillboard"
                                billboardGui.Size = UDim2.new(4, 0, 1, 0)
                                billboardGui.StudsOffset = Vector3.new(0, 2, 0)
                                billboardGui.Adornee = head
                                billboardGui.AlwaysOnTop = true

                                local textLabel = Instance.new("TextLabel", billboardGui)
                                textLabel.Size = UDim2.new(1, 0, 1, 0)
                                textLabel.BackgroundTransparency = 1
                                textLabel.Text = child.Name
                                textLabel.TextScaled = false
                                textLabel.TextColor3 = nameTagColorPicker.Value
                                textLabel.Font = Enum.Font.GothamBold
                                textLabel.TextSize = defaultTextSize
                            end
                        elseif existing then
                            existing:Destroy()
                        end
                    end
                end
            end
        end
    end
end)


options.textSize_Slider:OnChanged(function(val) defaultTextSize = val end)

options.excludedKillers_Dropdown:OnChanged(function(val)
    excludedKillers = {}
    for name in pairs(val) do
        excludedKillers[name] = true
    end

    if killerESPToggle.Value then
        if killersFolder then
            clearESP(killersFolder)
            applyESP(killersFolder)
        end
    end
end)

toggles.rainbowESPColor_Toggle:OnChanged(function(enabled)
    toggleRainbow(enabled, "killerESPColor_ColorPicker")
end)

toggles.rainbowNameTagColor_Toggle:OnChanged(function(enabled)
    toggleRainbow(enabled, "killerNameTagColor_ColorPicker")
end)

toggles.enableFOV_Toggle:OnChanged(function(enabled)
    if enabled then
        entityLib.storeData(camera, "FieldOfView", true)
        camera.FieldOfView = options.fieldOfViewValue_Slider.Value
    else
        entityLib.restoreData(camera, "FieldOfView")
    end
end)

options.fieldOfViewValue_Slider:OnChanged(function(val)
    local fovEnabled = toggles.enableFOV_Toggle.Value

    if fovEnabled then
        camera.FieldOfView = val
    end
end)

-- =================================================
--                   TAB: WORLD                   --
-- =================================================

local worldGroup = tabs.world:AddLeftGroupbox("World")
local unlockAlienGroup = tabs.world:AddRightGroupbox("Alien")

-------------------------------------
--      WORLD: WORLD GROUP  --
-------------------------------------

worldGroup:AddToggle("disableCactuses_Toggle", { Text = "Disable Cactuses", Tooltip = false })
worldGroup:AddToggle("removeBearTraps_Toggle", { Text = "Remove Bear Traps", Tooltip = false })
worldGroup:AddToggle("disableRadioactiveZone_Toggle", { Text = "Disable Radioactive Damage", Tooltip = false })

local radioactiveZoneDepbox = worldGroup:AddDependencyBox()

radioactiveZoneDepbox:AddToggle("removeBarriers_Toggle", { Text = "Remove Barriers", Tooltip = false })
radioactiveZoneDepbox:AddToggle("removeEntrance_Toggle", { Text = "Remove Entrance", Tooltip = false })
radioactiveZoneDepbox:AddToggle("disableRadioactiveFog_Toggle", { Text = "Disable Fog", Tooltip = false })
radioactiveZoneDepbox:AddDivider()

worldGroup:AddToggle("disableKillParts_Toggle", { Text = "Disable Kill Parts", Tooltip = "Disables the fans/spinners, etc." })

radioactiveZoneDepbox:SetupDependencies({ { toggles.disableRadioactiveZone_Toggle, true } })

toggles.disableCactuses_Toggle:OnChanged(function(enabled)
    for _, cactus in pairs(area51.Outside.Cactus:GetDescendants()) do
        if cactus:IsA("BasePart") then
            cactus.CanTouch = not enabled
        end
    end
end)

toggles.removeBearTraps_Toggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.removeBearTraps_Toggle.Value do
                
                    for _, bearTrap in ipairs(game:GetService("Workspace"):GetChildren()) do
                        if bearTrap:IsA("BasePart") and bearTrap.Name == "BearTrap" then
                            bearTrap:Destroy()
                            print("Destroyed bear trap.")
                        end
                    end

                task.wait(0.1)
            end
        end)
    end
end)

toggles.disableRadioactiveZone_Toggle:OnChanged(function(enabled)
    -- disable damage

    for _, obj in ipairs(area51.RadioactiveArea:GetChildren()) do
        if obj.Name == "Entrance" and obj:IsA("BasePart") then
            obj.CanTouch = not enabled
        end
    end

    -- disable color change

    if enabled then
        local script = area51.RadioactiveArea.RadioactiveDrop.Drops:FindFirstChild("Color change")

        if script then
            script.Parent = game:GetService("Teams")
        end
    else
        local script = game:GetService("Teams"):FindFirstChild("Color change")

        if script then
            script.Parent = area51.RadioactiveArea.RadioactiveDrop.Drops
        end
    end
end)

toggles.removeBarriers_Toggle:OnChanged(function(enabled)
    if enabled then
        for _, barriers in ipairs(area51.RadioactiveArea.Floor1.Barrier:GetChildren()) do
            barriers.Parent = game:GetService("Chat")
        end
    else
        for _, barriers in ipairs(game:GetService("Chat"):GetChildren()) do
            barriers.Parent = area51.RadioactiveArea.Floor1.Barrier
        end
    end
end)

toggles.removeEntrance_Toggle:OnChanged(function(enabled)
    if enabled then
        for _, entrance in ipairs(area51.RadioactiveArea.Floor1.Entrance:GetChildren()) do
            entrance.Parent = game:GetService("Lighting")
        end

        for _, dirt in ipairs(area51.RadioactiveArea.Floor1.Dirt:GetChildren()) do
            dirt.Parent = game:GetService("StarterGui")
        end
    else
        for _, entrance in ipairs(game:GetService("Lighting"):GetChildren()) do
            entrance.Parent = area51.RadioactiveArea.Floor1.Entrance
        end

        for _, dirt in ipairs(game:GetService("StarterGui"):GetChildren()) do
            dirt.Parent = area51.RadioactiveArea.Floor1.Dirt
        end
    end
end)

toggles.disableRadioactiveFog_Toggle:OnChanged(function(enabled)
    area51.RadioactiveArea.RadioactiveDrop.Part.Smoke.Enabled = not enabled
end)

local function getKillParts()
    local parts = {
        area51.CentralSewerRoom.Spinner.Kill,
        area51.GarbageSewer.KillTop,
        area51.SewerCaptainRoom.Spinner.Kill,
        area51.TrashGrindRoom.Spinner.Kill,
        area51.WasteRoom.Spinner.Kill,
        area51.MaterialOrdererRoom.GreenThing
    }

    for _, deathPart in ipairs(area51.WasteRoom["Polluted Water"]["Toxic Water"]:GetChildren()) do
        if deathPart:IsA("BasePart") and deathPart.Name == "Kill" then
            table.insert(parts, deathPart)
        end
    end

    for _, deathPart in ipairs(area51.MultiDirectionalRoom.Deadly:GetChildren()) do
        if deathPart:IsA("BasePart") then
            table.insert(parts, deathPart)
        end
    end

    return parts
end

local function highlightPart(part)
    if part:FindFirstChild("_CelestialKillPartESP") then return end

    local highlight = Instance.new("Highlight", part)
    highlight.Name = "_CelestialKillPartESP"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
end

local function removeHighlight(part)
    local highlight = part:FindFirstChild("_CelestialKillPartESP")
    if highlight then
        highlight:Destroy()
    end
end

local function storeKillParts()
    for _, part in ipairs(getKillParts()) do
        entityLib.storeData(part, "CanTouch", true)
        entityLib.storeData(part, "CanCollide", true)
        entityLib.storeData(part, "Transparency", true)
    end
end

local function setKillPartState(part, enabled)
    if not part:IsA("BasePart") then return end

    if enabled then
        entityLib.storeData(part, "CanTouch", true)
        entityLib.storeData(part, "CanCollide", true)
        entityLib.storeData(part, "Transparency", true)

        part.CanTouch = false
        part.CanCollide = true
        part.Transparency = 0

        highlightPart(part)
    else
        entityLib.restoreData(part, "CanTouch")
        entityLib.restoreData(part, "CanCollide")
        entityLib.restoreData(part, "Transparency")

        removeHighlight(part)
    end
end

storeKillParts()

toggles.disableKillParts_Toggle:OnChanged(function(enabled)
    local killParts = getKillParts()

    for _, part in ipairs(killParts) do
        setKillPartState(part, enabled)
    end
end)


-------------------------------------
--      WORLD: ALIEN GROUP  --
-------------------------------------

local alienCode = area51.CodeModel.Code.Value

unlockAlienGroup:AddLabel("Code: " .. alienCode, true)
unlockAlienGroup:AddToggle("viewAlienCode_Toggle", { Text = "View Code", Tooltip = false })
unlockAlienGroup:AddDropdown("codeRevealMethod_Dropdown", { Text = "Code Reveal Method", Tooltip = false, Values = { "Announce", "Silent" }, Default = 2, Multi = false, Searchable = false })

unlockAlienGroup:AddButton({ Text = "Reveal Code",
    Func = function()
        local method = options.codeRevealMethod_Dropdown.Value

        if method == "Announce" then
            utils.sendMessage("The alien code is " .. alienCode)
        else
            notify("Alien code", "The alien code is " .. alienCode, options.silentModeNotifDuration_Slider.Value)
        end
    end,
})

unlockAlienGroup:AddSlider("silentModeNotifDuration_Slider", { Text = "Notification Time", Tooltip = "Controls how long the notification will last when using 'Silent.'", Default = 15, Min = 5, Max = 30, Compact = true, Suffix = " Seconds", Rounding = 0 })

unlockAlienGroup:AddButton({ Text = "Code Input",
    Func = function()
        entityLib.teleport(CFrame.new(137.72377, 333.499939, 525.566956))
    end,
})

unlockAlienGroup:AddButton({ Text = "Alien Door",
    Func = function()
        entityLib.teleport(CFrame.new(226.598221, 333.499939, 472.223358))
    end,
})

toggles.viewAlienCode_Toggle:OnChanged(function(enabled)
    if enabled then
        camera.CameraSubject = area51.CodeModel
    else
        local hum = getHumanoid()
        camera.CameraSubject = hum
    end
end)

localplayer.CharacterAdded:Connect(function(char)
	if toggles.viewAlienCode_Toggle.Value then
        toggles.viewAlienCode_Toggle:SetValue(false)
	end
end)

-- =================================================
--                   TAB: WEAPONS                   --
-- =================================================

local weaponsGroup = tabs.weapons:AddLeftGroupbox("Weapons")
local papRequirementsGroup = tabs.weapons:AddRightGroupbox("Pack A Punch Requirements")
local defenseGroup = tabs.weapons:AddLeftGroupbox("Defense")
local othersGroup = tabs.weapons:AddRightGroupbox("Other")

-------------------------------------
--      WEAPONS: WEAPONS GROUP  --
-------------------------------------

local weaponNames = {}

for _, weapon in ipairs(game:GetService("Workspace").Weapons:GetChildren()) do
    table.insert(weaponNames, weapon.Name)
end

local extraWeapons = { "Crossbow", "MG42", "FreezeGun" }
for _, name in ipairs(extraWeapons) do
    if not table.find(weaponNames, name) then
        table.insert(weaponNames, name)
    end
end

weaponsGroup:AddDropdown("weaponsList_Dropdown", { Text = "Obtain Weapon(s)", Tooltip = false, Values = weaponNames, Default = nil, Multi = true, Searchable = true,
    Callback = function(val)
        local selectedNames = {}
        for name, isSelected in pairs(val) do
            if isSelected then
                table.insert(selectedNames, name)
            end
        end

        if #selectedNames == 0 then
            giveWeaponBtn:SetText("Obtain Weapon")
            papWeaponBtn:SetText("Pack a Punch Weapon")
            return
        end

        local displayLimit = 2
        if #selectedNames > displayLimit then
            local shown = table.concat({ unpack(selectedNames, 1, displayLimit) }, ", ")
            local extra = #selectedNames - displayLimit
            giveWeaponBtn:SetText("Obtain " .. shown .. ", +" .. extra .. " more")
            papWeaponBtn:SetText("Pack a Punch  " .. shown .. ", +" .. extra .. " more")
        else
            giveWeaponBtn:SetText("Obtain " .. table.concat(selectedNames, ", "))
            papWeaponBtn:SetText("Pack a Punch " .. table.concat(selectedNames, ", "))
        end
    end,
})

weaponsGroup:AddDropdown("giveWeaponMethod_Dropdown", { Text = "Method", Tooltip = false, Values = { "Normal", "Alternative" }, Default = 1, Multi = false, Searchable = false })

local function obtainSelectedWeapons()
	local selected = options.weaponsList_Dropdown.Value
	local anySelected = false
	local hrp = getHRP()

	local alreadyHave = {}
	local givenWeapons = {}
	local weaponsToGive = {}

	for weaponName, isSelected in pairs(selected) do
		if isSelected then
			if restrictedWeapons[weaponName] then
				notify("Error", weaponName .. " cannot be given and can only be pack a punched due to requirements/gamepasses.", 14)
			else
				anySelected = true

				local hasBase = entityLib.getTool("Specific", weaponName)
				local hasPAP = entityLib.getTool("Specific", "PAP" .. weaponName)

				if hasBase or hasPAP then
					table.insert(alreadyHave, weaponName)
				else
					local weapon = game.Workspace.Weapons:FindFirstChild(weaponName)

					if weapon and weapon:FindFirstChild("Hitbox") then
						table.insert(weaponsToGive, weapon)
					else
						notify("Error", weaponName .. " is missing or has no available hitbox.", 13)
					end
				end
			end
		end
	end

	local method = options.giveWeaponMethod_Dropdown.Value
	for _, weapon in ipairs(weaponsToGive) do
		if method == "Normal" then
			utils.fireTouchEvent(hrp, weapon.Hitbox)
		else
			weapon.Hitbox.CanCollide = false

			local origCFrame = entityLib.storeData(hrp, "CFrame")

			entityLib.teleport(weapon.Hitbox)
			task.wait(0.01)

			entityLib.restoreData(hrp, "CFrame")
			entityLib.clearData(hrp, "CFrame")

			weapon.Hitbox.CanCollide = true
		end
	end

	for _, weapon in ipairs(weaponsToGive) do
		repeat task.wait() until entityLib.getTool("Specific", weapon.Name)
		table.insert(givenWeapons, weapon.Name)
	end

	if #alreadyHave > 0 then
		notify("Error", "You already have the following weapons: " .. table.concat(alreadyHave, ", "), 8)
	end

	if #givenWeapons > 0 then
		notify("Success", "You have been given the following weapons: " .. table.concat(givenWeapons, ", "), 5)
		if toggles.clearOnAction_Toggle.Value then
			options.weaponsList_Dropdown:SetValue({})
		end
	end

	if not anySelected then
		notify("Error", "No weapons selected.", 8)
	end
end

giveWeaponBtn = weaponsGroup:AddButton({ Text = "Obtain Weapon",
    Func = function()
        obtainSelectedWeapons()
    end,
})

local function pap(weaponName, selectedWeapons, currentIndex)
	-- Weapon check

	if not entityLib.getTool("Specific", weaponName) then
		notify("Error", "You don't have " .. weaponName .. " in your inventory. Skipping...", 6)
		return false
	end

	-- Kill requirements

	local requirements = require(game:GetService("StarterPlayer").StarterPlayerScripts.LocalAnimations["Classic area"].Teleportation.PackAPunch["Classic mode"].Requirements)
	local requiredKills = requirements[weaponName]
	local kills = game:GetService("Players").LocalPlayer.leaderstats["Killers Killed"].Value

	if requiredKills and kills < requiredKills then
		local needed = requiredKills - kills
		notify("Error", weaponName .. " requires " .. requiredKills .. " kills to pack a punch. You need " .. needed .. " more.", 7)
		return false
	end

    local hrp = getHRP()

	-- Teleport to control panel

    freeze(true)
	entityLib.teleport(CFrame.new(110.864708, 313.499969, 72.9767151))
    repeat task.wait(0.09) until entityLib.checkTeleport(hrp, CFrame.new(110.86470794677734, 313.4999694824219, 72.97671508789062), 5)
	--task.wait(0.15)

	-- Fire teleport prompt

	utils.fireProxPrompt(area51.TeleporterRoom.Teleporter["Control Panels"].Middle.Teleport)
    notify("Working..", "Teleporting in progress...\nPack a punching the " .. weaponName .. "...", 11)

	-- Confirm teleport has started

	local displayLabel = area51.TeleporterRoom.Teleporter["Control Panels"].Middle.Displayer.SurfaceGui.Frame.TextLabel
    repeat task.wait() until string.find(displayLabel.Text, "Teleporting" )
    notify("Working..", "Correct teleport.\nPack a punching the " .. weaponName .. "...", 12)

	-- Teleport inside teleporter

	local inside = area51.TeleporterRoom.Teleporter.Teleporter.Inside
	inside.CanCollide = false
	entityLib.teleport(CFrame.new(111.216148, 315.700012, 41.9078827))

	local punchRoomCFrame = CFrame.new(109.300003, 335.499969, 62)
	repeat task.wait() until entityLib.checkTeleport(hrp, punchRoomCFrame, 5)
    notify("Working..", "Teleport finished.\nPack a punching the " .. weaponName .. "...", 9)

	-- PAP weapon

	game:GetService("Workspace").PACKAPUNCH.PAPStarted:FireServer(weaponName)
	game:GetService("Workspace").PACKAPUNCH.PAPFinished:FireServer()
    notify("Success", weaponName .. " has been pack a punched!", 7)

    -- Notify remaining queue

    if selectedWeapons and currentIndex then
        local remaining = {}
        for i = currentIndex + 1, #selectedWeapons do
            table.insert(remaining, selectedWeapons[i])
        end

        if #remaining > 0 then
            notify("Info", "Remaining in queue (" .. #remaining .. "): " .. table.concat(remaining, ", "), 26)
        end
    end

    freeze(false)

	return true
end

papWeaponBtn = weaponsGroup:AddButton({ Text = "Pack a Punch Weapon",
    Func = function()
        papWeaponBtn:SetDisabled(true)
        papHeldBtn:SetDisabled(true)

        local player = game:GetService("Players").LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")

        local died = false
        local deathConnection = humanoid.Died:Connect(function()
            died = true
            notify("Error", "You died during Pack-a-Punch. Process stopped.", 7)
            papWeaponBtn:SetDisabled(false)
            papHeldBtn:SetDisabled(false)
        end)

        task.spawn(function()
            local requirements = require(game:GetService("StarterPlayer").StarterPlayerScripts.LocalAnimations["Classic area"].Teleportation.PackAPunch["Classic mode"].Requirements)
            local kills = player.leaderstats["Killers Killed"].Value
            local selected = options.weaponsList_Dropdown.Value
            local selectedWeapons = {}

            for name, isSelected in pairs(selected) do
                if isSelected then
                    if entityLib.getTool("Specific", "PAP" .. name) then
                        notify("Info", "You already have PAP" .. name .. ". Skipping...", 5)
                    elseif string.sub(name, 1, 3) == "PAP" then
                        notify("Info", name .. " is already pack a punched. Skipping...", 5)
                    else
                        table.insert(selectedWeapons, name)
                    end
                end
            end

            local anyPunched = false

            for index, weaponName in ipairs(selectedWeapons) do
                if died then break end

                local hasBase = entityLib.getTool("Specific", weaponName)
                local hasPAP = entityLib.getTool("Specific", "PAP" .. weaponName)

                if not (hasBase or hasPAP) then
                    notify("Error", "You don't have " .. weaponName .. ". Cannot pack a punch.", 6)
                else
                    local requiredKills = requirements[weaponName] or 0
                    if kills < requiredKills then
                        notify("Error", "Not enough kills to pack a punch " .. weaponName .. ". Need " .. (requiredKills - kills) .. " more kills.", 6)
                    else
                        repeat
                            if died then break end
                            if teleporterInUse() then
                                local pending = {}
                                for i = index, #selectedWeapons do
                                    table.insert(pending, selectedWeapons[i])
                                end
                                notify("Waiting", "Teleporter in use. Waiting to pack a punch: " .. table.concat(pending, ", "), 4)
                            end
                            task.wait(2)
                        until not teleporterInUse() or died

                        if died then break end
                        local success = pap(weaponName, selectedWeapons, index)
                        if success then
                            anyPunched = true
                        else
                            notify("Error", "Failed to pack a punch " .. weaponName, 5)
                            break
                        end

                        local hrp = getHRP()
                        local returnCFrame = CFrame.new(219.199997, 323.500061, 845.900024, 1, 0, 0, 0, 1, 0, 0, 0, 1)
                        repeat task.wait() until entityLib.checkTeleport(hrp, returnCFrame, 5) or died
                    end
                end
            end

            if not died then
                if anyPunched then
                    notify("Success", "All selected weapons have been pack a punched!", 6)
                    if toggles.clearOnAction_Toggle.Value then
                        options.weaponsList_Dropdown:SetValue({})
                    end
                else
                    notify("Info", "No weapons were pack a punched.", 6)
                end

                papWeaponBtn:SetDisabled(false)
                papHeldBtn:SetDisabled(false)
            end

            deathConnection:Disconnect()
        end)
    end,
})

papHeldBtn = weaponsGroup:AddButton({ Text = "Pack a Punch Held Weapon",
	Func = function()
		local heldWeapon = tostring(entityLib.getTool("Held"))
		if not heldWeapon then
			notify("Error", "You're not holding a weapon.", 5)
			return
		end

		papWeaponBtn:SetDisabled(true)
		papHeldBtn:SetDisabled(true)

		local player = game:GetService("Players").LocalPlayer
		local char = player.Character or player.CharacterAdded:Wait()
		local humanoid = char:WaitForChild("Humanoid")

		local died = false
		local deathConnection = humanoid.Died:Connect(function()
			died = true
			notify("Error", "You died during Pack-a-Punch. Process stopped.", 7)
			papWeaponBtn:SetDisabled(false)
			papHeldBtn:SetDisabled(false)
		end)

		task.spawn(function()
			if died then return end

			local success = pap(heldWeapon)
			if success and not died then
				local hrp = getHRP()
				local returnCFrame = CFrame.new(219.199997, 323.500061, 845.900024)
				repeat task.wait() until entityLib.checkTeleport(hrp, returnCFrame, 5) or died

				if not died then
					notify("Success", heldWeapon .. " has been pack a punched!", 6)
					if toggles.clearOnAction_Toggle.Value then
						options.weaponsList_Dropdown:SetValue({})
					end
				end
			end

			if not died then
				papWeaponBtn:SetDisabled(false)
				papHeldBtn:SetDisabled(false)
			end

			deathConnection:Disconnect()
		end)
	end,
})

weaponsGroup:AddButton({ Text = "Select All Weapons",
    Func = function()
        local allWeapons = options.weaponsList_Dropdown.Values
        local selection = {}

        for _, weaponName in ipairs(allWeapons) do
            if not restrictedWeapons[weaponName] then
                selection[weaponName] = true
            end
        end

        options.weaponsList_Dropdown:SetValue(selection)
    end,
})

weaponsGroup:AddButton({ Text = "Clear Selection",
    Func = function()
        options.weaponsList_Dropdown:SetValue(nil)
    end,
})

weaponsGroup:AddToggle("fireOnRespawn_Toggle", { Text = "Fire On Respawn", Tooltip = "Automatically gives the selected weapons after you respawn.", Default = false })

localplayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if toggles.fireOnRespawn_Toggle.Value then
		obtainSelectedWeapons()
	end
end)


weaponsGroup:AddToggle("clearOnAction_Toggle", { Text = "Clear on Action", Tooltip = "Clears the selected weapons when you obtain, pack a punch it, etc.", Default = false })
weaponsGroup:AddLabel("Due to recent updates, you can only pack a punch one weapon per teleporter usage. Meaning one weapon can be pack a punched for each teleport.", true)
local teleporterStateLabel = weaponsGroup:AddLabel("Teleporter: " .. getTeleporterState(), true)

local isUpdatingTeleporterState = true
task.spawn(function()
	while isUpdatingTeleporterState do
		teleporterStateLabel:SetText("Teleporter: " .. getTeleporterState())
		task.wait(0.1)
	end
end)

-------------------------------------
--      WEAPONS: PAP REQUIREMENTS GROUP  --
-------------------------------------

local papRequirements = require(game:GetService("StarterPlayer").StarterPlayerScripts.LocalAnimations["Classic area"].Teleportation.PackAPunch["Classic mode"].Requirements)

local textLines = {}
for weapon, killsRequired in pairs(papRequirements) do
    table.insert(textLines, weapon .. ": " .. killsRequired .. " kills")
end

table.sort(textLines) -- Sort alphabetically

local labelText = table.concat(textLines, "\n")
local papLabel = papRequirementsGroup:AddLabel(labelText, true)

-------------------------------------
--      WEAPONS: DEFENSE GROUP  --
-------------------------------------

defenseGroup:AddToggle("zombieMorph_Toggle", { Text = "Zombie Morph", Tooltip = false })

local zombieMorphDepbox = defenseGroup:AddDependencyBox()

zombieMorphDepbox:AddToggle("disableSelfGlow_Toggle", { Text = "Disable Self Glow", Tooltip = "Disables the green glow from you only." })

defenseGroup:AddToggle("obtainArmor_Toggle", { Text = "Obtain Armor", Tooltip = false })

zombieMorphDepbox:SetupDependencies({ { toggles.zombieMorph_Toggle, true } })

toggles.zombieMorph_Toggle:OnChanged(function(enabled)
    if enabled then
        local hrp = getHRP()
        utils.fireTouchEvent(hrp, area51.Outside.Hangar.Right["Zombie Morph"].TheButton)
    end
end)

toggles.disableSelfGlow_Toggle:OnChanged(function(enabled)
    local glow = localplayer.Character.Chest.Torso:FindFirstChildOfClass("PointLight")

    if glow then
        glow.Enabled = not enabled
    end
end)

toggles.obtainArmor_Toggle:OnChanged(function(enabled)
    if enabled then
        local hrp = getHRP()
        utils.fireTouchEvent(hrp, area51.Amory2Room.Armory.Giver)
    end
end)

localplayer.CharacterAdded:Connect(function(char)
    local hrp = getHRP()
    task.wait(0.5)

    if toggles.zombieMorph_Toggle.Value then
        local disableSelfGlowEnabled = toggles.disableSelfGlow_Toggle.Value

        utils.fireTouchEvent(hrp, area51.Outside.Hangar.Right["Zombie Morph"].TheButton)

        if disableSelfGlowEnabled then
            print("waiting for chest")
            local chest
            repeat
                task.wait()
                chest = localplayer.Character:FindFirstChild("Chest")
            until chest
            print("found chest")

            print("waiting for torso")
            local torso
            repeat
                task.wait()
                torso = chest:FindFirstChild("Torso")
            until torso

            print("waiting for glow")
            local glow
            repeat
                task.wait()
                glow = torso:FindFirstChildOfClass("PointLight")
            until glow
            print("found glow")

            glow.Enabled = false
            print("disabled glow")
        end
    end

    if toggles.obtainArmor_Toggle.Value then
        utils.fireTouchEvent(hrp, area51.Amory2Room.Armory.Giver)
    end
end)

-------------------------------------
--      WEAPONS: OTHERS GROUP  --
-------------------------------------

othersGroup:AddToggle("autoReloadWeapons_Toggle", { Text = "Auto Reload", Tooltip = false })
othersGroup:AddButton({ Text = "Give Office Card",
    Func = function()
        local hrp = getHRP()
        utils.fireTouchEvent(hrp, area51.AdminRoom.Table.Card)
    end,
})

local autoReloadDepbox = othersGroup:AddDependencyBox()

autoReloadDepbox:AddSlider("autoReloadDelay_Slider", { Text = "Delay", Tooltip = false, Default = 1, Min = 0.5, Max = 10, Suffix = " Second", Rounding = 1,
    Callback = function(val)
        options.autoReloadDelay_Slider:SetSuffix(getSuffix(options.autoReloadDelay_Slider, "Second"))
    end
})

autoReloadDepbox:SetupDependencies({ { toggles.autoReloadWeapons_Toggle, true } })

toggles.autoReloadWeapons_Toggle:OnChanged(function(enabled)
    -- Disable sound

    local reloadSound = game:GetService("SoundService").AmmoReload
    reloadSound.Volume = enabled and 0 or 1
    
    task.spawn(function()
        while toggles.autoReloadWeapons_Toggle.Value do

            local hrp = getHRP()
            utils.fireTouchEvent(hrp, area51.PlantRoom["Box of Shells"].Box)

            task.wait(options.autoReloadDelay_Slider.Value)
        end
    end)
end)

-- =================================================
--                   TAB: MISCELLANEOUS                   --
-- =================================================

local killersGroup = tabs.misc:AddLeftGroupbox("Killers")
local othersGroup2 = tabs.misc:AddRightGroupbox("Others")

-------------------------------------
--      MISCELLANEOUS: KILLERS GROUP  --
-------------------------------------


local proximityRange = 30

killersGroup:AddToggle("disableAllKillers_Toggle", { Text = "Disable Aura", Tooltip = "Breaks the movement for all NEARBY killers within the specified amount of studs." })

local disableKillersDepbox = killersGroup:AddDependencyBox()

disableKillersDepbox:AddSlider("disableKillersDistance_Slider", { Text = "Range", Tooltip = "How far away to disable killers", Default = 30, Min = 10, Max = 150, Suffix = " Studs", Rounding = 0 })

killersGroup:AddToggle("killerGodmode_Toggle", { Text = "Killer Godmode", Tooltip = "Makes you invincible to the killers by blocking killer interactions." })

local killerGodmodeDepbox = killersGroup:AddDependencyBox()

killerGodmodeDepbox:AddToggle("antiPinhead_Toggle", { Text = "Anti Pinhead", Tooltip = "Disables (mostly) disables Pinhead's spikes that he expels upon death." })
killerGodmodeDepbox:AddLabel("Some killers can NOT be disabled due to the killer's attack or damage being serversided. These killers are: Alien, Fishface, Robot, and Eyeless Jack (spit)", true)

killersGroup:AddToggle("antiSlendermanJumpscare", { Text = "Anti Slenderman Jumpscare", Tooltip = false })

killerGodmodeDepbox:SetupDependencies({ { toggles.killerGodmode_Toggle, true } })
disableKillersDepbox:SetupDependencies({ { toggles.disableAllKillers_Toggle, true } })

local frozenKillers = {}
toggles.disableAllKillers_Toggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.disableAllKillers_Toggle.Value do
                local player = game.Players.LocalPlayer
                local hrp = getHRP()
                if not hrp then task.wait(0.5); continue end

                for _, model in pairs(killersFolder:GetChildren()) do
                    if model:IsA("Model") then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        local root = model:FindFirstChild("HumanoidRootPart")
                        if hum and root then
                            local distance = entityLib.getEntityDistance(hrp, root)

                            if distance <= proximityRange then
                                if not frozenKillers[hum] then
                                    if not entityLib.isStored(hum, "WalkSpeed") then
                                        entityLib.storeData(hum, "WalkSpeed")
                                    end
                                    hum.WalkSpeed = 0
                                    frozenKillers[hum] = true
                                end
                            else
                                if frozenKillers[hum] then
                                    entityLib.restoreData(hum, "WalkSpeed")
                                    frozenKillers[hum] = nil
                                end
                            end
                        end
                    end
                end

                task.wait(0.2)
            end
        end)
    else
        for _, model in pairs(killersFolder:GetChildren()) do
            if model:IsA("Model") then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                    entityLib.restoreData(hum, "WalkSpeed")
                    entityLib.clearData(hum, "WalkSpeed")
                end
            end
        end
        frozenKillers = {}
    end
end)

options.disableKillersDistance_Slider:OnChanged(function(val)
    proximityRange = val
end)

toggles.killerGodmode_Toggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.killerGodmode_Toggle.Value do
                for _, model in pairs(killersFolder:GetChildren()) do
                    if model:IsA("Model") then
                        for _, descendant in ipairs(model:GetDescendants()) do
                            if descendant:IsA("TouchTransmitter") then
                                descendant:Destroy()
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end)

local pinheadConnection
toggles.antiPinhead_Toggle:OnChanged(function(enabled)
    if enabled and not pinheadconnection then
        pinheadconnection = runService.Heartbeat:Connect(function()
            for _, obj in ipairs(game:GetService("Workspace"):GetChildren()) do
                if obj:IsA("Model") then
                    for _, spike in ipairs(obj:GetChildren()) do
                        if spike:IsA("BasePart") and spike.Name == "Spike" then
                            spike:Destroy()
                        end
                    end
                end
            end
        end)
    elseif not enabled and pinheadconnection then
        pinheadconnection:Disconnect()
        pinheadconnection = nil
    end
end)

toggles.antiSlendermanJumpscare:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.antiSlendermanJumpscare.Value do
                local gui = localplayer:FindFirstChild("PlayerGui"):FindFirstChild("Slender")
                local slenderman = game:GetService("Workspace"):FindFirstChild("Killers") and game:GetService("Workspace").Killers:FindFirstChild("Slenderman")
                
                if slenderman and gui then
                    gui.Enabled = false

                    local deathSound = slenderman:FindFirstChild("HumanoidRootPart") and slenderman.HumanoidRootPart:FindFirstChild("SlenderTouch")
                    if deathSound then
                        deathSound:Stop()
                    end
                end

                task.wait()
            end
        end)
    end
end)

-------------------------------------
--      MISCELLANEOUS: OTHERS GROUP  --
-------------------------------------

othersGroup2:AddToggle("weaponSpam_Toggle", { Text = "Weapon Spam", Tooltip = false })
othersGroup2:AddButton({ Text = "Teleport to Security Cameras",
    Func = function()
        entityLib.teleport(game:GetService("Workspace")["Surveillance Cameras"].Triggers.Seat)
    end,
})

toggles.weaponSpam_Toggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.weaponSpam_Toggle.Value do
                local totalTools = entityLib.getTool("Count")
                local backpackTools = localplayer.Backpack:GetChildren()

                if totalTools < 3 then
                    notify("Error", "You must have at least 3 weapons.", 8)
                    toggles.weaponSpam_Toggle:SetValue(false)
                    return
                end

                for i = 1, totalTools do
                    if not toggles.weaponSpam_Toggle.Value then
                        break
                    end

                    local tool = backpackTools[i]
                    if tool and tool:IsA("Tool") then
                        entityLib.equipTool(tool.Name, true)
                        task.wait() -- Equip delay

                        if not toggles.weaponSpam_Toggle.Value then
                            break
                        end

                        entityLib.equipTool(nil, false)
                        task.wait() -- Unequip delay
                    end
                end

                task.wait()
            end

            if entityLib.getTool("Held") then
                entityLib.equipTool(nil, false)
            end
        end)
    end
end)






-- =================================================
--                   TAB: UI SETTINGS                   --
-- =================================================

local menuGroup = tabs.uiSettings:AddLeftGroupbox("Menu")

menuGroup:AddToggle("KeybindMenuOpen", { Text = "Open Keybind Menu", Default = window.keybindFrameEnabled, Disabled = false, Callback = function(enabled) library.KeybindFrame.Visible = enabled end })
menuGroup:AddToggle("autoResetColor_Toggle", { Text = "Auto Reset Color", Tooltip = "Resets the colorpicker color back to its default color once a rainbow toggle is disabled.", Default = true,
    Callback = function(Value) window.autoResetRainbowColor = Value end })
menuGroup:AddToggle("notifSound_Toggle", { Text = "Notification Alert Sounds", Tooltip = false, Default = true, Callback = function(enabled) window.notifSoundEnabled = enabled end })

local notifSoundDepbox = menuGroup:AddDependencyBox()

local notifAlertVolume_Slider = notifSoundDepbox:AddSlider("notifAlertVolumeSlider", { Text = "Alert Volume", Tooltip = false, Default = 1, Min = 0.1, Max = 6, Rounding = 1 })
notifSoundDepbox:SetupDependencies({ { toggles.notifSound_Toggle, true } })

menuGroup:AddDropdown("NotificationSide", { Text = "Notification Side", Values = { "Left", "Right" }, Default = "Right", Callback = function(Value) library:SetNotifySide(Value) end })
menuGroup:AddDropdown("DPIDropdown", { Text = "DPI Scale", Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%",
	Callback = function(val)
		val = val:gsub("%%", "")
		local DPI = tonumber(val)

		library:SetDPIScale(DPI)
	end,
})

local rainbowSpeed_Slider = menuGroup:AddSlider("rainbowSpeed_Slider", { Text = "Rainbow Speed", Tooltip = false, Default = window.rainbowSpeed, Min = 0.1, Max = 1, Rounding = 1 })
menuGroup:AddLabel("Menu bind"):AddKeyPicker("menuKeybind_KeyPicker", { Text = "Menu keybind", Default = "RightControl", NoUI = true })

local function unloadModules()
	local modules = { "killerGodmode_Toggle", "disableAllKillers_Toggle", "toggleKillersNametags_Toggle", "killerESP_Toggle", "removeFog_Toggle", "toggleNoclip_Toggle", "toggleFly_Toggle", "doorNoclip_Toggle",
    "enableNoclip_Toggle", "enableFly_Toggle", "speedExploit_Toggle", "autoRefill_Toggle", "autoDrink_Toggle", "rainbowESPColor_Toggle", "rainbowNameTagColor_Toggle" }

	for _, moduleName in ipairs(modules) do
		if toggles[moduleName] and toggles[moduleName].Value == true then
			toggles[moduleName]:SetValue(false)
		end
	end

	if not isScriptReloadable then
		shared.scriptLoaded = false
	end

    rainbowConnections = nil
	hues = nil
    isUpdatingTeleporterState = false
end

-- Handle any case were the interface is destroyed abruptly

for _, newUI in pairs(gethui():GetDescendants()) do
	if newUI:IsA("ScreenGui") then
		if newUI.Name == "Obsidian" then
			task.spawn(function()
				newUI.AncestryChanged:Connect(function(_, parent)
					if not parent then
						unloadModules()
                        library:Unload()
					end
				end)
			end)
		end
	end
end

menuGroup:AddButton({ Text = "Unload", DoubleClick = true, Func = function() library:Unload() unloadModules() end })

library.ToggleKeybind = options.menuKeybind_KeyPicker

notifAlertVolume_Slider:OnChanged(function(val) window.alertVolume = val end)
rainbowSpeed_Slider:OnChanged(function(val) window.rainbowSpeed = val end)

themeManager:SetLibrary(library)
saveManager:SetLibrary(library)
saveManager:IgnoreThemeSettings()
saveManager:SetIgnoreIndexes({ "menuKeybind_KeyPicker" })
themeManager:SetFolder("Celestial ScriptHub")
saveManager:SetFolder("Celestial ScriptHub/Survive and Kill the Killers in Area 51")
saveManager:SetSubFolder("Classic - Normal")
saveManager:BuildConfigSection(tabs.uiSettings)
themeManager:ApplyToTab(tabs.uiSettings)
saveManager:LoadAutoloadConfig()