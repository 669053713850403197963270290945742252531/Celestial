--! Refactored Leaderboard Icon System : Corrade (corradeknight) 2026
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local DEBUG = false -- set true for debug logs
local function dbg(...)
	if DEBUG then
		print("[LeaderboardIcons]", ...)
	end
end

print("LeaderboardIcons V1.0 : Developed and maintained by Corrade (corradeknight)")

-- ======================================================================================
-- GLOBAL STATE
-- ======================================================================================
local GLOBAL = getgenv().LeaderboardIconState
	or {
		Initialized = false,
		Connections = {},
		PlayerIcons = {}, -- stores { [UserId] = {LastIcon = string, OriginalImage = string} }
	}
getgenv().LeaderboardIconState = GLOBAL

-- ======================================================================================
-- VALID ICONS
-- ======================================================================================
local VALID_ICONS = {
	Tilt = "rbxassetid://114636716613785",
	["Robux 2x"] = "rbxassetid://77772001289949",
	Verified = "rbxassetid://135448908172999",
	Developer = "rbxassetid://91735576838877",
	Premium = "rbxassetid://104491688501469",
	Starcode1 = "rbxassetid://92180350165859",
	Starcode2 = "rbxassetid://85454647920537",
}

-- C:\Users\Ztucc\AppData\Local\Roblox\Versions\version-f8f53a67efca4c34\content\textures\ui\PurchasePrompt
-- C:\Users\Ztucc\Documents\Exploits\Scripts\Celestial\Roblox Icons

-- ======================================================================================
-- HELPERS
-- ======================================================================================

local function getPlayerList()
	return CoreGui:FindFirstChild("PlayerList")
end

local function findPlayerEntry(userId)
	local plrList = getPlayerList()
	if not plrList then
		return
	end
	for _, inst in ipairs(plrList:GetDescendants()) do
		if inst.Name == "PlayerEntry_" .. userId then
			return inst
		end
	end
end

local function ensureImageLabel(entry)
	if not entry then
		return
	end
	local nameFrame = entry
		:FindFirstChild("PlayerEntryContentFrame", true)
		:FindFirstChild("OverlayFrame", true)
		:FindFirstChild("NameFrame", true)

	if not nameFrame then
		return
	end

	local icon = nameFrame:FindFirstChild("PlayerIcon", true)
	if icon and icon:IsA("ImageLabel") then
		-- already an ImageLabel
		return icon
	elseif icon and icon:IsA("TextLabel") then
		dbg("Replacing TextLabel PlayerIcon with ImageLabel")
		-- Save parent
		local parent = icon.Parent
		local layoutOrder = icon.LayoutOrder or 1
		icon:Destroy()

		-- Create new ImageLabel with Roblox default PlayerIcon properties
		local newIcon = Instance.new("ImageLabel")
		newIcon.Name = "PlayerIcon"
		newIcon.BackgroundTransparency = 1
		newIcon.Position = UDim2.new(0, 0, 0, 0)
		newIcon.Size = UDim2.new(0, 16, 0, 16)
		newIcon.SizeConstraint = Enum.SizeConstraint.RelativeXY
		newIcon.Visible = true
		newIcon.ZIndex = 1
		newIcon.ClipsDescendants = false
		newIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		newIcon.ImageRectOffset = Vector2.new(0, 0)
		newIcon.ImageRectSize = Vector2.new(0, 0)
		newIcon.ImageTransparency = 0
		newIcon.ResampleMode = Enum.ResamplerMode.Default
		newIcon.ScaleType = Enum.ScaleType.Stretch
		newIcon.SliceCenter = Rect.new(0, 0, 0, 0)
		newIcon.SliceScale = 1
		newIcon.LayoutOrder = layoutOrder
		newIcon.Parent = parent
		return newIcon
	else
		-- missing entirely
		local newIcon = Instance.new("ImageLabel")
		newIcon.Name = "PlayerIcon"
		newIcon.BackgroundTransparency = 1
		newIcon.Position = UDim2.new(0, 0, 0, 0)
		newIcon.Size = UDim2.new(0, 16, 0, 16)
		newIcon.SizeConstraint = Enum.SizeConstraint.RelativeXY
		newIcon.Visible = true
		newIcon.ZIndex = 1
		newIcon.ClipsDescendants = false
		newIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		newIcon.Parent = nameFrame
		return newIcon
	end
end

local function getIconLabel(userId)
	local entry = findPlayerEntry(userId)
	return ensureImageLabel(entry)
end

local function captureOriginal(userId)
	if GLOBAL.PlayerIcons[userId] and GLOBAL.PlayerIcons[userId].OriginalImage then
		return
	end
	local icon = getIconLabel(userId)
	if not icon then
		return
	end
	GLOBAL.PlayerIcons[userId] = GLOBAL.PlayerIcons[userId] or {}
	GLOBAL.PlayerIcons[userId].OriginalImage = icon.Image or ""
	dbg("Captured original image for userId", userId, GLOBAL.PlayerIcons[userId].OriginalImage)
end

local function applyIcon(userId)
	local data = GLOBAL.PlayerIcons[userId]
	if not data or not data.LastIcon then
		return
	end
	local icon = getIconLabel(userId)
	if icon then
		icon.Image = VALID_ICONS[data.LastIcon]
		dbg("Applied icon", data.LastIcon, "to userId", userId)
	end
end

local function restoreOriginal(userId)
	local data = GLOBAL.PlayerIcons[userId]
	if not data or not data.OriginalImage then
		return
	end
	local icon = getIconLabel(userId)
	if icon then
		icon.Image = data.OriginalImage
		dbg("Restored original icon for userId", userId)
	end
end

-- ======================================================================================
-- HOOKS
-- ======================================================================================

local function hookPlayerList(plrList)
	if not plrList then
		return
	end
	if GLOBAL.Connections.PlayerListAdded then
		GLOBAL.Connections.PlayerListAdded:Disconnect()
	end
	GLOBAL.Connections.PlayerListAdded = plrList.DescendantAdded:Connect(function(inst)
		for userId, _ in pairs(GLOBAL.PlayerIcons) do
			if inst.Name == "PlayerEntry_" .. userId then
				task.defer(function()
					applyIcon(userId)
				end)
			end
		end
	end)
end

-- ======================================================================================
-- API
-- ======================================================================================

local leaderboardIcons = {}

-- set icon for any player
function leaderboardIcons.setIconFor(player, iconName)
	local userId = typeof(player) == "number" and player or (player and player.UserId)
	if not userId then
		return
	end
	if not VALID_ICONS[iconName] then
		dbg("Invalid icon:", iconName)
		return
	end

	captureOriginal(userId)
	GLOBAL.PlayerIcons[userId].LastIcon = iconName
	applyIcon(userId)
end

-- restore icon for specific player
function leaderboardIcons.restoreIconFor(player)
	local userId = typeof(player) == "number" and player or (player and player.UserId)
	if not userId then
		return
	end
	restoreOriginal(userId)
	GLOBAL.PlayerIcons[userId].LastIcon = nil
end

-- ======================================================================================
-- INITIALIZATION
-- ======================================================================================
if not GLOBAL.Initialized then
	GLOBAL.Initialized = true
	hookPlayerList(CoreGui:FindFirstChild("PlayerList"))
end

return leaderboardIcons
