while not game:IsLoaded() do
    task.wait()
end

local auth = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Authentication.lua?ref_type=heads"))()
local entityLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Entity%20Library.lua?ref_type=heads"))()
local utils = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Core%20Utilities.lua?ref_type=heads"))()
auth.trigger()

if not auth.isUser() or auth.kicked then
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
local hrp = entityLib.getCharInstance("HumanoidRootPart")
local remoteEvents = game:GetService("ReplicatedStorage").RemoteEvents

-- Window

local window = library:CreateWindow({
    Title = "Celestial - " .. gameName .. ": " .. auth.currentUser.Identifier,
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Left",
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Module Variables

local truckTeleportDropdownValue = "Truck 1"
local basicRoleDropdownValue = "The Hyper (Lollipop)"
local specialRoleDropdownValue = "The Nerd (Book)"
local useCostume = false
local useKidHeight = true

-- Functions

local notifSounds = {
    neutral = 17208372272,
    success = 5797580410,
    error = 5797578819
}

local tabs = {
    info = window:AddTab("Info"),
    main = window:AddTab("Main"),
    gui = window:AddTab("GUI"),
    ["UI Settings"] = window:AddTab("Configs")
}

library:Notify("Successfully logged in as " .. auth.currentUser.Rank .. ": " .. auth.currentUser.Identifier, 6, notifSounds.neutral)

-- Tab: Game Info

local gameDetailsGroup = tabs.info:AddLeftGroupbox("Game Details")
local userDetailsGroup = tabs.info:AddRightGroupbox("User Details")
local whitelistDetailsGroup = tabs.info:AddLeftGroupbox("Whitelist Details")

-- Group: Game Info

gameDetailsGroup:AddDivider()

gameDetailsGroup:AddLabel("Game Supported: true", true)
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
whitelistDetailsGroup:AddLabel("Identifier: " .. auth.currentUser.Identifier, true)
whitelistDetailsGroup:AddLabel("Rank: " .. auth.currentUser.Rank, true)
whitelistDetailsGroup:AddLabel("JoinDate: " .. auth.currentUser.JoinDate, true)
whitelistDetailsGroup:AddLabel("Discord ID: " .. auth.currentUser.DiscordId, true)
whitelistDetailsGroup:AddLabel("Key: " .. auth.currentUser.Key, true)

-- Tab: Main

local automationGroup = tabs.main:AddLeftGroupbox("Automation")
local rolesGroup = tabs.main:AddRightGroupbox("Roles")

-- Group: Automation

automationGroup:AddDivider()

automationGroup:AddDropdown("truckTeleportDropdown", {
    Values = {"Truck 1", "Truck 2"},
    Default = 1,
    Multi = false,

    Text = "Truck Teleport",
    Tooltip = false,

    Callback = function(value)
        truckTeleportDropdownValue = value
    end
})

local truckTeleportBtn = automationGroup:AddButton({
    Text = "Teleport",
    Func = function()
        local humanoid = entityLib.getCharInstance("Humanoid")

        if humanoid.Sit then
            humanoid.Sit = false

            wait(0.4)
        else
            humanoid.Sit = false
        end

        if truckTeleportDropdownValue == "Truck 1" then
            entityLib.teleport(87.4349976, 7.86999941, 108.889984, 8.10623169e-05, 1, 8.10623169e-05, -8.10623169e-05, -8.10623169e-05, 1, 1, -8.10623169e-05, 8.10623169e-05)
        elseif truckTeleportDropdownValue == "Truck 2" then
            entityLib.teleport(87.4349976, 7.86999941, 147.389984, 8.10623169e-05, 1, 8.10623169e-05, -8.10623169e-05, -8.10623169e-05, 1, 1, -8.10623169e-05, 8.10623169e-05)
        end

        if truckTeleportDropdownValue ~= "" then
            library:Notify("You've been teleported to: " .. truckTeleportDropdownValue .. ".", 3, notifSounds.success)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

-- Group: Roles

rolesGroup:AddDivider()

rolesGroup:AddToggle("useCostumeToggle", {
	Text = "Use Costume",
	Tooltip = "Toggles the use of costumes for each role.",
	Default = false,

	Callback = function(state)
        useCostume = state
	end
})

rolesGroup:AddToggle("useKidHeightToggle", {
	Text = "Use Kid Height",
	Tooltip = "Toggles the use of kid height for each role.",
	Default = true,

	Callback = function(state)
        useKidHeight = state
	end
})

rolesGroup:AddDropdown("basicRoleDropdown", {
    Values = {"The Hyper (Lollipop)", "The Sporty (Sports Drink)", "The Protecter (Bat)", "The Medic (MedKit)"},
    Default = 1,
    Multi = false,

    Text = "Basic Role",
    Tooltip = false,

    Callback = function(value)
        basicRoleDropdownValue = value
    end
})

local updateBasicRoleBtn = rolesGroup:AddButton({
    Text = "Update Role",
    Func = function()
        if basicRoleDropdownValue == "The Hyper (Lollipop)" then
            remoteEvents.MakeRole:FireServer("Lollipop", useKidHeight, useCostume)
        elseif basicRoleDropdownValue == "The Sporty (Sports Drink)" then
            remoteEvents.MakeRole:FireServer("Bottle", useKidHeight, useCostume)
        elseif basicRoleDropdownValue == "The Protecter (Bat)" then
            remoteEvents.MakeRole:FireServer("Bat", useKidHeight, useCostume)
        elseif basicRoleDropdownValue == "The Medic (Medkit)" then
            remoteEvents.MakeRole:FireServer("MedKit", useKidHeight, useCostume)
        end

        if basicRoleDropdownValue ~= "" then
            library:Notify("Your role has been updated to: " .. basicRoleDropdownValue .. ".", 3, notifSounds.success)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

rolesGroup:AddDivider()

rolesGroup:AddDropdown("specialRoleDropdown", {
    Values = {"The Nerd (Book)", "The Hacker (Admin Phone)"},
    Default = 1,
    Multi = false,

    Text = "Special Role",
    Tooltip = false,

    Callback = function(value)
        specialRoleDropdownValue = value
    end
})

local updateSpecialRoleBtn = rolesGroup:AddButton({
    Text = "Update Role",
    Func = function()
        if specialRoleDropdownValue == "The Nerd (Book)" then
            remoteEvents.MakeRole:FireServer("Book", useKidHeight, useCostume)
        elseif specialRoleDropdownValue == "The Hacker (Admin Phone)" then
            remoteEvents.MakeRole:FireServer("Phone", useKidHeight, useCostume)
        end

        if specialRoleDropdownValue ~= "" then
            library:Notify("Your role has been updated to: " .. specialRoleDropdownValue .. ".", 3, notifSounds.success)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

-- Tab: GUI

local guiGroup = tabs.gui:AddLeftGroupbox("UI Elements")
local achievementSpoofGroup = tabs.gui:AddRightGroupbox("Achievement Spoofer")

-- Group: UI Elements

guiGroup:AddDivider()

guiGroup:AddToggle("disableBreakIn1Recap", {
	Text = "Disable Break In 1 Recap",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        player.PlayerGui.RightMenu.RightMenu.RightMenu.RightMenu.BreakIn1.Visible = not state
	end
})

guiGroup:AddToggle("toggleTheHuntEventMenu", {
	Text = "The Hunt Event Menu",
	Tooltip = 'Toggles "The Hunt" menu, used in the 2024 Roblox Egg Hunt.',
	Default = false,

	Callback = function(state)
        local frame = player.PlayerGui.BreakIn1ScreenHunt.BreakIn1ScreenHunt.BreakIn1ScreenHunt.Dialogue
        local toggle = toggles.toggleTheHuntEventMenu

        if state then
            frame.Visible = true
    
            -- Monitor visibility
            
            local connection
            connection = frame:GetPropertyChangedSignal("Visible"):Connect(function()
                if not frame.Visible then
                    toggle:SetValue(false)
                    connection:Disconnect()
                end
            end)
        else
            frame.Visible = false
        end
	end
})

-- Group: Achievement Spoofer

achievementSpoofGroup:AddDivider()

local achievementNumberInput = ""
local newAchievementIndicator = false

local previousAchievementRatio
local hadNewIndicator

local saveAchievementSettingsBtn = achievementSpoofGroup:AddButton({
	Text = "Save Current Achievement Settings",
	Func = function()
        previousAchievementRatio = player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.TextLabel.Text
        hadNewIndicator = player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.NewImage.Visible

        library:Notify("Saved achievement settings:\n\nSaved Achievement Ratio: " .. previousAchievementRatio .. "\nHad New Indicator: " .. tostring(hadNewIndicator), 10, notifSounds.neutral)
	end,
	DoubleClick = false,
    Tooltip = false,
})

achievementSpoofGroup:AddInput("newAchievementRatioInput", {
    Default = false,
    Numeric = false,
    Finished = false,
    ClearTextOnFocus = true,

    Text = "Achievements Completed",
    Tooltip = "The text to show in the purple box under the achievements medal.",

    Placeholder = "E.g. 4/7",
    MaxLength = 5,

    Callback = function(value)
        achievementNumberInput = value
    end
})

achievementSpoofGroup:AddToggle("newAchievementToggle", {
	Text = "New Achievement",
	Tooltip = 'Toggles the "NEW" achievement indicator at the top right of the achievement medal.',
	Default = false,

	Callback = function(state)
        newAchievementIndicator = state
	end
})

local spoofAchievementsBtn = achievementSpoofGroup:AddButton({
	Text = "Spoof Achievements",
	Func = function()
        -- Only allowing numbers and slashes for the achievements ratio

        local function isValidAchievementString(value)
            return value:match("^(%d+)/(%d+)$") ~= nil
        end

        if isValidAchievementString(achievementNumberInput) then
            --print("Valid achievement string: " .. achievementNumberInput)

            -- if the given ratio is valid then proceed

            player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.TextLabel.Text = achievementNumberInput

            if newAchievementIndicator then
                player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.NewImage.Visible = true
            else
                player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.NewImage.Visible = false
            end

        else
            library:Notify("Invalid achievement string. Please enter in the format 'X/Y' or 'XX/YY'.", 8, notifSounds.error)
        end
	end,
	DoubleClick = false,
	Tooltip = "Applies the changes above to the achievements menu"
})

local undoAchievementSpoof = achievementSpoofGroup:AddButton({
	Text = "Restore Achievements",
	Func = function()
        -- Handling nil Values

        if previousAchievementRatio == nil or previousAchievementRatio == "" and hadNewIndicator == nil then
            library:Notify("No saved achievement ratio or new indicator state saved.", 6, notifSounds.error)
            return
        end

        -- Disabling the achievement spoofer

        options.newAchievementRatioInput:SetValue("")
        toggles.newAchievementToggle:SetValue(false)

        wait(0.3)

        player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.TextLabel.Text = previousAchievementRatio

        player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.NewImage.Visible = hadNewIndicator

        -- Clearing saved data

        previousAchievementRatio = ""
        hadNewIndicator = false

        library:Notify("Successfully restored achievements.", 3, notifSounds.success)
        library:Notify("Successfully cleared saved data.", 3.5, notifSounds.success)
	end,
	DoubleClick = false,
	Tooltip = "Reverts all the changes made to the achievements if any data was saved by the user."
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
            math.floor(FPS),
            math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        ))
    end)
end

library.KeybindFrame.Visible = false

library:OnUnload(function()


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

themeManager:SetFolder("Celestial ScriptHub")
saveManager:SetFolder("Celestial ScriptHub/Break In 2")
saveManager:SetSubFolder("Lobby")

saveManager:IgnoreThemeSettings()
saveManager:SetIgnoreIndexes({"MenuKeybind"})
saveManager:BuildConfigSection(tabs["UI Settings"])
themeManager:ApplyToTab(tabs["UI Settings"])

saveManager:LoadAutoloadConfig()

_G.script_key = nil