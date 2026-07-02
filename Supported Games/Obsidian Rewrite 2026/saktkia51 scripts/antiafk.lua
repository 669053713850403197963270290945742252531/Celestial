repeat task.wait() until game:IsLoaded()

local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local startTime = tick()
local connection

local function updateTime()
    local currentTime = tick() - startTime
    local seconds = math.floor(currentTime % 60)
    local minutes = math.floor((currentTime / 60) % 60)
    local hours = math.floor(currentTime / 3600)
    --print(string.format("Time Active: %02d:%02d:%02d", hours, minutes, seconds))
end

-- Anti-AFK Function
local function antiAFK()
    local lastMove = tick()

    -- Connect to PreRender for smoother updates
    connection = RunService.PreRender:Connect(function()
        updateTime()

        -- Simulate activity every 15 minutes
        if tick() - lastMove >= 15 * 60 then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                --warn("Status: Simulating Activity")
                --wait(0.1)
                --warn("Status: Active")
            end)
            lastMove = tick()
        end
    end)
end

-- Handle Player Focus
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- Start Anti-AFK
antiAFK()