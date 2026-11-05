--[[
    CELESTIAL SCRIPTHUB | SAKTKIA51 - CLASSIC MODE

    TABLE OF CONTENTS
    01. Bootstrap and external dependencies
    02. Services, shared constants, and visual defaults
    03. Shared runtime state
    04. Window configuration
    05. Tab registration
    06. Shared helpers
    07. Home: player, game, and whitelist panels
    08. Utility: teleport, healing, sounds, and interactions
    09. Player: movement, speed handling, freecam, and backtrack
    10. Exploits: Pack-a-Punch, aim controls, collection, and killer controls
    11. Visuals: ESP, FOV, fog, anti-effect handlers, scope overlay removal, and grenade trajectory preview
    12. World: environmental settings and alien / kill-part controls
    13. Weapons: inventory, Pack-a-Punch queue, defense, gun options, and skin changer
    14. Miscellaneous: utility actions and weapon spam
    15. UI settings, Session Info overlay, teardown, and configuration persistence

    MAINTENANCE NOTES
    - Keep feature controls near the callbacks that handle them.
    - Execution order matters: callbacks share locals declared in earlier sections.
    - When adding a toggle, also review unloadModules() and relevant respawn hooks.
]]
-- 01 | BOOTSTRAP AND DEPENDENCIES
while not game:IsLoaded() do
    task.wait()
end

local utils: any = assert(loadstring(readfile("Celestial/Libraries/Core Utilities.luau")))()
local entityLib: any = assert(loadstring(readfile("Celestial/Libraries/Entity Library.luau")))()
local camLib: any = assert(loadstring(readfile("Celestial/Libraries/Camera Library.luau")))()
local assetLib: any = assert(loadstring(readfile("Celestial/Libraries/Asset Library.luau")))()

local library: any = assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/corradedied/Obsidian/refs/heads/full/Library.lua")))()
local themeManager: any = assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/corradedied/Obsidian/refs/heads/full/addons/ThemeManager.lua")))()
local saveManager: any = assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/corradedied/Obsidian/refs/heads/full/addons/SaveManager.lua")))()

local options: any = library.Options
local toggles: any = library.Toggles

library.ForceCheckbox = false
library.ShowToggleFrameInKeybinds = true
library.NotifyOnError = true

-- 02 | SERVICES, SHARED CONSTANTS, AND VISUAL DEFAULTS
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local uis = game:GetService("UserInputService")
local killersFolder = game.Workspace:FindFirstChild("Killers")
local area51 = game:GetService("Workspace").AREA51
local camera = game:GetService("Workspace").CurrentCamera

-- Default colors used when rainbow cycling is reset.
local defaults = {
    killerESPColor_ColorPicker = Color3.fromRGB(255, 0, 0),
    killerNameTagColor_ColorPicker = Color3.fromRGB(255, 255, 255),
    silentAimFOVColor_ColorPicker = Color3.fromRGB(0, 229, 255)
}

-- Names used by the target-exclusion dropdowns.
local killerNames = {
    "Alien", "Ao Oni", "Captain Zombie",
    "Chucky", "Eyeless Jack", "Fishface",
    "Freddy Krueger", "Ghostface", "Granny",
    "Jack Torrance", "Jane", "Jason", "Jeff",
    "Leatherface", "Michael Myers", "Pennywise",
    "Pinhead", "Rake", "Robot", "Slenderman",
    "Smile Dog", "Sonic.exe", "Tails Doll",
    "Wendigo", "Yeti", "Zombie", "Fuwatti",
    "Giant", "Evil Lawn Mower"
}

-- 03 | SHARED RUNTIME STATE

local cancelPAPQueue = false
local wasTeleporterBusy = false

local rainbowConnections = {}
-- Every rainbow color picker follows this ONE hue (advanced once per frame), so rainbow colors can never drift apart.
local rainbowState = { hue = 0, active = {} }

-- Callbacks executed once on unload, while library.Toggles / library.Options are still populated.
local teardownTasks = {}

-- 04 | WINDOW CONFIGURATION

local function getMode(): string
    if game.PlaceId == 2092166489 then
        return "Normal"
    elseif game.PlaceId == 5740483929 then
        return "Hard"
    elseif game.PlaceId == 3182083477 then
        return "Extreme"
    end
    return "Unknown"
end

-- Name the main menu uses to request the current Classic mode (used by Serverhop).
-- Asks the game itself first, then falls back to the PlaceId, then to Normal.
local function getModeRequestName(): string
    local ok, result = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("Utilities")):get_gamemode()
    end)

    if ok and (result == "Classic mode" or result == "Hard classic mode" or result == "Extreme classic mode") then
        return result
    end

    local mode = getMode()
    if mode == "Hard" then
        return "Hard classic mode"
    elseif mode == "Extreme" then
        return "Extreme classic mode"
    end

    return "Classic mode"
end

local window = library:CreateWindow({
    Title = "Celestial",
    Footer = "Survive and Kill the Killers in Area 51: " .. gameName .. " - " .. getMode(),
    Center = true,
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.RightControl,
    NotifySide = "Right",
    ShowCustomCursor = false,
    Icon = assetLib.fetchAsset("Icons/Celestial.png"),
    Resizable = true,
    MobileButtonsSide = "Left",

    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true,
        Slider = true,
        ColorPicker = true,
        Input = true,
        Button = true
    },

    NotifyPriority = {
        Urgent = 0,
        Normal = 1,
        Low = 2,
    },
})

window.autoResetRainbowColor = true
window.rainbowSpeed = 0.1
window.alertVolume = 1
window.notifSoundEnabled = true
window.keybindFrameEnabled = true

library.KeybindFrame.Visible = window.keybindFrameEnabled

-- 05 | TAB REGISTRATION

local tabs = {
    home = window:AddTab("Home", assetLib.fetchAsset("Icons/info.png")),
    utils = window:AddTab("Utility", assetLib.fetchAsset("Icons/wrench.png")),
    player = window:AddTab("Player", assetLib.fetchAsset("Icons/circle-user-round.png")),
    exploits = window:AddTab("Exploits", assetLib.fetchAsset("Icons/bug.png")),
    visuals = window:AddTab("Visuals", assetLib.fetchAsset("Icons/eye.png")),
    world = window:AddTab("World", assetLib.fetchAsset("Icons/globe.png")),
    weapons = window:AddTab("Weapons", assetLib.fetchAsset("Icons/swords.png")),
    misc = window:AddTab("Miscellaneous", assetLib.fetchAsset("Icons/circle-ellipsis.png")),
    uiSettings = window:AddTab("UI Settings", assetLib.fetchAsset("Icons/settings.png")),
}

-- 06 | SHARED HELPERS

-- [Shared Helpers / Notifications] Volume and notification formatting
local function getAlertVolume()
    return window.notifSoundEnabled and (tonumber(window.alertVolume) or 3) or 0
end

local function notify(notificationType: string, title: string, desc: string, duration: number?, persist: boolean?)
    if typeof(title) ~= "string" then
        library:Notify("Error notifying", "Argument #1 (title) expected a string value but got a " .. typeof(title) .. " value.", 4590662766)
        return
    end

    if typeof(desc) ~= "string" then
        library:Notify("Error notifying", "Argument #1 (desc) expected a string value but got a " .. typeof(desc) .. " value.", 4590662766)
        return
    end

    if duration ~= nil and typeof(duration) ~= "number" then
        library:Notify("Error notifying", "Argument #2 (duration) expected a number value but got a " .. typeof(duration) .. " value.", 4590662766)
        return
    end

    duration = duration or 5

    local notification = nil

    if notificationType == "Success" then
        notification = library:Notify({
            Title = title,
            TitleColor = Color3.fromRGB(21, 140, 49),
            Description = desc,
            Time = duration,
            Persist = persist == true,
            Priority = 1,
            SoundId = 4590662766,
            Volume = getAlertVolume(),
            BigIcon = assetLib.fetchAsset("Icons/circle-check.png"),
            IconColor = Color3.fromRGB(21, 140, 49),
            Closable = true,
        })
    elseif notificationType == "Error" then
        notification = library:Notify({
            Title = title,
            TitleColor = Color3.fromRGB(140, 21, 21),

            Description = desc,
            Time = duration,
            Persist = persist == true,
            Priority = 0,
            SoundId = 4590662766,
            Volume = getAlertVolume(),
            Closable = true,
        })
    elseif notificationType == "Info" then
        notification = library:Notify({
            Title = title,
            Description = desc,
            Time = duration,
            Persist = persist == true,
            Priority = 2,
            SoundId = 4590662766,
            Volume = getAlertVolume(),
            BigIcon = assetLib.fetchAsset("Icons/info.png"),
            Closable = true,
        })
    end

    return notification
end

-- [Shared Helpers / Pack-a-Punch Notifications] Persistent progress notifications that are dismissed once their step is done
utils.papNotify = function(notificationType, title, desc)
    return notify(notificationType, title, desc, 5, true)
end

utils.dismissNotify = function(notification)
    if typeof(notification) == "table" and not notification.Destroyed then
        pcall(function() notification:Destroy("dismissed") end)
    end
end

-- The queue notification stays up until the next queue update replaces it, or the queue is empty/cleared
utils.papQueueNote = nil

utils.setPAPQueueNote = function(title, desc)
    utils.dismissNotify(utils.papQueueNote)
    utils.papQueueNote = utils.papNotify("Info", title, desc)
end

utils.clearPAPQueueNote = function()
    utils.dismissNotify(utils.papQueueNote)
    utils.papQueueNote = nil
end


-- [Shared Helpers / Character State] Character part and alive-state accessors
local function getHRP()
    return entityLib.getCharInstance("HumanoidRootPart") or nil
end

local function getHumanoid()
    return entityLib.getCharInstance("Humanoid") or nil
end

local function isAlive()
    return entityLib.isAlive()
end

-- [Shared Helpers / Color Cycling] Rainbow picker lifecycle
local function toggleRainbow(enabled, colorPickerName)
    local active = rainbowState.active

    if enabled then
        if not options[colorPickerName] or not defaults[colorPickerName] then
            notify("Error", "Invalid object", "Invalid colorpicker object and/or no valid default was found.", 99999)
            return
        end

        active[colorPickerName] = true

        if not rainbowConnections.driver then
            rainbowConnections.driver = runService.RenderStepped:Connect(function(deltaTime)
                rainbowState.hue = (rainbowState.hue + deltaTime * window.rainbowSpeed) % 1
                local color = Color3.fromHSV(rainbowState.hue, 1, 1)

                for pickerName in pairs(rainbowState.active) do
                    local picker = options[pickerName]

                    if picker then
                        picker:SetValueRGB(color)
                    else
                        rainbowState.active[pickerName] = nil
                    end
                end
            end)
        end
    else
        active[colorPickerName] = nil

        -- Stop the shared driver once no picker is cycling anymore (the hue itself is kept for the next time).
        if next(active) == nil and rainbowConnections.driver then
            rainbowConnections.driver:Disconnect()
            rainbowConnections.driver = nil
        end

        if window.autoResetRainbowColor then
            if not options[colorPickerName] or not defaults[colorPickerName] then

                notify("Error", "Invalid object", "Invalid colorpicker object and/or no valid default was found.", 99999)
                return
            else
                options[colorPickerName]:SetValueRGB(defaults[colorPickerName])
            end
        end
    end
end

-- [Shared Helpers / Teleporter State] State checks
local function teleporterInUse()
    local displayLabel = area51.TeleporterRoom.Teleporter["Control Panels"].Middle.Displayer.SurfaceGui.Frame.TextLabel
    local teleportSmoke = area51.TeleporterRoom.Teleporter.Teleporter.Collision.Smoke

    if string.find(displayLabel.Text, "Teleporting") or teleportSmoke.Enabled then
        return true
    end

    return false
end

local function getTeleporterState()
    local door = area51.TeleporterRoom.Teleporter.Teleporter.Inside
    local teleportSmoke = area51.TeleporterRoom.Teleporter.Teleporter.Collision.Smoke
    local openY = 329.900665
    local closedY = 320.000061
    local tolerance = 0.1

    local currentY = door.CFrame.Position.Y

    if math.abs(currentY - openY) < tolerance then
        return "Open"
    elseif teleportSmoke.Enabled then
        return "Teleporting in Progress"
    elseif math.abs(currentY - closedY) < tolerance and not teleportSmoke.Enabled then
        return "Closed"
    else
        return "Moving"
    end
end

-- [Shared Helpers / Character Control] Save and restore movement values
local function freeze(enabled)
    local hum = getHumanoid()

    if enabled then
        entityLib.storeData(hum, "WalkSpeed", true)
        entityLib.storeData(hum, "JumpPower", true)

        hum.WalkSpeed = 0
        hum.JumpPower = 0
    else
        entityLib.restoreData(hum, "WalkSpeed")
        entityLib.restoreData(hum, "JumpPower")
    end
end

-- [Shared Helpers / Pack-a-Punch Teleporter]
utils.runPAPTeleport = function(weaponName, cancelCheck)
    local maxAttempts = 8
    local confirmTimeout = 2.5 -- seconds to wait for the teleporter to react to one prompt fire
    local busyTimeout = 120 -- seconds to wait for another player's teleport to finish
    local arrivalTimeout = 15 -- seconds to wait for arriving in the punch room once inside

    local standCFrame = CFrame.new(110.864708, 313.499969, 72.9767151)
    local insideCFrame = CFrame.new(111.216148, 315.700012, 41.9078827)
    local punchRoomCFrame = CFrame.new(109.300003, 335.499969, 62)

    local teleporterModel = area51.TeleporterRoom.Teleporter
    local promptPart = teleporterModel["Control Panels"].Middle.Teleport
    local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
    local faceName = "PAPFaceTeleportPrompt"

    -- One progress notification at a time: it stays up until the step it describes is done, then the next one replaces it
    local statusNote = nil

    local function clearStatus()
        utils.dismissNotify(statusNote)
        statusNote = nil
    end

    local function setStatus(title, desc)
        clearStatus()
        statusNote = utils.papNotify("Info", title, desc)
        return statusNote
    end

    -- Teleport to the prompt surface part and face toward it to prevent incorrect activation edge cases
    local facingStandCFrame = CFrame.lookAt(standCFrame.Position, Vector3.new(promptPart.Position.X, standCFrame.Position.Y, promptPart.Position.Z))

    local function stopped(ignoreCancel)
        if not ignoreCancel and cancelCheck and cancelCheck() then
            return "cancelled"
        end

        if not isAlive() then
            return "died"
        end

        return nil
    end

    local function blocked()
        return teleporterInUse() or (prompt ~= nil and not prompt.Enabled)
    end

    local function waitUntil(condition, timeout)
        local startedAt = os.clock()

        repeat
            if condition() then
                return true
            end

            task.wait(0.05)
        until os.clock() - startedAt >= timeout

        return condition()
    end

    -- Keep the camera pointed at the prompt so it counts as visible and can be triggered
    local function startFacing()
        pcall(function() runService:UnbindFromRenderStep(faceName) end)

        runService:BindToRenderStep(faceName, Enum.RenderPriority.Camera.Value + 1, function()
            local currentCamera = workspace.CurrentCamera

            if currentCamera then
                currentCamera.CFrame = CFrame.lookAt(currentCamera.CFrame.Position, promptPart.Position)
            end
        end)
    end

    local function stopFacing()
        pcall(function() runService:UnbindFromRenderStep(faceName) end)
    end

    local function activate()
        for attempt = 1, maxAttempts do
            local stopReason = stopped()
            if stopReason then
                return false, stopReason
            end

            -- Another player is using the teleporter: wait for it instead of firing into a locked prompt
            if blocked() then
                stopFacing()
                setStatus("Waiting..", "Teleporter in use. Waiting for it to be free to pack a punch the " .. weaponName .. "...")

                local freed = waitUntil(function()
                    return stopped() ~= nil or not blocked()
                end, busyTimeout)

                stopReason = stopped()
                if stopReason then
                    return false, stopReason
                end

                if not freed then
                    return false, "busy"
                end

                clearStatus()
                task.wait(0.3)
            end

            -- (Re)position facing the panel so the prompt is in range and on screen
            entityLib.teleport(facingStandCFrame)

            waitUntil(function()
                local root = getHRP()
                return root ~= nil and entityLib.checkCFrame(root, standCFrame, 5)
            end, 3)

            startFacing()
            task.wait(math.min(0.15 + 0.1 * (attempt - 1), 0.6))

            utils.fireProxPrompt(promptPart)

            if attempt >= 3 and prompt then
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait()
                    prompt:InputHoldEnd()
                end)
            end

            -- Keep the "Retrying.." notification up while retrying; otherwise show that the teleport is being started
            if attempt == 1 or statusNote == nil then
                setStatus("Working..", "Teleporting in progress...\nPack a punching the " .. weaponName .. "...")
            end

            -- Confirm teleport has started
            local started = waitUntil(function()
                return teleporterInUse() or stopped() ~= nil
            end, confirmTimeout)

            stopReason = stopped()
            if stopReason then
                return false, stopReason
            end

            if started then
                stopFacing()
                return true
            end

            if attempt < maxAttempts then
                setStatus("Retrying..", "The teleporter did not respond. Retrying (" .. attempt .. "/" .. (maxAttempts - 1) .. ")...")
                task.wait(math.min(0.25 * attempt, 1.5))
            end
        end

        return false, "retries"
    end

    local function enter()
        local inside = teleporterModel.Teleporter.Inside
        inside.CanCollide = false

        -- Teleport inside teleporter
        entityLib.teleport(insideCFrame)

        local startedAt = os.clock()
        local lastTeleport = os.clock()

        while true do
            local stopReason = stopped(true)
            if stopReason then
                return false, stopReason
            end

            local root = getHRP()

            if root and entityLib.checkCFrame(root, punchRoomCFrame, 5) then
                return true
            end

            if os.clock() - startedAt > arrivalTimeout then
                return false, "arrival"
            end

            -- Got pushed out of the teleporter while it is running: put the player back inside
            if root and teleporterInUse() and os.clock() - lastTeleport >= 1
                and (root.Position - insideCFrame.Position).Magnitude > 10 then
                lastTeleport = os.clock()
                entityLib.teleport(insideCFrame)
            end

            task.wait()
        end
    end

    local function run()
        for cycle = 1, 2 do
            local activated, activateReason = activate()
            if not activated then
                return false, activateReason
            end

            setStatus("Working..", "Correct teleport.\nPack a punching the " .. weaponName .. "...")

            local arrived, arrivalReason = enter()
            if arrived then
                -- Handed to the caller, which dismisses it once the weapon has been pack a punched
                return true, setStatus("Working..", "Teleport finished.\nPack a punching the " .. weaponName .. "...")
            end

            if arrivalReason ~= "arrival" or cycle == 2 then
                return false, arrivalReason
            end

            setStatus("Retrying..", "Did not reach the punch room. Restarting the teleport...")
        end

        return false, "arrival"
    end

    local ran, success, reason = pcall(run)
    stopFacing()

    if not ran or not success then
        clearStatus()
    end

    if not ran then
        warn("utils.runPAPTeleport: " .. tostring(success))
        return false, "error"
    end

    -- On success the second value is the "Teleport finished" notification, on failure it is the reason
    return success, reason
end

local function getSuffix(sliderObj, suffixString)
    if typeof(sliderObj) ~= "table" then
        notify("Error", "Invalid instance", "Argument #1 (sliderObj) did not return a table instance.", 1000)
        return
    end

    if typeof(suffixString) ~= "string" then
        notify("Error", "Invalid instance", "Argument #2 (suffixString) did not return a string value.", 1000)
        return
    end

    local val = sliderObj.Value
    return val == 1 and " " .. suffixString or " " .. suffixString .. "s"
end

-- [Shared Helpers / Navigation] Named destination handling
local function teleport(destination, hrp)
    local cframeValues = {
        ["Surface"] = CFrame.new(326.087067, 511.699921, 392.975769, 0.999967098, 0, 0.00810976978, 0, 1, 0, -0.00810976978, 0, 0.999967098),
        ["Area 51"] = CFrame.new(327.146332, 313.499908, 369.922913, 0.0146765877, 0, 0.999892294, 0, 1, 0, -0.999892294, 0, 0.0146765877),
        ["Teleportation Zone"] = CFrame.new(110.864708, 313.499969, 72.9767151, 0.999984086, -2.85284294e-08, -0.00564495847, 2.80977517e-08, 1, -7.6373631e-08, 0.00564495847, 7.62138015e-08, 0.999984086),
        ["Alien"] = CFrame.new(237.99556, 337.799927, 472.399994, 4.34290196e-05, 1.17440393e-07, -1, 3.82457843e-09, 1, 1.17440564e-07, 1, -3.8296788e-09, 4.34290196e-05),
        ["Keypad Room"] = CFrame.new(137.72377, 333.499939, 525.566956, -0.999551415, 4.71232431e-09, 0.0299497657, 4.37261027e-09, 1, -1.14082894e-08, -0.0299497657, -1.12722134e-08, -0.999551415),
        ["Armory #1"] = CFrame.new(-134, 313.499817, 280.700012, 1, 4.96563608e-08, -1.20892841e-15, -4.96563608e-08, 1, -5.78394499e-10, 1.18020743e-15, 5.78394499e-10, 1),
        ["Armory #2"] = CFrame.new(-167.243805, 293.500214, 316.368713, -0.0163577069, -1.04670743e-08, 0.999866188, 6.23807708e-08, 1, 1.14890186e-08, -0.999866188, 6.25603604e-08, -0.0163577069),
        ["Ammunition Room"] = CFrame.new(184.26889, 314.102753, 437.041473, -0.999995649, 5.072752e-09, 0.00294528855, 5.24779331e-09, 1, 5.94231793e-08, -0.00294528855, 5.94383778e-08, -0.999995649),
        ["Radioactive Zone"] = CFrame.new(140.615601, 313.499969, 435.841766, -0.9997648, 3.54234375e-09, 0.0216868054, 6.39699493e-09, 1, 1.31561421e-07, -0.0216868054, 1.31669211e-07, -0.9997648),
        ["Checkpoint Office"] = CFrame.new(-52.6837997, 313.500305, 292.096558, 1, 1.49757151e-09, -4.17306546e-05, -1.49720991e-09, 1, 8.6659675e-09, 4.17306546e-05, -8.66590533e-09, 1),
        ["UFO / Experimentation Room"] = CFrame.new(-9.31313705, 303.499725, 659.399963, 1, 2.64172648e-08, -8.89015791e-06, -2.64172684e-08, 1, -3.07409292e-10, 8.89015791e-06, 3.0764416e-10, 1),
        ["Jail"] = CFrame.new(97.5999985, 291.5, 241.300003, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Hatch"] = CFrame.new(60.5999985, 313.5, 527.799988, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Cafeteria Back Room"] = CFrame.new(376.116302, 333.499939, 615.305908, -0.0125078484, 0, 0.999921799, 0, 1, 0, -0.999921799, 0, -0.0125078484),
        ["Bunker"] = CFrame.new(165.600006, 239.699997, 428.299988, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Sub-Office Room"] = CFrame.new(-7, 293.499939, 291, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Computer Room"] = CFrame.new(-55.5999985, 292.499725, 736.599976, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Sewer"] = CFrame.new(62.4396858, 271.700226, 178.499451, 0.999994755, -6.60116868e-08, -0.00324202515, 6.62044073e-08, 1, 5.93380776e-08, 0.00324202515, -5.95524021e-08, 0.999994755),
        ["Cafe"] = CFrame.new(177.5, 333.399994, 600, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["Research Office"] = CFrame.new(-15.5787725, 303.499695, 339.084656, 1, -4.2062446e-08, 4.6596204e-14, 4.2062446e-08, 1, -3.00335863e-08, -4.53329153e-14, 3.00335863e-08, 1),
    }

    if not isAlive() then return end

    local cframeDestination = cframeValues[destination]

    if destination == "Pack A Punch Machine" then
        entityLib.teleport(game:GetService("Workspace").PACKAPUNCH.GUI)

        local papMachineCFrame = game:GetService("Workspace").PACKAPUNCH.GUI.CFrame

        if entityLib.checkCFrame(hrp, papMachineCFrame, 5) then
            notify("Success", "Successful teleport", "Successfully teleported to " .. destination .. ".", 6)
        else
            notify("Error", "Teleport failed", "Failed to teleport to " .. destination .. ".", 7)
        end

        return
    end

    entityLib.teleport(cframeDestination)

    if entityLib.checkCFrame(hrp, cframeDestination, 5) then
        notify("Success", "Successful teleport", "Successfully teleported to " .. destination .. ".", 6)
    else
        notify("Error", "Teleport failed", "Failed to teleport to " .. destination .. ".", 7)
    end
end

-- [Shared Helpers / Game State] Gamepass and killer-state queries
local function getEnergyDrinkState()
    return utils.fetchOwnership("Gamepass", 1182965)
end

local function isKillerAlive(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end




-- ============================================================================
-- 07 | TAB: HOME
-- ============================================================================

local infoTabBox = tabs.home:AddLeftTabbox()

-- [Home / Panels] Player, game, and optional whitelist tabs

local playerTab = infoTabBox:AddTab("Player")
local gameTab = infoTabBox:AddTab("Game")
if getgenv()._celestial_auth then
    local whitelistTab = infoTabBox:AddTab("Whitelist")

    local auth = getgenv()._celestial_auth
    local user = auth.getUser()
    whitelistTab:AddLabel("Identifier: " .. user.Identifier, true)
    whitelistTab:AddLabel("Rank: " .. user.Rank, true)
    whitelistTab:AddLabel("Discord ID: " .. user.DiscordId, true)
end

-- [Home / Player] Player status and actions

playerTab:AddImage("UserThumbnail", {
    Image = utils.fetchUserThumbnail("AvatarBust", "Size420x420"),
    Height = 200,

    BackgroundTransparency = 1,
})

local resolvedBeforeToggle = false

utils.fetchResetButtonState(function(isActive)
    resolvedBeforeToggle = true
    if toggles.respawnButton_Toggle then
        toggles.respawnButton_Toggle:SetValue(isActive)
    end
end)

local respawnButton_Toggle = playerTab:AddToggle("toggleRespawn_Toggle", {
    Text = "Respawn Button",
    Tooltip = false,
    Default = resolvedBeforeToggle or false
})
toggles.respawnButton_Toggle = respawnButton_Toggle

playerTab:AddLabel("Name: " .. localplayer.DisplayName .. " (@" .. localplayer.Name .. ")", true)
playerTab:AddLabel("UserId: " .. localplayer.UserId, true)
playerTab:AddLabel("Shift Lock Allowed: true", true)

respawnButton_Toggle:OnChanged(function(enabled)
    utils.setGuiEnabled("reset button", enabled)
end)

-- [Home / Game] Game information and session actions

gameTab:AddImage("GameIcon", { Image = utils.fetchGameImage("Icon"), Height = 200, BackgroundTransparency = 1 })

gameTab:AddLabel("Game Name: " .. gameName, true)
gameTab:AddLabel("Place ID: " .. game.PlaceId, true)
gameTab:AddLabel("Classic Mode: " .. getMode(), true)
gameTab:AddLabel("Creator ID: " .. game.CreatorId, true)
gameTab:AddLabel("Creator Type: " .. game.CreatorType.Name, true)

local serverJoinScript = [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId..", '" .. game.JobId.."')"
gameTab:AddButton({ Text = "Copy Server Join Script", DoubleClick = false,
    Func = function()
        setclipboard(serverJoinScript)
        notify("Success", "Copied", "The server join script has been copied to your clipboard.", 5)
    end,
})

gameTab:AddButton({
    Text = "Serverhop",
    Func = function()
        local reload
        window:AddDialog("reloadConfirmation_Dialog", {
            Title = "Reload",
            Description = "Would you like to reload the script when you join the new server?",
            AutoDismiss = false,
            OutsideClickDismiss = true,

            FooterButtons = {
                Cancel = {
                    Title = "No",
                    Variant = "Ghost",
                    Order = 1,

                    Callback = function(self)
                        reload = false
                    end
                },

                Confirm = {
                    Title = "Yes",
                    Variant = "Primary",
                    Order = 2,

                    Callback = function(self)
                        reload = true
                    end
                }
            }
        })

        -- Wait for the user to interact with the dialog
        repeat task.wait() until typeof(reload) == "boolean"


        local requestedMode = getModeRequestName()

        game:GetService("ReplicatedStorage")["Remote Events"].TeleportToMenu:FireServer()

        queue_on_teleport(string.format([[
            repeat task.wait() until game:IsLoaded()

            if %s then

                queue_on_teleport([=[
                    loadstring(readfile("Celestial/Supported Games/[!] SAKTKIA51 - Classic.luau"))()
                ]=])
            end

            game:GetService("ReplicatedStorage").TeleportEvents.TeleportRequested:FireServer("%s")
        ]], tostring(reload), requestedMode))
    end,
})

-- ============================================================================
-- 08 | TAB: UTILITY
-- ============================================================================

-- [Utility / Layout] Groupbox registration
local teleportGroup = tabs.utils:AddLeftGroupbox("Teleport")
local healingGroup = tabs.utils:AddRightGroupbox("Healing")
local soundsGroup = tabs.utils:AddLeftGroupbox("Sounds")
local otherGroup2 = tabs.utils:AddRightGroupbox("Other")

-- [Utility / Teleport] Location controls

teleportGroup:AddDropdown("locationsList_Dropdown", { Text = "Location", Tooltip = false, Values = {"Surface", "Area 51", "Teleportation Zone", "Alien", "Keypad Room",
"Armory #1", "Armory #2", "Pack A Punch Machine", "Ammunition Room", "Radioactive Zone", "Checkpoint Office", "UFO / Experimentation Room", "Jail", "Hatch",
"Cafeteria Back Room", "Bunker", "Sub-Office Room", "Computer Room", "Sewer", "Cafe", "Research Office" }, Default = 1 })
teleportGroup:AddButton({ Text = "Teleport", Func = function()
        if not isAlive() then return end
        local hrp = getHRP()

        local dropdown = options.locationsList_Dropdown
        teleport(dropdown.Value, hrp)
    end,
})

teleportGroup:AddButton({ Text = "Office Teleport", Tooltip = "Teleports you to an area where you can kill the killers through the glass.",
    Func = function()
        if not isAlive() then return end

        local hrp = getHRP()
        teleport("Checkpoint Office", hrp)
    end,
}):AddKeyPicker("office_KeyPicker", {
    Default = "V",
    Text = "Teleport to Office",
    Mode = "Press",
})

-- [Utility / Healing] Drink inventory, auto-drink, and refill controls

-- [Utility / Healing] Drink inventory lookup
local function getEnergyDrink(allowEmpty)
    if not getEnergyDrinkState() then
        return nil, "You do not own the gamepass."
    end

    local energyDrink = entityLib.getTool("Specific", "Energy")
    if not energyDrink then
        return nil, "Energy drink not found."
    end

    local ammo = energyDrink:FindFirstChild("Ammo")
    if not ammo then
        return nil, "Energy drink ammo counter not found."
    end

    if ammo.Value == 0 and not allowEmpty then
        return nil, "Energy drink has no more charges left."
    end

    return energyDrink
end

local function refillEnergyDrink()
    local energyDrink = getEnergyDrink(true)
    local hrp = getHRP()

    if not energyDrink or not hrp then
        return
    end

    local remainingCharges = energyDrink.Ammo.Value
    if remainingCharges ~= 0 then
        notify("Error", "Refill failed", "You still have " .. remainingCharges .. " charges left.", 6)
        return
    end

    entityLib.storeData(hrp, "CFrame", true)
    task.wait(0.01)

    entityLib.teleport(CFrame.new(178.023087, 333.499908, 597.890442, 0.0192538705, -8.12836092e-08, 0.99981463, 1.48566126e-09, 1, 8.12700662e-08, -0.99981463, -7.93774491e-11, 0.0192538705))
    task.wait(0.17)

    utils.fireProxPrompt(area51.CafeRoom["Coffee Machine"].Energy.Head)
    entityLib.restoreData(hrp, "CFrame")
    entityLib.clearData(hrp, "CFrame")
end

healingGroup:AddButton({ Text = "Drink Energy Drink", Disabled = not getEnergyDrinkState(), Func = function()
        local energyDrink, err = getEnergyDrink()
        local drinkAmount = options.energyDrinkAmount_Slider.Value

        if energyDrink then

            for _ = 1, drinkAmount do
                energyDrink.Drank:FireServer()
            end

        else

            notify("Error", "Error", err, 7)
        end
    end,
})

healingGroup:AddSlider("energyDrinkAmount_Slider", { Text = "Drink Amount", Tooltip = "How much to drink from the energy drink.", Default = 5, Min = 1, Max = 5, Rounding = 0, Disabled = not getEnergyDrinkState() })
healingGroup:AddButton({ Text = "Drink All", Disabled = not getEnergyDrinkState(), Func = function()
        local energyDrink, err = getEnergyDrink()

        if energyDrink then
            local remainingCharges = energyDrink.Ammo.Value

            for _ = 1, remainingCharges do
                energyDrink.Drank:FireServer()
            end

        else

            notify("Error", "Error", err, 7)
        end
    end,
})

healingGroup:AddButton({ Text = "Refill", Disabled = not getEnergyDrinkState(), Func = function()
        local energyDrink, err = getEnergyDrink(true)

        if not energyDrink then
            notify("Error", "Error", err, 7)
            return
        end

        refillEnergyDrink()
    end,
})

-----------------------
-- [Utility / Healing] Auto-drink thresholds and loop state
-----------------------

-- [Utility / Healing] Threshold calculation and background loops
local function getMaxThreshold()
    if utils.fetchOwnership("Gamepass", 1273854) then -- If the player owns the "Survivor pack" gamepass
        return 150
    else
        return 100
    end
end

local autoDrinkToggle
local autoDrinkThresholdSlider
local autoRefillToggle
local drinkLoopRunning = false
local autoRefillLoopRunning = false

local function startAutoDrinkLoop()
    if drinkLoopRunning or not autoDrinkToggle.Value then return end
    drinkLoopRunning = true

    task.spawn(function()
        while autoDrinkToggle.Value do
            local humanoid = getHumanoid()

            if humanoid and humanoid.Health <= autoDrinkThresholdSlider.Value then
                local energyDrink, err = getEnergyDrink()

                if err and err ~= "Energy drink has no more charges left." then
                    notify("Error", "Error", err, 10)
                    drinkLoopRunning = false
                    return
                end

                if energyDrink then
                    local drankEvent = energyDrink:FindFirstChild("Drank")

                    if drankEvent then
                        for _ = 1, 5 do
                            drankEvent:FireServer()
                            task.wait(0.1)
                        end
                    end
                end
            end

            task.wait(0.2)
        end

        drinkLoopRunning = false
    end)
end

local function startAutoRefillLoop()
    if autoRefillLoopRunning or not autoRefillToggle.Value then return end
    autoRefillLoopRunning = true

    task.spawn(function()
        local wasOutOfAmmo = false

        local lastErrorMessage = nil

        while true do
            if not autoRefillToggle.Value then break end

            local energyDrink, err = getEnergyDrink(true)

            if energyDrink and energyDrink:FindFirstChild("Ammo") then
                local ammoValue = energyDrink.Ammo.Value

                if ammoValue == 0 and not wasOutOfAmmo then
                    refillEnergyDrink()
                    wasOutOfAmmo = true
                elseif ammoValue > 0 then
                    wasOutOfAmmo = false
                end

                lastErrorMessage = nil
            elseif err then
                if not autoRefillToggle.Value then break end

                if err ~= lastErrorMessage then
                    notify("Error", "Error", err, 10)
                    lastErrorMessage = err
                end
            end

            task.wait(0.5)
        end

        autoRefillLoopRunning = false
    end)
end

-- [Utility / Healing] Auto-drink and auto-refill controls

autoDrinkToggle = healingGroup:AddToggle("autoDrink_Toggle", { Text = "Auto Drink", Tooltip = "Drinks the entire energy drink when you are below the threshold.", Default = false, Disabled = not getEnergyDrinkState() })

-- [Utility / Healing] Toggle controls and dependency wiring
local autoDrinkDepbox = healingGroup:AddDependencyBox()
autoDrinkThresholdSlider = autoDrinkDepbox:AddSlider("autoDrinkThreshold_Slider", { Text = "Threshold", Tooltip = false, Default = 40, Min = 10, Max = getMaxThreshold(), Rounding = 0 })

autoDrinkDepbox:SetupDependencies({ { toggles.autoDrink_Toggle, true } })

autoRefillToggle = healingGroup:AddToggle("autoRefill_Toggle", { Text = "Auto Refill", Tooltip = "Refills your energy drink when it has no more charges left.", Default = false, Disabled = not getEnergyDrinkState() })

toggles.autoDrink_Toggle:OnChanged(function(enabled)
    if enabled then
        startAutoDrinkLoop()
    else
        drinkLoopRunning = false
    end
end)

toggles.autoRefill_Toggle:OnChanged(function(enabled)
    if enabled then
        startAutoRefillLoop()
    else
        autoRefillLoopRunning = false
    end
end)

-- [Utility / Healing] Respawn and auto-restart handling

localplayer.CharacterAdded:Connect(function()
    drinkLoopRunning = false
    task.wait(1)

    if autoDrinkToggle.Value then
        startAutoDrinkLoop()
    end
end)

-----------------------------
-- [Utility / Healing] End of the auto-drink control block
-----------------------------

-- [Utility / Sounds] Sound toggles and loop management

local disabledSounds: {[string]: boolean} = {
    Lightning = false,
    Thunder = false,
    Music = false
}

local runningLoops: {[string]: boolean} = {}

-- [Utility / Sounds] Reusable sound-loop controller
local function updateSoundLoop(soundName, isEnabled)
    if isEnabled and not runningLoops[soundName] then
        runningLoops[soundName] = true

        task.spawn(function()
            while not library.Unloaded and disabledSounds[soundName] do
                local soundInstance: Instance? = nil

                if soundName == "Lightning" then
                    soundInstance = game.Workspace:FindFirstChild("LightningSound")
                elseif soundName == "Thunder" then
                    soundInstance = game.Workspace:FindFirstChild("ThunderSound")
                elseif soundName == "Music" then
                    soundInstance = game.Workspace:FindFirstChild("Music")
                end

                if soundInstance and soundInstance:IsA("Sound") then
                    local sound = soundInstance :: Sound
                    sound:Stop()
                    sound.Playing = false
                end

                task.wait(0.1)
            end

            runningLoops[soundName] = nil
        end)

    end
end

soundsGroup:AddDropdown("disabledSoundsList_Dropdown", { Text = "Disabled Ambience", Tooltip = false, Values = { "Lightning", "Thunder", "Music" }, Default = 0, Multi = true,
    Callback = function(valueTable)
        for option in pairs(disabledSounds) do
            local newState = valueTable[option] or false

            if disabledSounds[option] ~= newState then
                disabledSounds[option] = newState
                updateSoundLoop(option, newState)
            end
        end
    end,
})

soundsGroup:AddButton({ Text = "Disable All Ambience",
    Func = function()
        options.disabledSoundsList_Dropdown:SetValue({
            Lightning = true,
            Thunder = true,
            Music = true
        })
    end,
})

-- [Utility / Interactions] Prompt reach and door interaction helpers

otherGroup2:AddToggle("promptReach_Toggle", { Text = "Prompt Reach", Tooltip = false, Default = false })
otherGroup2:AddToggle("weaponPromptReach_Toggle", { Text = "Weapon Prompt Reach", Tooltip = false, Default = false })
otherGroup2:AddToggle("instantInteract_Toggle", { Text = "Instant Interact", Tooltip = false, Default = false })
otherGroup2:AddToggle("autoOpenDoors_Toggle", { Text = "Auto Open Doors", Tooltip = "Automatically opens all nearby doors.", Default = false })
otherGroup2:AddToggle("autoCloseDoors_Toggle", { Text = "Auto Close Doors", Tooltip = "Automatically closes all nearby doors.", Default = false })

toggles.promptReach_Toggle:OnChanged(function(enabled)
    for _, obj in ipairs(game:GetService("Workspace").Doors:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if enabled then
                entityLib.storeData(obj, "MaxActivationDistance", true)
                obj.MaxActivationDistance = 32
            else
                entityLib.restoreData(obj, "MaxActivationDistance")
            end
        end
    end
end)

toggles.weaponPromptReach_Toggle:OnChanged(function(enabled)
    for _, obj in ipairs(game:GetService("Workspace").Weapons:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if enabled then
                entityLib.storeData(obj, "MaxActivationDistance", true)
                obj.MaxActivationDistance = 20
            else
                entityLib.restoreData(obj, "MaxActivationDistance")
            end
        end
    end
end)

toggles.instantInteract_Toggle:OnChanged(function(enabled)
    for _, obj in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if enabled then
                entityLib.storeData(obj, "HoldDuration", true)
                obj.HoldDuration = 0
            else
                entityLib.restoreData(obj, "HoldDuration")
            end
        end
    end
end)

local doorLoopRunning = false
-- [Utility / Interactions] Door-prompt cache and refresh loop
local doorPromptCache = {}
local lastCacheUpdate = 0

local function updateDoorCache()
    table.clear(doorPromptCache)
    for _, obj in ipairs(workspace.Doors:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Parent:IsA("BasePart") then
            local name = obj.Parent.Name
            if name == "Open" or name == "Close" then
                table.insert(doorPromptCache, obj)
            end
        end
    end
end

local function doorLoopWanted()
    return toggles.autoOpenDoors_Toggle.Value or toggles.autoCloseDoors_Toggle.Value
end

local function doorLoopStep()
    local hrp = getHRP()
    if not hrp then return end

    -- Update cache every 5 seconds
    if os.clock() - lastCacheUpdate > 5 then
        updateDoorCache()
        lastCacheUpdate = os.clock()
    end

    for _, prompt in ipairs(doorPromptCache) do
        if prompt.Parent and prompt.Enabled then
            local promptName = prompt.Parent.Name
            if (promptName == "Open" and toggles.autoOpenDoors_Toggle.Value)
            or (promptName == "Close" and toggles.autoCloseDoors_Toggle.Value) then

                local dist = entityLib.getEntityDistance(hrp, prompt.Parent)
                local maxDist = prompt.MaxActivationDistance or 10

                if dist <= maxDist then
                    utils.fireProxPrompt(prompt.Parent)
                    task.wait(0.02)
                end
            end
        end
    end
end

-- A boolean flag guards the loop: an outdated thread could block the loop from ever starting again.
local function updateDoorLoop()
    if doorLoopRunning or not doorLoopWanted() then return end
    doorLoopRunning = true

    task.spawn(function()
        while doorLoopWanted() do
            local ok, err = pcall(doorLoopStep)
            if not ok then
                warn("[Auto Doors] " .. tostring(err))
            end
            task.wait(0.15)
        end

        doorLoopRunning = false
    end)
end

toggles.autoOpenDoors_Toggle:OnChanged(updateDoorLoop)
toggles.autoCloseDoors_Toggle:OnChanged(updateDoorLoop)

-- ============================================================================
-- 09 | TAB: PLAYER
-- ============================================================================

-- [Player / Layout] Groupbox registration
local movementGroup = tabs.player:AddLeftGroupbox("Movement")
local othersGroup3 = tabs.player:AddRightGroupbox("Other")

tabs.player:UpdateWarningBox({ Title = "Warning", Text = "Due to Roblox's physics limitations, high velocity speeds may cause unexpected falling on collisions.\n\nFly is NOT compatible when Speed Exploit's mode is set as Velocity and will be swapped.",
Visible = true })

-- [Player / Movement] Speed, fly, noclip, and jump settings

-- [Player / Speed Exploit] Controls

movementGroup:AddToggle("speedExploit_Toggle", { Text = "Speed Exploit", Tooltip = false, Default = false })

local speedExploitDepbox = movementGroup:AddDependencyBox()

speedExploitDepbox:AddDropdown("speedExploitMethod_Dropdown", { Text = "Method", Tooltip = false, Values = { "WalkSpeed", "Velocity" }, Default = 1 })
speedExploitDepbox:AddSlider("speedExploitAmount_Slider", { Text = "Amount", Tooltip = false, Default = 20, Min = 16, Max = 100, Rounding = 0 })
speedExploitDepbox:AddDivider()

-- [Player / Fly] Controls and input handling

movementGroup:AddToggle("enableFly_Toggle", { Text = "Enable Fly" })

local flyDepbox = movementGroup:AddDependencyBox()
flyDepbox:AddToggle("toggleFly_Toggle", { Text = "Fly" })
:AddKeyPicker("fly_KeyPicker", { Text = "Fly", Default = "F", SyncToggleState = true, Mode = "Toggle", NoUI = true, Disabled = true })
local flyHorizSpeed_Slider = flyDepbox:AddSlider("flyHorizSpeed_Slider", { Text = "Horizontal Speed", Tooltip = "The speed you normally go at.", Default = 100, Min = 30, Max = 1000, Rounding = 0 })
local flyVertSpeed_Slider = flyDepbox:AddSlider("flyVertSpeed_Slider", { Text = "Vertical Speed", Tooltip = "The speed you go when ascending/descending.", Default = 100, Min = 30, Max = 300, Rounding = 0 })
flyDepbox:AddDivider()

-- [Player / Noclip] Controls

movementGroup:AddToggle("enableNoclip_Toggle", { Text = "Enable Noclip" })

local noclipDepbox = movementGroup:AddDependencyBox()
noclipDepbox:AddToggle("toggleNoclip_Toggle", { Text = "Noclip" })
:AddKeyPicker("noclip_KeyPicker", { Text = "Noclip", Default = "G", SyncToggleState = true, Mode = "Toggle", NoUI = true, Disabled = true })
noclipDepbox:AddDivider()

-- [Player / Jump Power] Controls

movementGroup:AddToggle("enableJumpPower_Toggle", { Text = "Enable JumpPower" })

local jumpPowerDepbox = movementGroup:AddDependencyBox()

jumpPowerDepbox:AddSlider("jumpPowerValue_Slider", { Text = "Value", Tooltip = false, Default = 50, Min = 50, Max = 200, Rounding = 0 })

speedExploitDepbox:SetupDependencies({ { toggles.speedExploit_Toggle, true } })
flyDepbox:SetupDependencies({ { toggles.enableFly_Toggle, true } })
noclipDepbox:SetupDependencies({ { toggles.enableNoclip_Toggle, true } })
jumpPowerDepbox:SetupDependencies({ { toggles.enableJumpPower_Toggle, true } })

toggles.enableJumpPower_Toggle:OnChanged(function(enabled)
    if enabled then
        local hum = getHumanoid()
        entityLib.storeData(hum, "JumpPower", true)

        entityLib.modifyPlayer("JumpPower", options.jumpPowerValue_Slider.Value)
    else
        local hum = getHumanoid()
        entityLib.restoreData(hum, "JumpPower")
    end
end)

options.jumpPowerValue_Slider:OnChanged(function(val)
    local jumpPowerEnabled = toggles.enableJumpPower_Toggle.Value

    if jumpPowerEnabled then
        entityLib.modifyPlayer("JumpPower", val)
    end
end)

localplayer.CharacterAdded:Connect(function(char)
    if toggles.enableJumpPower_Toggle.Value then
        entityLib.modifyPlayer("JumpPower", options.jumpPowerValue_Slider.Value)
    end
end)

toggles.enableFly_Toggle:OnChanged(function(enabled)
    local keypicker = options.fly_KeyPicker
    keypicker:SetDisabled(not enabled)
    keypicker:SetNoUI(not enabled)

    if not enabled then
        toggles.toggleFly_Toggle:SetValue(false)
    end
end)

toggles.toggleFly_Toggle:OnChanged(function(flyToggleEnabled)
    if flyToggleEnabled then
        if toggles.speedExploit_Toggle.Value == true and options.speedExploitMethod_Dropdown.Value == "Velocity" then
            options.speedExploitMethod_Dropdown:SetValue("WalkSpeed")
            options.speedExploitAmount_Slider:SetValue(options.speedExploitAmount_Slider.Max)

            notify("Error", "Incompatible", "Fly is incompatible with Velocity. Speed Exploit has been updated to WalkSpeed.", 10)
        end
    end

    entityLib.toggleFly(flyToggleEnabled)
    entityLib.setFlySpeed(flyHorizSpeed_Slider.Value, flyVertSpeed_Slider.Value)
end)

options.flyHorizSpeed_Slider:OnChanged(function()
    entityLib.setFlySpeed(flyHorizSpeed_Slider.Value, flyVertSpeed_Slider.Value)
end)

options.flyVertSpeed_Slider:OnChanged(function()
    entityLib.setFlySpeed(flyHorizSpeed_Slider.Value, flyVertSpeed_Slider.Value)
end)

toggles.enableNoclip_Toggle:OnChanged(function(enabled)
    local keypicker = options.noclip_KeyPicker
    keypicker:SetDisabled(not enabled)
    keypicker:SetNoUI(not enabled)

    if not enabled then
        toggles.toggleNoclip_Toggle:SetValue(false)
    end
end)

-- [Player / Noclip] Replacement for entityLib.toggleNoclip that survives death
do
    local noclip = {
        Enabled = false,
        Connection = nil,
        Original = setmetatable({}, { __mode = "k" }), -- part -> CanCollide before noclip first touched it
    }

    function noclip.step()
        local character = localplayer.Character

        if not character then
            return
        end

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if noclip.Original[part] == nil then
                    noclip.Original[part] = part.CanCollide
                end

                if part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end

    function noclip.set(enabled)
        local wasEnabled = noclip.Enabled

        noclip.Enabled = enabled and true or false

        if noclip.Connection then
            noclip.Connection:Disconnect()
            noclip.Connection = nil
        end

        if enabled then
            noclip.step()
            noclip.Connection = runService.Stepped:Connect(noclip.step)

            return
        end

        if not wasEnabled then
            return
        end

        local character = localplayer.Character

        for part, original in pairs(noclip.Original) do
            if character and part.Parent and part:IsDescendantOf(character) then
                part.CanCollide = original
            end
        end

        table.clear(noclip.Original)

        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    entityLib.toggleNoclip = noclip.set

    table.insert(teardownTasks, function()
        noclip.set(false)
    end)
end

toggles.toggleNoclip_Toggle:OnChanged(function(noclipToggleEnabled)
    local noclipAllowed = toggles.enableNoclip_Toggle.Value

    if noclipToggleEnabled and not noclipAllowed then
        toggles.toggleNoclip_Toggle:SetValue(false)
        return
    end

    if noclipAllowed then
        entityLib.toggleNoclip(noclipToggleEnabled)
    else
        entityLib.toggleNoclip(false)
    end
end)

-- [Player / Speed Exploit] Initial configuration and runtime updates

local method = options.speedExploitMethod_Dropdown.Value
local slider = options.speedExploitAmount_Slider
slider:SetMin(1)

if method == "WalkSpeed" then
    slider:SetMax(20)
else
    slider:SetMax(100)
end

local humanoid: Humanoid? = nil
local rootPart: BasePart? = nil
local bodyVelocity: BodyVelocity? = nil
local velocityConnection: RBXScriptConnection? = nil

-- [Player / Speed Exploit] Character and velocity helpers

local function getCharacterParts()
    local character = localplayer.Character or localplayer.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
    rootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
end

local function enableVelocityMode(speed)
    if not rootPart then
        return
    end
    if bodyVelocity then bodyVelocity:Destroy() end

    local newBodyVelocity = Instance.new("BodyVelocity")
    newBodyVelocity.Name = "SpeedExploitVelocity"
    newBodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
    newBodyVelocity.Velocity = Vector3.zero
    newBodyVelocity.Parent = rootPart
    bodyVelocity = newBodyVelocity

    if velocityConnection then velocityConnection:Disconnect() end

    velocityConnection = runService.RenderStepped:Connect(function()
        local currentHumanoid = humanoid
        local currentBodyVelocity = bodyVelocity
        if not currentHumanoid or not currentBodyVelocity then
            return
        end

        local moveDir = currentHumanoid.MoveDirection
        currentBodyVelocity.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * speed or Vector3.zero
    end)
end

local function disableVelocityMode()
    if velocityConnection then
        velocityConnection:Disconnect()
        velocityConnection = nil
    end

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
end

local function applySpeed()
    if not humanoid or not rootPart then
        getCharacterParts()
    end
    if not humanoid or not rootPart then
        return
    end

    if not toggles.speedExploit_Toggle then return end
    if not options.speedExploitMethod_Dropdown then return end
    if not options.speedExploitAmount_Slider then return end

    local enabled = toggles.speedExploit_Toggle.Value 
    local method = options.speedExploitMethod_Dropdown.Value
    local speed = options.speedExploitAmount_Slider.Value

    if enabled then
        if method == "WalkSpeed" then
            disableVelocityMode()
            humanoid.WalkSpeed = speed
        else
            humanoid.WalkSpeed = 16
            enableVelocityMode(speed)
        end
    else
        disableVelocityMode()
        humanoid.WalkSpeed = 16
    end
end

toggles.speedExploit_Toggle:OnChanged(applySpeed)
options.speedExploitAmount_Slider:OnChanged(applySpeed)

options.speedExploitMethod_Dropdown:OnChanged(function()
    local method = options.speedExploitMethod_Dropdown.Value
    local slider = options.speedExploitAmount_Slider

    if method == "Velocity" and toggles.toggleFly_Toggle.Value then
        options.speedExploitMethod_Dropdown:SetValue("WalkSpeed")
        notify("Error", "Incompatible", "Velocity Speed is incompatible with Fly. Speed Exploit has been updated to WalkSpeed.", 10)
    end

    if method == "WalkSpeed" then
        slider:SetMin(1)
        slider:SetMax(20)
        if slider.Value > 20 then slider:SetValue(20) end
    else
        slider:SetMin(1)
        slider:SetMax(100)
    end

    applySpeed()
end)

-- [Player / Speed Exploit] Reapply speed after respawn

local function speedOnCharacterAdded(char: Model?)
    if not char then return end

    humanoid = char:WaitForChild("Humanoid", 5) :: Humanoid?
    rootPart = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?

    if humanoid and rootPart then
        task.wait(0.1)
        applySpeed()
    end
end

localplayer.CharacterAdded:Connect(speedOnCharacterAdded)

if localplayer.Character then
    speedOnCharacterAdded(localplayer.Character)
else
    local character = localplayer.CharacterAdded:Wait()
    speedOnCharacterAdded(character)
end

-- [Player / Speed Exploit] WalkSpeed enforcement
do
    local walkSpeedConnection = runService.RenderStepped:Connect(function()
        if not options.speedExploitMethod_Dropdown then return end
        if humanoid and toggles.speedExploit_Toggle.Value and options.speedExploitMethod_Dropdown.Value == "WalkSpeed" then
            local targetSpeed = options.speedExploitAmount_Slider.Value
            if humanoid.WalkSpeed ~= targetSpeed then
                humanoid.WalkSpeed = targetSpeed
            end
        end
    end)

    table.insert(teardownTasks, function()
        walkSpeedConnection:Disconnect()
    end)
end

-- [Player / Other] Door noclip, backtrack, and freecam

othersGroup3:AddToggle("doorNoclip_Toggle", { Text = "Door Noclip" })
othersGroup3:AddToggle("autoBacktrack_Toggle", { Text = "Backtrack", Tooltip = "Automatically teleports you back to your last death location." })

-- [Player / Out-of-Bounds Guard] Attempts to move you back to a safe spot before the game's out-of-bounds / in-wall kill fires

othersGroup3:AddToggle("outOfBoundsGuard_Toggle", { Text = "Out-of-Bounds Guard", Tooltip = "The game kills you about 2-3 seconds after you leave the map or sit inside a wall. This teleports you back to your last safe position if you leave the real map (fly and noclip included) or end up inside a wall." })

do
    local guardDepbox = othersGroup3:AddDependencyBox()

    guardDepbox:AddSlider("outOfBoundsGuardGrace_Slider", { Text = "Grace Time", Tooltip = "How long you can be out of bounds or inside a wall before you are moved back. The game kills you after about 2-3 seconds, so keep this well below that. Falling out of the map is always handled instantly.", Default = 0.8, Min = 0.1, Max = 1.5, Suffix = " Seconds", Rounding = 1,
        Callback = function(val)
            options.outOfBoundsGuardGrace_Slider:SetSuffix(getSuffix(options.outOfBoundsGuardGrace_Slider, "Second"))
        end
    })

    guardDepbox:AddSlider("outOfBoundsGuardMargin_Slider", { Text = "Map Edge Margin", Tooltip = "How far from the real map (rooms, walls, fences, buildings) you can get before you are moved back. The map is much smaller than the game's own MapLimit box, so this is what keeps you from flying through walls and around outside it. Lower is tighter, but below 24 it can misfire in the largest halls. The open surface allows 4x this value.", Default = 24, Min = 16, Max = 96, Suffix = " Studs", Rounding = 0,
        Callback = function(val)
            options.outOfBoundsGuardMargin_Slider:SetSuffix(getSuffix(options.outOfBoundsGuardMargin_Slider, "Stud"))
        end
    })

    guardDepbox:SetupDependencies({ { toggles.outOfBoundsGuard_Toggle, true } })

    local config = {
        SolidInterval = 0.05, -- seconds between the inside-a-wall checks
        SolidBox = Vector3.new(1.6, 3.2, 1.6), -- smaller than the character, so standing on the floor or against a wall is clear
        MinGrace = 0.1,
        MaxGrace = 1.5, -- hard cap, so an old saved config can never outlast the kill timer
        VoidHeight = 150, -- studs above the MapLimit floor; below this with nothing underneath counts as falling out of the map
        NotifyCooldown = 3, -- seconds between notifications
        GroundRay = 400,
        EdgeInset = 1, -- studs the root part is held inside the map walls (a root part hugging a wall is already ~1 stud away)
        CeilingInset = 3, -- studs the root part is held below the ceiling
        RepeatWindow = 3, -- seconds after a rescue during which grace drops to MinGrace (fly/noclip pushing you straight back in)
        HullFineCell = 8, -- studs per cell of the underground (3D) map hull
        HullCoarseCell = 32, -- studs per cell of the surface (2D) map hull
        HullMargin = { Default = 24, Min = 16, Max = 96 }, -- studs from real map geometry that still count as inside the map (matches the slider)
        HullSurfaceScale = 4, -- the open surface allows this many times the margin (open desert between the buildings)
        HullSurfaceAirHeight = 120, -- studs above the highest surface part that still count as inside the map
        HullMaxPartCells = 60000, -- a single part that would cover more cells than this is skipped
        HullSliceBudget = 0.004, -- seconds of hull building per frame, so building it never causes a hitch
    }

    local solidGroup = "Default"

    for _, group in ipairs(game:GetService("PhysicsService"):GetRegisteredCollisionGroups()) do
        if group.name == "Survivors" then
            solidGroup = "Survivors"
            break
        end
    end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.RespectCanCollide = true
    overlapParams.CollisionGroup = solidGroup

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true
    rayParams.CollisionGroup = solidGroup

    local guard = {
        Token = 0, -- incremented on every start/stop so a stale bounds measurement can tell it was cancelled
        Heartbeat = nil,
        CharacterAdded = nil,
        SolidElapsed = 0,
        InsideSolid = false, -- result of the last inside-a-wall check
        Bounds = nil, -- { Min = Vector3, Max = Vector3, VoidY = number }
        Hull = nil, -- { Fine = set, Coarse = set, SurfaceY = number?, SurfaceTop = number } (see guard.buildHull)
        HullBuild = 0, -- incremented on every hull build so an older, slower build can tell it was replaced
        HullRejected = false, -- true when the last hull build was dropped because you were outside it (retried when the margin changes)
        LastInHull = nil, -- Vector3: the last position that was inside the map hull
        LastSafe = nil, -- CFrame of the last position that was in bounds and not inside anything solid
        LastGrounded = nil, -- CFrame of the last safe position you were standing on
        UnsafeSince = nil,
        LastNotify = -math.huge,
        LastRescue = -math.huge,
        FilteredCharacter = nil,
        FiltersReady = false,
    }

    local function notifyGuard(notificationType, description, force)
        local now = os.clock()

        -- Repeating notices are throttled; one-time ones (force) always show.
        if not force and now - guard.LastNotify < config.NotifyCooldown then
            return
        end

        guard.LastNotify = now
        notify(notificationType, "Out-of-Bounds Guard", description, 5)
    end

    -- Killers and the MapLimit walls are excluded completely. Other players' characters are skipped per hit (see isInsideSolid).
    local function refreshFilters(character)
        local ignored = {}

        if character then
            table.insert(ignored, character)
        end

        for _, name in ipairs({ "Killers", "Characters to kill" }) do
            local folder = workspace:FindFirstChild(name)

            if folder then
                table.insert(ignored, folder)
            end
        end

        local area = workspace:FindFirstChild("AREA51")
        local limit = area and area:FindFirstChild("MapLimit")

        if limit then
            table.insert(ignored, limit)
        end

        overlapParams.FilterDescendantsInstances = ignored
        rayParams.FilterDescendantsInstances = ignored
        guard.FilteredCharacter = character
        guard.FiltersReady = true
    end

    -- Builds the map's box from the INNER faces of the MapLimit walls.
    -- A wall is thin on exactly one axis; that axis is the one it closes off.
    local function measureMapBounds()
        local area = workspace:FindFirstChild("AREA51") or workspace:WaitForChild("AREA51", 5)
        local limit = area and (area:FindFirstChild("MapLimit") or area:WaitForChild("MapLimit", 5))

        if not limit then
            return nil
        end

        local center = limit:GetBoundingBox().Position
        local low, high = {}, {}

        for _, part in ipairs(limit:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                local size, position = part.Size, part.Position
                local axis

                if size.X <= 4 and size.Y > 20 and size.Z > 20 then
                    axis = "X"
                elseif size.Y <= 4 and size.X > 20 and size.Z > 20 then
                    axis = "Y"
                elseif size.Z <= 4 and size.X > 20 and size.Y > 20 then
                    axis = "Z"
                end

                if axis then
                    local half = size[axis] / 2

                    if position[axis] < center[axis] then
                        low[axis] = math.max(low[axis] or -math.huge, position[axis] + half)
                    else
                        high[axis] = math.min(high[axis] or math.huge, position[axis] - half)
                    end
                end
            end
        end

        for _, axis in ipairs({ "X", "Y", "Z" }) do
            if not (low[axis] and high[axis]) then
                return nil
            end
        end

        return {
            Min = Vector3.new(low.X, low.Y, low.Z),
            Max = Vector3.new(high.X, high.Y, high.Z),
            VoidY = low.Y + config.VoidHeight,
        }
    end

    local function refreshBounds(token)
        local success, bounds = pcall(measureMapBounds)

        if guard.Token ~= token then
            return
        end

        if success and bounds then
            guard.Bounds = bounds
        else
            guard.Bounds = nil
            notifyGuard("Error", "Could not find the map limits, so only the wall check and the void floor are active.", true)
        end
    end

    local function isInsideSolid(position)
        for _, part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(position), config.SolidBox, overlapParams)) do
            -- Another player's character (or anything with a Humanoid) is not a wall.
            local model = part:FindFirstAncestorOfClass("Model")

            if not (model and model:FindFirstChildOfClass("Humanoid")) then
                return true
            end
        end

        return false
    end

    local function hasGroundBelow(position)
        return workspace:Raycast(position, Vector3.new(0, -config.GroundRay, 0), rayParams) ~= nil
    end

    function guard.hullContains(hull, position)
        local slider = options.outOfBoundsGuardMargin_Slider
        local margin = math.clamp(slider and slider.Value or config.HullMargin.Default, config.HullMargin.Min, config.HullMargin.Max)
        local surfaceY = hull.SurfaceY

        if surfaceY and position.Y >= surfaceY then
            if position.Y > hull.SurfaceTop + config.HullSurfaceAirHeight then
                return false
            end

            -- A cell counts when its box is within the margin along every axis.
            local cell = config.HullCoarseCell
            local range = margin * config.HullSurfaceScale
            local reach = math.ceil(range / cell)
            local px, pz = position.X, position.Z
            local cx, cz = math.floor(px / cell), math.floor(pz / cell)
            local coarse = hull.Coarse

            for x = cx - reach, cx + reach do
                if math.max(x * cell - px, px - (x + 1) * cell, 0) <= range then
                    for z = cz - reach, cz + reach do
                        if coarse[(x + 256) + 1024 * (z + 256)] and math.max(z * cell - pz, pz - (z + 1) * cell, 0) <= range then
                            return true
                        end
                    end
                end
            end

            return false
        end

        local cell = config.HullFineCell
        local reach = math.ceil(margin / cell)
        local px, py, pz = position.X, position.Y, position.Z
        local cx, cy, cz = math.floor(px / cell), math.floor(py / cell), math.floor(pz / cell)
        local fine = hull.Fine

        for x = cx - reach, cx + reach do
            if math.max(x * cell - px, px - (x + 1) * cell, 0) <= margin then
                for y = cy - reach, cy + reach do
                    if math.max(y * cell - py, py - (y + 1) * cell, 0) <= margin then
                        for z = cz - reach, cz + reach do
                            if fine[(x + 256) + 1024 * ((z + 256) + 1024 * (y + 256))] and math.max(z * cell - pz, pz - (z + 1) * cell, 0) <= margin then
                                return true
                            end
                        end
                    end
                end
            end
        end

        return false
    end

    -- Voxelizes the real map once. Runs in slices so it never hitches a frame, and is replaced by newer
    -- builds (respawn) or cancelled by stopping the guard.
    function guard.buildHull(token)
        guard.HullBuild = guard.HullBuild + 1

        local build = guard.HullBuild
        local area = workspace:FindFirstChild("AREA51") or workspace:WaitForChild("AREA51", 5)

        if not area then
            return
        end

        local limit = area:FindFirstChild("MapLimit")
        local outside = area:FindFirstChild("Outside")
        local ground = outside and outside:FindFirstChild("GroundOutside")
        local fineCell, coarseCell = config.HullFineCell, config.HullCoarseCell
        local fine, coarse = {}, {}
        local surfaceY, surfaceTop = nil, -math.huge

        local function extents(part)
            local cframe, size = part.CFrame, part.Size
            local right, up, look = cframe.RightVector, cframe.UpVector, cframe.LookVector

            return cframe.Position, Vector3.new(
                (math.abs(right.X) * size.X + math.abs(up.X) * size.Y + math.abs(look.X) * size.Z) / 2,
                (math.abs(right.Y) * size.X + math.abs(up.Y) * size.Y + math.abs(look.Y) * size.Z) / 2,
                (math.abs(right.Z) * size.X + math.abs(up.Z) * size.Y + math.abs(look.Z) * size.Z) / 2
            )
        end

        if ground then
            local top = -math.huge

            for _, part in ipairs(ground:GetDescendants()) do
                if part:IsA("BasePart") then
                    local center, half = extents(part)
                    top = math.max(top, center.Y + half.Y)
                end
            end

            if top > -math.huge then
                surfaceY = top - 3 -- the character's root part hovers above the ground, so "surface" starts a little below its top face
            end
        end

        local roots = { area }

        for _, name in ipairs({ "Doors", "Spawns", "PACKAPUNCH", "Top10" }) do
            local root = workspace:FindFirstChild(name)

            if root then
                table.insert(roots, root)
            end
        end

        local sliceStart = os.clock()

        for _, root in ipairs(roots) do
            for _, part in ipairs(root:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide and not (limit and part:IsDescendantOf(limit)) and not (ground and part:IsDescendantOf(ground)) then
                    local center, half = extents(part)
                    local x0, x1 = math.floor((center.X - half.X) / fineCell), math.floor((center.X + half.X) / fineCell)
                    local y0, y1 = math.floor((center.Y - half.Y) / fineCell), math.floor((center.Y + half.Y) / fineCell)
                    local z0, z1 = math.floor((center.Z - half.Z) / fineCell), math.floor((center.Z + half.Z) / fineCell)

                    if (x1 - x0 + 1) * (y1 - y0 + 1) * (z1 - z0 + 1) <= config.HullMaxPartCells then
                        for x = x0, x1 do
                            for y = y0, y1 do
                                for z = z0, z1 do
                                    fine[(x + 256) + 1024 * ((z + 256) + 1024 * (y + 256))] = true
                                end
                            end
                        end
                    end

                    -- Surface footprint: only parts that stand on or above the ground (a shaft's centre is far below it).
                    if surfaceY and center.Y >= surfaceY - 1 then
                        local cx0, cx1 = math.floor((center.X - half.X) / coarseCell), math.floor((center.X + half.X) / coarseCell)
                        local cz0, cz1 = math.floor((center.Z - half.Z) / coarseCell), math.floor((center.Z + half.Z) / coarseCell)

                        if (cx1 - cx0 + 1) * (cz1 - cz0 + 1) <= config.HullMaxPartCells then
                            surfaceTop = math.max(surfaceTop, center.Y + half.Y)

                            for x = cx0, cx1 do
                                for z = cz0, cz1 do
                                    coarse[(x + 256) + 1024 * (z + 256)] = true
                                end
                            end
                        end
                    end
                end

                if os.clock() - sliceStart > config.HullSliceBudget then
                    task.wait()

                    if guard.Token ~= token or guard.HullBuild ~= build then
                        return
                    end

                    sliceStart = os.clock()
                end
            end
        end

        if guard.Token ~= token or guard.HullBuild ~= build then
            return
        end

        local hull = { Fine = fine, Coarse = coarse, SurfaceY = surfaceY, SurfaceTop = surfaceTop }
        local hrp = getHRP()

        -- Only trust a hull your character is inside right now. If it is not, using it would just teleport you around, so it stays off.
        if hrp and isAlive() and not guard.hullContains(hull, hrp.Position) then
            guard.Hull = nil
            guard.HullRejected = true
            notifyGuard("Error", "Your character is outside the real map right now, so the map edge check is off. Switch the guard off and on again while you are inside the map.", true)
            return
        end

        guard.Hull = hull
        guard.HullRejected = false
    end

    -- Inside the MapLimit box
    function guard.insideBox(position)
        local bounds = guard.Bounds

        if not bounds then
            return true
        end

        local inset = config.EdgeInset

        return position.X >= bounds.Min.X + inset and position.X <= bounds.Max.X - inset
            and position.Z >= bounds.Min.Z + inset and position.Z <= bounds.Max.Z - inset
            and position.Y <= bounds.Max.Y - config.CeilingInset
    end

    -- A remembered spot is only a valid rescue target if it is still inside the map with the CURRENT settings
    function guard.isSafeTarget(cframe)
        local position = cframe.Position
        local hull = guard.Hull

        return guard.insideBox(position) and not (hull and not guard.hullContains(hull, position))
    end

    local function returnToSafety(hrp, reason)
        local target = guard.LastSafe

        -- A safe spot in mid-air over nothing would just drop you out of bounds again.
        if not target or not guard.isSafeTarget(target) or not hasGroundBelow(target.Position) then
            target = guard.LastGrounded
        end

        if target and not guard.isSafeTarget(target) then
            target = nil
        end

        -- Last resort: the spawn platform.
        if not target then
            local spawns = workspace:FindFirstChild("Spawns")

            if spawns then
                target = spawns:GetPivot() + Vector3.new(0, 5, 0)
            end
        end

        if not target then
            notifyGuard("Error", "You are " .. reason .. " but there is nowhere safe to move you back to.", true)
            return
        end

        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        entityLib.teleport(target)
        guard.LastRescue = os.clock()

        notifyGuard("Info", "Moved you back to a safe position (" .. reason .. ").")
    end

    local function guardTick(runSolid)
        local hrp = getHRP()

        if not hrp or not isAlive() then
            guard.UnsafeSince = nil
            guard.InsideSolid = false
            return
        end

        local character = localplayer.Character

        if not guard.FiltersReady or guard.FilteredCharacter ~= character then
            refreshFilters(character)
            runSolid = true
        end

        local position = hrp.Position
        local bounds = guard.Bounds
        local reason

        if bounds then
            -- Below the void line with nothing under you: immediate, because falling accelerates and the MapLimit floor hurts.
            if position.Y < bounds.VoidY and not hasGroundBelow(position) then
                reason = "falling out of the map"
            else
                if not guard.insideBox(position) then
                    reason = "outside the map"
                end
            end
        elseif position.Y < workspace.FallenPartsDestroyHeight + 150 then
            reason = "falling out of the map"
        end

        -- The real map is far smaller than the MapLimit box checked above, so this is what actually catches flying or noclipping
        -- through the map's walls and out into the empty space around it.
        local hull = guard.Hull

        if hull and not reason then
            if guard.hullContains(hull, position) then
                guard.LastInHull = position
            else
                -- Outside the real map: the grace-time rescue below teleports you back to your last safe position..
                reason = "outside the map"
            end
        end

        if runSolid then
            guard.InsideSolid = not reason and isInsideSolid(position)
        end

        if not reason and guard.InsideSolid then
            reason = "inside a wall"
        end

        if not reason then
            guard.UnsafeSince = nil

            -- Only trust a position that has just passed the solid check, not one carried over from an earlier frame.
            if runSolid then
                -- Only keep spots with ground under them
                if hasGroundBelow(position) then
                    guard.LastSafe = hrp.CFrame
                end

                local humanoid = getHumanoid()

                if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                    guard.LastGrounded = hrp.CFrame
                end
            end

            return
        end

        local now = os.clock()
        guard.UnsafeSince = guard.UnsafeSince or now

        local slider = options.outOfBoundsGuardGrace_Slider
        local grace = math.clamp(slider and slider.Value or 0.8, config.MinGrace, config.MaxGrace)

        -- Fly or noclip that keeps pushing you straight back into the wall: do not give it the full grace time again.
        if now - guard.LastRescue < config.RepeatWindow then
            grace = config.MinGrace
        end

        if reason == "falling out of the map" or now - guard.UnsafeSince >= grace then
            guard.UnsafeSince = nil
            guard.InsideSolid = false
            returnToSafety(hrp, reason)
        end
    end

    local function stopGuard()
        guard.Token = guard.Token + 1

        if guard.Heartbeat then
            guard.Heartbeat:Disconnect()
            guard.Heartbeat = nil
        end

        if guard.CharacterAdded then
            guard.CharacterAdded:Disconnect()
            guard.CharacterAdded = nil
        end

        guard.Bounds = nil
        guard.Hull = nil
        guard.HullRejected = false
        guard.LastInHull = nil
        guard.LastSafe = nil
        guard.LastGrounded = nil
        guard.UnsafeSince = nil
        guard.InsideSolid = false
        guard.LastRescue = -math.huge
        guard.FilteredCharacter = nil
        guard.FiltersReady = false
        guard.SolidElapsed = 0
    end

    local function startGuard()
        stopGuard()

        -- Measure the map; until it finishes only the void line and the wall check are active.
        task.spawn(refreshBounds, guard.Token)
        task.spawn(guard.buildHull, guard.Token)

        guard.CharacterAdded = localplayer.CharacterAdded:Connect(function()
            -- Positions from the last life mean nothing in the new one, and the map may have been rebuilt for the new round.
            guard.LastSafe = nil
            guard.LastGrounded = nil
            guard.LastInHull = nil
            guard.UnsafeSince = nil
            guard.InsideSolid = false
            guard.FiltersReady = false

            task.spawn(refreshBounds, guard.Token)
            task.spawn(guard.buildHull, guard.Token)
        end)

        guard.Heartbeat = runService.Heartbeat:Connect(function(deltaTime)
            guard.SolidElapsed = guard.SolidElapsed + deltaTime

            local runSolid = guard.SolidElapsed >= config.SolidInterval

            if runSolid then
                guard.SolidElapsed = 0
            end

            local success, tickError = pcall(guardTick, runSolid)

            if not success then
                warn("[Out-of-Bounds Guard] " .. tostring(tickError))
            end
        end)
    end

    -- Apply a changed slider immediately: forget the pending timer and the "just rescued" shortening, so the very next check uses the new value.
    options.outOfBoundsGuardGrace_Slider:OnChanged(function()
        guard.UnsafeSince = nil
        guard.LastRescue = -math.huge
    end)

    options.outOfBoundsGuardMargin_Slider:OnChanged(function()
        guard.UnsafeSince = nil
        guard.LastRescue = -math.huge

        -- If the map hull was dropped because you were outside it at the old margin, try again with the new one.
        if guard.Heartbeat and guard.HullRejected then
            task.spawn(guard.buildHull, guard.Token)
        end
    end)

    toggles.outOfBoundsGuard_Toggle:OnChanged(function(enabled)
        if enabled then
            startGuard()
        else
            stopGuard()
        end
    end)

    -- Runs from unloadModules() after every toggle has been switched off; this is the safety net.
    table.insert(teardownTasks, stopGuard)
end

-- [Player / Freecam] Controls and camera lifecycle

othersGroup3:AddToggle("freecam_Toggle", { Text = "Freecam", Tooltip = false, Default = false })

local freecamDepbox = othersGroup3:AddDependencyBox()

local freecamSpeedSlider = freecamDepbox:AddSlider("freecamSpeedSlider", { Text = "Speed", Tooltip = "The speed you move at in freecam.",  Default = 64, Min = 10, Max = 2000, Rounding = 0 })
local freecamPanSpeedSlider = freecamDepbox:AddSlider("freecamPanSpeedSlider", { Text = "Pan Speed", Tooltip = "How fast your camera moves when moving your mouse around in freecam.",  Default = 8, Min = 2, Max = 30, Rounding = 0 })
freecamDepbox:AddDivider()

freecamDepbox:SetupDependencies({ { toggles.freecam_Toggle, true } })

toggles.doorNoclip_Toggle:OnChanged(function(enabled)
    for _, part in ipairs(game.Workspace:GetDescendants()) do
        if part:IsA("Part") and part.Name == "Door" then
            if enabled then
                entityLib.storeData(part, "Transparency", true)
                part.CanCollide = false
                part.Transparency = 0.8
            else
                part.CanCollide = true
                entityLib.restoreData(part, "Transparency")
            end

            -- Handle decals

            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    if enabled then
                        entityLib.storeData(child, "Transparency", true)
                        child.Transparency = 0.8
                    else
                        entityLib.restoreData(child, "Transparency")
                    end
                end
            end
        end
    end
end)

-- [Player / Backtrack] Store death location and restore it on respawn
local backtrackCFrame
local function connectDied(humanoid)
    humanoid.Died:Connect(function()
        if toggles.autoBacktrack_Toggle.Value then
            local hrp = getHRP()
            backtrackCFrame = hrp.CFrame
            entityLib.storeData(hrp, "CFrame", true)
        end

        toggles.autoBacktrack_Toggle:SetDisabled(true)
    end)
end

if localplayer.Character then
    local characterHumanoid = localplayer.Character:FindFirstChildOfClass("Humanoid")
    if characterHumanoid then
        connectDied(characterHumanoid)
    end
end

localplayer.CharacterAdded:Connect(function(char)
    local characterHumanoid = char:FindFirstChildOfClass("Humanoid")
    if characterHumanoid then
        connectDied(characterHumanoid)
    end

    if backtrackCFrame then
        entityLib.teleport(backtrackCFrame)
        backtrackCFrame = nil
    end

    toggles.autoBacktrack_Toggle:SetDisabled(false)
end)

do
    -- Calling disable() then make the camera library restore a camera state it never saved (CameraType = nil), so only disable what was actually enabled.
    local freecamActive = false

    toggles.freecam_Toggle:OnChanged(function(enabled)
        camLib.Freecam:updateSpeed(freecamSpeedSlider.Value)
        camLib.Freecam:updatePanSpeed(freecamPanSpeedSlider.Value)

        if enabled and not freecamActive then
            freecamActive = true
            camLib.Freecam:enable()
        elseif not enabled and freecamActive then
            freecamActive = false
            camLib.Freecam:disable()
        end
    end)
end

options.freecamSpeedSlider:OnChanged(function(val)
    camLib.Freecam:updateSpeed(freecamSpeedSlider.Value)
end)

options.freecamPanSpeedSlider:OnChanged(function(val)
    camLib.Freecam:updatePanSpeed(freecamPanSpeedSlider.Value)
end)

-- ============================================================================
-- 10 | TAB: EXPLOITS
-- ============================================================================

local exploitsGroup = tabs.exploits:AddLeftGroupbox("Exploits")
local killersGroup = tabs.exploits:AddRightGroupbox("Killers")

-- [Exploits / Main] Weapon workflow and aim controls

-- [Exploits / Pack-a-Punch] Single-weapon teleporter workflow
local function singlePAP(weaponName)
    -- Validate selected weapon

    if not entityLib.getTool("Specific", weaponName) then
        notify("Error", "Invalid tool", "You don't have " .. weaponName .. " in your inventory.", 6)
        return false
    end

    -- Validate required kill count

    local requirements = require(game:GetService("StarterPlayer").StarterPlayerScripts.LocalAnimations["Classic area"].Teleportation.PackAPunch["Classic mode"].Requirements)
    local requiredKills = requirements[weaponName]
    local kills = game:GetService("Players").LocalPlayer.leaderstats["Killers Killed"].Value

    if requiredKills and kills < requiredKills then
        local needed = requiredKills - kills
        notify("Error", "Insufficient kills", weaponName .. " requires " .. requiredKills .. " kills to pack a punch. You need " .. needed .. " more.", 7)
        return false
    end

    -- Teleport to the control panel, activate the teleporter (with retries) and validate the punch room

    freeze(true)

    local teleported, teleportResult = utils.runPAPTeleport(weaponName)

    if not teleported then
        local failReason = teleportResult

        -- On death the humanoid is replaced, so there is nothing to unfreeze
        if failReason ~= "died" then
            freeze(false)
        end

        if failReason == "retries" then
            notify("Error", "Teleporter unresponsive", "The teleporter did not respond after several attempts. Please try again.", 8)
        elseif failReason == "busy" then
            notify("Error", "Teleporter busy", "The teleporter stayed in use by another player. Please try again later.", 8)
        elseif failReason == "arrival" then
            notify("Error", "Teleport failed", "You did not reach the punch room. Please try again.", 8)
        elseif failReason == "error" then
            notify("Error", "Teleport failed", "Something went wrong while using the teleporter.", 6)
        end

        return false
    end

    -- PAP weapon

    game:GetService("Workspace").PACKAPUNCH.PAPStarted:FireServer(weaponName)
    game:GetService("Workspace").PACKAPUNCH.PAPFinished:FireServer()

    -- "Teleport finished" has done its job once the weapon is being pack a punched
    utils.dismissNotify(teleportResult)
    notify("Success", "Success", weaponName .. " has been pack a punched!", 7)

    freeze(false)
    return true
end

exploitsGroup:AddToggle("enableAimbot_Toggle", { Text = "Enable Aimbot", Tooltip = false })

-- [Exploits / Aimbot] Targeting controls
local aimbotDepbox = exploitsGroup:AddDependencyBox()
aimbotDepbox:AddDropdown("aimbotHitPart_Dropdown", { Text = "Hit Part", Tooltip = false, Values = { "Head", "HumanoidRootPart" }, Default = 1, Multi = false })
aimbotDepbox:AddDropdown("aimbotTargetType_Dropdown", { Text = "Target Type", Tooltip = false, Values = { "Closest", "Closest to Cursor" }, Default = 2, Multi = false })
aimbotDepbox:AddDropdown("aimbotExcludedKillers_Dropdown", { Text = "Excluded Killers", Tooltip = false, Values = killerNames, Default = { "Giant", "Jane" }, Multi = true, Searchable = true })
aimbotDepbox:AddSlider("aimbotMaximumDistance_Slider", { Text = "Range", Tooltip = "Killers farther than this distance will not be targeted.", Default = 100, Min = 10, Max = 2000, Suffix = " Studs", Rounding = 1 })
aimbotDepbox:AddSlider("aimbotSmoothing_Slider", { Text = "Smoothing", Tooltip = "How smooth aimbot should lock onto Killer's.", Default = 400, Min = 10, Max = 1000, Rounding = 0 })
aimbotDepbox:AddToggle("aimbotVisibilityCheck_Toggle", { Text = "Visibility Check", Tooltip = "Whether to only target Killers that are visible.", Default = true })
aimbotDepbox:AddDivider()

exploitsGroup:AddToggle("enableSilentAim_Toggle", { Text = "Enable Silent Aim", Tooltip = false })

local silentAimDepbox = exploitsGroup:AddDependencyBox()
silentAimDepbox:AddSlider("FOV_Slider", { Text = "FOV", Tooltip = "The screen-space radius in which targets can be selected.", Default = 150, Min = 0, Max = 1000, Suffix = " px", Rounding = 0 })
silentAimDepbox:AddToggle("silentAimWallCheck_Toggle", { Text = "Wall Check", Tooltip = "Only target Killers that are visible. Wallbang takes priority when enabled.", Default = true })
silentAimDepbox:AddToggle("silentAimWallBang_Toggle", { Text = "Wallbang", Tooltip = "Bullets fired at a locked Killer fly through walls and other obstructions. Shots with no Killer inside the FOV behave normally.", Default = true })
silentAimDepbox:AddToggle("silentAimNoSpread_Toggle", { Text = "No Spread", Tooltip = "Removes weapon inaccuracy and shotgun pellet spread while a Killer is locked, so every bullet follows the aimed line.", Default = true })
silentAimDepbox:AddDropdown("silentAimHitPart_Dropdown", { Text = "Hit Part", Tooltip = "Auto aims at the Head while a Killer is close and standing still, and at the larger HumanoidRootPart when it is moving or far away.", Values = { "Auto", "Head", "HumanoidRootPart" }, Default = 1, Multi = false })
silentAimDepbox:AddToggle("silentAimPrediction_Toggle", { Text = "Prediction", Tooltip = "Lead moving Killers based on their velocity and projectile travel time.", Default = true })
silentAimDepbox:AddSlider("silentAimProjectileSpeed_Slider", { Text = "Projectile Speed", Tooltip = "Used to estimate projectile travel time for prediction.", Default = 150, Min = 25, Max = 1000, Suffix = " studs/s", Rounding = 0 })
silentAimDepbox:AddSlider("silentAimPredictionFactor_Slider", { Text = "Prediction Factor", Tooltip = "Scales how far ahead the predicted position is.", Default = 1, Min = 0, Max = 2, Rounding = 1 })
silentAimDepbox:AddToggle("silentAimShowFOV_Toggle", { Text = "Show FOV", Tooltip = "Display the silent-aim target radius when Silent Aim is enabled.", Default = true })

local silentAimFOVColorDepbox = silentAimDepbox:AddDependencyBox()

silentAimFOVColorDepbox:AddLabel("FOV Color"):AddColorPicker("silentAimFOVColor_ColorPicker", { Title = "FOV Color", Default = Color3.fromRGB(0, 229, 255), Transparency = nil })
silentAimFOVColorDepbox:AddCheckbox("rainbowSilentAimFOVColor_Toggle", { Text = "Rainbow FOV Color" })

silentAimDepbox:AddDivider()

exploitsGroup:AddToggle("autoCollect_Toggle", { Text = "Auto Collect Ingredients", Tooltip = "Automatically collects all materials/ingredients added in V17.0." })
exploitsGroup:AddButton({ Text = "Complete Area 51 Personnel",
    Func = function()
        local hrp = getHRP()
        entityLib.storeData(hrp, "CFrame", true)

        utils.fireTouchEvent(hrp, game:GetService("Workspace").AREA51.AlienExit.Reward) -- Find the alien
        utils.fireTouchEvent(hrp, area51.PlantRoom["Box of Shells"].Box) -- Find an ammo bag
        utils.fireTouchEvent(hrp, game:GetService("Workspace").AREA51.ExecutionRoom.Reward) -- Access the execution room
        -- Find the giant zombie

        entityLib.teleport(CFrame.new(177.195404, 313.499969, 577.864624, -0.00262195012, -7.50515117e-09, 0.999996543, 9.9084508e-12, 1, 7.50520268e-09, -0.999996543, 2.95866838e-11, -0.00262195012))
        utils.fireTouchEvent(hrp, game:GetService("Workspace").AREA51.RadioactiveArea.GiantZombieRoom.GiantZombieEngine.Close.Door2)

        utils.fireTouchEvent(hrp, workspace.Weapons.M14.Hitbox) -- Find the M14
        utils.fireTouchEvent(hrp, workspace.Weapons["M16A2/M203"].Hitbox) -- Find the M16A2/M203
        utils.fireTouchEvent(hrp, workspace.Weapons.MP5k.Hitbox) -- Find the MP5k

        utils.fireTouchEvent(hrp, workspace.AREA51.RadioactiveArea.Floor1.Paper) -- Find the paper 1
        utils.fireTouchEvent(hrp, workspace.AREA51.YellowBedRoom.Buro.Paper) -- Find the paper 2
        utils.fireTouchEvent(hrp, workspace.AREA51.MeetingRoom.DeadGuy.Paper) -- Find the paper 3

        utils.fireTouchEvent(hrp, workspace.Weapons.R870.Hitbox) -- Find the R870
        utils.fireTouchEvent(hrp, workspace.Weapons.RayGun.Hitbox) -- Find the RayGun
        utils.fireTouchEvent(hrp, workspace.Weapons.SVD.Hitbox) -- Find the SVD
        utils.fireTouchEvent(hrp, workspace.Weapons["Desert Eagle"].Hitbox) -- Find the Desert Eagle

        utils.fireTouchEvent(hrp, workspace.AREA51.SecretPath1.Reward) -- Find the secret path 1
        utils.fireTouchEvent(hrp, workspace.AREA51.SecretPath2.Reward) -- Find the secret path 2
        utils.fireTouchEvent(hrp, workspace.AREA51.SecretPath3.Reward) -- Find the secret path 3
        utils.fireTouchEvent(hrp, workspace.AREA51.SecretPath4.Reward) -- Find the secret path 4
        utils.fireTouchEvent(hrp, workspace.AREA51.SecretPath5.Reward) -- Find the secret path 5
        utils.fireTouchEvent(hrp, workspace.AREA51.SecretPath6.Reward) -- Find the secret path 6

        utils.fireTouchEvent(hrp, area51.Outside.Hangar.Right["Zombie Morph"].TheButton) -- Wear the zombie morph

        -- Pack A Punch a weapon
        repeat task.wait() until entityLib.getTool("Specific", "MP5k")
        local punched = singlePAP("MP5k")

        local returnCFrame = CFrame.new(219.199997, 323.500061, 845.900024)

        -- Wait until you're at the return cframe/in the gun room place BEFORE breaking (gives up after 30s)
        if punched then
            local waitStart = os.clock()
            repeat task.wait() until entityLib.checkCFrame(getHRP() or hrp, returnCFrame, 5) or os.clock() - waitStart > 30
        end

        entityLib.restoreData(hrp, "CFrame")
        entityLib.clearData(hrp, "CFrame")
    end,
})

aimbotDepbox:SetupDependencies({ { toggles.enableAimbot_Toggle, true } })
silentAimDepbox:SetupDependencies({ { toggles.enableSilentAim_Toggle, true } })
silentAimFOVColorDepbox:SetupDependencies({ { toggles.silentAimShowFOV_Toggle, true } })

-- [Exploits / Silent Aim] Settings, target resolution, and weapon hooks
local silentAimHookRecords = {}

local function isSilentAimEnabled()
    if library.Unloaded then
        return false
    end

    local silentAimToggle = toggles.enableSilentAim_Toggle
    return silentAimToggle ~= nil and silentAimToggle.Value == true
end

-- Assigned inside the block below; the scanner further down calls it.
local scanSilentAimWeaponTables

do
    local silentAimBlacklistedNames = {
        Jane = true,
        Giant = true,
    }

    -- A shot's aim lookup, its spread rolls and its bullets all happen in the same frame, so a lock this young belongs to the current shot.
    local SILENT_AIM_LOCK_LIFETIME = 0.15
    -- Never lead a target by more than this many seconds of bullet travel time.
    local SILENT_AIM_MAX_LEAD_TIME = 1.5
    -- A Killer reported faster than this is teleporting or glitching; leading on that velocity would throw the shot away.
    local SILENT_AIM_MAX_TARGET_SPEED = 80

    local silentAimHookedObjects = setmetatable({}, { __mode = "k" })

    -- The Killer the latest shot was aimed at ({ model, time }). Cleared when a shot finds nothing inside the FOV.
    local silentAimLock = nil
    -- Every bullet remembers the Killer it was fired at, so Wallbang only ever applies to bullets that have a target.
    local silentAimMissileLocks = setmetatable({}, { __mode = "k" })

    local function isValidSilentAimTarget(model)
        if not model or not model:IsA("Model") or silentAimBlacklistedNames[model.Name] then
            return false
        end

        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            return false
        end

        if model == localplayer.Character then
            return false
        end

        local currentKillersFolder = workspace:FindFirstChild("Killers")
        return currentKillersFolder ~= nil and model:IsDescendantOf(currentKillersFolder)
    end

    local function getFreshSilentAimLock()
        local lock = silentAimLock

        if lock and os.clock() - lock.time <= SILENT_AIM_LOCK_LIFETIME and isValidSilentAimTarget(lock.model) then
            return lock
        end

        return nil
    end

    local function isSilentAimTargetVisible(targetPart, character)
        -- Wallbang bypasses the visibility check
        if not toggles.silentAimWallCheck_Toggle.Value or toggles.silentAimWallBang_Toggle.Value then
            return true
        end

        local currentCamera = workspace.CurrentCamera or camera
        if not currentCamera then
            return false
        end

        local origin = currentCamera.CFrame.Position
        local direction = targetPart.Position - origin
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = { localplayer.Character, character }
        raycastParams.IgnoreWater = true

        local result = workspace:Raycast(origin, direction, raycastParams)
        return result == nil or result.Instance:IsDescendantOf(character)
    end

    local function findSilentAimTargetModelFromPart(part)
        if typeof(part) ~= "Instance" then
            return nil
        end

        local current = part
        while current and current ~= workspace do
            if current:IsA("Model") and isValidSilentAimTarget(current) then
                return current
            end
            current = current.Parent
        end

        return nil
    end

    -- Where bullets actually leave the weapon (Weapon.fire uses the Flash part, or the Aim part while scoped).
    local function getSilentAimMuzzlePosition(weapon)
        local success, position = pcall(function()
            local tool = weapon.instance
            if typeof(tool) ~= "Instance" then
                return nil
            end

            local muzzle = tool:FindFirstChild("Flash")
            if weapon.aiming and weapon.has_scope then
                muzzle = tool:FindFirstChild("Aim") or muzzle
            end

            if muzzle and muzzle:IsA("BasePart") then
                return muzzle.Position
            end

            return nil
        end)

        return success and position or nil
    end

    local function getSilentAimRootPart(model)
        local rootPart = model:FindFirstChild("HumanoidRootPart", true)
            or model:FindFirstChild("Torso", true)
            or model:FindFirstChild("UpperTorso", true)

        if rootPart and rootPart:IsA("BasePart") then
            return rootPart
        end

        return model.PrimaryPart
    end

    local function resolveSilentAimPart(model, rootPart, horizontalSpeed, distance)
        local mode = options.silentAimHitPart_Dropdown.Value
        local part

        if mode == "Auto" then
            -- The Head is only worth aiming at while the Killer is close and nearly still. Otherwise the bigger
            -- center-mass part forgives the prediction error that moving Killers always have.
            if horizontalSpeed < 4 and distance < 80 then
                part = model:FindFirstChild("Head", true)
            else
                part = rootPart
            end
        else
            part = model:FindFirstChild(mode, true)
        end

        if not part or not part:IsA("BasePart") then
            part = model:FindFirstChild("Head", true)
        end
        if not part or not part:IsA("BasePart") then
            part = rootPart
        end

        return part
    end

    -- Time t at which a bullet leaving `origin` at `projectileSpeed` meets a target moving at `velocity`:
    -- |relative + velocity * t| = projectileSpeed * t, solved as a quadratic instead of guessing from the straight-line distance.
    local function solveSilentAimLeadTime(origin, targetPosition, velocity, projectileSpeed)
        local relative = targetPosition - origin
        local a = velocity:Dot(velocity) - projectileSpeed * projectileSpeed
        local b = 2 * relative:Dot(velocity)
        local c = relative:Dot(relative)
        local leadTime

        if math.abs(a) < 1e-6 then
            if math.abs(b) > 1e-6 then
                leadTime = -c / b
            end
        else
            local discriminant = b * b - 4 * a * c

            if discriminant >= 0 then
                local root = math.sqrt(discriminant)
                local first = (-b - root) / (2 * a)
                local second = (-b + root) / (2 * a)

                leadTime = math.huge
                if first > 0 then
                    leadTime = first
                end
                if second > 0 and second < leadTime then
                    leadTime = second
                end
                if leadTime == math.huge then
                    leadTime = nil
                end
            end
        end

        if not leadTime or leadTime <= 0 then
            leadTime = relative.Magnitude / projectileSpeed
        end

        return math.min(leadTime, SILENT_AIM_MAX_LEAD_TIME)
    end

    local function predictSilentAimPosition(origin, targetPart, rootPart)
        local position = targetPart.Position

        if not toggles.silentAimPrediction_Toggle.Value or not rootPart then
            return position
        end

        local projectileSpeed = tonumber(options.silentAimProjectileSpeed_Slider.Value) or 150
        if projectileSpeed <= 0 then
            return position
        end

        -- Only horizontal movement is led. Measured on this game's Killers, adding the vertical velocity made the guess
        -- worse (idle physics jitter and falls spike it to +-40 studs/s) and horizontal-only cut the average miss by about a third.
        local velocity = rootPart.AssemblyLinearVelocity
        velocity = Vector3.new(velocity.X, 0, velocity.Z)

        if velocity.Magnitude > SILENT_AIM_MAX_TARGET_SPEED then
            return position
        end

        local predictionFactor = tonumber(options.silentAimPredictionFactor_Slider.Value) or 1
        local leadTime = solveSilentAimLeadTime(origin, position, velocity, projectileSpeed)

        return position + velocity * leadTime * predictionFactor
    end

    -- Returns the Killer model and the position to shoot at, or nil when nothing is inside the FOV.
    local function getClosestSilentAimTarget(muzzlePosition)
        if not isSilentAimEnabled() then
            return nil, nil
        end

        local currentCamera = workspace.CurrentCamera or camera
        if not currentCamera then
            return nil, nil
        end

        local origin = muzzlePosition or currentCamera.CFrame.Position
        local fov = math.max(0, tonumber(options.FOV_Slider.Value) or 150)
        local mousePosition = uis:GetMouseLocation()
        local closestModel, closestPosition
        local shortestScreenDistance = fov

        local function evaluateKiller(model)
            if not isValidSilentAimTarget(model) then
                return
            end

            local rootPart = getSilentAimRootPart(model)
            if not rootPart then
                return
            end

            local velocity = rootPart.AssemblyLinearVelocity
            local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
            local distance = (rootPart.Position - origin).Magnitude
            local targetPart = resolveSilentAimPart(model, rootPart, horizontalSpeed, distance)
            if not targetPart then
                return
            end

            -- The FOV circle is judged on where the Killer is on screen right now, not where it is about to be,
            -- so what is inside the circle is what gets locked.
            local screenPosition, onScreen = currentCamera:WorldToViewportPoint(targetPart.Position)
            if not onScreen then
                return
            end

            local screenDistance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
            if screenDistance < shortestScreenDistance and isSilentAimTargetVisible(targetPart, model) then
                shortestScreenDistance = screenDistance
                closestModel = model
                closestPosition = predictSilentAimPosition(origin, targetPart, rootPart)
            end
        end

        local currentKillersFolder = workspace:FindFirstChild("Killers")
        if currentKillersFolder then
            for _, model in ipairs(currentKillersFolder:GetChildren()) do
                evaluateKiller(model)
            end
        end

        return closestModel, closestPosition
    end

    -- Weapon.screen_to_target: where the shot goes. Also decides which Killer (if any) this shot is locked on.
    local function createScreenToTargetHook(original)
        return function(self, ...)
            if isSilentAimEnabled() then
                local model, predictedPosition = getClosestSilentAimTarget(getSilentAimMuzzlePosition(self))

                if model and predictedPosition then
                    silentAimLock = { model = model, time = os.clock() }
                    return predictedPosition
                end

                silentAimLock = nil
            end

            return original(self, ...)
        end
    end

    -- Weapon.target_ray_callback: which things the game's short muzzle ray counts as hits.
    local function createRayCallbackHook(original)
        return function(raycastResult, ...)
            if toggles.silentAimWallBang_Toggle.Value
                and isSilentAimEnabled()
                and raycastResult
                and raycastResult.Instance
                and getFreshSilentAimLock()
            then
                return findSilentAimTargetModelFromPart(raycastResult.Instance) ~= nil
            end

            return original(raycastResult, ...)
        end
    end

    -- Weapon.compute_inaccuracy: spread of every bullet / pellet. Zero while a Killer is locked.
    local function createInaccuracyHook(original)
        return function(self, ...)
            if isSilentAimEnabled() and toggles.silentAimNoSpread_Toggle.Value and getFreshSilentAimLock() then
                return 0
            end

            return original(self, ...)
        end
    end

    -- Weapon.set_missile: runs once for every bullet right after it is created. Remember who it was fired at.
    local function createSetMissileHook(original)
        return function(self, missile, ...)
            if typeof(missile) == "Instance" and isSilentAimEnabled() then
                local lock = getFreshSilentAimLock()

                if lock then
                    silentAimMissileLocks[missile] = lock.model
                end
            end

            return original(self, missile, ...)
        end
    end

    -- Weapon.missile_hit: a bullet touched something. Bullets that were fired at a Killer ignore solid parts that
    -- are not Killers, so they fly through walls and reach the target. Bullets without a target behave normally.
    local function createMissileHitHook(original)
        return function(self, missile, moment, hitPart, ...)
            local lockedModel = missile ~= nil and silentAimMissileLocks[missile]

            if lockedModel
                and isSilentAimEnabled()
                and toggles.silentAimWallBang_Toggle.Value
                and isValidSilentAimTarget(lockedModel)
                and typeof(hitPart) == "Instance"
                and hitPart:IsA("BasePart")
                and hitPart.CanCollide
                and not findSilentAimTargetModelFromPart(hitPart)
            then
                return
            end

            return original(self, missile, moment, hitPart, ...)
        end
    end

    local function installSilentAimHook(record, object, key, createHook)
        local original = rawget(object, key)
        if type(original) ~= "function" then
            return
        end

        local hooked = createHook(original)
        object[key] = hooked
        table.insert(record.Hooks, { Key = key, Original = original, Hooked = hooked })
    end

    local function restoreSilentAimRecord(record)
        local object = record.Object

        for _, hook in ipairs(record.Hooks) do
            pcall(function()
                if rawget(object, hook.Key) == hook.Hooked then
                    object[hook.Key] = hook.Original
                end
            end)
        end

        table.clear(record.Hooks)
    end

    local function hookSilentAimWeaponTable(object)
        if library.Unloaded or type(object) ~= "table" or silentAimHookedObjects[object] then
            return
        end

        -- The base weapon class owns screen_to_target. A subclass set_missile shadows the base one, so it must be hooked as well or those
        -- bullets are never tied to the Killer they were fired at and Wallbang silently does nothing for them.
        local isWeaponBase = type(rawget(object, "screen_to_target")) == "function"
        local isMissileSubclass = type(rawget(object, "set_missile")) == "function"
            or type(rawget(object, "missile_hit")) == "function"

        if not isWeaponBase and not isMissileSubclass then
            return
        end

        local record = { Object = object, Hooks = {} }

        local success, hookError = pcall(function()
            if isWeaponBase then
                installSilentAimHook(record, object, "screen_to_target", createScreenToTargetHook)
                installSilentAimHook(record, object, "target_ray_callback", createRayCallbackHook)
                installSilentAimHook(record, object, "compute_inaccuracy", createInaccuracyHook)
            end

            installSilentAimHook(record, object, "set_missile", createSetMissileHook)
            installSilentAimHook(record, object, "missile_hit", createMissileHitHook)
        end)

        if success and #record.Hooks > 0 then
            silentAimHookedObjects[object] = true
            table.insert(silentAimHookRecords, record)
        else
            restoreSilentAimRecord(record)

            if not success then
                warn("[Silent Aim] Could not hook a weapon table: " .. tostring(hookError))
            end
        end
    end

    scanSilentAimWeaponTables = function()
        if type(getgc) ~= "function" then
            warn("[Silent Aim] This executor does not provide getgc(true); weapon hooks cannot be installed.")
            return false
        end

        -- Let the executor filter the huge amount of instances instead of handing back a million objects to search in Lua
        if type(filtergc) == "function" then
            local scanned = false

            -- The base weapon class first, then every subclass that overrides set_missile or missile_hit by itself.
            for _, keys in ipairs({ { "screen_to_target" }, { "set_missile" }, { "missile_hit" } }) do
                local filtered, matches = pcall(filtergc, "table", { Keys = keys }, false)

                if filtered and type(matches) == "table" then
                    scanned = true

                    for _, object in ipairs(matches) do
                        hookSilentAimWeaponTable(object)
                    end
                end
            end

            if scanned then
                return true
            end
        end

        local success, objects = pcall(getgc, true)
        if not success or type(objects) ~= "table" then
            warn("[Silent Aim] getgc(true) failed: " .. tostring(objects))
            return true
        end

        -- Walk the heap in slices so the scan is spread over several frames instead of one long one.
        for index = 1, #objects do
            hookSilentAimWeaponTable(objects[index])

            if index % 15000 == 0 then
                task.wait()

                if library.Unloaded then
                    return true
                end
            end
        end
        return true
    end

    -- Optional FOV drawing; Silent Aim remains usable if Drawing is unavailable.
    local silentAimFOVCircle
    local fovColorPicker = options.silentAimFOVColor_ColorPicker

    if type(Drawing) == "table" and type(Drawing.new) == "function" then
        local success, circle = pcall(Drawing.new, "Circle")
        if success then
            silentAimFOVCircle = circle
            silentAimFOVCircle.Visible = false
            silentAimFOVCircle.Transparency = 0.8
            silentAimFOVCircle.Color = fovColorPicker.Value
            silentAimFOVCircle.Thickness = 1
            silentAimFOVCircle.Filled = false
            silentAimFOVCircle.Radius = options.FOV_Slider.Value
        end
    end

    -- The rainbow loop writes into the color picker, so the circle only has to follow the picker.
    toggles.rainbowSilentAimFOVColor_Toggle:OnChanged(function(enabled)
        toggleRainbow(enabled, "silentAimFOVColor_ColorPicker")
    end)

    local silentAimFOVConnection = runService.RenderStepped:Connect(function()
        if not silentAimFOVCircle then
            return
        end

        local visible = isSilentAimEnabled() and toggles.silentAimShowFOV_Toggle.Value
        silentAimFOVCircle.Visible = visible

        if visible then
            silentAimFOVCircle.Color = fovColorPicker.Value
            silentAimFOVCircle.Radius = tonumber(options.FOV_Slider.Value) or 150
            silentAimFOVCircle.Position = uis:GetMouseLocation()
        end
    end)

    -- On unload: stop drawing, put the game's original weapon functions back, and remove the FOV circle.
    table.insert(teardownTasks, function()
        silentAimFOVConnection:Disconnect()

        for _, record in ipairs(silentAimHookRecords) do
            restoreSilentAimRecord(record)
        end

        table.clear(silentAimHookRecords)
        table.clear(silentAimHookedObjects)
        table.clear(silentAimMissileLocks)
        silentAimLock = nil

        if silentAimFOVCircle then
            pcall(function() silentAimFOVCircle:Remove() end)
            silentAimFOVCircle = nil
        end
    end)
end

-- [Exploits / Silent Aim] On-demand weapon table scanning
local silentAimScanQueued = false
local silentAimScanOwed = true
local silentAimConnections = {}

if type(getgc) ~= "function" then
    warn("[Silent Aim] This executor does not provide getgc(true); weapon hooks cannot be installed.")
end

local function requestSilentAimScan(delaySeconds)
    if library.Unloaded or type(getgc) ~= "function" then
        return
    end

    silentAimScanOwed = true

    if silentAimScanQueued then
        return
    end

    silentAimScanQueued = true

    task.delay(delaySeconds or 0, function()
        silentAimScanQueued = false

        -- While Silent Aim is off the scan stays owed and runs the moment it is switched on.
        if library.Unloaded or not silentAimScanOwed or not isSilentAimEnabled() then
            return
        end

        silentAimScanOwed = false
        scanSilentAimWeaponTables()
    end)
end

local function watchSilentAimContainer(container)
    if container then
        table.insert(silentAimConnections, container.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                requestSilentAimScan(2)
            end
        end))
    end
end

watchSilentAimContainer(localplayer:FindFirstChildOfClass("Backpack"))
watchSilentAimContainer(localplayer.Character)

table.insert(silentAimConnections, localplayer.ChildAdded:Connect(function(child)
    if child:IsA("Backpack") then
        watchSilentAimContainer(child)
        requestSilentAimScan(3)
    end
end))

table.insert(silentAimConnections, localplayer.CharacterAdded:Connect(function(character)
    watchSilentAimContainer(character)
    requestSilentAimScan(3)
end))

toggles.enableSilentAim_Toggle:OnChanged(function(enabled)
    if enabled then
        requestSilentAimScan(0)
    end
end)

-- Silent Aim is on but no weapon table has been hooked yet (e.g. the weapon scripts loaded late)
task.spawn(function()
    while not library.Unloaded do
        task.wait(15)

        if isSilentAimEnabled() and #silentAimHookRecords == 0 then
            requestSilentAimScan(0)
        end
    end
end)

if isSilentAimEnabled() then
    requestSilentAimScan(0)
end

table.insert(teardownTasks, function()
    for _, connection in ipairs(silentAimConnections) do
        connection:Disconnect()
    end

    table.clear(silentAimConnections)
end)

local aimbotConnection

-- [Exploits / Aimbot] Visibility helper

local function isVisible(targetPart)
    if not toggles.aimbotVisibilityCheck_Toggle.Value then
        return true
    end

    local char = localplayer.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local direction = (targetPart.Position - hrp.Position)

    local result = workspace:Raycast(hrp.Position, direction, params)

    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end

    return true
end

-- [Exploits / Aimbot] Target exclusion rules

local function isExcluded(killer)
    local excluded = options.aimbotExcludedKillers_Dropdown.Value

    if not excluded then return false end

    for name, enabled in pairs(excluded) do
        if enabled and killer.Name == name then
            return true
        end
    end

    return false
end

-- [Exploits / Aimbot] Closest target by world distance

local function getClosestKiller()

    local closest = nil
    local shortestDistance = math.huge

    local char = localplayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local maxDistance = options.aimbotMaximumDistance_Slider.Value
    local partName = options.aimbotHitPart_Dropdown.Value

    for _, killer in pairs(killersFolder:GetChildren()) do

        if isKillerAlive(killer) and not isExcluded(killer) then

            local targetPart = killer:FindFirstChild(partName, true)

            if targetPart then

                local dist = (hrp.Position - targetPart.Position).Magnitude

                if dist <= maxDistance and isVisible(targetPart) then
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closest = targetPart
                    end
                end

            end
        end
    end

    return closest
end

-- [Exploits / Aimbot] Closest target to cursor

local function getClosestToCursor()

    local closest = nil
    local shortestDistance = math.huge

    local mousePos = uis:GetMouseLocation()
    local partName = options.aimbotHitPart_Dropdown.Value

    local char = localplayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local maxDistance = options.aimbotMaximumDistance_Slider.Value

    for _, killer in pairs(killersFolder:GetChildren()) do

        if isKillerAlive(killer) and not isExcluded(killer) then

            local targetPart = killer:FindFirstChild(partName, true)

            if targetPart then

                local dist3D = (hrp.Position - targetPart.Position).Magnitude

                if dist3D <= maxDistance and isVisible(targetPart) then

                    local screenPos, visible = camera:WorldToViewportPoint(targetPart.Position)

                    if visible then

                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                        if dist2D < shortestDistance then
                            shortestDistance = dist2D
                            closest = targetPart
                        end

                    end
                end
            end
        end
    end

    return closest
end

-- [Exploits / Aimbot] Render-step connection lifecycle

toggles.enableAimbot_Toggle:OnChanged(function(state)

    if state then

        aimbotConnection = runService.RenderStepped:Connect(function()

            local target

            if not options.aimbotTargetType_Dropdown then return end
            local targetType = options.aimbotTargetType_Dropdown.Value

            if targetType == "Closest" then
                target = getClosestKiller()
            else
                target = getClosestToCursor()
            end

            if target then

                local char = localplayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if hrp then
                    local maxDistance = options.aimbotMaximumDistance_Slider.Value
                    local dist = (hrp.Position - target.Position).Magnitude

                    -- Enforce distance check while tracking
                    if dist <= maxDistance then

                        local camPos = camera.CFrame.Position
                        local goal = CFrame.new(camPos, target.Position)

                        local smoothing = options.aimbotSmoothing_Slider.Value
                        local alpha = math.clamp(1 / smoothing * 50, 0, 1)

                        camera.CFrame = camera.CFrame:Lerp(goal, alpha)
                    end
                end
            end
        end)
    else

        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end)

-- [Exploits / Collection] Recognized ingredient names
local collectibles = {
    Gem = true,
    Antenna = true,
    Bone = true,
    Brain = true,
    Claw = true,
    Fabric = true,
    Fur = true,
    Glass = true,
    Hair = true,
    Horn = true,
    Ice = true,
    Metal = true,
    Plastic = true,
    Pumpkin = true,
    ["Red Light"] = true,
    Ribbon = true,
    Rubber = true,
    Skin = true,
    Slime = true,
    Spike = true,
    Tentacle = true,
    Tie = true,
    Wood = true
}

local autoCollectRunning = false

-- [Exploits / Collection] Touch helper
local autoCollectInFlight = setmetatable({}, { __mode = "k" })

local function collectIngredients(hrp)
    local touching = {}

    for _, obj in ipairs(workspace:GetChildren()) do
        if (obj:IsA("Part") or obj:IsA("MeshPart")) and collectibles[obj.Name] and not autoCollectInFlight[obj] then
            -- Touch-begin. Skipped silently when the part is not in the physics world yet; the next sweep retries it.
            if hrp:IsDescendantOf(workspace) and pcall(firetouchinterest, hrp, obj, 0) then
                autoCollectInFlight[obj] = true
                table.insert(touching, obj)
            end
        end
    end

    if #touching == 0 then
        return
    end

    task.wait()

    for _, obj in ipairs(touching) do
        autoCollectInFlight[obj] = nil

        -- Touch-end only if both parts survived the yield.
        if obj:IsDescendantOf(workspace) and hrp:IsDescendantOf(workspace) then
            pcall(firetouchinterest, hrp, obj, 1)
        end
    end
end

-- [Exploits / Collection] Collection loop and toggle callback
toggles.autoCollect_Toggle:OnChanged(function(state)
    autoCollectRunning = state

    if state then
        task.spawn(function()
            while autoCollectRunning and not library.Unloaded do
                local hrp = getHRP()

                if hrp then
                    collectIngredients(hrp)
                end

                task.wait(0.2)
            end
        end)
    end
end)

-- [Exploits / Killer Controls] Disable Aura and defensive toggles

-- [Exploits / Killer Controls] Disable Aura

killersGroup:AddToggle("disableAllKillers_Toggle", { Text = "Disable Aura", Tooltip = "Deals with all nearby killers within the specified amount of studs, using the selected method." })

local disableKillersDepbox = killersGroup:AddDependencyBox()
disableKillersDepbox:AddDropdown("disableAuraMethod_Dropdown", { Text = "Method", Tooltip = false, Values = { "Kill", "Disable Movement", "Disable Humanoid", "Push" }, Default = 4, Multi = false, Searchable = false })
disableKillersDepbox:AddSlider("disableKillersDistance_Slider", { Text = "Range", Tooltip = "How far away to disable killers", Default = 20, Min = 10, Max = 100, Suffix = " Studs", Rounding = 0 })
disableKillersDepbox:AddToggle("disableAuraWallCheck_Toggle", { Text = "Wall Check", Tooltip = "Only affects Killers that are visible. Killers behind walls are left alone. Emergency Kill ignores this.", Default = false })
disableKillersDepbox:AddLabel("Emergency Kill"):AddKeyPicker("emergencyKill_KeyPicker", { Text = "Emergency Kill", Default = "X", Mode = "Hold", NoUI = true, Disabled = true })
disableKillersDepbox:AddToggle("disableAuraDebugNotifs_Toggle", { Text = "Debug Notifications", Tooltip = "Sends a notification each time Disable Aura kills, disables or starts pushing a killer." })
disableKillersDepbox:AddDivider()

-- [Exploits / Killer Controls] Defensive toggles

killersGroup:AddToggle("killerGodmode_Toggle", { Text = "Killer Godmode", Tooltip = "Makes you invincible to the killers by blocking killer interactions.." })

local killerGodmodeDepbox = killersGroup:AddDependencyBox()
killerGodmodeDepbox:AddToggle("antiPinhead_Toggle", { Text = "Anti Pinhead", Tooltip = "Disables (mostly) Pinhead's spikes that he expels upon death." })
killerGodmodeDepbox:AddLabel("Covers what your client reports or detects itself: touch hitboxes, Freddy's nightmare (snakes, bugs and the hole), Chucky's jump attack and Pinhead's spikes. Attacks the server checks on its own, like Alien's arm and Yeti's ice slam, can not be blocked from the client. Use Disable Aura against those.", true)
killerGodmodeDepbox:AddDivider()

killersGroup:AddToggle("antiSlendermanJumpscare_Toggle", { Text = "Anti Slenderman Jumpscare", Tooltip = false })

-- [Exploits / Killer Controls] Slenderman teleport check
do
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include

    utils.slendermanCanTeleportBehind = function(position, lookVector)
        -- His checks only see the facility and its doors
        local filter = {}

        for _, name in ipairs({ "AREA51", "Doors" }) do
            local instance = workspace:FindFirstChild(name)

            if instance then
                table.insert(filter, instance)
            end
        end

        raycastParams.FilterDescendantsInstances = filter

        local behind = position - lookVector * Vector3.new(1, 0, 1) * 15 + Vector3.new(0, 1.5, 0)

        if workspace:Raycast(position, behind - position, raycastParams) then
            return false
        end

        local floor = workspace:Raycast(behind, Vector3.new(0, -10, 0), raycastParams)

        if not (floor and floor.Instance.CanCollide) then
            return false
        end

        return workspace:Raycast(behind, Vector3.new(0, 2.5, 0), raycastParams) == nil
    end
end

-- [Exploits / Killer Controls] Slenderman Safe Facing
do
    killersGroup:AddToggle("slendermanSafeFacing_Toggle", { Text = "Slenderman Safe Facing", Tooltip = "While Slenderman is near, keeps you facing a direction where he cannot teleport behind you (a wall or no floor behind you). Your character stops turning on its own while this holds a facing. Does nothing where no such direction exists." })

    local safeFacingDepbox = killersGroup:AddDependencyBox()
    safeFacingDepbox:AddSlider("slendermanSafeFacingDistance_Slider", { Text = "Minimum Distance", Tooltip = "Safe Facing only takes over your facing while Slenderman is closer to you than this. He starts targeting players from 200 studs away, so the maximum covers everything he can do. Lower it to keep control of your character until he gets close.", Default = 200, Min = 50, Max = 200, Suffix = " Studs", Rounding = 0 })
    safeFacingDepbox:AddDivider()
    safeFacingDepbox:SetupDependencies({ { toggles.slendermanSafeFacing_Toggle, true } })

    -- The margin covers him closing in between two checks, it is added on top of the slider
    local distanceMargin = 50

    local facing = {
        connection = nil,
        humanoid = nil,     -- the humanoid whose AutoRotate was switched off by this feature
        autoRotate = nil,   -- the AutoRotate value to give back
        lastError = nil,
    }

    local function release()
        local humanoid = facing.humanoid

        if humanoid and humanoid.Parent and facing.autoRotate ~= nil then
            humanoid.AutoRotate = facing.autoRotate
        end

        facing.humanoid = nil
        facing.autoRotate = nil
    end

    local function hold(humanoid)
        if facing.humanoid ~= humanoid then
            release()
            facing.humanoid = humanoid
            facing.autoRotate = humanoid.AutoRotate
        end

        humanoid.AutoRotate = false
    end

    local function getSlendermanRoot()
        local folder = workspace:FindFirstChild("Killers")
        local model = folder and folder:FindFirstChild("Slenderman")
        local root = model and model:FindFirstChild("HumanoidRootPart")

        if model and root and isKillerAlive(model) then
            return root
        end

        return nil
    end

    local function step()
        local hrp = getHRP()
        local humanoid = getHumanoid()
        local slendermanRoot = getSlendermanRoot()

        if not (hrp and humanoid and humanoid.Health > 0 and slendermanRoot and (slendermanRoot.Position - hrp.Position).Magnitude <= options.slendermanSafeFacingDistance_Slider.Value + distanceMargin) then
            release()
            return
        end

        local look = hrp.CFrame.LookVector
        local currentLook = Vector3.new(look.X, 0, look.Z)

        if currentLook.Magnitude < 0.001 then
            return
        end

        currentLook = currentLook.Unit

        -- Already facing a direction he cannot use: keep it
        if not utils.slendermanCanTeleportBehind(hrp.Position, currentLook) then
            hold(humanoid)
            return
        end

        -- Otherwise turn to the blocked direction that is closest to where you are facing
        local bestLook, bestAngle = nil, math.huge

        for i = 0, 35 do
            local angle = math.rad(i * 10)
            local candidate = Vector3.new(math.sin(angle), 0, math.cos(angle))

            if not utils.slendermanCanTeleportBehind(hrp.Position, candidate) then
                local difference = math.acos(math.clamp(candidate:Dot(currentLook), -1, 1))

                if difference < bestAngle then
                    bestLook, bestAngle = candidate, difference
                end
            end
        end

        if not bestLook then
            -- Open ground in every direction: there is nothing to turn to
            release()
            return
        end

        hold(humanoid)
        hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + bestLook)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    local function stop()
        if facing.connection then
            facing.connection:Disconnect()
            facing.connection = nil
        end

        release()
    end

    toggles.slendermanSafeFacing_Toggle:OnChanged(function(enabled)
        stop()

        if not enabled then
            return
        end

        -- Every frame: the facing can be checked by the server at any moment, so the gap between corrections has to be as small as possible
        facing.connection = runService.Heartbeat:Connect(function()
            if library.Unloaded or not toggles.slendermanSafeFacing_Toggle.Value then
                stop()
                return
            end

            local ok, err = pcall(step)

            if not ok and err ~= facing.lastError then
                facing.lastError = err
                warn("[Slenderman Safe Facing] " .. tostring(err))
            end
        end)
    end)
end

killerGodmodeDepbox:SetupDependencies({ { toggles.killerGodmode_Toggle, true } })
disableKillersDepbox:SetupDependencies({ { toggles.disableAllKillers_Toggle, true } })

-- [Exploits / Killer Controls] Auto Safe Spot
do
    killersGroup:AddToggle("autoSafeSpot_Toggle", { Text = "Auto Safe Spot", Tooltip = "Teleports you to the nearest safe spot when your health is low and a killer is close, then returns you once your original position is safe again." })

    local autoSafeSpotDepbox = killersGroup:AddDependencyBox()
    autoSafeSpotDepbox:AddSlider("autoSafeSpotHealth_Slider", { Text = "Health Threshold", Tooltip = "You are teleported to a safe spot once your health is at or below this while a killer is within the safe radius.", Default = 60, Min = 30, Max = 100, Suffix = " HP", Rounding = 0 })
    autoSafeSpotDepbox:AddSlider("autoSafeSpotRadius_Slider", { Text = "Safe Radius", Tooltip = "A killer has to be at least this far away for a safe spot (or your original position) to count as safe.", Default = 50, Min = 20, Max = 200, Suffix = " Studs", Rounding = 0 })
    autoSafeSpotDepbox:AddToggle("autoSafeSpotSpectate_Toggle", { Text = "Spectate Killer", Tooltip = "While hiding, spectates the killer you are avoiding so you can see what it is doing." })
    local settings = toggles.autoSafeSpotSpectate_Toggle:AddSettings({
        Width = 220,
    })

    settings:AddSlider("AimbotFOV", {
        Text = "FOV",
        Default = 90,
        Min = 10,
        Max = 360,
        Rounding = 0,
    })

    autoSafeSpotDepbox:AddToggle("autoSafeSpotSlenderman_Toggle", { Text = "Flee Slenderman", Tooltip = "Hides as soon as Slenderman is chasing you and within the minimum distance, no matter your health. He can teleport behind you from up to 200 studs away, so waiting for low health is too late." })

    local slendermanDepbox = autoSafeSpotDepbox:AddDependencyBox()
    slendermanDepbox:AddSlider("autoSafeSpotSlendermanDistance_Slider", { Text = "Minimum Distance", Tooltip = "Slenderman has to be at least this far from you for you to be safe: you flee once he is chasing you from closer than this, and only return once he is this far from your original position.", Default = 50, Min = 50, Max = 200, Suffix = " Studs", Rounding = 0 })
    slendermanDepbox:SetupDependencies({ { toggles.autoSafeSpotSlenderman_Toggle, true } })

    autoSafeSpotDepbox:AddDivider()
    autoSafeSpotDepbox:SetupDependencies({ { toggles.autoSafeSpot_Toggle, true } })

    -- Predefined spots where no killers spawn.
    local safeSpots = {
        { name = "Bedroom", position = Vector3.new(109.70925903320312, 335.4999694824219, 62.200706481933594) },
        { name = "Surface", position = Vector3.new(326.0870666503906, 511.6999816894531, 392.97576904296875) },
        { name = "Execution Room", position = Vector3.new(20.30820083618164, 313.50030517578125, 202.9387969970703) },
        { name = "Isolation Vault", position = Vector3.new(301.66265869140625, 271.7003173828125, 143.39537048339844) },
        { name = "Vent 1", position = Vector3.new(195.15359497070312, 343.4999694824219, 113.28348541259766) },
        { name = "Vent 2", position = Vector3.new(204.2087860107422, 337.3002014160156, 290.872314453125) },
        { name = "Bunker", position = Vector3.new(161.3929901123047, 239.70028686523438, 427.53143310546875) },
        { name = "Cleaner Two", position = Vector3.new(180.0406494140625, 271.7001953125, 94.63085174560547) },
        { name = "Vault", position = Vector3.new(27.61656951904297, 291.5000915527344, 240.07852172851562) },
        { name = "Helpful Killers Room", position = Vector3.new(119.75243377685547, 325.4999694824219, 370.15093994140625) },
    }

    -- Extra distance Slenderman has to be from your original position before you return, so you do not flee, return and flee again
    local slendermanReturnBuffer = 15

    local state = {
        loopId = 0,           -- bumped on every toggle change so an old loop can never keep running next to a new one
        hiding = false,
        character = nil,      -- the character the hide started on (a different one means you died or respawned)
        origin = nil,         -- CFrame from before the first teleport, where you return to
        spot = nil,           -- the safe spot you are currently at
        spectateSubject = nil, -- what the camera was pointed at by this feature (so it only hands back what it took)
        notification = nil,
        shownKiller = nil,    -- what the notification currently shows, so it is only touched when something changed
        shownText = nil,
        lastUpdate = 0,
        lastError = nil,
        proofCache = {},      -- spot -> { proof, time }: whether Slenderman can teleport behind you at that spot at all
    }

    -- Living killers with the position of their root part
    local function getAliveKillers()
        local list = {}
        local folder = workspace:FindFirstChild("Killers")

        if not folder then
            return list
        end

        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") and isKillerAlive(model) then
                local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart

                if root then
                    table.insert(list, { name = model.Name, position = root.Position, model = model })
                end
            end
        end

        return list
    end

    -- Closest killer to a position and how far away it is (nil and math.huge when no killer is alive)
    local function getNearestKiller(position, killers)
        local nearest, nearestDistance = nil, math.huge

        for _, killer in ipairs(killers) do
            local distance = (killer.position - position).Magnitude

            if distance < nearestDistance then
                nearest, nearestDistance = killer, distance
            end
        end

        return nearest, nearestDistance
    end

    -- True when no direction at this spot lets Slenderman teleport behind you (checked on 36 facings, cached because spots do not move)
    local function isTeleportProof(spot)
        local canTeleport = utils.slendermanCanTeleportBehind

        if not canTeleport then
            return false
        end

        local now = os.clock()
        local cached = state.proofCache[spot]

        if cached and now - cached.time < 10 then
            return cached.proof
        end

        local proof = true

        for i = 0, 35 do
            local angle = math.rad(i * 10)

            if canTeleport(spot.position, Vector3.new(math.sin(angle), 0, math.cos(angle))) then
                proof = false
                break
            end
        end

        state.proofCache[spot] = { proof = proof, time = now }

        return proof
    end

    -- How far Slenderman has to be. spot is the safe spot in question, or nil for your own position; forReturn adds the return buffer.
    local function getSlendermanRequired(radius, spot, forReturn)
        if not toggles.autoSafeSpotSlenderman_Toggle.Value then
            return radius
        end

        -- Walled in on every side he cannot teleport onto you, he has to walk, so the normal radius is enough
        if spot and isTeleportProof(spot) then
            return radius
        end

        local minimum = options.autoSafeSpotSlendermanDistance_Slider.Value + (forReturn and slendermanReturnBuffer or 0)

        return math.max(radius, minimum)
    end

    -- How much room you have at a position: the smallest of (distance to a killer - distance that killer has to keep). Negative means unsafe.
    -- Also returns the killer that limits it and the distance that killer has to keep.
    local function getMargin(position, killers, radius, slendermanRequired)
        local margin, limiting, limitingRequired = math.huge, nil, radius

        for _, killer in ipairs(killers) do
            local required = killer.name == "Slenderman" and slendermanRequired or radius
            local killerMargin = (killer.position - position).Magnitude - required

            if killerMargin < margin then
                margin, limiting, limitingRequired = killerMargin, killer, required
            end
        end

        return margin, limiting, limitingRequired
    end

    -- Returns spot, isSafe, margin. Prefers the safe spot nearest to you; when none is safe it falls back to the spot with the most room.
    local function pickSafeSpot(fromPosition, killers, radius)
        local bestSafe, bestSafeDistance = nil, math.huge
        local bestFallback, bestFallbackMargin = nil, -math.huge

        for _, spot in ipairs(safeSpots) do
            local margin = getMargin(spot.position, killers, radius, getSlendermanRequired(radius, spot, false))

            if margin >= 0 then
                local distance = (spot.position - fromPosition).Magnitude

                if distance < bestSafeDistance then
                    bestSafe, bestSafeDistance = spot, distance
                end
            elseif margin > bestFallbackMargin then
                bestFallback, bestFallbackMargin = spot, margin
            end
        end

        if bestSafe then
            return bestSafe, true, math.huge
        end

        return bestFallback, false, bestFallbackMargin
    end

    -- Slenderman chasing you from closer than the minimum distance (FollowingTorso is the root part of the player he is going after)
    local function getChasingSlenderman(hrp, killers)
        if not toggles.autoSafeSpotSlenderman_Toggle.Value then
            return nil
        end

        local minimum = options.autoSafeSpotSlendermanDistance_Slider.Value

        for _, killer in ipairs(killers) do
            if killer.name == "Slenderman" then
                local following = killer.model:FindFirstChild("FollowingTorso")
                local distance = (killer.position - hrp.Position).Magnitude

                if following and following.Value == hrp and distance <= minimum then
                    return killer, distance
                end
            end
        end

        return nil
    end

    local function teleportTo(cframe)
        local hrp = getHRP()

        if not hrp then
            return
        end

        entityLib.teleport(cframe)

        -- Do not carry momentum from before the teleport into the new spot
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    -- Points the camera at a killer (an entry from getAliveKillers), or gives it back to your own character when passed nil.
    -- It only returns the camera back if it is still on what this set, so a feature that took the camera since is not overridden.
    local function setSpectating(killer)
        local subject = killer and (killer.model:FindFirstChildOfClass("Humanoid") or killer.model:FindFirstChild("HumanoidRootPart"))

        if subject then
            if camera.CameraSubject ~= subject then
                camera.CameraSubject = subject
            end

            state.spectateSubject = subject
        elseif state.spectateSubject then
            local humanoid = getHumanoid()

            if humanoid and camera.CameraSubject == state.spectateSubject then
                camera.CameraSubject = humanoid
            end

            state.spectateSubject = nil
        end
    end

    local function buildDescription(spotName, spotIsSafe, killerName, killerDistance, required)
        return string.format(
            "Hiding at %s%s. Returning once %s is %d studs away from your original position (currently %d).",
            spotName,
            spotIsSafe and "" or " (no fully safe spot, this is the least dangerous)",
            killerName,
            math.floor(required),
            math.floor(killerDistance)
        )
    end

    local function updateNotification(killerName, killerDistance, required, spotIsSafe)
        local notification = state.notification

        -- Dismissing the notification by hand does not stop the hide, it just stops updating
        if not notification or notification.Destroyed then
            return
        end

        local now = os.clock()

        if now - state.lastUpdate < 0.25 then
            return
        end

        state.lastUpdate = now

        if killerName ~= state.shownKiller then
            notification:ChangeTitle("Avoiding " .. killerName)
            state.shownKiller = killerName
        end

        local description = buildDescription(state.spot.name, spotIsSafe, killerName, killerDistance, required)

        if description ~= state.shownText then
            notification:ChangeDescription(description)
            state.shownText = description
        end
    end

    -- Ends the hide. returnToOrigin is false when you died, respawned or turned the feature off.
    local function stopHiding(returnToOrigin)
        setSpectating(nil)
        utils.dismissNotify(state.notification)

        if returnToOrigin and state.origin then
            teleportTo(state.origin)
        end

        state.hiding = false
        state.character = nil
        state.origin = nil
        state.spot = nil
        state.notification = nil
        state.shownKiller = nil
        state.shownText = nil
    end

    local function beginHiding(hrp, killers, killer, killerDistance, radius)
        local spot, isSafe, margin = pickSafeSpot(hrp.Position, killers, radius)

        if not spot then
            return
        end

        -- No fully safe spot and none that beats where you are standing: moving would not help
        if not isSafe then
            local currentMargin = getMargin(hrp.Position, killers, radius, getSlendermanRequired(radius, nil, false))

            if margin <= currentMargin then
                return
            end
        end

        state.hiding = true
        state.character = localplayer.Character
        state.origin = hrp.CFrame
        state.spot = spot

        teleportTo(CFrame.new(spot.position))

        local required = killer.name == "Slenderman" and getSlendermanRequired(radius, nil, true) or radius
        local description = buildDescription(spot.name, isSafe, killer.name, killerDistance, required)

        state.shownKiller = killer.name
        state.shownText = description
        state.lastUpdate = os.clock()
        state.notification = notify("Info", "Avoiding " .. killer.name, description, 5, true)
    end

    local function step()
        local character = localplayer.Character
        local humanoid = getHumanoid()
        local hrp = getHRP()

        -- Died or respawned while hiding: the original position belongs to a character that no longer exists
        if state.hiding and (character ~= state.character or not humanoid or not hrp or humanoid.Health <= 0) then
            stopHiding(false)
            return
        end

        if not humanoid or not hrp or humanoid.Health <= 0 then
            return
        end

        local radius = options.autoSafeSpotRadius_Slider.Value
        local killers = getAliveKillers()

        if not state.hiding then
            -- Slenderman teleports behind you from far away, so this does not wait for low health
            local slenderman, slendermanDistance = getChasingSlenderman(hrp, killers)

            if slenderman then
                beginHiding(hrp, killers, slenderman, slendermanDistance, radius)

                if state.hiding then
                    return
                end
            end

            if humanoid.Health > options.autoSafeSpotHealth_Slider.Value then
                return
            end

            local nearest, distance = getNearestKiller(hrp.Position, killers)

            if nearest and distance <= radius then
                beginHiding(hrp, killers, nearest, distance, radius)
            end

            return
        end

        -- Hiding: first check whether the original position is clear again
        local originMargin, avoided, avoidedRequired = getMargin(state.origin.Position, killers, radius, getSlendermanRequired(radius, nil, true))

        if originMargin >= 0 then
            stopHiding(true)
            return
        end

        local avoidedDistance = (avoided.position - state.origin.Position).Magnitude

        -- The spot itself can become unsafe as killers move, so move on to another one
        local currentMargin = getMargin(hrp.Position, killers, radius, getSlendermanRequired(radius, state.spot, false))
        local spotIsSafe = currentMargin >= 0

        if not spotIsSafe then
            local spot, isSafe, margin = pickSafeSpot(hrp.Position, killers, radius)

            -- The margin keeps two equally bad spots from bouncing you back and forth
            if spot and spot ~= state.spot and (isSafe or margin > currentMargin + 5) then
                state.spot = spot
                spotIsSafe = isSafe
                teleportTo(CFrame.new(spot.position))
            end
        end

        setSpectating(toggles.autoSafeSpotSpectate_Toggle.Value and avoided or nil)
        updateNotification(avoided.name, avoidedDistance, avoidedRequired, spotIsSafe)
    end

    toggles.autoSafeSpot_Toggle:OnChanged(function(enabled)
        state.loopId += 1
        local loopId = state.loopId

        if not enabled then
            -- Turned off mid-hide: you stay where you are (going back could put you in front of the killer)
            stopHiding(false)
            return
        end

        task.spawn(function()
            while toggles.autoSafeSpot_Toggle.Value and state.loopId == loopId and not library.Unloaded do
                local ok, err = pcall(step)

                if not ok and err ~= state.lastError then
                    state.lastError = err
                    warn("[Auto Safe Spot] " .. tostring(err))
                end

                task.wait(0.05)
            end

            if library.Unloaded then
                stopHiding(false)
            end
        end)
    end)
end

-- [Exploits / Killer Controls] Disable Aura: Wall Check helper
do
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    -- Only solid parts count as walls, so invisible triggers and other non-collidable parts never hide a killer
    params.RespectCanCollide = true

    local lastBuilt = 0
    local lastCharacter = nil

    -- Rays must look straight through every killer and every character, so only the map can block them
    local function refreshFilter()
        local now = os.clock()
        local character = localplayer.Character

        if now - lastBuilt < 0.25 and character == lastCharacter then
            return
        end

        lastBuilt = now
        lastCharacter = character

        local filter = { killersFolder }

        for _, player in ipairs(players:GetPlayers()) do
            if player.Character then
                table.insert(filter, player.Character)
            end
        end

        local folder = character and character.Parent

        if folder and folder ~= workspace then
            table.insert(filter, folder)
        end

        params.FilterDescendantsInstances = filter
    end

    -- A killer is visible when a straight line from `origin` to its body or its head has no wall in the way
    utils.isKillerVisible = function(origin, model, root)
        refreshFilter()

        if not workspace:Raycast(origin, root.Position - origin, params) then
            return true
        end

        local head = model:FindFirstChild("Head")

        if head and head:IsA("BasePart") and not workspace:Raycast(origin, head.Position - origin, params) then
            return true
        end

        return false
    end
end

local affectedKillers = {}
local proximityRange = options.disableKillersDistance_Slider.Value

-- Gives a killer its movement back and stops tracking it
local function releaseKiller(hum)
    if affectedKillers[hum] == "Disable Movement" then
        pcall(function()
            entityLib.restoreData(hum, "WalkSpeed")
            entityLib.restoreData(hum, "JumpPower")
            entityLib.clearData(hum, "WalkSpeed")
            entityLib.clearData(hum, "JumpPower")
        end)
    end

    affectedKillers[hum] = nil
end

local function updateKiller(hum, model, method, inRange, visible)
    if hum.Health <= 0 then
        if affectedKillers[hum] then
            releaseKiller(hum)
        end

        return
    end

    -- Restore if leaving range
    if not inRange and affectedKillers[hum] == "Disable Movement" then
        releaseKiller(hum)
        if toggles.disableAuraDebugNotifs_Toggle.Value then
            notify("Info", "Successful restore", "Restored " .. model.Name .. "'s movement.", 3)
        end
    end

    -- Skip if not in range
    if not inRange then return end

    -- Skip if method already applied
    if affectedKillers[hum] == method then return end

    -- Wall Check: killers behind walls are left alone
    if visible == false then return end

    -- Restore previous movement if switching methods
    if affectedKillers[hum] == "Disable Movement" then
        releaseKiller(hum)
    end

    -- Apply new method
    if method == "Kill" then
        hum.Health = 0
        if toggles.disableAuraDebugNotifs_Toggle.Value then
            notify("Info", "Disable Aura", "Killed " .. model.Name, 3)
        end
    elseif method == "Disable Movement" then
        if not entityLib.isStored(hum, "WalkSpeed") then
            entityLib.storeData(hum, "WalkSpeed", true)
        end
        if not entityLib.isStored(hum, "JumpPower") then
            entityLib.storeData(hum, "JumpPower", true)
        end
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        if toggles.disableAuraDebugNotifs_Toggle.Value then
            notify("Info", "Disable Aura", "Disabled " .. model.Name .. "'s movement.", 3)
        end
    elseif method == "Disable Humanoid" then
        hum:Destroy()
        if toggles.disableAuraDebugNotifs_Toggle.Value then
            notify("Info", "Disable Aura", "Disabled " .. model.Name .. "'s humanoid.", 3)
        end
    end

    affectedKillers[hum] = method
end

-- Set by the Push block further down
local pushToggled

-- [Exploits / Killer Controls] Disable Aura: Emergency Kill (Hold)
-- While the key is held, every killer inside the Range is killed, whatever Method is selected.
do
    local loopId = 0
    local lastError = nil

    local function step()
        local keypicker = options.emergencyKill_KeyPicker

        -- Hold mode: GetState() is only true while the key is physically down. Typing in chat must not trigger it.
        if not keypicker or keypicker.Disabled or uis:GetFocusedTextBox() or not keypicker:GetState() then
            return
        end

        local hrp = getHRP()
        if not hrp then
            return
        end

        local range = proximityRange or 30

        for _, model in ipairs(killersFolder:GetChildren()) do
            if not model:IsA("Model") then
                continue
            end

            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")

            if hum and root and hum.Health > 0 and entityLib.getEntityDistance(hrp, root) <= range then
                hum.Health = 0

                if toggles.disableAuraDebugNotifs_Toggle.Value then
                    notify("Info", "Emergency Kill", "Killed " .. model.Name, 3)
                end
            end
        end
    end

    utils.emergencyKillToggled = function(enabled)
        local keypicker = options.emergencyKill_KeyPicker

        if keypicker then
            pcall(keypicker.SetDisabled, keypicker, not enabled)
            pcall(keypicker.SetNoUI, keypicker, not enabled)
        end

        -- Invalidates any previous loop
        loopId += 1
        local myLoopId = loopId

        if enabled then
            task.spawn(function()
                while toggles.disableAllKillers_Toggle.Value and loopId == myLoopId and not library.Unloaded do
                    local ok, err = pcall(step)

                    if not ok and err ~= lastError then
                        lastError = err
                        warn("[Disable Aura: Emergency Kill] " .. tostring(err))
                    end

                    task.wait()
                end
            end)
        end
    end
end

toggles.disableAllKillers_Toggle:OnChanged(function(enabled)
    utils.emergencyKillToggled(enabled)

    if pushToggled then
        pushToggled(enabled)
    end

    if enabled then
        task.spawn(function()
            while toggles.disableAllKillers_Toggle.Value do
                local hrp = getHRP()
                if not hrp then
                    task.wait(0.3)
                    continue
                end

                local method = tostring(options.disableAuraMethod_Dropdown.Value)
                local range = proximityRange or 30

                -- Push runs every frame in its own loop (see Disable Aura: Push). Nothing is applied from here, and whatever another method applied is given back.
                if method == "Push" then
                    for trackedHum in pairs(affectedKillers) do
                        releaseKiller(trackedHum)
                    end

                    task.wait(0.15)
                    continue
                end

                -- Forget killers that are gone (removed corpses, destroyed humanoids)
                for trackedHum in pairs(affectedKillers) do
                    if not trackedHum:IsDescendantOf(killersFolder) then
                        releaseKiller(trackedHum)
                    end
                end

                for _, model in ipairs(killersFolder:GetChildren()) do
                    if not model:IsA("Model") then
                        continue
                    end
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    local root = model:FindFirstChild("HumanoidRootPart")
                    if hum and root then
                        local distance = entityLib.getEntityDistance(hrp, root)
                        local inRange = distance <= range
                        local visible = true

                        if inRange and affectedKillers[hum] ~= method and toggles.disableAuraWallCheck_Toggle.Value then
                            visible = utils.isKillerVisible(hrp.Position, model, root)
                        end

                        updateKiller(hum, model, method, inRange, visible)
                    end
                end

                task.wait(0.15)
            end
        end)
    else
        -- Restore movement for all affected killers when toggled off
        for hum, method in pairs(affectedKillers) do
            if hum and method == "Disable Movement" then
                entityLib.restoreData(hum, "WalkSpeed")
                entityLib.restoreData(hum, "JumpPower")
                entityLib.clearData(hum, "WalkSpeed")
                entityLib.clearData(hum, "JumpPower")
            end
        end
        affectedKillers = {}
    end
end)

options.disableKillersDistance_Slider:OnChanged(function(val)
    proximityRange = val
end)

-- [Exploits / Killer Controls] Disable Aura: Push
do
    local PUSH_MAX_SPEED = 170      -- studs per second at the centre of the range, and for a killer that just teleported next to you
    local PUSH_DECAY = 7            -- how quickly a throw loses speed once the killer is out of range (per second)
    local PUSH_MAX_STEP = 6         -- the most a killer can be moved in a single frame, whatever the speed
    local TELEPORT_JUMP = 12        -- a killer that moves further than this in one frame without our help has teleported (Slenderman)
    local WALL_MARGIN = 0.25        -- studs kept between a killer and the wall that stopped it
    local CAST_BACKOFF = 0.3        -- the box check starts this far behind the killer
    local STEP_CLEARANCE = 0.8      -- wall checks start this far above the feet, so steps and the floor itself never count as walls
    local GROUND_CHECK = 12         -- floor has to exist within this many studs under the new spot, so killers are never shoved off a ledge

    local castParams = RaycastParams.new()
    castParams.FilterType = Enum.RaycastFilterType.Exclude
    castParams.RespectCanCollide = true
    castParams.IgnoreWater = true
    -- Only count what killers actually collide with, so invisible triggers and other non-solid parts never stop one
    pcall(function()
        castParams.CollisionGroup = "Killers"
    end)

    local shapes = setmetatable({}, { __mode = "k" })

    -- How big the wall checks have to be for a killer: its width, how far its feet are under the root part and how far its head is above it
    local function getShape(model, root)
        local shape = shapes[model]

        if shape then
            return shape
        end

        local bottom, top, width = 3.5, 3, 3
        local ok, boxCFrame, boxSize = pcall(model.GetBoundingBox, model)

        if ok then
            local rootY = root.Position.Y
            bottom = math.clamp(rootY - (boxCFrame.Position.Y - boxSize.Y / 2), 1.5, 8)
            top = math.clamp((boxCFrame.Position.Y + boxSize.Y / 2) - rootY, 1, 8)
            width = math.clamp(math.min(boxSize.X, boxSize.Z) * 0.6, 1.6, 6)
        end

        shape = { bottom = bottom, top = top, width = width }
        shapes[model] = shape

        return shape
    end

    -- How far (0 to `distance`) a killer standing at `origin` can move along the flat direction `dir` before a wall stops it, and what stopped it.
    local function castStep(origin, shape, dir, distance)
        local low = origin.Y - shape.bottom + STEP_CLEARANCE
        local high = origin.Y + shape.top * 0.9
        local radius = shape.width / 2
        local allowed = distance
        local blocker = nil

        local center = Vector3.new(origin.X, (low + high) / 2, origin.Z)
        local start = center - dir * CAST_BACKOFF
        local size = Vector3.new(shape.width, math.max(high - low, 1), shape.width)
        local sweep = workspace:Blockcast(CFrame.lookAt(start, start + dir), size, dir * (distance + CAST_BACKOFF + WALL_MARGIN), castParams)

        if sweep then
            allowed = math.clamp(sweep.Distance - CAST_BACKOFF - WALL_MARGIN, 0, distance)
            blocker = sweep
        end

        local side = dir:Cross(Vector3.yAxis) * (radius * 0.8)
        local reach = distance + radius + WALL_MARGIN

        for _, y in ipairs({ low + 0.2, center.Y, high }) do
            for _, offset in ipairs({ Vector3.zero, side, -side }) do
                local ray = workspace:Raycast(Vector3.new(origin.X, y, origin.Z) + offset, dir * reach, castParams)

                if ray then
                    local rayAllowed = math.clamp(ray.Distance - radius - WALL_MARGIN, 0, distance)

                    if rayAllowed < allowed or not blocker then
                        allowed = math.min(allowed, rayAllowed)
                        blocker = ray
                    end
                end
            end
        end

        return allowed, blocker
    end

    local function hasFloor(position, shape)
        local from = Vector3.new(position.X, position.Y - shape.bottom + 2, position.Z)

        return workspace:Raycast(from, Vector3.new(0, -(GROUND_CHECK + 2), 0), castParams) ~= nil
    end

    -- The move to apply to a killer: `distance` studs along `dir`, stopped by walls, sliding along the wall for whatever is left and
    -- cancelled altogether if it would leave the killer over a drop. A killer is never moved through anything.
    local function resolveMove(origin, shape, dir, distance)
        local allowed, hit = castStep(origin, shape, dir, distance)
        local first = dir * allowed
        local move = first

        if hit and allowed < distance - 0.01 then
            local normal = hit.Normal
            local slide = Vector3.new(dir.X - normal.X * dir:Dot(normal), 0, dir.Z - normal.Z * dir:Dot(normal))

            if slide.Magnitude > 0.05 then
                local slideDir = slide.Unit
                local slideAllowed = castStep(origin + first, shape, slideDir, (distance - allowed) * slide.Magnitude)

                move += slideDir * slideAllowed
            end
        end

        if move.Magnitude > 0.005 and not hasFloor(origin + move, shape) then
            return Vector3.zero, Vector3.zero
        end

        return move, first
    end

    local pushStates = setmetatable({}, { __mode = "k" })
    local pushConnection = nil
    local pushLastError = nil

    local function ownsPart(part)
        if type(isnetworkowner) ~= "function" then
            return true
        end

        local ok, owned = pcall(isnetworkowner, part)

        return ok and owned
    end

    -- Everything the wall checks must look straight through: killers, and every character (the LocalPlayer and the other players')
    local function buildFilter()
        local filter = { killersFolder }

        for _, player in ipairs(players:GetPlayers()) do
            if player.Character then
                table.insert(filter, player.Character)
            end
        end

        local folder = localplayer.Character and localplayer.Character.Parent

        if folder and folder ~= workspace then
            table.insert(filter, folder)
        end

        castParams.FilterDescendantsInstances = filter
    end

    local function stopPush()
        if pushConnection then
            pushConnection:Disconnect()
            pushConnection = nil
        end

        table.clear(pushStates)
    end

    local function pushStep(deltaTime)
        if library.Unloaded or not toggles.disableAllKillers_Toggle.Value then
            stopPush()
            return
        end

        if tostring(options.disableAuraMethod_Dropdown.Value) ~= "Push" then
            if next(pushStates) then
                table.clear(pushStates)
            end

            return
        end

        local hrp = getHRP()

        if not hrp then
            return
        end

        local dt = math.min(deltaTime, 0.05)
        local origin = hrp.Position
        local range = proximityRange or 30
        local decay = math.exp(-PUSH_DECAY * dt)
        local now = os.clock()
        local filterBuilt = false
        local wallCheck = toggles.disableAuraWallCheck_Toggle.Value

        for _, model in ipairs(killersFolder:GetChildren()) do
            local hum = model:IsA("Model") and model:FindFirstChildOfClass("Humanoid")
            local root = hum and model:FindFirstChild("HumanoidRootPart")

            -- Dead killers (and ones whose humanoid is gone) are left alone
            if not (root and root:IsA("BasePart")) or hum.Health <= 0 then
                pushStates[model] = nil
                continue
            end

            local position = root.Position
            local state = pushStates[model]

            if not state then
                state = { speed = 0, last = position, active = false, notifiedAt = 0 }
                pushStates[model] = state
            end

            local distance = (position - origin).Magnitude
            local inRange = distance <= range

            -- Wall Check: killers behind walls are not pushed
            if inRange and wallCheck and not utils.isKillerVisible(origin, model, root) then
                inRange = false
            end

            -- Moving far in one frame without our help is a teleport
            local teleported = (position - state.last).Magnitude > TELEPORT_JUMP

            -- Harder the closer the killer is. A killer that keeps walking in is held at the edge because even the gentlest push is faster
            -- than a walk, and a throw keeps its speed for a moment after the killer is out of range.
            local speed = state.speed * decay

            if inRange then
                local want = PUSH_MAX_SPEED * math.sqrt(math.clamp(1 - distance / range, 0, 1))

                if teleported then
                    want = PUSH_MAX_SPEED
                end

                speed = math.max(speed, want)
            end

            if speed < 1 or not ownsPart(root) then
                state.speed = 0
                state.last = position
                state.active = false
                continue
            end

            state.speed = speed

            if not filterBuilt then
                buildFilter()
                filterBuilt = true
            end

            -- Straight away from you, flat. A killer exactly above or below you is sent the way you are facing.
            local away = Vector3.new(position.X - origin.X, 0, position.Z - origin.Z)

            if away.Magnitude < 0.05 then
                local look = hrp.CFrame.LookVector
                away = Vector3.new(look.X, 0, look.Z)

                if away.Magnitude < 0.05 then
                    away = Vector3.xAxis
                end
            end

            local move = resolveMove(position, getShape(model, root), away.Unit, math.min(speed * dt, PUSH_MAX_STEP))

            if move.Magnitude > 0.005 then
                root.CFrame += move
                position += move
            end

            state.last = position

            if inRange and not state.active and now - state.notifiedAt > 3 then
                state.active = true
                state.notifiedAt = now

                if toggles.disableAuraDebugNotifs_Toggle.Value then
                    notify("Info", "Disable Aura", "Pushing " .. model.Name, 3)
                end
            end
        end
    end

    pushToggled = function(enabled)
        stopPush()

        if not enabled then
            return
        end

        pushConnection = runService.Heartbeat:Connect(function(deltaTime)
            local ok, err = pcall(pushStep, deltaTime)

            if not ok and err ~= pushLastError then
                pushLastError = err
                warn("[Disable Aura: Push] " .. tostring(err))
            end
        end)
    end
end

-- [Exploits / Killer Controls] Killer Godmode
do
    -- Remotes fired from your client that report damage, and when a call counts as a hit
    local blockedReports = {
        DreamDamage = function()
            return true
        end,
        TargetAttack = function(target)
            -- Called with no target when the jump simply ends, which the server still needs to hear about
            return target ~= nil
        end,
    }

    local godmode = {
        active = false,
        hookInstalled = false,
        warned = false,
        loopId = 0,
        connections = {},
    }

    local function shouldBlock(remote, ...)
        if typeof(remote) ~= "Instance" or remote.ClassName ~= "RemoteEvent" then
            return false
        end

        local rule = blockedReports[remote.Name]

        if not rule then
            return false
        end

        -- Only remotes of killers that are not you: when you play a killer these are your own attacks
        local killer = remote.Parent

        if not killer or killer.Parent ~= killersFolder or killer == localplayer.Character then
            return false
        end

        return rule(...)
    end

    -- One permanent __namecall hook, inert whenever Killer Godmode is off or the script is unloaded
    local function installReportBlocker()
        if godmode.hookInstalled then
            return true
        end

        if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
            return false
        end

        local wrap = type(newcclosure) == "function" and newcclosure or function(callback)
            return callback
        end

        local original
        original = hookmetamethod(game, "__namecall", wrap(function(self, ...)
            if godmode.active and not library.Unloaded and getnamecallmethod() == "FireServer" then
                local ok, blocked = pcall(shouldBlock, self, ...)

                if ok and blocked then
                    return nil
                end
            end

            return original(self, ...)
        end))

        godmode.hookInstalled = true

        return true
    end

    local function isOwnCharacter(instance)
        local character = localplayer.Character

        return character ~= nil and instance:IsDescendantOf(character)
    end

    local function stripKillerHitbox(instance)
        if instance:IsA("TouchTransmitter") and not isOwnCharacter(instance) then
            pcall(instance.Destroy, instance)
        end
    end

    local function disconnectAll()
        for _, connection in ipairs(godmode.connections) do
            connection:Disconnect()
        end

        table.clear(godmode.connections)
    end

    toggles.killerGodmode_Toggle:OnChanged(function(enabled)
        godmode.active = enabled
        godmode.loopId += 1
        disconnectAll()

        if not enabled then
            return
        end

        local blockerReady = installReportBlocker()

        if not blockerReady and not godmode.warned then
            godmode.warned = true
            notify("Error", "Killer Godmode", "This executor can not hook __namecall, so damage reports can not be blocked. Only hitboxes are removed.", 6)
        end

        -- Hitboxes: removed the moment they appear instead of waiting for the next sweep
        table.insert(godmode.connections, killersFolder.DescendantAdded:Connect(stripKillerHitbox))

        -- Freddy's nightmare hazards only ever exist on the client. The hole pulls your character with a LineForce, so it goes as well
        table.insert(godmode.connections, workspace.ChildAdded:Connect(function(child)
            if child.Name == "HolePart" or child.Name == "FreddyNightmare" then
                task.defer(pcall, child.Destroy, child)
            end
        end))

        local loopId = godmode.loopId

        task.spawn(function()
            while godmode.loopId == loopId and toggles.killerGodmode_Toggle.Value and not library.Unloaded do
                for _, model in ipairs(killersFolder:GetChildren()) do
                    if model:IsA("Model") and model ~= localplayer.Character then
                        for _, descendant in ipairs(model:GetDescendants()) do
                            stripKillerHitbox(descendant)

                            -- Without the hook the best that can be done is to take away the remote the damage goes through
                            if not blockerReady and descendant.Name == "DreamDamage" and descendant:IsA("RemoteEvent") then
                                pcall(descendant.Destroy, descendant)
                            end
                        end
                    end
                end

                task.wait(0.5)
            end
        end)
    end)
end

local pinheadConnection
toggles.antiPinhead_Toggle:OnChanged(function(enabled)
    if enabled and not pinheadConnection then
        pinheadConnection = runService.Heartbeat:Connect(function()
            for _, obj in ipairs(game:GetService("Workspace"):GetChildren()) do
                if obj:IsA("Model") then
                    for _, spike in ipairs(obj:GetChildren()) do
                        if spike:IsA("BasePart") and spike.Name == "Spike" then
                            spike:Destroy()
                        end
                    end
                end
            end
        end)
    elseif not enabled and pinheadConnection then
        pinheadConnection:Disconnect()
        pinheadConnection = nil
    end
end)

toggles.antiSlendermanJumpscare_Toggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.antiSlendermanJumpscare_Toggle.Value do
                local gui = localplayer:FindFirstChild("PlayerGui"):FindFirstChild("Slender")
                local slenderman = game:GetService("Workspace"):FindFirstChild("Killers") and game:GetService("Workspace").Killers:FindFirstChild("Slenderman")

                if slenderman and gui then
                    gui.Enabled = false

                    local deathSound = slenderman:FindFirstChild("HumanoidRootPart") and slenderman.HumanoidRootPart:FindFirstChild("SlenderTouch")
                    if deathSound then
                        deathSound:Stop()
                    end
                end

                task.wait()
            end
        end)
    end
end)

-- ============================================================================
-- 11 | TAB: VISUALS
-- ============================================================================

-- [Visuals / Layout] Groupbox and control registration
local visualsGroup = tabs.visuals:AddLeftGroupbox("Visuals")

-- [Visuals / Controls] ESP, name tags, fog, FOV, and anti-effects

visualsGroup:AddToggle("removeFog_Toggle", { Text = "Remove Fog", Tooltip = false, Default = false })
visualsGroup:AddToggle("killerESP_Toggle", { Text = "Killer ESP", Tooltip = false })

local killerESPDepbox = visualsGroup:AddDependencyBox()

killerESPDepbox:AddDropdown("excludedKillers_Dropdown", { Text = "Excluded Killers", Tooltip = false, Values = killerNames, Default = { "Giant", "Jane" }, Multi = true, Searchable = true })
killerESPDepbox:AddSlider("killerESPDistance_Slider", { Text = "Range", Tooltip = "How far away to show ESP on killers", Default = 150, Min = 100, Max = 1000, Suffix = " Studs", Rounding = 0 })
killerESPDepbox:AddDropdown("killerESPBoxType_Dropdown", { Text = "Box Type", Tooltip = "2D draws a flat box around the killer, 3D draws a wireframe box.", Values = { "2D", "3D" }, Default = "2D" })
killerESPDepbox:AddToggle("killerESPHealthBar_Toggle", { Text = "Health Bar", Tooltip = "Shows a health bar next to the killer.", Default = true })
killerESPDepbox:AddLabel("ESP Color"):AddColorPicker("killerESPColor_ColorPicker",{ Title = "ESP Color", Default = Color3.fromRGB(255, 0, 0), Transparency = nil })
killerESPDepbox:AddCheckbox("rainbowESPColor_Toggle", { Text = "Rainbow ESP Color" })
killerESPDepbox:AddToggle("toggleKillersNametags_Toggle", { Text = "Enable Name Tags" })
killerESPDepbox:AddDivider()

local killerNametagDepbox = killerESPDepbox:AddDependencyBox()

killerNametagDepbox:AddLabel("Name Tag Color"):AddColorPicker("killerNameTagColor_ColorPicker",{ Title = "Name Tag Color", Default = Color3.fromRGB(255, 255, 255), Transparency = nil })

killerNametagDepbox:AddCheckbox("rainbowNameTagColor_Toggle", { Text = "Rainbow Name Tag Color" })
killerNametagDepbox:AddSlider("textSize_Slider", { Text = "Text Size", Tooltip = false, Default = 15, Min = 10, Max = 50, Rounding = 0 })
killerNametagDepbox:AddDivider()

visualsGroup:AddToggle("enableFOV_Toggle", { Text = "Enable FOV" })

local fieldOfViewDepbox = visualsGroup:AddDependencyBox()

fieldOfViewDepbox:AddSlider("fieldOfViewValue_Slider", { Text = "Value", Tooltip = false, Default = 80, Min = 80, Max = 120, Rounding = 0 })
fieldOfViewDepbox:AddDivider()

visualsGroup:AddToggle("antiInk_Toggle", { Text = "Anti Ink", Tooltip = "Disables the black ink popup from Eyeless Jack." })
visualsGroup:AddToggle("antiTailsPopup_Toggle", { Text = "Anti Tails Popup", Tooltip = "Disables the popup from Tails Doll." })

killerESPDepbox:SetupDependencies({ { toggles.killerESP_Toggle, true } })
killerNametagDepbox:SetupDependencies({ { toggles.toggleKillersNametags_Toggle, true } })
fieldOfViewDepbox:SetupDependencies({ { toggles.enableFOV_Toggle, true } })

-- [Visuals / Fog] Toggle lifecycle and property-change connections
local fogConnections = {}
toggles.removeFog_Toggle:OnChanged(function(enabled)
    if enabled then
        entityLib.storeData(lighting, "FogColor")
        entityLib.storeData(lighting, "FogEnd")
        entityLib.storeData(lighting, "FogStart")

        local function removeFog()
            lighting.FogEnd = math.huge
            lighting.FogStart = 0
        end

        removeFog()

        -- Connect to property changes

        fogConnections.FogEnd = lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
            if toggles.removeFog_Toggle.Value and lighting.FogEnd ~= math.huge then
                lighting.FogEnd = math.huge
            end
        end)

        fogConnections.FogStart = lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
            if toggles.removeFog_Toggle.Value and lighting.FogStart ~= 0 then
                lighting.FogStart = 0
            end
        end)

    else
        -- Disconnect all property change listeners

        for _, conn in pairs(fogConnections) do
            if conn.Connected then
                conn:Disconnect()
            end
        end

        fogConnections = {}

        entityLib.restoreData(lighting, "FogColor")
        entityLib.restoreData(lighting, "FogEnd")
        entityLib.restoreData(lighting, "FogStart")

        entityLib.clearData(lighting, "FogColor")
        entityLib.clearData(lighting, "FogEnd")
        entityLib.clearData(lighting, "FogStart")
    end
end)

local excludedKillers = { Giant = true, Jane = true }

local defaultTextSize = 15

-- [Visuals / Killer ESP] Drawing library rendering
-- Each killer gets an unfilled 2D box or a 3D wireframe box with an optional health bar and an optional name tag.
do
    local killerESPToggle = toggles.killerESP_Toggle
    local killerESPRangeSlider = options.killerESPDistance_Slider
    local killerColorPicker = options.killerESPColor_ColorPicker
    local nameTagColorPicker = options.killerNameTagColor_ColorPicker

    local renderConnection: RBXScriptConnection? = nil

    -- espObjects[model] = { mode, box, boxOutline, lines, healthBG, healthFill, label }
    local espObjects: { [Instance]: any } = {}

    -- The 8 corners of a box (multipliers of its half size). Corner index = 1 + x * 4 + y * 2 + z, where each of
    -- x / y / z is 0 for the negative side and 1 for the positive side.
    local boxCorners: { Vector3 } = {}
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                table.insert(boxCorners, Vector3.new(x, y, z))
            end
        end
    end

    -- The 12 edges of the box, as pairs of corner indices (corners that differ by exactly one axis).
    local boxEdges: { { number } } = {
        { 1, 2 }, { 3, 4 }, { 5, 6 }, { 7, 8 }, -- along Z
        { 1, 3 }, { 2, 4 }, { 5, 7 }, { 6, 8 }, -- along Y
        { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 }, -- along X
    }

    -- A killer's box is measured ONCE from its humanoid body parts and then never changes. Extra moving parts are ignored.
    local boxCoreParts = { HumanoidRootPart = true, Head = true, UpperTorso = true, LowerTorso = true, Torso = true }
    local boxLegParts = {
        LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
        RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
        ["Left Leg"] = true, ["Right Leg"] = true,
    }

    -- boxCache[killer] = { size = Vector3, offset = Vector3 }. size is the fixed box size, offset is the box center
    -- relative to the killer's HumanoidRootPart.
    local boxCache: { [Instance]: any } = setmetatable({}, { __mode = "k" })

    local function destroyDrawing(drawing: any)
        if drawing then
            pcall(function() drawing:Destroy() end)
        end
    end

    local function setVisible(drawing: any, visible: boolean)
        if drawing then
            drawing.Visible = visible
        end
    end

    local function destroyBoxDrawings(objs: any)
        destroyDrawing(objs.box)
        destroyDrawing(objs.boxOutline)
        objs.box = nil
        objs.boxOutline = nil

        if objs.lines then
            for _, line in ipairs(objs.lines) do
                destroyDrawing(line)
            end
            objs.lines = nil
        end

        objs.mode = nil
    end

    local function destroyHealthBar(objs: any)
        destroyDrawing(objs.healthBG)
        destroyDrawing(objs.healthFill)
        objs.healthBG = nil
        objs.healthFill = nil
    end

    local function hideESPObjects(objs: any)
        setVisible(objs.box, false)
        setVisible(objs.boxOutline, false)
        setVisible(objs.healthBG, false)
        setVisible(objs.healthFill, false)
        setVisible(objs.label, false)

        if objs.lines then
            for _, line in ipairs(objs.lines) do
                line.Visible = false
            end
        end
    end

    local function clearESPForModel(model: Instance)
        local objs = espObjects[model]
        if objs then
            destroyBoxDrawings(objs)
            destroyHealthBar(objs)
            destroyDrawing(objs.label)
            espObjects[model] = nil
            boxCache[model] = nil
        end
    end

    local function clearESP()
        for model in pairs(espObjects) do
            clearESPForModel(model)
        end
    end

    local function createESPObjects(): any
        local label = Drawing.new("Text")
        label.Center = true
        label.Outline = true
        label.OutlineColor = Color3.new(0, 0, 0)
        label.Transparency = 1
        label.ZIndex = 4
        label.Visible = false

        return { label = label }
    end

    -- Creates the drawings for the selected box style (and removes the other style's drawings when it changes).
    local function ensureBoxDrawings(objs: any, mode: string)
        if objs.mode == mode then
            return
        end

        destroyBoxDrawings(objs)
        objs.mode = mode

        if mode == "3D" then
            local lines = {}

            for index = 1, #boxEdges do
                local line = Drawing.new("Line")
                line.Thickness = 1.5
                line.Transparency = 1
                line.ZIndex = 2
                line.Visible = false
                lines[index] = line
            end

            objs.lines = lines
        else
            local outline = Drawing.new("Square")
            outline.Filled = false
            outline.Thickness = 3
            outline.Color = Color3.new(0, 0, 0)
            outline.Transparency = 1
            outline.ZIndex = 1
            outline.Visible = false

            local box = Drawing.new("Square")
            box.Filled = false
            box.Thickness = 1
            box.Transparency = 1
            box.ZIndex = 2
            box.Visible = false

            objs.boxOutline = outline
            objs.box = box
        end
    end

    local function ensureHealthBar(objs: any)
        if objs.healthBG then
            return
        end

        local background = Drawing.new("Square")
        background.Filled = true
        background.Color = Color3.new(0, 0, 0)
        background.Transparency = 0.7
        background.ZIndex = 1
        background.Visible = false

        local fill = Drawing.new("Square")
        fill.Filled = true
        fill.Transparency = 1
        fill.ZIndex = 3
        fill.Visible = false

        objs.healthBG = background
        objs.healthFill = fill
    end

    -- Measures the killer's fixed box size from its humanoid body parts, in the HumanoidRootPart's local space.
    local function measureKillerBox(model: Model, root: BasePart): any
        local rootCFrame = root.CFrame
        local minV = Vector3.new(math.huge, math.huge, math.huge)
        local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
        local found = 0

        for _, part in ipairs(model:GetChildren()) do
            local isCore = boxCoreParts[part.Name] == true

            if part:IsA("BasePart") and (isCore or boxLegParts[part.Name]) then
                local half = part.Size / 2
                found += 1

                for _, corner in ipairs(boxCorners) do
                    local p = rootCFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(corner * half))

                    if isCore then
                        minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
                        maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
                    else
                        minV = Vector3.new(minV.X, math.min(minV.Y, p.Y), minV.Z)
                        maxV = Vector3.new(maxV.X, math.max(maxV.Y, p.Y), maxV.Z)
                    end
                end
            end
        end

        local size = maxV - minV
        local valid = found > 1
            and size.X > 0 and size.Y > 0 and size.Z > 0
            and size.X < math.huge and size.Y < math.huge and size.Z < math.huge

        if valid then
            return {
                size = Vector3.new(math.max(size.X, 1), math.max(size.Y, 1), math.max(size.Z, 1)),
                offset = (minV + maxV) / 2,
            }
        end

        -- Not a humanoid rig: fall back to the model's bounding box, measured once and then kept as well.
        local boundsCFrame, boundsSize = model:GetBoundingBox()
        return { size = boundsSize, offset = rootCFrame:PointToObjectSpace(boundsCFrame.Position) }
    end

    local function getKillerBox(model: Model, root: BasePart): any
        local box = boxCache[model]

        if not box then
            box = measureKillerBox(model, root)
            boxCache[model] = box
        end

        return box
    end

    -- Builds the killer's fixed-size box on screen. Returns nil when the killer is behind the camera.
    --   minX / minY / width / height : the 2D rectangle (also used by the health bar and name tag in 3D mode)
    --   points                       : the 8 projected corners of the 3D box (only built when need3D is true);
    --                                  points[i] is false when that corner is behind the camera
    local function projectBox(model: Model, root: BasePart, cam: Camera, need3D: boolean): any
        local box = getKillerBox(model, root)
        local size = box.size
        local boxCFrame = root.CFrame * CFrame.new(box.offset)

        local center = cam:WorldToViewportPoint(boxCFrame.Position)
        if center.Z <= 0 then
            return nil
        end

        -- Pixels per stud at the killer's depth, from the camera's field of view. The 2D rectangle depends only on
        -- the fixed box size and the distance, never on the killer's pose, rotation or the camera angle.
        local pixelsPerStud = cam.ViewportSize.Y / (2 * center.Z * math.tan(math.rad(cam.FieldOfView) / 2))
        local width = math.floor(math.max(size.X, size.Z) * pixelsPerStud + 0.5)
        local height = math.floor(size.Y * pixelsPerStud + 0.5)

        local points: { any }? = nil

        if need3D then
            local half = size / 2
            points = {}

            for index, corner in ipairs(boxCorners) do
                local screen = cam:WorldToViewportPoint(boxCFrame:PointToWorldSpace(corner * half))
                points[index] = screen.Z > 0 and Vector2.new(screen.X, screen.Y) or false
            end
        end

        return {
            points = points,
            minX = math.floor(center.X - width / 2 + 0.5),
            minY = math.floor(center.Y - height / 2 + 0.5),
            width = width,
            height = height,
        }
    end

    local function updateESP()
        local hrp = getHRP()
        local folder = killersFolder or workspace:FindFirstChild("Killers")
        local cam = workspace.CurrentCamera

        if not hrp or not folder or not cam then
            for _, objs in pairs(espObjects) do
                hideESPObjects(objs)
            end
            return
        end

        local espColor = killerColorPicker.Value
        local tagColor = nameTagColorPicker.Value
        local showTags = toggles.toggleKillersNametags_Toggle.Value
        local showHealth = toggles.killerESPHealthBar_Toggle.Value
        local boxMode = options.killerESPBoxType_Dropdown.Value == "3D" and "3D" or "2D"
        local maxDistance = killerESPRangeSlider.Value

        local seen = {}

        for _, killer in ipairs(folder:GetChildren()) do
            if not killer:IsA("Model") or excludedKillers[killer.Name] then
                continue
            end

            -- Dead / invalid killers are left unseen so their drawings get destroyed below
            local root = killer:FindFirstChild("HumanoidRootPart")
            local killerHumanoid = killer:FindFirstChildOfClass("Humanoid")
            if not root or not killerHumanoid or killerHumanoid.Health <= 0 then
                continue
            end

            seen[killer] = true

            local objs = espObjects[killer]

            if entityLib.getEntityDistance(hrp, root) > maxDistance then
                if objs then hideESPObjects(objs) end
                continue
            end

            local projection = projectBox(killer, root, cam, boxMode == "3D")
            if not projection then
                if objs then hideESPObjects(objs) end
                continue
            end

            if not objs then
                objs = createESPObjects()
                espObjects[killer] = objs
            end

            local points = projection.points
            local minX, minY = projection.minX, projection.minY
            local width, height = projection.width, projection.height

            -- Box (never filled)
            ensureBoxDrawings(objs, boxMode)

            if boxMode == "3D" then
                for index, edge in ipairs(boxEdges) do
                    local from, to = points[edge[1]], points[edge[2]]
                    local line = objs.lines[index]

                    if from and to then
                        line.From = from
                        line.To = to
                        line.Color = espColor
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end
            else
                local position = Vector2.new(minX, minY)
                local size = Vector2.new(width, height)

                objs.boxOutline.Position = position
                objs.boxOutline.Size = size
                objs.boxOutline.Visible = true

                objs.box.Position = position
                objs.box.Size = size
                objs.box.Color = espColor
                objs.box.Visible = true
            end

            -- Health bar (vertical, left of the box; fills from the bottom up)
            if showHealth then
                ensureHealthBar(objs)

                local healthRatio = math.clamp(killerHumanoid.Health / math.max(killerHumanoid.MaxHealth, 1), 0, 1)
                local fillHeight = math.floor(height * healthRatio + 0.5)

                objs.healthBG.Position = Vector2.new(minX - 7, minY - 1)
                objs.healthBG.Size = Vector2.new(4, height + 2)
                objs.healthBG.Visible = true

                objs.healthFill.Position = Vector2.new(minX - 6, minY + height - fillHeight)
                objs.healthFill.Size = Vector2.new(2, fillHeight)
                objs.healthFill.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthRatio)
                objs.healthFill.Visible = fillHeight > 0
            elseif objs.healthBG then
                destroyHealthBar(objs)
            end

            -- Name tag
            objs.label.Text = killer.Name
            objs.label.Size = defaultTextSize
            objs.label.Color = tagColor
            objs.label.Position = Vector2.new(minX + math.floor(width / 2), minY - defaultTextSize - 4)
            objs.label.Visible = showTags
        end

        for model in pairs(espObjects) do
            if not seen[model] then
                clearESPForModel(model)
            end
        end
    end

    toggles.killerESP_Toggle:OnChanged(function(enabled)
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        clearESP()

        if enabled then
            if not Drawing then
                notify("Error", "Drawing unsupported", "Your executor does not support the Drawing library.", 8)
                killerESPToggle:SetValue(false)
                return
            end

            renderConnection = runService.RenderStepped:Connect(updateESP)
        end
    end)
end

options.textSize_Slider:OnChanged(function(val) defaultTextSize = val end)

options.excludedKillers_Dropdown:OnChanged(function(val)
    excludedKillers = {}
    for name in pairs(val) do
        excludedKillers[name] = true
    end
    -- updateESP() clears drawings for newly excluded killers on its next frame
end)

toggles.rainbowESPColor_Toggle:OnChanged(function(enabled)
    toggleRainbow(enabled, "killerESPColor_ColorPicker")
end)

toggles.rainbowNameTagColor_Toggle:OnChanged(function(enabled)
    toggleRainbow(enabled, "killerNameTagColor_ColorPicker")
end)

toggles.enableFOV_Toggle:OnChanged(function(enabled)
    if enabled then
        entityLib.storeData(camera, "FieldOfView", true)
        camera.FieldOfView = options.fieldOfViewValue_Slider.Value
    else
        entityLib.restoreData(camera, "FieldOfView")
    end
end)

options.fieldOfViewValue_Slider:OnChanged(function(val)
    local fovEnabled = toggles.enableFOV_Toggle.Value

    if fovEnabled then
        camera.FieldOfView = val
    end
end)

-- [Visuals / Anti-effects] Ink and popup handling
local function destroyInkEvent()
    local eyelessJack = killersFolder:FindFirstChild("Eyeless Jack")
    if eyelessJack then
        local event = eyelessJack:FindFirstChild("Inked")
        if event then
            event:Destroy()
        end
    end
end

local function disableInkGui()
    local inkGui = localplayer.PlayerGui:FindFirstChild("Ink")

    if inkGui then
        local isInked = inkGui:FindFirstChildWhichIsA("ImageLabel", true)
        if isInked and isInked.Visible then
            inkGui.Enabled = false
        end
    end
end

local killerConnection
toggles.antiInk_Toggle:OnChanged(function(enabled)
    if enabled then
        destroyInkEvent()
        disableInkGui()

        killerConnection = killersFolder.ChildAdded:Connect(function(child)
            if child.Name == "Eyeless Jack" then
                task.wait(0.1)
                destroyInkEvent()
            end
        end)

    else
        if killerConnection then
            killerConnection:Disconnect()
            killerConnection = nil
        end
    end
end)

toggles.antiTailsPopup_Toggle:OnChanged(function(enabled)
    local popupGui = localplayer.PlayerGui:FindFirstChild("TailsPopup")

    if popupGui then
        popupGui.Enabled = not enabled
    else
        notify("Error", "Failed to locate", "Failed to find Tails Doll popup.", 100)
    end
end)

-- [Visuals / Scope Overlay]
do
    local function buildScopeOverlayRemoval()
        visualsGroup:AddToggle("disableScopeOverlay_Toggle", { Text = "Disable Scope Overlay", Tooltip = "Removes the black overlay when aiming through a scope, on any weapon. The zoom is kept.", Default = false })

        local scopeOverlayDepbox = visualsGroup:AddDependencyBox()

        scopeOverlayDepbox:AddToggle("keepScopeCrosshair_Toggle", { Text = "Keep Crosshair", Tooltip = "Shows the normal crosshair while scoped, since the scope's own reticle goes away with the overlay.", Default = true })
        scopeOverlayDepbox:AddDivider()

        scopeOverlayDepbox:SetupDependencies({ { toggles.disableScopeOverlay_Toggle, true } })

        local active = false
        local originals = {} -- [instance] = transparency the game gave it
        local connections = {}
        local guiAddedConnection = nil
        local reapplyQueued = false

        local function getScopeGuis()
            local mouseGui = localplayer.PlayerGui:FindFirstChild("Mouse")

            if not mouseGui then
                return nil, nil
            end

            return mouseGui:FindFirstChild("Scope"), mouseGui:FindFirstChild("Aim")
        end

        local function hideOverlay(scope)
            if originals[scope] == nil then
                originals[scope] = scope.ImageTransparency
            end

            scope.ImageTransparency = 1

            for _, child in ipairs(scope:GetChildren()) do
                if child:IsA("GuiObject") then
                    if originals[child] == nil then
                        originals[child] = child.BackgroundTransparency
                    end

                    child.BackgroundTransparency = 1
                end
            end
        end

        local function restoreOverlay()
            for instance, value in pairs(originals) do
                if instance.Parent then
                    if instance:IsA("ImageLabel") then
                        instance.ImageTransparency = value
                    else
                        instance.BackgroundTransparency = value
                    end
                end

                originals[instance] = nil
            end
        end

        local function disconnectScopeConnections()
            for name, connection in pairs(connections) do
                connection:Disconnect()
                connections[name] = nil
            end
        end

        -- The game hides the crosshair (Mouse.Aim) when aiming starts and shows the scope right after.
        local function wantsCrosshair()
            return active and toggles.keepScopeCrosshair_Toggle.Value
        end

        local function refreshCrosshair()
            local scope, aim = getScopeGuis()

            if scope and aim and scope.Visible then
                aim.Visible = wantsCrosshair()
            end
        end

        local function applyOverlayRemoval()
            reapplyQueued = false

            if not active then
                return
            end

            local scope, aim = getScopeGuis()

            if not scope then
                return
            end

            hideOverlay(scope)
            disconnectScopeConnections()

            if aim then
                connections.scopeVisible = scope:GetPropertyChangedSignal("Visible"):Connect(function()
                    if scope.Visible and wantsCrosshair() then
                        aim.Visible = true
                    end
                end)

                connections.aimVisible = aim:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not aim.Visible and scope.Visible and wantsCrosshair() then
                        aim.Visible = true
                    end
                end)
            end

            refreshCrosshair()
        end

        local function stopOverlayRemoval()
            active = false
            disconnectScopeConnections()
            restoreOverlay()

            if guiAddedConnection then
                guiAddedConnection:Disconnect()
                guiAddedConnection = nil
            end

            local scope, aim = getScopeGuis()

            if scope and aim and scope.Visible then
                aim.Visible = false -- back to what the game does while scoped
            end
        end

        toggles.disableScopeOverlay_Toggle:OnChanged(function(enabled)
            if not enabled then
                stopOverlayRemoval()
                return
            end

            active = true

            -- The GUI is rebuilt if the player's GUI ever resets; queue a re-apply when a new Scope shows up.
            if guiAddedConnection then
                guiAddedConnection:Disconnect()
            end

            guiAddedConnection = localplayer.PlayerGui.DescendantAdded:Connect(function(descendant)
                if active and not reapplyQueued and descendant.Name == "Scope" and descendant.Parent and descendant.Parent.Name == "Mouse" then
                    reapplyQueued = true
                    task.defer(applyOverlayRemoval)
                end
            end)

            if not getScopeGuis() then
                notify("Error", "Failed to locate", "Failed to find the scope overlay. It will be removed once it loads.", 8)
            end

            applyOverlayRemoval()
        end)

        toggles.keepScopeCrosshair_Toggle:OnChanged(function()
            refreshCrosshair()
        end)

        table.insert(teardownTasks, stopOverlayRemoval)
    end

    buildScopeOverlayRemoval()
end

-- [Visuals / Grenade Trajectory] Flight path and landing preview for the M16A2's grenade launcher (M203)
do
    local function buildGrenadeTrajectory()
        local trajectoryGroup = tabs.visuals:AddRightGroupbox("Grenade Trajectory")

        trajectoryGroup:AddToggle("trajectoryPreview_Toggle", { Text = "Grenade Trajectory", Tooltip = "Draws the flight path and landing spot of the M16A2's grenade launcher (M203) while it is equipped in grenade mode.", Default = false })

        local trajectoryDepbox = trajectoryGroup:AddDependencyBox()

        trajectoryDepbox:AddLabel("Path Color"):AddColorPicker("trajectoryPathColor_ColorPicker", { Title = "Path Color", Default = Color3.fromRGB(0, 229, 255) })
        trajectoryDepbox:AddLabel("Landing Color"):AddColorPicker("trajectoryLandingColor_ColorPicker", { Title = "Landing Color", Default = Color3.fromRGB(255, 170, 0) })
        trajectoryDepbox:AddSlider("trajectoryThickness_Slider", { Text = "Line Thickness", Tooltip = false, Default = 2, Min = 1, Max = 5, Rounding = 0 })
        trajectoryDepbox:AddSlider("trajectoryMarkerSize_Slider", { Text = "Landing Marker Size", Tooltip = "Radius of the ring drawn where the grenade lands. Only a visual size, not the explosion radius.", Default = 3, Min = 1, Max = 10, Suffix = " Studs", Rounding = 0 })
        trajectoryDepbox:AddToggle("trajectoryShowInfo_Toggle", { Text = "Show Distance / Time", Tooltip = "Shows the flight distance and flight time next to the landing spot.", Default = true })
        trajectoryDepbox:AddToggle("trajectoryKillerHighlight_Toggle", { Text = "Highlight Killer On Hit", Tooltip = "When the grenade is predicted to hit a killer, that killer and the path turn the hit color.", Default = true })

        local trajectoryKillerDepbox = trajectoryDepbox:AddDependencyBox()

        trajectoryKillerDepbox:AddLabel("Killer Hit Color"):AddColorPicker("trajectoryKillerColor_ColorPicker", { Title = "Killer Hit Color", Default = Color3.fromRGB(0, 255, 0) })

        trajectoryDepbox:SetupDependencies({ { toggles.trajectoryPreview_Toggle, true } })
        trajectoryKillerDepbox:SetupDependencies({ { toggles.trajectoryKillerHighlight_Toggle, true } })

        local LAUNCHER_TOOL_NAME = "M16A2/M203"
        local MUZZLE_SPEED = 150 -- Weapon.fire: Part.AssemblyLinearVelocity = Unit * 150
        local LAUNCHER_UP_FORCE = 10 -- M16A2/M203 set_missile: BodyForce.Force = Vector3.new(0, 10, 0)
        local MISSILE_RADIUS = 0.5 -- set_missile resizes the grenade to 1 x 1 x 1
        local AIM_RAY_LENGTH = 200 -- Weapon.screen_to_target
        local SOLID_TRANSPARENCY = 0.99 -- Weapon.hit_transparency_threshold
        local NO_CLIP_GROUP = "SurvivorsKillersNoClip"
        local UNHITTABLE_KILLERS = { Giant = true, Jane = true } -- Weapon.missile_check (Classic mode)

        -- Simulation and drawing settings
        local STEP_TIME = 0.05
        local MAX_STEPS = 100
        local MAX_RANGE = 800
        local NEAR_PLANE = 0.1
        local RING_SEGMENTS = 20
        local RENDER_NAME = "CelestialGrenadeTrajectory"

        local missileMass = nil
        local launcherCache = { object = nil, scanning = false, nextScan = 0 }
        local hasSpherecast = pcall(function() return workspace.Spherecast end)

        local aimParams = RaycastParams.new()
        aimParams.FilterType = Enum.RaycastFilterType.Exclude
        aimParams.IgnoreWater = true

        local missileParams = RaycastParams.new()
        missileParams.FilterType = Enum.RaycastFilterType.Exclude
        missileParams.IgnoreWater = true

        local pathLines = {}
        local ringLines = {}
        local infoLabel = nil
        local highlights = {}
        local highlightContainer = nil
        local grenadeIcon = nil
        local running = false
        local lastErrorTime = 0

        -- [Grenade Trajectory / Physics] Mass of the grenade (a 1 x 1 x 1 ball with default density)
        local function getMissileMass()
            if not missileMass then
                local probe = Instance.new("Part")
                probe.Shape = Enum.PartType.Ball
                probe.Size = Vector3.new(1, 1, 1)
                missileMass = probe.Mass
                probe:Destroy()
            end

            return missileMass
        end

        -- [Grenade Trajectory / Game rules] Weapon.find_humanoid and the Killer checks used for aiming and for hits
        local function findHumanoid(part)
            local parent = part.Parent

            if not parent then
                return nil
            end

            local humanoid = parent:FindFirstChildOfClass("Humanoid")

            if not humanoid and parent.Parent then
                humanoid = parent.Parent:FindFirstChildOfClass("Humanoid")
            end

            if humanoid then
                local heldTool = humanoid.Parent and humanoid.Parent:FindFirstChildOfClass("Tool")

                if not (heldTool and part:IsDescendantOf(heldTool)) then
                    return humanoid
                end
            end

            return nil
        end

        local function asKillerHumanoid(humanoid, killers)
            if humanoid and (humanoid.Name == "Zombie" or (killers and humanoid:IsDescendantOf(killers))) then
                return humanoid
            end

            return nil
        end

        -- Weapon.target_ray_callback (Classic mode): what the aim ray stops at
        local function isAimBlocker(result, killers)
            local part = result.Instance
            local humanoid = asKillerHumanoid(findHumanoid(part), killers)

            if humanoid then
                return humanoid.Health > 0
            end

            return part.Transparency < SOLID_TRANSPARENCY and part.CanCollide and part.CollisionGroup ~= NO_CLIP_GROUP
        end

        -- Weapon.missile_hit + missile_check (Classic mode): what makes the grenade explode. Returns the kind of hit
        -- ("killer", "object" or "solid") and, for a killer, its humanoid; nil when the grenade flies straight through.
        local function classifyMissileHit(part, killers)
            if not part.CanTouch then
                return nil
            end

            if part:FindFirstChild("BulletHitEvent") then
                return "object", nil
            end

            local humanoid = asKillerHumanoid(findHumanoid(part), killers)

            if humanoid and UNHITTABLE_KILLERS[humanoid.Parent.Name] then
                humanoid = nil
            end

            if humanoid then
                if humanoid.Health > 0 then
                    return "killer", humanoid
                end

                return nil
            end

            if part.CanCollide and part.Transparency < SOLID_TRANSPARENCY then
                return "solid", nil
            end

            return nil
        end

        -- [Grenade Trajectory / Weapon state] Is the M203 equipped, and is the player scoped in?
        -- The game keeps a Lua object per fire mode (M16A2 and M203) with equipped / aiming flags. It is found once through
        -- the garbage collector (same approach as Silent Aim) and only read afterwards.
        local function scanForLauncherObject(tool)
            local found = nil

            local function consider(object)
                if not found and type(object) == "table"
                    and rawget(object, "instance") == tool
                    and rawget(object, "is_grenade") == true
                then
                    found = object
                end
            end

            if type(filtergc) == "function" then
                local success, matches = pcall(filtergc, "table", { Keys = { "instance", "is_grenade" } }, false)

                if success and type(matches) == "table" then
                    for _, object in ipairs(matches) do
                        consider(object)
                    end
                end
            end

            if not found and type(getgc) == "function" then
                local success, objects = pcall(getgc, true)

                if success and type(objects) == "table" then
                    for index = 1, #objects do
                        consider(objects[index])

                        if found then
                            break
                        end

                        if index % 20000 == 0 then
                            task.wait()

                            if library.Unloaded then
                                return nil
                            end
                        end
                    end
                end
            end

            return found
        end

        local function requestLauncherScan(tool)
            if launcherCache.scanning or os.clock() < launcherCache.nextScan then
                return
            end

            launcherCache.scanning = true
            launcherCache.nextScan = os.clock() + 2

            task.spawn(function()
                local object = scanForLauncherObject(tool)

                if object then
                    launcherCache.object = object
                end

                launcherCache.scanning = false
            end)
        end

        -- Fallback when the weapon object cannot be found: the crosshair shows a grenade icon in grenade mode.
        local function getGrenadeIcon()
            if grenadeIcon and grenadeIcon.Parent then
                return grenadeIcon
            end

            local mouseGui = localplayer.PlayerGui:FindFirstChild("Mouse")
            grenadeIcon = mouseGui and mouseGui:FindFirstChild("Grenade", true) or nil

            return grenadeIcon
        end

        -- Returns the equipped M16A2/M203 tool and whether the player is scoped in, or nil when grenade mode is not active.
        local function getActiveLauncher(character)
            local tool = character:FindFirstChildWhichIsA("Tool")

            if not tool or not string.find(tool.Name, LAUNCHER_TOOL_NAME, 1, true) then
                return nil
            end

            local object = launcherCache.object

            if object and rawget(object, "instance") ~= tool then
                object = nil
                launcherCache.object = nil
            end

            if object then
                if object.equipped ~= true then
                    return nil
                end

                return tool, object.aiming == true and object.has_scope == true
            end

            requestLauncherScan(tool)

            local icon = getGrenadeIcon()

            if icon and icon.Visible then
                return tool, false
            end

            return nil
        end

        -- Weapon.fire: the grenade leaves from the Aim part while scoped (if the tool has one), otherwise from Flash.
        local function getMuzzlePart(tool, scoped)
            local flash = tool:FindFirstChild("Flash")

            if scoped then
                return tool:FindFirstChild("Aim") or flash
            end

            return flash
        end

        -- [Grenade Trajectory / Aim] Weapon.screen_to_target: where the cursor ray ends, up to 200 studs out
        local function findAimPoint(rayOrigin, rayDirection, charactersFolder, killers)
            local ignored = {}

            if charactersFolder then
                ignored[1] = charactersFolder
            end

            aimParams.FilterDescendantsInstances = ignored

            for _ = 1, 12 do
                local result = workspace:Raycast(rayOrigin, rayDirection, aimParams)

                if not result then
                    break
                end

                if isAimBlocker(result, killers) then
                    return result.Position
                end

                ignored[#ignored + 1] = result.Instance
                aimParams.FilterDescendantsInstances = ignored
            end

            return rayOrigin + rayDirection
        end

        -- [Grenade Trajectory / Simulation] Steps the grenade along its parabola and finds where it explodes.
        -- Returns { points = { Vector3... }, impact = { position, normal, kind, humanoid, time } | nil }.
        -- Parts that do not stop the grenade are skipped for the rest of the simulation (that never changes mid-flight).
        local function simulateMissile(origin, velocity, accelY, charactersFolder, killers)
            local ignored = {}

            if charactersFolder then
                ignored[1] = charactersFolder
            end

            missileParams.FilterDescendantsInstances = ignored

            local points = { origin }
            local position = origin
            local floorY = workspace.FallenPartsDestroyHeight
            local radius = MISSILE_RADIUS

            for step = 1, MAX_STEPS do
                local time = step * STEP_TIME
                local nextPosition = origin + velocity * time - Vector3.new(0, 0.5 * accelY * time * time, 0)
                local delta = nextPosition - position
                local distance = delta.Magnitude

                if distance > 1e-4 then
                    for _ = 1, 16 do
                        local result

                        if hasSpherecast then
                            result = workspace:Spherecast(position, radius, delta, missileParams)
                        else
                            result = workspace:Raycast(position, delta, missileParams)
                        end

                        if not result then
                            break
                        end

                        local kind, humanoid = classifyMissileHit(result.Instance, killers)

                        if kind then
                            local fraction = math.clamp(result.Distance / distance, 0, 1)
                            points[#points + 1] = position + delta * fraction

                            return {
                                points = points,
                                impact = {
                                    position = result.Position,
                                    normal = result.Normal,
                                    kind = kind,
                                    humanoid = humanoid,
                                    time = (step - 1 + fraction) * STEP_TIME,
                                },
                            }
                        end

                        ignored[#ignored + 1] = result.Instance
                        missileParams.FilterDescendantsInstances = ignored
                    end
                end

                points[#points + 1] = nextPosition
                position = nextPosition

                if nextPosition.Y < floorY or (nextPosition - origin).Magnitude > MAX_RANGE then
                    break
                end
            end

            return { points = points }
        end

        -- [Grenade Trajectory / Drawing] Line pools, near-plane clipping and the info label
        local function destroyDrawing(drawing)
            pcall(function()
                if drawing.Remove then
                    drawing:Remove()
                else
                    drawing:Destroy()
                end
            end)
        end

        local function getLine(pool, index)
            local line = pool[index]

            if not line then
                line = Drawing.new("Line")
                line.Transparency = 1
                line.ZIndex = 5
                line.Visible = false
                pool[index] = line
            end

            return line
        end

        local function hidePool(pool, fromIndex)
            for index = fromIndex, #pool do
                pool[index].Visible = false
            end
        end

        local function getInfoLabel()
            if not infoLabel then
                infoLabel = Drawing.new("Text")
                infoLabel.Center = true
                infoLabel.Outline = true
                infoLabel.OutlineColor = Color3.new(0, 0, 0)
                infoLabel.Color = Color3.new(1, 1, 1)
                infoLabel.Size = 16
                infoLabel.Transparency = 1
                infoLabel.ZIndex = 6
                infoLabel.Visible = false
            end

            return infoLabel
        end

        -- Projects a world-space segment to the screen, clipping the part that is behind the camera.
        local function projectSegment(cam, camPosition, camLook, from, to)
            local fromDepth = camLook:Dot(from - camPosition)
            local toDepth = camLook:Dot(to - camPosition)

            if fromDepth < NEAR_PLANE and toDepth < NEAR_PLANE then
                return nil, nil
            end

            if fromDepth < NEAR_PLANE then
                from = from + (to - from) * ((NEAR_PLANE - fromDepth) / (toDepth - fromDepth))
            elseif toDepth < NEAR_PLANE then
                to = from + (to - from) * ((NEAR_PLANE - fromDepth) / (toDepth - fromDepth))
            end

            local fromScreen = cam:WorldToViewportPoint(from)
            local toScreen = cam:WorldToViewportPoint(to)

            return Vector2.new(fromScreen.X, fromScreen.Y), Vector2.new(toScreen.X, toScreen.Y)
        end

        -- [Grenade Trajectory / Killer highlight] One Highlight on the killer the grenade is predicted to hit
        local function getHighlightContainer()
            if highlightContainer and highlightContainer.Parent then
                return highlightContainer
            end

            highlightContainer = Instance.new("Folder")
            highlightContainer.Name = "GrenadeTrajectoryHighlights"

            local success = type(gethui) == "function" and pcall(function()
                highlightContainer.Parent = gethui()
            end)

            if not success or not highlightContainer.Parent then
                highlightContainer.Parent = game:GetService("CoreGui")
            end

            return highlightContainer
        end

        local function clearHighlights()
            for model, highlight in pairs(highlights) do
                pcall(function() highlight:Destroy() end)
                highlights[model] = nil
            end
        end

        local function setHighlightTarget(model, color)
            for existing, highlight in pairs(highlights) do
                if existing ~= model or not highlight.Parent then
                    pcall(function() highlight:Destroy() end)
                    highlights[existing] = nil
                end
            end

            if not model then
                return
            end

            local highlight = highlights[model]

            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "GrenadeTrajectoryHit"
                highlight.Adornee = model
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.Parent = getHighlightContainer()
                highlights[model] = highlight
            end

            highlight.FillColor = color
            highlight.OutlineColor = color
        end

        local function hideVisuals()
            hidePool(pathLines, 1)
            hidePool(ringLines, 1)

            if infoLabel then
                infoLabel.Visible = false
            end

            setHighlightTarget(nil)
        end

        -- [Grenade Trajectory / Frame update]
        local function updatePreview()
            if library.Unloaded then
                return
            end

            local cam = workspace.CurrentCamera
            local character = localplayer.Character
            local tool, scoped

            if cam and character then
                tool, scoped = getActiveLauncher(character)
            end

            local muzzlePart = tool and getMuzzlePart(tool, scoped)

            if not muzzlePart then
                hideVisuals()
                return
            end

            local charactersFolder = workspace:FindFirstChild("Characters to kill")
            local killers = workspace:FindFirstChild("Killers")
            local origin = muzzlePart.Position

            local mouse = uis:GetMouseLocation()
            local ray = cam:ViewportPointToRay(mouse.X, mouse.Y)
            local aimPoint = findAimPoint(ray.Origin, ray.Direction * AIM_RAY_LENGTH, charactersFolder, killers)
            local aimVector = aimPoint - origin

            if aimVector.Magnitude < 1e-3 then
                hideVisuals()
                return
            end

            local velocity = aimVector.Unit * MUZZLE_SPEED
            local accelY = workspace.Gravity - LAUNCHER_UP_FORCE / getMissileMass()
            local path = simulateMissile(origin, velocity, accelY, charactersFolder, killers)
            local impact = path.impact

            local killerHit = impact ~= nil and impact.kind == "killer" and toggles.trajectoryKillerHighlight_Toggle.Value
            local killerColor = options.trajectoryKillerColor_ColorPicker.Value
            local pathColor = killerHit and killerColor or options.trajectoryPathColor_ColorPicker.Value
            local landingColor = killerHit and killerColor or options.trajectoryLandingColor_ColorPicker.Value
            local thickness = options.trajectoryThickness_Slider.Value

            local camPosition = cam.CFrame.Position
            local camLook = cam.CFrame.LookVector

            -- Flight path
            local points = path.points
            local lineCount = 0

            for index = 1, #points - 1 do
                local from, to = projectSegment(cam, camPosition, camLook, points[index], points[index + 1])

                if from then
                    lineCount += 1

                    local line = getLine(pathLines, lineCount)
                    line.From = from
                    line.To = to
                    line.Color = pathColor
                    line.Thickness = thickness
                    line.Visible = true
                end
            end

            hidePool(pathLines, lineCount + 1)

            -- Landing ring, lying on the surface that was hit
            local ringCount = 0

            if impact then
                local radius = options.trajectoryMarkerSize_Slider.Value
                local normal = impact.normal
                local reference = math.abs(normal.Y) < 0.99 and Vector3.yAxis or Vector3.xAxis
                local tangent = normal:Cross(reference).Unit
                local bitangent = normal:Cross(tangent)
                local center = impact.position + normal * 0.05
                local previous = center + tangent * radius

                for index = 1, RING_SEGMENTS do
                    local angle = (index / RING_SEGMENTS) * math.pi * 2
                    local nextPoint = center + (tangent * math.cos(angle) + bitangent * math.sin(angle)) * radius
                    local from, to = projectSegment(cam, camPosition, camLook, previous, nextPoint)

                    if from then
                        ringCount += 1

                        local line = getLine(ringLines, ringCount)
                        line.From = from
                        line.To = to
                        line.Color = landingColor
                        line.Thickness = thickness
                        line.Visible = true
                    end

                    previous = nextPoint
                end
            end

            hidePool(ringLines, ringCount + 1)

            -- Distance / time label above the landing spot
            if impact and toggles.trajectoryShowInfo_Toggle.Value then
                local screen = cam:WorldToViewportPoint(impact.position)

                if screen.Z > 0 then
                    local text = string.format("%d studs | %.1fs", math.floor((impact.position - origin).Magnitude + 0.5), impact.time)

                    if killerHit then
                        text ..= " | " .. impact.humanoid.Parent.Name
                    end

                    local label = getInfoLabel()
                    label.Text = text
                    label.Position = Vector2.new(screen.X, screen.Y - 30)
                    label.Visible = true
                else
                    getInfoLabel().Visible = false
                end
            elseif infoLabel then
                infoLabel.Visible = false
            end

            if killerHit then
                setHighlightTarget(impact.humanoid.Parent, killerColor)
            else
                setHighlightTarget(nil)
            end
        end

        local function stepPreview()
            local success, err = pcall(updatePreview)

            if not success and os.clock() - lastErrorTime > 5 then
                lastErrorTime = os.clock()
                warn("[Grenade Trajectory] " .. tostring(err))
            end
        end

        local function startPreview()
            if running then
                return
            end

            running = true

            pcall(function() runService:UnbindFromRenderStep(RENDER_NAME) end)
            runService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Last.Value, stepPreview)
        end

        local function stopPreview()
            running = false

            pcall(function() runService:UnbindFromRenderStep(RENDER_NAME) end)

            for index, line in ipairs(pathLines) do
                destroyDrawing(line)
                pathLines[index] = nil
            end

            for index, line in ipairs(ringLines) do
                destroyDrawing(line)
                ringLines[index] = nil
            end

            if infoLabel then
                destroyDrawing(infoLabel)
                infoLabel = nil
            end

            clearHighlights()

            if highlightContainer then
                pcall(function() highlightContainer:Destroy() end)
                highlightContainer = nil
            end
        end

        toggles.trajectoryPreview_Toggle:OnChanged(function(enabled)
            if enabled then
                if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
                    notify("Error", "Drawing unsupported", "Your executor does not support the Drawing library.", 8)
                    toggles.trajectoryPreview_Toggle:SetValue(false)
                    return
                end

                startPreview()
            else
                stopPreview()
            end
        end)

        table.insert(teardownTasks, stopPreview)
    end

    buildGrenadeTrajectory()
end

-- ============================================================================
-- 12 | TAB: WORLD
-- ============================================================================

local worldGroup = tabs.world:AddLeftGroupbox("World")
local unlockAlienGroup = tabs.world:AddRightGroupbox("Alien")

-- [World / Environment] Hazards, radioactive area, and kill parts

worldGroup:AddToggle("disableCactuses_Toggle", { Text = "Disable Cactuses", Tooltip = false })
worldGroup:AddToggle("removeBearTraps_Toggle", { Text = "Remove Bear Traps", Tooltip = false })
worldGroup:AddToggle("disableRadioactiveZone_Toggle", { Text = "Disable Radioactive Zone", Tooltip = false })

worldGroup:AddToggle("disableKillParts_Toggle", { Text = "Disable Kill Parts", Tooltip = "Disables parts that can damage or kill you such as fans/spinners, polluted water, etc." })

toggles.disableCactuses_Toggle:OnChanged(function(enabled)
    for _, cactus in pairs(area51.Outside.Cactus:GetDescendants()) do
        if cactus:IsA("BasePart") then
            cactus.CanTouch = not enabled
        end
    end
end)

toggles.removeBearTraps_Toggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.removeBearTraps_Toggle.Value do

                    for _, bearTrap in ipairs(game:GetService("Workspace"):GetChildren()) do
                        if bearTrap:IsA("BasePart") and bearTrap.Name == "BearTrap" then
                            bearTrap:Destroy()
                        end
                    end

                task.wait(0.1)
            end
        end)
    end
end)

toggles.disableRadioactiveZone_Toggle:OnChanged(function(enabled)
    -- Disable damage

    for _, obj in ipairs(area51.RadioactiveArea:GetChildren()) do
        if obj.Name == "Entrance" and obj:IsA("BasePart") then
            obj.CanTouch = not enabled
        end
    end

    -- Disable radioactive smoke/fog

    area51.RadioactiveArea.RadioactiveDrop.Part.Smoke.Enabled = not enabled

    if enabled then
        -- Disable color change

        local script = area51.RadioactiveArea.RadioactiveDrop.Drops:FindFirstChild("Color change")

        if script then
            script.Parent = game:GetService("Teams")
        end

        -- Remove barriers

        for _, barriers in ipairs(area51.RadioactiveArea.Floor1.Barrier:GetChildren()) do
            barriers.Parent = game:GetService("Chat")
        end

        -- Remove entrance

        for _, entrance in ipairs(area51.RadioactiveArea.Floor1.Entrance:GetChildren()) do
            entrance.Parent = game:GetService("Lighting")
        end

        for _, dirt in ipairs(area51.RadioactiveArea.Floor1.Dirt:GetChildren()) do
            dirt.Parent = game:GetService("StarterGui")
        end
    else
        -- Disable color change

        local script = game:GetService("Teams"):FindFirstChild("Color change")

        if script then
            script.Parent = area51.RadioactiveArea.RadioactiveDrop.Drops
        end

        -- Remove barriers

        for _, barriers in ipairs(game:GetService("Chat"):GetChildren()) do
            barriers.Parent = area51.RadioactiveArea.Floor1.Barrier
        end

        -- Remove entrance

        for _, entrance in ipairs(game:GetService("Lighting"):GetChildren()) do
            entrance.Parent = area51.RadioactiveArea.Floor1.Entrance
        end

        for _, dirt in ipairs(game:GetService("StarterGui"):GetChildren()) do
            dirt.Parent = area51.RadioactiveArea.Floor1.Dirt
        end
    end
end)

-- [World / Kill Parts] Discovery, highlighting, and state restoration
local function getKillParts()
    local parts = {
        area51.CentralSewerRoom.Spinner.Kill,
        area51.GarbageSewer.KillTop,
        area51.SewerCaptainRoom.Spinner.Kill,
        area51.TrashGrindRoom.Spinner.Kill,
        area51.WasteRoom.Spinner.Kill,
        area51.MaterialOrdererRoom.GreenThing,
        area51.WasteRoom["Polluted Water"]["Toxic Water"].Kill,
        area51.WasteRoom["Polluted Water"]["Toxic Water"]:GetChildren()[2],
        area51.CleanerTwoRoom["Polluted Water"]["Polluted Water"]
    }

    for _, deathPart in ipairs(area51.MultiDirectionalRoom.Deadly:GetChildren()) do
        if deathPart:IsA("BasePart") then
            table.insert(parts, deathPart)
        end
    end

    return parts
end

local function highlightPart(part)
    if part:FindFirstChild("_CelestialKillPartESP") then return end

    local highlight = Instance.new("Highlight", part)
    highlight.Name = "_CelestialKillPartESP"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
end

local function removeHighlight(part)
    local highlight = part:FindFirstChild("_CelestialKillPartESP")
    if highlight then
        highlight:Destroy()
    end
end

local function storeKillParts()
    for _, part in ipairs(getKillParts()) do
        entityLib.storeData(part, "CanTouch", true)
        entityLib.storeData(part, "CanCollide", true)
        entityLib.storeData(part, "Transparency", true)
    end
end

local function setKillPartState(part, enabled)
    if not part:IsA("BasePart") then return end

    if enabled then
        entityLib.storeData(part, "CanTouch", true)
        entityLib.storeData(part, "CanCollide", true)
        entityLib.storeData(part, "Transparency", true)

        part.CanTouch = false
        part.CanCollide = true
        part.Transparency = 0

        highlightPart(part)
    else
        entityLib.restoreData(part, "CanTouch")
        entityLib.restoreData(part, "CanCollide")
        entityLib.restoreData(part, "Transparency")

        removeHighlight(part)
    end
end

storeKillParts()

toggles.disableKillParts_Toggle:OnChanged(function(enabled)
    local killParts = getKillParts()

    for _, part in ipairs(killParts) do
        setKillPartState(part, enabled)
    end
end)


-- [World / Alien] Code display and navigation actions

local alienCode = area51.CodeModel.Code.Value

unlockAlienGroup:AddLabel("Code: " .. alienCode, true)
unlockAlienGroup:AddToggle("viewAlienCode_Toggle", { Text = "View Code", Tooltip = false })
unlockAlienGroup:AddDropdown("codeRevealMethod_Dropdown", { Text = "Code Reveal Method", Tooltip = false, Values = { "Announce", "Silent" }, Default = 2, Multi = false, Searchable = false })

unlockAlienGroup:AddButton({ Text = "Reveal Code",
    Func = function()
        local method = options.codeRevealMethod_Dropdown.Value

        if method == "Announce" then
            utils.sendMessage("The alien code is " .. alienCode)
        else
            notify("Info", "Alien code", "The alien code is " .. alienCode, options.silentModeNotifDuration_Slider.Value)
        end
    end,
})

unlockAlienGroup:AddSlider("silentModeNotifDuration_Slider", { Text = "Notification Time", Tooltip = "Controls how long the notification will last when using 'Silent.'", Default = 15, Min = 5, Max = 30, Compact = true, Suffix = " Seconds", Rounding = 0 })

unlockAlienGroup:AddButton({ Text = "Code Input",
    Func = function()
        entityLib.teleport(CFrame.new(137.72377, 333.499939, 525.566956))
    end,
})

unlockAlienGroup:AddButton({ Text = "Alien Door",
    Func = function()
        entityLib.teleport(CFrame.new(226.598221, 333.499939, 472.223358))
    end,
})

toggles.viewAlienCode_Toggle:OnChanged(function(enabled)
    if enabled then
        camera.CameraSubject = area51.CodeModel
    else
        local hum = getHumanoid()
        camera.CameraSubject = hum
    end
end)

localplayer.CharacterAdded:Connect(function(char)
    if toggles.viewAlienCode_Toggle.Value then
        toggles.viewAlienCode_Toggle:SetValue(false)
    end
end)

-- ============================================================================
-- 13 | TAB: WEAPONS
-- ============================================================================

tabs.weapons:UpdateWarningBox({ Title = "Warning", Text = "Usage of any gun mods has a high chance of resulting in a permanent game ban.", Visible = true })

local weaponsGroup = tabs.weapons:AddLeftGroupbox("Weapons")
local defenseGroup = tabs.weapons:AddRightGroupbox("Defense")
local othersGroup = tabs.weapons:AddRightGroupbox("Other")

-- [Weapons / Inventory] Weapon catalog, acquisition, and selection

-- [Weapons / Inventory] Restricted weapon rules
local restrictedWeapons = {
    Crossbow = true,
    MG42 = true,
    FreezeGun = true
}

-- [Weapons / Inventory] Build the selectable weapon catalog
local weaponNames = {}
local giveWeaponBtn, papWeaponBtn, papHeldBtn

for _, weapon in ipairs(game:GetService("Workspace").Weapons:GetChildren()) do
    table.insert(weaponNames, weapon.Name)
end

weaponsGroup:AddDropdown("weaponsList_Dropdown", { Text = "Obtain Weapon(s)", Tooltip = false, Values = weaponNames, Default = nil, Multi = true, Searchable = true,
    Callback = function(val)
        local selectedNames = {}
        for name, isSelected in pairs(val) do
            if isSelected then
                table.insert(selectedNames, name)
            end
        end

        if #selectedNames == 0 then
            giveWeaponBtn:SetText("Obtain Weapon")
            papWeaponBtn:SetText("Pack a Punch Weapon")
            return
        end

        local displayLimit = 2
        if #selectedNames > displayLimit then
            local shown = table.concat({ unpack(selectedNames, 1, displayLimit) }, ", ")
            local extra = #selectedNames - displayLimit
            giveWeaponBtn:SetText("Obtain " .. shown .. ", +" .. extra .. " more")
            papWeaponBtn:SetText("Pack a Punch  " .. shown .. ", +" .. extra .. " more")
        else
            giveWeaponBtn:SetText("Obtain " .. table.concat(selectedNames, ", "))
            papWeaponBtn:SetText("Pack a Punch " .. table.concat(selectedNames, ", "))
        end
    end,
})

weaponsGroup:AddDropdown("giveWeaponMethod_Dropdown", { Text = "Method", Tooltip = false, Values = { "Touch Events", "ProximityPrompt" }, Default = 1, Multi = false, Searchable = false })

-- [Weapons / Inventory] Acquire the selected weapons
local function obtainSelectedWeapons()
    local selected = options.weaponsList_Dropdown.Value
    local anySelected = false
    local hrp = getHRP()

    local alreadyHave = {}
    local givenWeapons = {}
    local weaponsToGive = {}

    for weaponName, isSelected in pairs(selected) do
        if isSelected then
            if restrictedWeapons[weaponName] then
                notify("Error", "Unable to pack-a-punch", weaponName .. " cannot be given and can only be pack a punched due to requirements/gamepasses.", 14)
            else
                anySelected = true

                local hasBase = entityLib.getTool("Specific", weaponName)
                local hasPAP = entityLib.getTool("Specific", "PAP" .. weaponName)

                if hasBase or hasPAP then
                    table.insert(alreadyHave, weaponName)
                else
                    local weapon = game.Workspace.Weapons:FindFirstChild(weaponName)

                    if weapon and weapon:FindFirstChild("Hitbox") then
                        table.insert(weaponsToGive, weapon)
                    else
                        notify("Error", "No available hitbox", weaponName .. " is missing or has no available hitbox.", 13)
                    end
                end
            end
        end
    end

    local method = options.giveWeaponMethod_Dropdown.Value
    for _, weapon in ipairs(weaponsToGive) do
        if method == "Touch Events" then
            utils.fireTouchEvent(hrp, weapon.Hitbox)
        else
            weapon.Hitbox.CanCollide = false

            entityLib.storeData(hrp, "CFrame", true)

            entityLib.teleport(weapon.Hitbox)
            task.wait(0.01)

            entityLib.restoreData(hrp, "CFrame")
            entityLib.clearData(hrp, "CFrame")

            weapon.Hitbox.CanCollide = true
        end
    end

    for _, weapon in ipairs(weaponsToGive) do
        repeat task.wait() until entityLib.getTool("Specific", weapon.Name)
        table.insert(givenWeapons, weapon.Name)
    end

    if #alreadyHave > 0 then
        notify("Error", "Cannot give weapons", "You already have the following weapons: " .. table.concat(alreadyHave, ", "), 8)
    end

    if #givenWeapons > 0 then
        notify("Success", "Gave weapons", "You have been given the following weapons: " .. table.concat(givenWeapons, ", "), 5)
        if toggles.clearOnAction_Toggle.Value then
            options.weaponsList_Dropdown:SetValue({})
        end
    end

    if not anySelected then
        notify("Error", "Invalid selection", "No weapons selected.", 8)
    end
end

giveWeaponBtn = weaponsGroup:AddButton({ Text = "Obtain Weapon",
    Func = function()
        obtainSelectedWeapons()
    end,
})

-- [Weapons / Pack-a-Punch] Validate weapon, satisfy requirements, and enter teleporter
local function pap(weaponName, selectedWeapons, currentIndex)
    -- Validate selected weapon

    if not entityLib.getTool("Specific", weaponName) then
        notify("Error", "Unavailable tool", "You don't have " .. weaponName .. " in your inventory. Skipping...", 6)
        return false
    end

    -- Validate required kill count

    local requirements = require(game:GetService("StarterPlayer").StarterPlayerScripts.LocalAnimations["Classic area"].Teleportation.PackAPunch["Classic mode"].Requirements)
    local requiredKills = requirements[weaponName]
    local kills = game:GetService("Players").LocalPlayer.leaderstats["Killers Killed"].Value

    if requiredKills and kills < requiredKills then
        local needed = requiredKills - kills
        notify("Error", "Insufficient kills", weaponName .. " requires " .. requiredKills .. " kills to pack a punch. You need " .. needed .. " more.", 7)
        return false
    end

    -- Teleport to the control panel, activate the teleporter (with retries) and validate the punch room (bedroom)

    freeze(true)

    local teleported, teleportResult = utils.runPAPTeleport(weaponName, function() return cancelPAPQueue end)

    if not teleported then
        local failReason = teleportResult

        -- On death the humanoid is replaced, so there is nothing to unfreeze
        if failReason ~= "died" then
            freeze(false)
        end

        if failReason == "retries" then
            notify("Error", "Teleporter unresponsive", "The teleporter did not respond after several attempts. Please try again.", 8)
        elseif failReason == "busy" then
            notify("Error", "Teleporter busy", "The teleporter stayed in use by another player. Please try again later.", 8)
        elseif failReason == "arrival" then
            notify("Error", "Teleport failed", "You did not reach the punch room. Please try again.", 8)
        elseif failReason == "error" then
            notify("Error", "Teleport failed", "Something went wrong while using the teleporter.", 6)
        end

        return false
    end

    -- PAP weapon

    game:GetService("Workspace").PACKAPUNCH.PAPStarted:FireServer(weaponName)
    game:GetService("Workspace").PACKAPUNCH.PAPFinished:FireServer()

    -- "Teleport finished" has done its job once the weapon is being pack a punched
    utils.dismissNotify(teleportResult)

    -- The last weapon of a multi-weapon queue is announced by the queue-finished notification instead
    local isLastInQueue = selectedWeapons ~= nil and currentIndex ~= nil and #selectedWeapons > 1 and currentIndex == #selectedWeapons

    if not isLastInQueue then
        notify("Success", "Success", weaponName .. " has been pack a punched!", 7)
    end

    -- Notify remaining queue

    if selectedWeapons and currentIndex then
        local remaining = {}
        for i = currentIndex + 1, #selectedWeapons do
            table.insert(remaining, selectedWeapons[i])
        end

        if #remaining > 0 then
            -- Stays up until the next queue update replaces it (or the queue is empty/cleared)
            utils.setPAPQueueNote("Queue updated", "Remaining in queue (" .. #remaining .. "): " .. table.concat(remaining, ", "))
        else
            utils.clearPAPQueueNote()
        end
    end

    freeze(false)
    return true
end

papWeaponBtn = weaponsGroup:AddButton({ Text = "PAP Weapon",
    Func = function()
        cancelPAPQueue = false
        local origCFrame = getHRP().CFrame

        papWeaponBtn:SetDisabled(true)
        papHeldBtn:SetDisabled(true)

        local player = game:GetService("Players").LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")

        local died = false
        local deathConnection = humanoid.Died:Connect(function()
            died = true
            utils.clearPAPQueueNote()
            notify("Error", "Process interrupted", "You died during Pack-a-Punch. Process stopped.", 7)
            papWeaponBtn:SetDisabled(false)
            papHeldBtn:SetDisabled(false)
        end)

        task.spawn(function()
            local requirements = require(game:GetService("StarterPlayer").StarterPlayerScripts.LocalAnimations["Classic area"].Teleportation.PackAPunch["Classic mode"].Requirements)
            local kills = player.leaderstats["Killers Killed"].Value
            local selected = options.weaponsList_Dropdown.Value
            local selectedWeapons = {}

            for name, isSelected in pairs(selected) do
                if isSelected then
                    if entityLib.getTool("Specific", "PAP" .. name) then
                        notify("Info", "Cannot pack-a-punch", "You already have PAP" .. name .. ". Skipping...", 5)
                    elseif string.sub(name, 1, 3) == "PAP" then
                        notify("Info", "Cannot pack-a-punch", name .. " is already pack a punched. Skipping...", 5)
                    else
                        table.insert(selectedWeapons, name)
                    end
                end
            end

            local anyPunched = false
            local punchedCount = 0

            for index, weaponName in ipairs(selectedWeapons) do
                if died or cancelPAPQueue then break end

                local hasBase = entityLib.getTool("Specific", weaponName)
                local hasPAP = entityLib.getTool("Specific", "PAP" .. weaponName)

                if not (hasBase or hasPAP) then
                    notify("Error", "Unavailable weapon", "You don't have " .. weaponName .. ". Cannot pack a punch.", 6)
                else
                    local requiredKills = requirements[weaponName] or 0
                    if kills < requiredKills then
                        notify("Error", "Insufficient kills", "Not enough kills to pack a punch " .. weaponName .. ". Need " .. (requiredKills - kills) .. " more kills.", 6)
                    else
                        local waitNote = nil

                        repeat
                            if died or cancelPAPQueue then break end

                            local busy = teleporterInUse()

                            if busy and not wasTeleporterBusy then
                                wasTeleporterBusy = true

                                local pending = {}
                                for i = index, #selectedWeapons do
                                    table.insert(pending, selectedWeapons[i])
                                end

                                waitNote = utils.papNotify("Info", "Waiting..", "Teleporter in use. Waiting to pack a punch: " .. table.concat(pending, ", "))

                            elseif not busy and wasTeleporterBusy then
                                wasTeleporterBusy = false
                                utils.dismissNotify(waitNote)
                                waitNote = nil
                                notify("Info", "Teleporter available", "Teleporter is now available.", 3)
                            end

                            task.wait(0.2)
                        until not teleporterInUse() or died or cancelPAPQueue

                        -- Covers leaving the wait through a cancel or death
                        utils.dismissNotify(waitNote)

                        if cancelPAPQueue then
                            local cancelNote = utils.papNotify("Info", "Queue canceled", "Pack-a-Punch queue canceled. Waiting to return...")

                            local returnCFrame = CFrame.new(219.199997, 323.500061, 845.900024)

                            -- Wait until you're at the return cframe/in the gun room place BEFORE stopping
                            repeat
                                task.wait()
                                local currentHRP = getHRP()
                            until (currentHRP and entityLib.checkCFrame(currentHRP, returnCFrame, 5)) or died

                            utils.dismissNotify(cancelNote)
                            break
                        end

                        local success = pap(weaponName, selectedWeapons, index)
                        if success then
                            anyPunched = true
                            punchedCount += 1
                        else
                            if not (cancelPAPQueue or died) then
                                notify("Error", "Failed", "Failed to pack a punch " .. weaponName, 5)
                            end
                            break
                        end

                        local returnCFrame = CFrame.new(219.199997, 323.500061, 845.900024)
                        -- Wait until current HRP reaches return position
                        repeat
                            task.wait()
                            local currentHRP = getHRP()
                        until (currentHRP and entityLib.checkCFrame(currentHRP, returnCFrame, 5)) or died

                    end
                end
            end

            -- After ALL weapons have been processed
            utils.clearPAPQueueNote()

            if not died then
                local currentHRP = getHRP()
                if currentHRP and origCFrame then
                    entityLib.teleport(origCFrame)
                end
            end

            if not died then
                if anyPunched then
                    if #selectedWeapons > 1 then
                        if punchedCount == #selectedWeapons then
                            notify("Success", "Queue finished", "All weapons have been pack a punched!", 7)
                        else
                            notify("Success", "Queue finished", punchedCount .. " of " .. #selectedWeapons .. " weapons have been pack a punched.", 7)
                        end
                    end
                    if toggles.clearOnAction_Toggle.Value then
                        options.weaponsList_Dropdown:SetValue({})
                    end
                else
                    notify("Info", "None pack-a-punched", "No weapons were pack a punched.", 6)
                end

                papWeaponBtn:SetDisabled(false)
                papHeldBtn:SetDisabled(false)
            end

            deathConnection:Disconnect()
        end)
    end,
})

papHeldBtn = papWeaponBtn:AddButton({ Text = "PAP Held Weapon",
    Func = function()
        cancelPAPQueue = false
        local origCFrame = getHRP().CFrame

        local heldTool = entityLib.getTool("Held")
        if not heldTool then
            notify("Error", "No weapon", "You're not holding a weapon.", 5)
            return
        end

        local heldWeapon = heldTool.Name

        papWeaponBtn:SetDisabled(true)
        papHeldBtn:SetDisabled(true)

        local player = game:GetService("Players").LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")

        local died = false
        local deathConnection = humanoid.Died:Connect(function()
            died = true
            utils.clearPAPQueueNote()
            notify("Error", "Process canceled", "You died during the pack-a-punch process and it has been stopped.", 7)
            papWeaponBtn:SetDisabled(false)
            papHeldBtn:SetDisabled(false)
        end)

        task.spawn(function()
            if died then return end

            local success = pap(heldWeapon)
            if success and not died then
                local returnCFrame = CFrame.new(219.199997, 323.500061, 845.900024)

                -- Wait for current HRP to reach return position
                repeat
                    task.wait()
                    local currentHRP = getHRP()
                until (currentHRP and entityLib.checkCFrame(currentHRP, returnCFrame, 5)) or died

                -- teleport back
                if not died then
                    local currentHRP = getHRP()
                    if currentHRP and origCFrame then
                        entityLib.teleport(origCFrame)
                    end

                    notify("Success", "Success", heldWeapon .. " has been pack a punched!", 6)

                    if toggles.clearOnAction_Toggle.Value then
                        options.weaponsList_Dropdown:SetValue({})
                    end
                end
            end

            if not died then
                papWeaponBtn:SetDisabled(false)
                papHeldBtn:SetDisabled(false)
            end

            deathConnection:Disconnect()
        end)
    end,
})

weaponsGroup:AddButton({ Text = "Select All Weapons",
    Func = function()
        local allWeapons = options.weaponsList_Dropdown.Values
        local selection: {[string]: boolean} = {}

        for _, weaponName in ipairs(allWeapons) do
            if not restrictedWeapons[weaponName] then
                selection[weaponName] = true
            end
        end

        options.weaponsList_Dropdown:SetValue(selection)
    end,
})

weaponsGroup:AddButton({ Text = "Clear Selection",
    Func = function()
        options.weaponsList_Dropdown:SetValue({})
    end,
})

weaponsGroup:AddButton({ Text = "Clear Queue", Tooltip = "Stops and clears the Pack a Punch queue.",
    Func = function()
        cancelPAPQueue = true
        utils.clearPAPQueueNote()

        notify("Success", "Cleared queue", "Pack a Punch queue has been cleared and canceled.", 5)
    end,
})

weaponsGroup:AddToggle("fireOnRespawn_Toggle", { Text = "Fire On Respawn", Tooltip = "Automatically gives the selected weapons after you respawn.", Default = false })

localplayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if toggles.fireOnRespawn_Toggle.Value then
        obtainSelectedWeapons()
    end
end)


weaponsGroup:AddToggle("clearOnAction_Toggle", { Text = "Clear on Action", Tooltip = "Clears the selected weapons when you obtain, pack a punch it, etc.", Default = false })
weaponsGroup:AddLabel("Due to recent updates, you can only pack a punch one weapon per teleporter usage. Meaning one weapon can be pack a punched for each teleport.", true)
local teleporterStateLabel = weaponsGroup:AddLabel("Teleporter: " .. getTeleporterState(), true)

local isUpdatingTeleporterState = true
task.spawn(function()
    while isUpdatingTeleporterState do
        teleporterStateLabel:SetText("Teleporter: " .. getTeleporterState())
        task.wait(0.1)
    end
end)


-- [Weapons / Defense] Morph, armor, helmet, and glow settings

defenseGroup:AddToggle("zombieMorph_Toggle", { Text = "Zombie Morph", Tooltip = false })

local zombieMorphDepbox = defenseGroup:AddDependencyBox()

zombieMorphDepbox:AddToggle("disableSelfGlow_Toggle", { Text = "Disable Self Glow", Tooltip = "Disables the green glow from you only." })
zombieMorphDepbox:AddToggle("normalAppearance_Toggle", { Text = "Normal Appearance", Tooltip = "Shows your normal character instead of the zombie morph's green skin. The morph stays worn, only its look is hidden." })

defenseGroup:AddToggle("obtainArmor_Toggle", { Text = "Obtain Armor", Tooltip = false })
defenseGroup:AddToggle("obtainHelmet_Toggle", { Text = "Obtain Helmet", Tooltip = false, Disabled = not (getMode() == "Extreme"), DisabledTooltip = "This feature is not available in this mode." })

zombieMorphDepbox:SetupDependencies({ { toggles.zombieMorph_Toggle, true } })

do
    -- Zombie morph appearance
    local zombieSkinModels = { "Chest", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }
    local normalBodyLookup = {}
    for _, name in ipairs({
        "Head", "UpperTorso", "LowerTorso",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot",
    }) do
        normalBodyLookup[name] = true
    end

    local morphAppearanceChar = nil
    local morphAppearanceConnections = {}

    -- Returns the Transparency this instance should have, or nil if it isn't part of the swap
    local function getMorphTransparency(char, inst, showZombieSkin)
        if inst.Parent == char and inst:IsA("BasePart") and normalBodyLookup[inst.Name] then
            return showZombieSkin and 1 or 0
        end

        -- Zombie skin parts and the decals on them (red eyes). "Middle" parts are invisible helpers, leave them alone
        if (inst:IsA("BasePart") and inst.Name ~= "Middle") or inst:IsA("Decal") or inst:IsA("Texture") then
            for _, name in ipairs(zombieSkinModels) do
                local model = char:FindFirstChild(name)
                if model and inst:IsDescendantOf(model) then
                    return showZombieSkin and 0 or 1
                end
            end
        end

        return nil
    end

    local function applyMorphAppearance(char, showZombieSkin)
        for _, inst in ipairs(char:GetDescendants()) do
            local transparency = getMorphTransparency(char, inst, showZombieSkin)
            if transparency then
                inst.Transparency = transparency
            end
        end
    end

    -- Keeps one instance in the right state while Normal Appearance is on (covers the server changing it later)
    local function watchMorphInstance(char, inst)
        if not (inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("Texture")) then
            return
        end

        local function enforce()
            if toggles.normalAppearance_Toggle.Value then
                local transparency = getMorphTransparency(char, inst, false)
                if transparency then
                    inst.Transparency = transparency
                end
            end
        end

        enforce()
        table.insert(morphAppearanceConnections, inst:GetPropertyChangedSignal("Transparency"):Connect(enforce))
    end

    local function refreshMorphAppearance(char)
        task.spawn(function()
            -- The server builds the morph after the button is touched, so wait for it to show up.
            -- Without a morph there is nothing to swap, so the normal body is left untouched.
            if not (char and char:WaitForChild("Chest", 10)) then
                return
            end

            -- Watch the character once, so anything added or changed later (like the eyes decal) is handled too
            if morphAppearanceChar ~= char then
                for _, connection in ipairs(morphAppearanceConnections) do
                    connection:Disconnect()
                end
                table.clear(morphAppearanceConnections)
                morphAppearanceChar = char

                for _, inst in ipairs(char:GetDescendants()) do
                    watchMorphInstance(char, inst)
                end

                table.insert(morphAppearanceConnections, char.DescendantAdded:Connect(function(inst)
                    watchMorphInstance(char, inst)
                end))
            end

            applyMorphAppearance(char, not toggles.normalAppearance_Toggle.Value)
        end)
    end

    toggles.normalAppearance_Toggle:OnChanged(function()
        refreshMorphAppearance(localplayer.Character)
    end)

    toggles.zombieMorph_Toggle:OnChanged(function(enabled)
        if enabled then
            -- Morph

            local hrp = getHRP()
            if hrp then
                utils.fireTouchEvent(hrp, area51.Outside.Hangar.Right["Zombie Morph"].TheButton)
                refreshMorphAppearance(localplayer.Character)

                -- The morph can't be taken off, so lock the toggle until the next respawn
                toggles.zombieMorph_Toggle:SetDisabled(true)
            else
                notify("Error", "Unavailable root", "Could not find HumanoidRootPart.", 10)
                toggles.zombieMorph_Toggle:SetValue(false)
            end
        end
    end)

    toggles.disableSelfGlow_Toggle:OnChanged(function(enabled)
        -- OnChanged fires once at load, and Chest only exists while the zombie morph is worn,
        -- so every step of the lookup has to handle a missing instance.
        local char = localplayer.Character
        local chest = char and char:FindFirstChild("Chest")
        local torso = chest and chest:FindFirstChild("Torso")
        local glow = torso and torso:FindFirstChildOfClass("PointLight")

        if glow then
            glow.Enabled = not enabled
        end
    end)

    toggles.obtainArmor_Toggle:OnChanged(function(enabled)
        if enabled then
            local hrp = getHRP()
            utils.fireTouchEvent(hrp, area51.Amory2Room.Armory.Giver)

            -- The armor can't be taken off, so lock the toggle until the next respawn
            toggles.obtainArmor_Toggle:SetDisabled(true)
        end
    end)

    toggles.obtainHelmet_Toggle:OnChanged(function(enabled)
        if enabled then

            local hrp = getHRP()
            utils.fireTouchEvent(hrp, area51.ComputersRoom.Helmet)

            -- The helmet can't be taken off, so lock the toggle until the next respawn
            toggles.obtainHelmet_Toggle:SetDisabled(true)
        end
    end)

    -- The morph, armor and helmet are gone once you die, so the toggles unlock for the respawn screen.
    local function unlockWornToggles()
        toggles.zombieMorph_Toggle:SetDisabled(false)
        toggles.obtainArmor_Toggle:SetDisabled(false)

        -- The helmet toggle is only usable in Extreme mode, so don't unlock it in other modes
        if getMode() == "Extreme" then
            toggles.obtainHelmet_Toggle:SetDisabled(false)
        end
    end

    local function watchDeath(char)
        task.spawn(function()
            local humanoid = char:WaitForChild("Humanoid", 10)
            if humanoid then
                humanoid.Died:Connect(unlockWornToggles)
            end
        end)
    end

    if localplayer.Character then
        watchDeath(localplayer.Character)
    end

    localplayer.CharacterAdded:Connect(function(char)
        watchDeath(char)
        unlockWornToggles()

        task.wait(0.5)
        local hrp = getHRP()

        if toggles.zombieMorph_Toggle.Value then
            local disableSelfGlowEnabled = toggles.disableSelfGlow_Toggle.Value

            utils.fireTouchEvent(hrp, area51.Outside.Hangar.Right["Zombie Morph"].TheButton)
            refreshMorphAppearance(char)
            toggles.zombieMorph_Toggle:SetDisabled(true)

            if disableSelfGlowEnabled then
                local chest
                repeat
                    task.wait()
                    chest = localplayer.Character:FindFirstChild("Chest")
                until chest

                local torso
                repeat
                    task.wait()
                    torso = chest:FindFirstChild("Torso")
                until torso

                local glow
                repeat
                    task.wait()
                    glow = torso:FindFirstChildOfClass("PointLight")
                until glow

                glow.Enabled = false
            end
        end

        if toggles.obtainArmor_Toggle.Value then
            utils.fireTouchEvent(hrp, area51.Amory2Room.Armory.Giver)
            toggles.obtainArmor_Toggle:SetDisabled(true)
        end

        if toggles.obtainHelmet_Toggle.Value then
            utils.fireTouchEvent(hrp, area51.ComputersRoom.Helmet)
            toggles.obtainHelmet_Toggle:SetDisabled(true)
        end
    end)
end

-- [Weapons / Other] Auto reload and gun-mod controls

othersGroup:AddToggle("autoReloadWeapons_Toggle", { Text = "Auto Reload", Tooltip = false })

local autoReloadDepbox = othersGroup:AddDependencyBox()

autoReloadDepbox:AddSlider("autoReloadDelay_Slider", { Text = "Delay", Tooltip = false, Default = 1, Min = 0.5, Max = 10, Suffix = " Second", Rounding = 1,
    Callback = function(val)
        options.autoReloadDelay_Slider:SetSuffix(getSuffix(options.autoReloadDelay_Slider, "Second"))
    end
})

-- [Weapons / Other] Auto Pickup Weapons
do
    local pickupAllowed = getMode() == "Hard" or getMode() == "Extreme"
    local pickupRunning = false
    local pickupConnection: RBXScriptConnection? = nil
    local pickupTracked = setmetatable({}, { __mode = "k" })

    othersGroup:AddToggle("autoPickupWeapons_Toggle", { Text = "Auto Pickup Weapons", Tooltip = "Automatically picks your weapon back up when the Alien's arm steals it. Only your own weapons are picked up.", Default = false, Disabled = not pickupAllowed, DisabledTooltip = "This feature is not available in this mode." })

    -- ToolOwner holds the Player the weapon was stolen from (a plain name string is accepted as well)
    local function isOwnStolenWeapon(model)
        local owner = model:FindFirstChild("ToolOwner")

        if not (owner and owner:IsA("ValueBase")) then
            return false
        end

        local value = (owner :: any).Value

        if typeof(value) == "string" then
            return value == localplayer.Name
        end

        return typeof(value) == "Instance" and (value == localplayer or value.Name == localplayer.Name)
    end

    local function pickupStolenWeapon(model)
        if pickupTracked[model] then
            return
        end

        pickupTracked[model] = true

        task.spawn(function()
            local function stillWanted()
                return pickupRunning and not library.Unloaded and model:IsDescendantOf(workspace)
            end

            -- The model can be applied before the server has filled in its owner and Hitbox, so give it a moment
            local waitStart = os.clock()

            while stillWanted() and os.clock() - waitStart < 3 do
                local owner = model:FindFirstChild("ToolOwner")

                if owner and (owner :: any).Value ~= nil and model:FindFirstChild("Hitbox") then
                    break
                end

                task.wait(0.05)
            end

            if stillWanted() and isOwnStolenWeapon(model) then
                local reference = model:FindFirstChild("ToolReference")
                local referencedTool = reference and reference:IsA("ObjectValue") and reference.Value
                local weaponName = referencedTool and referencedTool.Name or "weapon"
                local fired = false

                -- Keep touching until the model is gone: the first touch is not always accepted
                while stillWanted() do
                    local hrp = getHRP()
                    local hitbox = model:FindFirstChild("Hitbox")

                    if hrp and hitbox and isAlive() and hrp:IsDescendantOf(workspace) and hitbox:IsDescendantOf(workspace) then
                        -- Touch-begin. Skipped silently when a part is not in the physics world yet; the next pass retries it.
                        if pcall(firetouchinterest, hrp, hitbox, 0) then
                            fired = true
                            task.wait()

                            -- Touch-end only if both parts survived the yield
                            if hrp:IsDescendantOf(workspace) and hitbox:IsDescendantOf(workspace) then
                                pcall(firetouchinterest, hrp, hitbox, 1)
                            end
                        end
                    end

                    task.wait(0.25)
                end

                -- The loop ended with the feature still on, so the model is gone and the weapon is back with you
                if fired and pickupRunning and not library.Unloaded then
                    notify("Success", "Picked up weapon", "Your " .. weaponName .. " was stolen and has been picked back up.", 5)
                end
            end

            pickupTracked[model] = nil
        end)
    end

    local function stopAutoPickup()
        pickupRunning = false

        if pickupConnection then
            pickupConnection:Disconnect()
            pickupConnection = nil
        end
    end

    local function startAutoPickup()
        pickupRunning = true

        pickupConnection = workspace.ChildAdded:Connect(function(child)
            if child.Name == "StolenWeapon" and child:IsA("Model") then
                pickupStolenWeapon(child)
            end
        end)

        -- A weapon may already be lying around from before the toggle was switched on
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "StolenWeapon" and child:IsA("Model") then
                pickupStolenWeapon(child)
            end
        end
    end

    toggles.autoPickupWeapons_Toggle:OnChanged(function(state)
        if state and pickupAllowed then
            if not pickupRunning then
                startAutoPickup()
            end
        else
            stopAutoPickup()
        end
    end)

    table.insert(teardownTasks, stopAutoPickup)
end

othersGroup:AddToggle("enableGunMods_Toggle", { Text = "Enable Gun Mods", Tooltip = "Usage of any gun mods has a high chance of resulting in a permanent game ban.", Risky = true })

local gunModsDepbox = othersGroup:AddDependencyBox()

gunModsDepbox:AddToggle("infiniteAmmoGunMod_Toggle", { Text = "Infinite Ammo", Tooltip = false, Risky = true })
gunModsDepbox:AddToggle("fullAutoGunMod_Toggle", { Text = "Fully Automatic", Tooltip = false, Risky = true })
gunModsDepbox:AddToggle("fireRateGunMod_Toggle", { Text = "Rapid Fire", Tooltip = false, Risky = true })
gunModsDepbox:AddToggle("noOverheatGunMod_Toggle", { Text = "Flamethrower: No Overheat", Tooltip = "Stops the Flamethrower from building heat, so it can be held down for as long as you like with no overheat lockout and no re-press delay. Pair with Infinite Ammo for unlimited gas.", Risky = true })
gunModsDepbox:AddToggle("noBoltGunMod_Toggle", { Text = "Disable Sniper Bolt", Tooltip = "Skips the bolt-action animation after each shot so Snipers can fire rapidly. Pair with Rapid Fire.", Risky = true })
gunModsDepbox:AddToggle("noRecoilGunMod_Toggle", { Text = "No Recoil", Tooltip = "Removes the camera kick when firing.", Risky = true })
gunModsDepbox:AddToggle("noSpreadGunMod_Toggle", { Text = "No Spread", Tooltip = "Removes bullet inaccuracy.", Risky = true })
gunModsDepbox:AddToggle("fastReloadGunMod_Toggle", { Text = "Fast Reload", Tooltip = "Shortens reload (and bolt) animations to a fraction of their normal time.", Risky = true })
gunModsDepbox:AddSlider("bulletCountGunMod_Slider", { Text = "Bullet Count", Tooltip = false, Default = 1, Min = 1, Max = 100, Suffix = " Bullet", Rounding = 0, Risky = true,
    Callback = function(val)
        options.bulletCountGunMod_Slider:SetSuffix(getSuffix(options.bulletCountGunMod_Slider, "Bullet"))
    end
})

autoReloadDepbox:SetupDependencies({ { toggles.autoReloadWeapons_Toggle, true } })
gunModsDepbox:SetupDependencies({ { toggles.enableGunMods_Toggle, true } })

toggles.autoReloadWeapons_Toggle:OnChanged(function(enabled)
    -- Disable sound

    local reloadSound = game:GetService("SoundService").AmmoReload
    reloadSound.Volume = enabled and 0 or 1

    task.spawn(function()
        while toggles.autoReloadWeapons_Toggle.Value do

            local hrp = getHRP()
            utils.fireTouchEvent(hrp, area51.PlantRoom["Box of Shells"].Box)

            task.wait(options.autoReloadDelay_Slider.Value)
        end
    end)
end)

-- [Weapons / Gun Mods] Non-destructive weapon modifiers
local GUN_MOD_FIELDS = { "ammo", "stored_ammo", "is_auto", "shoot_wait", "bullet_count", "inaccuracy", "bolt_fire", "move_camera", "reload_wait" }

-- Replacement methods: They are created once so their identity is stable for the "is this still ours?" comparison.
local GUN_MOD_FAST_RELOAD_SCALE = 0.1 -- reload/bolt animation waits are multiplied by this (lower = faster)

local function gunModNoRecoilMoveCamera()
    -- Intentionally empty: skipping the camera rotation is the whole mod.
end

local function gunModFastReloadWait(duration)
    if type(duration) == "number" then
        return task.wait(duration * GUN_MOD_FAST_RELOAD_SCALE)
    end

    return task.wait(duration)
end

-- Current-ammo fields mapped to the field that holds the weapon's real capacity.
local GUN_MOD_CAPACITY_FIELD = { ammo = "max_ammo", stored_ammo = "max_stored" }

local gunModSnapshots = setmetatable({}, { __mode = "k" }) -- weapon -> { [field] = { value = original raw value } }
local gunModApplied = setmetatable({}, { __mode = "k" })   -- weapon -> { [field] = value written by a mod }
local gunModsEngaged = false -- true while any weapon may still hold a modified value
local gunModsUnloaded = false

local function isFiniteNumber(value: any): boolean
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function findGunModTargets(): { any }
    local targets = {}

    for _, object in next, getgc(true) do
        if type(object) == "table"
            and rawget(object, "ammo") ~= nil
            and typeof(rawget(object, "instance")) == "Instance"
            and getmetatable(object) ~= nil then
            table.insert(targets, object)
        end
    end

    return targets
end

-- What every managed field should currently be overridden to. A field that is absent here must be original.
local function getDesiredGunMods(): { [string]: any }
    local desired = {}

    if gunModsUnloaded or not toggles.enableGunMods_Toggle.Value then
        return desired
    end

    if toggles.infiniteAmmoGunMod_Toggle.Value then
        desired.ammo = math.huge
        desired.stored_ammo = math.huge
    end

    if toggles.fullAutoGunMod_Toggle.Value then
        desired.is_auto = true
        desired.inaccuracy = 0.00001
    end

    if toggles.fireRateGunMod_Toggle.Value then
        desired.shoot_wait = 1e-14
        desired.is_auto = true
    end

    if toggles.noBoltGunMod_Toggle.Value then
        desired.bolt_fire = false
    end

    if toggles.noRecoilGunMod_Toggle.Value then
        desired.move_camera = gunModNoRecoilMoveCamera
    end

    if toggles.noSpreadGunMod_Toggle.Value then
        desired.inaccuracy = 0.00001
    end

    if toggles.fastReloadGunMod_Toggle.Value then
        desired.reload_wait = gunModFastReloadWait
    end

    -- 1 is the slider's neutral position, so it leaves weapons untouched.
    local bulletCount = options.bulletCountGunMod_Slider.Value
    if type(bulletCount) == "number" and bulletCount > 1 then
        desired.bullet_count = bulletCount
    end

    return desired
end

-- Returns true when a value was written back.
local function restoreGunModField(weapon: any, field: string, original: any): boolean
    local capacityField = GUN_MOD_CAPACITY_FIELD[field]

    if capacityField then
        local target = original and original.value

        -- No usable snapshot (e.g. the weapon was already infinite when first seen): use its real capacity instead.
        if not isFiniteNumber(target) then
            target = rawget(weapon, capacityField)
        end

        if isFiniteNumber(target) then
            rawset(weapon, field, target)
            return true
        end

        return false
    end

    if original then
        rawset(weapon, field, original.value) -- nil removes the override so the class value shows through again
        return true
    end

    return false
end

-- [Weapons / Gun Mods] Flamethrower: No Overheat
local gunModHeatHooks = setmetatable({}, { __mode = "k" }) -- weapon -> { RawUpdate, RawStop, HookedUpdate, HookedStop }

local function isNoOverheatDesired()
    return not gunModsUnloaded
        and toggles.enableGunMods_Toggle.Value == true
        and toggles.noOverheatGunMod_Toggle.Value == true
end

local function applyNoOverheat(weapon)
    -- Only Flamethrower-style weapons own a max_heat number (Flamethrower and PAPFlamethrower).
    if gunModHeatHooks[weapon] or type(rawget(weapon, "max_heat")) ~= "number" then
        return
    end

    local originalUpdate = weapon.update_ammo_gui -- resolves through the metatable when inherited
    local originalStop = weapon.stop_fire
    if type(originalUpdate) ~= "function" or type(originalStop) ~= "function" then
        return
    end

    local record = {
        RawUpdate = rawget(weapon, "update_ammo_gui"), -- nil when inherited from the class
        RawStop = rawget(weapon, "stop_fire"),
    }

    record.HookedUpdate = function(self, ...)
        if isNoOverheatDesired() and (rawget(self, "heat") or 0) > 0 then
            rawset(self, "heat", 0)
        end

        return originalUpdate(self, ...)
    end

    record.HookedStop = function(self, ...)
        originalStop(self, ...)

        if isNoOverheatDesired() then
            rawset(self, "flaming_stop_moment", 0) -- removes the 1 second re-press lockout
        end
    end

    local success, hookError = pcall(function()
        rawset(weapon, "update_ammo_gui", record.HookedUpdate)
        rawset(weapon, "stop_fire", record.HookedStop)
    end)

    if not success then
        warn("[Gun Mods] Could not hook the Flamethrower: " .. tostring(hookError))
        return
    end

    gunModHeatHooks[weapon] = record

    -- Already hot when the mod was switched on: cool it down immediately.
    if (rawget(weapon, "heat") or 0) > 0 then
        rawset(weapon, "heat", 0)
        pcall(originalUpdate, weapon)
    end
end

local function removeNoOverheat(weapon)
    local record = gunModHeatHooks[weapon]
    if not record then
        return
    end

    -- Only undo what is still ours.
    if rawget(weapon, "update_ammo_gui") == record.HookedUpdate then
        rawset(weapon, "update_ammo_gui", record.RawUpdate) -- nil removes the override so the class method shows through again
    end

    if rawget(weapon, "stop_fire") == record.HookedStop then
        rawset(weapon, "stop_fire", record.RawStop)
    end

    gunModHeatHooks[weapon] = nil
end

local function reconcileGunMods()
    local desired = getDesiredGunMods()
    local noOverheat = isNoOverheatDesired()

    if next(desired) == nil and not noOverheat and not gunModsEngaged then
        return
    end

    for _, weapon in ipairs(findGunModTargets()) do
        local snapshot = gunModSnapshots[weapon]
        local applied = gunModApplied[weapon]
        local ammoRestored = false

        for _, field in ipairs(GUN_MOD_FIELDS) do
            local wanted = desired[field]

            if wanted ~= nil then
                if not snapshot then
                    snapshot, applied = {}, {}
                    gunModSnapshots[weapon] = snapshot
                    gunModApplied[weapon] = applied
                end

                local current = rawget(weapon, field)

                if GUN_MOD_CAPACITY_FIELD[field] then
                    -- Always keep the latest real value (it may have been refilled since), never an infinite one.
                    if isFiniteNumber(current) then
                        snapshot[field] = { value = current }
                    end
                elseif snapshot[field] == nil then
                    snapshot[field] = { value = current }
                end

                if current ~= wanted then
                    rawset(weapon, field, wanted)
                end

                applied[field] = wanted
            elseif applied and applied[field] ~= nil then
                -- Only undo what is still ours: if the game changed the field since (refill, fire-mode switch), keep it.
                if rawget(weapon, field) == applied[field] and restoreGunModField(weapon, field, snapshot[field]) then
                    if GUN_MOD_CAPACITY_FIELD[field] then
                        ammoRestored = true
                    end
                end

                applied[field] = nil
                snapshot[field] = nil
            end
        end

        if noOverheat then
            applyNoOverheat(weapon)
        else
            removeNoOverheat(weapon)
        end

        -- Refresh the on-screen counter so it stops showing the infinite value.
        if ammoRestored and type(weapon.update_ammo_gui) == "function" then
            pcall(weapon.update_ammo_gui, weapon)
        end
    end

    gunModsEngaged = next(desired) ~= nil or noOverheat
end

toggles.enableGunMods_Toggle:OnChanged(reconcileGunMods)
toggles.infiniteAmmoGunMod_Toggle:OnChanged(reconcileGunMods)
toggles.fullAutoGunMod_Toggle:OnChanged(reconcileGunMods)
toggles.fireRateGunMod_Toggle:OnChanged(reconcileGunMods)
toggles.noOverheatGunMod_Toggle:OnChanged(reconcileGunMods)
toggles.noBoltGunMod_Toggle:OnChanged(reconcileGunMods)
toggles.noRecoilGunMod_Toggle:OnChanged(reconcileGunMods)
toggles.noSpreadGunMod_Toggle:OnChanged(reconcileGunMods)
toggles.fastReloadGunMod_Toggle:OnChanged(reconcileGunMods)
options.bulletCountGunMod_Slider:OnChanged(reconcileGunMods)

-- [Weapons / Gun Mods] Backpack listener for newly acquired tools

local gunModBackpackConnection: RBXScriptConnection? = nil

local function setupBackpackListener()
    if gunModBackpackConnection then
        gunModBackpackConnection:Disconnect()
        gunModBackpackConnection = nil
    end

    if gunModsUnloaded then
        return
    end

    local backpack = localplayer:FindFirstChild("Backpack") or localplayer:WaitForChild("Backpack")

    gunModBackpackConnection = backpack.ChildAdded:Connect(function(tool)
        if tool:IsA("Tool") then
            task.delay(0.5, reconcileGunMods) -- gives the game time to build the weapon object; no-op when no mod is on
        end
    end)
end

setupBackpackListener()

-- [Weapons / Gun Mods] Reapply listeners after respawn

local gunModCharacterConnection = localplayer.CharacterAdded:Connect(function()
    task.defer(setupBackpackListener)
end)

-- Runs from unloadModules() after every toggle has been switched off; the final reconcile is for safety.
table.insert(teardownTasks, function()
    gunModsUnloaded = true

    if gunModBackpackConnection then
        gunModBackpackConnection:Disconnect()
        gunModBackpackConnection = nil
    end

    gunModCharacterConnection:Disconnect()
    reconcileGunMods()
end)


-- ============================================================================
-- [Weapons / Skin Changer] Client-side weapon skins
-- ============================================================================
-- Recolors weapons locally through the game's own Utilities:apply_skin, using the skins from Constants.Skins.SKINS.

task.spawn(function()
    local skinGroup = tabs.weapons:AddLeftGroupbox("Skin Changer")
    local replicatedStorage = game:GetService("ReplicatedStorage")

    local skinUtilities: any, skinList: any
    local loaded, loadError = pcall(function()
        skinUtilities = require(replicatedStorage:WaitForChild("Utilities", 10))
        skinList = require(replicatedStorage:WaitForChild("Constants", 10):WaitForChild("Skins", 10)).SKINS
    end)

    if not loaded or type(skinList) ~= "table" or type(skinUtilities.apply_skin) ~= "function" then
        warn("[Skin Changer] Could not load the game's skin data: " .. tostring(loadError))
        skinGroup:AddLabel("The game's skin data could not be loaded.", true)
        return
    end

    -- Full skin list straight from the game ("[None]" is covered by the Reset button instead).
    local skinNames = {}
    for name in pairs(skinList) do
        if name ~= "[None]" then
            table.insert(skinNames, name)
        end
    end
    table.sort(skinNames, function(a, b)
        return a:lower() < b:lower()
    end)

    local state = { skin = nil, scope = "Equipped weapon", auto = false, matchBullets = true }
    local touched = setmetatable({}, { __mode = "k" }) -- tool -> { hadAttr, attr, skin, probe, look }
    local autoConnections = {}
    local sourceConnections = {}
    local autoToken = 0
    local unloaded = false

    local function disconnectAll(list)
        for _, connection in ipairs(list) do
            connection:Disconnect()
        end
        table.clear(list)
    end

    -- Parts the game's apply_skin actually recolors (same condition it uses).
    local function getSkinParts(tool: Instance)
        local parts = {}
        if not tool:FindFirstChild("Handle") then
            return parts
        end

        for _, descendant in ipairs(tool:GetDescendants()) do
            if descendant:IsA("BasePart") and descendant:FindFirstChild("HandleDistance") then
                table.insert(parts, descendant)
            end
        end

        return parts
    end

    -- Cheap fingerprint of one recolorable part, used to notice when the game overwrites the skin.
    local function getLook(part: any): string
        return part.Color:ToHex() .. "|" .. part.Material.Name
    end

    local function getTargets(scope: string)
        local targets = {}
        local character = localplayer.Character

        if scope == "Equipped weapon" then
            local held = character and character:FindFirstChildOfClass("Tool")
            if held then
                table.insert(targets, held)
            end
            return targets
        end

        local backpack = localplayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, child in ipairs(backpack:GetChildren()) do
                if child:IsA("Tool") then
                    table.insert(targets, child)
                end
            end
        end

        if character then
            for _, child in ipairs(character:GetChildren()) do
                if child:IsA("Tool") then
                    table.insert(targets, child)
                end
            end
        end

        return targets
    end

    local function restoreAttribute(tool: Instance, record)
        tool:SetAttribute("AppliedSkin", record.hadAttr and record.attr or nil)
    end

    local function applySkin(tool: Instance, skinName: string, knownParts: any?): boolean
        if not skinList[skinName] then
            return false
        end

        local parts = knownParts or getSkinParts(tool)
        if #parts == 0 then
            return false
        end

        local record = touched[tool]
        if not record then
            local original = tool:GetAttribute("AppliedSkin")
            record = { hadAttr = original ~= nil, attr = original }
            touched[tool] = record
        end

        local success, err = pcall(skinUtilities.apply_skin, skinUtilities, tool, skinName)
        if not success then
            warn("[Skin Changer] apply_skin failed for " .. tool.Name .. ": " .. tostring(err))
            return false
        end

        -- Bullet color follows the AppliedSkin attribute; setting it locally makes bullets match the skin.
        if state.matchBullets then
            tool:SetAttribute("AppliedSkin", skinName)
        end

        record.skin = skinName
        record.probe = parts[1]
        record.look = getLook(parts[1])
        return true
    end

    local function restoreTool(tool: Instance, record)
        restoreAttribute(tool, record)

        local realSkin = "[None]"
        if record.hadAttr and type(record.attr) == "string" and skinList[record.attr] then
            realSkin = record.attr
        end

        pcall(skinUtilities.apply_skin, skinUtilities, tool, realSkin)
    end

    local function resetAll(): number
        local tools = {}
        for tool in pairs(touched) do
            table.insert(tools, tool)
        end

        local restored = 0
        for _, tool in ipairs(tools) do
            local record = touched[tool]
            touched[tool] = nil

            if record and tool.Parent then
                restoreTool(tool, record)
                restored += 1
            end
        end

        return restored
    end

    -- Re-applies the chosen skin wherever it is missing (new tools, respawn, or the game putting the real skin back).
    local function reapplyAll(force: boolean?)
        if unloaded or not state.skin then
            return
        end

        -- Forget weapons the game has destroyed so records don't pile up.
        for tool in pairs(touched) do
            if not tool.Parent then
                touched[tool] = nil
            end
        end

        for _, tool in ipairs(getTargets(state.scope)) do
            local record = touched[tool]
            local probe = record and record.probe

            if force ~= true and probe and probe:IsDescendantOf(tool) then
                -- Known tool: one part is enough to tell whether the game has put its own look back.
                local stale = record.skin ~= state.skin
                    or record.look ~= getLook(probe)
                    or (state.matchBullets and tool:GetAttribute("AppliedSkin") ~= state.skin)

                if stale then
                    applySkin(tool, state.skin)
                end
            else
                local parts = getSkinParts(tool)

                if #parts > 0 then
                    applySkin(tool, state.skin, parts)
                end
            end
        end
    end

    local function hookSources()
        disconnectAll(sourceConnections)

        if not state.auto or unloaded then
            return
        end

        local onToolAdded = function(child: Instance)
            if child:IsA("Tool") then
                task.delay(0.1, reapplyAll)
            end
        end

        local backpack = localplayer:FindFirstChildOfClass("Backpack")
        if backpack then
            table.insert(sourceConnections, backpack.ChildAdded:Connect(onToolAdded))
        end

        local character = localplayer.Character
        if character then
            table.insert(sourceConnections, character.ChildAdded:Connect(onToolAdded))
        end
    end

    local function setAuto(enabled: boolean)
        state.auto = enabled
        autoToken += 1
        disconnectAll(autoConnections)
        disconnectAll(sourceConnections)

        if not enabled or unloaded then
            return
        end

        -- Read-only listener: the game re-applies the real skin on equip, loadout change and respawn.
        local characterRemotes = replicatedStorage:FindFirstChild("Character Remotes")
        local skinsEquipped = characterRemotes and characterRemotes:FindFirstChild("SkinsEquipped")
        if skinsEquipped and skinsEquipped:IsA("RemoteEvent") then
            table.insert(autoConnections, skinsEquipped.OnClientEvent:Connect(function()
                task.delay(0.05, reapplyAll)
            end))
        end

        table.insert(autoConnections, localplayer.CharacterAdded:Connect(function()
            task.delay(0.5, function()
                hookSources()
                reapplyAll()
            end)
        end))

        hookSources()
        reapplyAll()

        -- Safety for anything the events miss; only re-applies when the look has actually changed.
        local token = autoToken
        task.spawn(function()
            while state.auto and not unloaded and token == autoToken do
                task.wait(0.5)

                if state.auto and not unloaded and token == autoToken then
                    pcall(reapplyAll)
                end
            end
        end)
    end

    local function syncBulletAttribute()
        for tool, record in pairs(touched) do
            if tool.Parent then
                if state.matchBullets and record.skin then
                    tool:SetAttribute("AppliedSkin", record.skin)
                else
                    restoreAttribute(tool, record)
                end
            end
        end
    end

    -- UI
    skinGroup:AddDropdown("skinChangerSkin_Dropdown", { Text = "Skin", Tooltip = "Every skin from the game's own skin list. Search by typing.", Values = skinNames, Default = nil, Multi = false, Searchable = true,
        Callback = function(val)
            state.skin = val

            if state.auto then
                reapplyAll()
            end
        end,
    })

    skinGroup:AddDropdown("skinChangerTarget_Dropdown", { Text = "Apply To", Tooltip = "Which weapon(s) get the skin.", Values = { "Equipped weapon", "All weapons" }, Default = 1, Multi = false, Searchable = false,
        Callback = function(val)
            state.scope = val or "Equipped weapon"

            if state.auto then
                reapplyAll()
            end
        end,
    })

    skinGroup:AddButton({ Text = "Apply Skin", Tooltip = "Applies the selected skin once.",
        Func = function()
            if not state.skin then
                notify("Error", "No skin selected", "Pick a skin from the dropdown first.", 6)
                return
            end

            local applied = 0
            for _, tool in ipairs(getTargets(state.scope)) do
                if applySkin(tool, state.skin) then
                    applied += 1
                end
            end

            if applied == 0 then
                local hint = state.scope == "Equipped weapon"
                    and "Hold a weapon first, or switch Apply To to All weapons."
                    or "No skinnable weapons were found in your hands or backpack."
                notify("Error", "No weapon found", hint, 7)
            else
                notify("Success", "Skin applied", state.skin .. " applied to " .. applied .. (applied == 1 and " weapon." or " weapons."), 5)
            end
        end,
    })

    skinGroup:AddToggle("skinChangerAuto_Toggle", { Text = "Auto Re-apply", Tooltip = "Keeps the skin on after equipping, respawning, loadout changes, or picking up weapons.", Default = false,
        Callback = function(enabled)
            setAuto(enabled)
        end,
    })

    skinGroup:AddToggle("skinChangerBullets_Toggle", { Text = "Match Bullet Color", Tooltip = "Also sets the weapon's AppliedSkin attribute locally so your bullets use the skin's color.", Default = true,
        Callback = function(enabled)
            state.matchBullets = enabled
            syncBulletAttribute()
        end,
    })

    skinGroup:AddButton({ Text = "Reset Skins", Tooltip = "Turns off Auto Re-apply and puts every weapon back to its real skin.",
        Func = function()
            if toggles.skinChangerAuto_Toggle.Value then
                toggles.skinChangerAuto_Toggle:SetValue(false)
            end

            local restored = resetAll()
            if restored > 0 then
                notify("Success", "Skins reset", "Restored " .. restored .. (restored == 1 and " weapon" or " weapons") .. " to the real skin.", 5)
            else
                notify("Error", "Nothing to reset", "No weapons have a local skin applied.", 5)
            end
        end,
    })

    -- Pick up whatever the dropdowns / toggles loaded with (saved configs may set them before the callbacks run).
    state.skin = options.skinChangerSkin_Dropdown.Value
    state.scope = options.skinChangerTarget_Dropdown.Value or "Equipped weapon"
    state.matchBullets = toggles.skinChangerBullets_Toggle.Value

    -- Runs from unloadModules(): stop listening and give every touched weapon its real look back.
    table.insert(teardownTasks, function()
        unloaded = true
        state.auto = false
        autoToken += 1
        disconnectAll(autoConnections)
        disconnectAll(sourceConnections)
        resetAll()
    end)
end)


-- ============================================================================
-- 14 | TAB: MISCELLANEOUS
-- ============================================================================

local othersGroup2 = tabs.misc:AddLeftGroupbox("Others")

-- [Miscellaneous / Other] Keycards, teleport actions, and weapon spam

-- [Miscellaneous / Weapon Spam] Repeated equip/unequip cycle
othersGroup2:AddToggle("weaponSpam_Toggle", { Text = "Weapon Spam", Tooltip = false })
othersGroup2:AddButton({ Text = "Give Office Card",
    Func = function()
        if entityLib.getTool("Specific", "Card2") then
            notify("Error", "Failed", "You already have the office keycard.", 8)
            return
        end

        local hrp = getHRP()
        utils.fireTouchEvent(hrp, area51.AdminRoom.Table.Card)
    end,
})

othersGroup2:AddButton({ Text = "Vault Keycard",
    Func = function()
        if entityLib.getTool("Specific", "Card1") then
            notify("Error", "Failed", "You already have the vault keycard.", 8)
            return
        end

        local hrp = getHRP()
        utils.fireTouchEvent(hrp, area51.JailsRoom.Jails.Left.Behind.Card)
    end,
})

-- [Miscellaneous / Utility actions] Security camera teleport with return
local securityCamActive = false

-- Waits for the character to sit, then for it to leave the seat (space bar), then returns it.
local function watchSecurityCamSeat(character, humanoid, seat, originCFrame)
    local startedAt = os.clock()

    local function characterGone()
        return not humanoid.Parent or humanoid.Health <= 0 or localplayer.Character ~= character
    end

    while humanoid.SeatPart ~= seat do
        if characterGone() then return end

        if os.clock() - startedAt > 2 then
            -- Never managed to sit (e.g. seat occupied), so put the player back where they were.
            notify("Error", "Failed", "Could not sit on the security camera seat.", 8)
            local root = getHRP()
            if root then
                root.CFrame = originCFrame
            end
            return
        end

        task.wait()
    end

    while humanoid.SeatPart == seat do
        if characterGone() then return end
        task.wait()
    end

    task.wait()
    if characterGone() then return end

    local root = getHRP()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = originCFrame
    end
end

othersGroup2:AddButton({ Text = "Teleport to Security Cameras",
    Func = function()
        if securityCamActive then return end

        local hrp = getHRP()
        local humanoid = getHumanoid()
        if not hrp or not humanoid or humanoid.Health <= 0 then return end

        local seat = game:GetService("Workspace")["Surveillance Cameras"].Triggers.Seat
        local character = humanoid.Parent
        local originCFrame = hrp.CFrame

        securityCamActive = true
        entityLib.teleport(seat)

        task.spawn(function()
            local ok, err = pcall(watchSecurityCamSeat, character, humanoid, seat, originCFrame)
            if not ok then
                warn("[Security Cameras] " .. tostring(err))
            end
            securityCamActive = false
        end)
    end,
})

toggles.weaponSpam_Toggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while toggles.weaponSpam_Toggle.Value do
                local totalTools = entityLib.getTool("Count")
                local backpackTools = localplayer.Backpack:GetChildren()

                if totalTools < 3 then
                    notify("Error", "Insufficient weapons", "You must have at least 3 weapons.", 8)
                    toggles.weaponSpam_Toggle:SetValue(false)
                    return
                end

                for i = 1, totalTools do
                    if not toggles.weaponSpam_Toggle.Value then
                        break
                    end

                    local tool = backpackTools[i]
                    if tool and tool:IsA("Tool") then
                        entityLib.equipTool(tool.Name, true)
                        task.wait() -- Equip delay

                        if not toggles.weaponSpam_Toggle.Value then
                            break
                        end

                        entityLib.equipTool(nil, false)
                        task.wait() -- Unequip delay
                    end
                end

                task.wait()
            end

            if entityLib.getTool("Held") then
                entityLib.equipTool(nil, false)
            end
        end)
    end
end)

localplayer.CharacterAdded:Connect(function(char)
    if toggles.weaponSpam_Toggle.Value then
        --[[
        -- VIP gamepass
        if not utils.fetchOwnership("Gamepass", 1243865) then
            toggles.weaponSpam_Toggle:SetValue(false)
            return
        end
        ]]

        task.spawn(function()
            while toggles.weaponSpam_Toggle.Value do
                local totalTools = entityLib.getTool("Count")
                local backpackTools = localplayer.Backpack:GetChildren()

                if totalTools < 3 then
                    notify("Error", "Insufficient weapons", "You must have at least 3 weapons.", 8)
                    toggles.weaponSpam_Toggle:SetValue(false)
                    return
                end

                for i = 1, totalTools do
                    if not toggles.weaponSpam_Toggle.Value then
                        break
                    end

                    local tool = backpackTools[i]
                    if tool and tool:IsA("Tool") then
                        entityLib.equipTool(tool.Name, true)
                        task.wait() -- Equip delay

                        if not toggles.weaponSpam_Toggle.Value then
                            break
                        end

                        entityLib.equipTool(nil, false)
                        task.wait() -- Unequip delay
                    end
                end

                task.wait()
            end

            if entityLib.getTool("Held") then
                entityLib.equipTool(nil, false)
            end
        end)
    end
end)

-- ============================================================================
-- 15 | TAB: UI SETTINGS AND CLEANUP
-- ============================================================================

local menuGroup = tabs.uiSettings:AddLeftGroupbox("Menu")

menuGroup:AddToggle("openKeybindMenu_Toggle", { Text = "Open Keybind Menu", Default = window.keybindFrameEnabled, Disabled = false, Callback = function(enabled) library.KeybindFrame.Visible = enabled end })
menuGroup:AddToggle("configKeybinds_Toggle", { Text = "Keybind Menu Visibility", Default = false, Tooltip = "Show or hide specific keybinds.", Visible = false, Callback = function(enabled) library.KeybindMenu:SetVisibilityControl(enabled) end })
menuGroup:AddToggle("autoResetColor_Toggle", { Text = "Auto Reset Color", Tooltip = "Resets the colorpicker color back to its default color once a rainbow toggle is disabled.", Default = true,
    Callback = function(Value) window.autoResetRainbowColor = Value end })
menuGroup:AddToggle("alwaysOnTop_Toggle", { Text = "Always On Top", Default = window.AlwaysOnTop, Tooltip = "Places the window over all Roblox GUI.", Callback = function(enabled) window:SetAlwaysOnTop(enabled) end })
menuGroup:AddToggle("notifSound_Toggle", { Text = "Notification Alert Sounds", Tooltip = false, Default = true, Callback = function(enabled) window.notifSoundEnabled = enabled end })

local notifSoundDepbox = menuGroup:AddDependencyBox()

local notifAlertVolume_Slider = notifSoundDepbox:AddSlider("notifAlertVolumeSlider", { Text = "Alert Volume", Tooltip = false, Default = 1, Min = 0.1, Max = 6, Rounding = 1 })
notifSoundDepbox:AddDivider()

notifSoundDepbox:SetupDependencies({ { toggles.notifSound_Toggle, true } })

menuGroup:AddDropdown("NotificationSide", { Text = "Notification Side", Values = { "Left", "Right" }, Default = "Right", Callback = function(val) library:SetNotifySide(val) end })
menuGroup:AddDropdown("DPIDropdown", { Text = "DPI Scale", Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%",
    Callback = function(val)
        val = val:gsub("%%", "")
        local dpi = tonumber(val)
        if dpi then
            library:SetDPIScale(dpi)
        end
    end,
})
menuGroup:AddSlider("cornerRadius_Slider", { Text = "Corner Radius", Default = library.CornerRadius, Min = 0, Max = 20, Callback = function(val) window:SetCornerRadius(val) end })

local rainbowSpeed_Slider = menuGroup:AddSlider("rainbowSpeed_Slider", { Text = "Rainbow Speed", Tooltip = false, Default = window.rainbowSpeed, Min = 0.1, Max = 1, Rounding = 1 })
menuGroup:AddLabel("Menu bind"):AddKeyPicker("menuKeybind_KeyPicker", { Text = "Menu keybind", Default = "RightControl", NoUI = true })

-- [UI Settings / Session Info] Draggable overlay with live stats for the current session
do
    local function buildSessionInfoOverlay()
        local sessionInfoGroup = tabs.uiSettings:AddRightGroupbox("Overlay")

        sessionInfoGroup:AddToggle("sessionInfo_Toggle", { Text = "Session Info", Tooltip = "Shows a draggable overlay with live stats for this session. Only the lines you enable below are tracked.", Default = false })

        local sessionInfoDepbox = sessionInfoGroup:AddDependencyBox()

        sessionInfoDepbox:AddToggle("sessionInfoCompact_Toggle", { Text = "Compact Mode", Tooltip = "Shows everything on a single line, split up by the separator, instead of one line per stat.", Default = false })

        local sessionInfoSeparatorDepbox = sessionInfoDepbox:AddDependencyBox()

        sessionInfoSeparatorDepbox:AddDropdown("sessionInfoSeparator_Dropdown", { Text = "Separator", Tooltip = "What goes between each stat in Compact Mode.", Values = {
            "•  | Bullet point",
            "■  | Black square",
            "- | Hyphen",
            "►  | Black Pointer",
            "→  | Rightwards Arrow",
        }, Default = 1, Multi = false })

        sessionInfoDepbox:AddDropdown("sessionInfoIconPosition_Dropdown", { Text = "Icon Position", Tooltip = false, Values = { "Left", "Right" }, Default = 1, Multi = false })
        sessionInfoDepbox:AddDivider()
        sessionInfoDepbox:AddLabel("Displayed information")

        local sessionInfo = {
            startTime = os.clock(), -- Elapsed Time counts from when the script loaded
            label = nil,
            loopToken = nil,
            lastText = nil,
            needs = {},

            -- Trackers
            renderConnection = nil,
            characterTracker = nil,
            characterSignature = nil,
            bulletTracker = nil,

            -- FPS
            frames = 0,
            frameStamp = os.clock(),
            fps = 0,

            -- Session stats
            kills = 0,
            killStat = nil,
            killBaseline = nil,
            killsAvailable = true,
            deaths = 0,
            bullets = 0,
            bulletsAvailable = true,
            damage = 0,
            mostDamage = 0,
            lifeStart = nil,

            -- Killer scan results (refreshed every update while a killer line is shown)
            scan = { nearestName = nil, nearestDistance = nil, owned = nil },
        }

        -- Only the units that are not zero are shown, e.g. "36s", "12m, 36s" or "1h, 5s".
        local function formatSessionTime(totalSeconds)
            totalSeconds = math.max(0, math.floor(totalSeconds))

            local hours = totalSeconds // 3600
            local minutes = (totalSeconds % 3600) // 60
            local seconds = totalSeconds % 60
            local parts = {}

            if hours > 0 then
                table.insert(parts, hours .. "h")
            end

            if minutes > 0 then
                table.insert(parts, minutes .. "m")
            end

            if seconds > 0 then
                table.insert(parts, seconds .. "s")
            end

            if #parts == 0 then
                return "0s"
            end

            return table.concat(parts, ", ")
        end

        local function roundSessionNumber(value)
            return tostring(math.floor(value + 0.5))
        end

        -- Order here is the order the lines appear in. "needs" lists the trackers a line depends on.
        local sessionInfoItems = {
            { id = "Elapsed", text = "Elapsed Time", default = true, tooltip = "How long the script has been running.",
                value = function() return formatSessionTime(os.clock() - sessionInfo.startTime) end },

            { id = "Kills", text = "Kills", default = true, needs = { "kills" }, tooltip = "Killers you killed this session (not your lifetime Killers Killed).",
                value = function() return sessionInfo.killsAvailable and tostring(sessionInfo.kills) or "N/A" end },

            { id = "Deaths", text = "Deaths", default = true, needs = { "deaths" }, tooltip = "Times you died this session.",
                value = function() return tostring(sessionInfo.deaths) end },

            { id = "KD", text = "K/D Ratio", default = false, needs = { "kills", "deaths" }, tooltip = "Session kills divided by session deaths.",
                value = function()
                    if not sessionInfo.killsAvailable then
                        return "N/A"
                    end

                    return string.format("%.2f", sessionInfo.kills / math.max(sessionInfo.deaths, 1))
                end },

            { id = "Bullets", text = "Bullets Fired", default = false, needs = { "bullets" }, tooltip = "Bullets you fired this session. Every pellet of a shotgun blast counts.",
                value = function() return sessionInfo.bulletsAvailable and tostring(sessionInfo.bullets) or "N/A" end },

            { id = "Damage", text = "Damage Taken", default = false, needs = { "damage" }, tooltip = "Total health you lost this session.",
                value = function() return roundSessionNumber(sessionInfo.damage) end },

            { id = "MostDamage", text = "Most Damage Taken", default = false, needs = { "damage" }, tooltip = "The most health you lost in a single hit this session.",
                value = function() return roundSessionNumber(sessionInfo.mostDamage) end },

            { id = "Survival", text = "Survival Time", default = false, needs = { "survival" }, tooltip = "How long you have been alive since your last death.",
                value = function() return formatSessionTime(sessionInfo.lifeStart and (os.clock() - sessionInfo.lifeStart) or 0) end },

            { id = "Health", text = "Health", default = false, tooltip = "Your current health out of your max health.",
                value = function()
                    local character = localplayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                    if not humanoid then
                        return "N/A"
                    end

                    return roundSessionNumber(humanoid.Health) .. "/" .. roundSessionNumber(humanoid.MaxHealth)
                end },

            { id = "NearestKiller", text = "Nearest Killer", default = false, needs = { "nearest" }, tooltip = "The closest living killer and how far away it is.",
                value = function()
                    local scan = sessionInfo.scan

                    if not scan.nearestName then
                        return "None"
                    end

                    return scan.nearestName .. " (" .. roundSessionNumber(scan.nearestDistance) .. " studs)"
                end },

            { id = "SimulatedKillers", text = "Simulated Killers", default = false, needs = { "owned" }, tooltip = "How many living killers your client owns the physics of. Those are the ones your client can control.",
                value = function() return sessionInfo.scan.owned ~= nil and tostring(sessionInfo.scan.owned) or "N/A" end },

            { id = "FPS", text = "FPS", default = true, needs = { "fps" }, tooltip = false,
                value = function() return sessionInfo.fps > 0 and roundSessionNumber(sessionInfo.fps) or "..." end },

            { id = "Ping", text = "Ping", default = true, tooltip = "Round-trip time to the server in milliseconds.",
                value = function() return roundSessionNumber(localplayer:GetNetworkPing() * 1000) end },
        }

        for _, item in ipairs(sessionInfoItems) do
            item.toggleId = "sessionInfo" .. item.id .. "_Toggle"
            sessionInfoDepbox:AddToggle(item.toggleId, { Text = item.text, Tooltip = item.tooltip, Default = item.default })
        end

        sessionInfoDepbox:SetupDependencies({ { toggles.sessionInfo_Toggle, true } })
        sessionInfoSeparatorDepbox:SetupDependencies({ { toggles.sessionInfoCompact_Toggle, true } })

        local function isSessionInfoItemEnabled(item)
            local toggle = toggles[item.toggleId]

            return toggle ~= nil and toggle.Value == true
        end

        local function getSessionInfoNeeds()
            local needs = {}

            for _, item in ipairs(sessionInfoItems) do
                if item.needs and isSessionInfoItemEnabled(item) then
                    for _, need in ipairs(item.needs) do
                        needs[need] = true
                    end
                end
            end

            return needs
        end

        -- [Session Info / Trackers]

        -- FPS and kills share one RenderStepped connection, and each only does its work while its line is shown.
        local function sessionInfoRenderStep()
            if sessionInfo.needs.fps then
                local now = os.clock()
                sessionInfo.frames += 1

                local elapsed = now - sessionInfo.frameStamp

                if elapsed >= 1 then
                    sessionInfo.fps = sessionInfo.frames / elapsed
                    sessionInfo.frames = 0
                    sessionInfo.frameStamp = now
                end
            end

            if sessionInfo.needs.kills then
                local killStat = sessionInfo.killStat

                if not killStat or not killStat.Parent then
                    local leaderstats = localplayer:FindFirstChild("leaderstats")
                    killStat = leaderstats and leaderstats:FindFirstChild("Killers Killed")
                    sessionInfo.killStat = killStat
                end

                if killStat then
                    local total = killStat.Value
                    local baseline = sessionInfo.killBaseline
                    sessionInfo.killsAvailable = true

                    -- Only the increase since tracking started counts, so the lifetime total is never shown.
                    if baseline == nil or total < baseline then
                        sessionInfo.killBaseline = total
                    elseif total > baseline then
                        sessionInfo.kills += total - baseline
                        sessionInfo.killBaseline = total
                    end
                else
                    sessionInfo.killsAvailable = false
                end
            end
        end

        local function stopSessionInfoCharacterTracker()
            local tracker = sessionInfo.characterTracker

            if tracker then
                for _, connection in ipairs(tracker.connections) do
                    connection:Disconnect()
                end

                for _, connection in ipairs(tracker.humanoidConnections) do
                    connection:Disconnect()
                end

                sessionInfo.characterTracker = nil
            end

            sessionInfo.characterSignature = nil
        end

        -- Deaths, damage and survival time all hang off the character, so they share one tracker that is rebuilt when the set changes.
        local function startSessionInfoCharacterTracker(needs)
            stopSessionInfoCharacterTracker()

            local tracker = { connections = {}, humanoidConnections = {} }
            sessionInfo.characterTracker = tracker
            sessionInfo.characterSignature = (needs.deaths and "d" or "") .. (needs.damage and "a" or "") .. (needs.survival and "s" or "")

            local function attach(character, newLife)
                for _, connection in ipairs(tracker.humanoidConnections) do
                    connection:Disconnect()
                end

                table.clear(tracker.humanoidConnections)

                local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)

                if not humanoid or sessionInfo.characterTracker ~= tracker then
                    return
                end

                if needs.survival then
                    if newLife or (not sessionInfo.lifeStart and humanoid.Health > 0) then
                        sessionInfo.lifeStart = os.clock()
                    end
                end

                if needs.damage then
                    local lastHealth = humanoid.Health

                    table.insert(tracker.humanoidConnections, humanoid.HealthChanged:Connect(function(health)
                        local lost = lastHealth - health
                        lastHealth = health

                        if lost > 0 then
                            sessionInfo.damage += lost

                            if lost > sessionInfo.mostDamage then
                                sessionInfo.mostDamage = lost
                            end
                        end
                    end))
                end

                table.insert(tracker.humanoidConnections, humanoid.Died:Connect(function()
                    if needs.deaths then
                        sessionInfo.deaths += 1
                    end

                    sessionInfo.lifeStart = nil
                end))
            end

            table.insert(tracker.connections, localplayer.CharacterAdded:Connect(function(character)
                task.spawn(attach, character, true)
            end))

            if localplayer.Character then
                task.spawn(attach, localplayer.Character, false)
            end
        end

        local function stopSessionInfoBulletTracker()
            local tracker = sessionInfo.bulletTracker

            if tracker then
                tracker.active = false

                -- If something else wrapped the function after this did, leave it be; the inactive wrapper just passes calls through.
                if rawget(tracker.channel, "send") == tracker.counted then
                    rawset(tracker.channel, "send", tracker.original)
                end

                sessionInfo.bulletTracker = nil
            end
        end

        -- Every bullet goes through the game's fire packet, so wrapping its send counts exactly the bullets this client fires.
        local function startSessionInfoBulletTracker()
            if sessionInfo.bulletTracker then
                return
            end

            local weaponModule = game:GetService("ReplicatedStorage"):FindFirstChild("Weapon")
            local loaded, weaponClass = pcall(function()
                return weaponModule and require(weaponModule)
            end)
            local packets = loaded and type(weaponClass) == "table" and weaponClass.weapon_packets
            local channel = type(packets) == "table" and packets.fire
            local original = type(channel) == "table" and rawget(channel, "send")

            if type(original) ~= "function" then
                sessionInfo.bulletsAvailable = false
                return
            end

            sessionInfo.bulletsAvailable = true

            local tracker = { active = true, channel = channel, original = original }

            tracker.counted = function(...)
                if tracker.active then
                    sessionInfo.bullets += 1
                end

                return original(...)
            end

            rawset(channel, "send", tracker.counted)
            sessionInfo.bulletTracker = tracker
        end

        -- [Session Info / Killer scan] Nearest living killer and how many living killers this client owns
        local function scanSessionInfoKillers(needNearest, needOwned)
            local scan = sessionInfo.scan
            scan.nearestName, scan.nearestDistance, scan.owned = nil, nil, nil

            local folder = killersFolder

            if not folder or not folder.Parent then
                folder = workspace:FindFirstChild("Killers")
            end

            local character = localplayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local canCheckOwner = type(isnetworkowner) == "function"

            if needOwned and canCheckOwner then
                scan.owned = 0
            end

            if not folder then
                return
            end

            for _, killer in ipairs(folder:GetChildren()) do
                local humanoid = killer:FindFirstChildOfClass("Humanoid")
                local killerRoot = killer:FindFirstChild("HumanoidRootPart") or killer.PrimaryPart

                if humanoid and humanoid.Health > 0 and killerRoot then
                    if needNearest and root then
                        local distance = (killerRoot.Position - root.Position).Magnitude

                        if not scan.nearestDistance or distance < scan.nearestDistance then
                            scan.nearestName, scan.nearestDistance = killer.Name, distance
                        end
                    end

                    if scan.owned then
                        local success, owned = pcall(isnetworkowner, killerRoot)

                        if success and owned then
                            scan.owned += 1
                        end
                    end
                end
            end
        end

        -- [Session Info / Label]
        local function getSessionInfoSeparator()
            local dropdown = options.sessionInfoSeparator_Dropdown
            local value = dropdown and tostring(dropdown.Value) or ""

            return value:match("^(%S+)") or "•"
        end

        local function updateSessionInfoLabel()
            local label = sessionInfo.label

            if not label then
                return
            end

            local needs = sessionInfo.needs

            if needs.nearest or needs.owned then
                scanSessionInfoKillers(needs.nearest, needs.owned)
            end

            local lines = {}

            for _, item in ipairs(sessionInfoItems) do
                if isSessionInfoItemEnabled(item) then
                    local success, value = pcall(item.value)
                    table.insert(lines, item.text .. ": " .. (success and value or "N/A"))
                end
            end

            local text

            if #lines == 0 then
                text = "No information selected"
            elseif toggles.sessionInfoCompact_Toggle.Value then
                text = table.concat(lines, " " .. getSessionInfoSeparator() .. " ")
            else
                text = table.concat(lines, "\n")
            end

            if text ~= sessionInfo.lastText then
                sessionInfo.lastText = text
                label:SetText(text)
            end
        end

        local function createSessionInfoLabel()
            local iconPosition = options.sessionInfoIconPosition_Dropdown and options.sessionInfoIconPosition_Dropdown.Value or "Left"

            local created, label = pcall(function()
                return library:AddDraggableLabel({
                    Text = "Session Info",
                    Icon = assetLib.fetchAsset("Icons/Celestial.png"),
                    IconPosition = iconPosition,
                })
            end)

            if not created or not label then
                -- The icon could not be loaded; the overlay still works without it.
                created, label = pcall(function()
                    return library:AddDraggableLabel({ Text = "Session Info", IconPosition = iconPosition })
                end)
            end

            if created and label then
                pcall(function()
                    label.Label.TextXAlignment = Enum.TextXAlignment.Left
                end)

                sessionInfo.label = label
                sessionInfo.lastText = nil
            end
        end

        local function stopSessionInfo()
            sessionInfo.loopToken = nil
            sessionInfo.needs = {}

            if sessionInfo.renderConnection then
                sessionInfo.renderConnection:Disconnect()
                sessionInfo.renderConnection = nil
            end

            stopSessionInfoCharacterTracker()
            stopSessionInfoBulletTracker()

            if sessionInfo.label then
                pcall(function()
                    sessionInfo.label:Destroy()
                end)

                sessionInfo.label = nil
            end

            sessionInfo.lastText = nil
        end

        -- Runs whenever the overlay or any of its lines is switched, and only keeps running what the shown lines need.
        local function refreshSessionInfo()
            local overlayToggle = toggles.sessionInfo_Toggle

            if library.Unloaded or not overlayToggle or overlayToggle.Value ~= true then
                stopSessionInfo()
                return
            end

            if not sessionInfo.label then
                createSessionInfoLabel()

                if not sessionInfo.label then
                    return
                end
            end

            local previous = sessionInfo.needs
            local needs = getSessionInfoNeeds()
            sessionInfo.needs = needs

            -- A tracker that was off starts from a clean baseline so nothing from the gap is counted.
            if needs.kills and not previous.kills then
                sessionInfo.killBaseline = nil
            end

            if needs.fps and not previous.fps then
                sessionInfo.frames, sessionInfo.frameStamp, sessionInfo.fps = 0, os.clock(), 0
            end

            local needsRender = needs.fps or needs.kills

            if needsRender and not sessionInfo.renderConnection then
                sessionInfo.renderConnection = runService.RenderStepped:Connect(sessionInfoRenderStep)
            elseif not needsRender and sessionInfo.renderConnection then
                sessionInfo.renderConnection:Disconnect()
                sessionInfo.renderConnection = nil
            end

            local needsCharacter = needs.deaths or needs.damage or needs.survival

            if needsCharacter then
                local signature = (needs.deaths and "d" or "") .. (needs.damage and "a" or "") .. (needs.survival and "s" or "")

                if sessionInfo.characterSignature ~= signature then
                    startSessionInfoCharacterTracker(needs)
                end
            else
                stopSessionInfoCharacterTracker()
            end

            if needs.bullets then
                startSessionInfoBulletTracker()
            else
                stopSessionInfoBulletTracker()
            end

            if not sessionInfo.loopToken then
                local token = {}
                sessionInfo.loopToken = token

                task.spawn(function()
                    while sessionInfo.loopToken == token and not library.Unloaded do
                        pcall(updateSessionInfoLabel)
                        task.wait(0.25)
                    end
                end)
            end

            pcall(updateSessionInfoLabel)
        end

        toggles.sessionInfo_Toggle:OnChanged(refreshSessionInfo)

        for _, item in ipairs(sessionInfoItems) do
            toggles[item.toggleId]:OnChanged(refreshSessionInfo)
        end

        -- Compact Mode and the separator are read on every update, so they only need the text rebuilt.
        local function rebuildSessionInfoText()
            sessionInfo.lastText = nil
            pcall(updateSessionInfoLabel)
        end

        toggles.sessionInfoCompact_Toggle:OnChanged(rebuildSessionInfoText)
        options.sessionInfoSeparator_Dropdown:OnChanged(rebuildSessionInfoText)

        options.sessionInfoIconPosition_Dropdown:OnChanged(function(position)
            if sessionInfo.label then
                pcall(sessionInfo.label.SetIconPosition, sessionInfo.label, position)
            end
        end)

        table.insert(teardownTasks, stopSessionInfo)
    end

    buildSessionInfoOverlay()
end

-- [UI Settings / Teardown] Disable active features and clear shared state
local function unloadModules()
    -- Switch off every toggle so each OnChanged handler can stop its own loops, connections and hooks.
    for name, toggle in pairs(toggles) do
        if type(toggle) == "table" and toggle.Value == true and type(toggle.SetValue) == "function"
            and name ~= "openKeybindMenu_Toggle" and name ~= "autoResetColor_Toggle" and name ~= "notifSound_Toggle" then
            local success = pcall(toggle.SetValue, toggle, false)

            if not success then
                -- The UI side failed; still make sure the value is off and the handler runs.
                toggle.Value = false
                pcall(function() toggle:RunChanged() end)
            end
        end
    end

    -- Rainbow loops index options[...] every frame, so stop them directly.
    for _, connection in pairs(rainbowConnections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end

    table.clear(rainbowConnections)
    table.clear(rainbowState.active)
    rainbowState.hue = 0

    shared.scriptLoaded = false
    isUpdatingTeleporterState = false

    -- Feature teardown (silent aim hooks, FOV circle, always-on RenderStepped handlers).
    for _, teardown in ipairs(teardownTasks) do
        local success, err = pcall(teardown)

        if not success then
            warn("[Celestial] Teardown error:", err)
        end
    end

    table.clear(teardownTasks)
end

-- Library:Unload() empties library.Toggles / library.Options right after it runs its unload callbacks. Anything that
-- outlives the UI (event connections, game weapon hooks, looping threads) would then hit "attempt to index nil with
-- 'Value'", so this script's references are swapped to snapshots before anything else happens.
library:OnUnload(function()
    local function snapshot(source)
        local copy = {}

        for key, value in pairs(source) do
            copy[key] = value
        end

        return copy
    end

    toggles = snapshot(toggles)
    options = snapshot(options)

    unloadModules()
end)

-- [UI Settings / Teardown] Watch for external UI removal

for _, newUI in pairs(gethui():GetDescendants()) do
    if newUI:IsA("ScreenGui") then
        if newUI.Name == "Obsidian" then
            task.spawn(function()
                newUI.AncestryChanged:Connect(function(_, parent)
                    if not parent and not library.Unloaded then
                        library:Unload() -- runs unloadModules() through the OnUnload callback
                    end
                end)
            end)
        end
    end
end

menuGroup:AddButton({
    Text = "Unload",
    DoubleClick = true,
    Func = function()
        library:Unload() -- runs unloadModules() through the OnUnload callback, before the library clears its tables
    end,
})

library.ToggleKeybind = options.menuKeybind_KeyPicker

notifAlertVolume_Slider:OnChanged(function(val) window.alertVolume = val end)
rainbowSpeed_Slider:OnChanged(function(val) window.rainbowSpeed = val end)

-- [UI Settings / Persistence] Theme and configuration setup
themeManager:SetLibrary(library)
saveManager:SetLibrary(library)
saveManager:IgnoreThemeSettings()
saveManager:SetIgnoreIndexes({ "menuKeybind_KeyPicker" })
themeManager:SetFolder("Celestial ScriptHub")
saveManager:SetFolder("Celestial ScriptHub/SAKTKIA51")
saveManager:SetSubFolder("Classic Mode")
saveManager:BuildConfigSection(tabs.uiSettings, "folder-cog")
themeManager:ApplyToTab(tabs.uiSettings, "paintbrush")
saveManager:LoadAutoloadConfig()