local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Target = LocalPlayer.PlayerScripts
    :WaitForChild("CommonGamemodeSetup")
    :GetFullName()

local function RemoveCanCollideCheck(Character)
    local HRP = Character:WaitForChild("HumanoidRootPart")

    -- Wait for CommonGamemodeSetup to initialize CheckSpeed
    local Timeout = os.clock() + 5

    repeat
        local Found = false

        -- Disable the CanCollide callbacks
        for _, Connection in ipairs(
            getconnections(HRP:GetPropertyChangedSignal("CanCollide"))
        ) do
            local Callback = Connection.Function
            local Info = Callback and debug.getinfo(Callback)

            if Info and type(Info.source) == "string"
                and string.find(Info.source, Target, 1, true) then

                Connection:Disable()
                Found = true

                print("Disabled CanCollide:", Info.source)
            end
        end

        if Found then
            return
        end

        task.wait(0.05)
    until os.clock() >= Timeout

    warn("Could not find CommonGamemodeSetup CanCollide connection")
end

-- Existing character
if LocalPlayer.Character then
    task.spawn(RemoveCanCollideCheck, LocalPlayer.Character)
end

-- Future characters
LocalPlayer.CharacterAdded:Connect(RemoveCanCollideCheck)