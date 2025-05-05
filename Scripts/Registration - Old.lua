while not game:IsLoaded() do
    task.wait()
end

local uiLocation

if typeof(gethui) == "function" then
    uiLocation = gethui()
else
	uiLocation = game:GetService("CoreGui")
end

local utils = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Utilities.lua?ref_type=heads"))()

-- Variables

local hwidValue = ""
local usernameValue = ""
local joinDateValue = ""
local discordIdValue = 0

local discordIdNumber = false
local invalidUsernameMinLength = true
local invalidUsernameMaxLength = true
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

if registered then
	warn("Detected invalid file contents or you have already registered.")
	return
end

-- Destroying any existing instances of the ui

if uiLocation:FindFirstChild("Register User") then
    uiLocation["Register User"]:Destroy()
end

-- Helper functions

local function convertRGB(r, g, b)
    return Color3.new(r / 255, g / 255, b / 255)
end

-- Create assets

if not isfolder("Celestial ScriptHub") then
	makefolder("Celestial ScriptHub")
end

writefile("Celestial ScriptHub/Registered.txt", "false")

-- Instances

local registrationUi = Instance.new("ScreenGui", uiLocation)
local registrationFrame = Instance.new("Frame", registrationUi)

local regUICorner = Instance.new("UICorner", registrationFrame)

local inputContainer = Instance.new("Frame", registrationFrame)
local containerLayout = Instance.new("UIListLayout", inputContainer)

local confirmDetails = Instance.new("TextButton", registrationFrame)
local confirmUICorner = Instance.new("UICorner", confirmDetails)

local dividerLabel = Instance.new("TextLabel", registrationFrame)
local titleLabel = Instance.new("TextLabel", registrationFrame)

local blur = Instance.new("BlurEffect", game:GetService("Lighting"))
blur.Size = math.huge


-- Containers

-- Hardware Id

local hardwareIdContainer = Instance.new("Frame", inputContainer)
local hardwareIdUICorner = Instance.new("UICorner", hardwareIdContainer)
local hardwareIdInput = Instance.new("TextBox", hardwareIdContainer)
--local hardwareIdDisabledFrame = Instance.new("Frame", hardwareIdContainer)

-- Username

local usernameContainer = Instance.new("Frame", inputContainer)
local usernameUICorner = Instance.new("UICorner", usernameContainer)
local usernameInput = Instance.new("TextBox", usernameContainer)

-- Join Date

local joinDateContainer = Instance.new("Frame", inputContainer)
local joinDateUICorner = Instance.new("UICorner", joinDateContainer)
local joinDateInput = Instance.new("TextBox", joinDateContainer)
--local joinDateDisabledFrame = Instance.new("Frame", joinDateContainer)

--local joinDateDisabledFrameUICorner = Instance.new("UICorner", joinDateDisabledFrame)
--local joinDateDisabledIcon = Instance.new("ImageLabel", joinDateDisabledFrame)

-- Discord Id

local discordIdContainer = Instance.new("Frame", inputContainer)
local discordIdUICorner = Instance.new("UICorner", discordIdContainer)
local discordIdInput = Instance.new("TextBox", discordIdContainer)

--local hardwareIdDisabledFrameUICorner = Instance.new("UICorner", hardwareIdDisabledFrame)
--local hardwareIdDisabledIcon = Instance.new("ImageLabel", hardwareIdDisabledFrame)


-- Constraints


local regFrameConstraint = Instance.new("UIAspectRatioConstraint", registrationFrame)
regFrameConstraint.AspectRatio = 0.917

local containerConstraint = Instance.new("UIAspectRatioConstraint", inputContainer)
containerConstraint.AspectRatio = 1.323

local confirmConstraint = Instance.new("UIAspectRatioConstraint", confirmDetails)
confirmConstraint.AspectRatio = 3.411

local dividerConstraint = Instance.new("UIAspectRatioConstraint", dividerLabel)
dividerConstraint.AspectRatio = 11.088

local titleConstraint = Instance.new("UIAspectRatioConstraint", titleLabel)
titleConstraint.AspectRatio = 7.54

local discordIdContainerConstraint = Instance.new("UIAspectRatioConstraint", discordIdContainer)
discordIdContainerConstraint.AspectRatio = 4.569

local discordIdInputConstraint = Instance.new("UIAspectRatioConstraint", discordIdInput)
discordIdInputConstraint.AspectRatio = 4.569

local hardwareIdContainerConstraint = Instance.new("UIAspectRatioConstraint", hardwareIdContainer)
hardwareIdContainerConstraint.AspectRatio = 4.569

local joinDateContainerConstraint = Instance.new("UIAspectRatioConstraint", joinDateContainer)
joinDateContainerConstraint.AspectRatio = 4.569

local usernameContainerConstraint = Instance.new("UIAspectRatioConstraint", usernameContainer)
usernameContainerConstraint.AspectRatio = 4.569

--local hardwareIdDisabledFrameConstraint = Instance.new("UIAspectRatioConstraint", hardwareIdDisabledFrame)
--hardwareIdDisabledFrameConstraint.AspectRatio = 4.569

local hardwareIdInputConstraint = Instance.new("UIAspectRatioConstraint", hardwareIdInput)
hardwareIdInputConstraint.AspectRatio = 4.569

local joinDateInputConstraint = Instance.new("UIAspectRatioConstraint", joinDateInput)
joinDateInputConstraint.AspectRatio = 4.569

local usernameInputConstraint = Instance.new("UIAspectRatioConstraint", usernameInput)
usernameInputConstraint.AspectRatio = 4.569






local confirmTextConstraint = Instance.new("UITextSizeConstraint", confirmDetails)
confirmTextConstraint.MaxTextSize = 45
confirmTextConstraint.MinTextSize = 1

local dividerTextConstraint = Instance.new("UITextSizeConstraint", dividerLabel)
dividerTextConstraint.MaxTextSize = 34
dividerTextConstraint.MinTextSize = 1

local titleTextConstraint = Instance.new("UITextSizeConstraint", titleLabel)
titleTextConstraint.MaxTextSize = 33
titleTextConstraint.MinTextSize = 1

local discordIdTextConstraint = Instance.new("UITextSizeConstraint", discordIdInput)
discordIdTextConstraint.MaxTextSize = 45
discordIdTextConstraint.MinTextSize = 1

local hardwareIdInputTextConstraint = Instance.new("UITextSizeConstraint", hardwareIdInput)
hardwareIdInputTextConstraint.MaxTextSize = 6
hardwareIdInputTextConstraint.MinTextSize = 1

local joinDateInputTextConstraint = Instance.new("UITextSizeConstraint", joinDateInput)
joinDateInputTextConstraint.MaxTextSize = 45
joinDateInputTextConstraint.MinTextSize = 1

local usernameInputTextConstraint = Instance.new("UITextSizeConstraint", usernameInput)
usernameInputTextConstraint.MaxTextSize = 45
usernameInputTextConstraint.MinTextSize = 1



-- UIStroke & UIPadding


local confirmUIPadding = Instance.new("UIPadding", confirmDetails)
local titleUIPadding = Instance.new("UIPadding", titleLabel)
local discordIdInputPadding = Instance.new("UIPadding", discordIdInput)
local joinDateInputPadding = Instance.new("UIPadding", joinDateInput)
local usernameInputPadding = Instance.new("UIPadding", usernameInput)

local regUIStroke = Instance.new("UIStroke", registrationFrame)
local confirmUIStroke = Instance.new("UIStroke", confirmDetails)




-- Properties




-- ScreenGui

registrationUi.Name = "Register User"
registrationUi.DisplayOrder = 10000000
registrationUi.Enabled = true
registrationUi.ResetOnSpawn = false

-- Registration Frame

registrationFrame.Name = "Registration"
registrationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
registrationFrame.BackgroundColor3 = convertRGB(49, 49, 49)
registrationFrame.LayoutOrder = 10000000
registrationFrame.Position = UDim2.new(0.5, 0, 0.488, 0)
registrationFrame.Size = UDim2.new(0, 377, 0, 411)

-- UICorner & UIStroke

regUICorner.CornerRadius = UDim.new(0, 14)

regUIStroke.Color = convertRGB(34, 34, 34)
regUIStroke.Thickness = 3

-- Input Container

inputContainer.Name = "Input Container"
inputContainer.BackgroundColor3 = convertRGB(255, 255, 255)
inputContainer.BackgroundTransparency = 1
inputContainer.BorderColor3 = convertRGB(0, 0, 0)
inputContainer.BorderSizePixel = 0
inputContainer.Position = UDim2.new(0, 0, 0.138, 0)
inputContainer.Size = UDim2.new(0, 377, 0, 285)

containerLayout.Padding = UDim.new(0.02, 0)
containerLayout.FillDirection = Enum.FillDirection.Vertical
containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
containerLayout.Wraps = false
containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
containerLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
containerLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- Confirm Button

confirmDetails.Name = "Confirm"
confirmDetails.AnchorPoint = Vector2.new(0.5, 1)
confirmDetails.AutoButtonColor = false
confirmDetails.BorderColor3 = convertRGB(0, 0, 0)
confirmDetails.BackgroundColor3 = convertRGB(0, 84, 0)
confirmDetails.Modal = true
confirmDetails.Position = UDim2.new(0.5, 0, 0.976, 0)
confirmDetails.Size = UDim2.new(0, 191, 0, 56)
confirmDetails.FontFace = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Medium)
confirmDetails.Text = "Confirm"
confirmDetails.TextColor3 = convertRGB(0, 255, 0)
confirmDetails.TextScaled = true
confirmDetails.TextSize = 14
confirmDetails.TextWrapped = true

-- Confirm Button: UIStroke & UIPadding

confirmUIPadding.PaddingBottom = UDim.new(0, 4)
confirmUIPadding.PaddingTop = UDim.new(0, 6)

confirmUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
confirmUIStroke.Color = convertRGB(84, 255, 0)
confirmUIStroke.Thickness = 2

-- Labels

dividerLabel.Name = "Divider"
dividerLabel.BackgroundTransparency = 1
dividerLabel.Position = UDim2.new(0, 0, 0.037, 0)
dividerLabel.Size = UDim2.new(0, 377, 0, 34)
dividerLabel.FontFace = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Regular)
dividerLabel.Text = "______________________"
dividerLabel.TextColor3 = convertRGB(255, 255, 255)
dividerLabel.TextScaled = true
dividerLabel.TextStrokeTransparency = 1
dividerLabel.TextWrapped = true

titleLabel.Name = "Title"
titleLabel.AnchorPoint = Vector2.new(0.5, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0.5, 0, 0, 0)
titleLabel.Size = UDim2.new(0, 377, 0, 50)
titleLabel.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
titleLabel.Text = "Celestial Registration"
titleLabel.TextColor3 = convertRGB(188, 188, 188)
titleLabel.TextScaled = true
titleLabel.TextStrokeTransparency = 1
titleLabel.TextWrapped = true
titleUIPadding.PaddingLeft = UDim.new(0, 30)
titleUIPadding.PaddingRight = UDim.new(0, 30)

-- Containers



-- Hardware Id



hardwareIdContainer.Name = "Hardware ID Container"
hardwareIdContainer.BackgroundColor3 = convertRGB(36, 36, 36)
hardwareIdContainer.Size = UDim2.new(0.788, 0, 0.228, 0)

hardwareIdUICorner.CornerRadius = UDim.new(0, 8)

hardwareIdInput.Name = "Hardware ID Input"
hardwareIdInput.BackgroundTransparency = 1
hardwareIdInput.ClearTextOnFocus = false
hardwareIdInput.Position = UDim2.new(0, 0, 0, 0)
hardwareIdInput.Size = UDim2.new(1, 0, 1, 0)
hardwareIdInput.TextEditable = false
hardwareIdInput.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold)
hardwareIdInput.PlaceholderColor3 = convertRGB(178, 178, 178)
hardwareIdInput.PlaceholderText = "Hardware ID"
hardwareIdInput.Text = ""
hardwareIdInput.TextColor3 = convertRGB(126, 126, 126)
hardwareIdInput.TextScaled = true
hardwareIdInput.TextStrokeTransparency = 1
hardwareIdInput.TextTransparency = 0
hardwareIdInput.TextWrapped = true

--[[

hardwareIdDisabledFrame.Name = "Disabled"
hardwareIdDisabledFrame.BackgroundColor3 = convertRGB(113, 0, 0)
hardwareIdDisabledFrame.BackgroundTransparency = 0.7
hardwareIdDisabledFrame.Position = UDim2.new(0, 0, 0, 0)
hardwareIdDisabledFrame.Size = UDim2.new(1, 0, 1, 0)

hardwareIdDisabledIcon.Name = "Icon"
hardwareIdDisabledIcon.AnchorPoint = Vector2.new(1, 0.5)
hardwareIdDisabledIcon.BackgroundTransparency = 1
hardwareIdDisabledIcon.Position = UDim2.new(1.135, 0, 0.5, 0)
hardwareIdDisabledIcon.Size = UDim2.new(0.135, 0, 0.615, 0)
hardwareIdDisabledIcon.Image = "rbxassetid://13056312518"
hardwareIdDisabledIcon.ImageColor3 = convertRGB(255, 255, 255)
hardwareIdDisabledIcon.ImageTransparency = 0

]]



-- Username


usernameContainer.Name = "Username Container"
usernameContainer.BackgroundColor3 = convertRGB(36, 36, 36)
usernameContainer.Size = UDim2.new(0.788, 0, 0.228, 0)

usernameUICorner.CornerRadius = UDim.new(0, 8)

usernameInput.Name = "Username Input"
usernameInput.BackgroundTransparency = 1
usernameInput.ClearTextOnFocus = false
usernameInput.Position = UDim2.new(0, 0, 0, 0)
usernameInput.Size = UDim2.new(1, 0, 1, 0)
usernameInput.TextEditable = true
usernameInput.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold)
usernameInput.PlaceholderColor3 = convertRGB(178, 178, 178)
usernameInput.PlaceholderText = "Username\n(The name to appear on the script. Doesn't have to be your roblox name)"
usernameInput.Text = ""
usernameInput.TextColor3 = convertRGB(126, 126, 126)
usernameInput.TextScaled = true
usernameInput.TextStrokeTransparency = 1
usernameInput.TextTransparency = 0
usernameInput.TextWrapped = true

usernameInputPadding.PaddingBottom = UDim.new(0.15, 0)
usernameInputPadding.PaddingLeft = UDim.new(0.02, 0)
usernameInputPadding.PaddingRight = UDim.new(0.02, 0)
usernameInputPadding.PaddingTop = UDim.new(0.15, 0)



-- Join Date


joinDateContainer.Name = "Join Date Container"
joinDateContainer.BackgroundColor3 = convertRGB(36, 36, 36)
joinDateContainer.Size = UDim2.new(0.788, 0, 0.228, 0)

joinDateUICorner.CornerRadius = UDim.new(0, 8)

joinDateInput.Name = "Join Date Input"
joinDateInput.BackgroundTransparency = 1
joinDateInput.ClearTextOnFocus = false
joinDateInput.Position = UDim2.new(0, 0, 0, 0)
joinDateInput.Size = UDim2.new(1, 0, 1, 0)
joinDateInput.TextEditable = false
joinDateInput.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold)
joinDateInput.PlaceholderColor3 = convertRGB(178, 178, 178)
joinDateInput.PlaceholderText = "Join Date"
joinDateInput.Text = ""
joinDateInput.TextColor3 = convertRGB(126, 126, 126)
joinDateInput.TextScaled = true
joinDateInput.TextStrokeTransparency = 1
joinDateInput.TextTransparency = 0
joinDateInput.TextWrapped = true

--[[

joinDateDisabledFrame.Name = "Disabled"
joinDateDisabledFrame.BackgroundColor3 = convertRGB(113, 0, 0)
joinDateDisabledFrame.BackgroundTransparency = 0.7
joinDateDisabledFrame.Position = UDim2.new(0, 0, 0, 0)
joinDateDisabledFrame.Size = UDim2.new(1, 0, 1, 0)

joinDateDisabledIcon.Name = "Icon"
joinDateDisabledIcon.AnchorPoint = Vector2.new(1, 0.5)
joinDateDisabledIcon.BackgroundTransparency = 1
joinDateDisabledIcon.Position = UDim2.new(1.135, 0, 0.5, 0)
joinDateDisabledIcon.Size = UDim2.new(0.135, 0, 0.615, 0)
joinDateDisabledIcon.Image = "rbxassetid://13056312518"
joinDateDisabledIcon.ImageColor3 = convertRGB(255, 255, 255)
joinDateDisabledIcon.ImageTransparency = 0

]]

joinDateInputPadding.PaddingBottom = UDim.new(0.15, 0)
joinDateInputPadding.PaddingLeft = UDim.new(0.02, 0)
joinDateInputPadding.PaddingRight = UDim.new(0.02, 0)
joinDateInputPadding.PaddingTop = UDim.new(0.15, 0)



-- Discord Id


discordIdContainer.Name = "Discord ID Container"
discordIdContainer.BackgroundColor3 = convertRGB(36, 36, 36)
discordIdContainer.Size = UDim2.new(0.788, 0, 0.228, 0)

discordIdUICorner.CornerRadius = UDim.new(0, 8)

discordIdInput.Name = "Discord ID Input"
discordIdInput.BackgroundTransparency = 1
discordIdInput.ClearTextOnFocus = false
discordIdInput.Position = UDim2.new(0, 0, 0, 0)
discordIdInput.Size = UDim2.new(1, 0, 1, 0)
discordIdInput.TextEditable = true
discordIdInput.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold)
discordIdInput.PlaceholderColor3 = convertRGB(178, 178, 178)
discordIdInput.PlaceholderText = "Discord ID"
discordIdInput.Text = ""
discordIdInput.TextColor3 = convertRGB(126, 126, 126)
discordIdInput.TextScaled = true
discordIdInput.TextStrokeTransparency = 1
discordIdInput.TextTransparency = 0
discordIdInput.TextWrapped = true

discordIdInputPadding.PaddingBottom = UDim.new(0.15, 0)
discordIdInputPadding.PaddingLeft = UDim.new(0.02, 0)
discordIdInputPadding.PaddingRight = UDim.new(0.02, 0)
discordIdInputPadding.PaddingTop = UDim.new(0.15, 0)








-- Functions








local errorRunning = false

local function confirmBtnError(text, delay)
	local text = text or "Invalid text."
	local delay = delay or 5

	confirmDetails.TextColor3 = convertRGB(255, 0, 0)
	confirmDetails.BackgroundColor3 = convertRGB(117, 0, 0)
	confirmUIStroke.Color = convertRGB(66, 0, 0)
	confirmDetails.Text = text
	errorRunning = true
	
	task.wait(delay)

	confirmDetails.TextColor3 = convertRGB(0, 255, 0)
	confirmDetails.BackgroundColor3 = convertRGB(0, 84, 0)
	confirmUIStroke.Color = convertRGB(84, 255, 0)
	confirmDetails.Text = "Confirm"
	errorRunning = false
end

local function createCircle(button)
	local mouse = game:GetService("Players").LocalPlayer:GetMouse()
	local X = mouse.X
	local Y = mouse.Y

	coroutine.resume(coroutine.create(function()
		button.ClipsDescendants = true
		
		local circle = Instance.new("ImageLabel", button)
		circle.BackgroundColor3 = convertRGB(255, 255, 255)
		circle.BackgroundTransparency = 1
		circle.ZIndex = 10
		circle.Image = "rbxassetid://266543268"
		circle.ImageColor3 = convertRGB(0, 0, 0)
		circle.ImageTransparency = 0.8

		local newX = X - circle.AbsolutePosition.X
		local newY = Y - circle.AbsolutePosition.Y
		circle.Position = UDim2.new(0, newX, 0, newY)
		
		local size = 0
		if button.AbsoluteSize.X > button.AbsoluteSize.Y then
			size = button.AbsoluteSize.X*1.5
		elseif button.AbsoluteSize.X < button.AbsoluteSize.Y then
			size = button.AbsoluteSize.Y*1.5
		elseif button.AbsoluteSize.X == button.AbsoluteSize.Y then
			size = button.AbsoluteSize.X*1.5
		end
		
		local time = 0.7
		circle:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, -size/2, 0.5, -size/2), "Out", "Quad", time, false, nil)

		for i = 1, 100 do
			circle.ImageTransparency = circle.ImageTransparency + 0.01
			wait(time / 100)
		end
		circle:Destroy()
	end))
end




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
						value = "||"  .. hwid .. "||",
						inline = true
					},

					{
						name = "Identifier",
						value = usernameValue,
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






-- When the user provided text inputs values update, update their respected values

for _, textBox in pairs(inputContainer:GetDescendants()) do
	if textBox:IsA("TextBox") then

		if textBox.Name == "Username Input" then

			textBox:GetPropertyChangedSignal("Text"):Connect(function()
				usernameValue = textBox.Text

				if #textBox.Text > 1 then
					invalidUsernameMinLength = false
				else
					invalidUsernameMinLength = true
				end

				if #textBox.Text > 36 then
					invalidUsernameMaxLength = true
				else
					invalidUsernameMaxLength = false
				end
			end)

		elseif textBox.Name == "Discord ID Input" then

			textBox:GetPropertyChangedSignal("Text"):Connect(function()
				discordIdValue = textBox.Text

				if tonumber(textBox.Text) then
					discordIdNumber = true
				else
					discordIdNumber = false
				end

				if #textBox.Text < 18 then
					invalidDiscordIdLength = true
				else
					invalidDiscordIdLength = false
				end
			end)
			
		end
	end
end

-- Updating the non-editable values

local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local hashedHWID = utils.hash(hwid, "SHA-384")
hardwareIdInput.Text = hashedHWID
hwidValue = hardwareIdInput.Text

joinDateInput.Text = os.date("%x, %I %p")
joinDateValue = joinDateInput.Text


-- Confirm Button

confirmDetails.MouseEnter:Connect(function()
	if not errorRunning then
		confirmDetails.BackgroundColor3 = Color3.new(0, 0.309804, 0)
		confirmDetails.UIStroke.Color = Color3.new(0.188235, 0.560784, 0)
	end
end)

confirmDetails.MouseLeave:Connect(function()
	if not errorRunning then
		confirmDetails.BackgroundColor3 = Color3.new(0, 0.333333, 0)
		confirmDetails.UIStroke.Color = Color3.new(0.333333, 1, 0)
	end
end)

confirmDetails.MouseButton1Click:Connect(function()
	createCircle(confirmDetails)

	-- Checks & restrictions

	if confirmDetails.TextColor3 == convertRGB(255, 0, 0) then -- If the button text color is red/in the error state, don't fire the error function again
		return
	end

	if invalidUsernameMinLength then
		confirmBtnError("Provided username has to be more than 1 character.", 4)
		return
	end

	if invalidUsernameMaxLength then
		confirmBtnError("Provided username can't be more than 36 characters.", 4)
		return
	end

	if invalidDiscordIdLength then
		confirmBtnError("Provided discord id can't less than 18 characters.", 4)
		return
	end

	if not discordIdNumber then
		confirmBtnError("DiscordId expected a valid number.", 4)
		return
	end


	-- Register function

	sendEmbed()

	writefile("Celestial ScriptHub/Registered.txt", "true")

	local successfulRegister = readfile("Celestial ScriptHub/Registered.txt")

	if successfulRegister == "true" then
		successfulRegister = true
	elseif successfulRegister == "false" then
		successfulRegister = false
	end

	wait(0.05)

	if successfulRegister then
		confirmDetails.Text = "Successfully registered."
		wait(3.5)
		registrationUi:Destroy()
		blur:Destroy()
	end
end)