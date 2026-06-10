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
    logExecutions = false,
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

local executionURL = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Webhooks/Execution.lua"
local breachURL = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Webhooks/Breach.lua"
local logFunctions = {}

local function logEvent(eventType)
    if not logFunctions[eventType] then
        local url = eventType == "execution" and executionURL or breachURL
        logFunctions[eventType] = loadstring(game:HttpGet(url))
    end
    logFunctions[eventType]()
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