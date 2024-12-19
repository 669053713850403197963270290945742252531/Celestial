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

-- Modular whitelist

local whitelistURL = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Users.json"

local function fetchWhitelist(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        print("Whitelist successfully fetched: ", response) -- Debugging line
        local successDecode, whitelistData = pcall(function()
            return HttpService:JSONDecode(response)
        end)

        if successDecode then
            print("Whitelist decoded successfully.") -- Debugging line
            return whitelistData
        else
            warn("Failed to decode whitelist JSON data.")
        end
    else
        warn("Failed to fetch whitelist from URL: " .. url)
    end
    return nil
end

-- Fetch whitelist

local WhitelistedUsers = fetchWhitelist(whitelistURL)
if not WhitelistedUsers then
    warn("Failed to retrieve the whitelist. Please try again.")
    return
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

if WhitelistedUsers[hwid] then
    local userInfo = WhitelistedUsers[hwid]
    auth.Username = userInfo.Username
    auth.Rank = userInfo.Rank
    auth.authorized = true

    if auth.notify_execution then
        utils.sendNotif("Celestial", "Successfully logged in as " .. auth.Rank .. ": " .. auth.Username, 3, 18568429771)
        --print("Successfully logged in as " .. auth.Rank .. ": " .. auth.Username)
    end

    if auth.log_executions then
        logEvent("execution")
    end
else
    auth.authorized = false
    
    player:Kick("This session has been invalidated due to invalid stored credentials.\n\nYour hardware id has been copied to your clipboard.")
    setclipboard(hwid)

    if auth.log_breaches then
        logEvent("breach")
    end
end

return auth