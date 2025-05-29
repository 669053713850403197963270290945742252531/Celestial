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
        warn("utils.updateAudio: Invalid path object provided.")
    end

    if not found then
        warn("utils.updateAudio: Audio with SoundId " .. soundId .. " not found.")
    end
end


-- Function - gameTeleport

utils.gameTeleport = function(arg)
    if typeof(arg) == "number" then
        teleportService:Teleport(arg)
    elseif typeof(arg) == "string" and arg == "Rejoin" then
        teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    else
        warn("Argument #2 (arg) expected a number or string value. but got a " .. typeof(arg) .. " value.")
    end

    --[[

    -- Checks

    if typeof(mode) ~= "string" then
        warn("utils.gameTeleport: Argument #1 expected string but got a " .. typeof(mode) .. ".")
        mode = "PlaceId"
    end

    -- Teleport

    if mode == "PlaceId" then
        if typeof(placeId) ~= "number" then
            warn("utils.gameTeleport: Argument #2 expected number but got a " .. typeof(placeId) .. ".")
            return
        end

        teleportService:Teleport(placeId)
    elseif mode == "Rejoin" then
        teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end

    ]]
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
            warn("utils.positionChatWindow: Invalid horizontal or vertical alignment provided.")
        end
    elseif chatversion == "Legacy" then
        local chatwindow = player.PlayerGui.Chat.Frame
        if validHorizontalAlignments[horizontalAlignment] and validVerticalAlignments[verticalAlignment] then
            chatwindow.AnchorPoint = Vector2.new(
            (horizontalAlignment == "Center" and 0.5) or (horizontalAlignment == "Left" and 0) or 1,
                (verticalAlignment == "Center" and 0.5) or (verticalAlignment == "Top" and 0) or 1)
            chatwindow.Position = UDim2.new(chatwindow.AnchorPoint.X, 0, chatwindow.AnchorPoint.Y, 0)
        else
            warn("utils.positionChatWindow: Invalid horizontal or vertical alignment provided.")
        end
    else
        warn("utils.positionChatWindow: Unknown chat version.")
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
        warn("utils.resetChatWindow: Unknown chat version.")
    end
end

-- Function - setCoreGuiEnabled

utils.setCoreGuiEnabled = function(coreGuiType, state)
    if typeof(state) ~= "boolean" then
        warn("utils.setCoreGuiEnabled: Argument #2 expected boolean but got a " .. typeof(state) .. ".")
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
        warn("utils.setCoreGuiEnabled: Unknown core GUI type: " .. coreGuiType)
    end
end

-- Function - setElementEnabled

utils.setElementEnabled = function(element, state)
    if typeof(element) ~= "string" then
        warn("utils.setElementEnabled: Argument #1 expected string but got a " .. typeof(element) .. ".")
    end

    if typeof(state) ~= "boolean" then
        warn("utils.setElementEnabled: Argument #2 expected boolean but got a " .. typeof(state) .. ".")
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
        warn("utils.chatNotif: Cannot process message: TextChatService is not enabled.")
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
        warn("utils.chatNotif: Invalid color name.")
    end

    local fontName = fontPresets[font] or "Arial"

    if not fontName then
        warn("utils.chatNotif: Invalid font.")
    end

    if size > 30 then
        warn("utils.chatNotif: Exceeded the allowed font size.")
        return
    end

    local colorHex = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
    local richText = string.format('<font color="%s" face="%s" size="%d">%s</font>', colorHex, fontName, size or 16, text or "Unknown message.")
    local channel = textChatService.TextChannels:FindFirstChild("RBXSystem")

    if channel then
        channel:DisplaySystemMessage(richText)
    else
        warn("utils.chatNotif: Cannot send message: TextChannel RBXSystem not found.")
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
            warn("utils.sendNotif: Invalid duration value.")
            return
        end
    end

    -- Preventing excessive duration values

    if duration > 10 then
        warn("utils.sendNotif: Duration exceeded the allowed limit.")
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
            warn("utils.sendNotif: Failed to get asset info for icon: " .. errorMessage)
            return
        end

        if asset then
            local asset_typeid = asset.AssetTypeId
            if asset_typeid ~= 1 then -- Ensure it's an image asset
                warn("utils.sendNotif: Cannot process notification: Invalid asset type. AssetTypeId: " .. asset_typeid)
                return
            end
        else
            warn("utils.sendNotif: Cannot process notification: Invalid icon.")
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

utils.fireTouchEvent = function(humanoidRootPart, touchTransmitterParent)
    if typeof(humanoidRootPart) ~= "Instance" then
        warn("utils.fireTouchEvent: Argument #1 (humanoidRootPart) expected Instance but got a " .. typeof(humanoidRootPart) .. " value.")
        return
    end

    if typeof(touchTransmitterParent) ~= "Instance" then
        warn("utils.fireTouchEvent: Argument #2 (touchTransmitterParent) expected Instance but got a " .. typeof(touchTransmitterParent) .. " value.")
        return
    end
    
    firetouchinterest(humanoidRootPart, touchTransmitterParent, 0)
    task.wait()
    firetouchinterest(humanoidRootPart, touchTransmitterParent, 1)
end

-- Function - fireAllTouchEvents

utils.fireAllTouchEvents = function(humanoidRootPart, location)
    if typeof(location) ~= "Instance" then
        warn("utils.fireAllTouchEvents: Argument #1 expected Instance but got a " .. typeof(location) .. ".")
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
                warn("utils.fireAllTouchEvents: TouchTransmitter's parent is not a BasePart.")
            end
        end
    end
end

-- Function - fireProxPrompt

utils.fireProxPrompt = function(promptPath)
    if typeof(promptPath) ~= "Instance" then
        warn("utils.fireProxPrompt: Argument #1 expected Instance but got a " .. typeof(promptPath) .. ".")
        return
    end

    local hasPrompt = false

    for _, v in ipairs(promptPath:GetChildren()) do
        if v:IsA("ProximityPrompt") then
            hasPrompt = true
            fireproximityprompt(v, 1)
            break
        end
    end

    if not hasPrompt then
        warn("utils.fireProxPrompt: ProximityPrompt was not found in: " .. tostring(promptPath))
    end
end


-- Function - fireClickEvent


utils.fireClickEvent = function(target, delay)
    if typeof(target) ~= "Instance" then
        warn("utils.fireClickEvent: Argument #1 expected Instance but got a " .. typeof(target) .. ".")
        return
    end

    delay = delay or 0

    if target:IsA("ClickDetector") then
        fireclickdetector(target)
    else
        for _, v in ipairs(target:GetDescendants()) do
            if v:IsA("ClickDetector") then
                fireclickdetector(v)
                
                if delay > 0 then
                    task.wait(delay)
                end
            end
        end
    end
end

-- Function - getTime

utils.getTime = function(displaySeconds)
    local time = os.date("*t")
    local hour = time.hour
    local minute = time.min
    local second = time.sec
    
    local ampm = "AM"
    if hour >= 12 then
        ampm = "PM"
    end
    
    -- Convert to 12 hour

    if hour == 0 then
        hour = 12 -- me when midnight 😨
    elseif hour > 12 then
        hour = hour - 12
    end

    if displaySeconds then
        return string.format("%02d:%02d:%02d %s", hour, minute, second, ampm)
    else
        return string.format("%02d:%02d %s", hour, minute, ampm)
    end
end

-- Function - getDate

utils.getDate = function()
    return os.date("%m/%d/%Y")
end

-- Function - getRawSiteData

utils.getRawData = function(siteUrl)
    if typeof(siteUrl) ~= "string" then
        warn("utils.getRawData: Argument #1 expected string but got a " .. typeof(siteUrl))
        return
    end

    return tostring(game:HttpGet(siteUrl))
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
        warn("utils.fetchOwnership: '" .. mode .. "' is not a valid mode.")
        return false
    end

    local success, productInfo = pcall(function()
        return marketplaceService:GetProductInfo(id)
    end)

    if not success then
        warn("utils.fetchOwnership: Failed to retrieve ownership for asset ID " .. id)
        return false
    end

    -- Badge Mode

    if mode == "Badge" then
        local badgeService = game:GetService("BadgeService")
        local success, hasBadge = pcall(function()
            return badgeService:UserHasBadgeAsync(player.UserId, id)
        end)

        if not success then
            warn("utils.fetchOwnership: Failed to check badge ownership for ID " .. id)
            return false
        end

        return hasBadge

        -- Gamepass Mode
    elseif mode == "Gamepass" then
        local success, hasPass = pcall(function()
            return marketplaceService:UserOwnsGamePassAsync(player.UserId, id)
        end)

        if not success then
            warn("utils.fetchOwnership: Failed to check gamepass ownership for ID " .. id)
            return false
        end

        return hasPass

        -- Asset Mode
    elseif mode == "Asset" then
        local success, ownsAsset = pcall(marketplaceService.PlayerOwnsAsset, marketplaceService, player, id)

        if not success then
            warn("utils.fetchOwnership: Error checking if {player.Name} owns {ASSET_NAME}: {errorMessage}")
            return
        end

        return ownsAsset or false
    end
end

utils.hash = function(text, algorithm)
    local hashLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Hash%20Library.lua"))()
    
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
        warn("utils.hash: Invalid hash algorithm: " .. tostring(algorithm))
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

utils.round = function(number, decimalPlaces)
    local formatString = "%." .. decimalPlaces .. "f"
    local roundedNumber = string.format(formatString, number)
    return tonumber(roundedNumber)
end

utils.success = function(text)
    if textChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
        warn("utils.success: Cannot process message: TextChatService is not enabled.")
        return
    end

    local font = "ArialBold"
    local color = Color3.fromRGB(0, 255, 0)
    local size = 16

    local colorHex = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
    local richText = string.format('<font color="%s" face="%s" size="%d">%s</font>', colorHex, font, size, text or "Unknown message.")
    local channel = textChatService.TextChannels:FindFirstChild("RBXSystem")

    if channel then
        channel:DisplaySystemMessage(richText)
    else
        warn("utils.success: Cannot send message: TextChannel RBXSystem not found.")
    end

end

utils.error = function(text)
    if textChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
        warn("utils.error: Cannot process message: TextChatService is not enabled.")
        return
    end

    local font = "ArialBold"
    local color = Color3.fromRGB(255, 0, 0)
    local size = 30

    local colorHex = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
    local richText = string.format('<font color="%s" face="%s" size="%d">%s</font>', colorHex, font, size, text or "Unknown message.")
    local channel = textChatService.TextChannels:FindFirstChild("RBXSystem")

    if channel then
        channel:DisplaySystemMessage(richText)
    else
        warn("utils.error: Cannot send message: TextChannel RBXSystem not found.")
    end

end

utils.checkFunction = function(functionName)
    if typeof(functionName) == "function" then
        return true
    else
        --warn(tostring(functionName) .. " did not return a function type.")
        return false
    end
end

return utils