local assetLib = {}

assetLib.updateFile = function(file, newContent)
    if not isfile(file) then
        warn("❌ | File '" .. file .. "' does not exist. Cannot update.")
        --customError("File does not exist.")
        return
    end

    writefile(file, newContent)
    --print("✅ | File '" .. file .. "' has been updated.")
end

assetLib.createFolder = function(name)
    if not isfolder(name) then
        --warn("❌ | No folder with the name 'Celestial ScriptHub' was found. Creating...")
        makefolder(name)
        repeat task.wait() until isfolder(name)
        print("✅ | Successfully created '" .. name .. "' folder.")
    end
end

assetLib.createFile = function(file, sourceContentOrURL, isTextContent)
    -- Folder check(s)

    if not isfolder("Celestial ScriptHub") then
        --warn("❌ | No folder with the name 'Celestial ScriptHub' was found. Creating...")
        makefolder("Celestial ScriptHub")
        repeat task.wait() until isfolder("Celestial ScriptHub")
        print("✅ | Successfully created 'Celestial ScriptHub' folder.")
    end

    -- Determine the new content based on the input type

    local newContent

    if isTextContent then
        newContent = sourceContentOrURL -- Treat the input as text content
    else
        newContent = game:HttpGet(sourceContentOrURL)
    end

    -- File existence check

    local resolvedFile = "Celestial ScriptHub/" .. file

    if not isfile(resolvedFile) then
        writefile(resolvedFile, newContent)
        --print("⏳ | Creating '" .. resolvedFile .. "'...")
        repeat task.wait() until isfile(resolvedFile)
        print("✅ | Successfully created '" .. resolvedFile .. "'")
    else
        -- Compare the file's content with the new content

        local currentContent = readfile(resolvedFile)

        if currentContent ~= newContent then
            print("⚠️ | Content mismatch detected for '" .. resolvedFile .. "'. Updating...")
            assetLib.updateFile(resolvedFile, newContent)
        else
            --print("✅ | The file '" .. resolvedFile .. "' is already up-to-date.")
        end
    end
end

assetLib.createAssets = function(assetType)
    local assets = {}

    local function checkAndAddAssets(assetList)
        for filePath, url in pairs(assetList) do
            assets[filePath] = url
        end
    end

    if assetType == "Icons" then
        checkAndAddAssets({
            ["Assets/Icons/Home.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Home.png?ref_type=heads",
            ["Assets/Icons/Player.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Player.png?ref_type=heads",
            ["Assets/Icons/Settings.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Settings.png?ref_type=heads",
            ["Assets/Icons/Miscellaneous.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Miscellaneous.png?ref_type=heads",
            ["Assets/Icons/Game Interface.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Game%20Interface.png?ref_type=heads",
            ["Assets/Icons/Exploit.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Exploit.png?ref_type=heads",
            ["Assets/Icons/Utility.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Utility.png?ref_type=heads",
            ["Assets/Icons/Endings.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Endings.png?ref_type=heads",
            ["Assets/Icons/World.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/World.png?ref_type=heads",
            ["Assets/Icons/Weapons.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Weapons.png?ref_type=heads",
            ["Assets/Icons/Visuals.png"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Visuals.png?ref_type=heads"
        })
    elseif assetType == "Sounds" then
        checkAndAddAssets({
            ["Assets/Sounds/Notification Main.mp3"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Notification%20Main.mp3?ref_type=heads",
            ["Assets/Sounds/Notification 2.mp3"] = "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Notification%202.mp3?ref_type=heads"
        })
    else
        return
    end

    for filePath, url in pairs(assets) do

        local resolvedFile = "Celestial ScriptHub/" .. filePath

        -- Make folders if needed

        local folderPath = resolvedFile:match("(.+)/[^/]+$")
        if folderPath and not isfolder(folderPath) then
            makefolder(folderPath)
        end

        -- Only download if file is missing

        if not isfile(resolvedFile) then

            local success, content = pcall(function()
                return game:HttpGet(url)
            end)

            if success and content then

                writefile(resolvedFile, content)
                print("✅ Created Asset: " .. resolvedFile)
            end
        end
    end
end

local function fetchTextAsset(fileName)
    local filePath = "Celestial ScriptHub/" .. fileName
    if not isfile(filePath) then
        warn("Text asset not found: " .. filePath)
        return nil
    end

    if string.match(fileName, "%.lua$") then
        return loadstring(readfile(filePath))() -- Execute lua script
    elseif string.match(fileName, "%.txt$") then
        return readfile(filePath) -- Return text file content
    end

    return nil
end

local soundCache = {}
assetLib.fetchAsset = function(fileName, mp3Volume)
    local fullPath = "Celestial ScriptHub/" .. fileName

    if not isfile(fullPath) then
        warn("Asset not found: '" .. fullPath .. "'.")
        return
    end

    if string.match(fileName, "%.mp3$") then
        -- Handle mp3 files

        if soundCache[fileName] then
            local cachedSound = soundCache[fileName]
            if not cachedSound:IsDescendantOf(gethui()) then
                cachedSound.Parent = gethui()
            end
            cachedSound:Play()
            return
        end

        local resolvedFile = getcustomasset(fullPath)
        local newMp3Sound = Instance.new("Sound", gethui())
        newMp3Sound.SoundId = resolvedFile
        newMp3Sound.Name = "_CelestialNotif"
        newMp3Sound.Looped = false
        newMp3Sound.Volume = mp3Volume or 1
        newMp3Sound.PlayOnRemove = true

        soundCache[fileName] = newMp3Sound
        newMp3Sound:Play()
        soundCache[fileName] = nil
        newMp3Sound:Destroy()

    else
        -- Handle txt or lua files separately

        return fetchTextAsset(fileName) or getcustomasset(fullPath)
    end
end

--assetLib.createFile("Celestial ScriptHub/Supported Exploits.lua", "https://gitlab.com/scripts1463602/Celestial/-/raw/main/Supported%20Exploits.json?ref_type=heads", false)

return assetLib