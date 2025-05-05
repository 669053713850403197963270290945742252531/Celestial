repeat task.wait(0.1) until game:IsLoaded()

local repo = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/LinoriaLib/main/"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Authentication.lua"))()

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local player = game:GetService("Players").LocalPlayer
local character = player.Character
local humanoid = character:FindFirstChild("Humanoid")
local humrootpart = character:FindFirstChild("HumanoidRootPart")
local getgamename = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local events = game:GetService("ReplicatedStorage").Events
local camera = game:GetService("Workspace").CurrentCamera

local Window = Library:CreateWindow({
    Title = "Celestial | " .. getgamename .. " - " .. auth.Username,
    Center = true,
    AutoShow = true,
    TabPadding = 7.9,
    MenuFadeTime = 0.2
})

-- Module Variables

local walkspeedenabled = false
local jumppowerenabled = false
local gravityenabled = false
local hipheightenabled = false

local walkspeedslidervalue = 16
local jumppowerslidervalue = 50
local gravityslidervalue = 196.2
local hipheightslidervalue = 2.3 -- default: 2.2977042198181152

local autogiveitemdelay = 1
local giveitemdropdownvalue = ""
local giveamountvalue = 1
local damageamountvalue = 0
local teleportdropdownvalue = ""
local giveweapondropdownvalue = ""
local antislipenabled = false

-- Loop Values

_G.updatewalkspeed = true

_G.godmodeloop = true
_G.loophideenergy = true
_G.disablefrontdoor = true
_G.autoeat = true
_G.noclip = true
_G.speedexploit = true
_G.removeinventorysound = true
_G.autohealall = true
_G.disablewindknockback = true
_G.bypasscutscenes = true
_G.larryesp = true
_G.updateoutsideitems = true
_G.updatehiddenitems = true
_G.collectcash = true
_G.disablevignette = true
_G.insidespoof = true
_G.outsidespoof = true
_G.spooffighting = true

-- Loop Functions

function updatewalkspeed()
    while _G.updatewalkspeed do
        utils.modifyPlayer("WalkSpeed", walkspeedslidervalue)

        wait()
    end
end

function updatejumppower()
    while _G.updatejumppower do
        utils.modifyPlayer("JumpPower", jumppowerslidervalue)

        wait()
    end
end




function godmodeloop()
    while _G.godmodeloop do
        events.GiveTool:FireServer("Pizza")
        events.Energy:FireServer(25, "Pizza")

        wait()
    end
end

function loophideenergy()
    while _G.loophideenergy do
        for _, v in pairs(player.PlayerGui.EnergyBar.EnergyBar.EnergyBar:GetDescendants()) do
            if v.Name == "Template" and v:IsA("TextLabel") then
                v.Visible = false
            end
        end

        wait()
    end
end

function disablefrontdoor()
    while _G.disablefrontdoor do
        for _, v in pairs(game.Workspace.tst:GetDescendants()) do
            if v.Name == "Door" and v:IsA("Part") then
                v.CanCollide = false
                v.Transparency = 0.4
            end
        end

        -- Method for the second door that occurs during the waves

        for _, v in pairs(game.Workspace.Doors1:GetDescendants()) do
            if v.Name == "Door" and v:IsA("Part") then
                v.CanCollide = false
                v.Transparency = 0.4
            end
        end

        wait(1)
    end
end

function autoeat()
    while _G.autoeat do
        -- Removing the eat sound

        for _, v in pairs(game.Workspace.Sounds:GetDescendants()) do
            if v.Name == "Temp" and v:IsA("Sound") then
                v.Playing = false
            end
        end

        events.Energy:FireServer(5, "Chips")

        events.Energy:FireServer(15, "Cookie")

        events.Energy:FireServer(15, "BloxyCola")

        events.Energy:FireServer(15, "Apple")

        events.Energy:FireServer(25, "Pizza")

        events.Energy:FireServer(15, "ExpiredBloxyCola")



        -- Golden Apple & Golden Pizza


        events.HealTheNoobs:FireServer() -- gold apple

        events.CurePlayer:FireServer(player, player) -- gold pizza

        events.RainbowPizza:FireServer(player) -- rainbow pizza
        

        wait()
    end
end

function noclip()
    while _G.noclip do
        for _, v in pairs(character:GetDescendants()) do
            pcall(function()
                if v:IsA("BasePart") or v:IsA("UnionOperation") then
                    v.CanCollide = false
                end
            end)
        end

        wait(1)
    end
end

function speedexploit()
    while _G.speedexploit do
        utils.modifyPlayer("WalkSpeed", 25)

        wait(3)
    end
end

function removeinventorysound()
    while _G.removeinventorysound do
        for _, v in pairs(game.Workspace.Sounds:GetDescendants()) do
            if v.Name == "Inventory" and v:IsA("Sound") then
                v.Playing = false
            end
        end

        wait()
    end
end

function autohealall()
    while _G.autohealall do
        events.GiveTool:FireServer("GoldenApple") -- give golden apple

        wait(0.1)

        events.BackpackEvent:FireServer("Equip", player.Backpack.GoldenApple) -- equip golden apple

        wait(0.1)

        events.HealTheNoobs:FireServer() -- fire heal event

        wait(6)
    end
end

function disablewindknockback()
    while _G.disablewindknockback do
        for _, v in pairs(game.Workspace:GetChildren()) do
            if v.Name == "WavePart" then
                v.CanTouch = false
            end
        end

        wait()
    end
end

function bypasscutscenes()
    while _G.bypasscutscenes do
        local camera = game.Workspace.CurrentCamera

        camera:GetPropertyChangedSignal("CameraType"):Connect(function()
            --print("camera type changed..")

            if camera.CameraType ~= Enum.CameraType.Custom then
                camera.CameraType = Enum.CameraType.Custom

                if camera.CameraType == Enum.CameraType.Custom then
                    --print("successfully changed camera type to Custom")
                else
                    warn("failed to change camera type to Custom")
                end
            end
        end)


        wait(0.2)
    end
end

function loopkillall()
    while _G.loopkillall do
        -- Normal Bad Guys

        for _, v in pairs(game:GetService("Workspace").BadGuys:GetChildren()) do
            events:WaitForChild("HitBadguy"):FireServer(v, 64.8, 4)
        end

        -- Bad Guy Boss

        for _, v in pairs(game:GetService("Workspace").BadGuysBoss:GetChildren()) do
            events:WaitForChild("HitBadguy"):FireServer(v, 64.8, 4)
        end

        -- Bad Guys Front Base

        for _, v in pairs(game:GetService("Workspace").BadGuysFront:GetChildren()) do
            events:WaitForChild("HitBadguy"):FireServer(v, 64.8, 4)
        end

        -- Bad Guy Pizza

        if game:GetService("Workspace"):FindFirstChild("BadGuyPizza", true) then
            events:WaitForChild("HitBadguy"):FireServer(game:GetService("Workspace"):FindFirstChild("BadGuyPizza", true), 64.8, 4)
        end

        -- Bad Guy Brute

        if game:GetService("Workspace"):FindFirstChild("BadGuyBrute") then
            events:WaitForChild("HitBadguy"):FireServer(game:GetService("Workspace").BadGuyBrute, 64.8, 4)
        end

        wait(0.05)
    end
end

function collectcash()
    while _G.collectcash do
		for _, v in pairs(game:GetService("Workspace"):GetChildren()) do
			if v.Name == "Part" and v:FindFirstChild("TouchInterest") and v:FindFirstChild("Weld") and v.Transparency == 1 then
				v.CFrame = humrootpart.CFrame
			end
		end

        wait(0.1)
    end
end

function disablevignette()
    while _G.disablevignette do
        player.PlayerGui.Assets.Vig.Visible = false

        wait()
    end
end

function insidespoof()
    while _G.insidespoof do
        utils.fireTouchEvent(humrootpart, game.Workspace.InsideTouchParts.FrontDoor)

        wait(0.2)
    end
end

function outsidespoof()
    while _G.outsidespoof do
        utils.fireTouchEvent(humrootpart, game.Workspace.OutsideTouchParts.OutsideTouch)

        wait(0.2)
    end
end

function spooffighting()
    while _G.spooffighting do
        utils.fireTouchEvent(humrootpart, game.Workspace.EvilArea.EnterPart)

        wait(1)
    end
end

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
    Information = Window:AddTab("Info"),
    Exploits = Window:AddTab("Exploits"),
    Utility = Window:AddTab("Utility"),
    LocalPlayer = Window:AddTab("LocalPlayer"),
    Endings = Window:AddTab("Endings"),
    Misc = Window:AddTab("Misc"),
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

-- Exploits Tab

local ExploitsGroup = Tabs.Exploits:AddLeftGroupbox("Exploits")
local VisualsGroup = Tabs.Exploits:AddRightGroupbox("Visuals")
local TeleportationGroup = Tabs.Exploits:AddLeftGroupbox("Teleportation")
local TouchInterestsGroup = Tabs.Exploits:AddLeftGroupbox("Touch Transmitter Manipulation")
local OtherGroup = Tabs.Exploits:AddRightGroupbox("Other")

-- Exploits Group

ExploitsGroup:AddDivider()

ExploitsGroup:AddToggle("GodmodeToggle", {
    Text = "Godmode",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        _G.godmodeloop = Value
        godmodeloop()
    end
})

ExploitsGroup:AddToggle("HideEnergyUI", {
    Text = "Hide Energy Gain",
    Default = false,
    Tooltip = "Disables the green +x energy text above\nthe health bar",

    Callback = function(Value)
        _G.loophideenergy = Value
        loophideenergy()
    end
})

ExploitsGroup:AddDivider()

ExploitsGroup:AddToggle("BypassCutscenes", {
    Text = "Bypass Cutscenes",
    Default = false,
    Tooltip = "Disable camera changing.",

    Callback = function(Value)
        _G.bypasscutscenes = Value
        bypasscutscenes()
    end
})

ExploitsGroup:AddToggle("WalkSpeedExploit", {
    Text = "Speed Boost",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            _G.speedexploit = true
            speedexploit()

        else

            _G.speedexploit = false

            utils.modifyPlayer("WalkSpeed", 16)
        end
    end
})

ExploitsGroup:AddToggle("CollectCash", {
    Text = "Collect Cash",
    Default = false,
    Tooltip = "Tends to act as if you collect one due\nto a lot of cash parts being added all\nat once.",

    Callback = function(Value)
        _G.collectcash = Value
        collectcash()
    end
})

-- Visuals Group

VisualsGroup:AddDivider()

VisualsGroup:AddToggle("HighlightHiddenItems", {
    Text = "Hidden Item ESP",
    Default = false,
    Tooltip = "Highlights the items in drawers.",

    Callback = function(Value)
        if Value then
            for _, v in pairs(game.Workspace.Hidden:GetChildren()) do
                local hiddenitemhighlight = Instance.new("Highlight", v)

                hiddenitemhighlight.Name = "_CelestialItemHighlight"
                hiddenitemhighlight.FillColor = Color3.new(0, 255, 255)
                hiddenitemhighlight.FillTransparency = 0.5
                hiddenitemhighlight.OutlineColor = Color3.new(0, 255, 255)
                hiddenitemhighlight.OutlineTransparency = 0
            end

        else

            for _, v in pairs(game.Workspace:GetDescendants()) do
                if v.Name == "_CelestialItemHighlight" then
                    v:Destroy()
                end
            end
        end
    end
})

VisualsGroup:AddToggle("DresserESP", {
    Text = "Dresser ESP",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            for _, v in pairs(game.Workspace.Dressers:GetChildren()) do
                local dresseresphighlight = Instance.new("Highlight", v)
    
                dresseresphighlight.Name = "_CelestialDresserHighlight"
                dresseresphighlight.FillColor = Color3.new(0, 0, 0)
                dresseresphighlight.FillTransparency = 0.5
                dresseresphighlight.OutlineColor = Color3.new(0, 0, 0)
                dresseresphighlight.OutlineTransparency = 0
            end

        else

            for _, v in pairs(game.Workspace:GetDescendants()) do
                if v.Name == "_CelestialDresserHighlight" then
                    v:Destroy()
                end
            end
        end
    end
})

VisualsGroup:AddToggle("DisableFrontDoor", {
    Text = "Disable Front Door",
    Default = false,
    Tooltip = "Makes the front door transparent and allows clipping.",

    Callback = function(Value)
        if Value then
            _G.disablefrontdoor = true
            disablefrontdoor()
        else
            _G.disablefrontdoor = false
            disablefrontdoor()

            wait(1)

            for _, v in pairs(game.Workspace.tst:GetDescendants()) do
                if v.Name == "Door" and v:IsA("Part") then
                    v.CanCollide = false
                    v.Transparency = 0
                end
            end
        end
    end
})

VisualsGroup:AddToggle("DisableVignette", {
    Text = "Disable Vignette",
    Default = false,
    Tooltip = "Disables the black border when outside.",

    Callback = function(Value)
        _G.disablevignette = Value
        disablevignette()
    end
})

-- Others Group

OtherGroup:AddDivider()

local KillEnemies = OtherGroup:AddButton({
    Text = "Kill Bad Guys",
    Func = function()
        -- Normal Bad Guys

        for _, v in pairs(game:GetService("Workspace").BadGuys:GetChildren()) do
            events:WaitForChild("HitBadguy"):FireServer(v, 64.8, 4)
        end

        -- Bad Guy Boss

        for _, v in pairs(game:GetService("Workspace").BadGuysBoss:GetChildren()) do
            events:WaitForChild("HitBadguy"):FireServer(v, 64.8, 4)
        end

        -- Bad Guys Front Base

        for _, v in pairs(game:GetService("Workspace").BadGuysFront:GetChildren()) do
            events:WaitForChild("HitBadguy"):FireServer(v, 64.8, 4)
        end

        -- Bad Guy Pizza

        if game:GetService("Workspace"):FindFirstChild("BadGuyPizza", true) then
            events:WaitForChild("HitBadguy"):FireServer(game:GetService("Workspace"):FindFirstChild("BadGuyPizza", true), 64.8, 4)
        end

        -- Bad Guy Brute

        if game:GetService("Workspace"):FindFirstChild("BadGuyBrute") then
            events:WaitForChild("HitBadguy"):FireServer(game:GetService("Workspace").BadGuyBrute, 64.8, 4)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

OtherGroup:AddToggle("LoopKillEnemies", {
    Text = "Kill Bad Guys",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        _G.loopkillall = Value
        loopkillall()
    end
})

-- Teleportation Group

TeleportationGroup:AddDivider()

TeleportationGroup:AddDropdown("TeleportLocationDropdown", {
    Values = {"Kitchen", "Fighting Arena", "Gym", "Pizza Boss", "Shop", "Golden Apple Path", "Generator", "Boss Fight"},
    Default = 0,
    Multi = false,

    Text = "Location",
    Tooltip = false,

    Callback = function(DropdownValue)
        teleportdropdownvalue = DropdownValue
    end
})

local TeleportToLocation = TeleportationGroup:AddButton({
    Text = "Teleport",
    Func = function()
        if teleportdropdownvalue == "Kitchen" then
            utils.teleport(-216.701218, 30.4702568, -722.335327, 0.00404609647, 1.23633853e-07, 0.999991834, -7.18327664e-09, 1, -1.23605801e-07, -0.999991834, -6.68309719e-09, 0.00404609647)
        elseif teleportdropdownvalue == "Fighting Arena" then
            utils.teleport(-262.294586, 62.7116394, -735.916199, -1, -7.62224133e-08, -0.000201582094, -7.6233647e-08, 1, 5.5719358e-08, 0.000201582094, 5.57347235e-08, -1)
            utils.fireTouchEvent(humrootpart, game.Workspace.EvilArea.EnterPart)
        elseif teleportdropdownvalue == "Gym" then
            utils.teleport(-257.281738, 63.4477501, -843.258362, 0.999999464, -6.6242154e-09, 0.00105193094, 6.52111609e-09, 1, 9.80127126e-08, -0.00105193094, -9.8005799e-08, 0.999999464)
        elseif teleportdropdownvalue == "Pizza Boss" then
            utils.teleport(-287.475769, 30.4527531, -721.746277, -0.00427152216, -8.6121041e-08, 0.99999088, 2.21573924e-08, 1, 8.6216474e-08, -0.99999088, 2.25254659e-08, -0.00427152216)
        elseif teleportdropdownvalue == "Shop" then
            utils.teleport(-251.009491, 30.4477539, -851.509705, 0.0225389507, 7.41174511e-10, -0.999745965, 2.19171417e-10, 1, 7.46304019e-10, 0.999745965, -2.35936659e-10, 0.0225389507)
        elseif teleportdropdownvalue == "Golden Apple Path" then
            utils.teleport(85.6087112, 29.4477024, -804.023926, -0.999134541, 1.15144616e-09, 0.0415947847, 4.49046622e-09, 1, 8.01815432e-08, -0.0415947847, 8.02989319e-08, -0.999134541)
        elseif teleportdropdownvalue == "Generator" then
            utils.teleport(-114.484352, 30.0235462, -790.053833, -0.656062722, 0, -0.754706323, 0, 1, 0, 0.754706323, 0, -0.656062722)
        elseif teleportdropdownvalue == "Boss Fight" then
            utils.teleport(-1328.85242, -346.249146, -810.092285, 0.00456922129, 5.69967078e-08, 0.999989569, 1.76120984e-08, 1, -5.70777772e-08, -0.999989569, 1.78727166e-08, 0.00456922129)
        end

        if teleportdropdownvalue ~= "" then
            Library:Notify("You have been teleported to: " .. teleportdropdownvalue .. ".", 4)
        else
            Library:Notify("Please select a location from the location dropdown above.", 5)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local TeleportToVillainBase = TeleportationGroup:AddButton({
    Text = "Villain Base",
    Func = function()
        utils.teleport(-233.926117, 30.4567528, -790.019897, 0.00195977557, -8.22674984e-11, -0.999998093, -2.4766762e-09, 1, -8.71213934e-11, 0.999998093, 2.47684229e-09, 0.00195977557)
        utils.fireTouchEvent(humrootpart, game.Workspace.InsideTouchParts.FrontDoor)
    end,
    DoubleClick = false,
    Tooltip = false,
})

-- Touch Interests Group

TouchInterestsGroup:AddDivider()

TouchInterestsGroup:AddToggle("SpoofInside", {
    Text = "Inside Spoof",
    Default = false,
    Tooltip = "Makes the server think you are inside.",

    Callback = function(Value)
        if Value then
            Toggles.SpoofOutside:SetValue(false)
            Toggles.AlwaysFight:SetValue(false)

            _G.insidespoof = true
            insidespoof()
        else
            _G.insidespoof = false
            insidespoof()
        end
    end
})

TouchInterestsGroup:AddToggle("SpoofOutside", {
    Text = "Outside Spoof",
    Default = false,
    Tooltip = "Makes the server think you are outside.",

    Callback = function(Value)
        if Value then
            Toggles.SpoofInside:SetValue(false)
            Toggles.AlwaysFight:SetValue(false)

            _G.outsidespoof = true
            outsidespoof()
        else
            _G.outsidespoof = false
            outsidespoof()
        end
    end
})

TouchInterestsGroup:AddToggle("AlwaysFight", {
    Text = "Spoof Fighting",
    Default = false,
    Tooltip = "Makes the server think you are always in the fighting arena.",

    Callback = function(Value)
        if Value then
            Toggles.SpoofInside:SetValue(false)
            Toggles.SpoofOutside:SetValue(false)

            _G.spooffighting = true
            spooffighting()
        else
            _G.spooffighting = false
            spooffighting()

            wait(1)

            utils.fireTouchEvent(humrootpart, game.Workspace.EvilArea.ExitPart2)
        end
    end
})

-- Utility Tab

local GiveItemGroup = Tabs.Utility:AddLeftGroupbox("Give Items / Weapons")
local AutoTrainGroup = Tabs.Utility:AddRightGroupbox("Training")
local DisablersGroup = Tabs.Utility:AddRightGroupbox("Disablers")
local OthersGroup1 = Tabs.Utility:AddLeftGroupbox("Other")

-- Give Item Group

GiveItemGroup:AddDivider()

GiveItemGroup:AddDropdown("ItemDropdown", {
    Values = {"GoldPizza", "GoldenApple", "RainbowPizzaBox", "RainbowPizza", "GoldKey", "Bottle", "Armor", "Louise", "Lollipop", "Ladder", "MedKit", "Chips", "Cookie", "BloxyCola", "Apple", "Pizza", "ExpiredBloxyCola"},
    Default = 0,
    Multi = false,

    Text = "Item",
    Tooltip = false,

    Callback = function(DropdownValue)
        giveitemdropdownvalue = DropdownValue
    end
})

GiveItemGroup:AddInput("GiveItemAmount", {
    Default = false,
    Numeric = true,
    Finished = false,

    Text = "Amount",
    Tooltip = false,

    Placeholder = "Number",
    MaxLength = 4,

    Callback = function(GiveAmountTextBoxValue)
        giveamountvalue = GiveAmountTextBoxValue
    end
})

local GiveItem = GiveItemGroup:AddButton({
    Text = "Give Item",
    Func = function()

        if giveitemdropdownvalue == "Armor" then
            events.Vending:FireServer(3, "Armor2", "Armor", player.Name, true, 1)
            Library:Notify("You have been given 1 of Armor.", 3)
            return
        end


        for _ = 1, giveamountvalue do -- Getting the number that was inputted into the input and firing the event x times
            events.GiveTool:FireServer(giveitemdropdownvalue)
        end

        if giveitemdropdownvalue ~= "" and giveamountvalue ~= 0 then
            Library:Notify("You have been given " .. giveamountvalue .. " of " .. giveitemdropdownvalue .. ".", 3)
        else
            Library:Notify("Please select a item from item dropdown and the give amount input above.", 5)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

GiveItemGroup:AddDivider()

GiveItemGroup:AddLabel("Weapons\n")

GiveItemGroup:AddDropdown("WeaponDropdown", {
    Values = {"Crowbar 1", "Crowbar 2", "Bat", "Pitchfork", "Hammer", "Wrench", "Broom"},
    Default = 0,
    Multi = false,

    Text = "Weapon",
    Tooltip = false,

    Callback = function(DropdownValue)
        giveweapondropdownvalue = DropdownValue
    end
})

local GiveWeapon = GiveItemGroup:AddButton({
    Text = "Give Weapon",
    Func = function()
        events.Vending:FireServer(3, giveweapondropdownvalue, "Weapons", player.Name, 1)

        if giveweapondropdownvalue ~= "" then
            Library:Notify("You have been given the " .. giveweapondropdownvalue .. ".", 3)
        else
            Library:Notify("Please select a item from weapon dropdown above.", 5)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

GiveItemGroup:AddDivider()

local bestweapon = player.PlayerGui.Phone.Phone.Phone.Background.InfoScreen.WeaponInfo.TwadoWants.Text

GiveItemGroup:AddLabel("Best Weapon: " .. bestweapon)

local GiveBestWeapon = GiveItemGroup:AddButton({
    Text = "Give Best Weapon",
    Func = function()
        -- checking if the player already has the best weapon

        if player.Backpack:FindFirstChild(bestweapon) or character:FindFirstChild(bestweapon) then
            Library:Notify("You already have the best weapon: " .. bestweapon)
            return
        end

        events.Vending:FireServer(3, bestweapon, "Weapons", player.Name, 1)

        -- checking if the player actually got the best weapon

        wait(0.2)

        if player.Backpack:FindFirstChild(bestweapon) or character:FindFirstChild(bestweapon) then
            Library:Notify("You have been given the best weapon: " .. bestweapon .. ".", 3)
        else
            Library:Notify("Failed to give best weapon: Best weapon wasn't found in Backpack. This is most\nlikely due to giving the best weapon and giving another weapon and results\nin the weapons replacing each other and bugging the weapons.")
            return
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

GiveItemGroup:AddDivider()

GiveItemGroup:AddLabel("Having more more then 1 of an item can prevent it from working. Some examples: \n • You give yourself 5 golden apples, and it will be worthless until you get down to just 1 golden apple and use that one.\n • You give yourself 100 pizza, you turn godmode on, and you get just 1 pizza permanently stuck in your inventory that you can't eat.", true)

-- Training Group

AutoTrainGroup:AddDivider()

local TrainAll = AutoTrainGroup:AddButton({
    Text = "Train Strength & Speed",
    Func = function()
        for _ = 1, 5 do
            events.RainbowWhatStat:FireServer("Strength")
            events.RainbowWhatStat:FireServer("Speed")
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local TrainStrength = AutoTrainGroup:AddButton({
    Text = "Train Strength",
    Func = function()
        for _ = 1, 5 do
            events.RainbowWhatStat:FireServer("Strength")
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local TrainSpeed = AutoTrainGroup:AddButton({
    Text = "Train Speed",
    Func = function()
        for _ = 1, 5 do
            events.RainbowWhatStat:FireServer("Speed")
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

-- Disablers Group

DisablersGroup:AddDivider()


DisablersGroup:AddToggle("AntiIceSlip", {
    Text = "Anti Slip",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            events:FindFirstChild("IceSlip").Parent = game:GetService("Chat")

            antislipenabled = true

        else

            game:GetService("Chat"):FindFirstChild("IceSlip").Parent = events

            antislipenabled = false
        end
    end
})

DisablersGroup:AddLabel("Anti Slip will also protect you from anything that makes you fall/sit down such as the wave 3 brute.", true)

DisablersGroup:AddToggle("AntiHail", {
    Text = "Anti Hail",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            game.Workspace:FindFirstChild("Hails").Parent = game:GetService("Chat")
        else
            game:GetService("Chat"):FindFirstChild("Hails").Parent = game.Workspace
        end
    end
})

DisablersGroup:AddToggle("DisableWind", {
    Text = "Disable Wind",
    Default = false,
    Tooltip = "Disables the wind knocking you back on the golden apple path.",

    Callback = function(Value)
        _G.disablewindknockback = true
        disablewindknockback()

        if Value == false then
            _G.disablewindknockback = false
            disablewindknockback()
            
            for _, v in pairs(game.Workspace:GetChildren()) do
                if v.Name == "WavePart" then
                    v.CanTouch = true
                end
            end
        end
    end
})

DisablersGroup:AddToggle("DisableMud", {
    Text = "Disable Mud",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            for _, v in pairs(game:GetService("Workspace").BogArea:GetChildren()) do
                if v.Name == "Mud" then
                    v.CanTouch = false
                end
            end

        else

            for _, v in pairs(game:GetService("Workspace").BogArea:GetChildren()) do
                if v.Name == "Mud" then
                    v.CanTouch = true
                end
            end
        end
    end
})

-- Others Group

OthersGroup1:AddDivider()

local CollectHiddenItems = OthersGroup1:AddButton({
    Text = "Collect Hidden Items",
    Func = function()
        utils.fireAllClickEvents(game.Workspace.Hidden)
    end,
    DoubleClick = false,
    Tooltip = "Collects all the items hidden in drawers."
})

--[[

local CollectHiddenItems = OthersGroup1:AddButton({
    Text = "Collect Hidden Items",
    Func = function()
        for _, v in pairs(game.Workspace.Hidden:GetDescendants()) do
            if v:IsA("ClickDetector") then
                utils.fireClickEvent(v.Parent)
            end
        end
    end,
    DoubleClick = false,
    Tooltip = "Collects all the items hidden in drawers."
})

]]

local hiddenitemslabel = OthersGroup1:AddLabel("Existing Hidden Items: ", true)

local function updatehiddenitems()
    while _G.updatehiddenitems do
        local hiddenParts = game.Workspace:FindFirstChild("Hidden")
        local text = "Existing Hidden Items: \n\n"

        if hiddenParts and #hiddenParts:GetChildren() > 0 then
            for _, part in ipairs(hiddenParts:GetChildren()) do
                text = text .. part.Name .. "\n"
            end
        else
            text = text .. "No more items left"
        end

        hiddenitemslabel:SetText(text, true)

        task.wait(1)
    end
end

-- Start the update loop
task.spawn(updatehiddenitems)

local CollectOutsideItems = OthersGroup1:AddButton({
    Text = "Collect Outside Items",
    Func = function()
        local origcframe = humrootpart.CFrame

        if #game.Workspace.OutsideParts:GetChildren() == 0 then
            Library:Notify("No more outside items.", 5)
            return
        end
        
        utils.fireAllClickEvents(game.Workspace.OutsideParts)

        wait(0.1)

        utils.teleport(-200.997543, 34.0999222, -790.799988, 1, -8.10623169e-05, -5.24520874e-06, 8.10623169e-05, 1, 5.24520874e-06, 5.24520874e-06, -5.24520874e-06, 1) -- teleport to entrance
        wait(0.01)
        events.TeleportMain:FireServer("Main") -- teleport to villian base
        wait(0.1)
        utils.teleportToCFrame(origcframe) -- teleport to original cframe
    end,
    DoubleClick = false,
    Tooltip = false,
})

local outsideitemslabel = OthersGroup1:AddLabel("Existing Outside Items: ", true)

local function updateoutsideitems()
    while _G.updateoutsideitems do
        local outsideParts = game.Workspace:FindFirstChild("OutsideParts")
        local text = "Existing Outside Items: \n\n"

        if outsideParts and #outsideParts:GetChildren() > 0 then
            for _, part in ipairs(outsideParts:GetChildren()) do
                text = text .. part.Name .. "\n"
            end
        else
            text = text .. "No more items left"
        end

        outsideitemslabel:SetText(text, true)

        task.wait(1)
    end
end

-- Start the update loop
task.spawn(updateoutsideitems)

local HealPlayersMedkit = OthersGroup1:AddButton({
    Text = "MedKit Heal Others",
    Func = function()
        for _, v in pairs(game:GetService("Players"):GetPlayers()) do
            events.HealPlayer:FireServer(v)
        end
    end,
    DoubleClick = false,
    Tooltip = "Heals all other players using the medkit."
})

local HealYourself = OthersGroup1:AddButton({
    Text = "Heal Yourself",
    Func = function()
        for _ = 1, 2 do
            events.GiveTool:FireServer("GoldPizza")

            wait(0.2)
        
            events.BackpackEvent:FireServer("Equip", player.Backpack.GoldPizza)
        
            wait(0.1)
        
            events.CurePlayer:FireServer(player, player)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local HealAll = OthersGroup1:AddButton({
    Text = "Heal All",
    Func = function()
        events.GiveTool:FireServer("GoldenApple")

        wait(0.2)
    
        events.BackpackEvent:FireServer("Equip", player.Backpack.GoldenApple)
    
        wait(0.2)
    
        events.HealTheNoobs:FireServer()
    end,
    DoubleClick = false,
    Tooltip = false,
})

OthersGroup1:AddToggle("AutoHealPlayers", {
    Text = "Auto Heal All",
    Default = false,
    Tooltip = "Loop heals all players using the golden apple. This will only work if the golden apple is not taken",

    Callback = function(Value)
        _G.autohealall = Value
        autohealall()
    end
})

OthersGroup1:AddToggle("AutoEat", {
    Text = "Auto Eat",
    Default = false,
    Tooltip = "Eats your editable items.",

    Callback = function(Value)
        _G.autoeat = Value
        autoeat()
    end
})

-- LocalPlayer Tab

local LocalPlayerGroup = Tabs.LocalPlayer:AddLeftGroupbox("LocalPlayer")
local DamageGroup = Tabs.LocalPlayer:AddRightGroupbox("Damage")

-- LocalPlayer Group

LocalPlayerGroup:AddDivider()

LocalPlayerGroup:AddToggle("PlayerModControlToggle", {Text = "Player Modification"})
local PlayerModDepBox = LocalPlayerGroup:AddDependencyBox();

PlayerModDepBox:SetupDependencies({
    {Toggles.PlayerModControlToggle, true}
})

PlayerModDepBox:AddSlider("WalkSpeedSlider", {
    Text = "WalkSpeed Value",
    Default = 16,
    Min = 16,
    Max = 300,
    Rounding = 0,
    Compact = false,

    Callback = function(Value)
        if walkspeedenabled then
            walkspeedslidervalue = Value
        end
    end
})

PlayerModDepBox:AddSlider("JumpPowerSlider", {
    Text = "JumpPower Value",
    Default = 50,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Compact = false,

    Callback = function(Value)
        if jumppowerenabled then
            jumppowerslidervalue = Value
        end
    end
})

PlayerModDepBox:AddInput("CustomWalkspeedInput", {
    Default = false,
    Numeric = true,
    Finished = true,

    Text = "Custom WalkSpeed Value",
    Tooltip = false,

    Placeholder = "Number",
    MaxLength = 3,

    Callback = function(Text)
        local textNumber = tonumber(Text)

        -- Determining Limits

        if textNumber == nil then
            Library:Notify("Invalid value.", 5)
            return
        end

        if textNumber < Options.WalkSpeedSlider.Min then
            Library:Notify("Cannot have a value less then the minimum of " .. Options.WalkSpeedSlider.Min .. ".", 5)
            return
        end

        if textNumber > Options.WalkSpeedSlider.Max then
            Library:Notify("Cannot have a value greater then the maximum of " .. Options.WalkSpeedSlider.Max .. ".", 5)
            return
        end

        -- Setting the value of the walkspeed slider to the text in the input

        Options.WalkSpeedSlider:SetValue(Text)
    end
})

PlayerModDepBox:AddInput("CustomJumpPowerInput", {
    Default = false,
    Numeric = true,
    Finished = true,

    Text = "Custom JumpPower Value",
    Tooltip = false,

    Placeholder = "Number",
    MaxLength = 3,

    Callback = function(Text)
        local textNumber = tonumber(Text)

        -- Determining Limits

        if textNumber == nil then
            Library:Notify("Invalid value.", 5)
            return
        end

        if textNumber < Options.JumpPowerSlider.Min then
            Library:Notify("Cannot have a value less then the minimum of " .. Options.JumpPowerSlider.Min .. ".", 5)
            return
        end

        if textNumber > Options.JumpPowerSlider.Max then
            Library:Notify("Cannot have a value greater then the maximum of " .. Options.JumpPowerSlider.Max .. ".", 5)
            return
        end

        -- Setting the value of the jump power slider to the text in the input

        Options.JumpPowerSlider:SetValue(Text)
    end
})

PlayerModDepBox:AddToggle("WalkSpeedEnabled", {
    Text = "Enable WalkSpeed",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            walkspeedenabled = true
            walkspeedslidervalue = Options.WalkSpeedSlider.Value -- set the slider variable to the value of the walkspeed slider to instantly apply walkspeed when enabled

            _G.updatewalkspeed = true
            updatewalkspeed()

            Toggles.WalkSpeedExploit:SetValue(false) -- disable WalkSpeedExploit to prevent overlapping
        else
            walkspeedenabled = false

            _G.updatewalkspeed = false
            updatewalkspeed()

            utils.modifyPlayer("WalkSpeed", 16)
        end
    end
})

PlayerModDepBox:AddToggle("JumpPowerEnabled", {
    Text = "Enable JumpPower",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            utils.modifyPlayer("UseJumpPower", true)

            jumppowerenabled = true
            jumppowerslidervalue = Options.JumpPowerSlider.Value -- set the slider variable to the value of the jump power slider to instantly apply jumppower when enabled

            _G.updatejumppower = true
            updatejumppower()
        else
            jumppowerenabled = false

            _G.updatejumppower = false
            updatejumppower()

            utils.modifyPlayer("JumpPower", 50) -- reset jump power
        end
    end
})

LocalPlayerGroup:AddDivider()

LocalPlayerGroup:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Tooltip = "Allows you to clip through walls.",

    Callback = function(Value)
        _G.noclip = Value
        noclip()
    end
})

-- Damage Group

DamageGroup:AddDivider()

DamageGroup:AddInput("DamageAmount", {
    Default = false,
    Numeric = true,
    Finished = false,

    Text = "Damage Amount",
    Tooltip = false,

    Placeholder = "Number",
    MaxLength = 3,

    Callback = function(TextBoxValue)
        damageamountvalue = TextBoxValue
    end
})

local DamageConfirm = DamageGroup:AddButton({
    Text = "Damage",
    Func = function()
        if damageamountvalue == 0 then
            Library:Notify("Invalid damage amount. Please enter a valid number.", 4)
        else
            events.Energy:FireServer(-damageamountvalue, false, false)
        end
    end,
    DoubleClick = true,
    Tooltip = false,
})

-- Endings Tab

local SecretEndingGroup = Tabs.Endings:AddLeftGroupbox("Secret Ending")
local EvilEndingGroup = Tabs.Endings:AddRightGroupbox("Evil Ending")
local OriginEnding = Tabs.Endings:AddLeftGroupbox("Origin Ending")

-- Secret Ending

SecretEndingGroup:AddDivider()

local CompleteSecretEnding = SecretEndingGroup:AddButton({
    Text = "Unlock Secret Ending",
    Func = function()
        local origcframe = humrootpart.CFrame

        Library:Notify("Knocked down tree.", 1)

        events.LarryEndingEvent:FireServer("TreeFelled") -- getting the gold crowbar

        wait(1.5)

        events.LarryEndingEvent:FireServer("CrowbarCollected") -- collecting crowbar that fell from the tree

        Library:Notify("Obtained gold crowbar.", 1)
        
        events.PunchableQuest:FireServer("Hit") -- hitting the boy

        wait(0.2)

        utils.teleport(-82.0809555, 29.4477024, -914.276917, -0.343557715, 7.47457136e-08, 0.939131558, -3.08562349e-08, 1, -9.08782312e-08, -0.939131558, -6.01999801e-08, -0.343557715) -- collecting the hat

        Library:Notify("Obtained Scary Larry hat.", 1)

        events.LarryEndingEvent:FireServer("MaskCollected") -- getting the mask

        Library:Notify("Obtained Scary Larry mask.", 1)

        -- Teleporting back to the base

        wait(0.8)

        utils.teleportToCFrame(origcframe) -- teleport back to original cframe

        Library:Notify("Successfully Finished Auto Secret Ending.", 3)
    end,
    DoubleClick = false,
    Tooltip = false,
})

-- Evil Ending

EvilEndingGroup:AddDivider()

EvilEndingGroup:AddLabel("First unlock all NPCs in the Miscellaneous tab and the Wave 3 Brute should drop it's crowbar, then pick up it by clicking on it and keep in mind it requires max strength.", true)

-- Origin Ending

OriginEnding:AddDivider()

local CollectRequiredPapers = OriginEnding:AddButton({
    Text = "Collect Required Papers",
    Func = function()
        for _, v in pairs(game.Workspace:GetDescendants()) do
            if v.Name == "Note1" or v.Name == "Note2" or v.Name == "Note3" or v.Name == "Note4" or v.Name == "Note5" or v.Name == "Note6" then
                for _, v in pairs(v:GetDescendants()) do
                    if v:IsA("ClickDetector") then
                        utils.fireClickEvent(v.Parent)
                    end
                end
            end
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

OriginEnding:AddLabel("Memory I - School")

OriginEnding:AddToggle("LarryESP", {
    Text = "Larry ESP",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        local originending

        -- Checking for origin ending

        if game.Workspace:FindFirstChild("Gym") then
            originending = true
        else
            originending = false
        end

        if Value then

            if originending then
                for _, v in pairs(game.Workspace:GetChildren()) do
                    if v.Name == "LarryBoss" and v:IsA("Model") then
                        local larryesp = Instance.new("Highlight", v)
        
                        larryesp.Name = "_CelestialLarryESP"
                        larryesp.Adornee = nil
                        larryesp.FillColor = Color3.new(255, 0, 0)
                        larryesp.FillTransparency = 0.5
                        larryesp.OutlineColor = Color3.new(255, 255, 255)
                        larryesp.OutlineTransparency = 0
                    end
                end
            else
                Library:Notify("Origin Ending not found.", 5)
                Toggles.LarryESP:SetValue(false)
            end

        else

            for _, v in pairs(game.Workspace:GetDescendants()) do
                if v.Name == "_CelestialLarryESP" then
                    v:Destroy()
                end
            end
        end
    end
})

OriginEnding:AddToggle("CardboardBoxESP", {
    Text = "Cardboard Box ESP",
    Default = false,
    Tooltip = "Tends to not be reliable due to Roblox's\nhighlight cap.",

    Callback = function(Value)
        local originending

        -- Checking for origin ending

        if game.Workspace:FindFirstChild("GameObjects") then
            originending = true
        else
            originending = false
        end

        if Value then

            if originending then
                for _, v in pairs(game.Workspace.GameObjects.Boxes:GetChildren()) do
                    if v.Name == "Box" and v:IsA("Model") then
                        local cardboardboxesp = Instance.new("Highlight", v)
        
                        cardboardboxesp.Name = "_CelestialCardboardBoxESP"
                        cardboardboxesp.Adornee = nil
                        cardboardboxesp.FillColor = Color3.new(255, 255, 255)
                        cardboardboxesp.FillTransparency = 1
                        cardboardboxesp.OutlineColor = Color3.new(255, 255, 255)
                        cardboardboxesp.OutlineTransparency = 0
                    end
                end
            else
                Library:Notify("Origin Ending not found.", 5)
                Toggles.CardboardBoxESP:SetValue(false)
            end
            
        else

            for _, v in pairs(game.Workspace:GetDescendants()) do
                if v.Name == "_CelestialCardboardBoxESP" then
                    v:Destroy()
                end
            end
        end
    end
})

OriginEnding:AddLabel("Memory II - Gym")

local RoseTeleport = OriginEnding:AddButton({
    Text = "Teleport to Rose",
    Func = function()
        local originending

        if game.Workspace:FindFirstChild("Gym") then
            originending = true
        else
            originending = false
        end

        if originending then
            utils.partTeleport(game.Workspace.Gym.Roses.Rose.Stem)
        else
            Library:Notify("Origin Ending not found.", 5)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local SafeSpotTeleport = OriginEnding:AddButton({
    Text = "Teleport to Safe Spot",
    Func = function()
        local originending

        if game.Workspace:FindFirstChild("Gym") then
            originending = true
        else
            originending = false
        end

        if originending then
            utils.teleport(498.540649, 265.847321, 701.331665, 0.999958396, 1.74917014e-09, -0.00912014209, -1.50502355e-09, 1, 2.67769042e-08, 0.00912014209, -2.67620646e-08, 0.999958396)
        else
            Library:Notify("Origin Ending not found.", 5)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

OriginEnding:AddLabel("Memory III - Obby")

local CompleteEndgameObby = OriginEnding:AddButton({
    Text = "Complete Obby",
    Func = function()
        local originending

        if game.Workspace:FindFirstChild("Obby") then
            originending = true
        else
            originending = false
        end

        if originending then
            utils.partTeleport(game.Workspace.Obby.CheckpointPart3)
        else
            Library:Notify("Origin Ending not found.", 5)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

-- Misc Tab

local MiscGroup = Tabs.Misc:AddLeftGroupbox("Miscellaneous")
local NPCGroup = Tabs.Misc:AddRightGroupbox("NPCs")

-- Miscellaneous Group

MiscGroup:AddDivider()

local TeleportToLobby = MiscGroup:AddButton({
    Text = "Lobby",
    Func = function()
        utils.gameTeleport(13864661000)
    end,
    DoubleClick = true,
    Tooltip = false,
})

local IceSlip = MiscGroup:AddButton({
    Text = "Slip",
    Func = function()
        if antislipenabled then
            Toggles.AntiIceSlip:SetValue(false) -- disabling anti slip because it is enabled

            events.IceSlip:FireServer() -- fire slip event

            Toggles.AntiIceSlip:SetValue(true) -- set anti slip back to true

        else

            events.IceSlip:FireServer() -- fire the slip event normally because anti slip isn't enabled
        end
    end,
    DoubleClick = false,
    Tooltip = "Triggers an ice slip.",
})

local BreakBarricades = MiscGroup:AddButton({
    Text = "Break Barricades",
    Func = function()
        local path = game.Workspace:FindFirstChild("FallenTrees")

        if not path then
            Library:Notify("Golden apple path not found. Try again once the path loads.")
            return
        end

        for _ = 1, 25 do
            for _, v in pairs(path:GetChildren()) do
				if v:FindFirstChild("TreeHitPart") then
					events.RoadMissionEvent:FireServer(1, v.TreeHitPart, 5)
                end
            end
        end
    end,
    DoubleClick = false,
    Tooltip = "Destroys the barricades leading to the golden apple.",
})

-- NPCs Group

NPCGroup:AddDivider()


local UnlockAllNPCs = NPCGroup:AddButton({
    Text = "Unlock All NPCs",
    Func = function()
        local requirement = player.PlayerGui.Phone.Phone.Phone.Background.InfoScreen.DogInfo.TwadoWants.Text
        local origcframe = humrootpart.CFrame

        -- Uncle Pete
    
    
        events.GiveCrowbar:FireServer(game.Workspace.TheHouse.Rack) -- getting crowbar

        wait(0.4)
        
        events.GiveTool:FireServer("Key") -- getting key

        wait(0.9)

        events.BackpackEvent:FireServer("Equip", player.Backpack.Key) -- equipping the key

        wait(0.2)
        
        events.KeyEvent:FireServer() -- firing unlock cage event

        wait(1)

        utils.fireClickEvent(game:GetService("Workspace").UnclePete) -- triggering quest
    
        Library:Notify("Unlocked Uncle Pete.", 6) -- notify step completion
    
    
    
        -- Detective
    
    
    
        events.GiveTool:FireServer("Louise") -- giving required item

        wait(0.5)

        events.LouiseGive:FireServer(2) -- giving required item to detective

        for _, v in pairs(game.Workspace.TheHouse.OfficeDoor.ClosedDoor:GetDescendants()) do
            if v:IsA("ClickDetector") then
                utils.fireClickEvent(v.Parent) -- opening the door so detective can exit the room easier and faster
            end
        end
    
        Library:Notify("Unlocked Detective.", 6) -- notify step completion
    
    
    
        -- Twado

        utils.teleport(-204.027481, 30.4477577, -791.114014, -0.00695088226, -8.00880642e-08, -0.99997586, 1.38134548e-09, 1, -8.00995963e-08, 0.99997586, -1.93807503e-09, -0.00695088226) -- teleporting to the entrance

        events.CatFed:FireServer(requirement) -- feeding twado
        wait(2) -- waiting 2 before the next step to accommodate with the server's twado feed delay
        utils.tweenTeleport(1, "-197.036865, 29.2477055, -791.058167, -0.00797706284, 7.27165101e-08, -0.999968171, -1.20378851e-09, 1, 7.27284331e-08, 0.999968171, 1.78390946e-09, -0.00797706284", true) -- moving forward through the entrance
    
        Library:Notify("Unlocked Twado.", 6) -- notify step completion

        wait(1.4)

        utils.teleportToCFrame(origcframe) -- teleport back to the original cframe
    end,
    DoubleClick = false,
    Tooltip = false,
})

NPCGroup:AddDivider()

-- Uncle Pete



NPCGroup:AddLabel("Uncle Pete")

local UnlockPete = NPCGroup:AddButton({
    Text = "Unlock Uncle Pete",
    Func = function()
        events.GiveCrowbar:FireServer(game.Workspace.TheHouse.Rack) -- getting crowbar

        wait(0.4)
        
        events.GiveTool:FireServer("Key") -- getting key

        wait(0.9)

        events.BackpackEvent:FireServer("Equip", player.Backpack.Key) -- equipping the key

        wait(0.2)
        
        events.KeyEvent:FireServer() -- firing unlock cage event

        wait(1)

        utils.fireClickEvent(game:GetService("Workspace").UnclePete) -- triggering quest
    end,
    DoubleClick = false,
    Tooltip = false,
})

local TriggerQuest = NPCGroup:AddButton({
    Text = "Trigger Quest",
    Func = function()
        utils.fireClickEvent(game:GetService("Workspace").UnclePete)
    end,
    DoubleClick = false,
    Tooltip = false,
})


-- Detective

NPCGroup:AddDivider()

NPCGroup:AddLabel("Detective")

local UnlockDetective = NPCGroup:AddButton({
    Text = "Unlock Detective",
    Func = function()
        events.GiveTool:FireServer("Louise")

        wait(0.5)

        events.LouiseGive:FireServer(2)

        -- opening the door so detective can exit the room easier

        for _, v in pairs(game.Workspace.TheHouse.OfficeDoor.ClosedDoor:GetDescendants()) do
            if v:IsA("ClickDetector") then
                utils.fireClickEvent(v.Parent)
            end
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local TeleportToDetectiveRoom = NPCGroup:AddButton({
    Text = "Teleport to Detective Room",
    Func = function()
        -- Opening the door so the light turns on

        for _, v in pairs(game.Workspace.TheHouse.OfficeDoor.ClosedDoor:GetDescendants()) do
            if v:IsA("ClickDetector") then
                utils.fireClickEvent(v.Parent)
            end
        end

        wait(0.1)
    
        -- Teleport
    
        utils.teleport(-278.495697, 95.4477386, -790.951477, 0.00650879554, -5.40658984e-09, 0.99997884, 2.86954238e-10, 1, 5.40483658e-09, -0.99997884, 2.51769161e-10, 0.00650879554)
    end,
    DoubleClick = false,
    Tooltip = false,
})


-- Twado

NPCGroup:AddDivider()

NPCGroup:AddLabel("Twado")

local UnlockTwado = NPCGroup:AddButton({
    Text = "Unlock Twado",
    Func = function()
        local requirement = player.PlayerGui.Phone.Phone.Phone.Background.InfoScreen.DogInfo.TwadoWants.Text
        local origcframe = humrootpart.CFrame

        utils.teleport(-204.027481, 30.4477577, -791.114014, -0.00695088226, -8.00880642e-08, -0.99997586, 1.38134548e-09, 1, -8.00995963e-08, 0.99997586, -1.93807503e-09, -0.00695088226) -- teleporting to the entrance

        events.CatFed:FireServer(requirement) -- feeding twado
        wait(2) -- waiting 2 before the next step to accommodate with the server's twado feed delay
        utils.tweenTeleport(1, "-197.036865, 29.2477055, -791.058167, -0.00797706284, 7.27165101e-08, -0.999968171, -1.20378851e-09, 1, 7.27284331e-08, 0.999968171, 1.78390946e-09, -0.00797706284", true) -- moving forward through the entrance
        wait(1)
        utils.teleportToCFrame(origcframe) -- teleport back to the original cframe
    end,
    DoubleClick = false,
    Tooltip = false,
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

    _G.updatewalkspeed = false

    _G.godmodeloop = false
    _G.loophideenergy = false
    _G.disablefrontdoor = false
    _G.autoeat = false
    _G.noclip = false
    _G.speedexploit = false
    _G.removeinventorysound = false
    _G.autohealall = false
    _G.disablewindknockback = false
    _G.bypasscutscenes = false
    _G.larryesp = false
    _G.updateoutsideitems = false
    _G.updatehiddenitems = false
    _G.collectcash = false
    _G.disablevignette = false
    _G.insidespoof = false
    _G.outsidespoof = false
    _G.spooffighting = false

    -- WalkSpeedExploit

    utils.modifyPlayer("WalkSpeed", 16)

    -- HighlightHiddenItems

    for _, v in pairs(game.Workspace:GetDescendants()) do
        if v.Name == "_CelestialItemHighlight" then
            v:Destroy()
        end
    end

    -- DresserESP

    for _, v in pairs(game.Workspace:GetDescendants()) do
        if v.Name == "_CelestialDresserHighlight" then
            v:Destroy()
        end
    end

    -- DisableFrontDoor

    for _, v in pairs(game.Workspace.tst:GetDescendants()) do
        if v.Name == "Door" and v:IsA("Part") then
            v.CanCollide = false
            v.Transparency = 0
        end
    end

    -- AlwaysFight

    utils.fireTouchEvent(humrootpart, game.Workspace.EvilArea.ExitPart2)

    -- AntiIceSlip

    if game:GetService("Chat"):FindFirstChild("IceSlip") then
        game:GetService("Chat"):FindFirstChild("IceSlip").Parent = events
    end

    -- AntiHail

    if game:GetService("Chat"):FindFirstChild("Hails") then
        game:GetService("Chat"):FindFirstChild("Hails").Parent = game.Workspace
    end

    -- DisableWind

    for _, v in pairs(game.Workspace:GetChildren()) do
        if v.Name == "WavePart" then
            v.CanTouch = true
        end
    end

    -- DisableMud

    for _, v in pairs(game:GetService("Workspace").BogArea:GetChildren()) do
        if v.Name == "Mud" then
            v.CanTouch = true
        end
    end

    -- WalkSpeedEnabled

    utils.modifyPlayer("WalkSpeed", 16)

    -- JumpPowerEnabled

    utils.modifyPlayer("JumpPower", 50)

    -- LarryESP

    for _, v in pairs(game.Workspace:GetDescendants()) do
        if v.Name == "_CelestialLarryESP" then
            v:Destroy()
        end
    end

    -- CardboardBoxESP

    for _, v in pairs(game.Workspace:GetDescendants()) do
        if v.Name == "_CelestialCardboardBoxESP" then
            v:Destroy()
        end
    end

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
SaveManager:SetFolder("Celestial/Break In 2 - Game")

SaveManager:BuildConfigSection(Tabs["UI Settings"])

ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()