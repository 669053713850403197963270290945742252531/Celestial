while not game:IsLoaded() do
    task.wait()
end

local auth = {}

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local httpService = game:GetService("HttpService")
local hashedHWID = utils.hash(hwid, "SHA-384")

-- Configuration

local authConfig = {
    logExecutions = false,
    logBreaches = false,
    notifyExecution = true,
    currentUser = nil
}

auth.currentUser = nil

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
        end
    else
        player:Kick("Failed to fetch data from URL: ", url)
    end
    return nil
end


-- URL fetching


local whitelistURL = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Users.json"
local supportedExploitsURL = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Supported%20Exploits.json"

local whitelistedUsers = fetchData(whitelistURL)
local supportedExploits = fetchData(supportedExploitsURL)

if not supportedExploits then
    player:Kick("Failed to retrieve the list of supported exploits.")
    return
end

if not whitelistedUsers then
    player:Kick("Failed to retrieve the whitelist.")
    return
end


-- Supported exploit function


local currentExploit = identifyexecutor()

local supported = false
for _, exploit in ipairs(supportedExploits) do
    if exploit == currentExploit then
        supported = true
        break
    end
end

if not supported then
    player:Kick("The current exploit is not supported: " .. currentExploit)
end


-- Logging


local function logEvent(eventType)
    local url = ""
    if eventType == "execution" then
        url = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Webhooks/Execution.lua"
    elseif eventType == "breach" then
        url = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Webhooks/Breach.lua"
    end

    if url ~= "" then
        loadstring(game:HttpGet(url))()
    end
end


-- Authentication functions




auth.isUser = function()
    return auth.currentUser ~= nil
end

auth.isAuthorized = function()
    for _, user in ipairs(whitelistedUsers) do
        if user.HWID == hashedHWID then
            return true, user
        end
    end
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

auth.trigger = function()
    if not whitelistedUsers then
        player:Kick("Failed to retrieve whitelist.")
        return
    end

    local isAuthorized, userData = auth.isAuthorized() -- Check auth

    if isAuthorized and userData then
        auth.currentUser = userData -- Store the current user's data

        -- Ban check

        if userData.Banned and userData.Rank ~= "Owner" then
            if userData.TempBan then
                player:Kick("\nYou are temporarily banned from using this service for " .. userData.TempBanDuration .. ". You will be unbanned on " .. userData.TempBanEnd .. ".\nReason: " .. (userData.BanReason or "No reason provided."))
            else
                player:Kick("\nYou are permanently banned from using this service.\nReason: " .. (userData.BanReason or "No reason provided."))
            end
        else
            -- Notify execution

            if authConfig.notifyExecution then
                local rank = userData.Rank or "Unknown Rank"  -- Default to "Unknown Rank" if nil
                local identifier = userData.Identifer or "Unknown Identifier"  -- Default to "Unknown Identifier" if nil
                utils.sendNotif("Celestial", "Successfully logged in as " .. rank .. ": " .. identifier, 3, 18568429771)
            end

            -- Log

            if authConfig.logExecutions then
                logEvent("execution")
            end
        end
    else
        setclipboard(hashedHWID)
        warn("Invalid HWID: Your hardware ID has been copied to your clipboard.")

        -- Log

        if authConfig.logBreaches then
            logEvent("breach")
        end
    end
end

return auth