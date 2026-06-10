local webhookUrl = "https://discord.com/api/webhooks/1514052412971683940/7-CFUCneSvs-dW4Aq0mCXHYDOVcZ95ahgWvDrTt_ldIl8t0_dRItt8s5sK5jZZpKVeL1"
local embedLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Embed%20Library.lua"))()

print("1")
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Authentication.lua"))()

print("2")
local players = game:GetService("Players")
local player = players.LocalPlayer
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local authUser = auth.getUser()

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

embedLib.addField(embed, "Timezone", "**" .. os.date("%Z") .. "**", true)
embedLib.addField(embed, "Linked Account", "<@" .. authUser.DiscordId .. ">", true)
embedLib.addField(embed, "", "[Game Page](https://www.roblox.com/games/" .. game.PlaceId .. ")", true)
embedLib.addField(embed, "Identifier", authUser.Identifier, true)
embedLib.addField(embed, "Account Age", player.AccountAge .. " Days", true)
embedLib.addField(embed, "Owner", "`" .. tostring(auth.isOwner()) .. "`", true)
embedLib.addField(embed, "Exploit", identifyexecutor(), true)
embedLib.addField(embed, "HWID", "||" .. auth.hwid("Hashed") .. "||", true)
embedLib.addField(embed, "HWID [Dehashed]", "||" .. auth.hwid("Normal") .. "||", true)
embedLib.addField(embed, "Key", "||" .. authUser.Key .. "||", true)

-- Conditional fields

if authUser.Notes and authUser.Notes ~= "false" then
    embedLib.addField(embed, "Notes", "```" .. authUser.Notes .. "```", true)
end

embedLib.addField(embed, "Server Join Code", "```" .. [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId .. ", '" .. game.JobId .. "')" .. "```", false)

-- Send

embedLib.sendEmbed(embed, "Celestial", "Celestial")