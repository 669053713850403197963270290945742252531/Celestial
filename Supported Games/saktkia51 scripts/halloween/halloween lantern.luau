--!strict
-- Place in ServerScriptService as a regular Script (NOT a LocalScript).
-- Rebuilds the "CampingLantern" tool from the .rbxm and puts it directly in each
-- player's Backpack every time their character spawns.
-- StarterPack and StarterGear are not touched.

local Players = game:GetService("Players")

local TOOL_NAME = "CampingLantern"

local function createLantern(): Tool
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.CanBeDropped = false
	tool.Enabled = true
	tool.ManualActivationOnly = false
	tool.RequiresHandle = true
	tool.ToolTip = ""
	tool.TextureId = "rbxassetid://123239881"
	tool.Grip = CFrame.new(0, 1, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.8, 2.4, 0.8)
	handle.Color = Color3.fromRGB(163, 162, 165)
	handle.Material = Enum.Material.Plastic
	handle.Transparency = 0
	handle.Reflectance = 0
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.Locked = false
	handle.TopSurface = Enum.SurfaceType.Studs
	handle.BottomSurface = Enum.SurfaceType.Inlet
	handle.Parent = tool

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "Mesh"
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "rbxassetid://123115084"
	mesh.TextureId = "rbxassetid://123115105"
	mesh.Offset = Vector3.zero
	mesh.Scale = Vector3.new(0.8, 0.8, 0.8)
	mesh.VertexColor = Vector3.new(1, 0.5, 0)
	mesh.Parent = handle

	local light = Instance.new("PointLight")
	light.Name = "PointLight"
	light.Range = 16
	light.Brightness = 5
	light.Color = Color3.fromRGB(255, 127, 0)
	light.Enabled = true
	light.Shadows = false
	light.Parent = handle

	return tool
end

local template = createLantern()

local function giveLantern(player: Player)
	-- The Backpack is rebuilt on each spawn, so always fetch it fresh.
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		return
	end

	local character = player.Character
	if backpack:FindFirstChild(TOOL_NAME) or (character and character:FindFirstChild(TOOL_NAME)) then
		return
	end

	template:Clone().Parent = backpack
end

local function onPlayerAdded(player: Player)
	-- Every spawn (including respawns)
	player.CharacterAdded:Connect(function()
		giveLantern(player)
	end)

	-- If the character already exists by the time we connect (e.g. script started late)
	if player.Character then
		task.spawn(giveLantern, player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end