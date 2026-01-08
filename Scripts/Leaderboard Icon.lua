-- game:GetService("CoreGui").PlayerList.Children.OffsetFrame.PlayerScrollList.SizeOffsetFrame.ScrollingFrameContainer.ScrollingFrameClippingFrame.ScrollingFrame.OffsetUndoFrame.TeamList_Neutral.PlayerEntry_3881598914.PlayerEntryContentFrame.OverlayFrame.NameFrame.PlayerIcon

local CoreGui = game:GetService("CoreGui")
local playerList = CoreGui:WaitForChild("PlayerList")

local player = game:GetService("Players")
local localUserId = game:GetService("Players").LocalPlayer.UserId

local function findPlayerEntry(userId)
	for _, inst in ipairs(playerList:GetDescendants()) do
		if inst.Name == ("PlayerEntry_" .. userId) then
			return inst
		end
	end
end

local entry = findPlayerEntry(localUserId)
print(entry)

if not entry then
    warn("[ERROR] Failed to determine your playerlist entry.")
    return
end