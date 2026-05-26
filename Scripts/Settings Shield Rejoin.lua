repeat task.wait() until game:IsLoaded()

--print("RejoinButton V1.0 : Developed and maintained by Corrade (corradeknight)")

--// Services
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--// Constants
local BUTTON_NAME = "MenuButtonContainer_REJOIN"
local REJOIN_TEXT = "Rejoin"
local REJOINING_TEXT = "Rejoining..."

getgenv().REJOIN_LOCK = getgenv().REJOIN_LOCK or false

--// ========= CORE HELPERS ========= --

local function SafeRejoin()
    if getgenv().REJOIN_LOCK then return end
    getgenv().REJOIN_LOCK = true

    task.spawn(function()
        local placeId = game.PlaceId
        local jobId = game.JobId

        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
        end)

        if not success then
            warn("Rejoin failed:", err)
        end

        task.wait(2)
        getgenv().REJOIN_LOCK = false
    end)
end

local function getMenuButtons()
	local robloxGui = CoreGui:FindFirstChild("RobloxGui")
	if not robloxGui then return end

	local shield = robloxGui:FindFirstChild("SettingsClippingShield")
	if not shield then return end

	local settings = shield:FindFirstChild("SettingsShield")
	if not settings then return end

	local menu = settings:FindFirstChild("MenuContainer")
	if not menu then return end

	local page = menu:FindFirstChild("Page")
	if not page then return end

	local bottom = page:FindFirstChild("BottomButtonFrame")
	if not bottom then return end

	return bottom:FindFirstChild("MenuButtons")
end

local function isMenuOpen()
	local robloxGui = CoreGui:FindFirstChild("RobloxGui")
	if not robloxGui then return false end

	local settings = robloxGui:FindFirstChild("SettingsClippingShield")
		and robloxGui.SettingsClippingShield:FindFirstChild("SettingsShield")

	return settings and settings.Visible
end

local function getLabel(button)
	return button:FindFirstChild("ButtonText")
		or button:FindFirstChildWhichIsA("TextLabel")
end

-- 🔥 Preferred template finder (NO resume)
local function findTemplate(menuButtons)
	local fallback

	for _, child in ipairs(menuButtons:GetChildren()) do
		local button = child:FindFirstChild("MenuButton")
		if button then
			local label = getLabel(button)
			if label then
				local text = string.lower(label.Text)

				if text:find("leave") then
					return child
				elseif text:find("reset") or text:find("respawn") then
					fallback = child
				end
			end

			fallback = fallback or child
		end
	end

	return fallback
end

--// ========= BUTTON ========= --

local function playRejoinAnimation(button)
	if not button or not button.Parent then return end

	local label = getLabel(button)
	if not label then return end

	button.AutoButtonColor = false

	local hint = button:FindFirstChild("Hint")
	if hint then hint:Destroy() end

	local existing = button:FindFirstChild("RejoiningText")
	if existing then existing:Destroy() end

	local newText = label:Clone()
	newText.Text = REJOINING_TEXT
	newText.TextTransparency = 1
	newText.Name = "RejoiningText"
	newText.Parent = button

	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)

	TweenService:Create(label, tweenInfo, {TextTransparency = 1}):Play()
	TweenService:Create(newText, tweenInfo, {TextTransparency = 0}):Play()

	button.BackgroundTransparency = 0.9

	task.delay(0.2, function()
		SafeRejoin()
	end)
end

local function connectButton(button)
	if not button or button:GetAttribute("Connected") then return end
	button:SetAttribute("Connected", true)

	button.MouseButton1Click:Connect(function()
		playRejoinAnimation(button)
	end)

	button.MouseEnter:Connect(function()
		button.BackgroundTransparency = 0.81
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundTransparency = 0.88
	end)
end

local function cleanupConnections()
	if getgenv().REJOIN_UI_CONNECTIONS then
		for _, conn in ipairs(getgenv().REJOIN_UI_CONNECTIONS) do
			pcall(function()
				conn:Disconnect()
			end)
		end
	end

	getgenv().REJOIN_UI_CONNECTIONS = {}
end

local function cleanupOldRejoinButtons(menuButtons)
	for _, child in ipairs(menuButtons:GetChildren()) do
		local button = child:FindFirstChild("MenuButton")

		if child.Name == BUTTON_NAME then
			child:Destroy()

		elseif button then
			local label = getLabel(button)
			if label and label.Text == REJOIN_TEXT then
				-- stale injected clone from old script run
				child:Destroy()
			end
		end
	end
end

--// ========= PREVENTING CONNECTION OVERLAPS & SPAM EXECUTION ========= --

getgenv().REJOIN_UI_CONNECTIONS = getgenv().REJOIN_UI_CONNECTIONS or {}

if getgenv().REJOIN_UI_LOADED then
	cleanupConnections()
end

getgenv().REJOIN_UI_LOADED = true

--// ========= INJECTION ========= --

local function tryInject(menuButtons)
	if not menuButtons then return end

    cleanupOldRejoinButtons(menuButtons)

	local template = findTemplate(menuButtons)
	if not template then return end

	local clone = template:Clone()
	clone.Name = BUTTON_NAME
	clone.Parent = menuButtons

	local button = clone:FindFirstChild("MenuButton")
	if not button then return end

	local label = getLabel(button)
	if label then
		label.Text = REJOIN_TEXT
	end

    local hint = button:FindFirstChild("Hint")
    if hint then
        hint.Image = "rbxassetid://129474000315473"
        hint.ImageRectOffset = Vector2.zero
        hint.ImageRectSize = Vector2.zero
    end

	connectButton(button)
end

--// ========= KEYBIND ========= --

UIS.InputBegan:Connect(function(input, gpe)
	if gpe or UIS:GetFocusedTextBox() then return end

	if input.KeyCode == Enum.KeyCode.J and isMenuOpen() then
		local menuButtons = getMenuButtons()
		local container = menuButtons and menuButtons:FindFirstChild(BUTTON_NAME)
		local button = container and container:FindFirstChild("MenuButton")

		playRejoinAnimation(button)
	end
end)

--// ========= INSTANT + RELIABLE HOOK ========= --

task.spawn(function()
	local robloxGui = CoreGui:WaitForChild("RobloxGui")

	-- instant detection
	table.insert(getgenv().REJOIN_UI_CONNECTIONS,
        robloxGui.DescendantAdded:Connect(function(obj)
            if obj.Name == "MenuButtons" then
                tryInject(obj)
            end
        end)
    )

	-- 🔥 FIX: detect menu reopening (no polling)
	local shield = robloxGui:WaitForChild("SettingsClippingShield")
	local settings = shield:WaitForChild("SettingsShield")

	table.insert(getgenv().REJOIN_UI_CONNECTIONS,
        settings:GetPropertyChangedSignal("Visible"):Connect(function()
            if settings.Visible then
                local menuButtons = getMenuButtons()
                tryInject(menuButtons)
            end
        end)
    )

	-- initial inject
	local existing = getMenuButtons()
	if existing then
		tryInject(existing)
	end
end)