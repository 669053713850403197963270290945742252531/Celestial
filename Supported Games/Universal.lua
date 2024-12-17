while not game:IsLoaded() do
    task.wait()
end

local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Authentication.lua"))()

--local repoOwner = "669053713850403197963270290945742252531"
local repoOwner = "mstudio45"
local exploit = identifyexecutor()

if exploit == "Synapse Z" then -- fuck syn z drawing lib
    repoOwner = "669053713850403197963270290945742252531"
else
    repoOwner = "mstudio45"
end

local repo = "https://raw.githubusercontent.com/" .. repoOwner .. "/LinoriaLib/main/"    
local library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local themeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local saveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local options = library.Options
local toggles = library.Toggles

local player = game:GetService("Players").LocalPlayer
local hrp = player.Character:FindFirstChild("HumanoidRootPart")
local humanoid = player.Character.Humanoid
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

while not hrp do
    warn("Player's HumanoidRootPart was not found at runtime. Halting further code execution until found.")
    task.wait()
end

local window = library:CreateWindow({
    Title = "Celestial - " .. gameName .. ": " .. auth.Username,
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Module Variables

local clipPosition = "Y (-)"
local clipAmount = 0

-- Functions



local tabs = {
    info = window:AddTab("Info"),
    main = window:AddTab("Main"),
    player = window:AddTab("Player"),
    ["UI Settings"] = window:AddTab("Configs"),
}

if auth.notify_execution then
    library:Notify("Successfully logged in as " .. auth.Rank .. ": " .. auth.Username, 6)
else
    library:Notify("Celestial has loaded / " .. utils.getTime(false) .. ".", 6)
end

-- Game Info Tab

local GameDetailsGroup = tabs.info:AddLeftGroupbox("Game Details")
local UserDetailsGroup = tabs.info:AddRightGroupbox("User Details")
local WhitelistDetailsGroup = tabs.info:AddLeftGroupbox("Whitelist Details")

-- Game Info Group

GameDetailsGroup:AddDivider()

GameDetailsGroup:AddLabel("Game Supported: true")
GameDetailsGroup:AddLabel("Game Name: " .. gameName, true)
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

local mainGroup = tabs.main:AddLeftGroupbox("Main")

-- Main Group

mainGroup:AddDivider()

mainGroup:AddLabel("Position Clipping\n", true)

mainGroup:AddDropdown('MyDisabledValueDropdown', {
    Values = {"X (+)", "X (-)", "Y (+)", "Y (-)", "Z (+)", "Z (-)"},
    DisabledValues = nil,
    Default = 0,
    --Default = "Y (-)",
    Multi = false,

    Text = 'Clip Position',
    Tooltip = 'The direction of which you will clip.',
    DisabledTooltip = nil,

    Callback = function(value)
        clipPosition = value
        print("clipPosition: ", clipPosition)
    end,

    Disabled = false,
    Visible = true,
})

mainGroup:AddInput("clipPositionAmount", {
    Default = false,
    Numeric = true,
    Finished = false,

    Text = "Amount",
    Tooltip = false,

    Placeholder = "Number (###)",
    MaxLength = 3,

    Callback = function(value)
        clipAmount = value
        print("clipAmount: ", clipAmount)
    end
})

local clip = mainGroup:AddButton({
    Text = "Clip",
    Func = function()
        local clipAmount = tonumber(clipAmount)
        local position = hrp.Position
        local hrpX = position.X
        local hrpY = position.Y
        local hrpZ = position.Z

        if clipPosition == "X (+)" then
            print(typeof(clipAmount))
            hrp.Position = Vector3.new(hrpX, hrpY, hrpZ + clipAmount)
        elseif clipPosition == "X (-)" then

        elseif clipPosition == "Y (+)" then

        elseif clipPosition == "Y (-)" then

        elseif clipPosition == "Z (+)" then

        elseif clipPosition == "Z (-)" then

        end
    end,
    DoubleClick = false,
    Tooltip = false
})

-- Player Tab

local localplayerGroup = tabs.player:AddLeftGroupbox("LocalPlayer")

-- LocalPlayer Group

localplayerGroup:AddDivider()

-----------------------------------------------------------------------------------------------------------------------------------

local watermarkEnabled = false

library:SetWatermarkVisibility(watermarkEnabled)

if watermarkEnabled then

    local FrameTimer = tick()
    local FrameCounter = 0
    local FPS = 60
    
    local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
        FrameCounter += 1
    
        if (tick() - FrameTimer) >= 1 then
            FPS = FrameCounter
            FrameTimer = tick()
            FrameCounter = 0
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

    if watermarkEnabled and WatermarkConnection then
        WatermarkConnection:Disconnect()
    end

    library.Unloaded = true
end)

local MenuGroup = tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function()
    library:Unload()
end)

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind",{ Default = "End", NoUI = true, Text = "Menu keybind" })

library.ToggleKeybind = options.MenuKeybind

themeManager:SetLibrary(library)
saveManager:SetLibrary(library)

MenuGroup:AddToggle("keybindMenuToggle", {
    Text = "Open Keybind Menu",
    Default = library.KeybindFrame.Visible,
    Callback = function(state)
        Library.KeybindFrame.Visible = state
    end
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(state)
        library.ShowCustomCursor = state
    end
})

--[[

MenuGroup:AddToggle("KeybindsVisible", {
    Text = "Show Keybind UI",
    Default = true,
    Tooltip = "Toggles the visibility of the keybinds",

    Callback = function(state)
        if state then
            library.KeybindFrame.Visible = true
        else
            library.KeybindFrame.Visible = false
        end
    end
})

]]

themeManager:SetFolder("Celestial")
saveManager:SetFolder("Celestial/Universal")
--saveManager:SetFolder("Celestial/Break In 2")
--saveManager:SetSubFolder("Lobby")

saveManager:IgnoreThemeSettings()
saveManager:SetIgnoreIndexes({"MenuKeybind"})
saveManager:BuildConfigSection(tabs["UI Settings"])
themeManager:ApplyToTab(tabs["UI Settings"])

saveManager:LoadAutoloadConfig()