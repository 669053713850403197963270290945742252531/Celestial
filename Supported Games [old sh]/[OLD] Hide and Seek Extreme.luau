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
local char = localplayer.Character or localplayer.CharacterAdded:Wait()
local camera = game:GetService("Workspace").CurrentCamera

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

local function onCharacterAdded(char)
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

local jumpPowerDepbox = movementGroup:AddDependencyBox()

jumpPowerDepbox:AddSlider("jumpPowerValue_Slider", { Text = "Value", Tooltip = false, Default = 50, Min = 50, Max = 400, Rounding = 0 })

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

localplayer.CharacterAdded:Connect(onCharacterAdded)

if localplayer.Character then
	onCharacterAdded(localplayer.Character)
else
	localplayer.CharacterAdded:Wait()
	onCharacterAdded(localplayer.Character)
end

-- =================================================
--                   TAB: EXPLOITS                   --
-- =================================================

local automationGroup = tabs.exploits:AddLeftGroupbox("Automation")

-------------------------------------
--      EXPLOITS: AUTOMATION GROUP  --
-------------------------------------

automationGroup:AddToggle("antiGlue_Toggle", { Text = "Anti Glue" })
automationGroup:AddToggle("collectCoins_Toggle", { Text = "Collect Coins" })

toggles.antiGlue_Toggle:OnChanged(function(enabled)
    if enabled then

        task.spawn(function()
            while toggles.antiGlue_Toggle.Value do

                for _, obj in pairs(game:GetService("Workspace").GameObjects:GetDescendants()) do
					if obj.Name == "GlueServer" and obj:IsA("BasePart") and obj.Color == Color3.fromRGB(248, 248, 248) then
						obj.CanTouch = false
					end
				end

                task.wait(0.1)
            end
        end)
	else
		for _, obj in pairs(game:GetService("Workspace").GameObjects:GetDescendants()) do
			if obj.Name == "GlueServer" and obj:IsA("BasePart") and obj.Color == Color3.fromRGB(248, 248, 248) then
				obj.CanTouch = true
			end
		end
    end
end)

toggles.collectCoins_Toggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.collectCoins_Toggle.Value do
                local hrp = getHRP()
                if hrp then
                    for _, obj in pairs(workspace.GameObjects:GetDescendants()) do
                        if obj.Name == "Credit" and obj:IsA("BasePart") and obj.Color == Color3.fromRGB(245, 205, 48) and obj:IsDescendantOf(workspace) then
                            utils.fireTouchEvent(hrp, obj)
                        end
                    end
                end
                task.wait(0.05)
            end
        end)
    end
end)

-- =================================================
--                   TAB: VISUALS                   --
-- =================================================

local visualsGroup = tabs.visuals:AddLeftGroupbox("Visuals")
local bypassesGroup = tabs.visuals:AddRightGroupbox("Bypasses")

-------------------------------------
--      VISUALS: VISUALS GROUP  --
-------------------------------------

visualsGroup:AddToggle("seekerESP_Toggle", { Text = "Seeker ESP" })
visualsGroup:AddToggle("hiderESP_Toggle", { Text = "Hider ESP" })
visualsGroup:AddToggle("coinESP_Toggle", { Text = "Coin ESP" })

local function getRole()
	if game:GetService("ReplicatedStorage").GameData.It.Value == localplayer.Name then
		return "Seeker"
	end

	return "Hider"
end

local espFolder = Instance.new("Folder")
espFolder.Name = "CelestialESP"
espFolder.Parent = game:GetService("CoreGui")

local function isCharAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function highlightTarget(targetModel, color, name)
	if not targetModel or not isCharAlive(targetModel) then return end
	if espFolder:FindFirstChild(name .. "_" .. targetModel.Name) then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = name .. "_" .. targetModel.Name
	highlight.Adornee = targetModel
	highlight.FillColor = color
	highlight.OutlineColor = Color3.new(0, 0, 0)
	highlight.OutlineTransparency = 0.5
	highlight.Parent = espFolder
end


local function removeHighlight(targetModel)
	for _, name in ipairs({"_CelestialSeekerESP", "_CelestialHiderESP"}) do
		local highlight = espFolder:FindFirstChild(name .. "_" .. targetModel.Name)
		if highlight then
			highlight:Destroy()
		end
	end
end

local function removeAllSeekerHighlights()
    local seekerObjectValue = game:GetService("ReplicatedStorage").GameData.It:FindFirstChild("PlayerObject")
    local seekerPlayer = seekerObjectValue and seekerObjectValue:IsA("ObjectValue") and seekerObjectValue.Value

    if seekerPlayer then
        local seekerChar = seekerPlayer.Character
        if seekerChar then
            removeHighlight(seekerChar)
        end
    end
end

local function removeAllHiderHighlights()
    local seekerObjectValue = game:GetService("ReplicatedStorage").GameData.It:FindFirstChild("PlayerObject")
    local seekerPlayer = seekerObjectValue and seekerObjectValue:IsA("ObjectValue") and seekerObjectValue.Value

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= seekerPlayer and player ~= localplayer then
            local char = player.Character
            if char then
                removeHighlight(char)
            end
        end
    end
end

local seekerTask
toggles.seekerESP_Toggle:OnChanged(function(enabled)
    if enabled then
        if seekerTask then return end
        seekerTask = task.spawn(function()
            while toggles.seekerESP_Toggle.Value do
                local seekerObjectValue = game:GetService("ReplicatedStorage").GameData.It:FindFirstChild("PlayerObject")
                local seekerPlayer = seekerObjectValue and seekerObjectValue:IsA("ObjectValue") and seekerObjectValue.Value

                if seekerPlayer and seekerPlayer ~= localplayer then
                    local seekerChar = seekerPlayer.Character
					if seekerChar and isCharAlive(seekerChar) then
						local existing = espFolder:FindFirstChild("_CelestialSeekerESP_" .. seekerChar.Name)
						if not existing then
							highlightTarget(seekerChar, Color3.fromRGB(255, 0, 0), "_CelestialSeekerESP")
						end
					else
						removeHighlight(seekerChar)
					end
                end

                task.wait(0.2)
            end
            seekerTask = nil
        end)
    else
        removeAllSeekerHighlights()
    end
end)

local hiderTask
toggles.hiderESP_Toggle:OnChanged(function(enabled)
    if enabled then
        if hiderTask then return end
        hiderTask = task.spawn(function()
            while toggles.hiderESP_Toggle.Value do
                local seekerObjectValue = game:GetService("ReplicatedStorage").GameData.It:FindFirstChild("PlayerObject")
                local seekerPlayer = seekerObjectValue and seekerObjectValue:IsA("ObjectValue") and seekerObjectValue.Value

                for _, player in ipairs(game.Players:GetPlayers()) do
                    if player ~= seekerPlayer and player ~= localplayer then
                        local char = player.Character
                        if char then
							local highlight = espFolder:FindFirstChild("_CelestialHiderESP_" .. char.Name)

							if isCharAlive(char) then
								if not highlight then
									highlightTarget(char, Color3.fromRGB(0, 255, 0), "_CelestialHiderESP")
								end
							else
								if highlight then
									highlight:Destroy()
								end
							end
                        end
                    end
                end

                task.wait(0.5)
            end
            hiderTask = nil
        end)
    else
        removeAllHiderHighlights()
    end
end)

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

camera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
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


miscGroup:AddButton({ Text = "Teleport to Safe Location",
    Func = function()
		if not isAlive() then return end

		entityLib.teleport(CFrame.new(305.8089294433594, 158.69802856445312, -20.035383224487305))
    end,
})

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
	local modules = { "" }

	for _, moduleName in ipairs(modules) do
		if toggles[moduleName] and toggles[moduleName].Value == true then
			toggles[moduleName]:SetValue(false)
		end
	end

	if not isScriptReloadable then
		shared.scriptLoaded = false
	end
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
saveManager:SetFolder("Celestial ScriptHub/Hide and Seek Extreme")
saveManager:BuildConfigSection(tabs.uiSettings)
themeManager:ApplyToTab(tabs.uiSettings)
saveManager:LoadAutoloadConfig()