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
local coreGui = game:GetService("CoreGui")
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local exploit = identifyexecutor()
local hrp = utils.getCharInstance("HumanoidRootPart")
local teleportService = game:GetService("TeleportService")
local remoteEvents = game:GetService("ReplicatedStorage").Network

-- Function checks

local notifSounds = {
    neutral = 17208372272,
    success = 5797580410,
    error = 5797578819
}

if not typeof(keypress) == "function" then
    library:Notify(exploit .. " does not support keypress.", 15, notifSounds.error)
end



-- https://duckys-playground.gitbook.io/wave/functions/input#keyboard

-- Functions

local function getRandomOffset() -- Generate a random offset within 5 studs around the local player
    local randomX = math.random(-5, 5)
    local randomZ = math.random(-5, 5)
    return Vector3.new(randomX, 0, randomZ)
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

local damageAmountValue = 1
local itemDropdownValue = "Gas Can"

local tabs = {
    info = window:AddTab("Info"),
    exploits = window:AddTab("Exploits"),
    player = window:AddTab("Player"),
    misc = window:AddTab("Misc"),
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

-- Tab: Exploits

local automationGroup = tabs.exploits:AddLeftGroupbox("Automation")
local objectsGroup = tabs.exploits:AddRightGroupbox("Objects")

-- Group: Automation

automationGroup:AddDivider()

local fillGas = false

automationGroup:AddToggle("autoGasFill", {
    Text = "Auto Fill Gas",
    Tooltip = false,
    Default = false,

    Callback = function(enabled)
        fillGas = enabled
        if enabled then
            task.spawn(function()
                while fillGas do
                    local foundGasCan = false
                    
                    -- Loop through each GasCan in the workspace
                    for _, gasCanModel in ipairs(workspace:GetChildren()) do
                        if gasCanModel.Name == "GasCan" then
                            local mainPart = gasCanModel:FindFirstChild("main")
                            if mainPart then
                                local tankValue = mainPart:FindFirstChild("tank")
                                if tankValue and tankValue:IsA("DoubleConstrainedValue") and tankValue.Value > 0 then
                                    foundGasCan = true
                                    
                                    -- Fill from this gas can
                                    local args = {
                                        [1] = workspace:WaitForChild("Van"):WaitForChild("Misc"):WaitForChild("tank"):WaitForChild("main"):WaitForChild("tank"),
                                        [2] = mainPart
                                    }

                                    print("Filling from gas can:", gasCanModel.Name, "Value:", tankValue.Value)
                                    game:GetService("ReplicatedStorage"):WaitForChild("fill"):FireServer(unpack(args))
                                    
                                    -- Wait to ensure the operation is completed before moving to the next can
                                    task.wait(1)
                                    break -- Stop looping once a valid gas can is found and used
                                end
                            end
                        end
                    end
                    
                    if not foundGasCan then
                        print("No valid gas cans found to fill from.")
                    end

                    -- Small delay before checking again
                    task.wait(0.3)
                end
            end)
        end
    end
})


-- Group: Objects

objectsGroup:AddDivider()

objectsGroup:AddDropdown("itemDropdown", {
    Values = {"Gas Can", "Diesel Can", "Oil Can", "Water Can"},
    Default = 1,
    Multi = false,

    Text = "Item",
    Tooltip = false,

    Callback = function(value)
        itemDropdownValue = value
    end
})

local bringItem = objectsGroup:AddButton({
    Text = "Bring Item",
    Func = function()
        local hrp = utils.getCharInstance("HumanoidRootPart")
        if not hrp then
            warn("HumanoidRootPart not found!")
            return
        end

        if itemDropdownValue == "Gas Can" then
            for _, object in pairs(game.Workspace:GetChildren()) do
                if object.Name == "GasCan" and object:IsA("Model") then
                    for _, GasCan in pairs(object:GetChildren()) do
                        if GasCan:IsA("MeshPart") or GasCan:IsA("Part") then
                            -- Calculate new position with a random offset
                            local newCFrame = hrp.CFrame + getRandomOffset()
                            GasCan.CFrame = newCFrame
                        end
                    end
                end
            end

        elseif itemDropdownValue == "Diesel Can" then
            -- Add Diesel Can logic here

        elseif itemDropdownValue == "Oil Can" then
            -- Add Oil Can logic here

        elseif itemDropdownValue == "Water Can" then
            -- Add Water Can logic here
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

-- Tab: Player

local movementGroup = tabs.player:AddLeftGroupbox("Movement")
local damageGroup = tabs.player:AddRightGroupbox("Damage")

-- Group: Movement

movementGroup:AddDivider()

--

-- Group: Damage

damageGroup:AddDivider()

damageGroup:AddSlider("damageAmountSlider", {
	Text = "Damage Times",
	Default = 1,
	Min = 1,
	Max = 20,
    Suffix = "x",
	Rounding = 0,
	Compact = false,

	Callback = function(value)
		damageAmountValue = value
	end,

    Tooltip = "The amount of times you will be damaged."
})

local damage = damageGroup:AddButton({
    Text = "Damage",
    Func = function()
        local damageEvent = remoteEvents:FindFirstChild("ECLIPSE_DAMAGE")

        if not damageEvent then
            warn("Damage event not found.")
            return
        end

        for i = 1, damageAmountValue do
            damageEvent:FireServer()
        end
    end,
    DoubleClick = true,
    Tooltip = false
})

-- Tab: Misc

local miscGroup = tabs.misc:AddLeftGroupbox("Miscellaneous")

-- Group: Miscellaneous

miscGroup:AddDivider()

local noclipEnabled = false
local originalCanCollideStates = {}
local connection

miscGroup:AddToggle("Noclip", {
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

local lobby = miscGroup:AddButton({
    Text = "Lobby",
    Func = function()
        --teleportService:Teleport(16389395869)
        remoteEvents.RETURN_TO_LOBBY:FireServer()
    end,
    DoubleClick = true,
    Tooltip = false
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
    local unlockCursorGui = coreGui:FindFirstChild("Unlock Cursor")
    if unlockCursorGui then
        unlockCursorGui:Destroy()
    end

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

menuGroup:AddToggle("unlockCursor", {
    Text = "Unlock Cursor",
    Default = true,
    Callback = function(state)
        local unlockCursorGui = coreGui:FindFirstChild("Unlock Cursor")

        if unlockCursorGui then
            unlockCursorGui.Enabled = state
        else
            local screenGui = Instance.new("ScreenGui", coreGui)
            local button = Instance.new("TextButton", screenGui)

            screenGui.Name = "Unlock Cursor"
            screenGui.Enabled = state
            button.Modal = true
        end
    end
})

-- why default no work

local unlockCursorGui = coreGui:FindFirstChild("Unlock Cursor")

if unlockCursorGui then
    unlockCursorGui.Enabled = state
else
    local screenGui = Instance.new("ScreenGui", coreGui)
    local button = Instance.new("TextButton", screenGui)

    screenGui.Name = "Unlock Cursor"
    screenGui.Enabled = true
    button.Modal = true
end

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