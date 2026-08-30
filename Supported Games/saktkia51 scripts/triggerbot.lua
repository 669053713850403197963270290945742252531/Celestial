local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Mouse = Players.LocalPlayer:GetMouse()
local Killers = workspace:WaitForChild("Killers")

local function isAlive(killer)
	local humanoid = killer:FindFirstChildWhichIsA("Humanoid")
	return humanoid and humanoid.Health > 0
end

RunService.RenderStepped:Connect(function()
	local target = Mouse.Target
	if not target then
		return
	end

	local model = target:FindFirstAncestorOfClass("Model")

	if not model or model.Parent ~= Killers then
		return
	end

	-- Ignore Jane
	if model.Name == "Jane" then
		return
	end

	-- Ignore dead killers
	if not isAlive(model) then
		return
	end

	print("Hovering:", model.Name, target.Name)
	mouse1click()
end)