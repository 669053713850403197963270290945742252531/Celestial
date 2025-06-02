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

local function isLibEnabled(library)
    local libraryRefs = {
        auth = auth,
        executionLib = executionLib,
        entityLib = entityLib,
        utils = utils
    }

    if typeof(libraryRefs[library]) ~= "table" then
        --warn(library .. " did not return a table.")
        return false
    end

    return true
end

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local runService = game:GetService("RunService")

local window = library:CreateWindow({
    Title = "Celestial",
    Footer = "Survive and Kill the Killers in Area 51: " .. gameName .. " - v1.0.0",
    Center = true,
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.RightShift,
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
    visuals = window:AddTab("Visuals", "globe"),
    weapons = window:AddTab("Weapons", "swords"),
    gui = window:AddTab("User Interface", "monitor"),
	misc = window:AddTab("Miscellaneous", "circle-ellipsis"),
	uiSettings = window:AddTab("UI Settings", "settings"),
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
    if isLibEnabled("entityLib") then
        return entityLib.getCharInstance("HumanoidRootPart") or nil
    else
        notify("Error", "Entity Library not loaded.", 100)
        return "Error"
    end
end

local function getHumanoid()
    if isLibEnabled("entityLib") then
        return entityLib.getCharInstance("Humanoid") or nil
    else
        notify("Error", "Entity Library not loaded.", 100)
        return "Error"
    end
end

local function isAlive()
    if entityLib.isAlive() then
        return true
    end

    return false
    --if not entityLib.isAlive() then return end
end

-- =================================================
--                   TAB: HOME                   --
-- =================================================

local infoTabBox = tabs.home:AddLeftTabbox()
local playerTab = infoTabBox:AddTab("Player")

local respawnButton_Toggle = playerTab:AddToggle("toggleRespawn_Toggle", { Text = "Respawn Button", Tooltip = false, Default = true })

playerTab:AddLabel("Name: " .. localplayer.DisplayName .. " (@" .. localplayer.Name .. ")", true)
playerTab:AddLabel("UserId: " .. localplayer.UserId, true)
playerTab:AddLabel("Mouse Lock Permitted: " .. tostring(localplayer.DevEnableMouseLock), true)
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

if isLibEnabled("auth") and isLibEnabled("executionLib") then
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

teleportGroup:AddDropdown("regularLocationsList_Dropdown", { Text = "Teleport", Tooltip = false, Values = {"Surface", "Area 51", "Alien", "Alien Code Input",
"Pack A Punch Machine", "Obtain Armor", "Ammo Box", "Zombie Morpher", "Radioactive Zone"}, Default = 1 })
teleportGroup:AddButton({ Text = "Teleport", Func = function()
        local cframeValues = {
            ["Surface"] = CFrame.new(326.087067, 511.699921, 392.975769, 0.999967098, 0, 0.00810976978, 0, 1, 0, -0.00810976978, 0, 0.999967098),
            ["Area 51"] = CFrame.new(327.146332, 313.499908, 369.922913, 0.0146765877, 0, 0.999892294, 0, 1, 0, -0.999892294, 0, 0.0146765877),
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

        if not isLibEnabled("entityLib") then
            notify("Error", "Entity Library not loaded.", 100)
            return
        end

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
    
    utils.fireProxPrompt(game.Workspace.AREA51.CafeRoom["Coffee Machine"].Energy.Head)
    
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

-- =================================================
--                   TAB: PLAYER                   --
-- =================================================

local movementGroup = tabs.player:AddLeftGroupbox("Movement")

tabs.player:UpdateWarningBox({ Title = "Warning", Text = "Due to Roblox's physics limitations, high velocity speeds may cause unexpected falling on collisions.", Visible = true })

-------------------------------------
--      PLAYER: MOVEMENT GROUP  --
-------------------------------------

movementGroup:AddToggle("speedExploit_Toggle", { Text = "Speed Exploit", Tooltip = false, Default = false })

local speedExploitDepbox = movementGroup:AddDependencyBox()

speedExploitDepbox:AddDropdown("speedExploitMethod_Dropdown", { Text = "Method", Tooltip = false, Values = { "WalkSpeed", "Velocity" }, Default = 1 })
speedExploitDepbox:AddSlider("speedExploitAmount_Slider", { Text = "Amount", Tooltip = false, Default = 16, Min = 1, Max = 100, Rounding = 0 })

movementGroup:AddToggle("enableFly_Toggle", { Text = "Enable Fly" })

local flyDepbox = movementGroup:AddDependencyBox()

flyDepbox:AddToggle("toggleFly_Toggle", { Text = "Fly" })
:AddKeyPicker("fly_KeyPicker", { Text = "Fly", Default = "F", SyncToggleState = true, Mode = "Toggle", NoUI = false })

movementGroup:AddToggle("enableNoclip_Toggle", { Text = "Enable Noclip" })

local noclipDepbox = movementGroup:AddDependencyBox()

noclipDepbox:AddToggle("toggleNoclip_Toggle", { Text = "Noclip" })
:AddKeyPicker("noclip_KeyPicker", { Text = "Noclip", Default = "G", SyncToggleState = true, Mode = "Toggle", NoUI = false })

speedExploitDepbox:SetupDependencies({ { toggles.speedExploit_Toggle, true } })
flyDepbox:SetupDependencies({ { toggles.enableFly_Toggle, true } })
noclipDepbox:SetupDependencies({ { toggles.enableNoclip_Toggle, true } })

toggles.toggleFly_Toggle:OnChanged(function(enabled)
    local flyEnabled = toggles.enableFly_Toggle.Value

    if enabled and not flyEnabled then
        toggles.toggleFly_Toggle:SetValue(false)
        return
    end

    if flyEnabled then
        entityLib.toggleFly(enabled)
        entityLib.setFlySpeed(100, 100)
    else
        entityLib.toggleFly(false)
    end
end)

toggles.toggleNoclip_Toggle:OnChanged(function(enabled)
    local noclipEnabled = toggles.enableNoclip_Toggle.Value

    if enabled and not noclipEnabled then
        toggles.toggleNoclip_Toggle:SetValue(false)
        return
    end

    if noclipEnabled then
        entityLib.toggleNoclip(enabled)
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

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "SpeedExploitVelocity"
	bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = rootPart

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

-- =================================================
--                   TAB: VISUALS                   --
-- =================================================

local testGroup = tabs.visuals:AddLeftGroupbox("Groupbox")

-------------------------------------
--      VISUALS: TEST GROUP  --
-------------------------------------

-- module code here

-- =================================================
--                   TAB: WEAPONS                   --
-- =================================================

local testGroup2 = tabs.weapons:AddLeftGroupbox("Groupbox")

-------------------------------------
--      WEAPONS: TEST GROUP  --
-------------------------------------

-- module code here

-- =================================================
--                   TAB: USER INTERFACE                   --
-- =================================================

local testGroup3 = tabs.gui:AddLeftGroupbox("Groupbox")

-------------------------------------
--      USER INTERFACE: TEST GROUP  --
-------------------------------------

-- module code here

-- =================================================
--                   TAB: MISCELLANEOUS                   --
-- =================================================

local testGroup4 = tabs.misc:AddLeftGroupbox("Groupbox")

-------------------------------------
--      MISCELLANEOUS: TEST GROUP  --
-------------------------------------

-- module code here



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
menuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Text = "Menu keybind", Default = "RightShift", NoUI = true })

local function unloadModules()
	local modules = { "", "", "" }

	for _, moduleName in ipairs(modules) do
		if toggles[moduleName] then
			toggles[moduleName]:SetValue(false)
		end
	end

	if not isScriptReloadable then
		shared.scriptLoaded = false
	end

    rainbowConnections = nil
	hues = nil
end

-- Handle any case were the interface is destroyed abruptly

for _, newUI in pairs(gethui():GetDescendants()) do
	if newUI:IsA("ScreenGui") then
		if newUI.Name == "Obsidian" then
			task.spawn(function()
				newUI.AncestryChanged:Connect(function(_, parent)
					if not parent then
						unloadModules()
					end
				end)
			end)
		end
	end
end

menuGroup:AddButton({ Text = "Unload", DoubleClick = true, Func = function() library:Unload() unloadModules() end })
menuGroup:AddLabel("Menu bind"):AddKeyPicker("menuKeybind_KeyPicker", { Text = "Menu keybind", Default = "RightShift", NoUI = true })

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