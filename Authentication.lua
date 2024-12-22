local auth = {}

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local httpService = game:GetService("HttpService")
local hashedHWID = utils.hash(hwid, "SHA-256")

-- Configuration

local authConfig = {
    logExecutions = false,
    logBreaches = false,
    notifyExecution = true,
    currentUser = nil
}

auth.currentUser = nil

-- Making the whitelist modular

local function fetchWhitelist(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local successDecode, whitelistData = pcall(function()
            --print(response) -- Print the entire whitelist
            return httpService:JSONDecode(response)
        end)

        if successDecode then
            return whitelistData
        else
            warn("Failed to decode whitelist.")
        end
    else
        warn("Failed to fetch whitelist.")
    end
    return nil
end

-- Fetch whitelist from the specified URL

local whitelistURL = "https://pastebin.com/raw/uSUpD1yL" --[["https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Users.json"]]
local whitelistedUsers = fetchWhitelist(whitelistURL)

if not whitelistedUsers then
    warn("Failed to retrieve the whitelist.")
    return
end

-- Authentication functions

--[[

isUser = Returns a boolean depending on if the user is currently whitelisted.
isAuthorized = Returns a boolean depending on if the user's current hwid matches any in the whitelistedUsers.

]]

auth.isUser = function()
    return auth.currentUser ~= nil
end

auth.isAuthorized = function()
    for _, user in ipairs(whitelistedUsers) do
        if user.HWID == hashedHWID then
            return true, user -- Return true and the user object
        end
    end
    return false, nil -- Return false and nil if no match found
end

auth.isOwner = function()
    local isAuthorized, user = auth.isAuthorized()
    return isAuthorized and user and user.Rank == "Owner"
end

auth.fetchConfig = function(configName)
    -- Error handling for invalid or missing value

    if typeof(configName) ~= "string" or configName == nil then
        warn("Argument #1 (configName) expected a string value and a valid config name but got a " .. typeof(configName) .. " value and an invalid config name.")
        return "Failed. Check console for more information."
    end

    configName = string.lower(configName) -- Convert to lowercase

    -- Check if the given configName matches a value inside authConfig

    for key, value in pairs(authConfig) do
        if string.lower(key) == configName then
            return value
        end
    end

    -- If no match is found

    warn("Argument #1 (configName) expected a valid config name.")
    return "Failed. Check console for more information."
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

-- Main whitelist function

if whitelistedUsers then
    local isAuthorized, userData = auth.isAuthorized()

    if isAuthorized and userData then
        auth.currentUser = userData -- Store the current user's data
        
        if userData.Banned and userData.Rank ~= "Owner" then -- Preventing use of the service if the user is banned and their rank is not "Owner"


            
            if userData.TempBan then
                warn("\nYou are temporary banned from using this service for " .. userData.TempBanDuration .. ". You will be unbanned on " .. userData.TempBanEnd .. ".\nReason: " .. (userData.BanReason or "No reason provided."))
            else
                warn("\nYou are permanently banned from using this service.\nReason: " .. (userData.BanReason or "No reason provided."))
            end



        else

            if authConfig.notifyExecution then
                local rank = userData.Rank or "Unknown Rank"  -- Default to "Unknown Rank" if nil
                local identifier = userData.Identifer or "Unknown Identifier"  -- Default to "Unknown Identifier" if nil

                warn("Successfully logged in as " .. rank .. ": " .. identifier .. " / " .. utils.getTime(true) .. os.date(" %p"))
            end

            -- utils.sendNotif("Celestial", "Successfully logged in as " .. userData.Rank .. ": " .. userData.Identifer, 3, 18568429771)

            if authConfig.logExecutions then
                logEvent("execution")
            end
        end
    else
        setclipboard(hashedHWID)
        player:Kick("Invalid HWID. Your hardware ID has been copied to your clipboard.")

        if authConfig.logBreaches then
            logEvent("breach")
        end
    end
else
    warn("Failed to retrieve whitelist.")
end

return auth