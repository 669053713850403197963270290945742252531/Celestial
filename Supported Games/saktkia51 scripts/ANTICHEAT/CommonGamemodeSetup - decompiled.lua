-- Script Path: game:GetService("Players").Neoystone.PlayerScripts.CommonGamemodeSetup
-- Took 0.11s to decompile.
-- Executor: Potassium (v2.6.0)

-- Decompiled using ByteFall
-- discord.gg/pHTnqmmWzk
local LocalPlayer: Player = game:GetService("Players").LocalPlayer
local playerGui: Instance = LocalPlayer:WaitForChild("PlayerGui")
local replicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local constants = require(replicatedStorage:WaitForChild("Constants"))
local replicatedStorage2: ReplicatedStorage = game:GetService("ReplicatedStorage")
local animator = require(replicatedStorage2:WaitForChild("Animator"))
local replicatedStorage3: ReplicatedStorage = game:GetService("ReplicatedStorage")
local stateModule = require(replicatedStorage3:WaitForChild("StateModule"))
local replicatedStorage4: ReplicatedStorage = game:GetService("ReplicatedStorage")
local utilities = require(replicatedStorage4:WaitForChild("Utilities"))
local inputContexts: Instance = game:GetService("ReplicatedStorage"):WaitForChild("InputContexts")
local clientDied: Instance = game:GetService("ReplicatedStorage"):WaitForChild("Character Remotes"):WaitForChild("ClientDied")
local localDescendant: Instance = game:GetService("ReplicatedStorage"):WaitForChild("Remote Events"):WaitForChild("LocalDescendant")
local playerLagging: Instance = game:GetService("ReplicatedStorage"):WaitForChild("Remote Events"):WaitForChild("PlayerLagging")
local v15 = utilities:get_gamemode(true)
local inventory = require(script.Parent:WaitForChild("Inventory"))
local u17 = nil
local t1: {[any]: any} = {
    sat = true,
    main = true,
    saktkia51 = true,
    UltimateTrollingGuiV3 = true,
    LOADERLoadingScreen = true,
    ["Demonic Hub"] = true,
    CreditXGui = true
}

playerGui.ChildAdded:Connect(function(p1: Instance)
    if t1[p1.Name] then
        if p1:IsA("GuiBase2d") then
            p1.AutoLocalize = false
        end

        task.wait(0.1)

        for _, v in pairs(p1:GetDescendants()) do
            if v:IsA("GuiBase2d") then
                v.AutoLocalize = false

                if v:IsA("GuiButton") then
                    local clone = v:Clone()

                    clone.Parent = v.Parent
                    v:Destroy()
                end
            end
        end

        game:GetService("ReplicatedStorage"):WaitForChild("Remote Events"):WaitForChild("LocalDescendant"):FireServer(nil, p1.Name)
    elseif p1.Name == "Killer Select" or p1.Name == "Class Select" then
        if u17 then
            stateModule:undo(u17)
        end

        u17 = stateModule:change(inventory, "toggle", { false }, 20)
    end
end)

local starterGui: Instance = game:GetService("ReplicatedStorage"):WaitForChild("StarterGui")

for _, v in pairs(starterGui:GetChildren()) do
    local clone = v:Clone()

    clone.Parent = playerGui
end

playerLagging.OnClientEvent:Connect(function()
    playerLagging:FireServer()
end)
localDescendant.AncestryChanged:Connect(function()
    LocalPlayer:Kick("Unexpected client behavior")
end)

local function BackpackToolAdded(p2)
    if p2:IsA("HopperBin") then
        localDescendant:FireServer(p2, 5)
    end
end

local n1: number = if v15 == (constants.PLACE_ENUMS.JuggernautMode or v15 == constants.PLACE_ENUMS.InfectionMode) then 21 else if v15 == constants.PLACE_ENUMS.EndlessSurvival then 28 else if v15 == constants.PLACE_ENUMS.BossRushMode then 23 else if v15 == constants.PLACE_ENUMS.Area51Storming then 30 else if v15 == constants.PLACE_ENUMS.Killhouse then 16 else 25
local connection = nil

local function CheckSpeed(p3)
    local humanoid = p3:WaitForChild("Humanoid")
    local humanoidWalkSpeed = humanoid.WalkSpeed
    local v82 = p3.Parent
    local killers: Instance = workspace:WaitForChild("Killers")
    local u84
    local n3

    if v82 == killers then
        local foundChild: Instance = game:GetService("ReplicatedStorage"):WaitForChild("Killer"):FindFirstChild(p3.Name)

        if not foundChild then
            LocalPlayer:Kick("Unexpected client behavior")

            return
        end

        u84 = require(foundChild).max_walkspeed

        if v15 == constants.PLACE_ENUMS.JuggernautMode then
            u84 = math.max(u84, 25)
        end

        n3 = 60
    else
        u84 = n1
        n3 = 50
    end

    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if humanoid.WalkSpeed > u84 then
            humanoid.WalkSpeed = humanoidWalkSpeed
            localDescendant:FireServer(nil, 1)

            return
        end

        humanoidWalkSpeed = humanoid.WalkSpeed
    end)
    humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if humanoid.JumpPower > n3 then
            localDescendant:FireServer(nil, 12)
        end
    end)

    local u87: boolean = false
    local n2: number = 0
    local jumping = Enum.HumanoidStateType.Jumping
    local freefall = Enum.HumanoidStateType.Freefall

    humanoid.StateChanged:Connect(function(p4, p5)
        if (p4 == freefall or p4 == jumping) and p5 == jumping then
            n2 += 1

            if n2 == 3 and not u87 then
                u87 = true
                localDescendant:FireServer(nil, 8)
                task.wait(3)
                u87 = false

                return
            end
        elseif p5 ~= freefall then
            n2 = 0
        end
    end)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
    humanoid.Strafing:Connect(function()
        if not u87 then
            u87 = true
            localDescendant:FireServer(nil, 2)
            task.wait(3)
            u87 = false
        end
    end)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
    humanoid.Swimming:Connect(function()
        if not u87 then
            u87 = true
            localDescendant:FireServer(nil, 3)
            task.wait(3)
            u87 = false
        end
    end)
    p3.DescendantAdded:Connect(function(p6)
        if p6:IsA("BodyMover") then
            task.wait(0.05)

            if humanoid.PlatformStand then
                localDescendant:FireServer(p6, 4)

                return
            end

            localDescendant:FireServer(p6, 13)

            return
        end
    end)
    connection = LocalPlayer:WaitForChild("Backpack").ChildAdded:Connect(BackpackToolAdded)

    local backpack: Instance = LocalPlayer:WaitForChild("Backpack")

    for _, v in pairs(backpack:GetChildren()) do
        if v:IsA("HopperBin") then
            localDescendant:FireServer(v, 5)
        end
    end

    p3:WaitForChild("HumanoidRootPart"):GetPropertyChangedSignal("CanCollide"):Connect(function()
        u87 = true
        localDescendant:FireServer(nil, 9)
        task.wait(3)
        u87 = false
    end)
end
local function SetupHumanoidDeath(p7)
    local humanoid = p7:WaitForChild("Humanoid")

    humanoid.Died:Connect(function()
        clientDied:FireServer(p7)
        utilities:destroy_main_joints(p7)
        humanoid:UnequipTools()
    end)
    humanoid.RequiresNeck = false
end

local u28 = nil
local t2: {[any]: any} = {
    [Enum.HumanoidStateType.Physics] = true,
    [Enum.HumanoidStateType.PlatformStanding] = false,
    [Enum.HumanoidStateType.FallingDown] = false,
    [Enum.HumanoidStateType.Ragdoll] = false,
    [Enum.HumanoidStateType.Dead] = true
}
local t3: {[any]: any} = {}

local function SetupHumanoidStates(p8)
    local humanoid = p8:WaitForChild("Humanoid")

    humanoid.StateChanged:Connect(function(_, p10)
        if t2[p10] ~= nil then
            if t2[p10] then
                humanoid:UnequipTools()
            end

            if not u28 then
                u28 = stateModule:change(inventory, "change_interactability", { false }, 10)

                return
            end
        elseif u28 then
            stateModule:undo(u28)
            u28 = nil
        end
    end)
end
local function AdjustRightHand(p11)
    local u99 = false

    if p11.Name == "RightGrip" then
        u99 = p11.Part0 and p11.Part0.Parent and p11.Part0.Parent:FindFirstChild("Right Arm")
    end

    if u99 then
        local v100 = p11.Part0.CFrame:ToObjectSpace(u99.CFrame)
        local v101 = CFrame.Angles(-1.5707963267948966, 0, 0)

        p11.C0 = v100 * v101 * CFrame.new(0, 0, -1)
    end
end

local u33 = nil

local function CharacterAdded(p12)
    CheckSpeed(p12)

    if u33 then
        u33:unload()
        u33 = nil
    end

    if u17 then
        stateModule:undo(u17)
        u17 = nil
    end

    if u28 then
        stateModule:undo(u28)
        u28 = nil
    end

    for _, v in pairs(t3) do
        stateModule:undo(v)
    end

    t3 = {}
    workspace.CurrentCamera.CameraSubject = p12:WaitForChild("Humanoid")
    LocalPlayer.CameraMinZoomDistance = 0.5

    local v105 = p12.Parent
    local killers: Instance = workspace:WaitForChild("Killers")

    if v105 == killers then
        u17 = stateModule:change(inventory, "toggle", { false }, 20)
        inputContexts:WaitForChild("Survivor").Enabled = false
        inputContexts:WaitForChild("Killer").Enabled = true

        return
    end

    inputContexts:WaitForChild("Survivor").Enabled = true
    inputContexts:WaitForChild("Killer").Enabled = false

    local humanoid = p12:WaitForChild("Humanoid")

    humanoid.Died:Connect(function()
        clientDied:FireServer(p12)
        utilities:destroy_main_joints(p12)
        humanoid:UnequipTools()
    end)
    humanoid.RequiresNeck = false

    local v108 = p12:WaitForChild("Humanoid")

    v108.StateChanged:Connect(function(_, p14)
        if t2[p14] ~= nil then
            if t2[p14] then
                v108:UnequipTools()
            end

            if not u28 then
                u28 = stateModule:change(inventory, "change_interactability", { false }, 10)

                return
            end
        elseif u28 then
            stateModule:undo(u28)
            u28 = nil
        end
    end)

    local rightGrip = p12:WaitForChild("RightHand"):FindFirstChild("RightGrip")

    if rightGrip then
        AdjustRightHand(rightGrip)
    end

    p12.RightHand.ChildAdded:Connect(AdjustRightHand)
    task.wait(0.035)

    local children = game:GetService("ReplicatedStorage"):WaitForChild("Player Animations"):GetChildren()

    u33 = animator:new(p12, children, nil, 17)
end

game:GetService("ReplicatedStorage"):WaitForChild("Character Remotes"):WaitForChild("ServerTrip").OnClientEvent:Connect(function(p15, p16, ...)
    if not p16 then
        return
    end

    if p15 then
        utilities:trip_humanoid(p16, ...)

        return
    end

    p16:ChangeState(Enum.HumanoidStateType.GettingUp)
end)
game:GetService("ReplicatedStorage"):WaitForChild("Character Remotes"):WaitForChild("ServerTeleport").OnClientEvent:Connect(function(p17, cFrame)
    if not p17 then
        return
    end

    if p17.Name == "HumanoidRootPart" and p17.Parent then
        p17.Parent:PivotTo(cFrame)

        return
    end

    p17.CFrame = cFrame
end)
game:GetService("ReplicatedStorage"):WaitForChild("Character Remotes"):WaitForChild("InventoryInteractability").OnClientEvent:Connect(function(p19, p20)
    if p20 then
        t3[p20] = stateModule:change(inventory, "change_interactability", { p19 }, 20)
    elseif t3[p19] then
        stateModule:undo(t3[p19])
        t3[p19] = nil
    end
end)
game:GetService("ReplicatedStorage"):WaitForChild("Remote Events"):WaitForChild("Explode").OnClientEvent:Connect(function(...)
    utilities:make_explosion_effect(...)
end)
game:GetService("Players").PlayerAdded:Connect(function(player: Player)
    player.CharacterRemoving:Connect(function(p22: Model)
        task.wait(20)
        p22:Destroy()
    end)
end)

local players: Players = game:GetService("Players")

for _, v in pairs(players:GetPlayers()) do
    v.CharacterRemoving:Connect(function(p22: Model)
        task.wait(20)
        p22:Destroy()
    end)
end

game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
    task.wait(30)
    player:Destroy()
end)

if v15 ~= constants.PLACE_ENUMS.BossRushMode then
    local u38: boolean = false

    workspace:WaitForChild("Doors").DescendantRemoving:Connect(function(p24: Instance)
        if utilities:is_door_part(p24) and not u38 then
            u38 = true
            localDescendant:FireServer(nil, 7)
            task.wait(3)
            u38 = false
        end
    end)
end

local replicatedStorage5: ReplicatedStorage = game:GetService("ReplicatedStorage")

require(replicatedStorage5:WaitForChild("Tool")):init()

local replicatedStorage6: ReplicatedStorage = game:GetService("ReplicatedStorage")

require(replicatedStorage6:WaitForChild("Weapon")):init()
LocalPlayer.CharacterAdded:Connect(CharacterAdded)

if LocalPlayer.Character then
    task.spawn(CharacterAdded, LocalPlayer.Character)
end

LocalPlayer.CharacterRemoving:Connect(function(character: Model)
    if u33 then
        u33:unload()
        u33 = nil
    end

    if connection then
        connection:Disconnect()
        connection = nil
    end

    task.wait(20)
    character:Destroy()
end)
game:GetService("ReplicatedStorage"):WaitForChild("Character Remotes"):WaitForChild("SkinsEquipped").OnClientEvent:Connect(function(player, p27)
    if player.Character then
        for k, v in pairs(p27) do
            local v126 = utilities:get_character_weapon(k, player.Character, player, false)

            if v126 then
                utilities:apply_skin(v126, v)
            end
        end
    end
end)

local players2: Players = game:GetService("Players")

for _, v in pairs(players2:GetPlayers()) do
    if v ~= LocalPlayer then
        local backpack = v:FindFirstChild("Backpack")

        if backpack then
            for _, iterValue in pairs(backpack:GetChildren()) do
                if iterValue.ClassName == "Tool" and iterValue:GetAttribute("AppliedSkin") then
                    utilities:apply_skin(iterValue, iterValue:GetAttribute("AppliedSkin"))
                end
            end
        end

        local Character = v.Character

        if Character then
            Character = v.Character:FindFirstChildOfClass("Tool")
        end

        if Character and Character:GetAttribute("AppliedSkin") then
            utilities:apply_skin(Character, Character:GetAttribute("AppliedSkin"))
        end
    end
end

local v48: Instance = game:GetService("ReplicatedStorage"):WaitForChild("Constants")
local skins = require(v48:WaitForChild("Skins"))

if v15 ~= constants.PLACE_ENUMS.Killhouse then
    local collectiblesFrame: Frame = Instance.new("Frame")

    collectiblesFrame.Name = "CollectiblesFrame"
    collectiblesFrame.BackgroundTransparency = 1
    collectiblesFrame.LayoutOrder = 10
    collectiblesFrame.Size = UDim2.new(0, 130, 0, 64)
    collectiblesFrame.Visible = true
    collectiblesFrame.AutoLocalize = false

    local collectiblesContent: Frame = Instance.new("Frame")

    collectiblesContent.Name = "CollectiblesContent"
    collectiblesContent.BackgroundTransparency = 1
    collectiblesContent.Size = UDim2.new(1, 0, 1, 0)
    collectiblesContent.Visible = true
    collectiblesContent.AutoLocalize = false
    collectiblesContent.Parent = collectiblesFrame

    local pickup: Sound = Instance.new("Sound")

    pickup.Name = "Pickup"
    pickup.SoundId = "http://www.roblox.com/asset/?id=119331181292083"
    pickup.Volume = 0.5
    pickup.Parent = collectiblesFrame
    collectiblesFrame.Parent = playerGui:WaitForChild("BottomLeftScreen"):WaitForChild("BottomLeftFrame")
    game:GetService("ReplicatedStorage"):WaitForChild("Remote Events"):WaitForChild("CollectibleDrop").OnClientEvent:Connect(function(p28, list, p30, p31, p32)
        if list then
            local n1: number = #list

            if n1 == 1 then
                utilities:drop_collectible(p28, list[1], p30[1], p31, p32)

                return
            end

            for k, v in pairs(list) do
                local n2 = k / n1 * 2 * 3.141592653589793
                local v136 = utilities:drop_collectible(p28, v, p30[k], p31, p32)

                if v136 then
                    local cosine = math.cos(n2)
                    local sine = math.sin(n2)

                    v136.AssemblyLinearVelocity = Vector3.new(cosine * 10, 50, sine * 10)
                end
            end

            return
        end

        utilities:collectibles_grabbed(p28)
    end)
end

local playerScripts: Instance = LocalPlayer:WaitForChild("PlayerScripts")
local inventory2 = require(playerScripts:WaitForChild("Inventory"))
local bag = inventory2.gui:WaitForChild("Bag")
local hotbar = inventory2.gui:WaitForChild("Hotbar")
local collectibles = game:GetService("ReplicatedStorage"):WaitForChild("Remote Functions"):WaitForChild("GetSkinsData"):InvokeServer().collectibles
local buttonRB: ImageLabel = Instance.new("ImageLabel")

buttonRB.Name = "ButtonRB"
buttonRB.AnchorPoint = Vector2.new(0.5, 0)
buttonRB.BackgroundTransparency = 1
buttonRB.Position = UDim2.new(1, 65, 0, 0)
buttonRB.Size = UDim2.new(1, 0, 1, 0)
buttonRB.SizeConstraint = Enum.SizeConstraint.RelativeYY
buttonRB.Image = utilities:get_keycode_image(Enum.KeyCode.ButtonR1)
buttonRB.AutoLocalize = false
buttonRB.Parent = inventory2.gui:WaitForChild("ControllerFrame")

local skinsButton: TextButton = Instance.new("TextButton")

skinsButton.Name = "SkinsButton"
skinsButton.AnchorPoint = Vector2.new(0.5, 0)
skinsButton.AutomaticSize = Enum.AutomaticSize.X
skinsButton.BackgroundColor3 = Color3.fromRGB(210, 210, 210)
skinsButton.BorderColor3 = Color3.fromRGB(150, 150, 150)
skinsButton.BorderSizePixel = 3
skinsButton.Size = UDim2.new(0, 100, 0, 30)

local v60 = bag.Visible

if v60 then
    v60 = not utilities:is_using_controller()
end

skinsButton.Visible = v60
skinsButton.Font = Enum.Font.SourceSans
skinsButton.Text = " Skins "
skinsButton.TextColor3 = Color3.fromRGB(0, 0, 0)
skinsButton.TextSize = 24

local buttonY: ImageLabel = Instance.new("ImageLabel")

buttonY.Name = "ButtonY"
buttonY.BackgroundTransparency = 1
buttonY.Size = UDim2.new(0, 30, 0, 30)
buttonY.Image = utilities:get_keycode_image(Enum.KeyCode.ButtonY)
buttonY.Visible = bag.Visible and utilities:is_using_controller()

local skinsLabel: TextLabel = Instance.new("TextLabel")

skinsLabel.Name = "SkinsLabel"
skinsLabel.BackgroundTransparency = 1
skinsLabel.Position = UDim2.new(1, 5, 0, 0)
skinsLabel.Size = UDim2.new(0, 100, 0, 30)
skinsLabel.Font = Enum.Font.SourceSans
skinsLabel.Text = "Skins"
skinsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
skinsLabel.TextStrokeColor3 = Color3.fromRGB(50, 50, 50)
skinsLabel.TextSize = 24
skinsLabel.TextStrokeTransparency = 0.25
skinsLabel.TextXAlignment = Enum.TextXAlignment.Left
skinsLabel.Parent = buttonY

local collectiblesCount: ScrollingFrame = Instance.new("ScrollingFrame")

collectiblesCount.Name = "CollectiblesCount"
collectiblesCount.BackgroundColor3 = bag.BackgroundColor3
collectiblesCount.BackgroundTransparency = bag.BackgroundTransparency
collectiblesCount.BorderColor3 = bag.BorderColor3
collectiblesCount.BorderSizePixel = bag.BorderSizePixel
collectiblesCount.AutoLocalize = false
collectiblesCount.Visible = bag.Visible
collectiblesCount.ScrollBarImageColor3 = bag.ScrollBarImageColor3
collectiblesCount.ScrollBarThickness = bag.ScrollBarThickness
collectiblesCount.ScrollingDirection = Enum.ScrollingDirection.Y

local t4: {[any]: any} = {}

for _, v in pairs(skins.CRAFT_ITEMS) do
    if not skins.EVENT_ITEMS[v] or game:GetService("ReplicatedStorage"):WaitForChild("Event").Value == skins.EVENT_ITEMS[v] then
        table.insert(t4, v)
    end
end

utilities:sort(t4, function(p33, p34)
    local v141 = skins.ITEM_CHANCES[p33]
    local v142 = skins.ITEM_CHANCES[p34]

    if not v141 or not v142 then
        if v141 == v142 then
            return p33 < p34
        end

        if not v141 then
            return true
        end

        return false
    end

    if v141 ~= v142 then
        return v141 > v142
    end

    return p33 < p34
end)

for k, v in pairs(t4) do
    local frame: Frame = Instance.new("Frame")

    frame.Name = v
    frame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
    frame.BackgroundTransparency = 0.5
    frame.Position = UDim2.new(0, 5, 0, 48 * (k - 1) + 5 * k)
    frame.Size = UDim2.new(1, -20, 0, 48)
    frame.AutoLocalize = false

    local imageLabel: ImageLabel = Instance.new("ImageLabel")

    imageLabel.BackgroundTransparency = 1
    imageLabel.Position = UDim2.new(0, 0, 0, 0)
    imageLabel.Size = UDim2.new(0, 48, 0, 48)
    imageLabel.Image = "http://www.roblox.com/asset/?id=" .. skins.ITEM_IMAGE_IDS[v]
    imageLabel.AutoLocalize = false
    imageLabel.Parent = frame

    local itemCount: TextLabel = Instance.new("TextLabel")

    itemCount.Name = "ItemCount"
    itemCount.BackgroundTransparency = 1
    itemCount.Position = UDim2.new(0, 52, 0, 0)
    itemCount.Size = UDim2.new(0, 48, 0, 48)
    itemCount.AutoLocalize = false
    itemCount.Font = Enum.Font.SourceSans
    itemCount.Text = "x " .. (collectibles[v] or 0)
    itemCount.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemCount.TextSize = 26
    itemCount.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    itemCount.TextStrokeTransparency = 0
    itemCount.TextXAlignment = Enum.TextXAlignment.Left
    itemCount.Parent = frame
    frame.Parent = collectiblesCount
end

collectiblesCount.CanvasSize = UDim2.new(0, 0, 0, #t4 * 53 + 5)

local function InventoryPositionSizeChanged()
    local bagPosition = bag.Position
    local uDim2 = UDim2.new(bag.Size.X.Scale, bag.Size.X.Offset + 10, 0, 0)

    collectiblesCount.Position = bagPosition + uDim2
    collectiblesCount.Size = UDim2.new(0, 110, bag.Size.Y.Scale, bag.Size.Y.Offset)
    skinsButton.Position = UDim2.new(collectiblesCount.Position.X.Scale, collectiblesCount.Position.X.Offset + 55, hotbar.Position.Y.Scale + (hotbar.Size.Y.Scale - skinsButton.Size.Y.Scale) / 2, hotbar.Position.Y.Offset + (hotbar.Size.Y.Offset - skinsButton.Size.Y.Offset) / 2)
    buttonY.Position = UDim2.new(collectiblesCount.Position.X.Scale, collectiblesCount.Position.X.Offset, hotbar.Position.Y.Scale + (hotbar.Size.Y.Scale - buttonY.Size.Y.Scale) / 2, hotbar.Position.Y.Offset + (hotbar.Size.Y.Offset - buttonY.Size.Y.Offset) / 2)
end

collectiblesCount.Parent = inventory2.gui
skinsButton.Parent = inventory2.gui
buttonY.Parent = inventory2.gui
bag:GetPropertyChangedSignal("Visible"):Connect(function()
    collectiblesCount.Visible = bag.Visible

    local v145 = bag.Visible

    if v145 then
        v145 = not utilities:is_using_controller()
    end

    skinsButton.Visible = v145
    buttonY.Visible = bag.Visible and utilities:is_using_controller()
end)
bag:GetPropertyChangedSignal("Position"):Connect(InventoryPositionSizeChanged)
bag:GetPropertyChangedSignal("Size"):Connect(InventoryPositionSizeChanged)
InventoryPositionSizeChanged()
skinsButton.MouseButton1Click:Connect(function()
    inventory2:toggle_visible(false)
    playerGui:WaitForChild("SkinsMenu").Enabled = true

    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid:UnequipTools()
    end
end)

local u73 = nil

game:GetService("UserInputService").InputBegan:Connect(function(input: InputObject)
    if collectiblesCount.Visible and input.KeyCode == Enum.KeyCode.ButtonR1 and not game:GetService("UserInputService"):IsGamepadButtonDown(input.UserInputType, Enum.KeyCode.ButtonL1) then
        local connection = nil
        local connection2 = nil

        connection = game:GetService("UserInputService").InputBegan:Connect(function(input: InputObject)
            if input.KeyCode == Enum.KeyCode.ButtonL1 and connection then
                connection:Disconnect()
                connection2:Disconnect()
                connection = nil
                connection2 = nil
            end
        end)
        connection2 = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
            if input.UserInputState == Enum.UserInputState.End and connection2 then
                connection:Disconnect()
                connection2:Disconnect()
                connection = nil
                connection2 = nil

                if collectiblesCount.Visible then
                    if game:GetService("GuiService").SelectedObject == collectiblesCount then
                        if u73 and u73:IsDescendantOf(game) then
                            utilities:select_gui(u73)
                        else
                            inventory2:select_default_slot()
                        end

                        u73 = nil

                        return
                    end

                    u73 = game:GetService("GuiService").SelectedObject
                    utilities:select_gui(collectiblesCount)

                    return
                end

                return
            end
        end)
    end
end)
inputContexts:WaitForChild("GuiWindowNavigation"):WaitForChild("MiscAction").Pressed:Connect(function()
    if collectiblesCount.Visible then
        inventory2:toggle_visible(false)
        playerGui:WaitForChild("SkinsMenu").Enabled = true

        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid:UnequipTools()
        end
    end
end)
utilities:on_input_type_changed(function(p37)
    skinsButton.Visible = bag.Visible and not p37
    buttonY.Visible = bag.Visible and p37
end)
