while not game:IsLoaded() do
    task.wait()
end

local macLib = loadstring(readfile("Maclib - Revamped.lua"))()
--local macLib = loadstring(readfile("Maclib - Revamped.lua"))()

local scriptSettings = {
    fastLoad = true,
    testing = true
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
local remoteEvents = game:GetService("ReplicatedStorage").RemoteEvents

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
    player = tabGroups.core:Tab({ Name = "Player", Image = assetLib.fetchAsset("Assets/Icons/Player.png") }),
    gui = tabGroups.core:Tab({ Name = "Game Interface", Image = assetLib.fetchAsset("Assets/Icons/Game Interface.png") }),
    misc = tabGroups.core:Tab({ Name = "Miscellaneous", Image = assetLib.fetchAsset("Assets/Icons/Miscellaneous.png") }),
    settings = tabGroups.core:Tab({ Name = "Configuration", Image = assetLib.fetchAsset("Assets/Icons/Settings.png") })
}

local sections = {
	homeSection1 = tabs.home:Section({ Side = "Left" }),
    homeSection2 = tabs.home:Section({ Side = "Right" }),
    homeSection3 = tabs.home:Section({ Side = "Left" }),

    playerSection1 = tabs.player:Section({ Side = "Left" }),
    playerSection2 = tabs.player:Section({ Side = "Right" }),

    miscSection1 = tabs.misc:Section({ Side = "Left" }),

    guiSection1 = tabs.gui:Section({ Side = "Left" })
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
--                   TAB: PLAYER                   --
-- =================================================

-------------------------------------
--      PLAYER: SECTION 1  --
-------------------------------------

local truckTeleportDropdown = sections.playerSection1:Dropdown({
	Name = "Teleport to Truck",
    Tooltip = false,
	Search = false,
	Multi = false,
	Required = true,
	Options = {"Truck 1", "Truck 2"},
	Default = 1,
    Disabled = false,
	Callback = function(value) end,
}, "truckTeleportDropdown")

sections.playerSection1:Button({
	Name = "Teleport",
    Tooltip = false,
    Disabled = false,
	Callback = function()
        local hrp = getHRP()
        local humanoid = getHumanoid()

        if humanoid.Sit then
            humanoid.Sit = false
            wait(1.5)
        end

        -- Get trucks

        local truck1 = false
        local truck2 = false
        
        for _, truckEnterPart in pairs(game.Workspace:GetChildren()) do
            if truckEnterPart.Name == "Part" and truckEnterPart:FindFirstChild("TouchInterest") and #truckEnterPart:GetChildren() == 1 then
               
                if truckEnterPart.Position == Vector3.new(87.43499755859375, 7.869999408721924, 108.88998413085938) then
                    truck1 = truckEnterPart
                elseif truckEnterPart.Position == Vector3.new(87.43499755859375, 7.869999408721924, 147.38998413085938) then
                    truck2 = truckEnterPart
                end

            end
        end

        -- Dropdown handling

        if truckTeleportDropdown.Value == "Truck 1" then
            utils.fireTouchEvent(hrp, truck1)
        elseif truckTeleportDropdown.Value == "Truck 2" then
            utils.fireTouchEvent(hrp, truck2)
        end
	end,
})

-------------------------------------
--      PLAYER: SECTION 2  --
-------------------------------------

local useCostumeToggle = sections.playerSection2:Toggle({
    Name = "Use Costume",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled) end,
}, "useCostumeToggle")

local useKidHeightToggle = sections.playerSection2:Toggle({
    Name = "Use Kid Height",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled) end,
}, "useKidHeightToggle")

local basicRoleDropdown = sections.playerSection2:Dropdown({
	Name = "Basic Role",
    Tooltip = false,
	Search = false,
	Multi = false,
	Required = true,
	Options = {"The Hyper (Lollipop)", "The Sporty (Sports Drink)", "The Protecter (Bat)", "The Medic (MedKit)"},
	Default = 1,
    Disabled = false,
	Callback = function(value) end,
}, "basicRoleDropdown")

sections.playerSection2:Button({
	Name = "Update Role",
    Tooltip = false,
    Disabled = false,
	Callback = function()
        local basicRoleDropdownValue = basicRoleDropdown.Value
        local useKidHeight = useKidHeightToggle:GetState()
        local useCostume = useCostumeToggle:GetState()

        if basicRoleDropdownValue == "The Hyper (Lollipop)" then
            remoteEvents.MakeRole:FireServer("Lollipop", useKidHeight, useCostume)
        elseif basicRoleDropdownValue == "The Sporty (Sports Drink)" then
            remoteEvents.MakeRole:FireServer("Bottle", useKidHeight, useCostume)
        elseif basicRoleDropdownValue == "The Protecter (Bat)" then
            remoteEvents.MakeRole:FireServer("Bat", useKidHeight, useCostume)
        elseif basicRoleDropdownValue == "The Medic (MedKit)" then
            remoteEvents.MakeRole:FireServer("MedKit", useKidHeight, useCostume)
        end
	end,
})


-- GAME INTERFACE


-------------------------------------
--      GAME INTERFACE: SECTION 1  --
-------------------------------------

local disableRecapToggle
disableRecapToggle = sections.guiSection1:Toggle({
    Name = "Disable Break In 1 Recap",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        local frame = player.PlayerGui.RightMenu.RightMenu.RightMenu.RightMenu.BreakIn1

        if enabled then
            frame.Visible = false
    
            local connection
            connection = frame:GetPropertyChangedSignal("Visible"):Connect(function()
                if frame.Visible then
                    disableRecapToggle:UpdateState(not enabled)
                    connection:Disconnect()
                end
            end)
        else
            frame.Visible = true
        end
    end,
}, "disableRecapToggle")

local theHuntMenuToggle
theHuntMenuToggle = sections.guiSection1:Toggle({
    Name = "The Hunt Event Menu",
    Tooltip = false,
    Default = false,
    Disabled = false,
    Callback = function(enabled)
        local frame = player.PlayerGui.BreakIn1ScreenHunt.BreakIn1ScreenHunt.BreakIn1ScreenHunt.Dialogue

        if enabled then
            frame.Visible = true
    
            local connection
            connection = frame:GetPropertyChangedSignal("Visible"):Connect(function()
                if not frame.Visible then
                    theHuntMenuToggle:UpdateState(not enabled)
                    connection:Disconnect()
                end
            end)
        else
            frame.Visible = false
        end
    end,
}, "theHuntMenuToggle")


-- =================================================
--                   TAB: MISCELLANEOUS                   --
-- =================================================


-------------------------------------
--      MISCELLANEOUS: SECTION 1  --
-------------------------------------

sections.miscSection1:Button({
	Name = "Rejoin",
    Tooltip = false,
    Disabled = false,
	Callback = function()
        window:Dialog({
            Title = "Rejoin",
            Description = "Are you sure you would like to rejoin this server?",
            Buttons = {
                {
                    Name = "Confirm",
                    Callback = function()

                        utils.gameTeleport("Rejoin")

                        notify("Rejoin in process", "Rejoining server...\n" .. game.JobId, 100, "Neutral")
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
    Disabled = false,
    Default = false,
    Callback = function(enabled)
        if fpsCapSlider then
            fpsCapSlider:SetVisibility(enabled)
        end

        if enabled then
            origFPSCap = getfpscap()
            setfpscap(utils.round(fpsCapSlider:GetValue(), 0))
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




-- Window unload shit


local function unloadModules()
    disableRecapToggle:UpdateState(false)
    theHuntMenuToggle:UpdateState(false)
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

tabs.player:Select()
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