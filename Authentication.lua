repeat task.wait() until game:IsLoaded()

local auth = {}

local player = game:GetService("Players").LocalPlayer
local httpService = game:GetService("HttpService")
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()

-- Capture originals before anything can hook them
local originalKick = player.Kick

local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local hashedHWID = utils.hash(hwid, "SHA-384")

local authConfig = {
    logExecutions = true,
    logBreaches = false,
    autoTrigger = true  -- set to false when loading as a utility library
}

-- Private local — never on the auth table
local currentUser = nil
local kicked = false

-- Fetch whitelist

local function fetchData(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        player:Kick("Failed to fetch data from URL: " .. url)
        kicked = true
        return nil
    end

    local successDecode, data = pcall(function()
        return httpService:JSONDecode(response)
    end)

    if not successDecode then
        player:Kick("Failed to decode JSON data from URL: " .. url)
        kicked = true
        return nil
    end

    return data
end

local whitelistURL = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Users.json"
local whitelistedUsers = fetchData(whitelistURL)
if not whitelistedUsers then
    player:Kick("Failed to retrieve the whitelist.")
    kicked = true
    return
end

-- Auth check

-- Auth check — populate private local
for _, user in ipairs(whitelistedUsers) do
    if user.HWID == hashedHWID then
        currentUser = user  -- private local, not auth.currentUser
    end
end

-- Private, unexposed version
local function isAuthorizedInternal()
    if currentUser then
        return true, currentUser
    end
    return false, nil
end

-- Public facing one still exists for your other scripts
auth.isAuthorized = newcclosure(function()
    return isAuthorizedInternal()
end)

-- Read-only getter for external scripts
-- Returns a copy so callers can't mutate the original
auth.getUser = newcclosure(function()
    if currentUser == nil then return nil end
    return {
        Identifier = currentUser.Identifier,
        HWID = currentUser.HWID,
        DiscordId = currentUser.DiscordId,
        Key = currentUser.Key,
        JoinDate = currentUser.JoinDate,
        Rank = currentUser.Rank,
        Notes = currentUser.Notes
    }
end)

auth.isKicked = newcclosure(function()
    return kicked
end)




auth.isUser = newcclosure(function()
    return currentUser ~= nil
end)

auth.isOwner = newcclosure(function()
    return currentUser ~= nil and currentUser.Rank == "Owner"
end)

auth.fetchConfig = function(configName)
    if type(configName) ~= "string" then
        warn("Argument #1 (configName) expected a string value and a valid config name but got a " .. typeof(configName) .. " value and an invalid config name.")
        return nil
    end

    configName = string.lower(configName)

    for key, value in pairs(authConfig) do
        if string.lower(key) == configName then
            return value
        end
    end

    warn("auth.fetchConfig: Config not found.")
end

auth.hwid = function(mode)
    if mode == "Normal" then
        return hwid
    elseif mode == "Hashed" then
        return hashedHWID
    else
        warn("auth.hwid: Invalid mode.")
        return
    end
end

auth.exploitSupported = function()
    local supported = {
        ["AWP"] = true,
        ["Wave"] = true,
        ["Synapse Z"] = true,
        ["Zenith"] = true,
        ["Seliware"] = true,
        ["Volcano"] = true,
        ["Potassium"] = true,
        ["Visual"] = false,
        ["Solara"] = false
    }

    local exec = identifyexecutor()
    if not supported[exec] then
        player:Kick("Celestial does not support " .. exec)
        kicked = true
    end

    return true
end

auth.clear = function()
    if getgenv().script_key ~= nil then
        getgenv().script_key = nil
    else
        if not auth.isUser() then return end
        warn("auth.clear: No key to clear.")
    end
end

local function logEvent(eventType)
    if eventType == "execution" then
        print("erherheherh")
        local webhookUrl = "https://discord.com/api/webhooks/1514052412971683940/7-CFUCneSvs-dW4Aq0mCXHYDOVcZ95ahgWvDrTt_ldIl8t0_dRItt8s5sK5jZZpKVeL1"
        local embedLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Embed%20Library.lua"))()

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
    elseif eventType == "breach" then
        local webhookUrl = "https://discord.com/api/webhooks/1514036528500965548/A5Kt2C4hJb2z_UYRSuI71E4h2-7v1q6IY528-EyB06frKL6Xu8RdDrsDnRNy0BIZmraV"
        local embedLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Embed%20Library.lua"))()

        local isUser = auth.isUser()
        local user = auth.getUser()

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
    else
        warn("Invalid event type.")
    end
end

-- ================ PROTECTION ================

-- Private trigger — not on the auth table, unreachable from outside
local function internalTrigger()
    if not whitelistedUsers then
        warn("[Celestial] Whitelist is nil.")
        player:Kick("Failed to retrieve whitelist.")
        kicked = true
        return
    end

    local isAuthorized, userData = isAuthorizedInternal()  -- private, not auth.isAuthorized

    if isAuthorized and userData then
        local scriptKey = getgenv().script_key

        if typeof(scriptKey) ~= "string" or userData.Key ~= scriptKey then
            warn("[Celestial] Invalid or missing script key.")
            if authConfig.logBreaches then logEvent("breach") end
            setclipboard(scriptKey or "nil")
            player:Kick("Invalid script key: " .. tostring(scriptKey))
            kicked = true
            return
        end

        if authConfig.logExecutions then logEvent("execution") end
    else
        warn("[Celestial] Not authorized. Copying HWID to clipboard.")
        setclipboard(hashedHWID)
        if authConfig.logBreaches then logEvent("breach") end
        player:Kick("You are not authorized to use this script.")
        kicked = true
    end
end

-- Public facing trigger delegates to the private local
-- Overwriting auth.trigger from outside has no effect on internalTrigger
auth.trigger = function()
    internalTrigger()
end

local runAntiHookChecks = function()

    -- 1. Kick
    local currentKick = player.Kick
    if not rawequal(currentKick, originalKick) or isfunctionhooked(originalKick) then
        if authConfig.logBreaches then logEvent("breach") end
        player:Kick("Tampering detected: Kick function has been overwritten.")
        kicked = true
        return false
    end

    -- 2. identifyexecutor
    if isfunctionhooked(identifyexecutor) then
        if authConfig.logBreaches then logEvent("breach") end
        player:Kick("Tampering detected: identifyexecutor has been hooked.")
        kicked = true
        return false
    end

    return true
end

auth.runAntiHookChecks = runAntiHookChecks

-- Run auth on load — before any external script can interfere
if authConfig.autoTrigger and not getgenv()._celestial_noauth then
    internalTrigger()
end
getgenv()._celestial_noauth = nil  -- clean up after

game:GetService("RunService").Heartbeat:Connect(newcclosure(function()
    if kicked then return end
    runAntiHookChecks()
end))

return auth