local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local restoring = {}

local function isBodyModel(instance)
	return instance.Name == "Chest"
		or instance.Name == "LeftArm"
		or instance.Name == "LeftLeg"
		or instance.Name == "RightArm"
		or instance.Name == "RightLeg"
end

local function hasBodyModels(character)
	for _, child in ipairs(character:GetChildren()) do
		if isBodyModel(child) then
			return true
		end
	end

	return false
end

local function restoreMeshPartTransparency(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("MeshPart") then
			descendant.Transparency = 0
		end
	end
end

local function setMeshPartTransparency(character, value)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("MeshPart") then
			descendant.Transparency = value
		end
	end
end

local function updateTransparency(character)
	if hasBodyModels(character) then
		setMeshPartTransparency(character, 1)
	else
		setMeshPartTransparency(character, 0)
	end
end

local function moveBodyModel(model, character)
	if restoring[model] then
		return
	end
	model.Parent = Lighting
	updateTransparency(character)
	task.spawn(function()
		task.wait(3) -- this wait is to mimick a "disable" function of this if it were placed into a toggle
		if not character.Parent then
			return
		end
		if model.Parent ~= Lighting then
			return
		end
		restoring[model] = true
		model.Parent = character
		updateTransparency(character)
		task.defer(function()
			restoring[model] = nil
		end)
	end)
end

local function setupCharacter(character)
	-- Move anything that already exists.
	for _, child in ipairs(character:GetChildren()) do
		if isBodyModel(child) then
			moveBodyModel(child, character)
		end
	end

	-- Watch for newly added models.
    character.ChildAdded:Connect(function(child)
        if isBodyModel(child) then
            if restoring[child] then
                return
            end
            moveBodyModel(child, character)
        end
    end)

    character.ChildRemoved:Connect(function(child)
        if isBodyModel(child) then
            updateTransparency(character)
        end
    end)

	updateTransparency(character)
end

if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)
