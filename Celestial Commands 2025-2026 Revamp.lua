-- fully functional | 3/19/2026

local permittedUsers = {
	[8890642382] = {
		Permitted = true,
		Rank = "Owner",
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

local RankHierarchy = {
	"Untrusted",
	"User",
	"Trusted",
	"Friend",
	"Moderator",
	"Admin",
	"Owner",
}

--[[

RANKING DESCRIPTION:
🔹 User
- Info-only commands
- No effect on other players

🔹 Trusted / Friend (optional middle tiers)
- Cosmetic features
- QoL commands
- Non-abusive tools

Example ideas:

- ;fly (client-side)
- ;esp
- ;highlight

🔹 Moderator
- Can affect other players
- But NOT permanently punish

Examples:
- kill
- sit
- freeze
- fling
- pm

🔹 Admin

- Can punish / enforce
- Strong authority

Examples:

- kick
- ban
- tempban
- mute (server-side)

🔹 Owner
- Full system control

Examples:

- whitelist editing
- rank changing
- system config

]]

--[[
        ==========================
=============== SERVICES ==================
        ==========================
]]

local plrs = game:GetService("Players")
local tcs = game:GetService("TextChatService")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local localizationService = game:GetService("LocalizationService")
local stats = game:GetService("Stats")

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

local ALLOW_WHITELIST_TARGETING = false -- set to false in production
local DEBUG_VIEW_AS_UNWHITELISTED = false -- simulate the unwhitelisted chat view to show test logic such as command redaction with only one whitelisted client and no unwhitelisted client
local dedupeWindow = 2 -- How long duplicate events are ignored for the same message. tldr; prevents double command execution. the higher the more safe

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
local lastCommandTimestamps = {} -- key = commandName, value = os.clock()

local activeHighlights = {} -- [player] = { connection = RBXScriptConnection, rainbowThread = thread }
local GLOBAL_RAINBOW_SPEED = 0.15 -- slower =  (0.05–0.15) | shared rainbow clock to sync rainbow for all players

--[[
        ==========================
=============== PERFORMANCE TRACKING ==================
        ==========================
]]

local currentFPS = 0
local currentPing = 0

local frames = {}
local pingValues = {}

-- FPS

runService.Heartbeat:Connect(function()
	local now = os.clock()

	-- add current frame timestamp
	table.insert(frames, now)

	-- remove frames older than 1 second
	while frames[1] and frames[1] < now - 1 do
		table.remove(frames, 1)
	end

	-- FPS = number of frames in last second
	currentFPS = #frames
end)

-- PING

task.spawn(function()
	while true do
		task.wait(1) -- update interval

		local pingStat = stats:FindFirstChild("PerformanceStats")
		if pingStat and pingStat:FindFirstChild("Ping") then
			local ping = tonumber(pingStat.Ping:GetValue())

			if ping then
				ping = math.floor(ping)
				currentPing = ping

				-- store history for stability & future use
				table.insert(pingValues, ping)

				if #pingValues > 60 then -- keep last ~minute
					table.remove(pingValues, 1)
				end
			end
		end
	end
end)

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

		-- Displaying the required rank for each command
		local RankColors = {
			Untrusted = "#888888",
			User = "#ffffff",
			Trusted = "#00ffcc",
			Friend = "#66ccff",
			Moderator = "#ffaa00",
			Admin = "#ff6600",
			Owner = "#ff0000",
		}

		if cmd.RequiredRank then
			local color = RankColors[cmd.RequiredRank] or "#ffaa00"
			line ..= string.format(" <font color='%s'>(%s+)</font>", color, cmd.RequiredRank)
		end

		return line
	end,

	resolveTargets = function(input, speaker, errorTarget)
		local players = plrs:GetPlayers()
		if not input or input == "" then
			return {}
		end

		input = input:lower()

		-- "me" selects the speaker (yourself)
		if input == "me" then
			return { speaker }, true
		end

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

		return matches, false -- Return matches (empty if none found)
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
	if not target then return end
	if localplayer ~= target then return end
	celestialFunctions.chatMsg(string.format('<font color="rgb(255,80,80)">[ERROR] %s</font>', msg))
end

function celestialFunctions.fetchStatus(target)
	if not target then
		return false
	end

	local data = permittedUsers[target.UserId]
	return data ~= nil and data.Permitted == true
end

function celestialFunctions.getRank(plr)
	if not plr then return "Untrusted" end

	local data = permittedUsers[plr.UserId]
	if data and data.Permitted then
		return data.Rank or "User"
	end

	return "Untrusted"
end

function celestialFunctions.getRankValue(rankName)
	for i, rank in ipairs(RankHierarchy) do
		if rank == rankName then
			return i
		end
	end
	return 0 -- unknown rank
end

function celestialFunctions.hasPermission(plr, requiredRank)
	local playerRank = celestialFunctions.getRank(plr)

	local playerValue = celestialFunctions.getRankValue(playerRank)
	local requiredValue = celestialFunctions.getRankValue(requiredRank)

	return playerValue >= requiredValue
end

function celestialFunctions.processTargets(targets, localPlayer, options)
	options = options or {}

	local blockWhitelisted = options.blockWhitelisted or false -- Whether to skip whitelisted users
	local action = options.action -- Function to execute on each target
	local targetMode = options.targetMode or TargetMode.Single -- Default targeting mode
	local ignoreWhitelistForMe = options.ignoreWhitelistForMe or false

    -- Return false immediately if no action or no targets
	if not action or #targets == 0 then
		return false
	end

	local success = false
	local skipWhitelistForAll = targetMode == TargetMode.All -- Determine if we should skip whitelist checks for 'All' or 'Others' target modes

    -- Iterate over each target player
	for _, plr in ipairs(targets) do
		local isWhitelisted = celestialFunctions.fetchStatus(plr)

        -- If blocking whitelisted users and player is whitelisted, and whitelisted users are not allowed to be targeted, show error (unless skipped)
		if blockWhitelisted and isWhitelisted and not skipWhitelistForAll and not (ignoreWhitelistForMe and options.ctx and options.ctx._isMeTarget) and not ALLOW_WHITELIST_TARGETING then
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

function celestialFunctions.sendChatMessage(message)
    local generalChannel = tcs:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
    generalChannel:SendAsync(message)
end

function celestialFunctions.getRainbowColor()
	local t = os.clock() * GLOBAL_RAINBOW_SPEED
	local hue = t % 1
	return Color3.fromHSV(hue, 1, 1)
end

function celestialFunctions.cmdError(ctx, msg) -- define context in the args because context is defined per command
	if not ctx then
		warn("celestialFunctions.cmdError: No context given.")
		return
	end

	celestialFunctions.errorMsgFor(ctx.ErrorTarget, msg)
end

--[[
        ==========================
=============== COMMAND REGISTRATION ==================
        ==========================
]]

local SharedCommands = {}
local ClientCommands = {}

local function registerCommand(cmdTable, name, aliases, arguments, description, callback, requiredRank)
	local command = {
		Name = name,
		Aliases = {}, -- Lowercased aliases for internal lookup
		DisplayAliases = {}, -- Keep original alias casing for displaying in the help message
		Arguments = arguments,
		Description = description,
		Callback = callback,
		RequiredRank = requiredRank or "User",
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
		celestialFunctions.cmdError(ctx, "No valid targets found.")
		return
	end

	celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		ctx = ctx,
		blockWhitelisted = true,
		ignoreWhitelistForMe = true,
		targetMode = ctx.TargetMode,
		action = function(plr)
            if celestialFunctions.isAlive(plr) then
                local hum = plr.Character.Humanoid
                hum.Health = 0
            end
		end,
	})
end, "Moderator")

registerCommand(SharedCommands, "loopkill", { "Lkill" }, "<target> <true|false>", "Loop kills target(s)", function(ctx)
	local targets = ctx.ResolveTargets(1)
	if #targets == 0 then
		celestialFunctions.cmdError(ctx, "No valid targets found.")
		return
	end

	local stateArg = ctx.Args[2]
	local state = celestialFunctions.toBoolean(stateArg)
	if state == nil then
		celestialFunctions.errorMsgFor(
			ctx.ErrorTarget,
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
		ctx = ctx,
		blockWhitelisted = true,
		ignoreWhitelistForMe = true,
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
end, "Moderator")

registerCommand(SharedCommands, "sit", nil, "<target> <true|false>", "Sits target(s)", function(ctx)
	local targets = ctx.ResolveTargets(1)
	if #targets == 0 then
		celestialFunctions.cmdError(ctx, "No valid targets found.")
		return
	end

	local stateArg = ctx.Args[2]
	local state = celestialFunctions.toBoolean(stateArg)
	if state == nil then
		celestialFunctions.cmdError(ctx, "Argument #2 expected a boolean value but given " .. tostring(stateArg))
		return
	end

	celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		ctx = ctx,
		blockWhitelisted = true,
		ignoreWhitelistForMe = true,
		targetMode = ctx.TargetMode,
		action = function(plr)
            if celestialFunctions.isAlive(plr) then
                local hum = plr.Character.Humanoid
                hum.Sit = state
            end
		end,
	})
end, "Moderator")

registerCommand(SharedCommands, "privatemessage", { "pm", "privmessage", "privmsg" }, "<target> <\"message\"> [duration]", "Displays a private message on the target's screen.", function(ctx)
    local targets = ctx.ResolveTargets(1)
    if #targets == 0 then
        celestialFunctions.cmdError(ctx, "No valid targets found.")
        return
    end

    -- Extract quoted message
    local full = ctx.ArgString
    local message = full:match('"(.-)"')
    if not message then
        celestialFunctions.errorMsgFor(
            ctx.ErrorTarget,
            "Missing message. Wrap the message in quotes."
        )
        return
    end

    -- Extract duration (number AFTER the quoted text)
    local afterQuote = full:match('".-"%s*(.+)')
    local duration = tonumber(afterQuote) or 5

    celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		ctx = ctx,
        blockWhitelisted = true,
		ignoreWhitelistForMe = true,
        targetMode = ctx.TargetMode,
        action = function(plr)
            -- Only show on the target’s client
            if plr == localplayer then
                celestialFunctions.showPrivateMessage(message, duration)
            end
        end,
    })
end, "Moderator")

registerCommand(SharedCommands, "kick", nil, "<target> [reason]", "Kicks target(s) with an optional reason.", function(ctx)
	local targets = ctx.ResolveTargets(1)
	if #targets == 0 then
		celestialFunctions.cmdError(ctx, "No valid targets found.")
		return
	end

    -- Ban the 'all' keyword
	if ctx.Args[1] and ctx.Args[1]:lower() == "all" then
		celestialFunctions.cmdError(ctx, "The 'all' keyword is not allowed for this command.")
		return
	end

	-- Build reason from args AFTER target
	local reasonParts = {}
	for i = 2, #ctx.Args do
		table.insert(reasonParts, ctx.Args[i])
	end

	local reason = (#reasonParts > 0 and table.concat(reasonParts, " ")) or DEFAULT_KICK_REASON

	celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		ctx = ctx,
		blockWhitelisted = true,
		ignoreWhitelistForMe = true,
		targetMode = ctx.TargetMode,
		action = function(plr)
			pcall(function() -- fuck roblox and its "Cannot kick a non-local Player from a LocalScript" error
                plr:Kick(reason)
            end)
		end,
	})
end, "Admin")

registerCommand(SharedCommands, "clearchat", { "clrchat" }, "<target>", "Clears the player's chat.", function(ctx)
    -- Ban the 'all' keyword
	if ctx.Args[1] and ctx.Args[1]:lower() == "all" then
		celestialFunctions.cmdError(ctx, "The 'all' keyword is not allowed for this command.")
		return
	end

    local targets = ctx.ResolveTargets(1)
    if #targets == 0 then
        celestialFunctions.cmdError(ctx, "No valid targets found.")
        return
    end

    celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
        ctx = ctx,
        blockWhitelisted = true,
		ignoreWhitelistForMe = true,
        targetMode = ctx.TargetMode,
        action = function(plr)
            -- Only execute on the target's client
            if plr == localplayer then
                celestialFunctions.sendChatMessage("/clear")
            end
        end,
    })

end, "Moderator")



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

registerCommand(ClientCommands, "help", nil, nil, "Displays a help page. Pages available: 'keywords' (target keywords), 'ranks' (rank system), or no argument to list all commands.", function(ctx)
	local firstArg = ctx.Args[1] and ctx.Args[1]:lower() or ""

	-- Predefined keywords block with dynamic prefix
	local keywordsDescription = {
		string.format(
			"<b>You can use 'Keywords' with the prefix '%s' to reference multiple targets at once.</b>",
			COMMAND_PREFIX
		),
		string.format("<font><b>Example:</b> %s%s all</font>", COMMAND_PREFIX, "kill"),
		"\u{200B}", -- zero-width divider
		"<b>All available keywords:</b>",
		"me - Targets yourself",
		"all - Targets every user, including yourself",
		"others - Targets every user, excluding yourself",
	}

	local ranksDescription = {
		string.format(
			"<b>Rank System</b>"
		),
		"<b>Ranks determine what commands a user can execute.</b>",
		"\u{200B}",

		"<b>Hierarchy (lowest → highest):</b>",
		"<font color='#888888'>Untrusted</font> - No access to commands",
		"<font color='#ffffff'>User</font>  - Basic command access",
		"<font color='#00ffcc'>Trusted</font> - Extended access to utility commands",
		"<font color='#66ccff'>Friend</font> - Elevated access (trusted inner circle)",
		"<font color='#ffaa00'>Moderator</font> - Can moderate players (e.g., sit, kill, pm)",
		"<font color='#ff6600'>Admin</font> - Can enforce punishments (e.g., kick)",
		"<font color='#ff0000'><b>Owner</b></font> - Full system control",
		"\u{200B}",

		"<b>Important Notes:</b>",
		"Higher ranks inherit all permissions from lower ranks",
		"Some commands are restricted to higher ranks only",
		"Ranks are assigned per-user in the system configuration",
	}

	-- Show only keywords if first argument is "keywords"
	if firstArg == "keywords" then
		for _, line in ipairs(keywordsDescription) do
			celestialFunctions.chatMsg(line)
		end
		return
	end

	-- Ranks page
	if firstArg == "ranks" then
		for _, line in ipairs(ranksDescription) do
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
end, "User")

registerCommand(ClientCommands, "test", nil, "<target>", "test cmd.", function(ctx)
	local arg1 = ctx.Args[1] and ctx.Args[1]:lower()

	print(tostring(arg1))
end, "User")

registerCommand(ClientCommands, "search", { "src" }, "<command>", "Searches for a command and shows detailed info.", function(ctx)
    local query = ctx.Args[1] and ctx.Args[1]:lower()

    if not query then
        celestialFunctions.cmdError(ctx, "Missing command to search for.")
        return
    end

    local found = {}
    local seen = {}

    local function scan(cmdTable, sourceName)
        for key, cmd in pairs(cmdTable) do
            if not seen[cmd] then
				local matchName = cmd.Name:lower()
				local matchAlias = false

				for _, alias in ipairs(cmd.Aliases) do
					local a = alias:lower()
					if a:find(query, 1, true) then -- partial matching
						matchAlias = true
						break
					end
				end

				-- Also allow partial match on the command name
				if matchName:find(query, 1, true) or matchAlias then
					seen[cmd] = true
					table.insert(found, {
						Command = cmd,
						Source = sourceName
					})
				end
            end
        end
    end

    scan(ClientCommands, "Client")
    scan(SharedCommands, "Shared")

    if #found == 0 then
        celestialFunctions.cmdError(ctx, "No command found: " .. query)
        return
    end

    for _, entry in ipairs(found) do
        local cmd = entry.Command
        local hasPerm = celestialFunctions.hasPermission(ctx.LocalPlayer, cmd.RequiredRank or "User")
        local rankColor = hasPerm and "#ffaa00" or "#ff4444"

        -- Header: command name + source in gray
        celestialFunctions.chatMsg(
            string.format("<font><b>%s</b> <font color='#aaaaaa'>[%s]</font></font>", 
                COMMAND_PREFIX .. cmd.Name, 
                entry.Source
            )
        )

        -- Description
        if cmd.Description then
            celestialFunctions.chatMsg(string.format("<font><b>Description:</b> %s</font>", cmd.Description))
        end

        -- Aliases
        if cmd.DisplayAliases and #cmd.DisplayAliases > 0 then
            celestialFunctions.chatMsg(string.format("<font><b>Aliases:</b> %s</font>", table.concat(cmd.DisplayAliases, ", ")))
        else
            celestialFunctions.chatMsg("<font><b>Aliases:</b> None</font>")
        end

        -- Arguments
		if cmd.Arguments then
			-- Escape < and > to prevent Roblox chat from breaking HTML
			local safeArgs = cmd.Arguments:gsub("<", "&lt;"):gsub(">", "&gt;")
			celestialFunctions.chatMsg(string.format("<font><b>Arguments:</b> %s</font>", safeArgs))
		else
			celestialFunctions.chatMsg("<font><b>Arguments:</b> None</font>")
		end

        -- Required Rank
        if cmd.RequiredRank then
            celestialFunctions.chatMsg(string.format(
                "<font><b>Required Rank:</b> <font color='%s'>%s+</font></font>",
                rankColor,
                cmd.RequiredRank
            ))
        else
            celestialFunctions.chatMsg("<font><b>Required Rank:</b> User+</font>")
        end

		celestialFunctions.chatMsg("\u{200B}") -- spacer
    end
end, "User")

registerCommand(ClientCommands, "searchplayers", { "searchplrs", "srcplrs" }, "<target>", "Checks, validates, and returns info about a player.", function(ctx)
    local targets = ctx.ResolveTargets(1)

    if #targets == 0 then
        celestialFunctions.cmdError(ctx, "No players found matching: " .. (ctx.Args[1] or ""))
        return
    end

    celestialFunctions.chatMsg(string.format("<b>Found %d player(s):</b>", #targets))

    celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
        ctx = ctx,
        blockWhitelisted = false, -- searching doesn't skip whitelisted
		ignoreWhitelistForMe = true,
        targetMode = ctx.TargetMode,
        action = function(plr)
            local rank = celestialFunctions.getRank(plr)
            local isWhitelisted = celestialFunctions.fetchStatus(plr)

            local statusColor = isWhitelisted and "#00ff88" or "#ff4444"
            local statusText = isWhitelisted and "Whitelisted" or "Unwhitelisted"

            celestialFunctions.chatMsg(string.format(
                "<font color='#aaaaaa'>•</font> <b>%s</b> (@%s) | Rank: <b>%s</b> | <font color='%s'>%s</font>",
                plr.DisplayName,
                plr.Name,
                rank,
                statusColor,
                statusText
            ))
        end,
    })
end, "Trusted")

registerCommand(ClientCommands, "highlightplayer", { "highlightplr", "hlplr", "hl" }, "<target> <persistent> [color|hex|rainbow]", "Toggles a highlight on the target.", function(ctx)
	local targets = ctx.ResolveTargets(1)
	if #targets == 0 then
		celestialFunctions.cmdError(ctx, "No valid targets found.")
		return
	end

	-- Persistent arg (REQUIRED)
	local persistentArg = ctx.Args[2]
	local persistent = celestialFunctions.toBoolean(persistentArg)

	if persistent == nil then
		celestialFunctions.cmdError(ctx, "Argument #2 expected a boolean value but given " .. tostring(persistentArg))
		return
	end

	-- Predefined colors
	local colorTable = {
		red = Color3.fromRGB(255, 0, 0),
		green = Color3.fromRGB(0, 255, 0),
		blue = Color3.fromRGB(0, 0, 255),
		yellow = Color3.fromRGB(255, 255, 0),
		purple = Color3.fromRGB(170, 0, 255),
		pink = Color3.fromRGB(255, 105, 180),
		orange = Color3.fromRGB(255, 140, 0),
		white = Color3.fromRGB(255, 255, 255),
		black = Color3.fromRGB(0, 0, 0),
		cyan = Color3.fromRGB(0, 255, 255),
	}

	-- Optional color arg
	local colorArg = ctx.Args[3]
	local resolvedColor = Color3.fromRGB(255, 255, 0)
	local isRainbow = false

	if colorArg then
		local lower = colorArg:lower()

		-- Rainbow handling
		if lower == "rainbow" then
			isRainbow = true

		-- Predefined color handling
		elseif colorTable[lower] then
			resolvedColor = colorTable[lower]

		-- HEX color handling
		elseif lower:match("^#%x%x%x%x%x%x$") then
			local r = tonumber(lower:sub(2, 3), 16)
			local g = tonumber(lower:sub(4, 5), 16)
			local b = tonumber(lower:sub(6, 7), 16)
			resolvedColor = Color3.fromRGB(r, g, b)
		else
			celestialFunctions.cmdError(ctx, "Invalid color: " .. colorArg)
			return
		end
	end

	-- Cleanup
	local function stopTracking(plr)
		local data = activeHighlights[plr]
		if not data then return end

		if data.connection then
			data.connection:Disconnect()
		end

		if data.rainbowThread then
			task.cancel(data.rainbowThread)
		end

		activeHighlights[plr] = nil
	end

	celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		ctx = ctx,
		blockWhitelisted = false,
		ignoreWhitelistForMe = true,
		targetMode = ctx.TargetMode,
		action = function(plr)
			local char = plr.Character
			if not char then return end

			local existing = char:FindFirstChild("CelestialHighlight")
			if existing then return end

			stopTracking(plr) -- overwrite

			-- Apply highlight
			local function applyHighlight(character)
				activeHighlights[plr] = activeHighlights[plr] or {}
				
				local highlight = Instance.new("Highlight")
				highlight.Name = "CelestialHighlight"
				highlight.FillTransparency = 0.5
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = character

				if isRainbow then
					local thread = task.spawn(function()
						while highlight and highlight.Parent do
							local color = celestialFunctions.getRainbowColor()
							highlight.FillColor = color
							highlight.OutlineColor = color
							runService.Heartbeat:Wait()
						end
					end)

					activeHighlights[plr] = activeHighlights[plr] or {}
					activeHighlights[plr].rainbowThread = thread
				else
					highlight.FillColor = resolvedColor
					highlight.OutlineColor = resolvedColor
				end
			end

			stopTracking(plr) -- Clean old tracking before anything
			applyHighlight(char) -- Apply immediately

			-- Persistent arg handling
			if persistent then
				local conn
				conn = plr.CharacterAdded:Connect(function(newChar)
					task.wait(0.1)
					applyHighlight(newChar)
				end)

				activeHighlights[plr] = activeHighlights[plr] or {}
				activeHighlights[plr].connection = conn
			end
		end,
	})
end, "Trusted")

registerCommand(ClientCommands, "unhighlightplayer", { "unhlplr", "unhl" }, "<target>", "Removes the target's highlight.", function(ctx)
	local targets = ctx.ResolveTargets(1)
	if #targets == 0 then
		celestialFunctions.cmdError(ctx, "No valid targets found.")
		return
	end

	-- Reuse cleanup logic from highlightplayer
	local function stopTracking(plr)
		local data = activeHighlights[plr]
		if not data then return end

		if data.connection then
			data.connection:Disconnect()
		end

		if data.rainbowThread then
			task.cancel(data.rainbowThread)
		end

		activeHighlights[plr] = nil
	end

	celestialFunctions.processTargets(targets, ctx.LocalPlayer, {
		ctx = ctx,
		blockWhitelisted = false,
		ignoreWhitelistForMe = true,
		targetMode = ctx.TargetMode,
		action = function(plr)
			local char = plr.Character
			if char then
				local highlight = char:FindFirstChild("CelestialHighlight")
				if highlight then
					highlight:Destroy()
				end
			end

			-- Always stop tracking even if no highlight exists
			stopTracking(plr)
		end,
	})
end, "Trusted")

registerCommand(ClientCommands, "performance", { "perf" }, nil, "Displays client performance stats (FPS, ping, memory, etc).", function(ctx)
	local stats = game:GetService("Stats")
	local runService = game:GetService("RunService")
	local players = game:GetService("Players")

	local ping = currentPing
	local fps = currentFPS
	local memory = math.floor(stats:GetTotalMemoryUsageMb())
	local playerCount = #players:GetPlayers()
	local region = "Unknown"

	-- Fetch region
	pcall(function()
		local regionCode = localizationService.RobloxLocaleId or localizationService.SystemLocaleId
		if regionCode then
			region = regionCode -- example: "en-us"
		end
	end)

	-- Output
	celestialFunctions.chatMsg("<b>Performance Stats</b>")
	celestialFunctions.chatMsg(string.format("📶 Ping: <b>%d ms</b>", ping))
	celestialFunctions.chatMsg(string.format("🎮 FPS: <b>%d</b>", fps))
	celestialFunctions.chatMsg(string.format("🧠 Memory: <b>%d MB</b>", memory))
	celestialFunctions.chatMsg(string.format("🌎 Region: <b>%s</b>", region))
	celestialFunctions.chatMsg(string.format("👥 Players: <b>%d</b>", playerCount))
end, "Trusted")

--[[
        ==========================
=============== COMMAND PARSING & HANDLING ==================
        ==========================
]]

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

local function parseCommandWithSilent(messageText)
    local commandName, args = parseCommand(messageText)
    local silent = false

    if args then
        for i = #args, 1, -1 do
            local arg = args[i]:lower()
            if arg == "-s" or arg == "--silent" then
                silent = true
                table.remove(args, i)
            end
        end
    end

    return commandName, args, silent
end

local function executeCommand(commandTable, commandName, args, speaker, errorTarget, silentOverride)
	local cmd = commandTable[commandName]
	if not cmd then
		celestialFunctions.errorMsgFor(errorTarget, "Unknown command: " .. (commandName or "<empty>"))
		return false
	end

	local currentTime = os.clock()

	-- Only dedupe for commands
	if lastCommandTimestamps[commandName] and (currentTime - lastCommandTimestamps[commandName]) < dedupeWindow then
		celestialFunctions.errorMsgFor(errorTarget, "Command ignored due to dedupe cooldown.")
		return false
	end

	lastCommandTimestamps[commandName] = currentTime

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

	---- SILENT FLAG ----

	local silent = silentOverride or false

	for i = #args, 1, -1 do
		local arg = args[i]:lower()
		if arg == "-s" or arg == "--silent" then
			silent = true
			table.remove(args, i)
		end
	end

	----- CONTEXT -----

	local ctx = {
		Speaker = speaker,
		LocalPlayer = localplayer,
		ErrorTarget = errorTarget,
		Args = args,
		ArgString = table.concat(args, " "),
		TargetMode = targetMode,
		Silent = silent,
		_isMeTarget = false -- default
	}

	ctx.ResolveTargets = function(argIndex)
		local targets, isMe = celestialFunctions.resolveTargets(args[argIndex], speaker, errorTarget)

		if argIndex == 1 then
			ctx._isMeTarget = isMe or false
		end

		return targets
	end

	if #args == 0 and cmd.Arguments and not cmd.Arguments:find("%[") then
		celestialFunctions.errorMsgFor(errorTarget, "Missing arguments for command: " .. commandName)
		return false
	end

	-- RANK CHECK
	local requiredRank = cmd.RequiredRank or "User"

	if not celestialFunctions.hasPermission(speaker, requiredRank) then
		celestialFunctions.errorMsgFor(
			errorTarget,
			"Insufficient rank. Required: " .. requiredRank
		)
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
		local msg = "Command executed"
		if ctx.Silent then
			msg = "Command silently executed"
		end
		msg = msg .. ": " .. commandName
		celestialFunctions.successMsg(msg)
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

	-- SILENT FLAG

	local rawText = message.Text or ""

	-- Step 1: must start with prefix
	local hasPrefix = rawText:sub(1, #COMMAND_PREFIX) == COMMAND_PREFIX

	local isCommand = false
	local commandName, args

	if hasPrefix then
		commandName, args = parseCommandWithSilent(rawText)

		-- Step 2: validate command exists
		if commandName and (ClientCommands[commandName] or SharedCommands[commandName]) then
			isCommand = true
		end
	end

	-- Step 3: ONLY process silent if it's a REAL command
	local isSilent = false
	local processedText = rawText

	if isCommand then
		isSilent = rawText:lower():match("%-s%s*$") ~= nil
		processedText = rawText:gsub("%s*%-s%s*$", "")
	end

	-- Step 4: clean display text
	local displayText = processedText

	if isCommand then
		displayText = processedText:sub(#COMMAND_PREFIX + 1)
	end

	-- HARD BLOCK: unwhitelisted speakers cannot issue commands
	if player and not celestialFunctions.fetchStatus(player) then
		if isCommand then
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
		props.PrefixText = string.format("%s %s:", tagText, displayName)
	else
		-- Other unwhitelisted clients see no tag
		props.PrefixText = displayName .. ":"
	end

	-- Command Execution
	if message.TextSource then
		--[[

		-- Ensure player chat messages are only processed once. Skip Status check for your own messages
		if player == localplayer then
			-- skip status check
		else
			if message.Status ~= Enum.TextChatMessageStatus.Success then
				return props
			end
		end

		]]

		-- Removed status check, only requiring success for non-commands due allow for greater execution times
		if not isCommand and player ~= localplayer then
			if message.Status ~= Enum.TextChatMessageStatus.Success then
				return props
			end
		end

		-- Appling a global "dedupe" to all clients
		local msgId = message.MessageId or (message.Text .. "_" .. tostring(message.TextSource and message.TextSource.UserId))

		if recentMessages[msgId] then
			return props
		end

		recentMessages[msgId] = true

		task.delay(dedupeWindow, function()
			recentMessages[msgId] = nil
		end)

		-- EXECUTIONER CLIENT (whitelisted)
		if celestialFunctions.fetchStatus(localplayer) then
			local commandName, args, silent = parseCommandWithSilent(rawText)

			if commandName then
				if ClientCommands[commandName] then
					executeCommand(ClientCommands, commandName, args, player, localplayer, silent)
				elseif SharedCommands[commandName] then
					executeCommand(SharedCommands, commandName, args, player, localplayer, silent)
				else
					celestialFunctions.errorMsgFor(localplayer, "Invalid command: " .. COMMAND_PREFIX .. commandName)
				end
			end
		end

		-- UNWHITELISTED CLIENT runs SharedCommands from whitelisted users

		if not celestialFunctions.fetchStatus(localplayer) and player and celestialFunctions.fetchStatus(player) then
			local commandName, args, silent = parseCommandWithSilent(rawText)

			if commandName and SharedCommands[commandName] then
				executeCommand(SharedCommands, commandName, args, player, nil, silent)
			end
		end
	end

	-- FINAL TEXT OVERRIDE
	if isSilent and isCommand then
		local isViewerWhitelisted = celestialFunctions.fetchStatus(localplayer)

		-- DEBUG override (optional)
		if DEBUG_VIEW_AS_UNWHITELISTED then
			isViewerWhitelisted = false
		end

		if not isViewerWhitelisted then
			-- Only OTHER players get hidden message via a message weight system
			local common = { "ok", "yeah", "alr", "lol", "idk", "alright", "nah", "yep", "yea", "k", "okay", "cool" }
			local rare = { "hold on", "gimme a sec", "makes sense", "my bad", "lmao", "bet", "what", "huh", "one sec" }

			local pool = (math.random() < 0.7) and common or rare
			props.Text = pool[math.random(1, #pool)]
			--props.Text = "..."
		else
			-- YOU see EXACT original message
			props.Text = rawText
		end
	else
		props.Text = rawText
	end

	return props
end

--[[
        ==========================
=============== EXECUTION CONFIRMATION DEBUG ==================
        ==========================
]]

local rank = celestialFunctions.getRank(localplayer)
local displayName = localplayer.DisplayName

-- Format time (12-hour with AM/PM)
local currentTime = os.date("%I:%M:%S %p")

print(string.format(
    "[Celestial] Initialized | User: %s (@%s) | Rank: %s | Time: %s",
    displayName,
    localplayer.Name,
    rank,
    currentTime
))