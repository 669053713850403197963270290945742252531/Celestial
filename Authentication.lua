while not game:IsLoaded() do task.wait() end

local auth = {}

local player = game:GetService("Players").LocalPlayer
local httpService = game:GetService("HttpService")
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()

local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local hashedHWID = utils.hash(hwid, "SHA-384")

-- Config
local authConfig = {
    logExecutions = false,
    logBreaches = false
}

auth.currentUser = nil
auth.kicked = false

-- Save originals early
local originalNamecall = getrawmetatable(game).__namecall
local realKick
realKick = hookfunction(player.Kick, function(...)
    return realKick(...)
end)

local originalKickAfterHook = player.Kick
local realIdentifyExecutor = identifyexecutor

-- Forward declare originalTrigger
local originalTrigger

-- Fetch whitelist
local function fetchData(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        realKick(player, "Failed to fetch data from URL: " .. url)
        auth.kicked = true
        return nil
    end

    local successDecode, data = pcall(function()
        return httpService:JSONDecode(response)
    end)

    if not successDecode then
        realKick(player, "Failed to decode JSON data from URL: " .. url)
        auth.kicked = true
        return nil
    end

    return data
end

-- URLs
local whitelistURL = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Users.json"
local whitelistedUsers = fetchData(whitelistURL)
if not whitelistedUsers then
    realKick(player, "Failed to retrieve the whitelist.")
    auth.kicked = true
    return
end

-- Logging function
local function logEvent(eventType)
    local url = ""
    if eventType == "execution" then
        url = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Webhooks/Execution.lua"
    elseif eventType == "breach" then
        url = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Webhooks/Breach.lua"
    end

    if url ~= "" then
        loadstring(game:HttpGet(url))()
    end
end

-- Authorization check
for _, user in ipairs(whitelistedUsers) do
    if user.HWID == hashedHWID then
        auth.currentUser = user
    end
end

auth.isUser = function()
    return auth.currentUser ~= nil
end

auth.isAuthorized = function()
    for _, user in ipairs(whitelistedUsers) do
        if user.HWID == hashedHWID then
            auth.currentUser = user
            return true, user
        end
    end
    auth.currentUser = nil
    return false, nil
end

auth.isOwner = function()
    local authorized, user = auth.isAuthorized()
    return authorized and user and user.Rank == "Owner"
end

auth.fetchConfig = function(configName)
    if typeof(configName) ~= "string" or configName == nil then
        warn("auth.fetchConfig: Invalid config name.")
        return "Failed: Check console for more information."
    end

    configName = string.lower(configName)

    for key, value in pairs(authConfig) do
        if string.lower(key) == configName then
            return value
        end
    end

    warn("auth.fetchConfig: Config not found.")
    return "Failed: Check console for more information."
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

-- Unsupported exploit check
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

    local exec = realIdentifyExecutor()
    if not supported[exec] then
        realKick(player, "Celestial does not support " .. exec)
    end
end

-- Main trigger authorization function
auth.trigger = function()
    if not whitelistedUsers then
        realKick(player, "Failed to retrieve whitelist.")
        auth.kicked = true
        return
    end

    local isAuthorized, userData = auth.isAuthorized()
    if isAuthorized and userData then
        local scriptKey = getgenv().script_key
        if typeof(scriptKey) ~= "string" or userData.Key ~= scriptKey then
            if authConfig.logBreaches then logEvent("breach") end
            setclipboard(scriptKey or "nil")
            realKick(player, "Invalid script key: " .. tostring(scriptKey))
            auth.kicked = true
            return
        end
        if authConfig.logExecutions then logEvent("execution") end
    else
        setclipboard(hashedHWID)
        warn("Invalid HWID: copied to clipboard.")
        return
    end
end

auth.clearStoredKey = function()
    if typeof(getgenv().script_key) ~= "nil" then
        getgenv().script_key = nil
    else
        warn("auth.clearStoredKey: No key to clear.")
    end
end

-- Save the original trigger
originalTrigger = auth.trigger

-- The core anti-hook check function
local rawExecutor = identifyexecutor
function auth.runAntiHookChecks()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local success, err

    if mt.__namecall ~= originalNamecall then
        setreadonly(mt, true)
        realKick(player, "Tampering detected: __namecall metamethod hooked.")
        return false
    end

    if player.Kick ~= originalKickAfterHook then
        setreadonly(mt, true)
        realKick(player, "Tampering detected: Kick function hooked.")
        return false
    end

    if auth.trigger ~= originalTrigger then
        setreadonly(mt, true)
        realKick(player, "Tampering detected: auth.trigger overwritten.")
        return false
    end

    if identifyexecutor ~= rawExecutor then
        setreadonly(mt, true)
        realKick(player, "Tampering detected: exploit identification tampered.")
        return false
    end

    setreadonly(mt, true)
    return true
end

task.defer(function()
    task.wait(10)
    auth.runAntiHookChecks()
end)

return auth
