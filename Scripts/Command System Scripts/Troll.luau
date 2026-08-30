local imageAssetId = "rbxassetid://117052551332157"

-- ===== SERVICES & CONSTANTS =====
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local SS = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

local processedCount = 0

-- ===== SETTINGS =====
local DEBUG = true              -- Enable debug messages
local INSTANCE_CAP = 1000000      -- Max number of instances to process
local SCRIPT_DURATION = 10       -- Duration in seconds before restoring everything

-- ===== TEXT REPLACEMENT =====
local TEXT_PRIMARY = "Trollage"
local TEXT_OVERRIDE = TEXT_PRIMARY

-- ===== AUDIO SETTINGS =====
local INTRO_ENABLED = true
local AUDIO2_ENABLED = true
local AUDIO3_ENABLED = true

local INTRO_ID = "rbxassetid://111091142204265"
local AUDIO2_ID = "rbxassetid://101769410694203" -- Loud "smile" sound
local AUDIO3_ID = "rbxassetid://73753120048787" -- Troll laugh
local audio2Instance
local audio3Instance

-- ===== GAME RESTRICTIONS =====
local DISABLED_GAMES = {
    [2440500124] = true -- DOORS
}

if DISABLED_GAMES[game.GameId] then -- Comparing the game's UniverseId to the UniverseId's in DISABLED_GAMES
    warn("[SCRIPT BLOCKED]: This game is blacklisted due to high instance count / low effectiveness.")
    return
end

-- ===== HELPER FUNCTIONS =====
local function debugLog(msg)
    if DEBUG then
        warn("[DEBUG]: " .. msg)
    end
end

local function playSound(id, volume)
    local s = Instance.new("Sound", SS)
    s.SoundId = id
    s.Volume = volume
    s.Looped = false
    s:Play()
    return s
end

-- ===== SOUNDS =====

if INTRO_ENABLED then
    local intro = playSound(INTRO_ID, 30)
    intro.Ended:Wait() -- Wait for it to finish
    intro:Destroy()
end

if AUDIO2_ENABLED then
    audio2Instance = playSound(AUDIO2_ID, 20)
end

if AUDIO3_ENABLED then
    audio3Instance = playSound(AUDIO3_ID, 25)
end

-- ===== STORING ORIGINAL PROPERTIES =====
local originalProperties = {}
local connections = {}
local running = true

local function saveOriginal(obj, prop)
    if not originalProperties[obj] then
        originalProperties[obj] = {}
    end
    
    if originalProperties[obj][prop] == nil then
        local success, value = pcall(function()
            return obj[prop]
        end)
        
        if success then
            originalProperties[obj][prop] = value
        end
    end
end

local function restoreAll()
    debugLog("Restoring all modified properties...")

    for obj, props in pairs(originalProperties) do
        if obj and obj.Parent then
            for prop, value in pairs(props) do
                pcall(function()
                    obj[prop] = value
                end)
            end
        end
    end

    if audio2Instance or audio3Instance then
        pcall(function()
            audio2Instance:Destroy()
            audio3Instance:Destroy()
        end)
    end

    for _, conn in ipairs(connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end

    table.clear(connections)
    table.clear(originalProperties)
end

local function safeConnect(obj, prop, callback)
    if not running then return end
    if not obj or not obj.GetPropertyChangedSignal then return end
    
    local success, signal = pcall(function()
        return obj:GetPropertyChangedSignal(prop)
    end)
    
    if success and signal then
        table.insert(connections, signal:Connect(callback))
    end
end

local function canProcess()
    if processedCount >= INSTANCE_CAP then
        return false
    end
    return true
end

local function markProcessed()
    processedCount += 1

    if processedCount == INSTANCE_CAP then
        debugLog("Instance cap reached (" .. INSTANCE_CAP .. "). Stopping further processing.")
    end
end

local function applyToInstance(v)
    if not running or not v then return end
    if not canProcess() then return end

    markProcessed()

    -- Images
    if v:IsA("ImageLabel") or v:IsA("ImageButton") then
        saveOriginal(v, "Image")
        v.Image = imageAssetId

        safeConnect(v, "Image", function()
            if running then
                v.Image = imageAssetId
            end
        end)
    end

    -- Text
    if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
        saveOriginal(v, "Text")

        if v.Text ~= "" then
            v.Text = TEXT_PRIMARY
        end

        safeConnect(v, "Text", function()
            if running and v.Text ~= "" then
                v.Text = TEXT_OVERRIDE
            end
        end)
    end

    -- Decals / Textures
    if v:IsA("Texture") or v:IsA("Decal") then
        saveOriginal(v, "Texture")
        v.Texture = imageAssetId

        safeConnect(v, "Texture", function()
            if running then
                v.Texture = imageAssetId
            end
        end)
    end

    -- MeshPart
    if v:IsA("MeshPart") then
        saveOriginal(v, "TextureID")
        v.TextureID = imageAssetId

        safeConnect(v, "TextureID", function()
            if running then
                v.TextureID = imageAssetId
            end
        end)
    end

    -- SpecialMesh
    if v:IsA("SpecialMesh") then
        saveOriginal(v, "TextureId")
        v.TextureId = imageAssetId

        safeConnect(v, "TextureId", function()
            if running then
                v.TextureId = imageAssetId
            end
        end)
    end
end

local function applyToSky()
    if not running then return end

    local sky = Lighting:FindFirstChildOfClass("Sky")
    
    if not sky then
        sky = Instance.new("Sky", Lighting)
    end

    local props = {
        "SkyboxBk","SkyboxDn","SkyboxFt",
        "SkyboxLf","SkyboxRt","SkyboxUp"
    }

    for _, prop in ipairs(props) do
        saveOriginal(sky, prop)
        pcall(function()
            sky[prop] = imageAssetId
        end)
    end
end

local function scan(container)
    for _, v in ipairs(container:GetDescendants()) do
        if not canProcess() then break end
        applyToInstance(v)
    end
end

-- MAIN

if LocalPlayer then
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)

    if playerGui then
        scan(playerGui)

        table.insert(connections, playerGui.DescendantAdded:Connect(function(v)
            if canProcess() then
                applyToInstance(v)
            end
        end))
    end
end

scan(workspace)
scan(CoreGui)

table.insert(connections, workspace.DescendantAdded:Connect(function(v)
    if canProcess() then
        applyToInstance(v)
    end
end))

table.insert(connections, CoreGui.DescendantAdded:Connect(function(v)
    if canProcess() then
        applyToInstance(v)
    end
end))

applyToSky()

task.spawn(function()
    while running do
        applyToSky()
        task.wait(2)
    end
end)

-- TIMER
task.delay(SCRIPT_DURATION, function()
    running = false
    restoreAll()
end)