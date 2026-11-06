local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local TARGET_SPEED = 35

local function RemoveSpeedCheck(Character)
    local Humanoid = Character:WaitForChild("Humanoid")

    -- Allow CommonGamemodeSetup to initialize CheckSpeed
    task.wait(0.25)

    -- Disable the WalkSpeed & JumpPower property-change callbacks
    for _, Signal in ipairs({
        Humanoid:GetPropertyChangedSignal("WalkSpeed"),
        Humanoid:GetPropertyChangedSignal("JumpPower")
    }) do
        for _, Connection in ipairs(getconnections(Signal)) do
            Connection:Disable()
        end
    end

    Humanoid.WalkSpeed = TARGET_SPEED
end

if LocalPlayer.Character then
    task.spawn(RemoveSpeedCheck, LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(RemoveSpeedCheck)

-- Disabled WalkSpeed & JumpPower connections