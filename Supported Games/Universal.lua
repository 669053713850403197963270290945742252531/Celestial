repeat task.wait(0.1) until game:IsLoaded()


local repo = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/LinoriaLib/main/"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Authentication.lua"))()
        
local library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local player = game:GetService("Players").LocalPlayer
local humrootpart = player.Character:FindFirstChild("HumanoidRootPart")
local humanoid = player.Character.Humanoid
local getgamename = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local remoteevents = game:GetService("ReplicatedStorage").RemoteEvents

local Window = library:CreateWindow({
    Title = "Celestial - " .. getgamename .. " : " .. auth.Username,
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Module Variables

local variable

-- Functions



local Tabs = {
    Info = Window:AddTab("Info"),
    Main = Window:AddTab("Main"),
    Player = Window:AddTab("Player"),
    ["UI Settings"] = Window:AddTab("Configs"),
}

if auth.notify_execution then
    library:Notify("Successfully logged in as " .. auth.Rank .. ": " .. auth.Username, 6)
else
    library:Notify("Celestial has loaded / " .. utils.getTime(false) .. ".", 6)
end

-- Game Info Tab

local GameDetailsGroup = Tabs.Info:AddLeftGroupbox("Game Details")
local UserDetailsGroup = Tabs.Info:AddRightGroupbox("User Details")
local WhitelistDetailsGroup = Tabs.Info:AddLeftGroupbox("Whitelist Details")

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

local mainGroup = Tabs.Main:AddLeftGroupbox("Main")

-- Main Group

mainGroup:AddDivider()

mainGroup:AddDropdown("Dropdown", {
    Values = {"Option 1", "Option 2"},
    Default = 0,
    Multi = false,

    Text = "Dropdown",
    Tooltip = false,

    Callback = function(Value)
        variable = Value
    end
})

local Button = mainGroup:AddButton({
    Text = "Button",
    Func = function()

    end,
    DoubleClick = false,
    Tooltip = false
})

-- Player Tab

local localplayerGroup = Tabs.Player:AddLeftGroupbox("LocalPlayer")

-- LocalPlayer Group

localplayerGroup:AddDivider()

-----------------------------------------------------------------------------------------------------------------------------------

library:SetWatermarkVisibility(false)

--[[

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

    library:SetWatermark(("Celestial | %s fps | %s ms"):format(
        math.floor(FPS),
        math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    ));
end);

]]

library.KeybindFrame.Visible = false;

library:OnUnload(function()


    -- Unloading

    WatermarkConnection:Disconnect()
    library.Unloaded = true
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function()
    library:Unload()
end)

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind",{ Default = "End", NoUI = true, Text = "Menu keybind" })

library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(library)
SaveManager:SetLibrary(library)

--[[

MenuGroup:AddToggle("KeybindsVisible", {
    Text = "Show Keybind UI",
    Default = true,
    Tooltip = "Toggles the visibility of the keybinds",

    Callback = function(Value)
        if Value then
            library.KeybindFrame.Visible = true
        else
            library.KeybindFrame.Visible = false
        end
    end
})

]]

ThemeManager:SetFolder("Celestial")
SaveManager:SetFolder("Celestial/Break In 2 - Lobby")

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()