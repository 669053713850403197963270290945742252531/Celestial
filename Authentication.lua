while not game:IsLoaded() do
    task.wait()
end

local auth = {}

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Core%20Utilities.lua"))()

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local httpService = game:GetService("HttpService")
local hashedHWID = utils.hash(hwid, "SHA-384")

-- Configuration

local authConfig = {
    logExecutions = false,
    logBreaches = false
}

auth.currentUser = nil
auth.kicked = false

-- Making the whitelist modular

local function fetchData(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local successDecode, data = pcall(function()
            --print(response)
            return httpService:JSONDecode(response)
        end)

        if successDecode then
            return data
        else
            player:Kick("Failed to decode JSON data from URL: ", url)
            auth.kicked = true
            return
        end
    else
        player:Kick("Failed to fetch data from URL: ", url)
        auth.kicked = true
        return
    end
    return nil
end

-- URL fetching


local whitelistURL = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Users.json?ref_type=heads"
local whitelistedUsers = fetchData(whitelistURL)

if not whitelistedUsers then
    player:Kick("Failed to retrieve the whitelist.")
    auth.kicked = true
    return
end


-- Logging


local function logEvent(eventType)
    local url = ""
    if eventType == "execution" then
        url = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Webhooks/Execution.lua?ref_type=heads"
    elseif eventType == "breach" then
        url = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Webhooks/Breach.lua?ref_type=heads"
    end

    if url ~= "" then
        loadstring(game:HttpGet(url))()
    end
end


-- Verify authentication

for _, user in ipairs(whitelistedUsers) do
    if user.HWID == hashedHWID then
        auth.currentUser = user -- Set the current user
    end
end

auth.isUser = function()
    return auth.currentUser ~= nil
end

auth.isAuthorized = function()
    for _, user in ipairs(whitelistedUsers) do
        if user.HWID == hashedHWID then
            auth.currentUser = user -- Set the current user
            return true, user
        end
    end
    auth.currentUser = nil -- Reset if not authorized
    return false, nil
end

auth.isOwner = function()
    local isAuthorized, user = auth.isAuthorized()
    return isAuthorized and user and user.Rank == "Owner"
end

auth.fetchConfig = function(configName)
    -- Checks

    if typeof(configName) ~= "string" or configName == nil then
        warn("Argument #1 (configName) expected a string value and a valid config name but got a " .. typeof(configName) .. " value and an invalid config name.")
        return "Failed: Check console for more information."
    end

    configName = string.lower(configName)

    -- Check if the given configName matches a value inside authConfig

    for key, value in pairs(authConfig) do
        if string.lower(key) == configName then
            return value
        end
    end

    -- If no match is found

    warn("Argument #1 (configName) expected a valid config name.")
    return "Failed: Check console for more information."
end

auth.hwid = function(mode)
    local validModes = {
        "Normal",
        "Hashed"
    }

    -- Check

    local isValid = false
    for _, validMode in ipairs(validModes) do
        if mode == validMode then
            isValid = true
            break
        end
    end

    if not isValid then
        warn("auth.hwid | " .. mode .. " is not a valid mode.")
        return
    end

    -- Mode

    if mode == "Normal" then
        return hwid
    else
        return hashedHWID
    end
end

-- Handling unsupported exploits

auth.exploitSupported = function()
    local exploits = {
        ["AWP"] = true,
        ["Wave"] = true,
        ["Synapse Z"] = true,
        ["Zenith"] = true,
        ["Seliware"] = true,
        ["Volcano"] = true,
        
        ["Visual"] = true,
        ["Solara"] = true
    }

    local currentExploit = identifyexecutor()

    if exploits[currentExploit] then
        return true
    else
        player:Kick("Celestial does not support " .. identifyexecutor() .. ".")
    end
end

auth.trigger = function()
    if not whitelistedUsers then
        player:Kick("Failed to retrieve whitelist.")
        auth.kicked = true
        return
    end

    local isAuthorized, userData = auth.isAuthorized() -- Check authorization

    if isAuthorized and userData then
        -- Handle bans

        if userData.Banned and userData.Rank ~= "Owner" then
            if userData.TempBan then
                player:Kick("\nYou are temporarily banned from using this service for " .. userData.TempBanDuration .. ". You will be unbanned on " .. userData.TempBanEnd .. ".\nReason: " .. (userData.BanReason or "No reason provided."))
                auth.kicked = true
                return
            else
                player:Kick("\nYou are permanently banned from using this service.\nReason: " .. (userData.BanReason or "No reason provided."))
                auth.kicked = true
                return
            end
        end

        -- Handle invalid keys

        local scriptKey = getgenv().script_key
        if userData.Key ~= scriptKey then
            if authConfig.logBreaches then logEvent("breach") end
        
            local keyDisplay = typeof(scriptKey) == "string" and scriptKey or "None"
            player:Kick("The provided key is invalid: " .. keyDisplay)
        
            auth.kicked = true
            return
        else
            if authConfig.logExecutions then logEvent("execution") end
        end
        
        
    else
        -- Handle invalid HWID

        setclipboard(hashedHWID)
        warn("Invalid HWID: Your hardware ID has been copied to your clipboard.")
        return
    end
end

auth.clearStoredKey = function()
    if typeof(getgenv().script_key) ~= "nil" then
        getgenv().script_key = nil
    else
        warn("auth.clearRestoredKey: No stored key.")
    end
end

return auth