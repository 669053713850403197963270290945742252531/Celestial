local auth = {}

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local HttpService = game:GetService("HttpService")

-- Configuration
auth.log_executions = false
auth.log_breaches = false
auth.notify_execution = true
auth.authorized = false
auth.CurrentUser = nil

-- Modular whitelist
local function fetchWhitelist(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        local successDecode, whitelistData = pcall(function()
            print(response)
            return HttpService:JSONDecode(response)
        end)
        if successDecode then
            return whitelistData
        else
            warn("Failed to decode the whitelist JSON data. Response: " .. response)
        end
    else
        warn("Failed to fetch the whitelist from URL: " .. url)
    end
    return nil
end

-- Fetch whitelist
local whitelistURL = "https://pastebin.com/raw/QDRgYs0d"
local WhitelistedUsers = fetchWhitelist(whitelistURL)

if not WhitelistedUsers then
    warn("Failed to retrieve the whitelist. Please verify the URL and try again.")
    return
end

-- Authentication functions

auth.isAuthorized = function()
    for _, user in ipairs(WhitelistedUsers) do
        if user.HWID == hwid then
            return true, user -- Return true and the user object
        end
    end
    return false, nil -- Return false and nil if no match found
end

auth.isOwner = function()
    local isAuthorized, user = auth.isAuthorized()
    return isAuthorized and user and user.Rank == "Owner"
end

-- Authentication process
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

if WhitelistedUsers then
    local isAuthorized, userData = auth.isAuthorized()
    if isAuthorized and userData then
        auth.CurrentUser = userData -- Store the current user's data
        if userData.Banned then
            warn("You are banned from using this service.\nReason: " .. (userData.BanReason or "No reason provided."))
        else
            print("Successfully logged in as " .. userData.Rank .. ": " .. userData.Identifer)
            -- utils.sendNotif("Celestial", "Successfully logged in as " .. userData.Rank .. ": " .. userData.Identifer, 3, 18568429771)

            if auth.log_executions then
                logEvent("execution")
            end
        end
    else
        warn("Invalid HWID. Your hardware ID has been copied to your clipboard.")
        setclipboard(hwid)

        if auth.log_breaches then
            logEvent("breach")
        end
    end
else
    warn("Failed to retrieve whitelist.")
end

return auth