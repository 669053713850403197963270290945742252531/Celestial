local AuthModule = {}

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()

local player = game:GetService("Players").LocalPlayer
local hwid = gethwid()

-- Configuration

AuthModule.log_executions = false
AuthModule.log_breaches = false
AuthModule.notify_execution = true

-- Whitelist

AuthModule.authorized = false

local WhitelistedUsers = {
    ["E920751F8FEA3C5EC9505ED8F3FB935E627D1D851E3E6738072C7D0C70CE145F20C2AC165D61016A11D5EFB2B0A4664B786E45AEE425937629C5A0FDB9BF9A31"] = { Username = "Corrade" , Rank = "Owner"},
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
