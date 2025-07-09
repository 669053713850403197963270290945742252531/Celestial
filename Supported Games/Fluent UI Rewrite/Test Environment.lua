local function destroyFluent(destroyWindow, destroyBlur)
    if destroyWindow then
        for _, obj in ipairs(gethui():GetChildren()) do
            if obj:IsA("ScreenGui") and obj.Name:find("FluentRenewed") then
                obj:Destroy()
            end
        end

    end

    if destroyBlur then
        -- Destroy acrylic blur

        for _, obj in ipairs(game:GetService("Workspace").CurrentCamera:GetDescendants()) do
            if obj:IsA("Folder") and obj:FindFirstChild("Body") then
                obj:Destroy()
            end
        end

    end
end

destroyFluent(true, true)

local Library = loadstring(game:HttpGet("https://github.com/669053713850403197963270290945742252531/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Fluent-Renewed/refs/heads/main/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Fluent-Renewed/refs/heads/main/Addons/InterfaceManager.luau"))()

local Options = Library.Options
local Window = Library:CreateWindow{
    Title = "Fluent " .. Library.Version,
    SubTitle = "Developed and maintained by Corrade",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 525),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
}

local Tabs = {
    Main = Window:CreateTab{ Title = "Main", Icon = "phosphor-users-bold" },
    Settings = Window:CreateTab{ Title = "Settings", Icon = "settings" }
}



-- Functions

local function isUnloaded()
    for _, obj in ipairs(gethui():GetChildren()) do
        if obj:IsA("ScreenGui") and obj.Name:find("FluentRenewed") then
            return false -- GUI still exists, library loaded
        end
    end
    return true -- GUI not found, library unloaded
end



local Toggle = Tabs.Main:CreateToggle("MyToggle", {Title = "Toggle", Default = false })

Toggle:OnChanged(function(enabled)
    print("Toggle changed:", enabled)

    if enabled then
        task.spawn(function()
            while Options.MyToggle.Value and not Library.Unloaded do

                warn("peak")

                task.wait(0.1)
            end
        end)
    end
end)




local function unloadModules()
	if isUnloaded() then return end

	local modules = { "MyToggle" }

	for _, moduleName in ipairs(modules) do
		if Options[moduleName] and Options[moduleName].Value == true then
			-- Library check before disabling
			if Options[moduleName].Object and Options[moduleName].Object:IsDescendantOf(game) then
				Options[moduleName]:SetValue(false)
			end
		end
	end
end


--[[

Library.OnUnload:Connect(function()
    unloadModules()
end)

]]

for _, fluent in pairs(gethui():GetDescendants()) do
	if fluent:IsA("ScreenGui") and fluent.Name:find("FluentRenewed") then
		task.spawn(function()
			fluent.AncestryChanged:Connect(function(_, parent)
				if not parent then
					unloadModules()

                    destroyFluent(false, true)                
				end
			end)
		end)
	end
end





--[[

for _, obj in ipairs(gethui():GetChildren()) do
	if obj:IsA("ScreenGui") and obj.Name:find("FluentRenewed") then obj:Destroy() end
end

for _, obj in ipairs(workspace.CurrentCamera:GetDescendants()) do
	if obj.Name == "Folder" and obj:IsA("Folder") and obj:FindFirstChild("Body") then obj:Destroy() end
end

]]









SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes{}
InterfaceManager:SetFolder("Celestial ScriptHub")
SaveManager:SetFolder("Celestial ScriptHub/Testing Environment")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Library:Notify{
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
}

SaveManager:LoadAutoloadConfig()