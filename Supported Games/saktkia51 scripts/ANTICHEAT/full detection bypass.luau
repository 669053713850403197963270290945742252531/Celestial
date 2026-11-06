local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local TARGET_SPEED = 35
local INITIALIZATION_TIMEOUT = 5
local RETRY_INTERVAL = 0.05

local Target = LocalPlayer.PlayerScripts
    :WaitForChild("CommonGamemodeSetup")
    :GetFullName()

local Checks = {
    {
        Name = "WalkSpeed",
        Signal = function(Humanoid)
            return Humanoid:GetPropertyChangedSignal("WalkSpeed")
        end
    },
    {
        Name = "JumpPower",
        Signal = function(Humanoid)
            return Humanoid:GetPropertyChangedSignal("JumpPower")
        end
    },
    {
        Name = "StateChanged",
        Signal = function(Humanoid)
            return Humanoid.StateChanged
        end
    },
    {
        Name = "Strafing",
        Signal = function(Humanoid)
            return Humanoid.Strafing
        end
    },
    {
        Name = "Swimming",
        Signal = function(Humanoid)
            return Humanoid.Swimming
        end
    },
    {
        Name = "DescendantAdded",
        Signal = function(Humanoid, Character)
            return Character.DescendantAdded
        end
    },
    {
        Name = "CanCollide",
        Signal = function(Humanoid, Character, HRP)
            return HRP:GetPropertyChangedSignal("CanCollide")
        end
    }
}

local function InitializeCharacter(Character)
    local Humanoid = Character:WaitForChild("Humanoid")
    local HRP = Character:WaitForChild("HumanoidRootPart")

    print("[CheckSpeed] Initializing:", Character.Name)

    local Completed = {}
    local DisabledCount = 0
    local Deadline = os.clock() + INITIALIZATION_TIMEOUT

    repeat
        local Pending = false

        for _, Check in ipairs(Checks) do
            if not Completed[Check.Name] then
                local Signal = Check.Signal(Humanoid, Character, HRP)
                local Found = false

                for _, Connection in ipairs(getconnections(Signal)) do
                    local Callback = Connection.Function
                    local Info = Callback and debug.getinfo(Callback)
                    local Source = Info and Info.source

                    if type(Source) == "string"
                        and string.find(Source, Target, 1, true) then

                        Found = true

                        local Success, Error = pcall(function()
                            Connection:Disable()
                        end)

                        if Success then
                            DisabledCount += 1

                            print(string.format(
                                "[CheckSpeed] [DISABLED] %s | %s",
                                Check.Name,
                                Source
                            ))
                        else
                            warn(string.format(
                                "[CheckSpeed] [FAILED] %s | %s",
                                Check.Name,
                                tostring(Error)
                            ))
                        end
                    end
                end

                Completed[Check.Name] = Found

                if not Found then
                    Pending = true
                end
            end
        end

        if not Pending then
            break
        end

        task.wait(RETRY_INTERVAL)
    until os.clock() >= Deadline

    local Missing = {}

    for _, Check in ipairs(Checks) do
        if not Completed[Check.Name] then
            table.insert(Missing, Check.Name)

            warn("[CheckSpeed] [NOT FOUND]", Check.Name)
        end
    end

    if Completed.WalkSpeed then
        Humanoid.WalkSpeed = TARGET_SPEED

        print("[CheckSpeed] WalkSpeed configured:", TARGET_SPEED)
    end

    print(string.format(
        "[CheckSpeed] Finished | %d/%d connections disabled",
        DisabledCount,
        #Checks
    ))

    if #Missing > 0 then
        warn("[CheckSpeed] Missing:", table.concat(Missing, ", "))
    end
end

if LocalPlayer.Character then
    task.spawn(InitializeCharacter, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(Character)
    task.spawn(InitializeCharacter, Character)
end)