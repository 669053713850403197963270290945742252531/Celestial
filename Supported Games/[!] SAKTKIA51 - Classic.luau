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
    09. Player: movement, phase, speed handling, freecam, and backtrack
    10. Exploits: Pack-a-Punch, aim controls, collection, killer controls, and Hitbox Expander
    11. Visuals: ESP, FOV, fog, anti-effect handlers, scope overlay removal, Hitbox Visualizer, and grenade trajectory preview
    12. World: environmental settings, door noclip, and alien / kill-part controls
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

local rainbowConnections: { [string]: any } = {}
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
    SearchbarSize = UDim2.fromScale(0.5, 1),
    GlobalSearch = true,
    EnableSidebarResize = true,
    EnableCompacting = true,
    Snapping = true,
    TabSwipeFrom = "Right",

    TabButtonsStyle = {
        Gap = 4,
        Padding = 6,
        CornerRadius = 6,
        Indicator = true,
        IndicatorWidth = 3,
        IndicatorHeight = 20,
    },

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
    home = window:AddTab("Home", assetLib.fetchAsset("Icons/info.png"), "Player info, game info, and whitelist"),
    utils = window:AddTab("Utility", assetLib.fetchAsset("Icons/wrench.png"), "Teleports, healing, sounds, and interactions"),
    player = window:AddTab("Player", assetLib.fetchAsset("Icons/circle-user-round.png"), "Movement, phase, freecam, and backtrack"),
    exploits = window:AddTab("Exploits", assetLib.fetchAsset("Icons/bug.png"), "Aim, collection, killer controls, and hitboxes"),
    visuals = window:AddTab("Visuals", assetLib.fetchAsset("Icons/eye.png"), "ESP, FOV, effects, hitboxes, and trajectory preview"),
    world = window:AddTab("World", assetLib.fetchAsset("Icons/globe.png"), "Map hazards, doors, and Alien controls"),
    weapons = window:AddTab("Weapons", assetLib.fetchAsset("Icons/swords.png"), "Inventory, defense, gun mods, and skins"),
    misc = window:AddTab("Miscellaneous", assetLib.fetchAsset("Icons/circle-ellipsis.png"), "Weapon spam and keycard shortcuts"),
    uiSettings = window:AddTab("UI Settings", assetLib.fetchAsset("Icons/settings.png"), "Menu, overlay, themes, and configs"),
}

-- 06 | SHARED HELPERS

-- [Shared Helpers / Notifications] Volume and notification formatting
local function getAlertVolume()
    if not window.notifSoundEnabled then
        return 0
    end

    return math.max(0, tonumber(window.alertVolume) or 3)
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

    local volume = getAlertVolume()
    local notification = nil

    if notificationType == "Success" then
        notification = library:Notify({
            Title = title,
            TitleColor = Color3.fromRGB(21, 140, 49),
            Description = desc,
            Time = duration,
            Persist = persist == true,
            Priority = 1,
            SoundId = volume > 0 and assetLib.fetchAsset("Sounds/new/success.wav") or nil,
            Volume = volume,
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
            SoundId = volume > 0 and assetLib.fetchAsset("Sounds/new/error.wav") or nil,
            Volume = volume,
            BigIcon = assetLib.fetchAsset("Icons/circle-x.png"),
            IconColor = Color3.fromRGB(140, 21, 21),
            Closable = true,
        })
    elseif notificationType == "Warning" then
        notification = library:Notify({
            Title = title,
            TitleColor = Color3.fromRGB(247, 92, 20),
            Description = desc,
            Time = duration,
            Persist = persist == true,
            Priority = 0,
            SoundId = volume > 0 and assetLib.fetchAsset("Sounds/new/warning.wav") or nil,
            Volume = volume,
            BigIcon = assetLib.fetchAsset("Icons/octagon-exclamation-point.png"),
            IconColor = Color3.fromRGB(247, 92, 20),
            Closable = true,
        })
    elseif notificationType == "Info" then
        notification = library:Notify({
            Title = title,
            Description = desc,
            Time = duration,
            Persist = persist == true,
            Priority = 2,
            SoundId = volume > 0 and assetLib.fetchAsset("Sounds/new/info.wav") or nil,
            Volume = volume,
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
            notify("Error", "Invalid object", "Invalid colorpicker object and/or no valid default was found.", 15)
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

                notify("Error", "Invalid object", "Invalid colorpicker object and/or no valid default was found.", 15)
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
        notify("Error", "Invalid instance", "Argument #1 (sliderObj) did not return a table instance.", 15)
        return
    end

    if typeof(suffixString) ~= "string" then
        notify("Error", "Invalid instance", "Argument #2 (suffixString) did not return a string value.", 15)
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

playerTab:AddImage("UserThumbnail", { Image = utils.fetchUserThumbnail("AvatarBust", "Size420x420"), Height = 200, BackgroundTransparency = 1 })

local resolvedBeforeToggle = false

utils.fetchResetButtonState(function(isActive)
    resolvedBeforeToggle = true
    if toggles.respawnButton_Toggle then
        toggles.respawnButton_Toggle:SetValue(isActive)
    end
end)

local respawnButton_Toggle = playerTab:AddToggle("toggleRespawn_Toggle", { Text = "Respawn Button", Default = resolvedBeforeToggle or false })
toggles.respawnButton_Toggle = respawnButton_Toggle

playerTab:AddLabel("Name: " .. localplayer.DisplayName .. " (@" .. localplayer.Name .. ")", true)
playerTab:AddLabel("UserId: " .. localplayer.UserId, true)

respawnButton_Toggle:OnChanged(function(enabled)
    utils.setGuiEnabled("reset button", enabled)
end)

-- [Home / Game] Game information and session actions

gameTab:AddImage("GameIcon", { Image = utils.fetchGameImage("Icon"), Height = 200, BackgroundTransparency = 1 })

gameTab:AddLabel("Game Name: " .. gameName .. " - " .. getMode(), true)
gameTab:AddLabel("Place ID: " .. game.PlaceId, true)
gameTab:AddLabel("Classic Mode: " .. getMode(), true)
gameTab:AddLabel("Creator ID: " .. game.CreatorId, true)
gameTab:AddLabel("Creator Type: " .. game.CreatorType.Name, true)

gameTab:AddButton({ Text = "Serverhop",
    Func = function()
        local reload
        window:AddDialog("reloadConfirmation_Dialog", { Title = "Reload", Description = "Would you like to reload the script when you join the new server?", OutsideClickDismiss = true,
            FooterButtons = {
                Cancel = { Title = "No", Variant = "Ghost", Order = 1,
                    Callback = function(self)
                        reload = false
                    end
                },

                Confirm = { Title = "Yes", Variant = "Primary", Order = 2,
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
local teleportGroup = tabs.utils:AddGroupbox({ Side = "Left", Name = "Teleport", IconName = assetLib.fetchAsset("Icons/map-pin.png"), Description = "Jump to map locations", })
local healingGroup = tabs.utils:AddGroupbox({ Side = "Right", Name = "Healing", IconName = assetLib.fetchAsset("Icons/heart-pulse.png"), Description = "Drinks and refills" })
local soundsGroup = tabs.utils:AddGroupbox({ Side = "Left", Name = "Sounds", IconName = assetLib.fetchAsset("Icons/volume-2.png"), Description = "Mute map ambience" })
local otherGroup2 = tabs.utils:AddGroupbox({ Side = "Right", Name = "Other", IconName = assetLib.fetchAsset("Icons/mouse-pointer-click.png"), Description = "Prompts and doors" })

-- [Utility / Teleport] Location controls

teleportGroup:AddDropdown("locationsList_Dropdown", { Text = "Location", Values = {"Surface", "Area 51", "Teleportation Zone", "Alien", "Keypad Room",
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
}):AddKeyPicker("office_KeyPicker", { Default = "V", Text = "Teleport to Office", Mode = "Press" })

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

healingGroup:AddSlider("energyDrinkAmount_Slider", { Text = "Drink Amount", Tooltip = "How much to drink from the energy drink.", Default = 5, Min = 1, Max = 5, Disabled = not getEnergyDrinkState() })
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

autoDrinkToggle = healingGroup:AddToggle("autoDrink_Toggle", { Text = "Auto Drink", Tooltip = "Drinks the entire energy drink when you are below the threshold.", Disabled = not getEnergyDrinkState() })

-- [Utility / Healing] Toggle controls and dependency wiring
local autoDrinkDepbox = healingGroup:AddDependencyBox()
autoDrinkThresholdSlider = autoDrinkDepbox:AddSlider("autoDrinkThreshold_Slider", { Text = "Threshold", Default = 40, Min = 10, Max = getMaxThreshold() })

autoDrinkDepbox:SetupDependencies({ { toggles.autoDrink_Toggle, true } })

autoRefillToggle = healingGroup:AddToggle("autoRefill_Toggle", { Text = "Auto Refill", Tooltip = "Refills your energy drink when it has no more charges left.", Disabled = not getEnergyDrinkState() })

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

do
    -- [Utility / Sounds] Sound toggles and event muting

    local disabledSounds: {[string]: boolean} = { Lightning = false, Thunder = false, Music = false }

    local ambienceSoundNames: {[string]: string} = { Lightning = "LightningSound", Thunder = "ThunderSound", Music = "Music" }

    -- [option] = { connections = {RBXScriptConnection}, watched = { [Sound] = true } } while that option is muted
    local ambienceMuters = {}

    -- Playing is checked first, so the Stop() can never re-trigger the signal that called it
    local function silenceSound(sound: Sound)
        if sound.Playing then
            sound:Stop()
        end
    end

    local function watchAmbienceSound(option: string, muter, sound: Sound)
        if muter.watched[sound] then
            return
        end

        muter.watched[sound] = true

        local function onStarted()
            if disabledSounds[option] then
                silenceSound(sound)
            end
        end

        -- Stops the sound the moment the game starts it
        table.insert(muter.connections, sound:GetPropertyChangedSignal("Playing"):Connect(onStarted))
        table.insert(muter.connections, sound.Played:Connect(onStarted))

        silenceSound(sound) -- Already playing when the option was enabled
    end

    local function stopMutingAmbience(option: string)
        local muter = ambienceMuters[option]

        if not muter then
            return
        end

        ambienceMuters[option] = nil

        for _, connection in ipairs(muter.connections) do
            connection:Disconnect()
        end
    end

    local function startMutingAmbience(option: string)
        if ambienceMuters[option] then
            return
        end

        local muter = { connections = {}, watched = setmetatable({}, { __mode = "k" }) }
        ambienceMuters[option] = muter

        local soundName = ambienceSoundNames[option]

        local function onChild(child: Instance)
            if child.Name == soundName and child:IsA("Sound") then
                watchAmbienceSound(option, muter, child :: Sound)
            end
        end

        -- Connected before the scan so a sound created in between is not missed; it also covers a sound the game replaces later
        table.insert(muter.connections, game.Workspace.ChildAdded:Connect(onChild))

        for _, child in ipairs(game.Workspace:GetChildren()) do
            onChild(child)
        end
    end

    local function setAmbienceMuted(option: string, muted: boolean)
        if muted then
            startMutingAmbience(option)
        else
            stopMutingAmbience(option)
        end
    end

    table.insert(teardownTasks, function()
        for option in pairs(ambienceMuters) do
            stopMutingAmbience(option)
        end
    end)

    soundsGroup:AddDropdown("disabledSoundsList_Dropdown", { Text = "Disabled Ambience", Values = { "Lightning", "Thunder", "Music" }, Multi = true, AllowNull = true,
        Callback = function(valueTable)
            for option in pairs(disabledSounds) do
                local newState = valueTable[option] or false

                if disabledSounds[option] ~= newState then
                    disabledSounds[option] = newState
                    setAmbienceMuted(option, newState)
                end
            end
        end,
    })

    soundsGroup:AddButton({ Text = "Disable All Ambience",
        Func = function()
            options.disabledSoundsList_Dropdown:SetValue({ Lightning = true, Thunder = true, Music = true })
        end,
    })
end

-- [Utility / Interactions] Prompt reach and door interaction helpers

otherGroup2:AddToggle("promptReach_Toggle", { Text = "Prompt Reach" })
otherGroup2:AddToggle("weaponPromptReach_Toggle", { Text = "Weapon Prompt Reach" })
otherGroup2:AddToggle("instantInteract_Toggle", { Text = "Instant Interact" })
otherGroup2:AddToggle("autoOpenDoors_Toggle", { Text = "Auto Open Doors", Tooltip = "Automatically opens all nearby doors." })
otherGroup2:AddToggle("autoCloseDoors_Toggle", { Text = "Auto Close Doors", Tooltip = "Automatically closes all nearby doors." })

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
local movementGroup = tabs.player:AddGroupbox({ Side = "Left", Name = "Movement", IconName = assetLib.fetchAsset("Icons/move.png"), Description = "Speed, fly, noclip, phase" })
local othersGroup3 = tabs.player:AddGroupbox({ Side = "Right", Name = "Other", IconName = assetLib.fetchAsset("Icons/sliders-horizontal.png"), Description = "Freecam, backtrack, guard, lag" })

-- [Player / Movement] Speed, fly, noclip, and jump settings

-- [Player / Speed Check Bypass] Controls

movementGroup:AddToggle("speedBypass_Toggle", { Text = "Speed Check Bypass", Default = true, Tooltip = "EXPERIMENTAL. Disables the game's client-side movement checks (WalkSpeed, JumpPower, state changes, collision). You should still be cautious when using features in the Player tab." })

local speedBypassDepbox = movementGroup:AddDependencyBox()
speedBypassDepbox:AddToggle("speedBypassNoAcceleration_Toggle", { Text = "Disable Acceleration", Tooltip = "Removes the slight sliding effect when starting or stopping at high WalkSpeed values. Only applies while on the ground." })
speedBypassDepbox:AddDivider()

-- [Player / Speed Exploit] Controls

movementGroup:AddToggle("speedExploit_Toggle", { Text = "Speed Exploit" })

local speedExploitDepbox = movementGroup:AddDependencyBox()
speedExploitDepbox:AddDropdown("speedExploitMethod_Dropdown", { Text = "Method", Values = { "WalkSpeed", "Velocity" }, Default = 1 })
speedExploitDepbox:AddSlider("speedExploitAmount_Slider", { Text = "Amount", Default = 20, Min = 16, Max = 100 })
speedExploitDepbox:AddLabel("Due to Roblox's physics limitations, high velocity speeds may cause unexpected falling on collisions.", true)
speedExploitDepbox:AddDivider()

-- [Player / Fly] Controls and input handling

movementGroup:AddToggle("enableFly_Toggle", { Text = "Enable Fly" })

local flyDepbox = movementGroup:AddDependencyBox()
flyDepbox:AddToggle("toggleFly_Toggle", { Text = "Fly" })
:AddKeyPicker("fly_KeyPicker", { Text = "Fly", Default = "F", SyncToggleState = true, Mode = "Toggle", NoUI = true, Disabled = true })
local flyHorizSpeed_Slider = flyDepbox:AddSlider("flyHorizSpeed_Slider", { Text = "Horizontal Speed", Tooltip = "The speed you normally go at.", Default = 100, Min = 30, Max = 1000 })
local flyVertSpeed_Slider = flyDepbox:AddSlider("flyVertSpeed_Slider", { Text = "Vertical Speed", Tooltip = "The speed you go when ascending/descending.", Default = 100, Min = 30, Max = 300 })
flyDepbox:AddLabel("Fly is NOT compatible when Speed Exploit's mode is set as Velocity and will be swapped.", true)
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
jumpPowerDepbox:AddSlider("jumpPowerValue_Slider", { Text = "Value", Default = 50, Min = 50, Max = 200 })

speedBypassDepbox:SetupDependencies({ { toggles.speedBypass_Toggle, true } })
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
        Original = setmetatable({}, { __mode = "k" }) :: any, -- part -> CanCollide before noclip first touched it
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

local WALKSPEED_BASE_MAX = 25 -- WalkSpeed slider maximum while Speed Check Bypass is off
local WALKSPEED_BYPASS_MAX = 200 -- WalkSpeed slider maximum while Speed Check Bypass is on

local function getWalkSpeedMax()
    return toggles.speedBypass_Toggle.Value and WALKSPEED_BYPASS_MAX or WALKSPEED_BASE_MAX
end

local method = options.speedExploitMethod_Dropdown.Value
local slider = options.speedExploitAmount_Slider
slider:SetMin(1)

if method == "WalkSpeed" then
    slider:SetMax(getWalkSpeedMax())
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
        local walkSpeedMax = getWalkSpeedMax()
        slider:SetMin(1)
        slider:SetMax(walkSpeedMax)
        if slider.Value > walkSpeedMax then slider:SetValue(walkSpeedMax) end
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

-- [Player / Speed Check Bypass] Disables the game's client-side movement checks and fully reverses it when turned off
do
    local bypass = {
        Active = false,
        Generation = 0, -- bumped on every start/stop so in-progress character setups know they are stale
        Disabled = {}, -- every connection this feature disabled, so each one can be re-enabled
        CharacterAdded = nil :: RBXScriptConnection?,
    }

    local INITIALIZATION_TIMEOUT = 5
    local RETRY_INTERVAL = 0.05

    local checks = {
        { Name = "WalkSpeed", Signal = function(hum) return hum:GetPropertyChangedSignal("WalkSpeed") end },
        { Name = "JumpPower", Signal = function(hum) return hum:GetPropertyChangedSignal("JumpPower") end },
        { Name = "StateChanged", Signal = function(hum) return hum.StateChanged end },
        { Name = "Strafing", Signal = function(hum) return hum.Strafing end },
        { Name = "Swimming", Signal = function(hum) return hum.Swimming end },
        { Name = "DescendantAdded", Signal = function(_, character) return character.DescendantAdded end },
        { Name = "CanCollide", Signal = function(_, _, root) return root:GetPropertyChangedSignal("CanCollide") end },
    }

    local function initializeCharacter(character: Model, generation: number, target: string)
        local hum = character:WaitForChild("Humanoid", 10)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if not hum or not root then return end

        local completed = {}
        local deadline = os.clock() + INITIALIZATION_TIMEOUT

        repeat
            if bypass.Generation ~= generation then return end

            local pending = false

            for _, check in ipairs(checks) do
                if not completed[check.Name] then
                    local found = false

                    for _, connection in ipairs(getconnections(check.Signal(hum, character, root))) do
                        local callback = connection.Function
                        local info = callback and debug.getinfo(callback)
                        local source = info and info.source

                        if type(source) == "string" and string.find(source, target, 1, true) then
                            found = true

                            if not bypass.Disabled[connection] and pcall(function() connection:Disable() end) then
                                bypass.Disabled[connection] = true

                                -- Turned off while this was running: undo it right away.
                                if bypass.Generation ~= generation then
                                    bypass.Disabled[connection] = nil
                                    pcall(function() connection:Enable() end)
                                    return
                                end
                            end
                        end
                    end

                    completed[check.Name] = found

                    if not found then
                        pending = true
                    end
                end
            end

            if not pending then break end

            task.wait(RETRY_INTERVAL)
        until os.clock() >= deadline

        if bypass.Generation ~= generation then return end

        local missing = {}
        for _, check in ipairs(checks) do
            if not completed[check.Name] then
                table.insert(missing, check.Name)
            end
        end

        if #missing > 0 then
            notify("Error", "Speed Check Bypass", "Could not find these checks: " .. table.concat(missing, ", "), 10)
        end
    end

    -- UI-free so it is also safe to call from teardown after the library has cleared its toggles.
    local function stopBypass()
        if not bypass.Active then return end

        bypass.Active = false
        bypass.Generation += 1

        if bypass.CharacterAdded then
            bypass.CharacterAdded:Disconnect()
            bypass.CharacterAdded = nil
        end

        for connection in pairs(bypass.Disabled) do
            pcall(function() connection:Enable() end)
        end

        table.clear(bypass.Disabled)
    end

    local function startBypass()
        if bypass.Active then return end

        if type(getconnections) ~= "function" then
            notify("Error", "Speed Check Bypass", "Your executor does not support getconnections.", 10)
            task.defer(function() toggles.speedBypass_Toggle:SetValue(false) end)
            return
        end

        bypass.Active = true
        bypass.Generation += 1
        local generation = bypass.Generation

        task.spawn(function()
            local gamemodeScript = localplayer:WaitForChild("PlayerScripts"):WaitForChild("CommonGamemodeSetup", 10)
            if bypass.Generation ~= generation then return end

            if not gamemodeScript then
                notify("Error", "Speed Check Bypass", "Could not find the game's movement check script.", 10)
                toggles.speedBypass_Toggle:SetValue(false)
                return
            end

            local target = gamemodeScript:GetFullName()

            if localplayer.Character then
                task.spawn(initializeCharacter, localplayer.Character, generation, target)
            end

            bypass.CharacterAdded = localplayer.CharacterAdded:Connect(function(character)
                task.spawn(initializeCharacter, character, generation, target)
            end)
        end)
    end

    -- Disable Acceleration: the Humanoid slides to a stop, which is very noticeable at high WalkSpeed.
    -- While grounded and above the default speed, snap horizontal velocity to the movement input (and to zero without input).
    local noAcceleration = { Connection = nil :: RBXScriptConnection? }

    local function stopNoAcceleration()
        if noAcceleration.Connection then
            noAcceleration.Connection:Disconnect()
            noAcceleration.Connection = nil
        end
    end

    local function startNoAcceleration()
        if noAcceleration.Connection then return end

        noAcceleration.Connection = runService.RenderStepped:Connect(function()
            local character = localplayer.Character
            local hum = character and character:FindFirstChildOfClass("Humanoid")
            local root = hum and hum.RootPart
            if not hum or not root then return end

            if hum.Health <= 0 or hum.Sit or hum.PlatformStand then return end
            if hum.WalkSpeed <= 16 or hum.FloorMaterial == Enum.Material.Air then return end
            if toggles.toggleFly_Toggle.Value then return end
            if toggles.speedExploit_Toggle.Value and options.speedExploitMethod_Dropdown.Value == "Velocity" then return end

            local velocity = root.AssemblyLinearVelocity
            local moveDirection = hum.MoveDirection

            if moveDirection.Magnitude > 0 then
                local target = moveDirection.Unit * hum.WalkSpeed
                root.AssemblyLinearVelocity = Vector3.new(target.X, velocity.Y, target.Z)
            else
                root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
            end
        end)
    end

    -- Active only while the bypass and its Disable Acceleration option are both on.
    local function refreshNoAcceleration()
        if toggles.speedBypass_Toggle.Value and toggles.speedBypassNoAcceleration_Toggle.Value then
            startNoAcceleration()
        else
            stopNoAcceleration()
        end
    end

    toggles.speedBypassNoAcceleration_Toggle:OnChanged(refreshNoAcceleration)

    toggles.speedBypass_Toggle:OnChanged(function(enabled)
        refreshNoAcceleration()

        local slider = options.speedExploitAmount_Slider
        local walkSpeedMode = options.speedExploitMethod_Dropdown.Value == "WalkSpeed"

        if enabled then
            -- Checks go down first, then the higher limit opens up.
            startBypass()

            if walkSpeedMode then
                slider:SetMin(1)
                slider:SetMax(WALKSPEED_BYPASS_MAX)
            end
        else
            -- Bring speed back under the normal limit first, then re-enable the checks.
            if walkSpeedMode then
                slider:SetMin(1)
                slider:SetMax(WALKSPEED_BASE_MAX)
                if slider.Value > WALKSPEED_BASE_MAX then slider:SetValue(WALKSPEED_BASE_MAX) end
            end

            applySpeed()
            stopBypass()
        end
    end)

    table.insert(teardownTasks, stopBypass)
    table.insert(teardownTasks, stopNoAcceleration)

    -- Enabled by default: OnChanged does not fire for the initial value.
    if toggles.speedBypass_Toggle.Value then
        startBypass()
    end

    refreshNoAcceleration()
end

-- [Player / Phase] Teleports you through a wall to the floor on the other side
do
    local performPhase

    local function buildPhase()
        movementGroup:AddToggle("enablePhase_Toggle", { Text = "Enable Phase", Tooltip = "Adds a Phase button and keybind. Phase teleports you through the wall in front of you to the floor behind it. It is not noclip: it refuses when the wall is too thick or there is no safe floor behind it." })

        local phaseDepbox = movementGroup:AddDependencyBox()

        phaseDepbox:AddButton({ Text = "Phase", Tooltip = "Teleports you through the wall you are facing (or walking into) to the floor behind it.",
            Func = function()
                performPhase()
            end,
        }):AddKeyPicker("phase_KeyPicker", { Default = "B", Text = "Phase", Mode = "Press", NoUI = true, Disabled = true })

        phaseDepbox:AddSlider("phaseWallThickness_Slider", { Text = "Wall Thickness", Tooltip = "The thickest wall Phase will go through. Thicker walls are refused. Nearly all walls in the map are 0.5-1 stud thick; a few go up to about 10.", Default = 5, Min = 2, Max = 10, Suffix = " Studs", Rounding = 1,
            Callback = function(val)
                options.phaseWallThickness_Slider:SetSuffix(getSuffix(options.phaseWallThickness_Slider, "Stud"))
            end
        })

        phaseDepbox:AddToggle("phaseSkipGaps_Toggle", { Text = "Skip Gaps", Tooltip = "When there is no floor behind the wall, keep scanning across the gap and land on the first safe ground. If another wall appears (like the wall of a room) Phase crosses it too, within the Wall Thickness limit, and lands on the floor inside." })

        local phaseGapDepbox = phaseDepbox:AddDependencyBox()

        phaseGapDepbox:AddSlider("phaseGapDistance_Slider", { Text = "Max Gap Scan", Tooltip = "How far past the first wall Skip Gaps will scan for safe ground, in studs.", Default = 60, Min = 10, Max = 150, Suffix = " Studs",
            Callback = function(val)
                options.phaseGapDistance_Slider:SetSuffix(getSuffix(options.phaseGapDistance_Slider, "Stud"))
            end
        })

        phaseGapDepbox:SetupDependencies({ { toggles.phaseSkipGaps_Toggle, true } })

        phaseDepbox:AddDivider()

        phaseDepbox:SetupDependencies({ { toggles.enablePhase_Toggle, true } })

        toggles.enablePhase_Toggle:OnChanged(function(enabled)
            local keypicker = options.phase_KeyPicker
            keypicker:SetDisabled(not enabled)
            keypicker:SetNoUI(not enabled)
        end)

        local config = {
            Reach = 6, -- studs in front of you that a wall may start
            Step = 0.25, -- studs between wall-thickness checks
            ProbeSize = Vector3.new(0.5, 3, 0.5), -- torso-height box that follows the wall (floor-level clutter is not a wall)
            ClearanceBox = Vector3.new(2.4, 4.6, 2.4), -- room needed around the landing spot (a bit larger than your body)
            ClearanceLift = 0.35, -- the clearance box sits this far above the root part, so the floor itself is never inside it
            ClearanceHalf = 1.25, -- the landing spot starts this far behind the wall's far face
            LandingSearch = 8, -- studs behind the wall that are searched for a landing spot
            MaxRise = 2.5, -- highest step up from your current floor that counts as floor behind the wall
            MaxDrop = 12, -- deepest drop from your current floor that counts as floor behind the wall
            MinFloorNormalY = 0.7, -- steeper than this is a wall or a slide, not a floor
            BoundsInset = 2, -- studs the landing spot is kept inside the MapLimit walls
            CeilingInset = 3, -- studs the landing spot is kept below the MapLimit ceiling
            GapStep = 0.5, -- studs between checks while scanning across a gap (matches the probe width, so thin walls are not skipped)
            GapMaxWalls = 4, -- most extra walls Skip Gaps will cross in one Phase
            GapEdgeMargin = 0.75, -- Skip Gaps will not land on the very lip of a floor: there must be floor this far back toward the gap too
            Cooldown = 0.3,
            NotifyCooldown = 1,
        }

        -- Roots to count as the "real" map
        local realMapRoots = { "AREA51", "Doors", "Spawns", "PACKAPUNCH", "Top10" }

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

        local mapBounds = nil
        local lastPhase = -math.huge
        local lastNotify = -math.huge

        local function notifyPhase(description)
            local now = os.clock()

            if now - lastNotify < config.NotifyCooldown then
                return
            end

            lastNotify = now
            notify("Error", "Phase", description, 3)
        end

        -- Your character, killers, other players and the MapLimit walls are never walls
        local function refreshFilters(character)
            local ignored = { character }

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
        end

        -- Inner faces of the MapLimit walls (a wall is thin on exactly one axis; that axis is the one it closes off)
        local function measureMapBounds()
            local area = workspace:FindFirstChild("AREA51")
            local limit = area and area:FindFirstChild("MapLimit")

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

            return { Min = Vector3.new(low.X, low.Y, low.Z), Max = Vector3.new(high.X, high.Y, high.Z) }
        end

        local function insideMapBox(position)
            if not mapBounds then
                local success, bounds = pcall(measureMapBounds)
                mapBounds = success and bounds or nil
            end

            if not mapBounds then
                return true -- the limits could not be measured; the floor and room checks still apply
            end

            local inset = config.BoundsInset

            return position.X >= mapBounds.Min.X + inset and position.X <= mapBounds.Max.X - inset
                and position.Z >= mapBounds.Min.Z + inset and position.Z <= mapBounds.Max.Z - inset
                and position.Y >= mapBounds.Min.Y and position.Y <= mapBounds.Max.Y - config.CeilingInset
        end

        local function isRealMapPart(part)
            for _, name in ipairs(realMapRoots) do
                local root = workspace:FindFirstChild(name)

                if root and part:IsDescendantOf(root) then
                    return true
                end
            end

            return false
        end

        -- Anything solid in the box that is not a character
        local function isSolid(cframe, size)
            for _, part in ipairs(workspace:GetPartBoundsInBox(cframe, size, overlapParams)) do
                local model = part:FindFirstAncestorOfClass("Model")

                if not (model and model:FindFirstChildOfClass("Humanoid")) then
                    return true
                end
            end

            return false
        end

        -- The way you are trying to go: your movement direction, otherwise where the camera points (flattened)
        local function getTravelDirection(hrp, humanoid)
            local move = humanoid.MoveDirection
            local flat = Vector3.new(move.X, 0, move.Z)

            if flat.Magnitude > 0.1 then
                return flat.Unit
            end

            local camera = workspace.CurrentCamera

            if camera then
                local look = camera.CFrame.LookVector
                flat = Vector3.new(look.X, 0, look.Z)

                if flat.Magnitude > 0.01 then
                    return flat.Unit
                end
            end

            local look = hrp.CFrame.LookVector

            return Vector3.new(look.X, 0, look.Z).Unit
        end

        -- Highest-first search for walkable floor under a spot: starts MaxRise above your floor, reaches MaxDrop below it
        local function findFloor(spot, floorLevel)
            local startY = floorLevel + config.MaxRise + 0.5
            local result = workspace:Raycast(Vector3.new(spot.X, startY, spot.Z), Vector3.new(0, -(config.MaxRise + config.MaxDrop + 0.5), 0), rayParams)

            if result and result.Normal.Y >= config.MinFloorNormalY then
                return result
            end

            return nil
        end

        -- Skip Gaps: crosses a wall that was found while scanning. `nearDistance` is the scan distance where the probe first hit it.
        -- Returns the distance of its far face, or nil and the reason.
        local function crossGapWall(pointAt, across, nearDistance, maxThickness)
            local step = config.Step
            local startDistance = math.max(nearDistance - config.GapStep, 0.1) -- the near face is somewhere in the last scan step
            local limit = nearDistance + maxThickness + 1 -- slack for the probe width; the real thickness is checked below
            local exitDistance = nil
            local distance = nearDistance

            while distance <= limit do
                if not isSolid(CFrame.new(pointAt(distance)), config.ProbeSize) then
                    exitDistance = distance
                    break
                end

                distance += step
            end

            if not exitDistance then
                return nil, string.format("A wall in the gap is thicker than %.1f studs.", maxThickness)
            end

            -- Exact far face, looking back at it from the clear side
            local clearPoint = exitDistance + 0.3
            local back = workspace:Raycast(pointAt(clearPoint), -across * (clearPoint - startDistance + 0.2), rayParams)
            local farFace = back and (clearPoint - back.Distance) or (exitDistance - 0.25)

            -- Exact near face, looking forward from the clear side before it (falls back to the scan step)
            local nearFace = startDistance
            local forward = workspace:Raycast(pointAt(startDistance), across * (farFace - startDistance + 0.2), rayParams)

            if forward then
                nearFace = startDistance + forward.Distance
            end

            local thickness = math.max(farFace - nearFace, 0)

            if thickness > maxThickness + 1e-3 then
                return nil, string.format("A wall in the gap is about %.1f studs thick (limit %.1f).", thickness, maxThickness)
            end

            return farFace
        end

        -- Skip Gaps: scans across the void behind the first wall. `startDistance` is the far face of the wall you are phasing through.
        -- Lands on the first safe floor; any further wall on the way is crossed (within the thickness limit) and its far side searched.
        -- Returns the landing position, or nil and the reason.
        local function scanAcrossGap(pointAt, across, startDistance, maxThickness, maxScan, origin, floorLevel, standOffset)
            local gapStep = config.GapStep
            local distance = startDistance + gapStep
            local landFrom = startDistance + config.ClearanceHalf -- landing spots must be this far past the last wall's far face
            local wallsCrossed = 0
            local sawFloor, sawMapFloor = false, false

            while distance <= maxScan do
                local spot = pointAt(distance)

                if isSolid(CFrame.new(spot), config.ProbeSize) then
                    if wallsCrossed >= config.GapMaxWalls then
                        return nil, "There are too many walls behind that gap."
                    end

                    local farFace, reason = crossGapWall(pointAt, across, distance, maxThickness)

                    if not farFace then
                        return nil, reason
                    end

                    wallsCrossed += 1
                    landFrom = farFace + config.ClearanceHalf
                    distance = farFace + gapStep
                else
                    if distance >= landFrom then
                        local floorHit = findFloor(spot, floorLevel)

                        if floorHit then
                            sawFloor = true

                            if isRealMapPart(floorHit.Instance) then
                                sawMapFloor = true

                                local landing = Vector3.new(spot.X, floorHit.Position.Y + standOffset, spot.Z)
                                local lip = findFloor(pointAt(distance - config.GapEdgeMargin), floorLevel)
                                local supported = lip ~= nil and math.abs(lip.Position.Y - floorHit.Position.Y) < 1

                                if supported and landing.Y >= origin.Y - config.MaxDrop and landing.Y <= origin.Y + config.MaxRise
                                    and insideMapBox(landing)
                                    and not isSolid(CFrame.new(landing + Vector3.new(0, config.ClearanceLift, 0)), config.ClearanceBox)
                                then
                                    return landing
                                end
                            end
                        end
                    end

                    distance += gapStep
                end
            end

            if sawFloor and not sawMapFloor then
                return nil, "The only floor past that gap is outside the map."
            end

            return nil, "There is no safe ground within " .. tostring(math.floor(maxScan)) .. " studs behind that wall."
        end

        -- Works out where Phase would put you. Returns the landing position and the wall thickness, or nil and the reason.
        local function planPhase(hrp, humanoid, direction, maxThickness)
            local origin = hrp.Position
            local wall = workspace:Raycast(origin, direction * config.Reach, rayParams)

            if not wall then
                return nil, "There is no wall in front of you."
            end

            if math.abs(wall.Normal.Y) > 0.5 then
                return nil, "That is not a wall."
            end

            -- Go straight across the wall (against its face), whatever angle you hit it from
            local across = -Vector3.new(wall.Normal.X, 0, wall.Normal.Z).Unit
            local base = wall.Position

            local function pointAt(distance)
                return base + across * distance -- distance 0 is the face you are touching
            end

            -- Follow the wall until it ends
            local step = config.Step
            local limit = maxThickness + 0.25 + step
            local exitDistance = nil
            local distance = 0.1

            while distance <= limit do
                if not isSolid(CFrame.new(pointAt(distance)), config.ProbeSize) then
                    exitDistance = distance
                    break
                end

                distance += step
            end

            if not exitDistance then
                return nil, string.format("That wall is thicker than %.1f studs.", maxThickness)
            end

            -- Measure the far face exactly: look back at it from a point that is in the clear
            local clearPoint = exitDistance + 0.3
            local back = workspace:Raycast(pointAt(clearPoint), -across * (clearPoint + 0.2), rayParams)
            local thickness = back and (clearPoint - back.Distance) or (exitDistance - 0.25)

            thickness = math.max(thickness, 0)

            if thickness > maxThickness + 1e-3 then
                return nil, string.format("That wall is about %.1f studs thick (limit %.1f).", thickness, maxThickness)
            end

            -- Find a landing spot behind it
            local standOffset = humanoid.HipHeight + hrp.Size.Y / 2
            local floorLevel = origin.Y - standOffset
            local sawFloor, sawMapFloor = false, false

            for extra = 0, config.LandingSearch, step do
                local spot = pointAt(thickness + config.ClearanceHalf + extra)
                local floorHit = findFloor(spot, floorLevel)

                if floorHit then
                    sawFloor = true

                    if isRealMapPart(floorHit.Instance) then
                        sawMapFloor = true

                        local landing = Vector3.new(spot.X, floorHit.Position.Y + standOffset, spot.Z)

                        if landing.Y >= origin.Y - config.MaxDrop and landing.Y <= origin.Y + config.MaxRise
                            and insideMapBox(landing)
                            and not isSolid(CFrame.new(landing + Vector3.new(0, config.ClearanceLift, 0)), config.ClearanceBox)
                        then
                            return landing, thickness
                        end
                    end
                end
            end

            -- Skip Gaps: nothing usable right behind the wall, so keep scanning across the gap (and through any further walls)
            if toggles.phaseSkipGaps_Toggle.Value then
                local gapLanding, gapReason = scanAcrossGap(pointAt, across, thickness, maxThickness, options.phaseGapDistance_Slider.Value, origin, floorLevel, standOffset)

                if gapLanding then
                    return gapLanding, thickness
                end

                return nil, gapReason
            end

            if not sawFloor then
                return nil, "There is no floor behind that wall."
            elseif not sawMapFloor then
                return nil, "The floor behind that wall is outside the map."
            end

            return nil, "There is no safe spot behind that wall."
        end

        performPhase = function()
            if not toggles.enablePhase_Toggle.Value or uis:GetFocusedTextBox() or not isAlive() then
                return
            end

            local now = os.clock()

            if now - lastPhase < config.Cooldown then
                return
            end

            lastPhase = now

            local hrp = getHRP()
            local humanoid = getHumanoid()

            if not hrp or not humanoid then
                return
            end

            local success, landing, info = pcall(function()
                refreshFilters(hrp.Parent)

                return planPhase(hrp, humanoid, getTravelDirection(hrp, humanoid), options.phaseWallThickness_Slider.Value)
            end)

            if not success then
                warn("[Phase] " .. tostring(landing))
                return
            end

            if not landing then
                notifyPhase(info)
                return
            end

            entityLib.teleport(CFrame.new(landing) * hrp.CFrame.Rotation)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end

    buildPhase()
end

-- [Player / Other] Backtrack and out-of-bounds guard

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

    guardDepbox:AddSlider("outOfBoundsGuardMargin_Slider", { Text = "Map Edge Margin", Tooltip = "How far from the real map (rooms, walls, fences, buildings) you can get before you are moved back. The map is much smaller than the game's own MapLimit box, so this is what keeps you from flying through walls and around outside it. Lower is tighter, but below 24 it can misfire in the largest halls. The open surface allows 4x this value.", Default = 24, Min = 16, Max = 96, Suffix = " Studs",
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
        Heartbeat = nil :: RBXScriptConnection?,
        CharacterAdded = nil :: RBXScriptConnection?,
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

    -- Runs from unloadModules() after every toggle has been disabled.
    table.insert(teardownTasks, stopGuard)
end

-- [Player / Freecam] Controls and camera lifecycle

othersGroup3:AddToggle("freecam_Toggle", { Text = "Freecam" })
:AddKeyPicker("freecam_KeyPicker", { Text = "Freecam", Default = "H", SyncToggleState = true, Mode = "Toggle" })

local freecamDepbox = othersGroup3:AddDependencyBox()

local freecamSpeedSlider = freecamDepbox:AddSlider("freecamSpeedSlider", { Text = "Speed", Tooltip = "The speed you move at in freecam.",  Default = 64, Min = 10, Max = 2000 })
local freecamPanSpeedSlider = freecamDepbox:AddSlider("freecamPanSpeedSlider", { Text = "Pan Speed", Tooltip = "How fast your camera moves when moving your mouse around in freecam.",  Default = 8, Min = 2, Max = 30 })
freecamDepbox:AddDivider()

freecamDepbox:SetupDependencies({ { toggles.freecam_Toggle, true } })

-- [Player / Fake Lag] Chokes the client's outgoing network traffic in bursts so other players see you freeze, then jump ahead

othersGroup3:AddToggle("fakeLag_Toggle", { Text = "Fake Lag", Tooltip = "Throttles what your client sends to the server in bursts, so other players see you freeze and then jump ahead while you keep moving normally on your screen. Anything else your client sends is delayed too, so shots and interactions land when each burst ends. Very long lag times can get you rubberbanded or kicked by the server." })
:AddKeyPicker("fakeLag_KeyPicker", { Text = "Fake Lag", Default = "Z", SyncToggleState = true, Mode = "Hold" })

do
    local fakeLagDepbox = othersGroup3:AddDependencyBox()

    fakeLagDepbox:AddSlider("fakeLagDuration_Slider", { Text = "Lag Time", Tooltip = "How long each burst holds your movement back before it is released to the server. Keep it short: long bursts are easier for the server to flag.", Default = 0.4, Min = 0.1, Max = 1.5, Rounding = 2, Suffix = " Seconds",
        Callback = function(val)
            options.fakeLagDuration_Slider:SetSuffix(getSuffix(options.fakeLagDuration_Slider, "Second"))
        end
    })

    fakeLagDepbox:AddSlider("fakeLagRelease_Slider", { Text = "Release Time", Tooltip = "How long your traffic flows normally between two bursts, so the server receives your real position and keeps you in sync.", Default = 0.1, Min = 0.05, Max = 0.5, Rounding = 2, Suffix = " Seconds",
        Callback = function(val)
            options.fakeLagRelease_Slider:SetSuffix(getSuffix(options.fakeLagRelease_Slider, "Second"))
        end
    })

    fakeLagDepbox:AddDivider()

    fakeLagDepbox:SetupDependencies({ { toggles.fakeLag_Toggle, true } })

    local networkClient = game:GetService("NetworkClient")

    -- The client has no getter for its outgoing limit, so "released" is a limit far above anything the game can send.
    local CHOKE_KBPS = 1
    local RELEASED_KBPS = 1000000

    local fakeLag = { token = 0, choking = false }

    -- Only records the new state when the call went through, so a failed release is retried instead of forgotten.
    local function setChoke(choking)
        if fakeLag.choking == choking then
            return
        end

        local success = pcall(function()
            networkClient:SetOutgoingKBPSLimit(choking and CHOKE_KBPS or RELEASED_KBPS)
        end)

        if success then
            fakeLag.choking = choking
        end
    end

    local function stopFakeLag()
        fakeLag.token += 1
        setChoke(false)
    end

    local function startFakeLag()
        fakeLag.token += 1
        local token = fakeLag.token

        task.spawn(function()
            while fakeLag.token == token and not library.Unloaded do
                -- A dead or respawning character is never choked, so the respawn request is not held back.
                if isAlive() then
                    setChoke(true)
                    task.wait(options.fakeLagDuration_Slider.Value)
                else
                    setChoke(false)
                    task.wait(0.1)
                end

                if fakeLag.token ~= token or library.Unloaded then
                    break
                end

                setChoke(false)
                task.wait(options.fakeLagRelease_Slider.Value)
            end

            if fakeLag.token == token then
                setChoke(false)
            end
        end)
    end

    toggles.fakeLag_Toggle:OnChanged(function(enabled)
        if enabled then
            startFakeLag()
        else
            stopFakeLag()
        end
    end)

    table.insert(teardownTasks, stopFakeLag)
end

-- [Player / Backtrack] Store death location and restore it on respawn
do
    local backtrackCFrame: CFrame? = nil
    local backtrackUnloaded = false

    local function watchBacktrackDeath(char: Model)
        task.spawn(function()
            local humanoid = char:WaitForChild("Humanoid", 10)
            if not humanoid or backtrackUnloaded then return end

            humanoid.Died:Connect(function()
                if backtrackUnloaded then return end

                if toggles.autoBacktrack_Toggle.Value then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp:IsA("BasePart") then
                        backtrackCFrame = hrp.CFrame
                        entityLib.storeData(hrp, "CFrame", true)
                    end
                end

                toggles.autoBacktrack_Toggle:SetDisabled(true)
            end)
        end)
    end

    if localplayer.Character then
        watchBacktrackDeath(localplayer.Character)
    end

    local backtrackCharacterAdded = localplayer.CharacterAdded:Connect(function(char)
        watchBacktrackDeath(char)

        -- Unlock the toggle first so a failed or slow teleport can never leave it stuck disabled.
        toggles.autoBacktrack_Toggle:SetDisabled(false)

        local savedCFrame = backtrackCFrame
        backtrackCFrame = nil

        if savedCFrame then
            local hrp = char:WaitForChild("HumanoidRootPart", 10)
            if hrp and not backtrackUnloaded then
                entityLib.teleport(savedCFrame)
            end
        end
    end)

    table.insert(teardownTasks, function()
        backtrackUnloaded = true
        backtrackCharacterAdded:Disconnect()
    end)
end

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

local exploitsGroup = tabs.exploits:AddGroupbox({ Side = "Left", Name = "Exploits", IconName = assetLib.fetchAsset("Icons/zap.png"), Description = "Aim and auto collect" })
local killersGroup = tabs.exploits:AddGroupbox({ Side = "Right", Name = "Killers", IconName = assetLib.fetchAsset("Icons/skull.png"), Description = "Killer control options" })

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

exploitsGroup:AddToggle("enableAimbot_Toggle", { Text = "Enable Aimbot" })

-- [Exploits / Aimbot] Targeting controls
local aimbotDepbox = exploitsGroup:AddDependencyBox()
aimbotDepbox:AddDropdown("aimbotHitPart_Dropdown", { Text = "Hit Part", Values = { "Head", "HumanoidRootPart" }, Default = 1 })
aimbotDepbox:AddDropdown("aimbotTargetType_Dropdown", { Text = "Target Type", Values = { "Closest", "Closest to Cursor" }, Default = 2 })
aimbotDepbox:AddDropdown("aimbotExcludedKillers_Dropdown", { Text = "Excluded Killers", Values = killerNames, Default = { "Giant", "Jane" }, Multi = true, Searchable = true })
aimbotDepbox:AddSlider("aimbotMaximumDistance_Slider", { Text = "Range", Tooltip = "Killers farther than this distance will not be targeted.", Default = 100, Min = 10, Max = 2000, Suffix = " Studs", Rounding = 1 })
aimbotDepbox:AddSlider("aimbotSmoothing_Slider", { Text = "Smoothing", Tooltip = "How smooth aimbot should lock onto Killer's.", Default = 400, Min = 10, Max = 1000 })
aimbotDepbox:AddToggle("aimbotVisibilityCheck_Toggle", { Text = "Visibility Check", Tooltip = "Whether to only target Killers that are visible.", Default = true })
aimbotDepbox:AddDivider()

exploitsGroup:AddToggle("enableSilentAim_Toggle", { Text = "Enable Silent Aim" })

local silentAimDepbox = exploitsGroup:AddDependencyBox()
silentAimDepbox:AddSlider("FOV_Slider", { Text = "FOV", Tooltip = "The screen-space radius in which targets can be selected.", Default = 150, Min = 0, Max = 1000, Suffix = " px" })
silentAimDepbox:AddToggle("silentAimWallCheck_Toggle", { Text = "Wall Check", Tooltip = "Only target Killers that are visible. Wallbang takes priority when enabled.", Default = true })
silentAimDepbox:AddToggle("silentAimWallBang_Toggle", { Text = "Wallbang", Tooltip = "Bullets fired at a locked Killer fly through walls and other obstructions. Shots with no Killer inside the FOV behave normally.", Default = true })
silentAimDepbox:AddToggle("silentAimNoSpread_Toggle", { Text = "No Spread", Tooltip = "Removes weapon inaccuracy and shotgun pellet spread while a Killer is locked, so every bullet follows the aimed line.", Default = true })
silentAimDepbox:AddDropdown("silentAimHitPart_Dropdown", { Text = "Hit Part", Tooltip = "Auto aims at the Head while a Killer is close and standing still, and at the larger HumanoidRootPart when it is moving or far away.", Values = { "Auto", "Head", "HumanoidRootPart" }, Default = 1 })
silentAimDepbox:AddToggle("silentAimPrediction_Toggle", { Text = "Prediction", Tooltip = "Lead moving Killers based on their velocity and projectile travel time.", Default = true })
silentAimDepbox:AddSlider("silentAimProjectileSpeed_Slider", { Text = "Projectile Speed", Tooltip = "Used to estimate projectile travel time for prediction.", Default = 150, Min = 25, Max = 1000, Suffix = " studs/s" })
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
    local silentAimBlacklistedNames = { Jane = true, Giant = true }

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

        -- While Silent Aim is off the scan stays owed and runs the moment it is enabled.
        if library.Unloaded or not silentAimScanOwed or not isSilentAimEnabled() then
            return
        end

        silentAimScanOwed = false
        scanSilentAimWeaponTables()
    end)
end

local function watchSilentAimContainer(container: Instance?)
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
disableKillersDepbox:AddDropdown("disableAuraMethod_Dropdown", { Text = "Method", Values = { "Kill", "Disable Movement", "Disable Humanoid", "Push" }, Default = 4 })
disableKillersDepbox:AddSlider("disableKillersDistance_Slider", { Text = "Range", Tooltip = "How far away to disable killers", Default = 20, Min = 10, Max = 100, Suffix = " Studs" })
disableKillersDepbox:AddToggle("disableAuraWallCheck_Toggle", { Text = "Wall Check", Tooltip = "Only affects Killers that are visible. Killers behind walls are left alone. Emergency Kill ignores this." })
disableKillersDepbox:AddLabel("Emergency Kill"):AddKeyPicker("emergencyKill_KeyPicker", { Text = "Emergency Kill", Default = "X", Mode = "Hold", NoUI = true, Disabled = true })
disableKillersDepbox:AddToggle("disableAuraDebugNotifs_Toggle", { Text = "Debug Notifications", Tooltip = "Sends a notification each time Disable Aura kills, disables or starts pushing a killer, and while it waits for control of a killer." })
disableKillersDepbox:AddDivider()

-- [Exploits / Killer Controls] Defensive toggles

killersGroup:AddToggle("killerGodmode_Toggle", { Text = "Killer Godmode", Tooltip = "Makes you invincible to the killers by blocking killer interactions." })

local killerGodmodeDepbox = killersGroup:AddDependencyBox()
killerGodmodeDepbox:AddToggle("antiPinhead_Toggle", { Text = "Anti Pinhead", Default = true, Tooltip = "Disables (mostly) Pinhead's spikes that he expels upon death." })
killerGodmodeDepbox:AddToggle("acidDodge_Toggle", { Text = "Acid Dodge", Default = true, Tooltip = "EXPERIMENTAL. Attempts to dodge the acid Alien spits at you by stepping out of the way before it lands. This isn't guaranteed to work due to the speed of the acid." })

local acidDodgeDepbox = killerGodmodeDepbox:AddDependencyBox()
acidDodgeDepbox:AddSlider("acidDodgeRange_Slider", { Text = "Alien Range", Tooltip = "Acid Dodge only reacts while an Alien is within this many studs of you.", Default = 9, Min = 5, Max = 20, Suffix = " Studs" })
acidDodgeDepbox:AddSlider("acidDodgeDistance_Slider", { Text = "Dodge Distance", Tooltip = "How far a dodge moves you. It is shortened automatically when a wall is closer, and a direction without enough room or floor is skipped.", Default = 7, Min = 4, Max = 12, Suffix = " Studs" })
acidDodgeDepbox:AddToggle("acidDodgeDebugNotifs_Toggle", { Text = "Debug Notifications", Tooltip = "Sends a notification each time Acid Dodge moves you, and when there is no safe room to dodge." })
acidDodgeDepbox:AddDivider()

killerGodmodeDepbox:AddLabel("Covers what your client reports or detects itself: touch hitboxes, Freddy's nightmare (snakes, bugs and the hole), Chucky's jump attack and Pinhead's spikes. Attacks the server checks on its own, like Alien's arm and Yeti's ice slam, can not be blocked from the client. Use Disable Aura against those.", true)
killerGodmodeDepbox:AddDivider()

killersGroup:AddToggle("antiSlendermanJumpscare_Toggle", { Text = "Anti Slenderman Jumpscare" })

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
    safeFacingDepbox:AddSlider("slendermanSafeFacingDistance_Slider", { Text = "Minimum Distance", Tooltip = "Safe Facing only takes over your facing while Slenderman is closer to you than this. He starts targeting players from 200 studs away, so the maximum covers everything he can do. Lower it to keep control of your character until he gets close.", Default = 200, Min = 50, Max = 200, Suffix = " Studs" })
    safeFacingDepbox:AddDivider()
    safeFacingDepbox:SetupDependencies({ { toggles.slendermanSafeFacing_Toggle, true } })

    -- The margin covers him closing in between two checks, it is added on top of the slider
    local distanceMargin = 50

    local facing = {
        connection = nil,
        humanoid = nil,     -- the humanoid whose AutoRotate was disabled by this feature
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
acidDodgeDepbox:SetupDependencies({ { toggles.acidDodge_Toggle, true } })
disableKillersDepbox:SetupDependencies({ { toggles.disableAllKillers_Toggle, true } })

-- [Exploits / Killer Controls] Auto Safe Spot
do
    killersGroup:AddToggle("autoSafeSpot_Toggle", { Text = "Auto Safe Spot", Tooltip = "Teleports you to the nearest safe spot when your health is low and a killer is close, then returns you once your original position is safe again." })

    local autoSafeSpotDepbox = killersGroup:AddDependencyBox()
    autoSafeSpotDepbox:AddSlider("autoSafeSpotHealth_Slider", { Text = "Health Threshold", Tooltip = "You are teleported to a safe spot once your health is at or below this while a killer is within the safe radius.", Default = 60, Min = 30, Max = 100, Suffix = " HP" })
    autoSafeSpotDepbox:AddSlider("autoSafeSpotRadius_Slider", { Text = "Safe Radius", Tooltip = "A killer has to be at least this far away for a safe spot (or your original position) to count as safe.", Default = 50, Min = 20, Max = 200, Suffix = " Studs" })
    autoSafeSpotDepbox:AddToggle("autoSafeSpotSpectate_Toggle", { Text = "Spectate Killer", Tooltip = "While hiding, spectates the killer you are avoiding so you can see what it is doing." })
    autoSafeSpotDepbox:AddToggle("autoSafeSpotSlenderman_Toggle", { Text = "Flee Slenderman", Tooltip = "Hides as soon as Slenderman is chasing you and within the minimum distance, no matter your health. He can teleport behind you from up to 200 studs away, so waiting for low health is too late." })
    autoSafeSpotDepbox:AddDivider()

    local slendermanDepbox = autoSafeSpotDepbox:AddDependencyBox()
    slendermanDepbox:AddSlider("autoSafeSpotSlendermanDistance_Slider", { Text = "Minimum Distance", Tooltip = "Slenderman has to be at least this far from you for you to be safe: you flee once he is chasing you from closer than this, and only return once he is this far from your original position.", Default = 50, Min = 50, Max = 200, Suffix = " Studs" })
    
    autoSafeSpotDepbox:SetupDependencies({ { toggles.autoSafeSpot_Toggle, true } })
    slendermanDepbox:SetupDependencies({ { toggles.autoSafeSpotSlenderman_Toggle, true } })

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

-- [Exploits / Killer Controls] Disable Aura: network control
do
    local function ownsKiller(root)
        if type(isnetworkowner) ~= "function" then
            return true
        end

        local ok, owned = pcall(isnetworkowner, root)

        return ok and owned == true
    end

    local function newTracker(source)
        -- model -> { startedAt = number, note = notification? }
        local waits = {}
        local tracker = {}

        -- Ends the wait for a killer and dismisses its notification. If there is a wait, return it.
        local function drop(model)
            local wait = waits[model]

            if wait then
                waits[model] = nil
                utils.dismissNotify(wait.note)
            end

            return wait
        end

        -- True while the killer can be affected. When it's not, the wait starts (and is announced, persistently) once.
        -- When control begins, the waiting notification is dismissed and how long it took is announced.
        function tracker.check(model, root)
            if ownsKiller(root) then
                local wait = drop(model)

                if wait and toggles.disableAuraDebugNotifs_Toggle.Value then
                    notify("Info", source, string.format("Took control of %s after %.1f s", model.Name, os.clock() - wait.startedAt), 3)
                end

                return true
            end

            local wait = waits[model]

            if not wait then
                wait = { startedAt = os.clock() }
                waits[model] = wait
            end

            -- Also covers Debug Notifications being enabled in the middle of a wait. A notification closed manually stays closed.
            if not wait.note and toggles.disableAuraDebugNotifs_Toggle.Value then
                wait.note = notify("Info", source, "Waiting for control of " .. model.Name, 3, true)
            end

            return false
        end

        -- The killer no longer needs to be affected (out of range, behind a wall, dead or gone), so its wait ends and its notification is dismissed
        function tracker.clear(model)
            drop(model)
        end

        -- Ends the waits of killers that are no longer in the Killers folder, have no humanoid or are dead, because the loops never reach those
        function tracker.prune()
            if not next(waits) then
                return
            end

            for model in pairs(waits) do
                local hum = model:IsDescendantOf(killersFolder) and model:FindFirstChildOfClass("Humanoid")

                if not hum or hum.Health <= 0 then
                    drop(model)
                end
            end
        end

        -- Dismisses the notifications but keeps the waits (Debug Notifications disabled)
        function tracker.dismissNotes()
            for _, wait in pairs(waits) do
                utils.dismissNotify(wait.note)
                wait.note = nil
            end
        end

        function tracker.reset()
            for model in pairs(waits) do
                drop(model)
            end
        end

        return tracker
    end

    utils.auraControl = newTracker("Disable Aura")
    utils.emergencyControl = newTracker("Emergency Kill")

    -- Disabled Debug Notifications dismisses the persistent "Waiting for control" and "Pushing" notifications that are still up.
    -- A toggle only has one OnChanged callback, so Push (defined further down) registers its part through utils.pushDismissNotes.
    toggles.disableAuraDebugNotifs_Toggle:OnChanged(function(enabled)
        if not enabled then
            utils.auraControl.dismissNotes()
            utils.emergencyControl.dismissNotes()

            if utils.pushDismissNotes then
                utils.pushDismissNotes()
            end
        end
    end)

    table.insert(teardownTasks, function()
        utils.auraControl.reset()
        utils.emergencyControl.reset()
    end)
end

-- [Exploits / Killer Controls] Disable Aura: killers it never touches
utils.auraIgnoredKillers = {
    ["Giant"] = true,
    ["Jane"] = true,
}

local function updateKiller(hum, model, root, method, inRange, visible)
    if hum.Health <= 0 then
        if affectedKillers[hum] then
            releaseKiller(hum)
        end

        utils.auraControl.clear(model)

        return
    end

    -- Restore if leaving range
    if not inRange then
        if affectedKillers[hum] == "Disable Movement" then
            releaseKiller(hum)
            if toggles.disableAuraDebugNotifs_Toggle.Value then
                notify("Info", "Successful restore", "Restored " .. model.Name .. "'s movement.", 3)
            end
        end

        utils.auraControl.clear(model)

        return
    end

    -- Already applied. Disable Movement is held every frame, because the game can raise WalkSpeed or JumpPower again.
    if affectedKillers[hum] == method then
        if method == "Disable Movement" and utils.auraControl.check(model, root) then
            if hum.WalkSpeed ~= 0 then
                hum.WalkSpeed = 0
            end

            if hum.JumpPower ~= 0 then
                hum.JumpPower = 0
            end
        end

        return
    end

    -- Wall Check: killers behind walls are left alone
    if visible == false then
        utils.auraControl.clear(model)
        return
    end

    -- Restore previous movement if switching methods
    if affectedKillers[hum] == "Disable Movement" then
        releaseKiller(hum)
    end

    -- Wait until you own the killer, then act on the frame control begins
    if not utils.auraControl.check(model, root) then
        return
    end

    -- Apply new method
    if method == "Kill" then
        -- The real hit parts come back first, so the ragdoll never starts from an enlarged hitbox (see Hitbox Expander)
        if utils.releaseKillerHitbox then
            pcall(utils.releaseKillerHitbox, model)
        end

        hum.Health = 0

        -- Session Info counts this as a Synthetic Kill (see the Kills line in Session Info)
        if utils.sessionInfoSyntheticKill then
            pcall(utils.sessionInfoSyntheticKill, model)
        end

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

    -- Session Info counts this killer as affected (see the Affected Killers line in Session Info)
    if utils.sessionInfoAffectedKiller then
        pcall(utils.sessionInfoAffectedKiller, model)
    end

    affectedKillers[hum] = method
end

-- Set by the Push block further down
local pushToggled

-- [Exploits / Killer Controls] Disable Aura: Emergency Kill (Hold)
-- While the key is held, every killer inside the Range is killed using whatever Method is selected. A killer is only killed while you own it.
do
    local connection = nil
    local lastError = nil

    local function stopLoop()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end

    local function step()
        local keypicker = options.emergencyKill_KeyPicker

        -- Hold mode: GetState() is only true while the key is physically down. Typing in chat must not trigger it.
        if not keypicker or keypicker.Disabled or uis:GetFocusedTextBox() or not keypicker:GetState() then
            utils.emergencyControl.reset() -- Nothing is pending when the key is let go
            return
        end

        local hrp = getHRP()
        if not hrp then
            utils.emergencyControl.reset()
            return
        end

        utils.emergencyControl.prune()

        local range = proximityRange or 30

        for _, model in ipairs(killersFolder:GetChildren()) do
            if not model:IsA("Model") then
                continue
            end

            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")

            if hum and root and hum.Health > 0 and entityLib.getEntityDistance(hrp, root) <= range then
                -- Wait until you own the killer, then kill it on the frame control begins
                if utils.emergencyControl.check(model, root) then
                    -- The real hit parts come back first, so the ragdoll never starts from an enlarged hitbox (see Hitbox Expander)
                    if utils.releaseKillerHitbox then
                        pcall(utils.releaseKillerHitbox, model)
                    end

                    hum.Health = 0

                    -- Session Info counts this as a Synthetic Kill (see the Kills line in Session Info)
                    if utils.sessionInfoSyntheticKill then
                        pcall(utils.sessionInfoSyntheticKill, model)
                    end

                    if utils.sessionInfoAffectedKiller then
                        pcall(utils.sessionInfoAffectedKiller, model)
                    end

                    if toggles.disableAuraDebugNotifs_Toggle.Value then
                        notify("Info", "Emergency Kill", "Killed " .. model.Name, 3)
                    end
                end
            else
                utils.emergencyControl.clear(model)
            end
        end
    end

    utils.emergencyKillToggled = function(enabled)
        local keypicker = options.emergencyKill_KeyPicker

        if keypicker then
            pcall(keypicker.SetDisabled, keypicker, not enabled)
            pcall(keypicker.SetNoUI, keypicker, not enabled)
        end

        stopLoop()
        utils.emergencyControl.reset()

        if enabled then
            -- Every frame
            connection = runService.Heartbeat:Connect(function()
                if library.Unloaded or not toggles.disableAllKillers_Toggle.Value then
                    stopLoop()
                    return
                end

                local ok, err = pcall(step)

                if not ok and err ~= lastError then
                    lastError = err
                    warn("[Disable Aura: Emergency Kill] " .. tostring(err))
                end
            end)
        end
    end
end

-- [Exploits / Killer Controls] Disable Aura: main loop
do
    local connection = nil
    local lastError = nil

    local function stopLoop()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end

    local function step()
        local hrp = getHRP()

        -- Without a character, nothing can be done to a killer, so no wait is pending either
        if not hrp then
            utils.auraControl.reset()
            return
        end

        utils.auraControl.prune()

        local method = tostring(options.disableAuraMethod_Dropdown.Value)
        local range = proximityRange or 30

        -- Push runs in its own loop (see Disable Aura: Push). Nothing is applied from here, and whatever another method applied is given back.
        if method == "Push" then
            for trackedHum in pairs(affectedKillers) do
                releaseKiller(trackedHum)
            end

            return
        end

        -- Forget killers that are gone (removed corpses, destroyed humanoids)
        for trackedHum in pairs(affectedKillers) do
            if not trackedHum:IsDescendantOf(killersFolder) then
                releaseKiller(trackedHum)
            end
        end

        local wallCheck = toggles.disableAuraWallCheck_Toggle.Value

        for _, model in ipairs(killersFolder:GetChildren()) do
            if not model:IsA("Model") then
                continue
            end
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if hum and root and not utils.auraIgnoredKillers[model.Name] then
                local distance = entityLib.getEntityDistance(hrp, root)
                local inRange = distance <= range
                local visible = true

                if inRange and affectedKillers[hum] ~= method and wallCheck then
                    visible = utils.isKillerVisible(hrp.Position, model, root)
                end

                updateKiller(hum, model, root, method, inRange, visible)
            end
        end
    end

    toggles.disableAllKillers_Toggle:OnChanged(function(enabled)
        utils.emergencyKillToggled(enabled)

        if pushToggled then
            pushToggled(enabled)
        end

        stopLoop()
        utils.auraControl.reset()

        if enabled then
            connection = runService.Heartbeat:Connect(function()
                if library.Unloaded or not toggles.disableAllKillers_Toggle.Value then
                    stopLoop()
                    return
                end

                local ok, err = pcall(step)

                if not ok and err ~= lastError then
                    lastError = err
                    warn("[Disable Aura] " .. tostring(err))
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
end

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
    local function getShape(model, root, hum)
        local shape = shapes[model]

        if shape then
            return shape
        end

        local rootCFrame = root.CFrame
        local minX, maxX, minY, maxY, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge, math.huge, -math.huge

        -- Grows the measured area (in the root part's own space, so the way the killer faces does not matter) to hold a part
        local function include(part)
            local relative = rootCFrame:ToObjectSpace(part.CFrame)
            local r00, r01, r02, r10, r11, r12, r20, r21, r22 = select(4, relative:GetComponents())
            local half = part.Size / 2
            local extentX = math.abs(r00) * half.X + math.abs(r01) * half.Y + math.abs(r02) * half.Z
            local extentY = math.abs(r10) * half.X + math.abs(r11) * half.Y + math.abs(r12) * half.Z
            local extentZ = math.abs(r20) * half.X + math.abs(r21) * half.Y + math.abs(r22) * half.Z

            minX, maxX = math.min(minX, relative.X - extentX), math.max(maxX, relative.X + extentX)
            minY, maxY = math.min(minY, relative.Y - extentY), math.max(maxY, relative.Y + extentY)
            minZ, maxZ = math.min(minZ, relative.Z - extentZ), math.max(maxZ, relative.Z + extentZ)
        end

        include(root)

        for _, part in ipairs(model:GetDescendants()) do
            if part ~= root and part:IsA("BasePart") and part.CanCollide and part.Size.Magnitude < 30 then
                include(part)
            end
        end

        -- R15 rigs stand on their hip height, and their legs do not collide, so the feet come from the humanoid
        local feet = math.min(minY, -(root.Size.Y / 2 + hum.HipHeight))

        shape = {
            bottom = math.clamp(-feet, 1.5, 12),
            top = math.clamp(maxY, 1, 10),
            width = math.clamp(math.min(maxX - minX, maxZ - minZ) * 1.2, 1.6, 6),
        }
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

    -- model -> { speed, last, active, notifiedAt, note }
    local pushStates = {}
    local pushConnection = nil
    local pushLastError = nil

    -- The push on a killer is over: its notification is dismissed
    local function endPush(state)
        state.active = false
        utils.dismissNotify(state.note)
        state.note = nil
    end

    local function dropPushState(model)
        local state = pushStates[model]

        if state then
            pushStates[model] = nil
            endPush(state)
        end
    end

    local function clearPushStates()
        for model in pairs(pushStates) do
            dropPushState(model)
        end
    end

    -- Debug Notifications disabled: the notifications dismissed, the pushes continue
    utils.pushDismissNotes = function()
        for _, state in pairs(pushStates) do
            utils.dismissNotify(state.note)
            state.note = nil
        end
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

        clearPushStates()
    end

    table.insert(teardownTasks, stopPush)

    local function pushStep(deltaTime)
        if library.Unloaded or not toggles.disableAllKillers_Toggle.Value then
            stopPush()
            return
        end

        if tostring(options.disableAuraMethod_Dropdown.Value) ~= "Push" then
            if next(pushStates) then
                clearPushStates()
                utils.auraControl.reset()
            end

            return
        end

        local hrp = getHRP()

        -- Without a character, nothing is being pushed, so no push is announced either
        if not hrp then
            for _, state in pairs(pushStates) do
                endPush(state)
            end

            utils.auraControl.reset()
            return
        end

        utils.auraControl.prune()

        -- Killers that left the Killers folder are never reached by the loop
        for model in pairs(pushStates) do
            if not model:IsDescendantOf(killersFolder) then
                dropPushState(model)
            end
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

            -- Ignored killers, dead killers (and ones whose humanoid is gone) are skipped
            if utils.auraIgnoredKillers[model.Name] or not (root and root:IsA("BasePart")) or hum.Health <= 0 then
                dropPushState(model)
                utils.auraControl.clear(model)
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

            if speed < 1 then
                state.speed = 0
                state.last = position
                endPush(state)
                utils.auraControl.clear(model)
                continue
            end

            -- Wait until you own the killer, then push it on the frame control begins
            if not utils.auraControl.check(model, root) then
                state.speed = 0
                state.last = position
                endPush(state)
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

            local move = resolveMove(position, getShape(model, root, hum), away.Unit, math.min(speed * dt, PUSH_MAX_STEP))

            local moved = move.Magnitude > 0.005

            if moved then
                root.CFrame += move
                position += move
            end

            state.last = position

            -- Session Info counts a killer that was really pushed
            if moved and inRange and utils.sessionInfoAffectedKiller then
                utils.sessionInfoAffectedKiller(model)
            end

            -- Only announced once the killer was really moved, so the notification always claims a real push
            if moved and inRange and not state.active and now - state.notifiedAt > 3 then
                state.active = true
                state.notifiedAt = now
            end

            -- Notification is displayed for as long as the push lasts (see endPush for every way it ends), also while the killer leaves the range.
            if state.active and not state.note and toggles.disableAuraDebugNotifs_Toggle.Value then
                state.note = notify("Info", "Disable Aura", "Pushing " .. model.Name, 3, true)
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
local pinheadConnection

local function syncAntiPinhead()
    local shouldRun = toggles.antiPinhead_Toggle.Value and toggles.killerGodmode_Toggle.Value and not library.Unloaded

    if shouldRun and not pinheadConnection then
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
    elseif not shouldRun and pinheadConnection then
        pinheadConnection:Disconnect()
        pinheadConnection = nil
    end
end

-- [Exploits / Killer Controls] Acid Dodge
local syncAcidDodge

do
    local ACID_SOUND_ID = "141649183"   -- every acid part carries this sound
    local MIN_SPEED = 5                 -- studs/s: slower parts are treated as puddles lying still
    local STEP_TIME = 0.025             -- seconds between two predicted points of an arc
    local MAX_FLIGHT_TIME = 1.2         -- an arc that has not landed by then is cut off
    local PATH_RADIUS = 2.4             -- how close a part may pass the character in flight before it counts as a hit
    local PATH_HEIGHT = 3.6             -- vertical reach of the character around its root part
    local LANDING_RADIUS = 3.6          -- clearance kept from where a part lands (covers the prediction error and the puddle)
    local LANDING_HEIGHT = 6            -- landing spots are on the floor, so they get a taller vertical window
    local PUDDLE_RADIUS = 1.8           -- contact radius of a part lying still
    local PUDDLE_MARGIN = 0.9           -- extra room asked of a dodge destination around puddles
    local BODY_CLEARANCE = 1.8          -- wall distance needed beside the character when stepping
    local MIN_STEP = 3.5                -- a dodge shorter than this would not clear the landing spots
    local COOLDOWN = 0.12               -- seconds between two dodges
    local FLOOR_TOLERANCE = 1.5         -- the floor under the destination may differ this much from the floor under you
    local FLOOR_REACH = 12
    local ACID_MAX_SIZE = 2             -- every acid part is a small disc or ball, no side is longer than this
    local SPAWN_RADIUS = 20             -- a new spit starts at the Alien's mouth, so its parts are this close to the Alien's root
    local REGISTER_WINDOW = 1.5         -- seconds a new Model keeps being checked in case its parts arrive late

    local acidModels = {}               -- [Model] = true
    local hazards = {}                  -- [BasePart] = { points = { Vector3 }, landed = bool, resting = bool }
    local connections: { RBXScriptConnection } = {}
    local active = false
    local lastDodge = -math.huge
    local lastWarn = -math.huge
    local lastNoRoomNotify = -math.huge

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true

    -- Walls are everything except characters, killers and the acid itself.
    local function refreshFilter(character)
        local ignored = { character }

        for _, name in ipairs({ "Killers", "Characters to kill" }) do
            local folder = workspace:FindFirstChild(name)

            if folder then
                table.insert(ignored, folder)
            end
        end

        for _, player in ipairs(players:GetPlayers()) do
            if player.Character then
                table.insert(ignored, player.Character)
            end
        end

        for model in pairs(acidModels) do
            table.insert(ignored, model)
        end

        rayParams.FilterDescendantsInstances = ignored
    end

    local function isAcidPart(part)
        if not part:IsA("Part") then
            return false
        end

        if part.Shape ~= Enum.PartType.Cylinder and part.Shape ~= Enum.PartType.Ball then
            return false
        end

        local size = part.Size

        return math.max(size.X, size.Y, size.Z) <= ACID_MAX_SIZE
    end

    local function isNearAlien(position)
        local folder = workspace:FindFirstChild("Killers")

        if not folder then
            return false
        end

        for _, model in ipairs(folder:GetChildren()) do
            if model.Name == "Alien" then
                local root = model:FindFirstChild("HumanoidRootPart")

                if root and (root.Position - position).Magnitude <= SPAWN_RADIUS then
                    return true
                end
            end
        end

        return false
    end

    -- A spit that is still in the air has no Sound yet, so a Model that just appeared counts when it holds small discs next to
    -- an Alien. Models that were already lying around (the puddles) are recognised by their Sound
    local function isAcidModel(model, justAdded)
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("Sound") and string.find(descendant.SoundId, ACID_SOUND_ID, 1, true) then
                return true
            end

            if justAdded and isAcidPart(descendant) and isNearAlien(descendant.Position) then
                return true
            end
        end

        return false
    end

    -- Returns true when the Model was taken in right now. A new Model that does not qualify yet keeps being watched for a moment
    local function considerModel(model, justAdded)
        if not model:IsA("Model") or model.Name ~= "Model" or acidModels[model] then
            return false
        end

        if isAcidModel(model, justAdded) then
            acidModels[model] = true

            return true
        end

        if justAdded then
            task.spawn(function()
                local deadline = os.clock() + REGISTER_WINDOW

                while os.clock() < deadline and model.Parent == workspace and active do
                    task.wait()

                    if isAcidModel(model, true) then
                        acidModels[model] = true

                        return
                    end
                end
            end)
        end

        return false
    end

    -- Follows the arc of a part from its launch velocity until it reaches something solid
    local function simulateArc(position, velocity)
        local gravity = Vector3.new(0, -workspace.Gravity, 0)
        local points = { position }
        local time = 0

        while time < MAX_FLIGHT_TIME do
            time += STEP_TIME

            local nextPosition = position + velocity * time + gravity * (0.5 * time * time)
            local previous = points[#points]
            local hit = workspace:Raycast(previous, nextPosition - previous, rayParams)

            if hit then
                table.insert(points, hit.Position)

                return points, true
            end

            table.insert(points, nextPosition)
        end

        return points, false
    end

    local function refreshHazards()
        local seen = {}

        for model in pairs(acidModels) do
            if model.Parent ~= workspace then
                acidModels[model] = nil
            else
                for _, descendant in ipairs(model:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        seen[descendant] = true

                        local hazard = hazards[descendant]
                        local velocity = descendant.AssemblyLinearVelocity
                        local moving = velocity.Magnitude >= MIN_SPEED

                        if moving and (not hazard or hazard.resting) then
                            -- Launched: its arc is worked out once, from the velocity it was launched with
                            local points, landed = simulateArc(descendant.Position, velocity)

                            hazards[descendant] = { points = points, landed = landed, resting = false }
                        elseif not moving and (not hazard or not hazard.resting) then
                            hazards[descendant] = { points = { descendant.Position }, landed = true, resting = true }
                        elseif hazard and hazard.resting then
                            hazard.points[1] = descendant.Position
                        end
                    end
                end
            end
        end

        for part in pairs(hazards) do
            if not seen[part] then
                hazards[part] = nil
            end
        end
    end

    -- How far a position is from being hit by a hazard: below zero means it is hit
    local function clearanceFrom(position, hazard, forDestination)
        if hazard.resting then
            local point = hazard.points[1]

            if math.abs(point.Y - position.Y) > LANDING_HEIGHT then
                return math.huge
            end

            local offset = Vector3.new(point.X - position.X, 0, point.Z - position.Z).Magnitude

            return offset - PUDDLE_RADIUS - (forDestination and PUDDLE_MARGIN or 0)
        end

        local best = math.huge
        local count = #hazard.points

        for index, point in ipairs(hazard.points) do
            local isLanding = hazard.landed and index == count
            local height = isLanding and LANDING_HEIGHT or PATH_HEIGHT

            if math.abs(point.Y - position.Y) <= height then
                local offset = Vector3.new(point.X - position.X, 0, point.Z - position.Z).Magnitude

                best = math.min(best, offset - (isLanding and LANDING_RADIUS or PATH_RADIUS))
            end
        end

        return best
    end

    local function worstClearance(position, forDestination)
        local worst = math.huge

        for _, hazard in pairs(hazards) do
            worst = math.min(worst, clearanceFrom(position, hazard, forDestination))
        end

        return worst
    end

    local function floorDistance(position)
        local hit = workspace:Raycast(position, Vector3.new(0, -FLOOR_REACH, 0), rayParams)

        return hit and hit.Distance or nil
    end

    -- Free space in a direction, measured at feet, chest and head height and a stud to both sides of the character
    local function roomAlong(origin, direction, limit)
        local sideways = Vector3.new(-direction.Z, 0, direction.X)
        local room = limit

        for _, height in ipairs({ -2, 0, 1.5 }) do
            for _, lateral in ipairs({ -1, 0, 1 }) do
                local start = origin + Vector3.new(0, height, 0) + sideways * lateral
                local hit = workspace:Raycast(start, direction * (limit + BODY_CLEARANCE), rayParams)

                if hit then
                    room = math.min(room, hit.Distance - BODY_CLEARANCE)
                end
            end
        end

        return room
    end

    local function nearestAlien(position, range)
        local folder = workspace:FindFirstChild("Killers")
        local closest, closestDistance

        if not folder then
            return nil
        end

        for _, model in ipairs(folder:GetChildren()) do
            if model.Name == "Alien" and model ~= localplayer.Character then
                local root = model:FindFirstChild("HumanoidRootPart")
                local humanoid = model:FindFirstChildOfClass("Humanoid")

                if root and humanoid and humanoid.Health > 0 then
                    local distance = (root.Position - position).Magnitude

                    if distance <= range and (not closestDistance or distance < closestDistance) then
                        closest, closestDistance = root, distance
                    end
                end
            end
        end

        return closest
    end

    -- Picks where to go: a side step when one side is clear, otherwise backwards (away from the Alien)
    local function planDodge(root, alienPosition)
        local origin = root.Position
        local currentFloor = floorDistance(origin)

        if not currentFloor then
            return nil
        end

        local away = Vector3.new(origin.X - alienPosition.X, 0, origin.Z - alienPosition.Z)

        if away.Magnitude < 0.5 then
            local look = root.CFrame.LookVector

            away = -Vector3.new(look.X, 0, look.Z)
        end

        away = away.Unit

        local sideways = Vector3.new(-away.Z, 0, away.X)
        local stepDistance = options.acidDodgeDistance_Slider.Value
        local candidates = {
            { kind = "side", direction = sideways },
            { kind = "side", direction = -sideways },
            { kind = "back", direction = away },
        }

        local bestSide, back

        for _, candidate in ipairs(candidates) do
            local distance = math.min(stepDistance, roomAlong(origin, candidate.direction, stepDistance))

            if distance >= MIN_STEP then
                local destination = origin + candidate.direction * distance
                local destinationFloor = floorDistance(destination)
                local middleFloor = floorDistance(origin + candidate.direction * (distance * 0.5))

                -- A destination over a gap, a ledge or a pit is no dodge
                if destinationFloor and middleFloor
                    and math.abs(destinationFloor - currentFloor) <= FLOOR_TOLERANCE
                    and math.abs(middleFloor - currentFloor) <= FLOOR_TOLERANCE then
                    candidate.distance = distance
                    candidate.destination = destination
                    candidate.clearance = worstClearance(destination, true)

                    if candidate.kind == "back" then
                        candidate.label = "backwards"
                        back = candidate
                    else
                        candidate.label = candidate.direction:Dot(root.CFrame.RightVector) >= 0 and "right" or "left"

                        if not bestSide or candidate.clearance > bestSide.clearance then
                            bestSide = candidate
                        end
                    end
                end
            end
        end

        if bestSide and bestSide.clearance >= 0 then
            return bestSide
        end

        if back and back.clearance >= 0 then
            return back
        end

        -- Nothing is completely clear: take the best option if it is clearly better than staying put
        local fallback = bestSide

        if back and (not fallback or back.clearance > fallback.clearance) then
            fallback = back
        end

        if fallback and fallback.clearance > worstClearance(origin, false) + 0.5 then
            return fallback
        end

        return nil
    end

    local function step()
        if next(acidModels) == nil then
            return
        end

        local root = getHRP()
        local humanoid = getHumanoid()

        if not root or not humanoid or humanoid.Health <= 0 then
            return
        end

        local alien = nearestAlien(root.Position, options.acidDodgeRange_Slider.Value)

        if not alien then
            return
        end

        refreshFilter(root.Parent)
        refreshHazards()

        if worstClearance(root.Position, false) >= 0 then
            return
        end

        local now = os.clock()

        if now - lastDodge < COOLDOWN then
            return
        end

        local plan = planDodge(root, alien.Position)

        if not plan then
            if toggles.acidDodgeDebugNotifs_Toggle.Value and now - lastNoRoomNotify > 1.5 then
                lastNoRoomNotify = now
                notify("Error", "Acid Dodge", "No safe room to dodge sideways or backwards.", 2)
            end

            return
        end

        lastDodge = now
        entityLib.teleport(CFrame.new(plan.destination) * root.CFrame.Rotation)
        root.AssemblyLinearVelocity = Vector3.zero

        if toggles.acidDodgeDebugNotifs_Toggle.Value then
            notify("Info", "Acid Dodge", string.format("Dodged %s by %.1f studs.", plan.label, plan.distance), 2)
        end
    end

    local function protectedStep()
        local ok, err = pcall(step)

        if not ok and os.clock() - lastWarn > 2 then
            lastWarn = os.clock()
            warn("[Acid Dodge] " .. tostring(err))
        end
    end

    local function onHeartbeat()
        if library.Unloaded then
            syncAcidDodge()

            return
        end

        protectedStep()
    end

    -- The discs of a new spit are already flying when it arrives, so it is dodged right away instead of on the next Heartbeat
    local function onChildAdded(child: any)
        if active and considerModel(child, true) then
            protectedStep()
        end
    end

    local function stop()
        active = false

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        table.clear(connections)
        table.clear(acidModels)
        table.clear(hazards)
    end

    local function start()
        active = true
        table.insert(connections, workspace.ChildAdded:Connect(onChildAdded))

        for _, child in ipairs(workspace:GetChildren()) do
            considerModel(child, false)
        end

        table.insert(connections, runService.Heartbeat:Connect(onHeartbeat))
    end

    syncAcidDodge = function()
        local shouldRun = toggles.acidDodge_Toggle.Value and toggles.killerGodmode_Toggle.Value and not library.Unloaded

        if shouldRun and not active then
            start()
        elseif not shouldRun and active then
            stop()
        end
    end
end

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
        connections = {} :: { RBXScriptConnection },
        mutedParts = {}, -- [BasePart] = true: CanTouch was disabled by Godmode
        stashedRemotes = {}, -- [RemoteEvent] = original parent (executors that can not hook __namecall)
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

    local function setCanTouch(part, value)
        part.CanTouch = value
    end

    local function setParent(instance, parent)
        instance.Parent = parent
    end

    -- Takes the touch hitbox of a killer part away in a way that can be undone.
    local function muteTouchHitbox(part)
        if godmode.active and part and part:IsA("BasePart") and part.CanTouch and pcall(setCanTouch, part, false) then
            godmode.mutedParts[part] = true
        end
    end

    local function stripKillerHitbox(instance: any)
        if instance:IsA("TouchTransmitter") and not isOwnCharacter(instance) then
            muteTouchHitbox(instance.Parent)
        end
    end

    -- Damage remotes can not be blocked without the hook, so they are taken out of the killer for as long as Godmode is on
    local function stashDamageRemote(remote)
        local parent = remote.Parent

        if parent and pcall(setParent, remote, nil) then
            godmode.stashedRemotes[remote] = parent
        end
    end

    -- Gives back everything Killer Godmode took away
    local function restoreKillerState()
        for part in pairs(godmode.mutedParts) do
            godmode.mutedParts[part] = nil

            if part.Parent then
                pcall(setCanTouch, part, true)
            end
        end

        for remote, parent in pairs(godmode.stashedRemotes) do
            godmode.stashedRemotes[remote] = nil

            if parent.Parent then
                pcall(setParent, remote, parent)
            end
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
        syncAntiPinhead()
        syncAcidDodge()

        if not enabled then
            restoreKillerState()

            return
        end

        local blockerReady = installReportBlocker()

        if not blockerReady and not godmode.warned then
            godmode.warned = true
            notify("Error", "Killer Godmode", "This executor can not hook __namecall, so damage reports can not be blocked. Only hitboxes are removed.", 6)
        end

        -- Hitboxes: removed the moment they appear instead of waiting for the next sweep
        table.insert(godmode.connections, killersFolder.DescendantAdded:Connect(stripKillerHitbox))

        -- Freddy's nightmare hazards only ever exist on the client and are created again for every attack. The hole pulls your character with a LineForce, so it goes as well
        table.insert(godmode.connections, workspace.ChildAdded:Connect(function(child)
            if godmode.active and (child.Name == "HolePart" or child.Name == "FreddyNightmare") then
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
                                stashDamageRemote(descendant)
                            end
                        end
                    end
                end

                -- mutedParts holds its parts, so let go of the ones that got destroyed
                for part in pairs(godmode.mutedParts) do
                    if not part:IsDescendantOf(game) then
                        godmode.mutedParts[part] = nil
                    end
                end

                task.wait(0.5)
            end
        end)
    end)
end

toggles.antiPinhead_Toggle:OnChanged(syncAntiPinhead)
table.insert(teardownTasks, syncAntiPinhead)
toggles.acidDodge_Toggle:OnChanged(syncAcidDodge)

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

-- [Exploits / Hitbox Expander] Resizes Killer hit parts safely
do
    local hitboxGroup = tabs.exploits:AddGroupbox({ Side = "Right", Name = "Hitbox Expander", IconName = assetLib.fetchAsset("Icons/crosshair.png"), Description = "Killer hitbox size" })

    hitboxGroup:AddToggle("hitboxExpander_Toggle", { Text = "Hitbox Expander", Tooltip = "Enlarges the hit parts of every Killer in range so shots land more easily." })

    local hitboxExpanderDepbox = hitboxGroup:AddDependencyBox()
    hitboxExpanderDepbox:AddSlider("hitboxSize_Slider", { Text = "Hitbox Size", Tooltip = "Smallest size of each resized hit part (head, arms and legs).", Default = 8, Min = 2, Max = 30, Suffix = " Studs", Rounding = 1 })
    hitboxExpanderDepbox:AddSlider("hitboxRange_Slider", { Text = "Range", Tooltip = "Only Killers closer than this get an expanded hitbox.", Default = 350, Min = 50, Max = 1000, Suffix = " Studs" })
    hitboxExpanderDepbox:AddDropdown("hitboxExcludedKillers_Dropdown", { Text = "Excluded Killers", Tooltip = "Killers that keep their original hitbox. Giant and Jane are always skipped, because the game ignores normal shots on them.", Values = killerNames, Multi = true, Searchable = true, AllowNull = true })
    hitboxExpanderDepbox:AddDivider()

    hitboxExpanderDepbox:SetupDependencies({ { toggles.hitboxExpander_Toggle, true } })

    -- Killers the game never registers normal shots on.
    local immuneKillers = { Giant = true, Jane = true }

    -- Only these humanoid parts are ever resized.
    local resizableParts = {
        Head = true,
        LeftUpperArm = true, RightUpperArm = true, LeftLowerArm = true, RightLowerArm = true, LeftHand = true, RightHand = true,
        LeftUpperLeg = true, RightUpperLeg = true, LeftLowerLeg = true, RightLowerLeg = true, LeftFoot = true, RightFoot = true,
    }

    -- ESP boxes are measured from these sizes, so enlarged hitboxes never inflate them.
    utils.hitboxOriginalSizes = setmetatable({}, { __mode = "k" })

    local expander = {
        killers = {},      -- [model] = { model, ghost, records = { [part] = record }, rejected = { [part] = retryTime } }
        compensated = {},  -- [HumanoidRootPart] = { physics, mass, applied }
        moveSources = {},  -- real parts, in the same order as moveGhosts
        moveGhosts = {},   -- normal-sized look-alike parts that follow the real ones every frame
        moveFrames = {},
        movesDirty = false,
        massDirty = false,
        token = nil,
        folder = nil,
        renderConnection = nil :: RBXScriptConnection?,
        physicsConnection = nil :: RBXScriptConnection?,
        excluded = {},
        lastError = nil,
        lastRenderError = nil,
    }

    local function getKillersFolder()
        return killersFolder or workspace:FindFirstChild("Killers")
    end

    local function readExcluded(value)
        expander.excluded = {}

        if type(value) == "table" then
            for name, selected in pairs(value) do
                if type(name) == "string" and selected then
                    expander.excluded[name] = true
                elseif type(selected) == "string" then
                    expander.excluded[selected] = true
                end
            end
        end
    end

    -- A part is safe to resize when it can be hit but never collides and never has a touch hitbox of its own.
    local function isResizable(part)
        return part:IsA("BasePart")
            and part.CanQuery and part.CanTouch and not part.CanCollide
            and not part:FindFirstChildWhichIsA("TouchTransmitter")
    end

    -- Re-check for parts that were already accepted once
    local function stillResizable(part)
        return part.CanQuery and part.CanTouch and not part.CanCollide
    end

    local function writeLocalTransparency(instance, value)
        if instance.LocalTransparencyModifier ~= value then
            instance.LocalTransparencyModifier = value
        end
    end

    local function setLocalTransparency(instance, value)
        pcall(writeLocalTransparency, instance, value)
    end

    local function readLocalTransparency(instance)
        local success, value = pcall(function()
            return instance.LocalTransparencyModifier
        end)

        return success and value or 0
    end

    local function getExpanderFolder()
        if expander.folder and expander.folder.Parent then
            return expander.folder
        end

        local folder = Instance.new("Folder")
        folder.Name = "KillerVisuals"
        folder.Parent = workspace
        expander.folder = folder

        return folder
    end

    -- Keep the Killer's appearance the same by cloning look-alike parts.
    local function getGhost(state)
        if state.ghost and state.ghost.Parent then
            return state.ghost
        end

        local ghost = Instance.new("Model")
        ghost.Name = state.model.Name

        local humanoid = Instance.new("Humanoid")
        humanoid.RigType = Enum.HumanoidRigType.R15
        humanoid.EvaluateStateMachine = false
        humanoid.RequiresNeck = false
        humanoid.BreakJointsOnDeath = false
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        humanoid.Parent = ghost

        for _, child in ipairs(state.model:GetChildren()) do
            if child:IsA("Shirt") or child:IsA("Pants") then
                local success, copy = pcall(child.Clone, child)

                if success and copy then
                    copy.Parent = ghost
                end
            end
        end

        ghost.Parent = getExpanderFolder()
        state.ghost = ghost

        return ghost
    end

    local function createGhostPart(state, part, size)
        local success, copy = pcall(part.Clone, part)

        if not success or not copy then
            return nil
        end

        for _, child in ipairs(copy:GetChildren()) do
            if not (child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") or child:IsA("SpecialMesh")) then
                child:Destroy()
            end
        end

        copy.Anchored = true
        copy.CanCollide = false
        copy.CanTouch = false
        copy.CanQuery = false
        copy.Massless = true
        copy.Size = size
        copy.CFrame = part.CFrame
        copy.Parent = getGhost(state)

        return copy
    end

    -- Parallel lists that BulkMoveTo uses to move every look-alike in one call per frame
    local function rebuildMoves()
        local sources, ghosts = {}, {}

        for _, state in pairs(expander.killers) do
            for part, record in pairs(state.records) do
                if record.ghost then
                    sources[#sources + 1] = part
                    ghosts[#ghosts + 1] = record.ghost
                end
            end
        end

        expander.moveSources = sources
        expander.moveGhosts = ghosts
        expander.moveFrames = table.create(#ghosts, CFrame.identity)
        expander.movesDirty = false
    end

    local function stepGhosts()
        if expander.movesDirty then
            rebuildMoves()
        end

        local sources, ghosts, frames = expander.moveSources, expander.moveGhosts, expander.moveFrames
        local count = #ghosts

        if count == 0 then
            return
        end

        for index = 1, count do
            frames[index] = sources[index].CFrame
        end

        workspace:BulkMoveTo(ghosts, frames, Enum.BulkMoveMode.FireCFrameChanged)
    end

    local function releasePart(state, part, restore)
        local record = state.records[part]

        if not record then
            return
        end

        state.records[part] = nil
        utils.hitboxOriginalSizes[part] = nil
        expander.massDirty = true

        if record.connection then
            record.connection:Disconnect()
        end

        if record.collideConnection then
            record.collideConnection:Disconnect()
        end

        if record.ghost then
            pcall(record.ghost.Destroy, record.ghost)
            expander.movesDirty = true
        end

        if restore and part.Parent then
            pcall(function()
                part.Size = record.original
                part.CustomPhysicalProperties = record.physics
                part.Massless = record.massless
            end)

            setLocalTransparency(part, record.localTransparency)

            for child, previous in pairs(record.hidden) do
                setLocalTransparency(child, previous)
            end
        end
    end

    -- Keeps the part's mass exactly as it was, so a client-owned Killer moves the same.
    local function writeSize(part, record, size)
        local original = record.original
        local ratio = (original.X * original.Y * original.Z) / (size.X * size.Y * size.Z)

        record.lost = 0
        expander.massDirty = true

        if ratio > 0.9999 then
            part.CustomPhysicalProperties = record.physics
            part.Massless = record.massless
        else
            local base = record.physics or PhysicalProperties.new(part.Material)
            local density = base.Density * ratio

            if density >= 0.01 then
                part.CustomPhysicalProperties = PhysicalProperties.new(density, base.Friction, base.Elasticity, base.FrictionWeight, base.ElasticityWeight)
                part.Massless = record.massless
            else
                -- Too light for a density to express: the part goes massless and its mass is handed to the root part below.
                part.CustomPhysicalProperties = record.physics
                part.Massless = true
                record.lost = record.mass
            end
        end

        part.Size = size
        record.applied = part.Size
    end

    -- The stretched original stays invisible and the normal-sized look-alike replaces it
    local function hideReal(part, record)
        setLocalTransparency(part, 1)

        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                if record.hidden[child] == nil then
                    record.hidden[child] = readLocalTransparency(child)
                end

                setLocalTransparency(child, 1)
            end
        end
    end

    -- The look-alike copies the live appearance, so Killers that fade or change colour still look right
    local function syncLook(part, record)
        local ghost = record.ghost

        if not ghost then
            return
        end

        if ghost.Color ~= part.Color then
            ghost.Color = part.Color
        end

        if ghost.Transparency ~= part.Transparency then
            ghost.Transparency = part.Transparency
        end

        if ghost.Material ~= part.Material then
            ghost.Material = part.Material
        end

        if ghost.Reflectance ~= part.Reflectance then
            ghost.Reflectance = part.Reflectance
        end

        writeLocalTransparency(part, 1) -- Re-assert the hiding in case something reset it

        for child in pairs(record.hidden) do
            setLocalTransparency(child, 1)
        end
    end

    local function applyPart(state, part, target)
        local record = state.records[part]

        if not record then
            record = {
                original = part.Size,
                massless = part.Massless,
                physics = part.CustomPhysicalProperties,
                mass = part.Massless and 0 or part.Mass,
                lost = 0,
                localTransparency = readLocalTransparency(part),
                hidden = {},
                applied = nil,
                ghost = nil,
            }

            state.records[part] = record
            utils.hitboxOriginalSizes[part] = record.original

            record.connection = part.AncestryChanged:Connect(function()
                if not part:IsDescendantOf(workspace) then
                    releasePart(state, part, false)
                end
            end)

            -- If a dying Killer ragdolls and its limbs start to collide, give the original size back immediately.
            record.collideConnection = part:GetPropertyChangedSignal("CanCollide"):Connect(function()
                if part.CanCollide then
                    releasePart(state, part, true)
                end
            end)

            -- The look-alike is made from the untouched part, before it is resized or hidden
            record.ghost = createGhostPart(state, part, record.original)

            if record.ghost then
                expander.movesDirty = true
            end
        elseif record.applied and (part.Size - record.applied).Magnitude > 0.01 then
            -- If the game resized the part itself, make that size the new original.
            record.original = part.Size
            utils.hitboxOriginalSizes[part] = part.Size
            record.applied = nil

            if record.ghost then
                record.ghost.Size = part.Size
            end
        end

        local original = record.original
        local size = Vector3.new(math.max(original.X, target), math.max(original.Y, target), math.max(original.Z, target))

        if not record.applied or (record.applied - size).Magnitude > 0.001 then
            writeSize(part, record, size)
        end

        if record.ghost then
            if not record.hiddenOnce then
                record.hiddenOnce = true
                hideReal(part, record)
            end

            syncLook(part, record)
        end
    end

    -- Total mass of every Killer stays exactly as the game made it: what a resized limb can not carry goes to the root part's density.
    local function refreshMassCompensation()
        local totals = {}

        expander.massDirty = false

        for _, state in pairs(expander.killers) do
            for part, record in pairs(state.records) do
                local model = part.Parent

                if model and record.lost > 0 then
                    totals[model] = (totals[model] or 0) + record.lost
                end
            end
        end

        for model, lost in pairs(totals) do
            local root = model:FindFirstChild("HumanoidRootPart")

            if root and root:IsA("BasePart") then
                local entry = expander.compensated[root]

                if not entry then
                    entry = { physics = root.CustomPhysicalProperties, mass = root.Mass, applied = 0 }
                    expander.compensated[root] = entry
                end

                if math.abs(entry.applied - lost) > 0.001 and entry.mass > 0 then
                    local base = entry.physics or PhysicalProperties.new(root.Material)
                    local density = math.min(base.Density * (entry.mass + lost) / entry.mass, 100)

                    root.CustomPhysicalProperties = PhysicalProperties.new(density, base.Friction, base.Elasticity, base.FrictionWeight, base.ElasticityWeight)
                    entry.applied = lost
                end
            end
        end

        for root, entry in pairs(expander.compensated) do
            if not root.Parent or not totals[root.Parent] then
                expander.compensated[root] = nil

                if root.Parent then
                    pcall(function()
                        root.CustomPhysicalProperties = entry.physics
                    end)
                end
            end
        end
    end

    local function deactivateKiller(model, restore)
        local state = expander.killers[model]

        if not state then
            return
        end

        expander.killers[model] = nil

        if state.healthConnection then
            state.healthConnection:Disconnect()
            state.healthConnection = nil
        end

        for part in pairs(state.records) do
            releasePart(state, part, restore)
        end

        if state.ghost then
            pcall(state.ghost.Destroy, state.ghost)
        end

        expander.movesDirty = true
    end

    -- A dying Killer gets its original sizes and mass back immediately
    local function releaseNow(model)
        if expander.killers[model] then
            deactivateKiller(model, model.Parent ~= nil)
        end

        if expander.massDirty then
            refreshMassCompensation()
        end
    end

    -- Also used by Disable Aura and Emergency Kill, which give the hit parts back right before they kill a Killer
    utils.releaseKillerHitbox = releaseNow

    local function isDying(state)
        local model = state.model
        local humanoid = state.humanoid

        if not (humanoid and humanoid.Parent == model) then
            humanoid = model:FindFirstChildOfClass("Humanoid")
            state.humanoid = humanoid
        end

        return not model.Parent or not humanoid or humanoid.Health <= 0
    end

    -- Runs right before every physics step, so no step simulates a dying Killer with enlarged parts
    local function releaseDying()
        for model, state in pairs(expander.killers) do
            if isDying(state) then
                deactivateKiller(model, model.Parent ~= nil)
            end
        end

        if expander.massDirty then
            refreshMassCompensation()
        end
    end

    -- Only Killers close to the camera are touched; each one is scanned from a cached list of its parts
    local function sweepExpander()
        local folder = getKillersFolder()
        local camera = workspace.CurrentCamera
        local character = localplayer.Character
        local target = tonumber(options.hitboxSize_Slider.Value) or 8
        local range = tonumber(options.hitboxRange_Slider.Value) or 350
        local origin = camera and camera.CFrame.Position or (character and character:GetPivot().Position)
        local now = os.clock()
        local eligible = {}

        if folder and origin then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") and model ~= character
                    and not immuneKillers[model.Name] and not expander.excluded[model.Name] then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    local root = model:FindFirstChild("HumanoidRootPart")

                    -- A dying Killer is left alone so it ragdolls with its original parts.
                    if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
                        -- A little extra room before a Killer is let go, so one standing on the edge does not flicker
                        local limit = expander.killers[model] and range * 1.1 or range

                        if (root.Position - origin).Magnitude <= limit then
                            eligible[model] = true
                        end
                    end
                end
            end
        end

        for model in pairs(expander.killers) do
            if not eligible[model] then
                deactivateKiller(model, model.Parent ~= nil)
            end
        end

        for model in pairs(eligible) do
            local state = expander.killers[model]

            if not state then
                state = { model = model, ghost = nil, records = {}, rejected = setmetatable({}, { __mode = "k" }) }
                expander.killers[model] = state

                local humanoid = model:FindFirstChildOfClass("Humanoid")

                if humanoid then
                    state.humanoid = humanoid

                    state.healthConnection = humanoid.HealthChanged:Connect(function(health)
                        if health <= 0 then
                            releaseNow(model)
                        end
                    end)
                end
            end

            local seen = {}

            for _, part in ipairs(model:GetChildren()) do
                if resizableParts[part.Name] then
                    if state.records[part] then
                        if stillResizable(part) then
                            seen[part] = true
                            applyPart(state, part, target)
                        end
                    else
                        local retry = state.rejected[part]

                        if not (retry and retry > now) then
                            if isResizable(part) then
                                seen[part] = true
                                applyPart(state, part, target)
                            else
                                state.rejected[part] = now + 2
                            end
                        end
                    end
                end
            end

            -- Anything no longer eligible gets its original size back.
            for part in pairs(state.records) do
                if not seen[part] then
                    releasePart(state, part, true)
                end
            end
        end

        if expander.massDirty then
            refreshMassCompensation()
        end
    end

    local function stopExpander()
        expander.token = nil

        if expander.renderConnection then
            expander.renderConnection:Disconnect()
            expander.renderConnection = nil
        end

        if expander.physicsConnection then
            expander.physicsConnection:Disconnect()
            expander.physicsConnection = nil
        end

        for model in pairs(expander.killers) do
            deactivateKiller(model, true)
        end

        refreshMassCompensation()
        rebuildMoves()

        if expander.folder then
            pcall(expander.folder.Destroy, expander.folder)
            expander.folder = nil
        end
    end

    toggles.hitboxExpander_Toggle:OnChanged(function(enabled)
        stopExpander()

        if not enabled then
            return
        end

        local token = {}
        expander.token = token

        expander.renderConnection = runService.RenderStepped:Connect(function()
            local success, err = pcall(stepGhosts)

            if not success and err ~= expander.lastRenderError then
                expander.lastRenderError = err
                warn("[Hitbox Expander] " .. tostring(err))
            end
        end)

        expander.physicsConnection = runService.PreSimulation:Connect(function()
            local success, err = pcall(releaseDying)

            if not success and err ~= expander.lastRenderError then
                expander.lastRenderError = err
                warn("[Hitbox Expander] " .. tostring(err))
            end
        end)

        task.spawn(function()
            while expander.token == token and not library.Unloaded do
                local success, err = pcall(sweepExpander)

                if not success and err ~= expander.lastError then
                    expander.lastError = err
                    warn("[Hitbox Expander] " .. tostring(err))
                end

                task.wait(0.25)
            end
        end)
    end)

    local function refreshNow()
        if expander.token then
            pcall(sweepExpander)
        end
    end

    options.hitboxSize_Slider:OnChanged(refreshNow)
    options.hitboxRange_Slider:OnChanged(refreshNow)

    readExcluded(options.hitboxExcludedKillers_Dropdown.Value)

    options.hitboxExcludedKillers_Dropdown:OnChanged(function(value)
        readExcluded(value)
        refreshNow()
    end)

    table.insert(teardownTasks, stopExpander)
end

-- ============================================================================
-- 11 | TAB: VISUALS
-- ============================================================================

-- [Visuals / Layout] Groupbox and control registration
local visualsGroup = tabs.visuals:AddGroupbox({ Side = "Left", Name = "Visuals", IconName = assetLib.fetchAsset("Icons/eye.png"), Description = "ESP, FOV, and effects" })

-- [Visuals / Controls] ESP, name tags, fog, FOV, and anti-effects

visualsGroup:AddToggle("removeFog_Toggle", { Text = "Remove Fog" })
visualsGroup:AddToggle("killerESP_Toggle", { Text = "Killer ESP" })
visualsGroup:AddToggle("enableFOV_Toggle", { Text = "Enable FOV" })
visualsGroup:AddToggle("antiInk_Toggle", { Text = "Anti Ink", Tooltip = "Disables the black ink popup from Eyeless Jack." })
visualsGroup:AddToggle("antiTailsPopup_Toggle", { Text = "Anti Tails Popup", Tooltip = "Disables the popup from Tails Doll." })
visualsGroup:AddToggle("disableScopeOverlay_Toggle", { Text = "Disable Scope Overlay", Tooltip = "Removes the black overlay when aiming through a scope, on any weapon. The zoom is kept." })

local scopeOverlayDepbox = visualsGroup:AddDependencyBox()
scopeOverlayDepbox:AddToggle("keepScopeCrosshair_Toggle", { Text = "Keep Crosshair", Tooltip = "Shows the normal crosshair while scoped, since the scope's own reticle goes away with the overlay.", Default = true })
scopeOverlayDepbox:AddDivider()

local killerESPDepbox = visualsGroup:AddDependencyBox()

killerESPDepbox:AddDropdown("excludedKillers_Dropdown", { Text = "Excluded Killers", Values = killerNames, Default = { "Giant", "Jane" }, Multi = true, Searchable = true })
killerESPDepbox:AddSlider("killerESPDistance_Slider", { Text = "Range", Tooltip = "How far away to show ESP on killers", Default = 150, Min = 100, Max = 1000, Suffix = " Studs" })
killerESPDepbox:AddDropdown("killerESPBoxType_Dropdown", { Text = "Box Type", Tooltip = "2D draws a flat box around the killer, 3D draws a wireframe box.", Values = { "2D", "3D" }, Default = 1 })
killerESPDepbox:AddToggle("killerESPHealthBar_Toggle", { Text = "Health Bar", Tooltip = "Shows a health bar next to the killer.", Default = true })
killerESPDepbox:AddLabel("ESP Color"):AddColorPicker("killerESPColor_ColorPicker",{ Title = "ESP Color", Default = Color3.fromRGB(255, 0, 0), Transparency = nil })
killerESPDepbox:AddCheckbox("rainbowESPColor_Toggle", { Text = "Rainbow ESP Color" })
killerESPDepbox:AddToggle("toggleKillersNametags_Toggle", { Text = "Enable Name Tags" })
killerESPDepbox:AddDivider()

local killerNametagDepbox = killerESPDepbox:AddDependencyBox()
killerNametagDepbox:AddLabel("Name Tag Color"):AddColorPicker("killerNameTagColor_ColorPicker",{ Title = "Name Tag Color", Default = Color3.fromRGB(255, 255, 255), Transparency = nil })
killerNametagDepbox:AddCheckbox("rainbowNameTagColor_Toggle", { Text = "Rainbow Name Tag Color" })
killerNametagDepbox:AddSlider("textSize_Slider", { Text = "Text Size", Default = 15, Min = 10, Max = 50 })
killerNametagDepbox:AddDivider()

local fieldOfViewDepbox = visualsGroup:AddDependencyBox()
fieldOfViewDepbox:AddSlider("fieldOfViewValue_Slider", { Text = "Value", Default = 80, Min = 80, Max = 120 })
fieldOfViewDepbox:AddDivider()

killerESPDepbox:SetupDependencies({ { toggles.killerESP_Toggle, true } })
killerNametagDepbox:SetupDependencies({ { toggles.toggleKillersNametags_Toggle, true } })
fieldOfViewDepbox:SetupDependencies({ { toggles.enableFOV_Toggle, true } })
scopeOverlayDepbox:SetupDependencies({ { toggles.disableScopeOverlay_Toggle, true } })

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
    local boxCache: { [Instance]: any } = setmetatable({}, { __mode = "k" }) :: any

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
                -- Enlarged hitboxes (Hitbox Expander) never inflate the ESP box
                local half = (utils.hitboxOriginalSizes[part] or part.Size) / 2
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
            local projected: { any } = {}

            for index, corner in ipairs(boxCorners) do
                local screen = cam:WorldToViewportPoint(boxCFrame:PointToWorldSpace(corner * half))
                projected[index] = screen.Z > 0 and Vector2.new(screen.X, screen.Y) or false
            end

            points = projected
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
do
    local connections: { RBXScriptConnection } = {}
    local silencedGuis = {} -- [ScreenGui] = true: Ink screens disabled by Anti Ink
    local active = false

    local function neutralizeInkEvent(event)
        -- One frame is left for the game to connect its handler, so that handler is cut off instead of waiting on a missing event forever
        task.wait()

        if not active or not event.Parent then
            return
        end

        if type(getconnections) == "function" then
            pcall(function()
                for _, connection in ipairs(getconnections(event.OnClientEvent)) do
                    connection:Disable()
                end
            end)
        end

        pcall(event.Destroy, event)
    end

    local function handleJack(jack: any)
        if jack.Name ~= "Eyeless Jack" then
            return
        end

        task.spawn(function()
            -- A Jack that just spawned may not have replicated its event yet
            local event = jack:WaitForChild("Inked", 5)

            if event and event:IsA("RemoteEvent") then
                neutralizeInkEvent(event)
            end
        end)
    end

    local function silenceInkGui(gui: any)
        if gui.Name == "Ink" and gui:IsA("ScreenGui") then
            silencedGuis[gui] = true
            gui.Enabled = false
        end
    end

    local function stop()
        active = false

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        table.clear(connections)

        for gui in pairs(silencedGuis) do
            if gui.Parent then
                gui.Enabled = true
            end
        end

        table.clear(silencedGuis)
    end

    local function start()
        stop()
        active = true

        -- The Jack if it is already on the map, and any that spawn later
        local jack = killersFolder:FindFirstChild("Eyeless Jack")

        if jack then
            handleJack(jack)
        end

        table.insert(connections, killersFolder.ChildAdded:Connect(handleJack))

        local playerGui = localplayer:FindFirstChild("PlayerGui")

        if playerGui then
            for _, child in ipairs(playerGui:GetChildren()) do
                silenceInkGui(child)
            end

            table.insert(connections, playerGui.ChildAdded:Connect(silenceInkGui))
        end
    end

    toggles.antiInk_Toggle:OnChanged(function(enabled)
        if enabled then
            start()
        else
            stop()
        end
    end)

    table.insert(teardownTasks, stop)
end

-- [Visuals / Anti Tails Popup]
do
    local connections = {}
    local silenced = {} -- [ScreenGui] = Enabled value the game had

    local function silencePopup(gui: Instance)
        if gui.Name ~= "TailsPopup" or not gui:IsA("ScreenGui") then
            return
        end

        local popup = gui :: ScreenGui

        if silenced[popup] == nil then
            silenced[popup] = popup.Enabled

            -- Keeps it off if the game ever switches it back on
            table.insert(connections, popup:GetPropertyChangedSignal("Enabled"):Connect(function()
                if silenced[popup] ~= nil and popup.Enabled then
                    popup.Enabled = false
                end
            end))
        end

        popup.Enabled = false
    end

    local function stop()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        table.clear(connections)

        for popup, wasEnabled in pairs(silenced) do
            if popup.Parent then
                popup.Enabled = wasEnabled
            end
        end

        table.clear(silenced)
    end

    local function start()
        stop()

        local playerGui = localplayer:FindFirstChildOfClass("PlayerGui")

        if not playerGui then
            notify("Error", "Failed to locate", "Failed to find PlayerGui.", 100)
            return
        end

        table.insert(connections, playerGui.ChildAdded:Connect(silencePopup))

        for _, child in ipairs(playerGui:GetChildren()) do
            silencePopup(child)
        end
    end

    toggles.antiTailsPopup_Toggle:OnChanged(function(enabled)
        if enabled then
            start()
        else
            stop()
        end
    end)

    table.insert(teardownTasks, stop)
end

-- [Visuals / Scope Overlay]
do
    local function buildScopeOverlayRemoval()
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

-- [Visuals / Hitbox Visualizer] One box per Killer around every part a shot can hit
do
    local hitboxVisualizerGroup = tabs.visuals:AddGroupbox({ Side = "Right", Name = "Hitbox Visualizer", IconName = assetLib.fetchAsset("Icons/crosshair.png"), Description = "Killer hitbox outlines" })

    hitboxVisualizerGroup:AddToggle("visualizeHitbox_Toggle", { Text = "Visualize Hitbox", Tooltip = "Draws a box around each Killer that covers every part a shot can hit." })

    local visualizeHitboxDepbox = hitboxVisualizerGroup:AddDependencyBox()
    visualizeHitboxDepbox:AddLabel("Hitbox Color"):AddColorPicker("hitboxVisualizeColor_ColorPicker", { Title = "Hitbox Color", Default = Color3.fromRGB(255, 60, 60), Transparency = nil })
    visualizeHitboxDepbox:AddSlider("hitboxVisualizeFill_Slider", { Text = "Fill Transparency", Default = 1, Min = 0, Max = 1, Rounding = 2 })
    visualizeHitboxDepbox:AddSlider("hitboxVisualizeRange_Slider", { Text = "Range", Tooltip = "How far away to show hitboxes on killers", Default = 150, Min = 50, Max = 1000, Suffix = " Studs" })
    visualizeHitboxDepbox:AddToggle("hitboxVisualizeWallCheck_Toggle", { Text = "Wall Check", Tooltip = "Only outline Killers that are visible.", Default = true })
    visualizeHitboxDepbox:AddDivider()

    visualizeHitboxDepbox:SetupDependencies({ { toggles.visualizeHitbox_Toggle, true } })

    -- Killers the game never registers normal shots on.
    local immuneKillers = { Giant = true, Jane = true }

    local OUTLINE_THICKNESS = 0.03
    local MEASURE_INTERVAL = 1 / 30 -- how often the bounds are measured; the box itself follows the Killer every frame
    local SHRINK_RATE = 1.2         -- how slowly the box lets go of space the limbs just left (it grows at once)
    local TURN_RATE = 25            -- how quickly the box follows the Killer turning

    local visualizer = {
        entries = {},     -- [model] = { proxy, box, outline, parts, bounds... }
        token = nil,
        folder = nil,       -- holds the drawn outlines (hidden UI container)
        proxyFolder = nil,  -- holds one invisible, non-solid stand-in part per box
        connection = nil,
        lastError = nil,
        lastRenderError = nil,
        lastStep = nil,
    }

    local function getKillersFolder()
        return killersFolder or workspace:FindFirstChild("Killers")
    end

    local function getVisualizerFolder()
        if visualizer.folder and visualizer.folder.Parent then
            return visualizer.folder
        end

        local folder = Instance.new("Folder")
        folder.Name = "HitboxVisualizer"
        folder.Parent = gethui()
        visualizer.folder = folder

        return folder
    end

    -- The game finds the Killer from the hit part's parent or grandparent, and ignores parts of a held tool.
    local function isHittablePart(model, part)
        if not part:IsA("BasePart") or not (part.CanQuery or part.CanTouch) then
            return false
        end

        local parent = part.Parent

        if parent ~= model and (not parent or parent.Parent ~= model) then
            return false
        end

        return part:FindFirstAncestorOfClass("Tool") == nil
    end

    -- Wall Check: a Killer is shown only when a straight line from the camera to its body or head has no wall in the way
    local function isKillerShown(model, origin)
        local root = model:FindFirstChild("HumanoidRootPart")

        if not (utils.isKillerVisible and root and root:IsA("BasePart")) then
            return true
        end

        return utils.isKillerVisible(origin, model, root)
    end

    local function getProxyFolder()
        if visualizer.proxyFolder and visualizer.proxyFolder.Parent then
            return visualizer.proxyFolder
        end

        local folder = Instance.new("Folder")
        folder.Name = "HitboxVisualizerBoxes"
        folder.Parent = workspace
        visualizer.proxyFolder = folder

        return folder
    end

    -- Each Killer gets one invisible copied part that is the box. It can not be hit, touched or collided with, so it never gets in the way of shots or movement.
    local function createEntry(model, now)
        local container = getVisualizerFolder()

        local proxy = Instance.new("Part")
        proxy.Name = model.Name
        proxy.Anchored = true
        proxy.CanCollide = false
        proxy.CanTouch = false
        proxy.CanQuery = false
        proxy.CastShadow = false
        proxy.Transparency = 1
        proxy.Size = Vector3.one
        proxy.Parent = getProxyFolder()

        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = proxy
        box.AlwaysOnTop = true
        box.ZIndex = 1
        box.Size = Vector3.one
        box.Transparency = 1
        box.Parent = container

        local outline = Instance.new("SelectionBox")
        outline.Adornee = proxy
        outline.LineThickness = OUTLINE_THICKNESS
        outline.SurfaceTransparency = 1
        outline.Parent = container

        return {
            model = model,
            humanoid = model:FindFirstChildOfClass("Humanoid"),
            proxy = proxy,
            box = box,
            outline = outline,
            parts = {},
            nextParts = 0,
            nextMeasure = 0,
            lastMeasure = now,
            minBound = nil,
            maxBound = nil,
            yaw = nil,
            shown = true,
            color = nil,
            fill = nil,
        }
    end

    local function releaseEntry(model)
        local entry = visualizer.entries[model]

        if entry then
            visualizer.entries[model] = nil
            pcall(entry.box.Destroy, entry.box)
            pcall(entry.outline.Destroy, entry.outline)
            pcall(entry.proxy.Destroy, entry.proxy)
        end
    end

    -- The parts a shot can hit are listed occasionally
    local function refreshParts(entry)
        local list = {}

        for _, part in ipairs(entry.model:GetDescendants()) do
            if isHittablePart(entry.model, part) then
                list[#list + 1] = part
            end
        end

        entry.parts = list
    end

    -- Smallest box, aligned to wherever the Killer's facing, that covers every hit part at its exact current size and rotation
    local function measure(parts, frame)
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        local abs = math.abs

        for index = 1, #parts do
            local part = parts[index]
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = frame:ToObjectSpace(part.CFrame):GetComponents()
            local size = part.Size
            local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
            local ex = abs(r00) * hx + abs(r01) * hy + abs(r02) * hz
            local ey = abs(r10) * hx + abs(r11) * hy + abs(r12) * hz
            local ez = abs(r20) * hx + abs(r21) * hy + abs(r22) * hz

            if x - ex < minX then minX = x - ex end
            if y - ey < minY then minY = y - ey end
            if z - ez < minZ then minZ = z - ez end
            if x + ex > maxX then maxX = x + ex end
            if y + ey > maxY then maxY = y + ey end
            if z + ez > maxZ then maxZ = z + ez end
        end

        if minX == math.huge then
            return nil, nil
        end

        return Vector3.new(minX, minY, minZ), Vector3.new(maxX, maxY, maxZ)
    end

    -- The box grows the moment a limb reaches out, but only lets go of space slowly, so a walk cycle does not make it pulse
    local function relaxLow(current, measured, keep)
        if measured <= current then
            return measured
        end

        return current + (measured - current) * keep
    end

    local function relaxHigh(current, measured, keep)
        if measured >= current then
            return measured
        end

        return current + (measured - current) * keep
    end

    local function updateEntry(entry, now, dt)
        local model = entry.model
        local root = model:FindFirstChild("HumanoidRootPart")
        local rootCFrame = root and root:IsA("BasePart") and root.CFrame or model:GetPivot()

        -- Upright and turning with the Killer; the box ignores any tilt of its limbs
        local look = rootCFrame.LookVector
        local targetYaw = math.atan2(-look.X, -look.Z)

        if not entry.yaw then
            entry.yaw = targetYaw
        else
            local difference = (targetYaw - entry.yaw + math.pi) % (2 * math.pi) - math.pi
            entry.yaw = entry.yaw + difference * (1 - math.exp(-dt * TURN_RATE))
        end

        local frame = CFrame.new(rootCFrame.Position) * CFrame.Angles(0, entry.yaw, 0)

        if now >= entry.nextParts then
            entry.nextParts = now + 1 + math.random() * 0.25
            refreshParts(entry)
        end

        local resized = false

        if now >= entry.nextMeasure then
            local elapsed = now - entry.lastMeasure

            entry.nextMeasure = now + MEASURE_INTERVAL
            entry.lastMeasure = now

            local measuredMin, measuredMax = measure(entry.parts, frame)

            if measuredMin then
                if not entry.minBound then
                    entry.minBound, entry.maxBound = measuredMin, measuredMax
                else
                    local keep = 1 - math.exp(-elapsed * SHRINK_RATE)
                    local low, high = entry.minBound, entry.maxBound

                    entry.minBound = Vector3.new(
                        relaxLow(low.X, measuredMin.X, keep), relaxLow(low.Y, measuredMin.Y, keep), relaxLow(low.Z, measuredMin.Z, keep))
                    entry.maxBound = Vector3.new(
                        relaxHigh(high.X, measuredMax.X, keep), relaxHigh(high.Y, measuredMax.Y, keep), relaxHigh(high.Z, measuredMax.Z, keep))
                end

                resized = true
            end
        end

        if not entry.minBound then
            return
        end

        if resized then
            local size = entry.maxBound - entry.minBound

            entry.proxy.Size = size
            entry.box.Size = size
        end

        entry.proxy.CFrame = frame * CFrame.new((entry.minBound + entry.maxBound) * 0.5)
    end

    local function stepEntries()
        local now = os.clock()
        local dt = math.min(now - (visualizer.lastStep or now), 0.25)

        visualizer.lastStep = now

        for model, entry in pairs(visualizer.entries) do
            local humanoid = entry.humanoid

            if not (humanoid and humanoid.Parent == model) then
                humanoid = model:FindFirstChildOfClass("Humanoid")
                entry.humanoid = humanoid
            end

            -- A Killer that dies loses its box.
            if not model.Parent or not humanoid or humanoid.Health <= 0 then
                releaseEntry(model)
            elseif entry.shown then
                updateEntry(entry, now, dt)
            end
        end
    end

    -- Decides which Killers get a box (alive, in range, visible) and keeps the colors current
    local function sweepVisualizer()
        local folder = getKillersFolder()
        local camera = workspace.CurrentCamera
        local color = options.hitboxVisualizeColor_ColorPicker.Value
        local fill = options.hitboxVisualizeFill_Slider.Value
        local range = options.hitboxVisualizeRange_Slider.Value
        local wallCheck = toggles.hitboxVisualizeWallCheck_Toggle.Value
        local now = os.clock()
        local active = {}

        if folder and camera then
            local origin = camera.CFrame.Position

            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") and model ~= localplayer.Character and not immuneKillers[model.Name] then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    local root = model:FindFirstChild("HumanoidRootPart")
                    local position = root and root:IsA("BasePart") and root.Position or model:GetPivot().Position

                    if humanoid and humanoid.Health > 0 and (position - origin).Magnitude <= range then
                        active[model] = true

                        local entry = visualizer.entries[model]

                        if not entry then
                            entry = createEntry(model, now)
                            visualizer.entries[model] = entry
                        end

                        local shown = not wallCheck or isKillerShown(model, origin)

                        if entry.shown ~= shown then
                            entry.shown = shown
                            entry.box.Visible = shown
                            entry.outline.Visible = shown
                        end

                        if entry.color ~= color then
                            entry.color = color
                            entry.box.Color3 = color
                            entry.outline.Color3 = color
                        end

                        if entry.fill ~= fill then
                            entry.fill = fill
                            entry.box.Transparency = fill
                        end
                    end
                end
            end
        end

        for model in pairs(visualizer.entries) do
            if not active[model] then
                releaseEntry(model)
            end
        end
    end

    local function stopVisualizer()
        visualizer.token = nil

        if visualizer.connection then
            visualizer.connection:Disconnect()
            visualizer.connection = nil
        end

        for model in pairs(visualizer.entries) do
            releaseEntry(model)
        end

        if visualizer.folder then
            pcall(visualizer.folder.Destroy, visualizer.folder)
            visualizer.folder = nil
        end

        if visualizer.proxyFolder then
            pcall(visualizer.proxyFolder.Destroy, visualizer.proxyFolder)
            visualizer.proxyFolder = nil
        end
    end

    toggles.visualizeHitbox_Toggle:OnChanged(function(enabled)
        stopVisualizer()

        if not enabled then
            return
        end

        local token = {}
        visualizer.token = token
        visualizer.lastStep = nil

        visualizer.connection = runService.RenderStepped:Connect(function()
            local success, err = pcall(stepEntries)

            if not success and err ~= visualizer.lastRenderError then
                visualizer.lastRenderError = err
                warn("[Visualize Hitbox] " .. tostring(err))
            end
        end)

        task.spawn(function()
            while visualizer.token == token and not library.Unloaded do
                local success, err = pcall(sweepVisualizer)

                if not success and err ~= visualizer.lastError then
                    visualizer.lastError = err
                    warn("[Visualize Hitbox] " .. tostring(err))
                end

                task.wait(0.2)
            end
        end)
    end)

    table.insert(teardownTasks, stopVisualizer)
end

-- [Visuals / Grenade Trajectory] Flight path and landing preview for the M16A2's grenade launcher (M203)
do
    local function buildGrenadeTrajectory()
        local trajectoryGroup = tabs.visuals:AddGroupbox({ Side = "Right", Name = "Grenade Trajectory", IconName = assetLib.fetchAsset("Icons/crosshair.png"), Description = "Grenade path preview" })

        trajectoryGroup:AddToggle("trajectoryPreview_Toggle", { Text = "Grenade Trajectory", Tooltip = "Draws the flight path and landing spot of the M16A2's grenade launcher (M203) while it is equipped in grenade mode." })

        local trajectoryDepbox = trajectoryGroup:AddDependencyBox()

        trajectoryDepbox:AddLabel("Path Color"):AddColorPicker("trajectoryPathColor_ColorPicker", { Title = "Path Color", Default = Color3.fromRGB(0, 229, 255) })
        trajectoryDepbox:AddLabel("Landing Color"):AddColorPicker("trajectoryLandingColor_ColorPicker", { Title = "Landing Color", Default = Color3.fromRGB(255, 170, 0) })
        trajectoryDepbox:AddSlider("trajectoryThickness_Slider", { Text = "Line Thickness", Default = 2, Min = 1, Max = 5 })
        trajectoryDepbox:AddSlider("trajectoryMarkerSize_Slider", { Text = "Landing Marker Size", Tooltip = "Radius of the ring drawn where the grenade lands. Only a visual size, not the explosion radius.", Default = 3, Min = 1, Max = 10, Suffix = " Studs" })
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

local worldGroup = tabs.world:AddGroupbox({ Side = "Left", Name = "World", IconName = assetLib.fetchAsset("Icons/globe.png"), Description = "Map hazards and doors" })
local unlockAlienGroup = tabs.world:AddGroupbox({ Side = "Right", Name = "Alien", IconName = assetLib.fetchAsset("Icons/ghost.png"), Description = "Alien code and door" })

-- [World / Environment] Hazards, radioactive area, kill parts, and door noclip

worldGroup:AddToggle("disableCactuses_Toggle", { Text = "Disable Cactuses" })
worldGroup:AddToggle("removeBearTraps_Toggle", { Text = "Remove Bear Traps" })
worldGroup:AddToggle("disableRadioactiveZone_Toggle", { Text = "Disable Radioactive Zone" })
worldGroup:AddToggle("disableKillParts_Toggle", { Text = "Disable Kill Parts", Tooltip = "Disables parts that can damage or kill you such as fans/spinners, polluted water, etc." })
worldGroup:AddToggle("doorNoclip_Toggle", { Text = "Door Noclip" })

-- Every part changed is recorded first, so switching a toggle off puts back exactly what the map had.

-- [World / Cactuses] Only the parts the server listens to are changed
do
    local originals = {} -- [BasePart] = CanTouch the map gave it
    local connection: RBXScriptConnection? = nil

    local function disarm(instance: Instance)
        if not instance:IsA("TouchTransmitter") then
            return
        end

        local part = instance.Parent

        if part and part:IsA("BasePart") then
            if originals[part] == nil then
                originals[part] = part.CanTouch
            end

            part.CanTouch = false
        end
    end

    local function stop()
        if connection then
            connection:Disconnect()
            connection = nil
        end

        for part, canTouch in pairs(originals) do
            if part.Parent then
                part.CanTouch = canTouch
            end
        end

        table.clear(originals)
    end

    local function start()
        stop()

        local outside = area51:FindFirstChild("Outside")
        local cactusFolder = outside and outside:FindFirstChild("Cactus")

        if not cactusFolder then
            notify("Error", "Failed to locate", "Failed to find the cactuses.", 100)
            return
        end

        -- Catches a touch listener the server adds after the toggle is on
        connection = cactusFolder.DescendantAdded:Connect(disarm)

        for _, descendant in ipairs(cactusFolder:GetDescendants()) do
            disarm(descendant)
        end
    end

    toggles.disableCactuses_Toggle:OnChanged(function(enabled)
        if enabled then
            start()
        else
            stop()
        end
    end)

    table.insert(teardownTasks, stop)
end

-- [World / Bear Traps] Granny's traps are made by the server, so each one is caught the moment it replicates
do
    local connection: RBXScriptConnection? = nil

    local function neutralize(instance: Instance)
        if instance.Name ~= "BearTrap" then
            return
        end

        -- Done immediately, before the trap can register a touch from the local character
        if instance:IsA("BasePart") then
            instance.CanTouch = false
        elseif instance:IsA("Model") then
            for _, descendant in ipairs(instance:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.CanTouch = false
                end
            end
        else
            return
        end

        -- Deferred: an instance cannot be re-parented from inside the signal that announced it
        task.defer(function()
            pcall(instance.Destroy, instance)
        end)
    end

    local function stop()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end

    local function start()
        stop()

        connection = game.Workspace.DescendantAdded:Connect(neutralize)

        -- Traps that were already placed. QueryDescendants is several times faster than searching the whole map via GetDescendants
        local success, existing = pcall(function()
            return game.Workspace:QueryDescendants("#BearTrap")
        end)

        if success then
            for _, trap in ipairs(existing) do
                neutralize(trap)
            end
        else
            for _, child in ipairs(game.Workspace:GetChildren()) do
                neutralize(child)
            end
        end
    end

    toggles.removeBearTraps_Toggle:OnChanged(function(enabled)
        if enabled then
            start()
        else
            stop()
        end
    end)

    table.insert(teardownTasks, stop)
end

-- [World / Radioactive Zone] Damage triggers, smoke, and the blocking geometry
do
    local touchOriginals = {} -- [BasePart] = CanTouch the map gave it
    local emitterOriginals = {} -- [Smoke / ParticleEmitter] = Enabled the map gave it
    local removedParents = {} -- [Instance] = the parent it was taken out of

    local function disarm(part: BasePart)
        if touchOriginals[part] == nil then
            touchOriginals[part] = part.CanTouch
        end

        part.CanTouch = false
    end

    local function stop()
        for part, canTouch in pairs(touchOriginals) do
            if part.Parent then
                part.CanTouch = canTouch
            end
        end

        for emitter, wasEnabled in pairs(emitterOriginals) do
            if emitter.Parent then
                emitter.Enabled = wasEnabled
            end
        end

        for instance, parent in pairs(removedParents) do
            pcall(function()
                instance.Parent = parent
            end)
        end

        table.clear(touchOriginals)
        table.clear(emitterOriginals)
        table.clear(removedParents)
    end

    local function start()
        stop()

        local zone = area51:FindFirstChild("RadioactiveArea")

        if not zone then
            notify("Error", "Failed to locate", "Failed to find the Radioactive Zone.", 100)
            return
        end

        -- The two Entrance trigger parts carry the damage script
        for _, child in ipairs(zone:GetChildren()) do
            if child.Name == "Entrance" and child:IsA("BasePart") then
                disarm(child)
            end
        end

        -- The liquid and drip parts also have touch listeners, and the smoke over them is the fog
        local drop = zone:FindFirstChild("RadioactiveDrop")

        if drop then
            for _, descendant in ipairs(drop:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    if descendant:FindFirstChildOfClass("TouchTransmitter") then
                        disarm(descendant)
                    end
                elseif descendant:IsA("Smoke") or descendant:IsA("ParticleEmitter") then
                    emitterOriginals[descendant] = descendant.Enabled
                    descendant.Enabled = false
                end
            end
        end

        -- Barriers, entrance walls, and dirt are taken out of the map and put back into the same container afterwards
        local floor1 = zone:FindFirstChild("Floor1")

        if floor1 then
            for _, containerName in ipairs({ "Barrier", "Entrance", "Dirt" }) do
                local container = floor1:FindFirstChild(containerName)

                if container then
                    for _, child in ipairs(container:GetChildren()) do
                        removedParents[child] = container
                        child.Parent = nil
                    end
                end
            end
        end
    end

    toggles.disableRadioactiveZone_Toggle:OnChanged(function(enabled)
        if enabled then
            start()
        else
            stop()
        end
    end)

    table.insert(teardownTasks, stop)
end

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


-- [World / Door Noclip] Doors turn transparent and stop colliding
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

-- [World / Alien] Code display and navigation actions

local alienCode = area51.CodeModel.Code.Value
unlockAlienGroup:AddLabel("Code: " .. alienCode, true)
unlockAlienGroup:AddDropdown("codeRevealMethod_Dropdown", { Text = "Code Reveal Method", Values = { "Announce", "Silent" }, Default = 2 })
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

unlockAlienGroup:AddSlider("silentModeNotifDuration_Slider", { Text = "Notification Time", Tooltip = "Controls how long the notification will last when using 'Silent.'", Default = 15, Min = 5, Max = 30, Compact = true, Suffix = " Seconds" })
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

-- ============================================================================
-- 13 | TAB: WEAPONS
-- ============================================================================

tabs.weapons:UpdateWarningBox({ Title = "Warning", Text = "Usage of any gun mods has a high chance of resulting in a permanent game ban." })

local weaponsGroup = tabs.weapons:AddGroupbox({ Side = "Left", Name = "Weapons", IconName = assetLib.fetchAsset("Icons/swords.png"), Description = "Obtain and Pack-a-Punch" })
local defenseGroup = tabs.weapons:AddGroupbox({ Side = "Right", Name = "Defense", IconName = assetLib.fetchAsset("Icons/shield.png"), Description = "Armor and morphs" })
local othersGroup = tabs.weapons:AddGroupbox({ Side = "Right", Name = "Other", IconName = assetLib.fetchAsset("Icons/package.png"), Description = "Reload, pickup, gun mods" })

-- [Weapons / Inventory] Weapon catalog, acquisition, and selection

-- [Weapons / Inventory] Restricted weapon rules
local restrictedWeapons = {Crossbow = true, MG42 = true, FreezeGun = true }

-- [Weapons / Inventory] Build the selectable weapon catalog
local weaponNames = {}
local giveWeaponBtn, papWeaponBtn, papHeldBtn

for _, weapon in ipairs(game:GetService("Workspace").Weapons:GetChildren()) do
    table.insert(weaponNames, weapon.Name)
end

weaponsGroup:AddDropdown("weaponsList_Dropdown", { Text = "Obtain Weapon(s)", Values = weaponNames, Multi = true, Searchable = true,
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

weaponsGroup:AddDropdown("giveWeaponMethod_Dropdown", { Text = "Method", Values = { "Touch Events", "ProximityPrompt" }, Default = 1 })

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

weaponsGroup:AddToggle("fireOnRespawn_Toggle", { Text = "Fire On Respawn", Tooltip = "Automatically gives the selected weapons after you respawn." })

localplayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if toggles.fireOnRespawn_Toggle.Value then
        obtainSelectedWeapons()
    end
end)


weaponsGroup:AddToggle("clearOnAction_Toggle", { Text = "Clear on Action", Tooltip = "Clears the selected weapons when you obtain, pack a punch it, etc." })
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

defenseGroup:AddToggle("zombieMorph_Toggle", { Text = "Zombie Morph" })

local zombieMorphDepbox = defenseGroup:AddDependencyBox()

zombieMorphDepbox:AddToggle("disableSelfGlow_Toggle", { Text = "Disable Self Glow", Tooltip = "Disables the green glow from you only." })
zombieMorphDepbox:AddToggle("normalAppearance_Toggle", { Text = "Normal Appearance", Tooltip = "Shows your normal character instead of the zombie morph's green skin. The morph stays worn, only its look is hidden." })

defenseGroup:AddToggle("obtainArmor_Toggle", { Text = "Obtain Armor" })
defenseGroup:AddToggle("obtainHelmet_Toggle", { Text = "Obtain Helmet", Disabled = not (getMode() == "Extreme"), DisabledTooltip = "This feature is not available in this mode." })

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

    local function refreshMorphAppearance(char: any)
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

    local function watchDeath(char: any)
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

othersGroup:AddToggle("autoReloadWeapons_Toggle", { Text = "Auto Reload" })

local autoReloadDepbox = othersGroup:AddDependencyBox()
autoReloadDepbox:AddSlider("autoReloadDelay_Slider", { Text = "Delay", Default = 1, Min = 0.5, Max = 10, Suffix = " Second", Rounding = 1,
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

    othersGroup:AddToggle("autoPickupWeapons_Toggle", { Text = "Auto Pickup Weapons", Tooltip = "Automatically picks your weapon back up when the Alien's arm steals it. Only your own weapons are picked up.", Disabled = not pickupAllowed, DisabledTooltip = "This feature is not available in this mode." })

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

    local function pickupStolenWeapon(model: any)
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

        -- A weapon may already be lying around from before the toggle was enabled
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
gunModsDepbox:AddToggle("infiniteAmmoGunMod_Toggle", { Text = "Infinite Ammo", Risky = true })
gunModsDepbox:AddToggle("fullAutoGunMod_Toggle", { Text = "Fully Automatic", Risky = true })
gunModsDepbox:AddToggle("fireRateGunMod_Toggle", { Text = "Rapid Fire", Risky = true })
gunModsDepbox:AddToggle("noOverheatGunMod_Toggle", { Text = "Flamethrower: No Overheat", Tooltip = "Stops the Flamethrower from building heat, so it can be held down for as long as you like with no overheat lockout and no re-press delay. Pair with Infinite Ammo for unlimited gas.", Risky = true })
gunModsDepbox:AddToggle("noBoltGunMod_Toggle", { Text = "Disable Sniper Bolt", Tooltip = "Skips the bolt-action animation after each shot so Snipers can fire rapidly. Pair with Rapid Fire.", Risky = true })
gunModsDepbox:AddToggle("noRecoilGunMod_Toggle", { Text = "No Recoil", Tooltip = "Removes the camera kick when firing.", Risky = true })
gunModsDepbox:AddToggle("noSpreadGunMod_Toggle", { Text = "No Spread", Tooltip = "Removes bullet inaccuracy/spreading out.", Risky = true })
gunModsDepbox:AddToggle("fastReloadGunMod_Toggle", { Text = "Fast Reload", Tooltip = "Shortens reload (and bolt) animations to a fraction of their normal time.", Risky = true })
gunModsDepbox:AddSlider("bulletCountGunMod_Slider", { Text = "Bullet Count", Default = 1, Min = 1, Max = 100, Suffix = " Bullet", Risky = true,
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

    -- Already hot when the mod was enabled: cool it down immediately.
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

-- Runs from unloadModules() after every toggle has been disabled; the final reconcile is for safety.
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
    local skinGroup = tabs.weapons:AddGroupbox({ Side = "Left", Name = "Skin Changer", IconName = assetLib.fetchAsset("Icons/palette.png"), Description = "Local weapon skins" })
    local replicatedStorage = game:GetService("ReplicatedStorage")

    local skinUtilities: any, skinList: any
    local loaded, loadError = pcall(function()
        skinUtilities = require(replicatedStorage:WaitForChild("Utilities", 10))
        skinList = (require(replicatedStorage:WaitForChild("Constants", 10):WaitForChild("Skins", 10)) :: any).SKINS
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
    skinGroup:AddDropdown("skinChangerSkin_Dropdown", { Text = "Skin", Tooltip = "Every skin from the game's own skin list. Search by typing.", Values = skinNames, Searchable = true,
        Callback = function(val)
            state.skin = val

            if state.auto then
                reapplyAll()
            end
        end,
    })

    skinGroup:AddDropdown("skinChangerTarget_Dropdown", { Text = "Apply To", Tooltip = "Which weapon(s) get the skin.", Values = { "Equipped weapon", "All weapons" }, Default = 1,
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

    skinGroup:AddToggle("skinChangerAuto_Toggle", { Text = "Auto Re-apply", Tooltip = "Keeps the skin on after equipping, respawning, loadout changes, or picking up weapons.",
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

local othersGroup2 = tabs.misc:AddGroupbox({ Side = "Left", Name = "Others", IconName = assetLib.fetchAsset("Icons/ellipsis.png"), Description = "Spam and keycards" })

-- [Miscellaneous / Other] Keycards, teleport actions, and weapon spam

-- [Miscellaneous / Weapon Spam] Repeated equip/unequip cycle
othersGroup2:AddToggle("weaponSpam_Toggle", { Text = "Weapon Spam" })
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

local menuGroup = tabs.uiSettings:AddGroupbox({ Side = "Left", Name = "Menu", IconName = assetLib.fetchAsset("Icons/settings.png"), Description = "Menu look and keybinds" })
local sessionInfoGroup = tabs.uiSettings:AddGroupbox({ Side = "Right", Name = "Overlay", IconName = assetLib.fetchAsset("Icons/monitor.png"), Description = "Session Info overlay", Collapsed = false, DisableCollapsing = false })

menuGroup:AddToggle("openKeybindMenu_Toggle", { Text = "Open Keybind Menu", Default = window.keybindFrameEnabled, Callback = function(enabled) library.KeybindFrame.Visible = enabled end })
menuGroup:AddToggle("configKeybinds_Toggle", { Text = "Keybind Menu Visibility", Tooltip = "Show or hide specific keybinds.", Visible = false, Callback = function(enabled) library.KeybindMenu:SetVisibilityControl(enabled) end })
menuGroup:AddToggle("autoResetColor_Toggle", { Text = "Auto Reset Color", Tooltip = "Resets the colorpicker color back to its default color once a rainbow toggle is disabled.", Default = true,
    Callback = function(Value) window.autoResetRainbowColor = Value end })
menuGroup:AddToggle("alwaysOnTop_Toggle", { Text = "Always On Top", Default = window.AlwaysOnTop, Tooltip = "Places the window over all Roblox GUI.", Callback = function(enabled) window:SetAlwaysOnTop(enabled) end })
menuGroup:AddToggle("notifSound_Toggle", { Text = "Notification Alert Sounds", Default = true, Callback = function(enabled) window.notifSoundEnabled = enabled end })

local notifSoundDepbox = menuGroup:AddDependencyBox()
notifSoundDepbox:AddSlider("notifAlertVolume_Slider", { Text = "Alert Volume", Default = 1, Min = 0.1, Max = 6, Rounding = 1 })
notifSoundDepbox:AddDivider()

notifSoundDepbox:SetupDependencies({ { toggles.notifSound_Toggle, true } })

menuGroup:AddDropdown("NotificationSide", { Text = "Notification Side", Values = { "Left", "Right" }, Default = "Right", Callback = function(val) library:SetNotifySide(val) end })
menuGroup:AddDropdown("DPIDropdown", { Text = "DPI Scale", Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = 3,
    Callback = function(val)
        val = val:gsub("%%", "")
        local dpi = tonumber(val)
        if dpi then
            library:SetDPIScale(dpi)
        end
    end,
})
menuGroup:AddSlider("cornerRadius_Slider", { Text = "Corner Radius", Default = library.CornerRadius, Min = 0, Max = 20, Callback = function(val) window:SetCornerRadius(val) end })

menuGroup:AddSlider("rainbowSpeed_Slider", { Text = "Rainbow Speed", Default = window.rainbowSpeed, Min = 0.1, Max = 1, Rounding = 1 })
menuGroup:AddLabel("Menu bind"):AddKeyPicker("menuKeybind_KeyPicker", { Text = "Menu keybind", Default = "RightControl", NoUI = true })

-- [UI Settings / Session Info] Draggable overlay with live stats for the current session
do
    local sessionInfoToggle = sessionInfoGroup:AddToggle("sessionInfo_Toggle", { Text = "Session Info", Tooltip = "Shows a draggable overlay with live stats for this session." })
    local sessionInfoSettings = sessionInfoToggle:AddSettings({ Width = 300 })

    local function buildSessionInfoOverlay()
        local sessionInfo = {
            loadStart = os.clock(), -- Elapsed Time counts from here (script load, or the last Reset Timer / Reset Session)
            deathStart = nil, -- When the last death happened, for Elapsed Time's "Since last death" mode
            label = nil,
            loopToken = nil,
            lastText = nil,
            needs = {} :: { [string]: boolean },

            -- Trackers
            renderConnection = nil,
            characterTracker = nil,
            characterSignature = nil,
            bulletTracker = nil :: any,

            -- FPS
            frames = 0,
            frameStamp = os.clock(),
            fps = 0,
            fpsPeak = nil,
            fpsLow = nil,
            fpsBelow = false, -- Already told the player about the current FPS drop
            fpsNotifyStamp = 0,

            -- Ping
            ping = nil,
            pingPeak = nil,
            pingLow = nil,
            pingAbove = false, -- Already told the player about the current ping spike
            pingNotifyStamp = 0,

            -- Session stats
            kills = 0,
            killStat = nil,
            killBaseline = nil,
            killsAvailable = true,
            killTrackedTime = 0, -- Seconds the Kills tracker has been running, for Kills per Minute
            lifeKills = 0, -- Kills since the last death
            syntheticKills = 0, -- Kills made through Disable Aura (and its Emergency Kill)
            lifeSyntheticKills = 0,
            syntheticPending = {}, -- When each Synthetic Kill happened, until the server credits it or the window runs out
            affectedKillers = 0, -- Different killers Disable Aura has affected
            affectedSeen = setmetatable({}, { __mode = "k" }), -- Killers already counted, so none is counted twice
            streakPeak = 0, -- Highest number of kills in one life (only the kills you made yourself)
            streakPeakCombined = 0, -- The same, with the Synthetic Kills of that life added
            syntheticModels = setmetatable({}, { __mode = "k" }), -- When Disable Aura last killed each killer, so that kill is not counted as Damage Dealt
            deaths = 0,
            bullets = 0, -- Every pellet that was fired
            shots = 0, -- Shots fired, where a whole shotgun blast adds exactly 1
            bulletsAvailable = true,
            lastShot = -math.huge, -- When your last shot or explosive hit was sent, for Damage Dealt
            damageDealt = 0,
            dealtTracker = nil :: any,
            dealtAvailable = true,
            damage = 0,
            mostDamage = 0,
            damageByKiller = {} :: { [string]: number }, -- Health lost near each Killer, for the Top Killer mode
            lifeStart = nil,
            livesCompleted = 0, -- Lives that ended while Survival Time was tracked
            livesTotal = 0, -- Seconds survived across those lives

            -- Killer scan results (refreshed every update while a killer line is shown)
            scan = { nearestName = nil, nearestDistance = nil, owned = nil },
        }

        local COLOR_GOOD = Color3.fromRGB(90, 220, 120)
        local COLOR_WARN = Color3.fromRGB(255, 205, 80)
        local COLOR_BAD = Color3.fromRGB(255, 95, 95)

        -- Thresholds for the Adaptive colors
        local FPS_GOOD, FPS_WARN = 60, 30
        local PING_GOOD, PING_WARN = 80, 150
        local HEALTH_GOOD, HEALTH_WARN = 0.6, 0.3

        -- How long between two notifications of the same kind, and how far away a Killer can be and still be blamed for damage.
        local NOTIFY_COOLDOWN = 4
        local DAMAGE_SOURCE_RANGE = 40

        -- Forward declarations, assigned below once everything they use exists.
        local updateSessionInfoLabel
        local rebuildSessionInfoText
        local refreshSessionInfo

        local function getOption(id, fallback)
            local option = options[id]

            if option ~= nil and option.Value ~= nil then
                return option.Value
            end

            return fallback
        end

        local function getToggle(id, fallback)
            local toggle = toggles[id]

            if toggle ~= nil and toggle.Value ~= nil then
                return toggle.Value == true
            end

            return fallback
        end

        local function escapeRichText(text)
            return (tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
        end

        local function paint(text, color)
            return string.format("<font color=\"#%s\">%s</font>", color:ToHex(), text)
        end

        local function colorHigherIsBetter(value, goodAt, warnAt)
            if value >= goodAt then
                return COLOR_GOOD
            elseif value >= warnAt then
                return COLOR_WARN
            end

            return COLOR_BAD
        end

        local function colorLowerIsBetter(value, goodAt, warnAt)
            if value <= goodAt then
                return COLOR_GOOD
            elseif value <= warnAt then
                return COLOR_WARN
            end

            return COLOR_BAD
        end

        -- "short" shows only the units that are not zero (36s, 12m, 36s, 1h, 5s), "clock" is 00:12:36 and "compact" is the total seconds.
        local function formatSessionTime(totalSeconds, style)
            totalSeconds = math.max(0, math.floor(totalSeconds))

            local hours = totalSeconds // 3600
            local minutes = (totalSeconds % 3600) // 60
            local seconds = totalSeconds % 60

            if style == "clock" then
                return string.format("%02d:%02d:%02d", hours, minutes, seconds)
            end

            if style == "compact" then
                return totalSeconds .. "s"
            end

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

        -- Rounding dropdown shared by the damage lines: "Whole numbers" or "One decimal"
        local function formatDamageNumber(value, optionId)
            if getOption(optionId, "Whole numbers") == "One decimal" then
                return string.format("%.1f", value)
            end

            return roundSessionNumber(value)
        end

        -- How long the server has to credit a Synthetic Kill to Killers Killed. A credited one is the same kill, so it is never counted twice.
        local SYNTHETIC_CREDIT_WINDOW = 3

        -- Takes the kills the server credited right after a Synthetic Kill out of the normal count, and returns how many were taken.
        local function claimSyntheticCredits(gained)
            local pending = sessionInfo.syntheticPending
            local now = os.clock()

            while pending[1] and now - pending[1] > SYNTHETIC_CREDIT_WINDOW do
                table.remove(pending, 1)
            end

            local claimed = math.min(gained, #pending)

            for _ = 1, claimed do
                table.remove(pending, 1)
            end

            return claimed
        end

        -- Kills, Kills per Minute, K/D Ratio and Bullets Per Kill all use this. Synthetic Kills are only added while their option is on.
        local function getSessionInfoKills(thisLifeOnly)
            local kills = thisLifeOnly and sessionInfo.lifeKills or sessionInfo.kills

            if getToggle("sessionInfoSyntheticKills_Toggle", false) then
                kills += thisLifeOnly and sessionInfo.lifeSyntheticKills or sessionInfo.syntheticKills
            end

            return kills
        end

        -- Highest Kill Streak: the best kill count of any single life. Called whenever a life's kills go up.
        local function updateKillStreakPeaks()
            sessionInfo.streakPeak = math.max(sessionInfo.streakPeak, sessionInfo.lifeKills)
            sessionInfo.streakPeakCombined = math.max(sessionInfo.streakPeakCombined, sessionInfo.lifeKills + sessionInfo.lifeSyntheticKills)
        end

        local function getElapsedSeconds()
            local now = os.clock()

            if getOption("sessionInfoElapsedMode_Dropdown", "") == "Since last death" and sessionInfo.deathStart then
                return now - sessionInfo.deathStart
            end

            return now - sessionInfo.loadStart
        end

        local function getTimeStyle()
            local value = tostring(getOption("sessionInfoElapsedFormat_Dropdown", "Short"))

            return (value:match("^(%a+)") or "short"):lower()
        end

        local function getCurrentLifeSeconds()
            return sessionInfo.lifeStart and (os.clock() - sessionInfo.lifeStart) or 0
        end

        -- Pellets or whole blasts, depending on the Count Every Pellet option.
        local function getSessionInfoBullets()
            if getToggle("sessionInfoBulletsPellets_Toggle", true) then
                return sessionInfo.bullets
            end

            -- A blast adds 1 / pellets per pellet, so the sum can be slightly under a whole number
            return math.floor(sessionInfo.shots + 0.0001)
        end

        local function getTopKiller()
            local topName, topDamage = nil, 0

            for name, total in pairs(sessionInfo.damageByKiller) do
                if total > topDamage then
                    topName, topDamage = name, total
                end
            end

            return topName
        end

        -- Value of an FPS / Ping line: the current reading, and the highest and lowest of this session when they are enabled.
        local function buildReadingValue(prefix, current, peak, low, colorFor)
            local adaptive = getToggle(prefix .. "Adaptive_Toggle", false)
            local showMax = getToggle(prefix .. "Max_Toggle", false)
            local showMin = getToggle(prefix .. "Min_Toggle", false)
            -- With nothing else enabled on the line, we still have to show something
            local showCurrent = getToggle(prefix .. "Current_Toggle", true) or (not showMax and not showMin)

            local function reading(value)
                if not value then
                    return "..."
                end

                local text = roundSessionNumber(value)

                return adaptive and paint(text, colorFor(value)) or text
            end

            local parts = {}

            if showCurrent then
                table.insert(parts, reading(current))
            end

            if showMax then
                table.insert(parts, "↑" .. reading(peak))
            end

            if showMin then
                table.insert(parts, "↓" .. reading(low))
            end

            return table.concat(parts, " ")
        end

        local function fpsColor(value)
            return colorHigherIsBetter(value, FPS_GOOD, FPS_WARN)
        end

        local function pingColor(value)
            return colorLowerIsBetter(value, PING_GOOD, PING_WARN)
        end

        -- Order here is the order the lines appear in. "needs" lists the trackers a line depends on.
        local sessionInfoItems = {
            { id = "Elapsed", text = "Elapsed Time", default = true, tooltip = "How long the script has been running, or how long since your last death.",
                needs = function()
                    return getOption("sessionInfoElapsedMode_Dropdown", "") == "Since last death" and { "deaths" } or {}
                end,
                settings = function(settings)
                    settings:AddDropdown("sessionInfoElapsedMode_Dropdown", { Text = "Tracking Mode", Values = { "Since script load", "Since last death" }, Default = 1,
                        Tooltip = "Since script load counts from when the script started (or from the last reset). Since last death restarts every time you die." })
                    settings:AddDropdown("sessionInfoElapsedFormat_Dropdown", { Text = "Time Format", Values = { "Short (12m, 36s)", "Clock (00:12:36)", "Compact (756s)" }, Default = 1 })
                    settings:AddButton({ Text = "Reset Timer", Tooltip = "Restarts only the timer. Reset Session restarts everything.", Func = function()
                        sessionInfo.loadStart = os.clock()
                        sessionInfo.deathStart = nil
                        rebuildSessionInfoText()
                    end })
                end,
                value = function() return formatSessionTime(getElapsedSeconds(), getTimeStyle()) end },

            { id = "Kills", text = "Kills", default = true, needs = { "kills" }, tooltip = "Killers you killed this session.",
                getText = function()
                    return getOption("sessionInfoKillsMode_Dropdown", "") == "Kills per minute" and "Kills/Min" or "Kills"
                end,
                settings = function(settings)
                    settings:AddDropdown("sessionInfoKillsMode_Dropdown", { Text = "Tracking Mode", Values = { "Session kills", "Kills per minute" }, Default = 1,
                        Tooltip = "Kills per minute is your kills divided by the time Kills has been tracked." })
                    settings:AddToggle("sessionInfoSyntheticKills_Toggle", { Text = "Synthetic Kills", Default = false, Tooltip = "Also counts the kills Disable Aura makes itself (the Kill method and Emergency Kill) in Kills, K/D Ratio and Bullets Per Kill. Off by default, so only kills you get yourself are counted." })
                end,
                value = function()
                    if not sessionInfo.killsAvailable then
                        return "N/A"
                    end

                    if getOption("sessionInfoKillsMode_Dropdown", "") == "Kills per minute" then
                        local minutes = sessionInfo.killTrackedTime / 60

                        if minutes <= 0 then
                            return "0.00"
                        end

                        return string.format("%.2f", getSessionInfoKills(false) / minutes)
                    end

                    return tostring(getSessionInfoKills(false))
                end },

            { id = "Deaths", text = "Deaths", default = true, needs = { "deaths" }, tooltip = "Times you died this session.",
                value = function() return tostring(sessionInfo.deaths) end },

            { id = "KD", text = "K/D Ratio", needs = { "kills", "deaths" }, tooltip = "Kills divided by deaths. Follows the Synthetic Kills option under Kills.",
                settings = function(settings)
                    settings:AddDropdown("sessionInfoKDDecimals_Dropdown", { Text = "Decimal Places", Values = { "0", "1", "2" }, Default = 3 })
                    settings:AddDropdown("sessionInfoKDMode_Dropdown", { Text = "Tracking Mode", Values = { "This session", "This life" }, Default = 1,
                        Tooltip = "This life only counts the kills you made since your last death, and every death starts a new one." })
                end,
                value = function()
                    if not sessionInfo.killsAvailable then
                        return "N/A"
                    end

                    local decimals = tonumber(getOption("sessionInfoKDDecimals_Dropdown", "2")) or 2
                    local ratio

                    if getOption("sessionInfoKDMode_Dropdown", "") == "This life" then
                        -- A life ends with exactly one death, so its ratio is simply the kills made in it
                        ratio = getSessionInfoKills(true)
                    else
                        ratio = getSessionInfoKills(false) / math.max(sessionInfo.deaths, 1)
                    end

                    return string.format("%." .. decimals .. "f", ratio)
                end },

            { id = "KillStreak", text = "Highest Kill Streak", needs = { "kills", "deaths" }, tooltip = "The most kills you made in a single life this session. Every death ends the streak, but the highest one is kept.",
                value = function()
                    if not sessionInfo.killsAvailable then
                        return "N/A"
                    end

                    return tostring(getToggle("sessionInfoSyntheticKills_Toggle", false) and sessionInfo.streakPeakCombined or sessionInfo.streakPeak)
                end },

            { id = "Bullets", text = "Bullets Fired", needs = function()
                    return getOption("sessionInfoBulletsMode_Dropdown", "") == "Bullets per kill" and { "bullets", "kills" } or { "bullets" }
                end,
                tooltip = "Bullets you fired this session.",
                getText = function()
                    return getOption("sessionInfoBulletsMode_Dropdown", "") == "Bullets per kill" and "Bullets Per Kill" or "Bullets Fired"
                end,
                settings = function(settings)
                    settings:AddToggle("sessionInfoBulletsPellets_Toggle", { Text = "Count Every Pellet", Default = true,
                        Tooltip = "On: every pellet of a shotgun blast counts as a bullet. Off: a whole blast counts as one shot." })
                    settings:AddDropdown("sessionInfoBulletsMode_Dropdown", { Text = "Tracking Mode", Values = { "Bullets fired", "Bullets per kill" }, Default = 1,
                        Tooltip = "Bullets per kill is your bullets divided by your kills, a rough accuracy-style stat. Follows the Synthetic Kills option under Kills." })
                end,
                value = function()
                    if not sessionInfo.bulletsAvailable then
                        return "N/A"
                    end

                    if getOption("sessionInfoBulletsMode_Dropdown", "") == "Bullets per kill" then
                        if not sessionInfo.killsAvailable then
                            return "N/A"
                        end

                        local kills = getSessionInfoKills(false)

                        if kills <= 0 then
                            return "N/A"
                        end

                        return string.format("%.1f", getSessionInfoBullets() / kills)
                    end

                    return tostring(getSessionInfoBullets())
                end },

            { id = "DamageDealt", text = "Damage Dealt", needs = { "dealt" }, tooltip = "Health the Killers lost from your shots this session. Damage that other players deal at the same moment can be included, and the kills Disable Aura makes itself are left out.",
                settings = function(settings)
                    settings:AddDropdown("sessionInfoDamageDealtRounding_Dropdown", { Text = "Rounding", Values = { "Whole numbers", "One decimal" }, Default = 1 })
                end,
                value = function()
                    if not sessionInfo.bulletsAvailable or not sessionInfo.dealtAvailable then
                        return "N/A"
                    end

                    return formatDamageNumber(sessionInfo.damageDealt, "sessionInfoDamageDealtRounding_Dropdown")
                end },

            { id = "Damage", text = "Damage Taken", needs = { "damage" }, tooltip = "Total health you lost this session.",
                settings = function(settings)
                    settings:AddDropdown("sessionInfoDamageRounding_Dropdown", { Text = "Rounding", Values = { "Whole numbers", "One decimal" }, Default = 1 })
                end,
                value = function() return formatDamageNumber(sessionInfo.damage, "sessionInfoDamageRounding_Dropdown") end },

            { id = "MostDamage", text = "Most Damage Taken", needs = { "damage" }, tooltip = "The most health you lost in a single hit this session, or the Killer that dealt you the most damage.",
                settings = function(settings)
                    settings:AddDropdown("sessionInfoMostDamageMode_Dropdown", { Text = "Tracking Mode", Values = { "Biggest hit", "Top Killer" }, Default = 1,
                        Tooltip = "Top Killer shows the name of the Killer that dealt you the most damage. Damage is given to the closest living Killer within " .. DAMAGE_SOURCE_RANGE .. " studs (one that is attacking comes first), so damage from anything else is not counted." })
                    settings:AddDropdown("sessionInfoMostDamageRounding_Dropdown", { Text = "Rounding", Values = { "Whole numbers", "One decimal" }, Default = 1 })
                end,
                value = function()
                    if getOption("sessionInfoMostDamageMode_Dropdown", "") == "Top Killer" then
                        return escapeRichText(getTopKiller() or "None")
                    end

                    return formatDamageNumber(sessionInfo.mostDamage, "sessionInfoMostDamageRounding_Dropdown")
                end },

            { id = "Survival", text = "Survival Time", needs = { "survival" }, tooltip = "How long you have been alive since your last death, or your average across lives.",
                getText = function()
                    return getOption("sessionInfoSurvivalMode_Dropdown", "") == "Average across lives" and "Avg. Survival Time" or "Survival Time"
                end,
                settings = function(settings)
                    settings:AddDropdown("sessionInfoSurvivalMode_Dropdown", { Text = "Tracking Mode", Values = { "Current life", "Average across lives" }, Default = 1,
                        Tooltip = "Average across lives is the average time you survived in the lives that ended. Until you die for the first time it shows your current life." })
                end,
                value = function()
                    if getOption("sessionInfoSurvivalMode_Dropdown", "") == "Average across lives" and sessionInfo.livesCompleted > 0 then
                        return formatSessionTime(sessionInfo.livesTotal / sessionInfo.livesCompleted)
                    end

                    return formatSessionTime(getCurrentLifeSeconds())
                end },

            { id = "Health", text = "Health", tooltip = "Your current health.",
                settings = function(settings)
                    settings:AddDropdown("sessionInfoHealthDisplay_Dropdown", { Text = "Health Display", Values = { "Current / Max", "Percentage" }, Default = 1 })
                    settings:AddToggle("sessionInfoHealthAdaptive_Toggle", { Text = "Adaptive", Default = false, Tooltip = "Colors the text green, yellow or red by how much health you have left." })
                end,
                value = function()
                    local character = localplayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                    if not humanoid then
                        return "N/A"
                    end

                    local fraction = humanoid.MaxHealth > 0 and (humanoid.Health / humanoid.MaxHealth) or 0
                    local text

                    if getOption("sessionInfoHealthDisplay_Dropdown", "") == "Percentage" then
                        text = roundSessionNumber(fraction * 100) .. "%"
                    else
                        text = roundSessionNumber(humanoid.Health) .. "/" .. roundSessionNumber(humanoid.MaxHealth)
                    end

                    if getToggle("sessionInfoHealthAdaptive_Toggle", false) then
                        return paint(text, colorHigherIsBetter(fraction, HEALTH_GOOD, HEALTH_WARN))
                    end

                    return text
                end },

            { id = "NearestKiller", text = "Nearest Killer", needs = { "nearest" }, tooltip = "The closest living killer and how far away it is.",
                value = function()
                    local scan = sessionInfo.scan

                    if not scan.nearestName then
                        return "None"
                    end

                    return escapeRichText(scan.nearestName) .. " (" .. roundSessionNumber(scan.nearestDistance) .. " studs)"
                end },

            { id = "SimulatedKillers", text = "Simulated Killers", needs = { "owned" }, tooltip = "How many living killers your client owns the physics of. Those are the ones your client can control and can be affected via Disable Aura.",
                value = function() return sessionInfo.scan.owned ~= nil and tostring(sessionInfo.scan.owned) or "N/A" end },

            { id = "AffectedKillers", text = "Affected Killers", needs = { "affected" }, tooltip = "How many different killers Disable Aura has affected this session, whatever the method (killed, slowed, disabled or pushed).",
                value = function() return tostring(sessionInfo.affectedKillers) end },

            { id = "FPS", text = "FPS", default = true, needs = { "fps" }, tooltip = "Frames per second, measured over the update interval.",
                settings = function(settings)
                    settings:AddSlider("sessionInfoFPSInterval_Slider", { Text = "Update Interval", Default = 1, Min = 0.5, Max = 2, Rounding = 1, Suffix = "s",
                        Tooltip = "How often the FPS is measured. A longer interval is smoother, a shorter one reacts faster." })
                    settings:AddToggle("sessionInfoFPSAdaptive_Toggle", { Text = "Adaptive", Default = false, Tooltip = "Colors the numbers green, yellow or red by how high the FPS is." })
                    settings:AddToggle("sessionInfoFPSCurrent_Toggle", { Text = "Show Current", Default = true, Tooltip = "Shows the current FPS. Turn it off to only show the highest and lowest." })
                    settings:AddToggle("sessionInfoFPSMax_Toggle", { Text = "Maximum", Default = false, Tooltip = "Shows the highest FPS of this session, like ↑304." })
                    settings:AddToggle("sessionInfoFPSMin_Toggle", { Text = "Minimum", Default = false, Tooltip = "Shows the lowest FPS of this session, like ↓54." })

                    local notifyToggle = settings:AddToggle("sessionInfoFPSNotify_Toggle", { Text = "Notify on Low FPS", Default = false, Tooltip = "Sends a notification when the FPS drops below the threshold, so you can spot big FPS drops." })
                    local notifySettings = notifyToggle:AddSettings({ Width = 240 })
                    notifySettings:AddSlider("sessionInfoFPSThreshold_Slider", { Text = "Threshold", Default = 30, Min = 5, Max = 240, Rounding = 0, Suffix = " FPS" })
                end,
                value = function() return buildReadingValue("sessionInfoFPS", sessionInfo.fps > 0 and sessionInfo.fps or nil, sessionInfo.fpsPeak, sessionInfo.fpsLow, fpsColor) end },

            { id = "Ping", text = "Ping", default = true, needs = { "ping" }, tooltip = "Round-trip time to the server in milliseconds.",
                settings = function(settings)
                    settings:AddToggle("sessionInfoPingAdaptive_Toggle", { Text = "Adaptive", Default = false, Tooltip = "Colors the numbers green, yellow or red by how low the ping is." })
                    settings:AddToggle("sessionInfoPingCurrent_Toggle", { Text = "Show Current", Default = true, Tooltip = "Shows the current ping. Turn it off to only show the highest and lowest." })
                    settings:AddToggle("sessionInfoPingMax_Toggle", { Text = "Maximum", Default = false, Tooltip = "Shows the highest ping of this session, like ↑56." })
                    settings:AddToggle("sessionInfoPingMin_Toggle", { Text = "Minimum", Default = false, Tooltip = "Shows the lowest ping of this session, like ↓12." })

                    local notifyToggle = settings:AddToggle("sessionInfoPingNotify_Toggle", { Text = "Notify on High Ping", Default = false, Tooltip = "Sends a notification when the ping goes above the threshold, so you can spot ping spikes." })
                    local notifySettings = notifyToggle:AddSettings({ Width = 240 })
                    notifySettings:AddSlider("sessionInfoPingThreshold_Slider", { Text = "Threshold", Default = 200, Min = 50, Max = 1000, Rounding = 0, Suffix = " ms" })
                end,
                value = function() return buildReadingValue("sessionInfoPing", sessionInfo.ping, sessionInfo.pingPeak, sessionInfo.pingLow, pingColor) end },
        }

        -- [Session Info / Menu]
        local compactToggle = sessionInfoSettings:AddToggle("sessionInfoCompact_Toggle", { Text = "Compact Mode", Tooltip = "Shows everything on a single line, split up by the separator, instead of one line per stat." })
        local compactSettings = compactToggle:AddSettings({ Width = 260 })
        compactSettings:AddDropdown("sessionInfoSeparator_Dropdown", { Text = "Separator", Tooltip = "What goes between each stat in Compact Mode.", Values = { "•  | Bullet point", "■  | Black square", "- | Hyphen",
            "►  | Black Pointer", "→  | Rightwards Arrow", }, Default = 1 })

        sessionInfoSettings:AddDivider()
        sessionInfoSettings:AddLabel("Displayed information")

        for _, item in ipairs(sessionInfoItems) do
            item.toggleId = "sessionInfo" .. item.id .. "_Toggle"
            local itemToggle = sessionInfoSettings:AddToggle(item.toggleId, { Text = item.text, Tooltip = item.tooltip, Default = item.default })

            if item.settings then
                item.settings(itemToggle:AddSettings({ Width = 280 }))
            end
        end

        local function isSessionInfoItemEnabled(item)
            local toggle = toggles[item.toggleId]

            return toggle ~= nil and toggle.Value == true
        end

        local function getSessionInfoNeeds()
            local needs = {}

            for _, item in ipairs(sessionInfoItems) do
                if item.needs and isSessionInfoItemEnabled(item) then
                    local list = type(item.needs) == "function" and item.needs() or item.needs

                    for _, need in ipairs(list) do
                        needs[need] = true
                    end
                end
            end

            return needs
        end

        -- [Session Info / Notifications]
        local function notifyReading(kind, title, description)
            local stampKey = kind .. "NotifyStamp"
            local now = os.clock()

            if now - sessionInfo[stampKey] < NOTIFY_COOLDOWN then
                return
            end

            sessionInfo[stampKey] = now
            pcall(notify, "Warning", title, description, 10)
        end

        -- A notification is sent once when the reading crosses the threshold, and again only after it has recovered.
        local function checkFpsThreshold(value)
            if not getToggle("sessionInfoFPSNotify_Toggle", false) then
                sessionInfo.fpsBelow = false
                return
            end

            local threshold = tonumber(getOption("sessionInfoFPSThreshold_Slider", 30)) or 30

            if value < threshold then
                if not sessionInfo.fpsBelow then
                    notifyReading("fps", "Low FPS", string.format("FPS dropped to %s (below %s).", roundSessionNumber(value), roundSessionNumber(threshold)))
                end

                sessionInfo.fpsBelow = true
            else
                sessionInfo.fpsBelow = false
            end
        end

        local function checkPingThreshold(value)
            if not getToggle("sessionInfoPingNotify_Toggle", false) then
                sessionInfo.pingAbove = false
                return
            end

            local threshold = tonumber(getOption("sessionInfoPingThreshold_Slider", 200)) or 200

            if value > threshold then
                if not sessionInfo.pingAbove then
                    notifyReading("ping", "High Ping", string.format("Ping spiked to %s ms (above %s ms).", roundSessionNumber(value), roundSessionNumber(threshold)))
                end

                sessionInfo.pingAbove = true
            else
                sessionInfo.pingAbove = false
            end
        end

        -- [Session Info / Trackers]

        -- FPS and kills share one RenderStepped connection, and each only does its work while its line is shown.
        local function sessionInfoRenderStep(deltaTime)
            if sessionInfo.needs.fps then
                local now = os.clock()
                sessionInfo.frames += 1

                local elapsed = now - sessionInfo.frameStamp
                local interval = tonumber(getOption("sessionInfoFPSInterval_Slider", 1)) or 1

                if elapsed >= interval then
                    local fps = sessionInfo.frames / elapsed
                    sessionInfo.fps = fps
                    sessionInfo.frames = 0
                    sessionInfo.frameStamp = now

                    sessionInfo.fpsPeak = math.max(sessionInfo.fpsPeak or fps, fps)
                    sessionInfo.fpsLow = math.min(sessionInfo.fpsLow or fps, fps)
                    checkFpsThreshold(fps)
                end
            end

            if sessionInfo.needs.kills then
                sessionInfo.killTrackedTime += deltaTime

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
                        local gained = total - baseline

                        -- A kill the server credits right after a Synthetic Kill is that same kill, so it is not also counted as a normal one
                        local normal = gained - claimSyntheticCredits(gained)
                        sessionInfo.kills += normal
                        sessionInfo.lifeKills += normal
                        updateKillStreakPeaks()
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

        -- Health lost can only be blamed on a Killer that is close enough; one that is attacking comes before one that is merely near.
        local function findDamageSource()
            local folder = killersFolder

            if not folder or not folder.Parent then
                folder = workspace:FindFirstChild("Killers")
            end

            local character = localplayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if not folder or not root then
                return nil
            end

            local nearestName, nearestDistance
            local attackingName, attackingDistance

            for _, killer in ipairs(folder:GetChildren()) do
                local humanoid = killer:FindFirstChildOfClass("Humanoid")
                local killerRoot = killer:FindFirstChild("HumanoidRootPart") or killer.PrimaryPart

                if humanoid and humanoid.Health > 0 and killerRoot then
                    local distance = (killerRoot.Position - root.Position).Magnitude

                    if distance <= DAMAGE_SOURCE_RANGE then
                        local attacking = killer:FindFirstChild("Attacking")

                        if attacking and attacking:IsA("BoolValue") and attacking.Value and (not attackingDistance or distance < attackingDistance) then
                            attackingName, attackingDistance = killer.Name, distance
                        end

                        if not nearestDistance or distance < nearestDistance then
                            nearestName, nearestDistance = killer.Name, distance
                        end
                    end
                end
            end

            return attackingName or nearestName
        end

        -- Deaths, damage and survival time all hang off the character, so they share one tracker that is rebuilt when the set changes.
        local function getCharacterSignature(needs)
            return (needs.deaths and "d" or "") .. (needs.damage and "a" or "") .. (needs.survival and "s" or "")
        end

        local function startSessionInfoCharacterTracker(needs)
            stopSessionInfoCharacterTracker()

            local tracker = { connections = {}, humanoidConnections = {} }
            sessionInfo.characterTracker = tracker
            sessionInfo.characterSignature = getCharacterSignature(needs)

            local function attach(character: any, newLife: boolean?)
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

                            local source = findDamageSource()

                            if source then
                                sessionInfo.damageByKiller[source] = (sessionInfo.damageByKiller[source] or 0) + lost
                            end
                        end
                    end))
                end

                table.insert(tracker.humanoidConnections, humanoid.Died:Connect(function()
                    local now = os.clock()

                    if needs.deaths then
                        sessionInfo.deaths += 1
                    end

                    if needs.survival and sessionInfo.lifeStart then
                        sessionInfo.livesCompleted += 1
                        sessionInfo.livesTotal += now - sessionInfo.lifeStart
                    end

                    -- Elapsed Time (Since last death) and K/D Ratio (This life) both start over here
                    sessionInfo.deathStart = now
                    sessionInfo.lifeKills = 0
                    sessionInfo.lifeSyntheticKills = 0
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
                for _, wrapped in ipairs(tracker.wrapped) do
                    if rawget(wrapped.channel, "send") == wrapped.counted then
                        rawset(wrapped.channel, "send", wrapped.original)
                    end
                end

                sessionInfo.bulletTracker = nil
            end
        end

        -- A shotgun blast sends one packet per pellet and every one of them says how many pellets the blast has (bullet_count),
        -- so each packet adds 1 / bullet_count to the shots and a whole blast adds exactly 1.
        local function startSessionInfoBulletTracker()
            if sessionInfo.bulletTracker then
                return
            end

            local weaponModule = game:GetService("ReplicatedStorage"):FindFirstChild("Weapon")
            local loaded, weaponClass = pcall(function()
                return weaponModule and require(weaponModule)
            end)
            local packets = loaded and type(weaponClass) == "table" and weaponClass.weapon_packets
            local fireChannel = type(packets) == "table" and packets.fire
            local fireOriginal = type(fireChannel) == "table" and rawget(fireChannel, "send")

            if type(fireOriginal) ~= "function" then
                sessionInfo.bulletsAvailable = false
                return
            end

            sessionInfo.bulletsAvailable = true

            local tracker = { active = true, wrapped = {} }

            local fireWrapper = { channel = fireChannel, original = fireOriginal }

            fireWrapper.counted = function(...)
                if tracker.active then
                    sessionInfo.lastShot = os.clock()

                    if sessionInfo.needs.bullets then
                        local packet = ...
                        local pellets = type(packet) == "table" and tonumber(packet.bullet_count) or 1

                        if not pellets or pellets < 1 then
                            pellets = 1
                        end

                        sessionInfo.bullets += 1
                        sessionInfo.shots += 1 / pellets
                    end
                end

                return fireOriginal(...)
            end

            rawset(fireChannel, "send", fireWrapper.counted)
            table.insert(tracker.wrapped, fireWrapper)

            -- Grenades and missiles report where they landed through this one; their damage comes after it, not after the shot.
            local touchChannel = type(packets) == "table" and packets.touch
            local touchOriginal = type(touchChannel) == "table" and rawget(touchChannel, "send")

            if type(touchOriginal) == "function" then
                local touchWrapper = { channel = touchChannel, original = touchOriginal }

                touchWrapper.counted = function(...)
                    if tracker.active then
                        sessionInfo.lastShot = os.clock()
                    end

                    return touchOriginal(...)
                end

                rawset(touchChannel, "send", touchWrapper.counted)
                table.insert(tracker.wrapped, touchWrapper)
            end

            sessionInfo.bulletTracker = tracker
        end

        -- [Session Info / Damage Dealt] Health a Killer loses shortly after you fire counts as damage you dealt
        local function getDamageDealtWindow()
            local success, ping = pcall(function()
                return localplayer:GetNetworkPing()
            end)

            -- Your shot has to reach the server and the lost health has to come back, so the window increases with the ping
            return math.clamp(0.35 + (success and ping or 0.1) * 2, 0.35, 1.5)
        end

        local function stopSessionInfoDealtTracker()
            local tracker = sessionInfo.dealtTracker

            if tracker then
                for _, connection in ipairs(tracker.connections) do
                    connection:Disconnect()
                end

                sessionInfo.dealtTracker = nil
            end
        end

        local function startSessionInfoDealtTracker()
            if sessionInfo.dealtTracker then
                return
            end

            local folder = killersFolder

            if not folder or not folder.Parent then
                folder = workspace:FindFirstChild("Killers")
            end

            if not folder then
                sessionInfo.dealtAvailable = false
                return
            end

            sessionInfo.dealtAvailable = true

            local tracker = {
                connections = {} :: { RBXScriptConnection },
                watched = setmetatable({}, { __mode = "k" }) :: any, -- Humanoids that are already being watched
            }
            sessionInfo.dealtTracker = tracker

            local function watch(killer: Instance)
                task.spawn(function()
                    local humanoid = (killer:FindFirstChildOfClass("Humanoid") or killer:WaitForChild("Humanoid", 10))

                    if not humanoid or sessionInfo.dealtTracker ~= tracker or tracker.watched[humanoid] then
                        return
                    end

                    tracker.watched[humanoid] = true

                    local lastHealth: number = humanoid.Health
                    local healthConnection: RBXScriptConnection
                    local ancestryConnection: RBXScriptConnection

                    healthConnection = humanoid.HealthChanged:Connect(function(health: number)
                        local lost = lastHealth - health
                        lastHealth = health

                        if lost <= 0 then
                            return
                        end

                        local now = os.clock()

                        if now - sessionInfo.lastShot > getDamageDealtWindow() then
                            return
                        end

                        -- Disable Aura sets the health of the killer it kills to 0 and reports it right after, so the check waits for that report
                        task.defer(function()
                            local stamp = sessionInfo.syntheticModels[killer]

                            if sessionInfo.dealtTracker == tracker and not (stamp and now - stamp < 0.5) then
                                sessionInfo.damageDealt += lost
                            end
                        end)
                    end)

                    ancestryConnection = killer.AncestryChanged:Connect(function(_: Instance, parent: Instance?)
                        if not parent then
                            healthConnection:Disconnect()
                            ancestryConnection:Disconnect()
                        end
                    end)

                    table.insert(tracker.connections, healthConnection)
                    table.insert(tracker.connections, ancestryConnection)
                end)
            end

            for _, killer in ipairs(folder:GetChildren()) do
                watch(killer)
            end

            table.insert(tracker.connections, folder.ChildAdded:Connect(watch))
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

        -- Ping is read on every overlay update, which is also where its highest, lowest and spike notification come from.
        local function sampleSessionInfoPing()
            local success, ping = pcall(function()
                return localplayer:GetNetworkPing() * 1000
            end)

            if not success then
                return
            end

            sessionInfo.ping = ping
            sessionInfo.pingPeak = math.max(sessionInfo.pingPeak or ping, ping)
            sessionInfo.pingLow = math.min(sessionInfo.pingLow or ping, ping)
            checkPingThreshold(ping)
        end

        -- [Session Info / Label]
        local function getSessionInfoSeparator()
            local dropdown = options.sessionInfoSeparator_Dropdown
            local value = dropdown and tostring(dropdown.Value) or ""

            return value:match("^(%S+)") or "•"
        end

        updateSessionInfoLabel = function()
            local label = sessionInfo.label

            if not label then
                return
            end

            local needs = sessionInfo.needs

            if needs.nearest or needs.owned then
                scanSessionInfoKillers(needs.nearest, needs.owned)
            end

            if needs.ping then
                sampleSessionInfoPing()
            end

            local lines = {}

            for _, item in ipairs(sessionInfoItems) do
                if isSessionInfoItemEnabled(item) then
                    local success, value = pcall(item.value)
                    local nameSuccess, name = pcall(function()
                        return item.getText and item.getText() or item.text
                    end)

                    table.insert(lines, (nameSuccess and name or item.text) .. ": " .. (success and value or "N/A"))
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
            local created, label = pcall(function()
                return library:AddDraggableLabel({
                    Text = "Session Info",
                    Icon = assetLib.fetchAsset("Icons/Celestial.png"),
                })
            end)

            if not created or not label then
                -- The icon could not be loaded; the overlay still works without it.
                created, label = pcall(function()
                    return library:AddDraggableLabel({ Text = "Session Info" })
                end)
            end

            if created and label then
                pcall(function()
                    label.Label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Label.RichText = true -- Adaptive colors
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
            stopSessionInfoDealtTracker()

            if sessionInfo.label then
                pcall(function()
                    sessionInfo.label:Destroy()
                end)

                sessionInfo.label = nil
            end

            sessionInfo.lastText = nil
        end

        -- Runs whenever the overlay, any of its lines or a mode that changes what a line tracks is switched, and only keeps running what the shown lines need.
        refreshSessionInfo = function()
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
                table.clear(sessionInfo.syntheticPending)
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
                if sessionInfo.characterSignature ~= getCharacterSignature(needs) then
                    startSessionInfoCharacterTracker(needs)
                end
            else
                stopSessionInfoCharacterTracker()
            end

            -- Damage Dealt needs the shot hook as well, to know when you fired
            if needs.bullets or needs.dealt then
                startSessionInfoBulletTracker()
            else
                stopSessionInfoBulletTracker()
            end

            if needs.dealt then
                startSessionInfoDealtTracker()
            else
                stopSessionInfoDealtTracker()
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

        -- Everything except the timer is read on every update, so most options only need the text rebuilt.
        rebuildSessionInfoText = function()
            sessionInfo.lastText = nil
            pcall(updateSessionInfoLabel)
        end

        -- [Session Info / Reset] Sets every stat back to zero at once
        local function resetSessionInfo()
            local now = os.clock()

            sessionInfo.loadStart = now
            sessionInfo.deathStart = nil

            sessionInfo.kills, sessionInfo.lifeKills = 0, 0
            sessionInfo.syntheticKills, sessionInfo.lifeSyntheticKills = 0, 0
            sessionInfo.streakPeak, sessionInfo.streakPeakCombined = 0, 0
            sessionInfo.killTrackedTime = 0
            sessionInfo.killBaseline = nil -- Counted from the Killers Killed it has right now
            table.clear(sessionInfo.syntheticPending)

            sessionInfo.affectedKillers = 0
            sessionInfo.affectedSeen = setmetatable({}, { __mode = "k" })

            sessionInfo.deaths = 0
            sessionInfo.bullets, sessionInfo.shots = 0, 0
            sessionInfo.damage, sessionInfo.mostDamage = 0, 0
            sessionInfo.damageDealt = 0
            table.clear(sessionInfo.damageByKiller)

            local character = localplayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            sessionInfo.lifeStart = (sessionInfo.needs.survival and humanoid and humanoid.Health > 0) and now or nil
            sessionInfo.livesCompleted, sessionInfo.livesTotal = 0, 0

            sessionInfo.frames, sessionInfo.frameStamp = 0, now
            sessionInfo.fpsPeak, sessionInfo.fpsLow, sessionInfo.fpsBelow = nil, nil, false
            sessionInfo.pingPeak, sessionInfo.pingLow, sessionInfo.pingAbove = nil, nil, false

            rebuildSessionInfoText()
        end

        sessionInfoGroup:AddButton({ Text = "Reset Session", Tooltip = "Sets every Session Info stat back to zero at once, including the timer.", Func = function()
            resetSessionInfo()
            pcall(notify, "Info", "Session Info", "Every stat was reset.", 3)
        end })

        toggles.sessionInfo_Toggle:OnChanged(refreshSessionInfo)

        for _, item in ipairs(sessionInfoItems) do
            toggles[item.toggleId]:OnChanged(refreshSessionInfo)
        end

        -- These change what a line needs to track
        for _, id in ipairs({ "sessionInfoElapsedMode_Dropdown", "sessionInfoBulletsMode_Dropdown" }) do
            options[id]:OnChanged(refreshSessionInfo)
        end

        -- These are only read when the text is built
        for _, id in ipairs({
            "sessionInfoSeparator_Dropdown", "sessionInfoElapsedFormat_Dropdown", "sessionInfoKillsMode_Dropdown",
            "sessionInfoKDDecimals_Dropdown", "sessionInfoKDMode_Dropdown", "sessionInfoDamageRounding_Dropdown",
            "sessionInfoMostDamageMode_Dropdown", "sessionInfoMostDamageRounding_Dropdown", "sessionInfoDamageDealtRounding_Dropdown",
            "sessionInfoSurvivalMode_Dropdown", "sessionInfoHealthDisplay_Dropdown",
        }) do
            options[id]:OnChanged(rebuildSessionInfoText)
        end

        for _, id in ipairs({
            "sessionInfoCompact_Toggle", "sessionInfoSyntheticKills_Toggle", "sessionInfoBulletsPellets_Toggle", "sessionInfoHealthAdaptive_Toggle",
            "sessionInfoFPSAdaptive_Toggle", "sessionInfoFPSCurrent_Toggle", "sessionInfoFPSMax_Toggle", "sessionInfoFPSMin_Toggle",
            "sessionInfoPingAdaptive_Toggle", "sessionInfoPingCurrent_Toggle", "sessionInfoPingMax_Toggle", "sessionInfoPingMin_Toggle",
        }) do
            toggles[id]:OnChanged(rebuildSessionInfoText)
        end

        -- Disable Aura and Emergency Kill call this for every kill they make. It only counts while the Kills line is being tracked.
        utils.sessionInfoSyntheticKill = function(model)
            -- Remembered even when Kills is not shown, so Damage Dealt can leave this kill out
            if model then
                sessionInfo.syntheticModels[model] = os.clock()
            end

            if not sessionInfo.needs.kills then
                return
            end

            sessionInfo.syntheticKills += 1
            sessionInfo.lifeSyntheticKills += 1
            updateKillStreakPeaks()
            table.insert(sessionInfo.syntheticPending, os.clock())
        end

        table.insert(teardownTasks, stopSessionInfo)
        -- Disable Aura, Emergency Kill and Push call this for every killer they affect. It only counts while the Affected Killers line is being tracked.
        utils.sessionInfoAffectedKiller = function(model)
            if not sessionInfo.needs.affected or sessionInfo.affectedSeen[model] then
                return
            end

            sessionInfo.affectedSeen[model] = true
            sessionInfo.affectedKillers += 1
        end

        table.insert(teardownTasks, function()
            utils.sessionInfoSyntheticKill = nil
            utils.sessionInfoAffectedKiller = nil
        end)
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

-- runs unloadModules() through the OnUnload callback, before the library clears its tables
menuGroup:AddButton({
    Text = "Unload",
    DoubleClick = true,
    Func = function()  library:Unload() end })

library.ToggleKeybind = options.menuKeybind_KeyPicker

options.notifAlertVolume_Slider:OnChanged(function(val) window.alertVolume = val end)
options.rainbowSpeed_Slider:OnChanged(function(val) window.rainbowSpeed = val end)

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