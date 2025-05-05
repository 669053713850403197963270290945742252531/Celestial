repeat task.wait(0.1) until game:IsLoaded()

local repo = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/LinoriaLib/main/"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/757788428949485651495849884358443235871/Corrade-Private/refs/heads/main/Utils.lua"))()
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/757788428949485651495849884358443235871/Corrade-Private/refs/heads/main/Corrade%20Private%20Auth.lua"))()
        
local Library = loadstring(game:HttpGet(repo  ..  "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo  ..  "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo  ..  "addons/SaveManager.lua"))()

local player = game:GetService("Players").LocalPlayer
local humrootpart = player.Character:FindFirstChild("HumanoidRootPart")
local humanoid = player.Character:FindFirstChild("Humanoid")
local getgamename = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local remoteEvents = game:GetService("ReplicatedStorage")["Remote Events"]
local remoteFunctions = game:GetService("ReplicatedStorage")["Remote Functions"]
local camera = game:GetService("Workspace").Camera

local Window = Library:CreateWindow({
    Title = "Celestial | " .. getgamename .. " - " .. auth.fetchAuthInfo("UserIdentifer"),
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Module Variables

local regularlocationdropdownvalue = ""
local coderevealmethoddropdownvalue = ""
local weapondropdownvalue = ""
local viewplayerdropdownvalue = ""
local isviewing = false
local specialweapondropdownvalue

-- Loop Values

_G.removeink = true
_G.removebeartraps = true
_G.instantpap = true
_G.removefog = true
_G.autoreload = true
_G.doorpromptreach = true
_G.disablemorphglow = true
_G.speedexploit = true
_G.disablelightning = true
_G.disablethunder = true
_G.disablemusic = true
_G.disableallsounds = true

-- Loop Functions

function removeink()
    while _G.removeink do
        for _, v in pairs(player.PlayerGui:GetChildren()) do
            if v.Name == "Ink" and v:IsA("ScreenGui") then
                v.Enabled = false
            end
        end

        wait()
    end
end

function removebeartraps()
    while _G.removebeartraps do
        for _, v in pairs(game.Workspace:GetChildren()) do
            if v.Name == "BearTrap" and v:IsA("BasePart") then
                v:Destroy()
            end
        end

        wait(1)
    end
end

function instantpap()
    while _G.instantpap do
        remoteEvents.PAPFinished:FireServer()

        wait()
    end
end

function removefog()
    while _G.removefog do
        game.Lighting.FogEnd = math.huge

        wait(1)
    end
end

function autoreload()
    while _G.autoreload do
        local humrootpart = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if not humrootpart then
            Library:Notify("No humanoid root part was found.", 8)
            return
        end

        utils.fireTouchEvent(humrootpart, game:GetService("Workspace").AREA51.PlantRoom["Box of Shells"].Box)

        wait()
    end
end

function doorpromptreach()
    while _G.doorpromptreach do
        for _, v in pairs(game.Workspace.Doors:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                v.MaxActivationDistance = 32
            end
        end

        wait()
    end
end

function disablemorphglow()
    while _G.disablemorphglow do
        for _, v in pairs(game.Workspace["Characters to kill"]:GetDescendants()) do
            if v:IsA("PointLight") then
                v.Enabled = false
            end
        end

        wait(1)
    end
end

function speedexploit()
    while _G.speedexploit do
        local humanoid = game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid")

        if not humanoid then
            wait(0.6)
        end

        humanoid.WalkSpeed = 25

        wait()
    end
end


-- Disable Sounds

function disablelightning()
    while _G.disablelightning do
        utils.updateAudio(game.Workspace, "rbxasset://sounds/HalloweenLightning.wav", false)

        wait()
    end
end

function disablethunder()
    while _G.disablethunder do
        utils.updateAudio(game.Workspace, "rbxasset://sounds/HalloweenThunder.wav", false)

        wait()
    end
end

function disablemusic()
    while _G.disablemusic do
        for _, v in pairs(game.Workspace:GetChildren()) do
            if v.Name == "Music" and v:IsA("Sound") then
                v.Playing = false
            end
        end

        wait()
    end
end

function disableallsounds()
    while _G.disableallsounds do
        for _, v in pairs(game.Workspace:GetChildren()) do
            if v.Name == "LightningSound" or v.Name == "ThunderSound" or v.Name == "Music" and v:IsA("Sound") then
                v.Playing = false
            end
        end

        wait()
    end
end

local function hasItem(itemName)
    for _, v in pairs(game:GetService("Players").LocalPlayer.Backpack:GetChildren()) do
        if v.Name == itemName and v:IsA("Tool") then
            return true
        end
    end

    return false
end

-- Miscellaneous

local requirementsModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.LocalAnimations["Classic area"].Teleportation.PackAPunch["Classic mode"].Requirements)

local papRequirements = {
    M14 = requirementsModule.M14,
    RayGun = requirementsModule.RayGun,
    MP5k = requirementsModule.MP5k,
    SVD = requirementsModule.SVD,
    R870 = requirementsModule.R870,
    ["M16A2/M203"] = requirementsModule["M16A2/M203"],
    M1911 = requirementsModule.M1911,
    G36C = requirementsModule.G36C,
    ["Desert Eagle"] = requirementsModule["Desert Eagle"],
    Crossbow = requirementsModule.Crossbow,
    AWP = requirementsModule.AWP,
    M4A1 = requirementsModule.M4A1,
    ["AK-47"] = requirementsModule["AK-47"],
    ["AN-94"] = requirementsModule["AN-94"],
    ["DB Shotgun"] = requirementsModule["DB Shotgun"],
    M1014 = requirementsModule.M1014,
    P90 = requirementsModule.P90,
    ["Colt Anaconda"] = requirementsModule["Colt Anaconda"],
    Flamethrower = requirementsModule.Flamethrower,
    MG42 = requirementsModule.MG42,
    FreezeGun = requirementsModule.FreezeGun,
}

local Tabs = {
    Information = Window:AddTab("Information"),
    Main = Window:AddTab("Main"),
    World = Window:AddTab("World"),
    Weapons = Window:AddTab("Weapons"),
    UI = Window:AddTab("UI"),
    Misc = Window:AddTab("Misc"),
    ["UI Settings"] = Window:AddTab("Configs"),
}

if auth.fetchConfig("Notify Execution") then
    Library:Notify("Successfully logged in as " .. auth.fetchAuthInfo("UserIdentifer") .. ": " .. auth.fetchAuthInfo("Rank"), 6)
else
    Library:Notify("Celestial has loaded / " .. utils.getTime(false), 6)
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

WhitelistDetailsGroup:AddLabel("Authorized Username: " .. auth.fetchAuthInfo("UserIdentifer"))
WhitelistDetailsGroup:AddLabel("Authorized: " .. tostring(auth.fetchAuth()))
WhitelistDetailsGroup:AddLabel("Notify Execution: " .. tostring(auth.fetchConfig("Notify Execution")))
WhitelistDetailsGroup:AddLabel("Log Executions: " .. tostring(auth.fetchConfig("Log Execution")))
WhitelistDetailsGroup:AddLabel("Log Breaches: " .. tostring(auth.fetchConfig("Log Breach")))

-- Main Tab

local TeleportGroup = Tabs.Main:AddLeftGroupbox("Teleport")
local EnergyDrinkGroup = Tabs.Main:AddRightGroupbox("Energy Drink")
local SoundsGroup = Tabs.Main:AddLeftGroupbox("Sounds")
local OtherGroup2 = Tabs.Main:AddRightGroupbox("Other")

-- Teleport Group

TeleportGroup:AddDivider()

TeleportGroup:AddDropdown("RegularLocationsDropdown", {
    Values = {"Surface", "Area 51", "Alien", "Alien Code Input", "Pack A Punch Machine", "Obtain Armor", "Ammo Box", "Zombie Morpher", "Radioactive Zone"},
    Default = 0,
    Multi = false,

    Text = "Regular Locations",
    Tooltip = false,

    Callback = function(DropdownValue)
        regularlocationdropdownvalue = DropdownValue
    end
})

local TeleportToRegularLocation = TeleportGroup:AddButton({
    Text = "Teleport",
    Func = function()
        if regularlocationdropdownvalue == "" then -- check if no perk is selected
            Library:Notify("Please select an option from the regular locations dropdown above", 6)
            return
        end
    
        if regularlocationdropdownvalue == "Surface" then
            utils.teleport(326.087067, 511.699921, 392.975769, 0.999967098, 0, 0.00810976978, 0, 1, 0, -0.00810976978, 0,
                0.999967098)
        elseif regularlocationdropdownvalue == "Area 51" then
            utils.teleport(327.146332, 313.499908, 369.922913, 0.0146765877, 0, 0.999892294, 0, 1, 0, -0.999892294, 0,
                0.0146765877)
        elseif regularlocationdropdownvalue == "Alien" then
            utils.teleport(237.99556, 337.799927, 472.399994, 4.34290196e-05, 1.17440393e-07, -1, 3.82457843e-09, 1,
                1.17440564e-07, 1, -3.8296788e-09, 4.34290196e-05)
        elseif regularlocationdropdownvalue == "Alien Code Input" then
            utils.teleport(137.72377, 333.499939, 525.566956, -0.999551415, 4.71232431e-09, 0.0299497657, 4.37261027e-09,
                1, -1.14082894e-08, -0.0299497657, -1.12722134e-08, -0.999551415)
        elseif regularlocationdropdownvalue == "Pack A Punch Machine" then
            utils.partTeleport(game.Workspace.PACKAPUNCH.GUI)
        elseif regularlocationdropdownvalue == "Obtain Armor" then
            utils.teleport(-167.243805, 293.500214, 316.368713, -0.0163577069, -1.04670743e-08, 0.999866188,
            6.23807708e-08, 1, 1.14890186e-08, -0.999866188, 6.25603604e-08, -0.0163577069)
        elseif regularlocationdropdownvalue == "Ammo Box" then
            utils.teleport(184.26889, 314.102753, 437.041473, -0.999995649, 5.072752e-09, 0.00294528855, 5.24779331e-09,
                1, 5.94231793e-08, -0.00294528855, 5.94383778e-08, -0.999995649)
        elseif regularlocationdropdownvalue == "Zombie Morpher" then
            utils.teleport(402.278748, 512.499817, 399.379395, 0.999998093, -4.97486283e-08, 0.00196264265,
                4.98476567e-08, 1, -5.0407067e-08, -0.00196264265, 5.05048021e-08, 0.999998093)
        elseif regularlocationdropdownvalue == "Radioactive Zone" then
            utils.teleport(140.615601, 313.499969, 435.841766, -0.9997648, 3.54234375e-09, 0.0216868054, 6.39699493e-09, 1, 1.31561421e-07, -0.0216868054, 1.31669211e-07, -0.9997648)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local SpawnKillTeleport = TeleportGroup:AddButton({
    Text = "Spawn Kill Teleport",
    Func = function()
        utils.teleport(-52.6837997, 313.500305, 292.096558, 1, 1.49757151e-09, -4.17306546e-05, -1.49720991e-09, 1, 8.6659675e-09, 4.17306546e-05, -8.66590533e-09, 1)
    end,
    DoubleClick = false,
    Tooltip = false,
})

-- Energy Drink Group

EnergyDrinkGroup:AddDivider()

local DrinkEnergy = EnergyDrinkGroup:AddButton({
    Text = "Drink Energy Drink",
    Func = function()
        local energydrink = player.Backpack:FindFirstChild("Energy") or player.Character:FindFirstChild("Energy") -- Checking if the energy drink is inside the players backpack or character and drinking it

        if not energydrink then
            Library:Notify("Energy Drink not found.", 7)
            return
        end
        
        if energydrink.Ammo.Value == 0 then -- if your energy drink runs out of charges
            Library:Notify("No more charges left.", 6)
            return
        end

        energydrink.Drank:FireServer()
    end,
    DoubleClick = false,
    Tooltip = false,
})

local DrinkAllEnergyDrink = EnergyDrinkGroup:AddButton({
    Text = "Drink All",
    Func = function()
        local energydrink = player.Backpack:FindFirstChild("Energy") or player.Character:FindFirstChild("Energy") -- Checking if the energy drink is inside the players backpack or character and drinking it

        if not energydrink then
            Library:Notify("Energy Drink not found.", 7)
            return
        end

        if energydrink.Ammo.Value == 0 then -- if your energy drink runs out of charges
            Library:Notify("No more charges left.", 6)
            return
        end

        for _ = 1, energydrink.Ammo.Value do
            energydrink.Drank:FireServer()
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local RefillDrink = EnergyDrinkGroup:AddButton({
    Text = "Refill Energy Drink",
    Func = function()
        local energydrink = player.Backpack:FindFirstChild("Energy") or player.Character:FindFirstChild("Energy") -- Checking if the energy drink is inside the players backpack or character and drinking it
        
        if not energydrink then
            Library:Notify("Energy Drink not found.", 7)
            return
        end

        local oldcframe = humrootpart.CFrame -- store the old cframe
        
        wait(0.01) -- wait 0.01 and teleport to the coffee machine
        
        utils.teleport(178.023087, 333.499908, 597.890442, 0.0192538705, -8.12836092e-08, 0.99981463, 1.48566126e-09, 1, 8.12700662e-08, -0.99981463, -7.93774491e-11, 0.0192538705)
        
        wait(0.18) -- wait 0.17 and fire the prox prompt
        
        utils.fireProxPrompt(game.Workspace.AREA51.CafeRoom["Coffee Machine"].Energy.Head)
        
        wait(0.01) -- wait 0.4 for the teleport to finish
        
        utils.teleportToCFrame(oldcframe) -- teleport to the old cframe
    end,
    DoubleClick = false,
    Tooltip = false,
})

-- Sounds Group

SoundsGroup:AddDivider()

SoundsGroup:AddToggle("DisableAllSounds", {
    Text = "Disable All Sounds",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        _G.disableallsounds = Value
        disableallsounds()
    end
})

SoundsGroup:AddToggle("DisableLightning", {
    Text = "Disable Lightning",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        _G.disablelightning = Value
        disablelightning()
    end
})

SoundsGroup:AddToggle("DisableThunder", {
    Text = "Disable Thunder",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        _G.disablethunder = Value
        disablethunder()
    end
})

SoundsGroup:AddToggle("DisableMusic", {
    Text = "Disable Music",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        _G.disablemusic = Value
        disablemusic()
    end
})

-- Others Group

OtherGroup2:AddDivider()

OtherGroup2:AddToggle("SpeedExploit", {
    Text = "Speed Exploit",
    Default = false,
    Tooltip = "Spoofs the speed boost gamepass.",

    Callback = function(Value)
        if Value then
            _G.speedexploit = true
            speedexploit()
        else

            _G.speedexploit = false

            wait(0.3)

            humanoid.WalkSpeed = 20
        end
    end
})

-- World Tab

local WorldGroup = Tabs.World:AddLeftGroupbox("World")
local UnlockAlienGroup = Tabs.World:AddRightGroupbox("Unlock Alien")

WorldGroup:AddDivider()

local originalfogcolor, originalfogend, originalfogstart

WorldGroup:AddToggle("RemoveFog", {
    Text = "Remove Fog",
    Default = false,
    Tooltip = "Removes the white fog for easier visibility.",

    Callback = function(Value)
        if Value then
            -- store original fog settings

            originalfogcolor = game.Lighting.FogColor
            originalfogend = game.Lighting.FogEnd
            originalfogstart = game.Lighting.FogStart
    
            _G.removefog = true
            removefog()
            
        else

            _G.removefog = false
            
            -- Restore original fog settings if they were stored

            if originalfogcolor then
                game.Lighting.FogColor = originalfogcolor
            end
    
            if originalfogend then
                game.Lighting.FogEnd = originalfogend
            end
    
            if originalfogstart then
                game.Lighting.FogStart = originalfogstart
            end
        end
    end
})

WorldGroup:AddToggle("DoorNoclip", {
    Text = "Door Noclip",
    Default = false,
    Tooltip = "Allows clipping through doors.",

    Callback = function(Value)
        if Value then
            -- making the door not collidable
        
            for _, v in pairs(game.Workspace:GetDescendants()) do
                if v.Name == "Door" and v:IsA("Part") then
                    v.CanCollide = false
                end
            end
        
            -- changing the transparency of the doors
        
            for _, v in pairs(game.Workspace.Doors:GetDescendants()) do
                if v.Name == "Door" and v:IsA("Part") or v:IsA("Texture") or v:IsA("Decal") then
                    v.Transparency = 0.8
                end
            end
            
        else

            -- making the door collidable

            for _, v in pairs(game.Workspace:GetDescendants()) do
                if v.Name == "Door" and v:IsA("Part") then
                    v.CanCollide = true
                end
            end

            -- restoring the transparency of the doors

            for _, v in pairs(game.Workspace.Doors:GetDescendants()) do
                if v.Name == "Door" and v:IsA("Part") or v:IsA("Texture") or v:IsA("Decal") then
                    v.Transparency = 0
                end
            end
        end
    end
})

WorldGroup:AddToggle("DisableCactuses", {
    Text = "Disable Cactuses",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            for _, v in pairs(game.Workspace.AREA51.Outside.Cactus:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanTouch = false
                end
            end

        else

            for _, v in pairs(game.Workspace.AREA51.Outside.Cactus:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanTouch = true
                end
            end
        end
    end
})

WorldGroup:AddToggle("RemoveBearTraps", {
    Text = "Remove Bear Traps",
    Default = false,
    Tooltip = "Removes the bear traps placed by Granny.",

    Callback = function(Value)
        _G.removebeartraps = Value
        removebeartraps()
    end
})

WorldGroup:AddToggle("RemoveRadioactiveZone", {
    Text = "Remove Radioactive Zone",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            -- Removing the radioactive zone

            for _, v in pairs(game.Workspace.AREA51.RadioactiveArea.Floor1:GetChildren()) do
                if v.Name == "Barrier" and v:IsA("Model") then
                    v.Parent = game.Lighting
                end
            end

            for _, v in pairs(game.Workspace.AREA51.RadioactiveArea:GetChildren()) do
                if v.Name == "RadioactiveDrop" and v:IsA("Model") then
                    v.Parent = game.Lighting
                end
            end
    
            for _, v in pairs(game.Workspace.AREA51.RadioactiveArea.Floor1:GetChildren()) do
                if v.Name == "Entrance" then
                    v.Parent = game.Lighting
                end
            end

            for _, v in pairs(game.Workspace.AREA51.RadioactiveArea.Floor1:GetChildren()) do
                if v.Name == "Dirt" and v:IsA("Model") then
                    v.Parent = game.Lighting
                end
            end

            -- Disabling radioactive zone damage

            for _, v in pairs(game.Workspace.AREA51.RadioactiveArea:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanTouch = false
                end
            end

        else

            -- Restoring the radioactive zone

            for _, v in pairs(game.Lighting:GetDescendants()) do
                if v.Name == "Barrier" and v:IsA("Model") or v.Name == "Entrance" or v.Name == "Dirt" then
                    v.Parent = game.Workspace.AREA51.RadioactiveArea.Floor1
                end
            end

            for _, v in pairs(game.Lighting:GetDescendants()) do
                if v.Name == "RadioactiveDrop" then
                    v.Parent = game.Workspace.AREA51.RadioactiveArea
                end
            end

            -- Enabling radioactive zone damage

            for _, v in pairs(game.Workspace.AREA51.RadioactiveArea:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanTouch = true
                end
            end
        end
    end
})

--[[

WorldGroup:AddToggle("RemoveRadioactiveZone", {
    Text = "Remove Radioactive Zone",
    Default = false,
    Tooltip = "Removes everything in the radioactive zone and the damage.",

    Callback = function(Value)
        if Value then
            for _, v in pairs(game.Workspace.AREA51.RadioactiveArea.Floor1:GetDescendants()) do
                if v.Name == "Part" then
                    v.Parent = game.Lighting
                end
            end

            for _, v in pairs(game.Workspace.AREA51.RadioactiveArea:GetDescendants()) do
                if v.Name == "RadioactiveDrop" then
                    v.Parent = game.Lighting
                end
            end
    
            for _, v in pairs(game.Workspace.AREA51.RadioactiveArea:GetDescendants()) do
                if v.Name == "Entrance" then
                    v.Parent = game.Lighting
                end
            end

        else

            for _, v in pairs(game.Lighting:GetDescendants()) do
                if v.Name == "Part" then
                    v.Parent = game.Workspace.AREA51.RadioactiveArea.Floor1.Barrier
                end
            end

            for _, v in pairs(game.Lighting:GetDescendants()) do
                if v.Name == "RadioactiveDrop" or v.Name == "Entrance" then
                    v.Parent = game.Workspace.AREA51.RadioactiveArea
                end
            end
        end
    end
})

]]

-- Unlock Alien Group

UnlockAlienGroup:AddDivider()

UnlockAlienGroup:AddLabel("Code: " .. game.Workspace.AREA51.CodeModel.Code.Value, true)

UnlockAlienGroup:AddToggle("ViewAlienCode", {
    Text = "View Code",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            if humanoid and humanoid.Health > 0 then
                camera.CameraSubject = game.Workspace.AREA51.CodeModel
            else
                Library:Notify("Failed to View: Cannot view a object if you are dead.", 6)
            end

        else

            if humanoid and humanoid.Health > 0 then
                camera.CameraSubject = humanoid
            else
                Library:Notify("Failed to Unview: Cannot unview a object if you are dead.", 6)
            end
        end
    end
})

UnlockAlienGroup:AddDropdown("CodeRevealMethodDropdown", {
    Values = {"Announce", "Silent"},
    Default = 0,
    Multi = false,

    Text = "Code Reveal Method",
    Tooltip = false,

    Callback = function(DropdownValue)
        coderevealmethoddropdownvalue = DropdownValue
    end
})

local RevealCode = UnlockAlienGroup:AddButton({
    Text = "Reveal Code",
    Func = function()
        local code = game.Workspace.AREA51.CodeModel.Code.Value

        if coderevealmethoddropdownvalue ~= "" then -- if the dropdown value equals to something
            
            if coderevealmethoddropdownvalue == "Announce" then
                replicatedstorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("The alien code is: " .. code, "All")
            elseif coderevealmethoddropdownvalue == "Silent" then
                Library:Notify("The alien code is: " .. code .. ".", 16)
            end

        else -- if the dropdown value equals to nothing

            Library:Notify("Alien Code Failed. Please select an option from the aline code method dropdown above.", 6)
        end
    end,
    DoubleClick = false,
    Tooltip = "Annonce - sends a message in chat, telling everyone the code\n\nSilent - onlys notifys you of the code."
})

local TeleportToAlienCodeInput = UnlockAlienGroup:AddButton({
    Text = "Teleport to Code Input",
    Func = function()
        utils.teleport(137.72377, 333.499939, 525.566956, -0.999551415, 4.71232431e-09, 0.0299497657, 4.37261027e-09, 1, -1.14082894e-08, -0.0299497657, -1.12722134e-08, -0.999551415)
    end,
    DoubleClick = false,
    Tooltip = false,
})

local TeleportToAlienDoor = UnlockAlienGroup:AddButton({
    Text = "Teleport to Door",
    Func = function()
        utils.teleport(226.598221, 333.499939, 472.223358, -0.0127793094, -9.48181196e-08, -0.999918342, 8.56549853e-09, 1, -9.49353378e-08, 0.999918342, -9.77800685e-09, -0.0127793094)
    end,
    DoubleClick = false,
    Tooltip = false,
})


-- Weapons Tab

local WeaponsGroup = Tabs.Weapons:AddLeftGroupbox("Weapons")
local PackaPunchGroup = Tabs.Weapons:AddRightGroupbox("Pack a Punch Requirements", true)
local OtherGroup = Tabs.Weapons:AddLeftGroupbox("Other")

-- Weapons Group

WeaponsGroup:AddDivider()

local weaponNames = {}

for _, weapon in ipairs(game.Workspace.Weapons:GetChildren()) do
    table.insert(weaponNames, weapon.Name)
end

WeaponsGroup:AddDropdown("WeaponDropdown", {
    Values = weaponNames,
    Default = 0,
    Multi = false,

    Text = "Weapon",
    Tooltip = false,

    Callback = function(DropdownValue)
        weapondropdownvalue = DropdownValue
    end
})

WeaponsGroup:AddDropdown("SpecialWeaponDropdown", {
    Values = {"Crossbow", "MG42", "FreezeGun"},
    Default = 0,
    Multi = false,

    Text = "Special Weapon",
    Tooltip = false,

    Callback = function(DropdownValue)
        specialweapondropdownvalue = DropdownValue
    end
})

local TeleportToWeapon = WeaponsGroup:AddButton({
    Text = "Teleport to Weapon",
    Func = function()
        if weapondropdownvalue == "" then
            Library:Notify("Invalid Value. Please select an option from the weapon dropdown above.", 4)
        else

            utils.partTeleport(game.Workspace.Weapons[weapondropdownvalue].Hitbox)

            if weapondropdownvalue ~= "" then -- if the dropdown value equals to something
                Library:Notify("You have been teleported to: " .. weapondropdownvalue .. ".", 3)
        
            else -- if the dropdown value equals to nothing
        
                Library:Notify("Teleport Failed. Please select an option from the weapon dropdown above.", 6)
        
            end
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local GiveWeapon = WeaponsGroup:AddButton({
    Text = "Give Weapon",
    Func = function()
        local humrootpart = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if not humrootpart then
            return
        end

        if hasItem(weapondropdownvalue) then
            Library:Notify(weapondropdownvalue .. " already found in your inventory.", 6)
            return
        end

        if weapondropdownvalue == "" then
            Library:Notify("Invalid Value. Please select a option from the weapon dropdown.", 4)
        else
            utils.fireTouchEvent(humrootpart, game.Workspace.Weapons[weapondropdownvalue].Hitbox)

            if not hasItem(weapondropdownvalue) then
                Library:Notify("You have been given: " .. weapondropdownvalue .. ".", 3)
            end
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

WeaponsGroup:AddDivider()

local PAPWeapon = WeaponsGroup:AddButton({
    Text = "Pack A Punch Weapon",
    Func = function()
        if weapondropdownvalue == "" then
            Library:Notify("Invalid Value. Please select an option from the weapon dropdown.", 4)
        else
            local requiredKills = papRequirements[weapondropdownvalue]
            local playerKills = player.leaderstats["Killers Killed"].Value

            if requiredKills > playerKills then
                local killsNeeded = math.max(0, requiredKills - playerKills)
                Library:Notify("Not enough kills to pack a punch the " .. weapondropdownvalue .. ". Try again when you obtain " .. killsNeeded .. " more kills.", 8)
                return
            end

            warn("Main function is currently disabled.")
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local PAPSpecialWeapon = WeaponsGroup:AddButton({
    Text = "Pack A Punch Special Weapon",
    Func = function()
        if specialweapondropdownvalue == "" then
            Library:Notify("Invalid Value. Please select an option from the weapon dropdown.", 4)
        else
            local requiredKills = papRequirements[specialweapondropdownvalue]
            local playerKills = player.leaderstats["Killers Killed"].Value

            if requiredKills > playerKills then
                local killsNeeded = math.max(0, requiredKills - playerKills)
                Library:Notify("Not enough kills to pack a punch the " .. specialweapondropdownvalue .. ". Try again when you obtain " .. killsNeeded .. " more kills.", 8)
                return
            end

            
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local PAPHeldWeapon = WeaponsGroup:AddButton({
    Text = "Pack A Punch Held Weapon",
    Func = function()
        local character = player.Character
    
        for _, v in pairs(character:GetChildren()) do
            if v:IsA("Tool") then
                local requiredKills = papRequirements[v.Name]
                local playerKills = player.leaderstats["Killers Killed"].Value

                if requiredKills > playerKills then
                    local killsNeeded = math.max(0, requiredKills - playerKills)
                    Library:Notify("Not enough kills to pack a punch the " .. v.Name .. ". Try again when you obtain " .. killsNeeded .. " more kills.", 8)
                    return
                end

                -- if the player is holding any of the tools mentioned above then pack a punch the weapon being held
    
                remoteFunctions["PAP Weapon"]:InvokeServer(v.Name)
                remoteEvents.PAPFinished:FireServer()
            end
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

WeaponsGroup:AddDivider()

local GiveAllWeapons = WeaponsGroup:AddButton({
    Text = "Give All Weapons",
    Func = function()
        local humrootpart = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        utils.fireAllTouchEvents(humrootpart, game.Workspace.Weapons)
    end,
    DoubleClick = false,
    Tooltip = false,
})

local PAPAllWeapons = WeaponsGroup:AddButton({
    Text = "Pack A Punch All Weapons",
    Func = function()
        for _ = 1, 3 do


            for i, v in pairs(player.Backpack:GetChildren()) do -- getting all the players weapons
                if v:IsA("Tool") then -- Check if the item is a tool
                    remoteFunctions["PAP Weapon"]:InvokeServer(v.Name)
                    remoteEvents.PAPFinished:FireServer()
                end
            end
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

-- Pack a Punch Group

PackaPunchGroup:AddDivider()

PackaPunchGroup:AddLabel("M14: " .. papRequirements.M14 .. " Kills")
PackaPunchGroup:AddLabel("RayGun: " .. papRequirements.RayGun .. " Kills")
PackaPunchGroup:AddLabel("MP5k: " .. papRequirements.MP5k .. " Kills")
PackaPunchGroup:AddLabel("SVD: " .. papRequirements.SVD .. " Kills")
PackaPunchGroup:AddLabel("R870: " .. papRequirements.R870 .. " Kills")
PackaPunchGroup:AddLabel("M16A2/M203: " .. papRequirements["M16A2/M203"] .. " Kills")
PackaPunchGroup:AddLabel("M1911: " .. papRequirements.M1911 .. " Kills")
PackaPunchGroup:AddLabel("G36C: " .. papRequirements.G36C .. " Kills")
PackaPunchGroup:AddLabel("Desert Eagle: " .. papRequirements["Desert Eagle"] .. " Kills")
PackaPunchGroup:AddLabel("Crossbow: " .. papRequirements.Crossbow .. " Kills")
PackaPunchGroup:AddLabel("AWP: " .. papRequirements.AWP .. " Kills")
PackaPunchGroup:AddLabel("M4A1: " .. papRequirements.M4A1 .. " Kills")
PackaPunchGroup:AddLabel("AK-47: " .. papRequirements["AK-47"] .. " Kills")
PackaPunchGroup:AddLabel("AN-94: " .. papRequirements["AN-94"] .. " Kills")
PackaPunchGroup:AddLabel("DB Shotgun: " .. papRequirements["DB Shotgun"] .. " Kills")
PackaPunchGroup:AddLabel("M1014: " .. papRequirements.M1014 .. " Kills")
PackaPunchGroup:AddLabel("P90: " .. papRequirements.P90 .. " Kills")
PackaPunchGroup:AddLabel("Colt Anaconda: " .. papRequirements["Colt Anaconda"] .. " Kills")
PackaPunchGroup:AddLabel("Flamethrower: " .. papRequirements.Flamethrower .. " Kills")
PackaPunchGroup:AddLabel("MG42: " .. papRequirements.MG42 .. " Kills")
PackaPunchGroup:AddLabel("FreezeGun: " .. papRequirements.FreezeGun .. " Kills")

-- Others Group

OtherGroup:AddDivider()

local weapons = {}

local function worldToScreenPoint(position)
    return camera:WorldToScreenPoint(position)
end

local function updateTextPosition(textLabel, object)
    local screenPosition = worldToScreenPoint(object.Position)
    textLabel.Position = Vector2.new(screenPosition.X, screenPosition.Y)
end

local function updatePositions()
    for weaponName, textLabel in pairs(weapons) do
        if workspace.Weapons[weaponName] then
            updateTextPosition(textLabel, workspace.Weapons[weaponName].Hitbox)
        end
    end
end

OtherGroup:AddToggle("WeaponESP", {
    Text = "Weapon ESP",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            weapons = {
                ["AK-47"] = Drawing.new("Text"),
                ["AN-94"] = Drawing.new("Text"),
                ["AWP"] = Drawing.new("Text"),
                ["DB Shotgun"] = Drawing.new("Text"),
                ["Desert Eagle"] = Drawing.new("Text"),
                ["G36C"] = Drawing.new("Text"),
                ["M1014"] = Drawing.new("Text"),
                ["M14"] = Drawing.new("Text"),
                ["M16A2/M203"] = Drawing.new("Text"),
                ["M4A1"] = Drawing.new("Text"),
                ["MP5k"] = Drawing.new("Text"),
                ["P90"] = Drawing.new("Text"),
                ["R870"] = Drawing.new("Text"),
                ["RayGun"] = Drawing.new("Text"),
                ["SVD"] = Drawing.new("Text"),
                ["Colt Anaconda"] = Drawing.new("Text"),
                ["Flamethrower"] = Drawing.new("Text"),
            }
    
            for weaponName, textLabel in pairs(weapons) do
                textLabel.Text = weaponName
                textLabel.Visible = true
                textLabel.Center = true
                textLabel.Outline = true
                textLabel.Font = 2
                textLabel.Color = Color3.fromRGB(255, 255, 255)
                textLabel.Size = 20
            end
    
            game:GetService("RunService").RenderStepped:Connect(updatePositions)
        else
            for _, textLabel in pairs(weapons) do
                textLabel:Destroy()
            end
        end
    end
})

OtherGroup:AddToggle("AutoReload", {
    Text = "Auto Reload",
    Default = false,
    Tooltip = "Automatically reloads all your weapons.",

    Callback = function(Value)
        if Value then
            for _, v in pairs(game:GetService("SoundService"):GetChildren()) do
                if v.Name == "AmmoReload" and v:IsA("Sound") then
                    v:Destroy()
                end
            end

            _G.autoreload = true
            autoreload()
        else
            _G.autoreload = false
        end
    end
})

-- UI Tab

local UIElementsGroup = Tabs.UI:AddLeftGroupbox("UI Elements")

UIElementsGroup:AddDivider()

UIElementsGroup:AddToggle("DisableTailsPopup", {
    Text = "Disable Tails Doll Popup",
    Default = false,
    Tooltip = "Disables the Tails Doll popup given by Tails Doll.",

    Callback = function(Value)
        if Value then
            for _, v in pairs(player.PlayerGui:GetDescendants()) do
                if v.Name == "TailsPopup" then
                    v.Enabled = false
                end
            end



        else



            for _, v in pairs(player.PlayerGui:GetDescendants()) do
                if v.Name == "TailsPopup" then
                    v.Enabled = true
                end
            end
        end
    end
})

UIElementsGroup:AddToggle("DisableInkPopup", {
    Text = "Disable Ink Popup",
    Default = false,
    Tooltip = "Disables the ink popup given by Eyeless Jack.",

    Callback = function(Value)
        _G.removeink = Value
        removeink()
    end
})

UIElementsGroup:AddDivider()

UIElementsGroup:AddToggle("PAPInterface", {
    Text = "Pack A Punch Interface",
    Default = false,
    Tooltip = "Toggles the visbility of the pack a punch interface.",

    Callback = function(Value)
        game:GetService("Players").LocalPlayer.PlayerGui.PAP.Enabled = Value
        game:GetService("Players").LocalPlayer.PlayerGui.PAP.Frame.Visible = Value
    end
})

-- Misc Tab

local MiscGroup = Tabs.Misc:AddLeftGroupbox("Miscellaneous")
local PlayingViewingGroup = Tabs.Misc:AddRightGroupbox("Player Viewing")
local ItemsGroup = Tabs.Misc:AddRightGroupbox("Items")
local GiversGroup = Tabs.Misc:AddLeftGroupbox("Givers")
local KeybindsGroup = Tabs.Misc:AddRightGroupbox("Keybinds")

-- Miscellaneous Group

MiscGroup:AddDivider()

local CollectAllPapers = MiscGroup:AddButton({
    Text = "Collect All Papers",
    Func = function()
        local humrootpart = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if not humrootpart then
            Library:Notify("No humanoid root part was found.", 8)
            return
        end

        for i, v in pairs(game:GetService("Workspace"):GetDescendants()) do
            if v.Name == "Paper" and v:IsA("BasePart") then
                utils.fireTouchEvent(humrootpart, v)
            end
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

--[[

local CompleteArea51Personnel = MiscGroup:AddButton({
    Text = "Complete Area 51 Personnel",
    Func = function()
        local humrootpart = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if not humrootpart then
            Library:Notify("No humanoid root part was found.", 8)
            return
        end

        local oldcframe = humrootpart.CFrame
    
        wait(0.3)
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.Outside.Hangar.Right["Zombie Morph"].TheButton) -- zombie morph
    
        utils.fireTouchEvent(humrootpart, game.Workspace.Weapons.M14.Hitbox) -- M14
    
        utils.fireTouchEvent(humrootpart, game.Workspace.Weapons["M16A2/M203"].Hitbox) -- M16A2/M203
    
        utils.fireTouchEvent(humrootpart, game.Workspace.Weapons.MP5k.Hitbox) -- MP5k
        
        utils.fireTouchEvent(humrootpart, game.Workspace.Weapons.R870.Hitbox) -- R870
        
        utils.fireTouchEvent(humrootpart, game.Workspace.Weapons.RayGun.Hitbox) -- RayGun
        
        utils.fireTouchEvent(humrootpart, game.Workspace.Weapons.SVD.Hitbox) -- SVD
        
        utils.fireTouchEvent(humrootpart, game.Workspace.Weapons["Desert Eagle"].Hitbox) -- Desert Eagle
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.RadioactiveArea.GiantZombieRoom.GiantZombieEngine.Close.Door2)
    
        remoteFunctions["PAP Weapon"]:InvokeServer("M14") -- pack a punch weapon
        remoteEvents.PAPFinished:FireServer()
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.PlantRoom["Box of Shells"].Box) -- ammo box
    
        wait(0.5)
    
        utils.teleport(32.7000198, 314.5, 203.399948, 1, 0, 0, 0, 1, 0, 0, 0, 1) -- execution room
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.AlienExit.Reward) -- alien
    
        remoteFunctions["PAP Weapon"]:InvokeServer("M14") -- pack a punch weapon
        remoteEvents.PAPFinished:FireServer()
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.RadioactiveArea.Floor1.Paper) -- paper 1
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.YellowBedRoom.Buro.Paper) -- paper 2
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.MeetingRoom.DeadGuy.Paper) -- paper 3
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.SecretPath1.Reward) -- secret path 1
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.SecretPath2.Reward) -- secret path 2
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.SecretPath3.Reward) -- secret path 3
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.SecretPath4.Reward) -- secret path 4
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.SecretPath5.Reward) -- secret path 5
    
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.SecretPath6.Reward) -- secret path 6
    
        wait(1.5)
    
        humrootpart.CFrame = oldcframe
    end,
    DoubleClick = false,
    Tooltip = false,
})

]]

MiscGroup:AddLabel("You need to have at least 5 kills to complete the pack a punch a weapon quest", true)

MiscGroup:AddToggle("KillerESP", {
    Text = "Killer ESP",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            local killerhighlight = Instance.new("Highlight", game.Workspace.Killers)
            killerhighlight.Name = "_CelestialKillerESP"
            killerhighlight.DepthMode = "AlwaysOnTop"
            killerhighlight.FillColor = Color3.new(1, 0, 0) -- red
            killerhighlight.OutlineColor = Color3.new(0.5804, 0, 0) -- dark red
            killerhighlight.FillTransparency = 0.5
            killerhighlight.OutlineTransparency = 0
            
        else

            local killerHighlight = game.Workspace.Killers:FindFirstChild("_CelestialKillerESP")

            if killerHighlight then
                killerHighlight:Destroy()
            end
        end
    end
})

MiscGroup:AddToggle("InstantPAP", {
    Text = "Instant Pack A Punch",
    Default = false,
    Tooltip = "Removes the wait when pack a punching a weapon.",

    Callback = function(Value)
        _G.instantpap = Value
        instantpap()
    end
})

MiscGroup:AddToggle("DoorProxPromptReach", {
    Text = "Door Prompt Reach",
    Default = false,
    Tooltip = "Extends the activation distance of door prompts.",

    Callback = function(Value)
        if Value then
            _G.doorpromptreach = true
            doorpromptreach()

        else

            _G.doorpromptreach = false

            for _, v in pairs(game.Workspace.Doors:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    v.MaxActivationDistance = 16
                end
            end
        end
    end
})

-- Player Viewing Group

PlayingViewingGroup:AddDivider()

local function getPlayerNames()
    local players = game:GetService("Players")
    local playerNames = {}
    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localplayer then
            table.insert(playerNames, player.Name)
        end
    end
    return playerNames
end

PlayingViewingGroup:AddDropdown("ViewPlayerDropdown", {
    Values = getPlayerNames(),
    Default = 0,
    Multi = false,
    Text = "View Player",
    Tooltip = false,
    Callback = function(value)
        viewplayerdropdownvalue = value
    end
})

PlayingViewingGroup:AddToggle("ViewPlayer", {
    Text = "View Player",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            Toggles.ViewAlienCode:SetValue(false) -- disabling View Code module

            camera.CameraSubject = game.Workspace["Characters to kill"][viewplayerdropdownvalue]
            Library:Notify("Viewing " .. viewplayerdropdownvalue .. ".", 4)
            isviewing = true
        else
            camera.CameraSubject = game.Workspace["Characters to kill"][player.Name]
        end
    end
})

-- Items Group

ItemsGroup:AddDivider()

ItemsGroup:AddDropdown("ItemDropdown", {
    Values = {"Vault Keycard", "Admin Card"},
    Default = 0,
    Multi = false,

    Text = "Item",
    Tooltip = false,

    Callback = function(DropdownValue)
        itemdropdownvalue = DropdownValue
    end
})

local GiveItem = ItemsGroup:AddButton({
    Text = "Give Item",
    Func = function()
        local humrootpart = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if not humrootpart then
            Library:Notify("No humanoid root part was found.", 8)
            return
        end

        if itemdropdownvalue == "" then
            Library:Notify("Invalid Value. Please select a option from the item dropdown above.", 4)
        end

        if itemdropdownvalue == "Vault Keycard" then
            utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.JailsRoom.Jails.Left.Behind.Card)
        elseif itemdropdownvalue == "Admin Card" then
            utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.AdminRoom.Table.Card)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

local GiveAllItems = ItemsGroup:AddButton({
    Text = "Give All Items",
    Func = function()
        local humrootpart = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if not humrootpart then
            Library:Notify("No humanoid root part was found.", 8)
            return
        end

        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.JailsRoom.Jails.Left.Behind.Card) -- vault keycard
        utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.AdminRoom.Table.Card) -- admin card
    end,
    DoubleClick = false,
    Tooltip = false,
})

-- Givers Group

GiversGroup:AddDivider()

GiversGroup:AddDropdown("ItemDropdown", {
    Values = {"Armor", "Zombie Morph"},
    Default = 0,
    Multi = false,

    Text = "Giver",
    Tooltip = false,

    Callback = function(DropdownValue)
        giverdropdownvalue = DropdownValue
    end
})

local GiveGiverItem = GiversGroup:AddButton({
    Text = "Give Giver Item",
    Func = function()
        local humrootpart = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if not humrootpart then
            Library:Notify("No humanoid root part was found.", 8)
            return
        end

        if giverdropdownvalue == "" then
            Library:Notify("Invalid Value. Please select a option from the giver dropdown above.", 4)
        end

        if giverdropdownvalue == "Armor" then
            utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.Amory2Room.Armory.Giver)
        elseif giverdropdownvalue == "Zombie Morph" then
            utils.fireTouchEvent(humrootpart, game.Workspace.AREA51.Outside.Hangar.Right["Zombie Morph"].TheButton)
        end
    end,
    DoubleClick = false,
    Tooltip = false,
})

GiversGroup:AddLabel("If you already have the armor and you give yourself the zombie morph, it will remove the armor. It is recommended to give yourself the zombie morph first.", true)

GiversGroup:AddDivider()

GiversGroup:AddToggle("RemoveZombieMorphGlow", {
    Text = "Remove Morph Glow",
    Default = false,
    Tooltip = "Removes the glow from all players that emits from the zombie morph.",

    Callback = function(Value)
        _G.disablemorphglow = Value
        disablemorphglow()
    end
})

-- Keybinds Group

KeybindsGroup:AddDivider()

local giveweaponkeybindenabled = false
local safezonekeybindenabled = false
local drinkenergykeybindenabled = false
local refillenergykeybindenabled = false

KeybindsGroup:AddToggle("KeybindsVisible", {
    Text = "Show Keybind UI",
    Default = true,
    Tooltip = "Toggles the visibility of the keybinds",

    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end
})

-- Give Weapon Keybind Toggle

KeybindsGroup:AddToggle("ToggleGiveWeaponKeybind", {
    Text = "Enable Give Weapon",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            giveweaponkeybindenabled = true
        else
            giveweaponkeybindenabled = false
        end
    end
})

KeybindsGroup:AddToggle("ToggleSafezoneKeybind", {
    Text = "Enable Safe Zone",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            safezonekeybindenabled = true
        else
            safezonekeybindenabled = false
        end
    end
})

KeybindsGroup:AddToggle("ToggleDrinkKeybind", {
    Text = "Enable Drink",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            drinkenergykeybindenabled = true
        else
            drinkenergykeybindenabled = false
        end
    end
})

KeybindsGroup:AddToggle("ToggleDrinkRefillKeybind", {
    Text = "Enable Refill",
    Default = false,
    Tooltip = false,

    Callback = function(Value)
        if Value then
            refillenergykeybindenabled = true
        else
            refillenergykeybindenabled = false
        end
    end
})

-- Give Weapon Keybind

KeybindsGroup:AddLabel("Give Weapon"):AddKeyPicker("GiveWeaponKeybind", {
    Default = "B",
    SyncToggleState = true,

    Mode = "Toggle",

    Text = "Give Weapon",
    NoUI = false,

    Callback = function(Value)
        if Value and giveweaponkeybindenabled then
            if weapondropdownvalue == "" then
                Library:Notify("Please select a option from the weapon dropdown in the Weapons tab.", 5)
            else


            end
        end
    end
})

-- Safe Zone

KeybindsGroup:AddLabel("Safe Zone"):AddKeyPicker("KeyPicker", {
    Default = "V",
    SyncToggleState = false,

    Mode = "Toggle",

    Text = "Safe Zone",
    NoUI = false,

    Callback = function(Value)
        if Value and safezonekeybindenabled then
            utils.teleport(-52.6837997, 313.500305, 292.096558, 1, 1.49757151e-09, -4.17306546e-05, -1.49720991e-09, 1, 8.6659675e-09, 4.17306546e-05, -8.66590533e-09, 1)
        end
    end
})

-- Drink Energy Drink

KeybindsGroup:AddLabel("Drink Energy Drink"):AddKeyPicker("DrinkEnergyDrinkKeyPicker", {
    Default = "F",
    SyncToggleState = false,

    Mode = "Toggle",

    Text = "Drink Energy Drink",
    NoUI = false,

    Callback = function(Value)
        if Value and drinkenergykeybindenabled then
            local energydrink = player.Backpack:FindFirstChild("Energy") or player.Character:FindFirstChild("Energy") -- Checking if the energy drink is inside the players backpack or character and drinking it
        
            if not energydrink then
                Library:Notify("Energy Drink not found.", 7)
                return
            end

            if energydrink.Ammo.Value == 0 then -- if your energy drink runs out of charges
                Library:Notify("No more charges left.", 6)
                return
            end
    
            energydrink.Drank:FireServer()
        end
    end
})

-- Refill Energy Drink

KeybindsGroup:AddLabel("Refill Energy Drink"):AddKeyPicker("RefillEnergyDrinkKeyPicker", {
    Default = "H",
    SyncToggleState = false,
    Mode = "Toggle",
    Text = "Refill Energy Drink",
    NoUI = false,

    Callback = function(Value)
        if Value and refillenergykeybindenabled then
            local player = game:GetService("Players").LocalPlayer
            local energydrink = player.Backpack:FindFirstChild("Energy") or player.Character:FindFirstChild("Energy") -- Checking if the energy drink is inside the players backpack or character and drinking it
        
            if not energydrink then
                Library:Notify("Energy Drink not found.", 7)
                return
            end
            
            local humrootpart = player.Character:FindFirstChild("HumanoidRootPart")
            local oldcframe

            if humrootpart then
                oldcframe = humrootpart.CFrame -- Store the old CFrame
            end
            
            -- Teleport to the coffee machine and refill the energy drink
            wait(0.01)
            utils.teleport(178.023087, 333.499908, 597.890442, 0.0192538705, -8.12836092e-08, 0.99981463, 1.48566126e-09, 1, 8.12700662e-08, -0.99981463, -7.93774491e-11, 0.0192538705)
            
            wait(0.18) -- Wait before firing the proximity prompt
            utils.fireProxPrompt(game.Workspace.AREA51.CafeRoom["Coffee Machine"].Energy.Head)

            wait(0.14) -- Adjust as necessary for consistent teleportation behavior
            
            -- Teleport back to the original position
            if oldcframe then
                utils.teleportToCFrame(oldcframe)
            end
        end
    end
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

Library.KeybindFrame.Visible = true;

Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    -- Restoring the default settings



    -- Changing the unloaded variable value

    Library.Unloaded = true
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddButton("Unload", function() Library:Unload() end)
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Celestial")
SaveManager:SetFolder("Celestial/SAKTKIA51 Classic - Normal")

SaveManager:BuildConfigSection(Tabs["UI Settings"])

ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()