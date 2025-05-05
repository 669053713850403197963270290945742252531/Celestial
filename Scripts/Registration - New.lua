while not game:IsLoaded() do
    task.wait()
end

local utils = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Core%20Utilities.lua?ref_type=heads"))()
local auth = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Authentication.lua?ref_type=heads"))()

if auth.kicked then
	return
end

local uiLocation

if typeof(gethui) == "function" then
    uiLocation = gethui()
else
	uiLocation = game:GetService("CoreGui")
end

-- Variables

local hwidValue = auth.hwid("Hashed")
local identifierValue = ""
local joinDateValue = ""
local discordIdValue = 0

local discordIdNumber = false
local invalidIdentifierMinLength = true
local invalidIdentifierMaxLength = true
local invalidDiscordIdLength = true

-- Registration check

local registered

if not isfile("Celestial ScriptHub/Registered.txt") then
	registered = false
else
	registered = readfile("Celestial ScriptHub/Registered.txt")
end

if registered == "true" then
	registered = true
elseif registered == "false" then
	registered = false
end

-- Destroying any existing instances of the ui

if uiLocation:FindFirstChild("Register User") then
    uiLocation["Register User"]:Destroy()
end

-- Helper functions

local function generateKey()
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local array = {}
	for i = 1, math.random(25, maxChars or 40) do
		local randomIndex = math.random(1, #chars)
		array[i] = chars:sub(randomIndex, randomIndex)
	end
	return table.concat(array)
end

local function sendEmbed()
	local httpService = game:GetService("HttpService")
	local webhookUrl = "https://discord.com/api/webhooks/1326062417444343919/2VWhZzKCVUvLHywL1PnhTjvMV1DX6UD8YJAlDmyiqY8mg0prlGqkhW4zt5SCSMcBeEGI"
	local player = game:GetService("Players").LocalPlayer
	local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

	local data = {
		embeds = {
			{
				title = "**__User has been registered__**",
				url = "https://roblox.com/users/" .. player.UserId .. "/profile",
				type = "rich",
				color = tonumber(2752256),
				fields = {
					{
						name = "Execution Date",
						value = "**" .. os.date("%x") .. " | " .. utils.getTime(true) .. " : " .. os.date("%Z") .. "**",
						inline = true
					},

					{
						name = "Roblox Name",
						value = player.DisplayName .. " (@" .. player.Name .. ")",
						inline = true
					},

					{
						name = "Exploit",
						value = identifyexecutor(),
						inline = true
					},

					{
						name = "================== Registration Details ==================",
						value = "",
						inline = false
					},
	
					{
						name = "Hardware ID",
						value = "```"  .. hwidValue .. "```",
						inline = true
					},

					{
						name = "Hardware ID [Dehashed]",
						value = "||"  .. auth.hwid("Normal") .. "||",
						inline = true
					},

					{
						name = "Identifier",
						value = identifierValue,
						inline = true
					},

					{
						name = "Join Date",
						value = joinDateValue,
						inline = true
					},

					{
						name = "Discord ID",
						value = "<@" .. discordIdValue .. "> (" .. discordIdValue .. ")",
						inline = true
					},

					{
						name = "Key",
						value = generateKey(),
						inline = true
					},
				}
			}
		}
	}

	local encodedData = httpService:JSONEncode(data)
	local headers = {
		["content-type"] = "application/json"
	}

	local args = {Url = webhookUrl, Body = encodedData, Method = "POST", Headers = headers}
	request(args)
end

-- Create assets

if not isfolder("Celestial ScriptHub") then
	makefolder("Celestial ScriptHub")
end

if not registered then
	writefile("Celestial ScriptHub/Registered.txt", "false")
end

-- Rayfield Interface

local rayfieldLib = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local rayfieldWindow = rayfieldLib:CreateWindow({
	Name = "Celestial Registration",
	Icon = 127059246403673,
	LoadingTitle = "Celestial Registration",
	LoadingSubtitle = "Celestial ScriptHub registration",
	Theme = "Default",

	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,

	Discord = {
		Enabled = true,
		Invite = "sGBSAHgaN8",
		RememberJoins = true
	}
})

-- Tab: Registration

local registrationTab = rayfieldWindow:CreateTab("Registration", 92281601154947)

-- Section: Prefilled

local prefilledSection = registrationTab:CreateSection("Prefilled")

local joinDate = os.date("%x, %I %p") or "Unknown Date"
joinDateValue = joinDate

local hwidPrefilled = registrationTab:CreateParagraph({Title = "Hardware ID", Content = hwidValue})
local joinDatePrefilled = registrationTab:CreateParagraph({Title = "Join Date", Content = joinDate})

-- Section: User Inputs

local inputsSection = registrationTab:CreateSection("User Inputs")

local identifierInput = registrationTab:CreateInput({
	Name = "Identifier",
	CurrentValue = false,
	PlaceholderText = "Name to be displayed on the script",
	RemoveTextAfterFocusLost = false,
	Flag = "identifierInput",
	Callback = function(value)
		identifierValue = value

		if #value > 1 then
			invalidIdentifierMinLength = false
		else
			invalidIdentifierMinLength = true

			rayfieldLib:Notify({
				Title = "Invalid Identifier",
				Content = "Provided identifier has to be more than 1 character.",
				Duration = 7,
				Image = "circle-x",
			 })
		end

		if #value > 36 then
			invalidIdentifierMaxLength = true

			rayfieldLib:Notify({
				Title = "Invalid Identifier",
				Content = "Provided identifier can't be more than 36 characters.",
				Duration = 7,
				Image = "circle-x",
			})
		else
			invalidIdentifierMaxLength = false
		end
	end,
})

local discordIDInput = registrationTab:CreateInput({
	Name = "Discord ID",
	CurrentValue = false,
	PlaceholderText = "The discord account to link the hardware id to",
	RemoveTextAfterFocusLost = false,
	Flag = "discordIDInput",
	Callback = function(value)
		discordIdValue = value

		if tonumber(value) then
			discordIdNumber = true
		else
			discordIdNumber = false

			rayfieldLib:Notify({
				Title = "Invalid Discord ID",
				Content = "Provided Discord ID has to be a numeric value.",
				Duration = 7,
				Image = "circle-x",
			})
		end

		if #value < 18 then
			invalidDiscordIdLength = true

			rayfieldLib:Notify({
				Title = "Invalid Discord ID",
				Content = "Provided Discord ID can't be less than 18 characters.",
				Duration = 7,
				Image = "circle-x",
			})
		else
			invalidDiscordIdLength = false
		end
	end,
})

-- Registration check via notif

if registered then
	rayfieldLib:Notify({
		Title = "Already Registered",
		Content = "Detected invalid file contents or you have already registered.",
		Duration = 7,
		Image = "circle-x",
	})
	wait(7)
	rayfieldLib:Destroy()
	return
end

local register = registrationTab:CreateButton({
    Name = "Register",
    Callback = function()
		if invalidIdentifierMinLength then
			rayfieldLib:Notify({
				Title = "Invalid Identifier",
				Content = "Provided identifier has to be more than 1 character.",
				Duration = 7,
				Image = "circle-x",
			})

			return
		end
	
		if invalidIdentifierMaxLength then
			rayfieldLib:Notify({
				Title = "Invalid Identifier",
				Content = "Provided identifier can't be more than 36 characters.",
				Duration = 7,
				Image = "circle-x",
			})

			return
		end
	
		if invalidDiscordIdLength then
			rayfieldLib:Notify({
				Title = "Invalid Discord ID",
				Content = "Provided Discord ID can't less than 18 characters",
				Duration = 7,
				Image = "circle-x",
			})

			return
		end
	
		if not discordIdNumber then
			rayfieldLib:Notify({
				Title = "Invalid Discord ID",
				Content = "Discord ID expected a valid number.",
				Duration = 7,
				Image = "circle-x",
			})

			return
		end


		
		sendEmbed()



		-- Keep track if the user already registered in the past

		writefile("Celestial ScriptHub/Registered.txt", "true")

		local successfulRegister = readfile("Celestial ScriptHub/Registered.txt")
	
		if successfulRegister == "true" then
			successfulRegister = true
		elseif successfulRegister == "false" then
			successfulRegister = false
		end
	
		wait(0.05)
	
		if successfulRegister then
			rayfieldLib:Notify({
				Title = "Registered",
				Content = "Successfully registered as " .. identifierValue .. " on " .. joinDateValue .. ".",
				Duration = 7,
				Image = "check",
			 })

			wait(3.5)
			rayfieldLib:Destroy()
		end
    end,
})

while true do
    -- Update the joinDateValue with the current date and time

    joinDateValue = os.date("%x, %I %p") or "Unknown date"
    
    -- Update the prefilled values

    joinDatePrefilled:Set({
        Title = "Join Date:", 
        Content = "\n" .. joinDateValue
    })
    
    task.wait(1)
end