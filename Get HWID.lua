local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local hashedHwid = utils.hash(hwid, "SHA-384")

print("-----------------------------------------------------------")
setclipboard(hashedHwid)

warn("Copied hwid to clipboard: ", hashedHwid)
warn("Copied hwid to clipboard: ", hashedHwid)
warn("Copied hwid to clipboard: ", hashedHwid)
warn("Copied hwid to clipboard: ", hashedHwid)
print("-----------------------------------------------------------")
local successSound = Instance.new("Sound", game:GetService("SoundService"))

successSound.SoundId = "rbxassetid://3450794184"
successSound.PlayOnRemove = true
successSound.Volume = 1
successSound:Destroy()