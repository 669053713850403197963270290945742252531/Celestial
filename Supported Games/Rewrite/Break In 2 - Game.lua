while not game:IsLoaded() do
    task.wait()
end

local auth = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Authentication.lua?ref_type=heads"))()
local entityLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/LIbraries/Entity%20Library.lua?ref_type=heads"))()
local utils = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Utilities.lua?ref_type=heads"))()
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
local events = game:GetService("ReplicatedStorage").Events
local camera = game:GetService("Workspace").CurrentCamera

local character = player.Character
local humanoid = entityLib.getCharInstance("Humanoid")
local hrp = entityLib.getCharInstance("HumanoidRootPart")

-- Window

local window = library:CreateWindow({
    Title = "Celestial - " .. gameName .. " : " .. auth.currentUser.Identifier,
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Left",
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Module Variables

local walkspeedEnabled = false
local jumppowerEnabled = false

local sliderWalkspeedValue = 16
local jumppowerSliderValue = 50

local giveItemDropdownValue = ""
local giveAmountValue = 1
local damageAmountValue = 0
local teleportDropdownValue = ""
local weaponDropdownValue = ""
local antiSlipEnabled = false

--[[

-- Loop Values

_G.updateWalkspeed = true

_G.godmode = true
_G.hideEnergy = true
_G.disableFrontDoor = true
_G.autoEat = true
_G.noclip = true
_G.speedExploit = true
_G.autoHealAll = true
_G.disableWind = true
_G.bypassCutscenes = true
_G.larryESP = true
_G.updateOutsideItems = true
_G.updateHiddenItems = true
_G.collectCash = true
_G.disableVignette = true
_G.insideSpoof = true
_G.outsideSpoof = true
_G.fightSpoof = true

-- Loop Functions

function updateWalkspeed()
    while _G.updateWalkspeed do
        entityLib.modifyPlayer("WalkSpeed", sliderWalkspeedValue)

        wait()
    end
end

function updatejumppower()
    while _G.updatejumppower do
        entityLib.modifyPlayer("JumpPower", jumppowerSliderValue)

        wait()
    end
end




function godmode()
    while _G.godmode do
        events.GiveTool:FireServer("Pizza")
        events.Energy:FireServer(25, "Pizza")

        wait()
    end
end

function hideEnergy()
    while _G.hideEnergy do
        for _, v in pairs(player.PlayerGui.EnergyBar.EnergyBar.EnergyBar:GetDescendants()) do
            if v.Name == "Template" and v:IsA("TextLabel") then
                v.Visible = false
            end
        end

        wait()
    end
end

function disableFrontDoor()
    while _G.disableFrontDoor do
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

function autoEat()
    while _G.autoEat do
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

function speedExploit()
    while _G.speedExploit do
        entityLib.modifyPlayer("WalkSpeed", 25)

        wait(3)
    end
end

function autoHealAll()
    while _G.autoHealAll do
        events.GiveTool:FireServer("GoldenApple") -- give golden apple

        wait(0.1)

        events.BackpackEvent:FireServer("Equip", player.Backpack.GoldenApple) -- equip golden apple

        wait(0.1)

        events.HealTheNoobs:FireServer() -- fire heal event

        wait(6)
    end
end

function disableWind()
    while _G.disableWind do
        for _, v in pairs(game.Workspace:GetChildren()) do
            if v.Name == "WavePart" then
                v.CanTouch = false
            end
        end

        wait()
    end
end

function bypassCutscenes()
    while _G.bypassCutscenes do
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

function collectCash()
    while _G.collectCash do
		for _, v in pairs(game:GetService("Workspace"):GetChildren()) do
			if v.Name == "Part" and v:FindFirstChild("TouchInterest") and v:FindFirstChild("Weld") and v.Transparency == 1 then
				v.CFrame = hrp.CFrame
			end
		end

        wait(0.1)
    end
end

function disableVignette()
    while _G.disableVignette do
        player.PlayerGui.Assets.Vig.Visible = false

        wait()
    end
end

function insideSpoof()
    while _G.insideSpoof do
        utils.fireTouchEvent(hrp, game.Workspace.InsideTouchParts.FrontDoor)

        wait(0.2)
    end
end

function outsideSpoof()
    while _G.outsideSpoof do
        utils.fireTouchEvent(hrp, game.Workspace.OutsideTouchParts.OutsideTouch)

        wait(0.2)
    end
end

function fightSpoof()
    while _G.fightSpoof do
        utils.fireTouchEvent(hrp, game.Workspace.EvilArea.EnterPart)

        wait(1)
    end
end

]]

-- Functions

local notifSounds = {
    neutral = 17208372272,
    success = 5797580410,
    error = 5797578819
}

local tabs = {
    info = window:AddTab("Info"),
    exploits = window:AddTab("Exploits"),
    util = window:AddTab("Utility"),
    localPlayer = window:AddTab("LocalPlayer"),
    endings = window:AddTab("Endings"),
    misc = window:AddTab("Misc"),
    ["UI Settings"] = window:AddTab("Configs")
}

library:Notify("Successfully logged in as " .. auth.currentUser.Rank .. ": " .. auth.currentUser.Identifier, 6, notifSounds.neutral)

-- Tab: Game Info

local gameDetailsGroup = tabs.info:AddLeftGroupbox("Game Details")
local serDetailsGroup = tabs.info:AddRightGroupbox("User Details")
local whitelistDetailsGroup = tabs.info:AddLeftGroupbox("Whitelist Details")

-- Group: Game Info

gameDetailsGroup:AddDivider()

gameDetailsGroup:AddLabel("Game Supported: true", true)
gameDetailsGroup:AddLabel("Game Name: Break In 2 (Story) - " .. gameName, true)
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

-- Tab: Exploits

local exploitsGroup = tabs.exploits:AddLeftGroupbox("Exploits")
local visualsGroup = tabs.exploits:AddRightGroupbox("Visuals")
local teleportationGroup = tabs.exploits:AddLeftGroupbox("Teleportation")
local touchInterestsGroup = tabs.exploits:AddLeftGroupbox("Touch Transmitter Manipulation")
local othersGroup = tabs.exploits:AddRightGroupbox("Other")

-- Group: Exploits

exploitsGroup:AddDivider()

exploitsGroup:AddToggle("godmodeToggle", {
	Text = "Godmode",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        _G.godmode = state
        godmode()
	end
})

exploitsGroup:AddToggle("hideEnergyUI", {
	Text = "Hide Energy Gain",
	Tooltip = 'Disables the green "+x" energy text above the health bar.',
	Default = false,

	Callback = function(state)
        _G.hideEnergy = state
        hideEnergy()
	end
})

exploitsGroup:AddDivider()

exploitsGroup:AddToggle("bypassCutscenes", {
	Text = "Bypass Cutscenes",
	Tooltip = "Prevents camera changing.\nVery unreliable.",
	Default = false,
    Risky = true,

	Callback = function(state)
        _G.bypassCutscenes = state
        bypassCutscenes()
	end
})

exploitsGroup:AddToggle("walkspeedExploit", {
	Text = "Speed Boost",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        if state then
            _G.speedExploit = true
            speedExploit()

        else

            _G.speedExploit = false

            entityLib.modifyPlayer("WalkSpeed", 16)
        end
	end
})

exploitsGroup:AddToggle("collectCash", {
	Text = "Collect Cash",
	Tooltip = "Tends to act as if you collect one due to a lot of cash parts being added and collected all at once.",
	Default = false,

	Callback = function(state)
        _G.collectCash = state
        collectCash()
	end
})

-- Group: Visuals

visualsGroup:AddDivider()

visualsGroup:AddToggle("hiddenItemsHighlight", {
	Text = "Hidden Item ESP",
	Tooltip = "Highlights the items in drawers.",
	Default = false,

	Callback = function(state)
        if state then
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

visualsGroup:AddToggle("dresserESP", {
	Text = "Dresser ESP",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        if state then
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

visualsGroup:AddToggle("disableFrontDoor", {
	Text = "Disable Front Door",
	Tooltip = "Makes the front door transparent and allows clipping.",
	Default = false,

	Callback = function(state)
        if state then
            _G.disableFrontDoor = true
            disableFrontDoor()
        else
            _G.disableFrontDoor = false
            disableFrontDoor()

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

visualsGroup:AddToggle("disableVignette", {
	Text = "Disable Vignette",
	Tooltip = "Disables the black border when in dark areas of the map.",
	Default = false,

	Callback = function(state)
        _G.disableVignette = state
        disableVignette()
	end
})

-- Group: Teleportation

teleportationGroup:AddDivider()

teleportationGroup:AddDropdown("locationTeleportDropdown", {
    Values = {"Kitchen", "Fighting Arena", "Gym", "Pizza Boss", "Shop", "Golden Apple Path", "Generator", "Boss Fight"},
    Default = 0,
    Multi = false,

    Text = "Location",
    Tooltip = false,

    Callback = function(value)
        teleportDropdownValue = value
    end
})

local teleportToLocation = teleportationGroup:AddButton({
    Text = "Teleport",
    Func = function()
        if teleportDropdownValue == "Kitchen" then
            entityLib.teleport(-216.701218, 30.4702568, -722.335327, 0.00404609647, 1.23633853e-07, 0.999991834, -7.18327664e-09, 1, -1.23605801e-07, -0.999991834, -6.68309719e-09, 0.00404609647)
        elseif teleportDropdownValue == "Fighting Arena" then
            entityLib.teleport(-262.294586, 62.7116394, -735.916199, -1, -7.62224133e-08, -0.000201582094, -7.6233647e-08, 1, 5.5719358e-08, 0.000201582094, 5.57347235e-08, -1)
            utils.fireTouchEvent(hrp, game.Workspace.EvilArea.EnterPart)
        elseif teleportDropdownValue == "Gym" then
            entityLib.teleport(-257.281738, 63.4477501, -843.258362, 0.999999464, -6.6242154e-09, 0.00105193094, 6.52111609e-09, 1, 9.80127126e-08, -0.00105193094, -9.8005799e-08, 0.999999464)
        elseif teleportDropdownValue == "Pizza Boss" then
            entityLib.teleport(-287.475769, 30.4527531, -721.746277, -0.00427152216, -8.6121041e-08, 0.99999088, 2.21573924e-08, 1, 8.6216474e-08, -0.99999088, 2.25254659e-08, -0.00427152216)
        elseif teleportDropdownValue == "Shop" then
            entityLib.teleport(-251.009491, 30.4477539, -851.509705, 0.0225389507, 7.41174511e-10, -0.999745965, 2.19171417e-10, 1, 7.46304019e-10, 0.999745965, -2.35936659e-10, 0.0225389507)
        elseif teleportDropdownValue == "Golden Apple Path" then
            entityLib.teleport(85.6087112, 29.4477024, -804.023926, -0.999134541, 1.15144616e-09, 0.0415947847, 4.49046622e-09, 1, 8.01815432e-08, -0.0415947847, 8.02989319e-08, -0.999134541)
        elseif teleportDropdownValue == "Generator" then
            entityLib.teleport(-114.484352, 30.0235462, -790.053833, -0.656062722, 0, -0.754706323, 0, 1, 0, 0.754706323, 0, -0.656062722)
        elseif teleportDropdownValue == "Boss Fight" then
            entityLib.teleport(-1328.85242, -346.249146, -810.092285, 0.00456922129, 5.69967078e-08, 0.999989569, 1.76120984e-08, 1, -5.70777772e-08, -0.999989569, 1.78727166e-08, 0.00456922129)
        end

        if teleportDropdownValue ~= "" then
            Library:Notify("You have been teleported to: " .. teleportDropdownValue .. ".", 4, notifSounds.success)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

local villianBase = teleportationGroup:AddButton({
    Text = "Villian Base",
    Func = function()
        entityLib.teleport(-233.926117, 30.4567528, -790.019897, 0.00195977557, -8.22674984e-11, -0.999998093, -2.4766762e-09, 1, -8.71213934e-11, 0.999998093, 2.47684229e-09, 0.00195977557)
        utils.fireTouchEvent(hrp, game.Workspace.InsideTouchParts.FrontDoor)
    end,
    DoubleClick = false,
    Tooltip = false
})

-- Group: Touch Transmitter Manipulation

touchInterestsGroup:AddDivider()

touchInterestsGroup:AddToggle("spoofInside", {
	Text = "Inside Spoof",
	Tooltip = "Makes the server think you are inside.",
	Default = false,

	Callback = function(state)
        if state then
            toggles.spoofOutside:SetValue(false)
            toggles.fightSpoof:SetValue(false)

            _G.insideSpoof = true
            insideSpoof()
        else
            _G.insideSpoof = false
            insideSpoof()
        end
	end
})

touchInterestsGroup:AddToggle("spoofOutside", {
	Text = "Outside Spoof",
	Tooltip = "Makes the server think you are outside.",
	Default = false,

	Callback = function(state)
        if state then
            toggles.spoofInside:SetValue(false)
            toggles.fightSpoof:SetValue(false)

            _G.outsideSpoof = true
            outsideSpoof()
        else
            _G.outsideSpoof = false
            outsideSpoof()
        end
	end
})

touchInterestsGroup:AddToggle("fightSpoof", {
	Text = "Spoof Fighting",
	Tooltip = "Makes the server think you are in the fighting arena.",
	Default = false,

	Callback = function(state)
        if state then
            toggles.spoofInside:SetValue(false)
            toggles.SpoofOutside:SetValue(false)

            _G.fightSpoof = true
            fightSpoof()
        else
            _G.fightSpoof = false
            fightSpoof()

            wait(1)

            utils.fireTouchEvent(hrp, game.Workspace.EvilArea.ExitPart2)
        end
	end
})

-- Group: Others

othersGroup:AddDivider()

local killNiggers = othersGroup:AddButton({
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

othersGroup:AddToggle("killNiggersLoop", {
	Text = "Kill Bad Guys",
	Tooltip = "Disables the black border when in dark areas of the map.",
	Default = false,

	Callback = function(state)
        _G.loopkillall = state
        loopkillall()
	end
})

-- Tab: Utility

local giveItemsGroup = tabs.util:AddLeftGroupbox("Give Objects")
local autoTrainGroup = tabs.util:AddRightGroupbox("Training")
local disablersGroup = tabs.util:AddRightGroupbox("Disablers")
local othersGroup2 = tabs.util:AddLeftGroupbox("Other")

-- Group: Give Items

giveItemsGroup:AddDivider()

giveItemsGroup:AddDropdown("itemDropdown", {
    Values = {"GoldPizza", "GoldenApple", "RainbowPizzaBox", "RainbowPizza", "GoldKey", "Bottle", "Armor", "Louise", "Lollipop", "Ladder", "MedKit", "Chips", "Cookie", "BloxyCola", "Apple", "Pizza", "ExpiredBloxyCola"},
    Default = 0,
    Multi = false,

    Text = "Item",
    Tooltip = false,

    Callback = function(value)
        giveItemDropdownValue = value
    end
})

giveItemsGroup:AddInput("giveItemAmount", {
    Default = false,
    Numeric = false,
    Finished = false,
    ClearTextOnFocus = true,

    Text = "Amount",
    Tooltip = false,

    Placeholder = "Number (####)",
    MaxLength = 4,

    Callback = function(value)
        giveAmountValue = value
    end
})

local giveItem = giveItemsGroup:AddButton({
	Text = "Give Item",
	Func = function()
        if giveItemDropdownValue == "Armor" then
            events.Vending:FireServer(3, "Armor2", "Armor", player.Name, true, 1)
            Library:Notify("You have been given 1 of Armor.", 3, notifSounds.success)
            return
        end


        for _ = 1, giveAmountValue do -- Getting the number that was inputted into the input and firing the event x times
            events.GiveTool:FireServer(giveItemDropdownValue)
        end

        if giveItemDropdownValue ~= "" and giveAmountValue ~= 0 then
            Library:Notify("You have been given " .. giveAmountValue .. " of " .. giveItemDropdownValue .. ".", 3, notifSounds.success)
        end
	end,
	DoubleClick = false,
    Tooltip = false,
})

giveItemsGroup:AddDivider()
giveItemsGroup:AddLabel("Weapons\n")

giveItemsGroup:AddDropdown("itemDropdown", {
    Values = {"Crowbar 1", "Crowbar 2", "Bat", "Pitchfork", "Hammer", "Wrench", "Broom"},
    Default = 0,
    Multi = false,

    Text = "Weapon",
    Tooltip = false,

    Callback = function(value)
        weaponDropdownValue = value
    end
})

local giveWeapon = giveItemsGroup:AddButton({
	Text = "Give Weapon",
	Func = function()
        events.Vending:FireServer(3, weaponDropdownValue, "Weapons", player.Name, 1)

        if weaponDropdownValue ~= "" then
            Library:Notify("You have been given the " .. weaponDropdownValue .. ".", 3, notifSounds.success)
        end
	end,
	DoubleClick = false,
    Tooltip = false,
})

giveItemsGroup:AddDivider()

local bestweapon = player.PlayerGui.Phone.Phone.Phone.Background.InfoScreen.WeaponInfo.TwadoWants.Text

giveItemsGroup:AddLabel("Best Weapon: " .. bestweapon)

local giveBestWeapon = giveItemsGroup:AddButton({
	Text = "Give Best Weapon",
	Func = function()
        -- checking if the player already has the best weapon

        if player.Backpack:FindFirstChild(bestweapon) or character:FindFirstChild(bestweapon) then
            Library:Notify("You already have the best weapon: " .. bestweapon, notifSounds.error)
            return
        end

        events.Vending:FireServer(3, bestweapon, "Weapons", player.Name, 1)

        -- checking if the player actually got the best weapon

        wait(0.2)

        if player.Backpack:FindFirstChild(bestweapon) or character:FindFirstChild(bestweapon) then
            Library:Notify("You have been given the best weapon: " .. bestweapon .. ".", 3, notifSounds.success)
        else
            Library:Notify("Failed to give best weapon: Best weapon wasn't found in Backpack. This is most likely due to giving the best weapon and\ngiving another weapon and results in the weapons replacing each other and bugging the weapons.", notifSounds.error)
            return
        end
	end,
	DoubleClick = false,
    Tooltip = false,
})

giveItemsGroup:AddDivider()

giveItemsGroup:AddLabel("Having more more then 1 of an item can prevent it from working. Some examples: \n • You give yourself 5 golden apples, and it will be worthless until you get down to just 1 golden apple and use that one.\n• You give yourself 100 pizza, you turn godmode on, and you get just 1 pizza permanently stuck in your inventory that you can't eat.", true)

-- Group: Training

autoTrainGroup:AddDivider()

local trainAll = autoTrainGroup:AddButton({
    Text = "Train Strength & Speed",
    Func = function()
        for _ = 1, 5 do
            events.RainbowWhatStat:FireServer("Strength")
            events.RainbowWhatStat:FireServer("Speed")
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

local trainStrength = autoTrainGroup:AddButton({
    Text = "Train Strength",
    Func = function()
        for _ = 1, 5 do
            events.RainbowWhatStat:FireServer("Strength")
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

local trainSpeed = autoTrainGroup:AddButton({
    Text = "Train Speed",
    Func = function()
        for _ = 1, 5 do
            events.RainbowWhatStat:FireServer("Speed")
        end
    end,
    DoubleClick = false,
    Tooltip = false
})


-- Group: Disablers

disablersGroup:AddDivider()

disablersGroup:AddToggle("antiIceSlip", {
	Text = "Anti Slip",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        if state then
            events:FindFirstChild("IceSlip").Parent = game:GetService("Chat")

            antiSlipEnabled = true

        else

            game:GetService("Chat"):FindFirstChild("IceSlip").Parent = events

            antiSlipEnabled = false
        end
	end
})

disablersGroup:AddLabel("Anti Slip will also protect you from anything that makes you fall/sit down such as the wave 3 brute.", true)

disablersGroup:AddToggle("antiHail", {
	Text = "Anti Hail",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        if state then
            game.Workspace:FindFirstChild("Hails").Parent = game:GetService("Chat")
        else
            game:GetService("Chat"):FindFirstChild("Hails").Parent = game.Workspace
        end
	end
})

disablersGroup:AddToggle("disableWind", {
	Text = "Disable Wind",
	Tooltip = "Disables the wind knocking you back on the golden apple path.",
	Default = false,

	Callback = function(state)
        if state then
            _G.disableWind = true
            disableWind()
        else
            _G.disableWind = false
            disableWind()
            
            for _, v in pairs(game.Workspace:GetChildren()) do
                if v.Name == "WavePart" then
                    v.CanTouch = true
                end
            end
        end
	end
})

disablersGroup:AddToggle("disableMud", {
	Text = "Disable Mud",
	Tooltip = false,
	Default = false,
    Disabled = true,

	Callback = function(state)
        if state then
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

-- Group: Other

othersGroup2:AddDivider()

local collectHiddenItems = othersGroup2:AddButton({
    Text = "Collect Hidden Items",
    Func = function()
        utils.fireAllClickEvents(game.Workspace.Hidden)
    end,
    DoubleClick = false,
    Tooltip = "Collects all the items hidden in drawers."
})

local hiddenitemslabel = othersGroup2:AddLabel("Existing Hidden Items: ", true)

local function updateHiddenItems()
    while _G.updateHiddenItems do
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
task.spawn(updateHiddenItems)

local collectOutsideItems = othersGroup2:AddButton({
    Text = "Collect Outside Items",
    Func = function()
        local origcframe = hrp.CFrame

        if #game.Workspace.OutsideParts:GetChildren() == 0 then
            Library:Notify("No more outside items.", 5, notifSounds.error)
            return
        end
        
        utils.fireAllClickEvents(game.Workspace.OutsideParts)

        wait(0.1)

        entityLib.teleport(-200.997543, 34.0999222, -790.799988, 1, -8.10623169e-05, -5.24520874e-06, 8.10623169e-05, 1, 5.24520874e-06, 5.24520874e-06, -5.24520874e-06, 1) -- teleport to entrance
        wait(0.01)
        events.TeleportMain:FireServer("Main") -- teleport to villian base
        wait(0.1)
        entityLib.teleport(origcframe) -- teleport to original cframe
    end,
    DoubleClick = false,
    Tooltip = false
})

local outsideitemslabel = othersGroup2:AddLabel("Existing Outside Items: ", true)

local function updateOutsideItems()
    while _G.updateOutsideItems do
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
task.spawn(updateOutsideItems)

local medkitHealOthers = othersGroup2:AddButton({
    Text = "MedKit Heal Others",
    Func = function()
        for _, v in pairs(game:GetService("Players"):GetPlayers()) do
            events.HealPlayer:FireServer(v)
        end
    end,
    DoubleClick = false,
    Tooltip = "Heals all other players using the medkit."
})

local healSelf = othersGroup2:AddButton({
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
    Tooltip = false
})

local healAll = othersGroup2:AddButton({
    Text = "Heal All",
    Func = function()
        events.GiveTool:FireServer("GoldenApple")

        wait(0.2)
    
        events.BackpackEvent:FireServer("Equip", player.Backpack.GoldenApple)
    
        wait(0.2)
    
        events.HealTheNoobs:FireServer()
    end,
    DoubleClick = false,
    Tooltip = false
})

othersGroup2:AddToggle("autoHealAllPlayers", {
	Text = "Auto Heal All",
	Tooltip = "Loop heals all players using the golden apple. Will only work if the golden apple is not taken.",
	Default = false,

	Callback = function(state)
        _G.autoHealAll = state
        autoHealAll()
	end
})

othersGroup2:AddToggle("autoEat", {
	Text = "Auto Eat",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        _G.autoEat = state
        autoEat()
	end
})

-- Tab: LocalPlayer

local localPlayerGroup = tabs.localPlayer:AddLeftGroupbox("LocalPlayer")
local damageGroup = tabs.localPlayer:AddRightGroupbox("Damage")

-- Group: Player

localPlayerGroup:AddDivider()

localPlayerGroup:AddToggle("playerModControlToggle", {Text = "Player Modification"})
local playerModDepBox = localPlayerGroup:AddDependencyBox();

playerModDepBox:SetupDependencies({
    {toggles.playerModControlToggle, true}
})

playerModDepBox:AddSlider("sliderWalkspeed", {
	Text = "WalkSpeed Value",
	Default = 16,
	Min = 16,
	Max = 300,
	Rounding = 0,
	Compact = false,

	Callback = function(value)
        if walkspeedEnabled then
            sliderWalkspeedValue = value
        end
	end,
	Tooltip = false
})

sliderWalkspeedValue = options.sliderWalkspeed.Value

playerModDepBox:AddSlider("jumppowerSlider", {
	Text = "JumpPower Value",
	Default = 50,
	Min = 10,
	Max = 1000,
	Rounding = 0,
	Compact = false,

	Callback = function(value)
        if jumppowerEnabled then
            jumppowerSliderValue = value
        end
	end,
	Tooltip = false
})

jumppowerSliderValue = options.jumppowerSlider.Value

playerModDepBox:AddInput("customWalkSpeedInput", {
    Default = false,
    Numeric = true,
    Finished = true,
    ClearTextOnFocus = true,

    Text = "Custom WalkSpeed Value",
    Tooltip = false,

    Placeholder = "Number (###)",
    MaxLength = 3,

    Callback = function(value)
        local textNumber = tonumber(value)

        -- Determining Limits

        if textNumber == nil then
            Library:Notify("Invalid value.", 5, notifSounds.error)
            return
        end

        if textNumber < options.sliderWalkspeed.Min then
            Library:Notify("Cannot have a value less then the minimum of " .. options.sliderWalkspeed.Min .. ".", 5, notifSounds.error)
            return
        end

        if textNumber > options.sliderWalkspeed.Max then
            Library:Notify("Cannot have a value greater then the maximum of " .. options.sliderWalkspeed.Max .. ".", 5, notifSounds.error)
            return
        end

        -- Setting the value of the walkspeed slider to the text in the input

        options.sliderWalkspeed:SetValue(value)
    end
})

playerModDepBox:AddInput("customJumpPowerInput", {
    Default = false,
    Numeric = true,
    Finished = true,
    ClearTextOnFocus = true,

    Text = "Custom JumpPower Value",
    Tooltip = false,

    Placeholder = "Number (###)",
    MaxLength = 3,

    Callback = function(value)
        local textNumber = tonumber(value)

        -- Determining Limits

        if textNumber == nil then
            Library:Notify("Invalid value.", 5, notifSounds.error)
            return
        end

        if textNumber < options.jumpPowerSlider.Min then
            Library:Notify("Cannot have a value less then the minimum of " .. options.jumpPowerSlider.Min .. ".", 5, notifSounds.error)
            return
        end

        if textNumber > options.jumpPowerSlider.Max then
            Library:Notify("Cannot have a value greater then the maximum of " .. options.jumpPowerSlider.Max .. ".", 5, notifSounds.error)
            return
        end

        -- Setting the value of the jump power slider to the text in the input

        options.jumpPowerSlider:SetValue(value)
    end
})

playerModDepBox:AddToggle("enableWalkSpeed", {
	Text = "Enable WalkSpeed",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        if state then
            walkspeedEnabled = true
            sliderWalkspeedValue = options.sliderWalkspeed -- set the slider variable to the value of the walkspeed slider to instantly apply walkspeed when enabled

            _G.updateWalkspeed = true
            updateWalkspeed()

            toggles.walkspeedExploit:SetValue(false) -- disable WalkspeedExploit to prevent overlapping
        else
            walkspeedEnabled = false

            _G.updateWalkspeed = false
            updateWalkspeed()

            entityLib.modifyPlayer("WalkSpeed", 16)
        end
	end
})

playerModDepBox:AddToggle("enableJumpPower", {
	Text = "Enable JumpPower",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        if state then
            entityLib.modifyPlayer("UseJumpPower", true)

            jumppowerEnabled = true
            jumppowerSliderValue = Options.JumpPowerSlider.Value -- set the slider variable to the value of the jump power slider to instantly apply jumppower when enabled

            _G.updatejumppower = true
            updatejumppower()
        else
            jumppowerEnabled = false

            _G.updatejumppower = false
            updatejumppower()

            entityLib.modifyPlayer("JumpPower", 50) -- reset jump power
        end
	end
})

localPlayerGroup:AddDivider()

local getValue = damageGroup:AddButton({
    Text = "get the gay fag value",
    Func = function()
        local slider = options.sliderWalkspeed
        library:Notify("walkspeed slider:\ncurrent value: " .. tostring(slider.Value) .. "\nminimum: " .. tostring(slider.Min) .. "\nmaximum: " .. tostring(slider.Max), 10, notifSounds.neutral)
    end,
    DoubleClick = false,
    Tooltip = false
})


local noclipEnabled = false
local originalCanCollideStates = {}

localPlayerGroup:AddToggle("Noclip", {
    Text = "Noclip",
    Tooltip = "Allows you to clip through walls.",
    Default = false,

    Callback = function(state)
        noclipEnabled = state
        if noclipEnabled then
            -- Enable noclip
            originalCanCollideStates = {} -- Reset the table to avoid overlaps
            game:GetService("RunService").Stepped:Connect(function()
                if noclipEnabled and game.Players.LocalPlayer.Character then
                    for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") and not originalCanCollideStates[part] then
                            originalCanCollideStates[part] = part.CanCollide -- Store original state
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            -- Disable noclip and restore original states
            if game.Players.LocalPlayer.Character then
                for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and originalCanCollideStates[part] ~= nil then
                        part.CanCollide = originalCanCollideStates[part] -- Restore original state
                    end
                end
            end
            originalCanCollideStates = {} -- Clear stored states
        end
    end
})

-- Group: Damage

damageGroup:AddDivider()

damageGroup:AddInput("damageAmount", {
    Default = false,
    Numeric = true,
    Finished = false,
    ClearTextOnFocus = true,

    Text = "Damage Amount",
    Tooltip = false,

    Placeholder = "Number (###)",
    MaxLength = 3,

    Callback = function(value)
        damageAmountValue = value
    end
})

local damage = damageGroup:AddButton({
    Text = "Damage",
    Func = function()
        if damageAmountValue == 0 or damageAmountValue == nil then
            Library:Notify("Invalid damage amount. Please enter a valid number.", 4, notifSounds.error)
        else
            events.Energy:FireServer(-damageAmountValue, false, false)
        end
    end,
    DoubleClick = true,
    Tooltip = false
})

-- Tab: Endings

local secretEndingGroup = tabs.endings:AddLeftGroupbox("Secret Ending")
local evilEndingGroup = tabs.endings:AddRightGroupbox("Evil Ending")
local originEnding = tabs.endings:AddLeftGroupbox("Origin Ending")

-- Group: Secret Ending

secretEndingGroup:AddDivider()

local completeSecretEnding = secretEndingGroup:AddButton({
    Text = "Unlock Secret Ending",
    Func = function()
        local origcframe = hrp.CFrame

        Library:Notify("Knocked down tree.", 1, notifSounds.neutral)

        events.LarryEndingEvent:FireServer("TreeFelled") -- getting the gold crowbar

        wait(1.5)

        events.LarryEndingEvent:FireServer("CrowbarCollected") -- collecting crowbar that fell from the tree

        Library:Notify("Obtained gold crowbar.", 1, notifSounds.neutral)
        
        events.PunchableQuest:FireServer("Hit") -- hitting the boy

        wait(0.2)

        entityLib.teleport(-82.0809555, 29.4477024, -914.276917, -0.343557715, 7.47457136e-08, 0.939131558, -3.08562349e-08, 1, -9.08782312e-08, -0.939131558, -6.01999801e-08, -0.343557715) -- collecting the hat

        Library:Notify("Obtained Scary Larry hat.", 1, notifSounds.neutral)

        events.LarryEndingEvent:FireServer("MaskCollected") -- getting the mask

        Library:Notify("Obtained Scary Larry mask.", 1, notifSounds.neutral)

        -- Teleporting back to the base

        wait(0.8)

        entityLib.teleportToCFrame(origcframe) -- teleport back to original cframe

        Library:Notify("Successfully Finished Auto Secret Ending.", 3, notifSounds.success)
    end,
    DoubleClick = false,
    Tooltip = false
})

-- Group: Evil Ending

evilEndingGroup:AddDivider()

evilEndingGroup:AddLabel("First unlock all NPCs in the Miscellaneous tab and the Wave 3 Brute should drop it's crowbar, then pick up it by clicking on it and keep in mind it requires max strength.", true)

-- Group: Origin Ending

originEnding:AddDivider()

local collectOriginEndingPapers = originEnding:AddButton({
    Text = "Collect Papers",
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
    Tooltip = false
})

originEnding:AddLabel("Memory I - School", true)

originEnding:AddToggle("larryESP", {
	Text = "Larry ESP",
	Tooltip = false,
	Default = false,

	Callback = function(state)
        local originending

        -- Checking for origin ending

        if game.Workspace:FindFirstChild("Gym") then -- use the 'Hiding' value inside the local player as another condition
            originending = true
        else
            originending = false
        end

        if state then

            if originending then
                for _, v in pairs(game.Workspace:GetChildren()) do
                    if v.Name == "LarryBoss" and v:IsA("Model") then
                        local larryESP = Instance.new("Highlight", v)
        
                        larryESP.Name = "_CelestialLarryESP"
                        larryESP.Adornee = nil
                        larryESP.FillColor = Color3.new(255, 0, 0)
                        larryESP.FillTransparency = 0.5
                        larryESP.OutlineColor = Color3.new(255, 255, 255)
                        larryESP.OutlineTransparency = 0
                    end
                end
            else
                Library:Notify("Origin Ending not found.", 5, notifSounds.error)
                toggles.larryESP:SetValue(false)
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

originEnding:AddToggle("cardboardBoxESP", {
	Text = "Cardboard Box ESP",
	Tooltip = false,
	Default = false,

	Callback = function(state)
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
                Library:Notify("Origin Ending not found.", 5, notifSounds.error)
                toggles.CardboardBoxESP:SetValue(false)
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

originEnding:AddLabel("Memory II - Gym", true)

local roseTeleport = originEnding:AddButton({
    Text = "Teleport to Rose",
    Func = function()
        local originending

        if game.Workspace:FindFirstChild("Gym") then
            originending = true
        else
            originending = false
        end

        if originending then
            entityLib.partTeleport(game.Workspace.Gym.Roses.Rose.Stem)
        else
            Library:Notify("Origin Ending not found.", 5, notifSounds.error)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

local safeSpotTeleport = originEnding:AddButton({
    Text = "Teleport to Safe Spot",
    Func = function()
        local originending

        if game.Workspace:FindFirstChild("Gym") then
            originending = true
        else
            originending = false
        end

        if originending then
            entityLib.teleport(498.540649, 265.847321, 701.331665, 0.999958396, 1.74917014e-09, -0.00912014209, -1.50502355e-09, 1, 2.67769042e-08, 0.00912014209, -2.67620646e-08, 0.999958396)
        else
            Library:Notify("Origin Ending not found.", 5, notifSounds.error)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

originEnding:AddLabel("Memory III - Obby", true)

local CompleteEndgameObby = originEnding:AddButton({
    Text = "Complete Obby",
    Func = function()
        local originending

        if game.Workspace:FindFirstChild("Obby") then
            originending = true
        else
            originending = false
        end

        if originending then
            entityLib.partTeleport(game.Workspace.Obby.CheckpointPart3)
        else
            Library:Notify("Origin Ending not found.", 5, notifSounds.error)
        end
    end,
    DoubleClick = false,
    Tooltip = false
})

-- Tab: Misc

local miscGroup = tabs.misc:AddLeftGroupbox("Miscellaneous")
local npcGroup = tabs.misc:AddRightGroupbox("NPCs")

-- Group: Miscellaneous

miscGroup:AddDivider()

local TeleportToLobby = miscGroup:AddButton({
    Text = "Lobby",
    Func = function()
        utils.gameTeleport(13864661000)
    end,
    DoubleClick = true,
    Tooltip = false,
})

local IceSlip = miscGroup:AddButton({
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

local BreakBarricades = miscGroup:AddButton({
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

-- Group: NPCs

npcGroup:AddDivider()

local UnlockAllNPCs = npcGroup:AddButton({
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

npcGroup:AddDivider()

-- Uncle Pete



npcGroup:AddLabel("Uncle Pete")

local UnlockPete = npcGroup:AddButton({
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

local TriggerQuest = npcGroup:AddButton({
    Text = "Trigger Quest",
    Func = function()
        utils.fireClickEvent(game:GetService("Workspace").UnclePete)
    end,
    DoubleClick = false,
    Tooltip = false,
})


-- Detective

npcGroup:AddDivider()

npcGroup:AddLabel("Detective")

local UnlockDetective = npcGroup:AddButton({
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

local TeleportToDetectiveRoom = npcGroup:AddButton({
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

npcGroup:AddDivider()

npcGroup:AddLabel("Twado")

local UnlockTwado = npcGroup:AddButton({
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
saveManager:SetFolder("Celestial ScriptHub/Break In 2")
saveManager:SetSubFolder("Game")

saveManager:IgnoreThemeSettings()
saveManager:SetIgnoreIndexes({"MenuKeybind"})
saveManager:BuildConfigSection(tabs["UI Settings"])
themeManager:ApplyToTab(tabs["UI Settings"])

saveManager:LoadAutoloadConfig()

_G.script_key = nil