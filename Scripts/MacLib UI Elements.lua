sections.miscSection2:Button({
	Name = "Button",
    Disabled = true,
	Callback = function()
        print("clicked")
    end,
})

testToggle = sections.miscSection2:Toggle({
    Name = "Toggle",
    Disabled = true,
    Default = false,
    Callback = function(value)
        print("state: ", value)
    end,
}, "testToggle")

local testDropdown
testDropdown = sections.miscSection2:Dropdown({
	Name = "Dropdown",
	Search = true,
	Multi = true,
	Required = true,
    Disabled = true,
	Options = {"Option 1", "Option 2", "Option 3", "Option 4", "Option 5", "Option 6"},
	Default = {"Option 1"},
	Callback = function(value)
        warn("---------------------------------")
            
        for _, weaponName in ipairs(testDropdown.Value) do
            print("Fired event for weapon:", weaponName)
        end
    end,
}, "testDropdown")

testSlider = sections.miscSection2:Slider({
    Name = "Slider",
    Default = 5,
    Minimum = 1,
    Maximum = 100,
    Precision = 0,
    DisplayMethod = "Round",
    Disabled = true,
    Callback = function(value)
        print("value: ", value)
    end,
}, "testSlider")

testColorpicker = sections.miscSection2:Colorpicker({
	Name = "Colorpicker",
	Default = Color3.fromRGB(50, 98, 168),
	Alpha = 0,
    AlphaEnabled = true,
    Disabled = true,
	Callback = function(color, alpha)
        print("color: ", tostring(color) .. " | alpha: ", alpha)
	end,
}, "testColorpicker")

testKeybind = sections.miscSection2:Keybind({
	Name = "Keybind",
    Disabled = true,
    Default = Enum.KeyCode.F,
	Callback = function(binded)
        print("triggered keybind callback")
    end,
	onBinded = function(bind)
        print("accepted bind: ", tostring(bind.Name))
	end,
    onBindHeld = function(heldDown, bind, rg)
        print("heldDown: ", heldDown)
        print("bind: ", bind)
    end,
}, "testKeybind")

testInput = sections.miscSection2:Input({
	Name = "Input",
	Placeholder = "Placeholder",
	AcceptedCharacters = "Numeric",
    Disabled = true,
	Callback = function(value)
		print("input set: ".. value)
	end,
    onChanged = function(value)
        print("text changed: ", value)
    end,
}, "testInput")