while not game:IsLoaded() do
    task.wait()
end

local macLib = loadstring(readfile("Maclib - Revamped.lua"))()
--local macLib = loadstring(readfile("Maclib - Revamped.lua"))()

local scriptSettings = {
    fastLoad = true,
    testing = true,
    rainbowSpeed = 0.1,
    autoResetRainbowColor = true
}

if scriptSettings.testing then
    getgenv().script_key = "lQwkSPLnL29AIKCAxmWuQ91M0gzjPuUugJ0Xd"
    getgenv().notifyLoad = true
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
local events = game:GetService("ReplicatedStorage").Events
local sounds = game:GetService("Workspace").Sounds

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
        Subtitle = auth.currentUser.Identifier .. " - " .. version .. " | Break In 2 (Story)\n - " .. gameName .. "\nTotal Executions: " .. executionLib.fetchExecutions(),
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
        Subtitle = "Disabled - " .. version .. " | Break In 2 (Story)\n - " .. gameName .. "\nTotal Executions: Disabled",
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

local function setInvenSoundState(enabled)
    local invenSound = sounds.Inventory

    if not enabled then
        invenSound.SoundId = ""
    else
        for i = 1, 1000 do
            invenSound.TimePosition = 0
            invenSound.Playing = false
        end

        invenSound.SoundId = "rbxassetid://4678793943"

    end
end

local function setEnergyUI(enabled)
    if not enabled then
        for _, v in pairs(player.PlayerGui.EnergyBar.EnergyBar.EnergyBar:GetChildren()) do
            if v.Name == "Template" and v:IsA("TextLabel") and v.TextColor3 ~= Color3.fromRGB(255, 72, 0) then
                v.Visible = false
            end
        end

    else

        for _, v in pairs(player.PlayerGui.EnergyBar.EnergyBar.EnergyBar:GetChildren()) do
            if v.Name == "Template" and v:IsA("TextLabel") and v.TextColor3 ~= Color3.fromRGB(255, 72, 0) then
                v.Visible = true
            end
        end
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
    Tooltip = false,
    Default = window:GetAcrylicBlurState(),
    Callback = function(state)
        window:SetAcrylicBlurState(state)
        notify("Acrylic UI Blur", (state and "Enabled" or "Disabled") .. " Acrylic UI Blur.", 5, "Success")
    end,
})

window:GlobalSetting({
    Name = "User Info",
    Tooltip = false,
    Default = window:GetUserInfoState(),
    Callback = function(state)
        window:SetUserInfoState(state)
        notify("User Info", (state and "Enabled" or "Redacted") .. " User Info.", 5, "Success")
    end,
})

window:GlobalSetting({
    Name = "Notification Sounds",
    Tooltip = false,
    Default = window.NotificationSounds,
    Callback = function(state)
        window.NotificationSounds = state
        notify("Notification Sounds", (state and "Enabled" or "Disabled") .. " Notification Sounds.", 5, "Success")
    end,
})

window:GlobalSetting({
    Name = "Respawn Button",
    Tooltip = false,
    Default = true,
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
    exploits = tabGroups.core:Tab({ Name = "Exploits", Image = assetLib.fetchAsset("Assets/Icons/Exploit.png") }),
    util = tabGroups.core:Tab({ Name = "Utility", Image = assetLib.fetchAsset("Assets/Icons/Utility.png") }),
    player = tabGroups.core:Tab({ Name = "Player", Image = assetLib.fetchAsset("Assets/Icons/Player.png") }),
    endings = tabGroups.core:Tab({ Name = "Endings", Image = assetLib.fetchAsset("Assets/Icons/Endings.png") }),
    misc = tabGroups.core:Tab({ Name = "Miscellaneous", Image = assetLib.fetchAsset("Assets/Icons/Miscellaneous.png") }),
    settings = tabGroups.core:Tab({ Name = "Configuration", Image = assetLib.fetchAsset("Assets/Icons/Settings.png") })
}

local sections = {
	homeSection1 = tabs.home:Section({ Side = "Left" }),
    homeSection2 = tabs.home:Section({ Side = "Right" }),
    homeSection3 = tabs.home:Section({ Side = "Left" }),

    exploitsSection1 = tabs.exploits:Section({ Side = "Left" }),
    exploitsSection2 = tabs.exploits:Section({ Side = "Right" }),
    exploitsSection3 = tabs.exploits:Section({ Side = "Left" }),
    exploitsSection4 = tabs.exploits:Section({ Side = "Right" }),
    exploitsSection5 = tabs.exploits:Section({ Side = "Left" }),

    utilSection1 = tabs.util:Section({ Side = "Left" }),

    playerSection1 = tabs.player:Section({ Side = "Left" }),

    endingsSection1 = tabs.endings:Section({ Side = "Left" }),

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
--                   TAB: EXPLOITS                   --
-- =================================================

-------------------------------------
--      EXPLOITS: SECTION 1  --
-------------------------------------

local godmodeToggle
local godmodeDelaySlider
godmodeToggle = sections.exploitsSection1:Toggle({
    Name = "Godmode",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        godmodeDelaySlider:SetVisibility(enabled)

        if enabled then
            setInvenSoundState(false)

            task.spawn(function()
                repeat
                    events.GiveTool:FireServer("Pizza")
                    events.Energy:FireServer(25, "Pizza")
                    
                    task.wait(godmodeDelaySlider:GetValue())
                until not godmodeToggle:GetState()
            end)
        else
            setInvenSoundState(true)
        end
    end,
}, "godmodeToggle")

godmodeDelaySlider = sections.exploitsSection1:Slider({
    Name = "Delay",
    Tooltip = false,
    Default = 0.05,
    Minimum = 0,
    Maximum = 10,
    Precision = 2,
    DisplayMethod = "Round",
    RoundedValue = true,
    Disabled = false,
    LimitInput = true,
    CustomValue = true,
    Callback = function(value) end,
}, "godmodeDelaySlider")

godmodeDelaySlider:SetVisibility(godmodeToggle:GetState())

local hideEnergyToggle
hideEnergyToggle = sections.exploitsSection1:Toggle({
    Name = "Hide Energy Gain",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                repeat

                    setEnergyUI(false)
                    
                    task.wait()
                until not hideEnergyToggle:GetState()
            end)

        else

            setEnergyUI(true)
        end
    end,
}, "hideEnergyToggle")


sections.exploitsSection1:Divider()

local speedExploitToggle
local speedExploitDelaySlider
speedExploitToggle = sections.exploitsSection1:Toggle({
    Name = "Speed Exploit",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        speedExploitDelaySlider:SetVisibility(enabled)

        if enabled then
            setInvenSoundState(false)

            task.spawn(function()
                repeat
                    events.GiveTool:FireServer("BloxyCola")
                    events.Energy:FireServer(15, "BloxyCola")
                    
                    task.wait(speedExploitDelaySlider:GetValue())
                until not speedExploitToggle:GetState()
            end)

            task.spawn(function()
                repeat
                    setEnergyUI(false)
                    
                    task.wait()
                until not speedExploitToggle:GetState()
            end)
        else
            setInvenSoundState(true)
            wait(2)
            setEnergyUI(true)
        end
    end,
}, "speedExploitToggle")

speedExploitDelaySlider = sections.exploitsSection1:Slider({
    Name = "Delay",
    Tooltip = false,
    Default = 1,
    Minimum = 0,
    Maximum = 10,
    Precision = 2,
    DisplayMethod = "Round",
    RoundedValue = true,
    Disabled = false,
    LimitInput = true,
    CustomValue = true,
    Callback = function(value) end,
}, "speedExploitDelaySlider")

speedExploitDelaySlider:SetVisibility(speedExploitToggle:GetState())

local collectCashToggle
collectCashToggle = sections.exploitsSection1:Toggle({
    Name = "Collect Cash",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        if enabled then
            local hrp = getHRP()

            task.spawn(function()
                repeat
                    for _, v in pairs(game:GetService("Workspace"):GetChildren()) do
                        if v.Name == "Part" and v:FindFirstChild("TouchInterest") and v:FindFirstChild("Weld") and v.Transparency == 1 then
                            v.CFrame = hrp.CFrame
                            task.wait(0.1)
                        end
                    end
                    
                    task.wait()
                until not collectCashToggle:GetState()
            end)
        end
    end,
}, "collectCashToggle")

-------------------------------------
--      EXPLOITS: SECTION 2  --
-------------------------------------

local hiddenItemESPToggle
local hiddenItemColorPicker
local hiddenItemESPRainbowToggle
local hiddenHighlights = {}
local hiddenItemESPDivider
hiddenItemESPToggle = sections.exploitsSection2:Toggle({
    Name = "Hidden Item ESP",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        hiddenItemColorPicker:SetVisibility(enabled)
        hiddenItemESPRainbowToggle:SetVisibility(enabled)
        hiddenItemESPDivider:SetVisibility(enabled)

        if enabled then
            task.spawn(function()
                repeat
                    local color = hiddenItemColorPicker.Color

                    for _, drawerItem in pairs(game.Workspace.Hidden:GetChildren()) do
                        if not drawerItem:FindFirstChild("_CelestialItemHighlight") then
                            local hiddenitemhighlight = Instance.new("Highlight", drawerItem)
                            hiddenitemhighlight.Name = "_CelestialItemHighlight"
                            hiddenitemhighlight.FillColor = color
                            hiddenitemhighlight.FillTransparency = 0.5
                            hiddenitemhighlight.OutlineColor = color
                            hiddenitemhighlight.OutlineTransparency = 0

                            hiddenHighlights[drawerItem] = hiddenitemhighlight
                        else
                            local highlight = drawerItem["_CelestialItemHighlight"]
                            highlight.FillColor = color
                            highlight.FillTransparency = 0.5
                            highlight.OutlineColor = color
                        end
                    end

                    task.wait()

                until not hiddenItemESPToggle:GetState()
            end)
        else
            for _, highlight in pairs(hiddenHighlights) do
                if highlight then
                    highlight:Destroy()
                end
            end
            table.clear(hiddenHighlights)
        end
    end,
}, "hiddenItemESPToggle")


hiddenItemColorPicker = sections.exploitsSection2:Colorpicker({
    Name = "Hidden Item Color",
    Tooltip = false,
    Default = Color3.fromRGB(0, 255, 255),
    Alpha = 0.5,
    AlphaEnabled = false,
    Disabled = false,
    Callback = function(color, alpha) end,
}, "hiddenItemColorPicker")

local rainbowActive1
local rainbowConnection1
local hue1 = 0

hiddenItemESPRainbowToggle = sections.exploitsSection2:Toggle({
    Name = "Rainbow",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        rainbowActive1 = enabled

        if rainbowActive1 then
            rainbowConnection1 = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
                hue1 = (hue1 + deltaTime * scriptSettings.rainbowSpeed) % 1
                hiddenItemColorPicker:SetColor(Color3.fromHSV(hue1, 1, 1))
            end)
        elseif rainbowConnection1 then
            rainbowConnection1:Disconnect()
            rainbowConnection1 = nil
        end

        if not enabled and scriptSettings.autoResetRainbowColor then
            hiddenItemColorPicker:SetColor(hiddenItemColorPicker.Settings.Default)
        end
    end,
}, "hiddenItemESPRainbowToggle")


hiddenItemESPDivider = sections.exploitsSection2:Divider()


local badGuyESPToggle
local badGuyColorPicker
local badGuyESPRainbowToggle
local espConnections = {}
local badGuyESPDivider

badGuyESPToggle = sections.exploitsSection2:Toggle({
    Name = "Bad Guy ESP",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        badGuyColorPicker:SetVisibility(enabled)
        badGuyESPRainbowToggle:SetVisibility(enabled)
        badGuyESPDivider:SetVisibility(enabled)

        local function applyESP(folder)
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("Model") and not child:FindFirstChild("_CelestialBadGuyHighlight") then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "_CelestialBadGuyHighlight"
                    highlight.Parent = child
                    highlight.FillColor = badGuyColorPicker.Color
                    highlight.OutlineColor = badGuyColorPicker.Color
                    highlight.FillTransparency = badGuyColorPicker.Alpha
                end
            end
        end
        
        local function clearESP(folder)
            for _, highlight in pairs(folder:GetDescendants()) do
                if highlight:IsA("Highlight") and highlight.Name == "_CelestialBadGuyHighlight" then
                    highlight:Destroy()
                end
            end
        end

        if enabled then
            -- Preventing duplicate connections

            for _, connection in pairs(espConnections) do
                if connection then connection:Disconnect() end
            end
            table.clear(espConnections)

            -- Look for bad guy models

            for _, folderName in pairs({"BadGuys", "BadGuysFront"}) do
                local folder = game.Workspace:FindFirstChild(folderName)
                if folder then
                    applyESP(folder) -- Existing models

                    -- New models

                    espConnections[folderName] = folder.ChildAdded:Connect(function(child)
                        if child:IsA("Model") then
                            local highlight = Instance.new("Highlight")
                            highlight.Name = "_CelestialBadGuyHighlight"
                            highlight.Parent = child
                            highlight.FillColor = badGuyColorPicker.Color
                            highlight.OutlineColor = badGuyColorPicker.Color
                            highlight.FillTransparency = badGuyColorPicker.Alpha
                        end
                    end)
                end
            end
        else
            -- Cleanup

            for _, folderName in pairs({"BadGuys", "BadGuysFront"}) do
                local folder = game.Workspace:FindFirstChild(folderName)
                if folder then clearESP(folder) end
            end

            for _, connection in pairs(espConnections) do
                if connection then connection:Disconnect() end
            end
            table.clear(espConnections)
        end
    end,
}, "badGuyESPToggle")

badGuyColorPicker = sections.exploitsSection2:Colorpicker({
    Name = "Bad Guy Color",
    Tooltip = false,
    Default = Color3.fromRGB(255, 0, 0),
    Alpha = 0.5,
    AlphaEnabled = true,
    Disabled = false,
    Callback = function(color, alpha)
        for _, folderName in pairs({"BadGuys", "BadGuysFront"}) do
            local folder = game.Workspace:FindFirstChild(folderName)

            if folder then
                for _, highlight in pairs(folder:GetDescendants()) do
                    if highlight:IsA("Highlight") and highlight.Name == "_CelestialBadGuyHighlight" then
                        highlight.FillColor = color
                        highlight.OutlineColor = color
                        highlight.FillTransparency = alpha
                    end
                end
            end
        end
    end,
}, "badGuyColorPicker")

local rainbowActive2
local rainbowConnection2
local hue2 = 0

badGuyESPRainbowToggle = sections.exploitsSection2:Toggle({
    Name = "Rainbow",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        rainbowActive2 = enabled

        if rainbowActive2 then
            rainbowConnection2 = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
                hue2 = (hue2 + deltaTime * scriptSettings.rainbowSpeed) % 1
                badGuyColorPicker:SetColor(Color3.fromHSV(hue2, 1, 1))
            end)
        elseif rainbowConnection2 then
            rainbowConnection2:Disconnect()
            rainbowConnection2 = nil
        end

        if not enabled and scriptSettings.autoResetRainbowColor then
            badGuyColorPicker:SetColor(badGuyColorPicker.Settings.Default)
        end
    end,
}, "badGuyESPRainbowToggle")


badGuyESPDivider = sections.exploitsSection2:Divider()


hiddenItemColorPicker:SetVisibility(hiddenItemESPToggle:GetState())
hiddenItemESPRainbowToggle:SetVisibility(hiddenItemESPToggle:GetState())

badGuyColorPicker:SetVisibility(badGuyESPToggle:GetState())
badGuyESPRainbowToggle:SetVisibility(badGuyESPToggle:GetState())

hiddenItemESPDivider:SetVisibility(hiddenItemESPToggle:GetState())
badGuyESPDivider:SetVisibility(badGuyESPToggle:GetState())

local disableFrontDoor
disableFrontDoor = sections.exploitsSection2:Toggle({
    Name = "Disable Front Door",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                while disableFrontDoor:GetState() do
                    for _, v in pairs(game.Workspace.tst:GetDescendants()) do
                        if v.Name == "Door" and v:IsA("Part") then
                            v.CanCollide = false
                            v.Transparency = 0.4
                        end
                    end
                
                    for _, v in pairs(game.Workspace.Doors1:GetDescendants()) do
                        if v.Name == "Door" and v:IsA("Part") then
                            v.CanCollide = false
                            v.Transparency = 0.4
                        end
                    end

                    task.wait(1)
                end
            end)
        else
            for _, v in pairs(game.Workspace.tst:GetDescendants()) do
                if v.Name == "Door" and v:IsA("Part") then
                    v.CanCollide = true
                    v.Transparency = 0
                end
            end

            for _, v in pairs(game.Workspace.Doors1:GetDescendants()) do
                if v.Name == "Door" and v:IsA("Part") then
                    v.CanCollide = true
                    v.Transparency = 0
                end
            end
        end
    end,
}, "disableFrontDoor")

local disableVignette
disableVignette = sections.exploitsSection2:Toggle({
    Name = "Disable Vignette",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                repeat
                    player.PlayerGui.Assets.Vig.Visible = false
                    
                    task.wait()
                until not disableVignette:GetState()
            end)
        else
            player.PlayerGui.Assets.Vig.Visible = true
        end
    end,
}, "disableFrontDoor")

-------------------------------------
--      EXPLOITS: SECTION 3  --
-------------------------------------

local locationTeleportDropdown = sections.exploitsSection3:Dropdown({
	Name = "Teleport to Location",
    Tooltip = false,
	Search = false,
	Multi = false,
	Required = true,
	Options = {"Villian Base", "Kitchen", "Fighting Arena", "Gym", "Pizza Boss", "Shop", "Golden Apple Path", "Generator", "Boss Fight"},
	Default = 1,
    Disabled = false,
	Callback = function(value) end,
}, "locationTeleportDropdown")

sections.exploitsSection3:Button({
	Name = "Teleport",
    Tooltip = false,
    Disabled = false,
	Callback = function()
        local targetCFrame = CFrame.new()
        local hrp = getHRP()

        if locationTeleportDropdown.Value == "Villian Base" then
            targetCFrame = CFrame.new(-233.926117, 30.4567528, -790.019897, 0.00195977557, -8.22674984e-11, -0.999998093, -2.4766762e-09, 1, -8.71213934e-11, 0.999998093, 2.47684229e-09, 0.00195977557)
            utils.fireTouchEvent(hrp, game.Workspace.InsideTouchParts.FrontDoor)
        elseif locationTeleportDropdown.Value == "Kitchen" then
            targetCFrame = CFrame.new(-216.701218, 30.4702568, -722.335327, 0.00404609647, 1.23633853e-07, 0.999991834, -7.18327664e-09, 1, -1.23605801e-07, -0.999991834, -6.68309719e-09, 0.00404609647)
        elseif locationTeleportDropdown.Value == "Fighting Arena" then
            targetCFrame = CFrame.new(-262.294586, 62.7116394, -735.916199, -1, -7.62224133e-08, -0.000201582094, -7.6233647e-08, 1, 5.5719358e-08, 0.000201582094, 5.57347235e-08, -1)
            utils.fireTouchEvent(hrp, game.Workspace.EvilArea.EnterPart)
        elseif locationTeleportDropdown.Value == "Gym" then
            targetCFrame = CFrame.new(-257.281738, 63.4477501, -843.258362, 0.999999464, -6.6242154e-09, 0.00105193094, 6.52111609e-09, 1, 9.80127126e-08, -0.00105193094, -9.8005799e-08, 0.999999464)
        elseif locationTeleportDropdown.Value == "Pizza Boss" then
            targetCFrame = CFrame.new(-287.475769, 30.4527531, -721.746277, -0.00427152216, -8.6121041e-08, 0.99999088, 2.21573924e-08, 1, 8.6216474e-08, -0.99999088, 2.25254659e-08, -0.00427152216)
        elseif locationTeleportDropdown.Value == "Shop" then
            targetCFrame = CFrame.new(-251.009491, 30.4477539, -851.509705, 0.0225389507, 7.41174511e-10, -0.999745965, 2.19171417e-10, 1, 7.46304019e-10, 0.999745965, -2.35936659e-10, 0.0225389507)
        elseif locationTeleportDropdown.Value == "Golden Apple Path" then
            targetCFrame = CFrame.new(85.6087112, 29.4477024, -804.023926, -0.999134541, 1.15144616e-09, 0.0415947847, 4.49046622e-09, 1, 8.01815432e-08, -0.0415947847, 8.02989319e-08, -0.999134541)
        elseif locationTeleportDropdown.Value == "Generator" then
            targetCFrame = CFrame.new(-114.484352, 30.0235462, -790.053833, -0.656062722, 0, -0.754706323, 0, 1, 0, 0.754706323, 0, -0.656062722)
        elseif locationTeleportDropdown.Value == "Boss Fight" then
            targetCFrame = CFrame.new(-1328.85242, -346.249146, -810.092285, 0.00456922129, 5.69967078e-08, 0.999989569, 1.76120984e-08, 1, -5.70777772e-08, -0.999989569, 1.78727166e-08, 0.00456922129)
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
--      EXPLOITS: SECTION 4  --
-------------------------------------

local insideSpoofToggle
local outsideSpoofToggle
local fightSpoofToggle
insideSpoofToggle = sections.exploitsSection4:Toggle({
    Name = "Inside Spoof",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        if enabled then
            outsideSpoofToggle:UpdateState(false)
            fightSpoofToggle:UpdateState(false)

            local hrp = getHRP()

            task.spawn(function()
                repeat
                    utils.fireTouchEvent(hrp, game.Workspace.InsideTouchParts.FrontDoor)
                    
                    task.wait(0.2)
                until not insideSpoofToggle:GetState()
            end)
        end
    end,
}, "insideSpoofToggle")

outsideSpoofToggle = sections.exploitsSection4:Toggle({
    Name = "Outside Spoof",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        if enabled then
            insideSpoofToggle:UpdateState(false)
            fightSpoofToggle:UpdateState(false)

            local hrp = getHRP()

            task.spawn(function()
                repeat
                    utils.fireTouchEvent(hrp, game.Workspace.OutsideTouchParts.OutsideTouch)
                    
                    task.wait(0.2)
                until not outsideSpoofToggle:GetState()
            end)
        end
    end,
}, "outsideSpoofToggle")

fightSpoofToggle = sections.exploitsSection4:Toggle({
    Name = "Fight Spoof",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        local hrp = getHRP()

        if enabled then
            insideSpoofToggle:UpdateState(false)
            outsideSpoofToggle:UpdateState(false)

            task.spawn(function()
                repeat
                    utils.fireTouchEvent(hrp, game.Workspace.EvilArea.EnterPart)
                    
                    task.wait(1)
                until not fightSpoofToggle:GetState()
            end)
        else
            utils.fireTouchEvent(hrp, game.Workspace.EvilArea.ExitPart2)
        end
    end,
}, "fightSpoofToggle")

-------------------------------------
--      EXPLOITS: SECTION 5  --
-------------------------------------

local autoKillToggle
local autoKillAmountSlider
autoKillToggle = sections.exploitsSection5:Toggle({
    Name = "Auto Kill",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        autoKillAmountSlider:SetVisibility(enabled)

        if enabled then
            task.spawn(function()
                local workspace = game:GetService("Workspace")
                local hitEvent = events:WaitForChild("HitBadguy")
                local damage, multiplier = autoKillAmountSlider:GetValue(), 4

                local function attackTargets(folderName)
                    local folder = workspace:FindFirstChild(folderName)

                    if folder then
                        for _, enemy in pairs(folder:GetChildren()) do
                            hitEvent:FireServer(enemy, damage, multiplier)
                        end
                    end
                end

                local enemyFolders = {"BadGuys", "BadGuysBoss", "BadGuysFront"}

                repeat

                    for _, group in ipairs(enemyFolders) do
                        attackTargets(group)
                    end

                    for _, enemyName in ipairs({"BadGuyPizza", "BadGuyBrute"}) do
                        local enemy = workspace:FindFirstChild(enemyName, true)
                        if enemy then
                            hitEvent:FireServer(enemy, damage, multiplier)
                        end
                    end

                    task.wait(0.1)
                until not autoKillToggle:GetState()
            end)
        end
    end,
}, "autoKillToggle")

autoKillAmountSlider = sections.exploitsSection5:Slider({
    Name = "Damage Amount",
    Tooltip = false,
    Default = 100,
    Minimum = 1,
    Maximum = 100,
    Precision = 0,
    DisplayMethod = "Round",
    RoundedValue = true,
    Disabled = false,
    LimitInput = { "Greater" },
    CustomValue = true,
    Callback = function(value) end,
}, "autoKillAmountSlider")

autoKillAmountSlider:SetVisibility(autoKillToggle:GetState())


-- =================================================
--                   TAB: UTILITY                   --
-- =================================================


-------------------------------------
--      UTILITY: SECTION 1  --
-------------------------------------

sections.utilSection1:Header({ Text = "Items", Flag = "itemsHeader"})

local itemDropdown = sections.utilSection1:Dropdown({
    Name = "Item",
    Tooltip = false,
    Search = true,
    Multi = true,
    Required = true,
    Options = {"GoldPizza", "GoldenApple", "RainbowPizzaBox", "RainbowPizza", "GoldKey", "Bottle", "Armor", "Louise", "Lollipop", "Ladder", "MedKit", "Chips", "Cookie", "BloxyCola", "Apple", "Pizza", "ExpiredBloxyCola"},
    Default = {"GoldPizza"},
    Disabled = false,
    Callback = function(value) end,
}, "itemDropdown")

local giveAmountSlider
giveAmountSlider = sections.utilSection1:Slider({
    Name = "Amount",
    Tooltip = false,
    Default = 10,
    Minimum = 1,
    Maximum = 800,
    Precision = 0,
    DisplayMethod = "Round",
    RoundedValue = true,
    Disabled = false,
    LimitInput = true,
    CustomValue = true,
    Callback = function(value) end,
}, "giveAmountSlider")

sections.utilSection1:Button({
    Name = "Give Item",
    Tooltip = false,
    Disabled = false,
    Callback = function()
        local selectedItems = 0
        local playerInventoryBefore = {}

        -- Save inventory count before giving items

        for _, tool in ipairs(player.Backpack:GetChildren()) do
            playerInventoryBefore[tool.Name] = (playerInventoryBefore[tool.Name] or 0) + 1
        end

        for item, isSelected in pairs(itemDropdown:GetOptions()) do
            if isSelected then
                selectedItems = selectedItems + 1

                -- Handle giving armor

                if item == "Armor" and not player.Character:FindFirstChild("Desert Storm Army Vest") then
                    events.Vending:FireServer(3, "Armor2", "Armor", player.Name, true, 1)

                    task.wait(0.03)
                    if player.Character:FindFirstChild("Desert Storm Army Vest") then
                        notify("Given Item", "You have been given armor.", 4, "Success")
                    else
                        notify("Give Item Failed", "Armor detection failed.", 4, "Error")
                    end
                else
                    -- Handle the giving of other items

                    for _ = 1, giveAmountSlider:GetValue() do
                        events.GiveTool:FireServer(item)
                    end
                end

                task.wait()
            end
        end

        task.wait(0.2)

        -- Save inventory count after giving items

        local playerInventoryAfter = {}
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            playerInventoryAfter[tool.Name] = (playerInventoryAfter[tool.Name] or 0) + 1
        end

        -- Compare the stored inventories before and after to detect new items and their quantities

        local newItems = {}
        for itemName, afterCount in pairs(playerInventoryAfter) do
            local beforeCount = playerInventoryBefore[itemName] or 0
            local quantityAdded = afterCount - beforeCount

            if quantityAdded > 0 then
                table.insert(newItems, quantityAdded .. "x " .. itemName)
            end
        end

        -- Notify new items

        if #newItems > 0 then
            notify("New Items Received", "You have received: " .. table.concat(newItems, ", "), 4, "Success")
        else
            notify("No New Items", "No new items were detected.", 4, "Error")
        end
    end,
})

sections.utilSection1:Divider()

sections.utilSection1:Header({ Text = "Weapons", Flag = "weaponsHeader"})

local giveWeaponBtn
local weaponDropdown = sections.utilSection1:Dropdown({
    Name = "Weapon",
    Tooltip = false,
    Search = true,
    Multi = false,
    Required = true,
    Options = {"Crowbar 1", "Crowbar 2", "Bat", "Pitchfork", "Hammer", "Wrench", "Broom"},
    Default = 1,
    Disabled = false,
    Callback = function(weapon)
        giveWeaponBtn:UpdateName("Give " .. weapon)
    end,
}, "weaponDropdown")

giveWeaponBtn = sections.utilSection1:Button({
    Name = "Give Weapon",
    Tooltip = false,
    Disabled = false,
    Callback = function()
        local weapon = weaponDropdown.Value

        -- Check if the player already has the weapon

        if entityLib.getTool("Specific", weapon) then
            notify("Give Weapon Failed", "You already have: " .. weapon .. ".", 6, "Error")
            return
        end

        -- Save inventory weapons before giving the weapon

        local inventoryBefore = {}
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            inventoryBefore[tool.Name] = true
        end

        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then
                inventoryBefore[tool.Name] = true
            end
        end

        events.Vending:FireServer(3, weapon, "Weapons", player.Name, 1)
        task.wait(0.5)

        -- Check inventory to determine if the weapon was successfully given

        if entityLib.getTool("Specific", weapon) then
            notify("Weapon Given", "You have received: " .. weapon .. ".", 6, "Success")
        else
            notify("Give Weapon Failed", "Weapon could not be given: " .. weapon .. ".", 6, "Error")
        end
    end,
})

giveWeaponBtn:UpdateName("Give " .. weaponDropdown.Value)

giveBestWeapon = sections.utilSection1:Button({
    Name = "Give Best Weapon",
    Tooltip = false,
    Disabled = false,
    Callback = function()
        local bestWeapon = player.PlayerGui.Phone.Phone.Phone.Background.InfoScreen.WeaponInfo.TwadoWants.Text

        -- Check if the player already has the weapon

        if entityLib.getTool("Specific", bestWeapon) then
            notify("Give Best Weapon Failed", "You already have the best weapon: " .. bestWeapon .. ".", 6, "Error")
            return
        end

        -- Save inventory weapons before giving the weapon

        local inventoryBefore = {}
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            inventoryBefore[tool.Name] = true
        end

        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then
                inventoryBefore[tool.Name] = true
            end
        end

        events.Vending:FireServer(3, bestWeapon, "Weapons", player.Name, 1)
        task.wait(0.5)

        -- Check inventory to determine if the weapon was successfully given

        if entityLib.getTool("Specific", bestWeapon) then
            notify("Best Weapon Given", "You have received: " .. bestWeapon .. ".", 6, "Success")
        else
            notify("Give Best Weapon Failed", "Best Weapon could not be given: " .. bestWeapon .. ".", 6, "Error")
        end
    end,
})

-- =================================================
--                   TAB: PLAYER                   --
-- =================================================


-------------------------------------
--      PLAYER: SECTION 1  --
-------------------------------------

-- code


-- =================================================
--                   TAB: ENDINGS                   --
-- =================================================


-------------------------------------
--      ENDINGS: SECTION 1  --
-------------------------------------

-- code


-- =================================================
--                   TAB: MISCELLANEOUS                   --
-- =================================================


-------------------------------------
--      MISCELLANEOUS: SECTION 1  --
-------------------------------------

sections.miscSection1:Button({
	Name = "Lobby",
    Tooltip = false,
    Disabled = false,
	Callback = function()
        window:Dialog({
            Title = "Lobby Teleport",
            Description = "Are you sure you would like to teleport to the Break In 2 lobby?",
            Buttons = {
                {
                    Name = "Confirm",
                    Callback = function()

                        utils.gameTeleport(13864661000)

                        notify("Teleport in process", "Teleporting to lobby...", 100, "Neutral")
                    end,
                },
                {
                    Name = "Cancel"
                }
            }
        })
	end,
})

local fpsCapSlider
local origFPSCap = getfpscap()
local unlockFPSToggle = sections.miscSection1:Toggle({
    Name = "Unlock FPS",
    Tooltip = false,
    Default = false,
    Disabled = false,
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
        local unlockFPSEnabled = unlockFPSToggle:GetState()

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
    Default = false,
    Disabled = false,
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
    Disabled = false,
    LimitInput = true,
    CustomValue = false,
    Callback = function(value)
        scriptSettings.rainbowSpeed = roundedValue
    end,
}, "rainbowSpeedSlider")

local autoColorResetToggle = sections.miscSection2:Toggle({
    Name = "Auto-Reset Color",
    Tooltip = false,
    Default = true,
    Disabled = false,
    Callback = function(enabled)
        scriptSettings.autoResetRainbowColor = enabled
    end,
}, "autoColorResetToggle")




-- Window unload shit


local function unloadModules()
    godmodeToggle:UpdateState(false)
    hideEnergyToggle:UpdateState(false)
    speedExploitToggle:UpdateState(false)
    collectCashToggle:UpdateState(false)
    hiddenItemESPToggle:UpdateState(false)
    badGuyESPToggle:UpdateState(false)
    disableFrontDoor:UpdateState(false)
    disableVignette:UpdateState(false)
    insideSpoofToggle:UpdateState(false)
    outsideSpoofToggle:UpdateState(false)
    fightSpoofToggle:UpdateState(false)

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

tabs.exploits:Select()
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