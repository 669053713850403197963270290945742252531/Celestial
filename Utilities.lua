local utils = {}

-- Services
local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local starterpack = game:GetService("StarterPack")
local soundservice = game:GetService("SoundService")
local textchatservice = game:GetService("TextChatService")
local tweenservice = game:GetService("TweenService")
local teleportservice = game:GetService("TeleportService")
local startergui = game:GetService("StarterGui")
local marketplaceservice = game:GetService("MarketplaceService")

local console = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Console%20Printing.lua"))()

local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character.Humanoid
local humrootpart = player.Character.HumanoidRootPart

--[[

-- Function - getPlayers

utils.getPlayers = function()
    return #players:GetPlayers()
end

-- Function - fetchServiceInfo

utils.fetchServiceInfo = function(service)
    local known_properties = {}

    if service == "Workspace" then
        known_properties = {
            CurrentCamera = workspace.CurrentCamera,
            DistributedGameTime = workspace.DistributedGameTime,
            WorldPivot = workspace.WorldPivot,
            AllowThirdPartySales = workspace.AllowThirdPartySales,
            FallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight,
            GlobalWind = workspace.GlobalWind,
            Gravity = workspace.Gravity
        }
    elseif service == "Players" then
        known_properties = {
            BubbleChat = players.BubbleChat,
            ClassicChat = players.ClassicChat,
            LocalPlayer = players.LocalPlayer,
            MaxPlayers = players.MaxPlayers,
            PreferredPlayers = players.PreferredPlayers,
            RespawnTime = players.RespawnTime,
            CharacterAutoLoads = players.CharacterAutoLoads
        }
    elseif service == "Lighting" then
        known_properties = {
            Ambient = lighting.Ambient,
            Brightness = lighting.Brightness,
            ColorShift_Bottom = lighting.ColorShift_Bottom,
            ColorShift_Top = lighting.ColorShift_Top,
            EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = lighting.EnvironmentSpecularScale,
            GlobalShadows = lighting.GlobalShadows,
            OutdoorAmbient = lighting.OutdoorAmbient,
            ShadowSoftness = lighting.ShadowSoftness,
            ClockTime = lighting.ClockTime,
            GeographicLatitude = lighting.GeographicLatitude,
            TimeOfDay = lighting.TimeOfDay,
            FogColor = lighting.FogColor,
            FogEnd = lighting.FogEnd,
            FogStart = lighting.FogStart
        }
    elseif service == "StarterPack" then
        local children = starterpack:GetChildren()
        print("Total Items: " .. #children)
        for _, child in ipairs(children) do
            print(child.Name)
        end
        return
    elseif service == "SoundService" then
        known_properties = {
            AmbientReverb = soundservice.AmbientReverb,
            DistanceFactor = soundservice.DistanceFactor,
            DopplerScale = soundservice.DopplerScale,
            RespectFilteringEnabled = soundservice.RespectFilteringEnabled,
            RolloffScale = soundservice.RolloffScale
        }
    elseif service == "TextChatService" then
        local ChatWindowConfiguration = textchatservice.ChatWindowConfiguration
        known_properties = {
            ChatTranslationEnabled = textchatservice.ChatTranslationEnabled,
            ChatVersion = textchatservice.ChatVersion,
            ChatWindowBackground = ChatWindowConfiguration.BackgroundColor3,
            ChatWindowTransparency = ChatWindowConfiguration.BackgroundTransparency,
            ChatWindowFont = ChatWindowConfiguration.FontFace,
            TextColor = ChatWindowConfiguration.TextColor3,
            TextSize = ChatWindowConfiguration.TextSize,
            HeightScale = ChatWindowConfiguration.HeightScale,
            WidthScale = ChatWindowConfiguration.WidthScale
        }
    end

    for prop, value in pairs(known_properties) do
        print(prop .. ": " .. tostring(value))
    end
end

-- Function - fetchPlayerDetails

utils.fetchPlayerDetails = function(targetName)
    local target = players:FindFirstChild(targetName)
    if not target then
        print("Target player not found: " .. targetName)
        return
    end

    local character = target.Character

    if character and character:FindFirstChild("Humanoid") then
        local team = target.Team or "None"
        local known_properties = {
            DisplayName = target.DisplayName,
            Name = target.Name,
            UserId = target.UserId,
            MembershipType = tostring(target.MembershipType),
            GameplayPaused = target.GameplayPaused,
            NameOcclusion = humanoid.NameOcclusion,
            RigType = humanoid.RigType,
            MaxHealth = humanoid.MaxHealth,
            Health = humanoid.Health,
            HipHeight = humanoid.HipHeight,
            MaxSlopeAngle = humanoid.MaxSlopeAngle,
            WalkSpeed = humanoid.WalkSpeed,
            CameraMode = target.CameraMode,
            HealthDisplayDistance = target.HealthDisplayDistance,
            NameDisplayDistance = target.NameDisplayDistance,
            Neutral = target.Neutral,
            Team = team,
            TeamColor = target.TeamColor
        }

        for prop, value in pairs(known_properties) do
            print(prop .. ": " .. tostring(value))
        end
    else
        print("Character or Humanoid not found for player: " .. target.Name)
    end
end

-- Function - createAudio

utils.createAudio = function(PlayOnRemove, SoundId, Looped, Volume)
    local audio = Instance.new("Sound", soundservice)
    audio.PlayOnRemove = PlayOnRemove
    audio.SoundId = "rbxassetid://" .. SoundId
    audio.Looped = Looped
    audio.Volume = Volume

    if PlayOnRemove then
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
            if v:IsA("Sound") and v.SoundId == "rbxassetid://" .. soundId then
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

-- Function - teleportToCFrame

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
    if character and character.PrimaryPart then
        character:SetPrimaryPartCFrame(part.CFrame)
    else
        warn("Character or PrimaryPart not found")
    end
end

]]

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

local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humrootpart = character:WaitForChild("HumanoidRootPart")
local tweenservice = game:GetService("TweenService")

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

    if not humrootpart then
        if smooth then
            restoreOriginalStates()
            workspace.Gravity = originalGravity
        end
        return
    end

    local targetCFrame = stringToCFrame(cframeString)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tweenGoal = {CFrame = targetCFrame}

    local tween = tweenservice:Create(humrootpart, tweenInfo, tweenGoal)
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

    if not humrootpart then
        if smooth then
            restoreOriginalStates()

            workspace.Gravity = originalGravity
        end
        return
    end

    local targetCFrame = targetPart.CFrame
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tweenGoal = {CFrame = targetCFrame}

    local tween = tweenservice:Create(humrootpart, tweenInfo, tweenGoal)
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

utils.gameTeleport = function(placeId)
    teleportservice:Teleport(placeId)
end

-- Function - gameInstanceTeleport

utils.gameInstanceTeleport = function(placeId, instanceId)
    teleportservice:TeleportToPlaceInstance(placeId, instanceId)
end

-- Function - positionChatWindow

utils.positionChatWindow = function(horizontalAlignment, verticalAlignment)
    local chatversion = (textchatservice.ChatVersion == Enum.ChatVersion.TextChatService) and "TextChatService" or "Legacy"

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
            textchatservice.ChatWindowConfiguration.HorizontalAlignment = validHorizontalAlignments[horizontalAlignment]
            textchatservice.ChatWindowConfiguration.VerticalAlignment = validVerticalAlignments[verticalAlignment]
        else
            warn("Invalid horizontal or vertical alignment provided.")
        end

    elseif chatversion == "Legacy" then
        local chatwindow = player.PlayerGui.Chat.Frame
        if validHorizontalAlignments[horizontalAlignment] and validVerticalAlignments[verticalAlignment] then
            chatwindow.AnchorPoint = Vector2.new((horizontalAlignment == "Center" and 0.5) or (horizontalAlignment == "Left" and 0) or 1, (verticalAlignment == "Center" and 0.5) or (verticalAlignment == "Top" and 0) or 1)
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
    local chatversion = (textchatservice.ChatVersion == Enum.ChatVersion.TextChatService) and "TextChatService" or "Legacy"

    if chatversion == "TextChatService" then
        local ChatWindowConfiguration = textchatservice.ChatWindowConfiguration
        local ChatInputBarConfiguration = textchatservice.ChatInputBarConfiguration
        local BubbleChatConfiguration = textchatservice.BubbleChatConfiguration

        ChatWindowConfiguration.BackgroundColor3 = Color3.new(25/255, 27/255, 29/255)
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

        ChatInputBarConfiguration.BackgroundColor3 = Color3.new(155/255, 173/255, 176/255)
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

        BubbleChatConfiguration.BackgroundColor3 = Color3.new(250/255, 250/255, 250/255)
        BubbleChatConfiguration.BackgroundTransparency = 0.1
        BubbleChatConfiguration.TailVisible = true
        BubbleChatConfiguration.TextColor3 = Color3.new(57/255, 59/255, 61/255)
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
        warn("Expected boolean but got " .. typeof(state) .. ".")
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
        startergui:SetCoreGuiEnabled(coreGuiEnum, state)
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

    local chatversion = (textchatservice.ChatVersion == Enum.ChatVersion.TextChatService) and "TextChatService" or "Legacy"

    if element == "Chat Window" then
        if chatversion == "TextChatService" then
            textchatservice.ChatWindowConfiguration.Enabled = state
        elseif chatversion == "Legacy" then
            player.PlayerGui.Chat.Frame.Visible = state
        end
    elseif element == "Chat Input Bar" then
        textchatservice.ChatInputBarConfiguration.Enabled = state
    elseif element == "Chat Bubble" then
        textchatservice.BubbleChatConfiguration.Enabled = state
    elseif element == "Reset Button" then
        startergui:SetCore("ResetButtonCallback", state)
    end
end

-- Function - chatNotif

utils.chatNotif = function(text, colorName, font, size)
    if textchatservice.ChatVersion ~= Enum.ChatVersion.TextChatService then
        utils.error("Cannot process message: TextChatService is not enabled.")
        return
    end

    local colorPresets = {
        White = Color3.fromRGB(255, 255, 255), Gray = Color3.fromRGB(120, 119, 119),
        Black = Color3.fromRGB(0, 0, 0), Red = Color3.fromRGB(255, 0, 0),
        Green = Color3.fromRGB(18, 94, 18), Lime = Color3.fromRGB(0, 255, 0),
        Blue = Color3.fromRGB(0, 0, 255), Yellow = Color3.fromRGB(255, 255, 0),
        Cyan = Color3.fromRGB(0, 255, 255), Magenta = Color3.fromRGB(255, 0, 255),
        Orange = Color3.fromRGB(255, 170, 0), Pink = Color3.fromRGB(255, 0, 191),
        Purple = Color3.fromRGB(170, 0, 255), Brown = Color3.fromRGB(100, 40, 0)
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

    local color = colorPresets[colorName]

    if not color then
        warn("Invalid color name.")
    end

    local fontName = fontPresets[font]

    if not fontName then
        warn("Invalid font.")
    end

    if size > 30 then
        utils.error("Exceeded the allowed font size.")
        return
    end

    local colorHex = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
    local richText = string.format('<font color="%s" face="%s" size="%d">%s</font>', colorHex, fontName, size, text)
    local channel = textchatservice.TextChannels:FindFirstChild("RBXSystem")

    if channel then
        channel:DisplaySystemMessage(richText)
    else
        utils.error("Cannot send message: TextChannel RBXSystem not found.")
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
            utils.error("Invalid duration value.")
            return
        end
    end

    -- Preventing excessive duration values
    
    if duration > 10 then
        utils.error("Exceeded the allowed limit.")
        return
    end

    if icon == nil or icon == "Default" or icon == "default" then
        icon = "rbxassetid://18568429771"
    end

    if icon ~= "" and icon ~= "rbxassetid://18568429771" then
        local asset
        pcall(function()
            asset = marketplaceservice:GetProductInfo(icon)
        end)

        if asset then
            local asset_typeid = asset.AssetTypeId
            if asset_typeid ~= 1 then
                utils.error("Cannot process notification: Invalid asset type.")
                return
            end
        else
            utils.error("Cannot process notification: Invalid icon.")
            return
        end
    end

    startergui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration,
        Icon = icon
    })
end



-- Function - sendMessage

utils.sendMessage = function(message)
    local RBXGeneral = textchatservice.TextChannels.RBXGeneral
    RBXGeneral:SendAsync(message)
end

-- Function - success

utils.success = function(content)
    console.custom_print(content, "rbxasset://textures/AudioDiscovery/done.png", Color3.fromRGB(9, 255, 0))
end

-- Function - error

utils.error = function(content)
    console.custom_print(content, "rbxasset://textures/AudioDiscovery/error.png", Color3.fromRGB(255, 0, 0))
end

-- Function - fireTouchEvent

utils.fireTouchEvent = function(touchtransmitter)
    if typeof(touchtransmitter) ~= "Instance" then
        warn("Expected Instance but got " .. typeof(touchtransmitter) .. ".")
        return
    end

    firetouchinterest(humrootpart, touchtransmitter, 1)
end

-- Function - fireProxPrompt

utils.fireProxPrompt = function(proximityprompt)
    if typeof(proximityprompt) ~= "Instance" then
        warn("Expected Instance but got " .. typeof(proximityprompt) .. ".")
        return
    end

    fireproximityprompt(proximityprompt.ProximityPrompt, 1)
end

-- Function - playerTeleport

utils.playerTeleport = function(delay)
    local player = players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humrootpart = character:FindFirstChild("HumanoidRootPart")

    if typeof(delay) ~= "number" then
        warn("Expected number but got " .. typeof(delay) .. ".")
        return
    end

    if not humrootpart then
        warn("HumanoidRootPart not found for the local player.")
        return
    end

    local originalcframe = humrootpart.CFrame
    --print("Original CFrame: ", originalcframe)

    for _, otherPlayer in pairs(players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherCharacter = otherPlayer.Character or otherPlayer.CharacterAdded:Wait()
            if otherCharacter then
                local otherHumrootpart = otherCharacter:FindFirstChild("HumanoidRootPart")

                if otherHumrootpart then
                    --print("Teleporting to player: ", otherPlayer.Name)
                    humanoid.Sit = false
                    humrootpart.CFrame = otherHumrootpart.CFrame
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
    humrootpart.CFrame = originalcframe
end

-- Function - getTime

utils.getTime = function(displaySeconds)
    if typeof(displaySeconds) ~= "boolean" then -- if the given value isn't nil, check if its a boolean
        warn("Expected boolean but got " .. typeof(displaySeconds) .. ".")
        return
    end
    
    if displaySeconds then
        return os.date("%I:%M:%S %p")
    else
        return os.date("%I:%M %p")
    end
end

return utils
