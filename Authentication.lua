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

local function fetchWhitelist(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        return HttpService:JSONDecode(response)
    else
        warn("Failed to fetch or decode the whitelist.")
        return nil
    end
end

-- Fetch whitelist

local whitelistURL = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Users.json"
local WhitelistedUsers = fetchWhitelist(whitelistURL)

--[[

if not WhitelistedUsers then
    player:Kick("Failed to retrieve the whitelist. Please try again.")
    return
end

]]

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
    local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    local userData = nil

    -- Find user by HWID
    for _, user in pairs(WhitelistedUsers) do
        if user.HWID == hwid then
            userData = user
            break
        end
    end

    if userData then
        if userData.Banned then
            warn("You are banned from using this service.\nReason: " .. (userData.BanReason or "No reason provided."))
        else
            print("Successfully logged in as " .. userData.Rank .. ": " .. userData.Username)
            --utils.sendNotif("Celestial", "Successfully logged in as " .. userData.Rank .. ": " .. userData.Username, 3, 18568429771)

            if auth.log_executions then
                logEvent("execution")
            end
        end
    else
        warn("This session has been invalidated due to invalid stored credentials.\nYour hardware id has been copied to your clipboard.")
        setclipboard(hwid)

        if auth.log_breaches then
            logEvent("breach")
        end
    end
else
    warn("Failed to retrieve whitelist.")
end

return auth