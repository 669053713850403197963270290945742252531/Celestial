local MacLib = loadstring(readfile("Celestial/Revamped UI Libraries/Maclib - Revamped.lua"))()

local Window = MacLib:Window({
	Title = "Maclib Demo",
	Subtitle = "This is a subtitle.",
	Size = UDim2.fromOffset(868, 650),
	DragStyle = 1,
	DisabledWindowControls = {},
	ShowUserInfo = false,
	Keybind = Enum.KeyCode.RightShift,
	AcrylicBlur = true,
    notifSounds = false,
    GlobalSettings = true
})

local globalSettings = {
	UIBlurToggle = Window:GlobalSetting({
		Name = "Acrylic UI Blur",
        Tooltip = "ui blur",
		Default = Window:GetAcrylicBlurState(),
		Callback = function(bool)
			Window:SetAcrylicBlurState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
				Lifetime = 5
			})
		end,
	}),
	ShowUserInfo = Window:GlobalSetting({
		Name = "User Info",
        Tooltip = false,
		Default = Window:GetUserInfoState(),
		Callback = function(bool)
			Window:SetUserInfoState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Showing" or "Redacted") .. " User Info",
				Lifetime = 5
			})
		end,
	})
}

local tabGroups = {
	TabGroup1 = Window:TabGroup()
}

local tabs = {
	Main = tabGroups.TabGroup1:Tab({ Name = "Demo", Image = "rbxassetid://18821914323", Disabled = false }),
	DisabledElements = tabGroups.TabGroup1:Tab({ Name = "Disable Elements", Image = "rbxassetid://10734984834", Disabled = false }),
	Settings = tabGroups.TabGroup1:Tab({ Name = "Settings", Image = "rbxassetid://10734950309", Disabled = false })
}

local sections = {
	MainSection1 = tabs.Main:Section({ Side = "Left" }),

	ElementsSection1 = tabs.DisabledElements:Section({ Side = "Left" }),
}

-- Section: Main

sections.MainSection1:Header({
	Name = "Header #1"
})

sections.MainSection1:Button({
	Name = "Button",
    Disabled = false,
    Tooltip = false,
	Callback = function()
		Window:Dialog({
			Title = Window.Settings.Title,
			Description = "Lorem ipsum odor amet, consectetuer adipiscing elit. Eros vestibulum aliquet mattis, ex platea nunc.",
			Buttons = {
				{
					Name = "Confirm",
					Callback = function()
						--print("Confirmed!")
					end,
				},
				{
					Name = "Cancel"
				}
			}
		})
	end,
})

sections.MainSection1:Input({
	Name = "Input",
    Tooltip = false,
	Placeholder = "Input",
	AcceptedCharacters = "All",
    Disabled = false,
	Callback = function(input)
		Window:Notify({
			Title = Window.Settings.Title,
			Description = "Successfully set input to " .. input
		})
	end,
	onChanged = function(input)
		print("Input is now " .. input)
	end,
}, "Input")

sections.MainSection1:Slider({
	Name = "Slider",
    Tooltip = false,
    LimitInput = {"Less", "Greater"},
    RoundedValue = true,
    CustomValue = true,
	Default = 50,
	Minimum = 0,
	Maximum = 100,
	DisplayMethod = "Round",
	Precision = 0,
    Disabled = false,
	Callback = function(Value)
		print("Changed to ".. Value)
	end
}, "Slider")

sections.MainSection1:Toggle({
	Name = "Toggle",
    Tooltip = false,
	Default = false,
    Disabled = false,
	Callback = function(value)
		Window:Notify({
			Title = Window.Settings.Title,
			Description = (value and "Enabled " or "Disabled ") .. "Toggle"
		})
	end,
}, "Toggle")

sections.MainSection1:Keybind({
	Name = "Keybind",
    Tooltip = false,
    Default = false,
    Disabled = false,
    BlacklistedBinds = {Enum.KeyCode.Backspace},
	Callback = function(binded)
		Window:Notify({
			Title = "Demo Window",
			Description = "Pressed keybind - "..tostring(binded.Name),
			Lifetime = 3
		})
	end,
	onBinded = function(bind)
		Window:Notify({
			Title = "Demo Window",
			Description = "Successfully Binded Keybind to - "..tostring(bind.Name),
			Lifetime = 3
		})
	end,
}, "Keybind")

local Colorpicker = sections.MainSection1:Colorpicker({
	Name = "Colorpicker",
    Tooltip = false,
	Default = Color3.fromRGB(0, 255, 255),
	Alpha = 0,
    Disabled = false,
    AlphaEnabled = false,
	Rainbow = true,
	Callback = function(color)
		print("Color: ", color)
	end,
}, "Colorpicker")

sections.MainSection1:Colorpicker({
	Name = "Transparency Colorpicker",
    Tooltip = false,
	Default = Color3.fromRGB(255,0,0),
	Alpha = 0.5,
    Disabled = false,
    AlphaEnabled = true,
	Rainbow = false,
	Callback = function(color, alpha)
		print("Color: ", color, " Alpha: ", alpha)
	end,
}, "TransparencyColorpicker")

local rainbowActive
local rainbowConnection
local hue = 0

sections.MainSection1:Toggle({
	Name = "Rainbow",
    Tooltip = false,
	Default = false,
    Disabled = false,
	Callback = function(value)
		rainbowActive = value

		if rainbowActive then
			rainbowConnection = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
				hue = (hue + deltaTime * 0.1) % 1
				Colorpicker:SetColor(Color3.fromHSV(hue, 1, 1))
			end)
		elseif rainbowConnection then
			rainbowConnection:Disconnect()
			rainbowConnection = nil
		end
	end,
}, "RainbowToggle")

local optionTable = {
	"Apple",
	"Banana",
	"Orange",
	"Grapes",
	"Pineapple",
	"Mango",
	"Strawberry",
	"Blueberry",
	"Watermelon",
	"Peach"
}

local Dropdown = sections.MainSection1:Dropdown({
	Name = "Dropdown",
    Tooltip = false,
	Multi = false,
	Required = true,
	Options = optionTable,
	Default = 1,
    Disabled = false,
	Callback = function(Value)
		print("Dropdown changed: ".. Value)
	end,
}, "Dropdown")

local MultiDropdown = sections.MainSection1:Dropdown({
	Name = "Multi Dropdown",
    Tooltip = false,
	Search = true,
	Multi = true,
	Required = false,
	Options = optionTable,
	Default = {"Apple", "Orange"},
    Disabled = false,
	Callback = function(Value)
		local Values = {}
		for Value, State in next, Value do
			table.insert(Values, Value)
		end
		print("Mutlidropdown changed:", table.concat(Values, ", "))
	end,
}, "MultiDropdown")

sections.MainSection1:Button({
	Name = "Update Selection",
    Tooltip = false,
    Disabled = false,
	Callback = function()
		Dropdown:UpdateSelection("Grapes")
		MultiDropdown:UpdateSelection({"Banana", "Pineapple"})
	end,
})

sections.MainSection1:Divider()

sections.MainSection1:Header({
	Text = "Header #2"
})

sections.MainSection1:Paragraph({
	Header = "Paragraph",
	Body = "Paragraph body. Lorem ipsum odor amet, consectetuer adipiscing elit. Morbi tempus netus aliquet per velit est gravida."
})

sections.MainSection1:Label({
	Text = "Label. Lorem ipsum odor amet, consectetuer adipiscing elit."
})

sections.MainSection1:SubLabel({
	Text = "Sub-Label. Lorem ipsum odor amet, consectetuer adipiscing elit."
})

-- Section: Elements

local isDisabled = true

sections.ElementsSection1:Button({
	Name = "Button",
    Tooltip = "this is a tooltipped button",
    Disabled = isDisabled,
	Callback = function()
		Dropdown:UpdateSelection("Grapes")
		MultiDropdown:UpdateSelection({"Banana", "Pineapple"})
	end,
})

local NewDropdown = sections.ElementsSection1:Dropdown({
	Name = "Dropdown",
    Tooltip = "tooltip dropdown",
	Multi = false,
	Required = true,
	Options = optionTable,
	Default = 1,
    Disabled = isDisabled,
	Callback = function(Value)
		print("Dropdown changed: ".. Value)
	end,
}, "NewDropdown")

sections.ElementsSection1:Toggle({
	Name = "Toggle",
    Tooltip = "tooltip toggle",
	Default = false,
    Disabled = isDisabled,
	Callback = function(value)
		print(value)
	end
}, "RainbowToggle")

local NewColorpicker = sections.ElementsSection1:Colorpicker({
	Name = "Colorpicker",
    Tooltip = "tooltip colorpicker",
	Default = Color3.fromRGB(0, 255, 255),
	Alpha = 0.5,
    Disabled = isDisabled,
    AlphaEnabled = true,
	Callback = function(color, alpha)
		print("Color: ", color, " Alpha: ", alpha)
	end,
}, "NewColorpicker")

local AlphaColorpicker = sections.ElementsSection1:Colorpicker({
	Name = "Disabled Alpha Colorpicker",
    Tooltip = "alpha disabled tooltip colorpicker",
	Default = Color3.fromRGB(255, 0, 0),
	Alpha = 0,
    Disabled = isDisabled,
    AlphaEnabled = false,
	Callback = function(color, alpha)
		print("Color: ", color, " Alpha: ", alpha)
	end,
}, "AlphaColorpicker")

sections.ElementsSection1:Input({
	Name = "Input",
    Tooltip = "tooltip input",
	Placeholder = "Input",
	AcceptedCharacters = "All",
    Disabled = isDisabled,
	Callback = function(input)
		Window:Notify({
			Title = Window.Settings.Title,
			Description = "Successfully set input to " .. input
		})
	end,
	onChanged = function(input)
		print("Input is now " .. input)
	end,
}, "NewInput")

sections.ElementsSection1:Slider({
	Name = "Slider",
    Tooltip = "tooltip slider",
    LimitInput = {"Less", "Greater"},
    RoundedValue = true,
    CustomValue = true,
	Default = 50,
	Minimum = 0,
	Maximum = 100,
	DisplayMethod = "Round",
	Precision = 0,
    Disabled = isDisabled,
	Callback = function(Value)
		print("Changed to ".. Value)
	end
}, "NewSlider")

sections.ElementsSection1:Keybind({
	Name = "Keybind",
    Tooltip = "keybind tooltip rtehg",
    Default = false,
    Disabled = isDisabled,
    BlacklistedBinds = {Enum.KeyCode.Backspace},
	Callback = function(binded)
		Window:Notify({
			Title = "Demo Window",
			Description = "Pressed keybind - "..tostring(binded.Name),
			Lifetime = 3
		})
	end,
	onBinded = function(bind)
		Window:Notify({
			Title = "Demo Window",
			Description = "Successfully Binded Keybind to - "..tostring(bind.Name),
			Lifetime = 3
		})
	end,
}, "Keybind")

MacLib:SetFolder("Maclib")
tabs.Settings:InsertConfigSection("Left")

Window.onUnloaded(function()
	--print("Unloaded!")
end)

tabs.Main:Select()
MacLib:LoadAutoLoadConfig()