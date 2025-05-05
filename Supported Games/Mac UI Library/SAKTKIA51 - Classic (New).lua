while not game:IsLoaded() do
    task.wait()
end

--local macLib = loadstring(game:HttpGet("https://github.com/669053713850403197963270290945742252531/Maclib/releases/download/3/Maclib.lua"))()
local macLib = loadstring(readfile("Maclib - Revamped.lua"))()

local scriptSettings = {
    fastLoad = true,
    testing = true,
    rainbowSpeed = 0.1,
    autoResetRainbowColor = true
}

if scriptSettings.testing then
    getgenv().script_key = "lQwkSPLnL29AIKCAxmWuQ91M0gzjPuUugJ0Xd"
    getgenv().notifyLoad = false
end

local startTime
if getgenv().notifyLoad == true then
    startTime = tick()
end

-- Global variable user defined value checks

if typeof(getgenv().notifyLoad) ~= "boolean" then
    warn("getgenv().notifyLoad expected a boolean value but got a " .. typeof(getgenv().notifyLoad) .. " (" .. tostring(getgenv().notifyLoad) .. ") value. Defaulting to true.")
    getgenv().notifyLoad = true
end

getgenv().script_key = getgenv().script_key or ""

local auth
local executionLib
if not scriptSettings.fastLoad then
    auth = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Authentication.lua?ref_type=heads"))()
    auth.trigger()

    if auth.kicked then
        return
    end

    executionLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Execution%20Library.lua?ref_type=heads"))()
end

local utils = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Core%20Utilities.lua?ref_type=heads"))()
local assetLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Asset%20Library.lua?ref_type=heads"))()
local entityLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Entity%20Library.lua?ref_type=heads"))()

-- Create assets

assetLib.createAssets()

-- Destroying any previous instances of macLib

local macLibLocation = gethui() or game:GetService("CoreGui") 

for _, screenGui in pairs(macLibLocation:GetDescendants()) do
    if screenGui:IsA("ScreenGui") then
        if screenGui.DisplayOrder == 2147483647 and screenGui.Name == "ScreenGui" and not screenGui.ResetOnSpawn then
            screenGui:Destroy()
        end
    end
end

-- Variables / Services

local starterGui = game:GetService("StarterGui")
local players = game:GetService("Players")
local player = players.LocalPlayer
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local gameEvent = "None"

-- Game event detection

if game:GetService("ReplicatedStorage"):FindFirstChild("WinterMapData") then
    gameEvent = "Winter"
end

-- Window

local version = "V.01"

if not scriptSettings.fastLoad then
    if auth.isOwner() then
        version = "DEV"
    else
        version = version
    end
else
    version = version
end

local window
if not scriptSettings.fastLoad then
    window = macLib:Window({
        Title = "Celestial",
        Subtitle = auth.currentUser.Identifier .. " - " .. version .. " | " .. gameName .. "\nTotal Executions: " .. executionLib.fetchExecutions(),
        DragStyle = 1,
        DisabledWindowControls = {},
        ShowUserInfo = true,
        Keybind = Enum.KeyCode.RightShift,
        AcrylicBlur = true,
        NotificationSounds = false,
        GlobalSettings = true
    })
else
    window = macLib:Window({
        Title = "Celestial",
        Subtitle = "Disabled - " .. version .. " | Survive and Kill the...\n - " .. gameName .. "\nTotal Executions: Disabled",
        DragStyle = 1,
        DisabledWindowControls = {},
        ShowUserInfo = true,
        Keybind = Enum.KeyCode.RightShift,
        AcrylicBlur = true,
        NotificationSounds = false,
        GlobalSettings = true
    })
end

-- Functions

local function notify(title, content, lifetime, soundName)
    window:Notify({
        Title = title,
        Description = content,
        Lifetime = lifetime
    })

    local sounds = {
        Neutral = 2.5,
        Success = 0.3,
        Error = 2,
        Hint = 3 }

    if not sounds[soundName] then
        warn("notify: Invalid sound: " .. soundName)
        return
    end

    if window.NotificationSounds then
        assetLib.fetchAsset("Assets/Sounds/" .. soundName .. ".mp3", sounds[soundName])
    end
end

local function getHRP()
    return entityLib.getCharInstance("HumanoidRootPart") or nil
end

local function getHumanoid()
    local humanoid = entityLib.getCharInstance("Humanoid")

    if not humanoid then
        return
    end

    return humanoid
end

-- Global Settings

window:GlobalSetting({
    Name = "Acrylic UI Blur",
    Default = window:GetAcrylicBlurState(),
    Tooltip = false,
    Callback = function(state)
        window:SetAcrylicBlurState(state)
        notify("Acrylic UI Blur", (state and "Enabled" or "Disabled") .. " Acrylic UI Blur.", 5, "Success")
    end,
})

window:GlobalSetting({
    Name = "User Info",
    Default = window:GetUserInfoState(),
    Tooltip = false,
    Callback = function(state)
        window:SetUserInfoState(state)
        notify("User Info", (state and "Enabled" or "Redacted") .. " User Info.", 5, "Success")
    end,
})

window:GlobalSetting({
    Name = "Notification Sounds",
    Default = window.NotificationSounds,
    Tooltip = false,
    Callback = function(state)
        window.NotificationSounds = state
        notify("Notification Sounds", (state and "Enabled" or "Disabled") .. " Notification Sounds.", 5, "Success")
    end,
})

window:GlobalSetting({
    Name = "Respawn Button",
    Default = true,
    Tooltip = false,
    Callback = function(state)
        starterGui:SetCore("ResetButtonCallback", state)
        notify("Respawn Button", (state and "Enabled" or "Disabled") .. " Respawn Button.", 5, "Success")
    end,
})

-- Tables

local tabGroups = {
    landing = window:TabGroup(),
    core = window:TabGroup()
}

local tabs = {
    home = tabGroups.landing:Tab({ Name = "Home", Image = assetLib.fetchAsset("Assets/Icons/Home.png") }),
    util = tabGroups.core:Tab({ Name = "Utility", Image = assetLib.fetchAsset("Assets/Icons/Utility.png") }),
    visuals = tabGroups.core:Tab({ Name = "Visuals", Image = assetLib.fetchAsset("Assets/Icons/Visuals.png") }),
    weapons = tabGroups.core:Tab({ Name = "Weapons", Image = assetLib.fetchAsset("Assets/Icons/Weapons.png") }),
    gui = tabGroups.core:Tab({ Name = "Game Interface", Image = assetLib.fetchAsset("Assets/Icons/Game Interface.png") }),
    misc = tabGroups.core:Tab({ Name = "Miscellaneous", Image = assetLib.fetchAsset("Assets/Icons/Miscellaneous.png") }),
    settings = tabGroups.core:Tab({ Name = "Configuration", Image = assetLib.fetchAsset("Assets/Icons/Settings.png") })
}

local sections = {
	homeSection1 = tabs.home:Section({ Side = "Left" }),
    homeSection2 = tabs.home:Section({ Side = "Right" }),
    homeSection3 = tabs.home:Section({ Side = "Left" }),

    utilSection1 = tabs.util:Section({ Side = "Left" }),
    utilSection2 = tabs.util:Section({ Side = "Right" }),
    utilSection3 = tabs.util:Section({ Side = "Left" }),
    utilSection4 = tabs.util:Section({ Side = "Right" }),

    visualsSection1 = tabs.visuals:Section({ Side = "Left" }),

    weaponsSection1 = tabs.weapons:Section({ Side = "Left" }),

    guiSection1 = tabs.gui:Section({ Side = "Left" }),

    miscSection1 = tabs.misc:Section({ Side = "Left" }),
    miscSection2 = tabs.misc:Section({ Side = "Right" })
}


-- =================================================
--                   TAB: HOME                   --
-- =================================================

-------------------------------------
--      HOME: SECTION 1  --
-------------------------------------

sections.homeSection1:Header({ Text = "User", Flag = "userHeader"})

if not scriptSettings.fastLoad then
    sections.homeSection1:Label({ Text = "Hardware ID:\n" .. auth.currentUser.HWID .. "\n\nIdentifier: " .. auth.currentUser.Identifier ..
    "\n\nRank: " .. auth.currentUser.Rank .. "\n\nJoin Date: " .. auth.currentUser.JoinDate .. "\n\nDiscord ID: " .. auth.currentUser.DiscordId, Flag = "authInfoLabel"})
else
    sections.homeSection1:Label({ Text = "Hardware ID: Disabled\n\nIdentifier: Disabled\n\nRank: Disabled\n\nJoin Date: Disabled\n\nDiscord ID: Disabled", Flag = "authInfoLabel"})
end

-------------------------------------
--      HOME: SECTION 2  --
-------------------------------------

sections.homeSection2:Header({ Text = "Game", Flag = "gameHeader"})

sections.homeSection2:Label({ Text = "Account Age: " .. player.AccountAge .. "\nDevEnableMouseLock: " .. tostring(player.DevEnableMouseLock) ..
"\nExecutor: " .. identifyexecutor() .. "\n\nCreator ID: " .. game.CreatorId .. "\nCreator Type: " .. game.CreatorType.Name .. "\nServer Instance:\n" .. game.JobId ..
"\nGame Name: " .. gameName .. "\nPlace ID: " .. game.PlaceId, Flag = "gameDetailsLabel"})

local playerCount = #players:GetPlayers()
local playerCountLabel = sections.homeSection2:Label({ Text = "Active Players: " .. playerCount})

local function updatePlayerCount()
    local newPlayerCount = #players:GetPlayers()
    playerCountLabel:UpdateName("Active Players: " .. newPlayerCount)
end

players.PlayerAdded:Connect(updatePlayerCount)
players.PlayerRemoving:Connect(updatePlayerCount)

currentGameEventLabel = sections.homeSection2:Label({ Text = "Current Game Event: " .. gameEvent})

-------------------------------------
--      HOME: SECTION 3  --
-------------------------------------

sections.homeSection3:Header({ Text = "Performance", Flag = "performanceHeader"})

local performanceLabel = sections.homeSection3:Label({ Text = "FPS: N/A\n\nPing: N/A\n\nMemory Usage: N/A", Flag = "performanceLabel"})

task.spawn(function()
    while true do
        performanceLabel:UpdateName("FPS: " .. entityLib.fetchFPS() .. "\n\nPing: " .. entityLib.fetchPing() .. " ms\n\nMemory Usage: " .. entityLib.fetchMemoryUsage() .. " MB")
        task.wait(1)
    end
end)

-- =================================================
--                   TAB: UTILITY                   --
-- =================================================

-------------------------------------
--      UTILITY: SECTION 1  --
-------------------------------------

local locationTeleportDropdown = sections.utilSection1:Dropdown({
	Name = "Teleport to Location",
    Tooltip = "sigma teleportation powers",
	Search = false,
	Multi = false,
	Required = true,
	Options = {"Spawn Kill", "Surface", "Area 51", "Alien", "Alien Code Input", "Pack A Punch Machine", "Armor", "Ammo Box", "Zombie Morph", "Radioactive Zone"},
	Default = 1,
    Disabled = false,
	Callback = function(value) end,
}, "locationTeleportDropdown")

sections.utilSection1:Button({
	Name = "Teleport",
    Tooltip = false,
    Disabled = false,
	Callback = function()
        local targetCFrame = CFrame.new()
        local hrp = getHRP()

        if locationTeleportDropdown.Value == "Spawn Kill" then
            targetCFrame = CFrame.new(-52.6837997, 313.500305, 292.096558, 1, 1.49757151e-09, -4.17306546e-05, -1.49720991e-09, 1, 8.6659675e-09, 4.17306546e-05, -8.66590533e-09, 1)
        elseif locationTeleportDropdown.Value == "Surface" then
            targetCFrame = CFrame.new(326.087067, 511.699921, 392.975769, 0.999967098, 0, 0.00810976978, 0, 1, 0, -0.00810976978, 0, 0.999967098)
        elseif locationTeleportDropdown.Value == "Area 51" then
            targetCFrame = CFrame.new(327.146332, 313.499908, 369.922913, 0.0146765877, 0, 0.999892294, 0, 1, 0, -0.999892294, 0, 0.0146765877)
        elseif locationTeleportDropdown.Value == "Alien" then
            targetCFrame = CFrame.new(237.99556, 337.799927, 472.399994, 4.34290196e-05, 1.17440393e-07, -1, 3.82457843e-09, 1, 1.17440564e-07, 1, -3.8296788e-09, 4.34290196e-05)
        elseif locationTeleportDropdown.Value == "Alien Code Input" then
            targetCFrame = CFrame.new(137.72377, 333.499939, 525.566956, -0.999551415, 4.71232431e-09, 0.0299497657, 4.37261027e-09, 1, -1.14082894e-08, -0.0299497657, -1.12722134e-08, -0.999551415)
        elseif locationTeleportDropdown.Value == "Pack A Punch Machine" then
            targetCFrame = game:GetService("Workspace").PACKAPUNCH.GUI
        elseif locationTeleportDropdown.Value == "Armor" then
            targetCFrame = CFrame.new(-167.243805, 293.500214, 316.368713, -0.0163577069, -1.04670743e-08, 0.999866188, 6.23807708e-08, 1, 1.14890186e-08, -0.999866188, 6.25603604e-08, -0.0163577069)
        elseif locationTeleportDropdown.Value == "Ammo Box" then
            targetCFrame = CFrame.new(184.26889, 314.102753, 437.041473, -0.999995649, 5.072752e-09, 0.00294528855, 5.24779331e-09, 1, 5.94231793e-08, -0.00294528855, 5.94383778e-08, -0.999995649)
        elseif locationTeleportDropdown.Value == "Zombie Morph" then
            targetCFrame = CFrame.new(402.278748, 512.499817, 399.379395, 0.999998093, -4.97486283e-08, 0.00196264265, 4.98476567e-08, 1, -5.0407067e-08, -0.00196264265, 5.05048021e-08, 0.999998093)
        elseif locationTeleportDropdown.Value == "Radioactive Zone" then
            targetCFrame = CFrame.new(140.615601, 313.499969, 435.841766, -0.9997648, 3.54234375e-09, 0.0216868054, 6.39699493e-09, 1, 1.31561421e-07, -0.0216868054, 1.31669211e-07, -0.9997648)
        end

        entityLib.teleport(targetCFrame)

        if entityLib.checkTeleport(hrp, targetCFrame, 5) then
            notify("Location Teleport", "Successfully teleported to " .. locationTeleportDropdown.Value .. ".", 6, "Success")
        else
            notify("Location Teleport", "Failed to teleport to " .. locationTeleportDropdown.Value .. ".", 6, "Error")
        end
	end,
})

-------------------------------------
--      UTILITY: SECTION 2  --
-------------------------------------

sections.utilSection2:Button({
	Name = "Drink Energy Drink",
    Tooltip = false,
    Disabled = false,
    Disabled = false,
	Callback = function()
        local energyDrink = entityLib.getTool("Specific", "Energy")

        if not energyDrink then
            notify("Drink Failed", "Energy Drink not found.", 7, "Error")
            return
        end
        
        if energyDrink.Ammo.Value == 0 then -- If no more uses
            notify("Drink Failed", "No more charges left.", 6, "Error")
            return
        end

        energyDrink.Drank:FireServer()
	end,
})

sections.utilSection2:Button({
	Name = "Drink All",
    Tooltip = false,
    Disabled = false,
	Callback = function()
        local energyDrink = entityLib.getTool("Specific", "Energy")

        if not energyDrink then
            notify("Drink Failed", "Energy Drink not found.", 7, "Error")
            return
        end
        
        if energyDrink.Ammo.Value == 0 then -- If no more uses
            notify("Drink Failed", "No more charges left.", 6, "Error")
            return
        end

        for _ = 1, energyDrink.Ammo.Value do
            energyDrink.Drank:FireServer()
        end
	end,
})

local function refillEnergyDrink()

    local energyDrink = entityLib.getTool("Specific", "Energy")
    local hrp = getHRP()
    
    if not energyDrink then
        notify("Refill Failed", "Energy Drink not found.", 7, "Error")
        return
    end
    
    if energyDrink.Ammo.Value ~= 0 then
        notify("Refill Failed", "You still have " .. energyDrink.Ammo.Value .. " charges left.", 6, "Error")
        return
    end
    
    local origCFrame = entityLib.storeData(hrp, "CFrame", true)
    
    task.wait(0.01)
    
    entityLib.teleport(CFrame.new(178.023087, 333.499908, 597.890442, 0.0192538705, -8.12836092e-08, 0.99981463, 1.48566126e-09, 1, 8.12700662e-08, -0.99981463, -7.93774491e-11, 0.0192538705))
    
    task.wait(0.17)
    
    utils.fireProxPrompt(game.Workspace.AREA51.CafeRoom["Coffee Machine"].Energy.Head)
    
    -- Restore original cframe / teleport back
    
    entityLib.restoreData(hrp, "CFrame")
    entityLib.clearData(hrp, "CFrame")
    

    --[[

    local energyDrink = entityLib.getTool("Specific", "Energy")
    local hrp = getHRP()
    
    if not energyDrink then
        notify("Refill Failed", "Energy Drink not found.", 7, "Error")
        return
    end

    if energyDrink.Ammo.Value ~= 0 then
        notify("Refill Failed", "You still have " .. energyDrink.Ammo.Value .. " charges left.", 6, "Error")
        return
    end

    local origCFrame = entityLib.storeData(hrp, "CFrame") -- Storing the original cframe before the teleports

    wait(0.01) -- wait 0.01 and teleport to the coffee machine
    
    entityLib.teleport(CFrame.new(178.023087, 333.499908, 597.890442, 0.0192538705, -8.12836092e-08, 0.99981463, 1.48566126e-09, 1, 8.12700662e-08, -0.99981463, -7.93774491e-11, 0.0192538705))
    
    wait(0.18) -- wait 0.17 and fire the prox prompt
    
    utils.fireProxPrompt(game.Workspace.AREA51.CafeRoom["Coffee Machine"].Energy.Head)
    
    wait(0.01) -- wait 0.4 for the teleport to finish
    
    entityLib.restoreData(hrp, "CFrame")

    -- Notify

    local timeout = 10
    local startTime = tick()
    
    repeat
        task.wait()
        if tick() - startTime > timeout then
            notify("Energy Drink Refill", "Timeout reached before refill.", 5, "Error")
            return -- Exit the loop if timeout is reached
        end
    until energyDrink.Ammo.Value == 4
    
    notify("Refill Energy Drink", "Successfully refilled energy drink.", 5, "Success")
    entityLib.clearData(hrp, "CFrame")

    ]]
end

sections.utilSection2:Button({
	Name = "Refill Energy Drink",
    Tooltip = false,
    Disabled = false,
	Callback = function()
        refillEnergyDrink()
	end,
})

local function getMaxThreshold()
    if utils.fetchOwnership("Gamepass", 1273854) then -- If the player owns the "Survivor pack" gamepass
        return 150
    else
        return 100
    end
end

local autoDrinkToggle
local autoDrinkThresholdSlider
local drinkLoopRunning = false
local autoDrinkDivider

-- Get energy drink tool

local function getEnergyDrink()
    local energyDrink = entityLib.getTool("Specific", "Energy")

    if energyDrink then
        local drankEvent = energyDrink:FindFirstChild("Drank")
        if not drankEvent then
            local connection
            connection = energyDrink.AncestryChanged:Connect(function(_, parent)
                if parent == player.Character then
                    if energyDrink:FindFirstChild("Drank") then
                        drankEvent = energyDrink.Drank
                        connection:Disconnect()
                    end
                end
            end)
        else
            return energyDrink, drankEvent
        end
    end
    return nil, nil
end

-- Start auto drink loop

local function startAutoDrinkLoop()
    if drinkLoopRunning or not autoDrinkToggle:GetState() then return end
    drinkLoopRunning = true

    task.spawn(function()
        while autoDrinkToggle:GetState() do
            local humanoid = getHumanoid()
            local energyDrink, drankEvent = getEnergyDrink()

            if not energyDrink or not drankEvent then
                notify("Drink Failed", "Energy Drink not found or invalid.", 7, "Error")
                break -- Stop loop if drink no is found
            end

            -- Auto drink when health is below the threshold

            if humanoid and humanoid.Health <= autoDrinkThresholdSlider:GetValue() then

                for _ = 1, 10 do
                    drankEvent:FireServer()
                    task.wait(0.1)
                end

            end

            task.wait()
        end

        drinkLoopRunning = false
    end)
end

local function startAutoRefillLoop()
    if autoRefillLoopRunning or not autoRefillToggle:GetState() then return end
    autoRefillLoopRunning = true

    task.spawn(function()
        local wasOutOfAmmo = false -- Track whether ammo was already 0 in the previous check

        while autoRefillToggle:GetState() do
            local energyDrink, _ = getEnergyDrink()
            if energyDrink and energyDrink:FindFirstChild("Ammo") then
                local ammoValue = energyDrink.Ammo.Value
                if ammoValue == 0 and not wasOutOfAmmo then
                    -- Notify when charges left is 0

                    --notify("Out of Energy Drink", "The energy drink's Ammo has run out.", 7, "Error")
                    refillEnergyDrink()

                    local hrp = getHRP()
                    entityLib.clearData(hrp, "CFrame")
                    
                    wasOutOfAmmo = true
                elseif ammoValue > 0 then
                    wasOutOfAmmo = false
                end
            end

            task.wait(0.5)
        end

        autoRefillLoopRunning = false
    end)
end

autoDrinkToggle = sections.utilSection2:Toggle({
    Name = "Auto Drink",
    Tooltip = false,
    Disabled = false,
    Default = false,
    Callback = function(enabled)
        autoDrinkThresholdSlider:SetVisibility(enabled)
        autoDrinkDivider:SetVisibility(enabled)

        if enabled then
            startAutoDrinkLoop()
        else
            drinkLoopRunning = false
        end
    end,
}, "autoDrinkToggle")

autoDrinkThresholdSlider = sections.utilSection2:Slider({
    Name = "Threshold",
    Tooltip = false,
    Default = 40,
    Minimum = 10,
    Maximum = getMaxThreshold(),
    Precision = 0,
    DisplayMethod = "Round",
    RoundedValue = true,
    Disabled = false,
    LimitInput = true,
    CustomValue = true,
    Callback = function(value) end,
}, "autoDrinkThresholdSlider")

-- Auto restart

player.CharacterAdded:Connect(function()
    drinkLoopRunning = false
    task.wait(1) -- Wait for character

    if autoDrinkToggle:GetState() then
        startAutoDrinkLoop()
    end
end)

sections.utilSection2:Label({ Text = "Auto Drink: Drinks the entire energy drink when you are below the threshold.", Flag = "autoDrinkHelpLabel" })
autoDrinkDivider = sections.utilSection2:Divider()

autoDrinkThresholdSlider:SetVisibility(autoDrinkToggle:GetState())
autoDrinkDivider:SetVisibility(autoDrinkToggle:GetState())

autoRefillToggle = sections.utilSection2:Toggle({
    Name = "Auto Refill",
    Tooltip = false,
    Tooltip = false,
    Disabled = false,
    Default = false,
    Callback = function(enabled)
        if enabled then
            startAutoRefillLoop()
        else
            autoRefillLoopRunning = false
        end
    end,
}, "autoRefillToggle")

-------------------------------------
--      UTILITY: SECTION 3  --
-------------------------------------

local weaponDropdown = sections.utilSection3:Dropdown({
	Name = "Give Weapons",
    Tooltip = false,
	Search = true,
	Multi = true,
	Required = false,
	Options = {"AK-47", "M4A1", "Desert Eagle", "AWP", "RayGun"},
	Default = {"M4A1", "AWP"},
    Disabled = false,
	Callback = function(value)
		-- Value should now directly contain the weapon names
		print("Selected weapons:", table.concat(value, ", "))
	end,
}, "weaponDropdown")

sections.utilSection3:Button({
	Name = "Give Weapon",
    Tooltip = false,
    Disabled = false,
    Disabled = false,
	Callback = function()
        if weaponDropdown.Value and type(weaponDropdown.Value) == "table" then
            for _, weaponName in ipairs(weaponDropdown.Value) do
                print("Fired event for weapon:", weaponName)
            end
        else
            print("No weapons selected or invalid value.")
        end
	end,
})




-------------------------------------
--      UTILITY: SECTION 4  --
-------------------------------------

-- code


-- =================================================
--                   TAB: VISUALS                   --
-- =================================================


-------------------------------------
--      VISUALS: SECTION 1  --
-------------------------------------

local killerESPToggle
local killerColorPicker
local killerESPRainbowToggle
local nameTagColorPicker
local nameTagRainbowToggle
local killerESPDivider
local sizeSlider
local excludedKillersDropdown

local espConnections = {}
local excludedKillers = { Giant = true, Jane = true, Tinsel = true, Chipper = true, Yeti = true, Keeps = true, Destroido = true }

local defaultTextSize = 15

local function clearESP(folder)
    for _, child in ipairs(folder:GetChildren()) do

        if child:IsA("Model") then
            local highlight = child:FindFirstChild("_CelestialKillerHighlight")
            if highlight then
                highlight:Destroy()
            end

            local head = child:FindFirstChild("Head")

            if head then
                local billboardGui = head:FindFirstChild("_CelestialBillboard")

                if billboardGui then
                    billboardGui:Destroy()
                end

            end

        end
    end
end

local function applyESP(folder)
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and not excludedKillers[child.Name] then
            -- Insert highlight

            if not child:FindFirstChild("_CelestialKillerHighlight") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "_CelestialKillerHighlight"
                highlight.Parent = child
                highlight.FillColor = killerColorPicker.Color
                highlight.OutlineColor = killerColorPicker.Color
                highlight.FillTransparency = killerColorPicker.Alpha
            end

            -- Insert BillboardGui name tag

            local head = child:FindFirstChild("Head")

            if head and not head:FindFirstChild("_CelestialBillboard") then
                local billboardGui = Instance.new("BillboardGui")
                billboardGui.Name = "_CelestialBillboard"
                billboardGui.Size = UDim2.new(4, 0, 1, 0)
                billboardGui.StudsOffset = Vector3.new(0, 2, 0)
                billboardGui.Adornee = head
                billboardGui.Parent = head
                billboardGui.AlwaysOnTop = true

                local textLabel = Instance.new("TextLabel")
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.Text = child.Name
                textLabel.TextScaled = false
                textLabel.TextColor3 = nameTagColorPicker.Color
                textLabel.Font = Enum.Font.GothamBold
                textLabel.TextSize = defaultTextSize
                textLabel.Parent = billboardGui
            end

        end
    end
end

killerESPToggle = sections.visualsSection1:Toggle({
    Name = "Killer ESP",
    Tooltip = false,
    Disabled = false,
    Default = false,
    Callback = function(enabled)
        killerColorPicker:SetVisibility(enabled)
        nameTagColorPicker:SetVisibility(enabled)
        killerESPRainbowToggle:SetVisibility(enabled)
        nameTagRainbowToggle:SetVisibility(enabled)
        excludedKillersDropdown:SetVisibility(enabled)
        sizeSlider:SetVisibility(enabled)
        killerESPDivider:SetVisibility(enabled)

        if enabled then
            -- Prevent duplicate connections

            for _, connection in pairs(espConnections) do
                if connection then connection:Disconnect() end
            end
            table.clear(espConnections)

            -- Apply esp

            local killersFolder = game.Workspace:FindFirstChild("Killers")
            if killersFolder then
                applyESP(killersFolder)
                
                espConnections["Killers"] = killersFolder.ChildAdded:Connect(function(child)
                    if child:IsA("Model") then
                        applyESP(killersFolder)
                    end
                end)

                -- Alive check

                espConnections["HealthCheck"] = game:GetService("RunService").Heartbeat:Connect(function()
                    for _, killer in pairs(killersFolder:GetChildren()) do
                        local humanoid = killer:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health <= 0 then
                            clearESP(killer)
                        end
                    end
                end)
            end
        else
            -- Cleanup
            
            local killersFolder = game.Workspace:FindFirstChild("Killers")
            if killersFolder then clearESP(killersFolder) end
            for _, connection in pairs(espConnections) do
                if connection then connection:Disconnect() end
            end

            table.clear(espConnections)
        end
    end,
}, "killerESPToggle")

killerColorPicker = sections.visualsSection1:Colorpicker({
    Name = "ESP Color",
    Tooltip = false,
    Default = Color3.fromRGB(255, 0, 0),
    Alpha = 0.5,
    AlphaEnabled = true,
    Disabled = false,
    Callback = function(color, alpha)
        local killersFolder = game.Workspace:FindFirstChild("Killers")
        clearESP(killersFolder)
        applyESP(killersFolder)
        
        if killersFolder then

            for _, highlight in pairs(killersFolder:GetDescendants()) do
                if highlight:IsA("Highlight") and highlight.Name == "_CelestialBadGuyHighlight" then
                    highlight.FillColor = color
                    highlight.OutlineColor = color
                    highlight.FillTransparency = alpha
                end
            end

        end
    end,
}, "killerColorPicker")

nameTagColorPicker = sections.visualsSection1:Colorpicker({
    Name = "Name Tag Color",
    Tooltip = false,
    Default = Color3.fromRGB(255, 255, 255),
    Alpha = 0,
    AlphaEnabled = false,
    Disabled = false,
    Callback = function(color)
        local killersFolder = game.Workspace:FindFirstChild("Killers")
        clearESP(killersFolder)
        applyESP(killersFolder)

        if killersFolder then
            for _, textLabel in pairs(killersFolder:GetDescendants()) do
                if textLabel:IsA("TextLabel") and textLabel.Parent:IsA("BillboardGui") then
                    textLabel.TextColor3 = color
                end
            end
        end
    end,
}, "nameTagColorPicker")

local rainbowActive
local rainbowConnection
local hue = 0

killerESPRainbowToggle = sections.visualsSection1:Toggle({
    Name = "ESP Rainbow",
    Tooltip = false,
    Disabled = true,
    Default = false,
    Callback = function(enabled)
        rainbowActive = enabled
        clearESP(game.Workspace:FindFirstChild("Killers"))
        applyESP(game.Workspace:FindFirstChild("Killers"))

        if rainbowActive then
            rainbowConnection = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
                hue = (hue + deltaTime * scriptSettings.rainbowSpeed) % 1
                killerColorPicker:SetColor(Color3.fromHSV(hue, 1, 1))
            end)
        elseif rainbowConnection then
            rainbowConnection:Disconnect()
            rainbowConnection = nil
        end

        if not enabled and scriptSettings.autoResetRainbowColor then
            killerColorPicker:SetColor(killerColorPicker.Settings.Default)
        end
    end,
}, "killerESPRainbowToggle")

local nameTagRainbowActive
local nameTagRainbowConnection
local nameTagHue = 0

nameTagRainbowToggle = sections.visualsSection1:Toggle({
    Name = "Name Tag Rainbow",
    Tooltip = false,
    Disabled = true,
    Default = false,
    Callback = function(enabled)
        nameTagRainbowActive = enabled
        clearESP(game.Workspace:FindFirstChild("Killers"))
        applyESP(game.Workspace:FindFirstChild("Killers"))

        if nameTagRainbowActive then
            nameTagRainbowConnection = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
                nameTagHue = (nameTagHue + deltaTime * scriptSettings.rainbowSpeed) % 1
                nameTagColorPicker:SetColor(Color3.fromHSV(nameTagHue, 1, 1))
            end)
        elseif nameTagRainbowConnection then
            nameTagRainbowConnection:Disconnect()
            nameTagRainbowConnection = nil
        end

        if not enabled and scriptSettings.autoResetRainbowColor then
            nameTagColorPicker:SetColor(nameTagColorPicker.Settings.Default)
        end
    end,
}, "nameTagRainbowToggle")

sizeSlider = sections.visualsSection1:Slider({
    Name = "Text Size",
    Tooltip = false,
    Default = 15,
    Minimum = 10,
    Maximum = 50,
    Precision = 0,
    DisplayMethod = "Round",
    RoundedValue = true,
    Disabled = false,
    LimitInput = { "Greater" },
    CustomValue = true,
    Callback = function(value)
        defaultTextSize = value
        local killersFolder = game.Workspace:FindFirstChild("Killers")

        if killersFolder then

            for _, billboard in pairs(killersFolder:GetDescendants()) do
                if billboard:IsA("TextLabel") and billboard.Parent.Name == "_CelestialBillboard" then
                    billboard.TextSize = value
                end
            end

        end
    end,
}, "sizeSlider")

if gameEvent == "Winter" then

    excludedKillersDropdown = sections.visualsSection1:Dropdown({
        Name = "Excluded Killers",
        Tooltip = false,
        Search = true,
        Multi = true,
        Required = false,
        Options = { "Alien", "Ao Oni", "Captain Zombie", "Chucky", "Eyeless Jack", "Fishface", "Freddy Krueger", "Ghostface", "Granny", "Jack Torrance", "Jane", "Jason", "Jeff", "Leatherface", "Michael Myers", "Pennywise", "Pinhead", "Rake", "Robot", "Slenderman", "Smile Dog", "Sonic.exe", "Tails Doll", "Wendigo", "Yeti", "Zombie", "Fuwatti", "Giant", "Evil Lawn Mower", "Tinsel", "Chipper", "Keeps", "Destroido"},
        Default = { "Giant", "Jane", "Tinsel", "Chipper", "Yeti", "Keeps", "Destroido" },
        Disabled = false,
        Callback = function(Value)
            excludedKillers = {}
    
            for killerName, state in pairs(Value) do
                if state then excludedKillers[killerName] = true end
            end
    
            if killerESPToggle:GetState() then
                local killersFolder = game.Workspace:FindFirstChild("Killers")
    
                if killersFolder then
                    clearESP(killersFolder)
                    applyESP(killersFolder)
                end
            end
        end,
    }, "excludedKillersDropdown")

else

    excludedKillersDropdown = sections.visualsSection1:Dropdown({
        Name = "Excluded Killers",
        Tooltip = false,
        Search = true,
        Multi = true,
        Required = false,
        Options = { "Alien", "Ao Oni", "Captain Zombie", "Chucky", "Eyeless Jack", "Fishface", "Freddy Krueger", "Ghostface", "Granny", "Jack Torrance", "Jane", "Jason", "Jeff", "Leatherface", "Michael Myers", "Pennywise", "Pinhead", "Rake", "Robot", "Slenderman", "Smile Dog", "Sonic.exe", "Tails Doll", "Wendigo", "Yeti", "Zombie", "Fuwatti", "Giant", "Evil Lawn Mower"},
        Default = { "Giant", "Jane" },
        Disabled = false,
        Callback = function(Value)
            excludedKillers = {}
    
            for killerName, state in pairs(Value) do
                if state then excludedKillers[killerName] = true end
            end
    
            if killerESPToggle:GetState() then
                local killersFolder = game.Workspace:FindFirstChild("Killers")
    
                if killersFolder then
                    clearESP(killersFolder)
                    applyESP(killersFolder)
                end
            end
        end,
    }, "excludedKillersDropdown")

end

killerESPDivider = sections.visualsSection1:Divider()

killerColorPicker:SetVisibility(killerESPToggle:GetState())
nameTagColorPicker:SetVisibility(killerESPToggle:GetState())
killerESPRainbowToggle:SetVisibility(killerESPToggle:GetState())
nameTagRainbowToggle:SetVisibility(killerESPToggle:GetState())
sizeSlider:SetVisibility(killerESPToggle:GetState())
excludedKillersDropdown:SetVisibility(killerESPToggle:GetState())
killerESPDivider:SetVisibility(killerESPToggle:GetState())

-- =================================================
--                   TAB: WEAPONS                   --
-- =================================================


-------------------------------------
--      WEAPONS: SECTION 1  --
-------------------------------------

-- code

-- =================================================
--                   TAB: GAME INTERFACE                   --
-- =================================================


-------------------------------------
--      GAME INTERFACE: SECTION 1  --
-------------------------------------

-- code

-- =================================================
--                   TAB: MISCELLANEOUS                   --
-- =================================================


-------------------------------------
--      MISCELLANEOUS: SECTION 1  --
-------------------------------------

local fpsCapSlider
local origFPSCap = getfpscap()
local unlockFPSToggle = sections.miscSection1:Toggle({
    Name = "Unlock FPS",
    Tooltip = false,
    Disabled = false,
    Default = false,
    Callback = function(enabled)
        if fpsCapSlider then
            fpsCapSlider:SetVisibility(enabled)
        end

        if enabled then
            origFPSCap = getfpscap()
            setfpscap(fpsCapSlider:GetValue())
        else
            setfpscap(origFPSCap)
        end
    end,
}, "UnlockFPS")

fpsCapSlider = sections.miscSection1:Slider({
    Name = "FPS Cap",
    Tooltip = false,
    Default = 0,
    Minimum = 0,
    Maximum = 360,
    Precision = 0,
    DisplayMethod = "Round",
    RoundedValue = true,
    Disabled = false,
    LimitInput = { "Greater" },
    CustomValue = true,
    Callback = function(value)
        if unlockFPSEnabled then
            setfpscap(value)
        end
    end,
}, "FPSCapSlider")

fpsCapSlider:SetVisibility(unlockFPSToggle:GetState())
unlockFPSToggle:UpdateState(true) -- why maclib default argument no work

local autoclickerToggle
local autoclickerBind
local autoclickerCPSSlider
local autoclickerEnabled = false
autoclickerToggle = sections.miscSection1:Toggle({
    Name = "Autoclicker",
    Tooltip = false,
    Disabled = false,
    Default = false,
    Callback = function(enabled)
        autoclickerBind:SetVisibility(enabled)
        autoclickerCPSSlider:SetVisibility(enabled)

        if not enabled then
            autoclickerEnabled = false
        end
    end,
}, "autoclickerToggle")

autoclickerBind = sections.miscSection1:Keybind({
    Name = "Autoclicker Keybind",
    Tooltip = false,
    Default = Enum.KeyCode.K,
    Disabled = false,
    BlacklistedBinds = {Enum.KeyCode.Space, Enum.KeyCode.LeftSuper, Enum.KeyCode.RightSuper, Enum.KeyCode.Escape, Enum.KeyCode.Backspace, Enum.KeyCode.Return,
    Enum.KeyCode.Power, Enum.KeyCode.Undo, Enum.KeyCode.Insert, Enum.KeyCode.Print, Enum.KeyCode.Slash, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S,
    Enum.KeyCode.D},
    Callback = function(binded)
        if not autoclickerToggle:GetState() then return end -- If the Autoclicker toggle is disabled, return
        autoclickerEnabled = not autoclickerEnabled -- Toggle the autoclicker state

        if autoclickerEnabled then
            task.spawn(function()
                while autoclickerEnabled and autoclickerToggle:GetState() do
                    if not isrbxactive() then
                        repeat task.wait(0.1) until isrbxactive()
                    end
                    
                    if window:GetState() then
                        repeat task.wait(0.1) until not window:GetState() -- Pause when window is open
                    end

                    mouse1click()
                    task.wait(1 / autoclickerCPSSlider:GetValue())
                end
            end)
        end
    end
}, "autoclickerBind")

autoclickerCPSSlider = sections.miscSection1:Slider({
    Name = "Autoclicker CPS",
    Tooltip = false,
    Default = 10,
    Minimum = 1,
    Maximum = 30,
    Precision = 0,
    DisplayMethod = "Round",
    RoundedValue = true,
    Disabled = false,
    LimitInput = true,
    CustomValue = false,
    Callback = function(value) end,
}, "autoclickerCPSSlider")

autoclickerBind:SetVisibility(autoclickerToggle:GetState())
autoclickerCPSSlider:SetVisibility(autoclickerToggle:GetState())

sections.miscSection1:Divider()

local interfaceToggleBind
interfaceToggleBind = sections.miscSection1:Keybind({
	Name = "Interface Toggle",
    Tooltip = false,
    Default = Enum.KeyCode.RightShift,
    Disabled = false,
    BlacklistedBinds = {Enum.KeyCode.Space, Enum.KeyCode.LeftSuper, Enum.KeyCode.RightSuper, Enum.KeyCode.Escape, Enum.KeyCode.Backspace, Enum.KeyCode.Return,
    Enum.KeyCode.Power, Enum.KeyCode.Undo, Enum.KeyCode.Insert, Enum.KeyCode.Print, Enum.KeyCode.Slash, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S,
    Enum.KeyCode.D},
	Callback = function(binded) end,
	onBinded = function(bind)
        window:SetKeybind(bind)
        notify("Celestial", "Successfully binded interface to " .. tostring(bind.Name) .. ".", 5, "Success")

        task.defer(function()
            task.wait(0.25)
            local visible = window:GetState()
            
            if not visible then
                window:SetState(true)
            end
        end)
	end,
}, "interfaceToggleBind")

-------------------------------------
--      MISCELLANEOUS: SECTION 2  --
-------------------------------------

sections.miscSection2:Header({ Text = "Script Settings", Flag = "scriptSettingsHeader"})

local rainbowSpeedSlider
rainbowSpeedSlider = sections.miscSection2:Slider({
    Name = "Rainbow Speed",
    Tooltip = false,
    Default = 0.1,
    Minimum = 0.1,
    Maximum = 1,
    Precision = 1,
    DisplayMethod = "Round",
    RoundedValue = true,
    Disabled = true,
    LimitInput = true,
    CustomValue = false,
    Callback = function(value)
        scriptSettings.rainbowSpeed = roundedValue
    end,
}, "rainbowSpeedSlider")

local autoColorResetToggle = sections.miscSection2:Toggle({
    Name = "Auto-Reset Color",
    Tooltip = false,
    Disabled = true,
    Default = true,
    Callback = function(enabled)
        scriptSettings.autoResetRainbowColor = enabled
    end,
}, "autoColorResetToggle")





-- Window unload shit


local function unloadModules()
    unlockFPSToggle:UpdateState(false)
    autoclickerToggle:UpdateState(false)
end

-- Handle any case were the Maclib interface is destroyed abruptly

for _, newMaclibUI in pairs(macLibLocation:GetDescendants()) do
    if newMaclibUI:IsA("ScreenGui") then
        if newMaclibUI.DisplayOrder == 2147483647 and newMaclibUI.Name == "ScreenGui" and not newMaclibUI.ResetOnSpawn then
            
            task.spawn(function()

                newMaclibUI.AncestryChanged:Connect(function(_, parent)
                    if not parent then
                        unloadModules()
                    end
                end)

            end)

        end
    end
end

window.onUnloaded(function()
    unloadModules()
end)

tabs.util:Select()
macLib:SetFolder("Celestial ScriptHub")
tabs.settings:InsertConfigSection("Left")
macLib:LoadAutoLoadConfig()

if getgenv().notifyLoad == true then
    local endTime = tick()
    local loadTime = utils.round(endTime - startTime, 2)
    
    if loadTime >= 5 then
        notify("⚠️ Celestial", "Delayed execution.\nCelestial loaded in " .. loadTime .. " seconds.", 6, "Success")
    else
        notify("Celestial", "Celestial loaded in " .. loadTime .. " seconds.", 6, "Success")
    end
end

getgenv().script_key = nil
getgenv().notifyLoad = nil