while not game:IsLoaded() do
    task.wait()
end

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Authentication.lua"))()

if not auth.isUser() then
    return
end

-- Library variables

local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"    
local library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local themeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local saveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local options = library.Options
local toggles = library.Toggles

-- Custom variables

local player = game:GetService("Players").LocalPlayer
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local exploit = identifyexecutor()
local workspace = game:GetService("Workspace")

-- Function checks

local notifSounds = {
    neutral = 17208372272,
    success = 5797580410,
    error = 5797578819
}

if not typeof(firetouchinterest) == "function" then
    library:Notify(exploit .. " does not support firetouchinterest.", 15, notifSounds.error)
end

-- Window

local window = library:CreateWindow({
    Title = "Celestial - " .. gameName .. ": " .. auth.currentUser.Identifer,
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Left",
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Module Variables

local queueDropdownValue = "1"

local tabs = {
    info = window:AddTab("Info"),
    main = window:AddTab("Main"),
    ["UI Settings"] = window:AddTab("Configs")
}

if auth.fetchConfig("notifyExecution") then
    library:Notify("Successfully logged in as " .. auth.currentUser.Rank .. ": " .. auth.currentUser.Identifer, 6, notifSounds.neutral)
else
    library:Notify("Celestial has loaded / " .. utils.getTime(false) .. ".", 6, notifSounds.neutral)
end

-- Tab: Game Info

local gameDetailsGroup = tabs.info:AddLeftGroupbox("Game Details")
local userDetailsGroup = tabs.info:AddRightGroupbox("User Details")
local whitelistDetailsGroup = tabs.info:AddLeftGroupbox("Whitelist Details")

-- Group: Game Info

gameDetailsGroup:AddDivider()

gameDetailsGroup:AddLabel("Game Supported: false", true)
gameDetailsGroup:AddLabel("Game Name: " .. gameName, true)
gameDetailsGroup:AddLabel("Place ID: " .. game.PlaceId, true)

-- Group: User Info

userDetailsGroup:AddDivider()

userDetailsGroup:AddLabel("Username: " .. player.Name, true)
userDetailsGroup:AddLabel("Display Name: " .. player.DisplayName, true)
userDetailsGroup:AddLabel("Account Age: " .. player.AccountAge .. " Days", true)
userDetailsGroup:AddLabel("Executor: " .. exploit, true)

-- Group: Whitelist Details

whitelistDetailsGroup:AddDivider()

whitelistDetailsGroup:AddLabel("HWID: " .. auth.currentUser.HWID, true)
whitelistDetailsGroup:AddLabel("Identifer: " .. auth.currentUser.Identifer, true)
whitelistDetailsGroup:AddLabel("Rank: " .. auth.currentUser.Rank, true)
whitelistDetailsGroup:AddLabel("JoinDate: " .. auth.currentUser.JoinDate, true)

-- Tab: Main

local objectsGroup = tabs.main:AddLeftGroupbox("Objects")
local gameGroup = tabs.main:AddRightGroupbox("Game")

-- Group: Objects

objectsGroup:AddDivider()

local noclipEnabled = false
local originalCanCollideStates = {}
local connection

objectsGroup:AddToggle("Noclip", {
    Text = "Noclip",
    Tooltip = "Allows you to clip through walls.",
    Default = false,

    Callback = function(enabled)
        noclipEnabled = enabled

        if noclipEnabled then
            -- Store original CanCollide states

            if game.Players.LocalPlayer.Character then
                for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and originalCanCollideStates[part] == nil then
                        originalCanCollideStates[part] = part.CanCollide -- Store the state
                        part.CanCollide = false
                    end
                end
            end

            -- Ensure collisions stay off

            if not connection then
                connection = game:GetService("RunService").Stepped:Connect(function()
                    if noclipEnabled and game.Players.LocalPlayer.Character then
                        for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") and originalCanCollideStates[part] ~= nil then
                                part.CanCollide = false -- Ensure collision remains off
                            end
                        end
                    end
                end)
            end
        else
            -- Restore original CanCollide states
            
            if game.Players.LocalPlayer.Character then
                for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and originalCanCollideStates[part] ~= nil then
                        part.CanCollide = originalCanCollideStates[part] -- Restore original state
                    end
                end
            end
            originalCanCollideStates = {}

            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})

-- Group: Game

gameGroup:AddDivider()

gameGroup:AddDropdown("queueDropdown", {
    Values = {"1", "2", "3", "4", "5", "6"},
    Default = 1,
    Multi = false,

    Text = "Location",
    Tooltip = false,

    Callback = function(value)
        queueDropdownValue = value
    end
})

local teleportToQueue = gameGroup:AddButton({
    Text = "Teleport",
    Func = function()
        local queuesFolder = workspace.Teleporters
        local requestedQueue = queuesFolder:FindFirstChild(queueDropdownValue)
        local hrp = utils.getCharInstance("HumanoidRootPart")

        if requestedQueue then
            utils.fireTouchEvent(hrp, requestedQueue.Updater)
        else
            library:Notify(queueDropdownValue .. " is not a valid queue.", 6, notifysounds.error)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

-----------------------------------------------------------------------------------------------------------------------------------

local watermarkEnabled = false

library:SetWatermarkVisibility(watermarkEnabled)

if watermarkEnabled then

    local frameTimer = tick()
    local frameCounter = 0
    local fps = 60
    
    local watermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
        frameCounter += 1
    
        if (tick() - frameTimer) >= 1 then
            fps = frameCounter
            frameTimer = tick()
            frameCounter = 0
        end
    
        library:SetWatermark(("Celestial | %s fps | %s ms"):format(
            math.floor(fps),
            math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        ))
    end)
end

library.KeybindFrame.Visible = false

library:OnUnload(function()
    -- Noclip

    if game.Players.LocalPlayer.Character then
        for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and originalCanCollideStates[part] ~= nil then
                part.CanCollide = originalCanCollideStates[part] -- Restore original state
            end
        end
    end
    originalCanCollideStates = {}

    if connection then
        connection:Disconnect()
        connection = nil
    end

    -- Unloading

    if watermarkEnabled and watermarkConnection then
        watermarkConnection:Disconnect()
    end

    library.Unloaded = true
end)

-- Group: Menu

local menuGroup = tabs["UI Settings"]:AddLeftGroupbox("Menu")

menuGroup:AddButton("Unload", function()
    library:Unload()
end)

menuGroup:AddDivider()

menuGroup:AddToggle("keybindMenuToggle", {
    Text = "Keybind Menu",
    Default = library.KeybindFrame.Visible,
    Callback = function(state)
        Library.KeybindFrame.Visible = state
    end,
    Disabled = true,
    DisabledTooltip = "No current keybinds."
})

menuGroup:AddToggle("customCursorToggle", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(state)
        library.ShowCustomCursor = state
    end
})

menuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind",{ Default = "End", NoUI = true, Text = "Menu keybind" })

library.ToggleKeybind = options.MenuKeybind

themeManager:SetLibrary(library)
saveManager:SetLibrary(library)

themeManager:SetFolder("Celestial")
saveManager:SetFolder("Celestial/A Dusty Trip")

saveManager:IgnoreThemeSettings()
saveManager:SetIgnoreIndexes({"MenuKeybind"})
saveManager:BuildConfigSection(tabs["UI Settings"])
themeManager:ApplyToTab(tabs["UI Settings"])

saveManager:LoadAutoloadConfig()