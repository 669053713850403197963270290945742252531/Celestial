local entityLib = {}

local players = game:GetService("Players")
local player = players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

-- Update character reference when the player respawns

player.CharacterAdded:Connect(function(newChar)
    char = newChar
end)

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHRP()
	return getCharacter():WaitForChild("HumanoidRootPart")
end

local function getHumanoid()
	return getCharacter():WaitForChild("Humanoid")
end

entityLib.isAlive = function()
    local humanoid = getHumanoid()

    if not humanoid then
        warn("entityLibrary.isAlive: No Humanoid found.")
        return
    end

    if humanoid.Health > 0 and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") then
        return true
    else
        return false
    end
end

entityLib.getCharInstance = function(charInstance)
    local requestedPart = game.Players.LocalPlayer.Character:FindFirstChild(charInstance)

    if requestedPart then
        return requestedPart
    else
        warn(charInstance .. " was not found inside character.")
        return false
    end
end

entityLib.copyCFrame = function()
    local hrp = getHRP()

    if not hrp then
        warn("entityLibrary.copyCFrame: No HumanoidRootPart found.")
        return
    end

    setclipboard(tostring(hrp.CFrame))
end

entityLib.copyPosition = function()
    local hrp = getHRP()

    if not hrp then
        warn("entityLibrary.copyPosition: No HumanoidRootPart found.")
        return
    end

    setclipboard(tostring(hrp.Position))
end

entityLib.moveTo = function(position)
    local humanoid = getHumanoid()

    if not humanoid then
        warn("entityLibrary.moveTo: No Humanoid found.")
        return
    end

    humanoid:MoveTo(Vector3.new(position))
end

entityLib.tweenTeleport = function(duration, targetPosition)
    local hrp = getHRP()
    local tweenRunning = false

    if not hrp then
        warn("entityLibrary.tweenTeleport: No HumanoidRootPart found.")
        return
    end

    if not tweenRunning then
        if typeof(targetPosition) == "CFrame" then -- CFrame tween teleport
            local tweenInfo = TweenInfo.new(
                duration or 3,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.InOut
            )
    
            local tweenGoal = {CFrame = targetPosition}
        
            hrp.Anchored = true
            local tween = tweenService:Create(hrp, tweenInfo, tweenGoal)
            tween:Play()
            tweenRunning = true
        
            tween.Completed:Connect(function()
                hrp.Anchored = false
                tweenRunning = false
            end)
    
        elseif typeof(targetPosition) == "Instance" then -- Part tween teleport
    
            local tweenInfo = TweenInfo.new(
                duration or 3,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.InOut
            )
    
            local tweenGoal = {CFrame = targetPosition.CFrame}
        
            hrp.Anchored = true
            local tween = tweenService:Create(hrp, tweenInfo, tweenGoal)
            tween:Play()
            tweenRunning = true
        
            tween.Completed:Connect(function()
                hrp.Anchored = false
                tweenRunning = false
            end)
        else
            warn("entityLibrary.tweenTeleport: Invalid targetPosition.")
            return
        end
    end
end

entityLib.teleport = function(targetPosition)
    local hrp = getHRP()

    if not hrp then
        warn("entityLibrary.teleport: No HumanoidRootPart found.")
        return
    end

    if typeof(targetPosition) == "CFrame" then -- CFrame teleport
        hrp.CFrame = targetPosition
    elseif typeof(targetPosition) == "Instance" then -- Part teleport
        hrp.CFrame = targetPosition.CFrame
    else
        warn("entityLibrary.teleport: Invalid targetPosition.")
        return
    end
end

entityLib.checkTeleport = function(rootPart, targetCFrame, tolerance)
    if not rootPart or not targetCFrame then
        warn("entityLibrary.checkTeleport: Argument #1 (rootPart) and/or argument #2 (targetCFrame) are invalid.")
        return false
    end

    wait(0.1)

    local targetPosition = targetCFrame.Position
    local currentPosition = rootPart.Position

    local distance = (currentPosition - targetPosition).Magnitude
    return distance <= (tolerance or 5)
end

entityLib.getEntityDistance = function(entity1, entity2)
    local pos1 = entity1.Position
    local pos2 = entity2.Position
    return (pos1 - pos2).Magnitude
end

entityLib.isOnGround = function(entity)
    if not entity then
        warn("entityLibrary.isOnGround: Invalid entity.")
        return false
    end

    return entity.Humanoid.FloorMaterial ~= Enum.Material.Air
end

entityLib.kill = function(useSpawnPoint)
    local humanoid = getHumanoid()
    local hrp = getHRP()

    if not hrp or not humanoid then
        warn("entityLibrary.kill: No HumanoidRootPart or Humanoid found.")
        return
    end

    if useSpawnPoint == true then
        local respawnTime = players.RespawnTime
        local origCFrame = hrp.CFrame
        print("Saved CFrame: ", origCFrame)

        humanoid.Health = 0

        -- Wait for respawn

        local newCharacter = player.CharacterAdded:Wait()
        print("Character respawned.")

        -- Wait for the new HRP to exist

        local newHRP
        repeat
            newHRP = newCharacter:FindFirstChild("HumanoidRootPart")
            task.wait()
        until newHRP

        if newHRP then
            newHRP.CFrame = origCFrame
        else
            warn("entityLibrary.kill: Failed to find HumanoidRootPart after waiting.")
        end
    else
        humanoid.Health = 0
    end
end

entityLib.modifyPlayer = function(propertyName, value)
    local humanoid = getHumanoid()

    if not humanoid then
        warn("entityLibrary.modifyPlayer: No Humanoid found.")
        return
    end

    -- Property check

    local success = pcall(function()
        local _ = humanoid[propertyName]
    end)

    if not success then
        warn(propertyName .. " is not a valid property of Humanoid.")
        return false
    end

    -- Value type check

    if typeof(value) ~= "number" then
        warn("entityLibrary.modifyPlayer: Argument #2 (value) expected a number value but received a " .. typeof(value) .. " value.")
        return false
    end

    humanoid[propertyName] = value
end

local storedData = {}

entityLib.storeData = function(object, propertyName)
    storedData[object] = storedData[object] or {}

    -- Check if the property is already stored
    if storedData[object][propertyName] ~= nil then
        warn(propertyName .. " is already stored. Skipping.")
        return storedData[object][propertyName] -- Return the stored value
    end

    storedData[object][propertyName] = object[propertyName] -- Store the property value in the table
    return storedData[object][propertyName] -- Return the stored value
end

entityLib.restoreData = function(object, propertyName)
    -- Restore the property value if it was saved

    if storedData[object] and storedData[object][propertyName] ~= nil then
        object[propertyName] = storedData[object][propertyName]
    else
        --warn("entityLibrary.restoreData: No stored data for ", propertyName)
    end
end

entityLib.clearData = function(object, propertyName)
    if storedData[object] then
        if storedData[object][propertyName] then
            storedData[object][propertyName] = nil
            --print(propertyName .. " data cleared for the given object.")
        else
            --warn("No stored data for " .. propertyName .. " on this object.")
        end
    else
        --warn("No data found for the given object: " .. tostring(object))
    end
end

--[[

entityLib.clearData = function(object, propertyName)
    if storedData[object] then
        storedData[object][propertyName] = nil
        if next(storedData[object]) == nil then
            storedData[object] = nil -- Remove the object entirely if no properties remain
        end
    end
end

]]

entityLib.clearAllData = function()
    storedData = {}
end

entityLib.playerTeleport = function(delay)
    local hrp = getHRP()
    local humanoid = getHumanoid()

    if not hrp or not humanoid then
        warn("entityLibrary.playerTeleport: No HumanoidRootPart or Humanoid found.")
        return
    end

    delay = delay or 0.1

    if typeof(delay) ~= "number" then
        warn("entityLibrary.playerTeleport: Argument #1 (delay) expected number but got " .. typeof(delay) .. ".")
        return
    end

    local originalcframe = hrp.CFrame
    --print("Original CFrame: ", originalcframe)

    for _, otherPlayer in pairs(players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherCharacter = otherPlayer.Character or otherPlayer.CharacterAdded:Wait()

            if otherCharacter then
                local otherhrp = otherCharacter:FindFirstChild("HumanoidRootPart")

                if otherhrp then
                    --print("Teleporting to player: ", otherPlayer.Name)
                    humanoid.Sit = false
                    hrp.CFrame = otherhrp.CFrame
                    task.wait(delay)
                else
                    --print("HumanoidRootPart not found for player: " .. otherPlayer.Name)
                end
            else
                --print("Character not found for player: " .. otherPlayer.Name)
            end
        end
    end

    --print("Teleporting back to original position.")
    hrp.CFrame = originalcframe
end

entityLib.fetchFPS = function()
    local deltaTime = nil

    -- Connect to RenderStepped and disconnect after first frame

    local connection
    connection = runService.RenderStepped:Connect(function(dt)
        deltaTime = dt
        connection:Disconnect()
    end)

    -- Wait for RenderStepped and deltaTime is set
    
    while deltaTime == nil do
        task.wait()
    end

    return math.floor(1 / deltaTime)
end

entityLib.fetchPing = function()
    local perfStats = game:GetService("Stats").PerformanceStats
    local currentPing = math.floor(tonumber(perfStats.Ping:GetValue()))
    return currentPing
end

entityLib.fetchMemoryUsage = function()
    local perfStats = game:GetService("Stats").PerformanceStats
    local memoryUsage = math.floor(tonumber(perfStats.Memory:GetValue()))
    return memoryUsage
end

entityLib.getTool = function(mode, toolName)
    local validModes = {
        Specific = true,
        Count = true,
        Held = true
    }

    if not validModes[mode] then
        warn("utils.getTool: Invalid mode '" .. tostring(mode) .. "'.")
        return nil
    end

    local backpack = player.Backpack
    local character = player.Character
    local toolCount = 0
    local held = nil

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            if mode == "Specific" and tool.Name == toolName then
                return tool -- If not found, return the tool instance
            end
            toolCount += 1
        end
    end

    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            if mode == "Specific" and tool.Name == toolName then
                return tool -- Return tool instance if found
            end

            toolCount += 1
            if mode == "Held" then
                held = tool
            end
        end
    end

    if mode == "Specific" then
        return nil
    elseif mode == "Count" then
        return toolCount
    elseif mode == "Held" then
        return held
    end
end

entityLib.equipTool = function(toolName, equip)
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    
    if not humanoid then
        warn("entityLib.equipTool: Humanoid not found.")
        return false
    end

    if equip then
        local tool = entityLib.getTool("Specific", toolName)
        if tool then
            humanoid:EquipTool(tool)
            return true
        else
            warn("entityLib.equipTool: Tool '" .. tostring(toolName) .. "' not found.")
        end
    else
        local heldTool = entityLib.getTool("Held") -- Get currently held tool
        if heldTool then
            heldTool.Parent = player.Backpack -- Move tool back to backpack
            return true
        else
            warn("entityLib.equipTool: No tool equipped to unequip.")
        end
    end

    return false
end

--[[-----------------------------------

            FLY FUNCTION

--------------------------------------]]

local userInput = game:GetService("UserInputService")

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getHRP()
    return getCharacter():WaitForChild("HumanoidRootPart")
end

local function getHumanoid()
    return getCharacter():WaitForChild("Humanoid")
end

local flying = false
local speed = 50
local verticalSpeed = 30
local bodyVelocity, bodyGyro, connection

local function cleanUp()
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if connection then connection:Disconnect() connection = nil end
end

local function getMovementDirection()
    local moveDirection = Vector3.zero
    local camera = game.Workspace.CurrentCamera

    if userInput:IsKeyDown(Enum.KeyCode.W) then
        moveDirection = moveDirection + camera.CFrame.LookVector
    end
    if userInput:IsKeyDown(Enum.KeyCode.S) then
        moveDirection = moveDirection - camera.CFrame.LookVector
    end
    if userInput:IsKeyDown(Enum.KeyCode.A) then
        moveDirection = moveDirection - camera.CFrame.RightVector
    end
    if userInput:IsKeyDown(Enum.KeyCode.D) then
        moveDirection = moveDirection + camera.CFrame.RightVector
    end

    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit * speed
    end

    return moveDirection
end

local function toggleFly(state)
    if state == flying then return end
    flying = state

    if flying then
        cleanUp()

        getHumanoid().PlatformStand = true

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = getHRP()

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.CFrame = getHRP().CFrame
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.P = 10000
        bodyGyro.Parent = getHRP()

        connection = runService.RenderStepped:Connect(function()
            if not flying then return end

            local moveDirection = getMovementDirection()
            
            if userInput:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0) * verticalSpeed
            end

            if userInput:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0) * verticalSpeed
            end

            if userInput:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0) * verticalSpeed
            end

            bodyVelocity.Velocity = moveDirection
            bodyGyro.CFrame = game.Workspace.CurrentCamera.CFrame
        end)
    else
        local moveDirection = getMovementDirection()

        cleanUp()

        getHumanoid().PlatformStand = false

        getHumanoid():Move(moveDirection, true)
    end
end

local function setFlySpeed(newHorizontalSpeed, newVerticalSpeed)
    speed = newHorizontalSpeed or speed
    verticalSpeed = newVerticalSpeed or verticalSpeed

    if flying and bodyVelocity then
        bodyVelocity.Velocity = getMovementDirection()
    end
end

entityLib.toggleFly = toggleFly
entityLib.setFlySpeed = setFlySpeed

local function onCharacterAdded(char)
    local humanoid = char:WaitForChild("Humanoid")
    local humanoidRootPart = char:WaitForChild("HumanoidRootPart")

    if humanoid then
        humanoid.PlatformStand = false
    end

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end

    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end

    while not char:WaitForChild("HumanoidRootPart") do
        wait(0.1)
    end
    while not char:WaitForChild("Humanoid") do
        wait(0.1)
    end

    if flying and getHRP() then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = getHRP()

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.CFrame = getHRP().CFrame
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.P = 10000
        bodyGyro.Parent = getHRP()

        connection = runService.RenderStepped:Connect(function()
            if not flying then return end

            local moveDirection = getMovementDirection()
            
            if userInput:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0) * verticalSpeed
            end

            if userInput:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0) * verticalSpeed
            end

            if userInput:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0) * verticalSpeed
            end

            bodyVelocity.Velocity = moveDirection
            bodyGyro.CFrame = game.Workspace.CurrentCamera.CFrame
        end)
    end
end

player.CharacterAdded:Connect(onCharacterAdded)


--[[-----------------------------------

            NOCLIP FUNCTION

--------------------------------------]]

local noclipEnabled = false
local noclipConnection = nil
local originalStates = {}
local char = nil

entityLib.toggleNoclip = function(enabled)
    noclipEnabled = enabled -- Keep track of toggle state

    if not enabled then
        -- Restore original CanCollide states
        for part, state in pairs(originalStates) do
            if part and part:IsDescendantOf(getCharacter()) then
                part.CanCollide = state
            end
        end
        originalStates = {}

        -- Force state refresh
        local humanoid = getHumanoid()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        -- Disconnect noclip loop
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end

        return
    end

    -- Save original CanCollide and disable collisions
    for _, part in ipairs(getCharacter():GetDescendants()) do
        if part:IsA("BasePart") then
            if originalStates[part] == nil then
                originalStates[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end

    -- Set up noclip loop
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    noclipConnection = runService.Stepped:Connect(function()
        if noclipEnabled then -- only force noclip when enabled
            for _, object in pairs(game.Workspace:GetChildren()) do
                if object.Name == player.Name then
                    for _, part in pairs(object:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end)
end

local function onCharacterAdded(char)
    local humanoid = char:WaitForChild("Humanoid")

    if not noclipEnabled then return end -- Don't re-enable if not toggled on

    -- Save CanCollide states
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if originalStates[part] == nil then
                originalStates[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end

    -- Re-establish noclip loop
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    noclipConnection = runService.Stepped:Connect(function()
        if noclipEnabled then
            for _, object in pairs(game.Workspace:GetChildren()) do
                if object.Name == player.Name then
                    for _, part in pairs(object:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end)
end

return entityLib