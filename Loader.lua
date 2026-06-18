local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local Quartz = loadstring(game:HttpGetAsync("https://github.com/notpoiu/Quartz/releases/latest/download/Quartz.luau"))()
local assetLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/corradedied/Public-Scripts/refs/heads/main/Libraries/Asset%20Library.lua"))()
local localplayer = game:GetService("Players").LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")

local Loading = Library:CreateLoading({
    Title = "Celestial",
    Icon = 102252277968437,
    TotalSteps = 3
})

Loading:ShowSidebarPage(true)
Loading.Sidebar:AddLabel("User: " .. localplayer.Name .. "\n\n")
Loading.Sidebar:AddLabel("Version: v1.0.0\n\n")

-- Step 0: Wait for game to load
Loading:SetMessage("Initializing...")
Loading:SetDescription("Waiting for game to load...")
repeat task.wait() until game:IsLoaded()

task.wait(0.2)

-- Step 1: Function validation via Quartz
Loading:SetCurrentStep(1)

local functionsToTest = {
    "loadfile", "makefolder", "getgc", "writefile", "queue_on_teleport", "fireproximityprompt",
    "delfile", "isfolder", "firetouchinterest", "isfunctionhooked", "readfile", "Drawing",
    "newcclosure", "gethui", "delfolder", "fireclickdetector", "isfile"
}

local manualChecks = {
    "getcustomasset", "HttpGet", "loadstring", "setclipboard", "identifyexecutor", "getgenv"
}

local function showErrorAndWait(message)
    Loading:ShowErrorPage(true)
    Loading:SetErrorMessage(message)

    local userChose = Instance.new("BindableEvent")

    Loading:SetErrorButtons({
        Retry = {
            Title = "Retry",
            Variant = "Primary",
            Order = 1,
            Callback = function()
                userChose:Fire("retry")
            end
        },
        Close = {
            Title = "Close",
            Variant = "Destructive",
            Order = 2,
            Callback = function()
                userChose:Fire("close")
            end
        }
    })

    local choice = userChose.Event:Wait()
    userChose:Destroy()
    return choice
end

local function runValidation()
    Loading:ShowErrorPage(false)
    Loading:SetCurrentStep(1)
    Loading:SetMessage("Verifying Compatibility")

    local Tester = Quartz.new({ Timeout = 5 })
    local failedFunctions = {}

    for _, funcName in functionsToTest do
        Loading:SetDescription("Validating function: " .. funcName)
        task.wait()

        local passed = Tester:Test(funcName)
        if not passed then
            table.insert(failedFunctions, funcName)
        end
    end

    for _, funcName in manualChecks do
        Loading:SetDescription("Validating function: " .. funcName)
        task.wait()

        local env = getfenv()
        if typeof(_G[funcName]) ~= "function" and typeof(env[funcName]) ~= "function" then
            table.insert(failedFunctions, funcName)
        end
    end

    if #failedFunctions > 0 then
        local choice = showErrorAndWait("Unsupported functions:\n" .. table.concat(failedFunctions, ", "))
        if choice == "retry" then
            return runValidation()
        else
            Loading:Destroy()
            return false
        end
    end

    return true
end

if not runValidation() then return end

-- Step 2: Assets
Loading:SetCurrentStep(2)
Loading:SetMessage("Verifying Files")

local assetFolders = {
    "Celestial ScriptHub",
    "Celestial ScriptHub/Icons",
    "Celestial ScriptHub/Sounds"
}

local assets = {
    ["Icons/swords.png"]            = "https://i.e-z.host/0jew61pq.png",
    ["Icons/bug.png"]               = "https://i.e-z.host/0lhdf90g.png",
    ["Icons/wrench.png"]            = "https://i.e-z.host/83n09jeg.png",
    ["Icons/eye.png"]               = "https://i.e-z.host/hi8fv5p2.png",
    ["Icons/info.png"]              = "https://i.e-z.host/aip85z9v.png",
    ["Icons/circle-ellipsis.png"]   = "https://i.e-z.host/9kurdyib.png",
    ["Icons/settings.png"]          = "https://i.e-z.host/jjjf7zlh.png",
    ["Icons/globe.png"]             = "https://i.e-z.host/nk3myn7k.png",
    ["Icons/circle-user-round.png"] = "https://i.e-z.host/mb3ax783.png",
    ["Sounds/success.mp3"]          = "https://i.e-z.host/d0f9729n.mp3",
    ["plans.txt"]                   = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Plans.txt"
}

local function getExtension(path)
    return path:match("%.([^%.]+)$"):lower()
end

local function isValidContent(fileName, content)
    local ext = getExtension(fileName)

    if content == nil or #content == 0 then
        return false, "empty response"
    end

    -- Check for HTML error pages
    local start = content:sub(1, 15):lower()
    if start:find("<!doctype") or start:find("<html") then
        return false, "server returned an error page"
    end

    if ext == "mp3" then
        local b1 = content:sub(1, 1)
        local b2 = content:sub(2, 2)
        local isID3 = content:sub(1, 3) == "ID3"
        local isMPEG = b1 == "\xFF" and bit32.band(string.byte(b2), 0xE0) == 0xE0
        local isOgg = content:sub(1, 4) == "OggS"
        if not isID3 and not isMPEG and not isOgg then
            return false, "invalid mp3 file"
        end
    end

    if ext == "png" then
        if content:sub(1, 4) ~= "\x89PNG" then
            return false, "invalid png file"
        end
    end

    return true
end

local function runAssets()
    Loading:ShowErrorPage(false)
    Loading:SetCurrentStep(2)
    Loading:SetMessage("Verifying Files")

    for _, folder in assetFolders do
        assetLib.createFolder(folder)
    end

    -- Delete invalid files FIRST so they get caught as missing below
    for file in assets do
        local resolvedFile = "Celestial ScriptHub/" .. file
        if isfile(resolvedFile) then
            local content = readfile(resolvedFile)
            local valid, _ = isValidContent(file, content)
            if not valid then
                delfile(resolvedFile)
            end
        end
    end

    -- Validation pass: now correctly catches freshly deleted invalid files
    local missingAssets = {}

    for file, source in assets do
        local assetName = file:match("[^/]+$")
        Loading:SetDescription("Validating asset: " .. assetName .. "...")
        task.wait()

        if not isfile("Celestial ScriptHub/" .. file) then
            missingAssets[file] = source
        end
    end

    local failedAssets = {}

    if next(missingAssets) then
        for file, source in missingAssets do
            local assetName = file:match("[^/]+$")
            Loading:SetDescription("Creating asset: " .. assetName .. "...")

            local ok, content = pcall(game.HttpGet, game, source)
            if not ok then
                table.insert(failedAssets, assetName .. " (request failed)")
                continue
            end

            local valid, reason = isValidContent(file, content)
            if not valid then
                table.insert(failedAssets, assetName .. " (" .. reason .. ")")
                continue
            end

            local writeOk, writeErr = pcall(assetLib.createFile, file, content, true)
            if not writeOk then
                table.insert(failedAssets, assetName .. " (write failed: " .. tostring(writeErr) .. ")")
            end
        end
    end

    if #failedAssets > 0 then
        local choice = showErrorAndWait("Failed to download assets:\n" .. table.concat(failedAssets, "\n"))
        if choice == "retry" then
            return runAssets()
        else
            Loading:Destroy()
            return false
        end
    end

    return true
end

if not runAssets() then return end

Loading:SetDescription("All assets ready!")
task.wait(0.2)

-- Step 3: Authentication
Loading:SetMessage("Authenticating...")
local auth = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Authentication.lua"))()

Loading:SetDescription("Validating whitelist...")
repeat task.wait() until auth
Loading:SetDescription("Validating user...")

local user = auth.getUser()
if not user then
    localplayer:Kick("how the hell did you not get kicked from the auth?? how the fuck did you encounter the not user check?? your hooks and circumvention methods win. this time.")
    return
else
    Loading.Sidebar:AddLabel("Identifier: " .. user.Identifier)
    Loading.Sidebar:AddLabel("Rank: " .. user.Rank)
end
Loading:SetDescription("Welcome, " .. user.Identifier)
task.wait(1)

Loading:SetCurrentStep(3)
Loading:SetMessage("Finalizing Setup")
Loading:SetDescription("Fetching script..")

local ok, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)

local gameName = ok and info.Name or "Unknown Game"
local games = {
    [123974602339071] = "Celestial/test 1.lua",
    [155382109] = "Celestial/test 2.lua"
}

local scriptPath = games[game.PlaceId]
if scriptPath then
    Loading:SetDescription("Starting " .. gameName .. " script...")
    loadstring(readfile(scriptPath))()
else
    warn("No Celestial script registered for this place (" .. game.PlaceId .. ")")
end

task.wait(0.3)
Loading:Continue()