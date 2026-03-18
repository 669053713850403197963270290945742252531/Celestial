while not game:IsLoaded() do task.wait() end

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
local runService = game:GetService("RunService")
local localplayer = utils.Services.LocalPlayer
local char = localplayer or localplayer.CharacterAdded:Wait()

local window = library:CreateWindow({
    Title = "Celestial",
    Footer = gameName .. " - v1.0.0",
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
    player = window:AddTab("Player", "circle-user-round"),
    exploits = window:AddTab("Exploits", "bug"),
    visuals = window:AddTab("Visuals", "eye"),
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
    return entityLib.getCharInstance("HumanoidRootPart") or nil
end

local function getHumanoid()
    return entityLib.getCharInstance("Humanoid") or nil
end

local humanoid = getHumanoid()
local hrp = getHRP()

local function isAlive()
    return entityLib.isAlive()
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

local function getHouse(self)
	local house = nil

	if self then
		for _, objValue in pairs(utils.Services.Workspace.Houses:GetDescendants()) do
			if objValue:IsA("ObjectValue") and objValue.Name == "Owner" and objValue.Value == utils.Services.LocalPlayer then
				house = objValue.Parent
				break
			end
		end

		if not house then
			notify("Error", "Failed to get own house.", 9)
			return nil
		end

		return house, house.CurrentUpgrade.Value
	end
end

local bodyVelocity, velocityConnection
local walkSpeedChangedConnection, bodyVelocityMonitorConnection

local function getCharacterParts()
	character = localplayer.Character or localplayer.CharacterAdded:Wait()
	humanoid = getHumanoid()
	hrp = getHRP()
end

local function monitorWalkSpeed()
	if walkSpeedChangedConnection then walkSpeedChangedConnection:Disconnect() end
	if not humanoid then return end

	walkSpeedChangedConnection = humanoid.Changed:Connect(function(prop)
		if prop == "WalkSpeed"
			and toggles.speedExploit_Toggle.Value
			and options.speedExploitMethod_Dropdown.Value == "WalkSpeed"
			and humanoid.WalkSpeed ~= options.speedExploitAmount_Slider.Value
		then
			humanoid.WalkSpeed = options.speedExploitAmount_Slider.Value
		end
	end)
end

local function enableVelocityMode(speed)
	if bodyVelocity then bodyVelocity:Destroy() end

	bodyVelocity = Instance.new("BodyVelocity", hrp)
	bodyVelocity.Name = "SpeedExploitVelocity"
	bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	bodyVelocity.Velocity = Vector3.zero

	if velocityConnection then velocityConnection:Disconnect() end
	velocityConnection = runService.RenderStepped:Connect(function()
		local moveDir = humanoid.MoveDirection
		bodyVelocity.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * speed or Vector3.zero
	end)
end

local function monitorBodyVelocity()
	if bodyVelocityMonitorConnection then bodyVelocityMonitorConnection:Disconnect() end
	if not bodyVelocity or not bodyVelocity:IsDescendantOf(hrp) then return end

	bodyVelocityMonitorConnection = runService.Stepped:Connect(function()
		if not bodyVelocity or not bodyVelocity:IsDescendantOf(hrp) then
			enableVelocityMode(options.speedExploitAmount_Slider.Value)
		end
	end)
end

local function disableVelocityMode()
	if velocityConnection then velocityConnection:Disconnect() end
	if bodyVelocity then bodyVelocity:Destroy() end
	if bodyVelocityMonitorConnection then bodyVelocityMonitorConnection:Disconnect() end
	if walkSpeedChangedConnection then walkSpeedChangedConnection:Disconnect() end

	velocityConnection = nil
	bodyVelocity = nil
	bodyVelocityMonitorConnection = nil
	walkSpeedChangedConnection = nil
end

local function applySpeed()
	if not humanoid or not hrp then getCharacterParts() end

	local enabled = toggles.speedExploit_Toggle.Value
	local method = options.speedExploitMethod_Dropdown.Value
	local speed = options.speedExploitAmount_Slider.Value

	if not enabled then
		disableVelocityMode()
		humanoid.WalkSpeed = 16
		return
	end

	if method == "WalkSpeed" then
		disableVelocityMode()
		humanoid.WalkSpeed = speed
		monitorWalkSpeed()
	else
		humanoid.WalkSpeed = 16
		enableVelocityMode(speed)
		monitorBodyVelocity()
	end
end

-- Handling respawns

local function onCharacterAdded1(char)
	if not char then return end

	task.spawn(function()
		character = char

		-- Wait for both humanoid and HRP to exist
		humanoid = char:WaitForChild("Humanoid", 5)
		hrp = char:WaitForChild("HumanoidRootPart", 5)

		if not humanoid or not hrp then return end

		task.wait(0.1) -- allow game to settle before reapplying

		if toggles.speedExploit_Toggle.Value then
			applySpeed()
		end

		if toggles.toggleFly_Toggle.Value and toggles.enableFly_Toggle.Value then
			entityLib.toggleFly(true)
			entityLib.setFlySpeed(options.flyHorizSpeed_Slider.Value, options.flyVertSpeed_Slider.Value)
		end

		if toggles.toggleNoclip_Toggle.Value and toggles.enableNoclip_Toggle.Value then
			entityLib.toggleNoclip(true)
		end
	end)
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
--                   TAB: PLAYER                   --
-- =================================================

local movementGroup = tabs.player:AddLeftGroupbox("Movement")

-------------------------------------
--      PLAYER: MOVEMENT GROUP  --
-------------------------------------

movementGroup:AddToggle("speedExploit_Toggle", { Text = "Speed Exploit", Tooltip = false, Default = false })

local speedExploitDepbox = movementGroup:AddDependencyBox()

speedExploitDepbox:AddDropdown("speedExploitMethod_Dropdown", { Text = "Method", Tooltip = false, Values = { "WalkSpeed", "Velocity" }, Default = 1 })
speedExploitDepbox:AddSlider("speedExploitAmount_Slider", { Text = "Amount", Tooltip = false, Default = 100, Min = 16, Max = 200, Rounding = 0 })
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
movementGroup:AddToggle("autoBacktrack_Toggle", { Text = "Backtrack", Tooltip = "Automatically teleports you back to your last death location." })

local jumpPowerDepbox = movementGroup:AddDependencyBox()

jumpPowerDepbox:AddSlider("jumpPowerValue_Slider", { Text = "Value", Tooltip = false, Default = 60, Min = 60, Max = 400, Rounding = 0 })

speedExploitDepbox:SetupDependencies({ { toggles.speedExploit_Toggle, true } })
flyDepbox:SetupDependencies({ { toggles.enableFly_Toggle, true } })
noclipDepbox:SetupDependencies({ { toggles.enableNoclip_Toggle, true } })
jumpPowerDepbox:SetupDependencies({ { toggles.enableJumpPower_Toggle, true } })

local backtrackCFrame
local function connectDied(humanoid)
    humanoid.Died:Connect(function()
        if toggles.autoBacktrack_Toggle.Value then
            local hrp = getHRP()
            backtrackCFrame = hrp.CFrame
            entityLib.storeData(hrp, "CFrame", true)

            if entityLib.isStored(hrp, "CFrame") then
                --print("stored cframe")
            end
        else
            --print("toggle disabled. not storing.")
        end

        toggles.autoBacktrack_Toggle:SetDisabled(true)
    end)
end

if localplayer.Character then
    local humanoid = getHumanoid()
    if humanoid then
        connectDied(humanoid)
    end
end

localplayer.CharacterAdded:Connect(function(char)
	task.wait(0.1)
    local humanoid = getHumanoid()
    if humanoid then
        connectDied(humanoid)
    end

    if backtrackCFrame then
    	print("valid cframe")
        entityLib.teleport(backtrackCFrame)
        backtrackCFrame = nil
    end

    toggles.autoBacktrack_Toggle:SetDisabled(false)
end)

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

toggles.toggleFly_Toggle:OnChanged(function(enabled)
	local flyAllowed = toggles.enableFly_Toggle.Value

	if enabled and not flyAllowed then
		toggles.toggleFly_Toggle:SetValue(false)
		return
	end

	if enabled and toggles.speedExploit_Toggle.Value and options.speedExploitMethod_Dropdown.Value == "Velocity" then
		options.speedExploitMethod_Dropdown:SetValue("WalkSpeed")
		options.speedExploitAmount_Slider:SetValue(options.speedExploitAmount_Slider.Max)
		notify("Fly is incompatible with Velocity", "Speed Exploit has been changed to WalkSpeed.", 10)
	end

	entityLib.toggleFly(flyAllowed and enabled or false)
	entityLib.setFlySpeed(flyHorizSpeed_Slider.Value, flyVertSpeed_Slider.Value)
end)

local function handleNoclipToggle(enabled)
	local allowed = toggles.enableNoclip_Toggle.Value
	if not allowed and enabled then
		toggles.toggleNoclip_Toggle:SetValue(false)
		return
	end
	entityLib.toggleNoclip(enabled and allowed)
end

toggles.toggleNoclip_Toggle:OnChanged(handleNoclipToggle)

options.flyHorizSpeed_Slider:OnChanged(function()
	entityLib.setFlySpeed(flyHorizSpeed_Slider.Value, flyVertSpeed_Slider.Value)
end)

options.flyVertSpeed_Slider:OnChanged(function()
	entityLib.setFlySpeed(flyHorizSpeed_Slider.Value, flyVertSpeed_Slider.Value)
end)

toggles.speedExploit_Toggle:OnChanged(applySpeed)
options.speedExploitAmount_Slider:OnChanged(applySpeed)

options.speedExploitMethod_Dropdown:OnChanged(function()
	local method = options.speedExploitMethod_Dropdown.Value

	if method == "Velocity" and toggles.toggleFly_Toggle.Value then
		options.speedExploitMethod_Dropdown:SetValue("WalkSpeed")
		notify("Velocity Speed is incompatible with Fly", "Speed Exploit has been changed to WalkSpeed.", 10)
	end
	applySpeed()
end)

-- Reapplying

localplayer.CharacterAdded:Connect(onCharacterAdded1)

if localplayer.Character then
	onCharacterAdded1(localplayer.Character)
else
	localplayer.CharacterAdded:Wait()
	onCharacterAdded1(localplayer.Character)
end

-- =================================================
--                   TAB: EXPLOITS                   --
-- =================================================

local automationGroup = tabs.exploits:AddLeftGroupbox("Automation")

-------------------------------------
--      EXPLOITS: AUTOMATION GROUP  --
-------------------------------------



local pizzasCountLabel = automationGroup:AddLabel("Is Pizzas: false (0)", true)
automationGroup:AddToggle("autoCollect_Toggle", { Text = "Auto Collect", "Collects all pizzas and sodas." })
automationGroup:AddToggle("voidPizzas_Toggle", { Text = "Void Pizzas & Sodas", "Destroys all pizzas and sodas for ALL players." })

local runningPizzaLoop = true
local voidPizzaHRPOrigPos = nil
local isVoiding = false

local Players = utils.Services.Players
local localPlayer = Players.LocalPlayer
local char = nil
local hrp = nil

local function getHRP()
	if char then
		return char:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

-- returns (isPizzas: boolean, pizzaTools: table)
local function getPizzas()
	local pizzaTools = {}
	for _, child in ipairs(utils.Services.Workspace:GetChildren()) do
		if child:IsA("Tool") then
			table.insert(pizzaTools, child)
		end
	end
	return #pizzaTools > 0, pizzaTools
end

local function updatePizzaLabel()
	if not runningPizzaLoop then return end
	local isPizzas, pizzas = getPizzas()
	pizzasCountLabel:SetText("Pizzas: " .. tostring(isPizzas) .. " (" .. #pizzas .. ")")
end

local function getNextPizza()
	for _, child in ipairs(utils.Services.Workspace:GetChildren()) do
		if child:IsA("Tool") and child:FindFirstChild("Handle") then
			return child
		end
	end
	return nil
end



local function voidPizzas()
	if isVoiding then return end
	isVoiding = true

	local hrpNow = getHRP()
	if not hrpNow or not hrpNow.Parent then
		isVoiding = false
		return
	end

	if not voidPizzaHRPOrigPos then
		voidPizzaHRPOrigPos = hrpNow.CFrame
	end

	local voidCFrame = CFrame.new(-6.1, 3, -1116.9)

	while true do
		local pizza = getNextPizza()
		if not pizza then break end

		local handle = pizza:FindFirstChild("Handle") or pizza:WaitForChild("Handle", 1)
		if not handle then continue end

		-- Teleport to void position
		entityLib.teleport(voidCFrame)

		local startTime = tick()
		while not entityLib.checkTeleport(hrpNow, voidCFrame, 1) and tick() - startTime < 2 do
			task.wait(0.05)
			hrpNow = getHRP()
			if not hrpNow then break end
		end

		-- Fire touch event
		utils.fireTouchEvent(hrpNow, handle)
		print("VOIDING:", pizza.Name)

		-- Wait until it's removed from Workspace (max 4s)
		local pizzaStart = tick()
		while pizza.Parent == utils.Services.Workspace and tick() - pizzaStart < 4 do
			task.wait(0.05)
		end

		task.wait(0.1) -- avoid overloading server
	end

	-- Teleport back
	task.wait(0.1)
	if voidPizzaHRPOrigPos then
		entityLib.teleport(voidPizzaHRPOrigPos)
		voidPizzaHRPOrigPos = nil
	end

	isVoiding = false
end

local function onCharacterAdded2(character)
	char = character
	hrp = nil
	voidPizzaHRPOrigPos = nil  -- reset position so we don't use a dead one

	hrp = character:WaitForChild("HumanoidRootPart", 5)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			voidPizzaHRPOrigPos = nil
		end)
	end

	task.wait(0.1)
	updatePizzaLabel()

	if toggles.voidPizzas_Toggle.Value then
		voidPizzas()
	end
end

-- Update label on script start
updatePizzaLabel()

-- Clear any leftovers on respawn
utils.Services.Players.LocalPlayer.CharacterAdded:Connect(function(char)
	voidPizzaHRPOrigPos = nil -- prevent old teleport targets
	isVoiding = false

	char:WaitForChild("HumanoidRootPart", 5)
	task.wait(0.1)

	updatePizzaLabel()

	if toggles.voidPizzas_Toggle.Value then
		voidPizzas()
	end
end)

-- Update label + auto-void when a pizza appears
utils.Services.Workspace.ChildAdded:Connect(function(child)
	if runningPizzaLoop and child:IsA("Tool") then
		updatePizzaLabel()
		if toggles.voidPizzas_Toggle.Value then
			task.defer(voidPizzas)
		end
	end
end)

-- Update label when a pizza is removed
utils.Services.Workspace.ChildRemoved:Connect(function(child)
	if runningPizzaLoop and child:IsA("Tool") then
		updatePizzaLabel()
	end
end)

-- Manual toggle
toggles.voidPizzas_Toggle:OnChanged(function(enabled)
	if enabled then
		voidPizzas()
	end
end)

--[[

toggles.autoCollect_Toggle:OnChanged(function(enabled)
    if enabled then

        task.spawn(function()
            while toggles.autoCollect_Toggle.Value do

				local isPizzas, pizzas = getPizzas()

				if isPizzas then

				end

                task.wait(0.1)
            end
        end)
	else

    end
end)

]]

localPlayer.CharacterAdded:Connect(onCharacterAdded2)
if localPlayer.Character then
	onCharacterAdded2(localPlayer.Character)
end

-- =================================================
--                   TAB: VISUALS                   --
-- =================================================

local visualsGroup = tabs.visuals:AddLeftGroupbox("Visuals")
local bypassesGroup = tabs.visuals:AddRightGroupbox("Bypasses")

-------------------------------------
--      VISUALS: VISUALS GROUP  --
-------------------------------------



-------------------------------------
--      VISUALS: BYPASSES GROUP  --
-------------------------------------

bypassesGroup:AddToggle("disableCutscenes_Toggle", { Text = "Disable Cutscenes" })

toggles.disableCutscenes_Toggle:OnChanged(function(enabled)
	if enabled and isAlive() then
		entityLib.storeData(camera, "CameraSubject", true)

		local humanoid = getHumanoid()
		if humanoid then
			camera.CameraSubject = humanoid
		end
	else
		entityLib.restoreData(camera, "CameraSubject")
	end
end)

utils.Services.Camera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
	if toggles.disableCutscenes_Toggle.Value and isAlive() then
		local humanoid = getHumanoid()
		if humanoid and camera.CameraSubject ~= humanoid then
			camera.CameraSubject = humanoid
		end
	end
end)

-- =================================================
--                   TAB: MISCELLANEOUS                   --
-- =================================================

local miscGroup = tabs.misc:AddLeftGroupbox("Miscellaneous")

-------------------------------------
--      MISCELLANEOUS: MISCELLANEOUS GROUP  --
-------------------------------------

--[[

miscGroup:AddButton({ Text = "Get Own House", DoubleClick = false,
    Func = function()
		local house, upgrade = getHouse(true)

		print("house: ", tostring(house))
		print("house upgrade: ", tostring(upgrade))
		--notify("Info", tostring(getHouse(true)), 5)
    end,
})

]]

miscGroup:AddToggle("selfSpamDoor_Toggle", { Text = "Spam Own Door", "Spams the door to your own house." })

toggles.selfSpamDoor_Toggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.selfSpamDoor_Toggle.Value do
				
				local house, upgrade = getHouse(true)

				house[upgrade.Name].Doors.FrontDoorMain.ClickDetector.Detector:FireServer()

                task.wait(0.1)
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
	local modules = { "speedExploit_Toggle", "enableFly_Toggle", "toggleFly_Toggle", "enableNoclip_Toggle", "toggleNoclip_Toggle", "enableJumpPower_Toggle" }

	for _, moduleName in ipairs(modules) do
		if toggles[moduleName] and toggles[moduleName].Value == true then
			toggles[moduleName]:SetValue(false)
		end
	end

	if not isScriptReloadable then
		shared.scriptLoaded = false
	end

	runningPizzaLoop = false
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
saveManager:SetFolder("Celestial ScriptHub/Work at a Pizza Place")
saveManager:BuildConfigSection(tabs.uiSettings)
themeManager:ApplyToTab(tabs.uiSettings)
saveManager:LoadAutoloadConfig()






--[[

MODULES




FIRE MANAGER PROMPTS:

workspace.SuperDoodles2017.HumanoidRootPart.ManagerProximityPrompt










game:GetService("Players").LocalPlayer.Team.Name == "Manager"
]]