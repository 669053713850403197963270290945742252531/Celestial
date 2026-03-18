repeat task.wait() until game:IsLoaded()

local settingsShield = game:GetService("CoreGui").RobloxGui.SettingsClippingShield.SettingsShield.MenuContainer

-- Preventing multiple script executions

for _, inst in pairs(settingsShield.Page.BottomButtonFrame:GetDescendants()) do
    if inst.Name == "RejoinButton" then
        warn("Cannot overwrite the current rejoin button.")
        return
    end
end

--------- CONSTANTS --------------

local respawnButton = settingsShield.Page.BottomButtonFrame.ResetCharacterButtonButton
local newButtonsFolder = Instance.new("Folder", respawnButton.Parent)

local uis = game:GetService("UserInputService")
local tps = game:GetService("TeleportService")
local localplayer = game:GetService("Players").LocalPlayer

---------- FUNCTIONS ---------

local function isSettingShieldShieldVisible()
    local settingsShieldSingle = game:GetService("CoreGui").RobloxGui.SettingsClippingShield.SettingsShield
    return settingsShieldSingle.Visible
end

local function rejoin()
    tps:Teleport(game.PlaceId, localplayer)
end

-------------- INSTANCES --------------

-- Tweak UIListLayout of the bottom button container to accommodate the rejoin button

local buttonLayout = game:GetService("CoreGui").RobloxGui.SettingsClippingShield.SettingsShield.MenuContainer.Page.BottomButtonFrame.UIListLayout
local buttonFrame = game:GetService("CoreGui").RobloxGui.SettingsClippingShield.SettingsShield.MenuContainer.Page.BottomButtonFrame

buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
buttonFrame.Size = UDim2.new(1, 0, 0, 113)

-- Creating the new button
local newButton = respawnButton:Clone()
newButton.Parent = newButtonsFolder
newButton.Name = "RejoinButton"
newButton.Position = UDim2.new(0.5, -131, 0.5, -55)

-- Modifying the labels of the new button

if not newButton:FindFirstChild("ResetCharacterButtonTextLabel") then return end
local text = newButton.ResetCharacterButtonTextLabel
text.Name = "RejoinButtonText"
text.Text = "Rejoin"

-- Triggering the rejoin function on button click. This is placed before the hover events because roblox is SHIT. i might be coping. just a lil bit

newButton.MouseButton1Click:Connect(function()
    newButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    newButton.BackgroundTransparency = 1
    rejoin()
end)

-- Bringing back the original button effects
newButton.MouseEnter:Connect(function()
    newButton.BackgroundColor3 = Color3.fromRGB(56, 57, 59)
    newButton.BackgroundTransparency = 0
end)

newButton.MouseLeave:Connect(function()
    newButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    newButton.BackgroundTransparency = 1
end)

-- Applying the custom hint image

local hint = newButton.ResetCharacterHint
hint.Image = "rbxassetid://125851991683380"

-- Triggering the rejoin function on keybind

uis.InputBegan:Connect(function(input)
	if (uis:GetFocusedTextBox()) then
		return -- Prevent activation from textboxes such as chat
	end

	if input.KeyCode == Enum.KeyCode.J then
		if isSettingShieldShieldVisible() then rejoin() end

        -- Mimicking the hovering behavior
        newButton.BackgroundColor3 = Color3.fromRGB(56, 57, 59)
        newButton.BackgroundTransparency = 0
        task.wait(0.05)
        -- Mimicking the unhover behavior
        newButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        newButton.BackgroundTransparency = 1
	end	
end)