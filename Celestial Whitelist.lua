local AuthModule = {}

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

-- Configuration

AuthModule.log_executions = false
AuthModule.log_breaches = false
AuthModule.notify_execution = true

-- Whitelist

AuthModule.authorized = false

local WhitelistedUsers = {
    ["CA226CC5-96FE-4347-8345-085323E65245"] = { Username = "Corrade" },
    ["00000000-0000-0000-0000-000000000000"] = { Username = "Linked Account" }
}

if WhitelistedUsers[hwid] then
    local userInfo = WhitelistedUsers[hwid]
    AuthModule.Username = userInfo.Username

    AuthModule.authorized = true

    if AuthModule.notify_execution then
        utils.success("User " .. AuthModule.Username .. " authenticated!")
    end

    if AuthModule.log_executions then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Webhooks/Execution.lua"))()
    end
else
    AuthModule.authorized = false
    
    player:Kick("This session has been invalidated due to the stored credentials not being authorized.")

    if AuthModule.log_breaches then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Webhooks/Breach.lua"))()
    end
end

return AuthModule
