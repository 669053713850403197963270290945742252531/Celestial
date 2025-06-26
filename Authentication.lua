while not game:IsLoaded() do task.wait() end

local auth = {}

local player = game:GetService("Players").LocalPlayer
local httpService = game:GetService("HttpService")
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()

local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local hashedHWID = utils.hash(hwid, "SHA-384")

-- Config
local authConfig = {
    logExecutions = true,
    logBreaches = true
}

auth.currentUser = nil
auth.kicked = false

-- Save original Kick function early
local originalKick = player.Kick -- Store the original Kick function
auth._originalKick = originalKick -- Save it for later checks

-- Hook the Kick function to prevent any tampering
local realKick = hookfunction(player.Kick, function(...)
    return realKick(...) -- Call the original Kick function
end)

local originalTrigger
local realIdentifyExecutor = identifyexecutor

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

-- Execution log lock (persistent per session)
getgenv()._celestial_logged_breach = getgenv()._celestial_logged_breach or false
getgenv()._celestial_logged_execution = getgenv()._celestial_logged_execution or false

local function logEvent(eventType)
    -- Block duplicate logs
    if eventType == "execution" and getgenv()._celestial_logged_execution then return end
    if eventType == "breach" and getgenv()._celestial_logged_breach then return end

    local url = ""
    if eventType == "execution" then
        url = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Webhooks/Execution.lua"
        warn("[Celestial] Execution log sent.")
        getgenv()._celestial_logged_execution = true
    elseif eventType == "breach" then
        url = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Webhooks/Breach.lua"
        warn("[Celestial] Breach log sent.")
        getgenv()._celestial_logged_breach = true
    end

    if url ~= "" then
        pcall(function()
            loadstring(game:HttpGet(url))()
        end)
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

    warn(logEvent("execution"))
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

    local exec = identifyexecutor()
    if not supported[exec] then
        realKick(player, "Celestial does not support " .. exec)
        auth.kicked = true
    end

    return true
end

-- Main trigger authorization function
auth.trigger = function()
    print("[Celestial] Trigger called.")

    if not whitelistedUsers then
        warn("[Celestial] Whitelist is nil.")
        realKick(player, "Failed to retrieve whitelist.")
        auth.kicked = true
        return
    end

    local isAuthorized, userData = auth.isAuthorized()
    print("[Celestial] isAuthorized =", isAuthorized)
    print("[Celestial] userData =", userData and userData.Key or "nil")

    if isAuthorized and userData then
        local scriptKey = getgenv().script_key
        print("[Celestial] scriptKey =", scriptKey)
        print("[Celestial] expected =", userData.Key)

        if typeof(scriptKey) ~= "string" or userData.Key ~= scriptKey then
            warn("[Celestial] Invalid or missing script key.")
            if authConfig.logBreaches then logEvent("breach") end
            setclipboard(scriptKey or "nil")
            player:Kick("Invalid script key: " .. tostring(scriptKey))
            auth.kicked = true
            return
        end

        warn("[Celestial] Passed all checks. Logging execution.")
        if authConfig.logExecutions then logEvent("execution") end
    else
        warn("[Celestial] Not authorized. Copying HWID to clipboard.")
        setclipboard(hashedHWID)
    end
end


local originalTrigger = auth.trigger

auth.clearStoredKey = function()
    if typeof(getgenv().script_key) ~= "nil" then
        getgenv().script_key = nil
    else
        warn("auth.clearStoredKey: No key to clear.")
    end
end

-- Save original __namecall before anything else
local mt = getrawmetatable(game)
setreadonly(mt, false)
local originalNamecall = mt.__namecall
setreadonly(mt, true)

-- Anti-hook check
function auth.runAntiHookChecks()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    if mt.__namecall ~= originalNamecall then
        setreadonly(mt, true)
        if authConfig.logBreaches then logEvent("breach") end
        realKick(player, "Tampering detected: __namecall metamethod hooked.")
        auth.kicked = true
        return false
    end

    -- Ensure Kick function cannot be overwritten
    local currentKick = player.Kick
    if not rawequal(currentKick, originalKick) then
        setreadonly(mt, true)
        if authConfig.logBreaches then logEvent("breach") end
        realKick(player, "Tampering detected: Kick function has been overwritten.")
        auth.kicked = true
        return false
    end

    if not rawequal(auth.trigger, originalTrigger) then
        setreadonly(mt, true)
        if authConfig.logBreaches then logEvent("breach") end
        realKick(player, "Tampering detected: auth.trigger overwritten.")
        auth.kicked = true
        return false
    end

    local currentExecutor = identifyexecutor()
    local expectedExecutor = realIdentifyExecutor()

    if currentExecutor ~= expectedExecutor then
        setreadonly(mt, true)
        if authConfig.logBreaches then logEvent("breach") end
        realKick(player, "Tampering detected: exploit identification mismatch (" .. tostring(currentExecutor) .. " vs " .. tostring(expectedExecutor) .. ").")
        auth.kicked = true
        return false
    end

    setreadonly(mt, true)
    return true
end

-- Run the check after a small delay
if not getgenv()._antiHookStarted then
    getgenv()._antiHookStarted = true

    task.defer(function()
        task.wait(5)
        auth.runAntiHookChecks()
    end)
end

auth.trigger()
return auth