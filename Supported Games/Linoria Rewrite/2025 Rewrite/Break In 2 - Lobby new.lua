while not game:IsLoaded() do
    task.wait()
end

local isScriptReloadable = true

if not isScriptReloadable then
	if shared.scriptLoaded then return end
	shared.scriptLoaded = true
end

local linoria = loadstring(readfile("Celestial/Revamped UI Libraries/Linoria - Library.lua"))()
local themeManager = loadstring(readfile("Celestial/Revamped UI Libraries/Linoria - Theme Manager.lua"))()
local saveManager = loadstring(readfile("Celestial/Revamped UI Libraries/Linoria - Save Manager.lua"))()

local startTime
if getgenv().notifyLoad == true then
    startTime = tick()
end

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local remoteEvents = game:GetService("ReplicatedStorage").RemoteEvents

local options = linoria.Options
local toggles = linoria.Toggles

linoria.ShowToggleFrameInKeybinds = true

-------------------------------------
--      LINORIA  --
-------------------------------------

if auth then Title = "Celestial - " .. gameName .. " : " .. auth.currentUser.Identifier else Title = "Celestial - " .. gameName end

-- Solution to transparent fill on the cursor due to solara's shit drawing lib

local useCustomCursor = true

if identifyexecutor() == "Solara" then
    useCustomCursor = false
end

local window = linoria:CreateWindow({
	Title = Title,
	Center = true,
	AutoShow = true,
	Resizable = true,
	ShowCustomCursor = useCustomCursor,
	NotifySide = "Left",
	TabPadding = 8,
	MenuFadeTime = 0.2,
	RainbowSpeed = 0.1
})

window.autoResetRainbowColor = true
window.notifSoundEnabled = true
window.notifSoundPath = "Notification Main.mp3"
window.alertVolume = 1

local tabs = {
	home = window:AddTab("Home"),
	main = window:AddTab("Main"),
	gui = window:AddTab("GUI"),
	misc = window:AddTab("Misc"),
	config = window:AddTab("Config")
}

-- Function things

local defaults = {
	ESPColorPicker = Color3.new(1, 0, 0),
	NametagColorPicker = Color3.new(0, 1, 0),
	ChamsColorPicker = Color3.new(0, 0, 1)
}

local function notify(message, duration)
    if typeof(message) ~= "string" then
        linoria:Notify("Argument #1 (message) expected a string value but got a " .. typeof(message) .. " value.", 20)
        return
    end

    if duration ~= nil and typeof(duration) ~= "number" then
        linoria:Notify("Argument #2 (duration) expected a number value but got a " .. typeof(duration) .. " value.", 20)
        return
    end

    if duration == nil then
        duration = 5
    end

    if window.notifSoundEnabled then
        local notifSound = getgenv().assetLib.fetchAsset("Assets/Sounds/Notification Main.mp3", window.alertVolume)
		linoria:Notify(message, duration, notifSound)
	else
		linoria:Notify(message, duration)
    end
end

local rainbowConnections = {}
local hues = {}

local function toggleRainbow(enabled, colorPickerName)
	if enabled then
		if not rainbowConnections[colorPickerName] then
			hues[colorPickerName] = hues[colorPickerName] or 0
			rainbowConnections[colorPickerName] = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
				hues[colorPickerName] = (hues[colorPickerName] + deltaTime * window.RainbowSpeed) % 1

				if not options[colorPickerName] or not defaults[colorPickerName] then
					window.notifSoundPath = getgenv().assetLib.fetchAsset("Assets/Sounds/Notification Main.mp3")

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
				window.notifSoundPath = getgenv().assetLib.fetchAsset("Assets/Sounds/Notification Main.mp3")

				notify("Invalid colorpicker object and/or no valid default was found.", 99999)
				return
			else
				options[colorPickerName]:SetValueRGB(defaults[colorPickerName])
			end
		end
	end
end

local function getHRP()
    return getgenv().entityLib.getCharInstance("HumanoidRootPart") or nil
end

local function getHumanoid()
    local humanoid = getgenv().entityLib.getCharInstance("Humanoid")

    if not humanoid then
        return
    end

    return humanoid
end


-- =================================================
--                   TAB: HOME                   --
-- =================================================

local informationGroup = tabs.home:AddLeftGroupbox("Information")
local gameGroup = tabs.home:AddRightGroupbox("Game")

-------------------------------------
--      HOME: INFORMATION GROUP  --
-------------------------------------

informationGroup:AddDivider()

if auth and executionLib then
	informationGroup:AddLabel("Identifier: " .. auth.currentUser.Identifier)
	informationGroup:AddLabel("Rank: " .. auth.currentUser.Rank)
	informationGroup:AddLabel("Discord ID: " .. auth.currentUser.DiscordId)
	informationGroup:AddLabel("Executions: " .. executionLib.fetchExecutions())

	informationGroup:AddLabel("Executor: " .. identifyexecutor())
end

-------------------------------------
--      HOME: GAME GROUP  --
-------------------------------------

gameGroup:AddDivider()

gameGroup:AddLabel("Game Name: " .. gameName)
gameGroup:AddLabel("Server Instance: " .. game.JobId, true)
gameGroup:AddLabel("Place ID: " .. game.PlaceId)
gameGroup:AddLabel("Shift Lock Allowed: " .. tostring(localplayer.DevEnableMouseLock))

-- =================================================
--                   TAB: MAIN                   --
-- =================================================

local utilGroup = tabs.main:AddLeftGroupbox("Utilities")
local rolesGroup = tabs.main:AddRightGroupbox("Roles")

-------------------------------------
--      MAIN: UTILITIES GROUP  --
-------------------------------------

utilGroup:AddDivider()

local truckTeleportDisabled = false

if not getgenv().utils.checkFunction(firetouchinterest) then
    truckTeleportDisabled = true
end

utilGroup:AddDropdown("truckTeleport_Dropdown", { Values = { "Truck 1", "Truck 2"}, Searchable = false, Default = 1, Multi = false, Text = "Teleport to Truck", Tooltip = false, Disabled = truckTeleportDisabled, DisabledTooltip = "Your exploit does not support this feature."})

local teleportToTruck_Btn = utilGroup:AddButton({ Text = "Teleport", Tooltip = false, DoubleClick = false, Disabled = truckTeleportDisabled, DisabledTooltip = "Your exploit does not support this feature.",
	Func = function()
		local hrp = getHRP()
        local humanoid = getHumanoid()

        if humanoid.Sit then
            humanoid.Sit = false
            wait(1.5)
        end

        -- Get trucks

        local truck1 = false
        local truck2 = false
        
        for _, truckEnterPart in pairs(game.Workspace:GetChildren()) do
            if truckEnterPart.Name == "Part" and truckEnterPart:FindFirstChild("TouchInterest") and #truckEnterPart:GetChildren() == 1 then
               
                if truckEnterPart.Position == Vector3.new(87.43499755859375, 7.869999408721924, 108.88998413085938) then
                    truck1 = truckEnterPart
                elseif truckEnterPart.Position == Vector3.new(87.43499755859375, 7.869999408721924, 147.38998413085938) then
                    truck2 = truckEnterPart
                end

            end
        end

        -- Dropdown handling

        if options.truckTeleport_Dropdown.Value == "Truck 1" then
            local success, response = getgenv().utils.fireTouchEvent(hrp, truck1)
            print(success)
        elseif options.truckTeleport_Dropdown.Value == "Truck 2" then
            local success, response = getgenv().utils.fireTouchEvent(hrp, truck1)
            print(success)
        end
	end
})

-------------------------------------
--      MAIN: ROLES GROUP  --
-------------------------------------

rolesGroup:AddDivider()

rolesGroup:AddToggle("useCostume_Toggle", { Text = "Use Custome", Tooltip = false, Default = false })
rolesGroup:AddToggle("useKidHeight_Toggle", { Text = "Kid Height", Tooltip = false, Default = false })
rolesGroup:AddDropdown("role_Dropdown", { Values = { "The Hyper (Lollipop)", "The Sporty (Sports Drink)", "The Protecter (Bat)", "The Medic (MedKit)" }, Searchable = false, Default = 1, Multi = false, Text = "Role", Tooltip = false })

local updateRole_Btn = rolesGroup:AddButton({ Text = "Update Role", Tooltip = false, DoubleClick = false,
	Func = function()
        local basicRoleDropdownValue = options.roleDropdown.Value
        local useKidHeight = toggles.useKidHeightToggle.Value
        local useCostume = toggles.useCostumeToggle.Value

        if basicRoleDropdownValue == "The Hyper (Lollipop)" then
            remoteEvents.MakeRole:FireServer("Lollipop", useKidHeight, useCostume)
        elseif basicRoleDropdownValue == "The Sporty (Sports Drink)" then
            remoteEvents.MakeRole:FireServer("Bottle", useKidHeight, useCostume)
        elseif basicRoleDropdownValue == "The Protecter (Bat)" then
            remoteEvents.MakeRole:FireServer("Bat", useKidHeight, useCostume)
        elseif basicRoleDropdownValue == "The Medic (MedKit)" then
            remoteEvents.MakeRole:FireServer("MedKit", useKidHeight, useCostume)
        end
	end
})

-- =================================================
--                   TAB: GUI                   --
-- =================================================

local gameInterfaceGroup = tabs.gui:AddLeftGroupbox("Game Interface")

gameInterfaceGroup:AddDivider()

gameInterfaceGroup:AddToggle("disableBreakIn1Recap_Toggle", { Text = "Disable Break In 1 Recap", Tooltip = "Disables the Break In 1 recap button on the right center of the screen.", Default = false })
gameInterfaceGroup:AddToggle("toggleTheHuntMenu_Toggle", { Text = "The Hunt Event Menu", Tooltip = false, Default = false })

toggles.disableBreakIn1Recap_Toggle:OnChanged(function(enabled)
	local frame = localplayer.PlayerGui.RightMenu.RightMenu.RightMenu.RightMenu.BreakIn1

	if enabled then
		frame.Visible = false

		local connection
		connection = frame:GetPropertyChangedSignal("Visible"):Connect(function()
			if frame.Visible then
				toggles.disableBreakIn1Recap_Toggle:SetValue(not enabled)
				connection:Disconnect()
			end
		end)
	else
		frame.Visible = true
	end
end)

toggles.toggleTheHuntMenu_Toggle:OnChanged(function(enabled)
	local frame = localplayer.PlayerGui.BreakIn1ScreenHunt.BreakIn1ScreenHunt.BreakIn1ScreenHunt.Dialogue

	if enabled then
		frame.Visible = true

		local connection
		connection = frame:GetPropertyChangedSignal("Visible"):Connect(function()
			if not frame.Visible then
				toggles.toggleTheHuntMenu_Toggle:SetValue(not enabled)
				connection:Disconnect()
			end
		end)
	else
		frame.Visible = false
	end
end)

-- =================================================
--                   TAB: MISCELLANEOUS                   --
-- =================================================

local miscGroup = tabs.misc:AddLeftGroupbox("Miscellaneous")

miscGroup:AddDivider()

local rejoin_Btn = miscGroup:AddButton({ Text = "Rejoin", Tooltip = false, DoubleClick = true,
	Func = function()
		getgenv().utils.gameTeleport("Rejoin")

		notify("Rejoining server...\n" .. game.JobId, 100)
	end
})

--[[

miscGroup:AddDropdown("players_Dropdown", { Text = "Player Dropdown", Tooltip = "A list of all player's in the server.", SpecialType = "Player", ExcludeLocalPlayer = true,
	Callback = function(player)
		print("player:" .. tostring(player) .. " | type: " .. typeof(player))

        if typeof(player) == "Instance" then
            warn("player health: " .. player.Character.Humanoid.Health)
            warn("player is an Instance")
        end
	end
})

]]

-------------------------------------
--      LINORIA / CONFIG  --
-------------------------------------

linoria:SetWatermarkVisibility(true)

local frameTimer = tick()
local frameCounter = 0
local fps = 60

local watermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
    frameCounter += 1

    if (tick() - frameTimer) >= 1 then
        fps = frameCounter
        frameTimer = tick()
        frameCounter = 0
    end

    local stats = game:GetService("Stats")
    local network = stats and stats:FindFirstChild("Network")
    local serverStats = network and network:FindFirstChild("ServerStatsItem")

    local pingValue = "N/A"
    if serverStats then
        local success, result = pcall(function() return serverStats["Data Ping"]:GetValue() end)
        if success and typeof(result) == "number" then
            pingValue = math.floor(result)
        else
            print("Failed to retrieve ping value, result:", result)
        end
    else
        print("ServerStatsItem not found!")
    end

    linoria:SetWatermark(("Celestial | %s fps | %s ms"):format(math.floor(fps), pingValue))
end)


linoria:OnUnload(function()
	watermarkConnection:Disconnect()

	local rainbowConnections = nil
	local hues = nil

	if not isScriptReloadable then
		shared.scriptLoaded = false
	end

	linoria.Unloaded = true
end)

-- =================================================
--                   TAB: CONFIG                   --
-- =================================================

local menuGroup = tabs.config:AddLeftGroupbox("Menu")

Library.KeybindFrame.Visible = false

menuGroup:AddToggle("keybindMenu_Toggle", { Default = linoria.KeybindFrame.Visible, Text = "Keybind Menu", Disabled = true, Callback = function(enabled) linoria.KeybindFrame.Visible = enabled end })
menuGroup:AddToggle("customCursor_Toggle", { Text = "Custom Cursor", Default = useCustomCursor, Callback = function(enabled) linoria.ShowCustomCursor = enabled end })
menuGroup:AddToggle("autoResetRainbowColor_Toggle", { Text = "Auto Reset Color", Tooltip = "Resets the colorpicker color back to its default color once a rainbow toggle is disabled.", Default = true, Disabled = true, Callback = function(enabled) window.autoResetRainbowColor = enabled end })
menuGroup:AddToggle("executeOnTeleport_Toggle", { Text = "Execute on Teleport", Tooltip = "Runs the script when a game teleport is detected. Once the script is queued, it cannot be unqueued.", Default = false, Callback = function(enabled) end })
menuGroup:AddToggle("notifSound_Toggle", { Text = "Notification Alert Sounds", Tooltip = false, Default = true, Callback = function(enabled) window.notifSoundEnabled = enabled end })

local notifSoundDepbox = menuGroup:AddDependencyBox()

notifSoundDepbox:AddSlider("notifAlertVolumeSlider", { Text = "Alert Volume", Tooltip = false, Default = 1, Min = 0.1, Max = 6, Rounding = 1, Compact = false, HideMax = false })
notifSoundDepbox:SetupDependencies({ { toggles.notifSound_Toggle, true } })

menuGroup:AddDropdown("notifSide", { Values = { "Left", "Right" }, Searchable = false, Default = 1, Multi = false, Text = "Notification Side", Tooltip = "The side of the screen notifications will appear on." })
menuGroup:AddSlider("rainbowSpeedSlider", { Text = "Rainbow Speed", Tooltip = false, Default = 0.1, Min = 0.1, Max = 1, Rounding = 1, Compact = false, HideMax = true, Disabled = true, })

if getgenv().scriptQueued == nil then
    getgenv().scriptQueued = false
end

toggles.executeOnTeleport_Toggle:OnChanged(function(enabled)
    if enabled then
        if not getgenv().scriptQueued then
            queue_on_teleport([[
                loadstring(readfile("Celestial/Supported Games/Linoria Rewrite/2025 Rewrite/Break In 2 - Lobby new.lua"))()
            ]])
    
            --notify("Successfully queued script.", 5)
            getgenv().scriptQueued = true

            toggles.executeOnTeleport_Toggle.Disabled = true
        else
            notify("Script is already queued.", 6)
        end
    end
end)

options.notifAlertVolumeSlider:OnChanged(function(val)
	window.alertVolume = val
end)

options.notifSide:OnChanged(function(val)
	linoria.NotifySide = val
end)

options.rainbowSpeedSlider:OnChanged(function(val)
	window.RainbowSpeed = val
end)

local function unloadModules()
    local modules = { "disableBreakIn1Recap_Toggle", "toggleTheHuntMenu_Toggle" }

    for _, moduleName in ipairs(modules) do
        if toggles[moduleName] then
            toggles[moduleName]:SetValue(false)
        end
    end

	if not isScriptReloadable then
		shared.scriptLoaded = false
	end

    getgenv().assetLib = nil
    getgenv().utils = nil
    getgenv().entityLib = nil
    getgenv().auth = nil
    getgenv().executionLib = nil
end

menuGroup:AddDivider()
menuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
menuGroup:AddButton("Unload", function() linoria:Unload() unloadModules() end)

linoria.ToggleKeybind = options.MenuKeybind

-- Handle any case were the Linoria interface is destroyed abruptly

for _, newUI in pairs(gethui():GetDescendants()) do
    if newUI:IsA("ScreenGui") then
        if newUI.Name == "Linoria" then
            
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

themeManager:SetLibrary(linoria)
themeManager:SetFolder("Celestial ScriptHub")
themeManager:ApplyToTab(tabs.config)

saveManager:SetLibrary(linoria)
saveManager:IgnoreThemeSettings()
saveManager:SetIgnoreIndexes({ "MenuKeybind" })
saveManager:SetFolder("Celestial ScriptHub/Break In 2")
saveManager:SetSubFolder("Lobby")
saveManager:BuildConfigSection(tabs.config)
saveManager:LoadAutoloadConfig()

if getgenv().notifyLoad == true then
    local endTime = tick()
    local loadTime = getgenv().utils.round(endTime - startTime, 2)
	window.notifSoundPath = getgenv().assetLib.fetchAsset("Assets/Sounds/Notification Main.mp3")

    if loadTime >= 5 then
        notify("⚠️ Delayed execution.\nCelestial loaded in " .. loadTime .. " seconds.", 5)
    else
        notify("Celestial loaded in " .. loadTime .. " seconds.", 6)
    end
end

getgenv().fastLoad = nil
getgenv().testing = nil
getgenv().notifyLoad = nil
auth.clearStoredKey()