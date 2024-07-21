local AuthModule = {}

local player = game:GetService("Players").LocalPlayer
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

-- Configuration

local log_executions = true

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

    print("User " .. AuthModule.Username .. " authenticated!")

    if log_executions then
        print("log executions: true")
    end
else
    AuthModule.authorized = false
    
    player:Kick("This session has been invalidated due to the stored credentials not being authorized.")

    loadstring(game:HttpGet("https://raw.githubusercontent.com/757788428949485651495849884358443235871/Celestial/main/Unauthorized%20Access%20Logger.lua"))()
end

return AuthModule
