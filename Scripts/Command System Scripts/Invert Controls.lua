local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local moveVector = Vector3.zero
local connection
local inverted = false

-- Key states
local keys = {
	W = false,
	A = false,
	S = false,
	D = false
}

local function updateMoveVector(camera)
	local forward = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector

	local direction = Vector3.zero

	-- INVERTED CONTROLS
	if keys.W then direction -= forward end -- W becomes backward
	if keys.S then direction += forward end -- S becomes forward
	if keys.A then direction += right end   -- A becomes right
	if keys.D then direction -= right end   -- D becomes left

	return direction
end

local function enableInvert(char)
	if inverted then return end
	inverted = true

	local humanoid = char:WaitForChild("Humanoid")

	-- Disable default controls
	local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
	controls:Disable()

	connection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		local dir = updateMoveVector(camera)

		if dir.Magnitude > 0 then
			humanoid:Move(dir.Unit, true)
		else
			humanoid:Move(Vector3.zero, true)
		end
	end)
end

local function disableInvert()
	if not inverted then return end
	inverted = false

	if connection then
		connection:Disconnect()
		connection = nil
	end

	-- Re-enable default controls
	local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
	controls:Enable()
end

-- Input tracking
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Enum.KeyCode.W then keys.W = true end
	if input.KeyCode == Enum.KeyCode.A then keys.A = true end
	if input.KeyCode == Enum.KeyCode.S then keys.S = true end
	if input.KeyCode == Enum.KeyCode.D then keys.D = true end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then keys.W = false end
	if input.KeyCode == Enum.KeyCode.A then keys.A = false end
	if input.KeyCode == Enum.KeyCode.S then keys.S = false end
	if input.KeyCode == Enum.KeyCode.D then keys.D = false end
end)

-- Reapply on respawn
player.CharacterAdded:Connect(function(char)
	if inverted then
		enableInvert(char)
	end
end)

task.spawn(function()
	if player.Character then
		enableInvert(player.Character)
	end
	print("Invert ON")

	task.wait(5)
	disableInvert()
	print("Invert OFF")
end)
