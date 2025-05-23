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

local linoria = loadstring(readfile("Celestial/Revamped UI Libraries/Linoria - Library.lua"))()
local themeManager = loadstring(readfile("Celestial/Revamped UI Libraries/Linoria - Theme Manager.lua"))()
local saveManager = loadstring(readfile("Celestial/Revamped UI Libraries/Linoria - Save Manager.lua"))()

--[[
local linoria = loadstring(readfile("Celestial/Revamped UI Libraries/Linoria - Library.lua"))()
local themeManager = loadstring(readfile("Celestial/Revamped UI Libraries/Linoria - Theme Manager.lua"))()
local saveManager = loadstring(readfile("Celestial/Revamped UI Libraries/Linoria - Save Manager.lua"))()
]]

local startTime
if getgenv().notifyLoad == true then
	startTime = tick()
end

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local events = game:GetService("ReplicatedStorage").Events
local sounds = game:GetService("Workspace").Sounds
local runService = game:GetService("RunService")

local function getLib(libraryName)
	local validLibraries = {
		assetLib = true,
		utils = true,
		entityLib = true,
		auth = true,
		executionLib = true,
	}

	if not validLibraries[libraryName] then
		warn(libraryName .. " is not a valid library.")
	else
		return getgenv()[libraryName]
	end
end

if getLib("auth") then
	if getLib("auth").kicked then
		return
	end
end

local options = linoria.Options
local toggles = linoria.Toggles

linoria.ShowToggleFrameInKeybinds = true

-------------------------------------
--      LINORIA  --
-------------------------------------

if getLib("auth") then
	Title = "Celestial - " .. gameName .. " : " .. getLib("auth").currentUser.Identifier
else
	Title = "Celestial - " .. gameName
end

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
	RainbowSpeed = 0.1,
})

window.autoResetRainbowColor = true
window.notifSoundEnabled = true
window.notifSoundPath = "Notification Main.mp3"
window.alertVolume = 1

local tabs = {
	home = window:AddTab("Home"),
	exploits = window:AddTab("Exploits"),
	util = window:AddTab("Utility"),
	player = window:AddTab("Player"),
	endings = window:AddTab("Endings"),
	misc = window:AddTab("Misc"),
	config = window:AddTab("Config"),
}

-- Function things

local defaults = {
	hiddenItemESPColor_Colorpicker = Color3.fromRGB(252, 186, 3),
	hiddenItemLabelColor_Colorpicker = Color3.fromRGB(36, 173, 26),
	badGuyESPColor_Colorpicker = Color3.fromRGB(255, 0, 0),
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
        local notifSound = getLib("assetLib").fetchAsset("Assets/Sounds/Notification Main.mp3", window.alertVolume)
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
			rainbowConnections[colorPickerName] = runService.RenderStepped:Connect(function(deltaTime)
				hues[colorPickerName] = (hues[colorPickerName] + deltaTime * window.RainbowSpeed) % 1

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

local function getHRP()
	return getLib("entityLib").getCharInstance("HumanoidRootPart") or nil
end

--[[
local function getHumanoid()
	local humanoid = getLib("entityLib").getCharInstance("Humanoid")

	if not humanoid then
		return
	end

	return humanoid
end
]]

local function setInvenSoundState(enabled)
	local invenSound = sounds.Inventory

	if not enabled then
		invenSound.SoundId = ""
	else
		for i = 1, 1000 do
			invenSound.TimePosition = 0
			invenSound.Playing = false
		end

		invenSound.SoundId = "rbxassetid://4678793943"
	end
end

local function setEnergyUI(enabled)
	if not enabled then
		for _, v in pairs(localplayer.PlayerGui.EnergyBar.EnergyBar.EnergyBar:GetChildren()) do
			if v.Name == "Template" and v:IsA("TextLabel") and v.TextColor3 ~= Color3.fromRGB(255, 72, 0) then
				v.Visible = false
			end
		end
	else
		for _, v in pairs(localplayer.PlayerGui.EnergyBar.EnergyBar.EnergyBar:GetChildren()) do
			if v.Name == "Template" and v:IsA("TextLabel") and v.TextColor3 ~= Color3.fromRGB(255, 72, 0) then
				v.Visible = true
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

-- =================================================
--                   TAB: EXPLOITS                   --
-- =================================================

local exploitsGroup1 = tabs.exploits:AddLeftGroupbox("Exploits")
local exploitsGroup2 = tabs.exploits:AddRightGroupbox("Visuals")
local exploitsGroup3 = tabs.exploits:AddLeftGroupbox("Other")

-------------------------------------
--      EXPLOITS: EXPLOITS GROUP  --
-------------------------------------

exploitsGroup1:AddToggle("godmode_Toggle", { Text = "Godmode", Tooltip = false })
local godmodeDepbox = exploitsGroup1:AddDependencyBox()

godmodeDepbox:AddSlider("godmodeDelay_Slider", { Text = "Delay", Tooltip = false, Default = 0.05, Min = 0, Max = 10, Rounding = 2 })
godmodeDepbox:AddToggle("godmodeHideEnergyGain_Toggle", { Text = "Hide Energy Gain", Tooltip = 'Hides the "+x" text above the energy bar while keeping the "-x" text.' })

exploitsGroup1:AddToggle("noclip_Toggle", { Text = "Noclip", Tooltip = false, Default = false }):AddKeyPicker("noclip_KeyPicker", { Default = "G", SyncToggleState = true, Mode = "Toggle", Text = "Noclip", NoUI = false }
)

exploitsGroup1:AddToggle("fly_Toggle", { Text = "Fly", Tooltip = false, Default = false })
:AddKeyPicker("fly_KeyPicker", { Default = "F", SyncToggleState = true, Mode = "Toggle", Text = "Fly", NoUI = false })

local flyDepbox = exploitsGroup1:AddDependencyBox()

flyDepbox:AddSlider("flyHorizontalSpeed_Slider", { Text = "Horizontal Speed", Tooltip = "How fast you fly in all directions.", Default = 50, Min = 10, Max = 300, Rounding = 1 })
flyDepbox:AddSlider("flyVerticalSpeed_Slider", {Text = "Vertical Speed", Tooltip = "How fast you fly ascending/descending.", Default = 30, Min = 5, Max = 150, Rounding = 1 })

exploitsGroup1:AddToggle("doorNoclip_Toggle", { Text = "Door Noclip", Tooltip = false, Default = false })

exploitsGroup1:AddDivider()

exploitsGroup1:AddToggle("speedExploit_Toggle", { Text = "Speed Exploit", Tooltip = false })
local speedExploitDepbox = exploitsGroup1:AddDependencyBox()

speedExploitDepbox:AddSlider("speedExploitDelay_Slider", { Text = "Delay", Tooltip = false, Default = 1, Min = 0, Max = 10, Rounding = 2 })
speedExploitDepbox:AddToggle("speedExploitHideTrail_Toggle", { Text = "Hide Trail (Client-Sided)", Tooltip = false })

exploitsGroup1:AddToggle("collectCash_Toggle", { Text = "Collect Cash", Tooltip = "Collects all on-ground cash drops." })

exploitsGroup1:AddToggle("autoKillBadGuys_Toggle", { Text = "Kill Aura", Tooltip = false })
local autoKillDepbox = exploitsGroup1:AddDependencyBox()

autoKillDepbox:AddSlider("autoKillDelay_Slider", { Text = "Damage Amount", Tooltip = false, Default = 100, Min = 1, Max = 100, Rounding = 0 })

godmodeDepbox:SetupDependencies({ { toggles.godmode_Toggle, true } })
flyDepbox:SetupDependencies({ { toggles.fly_Toggle, true } })
speedExploitDepbox:SetupDependencies({ { toggles.speedExploit_Toggle, true } })
autoKillDepbox:SetupDependencies({ { toggles.autoKillBadGuys_Toggle, true } })

toggles.godmode_Toggle:OnChanged(function(enabled)
	if enabled then
		setInvenSoundState(false)

		task.spawn(function()
			repeat
				events.GiveTool:FireServer("Pizza")
				events.Energy:FireServer(25, "Pizza")

				task.wait(options.godmodeDelay_Slider.Value)
			until not toggles.godmode_Toggle.Value
		end)
	else
		setInvenSoundState(true)
	end
end)

toggles.godmodeHideEnergyGain_Toggle:OnChanged(function(enabled)
	if enabled then
		if toggles.speedExploit_Toggle.Value == true then -- If Speed Exploit is enabled and already hiding energy
			return
		end

		task.spawn(function()
			repeat
				setEnergyUI(false)

				task.wait()
			until not toggles.godmodeHideEnergyGain_Toggle.Value
		end)
	else
		setEnergyUI(true)
	end
end)

toggles.noclip_Toggle:OnChanged(function(enabled)
	getLib("entityLib").toggleNoclip(enabled)
end)

toggles.fly_Toggle:OnChanged(function(enabled)
	getLib("entityLib").toggleFly(enabled)
end)

options.flyHorizontalSpeed_Slider:OnChanged(function(val)
	entityLib.setFlySpeed(val, options.flyVerticalSpeed_Slider.Value)
end)

options.flyVerticalSpeed_Slider:OnChanged(function(val)
	entityLib.setFlySpeed(options.flyHorizontalSpeed_Slider.Value, val)
end)

local doorNoclipActive = false

toggles.doorNoclip_Toggle:OnChanged(function(enabled)
	doorNoclipActive = enabled

	if enabled then
		task.spawn(function()
			while doorNoclipActive do
				-- Doors1 and Doors2

				for _, doorsName in ipairs({ "Doors1", "Doors2" }) do
					local doors = workspace:FindFirstChild(doorsName)
					if doors then
						for _, part in pairs(doors:GetDescendants()) do
							if part:IsA("BasePart") and part.Transparency ~= 1 then
								part.Transparency = 0.5
								part.CanCollide = false
							end
						end
					end
				end

				-- Villain base front door

				local tst = workspace:FindFirstChild("tst")
				if tst then
					local frontDoor = tst:FindFirstChild("FrontDoor")
					if frontDoor then
						for _, part in ipairs(frontDoor:GetDescendants()) do
							if part:IsA("BasePart") and part.Transparency ~= 1 then
								part.Transparency = 0.5
								part.CanCollide = false
							end
						end
					end
				end

				-- Break room door

				local breakRoomDoor1 = game:GetService("Workspace").TheHouse:FindFirstChild("MetalBitBreakRoom")
				if breakRoomDoor1 then
					breakRoomDoor1.Transparency = 0.5
					breakRoomDoor1.CanCollide = false
				end

				-- First door

				local theHouse = game:GetService("Workspace"):FindFirstChild("TheHouse")

				if theHouse then
					local door1 = theHouse:FindFirstChild("Door")
					if door1 then
						for _, part in ipairs(door1:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Transparency = 0.5
								part.CanCollide = false
							end
						end
					end

					-- Pizza boss room

					local door2 = theHouse:FindFirstChild("Door2")
					if door2 then
						for _, part in ipairs(door2:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Transparency = 0.5
								part.CanCollide = false
							end
						end
					end

					task.wait(0.5)
				end
			end
		end)
	else
		-- Reset doors

		for _, doorsName in ipairs({ "Doors1", "Doors2" }) do
			local doors = workspace:FindFirstChild(doorsName)
			if doors then
				for _, part in pairs(doors:GetDescendants()) do
					if part:IsA("BasePart") and part.Transparency == 0.5 then
						part.Transparency = 0
						part.CanCollide = true
					end
				end
			end
		end

		local tst = workspace:FindFirstChild("tst")
		if tst then
			local frontDoor = tst:FindFirstChild("FrontDoor")
			if frontDoor then
				for _, part in ipairs(frontDoor:GetDescendants()) do
					if part:IsA("BasePart") and part.Transparency == 0.5 then
						part.Transparency = 0
						part.CanCollide = true
					end
				end
			end
		end

		-- Break room door

		local breakRoomDoor1 = game:GetService("Workspace").TheHouse:FindFirstChild("MetalBitBreakRoom")
		if breakRoomDoor1 and breakRoomDoor1.Transparency == 0.5 then
			breakRoomDoor1.Transparency = 0
			breakRoomDoor1.CanCollide = true
		end

		local theHouse = game:GetService("Workspace"):FindFirstChild("TheHouse")
		if theHouse then
			local door1 = theHouse:FindFirstChild("Door")
			if door1 then
				for _, part in ipairs(door1:GetDescendants()) do
					if part:IsA("BasePart") and part.Transparency == 0.5 then
						part.Transparency = 0
						part.CanCollide = true
					end
				end
			end

			-- Pizza boss room

			local door2 = theHouse:FindFirstChild("Door2")
			if door2 then
				for _, part in ipairs(door2:GetDescendants()) do
					if part:IsA("BasePart") and part.Transparency == 0.5 then
						part.Transparency = 0
						part.CanCollide = true
					end
				end
			end
		end
	end
end)

toggles.speedExploit_Toggle:OnChanged(function(enabled)
	if enabled then
		setInvenSoundState(false)

		task.spawn(function()
			repeat
				events.GiveTool:FireServer("BloxyCola")
				events.Energy:FireServer(15, "BloxyCola")

				task.wait(options.speedExploitDelay_Slider.Value)
			until not toggles.speedExploit_Toggle.Value
		end)

		if toggles.godmodeHideEnergyGain_Toggle.Value == true then -- If Godmode Hide Energy Gain is enabled and already hiding energy
			return
		end

		task.spawn(function()
			repeat
				if not toggles.godmodeHideEnergyGain_Toggle.Value == true then -- Preventing Godmode Hide Energy conflicting with Speed Exploit hiding energy
					setEnergyUI(false)
				else
					setEnergyUI(false)
				end

				task.wait()
			until not toggles.speedExploit_Toggle.Value
		end)
	else
		setInvenSoundState(true)
		task.wait(2)
		setEnergyUI(true)
	end
end)

toggles.speedExploitHideTrail_Toggle:OnChanged(function(enabled)
	if enabled then
		task.spawn(function()
			while toggles.speedExploit_Toggle.Value and toggles.speedExploitHideTrail_Toggle.Value do
				local hrp = getHRP()
				if hrp then
					for _, child in ipairs(hrp:GetChildren()) do
						if child.Name == "BloxyCola" and child:IsA("Trail") then
							child.Enabled = false
						end
					end
				end
				task.wait()
			end
		end)
	else
		local hrp = getHRP()
		if hrp then
			for _, child in ipairs(hrp:GetChildren()) do
				if child.Name == "BloxyCola" and child:IsA("Trail") then
					child.Enabled = true
				end
			end
		end
	end
end)

toggles.collectCash_Toggle:OnChanged(function(enabled)
	if enabled then
		local hrp = getHRP()

		task.spawn(function()
			repeat
				for _, cashPart in pairs(game:GetService("Workspace"):GetChildren()) do
					if
						cashPart.Name == "Part"
						and cashPart:FindFirstChild("TouchInterest")
						and cashPart:FindFirstChild("Weld")
						and cashPart.Transparency == 1
					then
						cashPart.CFrame = hrp.CFrame
						task.wait(0.1) -- Prevent collect all cash at once and under valuing how much cash their really is
					end
				end

				task.wait()
			until not toggles.collectCash_Toggle.Value
		end)
	end
end)

toggles.autoKillBadGuys_Toggle:OnChanged(function(enabled)
	local autoKillAmountSlider = options.autoKillDelay_Slider

	if enabled then
		task.spawn(function()
			local hitEvent = events:WaitForChild("HitBadguy")
			local damage, multiplier = autoKillAmountSlider.Value, 4

			local function attackTargets(folderName)
				local folder = game:GetService("Workspace"):FindFirstChild(folderName)

				if folder then
					for _, enemy in pairs(folder:GetChildren()) do
						hitEvent:FireServer(enemy, damage, multiplier)
					end
				end
			end

			local enemyFolders = { "BadGuys", "BadGuysBoss", "BadGuysFront" }

			repeat
				for _, group in ipairs(enemyFolders) do
					attackTargets(group)
				end

				for _, enemyName in ipairs({ "BadGuyPizza", "BadGuyBrute" }) do
					local enemy = game:GetService("Workspace"):FindFirstChild(enemyName, true)
					if enemy then
						hitEvent:FireServer(enemy, damage, multiplier)
					end
				end

				task.wait(0.1)
			until not toggles.autoKillBadGuys_Toggle.Value
		end)
	end
end)

-------------------------------------
--      EXPLOITS: VISUALS GROUP  --
-------------------------------------

exploitsGroup2:AddToggle("hiddenItemESP_Toggle", { Text = "Hidden Item ESP", Tooltip = "Highlights all the items inside drawers." })

local hiddenItemsDepbox = exploitsGroup2:AddDependencyBox()

hiddenItemsDepbox:AddLabel("ESP Color"):AddColorPicker("hiddenItemESPColor_Colorpicker",{ Title = "ESP Color", Default = Color3.fromRGB(252, 186, 3), Transparency = 0.5 })
hiddenItemsDepbox:AddToggle("rainbowHiddenItemESP_Toggle", { Text = "Rainbow ESP", Tooltip = false })
hiddenItemsDepbox:AddToggle("hiddenItemESPEnableLabels_Toggle", { Text = "Enable Labels", Tooltip = false })

local hiddenItemESPLabelDepbox = hiddenItemsDepbox:AddDependencyBox()

hiddenItemESPLabelDepbox:AddLabel("Label Color"):AddColorPicker("hiddenItemLabelColor_Colorpicker", { Title = "Label Color", Default = Color3.fromRGB(36, 173, 26), Transparency = false })
hiddenItemESPLabelDepbox:AddToggle("rainbowHiddenItemLabel_Toggle", { Text = "Rainbow Label", Tooltip = false })
hiddenItemESPLabelDepbox:AddSlider("hiddenItemLabelSize_Slider", { Text = "Label Size", Tooltip = false, Default = 15, Min = 10, Max = 30, Rounding = 0 })

exploitsGroup2:AddToggle("badGuyESP_Toggle", { Text = "Bad Guy ESP", Tooltip = false })

local badGuyESPDepbox = exploitsGroup2:AddDependencyBox()

badGuyESPDepbox:AddLabel("ESP Color"):AddColorPicker("badGuyESPColor_Colorpicker", { Title = "ESP Color", Default = Color3.fromRGB(255, 0, 0), Transparency = 0.5 })
badGuyESPDepbox:AddToggle("rainbowBadGuyESP_Toggle", { Text = "Rainbow ESP", Tooltip = false })

exploitsGroup2:AddToggle("disableVignette_Toggle", { Text = "Disable Vignette", Tooltip = false })

hiddenItemsDepbox:SetupDependencies({ { toggles.hiddenItemESP_Toggle, true } })
hiddenItemESPLabelDepbox:SetupDependencies({ { toggles.hiddenItemESPEnableLabels_Toggle, true } })

hiddenItemsDepbox:SetupDependencies({ { toggles.hiddenItemESP_Toggle, true } })
hiddenItemESPLabelDepbox:SetupDependencies({ { toggles.hiddenItemESPEnableLabels_Toggle, true } })
badGuyESPDepbox:SetupDependencies({ { toggles.badGuyESP_Toggle, true } })

local hiddenHighlights = {}
local hiddenLabels = {}

local hiddenItemToggle = toggles.hiddenItemESP_Toggle
local espColorOption = options.hiddenItemESPColor_Colorpicker
local labelColorOption = options.hiddenItemLabelColor_Colorpicker
local labelSizeOption = options.hiddenItemLabelSize_Slider

hiddenItemToggle:OnChanged(function(enabled)
	if enabled then
		task.spawn(function()
			while hiddenItemToggle.Value do
				local espColor = espColorOption.Value
				local espTransparency = espColorOption.Transparency
				local labelColor = labelColorOption.Value
				local labelSize = labelSizeOption.Value
				local showLabels = toggles.hiddenItemESPEnableLabels_Toggle

				for _, item in ipairs(game:GetService("Workspace").Hidden:GetChildren()) do
					-- Highlight

					local highlight = item:FindFirstChild("_CelestialItemHighlight")
					if not highlight then
						highlight = Instance.new("Highlight")
						highlight.Name = "_CelestialItemHighlight"
						highlight.Parent = item
						hiddenHighlights[item] = highlight
					end

					highlight.FillColor = espColor
					highlight.FillTransparency = espTransparency
					highlight.OutlineColor = espColor
					highlight.OutlineTransparency = 0

					-- Labels

					local labelGui = item:FindFirstChild("_CelestialItemLabel")
					if showLabels.Value then
						if not labelGui then
							labelGui = Instance.new("BillboardGui")
							labelGui.Name = "_CelestialItemLabel"
							labelGui.Adornee = item
							labelGui.Size = UDim2.new(0, 200, 0, 50)
							labelGui.StudsOffset = Vector3.new(0, 2, 0)
							labelGui.AlwaysOnTop = true
							labelGui.Parent = item

							local textLabel = Instance.new("TextLabel")
							textLabel.Name = "Label"
							textLabel.Size = UDim2.new(1, 0, 1, 0)
							textLabel.BackgroundTransparency = 1
							textLabel.TextStrokeTransparency = 0
							textLabel.TextScaled = false
							textLabel.Font = Enum.Font.SourceSansBold
							textLabel.Text = item.Name
							textLabel.TextColor3 = labelColor
							textLabel.TextSize = labelSize
							textLabel.Parent = labelGui

							hiddenLabels[item] = labelGui
						else
							local textLabel = labelGui:FindFirstChild("Label")
							if textLabel then
								textLabel.TextColor3 = labelColor
								textLabel.TextSize = labelSize
							end
						end
					elseif labelGui then
						labelGui:Destroy()
						hiddenLabels[item] = nil
					end
				end

				task.wait(0.25)
			end
		end)
	else
		for _, highlight in pairs(hiddenHighlights) do
			highlight:Destroy()
		end
		table.clear(hiddenHighlights)

		for _, label in pairs(hiddenLabels) do
			label:Destroy()
		end
		table.clear(hiddenLabels)
	end
end)

toggles.rainbowHiddenItemESP_Toggle:OnChanged(function(enabled)
	toggleRainbow(enabled, "hiddenItemESPColor_Colorpicker")
end)

toggles.rainbowHiddenItemLabel_Toggle:OnChanged(function(enabled)
	toggleRainbow(enabled, "hiddenItemLabelColor_Colorpicker")
end)

local badGuyESPConnections = {}
local updateConnection = nil

toggles.badGuyESP_Toggle:OnChanged(function(enabled)
	local badGuyColorPicker = options.badGuyESPColor_Colorpicker

	local function applyESP(folder)
		for _, child in pairs(folder:GetChildren()) do
			if child:IsA("Model") and not child:FindFirstChild("_CelestialBadGuyHighlight") then
				local highlight = Instance.new("Highlight")
				highlight.Name = "_CelestialBadGuyHighlight"
				highlight.Parent = child
				highlight.FillColor = badGuyColorPicker.Value
				highlight.OutlineColor = badGuyColorPicker.Value
				highlight.FillTransparency = badGuyColorPicker.Transparency
			end
		end
	end

	local function clearESP(folder)
		for _, highlight in pairs(folder:GetDescendants()) do
			if highlight:IsA("Highlight") and highlight.Name == "_CelestialBadGuyHighlight" then
				highlight:Destroy()
			end
		end
	end

	if enabled then
		-- Clear previous

		for _, connection in pairs(badGuyESPConnections) do
			if connection then
				connection:Disconnect()
			end
		end
		table.clear(badGuyESPConnections)

		-- Apply ESP, get new models

		for _, folderName in pairs({ "BadGuys", "BadGuysFront" }) do
			local folder = game:GetService("Workspace"):FindFirstChild(folderName)
			if folder then
				applyESP(folder)

				badGuyESPConnections[folderName] = folder.ChildAdded:Connect(function(child)
					if child:IsA("Model") then
						local highlight = Instance.new("Highlight")
						highlight.Name = "_CelestialBadGuyHighlight"
						highlight.Parent = child
						highlight.FillColor = badGuyColorPicker.Value
						highlight.OutlineColor = badGuyColorPicker.Value
						highlight.FillTransparency = badGuyColorPicker.Transparency
					end
				end)
			end
		end

		-- Update every frame

		if not updateConnection then
			updateConnection = runService.RenderStepped:Connect(function()
				local color = badGuyColorPicker.Value
				local transparency = badGuyColorPicker.Transparency

				for _, folderName in pairs({ "BadGuys", "BadGuysFront" }) do
					local folder = game:GetService("Workspace"):FindFirstChild(folderName)
					if folder then
						for _, model in pairs(folder:GetChildren()) do
							local highlight = model:FindFirstChild("_CelestialBadGuyHighlight")
							if highlight and highlight:IsA("Highlight") then
								if highlight.FillColor ~= color then
									highlight.FillColor = color
								end
								if highlight.OutlineColor ~= color then
									highlight.OutlineColor = color
								end
								if highlight.FillTransparency ~= transparency then
									highlight.FillTransparency = transparency
								end
							end
						end
					end
				end
			end)
		end
	else
		-- Cleanup

		for _, folderName in pairs({ "BadGuys", "BadGuysFront" }) do
			local folder = game:GetService("Workspace"):FindFirstChild(folderName)
			if folder then
				clearESP(folder)
			end
		end

		for _, connection in pairs(badGuyESPConnections) do
			if connection then
				connection:Disconnect()
			end
		end
		table.clear(badGuyESPConnections)

		if updateConnection then
			updateConnection:Disconnect()
			updateConnection = nil
		end
	end
end)

toggles.rainbowBadGuyESP_Toggle:OnChanged(function(enabled)
	toggleRainbow(enabled, "badGuyESPColor_Colorpicker")
end)

toggles.disableVignette_Toggle:OnChanged(function(enabled)
	local vignette = localplayer.PlayerGui.Assets.Vig

	if enabled then
		task.spawn(function()
			repeat
				vignette.Visible = false

				task.wait()
			until not toggles.disableVignette_Toggle.Value
		end)
	else
		vignette.Visible = true
	end
end)

-------------------------------------
--      EXPLOITS: OTHERS GROUP  --
-------------------------------------

exploitsGroup3:AddDropdown("locationTeleport_Dropdown", { Values = { "Villian Base", "Kitchen", "Fighting Arena", "Gym", "Pizza Boss", "Shop", "Golden Apple Path", "Generator", "Boss Fight Start",
"Boss Fight Main", "Kitchen", "Twado", "Detective" }, Searchable = false, Default = 1, Multi = false, Text = "Teleport to Location", Tooltip = false })

exploitsGroup3:AddButton({ Text = "Teleport", Tooltip = false, DoubleClick = false,
	Func = function()
        local cframeValues = {
            ["Villian Base"] = CFrame.new(-233.926117, 30.4567528, -790.019897, 0.00195977557, -8.22674984e-11, -0.999998093, -2.4766762e-09, 1, -8.71213934e-11, 0.999998093, 2.47684229e-09, 0.00195977557),
            ["Kitchen"] = CFrame.new(-216.701218, 30.4702568, -722.335327, 0.00404609647, 1.23633853e-07, 0.999991834, -7.18327664e-09, 1, -1.23605801e-07, -0.999991834, -6.68309719e-09, 0.00404609647),
            ["Fighting Arena"] = CFrame.new(-262.294586, 62.7116394, -735.916199, -1, -7.62224133e-08, -0.000201582094, -7.6233647e-08, 1, 5.5719358e-08, 0.000201582094, 5.57347235e-08, -1),
            ["Gym"] = CFrame.new(-257.281738, 63.4477501, -843.258362, 0.999999464, -6.6242154e-09, 0.00105193094, 6.52111609e-09, 1, 9.80127126e-08, -0.00105193094, -9.8005799e-08, 0.999999464),
            ["Pizza Boss"] = CFrame.new(-287.475769, 30.4527531, -721.746277, -0.00427152216, -8.6121041e-08, 0.99999088, 2.21573924e-08, 1, 8.6216474e-08, -0.99999088, 2.25254659e-08, -0.00427152216),
            ["Shop"] = CFrame.new(-251.009491, 30.4477539, -851.509705, 0.0225389507, 7.41174511e-10, -0.999745965, 2.19171417e-10, 1, 7.46304019e-10, 0.999745965, -2.35936659e-10, 0.0225389507),
            ["Golden Apple Path"] = CFrame.new(85.6087112, 29.4477024, -804.023926, -0.999134541, 1.15144616e-09, 0.0415947847, 4.49046622e-09, 1, 8.01815432e-08, -0.0415947847, 8.02989319e-08, -0.999134541),
            ["Generator"] = CFrame.new(-114.484352, 30.0235462, -790.053833, -0.656062722, 0, -0.754706323, 0, 1, 0, 0.754706323, 0, -0.656062722),
            ["Boss Fight Start"] = CFrame.new(-1328.85242, -346.249146, -810.092285, 0.00456922129, 5.69967078e-08, 0.999989569, 1.76120984e-08, 1, -5.70777772e-08, -0.999989569, 1.78727166e-08, 0.00456922129),
            ["Boss Fight Main"] = CFrame.new(-1589.43518, -368.714264, -1009.18408, 0.00910976715, -2.96539877e-08, -0.999958515, 2.42480613e-09, 1, -2.9633128e-08, 0.999958515, -2.15475482e-09, 0.00910976715),
            ["Kitchen"] = CFrame.new(-244.960632, 30.4702587, -735.684692, -0.998042107, 7.45045003e-09, -0.0625452921, 1.36177949e-08, 1, -9.81797754e-08, 0.0625452921, -9.88392799e-08, -0.998042107),
            ["Twado"] = CFrame.new(-273.23111, 30.2200623, -907.456665, -0.214113176, -1.13417443e-07, 0.976808846, -8.10850675e-09, 1, 1.14332813e-07, -0.976808846, 1.65597012e-08, -0.214113176),
            ["Detective"] = CFrame.new(-278.495697, 95.4477386, -790.951477, 0.00650879554, -5.40658984e-09, 0.99997884, 2.86954238e-10, 1, 5.40483658e-09, -0.99997884, 2.51769161e-10, 0.00650879554)
        }

        local dropdown = options.locationTeleport_Dropdown
        local cframeDestination = cframeValues[dropdown.Value]
        local hrp = getHRP()

        getLib("entityLib").teleport(cframeDestination)

        if getLib("entityLib").checkTeleport(hrp, cframeDestination, 5) then
            notify("Successfully teleported to " .. dropdown.Value .. ".", 6)

            -- If the teleport was successful, perform additional actions

            if dropdown.Value == "Villian Base" then
                getLib("utils").fireTouchEvent(hrp, game.Workspace.InsideTouchParts.FrontDoor)
                print("fired touch: base")

            elseif dropdown.Value == "Fighting Arena" then
                getLib("utils").fireTouchEvent(hrp, game:GetService("Workspace").EvilArea.EnterPart)
                print("fired touch: arena")

            elseif dropdown.Value == "Detective" then
                local clickDetector = game.Workspace.TheHouse.OfficeDoor.ClosedDoor.Handle:FindFirstChildOfClass("ClickDetector")

                if clickDetector then
                    getLib("utils").fireClickEvent(clickDetector)
                end
            end

            -- If value is NOT "Fighting Arena", remove the strength overhead

            if dropdown.Value ~= "Fighting Arena" then
                getLib("utils").fireTouchEvent(hrp, game.Workspace.EvilArea.ExitPart2)
            end

        else
            notify("Failed to teleport to " .. dropdown.Value .. ".", 7)
        end
	end
})

exploitsGroup3:AddToggle("insideSpoof_Toggle", { Text = "Inside Spoof", Tooltip = false })
exploitsGroup3:AddToggle("outsideSpoof_Toggle", { Text = "Outside Spoof", Tooltip = false })
exploitsGroup3:AddToggle("fightSpoof_Toggle", { Text = "Fight Spoof", Tooltip = false })

toggles.insideSpoof_Toggle:OnChanged(function(enabled)
	if enabled then
		toggles.outsideSpoof_Toggle:SetValue(false)

		task.spawn(function()
			repeat
				local hrp = getHRP()
				getLib("utils").fireTouchEvent(hrp, game.Workspace.InsideTouchParts.FrontDoor)

				task.wait(0.2)
			until not toggles.insideSpoof_Toggle.Value
		end)
	end
end)

toggles.outsideSpoof_Toggle:OnChanged(function(enabled)
	if enabled then
		toggles.insideSpoof_Toggle:SetValue(false)
		toggles.fightSpoof_Toggle:SetValue(false)

		task.spawn(function()
			repeat
				local hrp = getHRP()
				getLib("utils").fireTouchEvent(hrp, game.Workspace.OutsideTouchParts.OutsideTouch)

				task.wait(0.2)
			until not toggles.outsideSpoof_Toggle.Value
		end)
	end
end)

toggles.fightSpoof_Toggle:OnChanged(function(enabled)
	if enabled then
		toggles.outsideSpoof_Toggle:SetValue(false)

		task.spawn(function()
			repeat
				local hrp = getHRP()
				getLib("utils").fireTouchEvent(hrp, game.Workspace.EvilArea.EnterPart)

				task.wait(0.2)
			until not toggles.outsideSpoof_Toggle.Value
		end)
	else
		local hrp = getHRP()
		getLib("utils").fireTouchEvent(hrp, game.Workspace.EvilArea.ExitPart2)
	end
end)

-- =================================================
--                   TAB: UTILITY                   --
-- =================================================

local itemsGroup2 = tabs.util:AddLeftGroupbox("Items")

-------------------------------------
--      UTIL: ITEMS GROUP  --
-------------------------------------

itemsGroup2:AddDropdown("itemList_Dropdown", { Values = { "GoldPizza", "GoldenApple", "RainbowPizzaBox", "RainbowPizza", "GoldKey",
"Bottle", "Armor", "Louise", "Lollipop", "Ladder", "MedKit", "Chips", "Cookie", "BloxyCola", "Apple", "Pizza", "ExpiredBloxyCola" }, Searchable = true, Default = 1, Multi = true, Text = "Item", Tooltip = false })

itemsGroup2:AddSlider("giveItemAmount_Slider", { Text = "Amount", Tooltip = false, Default = 10, Min = 1, Max = 800, Rounding = 0 })

itemsGroup2:AddInput("customGiveAmount_Input", { Default = "", Numeric = true, Finished = false, ClearTextOnFocus = true, Text = "Custom Value", Tooltip = false, Placeholder = "Number (###)", MaxLength = 3,
	Callback = function(val)
		local amountSlider = options.giveItemAmount_Slider
        local amountSliderMin = options.giveItemAmount_Slider.Min
        local amountSliderMax = options.giveItemAmount_Slider.Max
        local NumeratedVal = tonumber(val)

        if NumeratedVal < amountSliderMin then
            notify("Cannot have values less than the minimum.", 6)
        end

        if NumeratedVal > amountSliderMax then
            notify("Cannot have values greater than the maximum", 6)
        end

        amountSlider:SetValue(NumeratedVal)
	end
})

itemsGroup2:AddButton({
	Text = "Give Item",
	Tooltip = false,
	DoubleClick = false,
	Func = function()
		local selectedItems = 0
		local playerInventoryBefore = {}

		local itemDropdown = options.itemList_Dropdown
		local amountSlider = options.giveItemAmount_Slider

		-- Save inventory count before giving items

		for _, tool in ipairs(localplayer.Backpack:GetChildren()) do
			playerInventoryBefore[tool.Name] = (playerInventoryBefore[tool.Name] or 0) + 1
		end

		for item, isSelected in pairs(itemDropdown.Value) do
			if isSelected then
				selectedItems += 1

				if item == "Armor" then
					if not localplayer.Character:FindFirstChild("Desert Storm Army Vest") then
						events.Vending:FireServer(3, "Armor2", "Armor", localplayer.Name, true, 1)
						task.wait(0.03)
						if localplayer.Character:FindFirstChild("Desert Storm Army Vest") then
							notify("You have been given armor.", 4)
						else
							notify("Armor detection failed.", 6)
						end
					else
						notify("You already have armor.", 4)
					end
				else
					for _ = 1, amountSlider.Value do
						events.GiveTool:FireServer(item)
					end
				end

				task.wait()
			end
		end

		task.wait(0.2)

		-- Save inventory count after giving items

		local playerInventoryAfter = {}
		for _, tool in ipairs(localplayer.Backpack:GetChildren()) do
			playerInventoryAfter[tool.Name] = (playerInventoryAfter[tool.Name] or 0) + 1
		end

		-- Compare the stored inventories before and after to detect new items and their quantities

		local newItems = {}
		for itemName, afterCount in pairs(playerInventoryAfter) do
			local beforeCount = playerInventoryBefore[itemName] or 0
			local quantityAdded = afterCount - beforeCount

			if quantityAdded > 0 then
				table.insert(newItems, quantityAdded .. "x " .. itemName)
			end
		end

		-- Notify new items

		if #newItems > 0 then
			notify("You have received: " .. table.concat(newItems, ", "), 4)
		else
			notify("No new items were detected.", 6)
		end
	end,
})

itemsGroup2:AddDivider()

itemsGroup2:AddDropdown("weaponList_Dropdown", { Values = { "Crowbar 1", "Crowbar 2", "Bat", "Pitchfork", "Hammer", "Wrench", "Broom" }, Searchable = true, Default = 1, Multi = false, Text = "Weapon", Tooltip = false })

local giveWeapon_Btn = itemsGroup2:AddButton({ Text = "Give Weapon", Tooltip = false, DoubleClick = false,
	Func = function()
        local weapon = options.weaponList_Dropdown.Value

        -- Weapon existence check

        if getLib("entityLib").getTool("Specific", weapon) then
            notify("You already have: " .. weapon .. ".", 6)
            return
        end

        -- Save current inventory

        local inventoryBefore = {}
        for _, tool in ipairs(localplayer.Backpack:GetChildren()) do
            inventoryBefore[tool.Name] = true
        end

        for _, tool in ipairs(localplayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                inventoryBefore[tool.Name] = true
            end
        end

        events.Vending:FireServer(3, weapon, "Weapons", localplayer.Name, 1)
        task.wait(0.5)

        -- Check inventory, determine successful give attempt

        if getLib("entityLib").getTool("Specific", weapon) then
            notify("You have received: " .. weapon .. ".", 4)
        else
            notify("Weapon could not be given: " .. weapon .. ".", 6)
        end
	end
})

local giveBestWeapon_Btn = itemsGroup2:AddButton({ Text = "Give Best Weapon", Tooltip = false, DoubleClick = false,
	Func = function()
        local bestWeapon = localplayer.PlayerGui.Phone.Phone.Phone.Background.InfoScreen.WeaponInfo.TwadoWants.Text

        -- Check if the player already has the weapon

        if getLib("entityLib").getTool("Specific", bestWeapon) then
            notify("You already have: " .. bestWeapon .. ".", 6)
            return
        end

        -- Save current inventory

        local inventoryBefore = {}
        for _, tool in ipairs(localplayer.Backpack:GetChildren()) do
            inventoryBefore[tool.Name] = true
        end

        for _, tool in ipairs(localplayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                inventoryBefore[tool.Name] = true
            end
        end

        events.Vending:FireServer(3, bestWeapon, "Weapons", localplayer.Name, 1)
        task.wait(0.5)

        -- Check inventory, determine successful give attempt

        if getLib("entityLib").getTool("Specific", bestWeapon) then
            notify("You have received: " .. bestWeapon .. ".", 4)
        else
            notify("Weapon could not be given: " .. bestWeapon .. ".", 6)
        end
	end
})

-- =================================================
--                   TAB: PLAYER                   --
-- =================================================

local testGroup3 = tabs.player:AddLeftGroupbox("Groupbox Title")

-------------------------------------
--      PLAYER: TEST GROUP  --
-------------------------------------

--print("code here")

-- =================================================
--                   TAB: ENDINGS                   --
-- =================================================

local testGroup4 = tabs.endings:AddLeftGroupbox("Groupbox Title")

-------------------------------------
--      ENDINGS: TEST GROUP  --
-------------------------------------

--print("code here")

-- =================================================
--                   TAB: MISCELLANEOUS                   --
-- =================================================

local miscGroup = tabs.misc:AddLeftGroupbox("Miscellaneous")

miscGroup:AddButton({ Text = "Lobby", Tooltip = false, DoubleClick = true,
	Func = function()
		getLib("utils").gameTeleport(13864661000)

		notify("Teleporting to lobby...", 100)
	end
})

miscGroup:AddToggle("bypassCutscenes_Toggle", { Text = "Bypass Cutscenes", Tooltip = false })

local lastCutsceneType = nil
toggles.bypassCutscenes_Toggle:OnChanged(function(enabled)
	local camera = game:GetService("Workspace").CurrentCamera

	if enabled then
		task.spawn(function()
			repeat
				local character = localplayer.Character
				local head = character and character:FindFirstChild("Head")

				if head then
					-- Only reset if something externally changed the camera
					
					if
						camera.CameraType ~= Enum.CameraType.Custom
						or (lastCutsceneType and lastCutsceneType ~= camera.CameraType)
					then
						camera.CameraType = Enum.CameraType.Custom
						camera.FieldOfView = 70
						camera.CFrame = head.CFrame
					end

					-- Update last known camera type to detect cutscene attempts

					lastCutsceneType = camera.CameraType
				end

				task.wait(0.05)
			until not toggles.bypassCutscenes_Toggle.Value
		end)
	end
end)

-------------------------------------
--      LINORIA / CONFIG  --
-------------------------------------

linoria:SetWatermarkVisibility(true)

local frameTimer = tick()
local frameCounter = 0
local fps = 60

local watermarkConnection = runService.RenderStepped:Connect(function()
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
		local success, result = pcall(function()
			return serverStats["Data Ping"]:GetValue()
		end)
		if success and typeof(result) == "number" then
			pingValue = math.floor(result)
		else
			print("Failed to retrieve ping value, result:", result)
		end
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

Library.KeybindFrame.Visible = true

menuGroup:AddToggle("keybindMenu_Toggle", { Default = linoria.KeybindFrame.Visible, Text = "Keybind Menu", Callback = function(enabled) linoria.KeybindFrame.Visible = enabled end })
menuGroup:AddToggle("customCursor_Toggle", { Text = "Custom Cursor", Default = useCustomCursor, Callback = function(enabled) linoria.ShowCustomCursor = enabled end })
menuGroup:AddToggle("autoResetRainbowColor_Toggle", { Text = "Auto Reset Color", Tooltip = "Resets the colorpicker color back to its default color once a rainbow toggle is disabled.", Default = true, Callback = function(enabled) window.autoResetRainbowColor = enabled end })
menuGroup:AddToggle("executeOnTeleport_Toggle", { Text = "Execute on Teleport", Tooltip = "Runs the script when a game teleport is detected. Once the script is queued, it cannot be unqueued.", Default = false })
menuGroup:AddToggle("notifSound_Toggle", { Text = "Notification Alert Sounds", Tooltip = false, Default = true, Callback = function(enabled) window.notifSoundEnabled = enabled end })

local notifSoundDepbox = menuGroup:AddDependencyBox()

notifSoundDepbox:AddSlider("notifAlertVolumeSlider", { Text = "Alert Volume", Tooltip = false, Default = 1, Min = 0.1, Max = 6, Rounding = 1, Compact = false, HideMax = false })
notifSoundDepbox:SetupDependencies({ { toggles.notifSound_Toggle, true } })

menuGroup:AddDropdown("notifSide", { Values = { "Left", "Right" }, Searchable = false, Default = 1, Multi = false, Text = "Notification Side", Tooltip = "The side of the screen notifications will appear on." })
menuGroup:AddSlider("rainbowSpeedSlider", { Text = "Rainbow Speed", Tooltip = false, Default = 0.1, Min = 0.1, Max = 1, Rounding = 1, Compact = false, HideMax = true })

if getgenv().scriptQueued == nil then
	getgenv().scriptQueued = false
end

toggles.executeOnTeleport_Toggle:OnChanged(function(enabled)
	if enabled then
		if not getgenv().scriptQueued then
			queue_on_teleport([[
                loadstring(readfile("Celestial/Supported Games/Linoria Rewrite/2025 Rewrite/Break In 2 - Game new.lua"))()
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
	local modules = { "noclip_Toggle", "fly_Toggle" }

	for _, moduleName in ipairs(modules) do
		if toggles[moduleName] then
			toggles[moduleName]:SetValue(false)
		end
	end

	if not isScriptReloadable then
		shared.scriptLoaded = false
	end

	task.wait(0.1)

	--[[
    getgenv().assetLib = nil
    getgenv().utils = nil
    getgenv().entityLib = nil
    getgenv().auth = nil
    getgenv().executionLib = nil
	]]
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
saveManager:SetSubFolder("Game")
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

if getgenv().auth then
	getgenv().auth.clearStoredKey()
end