local permittedUsers = {
	[3881598914] = {
		Permitted = true,
		ChatTag = {
			Text = "chrismtas",
			Color = Color3.fromRGB(139, 0, 0),
		},
	} --[[,
    [3881601281] = {
        Permitted = true,
        ChatTag = {
            Text = "number one bitch",
            Color = Color3.fromRGB(0, 0, 0),
            Prefix = "<b>",
            Suffix = "</b>",
        }
    },]],
}

--[[
        ==========================
=============== SERVICES ==================
        ==========================
]]

local plrs = game:GetService("Players")
local tcs = game:GetService("TextChatService")
local tweenService = game:GetService("TweenService")

local localplayer = plrs.LocalPlayer

--[[
        ==========================
=============== CONSTANTS ==================
        ==========================
]]

local COMMAND_PREFIX = ";"
local CHAT_TAG_PREFIX = "<b>"
local CHAT_TAG_SUFFIX = "</b>"

local MAX_PRIVMESSAGES = 4
local PRIVMSG_TWEEN_IN = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local PRIVMSG_TWEEN_OUT = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local DEFAULT_KICK_REASON =
	"You have been kicked due to unexpected client behavior."
-- Same account launched experience from different device. Reconnect if you prefer to use this device.

local TargetMode = {
	Single = "Single",
	All = "All",
	Others = "Others",
}

--[[
        ==========================
=============== TABLES & TRACKERS ==================
        ==========================
]]

local activeLoopKills = {}

--[[
        ==========================
=============== COMMAND FUNCTIONS ==================
        ==========================
]]

local celestialFunctions = {
	isAlive = function(plrInstance)
		local char = plrInstance.Character
		local humanoid = char and char:FindFirstChild("Humanoid")
		return char
			and char:FindFirstChild("HumanoidRootPart")
			and char:FindFirstChild("Head")
			and humanoid
			and humanoid.Health > 0
	end,

	colorToHex = function(color)
		return string.format(
			"#%02X%02X%02X",
			math.floor(color.R * 255),
			math.floor(color.G * 255),
			math.floor(color.B * 255)
		)
	end,

	lightenColor = function(color)
        local factor = 0.5

        return Color3.new(
            color.R + (1 - color.R) * factor,
            color.G + (1 - color.G) * factor,
            color.B + (1 - color.B) * factor
        )
	end,

	toBoolean = function(input)
        if type(input) == "boolean" then
            return input
        end

        if type(input) ~= "string" then
            return nil
        end

        local value = input:lower()

        if value == "true" or value == "1" then
            return true
        elseif value == "false" or value == "0" then
            return false
        end

        return nil
    end,

	getUniqueCommands = function(cmdTable)
		local seen = {} -- Track all the commands already viewed
		local result = {} -- Store unique commands

        -- Iterate through each command in the provided command table
		for _, cmd in pairs(cmdTable) do
            -- If this command hasn't been seen yet, add it to the result
			if not seen[cmd] then
				seen[cmd] = true
				table.insert(result, cmd)
			end
		end

        -- Sort the result table alphabetically by the command's Name property

		table.sort(result, function(cmdA, cmdB)
			return cmdA.Name < cmdB.Name
		end)

		return result
	end,

	formatCommandLine = function(cmd)
		local parts = { COMMAND_PREFIX .. cmd.Name } -- Start with the command name and prefix

        -- Add aliases if they exist
		if cmd.DisplayAliases and #cmd.DisplayAliases > 0 then
			table.insert(parts, "(" .. table.concat(cmd.DisplayAliases, ", ") .. ")")
		end

        -- Add arguments safely (escape < and >) because fucking roblox raw html chat
		if cmd.Arguments then
			local safeArgs = cmd.Arguments:gsub("<", "&lt;"):gsub(">", "&gt;")
			table.insert(parts, "| " .. safeArgs)
		end

        -- Combine parts and wrap in bold htnl
		local line = "<b>" .. table.concat(parts, " ") .. "</b>"

        -- Append description if available
		if cmd.Description then
			line ..= " - " .. cmd.Description
		end

		return line
	end,

	resolveTargets = function(input, speaker, errorTarget)
		local players = plrs:GetPlayers()
		if not input or input == "" then
			return {}
		end

		input = input:lower()

        -- "all" selects every player
		if input == "all" then
			return players
		end

        -- "others" selects everyone except the speaker
		if input == "others" then
			local result = {}
			for _, plr in ipairs(players) do
				if plr ~= speaker then
					table.insert(result, plr)
				end
			end
			return result
		end

        -- Match players by name or display name prefix
		local matches = {}
		for _, plr in ipairs(players) do
			local name = plr.Name:lower()
			local display = plr.DisplayName:lower()
			if name:sub(1, #input) == input or display:sub(1, #input) == input then
				table.insert(matches, plr)
			end
		end

		return matches -- Return matches (empty if none found)
	end,

    showPrivateMessage = function(message, duration)
        duration = tonumber(duration) or 5
        local plrGui = localplayer.PlayerGui

        -- ScreenGui: create if it doesn't exist
        local gui = plrGui:FindFirstChild("Private Message")
        if not gui then
            gui = Instance.new("ScreenGui", plrGui)
            gui.Name = "Private Message"
            gui.ResetOnSpawn = false
            gui.DisplayOrder = 10000
        end

        -- Container frame inside ScreenGui
        local container = gui:FindFirstChild("Container")
        if not container then
            container = Instance.new("Frame", gui)
            container.Name = "Container"
            container.Size = UDim2.fromScale(0.5, 0)
            container.AutomaticSize = Enum.AutomaticSize.Y
            container.Position = UDim2.fromScale(0.25, 0.05)
            container.BackgroundTransparency = 1

            local layout = Instance.new("UIListLayout", container)
            layout.Padding = UDim.new(0, 8)
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        end

        -- Enforce max number of messages
        local existing = {}
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("TextLabel") then
                table.insert(existing, child)
            end
        end

        if #existing >= MAX_PRIVMESSAGES then
            existing[1]:Destroy() -- Remove oldest message
        end

        -- Create new message label
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        label.BackgroundTransparency = 1 -- Start invisible
        label.BorderSizePixel = 0
        label.TextWrapped = true
        label.RichText = true
        label.TextSize = 20
        label.Font = Enum.Font.GothamSemibold
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextTransparency = 1
        label.Text = message

        -- Add padding and rounded corners
        local padding = Instance.new("UIPadding", label)
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 14)

        local corner = Instance.new("UICorner", label)
        corner.CornerRadius = UDim.new(0, 14)

        -- Initial offset for slide-in animation
        label.Position = UDim2.fromOffset(0, -12)

        -- Tween IN animation
        tweenService:Create(label, PRIVMSG_TWEEN_IN, {
            BackgroundTransparency = 0.15,
            TextTransparency = 0,
            Position = UDim2.fromOffset(0, 0),
        }):Play()

        -- Play notification sound
        local sound = Instance.new("Sound", label)
        sound.SoundId = "rbxassetid://5621616510"
        sound.Volume = 2.5
        sound.PlayOnRemove = true
        sound:Destroy()

        -- Tween OUT and cleanup after duration
        task.delay(duration, function()
            if not label or not label.Parent then return end

            local tweenOut = tweenService:Create(label, PRIVMSG_TWEEN_OUT, {
                BackgroundTransparency = 1,
                TextTransparency = 1,
                Position = UDim2.fromOffset(0, -10),
            })

            tweenOut:Play()
            tweenOut.Completed:Wait()

            if label then label:Destroy() end
            if container and #container:GetChildren() <= 1 then
                gui:Destroy() -- Remove gui if no messages left
            end
        end)
    end
}

function celestialFunctions.chatMsg(msg)
	local generalChannel = tcs.TextChannels:WaitForChild("RBXGeneral")

	task.spawn(function()
		task.wait(0.1)
		generalChannel:DisplaySystemMessage(msg)
	end)
end

function celestialFunctions.successMsg(msg)
	celestialFunctions.chatMsg(string.format('<font color="rgb(80,255,80)">[SUCCESS] %s</font>', msg))
end

function celestialFunctions.errorMsgFor(target, msg)
	if localplayer ~= target then
		return
	end

	celestialFunctions.chatMsg(string.format('<font color="rgb(255,80,80)">[ERROR] %s</font>', msg))
end

function celestialFunctions.fetchStatus(target)
	if not target then
		return false
	end

	local data = permittedUsers[target.UserId]
	return data ~= nil and data.Permitted == true
end

function celestialFunctions.processTargets(targets, localPlayer, options)
	options = options or {}

	local blockWhitelisted = options.blockWhitelisted or false -- Whether to skip whitelisted users
	local action = options.action -- Function to execute on each target
	local targetMode = options.targetMode or TargetMode.Single -- Default targeting mode

    -- Return false immediately if no action or no targets
	if not action or #targets == 0 then
		return false
	end

	local success = false
	local skipWhitelistForAll = targetMode == TargetMode.All or targetMode == TargetMode.Others -- Determine if we should skip whitelist checks for 'All' or 'Others' target modes

    -- Iterate over each target player
	for _, plr in ipairs(targets) do
		local isWhitelisted = celestialFunctions.fetchStatus(plr)

        -- If blocking whitelisted users and player is whitelisted, show error (unless skipped)
		if blockWhitelisted and isWhitelisted and not skipWhitelistForAll then
			celestialFunctions.errorMsgFor(localPlayer, "Cannot target whitelisted user: " .. plr.Name)
		else
            -- Apply action if the player is alive
			if celestialFunctions.isAlive(plr) then
				action(plr)
				success = true
			end
		end
	end

	return success -- Returns true if at least one action was successfully applied
end

--[[
        ==========================
=============== COMMAND REGISTRATION ==================
        ==========================
]]

local SharedCommands = {}
local ClientCommands = {}

local function registerCommand(cmdTable, name, aliases, arguments, description, callback)
	local command = {
		Name = name,
		Aliases = {}, -- Lowercased aliases for internal lookup
		DisplayAliases = {}, -- Keep original alias casing for displaying in the help message
		Arguments = arguments,
		Description = description,
		Callback = callback,
	}

    -- Handle aliases: can be a string or a table
	if type(aliases) == "string" then
		table.insert(command.Aliases, aliases:lower()) -- Store lowercase for lookup
		table.insert(command.DisplayAliases, aliases) -- Keep original for display
	elseif type(aliases) == "table" then
		for _, a in ipairs(aliases) do
			table.insert(command.Aliases, a:lower())  -- Store lowercase for lookup
			table.insert(command.DisplayAliases, a) -- Keep original for display
		end
	end

	cmdTable[name:lower()] = command -- Register the primary name in the command table

	-- Register each alias as a reference to the same command
	for _, alias in ipairs(command.Aliases) do
		cmdTable[alias] = command
	end
end

--[[
        ==========================
=============== SHARED COMMANDS ==================
        ==========================
]]

registerCommand(SharedCommands, "kill", nil, "<target>", "Kills target(s)", function(ctx)
	local targets = ctx.ResolveTargets(1)
	if #targets == 0 then
		celestialFunctions.errorMsgFor(ctx.LocalPlayer, "No valid targets found.")
		return
	end

	celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		blockWhitelisted = true,
		targetMode = ctx.TargetMode,
		action = function(plr)
            if celestialFunctions.isAlive(plr) then
                local hum = plr.Character.Humanoid
                hum.Health = 0
            end
		end,
	})
end)

registerCommand(SharedCommands, "loopkill", { "Lkill" }, "<target> <true|false>", "Loop kills target(s)", function(ctx)
	local targets = ctx.ResolveTargets(1)
	if #targets == 0 then
		celestialFunctions.errorMsgFor(ctx.LocalPlayer, "No valid targets found.")
		return
	end

	local stateArg = ctx.Args[2]
	local state = celestialFunctions.toBoolean(stateArg)
	if state == nil then
		celestialFunctions.errorMsgFor(
			ctx.LocalPlayer,
			"Argument #2 expected a boolean value but given " .. tostring(stateArg)
		)
		return
	end

	-- Handle disabling loopkill before doing anything else
	if not state then
		for _, plr in ipairs(targets) do
			if activeLoopKills[plr] then
				activeLoopKills[plr]:Disconnect()
				activeLoopKills[plr] = nil
			end
		end
		return
	end

	-- Enabling loopkill
	celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		blockWhitelisted = true,
		targetMode = ctx.TargetMode,
		action = function(plr)
			-- Skip if already looping
			if activeLoopKills[plr] then
				return
			end

			local function removeFF(char)
				if char:FindFirstChildOfClass("ForceField") then
					char:FindFirstChildOfClass("ForceField"):Destroy()
				end
			end

			-- Kill immediately if alive
            if not celestialFunctions.isAlive(plr) then return end

			local hum = plr.Character.Humanoid
			removeFF(plr.Character)
			hum.Health = 0

			-- Connect to future respawns
			activeLoopKills[plr] = plr.CharacterAdded:Connect(function(char)
				task.wait(0.1)

				removeFF(plr.Character)
                if celestialFunctions.isAlive(plr) then
                    local hum = char.Humanoid
                    hum.Health = 0
                end
			end)
		end,
	})
end)

registerCommand(SharedCommands, "sit", nil, "<target> <true|false>", "Sits target(s)", function(ctx)
	local targets = ctx.ResolveTargets(1)
	if #targets == 0 then
		celestialFunctions.errorMsgFor(ctx.LocalPlayer, "No valid targets found.")
		return
	end

	local stateArg = ctx.Args[2]
	local state = celestialFunctions.toBoolean(stateArg)
	if state == nil then
		celestialFunctions.errorMsgFor(ctx.LocalPlayer, "Argument #2 expected a boolean value but given " .. tostring(stateArg))
		return
	end

	celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		blockWhitelisted = true,
		targetMode = ctx.TargetMode,
		action = function(plr)
            if celestialFunctions.isAlive(plr) then
                local hum = plr.Character.Humanoid
                hum.Sit = state
            end
		end,
	})
end)

registerCommand(SharedCommands, "privatemessage", { "pm", "privmessage", "privmsg" }, "<target> \"message\" [duration]", "Displays a private message on the target's screen.", function(ctx)
    local targets = ctx.ResolveTargets(1)
    if #targets == 0 then
        celestialFunctions.errorMsgFor(ctx.LocalPlayer, "No valid targets found.")
        return
    end

    -- Extract quoted message
    local full = ctx.ArgString
    local message = full:match('"(.-)"')
    if not message then
        celestialFunctions.errorMsgFor(
            ctx.LocalPlayer,
            "Missing message. Wrap the message in quotes."
        )
        return
    end

    -- Extract duration (number AFTER the quoted text)
    local afterQuote = full:match('".-"%s*(.+)')
    local duration = tonumber(afterQuote) or 5

    celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
        blockWhitelisted = true,
        targetMode = ctx.TargetMode,
        action = function(plr)
            -- Only show on the target’s client
            if plr == localplayer then
                celestialFunctions.showPrivateMessage(message, duration)
            end
        end,
    })
end)

registerCommand(SharedCommands, "kick", nil, "<target> [reason]", "Kicks target(s) with an optional reason.", function(ctx)
	local targets = ctx.ResolveTargets(1)
	if #targets == 0 then
		celestialFunctions.errorMsgFor(ctx.LocalPlayer, "No valid targets found.")
		return
	end

    -- Ban the 'all' keyword
	if ctx.Args[1] and ctx.Args[1]:lower() == "all" then
		celestialFunctions.errorMsgFor(ctx.LocalPlayer, "The 'all' keyword is not allowed for this command.")
		return
	end

	-- Build reason from args AFTER target
	local reasonParts = {}
	for i = 2, #ctx.Args do
		table.insert(reasonParts, ctx.Args[i])
	end

	local reason = (#reasonParts > 0 and table.concat(reasonParts, " ")) or DEFAULT_KICK_REASON

	celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		blockWhitelisted = true,
		targetMode = ctx.TargetMode,
		action = function(plr)
			pcall(function() -- fuck roblox and its "Cannot kick a non-local Player from a LocalScript" error
                plr:Kick(reason)
            end)
		end,
	})
end)

--[[
        ==========================
=============== CLIENT COMMANDS ==================
        ==========================
]]

--[[
registerCommand(ClientCommands, "sayhi", nil, "Prints hello for the executioner", function()
    print("Hello! Executed on your client only.")
end)
]]

registerCommand(ClientCommands, "help", nil, "[keywords]", "Lists all available commands or displays keywords block", function(ctx)
	local firstArg = ctx.Args[1] and ctx.Args[1]:lower() or ""

	-- Predefined keywords block with dynamic prefix
	local keywordsDescription = {
		string.format(
			"<b>You can use 'Keywords' with the prefix '%s' to reference multiple targets at once.</b>",
			COMMAND_PREFIX
		),
		string.format("<b>Example:</b> %skill all", COMMAND_PREFIX),
		"\u{200B}", -- zero-width divider
		"<b>All available keywords:</b>",
		"all - Targets every user, including yourself",
		"others - Targets every user, excluding yourself",
	}

	-- Show only keywords if first argument is "keywords"
	if firstArg == "keywords" then
		for _, line in ipairs(keywordsDescription) do
			celestialFunctions.chatMsg(line)
		end
		return
	end

	-- Otherwise, show commands
	celestialFunctions.chatMsg("<b>Client Commands</b>")
	for _, cmd in ipairs(celestialFunctions.getUniqueCommands(ClientCommands)) do
		celestialFunctions.chatMsg(celestialFunctions.formatCommandLine(cmd))
	end

	celestialFunctions.chatMsg("\u{200B}") -- spacer

	celestialFunctions.chatMsg("<b>Shared Commands</b>")
	for _, cmd in ipairs(celestialFunctions.getUniqueCommands(SharedCommands)) do
		celestialFunctions.chatMsg(celestialFunctions.formatCommandLine(cmd))
	end
end)

-- Command Parsing

local function parseCommand(messageText)
	local prefix = COMMAND_PREFIX

	-- Check if message starts with the current prefix
	if messageText:sub(1, #prefix) ~= prefix then
		return nil, {}
	end

	local stripped = messageText:sub(#prefix + 1)

	local parts = {}
	for word in stripped:gmatch("%S+") do
		table.insert(parts, word)
	end

	local commandName = table.remove(parts, 1)
	if commandName then
		commandName = commandName:lower() -- lowercase only command name
	end

	return commandName, parts
end

local function executeCommand(commandTable, commandName, args, speaker, errorTarget)
	local cmd = commandTable[commandName]
	if not cmd then
		celestialFunctions.errorMsgFor(errorTarget, "Unknown command: " .. (commandName or "<empty>"))
		return false
	end

	-- CENTRALIZED TARGET MODE RESOLUTION
	local rawTarget = args[1] and args[1]:lower() or ""
	local targetMode

	if rawTarget == "all" then
		targetMode = TargetMode.All
	elseif rawTarget == "others" then
		targetMode = TargetMode.Others
	else
		targetMode = TargetMode.Single
	end

	local ctx = {
		Speaker = speaker,
		LocalPlayer = localplayer,
		Args = args,
		ArgString = table.concat(args, " "),
		TargetMode = targetMode, -- ✅ enum instead of boolean
		ResolveTargets = function(argIndex)
			return celestialFunctions.resolveTargets(args[argIndex], speaker, errorTarget)
		end,
	}

	if #args == 0 and cmd.Description:lower():find("target") then
		celestialFunctions.errorMsgFor(errorTarget, "Missing arguments for command: " .. commandName)
		return false
	end

	local ok, err = pcall(function()
		cmd.Callback(ctx)
	end)

	if not ok then
		celestialFunctions.errorMsgFor(
			errorTarget,
			"Error executing command '" .. commandName .. "': " .. tostring(err)
		)
		return false
	end

	if localplayer == errorTarget then
		celestialFunctions.successMsg("Command executed: " .. commandName)
	end

	return true
end

-- Command Execution Logic
local recentMessages = {}

tcs.OnIncomingMessage = function(message)
	local props = Instance.new("TextChatMessageProperties")
	props.Text = message.Text or ""

	local player = message.TextSource and plrs:GetPlayerByUserId(message.TextSource.UserId)
	local displayName = player and player.DisplayName or "Unknown"

	-- HARD BLOCK: unwhitelisted speakers cannot issue commands
	if player and not celestialFunctions.fetchStatus(player) then
		local cmd = parseCommand(message.Text or "")
		if cmd then
			return props
		end
	end

	if not message.TextSource then
		local props = Instance.new("TextChatMessageProperties")
		props.PrefixText = ""
		return props
	end

	-- Chat tag logic
	if celestialFunctions.fetchStatus(player) then
		-- Whitelisted user: show their normal tag
		local tag = permittedUsers[player.UserId].ChatTag
		local tagText = string.format(
			'%s<font color="%s">[</font><font color="%s">%s</font><font color="%s">]</font>%s',
			CHAT_TAG_PREFIX,
			celestialFunctions.colorToHex(celestialFunctions.lightenColor(tag.Color)),
			celestialFunctions.colorToHex(tag.Color),
			tag.Text,
			celestialFunctions.colorToHex(celestialFunctions.lightenColor(tag.Color)),
			CHAT_TAG_SUFFIX
		)
		props.PrefixText = string.format("%s %s: ", tagText, displayName)
	else
		-- Other unwhitelisted clients see no tag
		props.PrefixText = displayName .. ": "
	end

	-- Command Execution
	if message.TextSource then
		local messageText = message.Text

		-- EXECUTIONER CLIENT (whitelisted)
		if celestialFunctions.fetchStatus(localplayer) then
			if not recentMessages[message.Text] then
				local commandName, args = parseCommand(messageText)

				if commandName then
					if ClientCommands[commandName] then
						executeCommand(ClientCommands, commandName, args, player, localplayer)
					elseif SharedCommands[commandName] then
						-- Run shared command locally so errors show
						executeCommand(SharedCommands, commandName, args, player, localplayer)
					else
						celestialFunctions.errorMsgFor(
							localplayer,
							"Invalid command: " .. COMMAND_PREFIX .. commandName
						)
					end
				end

				recentMessages[message.Text] = true
				task.delay(0.5, function()
					recentMessages[message.Text] = nil
				end)
			end
		end

		-- UNWHITELISTED CLIENT runs SharedCommands from whitelisted users
		if not celestialFunctions.fetchStatus(localplayer) and player and celestialFunctions.fetchStatus(player) then
			local commandName, args = parseCommand(messageText)

			if commandName then
				if SharedCommands[commandName] then
					executeCommand(SharedCommands, commandName, args, player, player)
				end
			end
		end
	end

	return props
end

print("Command system initialized correctly.")
