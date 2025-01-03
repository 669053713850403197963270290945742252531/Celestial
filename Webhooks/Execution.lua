local webhookUrl = "https://discord.com/api/webhooks/1264103527165198376/zcTnP6tevI4KTzCBFmBUYyZeTsmveU4ELQcZoYw7hl3CLOQiUEip25yf9Qw5aZAOT8lp"

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Authentication.lua"))()

local players = game:GetService("Players")
local player = players.LocalPlayer
local httpService = game:GetService("HttpService")
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

if not auth.isUser() then
    player:Kick("Not authorized.")
    return
end

-- Embed

local data = {
    embeds = {
        {
            title = "**__Celestial has been executed__**",
            type = "rich",
            color = tonumber(2752256),
            fields = {
                {
                    name = "Execution Date",
                    value = "**" .. os.date("%x") .. " | " .. utils.getTime(true) .. " : " .. os.date("%Z") .. "**",
                    inline = true
                },

                {
                    name = "",
                    value = "[**" .. player.DisplayName .. "**'s Profile](https://roblox.com/users/" .. player.UserId .. "/profile)",
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
                    name = "Server Join Code",
                    value = "```" .. [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId..", '" .. game.JobId.."')" .. "```",
                    inline = true
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