--[[
    Area 51 - Standalone Silent Aim
    Extracted from the supplied script.luau.

    Executor-specific requirements:
      - getgenv()
      - getgc(true)
      - Drawing.new("Circle") (optional; used only for the FOV ring)

    This targets the game's existing weapon table/function layout. If the game
    changes screen_to_target or the target folders, the hook will need updating.
]]

local Environment = (type(getgenv) == "function" and getgenv()) or _G

if Environment.__AREA51_STANDALONE_SILENT_AIM then
    warn("[Silent Aim] Already running. Use UnloadArea51SilentAim() first.")
    return
end
Environment.__AREA51_STANDALONE_SILENT_AIM = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings are kept in getgenv().SilentAimConfig so they can be changed live.
local Config = Environment.SilentAimConfig or {}
local Defaults = {
    Enabled = false,
    FOV = 150,
    WallCheck = false,
    Wallbang = true,
    TargetPart = "HumanoidRootPart",
    TargetTypes = {
        Killers = true,
        Players = false,
    },
    Prediction = true,
    PredictionFactor = 1.0,
    ProjectileSpeed = 150,
    ShowFOV = true,
    FOVColor = Color3.fromRGB(0, 229, 255),
    FOVThickness = 1,
    ToggleKey = Enum.KeyCode.RightControl,
}

for key, value in pairs(Defaults) do
    if Config[key] == nil then
        Config[key] = value
    end
end

if type(Config.TargetTypes) ~= "table" then
    Config.TargetTypes = table.clone(Defaults.TargetTypes)
else
    for key, value in pairs(Defaults.TargetTypes) do
        if Config.TargetTypes[key] == nil then
            Config.TargetTypes[key] = value
        end
    end
end

Environment.SilentAimConfig = Config

local BlacklistedNames = {
    Jane = true,
    Giant = true,
}

local Connections = {}
local HookRecords = {}
local HookedObjects = setmetatable({}, { __mode = "k" })
local Unloaded = false

local function TrackConnection(connection)
    table.insert(Connections, connection)
    return connection
end

local function GetTargetFolders()
    return Workspace:FindFirstChild("Killers"), Workspace:FindFirstChild("Characters to kill")
end

local function IsValidTarget(model)
    if not model or not model:IsA("Model") then
        return false
    end

    if BlacklistedNames[model.Name] then
        return false
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    if model == LocalPlayer.Character or humanoid.Parent == LocalPlayer.Character then
        return false
    end

    local killersFolder, charactersFolder = GetTargetFolders()
    local targetTypes = Config.TargetTypes

    if targetTypes.Killers and killersFolder and model:IsDescendantOf(killersFolder) then
        return true
    end

    if targetTypes.Players and charactersFolder and model:IsDescendantOf(charactersFolder) then
        return true
    end

    return false
end

local function IsVisible(targetPart, character)
    -- Match the original script: Wallbang takes precedence over Wall Check.
    if not Config.WallCheck or Config.Wallbang then
        return true
    end

    local camera = Workspace.CurrentCamera or Camera
    if not camera then
        return false
    end

    local origin = camera.CFrame.Position
    local direction = targetPart.Position - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {
        LocalPlayer.Character,
        character,
    }
    raycastParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function GetClosestTarget()
    if not Config.Enabled then
        return nil, nil
    end

    local camera = Workspace.CurrentCamera or Camera
    if not camera then
        return nil, nil
    end

    local fov = math.max(0, tonumber(Config.FOV) or Defaults.FOV)
    local mousePosition = UserInputService:GetMouseLocation()
    local closestTargetPart = nil
    local closestPredictedPosition = nil
    local shortestScreenDistance = fov

    local function EvaluateCharacter(model)
        if not IsValidTarget(model) then
            return
        end

        local targetPart = model:FindFirstChild(Config.TargetPart)
        if not targetPart or not targetPart:IsA("BasePart") then
            targetPart = model:FindFirstChild("Head")
        end

        if not targetPart or not targetPart:IsA("BasePart") then
            return
        end

        local rootPart = model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("Torso")

        local predictedPosition = targetPart.Position

        if Config.Prediction and rootPart and rootPart:IsA("BasePart") then
            local projectileSpeed = tonumber(Config.ProjectileSpeed) or Defaults.ProjectileSpeed
            if projectileSpeed > 0 then
                local distance = (camera.CFrame.Position - targetPart.Position).Magnitude
                local travelTime = distance / projectileSpeed
                local predictionFactor = tonumber(Config.PredictionFactor) or 1

                predictedPosition = targetPart.Position
                    + (rootPart.AssemblyLinearVelocity * travelTime * predictionFactor)
            end
        end

        local screenPosition, onScreen = camera:WorldToViewportPoint(predictedPosition)
        if not onScreen then
            return
        end

        local screenDistance = (
            Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition
        ).Magnitude

        if screenDistance < shortestScreenDistance and IsVisible(targetPart, model) then
            shortestScreenDistance = screenDistance
            closestTargetPart = targetPart
            closestPredictedPosition = predictedPosition
        end
    end

    local killersFolder, charactersFolder = GetTargetFolders()
    local targetTypes = Config.TargetTypes

    if targetTypes.Killers and killersFolder then
        for _, model in ipairs(killersFolder:GetChildren()) do
            EvaluateCharacter(model)
        end
    end

    if targetTypes.Players and charactersFolder then
        for _, model in ipairs(charactersFolder:GetChildren()) do
            EvaluateCharacter(model)
        end
    end

    return closestTargetPart, closestPredictedPosition
end

-- Return the first valid target Model above a hit part. This also handles
-- hit parts nested inside Accessories or submodels.
local function FindTargetModelFromPart(part)
    if typeof(part) ~= "Instance" then
        return nil
    end

    local current = part
    while current and current ~= Workspace do
        if current:IsA("Model") and IsValidTarget(current) then
            return current
        end
        current = current.Parent
    end

    return nil
end

local function HookWeaponTable(object)
    if type(object) ~= "table" or HookedObjects[object] then
        return
    end

    local originalScreenToTarget = rawget(object, "screen_to_target")
    if type(originalScreenToTarget) ~= "function" then
        return
    end

    local originalRayCallback = rawget(object, "target_ray_callback")
    local originalMissileHit = rawget(object, "missile_hit")

    local record = {
        Object = object,
        OriginalScreenToTarget = originalScreenToTarget,
        OriginalRayCallback = originalRayCallback,
        OriginalMissileHit = originalMissileHit,
    }

    local success, hookError = pcall(function()
        record.HookedScreenToTarget = function(self, inputFunction, ...)
            if Config.Enabled then
                local _, predictedPosition = GetClosestTarget()
                if predictedPosition then
                    return predictedPosition
                end
            end

            return originalScreenToTarget(self, inputFunction, ...)
        end
        object.screen_to_target = record.HookedScreenToTarget

        if type(originalRayCallback) == "function" then
            record.HookedRayCallback = function(raycastResult, ...)
                if Config.Enabled
                    and Config.Wallbang
                    and raycastResult
                    and raycastResult.Instance
                then
                    return FindTargetModelFromPart(raycastResult.Instance) ~= nil
                end

                return originalRayCallback(raycastResult, ...)
            end
            object.target_ray_callback = record.HookedRayCallback
        end

        if type(originalMissileHit) == "function" then
            record.HookedMissileHit = function(self, missile, moment, hitPart, missilePosition, ...)
                if Config.Enabled
                    and Config.Wallbang
                    and typeof(hitPart) == "Instance"
                    and hitPart:IsA("BasePart")
                    and hitPart.CanCollide
                then
                    if not FindTargetModelFromPart(hitPart) then
                        return
                    end
                end

                return originalMissileHit(self, missile, moment, hitPart, missilePosition, ...)
            end
            object.missile_hit = record.HookedMissileHit
        end
    end)

    if success then
        HookedObjects[object] = true
        table.insert(HookRecords, record)
    else
        warn("[Silent Aim] Could not hook a weapon table: " .. tostring(hookError))
    end
end

local function ScanWeaponTables()
    if type(getgc) ~= "function" then
        warn("[Silent Aim] This executor does not provide getgc(true); weapon hooks cannot be installed.")
        return
    end

    local success, objects = pcall(getgc, true)
    if not success or type(objects) ~= "table" then
        warn("[Silent Aim] getgc(true) failed: " .. tostring(objects))
        return
    end

    for _, object in ipairs(objects) do
        HookWeaponTable(object)
    end
end

-- FOV circle. Silent Aim itself can still run if Drawing is unavailable.
local FOVCircle
if type(Drawing) == "table" and type(Drawing.new) == "function" then
    local success, circle = pcall(Drawing.new, "Circle")
    if success then
        FOVCircle = circle
        FOVCircle.Visible = false
        FOVCircle.Transparency = 0.8
        FOVCircle.Color = Config.FOVColor
        FOVCircle.Thickness = Config.FOVThickness
        FOVCircle.Filled = false
        FOVCircle.Radius = Config.FOV
    end
end

-- Small standalone toggle panel; the remaining settings are in the config table.
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "Area51SilentAimStandalone"
ToggleGui.ResetOnSpawn = false
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Toggle"
ToggleButton.Size = UDim2.fromOffset(180, 34)
ToggleButton.Position = UDim2.new(1, -195, 0, 18)
ToggleButton.BackgroundColor3 = Color3.fromRGB(23, 25, 34)
ToggleButton.BorderSizePixel = 0
ToggleButton.Font = Enum.Font.GothamSemibold
ToggleButton.TextSize = 13
ToggleButton.TextColor3 = Color3.fromRGB(235, 240, 250)
ToggleButton.Parent = ToggleGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 7)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 229, 255)
ToggleStroke.Thickness = 1
ToggleStroke.Transparency = 0.35
ToggleStroke.Parent = ToggleButton

local function UpdateToggleText()
    ToggleButton.Text = "Silent Aim: " .. (Config.Enabled and "ON" or "OFF")
end

UpdateToggleText()

TrackConnection(ToggleButton.Activated:Connect(function()
    Config.Enabled = not Config.Enabled
    UpdateToggleText()
end))

local parented = pcall(function()
    ToggleGui.Parent = CoreGui
end)
if not parented or not ToggleGui.Parent then
    ToggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Config.ToggleKey then
        Config.Enabled = not Config.Enabled
        UpdateToggleText()
    end
end))

TrackConnection(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end))

TrackConnection(RunService.RenderStepped:Connect(function()
    if not FOVCircle then
        return
    end

    FOVCircle.Visible = Config.Enabled and Config.ShowFOV
    FOVCircle.Radius = tonumber(Config.FOV) or Defaults.FOV
    FOVCircle.Color = Config.FOVColor
    FOVCircle.Thickness = Config.FOVThickness
    FOVCircle.Position = UserInputService:GetMouseLocation()
end))

-- Periodic rescanning catches weapon tables created after this script starts.
task.spawn(function()
    while not Unloaded do
        ScanWeaponTables()
        task.wait(5)
    end
end)

local function UnloadSilentAim()
    if Unloaded then
        return
    end
    Unloaded = true

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Connections)

    for _, record in ipairs(HookRecords) do
        local object = record.Object
        if type(object) == "table" then
            pcall(function()
                if rawget(object, "screen_to_target") == record.HookedScreenToTarget then
                    object.screen_to_target = record.OriginalScreenToTarget
                end
                if record.HookedRayCallback
                    and rawget(object, "target_ray_callback") == record.HookedRayCallback
                then
                    object.target_ray_callback = record.OriginalRayCallback
                end
                if record.HookedMissileHit
                    and rawget(object, "missile_hit") == record.HookedMissileHit
                then
                    object.missile_hit = record.OriginalMissileHit
                end
            end)
        end
    end
    table.clear(HookRecords)

    if FOVCircle then
        pcall(function()
            FOVCircle:Remove()
        end)
        FOVCircle = nil
    end

    pcall(function()
        ToggleGui:Destroy()
    end)

    Environment.__AREA51_STANDALONE_SILENT_AIM = nil
    Environment.UnloadArea51SilentAim = nil
    warn("[Silent Aim] Unloaded and restored hooked weapon functions.")
end

Environment.UnloadArea51SilentAim = UnloadSilentAim

print("[Silent Aim] Standalone script loaded. Toggle with the on-screen button or RightControl.")
print("[Silent Aim] Settings: getgenv().SilentAimConfig")
