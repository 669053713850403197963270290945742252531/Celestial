local webhookUrl = "https://discord.com/api/webhooks/1324865889610498049/scgOM1LB-40-a8B-PgqEQU8lWnoMExewy-wVRwBQLHXSOiUJlokOv03O242-2h3tWpH7"

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Authentication.lua"))()

local players = game:GetService("Players")
local player = players.LocalPlayer
local httpService = game:GetService("HttpService")
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

if not auth.isUser() then
    player:Kick("Not authorized. Your hardware id has been copied to your clipboard.")
    setclipboard(auth.hwid("Hashed"))
    return
end

-- Embed

local data = {
    embeds = {
        {
            title = "**__Celestial has been executed__**",
            url = "https://roblox.com/users/" .. player.UserId .. "/profile)",
            type = "rich",
            color = tonumber(2752256),
            fields = {
                {
                    name = "Execution Date",
                    value = "**" .. os.date("%x") .. " | " .. utils.getTime(true) .. " : " .. os.date("%Z") .. "**",
                    inline = true
                },

                {
                    name = "Linked Account",
                    value = "<@" .. auth.currentUser.DiscordId .. ">",
                    inline = true
                },

                {
                    name = "",
                    value = "[Game Page](https://www.roblox.com/games/" .. game.PlaceId .. ")",
                    inline = true
                },

                {
                    name = "Name",
                    value = player.DisplayName .. " (@" .. player.Name .. ")",
                    inline = true
                },
    
                {
                    name = "Account Age",
                    value = player.AccountAge .. " Days",
                    inline = true
                },

                {
                    name = "Owner",
                    value = auth.isOwner(),
                    inline = true
                },

                {
                    name = "Exploit",
                    value = identifyexecutor(),
                    inline = true
                },

                {
                    name = "HWID",
                    value = "||" .. auth.hwid("Normal") .. "||",
                    inline = true
                },

                {
                    name = "HWID [Hashed]",
                    value = "||" .. auth.hwid("Hashed") .. "||",
                    inline = true
                },

                {
                    name = "Notes",
                    value = "```" .. auth.currentUser.Notes .. "```",
                    inline = false
                },

                {
                    name = "Server Join Code",
                    value = "```" .. [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId..", '" .. game.JobId.."')" .. "```",
                    inline = false
                },
               }
           }
       }
    }

    local encodedData = httpService:JSONEncode(data)

    local headers = {
        ["content-type"] = "application/json"
     }

     local args = {Url = webhookUrl, Body = encodedData, Method = "POST", Headers = headers}
     request(args)

     print("processed")