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
    ["5A572703-967C-43DD-B87F-7754C5EFFDAF"] = { Username = "Corrade" , Rank = "Owner"},
    ["00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"] = { Username = "Unknown" , Rank = "User"}
}

-- Placeholder: 00000000-0000-0000-0000-000000000000

if WhitelistedUsers[hwid] then
    local userInfo = WhitelistedUsers[hwid]
    AuthModule.Username = userInfo.Username
    AuthModule.Rank = userInfo.Rank

    AuthModule.authorized = true

    if AuthModule.notify_execution then
        --print("Successfully logged in as " .. AuthModule.Rank .. ": " .. AuthModule.Username)
        
        --utils.success("Successfully logged in as " .. AuthModule.Rank .. ": " .. AuthModule.Username)
        --utils.sendNotif("Celestial", "Successfully logged in as " .. AuthModule.Rank .. ": " .. AuthModule.Username, 3, 18568429771)
    end

    if AuthModule.log_executions then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Webhooks/Execution.lua"))()
    end
else
    AuthModule.authorized = false
    
    player:Kick("This session has been invalidated due to the stored credentials not being authorized.\n\nYour hardware id has been copied to your clipboard.")

    setclipboard(hwid)

    if AuthModule.log_breaches then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Webhooks/Breach.lua"))()
    end
end

return AuthModule
