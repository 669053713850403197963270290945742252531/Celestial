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
local hrp = utils.getHRP()

while not hrp do
    warn("Player's HumanoidRootPart was not found at runtime. Halting further code execution until found.")
    task.wait()
end

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

local clipPosition = "Y (-)"
local clipAmount = 0

-- Functions

local function func()

end

local tabs = {
    info = window:AddTab("Info"),
    main = window:AddTab("Main"),
    player = window:AddTab("Player"),
    ["UI Settings"] = window:AddTab("Configs"),
}

if auth.fetchConfig("notifyExecution") then
    library:Notify("Successfully logged in as " .. auth.currentUser.Rank .. ": " .. auth.currentUser.Identifer, 6)
else
    library:Notify("Celestial has loaded / " .. utils.getTime(false) .. ".", 6)
end

-- Game Info Tab

local GameDetailsGroup = tabs.info:AddLeftGroupbox("Game Details")
local UserDetailsGroup = tabs.info:AddRightGroupbox("User Details")
local WhitelistDetailsGroup = tabs.info:AddLeftGroupbox("Whitelist Details")

-- Game Info Group

GameDetailsGroup:AddDivider()

GameDetailsGroup:AddLabel("Game Supported: false", true)
GameDetailsGroup:AddLabel("Game Name: " .. gameName, true)
GameDetailsGroup:AddLabel("Place ID: " .. game.PlaceId, true)

-- User Info Group

UserDetailsGroup:AddDivider()

UserDetailsGroup:AddLabel("Username: " .. player.Name, true)
UserDetailsGroup:AddLabel("Display Name: " .. player.DisplayName, true)
UserDetailsGroup:AddLabel("Account Age: " .. player.AccountAge .. " Days", true)
UserDetailsGroup:AddLabel("Executor: " .. exploit, true)

-- Whitelist Details Group

WhitelistDetailsGroup:AddDivider()

WhitelistDetailsGroup:AddLabel("HWID: " .. auth.currentUser.HWID, true)
WhitelistDetailsGroup:AddLabel("Identifer: " .. auth.currentUser.Identifer, true)
WhitelistDetailsGroup:AddLabel("Rank: " .. auth.currentUser.Rank, true)
WhitelistDetailsGroup:AddLabel("JoinDate: " .. auth.currentUser.JoinDate, true)

-- Main Tab

local mainGroup = tabs.main:AddLeftGroupbox("Main")

-- Main Group

mainGroup:AddDivider()

mainGroup:AddLabel("Position Clipping\n", true)

mainGroup:AddDropdown("clipPositionDropdown", {
    Values = {"X (+)", "X (-)", "Y (+)", "Y (-)", "Z (+)", "Z (-)"},
    DisabledValues = nil,
    Default = "Y (-)",
    Multi = false,

    Text = "Clip Position",
    Tooltip = "The direction of which you will clip.",
    DisabledTooltip = nil,

    Callback = function(value)
        clipPosition = value
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
        clipAmount = tonumber(value)
    end
})

local clip = mainGroup:AddButton({
    Text = "Clip",
    Func = function()
        local hrp = utils.getHRP()

        if not hrp then
            warn("HRP not found.")
            return
        end

        local clipAmount = tonumber(clipAmount) or 0
        local cframe = hrp.CFrame

        if clipPosition == "X (+)" then
            hrp.CFrame = cframe + Vector3.new(clipAmount, 0, 0)
        elseif clipPosition == "X (-)" then
            hrp.CFrame = cframe + Vector3.new(-clipAmount, 0, 0)
        elseif clipPosition == "Y (+)" then
            hrp.CFrame = cframe + Vector3.new(0, clipAmount, 0)
        elseif clipPosition == "Y (-)" then
            hrp.CFrame = cframe + Vector3.new(0, -clipAmount, 0)
        elseif clipPosition == "Z (+)" then
            hrp.CFrame = cframe + Vector3.new(0, 0, clipAmount)
        elseif clipPosition == "Z (-)" then
            hrp.CFrame = cframe + Vector3.new(0, 0, -clipAmount)
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