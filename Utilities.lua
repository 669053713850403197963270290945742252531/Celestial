local utils = {}

-- Services

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local soundService = game:GetService("SoundService")
local textChatService = game:GetService("TextChatService")
local tweenService = game:GetService("TweenService")
local teleportService = game:GetService("TeleportService")
local starterGui = game:GetService("StarterGui")
local marketplaceService = game:GetService("MarketplaceService")

local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid")
local hrp = character:FindFirstChild("HumanoidRootPart")

if not hrp then
    repeat
        task.wait()
    until hrp
end

-- Function - getPlayers

utils.getPlayerCount = function()
    return #players:GetPlayers()
end

-- Function - createAudio

utils.createAudio = function(playOnRemove, soundId, looped, volume)
    local audio = Instance.new("Sound", soundService)
    audio.PlayOnRemove = playOnRemove
    audio.SoundId = "rbxassetid://" .. soundId
    audio.Looped = looped
    audio.Volume = volume

    if playOnRemove then
        audio:Destroy()
    else
        audio:Play()
    end
end

-- Function - updateAudio

utils.updateAudio = function(path, soundId, isPlaying)
    local found = false

    if type(path.GetChildren) == "function" then
        for _, v in pairs(path:GetChildren()) do
            if v:IsA("Sound") and v.SoundId == soundId then
                v.Playing = isPlaying
                found = true
            end
        end
    else
        warn("Invalid path object provided.")
    end

    if not found then
        warn("Audio with SoundId " .. soundId .. " not found.")
    end
end

-- Function - teleport

utils.teleport = function(px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22)
    local player = players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    if character and character.PrimaryPart then
        local destinationCFrame = CFrame.new(px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22)
        character:SetPrimaryPartCFrame(destinationCFrame)
    else
        warn("Character or PrimaryPart not found")
    end
end

-- Function - teleportToCFrame (used when teleporting to a cframe set by a variable)

utils.teleportToCFrame = function(destinationCFrame)
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    if character and character.PrimaryPart then
        character:SetPrimaryPartCFrame(destinationCFrame)
    else
        warn("Character or PrimaryPart not found")
    end
end


-- Function - partTeleport


utils.partTeleport = function(part)
    local character = game:GetService("Players").LocalPlayer.Character
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if character and hrp then
        hrp.CFrame = part.CFrame
    else
        warn("Character or PrimaryPart not found")
    end
end

-- Function - tweenTeleport

-- Function to convert a string to a CFrame
local function stringToCFrame(cframeString)
    local components = cframeString:split(", ")
    local cframeComponents = {}
    for _, component in ipairs(components) do
        table.insert(cframeComponents, tonumber(component))
    end
    return CFrame.new(unpack(cframeComponents))
end

local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local originalCanCollideStates = {}
local originalGravity

local function storeOriginalStates()
    originalGravity = workspace.Gravity
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            originalCanCollideStates[v] = v.CanCollide
            v.CanCollide = false
        end
    end
    --print("Stored original states and disabled CanCollide")
end

local function restoreOriginalStates()
    for part, canCollide in pairs(originalCanCollideStates) do
        if part and part:IsA("BasePart") then
            part.CanCollide = canCollide
        end
    end
    workspace.Gravity = originalGravity
    --print("Restored original states and re-enabled CanCollide")
end

utils.tweenTeleport = function(duration, cframeString, smooth)
    if smooth then
        storeOriginalStates()
        workspace.Gravity = 0
        --print("Gravity set to 0")
    end

    if not hrp then
        if smooth then
            restoreOriginalStates()
            workspace.Gravity = originalGravity
        end
        return
    end

    local targetCFrame = stringToCFrame(cframeString)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tweenGoal = { CFrame = targetCFrame }

    local tween = tweenService:Create(hrp, tweenInfo, tweenGoal)
    tween:Play()

    --print("Tween started")

    tween.Completed:Connect(function()
        --print("Tween completed")
        if smooth then
            restoreOriginalStates()
            workspace.Gravity = originalGravity
        end
    end)
end



-- Function - tweenPartTeleport

utils.tweenPartTeleport = function(duration, targetPart, smooth)
    if smooth then
        storeOriginalStates()
        workspace.Gravity = 0
        --print("Gravity set to 0")
    end

    if not hrp then
        if smooth then
            restoreOriginalStates()

            workspace.Gravity = originalGravity
        end
        return
    end

    local targetCFrame = targetPart.CFrame
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tweenGoal = { CFrame = targetCFrame }

    local tween = tweenService:Create(hrp, tweenInfo, tweenGoal)
    tween:Play()

    --print("Tween started")

    tween.Completed:Connect(function()
        --print("Tween completed")

        if smooth then
            restoreOriginalStates()
            workspace.Gravity = originalGravity
        end
    end)
end


-- Function - gameTeleport

utils.gameTeleport = function(mode, placeId)
    -- Checks

    if typeof(mode) ~= "string" then
        warn("Argument #1 expected string but got " .. typeof(mode) .. ".")
        mode = "PlaceId"
    end

    -- Teleport

    if mode == "PlaceId" then
        if typeof(placeId) ~= "number" then
            warn("Argument #2 expected number but got " .. typeof(placeId) .. ".")
            return
        end

        teleportService:Teleport(placeId)
    elseif mode == "Rejoin" then
        teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end
end

-- Function - gameInstanceTeleport

utils.gameInstanceTeleport = function(placeId, instanceId)
    teleportService:TeleportToPlaceInstance(placeId, instanceId)
end

-- Function - positionChatWindow

utils.positionChatWindow = function(horizontalAlignment, verticalAlignment)
    local chatversion = (textChatService.ChatVersion == Enum.ChatVersion.TextChatService) and "TextChatService" or
    "Legacy"

    local validHorizontalAlignments = {
        Center = Enum.HorizontalAlignment.Center,
        Left = Enum.HorizontalAlignment.Left,
        Right = Enum.HorizontalAlignment.Right
    }

    local validVerticalAlignments = {
        Bottom = Enum.VerticalAlignment.Bottom,
        Top = Enum.VerticalAlignment.Top,
        Center = Enum.VerticalAlignment.Center
    }

    if chatversion == "TextChatService" then
        if validHorizontalAlignments[horizontalAlignment] and validVerticalAlignments[verticalAlignment] then
            textChatService.ChatWindowConfiguration.HorizontalAlignment = validHorizontalAlignments[horizontalAlignment]
            textChatService.ChatWindowConfiguration.VerticalAlignment = validVerticalAlignments[verticalAlignment]
        else
            warn("Invalid horizontal or vertical alignment provided.")
        end
    elseif chatversion == "Legacy" then
        local chatwindow = player.PlayerGui.Chat.Frame
        if validHorizontalAlignments[horizontalAlignment] and validVerticalAlignments[verticalAlignment] then
            chatwindow.AnchorPoint = Vector2.new(
            (horizontalAlignment == "Center" and 0.5) or (horizontalAlignment == "Left" and 0) or 1,
                (verticalAlignment == "Center" and 0.5) or (verticalAlignment == "Top" and 0) or 1)
            chatwindow.Position = UDim2.new(chatwindow.AnchorPoint.X, 0, chatwindow.AnchorPoint.Y, 0)
        else
            warn("Invalid horizontal or vertical alignment provided.")
        end
    else
        warn("Unknown chat version.")
    end
end

-- Function - resetChatWindow

utils.resetChatWindow = function()
    local chatversion = (textChatService.ChatVersion == Enum.ChatVersion.TextChatService) and "TextChatService" or "Legacy"

    if chatversion == "TextChatService" then
        local ChatWindowConfiguration = textChatService.ChatWindowConfiguration
        local ChatInputBarConfiguration = textChatService.ChatInputBarConfiguration
        local BubbleChatConfiguration = textChatService.BubbleChatConfiguration

        ChatWindowConfiguration.BackgroundColor3 = Color3.new(25 / 255, 27 / 255, 29 / 255)
        ChatWindowConfiguration.BackgroundTransparency = 0.5
        ChatWindowConfiguration.TextColor3 = Color3.new(1, 1, 1)
        ChatWindowConfiguration.TextSize = 18
        ChatWindowConfiguration.TextStrokeColor3 = Color3.new(0, 0, 0)
        ChatWindowConfiguration.TextStrokeTransparency = 0.5
        ChatWindowConfiguration.HorizontalAlignment = Enum.HorizontalAlignment.Left
        ChatWindowConfiguration.VerticalAlignment = Enum.VerticalAlignment.Top
        ChatWindowConfiguration.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
        ChatWindowConfiguration.Enabled = true
        ChatWindowConfiguration.HeightScale = 1
        ChatWindowConfiguration.WidthScale = 1

        ChatInputBarConfiguration.BackgroundColor3 = Color3.new(155 / 255, 173 / 255, 176 / 255)
        ChatInputBarConfiguration.BackgroundTransparency = 0.2
        ChatInputBarConfiguration.PlaceholderColor3 = Color3.new(0, 0, 0)
        ChatInputBarConfiguration.TextColor3 = Color3.new(0, 0, 0)
        ChatInputBarConfiguration.TextSize = 18
        ChatInputBarConfiguration.TextStrokeColor3 = Color3.new(0, 0, 0)
        ChatInputBarConfiguration.TextStrokeTransparency = 1
        ChatInputBarConfiguration.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
        ChatInputBarConfiguration.AutocompleteEnabled = true
        ChatInputBarConfiguration.Enabled = true
        ChatInputBarConfiguration.KeyboardKeyCode = Enum.KeyCode.Slash

        BubbleChatConfiguration.BackgroundColor3 = Color3.new(250 / 255, 250 / 255, 250 / 255)
        BubbleChatConfiguration.BackgroundTransparency = 0.1
        BubbleChatConfiguration.TailVisible = true
        BubbleChatConfiguration.TextColor3 = Color3.new(57 / 255, 59 / 255, 61 / 255)
        BubbleChatConfiguration.TextSize = 16
        BubbleChatConfiguration.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        BubbleChatConfiguration.BubbleDuration = 15
        BubbleChatConfiguration.BubblesSpacing = 6
        BubbleChatConfiguration.Enabled = true
        BubbleChatConfiguration.MaxBubbles = 3
        BubbleChatConfiguration.MaxDistance = 100
        BubbleChatConfiguration.MinimizeDistance = 40
        BubbleChatConfiguration.VerticalStudsOffset = 0
    elseif chatversion == "Legacy" then
        local chatwindow = player.PlayerGui.Chat.Frame
        chatwindow.AnchorPoint = Vector2.new(0, 0)
        chatwindow.Position = UDim2.new(0, 0, 0)
    else
        warn("Unknown chat version.")
    end
end

-- Function - setCoreGuiEnabled

utils.setCoreGuiEnabled = function(coreGuiType, state)
    if typeof(state) ~= "boolean" then
        warn("Argument #2 expected boolean but got " .. typeof(state) .. ".")
        return
    end

    coreGuiType = coreGuiType:lower()

    local coreGuiTypes = {
        ["playerlist"] = Enum.CoreGuiType.PlayerList,
        ["leaderboard"] = Enum.CoreGuiType.PlayerList,
        ["health"] = Enum.CoreGuiType.Health,
        ["health bar"] = Enum.CoreGuiType.Health,
        ["backpack"] = Enum.CoreGuiType.Backpack,
        ["inventory"] = Enum.CoreGuiType.Backpack,
        ["chat"] = Enum.CoreGuiType.Chat,
        ["emotesmenu"] = Enum.CoreGuiType.EmotesMenu,
        ["emotes"] = Enum.CoreGuiType.EmotesMenu,
        ["all"] = Enum.CoreGuiType.All
    }

    local coreGuiEnum = coreGuiTypes[coreGuiType]

    if coreGuiEnum then
        starterGui:SetCoreGuiEnabled(coreGuiEnum, state)
    else
        warn("Unknown core GUI type: " .. coreGuiType)
    end
end

-- Function - modifyPlayer

utils.modifyPlayer = function(property, value)
    humanoid[property] = value
end

-- Function - setElementEnabled

utils.setElementEnabled = function(element, state)
    if typeof(element) ~= "string" then
        warn("Argument #1 expected string but got " .. typeof(element) .. ".")
    end

    if typeof(state) ~= "boolean" then
        warn("Argument #2 expected boolean but got " .. typeof(state) .. ".")
        return
    end

    local chatversion = (textChatService.ChatVersion == Enum.ChatVersion.TextChatService) and "TextChatService" or
    "Legacy"

    if element == "Chat Window" then
        if chatversion == "TextChatService" then
            textChatService.ChatWindowConfiguration.Enabled = state
        elseif chatversion == "Legacy" then
            player.PlayerGui.Chat.Frame.Visible = state
        end
    elseif element == "Chat Input Bar" then
        textChatService.ChatInputBarConfiguration.Enabled = state
    elseif element == "Chat Bubble" then
        textChatService.BubbleChatConfiguration.Enabled = state
    elseif element == "Reset Button" then
        starterGui:SetCore("ResetButtonCallback", state)
    end
end

-- Function - chatNotif

utils.chatNotif = function(text, colorName, font, size)
    if textChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
        warn("Cannot process message: TextChatService is not enabled.")
        return
    end

    local colorPresets = {
        White = Color3.fromRGB(255, 255, 255),
        Gray = Color3.fromRGB(120, 119, 119),
        Black = Color3.fromRGB(0, 0, 0),
        Red = Color3.fromRGB(255, 0, 0),
        Green = Color3.fromRGB(18, 94, 18),
        Lime = Color3.fromRGB(0, 255, 0),
        Blue = Color3.fromRGB(0, 0, 255),
        Yellow = Color3.fromRGB(255, 255, 0),
        Cyan = Color3.fromRGB(0, 255, 255),
        Magenta = Color3.fromRGB(255, 0, 255),
        Orange = Color3.fromRGB(255, 170, 0),
        Pink = Color3.fromRGB(255, 0, 191),
        Purple = Color3.fromRGB(170, 0, 255),
        Brown = Color3.fromRGB(100, 40, 0)
    }

    local fontPresets = {
        Legacy = "Legacy",
        Arial = "Arial",
        ArialBold = "ArialBold",
        SourceSans = "SourceSans",
        SourceSansBold = "SourceSansBold",
        SourceSansLight = "SourceSansLight",
        SourceSansItalic = "SourceSansItalic",
        SourceSansSemibold = "SourceSansSemibold",

        Gotham = "Gotham",
        GothamBlack = "GothamBlack",
        GothamBold = "GothamBold",
        GothamMedium = "GothamMedium",

        Bodoni = "Bodoni",
        Garamond = "Garamond",
        Cartoon = "Cartoon",
        Code = "Code",
        Highway = "Highway",
        SciFi = "SciFi",
        Arcade = "Arcade",
        Fantasy = "Fantasy",
        Antique = "Antique",
        Montserrat = "Montserrat",
        MontserratBold = "MontserratBold",
        AmaticSC = "AmaticSC",
        Bangers = "Bangers",
        Creepster = "Creepster",
        DenkOne = "DenkOne",
        Fondamento = "Fondamento",
        FredokaOne = "FredokaOne",
        GrenzeGotisch = "GrenzeGotisch",
        IndieFlower = "IndieFlower",
        Jura = "Jura",
        JosefinSans = "JosefinSans",
        Kalam = "Kalam",
        LuckiestGuy = "LuckiestGuy",
        Merriweather = "Merriweather",
        Michroma = "Michroma",
        Nunito = "Nunito",
        Oswald = "Oswald",
        PatrickHand = "PatrickHand",
        PermanentMarker = "PermanentMarker",
        Roboto = "Roboto",
        RobotoCondensed = "RobotoCondensed",
        RobotoMono = "RobotoMono",
        Sarpanch = "Sarpanch",
        SpecialElite = "SpecialElite",
        TitilliumWeb = "TitilliumWeb",
        Ubuntu = "Ubuntu",
        BuilderSans = "BuilderSans",
        BuilderSansMedium = "BuilderSansMedium",
        BuilderSansBold = "BuilderSansBold",
        BuilderSansExtraBold = "BuilderSansExtraBold",
        Arimo = "Arimo",
        ArimoBold = "ArimoBold"
    }

    local color = colorPresets[colorName] or "Black"

    if not color then
        warn("Invalid color name.")
    end

    local fontName = fontPresets[font] or "Arial"

    if not fontName then
        warn("Invalid font.")
    end

    if size > 30 then
        warn("Exceeded the allowed font size.")
        return
    end

    local colorHex = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
    local richText = string.format('<font color="%s" face="%s" size="%d">%s</font>', colorHex, fontName, size or 16, text or "Unknown message.")
    local channel = textChatService.TextChannels:FindFirstChild("RBXSystem")

    if channel then
        channel:DisplaySystemMessage(richText)
    else
        warn("Cannot send message: TextChannel RBXSystem not found.")
    end
end


-- Function - sendNotif

utils.sendNotif = function(title, text, duration, icon)
    -- Nil Handling
    if title == nil or title == "None" or title == "none" then
        title = "Untitled"
    end

    if duration == nil or duration == "Default" or duration == "default" then
        duration = 5
    else
        duration = tonumber(duration)

        if duration == nil then
            warn("Invalid duration value.")
            return
        end
    end

    -- Preventing excessive duration values
    if duration > 10 then
        warn("Duration exceeded the allowed limit.")
        return
    end

    -- Check for icon and set asset ID

    if icon == "Celestial" then
        icon = 18568429771
    elseif icon == "Corrade Private" then
        icon = 96825048421923
    end

    if icon then
        local asset
        local success, errorMessage = pcall(function()
            asset = marketplaceService:GetProductInfo(icon)
        end)

        -- Error handling

        if not success then
            warn("Failed to get asset info for icon: " .. errorMessage)
            return
        end

        if asset then
            local asset_typeid = asset.AssetTypeId
            if asset_typeid ~= 1 then -- Ensure it's an image asset
                warn("Cannot process notification: Invalid asset type. AssetTypeId: " .. asset_typeid)
                return
            end
        else
            warn("Cannot process notification: Invalid icon.")
            return
        end
    end

    -- Sending the notification

    starterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration,
        Icon = "rbxassetid://" .. tostring(icon)
    })
end

-- Function - sendMessage

utils.sendMessage = function(message)
    local chatVersion = textChatService.ChatVersion.Name

    if chatVersion == "TextChatService" then -- TextChatService
        local RBXGeneral = textChatService.TextChannels.RBXGeneral
        RBXGeneral:SendAsync(message)
    else -- LegacyChatService
        local chatEvent = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents").SayMessageRequest

        if chatEvent then
            chatEvent:FireServer(message, "All")
        end
    end
end

-- Function - fireTouchEvent

utils.fireTouchEvent = function(humanoidRootPart, touchtransmitter)
    if typeof(humanoidRootPart) ~= "Instance" then
        warn("Argument #1 expected Instance but got " .. typeof(humanoidRootPart) .. ".")
        return
    end

    if typeof(touchtransmitter) ~= "Instance" then
        warn("Argument #2 expected Instance but got " .. typeof(touchtransmitter) .. ".")
        return
    end

    firetouchinterest(humanoidRootPart, touchtransmitter, 0)
    task.wait()
    firetouchinterest(humanoidRootPart, touchtransmitter, 1)
end

-- Function - fireAllTouchEvents

utils.fireAllTouchEvents = function(humanoidRootPart, location)
    if typeof(location) ~= "Instance" then
        warn("Argument #1 expected Instance but got " .. typeof(location) .. ".")
        return
    end

    for _, descendant in ipairs(location:GetDescendants()) do
        if descendant:IsA("TouchTransmitter") then
            local touchParent = descendant.Parent

            if touchParent and touchParent:IsA("BasePart") then
                firetouchinterest(humanoidRootPart, touchParent, 0)
                wait(0.01)
                firetouchinterest(humanoidRootPart, touchParent, 1)
            else
                warn("TouchTransmitter's parent is not a BasePart.")
            end
        end
    end
end

-- Function - fireProxPrompt

utils.fireProxPrompt = function(promptPath)
    if typeof(promptPath) ~= "Instance" then
        warn("Argument #1 expected Instance but got " .. typeof(promptPath) .. ".")
        return
    end

    local hasPrompt = false

    for _, v in ipairs(promptPath:GetChildren()) do
        if v:IsA("ProximityPrompt") then
            hasPrompt = true
            fireproximityprompt(v, 1)
            break -- Fire the first found ProximityPrompt and break the loop
        end
    end

    if not hasPrompt then
        warn("ProximityPrompt was not found in: " .. tostring(promptPath))
    end
end


-- Function - fireClickEvent


utils.fireClickEvent = function(clickdetector)
    if typeof(clickdetector) ~= "Instance" then
        warn("Argument #1 expected Instance but got " .. typeof(clickdetector) .. ".")
        return
    end

    fireclickdetector(clickdetector.ClickDetector, 1)
end

-- Function - fireAllClickEvents

utils.fireAllClickEvents = function(location)
    if typeof(location) ~= "Instance" then
        warn("Argument #1 expected Instance but got " .. typeof(location) .. ".")
        return
    end

    for _, v in ipairs(location:GetDescendants()) do
        if v:IsA("ClickDetector") then
            fireclickdetector(v, 1)
        end
    end
end

-- Function - playerTeleport

utils.playerTeleport = function(delay)
    local player = players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if typeof(delay) ~= "number" then
        warn("Argument #1 expected number but got " .. typeof(delay) .. ".")
        return
    end

    if not hrp then
        warn("HumanoidRootPart not found for the local player.")
        return
    end

    local originalcframe = hrp.CFrame
    --print("Original CFrame: ", originalcframe)

    for _, otherPlayer in pairs(players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherCharacter = otherPlayer.Character or otherPlayer.CharacterAdded:Wait()
            if otherCharacter then
                local otherhrp = otherCharacter:FindFirstChild("HumanoidRootPart")

                if otherhrp then
                    --print("Teleporting to player: ", otherPlayer.Name)
                    humanoid.Sit = false
                    hrp.CFrame = otherhrp.CFrame
                    wait(delay)
                else
                    --print("HumanoidRootPart not found for player: " .. otherPlayer.Name)
                end
            else
                --print("Character not found for player: " .. otherPlayer.Name)
            end
        end
    end

    --print("Teleporting back to original position.")
    hrp.CFrame = originalcframe
end

-- Function - getTime

utils.getTime = function(displaySeconds)
    if typeof(displaySeconds) ~= "boolean" then
        warn("Argument #1 expected boolean but got " .. typeof(displaySeconds) .. ".")
        return
    end

    local is24Hour = tonumber(os.date("%H")) == tonumber(os.date("%I"))

    local timeFormat

    if is24Hour then
        timeFormat = displaySeconds and "%H:%M:%S" or "%H:%M"
    else
        timeFormat = displaySeconds and "%I:%M:%S %p" or "%I:%M %p"
    end

    return os.date(timeFormat)
end

-- Function - kill

utils.kill = function(mode)
    local supportedModes = {
        Normal = true,    -- set health to 0
        Explosion = true, -- insert explosion instance into player
        Ragdoll = false,  -- disable humanoid properties to make the player fall down then kill
        Sit = true        -- wait a couple seconds to confirm that player is sitting down and then kill
    }

    if not supportedModes[mode] then
        mode = "Normal"
        --warn("Invalid kill mode. The list of available modes is listed on the documentation.")
        --return
    end

    -- Checking for the needed conditions to proceed

    local dead

    -- Death Check

    if humanoid.Health <= 0 or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") or not character:FindFirstChild("Humanoid") then
        dead = true
    else
        dead = false
    end


    -- Proceeding with the function if the player isn't dead

    if not dead then
        if mode == "Normal" then
            humanoid.Health = 0
        elseif mode == "Explosion" then
            local explosion = Instance.new("Explosion", character)

            explosion.BlastPressure = 1000000
            explosion.BlastRadius = 10000
            explosion.DestroyJointRadiusPercent = 1
            explosion.ExplosionType = Enum.ExplosionType.NoCraters
            explosion.Position = hrp.Position
        elseif mode == "Sit" then
            humanoid.Sit = true
            wait(0.3)
            humanoid.Health = 0
        end
    else
        warn("kill failed: Player is dead. Please try again once the player is alive.")
    end
end

-- Function - getRawSiteData

utils.getRawSiteData = function(siteUrl)
    if typeof(siteUrl) ~= "string" then
        warn("Argument #1 expected string but got " .. typeof(siteUrl))
        return
    end

    return tostring(game:HttpGet(siteUrl))
end

-- Function - kick

utils.kick = function(config)
    -- Checks

    if typeof(config.reason) ~= "string" then
        warn("reason expected string but got " .. typeof(config.reason) .. ".")
        config.reason = "No reason provided."
    end

    if config.distortLighting ~= nil and typeof(config.distortLighting) ~= "boolean" then
        warn("distortLighting expected boolean but got " .. typeof(config.distortLighting) .. ".")
        config.distortLighting = false
    end

    if config.createBlur ~= nil and typeof(config.createBlur) ~= "boolean" then
        warn("createBlur expected boolean but got " .. typeof(config.createBlur) .. ".")
        config.createBlur = false
    end

    if config.customAmbience ~= nil and typeof(config.customAmbience) ~= "boolean" then
        warn("customAmbience expected boolean but got " .. typeof(config.customAmbience) .. ".")
        config.customAmbience = false
    end

    if config.deadlands ~= nil and typeof(config.deadlands) ~= "boolean" then
        warn("deadlands expected boolean but got " .. typeof(config.deadlands) .. ".")
        config.deadlands = false
    end

    --player:Kick(config.reason)

    -- Access the config options using config.<key>

    if config.distortLighting then
        -- Creating no more then 1 for whatever reason

        local found = false

        for _, v in pairs(lighting:GetChildren()) do
            if v.Name == "Distortion" and v:IsA("ColorCorrectionEffect") then
                found = true
                break
            else
                found = false
            end
        end

        if not found then
            local distortion = Instance.new("ColorCorrectionEffect", lighting)

            distortion.Name = "Distortion"
            distortion.Saturation = 5
            distortion.Contrast = 150
            distortion.Brightness = 1
        end
    end

    if config.createBlur then
        -- Creating no more then 1 for whatever reason

        local found = false

        for _, v in pairs(lighting:GetChildren()) do
            if v.Name == "Kick Blur" and v:IsA("BlurEffect") then
                found = true
                break
            else
                found = false
            end
        end

        if not found then
            local blur = Instance.new("BlurEffect", lighting)

            blur.Name = "Kick Blur"
            blur.Size = math.huge
        end
    end

    if config.customAmbience then
        -- Creating no more then 1 for whatever reason

        local found = false

        for _, v in pairs(lighting:GetChildren()) do
            if v.Name == "Custom Lighting" and v:IsA("ColorCorrectionEffect") then
                found = true
                break
            else
                found = false
            end
        end

        if not found then
            if typeof(config.customAmbienceColor) ~= "Color3" then
                warn("customAmbienceColor expected Color3 but got " .. typeof(config.customAmbienceColor) .. ".")
                config.customAmbienceColor = Color3.new(255, 255, 255)
            end

            local r = config.customAmbienceColor.r / 255
            local g = config.customAmbienceColor.g / 255
            local b = config.customAmbienceColor.b / 255
            local ambienceColor = Color3.new(r, g, b)

            local distortion = Instance.new("ColorCorrectionEffect", lighting)

            distortion.Name = "Custom Lighting"
            distortion.Saturation = 5
            distortion.Contrast = 30
            distortion.Brightness = 0
            distortion.TintColor = ambienceColor
        end
    end

    if config.deadlands then
        local char = players.LocalPlayer.Character

        if char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            if humanoid.Health > 0 then
                char:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(math.huge, math.huge, math.huge)
            end
        end
    end
end

--[[

utils.kick({
    reason = "",
    distortLighting = true,
    createBlur = true,
    customAmbience = true,
    customAmbienceColor = Color3.new(255, 0, 0),
    deadlands = true
})

]]

--[[

-- Function - createErrorPrompt

utils.createErrorPrompt = function(errorTitle, errorMessage, buttonIsPrimary)
    -- Checks and providing default values

    if typeof(errorTitle) ~= "number" and typeof(errorTitle) ~= "string" then
        warn("Argument #1 expected number or string but got " .. typeof(errorTitle) .. ".")
        errorTitle = "Error"
    end

    if typeof(errorMessage) ~= "boolean" and typeof(errorMessage) ~= "number" and typeof(errorMessage) ~= "string" and typeof(errorMessage) ~= "Instance" then
        warn("Argument #2 expected boolean, number, string, or Instance but got " .. typeof(errorMessage) .. ".")
        errorMessage = "An error occurred"
    end

    if errorTitle == "Default" or errorTitle == "default" or errorTitle == "None" or errorTitle == "none" then
        errorTitle = "Corrade Private"
    end

    -- Check if buttonIsPrimary is nil, if so set a default value (false)

    if buttonIsPrimary == nil then
        buttonIsPrimary = false
    elseif typeof(buttonIsPrimary) ~= "boolean" then -- if buttonIsPrimary is provided but is not a boolean
        warn("Argument #3 expected boolean but got " .. typeof(buttonIsPrimary) .. ".")
        buttonIsPrimary = false
    end

    local errorPrompt = getrenv().require(game:GetService("CoreGui").RobloxGui.Modules.ErrorPrompt)
    local prompt = errorPrompt.new("Default")
    prompt._hideErrorCode = true
    prompt:setErrorTitle(errorTitle)

    local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    gui.Name = "Corrade Private Error Prompt"

    local funcs = {{
        Text = "Close",
        Callback = function()
            prompt:_close()
            -- Cleanup the leftover GUI after closing
            task.spawn(function()
                for _, v in pairs(game:GetService("CoreGui"):GetDescendants()) do
                    if v.Name == "Corrade Private Error Prompt" and v:IsDescendantOf(gui) then
                        v:Destroy()
                        gui:Destroy()
                        return
                    end
                end
                gui:Destroy()  -- Destroy ScreenGui if no error prompt found
            end)
        end,
        Primary = buttonIsPrimary -- Set the value of Primary based on buttonIsPrimary
    }}

    prompt:updateButtons(funcs, "Default")
    prompt:setParent(gui)
    prompt:_open(tostring(errorMessage))
end

]]

-- Function - getPlayerTools : Checks inside the players backpack using the given name or counts all tools on the player

utils.getPlayerTools = function(mode, itemName)
    local validModes = {
        Specific = true,
        Count = true
    }

    if not validModes[mode] then
        warn("'" .. mode .. "' is not a valid mode.")
        return
    end

    if mode == "Specific" then
        -- Check the Backpack for a specific item

        for _, v in pairs(player.Backpack:GetChildren()) do
            if v:IsA("Tool") and v.Name == itemName then
                return v -- Return the item if found
            end
        end

        -- Check the Character for a specific item

        for _, v in pairs(player.Character:GetChildren()) do
            if v:IsA("Tool") and v.Name == itemName then
                return v -- Return the item if found
            end
        end

        return "'" .. itemName .. "' was not found." -- Return nil if the item is not found
    elseif mode == "Count" then
        -- Count all tools in the Backpack and Character

        local count = 0

        for _, v in pairs(player.Backpack:GetChildren()) do
            if v:IsA("Tool") then
                count += 1
            end
        end

        for _, v in pairs(player.Character:GetChildren()) do
            if v:IsA("Tool") then
                count += 1
            end
        end

        return count
    end
end

-- Function - getTool

utils.getTool = function(mode, toolName)
    local validModes = {
        Specific = true,
        CurrentlyHeld = true
    }

    if not validModes[mode] then
        warn("'" .. mode .. "' is not a valid mode.")
        return
    end

    if mode == "Specific" then
        if toolName == nil or toolName == "" then
            warn("Tool name cannot be nil or empty for 'Specific' mode.")
            return false
        end

        -- Check both Backpack and Character for the specific tool
        local backpackAndCharacter = player.Backpack or player.Character

        for _, v in pairs(player.Backpack:GetDescendants()) do
            if v:IsA("Tool") and v.Name == toolName then
                return true
            end
        end

        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("Tool") and v.Name == toolName then
                return true
            end
        end

        return false
    elseif mode == "CurrentlyHeld" then
        local character = player.Character

        for _, v in pairs(character:GetDescendants()) do
            if v:IsA("Tool") then
                return v
            end
        end

        return "No tool currently being held."
    end
end

-- Function - isAlive

utils.isAlive = function()
    local player = game.Players.LocalPlayer

    -- Function to get the Humanoid

    local function getHumanoid()
        return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    end

    -- Function to check if the player is alive

    local function checkAlive()
        local humanoid = getHumanoid()
        if not humanoid then
            warn("Failed to get alive status: Humanoid not found.")
            return false
        end

        -- Check health status
        if humanoid.Health > 0 then
            --print("Player is alive and functioning.")
            return true
        else
            --print("Failed to get alive status: Humanoid is dead.")
            return false
        end
    end

    -- Function to handle character respawn

    local function onCharacterAdded(character)
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.HealthChanged:Connect(function(health)
                if health <= 0 then
                    --print("Player has died.")
                else
                    --print("Player is alive.")
                end
            end)

            -- Check character parts after respawn

            local characterParts = {
                Head = "MeshPart",
                LeftFoot = "MeshPart",
                LeftHand = "MeshPart",
                LeftLowerArm = "MeshPart",
                LeftLowerLeg = "MeshPart",
                LeftUpperArm = "MeshPart",
                LowerTorso = "MeshPart",
                RightFoot = "MeshPart",
                RightHand = "MeshPart",
                RightLowerArm = "MeshPart",
                RightLowerLeg = "MeshPart",
                RightUpperArm = "MeshPart",
                RightUpperLeg = "MeshPart",
                UpperTorso = "MeshPart",
                HumanoidRootPart = "Part"
            }

            -- Check if all parts exist in the character

            for partName, partType in pairs(characterParts) do
                local part = character:FindFirstChild(partName)

                if not part then
                    warn(partName .. " not found in the character.")
                elseif not part:IsA(partType) then
                    warn(partName .. " is not the expected type: " .. partType)
                end
            end
        end
    end

    player.CharacterAdded:Connect(onCharacterAdded) -- Connect to character respawn

    -- Initial character setup

    local character = player.Character
    if character then
        return checkAlive()
    end

    return false -- Default to false if the character or humanoid isn't found
end

-- Function - checkOwnership

utils.fetchOwnership = function(mode, id)
    local validModes = {
        Badge = true,
        Gamepass = true,
        Asset = true,
        ["Developer Product"] = true
    }

    if not validModes[mode] then
        warn("'" .. mode .. "' is not a valid mode.")
        return false
    end

    local success, productInfo = pcall(function()
        return marketplaceService:GetProductInfo(id)
    end)

    if not success then
        warn("Failed to retrieve ownership for asset ID " .. id)
        return false
    end

    -- Badge Mode

    if mode == "Badge" then
        local badgeService = game:GetService("BadgeService")
        local success, hasBadge = pcall(function()
            return badgeService:UserHasBadgeAsync(player.UserId, id)
        end)

        if not success then
            warn("Failed to check badge ownership for ID " .. id)
            return false
        end

        return hasBadge

        -- Gamepass Mode
    elseif mode == "Gamepass" then
        local success, hasPass = pcall(function()
            return marketplaceService:UserOwnsGamePassAsync(player.UserId, id)
        end)

        if not success then
            warn("Failed to check gamepass ownership for ID " .. id)
            return false
        end

        return hasPass

        -- Asset Mode
    elseif mode == "Asset" then
        local success, ownsAsset = pcall(marketplaceService.PlayerOwnsAsset, marketplaceService, player, id)

        if not success then
            warn("Error checking if {player.Name} owns {ASSET_NAME}: {errorMessage}")
            return
        end

        return ownsAsset or false
    end
end

utils.getCharInstance = function(partName)
    local requestedPart = game:GetService("Players").LocalPlayer.Character:FindFirstChild(partName)

    if requestedPart then
        return requestedPart
    else
        --warn(partName .. " was not found inside character.")
    end
end

utils.hash = function(text, algorithm)
    local hashLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Secure-Hash-Algorithm/refs/heads/master/sha2.lua"))()
    
    -- Valid algorithms

    local validAlgorithms = {
        ["SHA-224"] = hashLib.sha224,
        ["SHA-256"] = hashLib.sha256,
        ["SHA-512/224"] = hashLib.sha512_224,
        ["SHA-512/256"] = hashLib.sha512_256,
        ["SHA-384"] = hashLib.sha384,
        ["SHA-512"] = hashLib.sha512,
        ["SHA3-224"] = hashLib.sha3_224,
        ["SHA3-256"] = hashLib.sha3_256,
        ["SHA3-384"] = hashLib.sha3_384,
        ["SHA3-512"] = hashLib.sha3_512,
        ["BLAKE2b"] = hashLib.blake2b,
        ["BLAKE2s"] = hashLib.blake2s,
        ["BLAKE2bp"] = hashLib.blake2bp,
        ["BLAKE2sp"] = hashLib.blake2sp,
    }
    
    local hashFunction = validAlgorithms[algorithm]
    if not hashFunction then
        warn("Invalid hash algorithm specified: " .. tostring(algorithm))
    end
    
    return hashFunction(text)
end

utils.randomString = function()
    local array = {}
    for i = 1, math.random(10, 100) do
        array[i] = string.char(math.random(32, 126))
    end

    return table.concat(array)
end


return utils
