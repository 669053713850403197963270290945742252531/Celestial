local utils = {}


-- Services

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local starterpack = game:GetService("StarterPack")
local soundservice = game:GetService("SoundService")
local textchatservice = game:GetService("TextChatService")

local players = game:GetService("Players")
local tweenservice = game:GetService("TweenService")
local teleportservice = game:GetService("TeleportService")
local startergui = game:GetService("StarterGui")
local marketplaceservice = game:GetService("MarketplaceService")

local console = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Console%20Printing.lua"))()
local player = players.LocalPlayer


-- Function - getPlayers


utils.getPlayers = function()
	local players = #players:GetPlayers()
	return players
end


-- Function - fetchServiceInfo


utils.fetchServiceInfo = function(service:string)
	if service == "Workspace" or service == "workspace" or service == "wspace" or service == "ws" then
		
		
		-- Workspace
		
		
		local known_properties = {
			CurrentCamera = workspace.CurrentCamera,
			DistributedGameTime = workspace.DistributedGameTime,
			WorldPivot = workspace.WorldPivot,
			AllowThirdPartySales = workspace.AllowThirdPartySales,
			FallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight,
			GlobalWind = workspace.GlobalWind,
			Gravity = workspace.Gravity
		}

		-- Convert properties to string format
		
		local propStrings = {
			"CurrentCamera: " .. tostring(known_properties.CurrentCamera),
			"DistributedGameTime: " .. known_properties.DistributedGameTime,
			"WorldPivot: " .. tostring(known_properties.WorldPivot),
			"AllowThirdPartySales: " .. tostring(known_properties.AllowThirdPartySales),
			"FallenPartsDestroyHeight: " .. known_properties.FallenPartsDestroyHeight,
			"GlobalWind: " .. tostring(known_properties.GlobalWind),
			"Gravity: " .. known_properties.Gravity
		}

		-- Print each property
		
		for _, propString in ipairs(propStrings) do
			print(propString)
		end

	elseif service == "Players" or service == "players" or service == "plyrs" or service == "plrs" then
		
		
		-- Players
		
		
		local known_properties = {
			BubbleChat = players.BubbleChat,
			ClassicChat = players.ClassicChat,
			LocalPlayer = players.LocalPlayer,
			MaxPlayers = players.MaxPlayers,
			PreferredPlayers = players.PreferredPlayers,
			RespawnTime = players.RespawnTime,
			CharacterAutoLoads = players.CharacterAutoLoads
		}

		-- Convert properties to string format
		
		local propStrings = {
			"BubbleChat: " .. tostring(known_properties.BubbleChat),
			"ClassicChat: " .. tostring(known_properties.ClassicChat),
			"LocalPlayer: " .. (known_properties.LocalPlayer and known_properties.LocalPlayer.Name or "N/A"),
			"MaxPlayers: " .. known_properties.MaxPlayers,
			"PreferredPlayers: " .. known_properties.PreferredPlayers,
			"RespawnTime: " .. known_properties.RespawnTime,
			"CharacterAutoLoads: " .. tostring(known_properties.CharacterAutoLoads)
		}

		-- Print each property
		
		for _, propString in ipairs(propStrings) do
			print(propString)
		end

	elseif service == "Lighting" or service == "lighting" or service == "light" or service == "lgt" then
		
		
		-- Lighting
		
		
		local known_properties = {
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

		-- Convert properties to string format
		
		local propStrings = {
			"Ambient: " .. tostring(known_properties.Ambient),
			"Brightness: " .. known_properties.Brightness,
			"ColorShift_Bottom: " .. tostring(known_properties.ColorShift_Bottom),
			"ColorShift_Top: " .. tostring(known_properties.ColorShift_Top),
			"EnvironmentDiffuseScale: " .. known_properties.EnvironmentDiffuseScale,
			"EnvironmentSpecularScale: " .. known_properties.EnvironmentSpecularScale,
			"GlobalShadows: " .. tostring(known_properties.GlobalShadows),
			"OutdoorAmbient: " .. tostring(known_properties.OutdoorAmbient),
			"ShadowSoftness: " .. known_properties.ShadowSoftness,
			"ClockTime: " .. known_properties.ClockTime,
			"GeographicLatitude: " .. tostring(known_properties.GeographicLatitude),
			"TimeOfDay: " .. known_properties.TimeOfDay,
			"FogColor: " .. tostring(known_properties.FogColor),
			"FogEnd: " .. known_properties.FogEnd,
			"FogStart: " .. known_properties.FogStart
		}

		-- Print each property
		
		for _, propString in ipairs(propStrings) do
			print(propString)
		end

	elseif service == "StarterPack" or service == "starterpack" or service == "spack" or service == "sp" or service == "stpack" then
		
		
		-- StarterPack
		
		
		local children = starterpack:GetChildren()
		local count = #starterpack:GetChildren()
		
		print("Total Items: " .. count)
		print("StarterPack Items:")
		
		-- Print each name of the children
		
		for _, child in ipairs(children) do
			print(child.Name)
		end
		
	elseif service == "SoundService" or service == "soundservice" or service == "ss" or service == "sservice" then
		
		
		-- SoundService
		
		
		local known_properties = {
			AmbientReverb = soundservice.AmbientReverb,
			DistanceFactor = soundservice.DistanceFactor,
			DopplerScale = soundservice.DopplerScale,
			RespectFilteringEnabled = soundservice.RespectFilteringEnabled,
			RolloffScale = soundservice.RolloffScale,
		}

		-- Convert properties to string format
		
		local propStrings = {
			"AmbientReverb: " .. tostring(known_properties.AmbientReverb),
			"DistanceFactor: " .. known_properties.DistanceFactor,
			"DopplerScale: " .. known_properties.DopplerScale,
			"RespectFilteringEnabled: " .. tostring(known_properties.RespectFilteringEnabled),
			"RolloffScale: " .. known_properties.RolloffScale
		}

		-- Print each property
		
		for _, propString in ipairs(propStrings) do
			print(propString)
		end
		
	elseif service == "TextChatService" or service == "textchatservice" or service == "Chat" or service == "chat" or service == "tcs" or service == "chatservice" then
		
		
		-- TextChatService
		
		local ChatWindowConfiguration = textchatservice.ChatWindowConfiguration
		local ChatInputBarConfiguration = textchatservice.ChatInputBarConfiguration
		local BubbleChatConfiguration = textchatservice.BubbleChatConfiguration
		
		
		local known_properties = {
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

		-- Convert properties to string format

		local propStrings = {
			"ChatTranslationEnabled: " .. tostring(known_properties.ChatTranslationEnabled),
			"ChatVersion: " .. tostring(known_properties.ChatVersion),
			"ChatWindowBackground: " .. tostring(known_properties.ChatWindowBackground),
			"ChatWindowTransparency: " .. tostring(known_properties.ChatWindowTransparency),
			"ChatWindowFont: " .. tostring(known_properties.ChatWindowFont),
			"TextColor: " .. tostring(known_properties.TextColor),
			"TextSize: " .. tostring(known_properties.TextSize),
			"HeightScale: " .. tostring(known_properties.HeightScale),
			"WidthScale: " .. tostring(known_properties.WidthScale)
		}

		-- Print each property

		for _, propString in ipairs(propStrings) do
			print(propString)
		end
		
	end
end


-- fetchPlayerDetails


utils.fetchPlayerDetails = function(targetName)
    local Players = game:GetService("Players")
    local target = Players:FindFirstChild(targetName)

    if not target then
        print("Target player not found: " .. targetName)
        return
    end

    local character = target.Character

    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
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

        -- Convert properties to string format
        local propStrings = {
            "DisplayName: " .. known_properties.DisplayName,
            "Name: " .. known_properties.Name,
            "UserId: " .. tostring(known_properties.UserId),
            "MembershipType: " .. known_properties.MembershipType,
            "GameplayPaused: " .. tostring(known_properties.GameplayPaused),
            "NameOcclusion: " .. tostring(known_properties.NameOcclusion),
            "RigType: " .. tostring(known_properties.RigType),
            "MaxHealth: " .. tostring(known_properties.MaxHealth),
            "Health: " .. tostring(known_properties.Health),
            "HipHeight: " .. tostring(known_properties.HipHeight),
            "MaxSlopeAngle: " .. tostring(known_properties.MaxSlopeAngle),
            "WalkSpeed: " .. tostring(known_properties.WalkSpeed),
            "CameraMode: " .. tostring(known_properties.CameraMode),
            "HealthDisplayDistance: " .. tostring(known_properties.HealthDisplayDistance),
            "NameDisplayDistance: " .. tostring(known_properties.NameDisplayDistance),
            "Neutral: " .. tostring(known_properties.Neutral),
            "Team: " .. tostring(known_properties.Team),
            "TeamColor: " .. tostring(known_properties.TeamColor)
        }

        -- Print each property
        for _, propString in ipairs(propStrings) do
            print(propString)
        end
    else
        print("Character or Humanoid not found for player: " .. target.Name)
    end
end


-- Function - createAudio


utils.createAudio = function(PlayOnRemove:boolean, SoundId:number, Looped:boolean, Volume:number)
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

utils.updateAudio = function(path:any, soundId:number, isPlaying:boolean)
	local found = false

	-- Check if path object has GetChildren method
	if type(path.GetChildren) == "function" then
		for _, sound in pairs(path:GetChildren()) do
			if sound:IsA("Sound") and sound.SoundId == "rbxassetid://" .. soundId then
				sound.Playing = isPlaying
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


utils.teleport = function(x:number, y:number, z:number)
	local character = player.Character or player.CharacterAdded:Wait()

	-- Ensure the character is fully loaded before teleporting
	if character and character.PrimaryPart then
		local destination = Vector3.new(x, y, z)
		character:SetPrimaryPartCFrame(CFrame.new(destination))
	else
		warn("Character or PrimaryPart not found")
	end
end


-- Function - tweenTeleport


utils.tweenTeleport = function(duration:number, x:number, y:number, z:number)
	local character = player.Character or player.CharacterAdded:Wait()
	local humrootpart = character:WaitForChild("HumanoidRootPart")

	local destination = CFrame.new(x, y, z)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tweenGoal = {CFrame = destination}

	local tween = tweenservice:Create(humrootpart, tweenInfo, tweenGoal)
	tween:Play()
end


-- Function - partTeleport


utils.partTeleport = function(part:path)
	local character = player.Character or player.CharacterAdded:Wait()

	character:SetPrimaryPartCFrame(part.CFrame)
end


-- Function - tweenPartTeleport


utils.tweenPartTeleport = function(duration, part)
	local character = player.Character or player.CharacterAdded:Wait()
	local humrootpart = character:WaitForChild("HumanoidRootPart")

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tweenGoal = {CFrame = part.CFrame}

	local tween = tweenservice:Create(humrootpart, tweenInfo, tweenGoal)
	tween:Play()
end


-- Function - gameTeleport


utils.gameTeleport = function(placeId:number)
	teleportservice:Teleport(placeId)
end



-- Function - gameInstanceTeleport


utils.gameInstanceTeleport = function(placeId:number, instanceId:string)
	teleportservice:TeleportToPlaceInstance(placeId, instanceId)
end


-- Function - positionChatWindow

utils.positionChatWindow = function(horizontalAlignment:string, verticalAlignment:string)
	local chatversion

	-- Checking for the chat version
	
	if textchatservice.ChatVersion == Enum.ChatVersion.TextChatService then
		chatversion = "TextChatService"
	else
		chatversion = "Legacy"
	end

	if chatversion == "TextChatService" then
		-- Alignment Checking
		
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

		if validHorizontalAlignments[horizontalAlignment] and validVerticalAlignments[verticalAlignment] then
			textchatservice.ChatWindowConfiguration.HorizontalAlignment = validHorizontalAlignments[horizontalAlignment]
			textchatservice.ChatWindowConfiguration.VerticalAlignment = validVerticalAlignments[verticalAlignment]
		else
			warn("Invalid horizontal alignment or vertical alignment provided.")
		end

	elseif chatversion == "Legacy" then
		local chatwindow = player.PlayerGui.Chat.Frame

		-- Alignment Checking
		
		local validHorizontalAlignments = {
			Center = "Center",
			Left = "Left",
			Right = "Right"
		}

		local validVerticalAlignments = {
			Bottom = "Bottom",
			Top = "Top",
			Center = "Center"
		}

		if validHorizontalAlignments[horizontalAlignment] and validVerticalAlignments[verticalAlignment] then
			-- Horizontal Alignments
			
			if horizontalAlignment == "Center" then
				chatwindow.AnchorPoint = Vector2.new(0.5, 0)
				chatwindow.Position = UDim2.new(0.5, 0, 0, 0)
			elseif horizontalAlignment == "Left" then
				chatwindow.AnchorPoint = Vector2.new(0, 0)
				chatwindow.Position = UDim2.new(0, 0, 0, 0)
			elseif horizontalAlignment == "Right" then
				chatwindow.AnchorPoint = Vector2.new(1, 0)
				chatwindow.Position = UDim2.new(1, 0, 0, 0)
			end

			-- Vertical Alignments
			
			if verticalAlignment == "Bottom" then
				chatwindow.AnchorPoint = Vector2.new(chatwindow.AnchorPoint.X, 1)
				chatwindow.Position = UDim2.new(chatwindow.Position.X.Scale, chatwindow.Position.X.Offset, 1, 0)
			elseif verticalAlignment == "Top" then
				chatwindow.AnchorPoint = Vector2.new(chatwindow.AnchorPoint.X, 0)
				chatwindow.Position = UDim2.new(chatwindow.Position.X.Scale, chatwindow.Position.X.Offset, 0, 0)
			elseif verticalAlignment == "Center" then
				chatwindow.AnchorPoint = Vector2.new(chatwindow.AnchorPoint.X, 0.5)
				chatwindow.Position = UDim2.new(chatwindow.Position.X.Scale, chatwindow.Position.X.Offset, 0.5, 0)
			end
		else
			warn("Invalid horizontal alignment or vertical alignment provided.")
		end
	else
		warn("Unknown chat version.")
	end
end


-- Function - resetChat


utils.resetChatWindow = function()
	local chatversion

	-- Checking for the chat version

	if textchatservice.ChatVersion == Enum.ChatVersion.TextChatService then
		chatversion = "TextChatService"
	else
		chatversion = "Legacy"
	end

	if chatversion == "TextChatService" then
		local ChatWindowConfiguration = textchatservice.ChatWindowConfiguration
		local ChatInputBarConfiguration = textchatservice.ChatInputBarConfiguration
		local BubbleChatConfiguration = textchatservice.BubbleChatConfiguration

		-- ChatWindowConfiguration

		ChatWindowConfiguration.BackgroundColor3 = Color3.new(25/255, 27/255, 29/255)
		ChatWindowConfiguration.BackgroundTransparency = 0.5
		ChatWindowConfiguration.TextColor3 = Color3.new(1, 1, 1)
		ChatWindowConfiguration.TextSize = 18
		ChatWindowConfiguration.TextStrokeColor3 = Color3.new(0, 0, 0)
		ChatWindowConfiguration.TextStrokeTransparency = 0.5
		ChatWindowConfiguration.HorizontalAlignment = Enum.HorizontalAlignment.Left
		ChatWindowConfiguration.VerticalAlignment = Enum.VerticalAlignment.Top
		ChatWindowConfiguration.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json") -- Change to desired font
		ChatWindowConfiguration.Enabled = true
		ChatWindowConfiguration.HeightScale = 1
		ChatWindowConfiguration.WidthScale = 1

		-- ChatInputBarConfiguration

		ChatInputBarConfiguration.BackgroundColor3 = Color3.new(155/255, 173/255, 176/255)
		ChatInputBarConfiguration.BackgroundTransparency = 0.2
		ChatInputBarConfiguration.PlaceholderColor3 = Color3.new(0, 0, 0)
		ChatInputBarConfiguration.TextColor3 = Color3.new(0, 0, 0)
		ChatInputBarConfiguration.TextSize = 18
		ChatInputBarConfiguration.TextStrokeColor3 = Color3.new(0, 0, 0)
		ChatInputBarConfiguration.TextStrokeTransparency = 1
		ChatInputBarConfiguration.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json") -- Change to desired font
		ChatInputBarConfiguration.AutocompleteEnabled = true
		ChatInputBarConfiguration.Enabled = true
		ChatInputBarConfiguration.KeyboardKeyCode = Enum.KeyCode.Slash

		-- BubbleChatConfiguration

		BubbleChatConfiguration.BackgroundColor3 = Color3.new(250/255, 250/255, 250/255)
		BubbleChatConfiguration.BackgroundTransparency = 0.1
		BubbleChatConfiguration.TailVisible = true
		BubbleChatConfiguration.TextColor3 = Color3.new(57/255, 59/255, 61/255)
		BubbleChatConfiguration.TextSize = 16
		BubbleChatConfiguration.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json") -- Change to desired font
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


utils.setCoreGuiEnabled = function(coreGuiType:string, state:boolean)
    -- Checking if the given state is a boolean and if not, return a warning
    if typeof(state) ~= "boolean" then
        local stateType = typeof(state)
        warn("Expected boolean but got " .. stateType .. ".")
        return
    end

    -- Normalize the coreGuiType input to lowercase for consistent comparison
    coreGuiType = coreGuiType:lower()

    -- Core Gui Mappings

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

    -- Check if the provided coreGuiType exists in the mapping

    local coreGuiEnum = coreGuiTypes[coreGuiType]

    if coreGuiEnum then
        startergui:SetCoreGuiEnabled(coreGuiEnum, state)
    else
        -- If the coreGuiType is not recognized, warn about it

        warn("Unknown core GUI type: " .. coreGuiType)
    end
end


-- Function - modifyPlayer


utils.modifyPlayer = function(property:string, value:number)
	local humanoid = player.Character.Humanoid

	humanoid[property] = value
end


-- Function - updateMouseAppearance


utils.updateMouseAppearance = function (assetid:number)
	local asset = marketplaceservice:GetProductInfo(assetid)
	local asset_typeid = asset.AssetTypeId

	-- Handling Asset Types

	local asset_type

	if asset.AssetTypeId == 1 then
		asset_type = "Image"
	elseif asset.AssetTypeId == 2 then
		asset_type = "TShirt"
	elseif asset.AssetTypeId == 3 then
		asset_type = "Audio"
	elseif asset.AssetTypeId == 4 then
		asset_type = "Mesh"
	elseif asset.AssetTypeId == 5 then
		asset_type = "Lua"
	elseif asset.AssetTypeId == 8 then
		asset_type = "Hat"
	elseif asset.AssetTypeId == 9 then
		asset_type = "Place"
	elseif asset.AssetTypeId == 10 then
		asset_type = "Model"
	elseif asset.AssetTypeId == 11 then
		asset_type = "Shirt"
	elseif asset.AssetTypeId == 12 then
		asset_type = "Pants"
	elseif asset.AssetTypeId == 13 then
		asset_type = "Decal"
	elseif asset.AssetTypeId == 17 then
		asset_type = "Head"
	elseif asset.AssetTypeId == 18 then
		asset_type = "Face"
	elseif asset.AssetTypeId == 19 then
		asset_type = "Gear"
	elseif asset.AssetTypeId == 21 then
		asset_type = "Badge"
	elseif asset.AssetTypeId == 24 then
		asset_type = "Animation"
	elseif asset.AssetTypeId == 61 then
		asset_type = "EmoteAnimation"
	elseif asset.AssetTypeId == 62 then
		asset_type = "Video"
	elseif asset.AssetTypeId == 73 then
		asset_type = "FontFamily"
	elseif asset.AssetTypeId == 78 then
		asset_type = "MoodAnimation"
	
	else

		if asset_type == nil then
			asset_type = "an unknown type"
		end
	end

	if asset_typeid == 13 then
		print('✅ Successfully loaded the decal "' .. asset.Name .. '".')
	else
		warn("Expected decal but got " .. asset_type)
	end

	-- Function

	local mouse = player:GetMouse()

	mouse.Icon = "rbxassetid://" .. assetid
end


-- Function - setElementEnabled

utils.setElementEnabled = function(element:string, state:boolean)
	local chatversion

	-- Checking for the chat version
	
	if textchatservice.ChatVersion == Enum.ChatVersion.TextChatService then
		chatversion = "TextChatService"
	else
		chatversion = "Legacy"
	end

	-- Checking if the given element is in a string and if not, return a warning

	if typeof(element) ~= "string" then
        local elementType = typeof(element)
        warn("Argument #1 expected string but got " .. elementType .. ".")
    end

    -- Checking if the given state is a boolean and if not, return a warning

    if typeof(state) ~= "boolean" then
        local stateType = typeof(state)
        warn("Argument #2 expected boolean but got " .. stateType .. ".")
        return
    end

	-- Function

	if element == "Chat Window" then

		if chatversion == "TextChatService" then
			textchatservice.ChatWindowConfiguration.Enabled = state
		elseif chatversion == "Legacy" then
			local chatwindow = player.PlayerGui.Chat.Frame
	
			chatwindow.Visible = state
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

utils.chatNotif = function(text:string, colorName:string, font:string, size:number)
	local channel = textchatservice.TextChannels.RBXSystem

	-- Color Presets

	local colorPresets = {
		White = Color3.fromRGB(255, 255, 255),
		Gray = Color3.fromRGB(120, 119, 119),
		Black = Color3.fromRGB(0, 0, 0),
		Red = Color3.fromRGB(255, 0, 0),
		Brown = Color3.fromRGB(128, 47, 0),
		Orange = Color3.fromRGB(255, 145, 0),
		Yellow = Color3.fromRGB(245, 255, 0),
		Lime = Color3.fromRGB(50, 205, 50),
		Green = Color3.fromRGB(0, 128, 0),
		Cyan = Color3.fromRGB(0, 255, 255),
		["Sky Blue"] = Color3.fromRGB(58, 112, 222),
		Blue = Color3.fromRGB(0, 17, 255),
		Purple = Color3.fromRGB(115, 0, 255),
		Pink = Color3.fromRGB(255, 192, 203),
		["Hot Pink"] = Color3.fromRGB(255, 105, 180)
	}

	-- Handling Message Formatting

	local function SystemMessage(info)
		return '<font color="#' .. info.Color .. '"><font size="' .. info.FontSize .. '"><font face="' .. info.Font .. '">' .. info.Text .. '</font></font></font>'
	end

	-- Sending Message

    local color = colorPresets[colorName]

    if not color then
        warn("Color preset '" .. colorName .. "' not found. Using default color: " .. tostring(colorPresets.White))
        color = colorPresets.White  -- Default to white if color not found
    end

	-- Nil Handling

	if font == "None" or font == "none" then
		font = "Arial"
	end

	if size == "Default" or size == "default" then
		size = 18
	end

	-- Size Limits

	if size > 50 then
		warn("Size exceeded the limit of 50. Try a lower number and try again.")
		return
	end

    if channel then
        channel:DisplaySystemMessage(
            SystemMessage({
                Text = text,
                Font = font,
                Color = color:ToHex(),
                FontSize = size
            })
        )
    else
        warn("Channel is nil")
    end
end


-- Function - createRbxNotif


utils.createRbxNotif = function(title:string, text:string, icon_assetid:number, duration:number)
	-- Nil Handling

	if title == "None" or title == "none" then
		title = "Untitled"
	end

	if icon == "None" or icon == "none" then
		icon = ""
	end

	-- Types

	local asset = marketplaceservice:GetProductInfo(icon_assetid)
	local asset_typeid = asset.AssetTypeId

	-- Handling Asset Types

	local asset_type

	if asset.AssetTypeId == 1 then
		asset_type = "Image"
	elseif asset.AssetTypeId == 2 then
		asset_type = "TShirt"
	elseif asset.AssetTypeId == 3 then
		asset_type = "Audio"
	elseif asset.AssetTypeId == 4 then
		asset_type = "Mesh"
	elseif asset.AssetTypeId == 5 then
		asset_type = "Lua"
	elseif asset.AssetTypeId == 8 then
		asset_type = "Hat"
	elseif asset.AssetTypeId == 9 then
		asset_type = "Place"
	elseif asset.AssetTypeId == 10 then
		asset_type = "Model"
	elseif asset.AssetTypeId == 11 then
		asset_type = "Shirt"
	elseif asset.AssetTypeId == 12 then
		asset_type = "Pants"
	elseif asset.AssetTypeId == 13 then
		asset_type = "Decal"
	elseif asset.AssetTypeId == 17 then
		asset_type = "Head"
	elseif asset.AssetTypeId == 18 then
		asset_type = "Face"
	elseif asset.AssetTypeId == 19 then
		asset_type = "Gear"
	elseif asset.AssetTypeId == 21 then
		asset_type = "Badge"
	elseif asset.AssetTypeId == 24 then
		asset_type = "Animation"
	elseif asset.AssetTypeId == 61 then
		asset_type = "EmoteAnimation"
	elseif asset.AssetTypeId == 62 then
		asset_type = "Video"
	elseif asset.AssetTypeId == 73 then
		asset_type = "FontFamily"
	elseif asset.AssetTypeId == 78 then
		asset_type = "MoodAnimation"
	
	else

		if asset_type == nil then
			asset_type = "an unknown type"
		end
	end

	if asset_typeid == 1 then
		
		startergui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Icon = "rbxassetid://" .. icon_assetid,
			Duration = duration
		})

		-- utils.createNotif("Celestial", "Celestial Information Card.", 18568429771, 4)

	else
		warn("Expected image but got " .. asset_type)
	end
end


-- Function - sendMessage


utils.sendMessage = function(message:string)
	local RBXGeneral = textchatservice.TextChannels.RBXGeneral
	RBXGeneral:SendAsync(message)
end


-- Function - success


utils.success = function(content:string)
	console.custom_print(content, "rbxasset://textures/AudioDiscovery/done.png", Color3.fromRGB(9, 255, 0))
end


-- Function - error


utils.error = function(content:string)
	console.custom_print(content, "rbxasset://textures/AudioDiscovery/error.png", Color3.fromRGB(255, 0, 0))
end

return utils
