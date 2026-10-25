-- HalloweenTransform_Test.server.luau
-- Place this Script beside the TRANSFORM ModuleScript.

local Workspace = game:GetService("Workspace")

local TRANSFORMATIONS = loadstring(readfile("Celestial/Supported Games/saktkia51 scripts/halloween/TRANSFORM.luau"))()
local HalloweenTransform = TRANSFORMATIONS.HalloweenTransform
local Killers = Workspace:WaitForChild("Killers")

-- Weak keys let removed killer Models be garbage-collected.
local processedKillers = setmetatable({}, { __mode = "k" }) :: { [Model]: boolean }

-- Only process the outermost Model for each killer. This still supports
-- killers stored inside Folders, without treating a killer's internal
-- sub-Models as separate killers.
local function isKillerModel(instance: Instance): boolean
	if not instance:IsA("Model") then
		return false
	end

	local ancestor = instance.Parent
	while ancestor and ancestor ~= Killers do
		if ancestor:IsA("Model") then
			return false
		end
		ancestor = ancestor.Parent
	end

	return ancestor == Killers
end

local function onDescendantAdded(instance: Instance)
	if not isKillerModel(instance) then
		return
	end

	local killer = instance :: Model
	if processedKillers[killer] then
		return
	end

	processedKillers[killer] = true

	-- Defer until the newly parented Model is fully present in the hierarchy.
	task.defer(function()
		if not killer:IsDescendantOf(Killers) or not isKillerModel(killer) then
			processedKillers[killer] = nil
			return
		end

		local transformedCount = HalloweenTransform(killer.Name)
		print(
			("HalloweenTransform: processed new killer %q (%d matching Model(s) transformed).")
				:format(killer.Name, transformedCount)
		)
	end)
end

-- Connect first so a killer added during startup cannot be missed.
-- DescendantAdded also catches killers placed inside Folders under Workspace.Killers.
Killers.DescendantAdded:Connect(onDescendantAdded)

-- Initial pass: transform every supported killer already in Workspace.Killers.
local initialCount = HalloweenTransform("All")
print(("HalloweenTransform: initial pass transformed %d killer Model(s)."):format(initialCount))