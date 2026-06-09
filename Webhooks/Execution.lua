local webhookUrl = "https://discord.com/api/webhooks/1514040672431374506/TJBm2XLMOcPftkn7EWgMYt7MbroTRedf_GLRFSNUlYMdMPbvnpVbOTE_nxR1R_8Zboop"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()
local embedLib = loadstring(readfile("Celestial/Libraries/Embed Library.lua"))() --[[loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Embed%20Library.lua"))()]]

local auth = loadstring(readfile("Celestial/Authentication.lua"))()
auth.trigger()

if auth.kicked then return end

local players = game:GetService("Players")
local player = players.LocalPlayer
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

-- Build embed

local embed = embedLib.createEmbed({
    webhookUrl = webhookUrl,
    title = "**__Celestial has been executed__**",
    url = "https://roblox.com/users/" .. player.UserId .. "/profile",
    color = Color3.fromRGB(0, 170, 0), -- #00AA00 = 2752256
    author = {
        name = "Celestial",
        icon_url = "Celestial"
    },
    footer = {
        enabled = true,
        displaySeconds = true,
        icon = "Celestial"
    }
})

-- Add fields

embedLib.addField(embed, "Execution Date", "**" .. os.date("%x") .. " | " .. utils.getTime(true) .. " : " .. os.date("%Z") .. "**", true)
embedLib.addField(embed, "Linked Account", "<@" .. auth.currentUser.DiscordId .. ">", true)
embedLib.addField(embed, "", "[Game Page](https://www.roblox.com/games/" .. game.PlaceId .. ")", true)
embedLib.addField(embed, "Identifier", auth.currentUser.Identifier, true)
embedLib.addField(embed, "Account Age", player.AccountAge .. " Days", true)
embedLib.addField(embed, "Owner", tostring(auth.isOwner()), true)
embedLib.addField(embed, "Exploit", identifyexecutor(), true)
embedLib.addField(embed, "HWID", "||" .. auth.hwid("Hashed") .. "||", true)
embedLib.addField(embed, "HWID [Dehashed]", "||" .. auth.hwid("Normal") .. "||", true)
embedLib.addField(embed, "Key", "||" .. auth.currentUser.Key .. "||", true)

-- Conditional fields

if auth.currentUser.Notes and auth.currentUser.Notes ~= "false" then
    embedLib.addField(embed, "Notes", auth.currentUser.Notes, false)
end

--embedLib.addField(embed, "Server Join Code", "```" .. [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId .. ", '" .. game.JobId .. "')" .. "```", false)

-- Send

embedLib.sendEmbed(embed, "Celestial", "Celestial")