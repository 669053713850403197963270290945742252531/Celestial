local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character

local function DisableConnections(Signal)
    for _, Connection in ipairs(getconnections(Signal)) do
        local Callback = Connection.Function
        local Info = Callback and debug.getinfo(Callback)

        if Info and Info.source and string.find(
            Info.source,
            LocalPlayer.PlayerScripts.CommonGamemodeSetup,
            1,
            true
        ) then
            Connection:Disable()
            print("Disabled:", Info.source, Info.name)
        end
    end
end

-- Humanoid events
DisableConnections(Character.Humanoid.StateChanged)
DisableConnections(Character.Humanoid.Strafing)
DisableConnections(Character.Humanoid.Swimming)

-- Instance event (use the same instance CommonGamemodeSetup uses)
DisableConnections(Character.DescendantAdded)

-- Disabled humanoid state trackers