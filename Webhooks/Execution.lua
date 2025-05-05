local webhookUrl = "https://discord.com/api/webhooks/1326062100014956605/o5QafnNyezs4UmfSZyIdMTvU81EcBQO11EEt3oaHchYXbkj12qzIQ6SugVhErSC6hATh"

local utils = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Core%20Utilities.lua?ref_type=heads"))()
local auth = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Authentication.lua?ref_type=heads"))()
auth.trigger()

local players = game:GetService("Players")
local player = players.LocalPlayer
local httpService = game:GetService("HttpService")
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

if not auth.isUser() or auth.kicked then
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
                    name = "Identifier",
                    value = auth.currentUser.Identifier,
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
                    value = "||" .. auth.hwid("Hashed") .. "||",
                    inline = true
                },

                {
                    name = "HWID [Dehashed]",
                    value = "||" .. auth.hwid("Normal") .. "||",
                    inline = true
                },

                {
                    name = "Key",
                    value = "||" .. auth.currentUser.Key .. "||",
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