local auth = {}

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

-- Configuration

auth.log_executions = false
auth.log_breaches = false
auth.notify_execution = true

-- Whitelist

auth.authorized = false

local WhitelistedUsers = {
    ["7453630E-B029-4398-844C-F511BEFC3C43"] = { Username = "Corrade", Rank = "Owner" },
    ["00000000-0000-0000-0000-000000000000"] = { Username = "Unknown", Rank = "User" }
}

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
        
        --utils.success("Successfully logged in as " .. auth.Rank .. ": " .. auth.Username)
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

-- Placeholder: 00000000-0000-0000-0000-000000000000

return auth