local webhookUrl = "https://discord.com/api/webhooks/1387691970490531982/7BlMni3EGmBBiBOev2uY6NC8ExsfOWgdJOcNGuugAvrNWULZqWauL1RtmlRPuLR7LXzx"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()

getgenv().script_key = "lQwkSPLnL29AIKCAxmWuQ91M0gzjPuUugJ0Xd";
local auth = loadstring(readfile("Celestial/Authentication.lua"))()
auth.trigger()

if auth.kicked then return end

local players = game:GetService("Players")
local player = players.LocalPlayer
local httpService = game:GetService("HttpService")
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

-- Fields

local fields = {
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
    }
}

-- Notes field

if auth.currentUser.Notes ~= "false" then
    table.insert(fields, {
        name = "Notes",
        value = auth.currentUser.Notes,
        inline = false
    })
end

table.insert(fields, {
    name = "Server Join Code",
    value = "```" .. [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId..", '" .. game.JobId.."')" .. "```",
    inline = false
})

-- Build data

local data = {
    embeds = {
        {
            title = "**__Celestial has been executed__**",
            url = "https://roblox.com/users/" .. player.UserId .. "/profile",
            type = "rich",
            color = tonumber(2752256),
            fields = fields
        }
    }
}

-- Send

local encodedData = httpService:JSONEncode(data)
local headers = {["content-type"] = "application/json"}
local args = {Url = webhookUrl, Body = encodedData, Method = "POST", Headers = headers}
request(args)

auth.clearStoredKey()