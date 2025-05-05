local commandUI = {}

local uiLocation = typeof(gethui) == "function" and gethui() or game:GetService("CoreGui")

-- Destroying any existing instances of the ui

if uiLocation:FindFirstChild("Celestial Commands") then
    uiLocation["Celestial Commands"]:Destroy()
    return
end

-- Helper functions

local function convertRGB(r, g, b)
    return Color3.new(r / 255, g / 255, b / 255)
end

-- Instances

local commandUi = Instance.new("ScreenGui", uiLocation)
local commandsFrame = Instance.new("Frame", commandUi)

local commandsFrameUICorner = Instance.new("UICorner", commandsFrame)
local commandsFrameUIStroke = Instance.new("UIStroke", commandsFrame)
local commandsContainer = Instance.new("ScrollingFrame", commandsFrame)
local commandContainerLayout = Instance.new("UIGridLayout", commandsContainer)

local searchBox = Instance.new("TextBox", commandsFrame)
local searchBoxPadding = Instance.new("UIPadding", searchBox)
local searchBoxUICorner = Instance.new("UICorner", searchBox)

local dividerLabel = Instance.new("TextLabel", commandsFrame)
local titleLabel = Instance.new("TextLabel", commandsFrame)
local titleLabelPadding = Instance.new("UIPadding", titleLabel)

-- Constraints


local commandFrameConstraint = Instance.new("UIAspectRatioConstraint", commandsFrame)
commandFrameConstraint.AspectRatio = 0.886

local searchBoxConstraint = Instance.new("UIAspectRatioConstraint", searchBox)
searchBoxConstraint.AspectRatio = 9.415

local dividerLabelConstraint = Instance.new("UIAspectRatioConstraint", dividerLabel)
dividerLabelConstraint.AspectRatio = 11.088

local titleConstraint = Instance.new("UIAspectRatioConstraint", titleLabel)
titleConstraint.AspectRatio = 7.54

local commandsContainerConstraint = Instance.new("UIAspectRatioConstraint", commandsContainer)
commandsContainerConstraint.AspectRatio = 1.163







local searchBoxTextConstraint = Instance.new("UITextSizeConstraint", searchBox)
searchBoxTextConstraint.MaxTextSize = 27
searchBoxTextConstraint.MinTextSize = 1

local dividerLabelTextConstraint = Instance.new("UITextSizeConstraint", dividerLabel)
dividerLabelTextConstraint.MaxTextSize = 34
dividerLabelTextConstraint.MinTextSize = 1

local titleTextConstraint = Instance.new("UITextSizeConstraint", titleLabel)
titleTextConstraint.MaxTextSize = 33
titleTextConstraint.MinTextSize = 1




-- Properties




-- ScreenGui

commandUi.Name = "Celestial Commands"
commandUi.DisplayOrder = 10000000
commandUi.Enabled = true
commandUi.ResetOnSpawn = false

-- Commands Frame

commandsFrame.Name = "Commands"
commandsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
commandsFrame.BackgroundColor3 = convertRGB(49, 49, 49)
commandsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
commandsFrame.Size = UDim2.new(0.181, 0, 0.422, 0)

commandsFrameUICorner.CornerRadius = UDim.new(0, 14)

-- UIStroke

commandsFrameUIStroke.Color = convertRGB(34, 34, 34)
commandsFrameUIStroke.Thickness = 3

-- Commands Container

commandsContainer.Name = "Commands"
commandsContainer.AnchorPoint = Vector2.new(0, 0)
commandsContainer.BackgroundTransparency = 1
commandsContainer.Position = UDim2.new(0, 0, 0.238, 0)
commandsContainer.BorderSizePixel = 0
commandsContainer.Size = UDim2.new(1, 0, 0.762, 0)
commandsContainer.AutomaticCanvasSize = "Y"
commandsContainer.CanvasSize = UDim2.new(0, 0, 2, 0)
commandsContainer.ScrollBarImageColor3 = convertRGB(0, 0, 140)
commandsContainer.ScrollBarThickness = 5

-- Search Box

searchBox.Name = "Search"
searchBox.BackgroundColor3 = convertRGB(34, 34, 34)
searchBox.BackgroundTransparency = 0
searchBox.BorderColor3 = convertRGB(0, 0, 0)
searchBox.BorderSizePixel = 0
searchBox.ClearTextOnFocus = false
searchBox.CursorPosition = -1
searchBox.Interactable = 1
searchBox.MultiLine = false
searchBox.Position = UDim2.new(0.015, 0, 0.131, 0)
searchBox.SelectionStart = -1
searchBox.Size = UDim2.new(0.968, 0, 0.091, 0)
searchBox.TextEditable = true
searchBox.Visible = true
searchBox.FontFace = Font.new("rbxasset://fonts/families/Inter.json", Enum.FontWeight.Medium)
searchBox.LineHeight = -1
searchBox.MaxVisibleGraphemes = -1
searchBox.PlaceholderColor3 = convertRGB(178, 178, 178)
searchBox.PlaceholderText = "Search"
searchBox.Text = ""
searchBox.TextColor3 = convertRGB(0, 0, 140)
searchBox.TextScaled = true
searchBox.TextSize = 14
searchBox.TextStrokeTransparency = 1
searchBox.TextWrapped = true

searchBoxUICorner.CornerRadius = UDim.new(0, 10)
searchBoxPadding.PaddingBottom = UDim.new(0, 7)
searchBoxPadding.PaddingTop = UDim.new(0, 7)

-- Labels

dividerLabel.Name = "Divider"
dividerLabel.BackgroundTransparency = 1
dividerLabel.Position = UDim2.new(0, 0, 0.037, 0)
dividerLabel.Size = UDim2.new(1, 0, 0.08, 0)
dividerLabel.FontFace = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Regular)
dividerLabel.Text = "______________________"
dividerLabel.TextColor3 = convertRGB(0, 0, 90)
dividerLabel.TextScaled = true
dividerLabel.TextStrokeTransparency = 1
dividerLabel.TextWrapped = true

titleLabel.Name = "Title"
titleLabel.AnchorPoint = Vector2.new(0.5, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0.5, 0, 0, 0)
titleLabel.Size = UDim2.new(0, 377, 0, 50)
titleLabel.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
titleLabel.Text = "Celestial Commands"
titleLabel.TextColor3 = convertRGB(0, 0, 140)
titleLabel.TextScaled = true
titleLabel.TextStrokeTransparency = 1
titleLabel.TextWrapped = true
titleLabelPadding.PaddingLeft = UDim.new(0, 30)
titleLabelPadding.PaddingRight = UDim.new(0, 30)

-- Container

commandsContainer.Name = "Commands"

commandContainerLayout.CellPadding = UDim2.new(0, 3, 0, 3)
commandContainerLayout.CellSize = UDim2.new(0, 230, 0, 30)
commandContainerLayout.FillDirection = Enum.FillDirection.Horizontal
commandContainerLayout.FillDirectionMaxCells = 2


-- Functions


commandUI.fetchUI = function()
    return commandUi
end

commandUI.createCommand = function(cmdName)
    -- Create a new TextBox for each command

    local newCommand = Instance.new("TextBox", commandsContainer)
    newCommand.Name = cmdName
    newCommand.AnchorPoint = Vector2.new(0, 0)
    newCommand.BackgroundTransparency = 0
    newCommand.BackgroundColor3 = convertRGB(34, 34, 34)
    newCommand.BorderSizePixel = 0
    newCommand.ClearTextOnFocus = false
    newCommand.TextEditable = false
    newCommand.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
    newCommand.Text = cmdName
    newCommand.TextColor3 = convertRGB(0, 0, 140)
    newCommand.TextScaled = true
    newCommand.TextWrapped = true

    -- Layout & Padding

    local newCommandPadding = Instance.new("UIPadding", newCommand)
    newCommandPadding.PaddingLeft = UDim.new(0, 10)
    newCommandPadding.PaddingRight = UDim.new(0, 10)

    local newCommandConstraint = Instance.new("UIAspectRatioConstraint", newCommand)
    newCommandConstraint.AspectRatio = 7.54

    local newCommandUICorner = Instance.new("UICorner", newCommand)
    newCommandUICorner.CornerRadius = UDim.new(0, 10)
end

-- Searching

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local searchText = string.lower(searchBox.Text)
	
	for _, cmd in pairs(commandsContainer:GetChildren()) do
		if cmd:IsA("TextBox") then
			if string.find(string.lower(cmd.Name), searchText) then
				cmd.Visible = true
			else
				cmd.Visible = false
			end
		end
	end
end)


return commandUI