-- Rayfield Interface

local rayfieldLib = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local rayfieldWindow = rayfieldLib:CreateWindow({
	Name = "Celestial Compatibility Test",
	Icon = 127059246403673,
	LoadingTitle = "Celestial Compatibility Test",
	LoadingSubtitle = "Build - V.01",
	Theme = "Default",

	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,

	Discord = {
		Enabled = true,
		Invite = "sGBSAHgaN8",
		RememberJoins = true
	}
})

local tabs = {
    compat = rayfieldWindow:CreateTab("Compatibility", 132535434457179)
}

local sections = {
    functionsSection = tabs.compat:CreateSection("Functions")
}


-- Tab: Compatibility


-- Section: Functions



local functionStatuses = {}
local function updateFunctionStatus(funcName, success)
    if functionStatuses[funcName] then
        local color = success and Color3.fromRGB(43, 181, 22) or Color3.fromRGB(181, 22, 22)
        local statusSymbol = success and "✅" or "❌"
        functionStatuses[funcName]:Set(funcName .. " " .. statusSymbol, nil, color, false)
    end
end

-- Fuck exploits and their restricted functions

local function isFunction(name)
    local success, result = pcall(function()
        return _G[name] ~= nil or getfenv()[name] ~= nil
    end)
    return success and result
end

local function resetStatuses()
	-- Reset labels

	for funcName, label in pairs(functionStatuses) do
		label:Set(funcName .. " ❌", nil, Color3.fromRGB(181, 22, 22), false) -- Preserve icon
	end

	-- Remove test objects
	
	local testFile = "test_file.txt"
	local testFolder = "test_folder"
	local testAsset = "test_asset.png"

	-- Remove test files

	if isfile and delfile then
		if isfile(testFile) then delfile(testFile) end
		if isfile(testAsset) then delfile(testAsset) end
	end

	-- Remove test folder

	if isfolder and delfolder then
		if isfolder(testFolder) then delfolder(testFolder) end
	end
end

local function testFireClickDetector()
    if not fireclickdetector then
        updateFunctionStatus("fireclickdetector", false)
        return
    end

    -- Create test part

    local testPart = Instance.new("Part", game.Workspace)
    local clickDetector = Instance.new("ClickDetector", testPart)

    -- If the ClickDetector gets triggered

    local clicked = false
    clickDetector.MouseClick:Connect(function()
        clicked = true
    end)

    fireclickdetector(clickDetector)

    -- Check if it was triggered
	
    task.wait(0.5)
    updateFunctionStatus("fireclickdetector", clicked)
    testPart:Destroy()
end

local function testFireProximityPrompt()
    if not fireproximityprompt then
        updateFunctionStatus("fireproximityprompt", false)
        return
    end

    -- Create test part

    local testPart = Instance.new("Part", game.Workspace)
    local proximityPrompt = Instance.new("ProximityPrompt", testPart)

    -- If the ProximityPrompt gets triggered

    local triggered = false
    proximityPrompt.Triggered:Connect(function()
        triggered = true
    end)

    fireproximityprompt(proximityPrompt)

    -- Check if it was triggered

    task.wait(0.5)
    updateFunctionStatus("fireproximityprompt", triggered)
    testPart:Destroy()
end

local function testFireTouchInterest()
    if not firetouchinterest then
        updateFunctionStatus("firetouchinterest", false)
        return
    end

    -- Create a part

    local touchedPart = Instance.new("Part", game.Workspace)

    -- HRP check

    local character = game.Players.LocalPlayer.Character
    if not character or not character.HumanoidRootPart then
        updateFunctionStatus("firetouchinterest", false)
        return
    end

    -- If the touch event gets triggered

    local touched = false
    touchedPart.Touched:Connect(function(hit)
        if hit == character.HumanoidRootPart then
            touched = true
        end
    end)

    firetouchinterest(touchedPart, character.HumanoidRootPart, 0)

    -- Check if it was triggered
	
    task.wait(0.5)
    updateFunctionStatus("firetouchinterest", touched)
    touchedPart:Destroy()
end

local function testIsRbxActive()
    local isActive = false

    -- Check if isrbxactive exists and fallback to isgameactive if isrbxactive is not accessible
	
    if isFunction("isrbxactive") then
        isActive = isrbxactive()
    elseif isFunction("isgameactive") then
        isActive = isgameactive()
    end

    -- Boolean check

    local isValidBoolean = typeof(isActive) == "boolean"
    updateFunctionStatus("isrbxactive", isValidBoolean)
end

local function testGethui()
	if typeof(gethui()) ~= "Instance" then
		updateFunctionStatus("gethui", false)
	elseif typeof(gethui()) == "Instance" then
		updateFunctionStatus("gethui", true)
	end
end

local function testSetclipboard()
    -- Check if setclipboard exists and fallback to toclipboard if setclipboard is not accessible
	
    if isFunction("setclipboard") then
        updateFunctionStatus("setclipboard", true)
    elseif isFunction("toclipboard") then
        updateFunctionStatus("setclipboard", true)
    end
end

local function testIdentifyExecutor()
    if isFunction("identifyexecutor") then
        updateFunctionStatus("identifyexecutor", true)
    elseif isFunction("getexecutorname") then
        updateFunctionStatus("identifyexecutor", true)
    end
end

local function testHttpRequest()
    local httpRequestFunc

    if isFunction("request") then
        httpRequestFunc = request
    elseif isFunction("http.request") then
        httpRequestFunc = http.request
    elseif isFunction("http_request") then
        httpRequestFunc = http_request
    end

    local testUrl = "https://example.com/"

    -- Make an http request

    local success, response = pcall(function()
        return httpRequestFunc({Url = testUrl, Method = "GET"})
    end)

    -- Successful request check
	
    if success then
        if response then
            if response.StatusCode == 200 then
                updateFunctionStatus("request", true)
            else
                updateFunctionStatus("request", false)
                print("Request failed with StatusCode:", response.StatusCode)
            end
        end
    end
end

local function testSetFpsCap()
    local fpsCap = 60
    setfpscap(fpsCap)

    task.wait(1)

    -- FPS measurement

    local fpsCount = 0
    local lastTime = tick()

    -- Sample FPS over a 1 second time period

    game:GetService("RunService").RenderStepped:Connect(function()
        if tick() - lastTime >= 1 then
            -- After 1 second, give back fps and check it

            if fpsCount <= fpsCap then
                updateFunctionStatus("setfpscap", true)
            end

            setfpscap(0)
        else
            fpsCount = fpsCount + 1
        end
    end)
end

local function testGetgenv()
	getgenv().TEST_GLOBAL = true

	if getgenv().TEST_GLOBAL == true then
		updateFunctionStatus("getgenv", true)
	end

	getgenv().TEST_GLOBAL = nil
end



local testType = "Basic"
local beginTestBtn
local testTypeParagraph
testTypeDropdown = tabs.compat:CreateDropdown({
	Name = "Test Type",
	Options = {"Basic", "Advanced"},
	CurrentOption = "Basic",
	MultipleOptions = false,
	Flag = "testTypeDropdown",
	Callback = function(value)
		for k, v in pairs(value) do
			testType = v
			beginTestBtn:Set("Start " .. v .. " Test", "Interact")

			if v == "Basic" then
				testTypeParagraph:Set({Title = "Basic Test", Content = "Determines if certain functions exist in the current environment by checking whether they are fully defined and accessible."})
			elseif v == "Advanced" then
				testTypeParagraph:Set({Title = "Advanced Test", Content = "Determines if certain functions exist in the current environment by verifying that they are fully defined, accessible, and perform their intended functions correctly."})
			end
		end
	end,
})

beginTestBtn = tabs.compat:CreateButton({
    Name = "Start " .. testType .. " Test",
    Callback = function()
        local testFile = "test_file.txt"
        local testFolder = "test_folder"
        local testContent = "test content"

		resetStatuses()
		wait(0.03)
        if testType == "Basic" then
            for funcName in pairs(functionStatuses) do
                updateFunctionStatus(funcName, _G[funcName] ~= nil or getfenv()[funcName] ~= nil)
            end
        elseif testType == "Advanced" then
            -- writefile
            local writeSuccess = pcall(function() writefile(testFile, testContent) end)
            updateFunctionStatus("writefile", writeSuccess and isfile(testFile))

            -- readfile
            local readSuccess, readData = pcall(function() return readfile(testFile) end)
            updateFunctionStatus("readfile", readSuccess and readData == testContent)

            -- isfile
            updateFunctionStatus("isfile", isfile(testFile))

            -- makefolder
            local makeFolderSuccess = pcall(function() makefolder(testFolder) end)
            updateFunctionStatus("makefolder", makeFolderSuccess and isfolder(testFolder))

            -- isfolder
            updateFunctionStatus("isfolder", isfolder(testFolder))

            -- getcustomasset
            if getcustomasset then
                local testAsset = "test_asset.png"
                if not isfile(testAsset) then
                    writefile(testAsset, "placeholder_data") -- Create test asset
                end
                local assetSuccess, assetPath = pcall(function() return getcustomasset(testAsset) end)
                updateFunctionStatus("getcustomasset", assetSuccess and typeof(assetPath) == "string" and #assetPath > 0)
            else
                updateFunctionStatus("getcustomasset", false)
            end

			-- fireclickdetector
			testFireClickDetector()

			-- fireproximityprompt
			testFireProximityPrompt()

			-- firetouchinterest
			testFireTouchInterest()

			-- isrbxactive (isgameactive)
			testIsRbxActive()

			-- mouse1click
			updateFunctionStatus("mouse1click", isFunction("mouse1click"))

			-- gethui
			testGethui()

			-- setclipboard
			testSetclipboard()

			-- identifyexecutor
			testIdentifyExecutor()

			-- request
			testHttpRequest()

			-- setfpscap
			testSetFpsCap()

			-- getgenv
			testGetgenv()
        end
    end,
})

testTypeParagraph = tabs.compat:CreateParagraph({Title = "Basic Test", Content = "Determines if certain functions exist in the current environment by checking whether they are fully defined and accessible."})

resetStatusBtn = tabs.compat:CreateButton({
    Name = "Reset Statuses",
    Callback = function()
		resetStatuses()
    end,
})

functionStatuses = {
    writefile = tabs.compat:CreateLabel("writefile ❌", 73470048335590, Color3.fromRGB(181, 22, 22), false),
    readfile = tabs.compat:CreateLabel("readfile ❌", 92748403151276, Color3.fromRGB(181, 22, 22), false),
    isfile = tabs.compat:CreateLabel("isfile ❌", 128017212826076, Color3.fromRGB(181, 22, 22), false),
    isfolder = tabs.compat:CreateLabel("isfolder ❌", 92905712960709, Color3.fromRGB(181, 22, 22), false),
    makefolder = tabs.compat:CreateLabel("makefolder ❌", 101454576076611, Color3.fromRGB(181, 22, 22), false),
    getcustomasset = tabs.compat:CreateLabel("getcustomasset ❌", 126579187754144, Color3.fromRGB(181, 22, 22), false),
	fireclickdetector = tabs.compat:CreateLabel("fireclickdetector ❌", 96515126084643, Color3.fromRGB(181, 22, 22), false),
	fireproximityprompt = tabs.compat:CreateLabel("fireproximityprompt ❌", 112469890786414, Color3.fromRGB(181, 22, 22), false),
	firetouchinterest = tabs.compat:CreateLabel("firetouchinterest ❌", 132328148802096, Color3.fromRGB(181, 22, 22), false),
	isrbxactive = tabs.compat:CreateLabel("isrbxactive ❌", 85680753522526, Color3.fromRGB(181, 22, 22), false),
	mouse1click = tabs.compat:CreateLabel("mouse1click ❌", 94623743944390, Color3.fromRGB(181, 22, 22), false),
	gethui = tabs.compat:CreateLabel("gethui ❌", 116982978657227, Color3.fromRGB(181, 22, 22), false),
	setclipboard = tabs.compat:CreateLabel("setclipboard ❌", 71722033040150, Color3.fromRGB(181, 22, 22), false),
	identifyexecutor = tabs.compat:CreateLabel("identifyexecutor ❌", 89952680502221, Color3.fromRGB(181, 22, 22), false),
	request = tabs.compat:CreateLabel("request ❌", 120921933599329, Color3.fromRGB(181, 22, 22), false),
	setfpscap = tabs.compat:CreateLabel("setfpscap ❌", 134745017667004, Color3.fromRGB(181, 22, 22), false),
	getgenv = tabs.compat:CreateLabel("getgenv ❌", 81678527621535, Color3.fromRGB(181, 22, 22), false)
}


local requiredFunctions = {}

if getcustomasset then table.insert(requiredFunctions, "getcustomasset") end
if isfolder then table.insert(requiredFunctions, "isfolder") end
if makefolder then table.insert(requiredFunctions, "makefolder") end
if isfile then table.insert(requiredFunctions, "isfile") end
if readfile then table.insert(requiredFunctions, "readfile") end
if writefile then table.insert(requiredFunctions, "writefile") end
if fireclickdetector then table.insert(requiredFunctions, "fireclickdetector") end
if fireproximityprompt then table.insert(requiredFunctions, "fireproximityprompt") end
if firetouchinterest then table.insert(requiredFunctions, "firetouchinterest") end
if isrbxactive then table.insert(requiredFunctions, "isrbxactive") end
if mouse1click then table.insert(requiredFunctions, "mouse1click") end
if gethui then table.insert(requiredFunctions, "gethui") end
if setclipboard then table.insert(requiredFunctions, "setclipboard") end
if identifyexecutor then table.insert(requiredFunctions, "identifyexecutor") end
if request then table.insert(requiredFunctions, "request") end
if setfpscap then table.insert(requiredFunctions, "setfpscap") end
if getgenv then table.insert(requiredFunctions, "getgenv") end

-- Icons

tabs.compat:CreateDivider()

destroyWindow = tabs.compat:CreateButton({
    Name = "Close",
    Callback = function()
        rayfieldLib:Destroy()
    end,
})