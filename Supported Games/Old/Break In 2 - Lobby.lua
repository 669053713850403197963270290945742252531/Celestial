repeat task.wait(0.1) until game:IsLoaded()


local repo = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/LinoriaLib/main/"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Authentication.lua"))()

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local player = game:GetService("Players").LocalPlayer
local humrootpart = player.Character:FindFirstChild("HumanoidRootPart")
local humanoid = player.Character.Humanoid
local getgamename = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local remoteevents = game:GetService("ReplicatedStorage").RemoteEvents

local Window = Library:CreateWindow({
    Title = "Celestial | " .. getgamename .. " - " .. auth.Username,
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Module Variables

local roledropdownvalue = ""
local teleportdropdownvalue = ""
local basicroledropdownvalue = ""
local specialroledropdownvalue = ""
local usecostume = false
local usekidheight = false

-- Functions

local function compareCFrames(cf1, cf2, tolerance)
    tolerance = tolerance or 0.001
    local pos1, pos2 = cf1.Position, cf2.Position
    local isPositionClose = (pos1 - pos2).Magnitude <= tolerance

    local function areRotationsClose(cf1, cf2, tolerance)
        local x1, y1, z1 = cf1:ToEulerAnglesXYZ()
        local x2, y2, z2 = cf2:ToEulerAnglesXYZ()
        return math.abs(x1 - x2) <= tolerance and math.abs(y1 - y2) <= tolerance and math.abs(z1 - z2) <= tolerance
    end

    local isRotationClose = areRotationsClose(cf1, cf2, tolerance)

    return isPositionClose and isRotationClose

    -- compareCFrames(humrootpart.CFrame, exitPoint)
end

local Tabs = {
    Information = Window:AddTab("Information"),
    Main = Window:AddTab("Main"),
    UI = Window:AddTab("UI"),
    ["UI Settings"] = Window:AddTab("Configs"),
}

if auth.notify_execution then
    Library:Notify("Successfully logged in as " .. auth.Rank .. ": " .. auth.Username, 6)
else
    Library:Notify("Celestial has loaded / " .. utils.getTime(false) .. ".", 6)
end

-- Game Info Tab

local GameDetailsGroup = Tabs.Information:AddLeftGroupbox("Game Details")
local UserDetailsGroup = Tabs.Information:AddRightGroupbox("User Details")
local WhitelistDetailsGroup = Tabs.Information:AddLeftGroupbox("Whitelist Details")

-- Game Info Group

GameDetailsGroup:AddDivider()

GameDetailsGroup:AddLabel("Game Supported: true")
GameDetailsGroup:AddLabel("Game Name: " .. getgamename, true)
GameDetailsGroup:AddLabel("Place ID: " .. game.PlaceId)

-- User Info Group

UserDetailsGroup:AddDivider()

UserDetailsGroup:AddLabel("Username: " .. player.Name)
UserDetailsGroup:AddLabel("Display Name: " .. player.DisplayName)
UserDetailsGroup:AddLabel("Account Age: " .. player.AccountAge .. " Days")
UserDetailsGroup:AddLabel("Executor: " .. identifyexecutor())

-- Whitelist Details Group

WhitelistDetailsGroup:AddDivider()

WhitelistDetailsGroup:AddLabel("Username: " .. auth.Username)
WhitelistDetailsGroup:AddLabel("Rank: " .. auth.Rank)

WhitelistDetailsGroup:AddLabel("Authorized: " .. tostring(auth.authorized))
WhitelistDetailsGroup:AddLabel("Notify Execution: " .. tostring(auth.notify_execution))
WhitelistDetailsGroup:AddLabel("Log Executions: " .. tostring(auth.log_executions))
WhitelistDetailsGroup:AddLabel("Log Breaches: " .. tostring(auth.log_breaches))

-- Main Tab

local AutomationGroup = Tabs.Main:AddLeftGroupbox("Automation")
local RolesGroup = Tabs.Main:AddRightGroupbox("Roles")

-- Combat Group

AutomationGroup:AddDivider()

AutomationGroup:AddDropdown("Teleports", {
    Values = {"Truck 1", "Truck 2"},
    Default = 0,
    Multi = false,

    Text = "Teleports",
    Tooltip = false,

    Callback = function(Value)
        teleportdropdownvalue = Value
    end
})

local TruckTeleport = AutomationGroup:AddButton({
    Text = "Teleport",
    Func = function()
        if humanoid.Sit then
            humanoid.Sit = false

            wait(0.4)
        else
            humanoid.Sit = false
        end

        if teleportdropdownvalue == "Truck 1" then
            utils.teleport(87.4349976, 7.86999941, 108.889984, 8.10623169e-05, 1, 8.10623169e-05, -8.10623169e-05, -8.10623169e-05, 1, 1, -8.10623169e-05, 8.10623169e-05)
        elseif teleportdropdownvalue == "Truck 2" then
            utils.teleport(87.4349976, 7.86999941, 147.389984, 8.10623169e-05, 1, 8.10623169e-05, -8.10623169e-05, -8.10623169e-05, 1, 1, -8.10623169e-05, 8.10623169e-05)
        end

        if teleportdropdownvalue ~= "" then
            Library:Notify("You have been teleported to: " .. teleportdropdownvalue .. ".", 3)
        else
            Library:Notify("Please select a truck from the truck dropdown above.", 5)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

-- Roles Group

RolesGroup:AddDivider()

RolesGroup:AddToggle("UseCostume", {
    Text = "Use Costume",
    Default = false,
    Tooltip = "Toggles the use of costumes for each role.",

    Callback = function(Value)
        usecostume = Value
    end
})

RolesGroup:AddToggle("UseKidHeight", {
    Text = "Use Kid Height",
    Default = true,
    Tooltip = false,

    Callback = function(Value)
        usekidheight = Value
    end
})

usekidheight = true

RolesGroup:AddDropdown("BasicRoleDropdown", {
    Values = {"The Hyper (Lollipop)", "The Sporty (Sports Drink)", "The Protecter (Bat)", "The Medic (MedKit)"},
    Default = 0,
    Multi = false,

    Text = "Basic Role",
    Tooltip = false,

    Callback = function(Value)
        basicroledropdownvalue = Value
    end
})

local UpdateRole = RolesGroup:AddButton({
    Text = "Update Role",
    Func = function()
        if basicroledropdownvalue == "The Hyper (Lollipop)" then
            remoteevents.MakeRole:FireServer("Lollipop", usekidheight, usecostume)
        elseif basicroledropdownvalue == "The Sporty (Sports Drink)" then
            remoteevents.MakeRole:FireServer("Bottle", usekidheight, usecostume)
        elseif basicroledropdownvalue == "The Protecter (Bat)" then
            remoteevents.MakeRole:FireServer("Bat", usekidheight, usecostume)
        elseif basicroledropdownvalue == "The Medic (Medkit)" then
            remoteevents.MakeRole:FireServer("MedKit", usekidheight, usecostume)
        end

        if basicroledropdownvalue ~= "" then
            Library:Notify("Your role has been updated to: " .. basicroledropdownvalue .. ".", 3)
        else
            Library:Notify("Please select a role from the basic roles dropdown above.", 5)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

RolesGroup:AddDivider()

RolesGroup:AddDropdown("SpecialRoleDropdown", {
    Values = {"The Nerd (Book)", "The Hacker (Admin Phone)"},
    Default = 0,
    Multi = false,

    Text = "Special Role",
    Tooltip = false,

    Callback = function(Value)
        specialroledropdownvalue = Value
    end
})

local UpdateRole = RolesGroup:AddButton({
    Text = "Update Role",
    Func = function()
        if specialroledropdownvalue == "The Nerd (Book)" then
            remoteevents.MakeRole:FireServer("Book", usekidheight, usecostume)
        elseif specialroledropdownvalue == "The Hacker (Admin Phone)" then
            remoteevents.MakeRole:FireServer("Phone", usekidheight, usecostume)
        end

        if specialroledropdownvalue ~= "" then
            Library:Notify("Your role has been updated to: " .. specialroledropdownvalue .. ".", 3)
        else
            Library:Notify("Please select a role from the special roles dropdown above.", 5)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

-- UI Tab

local UIGroups = Tabs.UI:AddLeftGroupbox("UI Elements")
local AchievementSpooferGroups = Tabs.UI:AddRightGroupbox("Achievement Spoofer")

-- UI Group

UIGroups:AddDivider()

UIGroups:AddToggle("HideBreakIn1", {
    Text = "Disable Break In 1 Recap",
    Default = false,
    Tooltip = "Hides Break In 1 recap button",

    Callback = function(Value)
        player.PlayerGui.RightMenu.RightMenu.RightMenu.RightMenu.BreakIn1.Visible = not player.PlayerGui.RightMenu.RightMenu.RightMenu.RightMenu.BreakIn1.Visible
    end
})

UIGroups:AddToggle("TheHuntUI", {
    Text = "The Hunt Menu",
    Default = false,
    Tooltip = "Enables The Hunt menu that was used in the 2024 Roblox Egg Hunt",

    Callback = function(Value)
        player.PlayerGui.BreakIn1ScreenHunt.BreakIn1ScreenHunt.BreakIn1ScreenHunt.Dialogue.Visible = not player.PlayerGui.BreakIn1ScreenHunt.BreakIn1ScreenHunt.BreakIn1ScreenHunt.Dialogue.Visible
    end
})

local leaveTruckButtonConnection -- Declare a variable to store the connection
_G.looptruckbutton = true -- Global variable to control the loop

UIGroups:AddToggle("TruckUI", {
    Text = "Leave Truck Button",
    Default = false,
    Tooltip = "Enables an unreleased button to leave a truck.",

    Callback = function(Value)
        local buttonEnabled = Value
        _G.looptruckbutton = Value

        player.PlayerGui.TruckUI.Enabled = Value
        player.PlayerGui.TruckUI.Leave.Visible = Value

        -- Disconnect the previous connection if it exists

        if leaveTruckButtonConnection then
            leaveTruckButtonConnection:Disconnect()
            leaveTruckButtonConnection = nil
        end

        -- Connect the event if the button is enabled

        if buttonEnabled then
            leaveTruckButtonConnection = player.PlayerGui.TruckUI.Leave.Button.MouseButton1Click:Connect(function()
                if buttonEnabled then
                    player.PlayerGui.TruckUI.Enabled = not player.PlayerGui.TruckUI.Enabled
                end
            end)
        end

        -- Recheck the conditions every time the player sits

        while _G.looptruckbutton do
            if humanoid.Sit and buttonEnabled then
                player.PlayerGui.TruckUI.Enabled = true
                player.PlayerGui.TruckUI.Leave.Visible = true
            else
                player.PlayerGui.TruckUI.Enabled = false
                player.PlayerGui.TruckUI.Leave.Visible = false
            end
            wait(0.1)
        end
    end
})


-- Achievement Spoofer Group

AchievementSpooferGroups:AddDivider()

local achievementnumberinput = ""
local newachievementindicator = false

local previous_achievementratio
local hadnewindicator

local SaveAchievementSettings = AchievementSpooferGroups:AddButton({
    Text = "Save Current Achievement Settings",
    Func = function()
        previous_achievementratio = player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.TextLabel.Text
        hadnewindicator = player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.NewImage.Visible

        Library:Notify("Saved achievement settings:\n\nSaved Achievement Ratio: " .. previous_achievementratio .. "\nHad New Indicator: " .. tostring(hadnewindicator), 10)
    end,
    DoubleClick = false,
    Tooltip = "Applies the changes above to the achievements menu."
})

AchievementSpooferGroups:AddInput("AchievementRatioInput", {
    Default = "",
    Numeric = false,
    Finished = false,

    Text = "Achievements Completed",
    Tooltip = "The text to show in the purple box under the achievements medal.",

    Placeholder = "E.g. 4/7",
    MaxLength = 5,

    Callback = function(Value)
        achievementnumberinput = Value
    end
})

AchievementSpooferGroups:AddToggle("NewAchievement", {
    Text = "New Achievement",
    Default = false,
    Tooltip = 'Toggles the "NEW" achievement indicator on top of the achievement medal.',

    Callback = function(Value)
        newachievementindicator = Value
    end
})

local SpoofAchievements = AchievementSpooferGroups:AddButton({
    Text = "Spoof Achievements",
    Func = function()
        -- Only allowing numbers and slashes for the achievements ratio

        local function isValidAchievementString(value)
            return value:match("^(%d+)/(%d+)$") ~= nil
        end

        if isValidAchievementString(achievementnumberinput) then
            print("Valid achievement string: " .. achievementnumberinput)

            -- if the given ratio is valid then proceed with function

            player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.TextLabel.Text = achievementnumberinput

            if newachievementindicator then
                player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.NewImage.Visible = true
            else
                player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.NewImage.Visible = false
            end

        else
            warn("Invalid achievement string. Please enter in the format 'X/Y' or 'XX/YY'.")
        end
    end,
    DoubleClick = false,
    Tooltip = "Applies the changes above to the achievements menu."
})

local UndoAchievementSpoof = AchievementSpooferGroups:AddButton({
    Text = "Restore",
    Func = function()
        -- Resolving Nil Values

        if previous_achievementratio == nil and hadnewindicator == nil then
            Library:Notify("No saved achievement ratio or new indicator state saved.", 6)
            return
        end

        -- Disabling the achievement spoofers

        Options.AchievementRatioInput:SetValue("")
        Toggles.NewAchievement:SetValue(false)

        wait(0.3)

        player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.TextLabel.Text = previous_achievementratio

        player.PlayerGui.LeftMenu.LeftMenu.LeftMenu.LeftMenu.AchievementsButton.NewImage.Visible = hadnewindicator

        -- Clearing saved data

        previous_achievementratio = ""
        hadnewindicator = false

        Library:Notify("Successfully restored achievements.", 3)
        Library:Notify("Reset saved data.", 3.5)
    end,
    DoubleClick = false,
    Tooltip = "Applies the changes above to the achievements menu."
})

-----------------------------------------------------------------------------------------------------------------------------------

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    Library:SetWatermark(("Celestial | %s fps | %s ms"):format(
        math.floor(FPS),
        math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    ));
end);

Library.KeybindFrame.Visible = false;

Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    -- Restoring the default settings

    _G.looptruckbutton = false

    -- TruckUI

    if leaveTruckButtonConnection then
        leaveTruckButtonConnection:Disconnect()
        leaveTruckButtonConnection = nil
    end

    player.PlayerGui.TruckUI.Enabled = false
    player.PlayerGui.TruckUI.Leave.Visible = false

    -- TheHuntUI

    player.PlayerGui.BreakIn1ScreenHunt.BreakIn1ScreenHunt.BreakIn1ScreenHunt.Dialogue.Visible = false

    -- HideBreakIn1

    player.PlayerGui.RightMenu.RightMenu.RightMenu.RightMenu.BreakIn1.Visible = false

    -- Changing the unloaded variable value

    Library.Unloaded = true
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddButton("Unload", function() Library:Unload() end)
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

--[[
 -- Menu Group Addons

 MenuGroup:AddToggle("KeybindsVisible", {
    Text = "Show Keybind UI",
    Default = true,
    Tooltip = "Toggles the visibility of the keybinds",

    Callback = function(Value)
        if Value then
            Library.KeybindFrame.Visible = true
        else
            Library.KeybindFrame.Visible = false
        end
    end
})
]]

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Celestial")
SaveManager:SetFolder("Celestial/Break In 2 - Lobby")

SaveManager:BuildConfigSection(Tabs["UI Settings"])

ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()