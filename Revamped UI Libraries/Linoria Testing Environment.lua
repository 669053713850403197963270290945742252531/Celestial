local isScriptReloadable = true

if not isScriptReloadable then
	if shared.scriptLoaded then return end
	shared.scriptLoaded = true
end

local assetLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Asset%20Library.lua?ref_type=heads"))()
assetLib.createAssets("Linoria")
assetLib.createAssets("Sounds")

local linoria = assetLib.fetchAsset("Assets/Library.lua")
local themeManager = assetLib.fetchAsset("Assets/Theme Manager.lua")
local saveManager = assetLib.fetchAsset("Assets/Save Manager.lua")

local scriptSettings = {
    fastLoad = true,
    testing = true,
}

if scriptSettings.testing then
    getgenv().script_key = "lQwkSPLnL29AIKCAxmWuQ91M0gzjPuUugJ0Xd"
    getgenv().notifyLoad = false
end

local startTime
if getgenv().notifyLoad == true then
    startTime = tick()
end

getgenv().script_key = getgenv().script_key or ""

local auth
local executionLib
if not scriptSettings.fastLoad then
    auth = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Authentication.lua?ref_type=heads"))()
    auth.trigger()

    if auth.kicked then
        return
    end

    executionLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Execution%20Library.lua?ref_type=heads"))()
end

local utils = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Core%20Utilities.lua?ref_type=heads"))()
local entityLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Entity%20Library.lua?ref_type=heads"))()
--local entityLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Entity%20Library.lua?ref_type=heads"))()

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

local Options = linoria.Options
local Toggles = linoria.Toggles

linoria.ShowToggleFrameInKeybinds = true

-------------------------------------
--      LINORIA  --
-------------------------------------

if auth then Title = "Celestial Test Environment - " .. auth.currentUser.Identifier else Title = "Celestial Test Environment" end
local window = linoria:CreateWindow({
	Title = Title,
	Center = true,
	AutoShow = true,
	Resizable = true,
	ShowCustomCursor = true,
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
        local notifSound = assetLib.fetchAsset("Assets/Sounds/Notification Main.mp3", window.alertVolume)
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

				if not Options[colorPickerName] or not defaults[colorPickerName] then
					window.notifSoundPath = assetLib.fetchAsset("Assets/Sounds/Notification Main.mp3")

					notify("Invalid colorpicker object and/or no valid default was found.", 99999)
					return
				else
					Options[colorPickerName]:SetValueRGB(Color3.fromHSV(hues[colorPickerName], 1, 1))
				end
			end)
		end
	else
		if rainbowConnections[colorPickerName] then
			rainbowConnections[colorPickerName]:Disconnect()
			rainbowConnections[colorPickerName] = nil
		end

		if window.autoResetRainbowColor then
			if not Options[colorPickerName] or not defaults[colorPickerName] then
				window.notifSoundPath = assetLib.fetchAsset("Assets/Sounds/Notification Main.mp3")

				notify("Invalid colorpicker object and/or no valid default was found.", 99999)
				return
			else
				Options[colorPickerName]:SetValueRGB(defaults[colorPickerName])
			end
		end
	end
end

-- =================================================
--                   TAB: HOME                   --
-- =================================================

local informationGroup = tabs.home:AddLeftGroupbox("Information")
local gameGroup = tabs.home:AddRightGroupbox("Game")

-------------------------------------
--      HOME: INFORMATION  --
-------------------------------------

if auth and executionLib then
	informationGroup:AddLabel("Identifier: " .. auth.currentUser.Identifier)
	informationGroup:AddLabel("Rank: " .. auth.currentUser.Rank)
	informationGroup:AddLabel("Discord ID: " .. auth.currentUser.DiscordId)
	informationGroup:AddLabel("Executions: " .. executionLib.fetchExecutions())

	informationGroup:AddLabel("Executor: " .. identifyexecutor())
end

-------------------------------------
--      HOME: GAME  --
-------------------------------------

gameGroup:AddLabel("Game Name: " .. gameName)
gameGroup:AddLabel("Server Instance: " .. game.JobId, true)
gameGroup:AddLabel("Place ID: " .. game.PlaceId)
gameGroup:AddLabel("Shift Lock Allowed: " .. tostring(localPlayer.DevEnableMouseLock))

-- =================================================
--                   TAB: MAIN                   --
-- =================================================

local leftGroupBox = tabs.main:AddLeftGroupbox("Groupbox")

-------------------------------------
--      MAIN: Groupbox  --
-------------------------------------

leftGroupBox:AddToggle("guyESP", { Text = "Bad Guy ESP", Tooltip = "Highlights all bad guys, obviously." })

local colorPickerDepbox = leftGroupBox:AddDependencyBox()

colorPickerDepbox:AddLabel("Color"):AddColorPicker("ESPColorPicker", { Title = "ESP Color", Default = defaults.ESPColorPicker, Transparency = 0.8 })
:AddColorPicker("NametagColorPicker", { Title = "Nametag Color", Default = defaults.NametagColorPicker, Transparency = 0 })
:AddColorPicker("ChamsColorPicker", { Title = "Chams Color", Default = defaults.ChamsColorPicker, Transparency = 0.5 })

colorPickerDepbox:AddToggle("rainbowESPToggle", { Text = "Rainbow ESP", Tooltip = false, Default = false })
colorPickerDepbox:AddToggle("rainbowNametagToggle", { Text = "Rainbow Nametag", Tooltip = false, Default = false })
colorPickerDepbox:AddToggle("rainbowChamsToggle", { Text = "Rainbow Chams", Tooltip = false, Default = false })

local GetStats = colorPickerDepbox:AddButton({ Text = "Get Colorpicker Stats", Tooltip = false, DoubleClick = false,
	Func = function()
		local ESPColorPicker = Options.ESPColorPicker

		notify("color: " .. tostring(ESPColorPicker.Value) .. "\ntransparency: " .. tostring(ESPColorPicker.Transparency), 12)
	end
})

Toggles.guyESP:OnChanged(function(enabled)
	print(enabled)
end)

Toggles.rainbowESPToggle:OnChanged(function(enabled)
	toggleRainbow(enabled, "ESPColorPicker")
end)

Toggles.rainbowNametagToggle:OnChanged(function(enabled)
	toggleRainbow(enabled, "NametagColorPicker")
end)

Toggles.rainbowChamsToggle:OnChanged(function(enabled)
	toggleRainbow(enabled, "ChamsColorPicker")
end)

Options.ESPColorPicker:OnChanged(function(color, alpha)
	print("color: ", tostring(color) .. " | alpha: " .. tostring(alpha))
end)

-- Setup depen

colorPickerDepbox:SetupDependencies({ { Toggles.guyESP, true } })

leftGroupBox:AddToggle("flyToggle", { Text = "Fly", Tooltip = "Enables the fly keybind.", Default = false })
:AddKeyPicker("flyKeybind", { Default = "F", SyncToggleState = false, Mode = "Toggle", Text = "Fly", NoUI = false,
	Callback = function(keybindState)
		local toggleEnabled = Toggles.flyToggle.Value

		if toggleEnabled then
			entityLib.toggleFly(keybindState)
			entityLib.setFlySpeed(Options.flyHorizontalSpeedSlider.Value, Options.flyVerticalSpeedSlider.Value)
		end
	end
})


leftGroupBox:AddSlider("flyHorizontalSpeedSlider", { Text = "Horizontal Speed", Tooltip = "How fast you fly in all directions.", Default = 50, Min = 10, Max = 300, Rounding = 1, Compact = false, HideMax = false, Visible = false })
leftGroupBox:AddSlider("flyVerticalSpeedSlider", { Text = "Vertical Speed", Tooltip = "How fast you fly ascending/descending.", Default = 30, Min = 5, Max = 150, Rounding = 1, Compact = false, HideMax = false, Visible = false })

Options.flyHorizontalSpeedSlider:OnChanged(function(val)
	entityLib.setFlySpeed(val, Options.flyVerticalSpeedSlider.Value)
end)

Options.flyVerticalSpeedSlider:OnChanged(function(val)
	entityLib.setFlySpeed(Options.flyHorizontalSpeedSlider.Value, val)
end)









---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------







local rejoinButton = leftGroupBox:AddButton({ Text = "Rejoin", Tooltip = false, DoubleClick = true,
	Func = function()
		utils.gameTeleport("Rejoin")
		notify("Rejoining server instance: " .. game.JobId, 1000)
	end
})

local resetButton = rejoinButton:AddButton({ Text = "Reset", Tooltip = false, DoubleClick = true,
	Func = function()
		local humanoid = localPlayer.Character.Humanoid

		if humanoid then
			humanoid.Health = 0
		end
	end
})

local myDisabledButton = leftGroupBox:AddButton({ Text = "Disabled Button", Tooltip = "This is a disabled button", DoubleClick = false,
	Func = function()
		print("You somehow clicked a disabled button!")
	end
})

leftGroupBox:AddLabel("This is a label")
leftGroupBox:AddLabel("This is a label\n\nwhich wraps its text!", true)
leftGroupBox:AddLabel("This is a label exposed to Labels", true, "TestLabel")
leftGroupBox:AddLabel("secondTestLabel", { Text = "This is a label made with table options and an index", DoesWrap = true })
leftGroupBox:AddLabel("secondTestLabel", { Text = "This is a label that doesn\"t wrap it\"s own text", DoesWrap = false })
leftGroupBox:AddDivider()

leftGroupBox:AddSlider("mySlider", { Text = "This is my slider!", Tooltip = "I am a slider!", Default = 0, Min = 0, Max = 5, Suffix = false, Rounding = 1, Compact = false, HideMax = false })

leftGroupBox:AddInput("myTextbox", { Default = "My textbox!", Numeric = false, Finished = false, ClearTextOnFocus = true, Text = "This is a textbox", Tooltip = "This is a tooltip", Placeholder = "Placeholder text", MaxLength = 3,
	Callback = function(val)
		print("[cb] Text updated. New text:", val)
	end
})

local dropdownGroupBox = tabs.main:AddRightGroupbox("Dropdowns")

dropdownGroupBox:AddDropdown("myDropdown", { Values = { "This", "is", "a", "dropdown" }, Searchable = false, Default = 1, Multi = false, Text = "A dropdown", Tooltip = "This is a tooltip",
	Callback = function(val)
		print("[cb] Dropdown got changed. New value:", val)
	end
})

dropdownGroupBox:AddDropdown("mySearchableDropdown", { Values = { "This", "is", "a", "searchable", "dropdown" }, Searchable = true, Default = 1, Multi = false, Text = "A searchable dropdown", Tooltip = "This is a tooltip",
	Callback = function(val)
		print("[cb] Dropdown got changed. New value:", val)
	end
})

dropdownGroupBox:AddDropdown("myDisplayFormattedDropdown", { Values = { "This", "is", "a", "formatted", "dropdown" }, Searchable = false, Default = 1, Multi = false, Text = "A display formatted dropdown", Tooltip = "This is a tooltip",
	FormatDisplayValue = function(val)
		if val == "formatted" then
			return "display formatted" -- formatted -> display formatted but in Options. myDisplayFormattedDropdown.Value it will still return formatted if its selected.
		end

		return val
	end,

	Callback = function(val)
		print("[cb] Display formatted dropdown got changed. New value:", val)
	end
})

dropdownGroupBox:AddDropdown("myMultiDropdown", { Values = { "This", "is", "a", "dropdown" }, Default = 1, Multi = true, Text = "A multi dropdown", Tooltip = "This is a tooltip",
	Callback = function(val)
		print("[cb] Multi dropdown got changed:")

		for key, value in next, Options.myMultiDropdown.Value do
			print(key, value)
		end
	end
})

Options.myMultiDropdown:SetValue({ This = true, is = true, })

dropdownGroupBox:AddDropdown("myDisabledDropdown", { Values = { "This", "is", "a", "dropdown" }, Default = 1, Multi = false, Text = "A disabled dropdown", Tooltip = "This is a tooltip",
    Callback = function(val)
        print("[cb] Disabled dropdown got changed. New value:", val)
    end
})

dropdownGroupBox:AddDropdown("myDisabledValueDropdown", { Values = { "This", "is", "a", "dropdown", "with", "disabled", "value" }, Default = 1, Multi = false, Text = "A dropdown with disabled value", Tooltip = "This is a tooltip",
    Callback = function(val)
        print("[cb] Dropdown with disabled value got changed. New value:", val)
    end
})

dropdownGroupBox:AddDropdown("myVeryLongDropdown", { Values = { "This", "is", "a", "very", "long", "dropdown", "with", "a", "lot", "of", "values", "but", "you", "can", "see", "more", "than", "8", "values" }, MaxVisibleDropdownItems = 12, Searchable = false,
Default = 1, Multi = false, Text = "A very long dropdown", Tooltip = "This is a tooltip",
	Callback = function(val)
		print("[cb] Very long dropdown got changed. New value:", val)
	end
})

dropdownGroupBox:AddDropdown("myPlayerDropdown", { Text = "A player dropdown", Tooltip = "This is a tooltip", SpecialType = "Player", ExcludeLocalPlayer = true,
	Callback = function(val)
		print("[cb] Player dropdown got changed:", val)
	end
})

dropdownGroupBox:AddDropdown("myTeamDropdown", { Text = "A team dropdown", Tooltip = "This is a tooltip", SpecialType = "Team",
	Callback = function(val)
		print("[cb] Team dropdown got changed:", val)
	end
})

leftGroupBox:AddLabel("Color"):AddColorPicker("colorPicker", { Title = "Some color", Default = Color3.new(0, 1, 0), Transparency = 0.5 })

Options.colorPicker:OnChanged(function(color, transparency)
	print("Color changed!", color)
	print("Transparency changed!", transparency)
end)

Options.colorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

--[[

leftGroupBox:AddLabel("Keybind"):AddKeyPicker("keyPicker", { Default = "MB2", SyncToggleState = false, Mode = "Toggle", Text = "Auto lockpick safes", NoUI = false,
	Callback = function(val)
		--print("[cb] Keybind clicked!", val)
	end,

	ChangedCallback = function(bind)
		--print("[cb] Keybind changed!", bind)
	end
})

Options.keyPicker:OnClick(function(active)
	print("Keybind clicked!", active)
end)

Options.keyPicker:OnChanged(function(bind)
	print("Keybind changed!", bind)
end)

task.spawn(function()
	while true do
		wait(1)

		local state = Options.keyPicker:GetState()
		if state then
			print("keyPicker is being held down")
		end

		if linoria.Unloaded then break end
	end
end)

Options.keyPicker:SetValue({ "MB2", "Hold" })

]]

leftGroupBox:AddLabel("Dropdown"):AddDropdown("myDropdown", { Values = { "Addon", "Dropdown" }, Searchable = false, Default = 1, Multi = false, Tooltip = "This is a tooltip", DisabledTooltip = "I am disabled!",
	Callback = function(val)
		print("[cb] Dropdown got changed. New value:", val)
	end
})

local LeftGroupBox2 = tabs.main:AddLeftGroupbox("Groupbox #2")
LeftGroupBox2:AddLabel("Oh no...\nThis label spans multiple lines!\n\nWe\"re gonna run out of UI space...\nJust kidding! Scroll down!\n\n\nHello from below!", true)

local TabBox = tabs.main:AddRightTabbox()

local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })

local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })

-- Dependency Boxes

local rightGroupbox = tabs.main:AddRightGroupbox("Dependency Boxes")

rightGroupbox:AddToggle("enableHumanoidMods", { Text = "Enable Humanoid Modifications" })

local walkspeedSliderDepbox = rightGroupbox:AddDependencyBox()

walkspeedSliderDepbox:AddSlider("walkspeedSlider", { Text = "WalkSpeed", Tooltip = false, Default = 16, Min = 16, Max = 300, Suffix = false, Rounding = 0, Compact = false, HideMax = true })

-- Set up the dependency: The slider only appears when "Enable Slider" is ON

walkspeedSliderDepbox:SetupDependencies({ { Toggles.enableHumanoidMods, true } })

local lastWalkspeed = 16  -- Default WalkSpeed

Toggles.enableHumanoidMods:OnChanged(function(enabled)
	if enabled then
		-- Store original WalkSpeed before modifying

		if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
			entityLib.clearData(localPlayer.Character.Humanoid, "WalkSpeed")
			entityLib.storeData(localPlayer.Character.Humanoid, "WalkSpeed")
		end

		lastWalkspeed = Options.walkspeedSlider.Value
		entityLib.modifyPlayer("WalkSpeed", lastWalkspeed)
	else
		-- Restore original WalkSpeed
		
		if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
			entityLib.restoreData(localPlayer.Character.Humanoid, "WalkSpeed")
		end
	end
end)

Options.walkspeedSlider:OnChanged(function(val)
	lastWalkspeed = val
	if Toggles.enableHumanoidMods.Value then
		entityLib.modifyPlayer("WalkSpeed", val)
	end
end)

localPlayer.CharacterAdded:Connect(function(character)
	if Toggles.enableHumanoidMods.Value then
		task.wait(0.3)
		entityLib.modifyPlayer("WalkSpeed", lastWalkspeed)
	end
end)

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

    linoria:SetWatermark(("Celestial Test Environment | %s fps | %s ms"):format(math.floor(fps), pingValue))
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

-- Config

local menuGroup = tabs.config:AddLeftGroupbox("Menu")

menuGroup:AddToggle("keybindMenuToggle", { Default = linoria.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(enabled) linoria.KeybindFrame.Visible = enabled end})
menuGroup:AddToggle("customCursorToggle", { Text = "Custom Cursor", Default = true, Callback = function(enabled) linoria.ShowCustomCursor = enabled end })
menuGroup:AddToggle("autoResetRainbowColorToggle", { Text = "Auto Reset Color", Tooltip = "Resets the colorpicker color back to its default color once a rainbow toggle is disabled.", Default = true, Callback = function(enabled) window.autoResetRainbowColor = enabled end })
menuGroup:AddToggle("notifSoundToggle", { Text = "Notification Alert Sounds", Tooltip = false, Default = true, Callback = function(enabled) window.notifSoundEnabled = enabled end })

local notifSoundDepbox = menuGroup:AddDependencyBox()

notifSoundDepbox:AddSlider("notifAlertVolumeSlider", { Text = "Alert Volume", Tooltip = false, Default = 1, Min = 0.1, Max = 6, Rounding = 1, Compact = false, HideMax = false })
menuGroup:AddDropdown("notifSide", { Values = { "Left", "Right" }, Searchable = false, Default = 1, Multi = false, Text = "Notification Side", Tooltip = "The side of the screen notifications will appear on." })
menuGroup:AddSlider("rainbowSpeedSlider", { Text = "Rainbow Speed", Tooltip = false, Default = 0.1, Min = 0.1, Max = 1, Rounding = 1, Compact = false, HideMax = true })

notifSoundDepbox:SetupDependencies({ { Toggles.notifSoundToggle, true } })
Options.notifAlertVolumeSlider:OnChanged(function(val)
	window.alertVolume = val
end)

Options.notifSide:OnChanged(function(val)
	linoria.NotifySide = val
end)

Options.rainbowSpeedSlider:OnChanged(function(val)
	window.RainbowSpeed = val
end)

-- =================================================
--                   TAB: CONFIG                   --
-- =================================================

local function unloadModules()
    local modules = {"enableHumanoidMods", "rainbowESPToggle", "rainbowNametagToggle", "rainbowChamsToggle", "flyToggle"}

    for _, moduleName in ipairs(modules) do
        if Toggles[moduleName] then
            Toggles[moduleName]:SetValue(false)
        end
    end

	if not isScriptReloadable then
		shared.scriptLoaded = false
	end
end

menuGroup:AddDivider()
menuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
menuGroup:AddButton("Unload", function() linoria:Unload() unloadModules() end)

linoria.ToggleKeybind = Options.MenuKeybind

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

themeManager:SetLibrary(Library)
themeManager:SetFolder("Celestial ScriptHub")
themeManager:ApplyToTab(tabs.config)

saveManager:SetLibrary(Library)
saveManager:IgnoreThemeSettings()
saveManager:SetIgnoreIndexes({ "MenuKeybind" })
saveManager:SetFolder("Celestial ScriptHub/Test Environment")
--saveManager:SetSubFolder("ex: DOORS")
saveManager:BuildConfigSection(tabs.config)
saveManager:LoadAutoloadConfig()

if getgenv().notifyLoad == true then
    local endTime = tick()
    local loadTime = utils.round(endTime - startTime, 2)
	window.notifSoundPath = assetLib.fetchAsset("Assets/Sounds/Notification Main.mp3")

    if loadTime >= 5 then
        notify("⚠️ Delayed execution.\nCelestial loaded in " .. loadTime .. " seconds.", 5)
    else
        notify("Celestial loaded in " .. loadTime .. " seconds.", 6)
    end
end

getgenv().script_key = nil
getgenv().notifyLoad = nil