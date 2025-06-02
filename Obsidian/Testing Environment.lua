while not game:IsLoaded() do
	task.wait()
end

local isScriptReloadable = true

if not isScriptReloadable then
	if shared.scriptLoaded then
		return
	end
	shared.scriptLoaded = true
end

local startTime = tick()

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()
local entityLib = loadstring(readfile("Celestial/Libraries/Entity Library.lua"))()

local fastLoad = true
local testing = false

if testing then
    getgenv().script_key = "lQwkSPLnL29AIKCAxmWuQ91M0gzjPuUugJ0Xd"
    getgenv().notifyLoad = true
end

getgenv().script_key = getgenv().script_key or ""

local auth
local executionLib
if not fastLoad then
    auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Authentication.lua"))()
    auth.trigger()

    if auth.kicked then
        return
    end

    executionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Execution%20Library.lua"))()
end

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

if isLibEnabled("auth") then
	if auth.kicked then
		return
	end
end


local library = loadstring(readfile("Celestial/Obsidian/Library.lua"))()
local ThemeManager = loadstring(readfile("Celestial/Obsidian/ThemeManager.lua"))()
local SaveManager = loadstring(readfile("Celestial/Obsidian/SaveManager.lua"))()

--[[
local repo = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Obsidian/"
local library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()
]]

local options = library.Options
local toggles = library.Toggles

library.ForceCheckbox = false
library.ShowToggleFrameInKeybinds = true

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local runService = game:GetService("RunService")

local window = library:CreateWindow({
	Title = "Celestial",
    Footer = "Universal - v1.0.0",
	Center = true,
    AutoShow = true,
    MobileButtonsSide = "Left",
	Icon = 105046741702072,
    IconColor = Color3.fromRGB(255, 255, 255),
	NotifySide = "Right",
	ShowCustomCursor = false,
})

window.autoResetRainbowColor = true
window.rainbowSpeed = 0.1
window.alertVolume = 1
window.notifSoundEnabled = true
window.notifSoundPath = "Notification Main.mp3"

local defaults = {
	ColorPicker1 = Color3.fromRGB(255, 0, 0)
}

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

local rainbowConnections = {}
local hues = {}

local function toggleRainbow(enabled, colorPickerName)
	if enabled then
		if not rainbowConnections[colorPickerName] then
			hues[colorPickerName] = hues[colorPickerName] or 0
			rainbowConnections[colorPickerName] = runService.RenderStepped:Connect(function(deltaTime)
				if not hues or not colorPickerName then return end
				
				hues[colorPickerName] = (hues[colorPickerName] + deltaTime * window.rainbowSpeed) % 1

				if not options[colorPickerName] or not defaults[colorPickerName] then
					notify("Error", "Invalid colorpicker object and/or no valid default was found.", 99999)
					return
				else
					options[colorPickerName]:SetValueRGB(Color3.fromHSV(hues[colorPickerName], 1, 1))
					--print("running")
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
				notify("Error", "Invalid colorpicker object and/or no valid default was found.", 99999)
				return
			else
				options[colorPickerName]:SetValueRGB(defaults[colorPickerName])
			end
		end
	end
end

local tabs = {
    home = window:AddTab("Home", "house"),
	main = window:AddTab("Main", "user"),
	misc = window:AddTab("Miscellaneous", "circle-ellipsis"),
	["UI Settings"] = window:AddTab("UI Settings", "settings"),
}

-- =================================================
--                   TAB: HOME                   --
-- =================================================

local infoTabBox = tabs.home:AddLeftTabbox()

tabs.home:UpdateWarningBox({Title = "Warning", Text = "This script is trash", Visible = true})

local playerTab = infoTabBox:AddTab("Player")

local respawnButton_Toggle = playerTab:AddToggle("toggleRespawn_Toggle", {Text = "Respawn Button", Tooltip = false, Default = true })

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

--[[

-------------------------------------
--      HOME: INFORMATION GROUP  --
-------------------------------------

if getLib("auth") and getLib("executionLib") then
	informationGroup:AddLabel("Identifier: " .. getLib("auth").currentUser.Identifier)
	informationGroup:AddLabel("Rank: " .. getLib("auth").currentUser.Rank)
	informationGroup:AddLabel("Discord ID: " .. getLib("auth").currentUser.DiscordId)
	informationGroup:AddLabel("Executions: " .. getLib("executionLib").fetchExecutions())

	informationGroup:AddLabel("Executor: " .. identifyexecutor())
end

-------------------------------------
--      HOME: GAME GROUP  --
-------------------------------------

gameGroup:AddLabel("Game Name: " .. gameName)
gameGroup:AddLabel("Server Instance: " .. game.JobId, true)
gameGroup:AddLabel("Place ID: " .. game.PlaceId)
gameGroup:AddLabel("Shift Lock Allowed: " .. tostring(localplayer.DevEnableMouseLock))

]]
-- =================================================
--                   TAB: MAIN                   --
-- =================================================

-------------------------------------
--      MAIN: LEFT GROUP BOX  --
-------------------------------------

local leftGroupBox = tabs.main:AddLeftGroupbox("Groupbox")

leftGroupBox:AddToggle("fly_Toggle", { Text = "Fly", Tooltip = false, Default = false })

local flyHorizSlider = leftGroupBox:AddSlider("flyHorizontalSpeed_Slider", { Text = "Horizontal Speed", Tooltip = "The speed you normally go at.",  Default = 10, Min = 5, Max = 1000, Rounding = 0 })
local flyVertSlider = leftGroupBox:AddSlider("flyVerticalSpeed_Slider", { Text = "Vertical Speed", Tooltip = "The speed you when ascending/descending.",  Default = 10, Min = 5, Max = 300, Rounding = 0 })

leftGroupBox:AddToggle("noclip_Toggle", { Text = "Noclip", Tooltip = false, Default = false })

options.flyHorizontalSpeed_Slider:OnChanged(function(val)
	entityLib.setFlySpeed(flyHorizSlider.Value, flyVertSlider.Value)
end)

options.flyVerticalSpeed_Slider:OnChanged(function(val)
	entityLib.setFlySpeed(flyHorizSlider.Value, flyVertSlider.Value)
end)

toggles.fly_Toggle:OnChanged(function(enabled)
	entityLib.toggleFly(enabled)
	entityLib.setFlySpeed(flyHorizSlider.Value, flyVertSlider.Value)
end)

toggles.noclip_Toggle:OnChanged(function(enabled)
	entityLib.toggleNoclip(enabled)
end)

leftGroupBox:AddToggle("MyToggle", { Text = "This is a toggle", Tooltip = "This is a tooltip", Default = true,
	Callback = function(Value)
		--print("[cb] MyToggle changed to:", Value)
	end,
}):AddColorPicker("ColorPicker1", { Default = Color3.new(1, 0, 0), Title = "Some color1", Transparency = 0.5,
		Callback = function(Value)
			--print("[cb] Color changed!", Value)
		end,
	}):AddColorPicker("ColorPicker2", { Default = Color3.new(0, 1, 0), Title = "Some color2",
		Callback = function(Value)
			--print("[cb] Color changed!", Value)
		end,
	})

toggles.MyToggle:OnChanged(function()
	--print("MyToggle changed to:", toggles.MyToggle.Value)
end)

toggles.MyToggle:SetValue(false)

local rainbowToggle = leftGroupBox:AddCheckbox("MyCheckbox", { Text = "Rainbow", Tooltip = "This is a tooltip", Default = false,
	Callback = function(Value)
		toggleRainbow(Value, "ColorPicker1")
	end,
})

toggles.MyCheckbox:OnChanged(function()
	--print("MyCheckbox changed to:", toggles.MyCheckbox.Value)
end)

local MyButton = leftGroupBox:AddButton({ Text = "Button", Tooltip = "This is the main button", DoubleClick = false,
	Func = function()
		--print("You clicked a button!")
        notify("test notification", "fuck you", 10)
	end,
})

local MyButton2 = MyButton:AddButton({ Text = "Sub button", Tooltip = "This is the sub button", DoubleClick = true,
	Func = function()
		--print("You clicked a sub button!")
	end,
})

local MyDisabledButton = leftGroupBox:AddButton({ Text = "Disabled Button", Tooltip = "This is a disabled button", DoubleClick = false, Disabled = true, DisabledTooltip = "I am disabled!",
	Func = function()
		--print("You somehow clicked a disabled button!")
	end,
})

--[[
	NOTE: You can chain the button methods!
	EXAMPLE:

	leftGroupBox:AddButton({ Text = 'Kill all', Func = Functions.KillAll, Tooltip = 'This will kill everyone in the game!' })
		:AddButton({ Text = 'Kick all', Func = Functions.KickAll, Tooltip = 'This will kick everyone in the game!' })
]]

leftGroupBox:AddLabel("This is a label")
leftGroupBox:AddLabel("This is a label\n\nwhich wraps its text!", true)
leftGroupBox:AddLabel("This is a label exposed to Labels", true, "TestLabel")
leftGroupBox:AddLabel("SecondTestLabel", { Text = "This is a label made with table options and an index", DoesWrap = true })

leftGroupBox:AddLabel("SecondTestLabel", { Text = "This is a label that doesn't wrap it's own text", DoesWrap = false })

leftGroupBox:AddDivider()

leftGroupBox:AddSlider("MySlider", { Text = "This is my slider!", Tooltip = "I am a slider!",  Default = 0, Min = 0, Max = 5, Rounding = 1,
	Callback = function(Value)
		--print("[cb] MySlider was changed! New value:", Value)
	end,
})

local Number = options.MySlider.Value
options.MySlider:OnChanged(function()
	--print("MySlider was changed! New value:", options.MySlider.Value)
end)

options.MySlider:SetValue(3)

leftGroupBox:AddInput("MyTextbox", { Text = "This is a textbox", Tooltip = "This is a tooltip", Placeholder = "Placeholder text", Default = "My textbox!", Numeric = false, MaxLength = 5, ClearTextOnFocus = true,
	Callback = function(Value)
		--print("[cb] Text updated. New text:", Value)
	end,
})

options.MyTextbox:OnChanged(function()
	--print("Text updated. New text:", options.MyTextbox.Value)
end)

-------------------------------------
--      MAIN: DROPDOWNS GROUP  --
-------------------------------------

local DropdownGroupBox = tabs.main:AddRightGroupbox("Dropdowns")

DropdownGroupBox:AddDropdown("MyDropdown", { Text = "A dropdown", Tooltip = "This is a tooltip", Values = { "This", "is", "a", "dropdown" }, Default = 1, Multi = false, Searchable = false,
	Callback = function(Value)
		--print("[cb] Dropdown got changed. New value:", Value)
	end,
})

options.MyDropdown:OnChanged(function()
	--print("Dropdown got changed. New value:", options.MyDropdown.Value)
end)

options.MyDropdown:SetValue("This")

DropdownGroupBox:AddDropdown("MySearchableDropdown", { Text = "A searchable dropdown", Tooltip = "This is a tooltip", Values = { "This", "is", "a", "searchable", "dropdown" }, Default = 1, Multi = false, Searchable = true,
	Callback = function(Value)
		--print("[cb] Dropdown got changed. New value:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyDisplayFormattedDropdown", { Text = "A display formatted dropdown", Tooltip = "This is a tooltip", Values = { "This", "is", "a", "formatted", "dropdown" }, Default = 1, Multi = false, Searchable = false,
	FormatDisplayValue = function(Value) -- You can change the display value for any values. The value will be still same, only the UI changes.
		if Value == "formatted" then
			return "display formatted" -- formatted -> display formatted but in Options.MyDisplayFormattedDropdown.Value it will still return formatted if its selected.
		end

		return Value
	end,

	Callback = function(Value)
		--print("[cb] Display formatted dropdown got changed. New value:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyMultiDropdown", { Text = "A multi dropdown", Tooltip = "This is a tooltip", Values = { "This", "is", "a", "dropdown" }, Default = 1, Multi = true,
	-- Default is the numeric index (e.g. "This" would be 1 since it if first in the values list)
	-- Default also accepts a string as well

	-- Currently you can not set multiple values with a dropdown

	Callback = function(Value)
		--print("[cb] Multi dropdown got changed:")
		for key, value in next, options.MyMultiDropdown.Value do
			--print(key, value) -- should print something like This, true
		end
	end,
})

options.MyMultiDropdown:SetValue({
	This = true,
	is = true,
})

DropdownGroupBox:AddDropdown("MyDisabledDropdown", { Text = "A disabled dropdown", Tooltip = "This is a tooltip", Values = { "This", "is", "a", "dropdown" }, Default = 1, Multi = false,
	Callback = function(Value)
		--print("[cb] Disabled dropdown got changed. New value:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyDisabledValueDropdown", { Text = "A dropdown with disabled value", Tooltip = "This is a tooltip", Values = { "This", "is", "a", "dropdown", "with", "disabled", "value" }, DisabledValues = { "disabled" },
Default = 1, Multi = false,

	Callback = function(Value)
		--print("[cb] Dropdown with disabled value got changed. New value:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyVeryLongDropdown", { Text = "A very long dropdown", Tooltip = "This is a tooltip", Default = 1, Multi = false, MaxVisibleDropdownItems = 12, Searchable = false,
	Values = {
		"This",
		"is",
		"a",
		"very",
		"long",
		"dropdown",
		"with",
		"a",
		"lot",
		"of",
		"values",
		"but",
		"you",
		"can",
		"see",
		"more",
		"than",
		"8",
		"values",
	},

	Callback = function(Value)
		--print("[cb] Very long dropdown got changed. New value:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyPlayerDropdown", { Text = "A player dropdown", Tooltip = "This is a tooltip", SpecialType = "Player", ExcludeLocalPlayer = true,
	Callback = function(Value)
		--print("[cb] Player dropdown got changed:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyTeamDropdown", { Text = "A team dropdown", Tooltip = "This is a tooltip", SpecialType = "Team",
	Callback = function(Value)
		--print("[cb] Team dropdown got changed:", Value)
	end,
})

leftGroupBox:AddLabel("Color"):AddColorPicker("ColorPicker", { Title = "Some color", Default = Color3.new(0, 1, 0), Transparency = 0,
	Callback = function(Value)
		--print("[cb] Color changed!", Value)
	end,
})

options.ColorPicker:OnChanged(function()
	--print("Color changed!", options.ColorPicker.Value)
	--print("Transparency changed!", options.ColorPicker.Transparency)
end)

options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

-- Label:AddKeyPicker
-- Arguments: Idx, Info

leftGroupBox:AddLabel("Keybind"):AddKeyPicker("KeyPicker", { Text = "Auto lockpick safes", Default = "MB2", SyncToggleState = false, Mode = "Toggle", NoUI = false,
	-- Occurs when the keybind is clicked, Value is `true`/`false`

	Callback = function(Value)
		--print("[cb] Keybind clicked!", Value)
	end,

	-- Occurs when the keybind itself is changed, `New` is a KeyCode Enum OR a UserInputType Enum

	ChangedCallback = function(New)
		--print("[cb] Keybind changed!", New)
	end,
})

-- OnClick is only fired when you press the keybind and the mode is Toggle
-- Otherwise, you will have to use Keybind:GetState()
options.KeyPicker:OnClick(function()
	--print("Keybind clicked!", options.KeyPicker:GetState())
end)

options.KeyPicker:OnChanged(function()
	--print("Keybind changed!", options.KeyPicker.Value)
end)

task.spawn(function()
	while true do
		wait(1)

		-- example for checking if a keybind is being pressed
		local state = options.KeyPicker:GetState()
		--[[
		if state then
			print("KeyPicker is being held down")
		end
		]]

		if library.Unloaded then
			break
		end
	end
end)

options.KeyPicker:SetValue({ "MB2", "Hold" })

-------------------------------------
--      MAIN: GROUPBOX #2  --
-------------------------------------

local LeftGroupBox2 = tabs.main:AddLeftGroupbox("Groupbox #2")
LeftGroupBox2:AddLabel( "This label spans multiple lines! We're gonna run out of UI space...\nJust kidding! Scroll down!\n\n\nHello from below!", true )

LeftGroupBox2:AddToggle('ControlToggle', { Text = 'Dependency box toggle' });

local Depbox = LeftGroupBox2:AddDependencyBox();

Depbox:AddToggle('DepboxToggle', { Text = 'Sub-dependency box toggle' });
Depbox:SetupDependencies({ { toggles.ControlToggle, true } });

toggles.ControlToggle:OnChanged(function(enabled)
	--print(enabled)
end)

local TabBox = tabs.main:AddRightTabbox() -- Add Tabbox on right side

-- Anything we can do in a Groupbox, we can do in a Tabbox tab (AddToggle, AddSlider, AddLabel, etc etc...)
local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })

local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })

library:OnUnload(function()
	--print("Unloaded!")
end)

-- =================================================
--                   TAB: MISCELLANEOUS                   --
-- =================================================

local miscGroupBox = tabs.misc:AddLeftGroupbox("Miscellaneous")

-------------------------------------
--      MISCELLANEOUS: MISCELLANEOUS GROUP  --
-------------------------------------

miscGroupBox:AddButton({ Text = "Rejoin", DoubleClick = true,
    Func = function()
        utils.gameTeleport("Rejoin")

		notify("Rejoining", "Rejoining server with job id " .. game.JobId .. ".", 1000)
    end,
})

-- =================================================
--                   TAB: UI SETTINGS                   --
-- =================================================

local MenuGroup = tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", { Default = library.KeybindFrame.Visible, Text = "Open Keybind Menu",
	Callback = function(value)
		library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = library.ShowCustomCursor,
	Callback = function(Value)
		library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddToggle("autoResetColor_Toggle", { Text = "Auto Reset Color", Tooltip = "Resets the colorpicker color back to its default color once a rainbow toggle is disabled.", Default = true,
	Callback = function(Value)
		window.autoResetRainbowColor = Value
	end,
})
MenuGroup:AddToggle("notifSound_Toggle", { Text = "Notification Alert Sounds", Tooltip = false, Default = true, Callback = function(enabled) window.notifSoundEnabled = enabled end })

local notifSoundDepbox = MenuGroup:AddDependencyBox()

notifSoundDepbox:AddSlider("notifAlertVolumeSlider", { Text = "Alert Volume", Tooltip = false, Default = 1, Min = 0.1, Max = 6, Rounding = 1, HideMax = false })
notifSoundDepbox:SetupDependencies({ { toggles.notifSound_Toggle, true } })

MenuGroup:AddDropdown("NotificationSide", { Text = "Notification Side", Values = { "Left", "Right" }, Default = "Right",
	Callback = function(Value)
		library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", { Text = "DPI Scale", Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%",
	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddSlider("rainbowSpeedSlider", { Text = "Rainbow Speed", Tooltip = false, Default = window.rainbowSpeed, Min = 0.1, Max = 1, Rounding = 1, HideMax = false })
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

local function unloadModules()
	local modules = { "fly_Toggle", "noclip_Toggle", "rainbowToggle" }

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

MenuGroup:AddButton("Unload", function()
	library:Unload()
	unloadModules()
end)

options.notifAlertVolumeSlider:OnChanged(function(val)
	window.alertVolume = val
end)

options.rainbowSpeedSlider:OnChanged(function(val)
	window.rainbowSpeed = val
end)

library.ToggleKeybind = options.MenuKeybind

ThemeManager:SetLibrary(library)
SaveManager:SetLibrary(library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Celestial ScriptHub")
SaveManager:SetFolder("Celestial ScriptHub/Testing Game")
SaveManager:SetSubFolder("Lobby")
SaveManager:BuildConfigSection(tabs["UI Settings"])
ThemeManager:ApplyToTab(tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

if getgenv().notifyLoad then
    if not startTime then
        notify("Unable to notify load", "The script start time was not recorded.", 10)
        return
    end

	local totalTime = utils.round(tick() - startTime, 1)

    local title = "Successfully loaded"
    if totalTime >= 5 then
        title = "⚠️ Delayed execution"
    end

    notify(title, "Celestial loaded in " .. totalTime .. " seconds.", 6)
end

getgenv().fastLoad = nil
getgenv().testing = nil
getgenv().notifyLoad = nil

if auth then
	auth.clearStoredKey()
end