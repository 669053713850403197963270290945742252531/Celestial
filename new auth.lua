local HttpService = game:GetService("HttpService")
local AnalyticsService = game:GetService("RbxAnalyticsService") -- or your websocket library

local utils = loadstring(readfile("Celestial/Libraries/Core Utilities.lua"))()
local WS_URL = "ws://localhost:8080"

local module = {}

local currentHWID = utils.hash(AnalyticsService:GetClientId(), "SHA-384")
local userData = nil
local isAuthenticated = false

local ws = WebSocket.connect(WS_URL)

local function parseServerMessage(msg)
    local success, data = pcall(function()
        return HttpService:JSONDecode(msg)
    end)
    if not success then
        warn("Failed to parse server message:", msg)
        return
    end

    if data.status == "AUTH_SUCCESS" and data.user then
        userData = data.user
        isAuthenticated = true
        print("✅ Authenticated as", userData.Identifier)
    elseif data.status == "AUTH_FAIL" then
        isAuthenticated = false
        warn("❌ Authentication failed")
    else
        warn("❓ Unknown server response")
    end
end

ws.OnMessage:Connect(function(msg)
    print("Server:", msg)
    parseServerMessage(msg)
end)

task.delay(1, function()
    ws:Send("AUTH_HWID:" .. currentHWID)
end)

function module.isWhitelisted()
    return isAuthenticated
end

function module.get(field)
    if not userData then return nil end
    return userData[field]
end

function module.isOwner()
    return userData and userData.Rank == "Owner"
end

function module.isUser()
    return userData and userData.Rank == "User"
end

function module.getAll()
    return userData
end

function module.getHWID()
    return currentHWID
end

return module
