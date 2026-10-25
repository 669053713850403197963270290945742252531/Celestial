local Workspace = game:GetService("Workspace")

local HalloweenTransformations = {}

type BodyColorOverrides = {
	HeadColor3: Color3?,
	TorsoColor3: Color3?,
	LeftArmColor3: Color3?,
	RightArmColor3: Color3?,
	LeftLegColor3: Color3?,
	RightLegColor3: Color3?,
}

type VariantConfig = {
	bodyColor: Color3?,
	bodyColors: BodyColorOverrides?,
	clothingColor: Color3?,
	headTextureId: string?,
	removeSurfaceAppearance: boolean?,
	surfaceAppearanceColorMap: string?,
	surfaceAppearanceTexturePack: string?,
	applyCustom: ((Model) -> ())?,
}

type KillerConfig = {
	Halloween: VariantConfig?,
	Normal: VariantConfig?,
}

-- Each killer's appearance is configured here. Killer-specific behavior belongs in applyCustom so
-- the shared traversal does not need to be duplicated. Every variant assigns absolute values
-- (never offsets from the current ones) and clears its own additions first, so repeated transforms
-- are safe.
local TRANSFORMATIONS: { [string]: KillerConfig } = {
	Alien = {
		Halloween = {
			bodyColor = Color3.fromRGB(151, 0, 0),
			clothingColor = Color3.fromRGB(255, 0, 0),
			headTextureId = "http://www.roblox.com/asset/?id=14937108994",
			removeSurfaceAppearance = true,
		},

		Normal = {
			bodyColor = Color3.fromRGB(80, 109, 84),
			clothingColor = Color3.fromRGB(255, 255, 255),
			headTextureId = "",
			surfaceAppearanceColorMap = "rbxassetid://20908610",
			surfaceAppearanceTexturePack = "rbxassetid://115155730780075",
		},
	},
}

local function setBodyColor(bodyColors: BodyColors, color: Color3)
	bodyColors.HeadColor3 = color
	bodyColors.TorsoColor3 = color
	bodyColors.LeftArmColor3 = color
	bodyColors.RightArmColor3 = color
	bodyColors.LeftLegColor3 = color
	bodyColors.RightLegColor3 = color
end

local function applyBodyColorOverrides(
	bodyColors: BodyColors,
	overrides: BodyColorOverrides
)
	local writableBodyColors = bodyColors :: any
	for propertyName, color in pairs(overrides) do
		writableBodyColors[propertyName] = color
	end
end

local function removeSurfaceAppearances(part: Instance?)
	if part == nil then
		return
	end

	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("SurfaceAppearance") then
			-- Local executors or concurrent game scripts may invalidate an instance
			-- between GetChildren() and Destroy(). Do not abort the whole transform.
			local destroyed = pcall(function()
				child:Destroy()
			end)
			if not destroyed then
				pcall(function()
					child.Parent = nil
				end)
			end
		end
	end
end

local function applySurfaceAppearance(head: MeshPart, variant: VariantConfig)
	if variant.removeSurfaceAppearance then
		removeSurfaceAppearances(head)
		return
	end

	if variant.surfaceAppearanceColorMap or variant.surfaceAppearanceTexturePack then
		removeSurfaceAppearances(head)

		local surfaceAppearance = Instance.new("SurfaceAppearance")

		if variant.surfaceAppearanceColorMap then
			surfaceAppearance.ColorMap = variant.surfaceAppearanceColorMap
		end

		if variant.surfaceAppearanceTexturePack then
			surfaceAppearance.TexturePack = variant.surfaceAppearanceTexturePack
		end

		surfaceAppearance.Parent = head
	end
end

local CAPTAIN_ZOMBIE_KILLER_NAME = "Captain Zombie"

-- Marks Halloween-only objects with the killer's name so they can be found and destroyed later.
local KILLER_HALLOWEEN_MARKER_ATTRIBUTE = "HalloweenTransformationKiller"

local function markHalloweenObjectForKiller(instance: Instance, killerName: string)
	instance:SetAttribute(KILLER_HALLOWEEN_MARKER_ATTRIBUTE, killerName)
end

local function clearHalloweenObjectsForKiller(model: Model, killerName: string)
	local descendants = model:GetDescendants()
	for index = #descendants, 1, -1 do
		local instance = descendants[index]
		if instance:GetAttribute(KILLER_HALLOWEEN_MARKER_ATTRIBUTE) == killerName then
			instance:Destroy()
		end
	end
end

-- Keeping originals inside the model makes restoration survive a re-require of
-- this ModuleScript; an in-memory-only table can be lost between calls.
local CAPTAIN_ZOMBIE_PRESERVED_FOLDER = "__CaptainZombieClassicObjects"

-- Remove any joints connecting an accessory/legacy Hat to the rig before detaching it; classic
-- hats can have their weld parented outside the hat.
local function removeCaptainZombieAccessoryJoints(
	model: Model,
	accoutrement: Accoutrement
)
	local handle = accoutrement:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return
	end

	local checked: { [Instance]: boolean } = {}
	local function inspect(instance: Instance)
		if checked[instance] then
			return
		end
		checked[instance] = true

		if instance:IsA("JointInstance") then
			if instance.Part0 == handle or instance.Part1 == handle then
				instance:Destroy()
			end
		elseif instance:IsA("WeldConstraint") then
			if instance.Part0 == handle or instance.Part1 == handle then
				instance:Destroy()
			end
		end
	end

	for _, instance in ipairs(model:GetDescendants()) do
		inspect(instance)
	end
	for _, instance in ipairs(accoutrement:GetDescendants()) do
		inspect(instance)
	end
end

local function getCaptainZombiePreservedFolder(
	model: Model,
	createIfMissing: boolean
): Folder?
	local existing = model:FindFirstChild(CAPTAIN_ZOMBIE_PRESERVED_FOLDER)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if not createIfMissing then
		return nil
	end

	local folder = Instance.new("Folder")
	folder.Name = CAPTAIN_ZOMBIE_PRESERVED_FOLDER
	folder.Parent = model
	return folder
end

local function detachCaptainZombieOriginal(model: Model, objectName: string)
	local instance = model:FindFirstChild(objectName)
	if not instance then
		return
	end

	local preservedFolder = getCaptainZombiePreservedFolder(model, true)
	if not preservedFolder or preservedFolder:FindFirstChild(objectName) then
		return
	end

	if instance:IsA("Accoutrement") then
		removeCaptainZombieAccessoryJoints(model, instance)
	end

	instance.Parent = preservedFolder
end

-- Handles both modern Accessory instances and legacy Hat/Accoutrement objects.
-- AddAccessory only accepts Accessory; old Hat instances must be parented and
-- attached with a weld explicitly.
local function ensureCaptainZombieAccessoryAttached(
	model: Model,
	accoutrement: Accoutrement
)
	local handle = accoutrement:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		warn("Captain Zombie accoutrement has no BasePart Handle:", accoutrement.Name)
		return
	end

	-- Do not duplicate a valid weld that already attaches this Handle.
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("JointInstance")
			and descendant.Name == "AccessoryWeld"
			and (descendant.Part0 == handle or descendant.Part1 == handle) then
			return
		end
		if descendant:IsA("WeldConstraint")
			and (descendant.Part0 == handle or descendant.Part1 == handle) then
			return
		end
	end

	-- Prefer Roblox attachment pairs when the Handle has a matching Attachment.
	for _, handleDescendant in ipairs(handle:GetDescendants()) do
		if handleDescendant:IsA("Attachment") then
			for _, rigDescendant in ipairs(model:GetDescendants()) do
				if rigDescendant:IsA("Attachment")
					and rigDescendant.Name == handleDescendant.Name
					and not rigDescendant:IsDescendantOf(accoutrement)
					and rigDescendant.Parent
					and rigDescendant.Parent:IsA("BasePart")
					and rigDescendant.Parent.Parent == model then
					local weld = Instance.new("Weld")
					weld.Name = "AccessoryWeld"
					weld.Part0 = rigDescendant.Parent
					weld.Part1 = handle
					weld.C0 = rigDescendant.CFrame
					weld.C1 = handleDescendant.CFrame
					weld.Parent = handle
					return
				end
			end
		end
	end

	-- Captain Zombie's custom Pirate Hat and some legacy hats have no Handle
	-- Attachment, so align the Handle from the Accoutrement's AttachmentPoint.
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local weld = Instance.new("Weld")
		weld.Name = "AccessoryWeld"
		weld.Part0 = head
		weld.Part1 = handle
		weld.C0 = accoutrement.AttachmentPoint
		weld.C1 = CFrame.identity
		weld.Parent = handle
	else
		warn("Captain Zombie could not find a Head to attach:", accoutrement.Name)
	end
end

local function addCaptainZombieAccessory(
	model: Model,
	humanoid: Humanoid,
	accessory: Accessory
)
	humanoid:AddAccessory(accessory)
	ensureCaptainZombieAccessoryAttached(model, accessory)
end

local function restoreCaptainZombieOriginalInstance(
	model: Model,
	humanoid: Humanoid?,
	instance: Instance
)
	local parentableInstance: Instance = instance

	if instance:IsA("Accoutrement") then
		removeCaptainZombieAccessoryJoints(model, instance)

		if instance:IsA("Accessory") and humanoid then
			local ok, err = pcall(function()
				humanoid:AddAccessory(instance)
			end)
			if not ok then
				warn("Captain Zombie: AddAccessory failed for", instance.Name, err)
				parentableInstance.Parent = model
			end
		else
			parentableInstance.Parent = model
		end

		-- Verify/rebuild the attachment: a legacy Hat, or an accessory without a matching weld,
		-- needs this fallback.
		ensureCaptainZombieAccessoryAttached(model, instance :: Accoutrement)
	else
		parentableInstance.Parent = model
	end
end

local function applyCaptainZombieHalloween(parent: any)
	local zombie = parent:FindFirstChild("Zombie")
	if not zombie or not zombie:IsA("Humanoid") then
		warn("Captain Zombie Halloween transformation: missing Humanoid 'Zombie' in", parent:GetFullName())
		return
	end

	clearHalloweenObjectsForKiller(parent, CAPTAIN_ZOMBIE_KILLER_NAME)
	local kraken: Accessory = Instance.new("Accessory")

	kraken.Name = "Kraken"
	kraken.AccessoryType = Enum.AccessoryType.Back

	local handle: Part = Instance.new("Part")

	handle.Name = "Handle"
	handle.Color = Color3.fromRGB(123, 0, 123)
	handle.Material = Enum.Material.Concrete
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.Shape = Enum.PartType.Ball
	handle.Size = Vector3.new(3, 3, 3)
	handle.Parent = kraken

	local bodyBackAttachment: Attachment = Instance.new("Attachment")

	bodyBackAttachment.Name = "BodyBackAttachment"

	local v5 = CFrame.Angles(0, 0.3490658503988659, 0)

	bodyBackAttachment.CFrame = CFrame.new(-0.8, -0.8, -1.25) * v5
	bodyBackAttachment.Parent = handle

	local function CreateKrakenEye(p5, c0)
		local color3 = Color3.fromRGB(17, 17, 17)
		local part: Part = Instance.new("Part")

		part.Name = "Eye" .. p5
		part.Color = color3
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.Parent = kraken

		local weld: Weld = Instance.new("Weld")

		weld.Part0 = handle
		weld.Part1 = part
		weld.C0 = c0
		weld.Parent = part
		part.Size = Vector3.new(0.5, 0.5, 0.5)

		local specialMesh: SpecialMesh = Instance.new("SpecialMesh")

		specialMesh.MeshType = Enum.MeshType.FileMesh
		specialMesh.MeshId = "http://www.roblox.com/asset/?id=7318166"
		specialMesh.Scale = Vector3.new(-0.53, -0.53, -0.53)
		specialMesh.Parent = part

		local color32 = Color3.fromRGB(255, 102, 204)
		local part2: Part = Instance.new("Part")

		part2.Name = "KrakenPupil" .. p5
		part2.Color = color32
		part2.CanCollide = false
		part2.CanQuery = false
		part2.CanTouch = false
		part2.Massless = true
		part2.Parent = kraken

		local weld2: Weld = Instance.new("Weld")

		weld2.Part0 = handle
		weld2.Part1 = part2
		weld2.C0 = c0
		weld2.Parent = part2
		part2.Material = Enum.Material.Neon
		part2.Shape = Enum.PartType.Ball
		part2.Size = Vector3.new(0.3, 0.3, 0.3)
	end

	v5 = function(p9, c0)
		local color3 = Color3.fromRGB(123, 0, 123)
		local part: Part = Instance.new("Part")

		part.Name = "Tentacle" .. p9
		part.Color = color3
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.Parent = kraken

		local weld: Weld = Instance.new("Weld")

		weld.Part0 = handle
		weld.Part1 = part
		weld.C0 = c0
		weld.Parent = part
		part.Material = Enum.Material.Concrete
		part.Size = Vector3.new(1, 1.6, 1)

		local specialMesh: SpecialMesh = Instance.new("SpecialMesh")

		specialMesh.MeshType = Enum.MeshType.FileMesh
		specialMesh.MeshId = "http://www.roblox.com/asset/?id=27492984"
		specialMesh.Parent = part
	end

	local color3 = Color3.fromRGB(123, 0, 123)
	local v10 = CFrame.Angles(0, 0, -0.7853981633974483)
	local headUp: Part = Instance.new("Part")

	headUp.Name = "HeadUp"
	headUp.Color = color3
	headUp.CanCollide = false
	headUp.CanQuery = false
	headUp.CanTouch = false
	headUp.Massless = true
	headUp.Parent = kraken

	local weld: Weld = Instance.new("Weld")

	weld.Part0 = handle
	weld.Part1 = headUp
	weld.C0 = CFrame.new(0.57, 0.56, 0) * v10
	weld.Parent = headUp
	headUp.Material = Enum.Material.Concrete
	headUp.Shape = Enum.PartType.Ball
	headUp.Size = Vector3.new(3, 3, 3)

	local color33 = Color3.fromRGB(123, 0, 123)
	local headLow: Part = Instance.new("Part")

	headLow.Name = "HeadLow"
	headLow.Color = color33
	headLow.CanCollide = false
	headLow.CanQuery = false
	headLow.CanTouch = false
	headLow.Massless = true
	headLow.Parent = kraken

	local weld3: Weld = Instance.new("Weld")

	weld3.Part0 = handle
	weld3.Part1 = headLow
	weld3.C0 = CFrame.new(0, -0.6, -0.6)
	weld3.Parent = headLow
	headLow.Material = Enum.Material.Concrete
	headLow.Shape = Enum.PartType.Ball
	headLow.Size = Vector3.new(2.2, 2.2, 2.2)

	local v16 = CFrame.Angles(0, 0, -0.7853981633974483)

	CreateKrakenEye("Center", CFrame.new(0.53, 0.38, -1.75) * v16)
	v16 = CFrame.Angles(0, 0, -0.7853981633974483)
	CreateKrakenEye("Left", CFrame.new(0.57, 0.95, -1.7) * v16)
	v16 = CFrame.Angles(0, 0, -0.7853981633974483)
	CreateKrakenEye("Right", CFrame.new(0.96, 0, -1.7) * v16)

	local color34 = Color3.fromRGB(17, 17, 17)

	v10 = CFrame.Angles(0, 0, -1.8325957145940461)

	local eyebrowLeft: Part = Instance.new("Part")

	eyebrowLeft.Name = "EyebrowLeft"
	eyebrowLeft.Color = color34
	eyebrowLeft.CanCollide = false
	eyebrowLeft.CanQuery = false
	eyebrowLeft.CanTouch = false
	eyebrowLeft.Massless = true
	eyebrowLeft.Parent = kraken

	local weld4: Weld = Instance.new("Weld")

	weld4.Part0 = handle
	weld4.Part1 = eyebrowLeft
	weld4.C0 = CFrame.new(0.95, 1.02, -1.7) * v10
	weld4.Parent = eyebrowLeft
	eyebrowLeft.Size = Vector3.new(0.5, 0.1, 0.15)

	local color35 = Color3.fromRGB(17, 17, 17)

	v10 = CFrame.Angles(0, 0, -0.2617993877991494)

	local eyebrowRight: Part = Instance.new("Part")

	eyebrowRight.Name = "EyebrowRight"
	eyebrowRight.Color = color35
	eyebrowRight.CanCollide = false
	eyebrowRight.CanQuery = false
	eyebrowRight.CanTouch = false
	eyebrowRight.Massless = true
	eyebrowRight.Parent = kraken

	local weld5: Weld = Instance.new("Weld")

	weld5.Part0 = handle
	weld5.Part1 = eyebrowRight
	weld5.C0 = CFrame.new(1.17, 0.3, -1.7) * v10
	weld5.Parent = eyebrowRight
	eyebrowRight.Size = Vector3.new(0.5, 0.1, 0.15)

	local v23 = CFrame.fromEulerAnglesYXZ(0.7853981633974483, 1.5707963267948966, 0.7853981633974483)
	local color36 = Color3.fromRGB(123, 47, 123)
	local part: Part = Instance.new("Part")

	part.Name = "Spot" .. 1
	part.Color = color36
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Parent = kraken

	local weld6: Weld = Instance.new("Weld")

	weld6.Part0 = handle
	weld6.Part1 = part
	weld6.C0 = CFrame.new(1.29, 1.28, -1.02) * v23
	weld6.Parent = part
	part.Material = Enum.Material.Pebble
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.15, 0.8, 0.8)
	v23 = CFrame.Angles(0, 0, -1.5707963267948966)

	local color37 = Color3.fromRGB(123, 47, 123)
	local part3: Part = Instance.new("Part")

	part3.Name = "Spot" .. 2
	part3.Color = color37
	part3.CanCollide = false
	part3.CanQuery = false
	part3.CanTouch = false
	part3.Massless = true
	part3.Parent = kraken

	local weld7: Weld = Instance.new("Weld")

	weld7.Part0 = handle
	weld7.Part1 = part3
	weld7.C0 = CFrame.new(0.57, 2, 0) * v23
	weld7.Parent = part3
	part3.Material = Enum.Material.Pebble
	part3.Shape = Enum.PartType.Cylinder
	part3.Size = Vector3.new(0.15, 0.8, 0.8)
	v23 = CFrame.fromEulerAnglesYXZ(0.7853981633974483, 1.5707963267948966, -0.7853981633974483)

	local color38 = Color3.fromRGB(123, 47, 123)
	local part4: Part = Instance.new("Part")

	part4.Name = "Spot" .. 3
	part4.Color = color38
	part4.CanCollide = false
	part4.CanQuery = false
	part4.CanTouch = false
	part4.Massless = true
	part4.Parent = kraken

	local weld8: Weld = Instance.new("Weld")

	weld8.Part0 = handle
	weld8.Part1 = part4
	weld8.C0 = CFrame.new(1.29, 1.28, 1.02) * v23
	weld8.Parent = part4
	part4.Material = Enum.Material.Pebble
	part4.Shape = Enum.PartType.Cylinder
	part4.Size = Vector3.new(0.15, 0.8, 0.8)
	v23 = CFrame.Angles(0, 0, 3.141592653589793)

	local color39 = Color3.fromRGB(123, 47, 123)
	local part5: Part = Instance.new("Part")

	part5.Name = "Spot" .. 4
	part5.Color = color39
	part5.CanCollide = false
	part5.CanQuery = false
	part5.CanTouch = false
	part5.Massless = true
	part5.Parent = kraken

	local weld9: Weld = Instance.new("Weld")

	weld9.Part0 = handle
	weld9.Part1 = part5
	weld9.C0 = CFrame.new(2, 0.56, 0) * v23
	weld9.Parent = part5
	part5.Material = Enum.Material.Pebble
	part5.Shape = Enum.PartType.Cylinder
	part5.Size = Vector3.new(0.15, 0.8, 0.8)
	v23 = CFrame.Angles(0, 0, -0.7853981633974483)

	local color310 = Color3.fromRGB(123, 47, 123)
	local part6: Part = Instance.new("Part")

	part6.Name = "Spot" .. 5
	part6.Color = color310
	part6.CanCollide = false
	part6.CanQuery = false
	part6.CanTouch = false
	part6.Massless = true
	part6.Parent = kraken

	local weld10: Weld = Instance.new("Weld")

	weld10.Part0 = handle
	weld10.Part1 = part6
	weld10.C0 = CFrame.new(1.37, -0.67, 0) * v23
	weld10.Parent = part6
	part6.Material = Enum.Material.Pebble
	part6.Shape = Enum.PartType.Cylinder
	part6.Size = Vector3.new(0.15, 0.8, 0.8)
	v23 = CFrame.fromEulerAnglesYXZ(0.7853981633974483, 1.5707963267948966, 0)

	local color311 = Color3.fromRGB(123, 47, 123)
	local part7: Part = Instance.new("Part")

	part7.Name = "Spot" .. 6
	part7.Color = color311
	part7.CanCollide = false
	part7.CanQuery = false
	part7.CanTouch = false
	part7.Massless = true
	part7.Parent = kraken

	local weld11: Weld = Instance.new("Weld")

	weld11.Part0 = handle
	weld11.Part1 = part7
	weld11.C0 = CFrame.new(0.36, 0.34, 1.43) * v23
	weld11.Parent = part7
	part7.Material = Enum.Material.Pebble
	part7.Shape = Enum.PartType.Cylinder
	part7.Size = Vector3.new(0.15, 0.8, 0.8)
	v23 = CFrame.Angles(0, 0, -0.7853981633974483)

	local color312 = Color3.fromRGB(123, 47, 123)
	local part8: Part = Instance.new("Part")

	part8.Name = "Spot" .. 7
	part8.Color = color312
	part8.CanCollide = false
	part8.CanQuery = false
	part8.CanTouch = false
	part8.Massless = true
	part8.Parent = kraken

	local weld12: Weld = Instance.new("Weld")

	weld12.Part0 = handle
	weld12.Part1 = part8
	weld12.C0 = CFrame.new(-0.65, 1.36, 0) * v23
	weld12.Parent = part8
	part8.Material = Enum.Material.Pebble
	part8.Shape = Enum.PartType.Cylinder
	part8.Size = Vector3.new(0.15, 0.8, 0.8)

	local color313 = Color3.fromRGB(13, 105, 172)

	v10 = CFrame.fromEulerAnglesYXZ(0.7853981633974483, 1.5707963267948966, 1.5707963267948966)

	local weakPoint: Part = Instance.new("Part")

	weakPoint.Name = "WeakPoint"
	weakPoint.Color = color313
	weakPoint.CanCollide = false
	weakPoint.CanQuery = false
	weakPoint.CanTouch = false
	weakPoint.Massless = true
	weakPoint.Parent = kraken

	local weld13: Weld = Instance.new("Weld")

	weld13.Part0 = handle
	weld13.Part1 = weakPoint
	weld13.C0 = CFrame.new(1.59, 1.57, 0) * v10
	weld13.Parent = weakPoint
	weakPoint.Material = Enum.Material.Pebble
	weakPoint.Shape = Enum.PartType.Cylinder
	weakPoint.Size = Vector3.new(0.2, 0.8, 0.8)
	v10 = CFrame.Angles(-0.06981317007977318, -0.7853981633974483, -1.3089969389957472)
	v5(1, CFrame.new(-1.5, 0.25, -0.8) * v10)
	v10 = CFrame.Angles(0, 0.3490658503988659, -0.7853981633974483)
	v5(2, CFrame.new(-1.73, -0.3, 0.04) * v10)
	v10 = CFrame.Angles(0, 0.3490658503988659, -1.8675022996339325)
	v5(3, CFrame.new(-1.22, 0.36, 0.81) * v10)
	v10 = CFrame.fromEulerAnglesYXZ(-1.2217304763960306, 1.5707963267948966, 2.792526803190927)
	v5(4, CFrame.new(0, -1.1, -1.8) * v10)
	v10 = CFrame.Angles(0.13962634015954636, 0.3490658503988659, 0.5235987755982988)
	v5(5, CFrame.new(1.14, -1.04, -0.63) * v10)
	v10 = CFrame.fromEulerAnglesYXZ(-0.5235987755982988, 2.443460952792061, 0)
	v5(6, CFrame.new(0.89, -1.4, 0.41) * v10)
	markHalloweenObjectForKiller(kraken, CAPTAIN_ZOMBIE_KILLER_NAME)
	addCaptainZombieAccessory(parent, zombie, kraken)

	local eyeLeft: Part = Instance.new("Part")

	eyeLeft.Name = "EyeLeft"
	eyeLeft.Color = Color3.fromRGB(255, 102, 204)
	eyeLeft.Material = Enum.Material.Neon
	eyeLeft.Size = Vector3.new(0.3, 0.1, 0.3)
	eyeLeft.CanCollide = false
	eyeLeft.CanQuery = false
	eyeLeft.CanTouch = false
	eyeLeft.Massless = true

	local specialMesh: SpecialMesh = Instance.new("SpecialMesh")

	specialMesh.MeshType = Enum.MeshType.FileMesh
	specialMesh.MeshId = "http://www.roblox.com/asset/?id=9604077649"
	specialMesh.Scale = Vector3.new(0.01, 0.01, 0.01)
	specialMesh.Parent = eyeLeft

	local weld14: Weld = Instance.new("Weld")

	weld14.Part0 = parent.Head
	weld14.Part1 = eyeLeft
	v23 = CFrame.fromEulerAnglesYXZ(1.5707963267948966, 0.2617993877991494, 0)
	weld14.C0 = CFrame.new(-0.2, 0.1, -0.58) * v23
	weld14.Parent = eyeLeft
	markHalloweenObjectForKiller(eyeLeft, CAPTAIN_ZOMBIE_KILLER_NAME)
	eyeLeft.Parent = parent

	local eyeRight: Part = Instance.new("Part")

	eyeRight.Name = "EyeRight"
	eyeRight.Color = Color3.fromRGB(255, 102, 204)
	eyeRight.Material = Enum.Material.Neon
	eyeRight.Size = Vector3.new(0.3, 0.1, 0.3)
	eyeRight.CanCollide = false
	eyeRight.CanQuery = false
	eyeRight.CanTouch = false
	eyeRight.Massless = true

	local specialMesh2: SpecialMesh = Instance.new("SpecialMesh")

	specialMesh2.MeshType = Enum.MeshType.FileMesh
	specialMesh2.MeshId = "http://www.roblox.com/asset/?id=9604077649"
	specialMesh2.Scale = Vector3.new(0.01, 0.01, 0.01)
	specialMesh2.Parent = eyeRight

	local weld15: Weld = Instance.new("Weld")

	weld15.Part0 = parent.Head
	weld15.Part1 = eyeRight
	v23 = CFrame.fromEulerAnglesYXZ(1.5707963267948966, -0.2617993877991494, 0)
	weld15.C0 = CFrame.new(0.2, 0.1, -0.58) * v23
	weld15.Parent = eyeRight
	markHalloweenObjectForKiller(eyeRight, CAPTAIN_ZOMBIE_KILLER_NAME)
	eyeRight.Parent = parent

	local shadowHead: Part = Instance.new("Part")

	shadowHead.Name = "ShadowHead"
	shadowHead.Transparency = 1
	shadowHead.Size = Vector3.new(1.225, 1.225, 1.225)
	shadowHead.CanCollide = false
	shadowHead.CanTouch = false
	shadowHead.CanQuery = false
	shadowHead.Massless = true
	shadowHead.Shape = Enum.PartType.Cylinder

	local texture: Texture = Instance.new("Texture")

	texture.Texture = "http://www.roblox.com/asset/?id=15791621722"
	texture.Face = Enum.NormalId.Front
	texture.OffsetStudsV = 1.2
	texture.Rotation = 270
	texture.StudsPerTileU = 2
	texture.StudsPerTileV = 5
	texture.Parent = shadowHead

	local clone: Texture = texture:Clone() :: Texture

	clone.Face = Enum.NormalId.Top
	clone.Parent = shadowHead

	local clone2: Texture = texture:Clone() :: Texture

	clone2.Face = Enum.NormalId.Bottom
	clone2.Parent = shadowHead

	local clone3: Texture = texture:Clone() :: Texture

	clone3.Face = Enum.NormalId.Back
	clone3.Rotation = 90
	clone3.Parent = shadowHead

	local weld16: Weld = Instance.new("Weld")

	weld16.Part0 = parent.Head
	weld16.Part1 = shadowHead
	weld16.C0 = CFrame.Angles(0, 0, 1.5707963267948966)
	weld16.Parent = shadowHead
	markHalloweenObjectForKiller(shadowHead, CAPTAIN_ZOMBIE_KILLER_NAME)
	shadowHead.Parent = parent

	local accessory: Accessory = Instance.new("Accessory")

	accessory.Name = "Pirate Hat"
	accessory.AccessoryType = Enum.AccessoryType.Hat
	v10 = CFrame.Angles(0.17453292519943295, 0, 0)
	accessory.AttachmentPoint = CFrame.new(0, -0.5, 0) * v10

	local part9: Part = Instance.new("Part")

	part9.Name = "Handle"
	part9.CanCollide = false
	part9.CanQuery = false
	part9.CanTouch = false
	part9.Massless = true
	part9.Size = Vector3.new(2, 2, 2)
	part9.Parent = accessory

	local specialMesh3: SpecialMesh = Instance.new("SpecialMesh")

	specialMesh3.MeshType = Enum.MeshType.FileMesh
	specialMesh3.MeshId = "http://www.roblox.com/asset/?id=752637790"
	specialMesh3.TextureId = "http://www.roblox.com/asset/?id=752637984"
	specialMesh3.Scale = Vector3.new(0.6, 0.6, 0.6)
	specialMesh3.Parent = part9
	markHalloweenObjectForKiller(accessory, CAPTAIN_ZOMBIE_KILLER_NAME)
	addCaptainZombieAccessory(parent, zombie, accessory)
	detachCaptainZombieOriginal(parent, "Brain")
	detachCaptainZombieOriginal(parent, "Black Leather Tricorne")
	parent.Head.face.Color3 = Color3.fromRGB(255, 0, 255)
	parent.Shirt.Color3 = Color3.fromRGB(255, 90, 156)
	parent["Body Colors"].HeadColor3 = Color3.fromRGB(89, 34, 89)
	parent["Body Colors"].TorsoColor3 = Color3.fromRGB(89, 34, 89)
	parent["Body Colors"].LeftArmColor3 = Color3.fromRGB(89, 34, 89)
	parent["Body Colors"].RightArmColor3 = Color3.fromRGB(89, 34, 89)
	parent["Body Colors"].LeftLegColor3 = Color3.fromRGB(89, 34, 89)
	parent["Body Colors"].RightLegColor3 = Color3.fromRGB(89, 34, 89)
	parent.LeftLowerLeg.SurfaceAppearance.Color = Color3.fromRGB(89, 34, 89)
	parent.LeftFoot.SurfaceAppearance.Color = Color3.fromRGB(89, 34, 89)
	parent.Sword.Handle.Mesh.TextureId = "http://www.roblox.com/asset/?id=14969597941"
	parent.Sword.Handle.Mesh.VertexColor = Vector3.new(1, 0, 1)
	parent.Sword.Handle.PointLight.Color = Color3.fromRGB(170, 0, 30)
	parent.Sword.Handle.Fire.Color = Color3.fromRGB(20, 0, 50)
	parent.Sword.Handle.Fire.SecondaryColor = Color3.fromRGB(170, 0, 30)
end

local function restoreCaptainZombieNormal(model: Model)
	clearHalloweenObjectsForKiller(model, CAPTAIN_ZOMBIE_KILLER_NAME)

	-- Restore the original objects from an in-model folder. Unlike a Lua table,
	-- this survives requiring this ModuleScript again between transformations.
	local preservedFolder = getCaptainZombiePreservedFolder(model, false)
	if preservedFolder then
		local zombie = model:FindFirstChild("Zombie")
		local humanoid = zombie and zombie:IsA("Humanoid") and zombie or nil
		local preservedInstances = preservedFolder:GetChildren()

		for _, instance in ipairs(preservedInstances) do
			local restored, err = pcall(function()
				restoreCaptainZombieOriginalInstance(
					model,
					humanoid :: Humanoid?,
					instance
				)
			end)

			if not restored then
				warn(
					"Captain Zombie: failed to restore original instance:",
					instance.Name,
					err
				)
			end
		end

		preservedFolder:Destroy()
	end

	local head = model:FindFirstChild("Head")
	local face = head and head:FindFirstChild("face")
	if face and face:IsA("Decal") then
		face.Color3 = Color3.fromRGB(255, 255, 255)
	end

	local shirt = model:FindFirstChildOfClass("Shirt")
	if shirt then
		shirt.Color3 = Color3.fromRGB(255, 255, 255)
	end

	for _, partName in ipairs({ "LeftLowerLeg", "LeftFoot" }) do
		local part = model:FindFirstChild(partName)
		local surfaceAppearance = part and part:FindFirstChildOfClass("SurfaceAppearance")
		if surfaceAppearance then
			surfaceAppearance.Color = Color3.fromRGB(255, 255, 255)
		end
	end

	local sword = model:FindFirstChild("Sword")
	local handle = sword and sword:FindFirstChild("Handle")
	if handle then
		local mesh = handle:FindFirstChild("Mesh")
		if mesh and mesh:IsA("SpecialMesh") then
			mesh.TextureId = "http://www.roblox.com/asset/?id=7505486794"
			mesh.VertexColor = Vector3.new(1, 1, 1)
		end

		local pointLight = handle:FindFirstChildOfClass("PointLight")
		if pointLight then
			pointLight.Color = Color3.fromRGB(0, 170, 0)
		end

		local fire = handle:FindFirstChildOfClass("Fire")
		if fire then
			fire.Color = Color3.fromRGB(0, 128, 0)
			fire.SecondaryColor = Color3.fromRGB(0, 50, 0)
		end
	end
end

TRANSFORMATIONS[CAPTAIN_ZOMBIE_KILLER_NAME] = {
	Halloween = {
		bodyColors = {
			HeadColor3 = Color3.fromRGB(89, 34, 89),
			TorsoColor3 = Color3.fromRGB(89, 34, 89),
			LeftArmColor3 = Color3.fromRGB(89, 34, 89),
			RightArmColor3 = Color3.fromRGB(89, 34, 89),
			LeftLegColor3 = Color3.fromRGB(89, 34, 89),
			RightLegColor3 = Color3.fromRGB(89, 34, 89),
		},
		clothingColor = Color3.fromRGB(255, 90, 156),
		applyCustom = applyCaptainZombieHalloween,
	},
	Normal = {
		bodyColors = {
			HeadColor3 = Color3.fromRGB(75, 151, 75),
			TorsoColor3 = Color3.fromRGB(0, 255, 0),
			LeftArmColor3 = Color3.fromRGB(75, 151, 75),
			RightArmColor3 = Color3.fromRGB(75, 151, 75),
			LeftLegColor3 = Color3.fromRGB(75, 151, 75),
			RightLegColor3 = Color3.fromRGB(75, 151, 75),
		},
		clothingColor = Color3.fromRGB(255, 255, 255),
		applyCustom = restoreCaptainZombieNormal,
	},
}

-- Accessories written for the legacy AttachmentPoint path own no Handle Attachment, which gives an
-- unreliable joint on this rig. Each such Handle therefore gets a "HatAttachment" at its
-- AttachmentPoint and joins Head.HatAttachment through the same attachment-based RigidConstraint
-- the rig's own accessories use.
--
-- Hair Handles own an "OriginalSize" Vector3Value that the humanoid scaling system uses to rebuild
-- Handle.Size, so it is updated together with Size, and the hair is edited AFTER the accessories
-- are added.
local CHUCKY_KILLER_NAME = "Chucky"
local CHUCKY_NORMAL_BODY_COLOR = Color3.fromRGB(204, 142, 105)
local CHUCKY_NORMAL_SHIRT_TEMPLATE = "http://www.roblox.com/asset/?id=15758951994"
local CHUCKY_NORMAL_PANTS_TEMPLATE = "http://www.roblox.com/asset/?id=15758953576"
local CHUCKY_HALLOWEEN_SHIRT_TEMPLATE = "http://www.roblox.com/asset/?id=13405588887"
local CHUCKY_HALLOWEEN_PANTS_TEMPLATE = "http://www.roblox.com/asset/?id=13405595303"
local CHUCKY_NORMAL_HAIR_SIZE = Vector3.new(1.7374468, 1.6654009, 1.7775795)
local CHUCKY_NORMAL_HAIR_ORIGINAL_SIZE = Vector3.new(2.0440550, 1.9592950, 2.0912700)
local CHUCKY_NORMAL_HAIR_COLOR = Color3.fromRGB(150, 70, 0)
local CHUCKY_NORMAL_HAIR_ATTACHMENT_CFRAME = CFrame.new(0.085, 0.425, -0.1702314)
local CHUCKY_HALLOWEEN_HAIR_ATTACHMENT_CFRAME = CFrame.new(0.085, 1, -0.17)
local CHUCKY_HALLOWEEN_HAIR_HEIGHT_SCALE = Vector3.new(1, 0.8, 1)
local CHUCKY_HALLOWEEN_HAIR_COLOR = Color3.fromRGB(248, 248, 248)

-- Name shared by the Handle attachment and Head.HatAttachment for every
-- Halloween accessory that used to rely on AttachmentPoint.
local CHUCKY_HAT_POINT_ATTACHMENT = "HatAttachment"
local CHUCKY_CLOAK_ATTACHMENT = "BodyFrontAttachment"

-- True if anything already joins this Handle to the rig: a classic Weld/Motor6D,
-- a WeldConstraint, or the RigidConstraint this rig uses for accessories.
local function isHandleJoined(model: Model, handle: BasePart): boolean
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("JointInstance") then
			if descendant.Part0 == handle or descendant.Part1 == handle then
				return true
			end
		elseif descendant:IsA("WeldConstraint") then
			if descendant.Part0 == handle or descendant.Part1 == handle then
				return true
			end
		elseif descendant:IsA("RigidConstraint") then
			local attachment0 = descendant.Attachment0
			local attachment1 = descendant.Attachment1
			if (attachment0 and attachment0.Parent == handle)
				or (attachment1 and attachment1.Parent == handle) then
				return true
			end
		end
	end

	return false
end

-- The rig-side attachment an accessory pairs with. Only the rig's own body parts
-- (direct children of the model) are searched, never another accessory's Handle,
-- so two hats that both own a "HatAttachment" cannot pair with each other.
local function findChuckyRigAttachment(model: Model, attachmentName: string): Attachment?
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			local attachment = child:FindFirstChild(attachmentName)
			if attachment and attachment:IsA("Attachment") then
				return attachment
			end
		end
	end

	return nil
end

-- Moves the Handle (and anything Weld'ed to it, e.g. the beard worms) to where
-- the attachment pair will put it, so a freshly built accessory never flashes at
-- the world origin before the joint solves.
local function snapChuckyAccessory(model: Model, accessory: Accessory, attachmentName: string)
	local handle = accessory:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return
	end

	local rigAttachment = findChuckyRigAttachment(model, attachmentName)
	local handleAttachment = handle:FindFirstChild(attachmentName)
	if rigAttachment and handleAttachment and handleAttachment:IsA("Attachment") then
		handle.CFrame = rigAttachment.WorldCFrame * handleAttachment.CFrame:Inverse()
	end

	for _, descendant in ipairs(accessory:GetDescendants()) do
		if descendant:IsA("Weld") and descendant.Part0 == handle then
			local welded = descendant.Part1
			if welded then
				welded.CFrame = handle.CFrame * descendant.C0 * descendant.C1:Inverse()
			end
		end
	end
end

-- Safety net only: if Humanoid:AddAccessory (or an earlier edit) left the Handle
-- unjoined, create the same attachment-pair RigidConstraint the rig's own
-- accessories use. Does nothing when a joint already exists, so it cannot
-- double-weld.
local function ensureChuckyHandleJoined(model: Model, handle: BasePart, attachmentName: string)
	if isHandleJoined(model, handle) then
		return
	end

	local rigAttachment = findChuckyRigAttachment(model, attachmentName)
	local handleAttachment = handle:FindFirstChild(attachmentName)
	if not rigAttachment
		or not handleAttachment
		or not handleAttachment:IsA("Attachment") then
		warn("Halloween transformation: cannot join", handle:GetFullName(), "- missing attachment", attachmentName)
		return
	end

	handle.CFrame = rigAttachment.WorldCFrame * handleAttachment.CFrame:Inverse()

	local constraint = Instance.new("RigidConstraint")
	constraint.Name = "AccessoryRigidConstraint"
	constraint.Attachment0 = handleAttachment
	constraint.Attachment1 = rigAttachment
	constraint.Parent = handle
end

-- Leaves exactly ONE joint on this Handle: a RigidConstraint pairing the Handle's
-- attachment with the rig's own body-part attachment. Anything else touching the
-- Handle that is a rig joint (a second constraint from a race with the engine's
-- AddAccessory, a legacy AccessoryWeld, or a constraint that paired with another
-- accessory's Handle instead of the rig) is removed. The beard worms' Welds are
-- not rig joints and are never touched. Creates the constraint if none is correct,
-- so the Handle can never be left unjoined (and fall through the floor).
local function normalizeChuckyHandleJoint(model: Model, handle: BasePart, attachmentName: string)
	local rigAttachment = findChuckyRigAttachment(model, attachmentName)
	local handleAttachment = handle:FindFirstChild(attachmentName)
	if not rigAttachment
		or not handleAttachment
		or not handleAttachment:IsA("Attachment") then
		warn("Halloween transformation: cannot join", handle:GetFullName(), "- missing attachment", attachmentName)
		return
	end

	local good: RigidConstraint? = nil
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("RigidConstraint") then
			local a0 = descendant.Attachment0
			local a1 = descendant.Attachment1
			local touchesHandle = (a0 ~= nil and a0.Parent == handle) or (a1 ~= nil and a1.Parent == handle)
			if touchesHandle then
				local correct = (a0 == handleAttachment and a1 == rigAttachment)
					or (a1 == handleAttachment and a0 == rigAttachment)
				if correct and good == nil then
					good = descendant
				else
					descendant:Destroy()
				end
			end
		elseif descendant:IsA("JointInstance") and descendant.Name == "AccessoryWeld" then
			if descendant.Part0 == handle or descendant.Part1 == handle then
				descendant:Destroy()
			end
		end
	end

	handle.CFrame = rigAttachment.WorldCFrame * handleAttachment.CFrame:Inverse()

	if good == nil then
		local constraint = Instance.new("RigidConstraint")
		constraint.Name = "AccessoryRigidConstraint"
		constraint.Attachment0 = handleAttachment
		constraint.Attachment1 = rigAttachment
		constraint.Parent = handle
	end
end

-- Removes accessories with the Halloween names that this module did not create (e.g. left by the
-- game's own script) so they do not stack on ours.
local CHUCKY_HALLOWEEN_ACCESSORY_NAMES = {
	PartyHat = true,
	Beard = true,
	TopTeeth = true,
	BottomTeeth = true,
	Cloak = true,
}

local function clearChuckyStrayAccessories(model: Model)
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") and CHUCKY_HALLOWEEN_ACCESSORY_NAMES[child.Name] then
			child:Destroy()
		end
	end
end

local function setChuckyHair(model: Model, halloween: boolean)
	local hair = model:FindFirstChild("MessyHairBrown")
	local handle = hair and hair:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		warn("Chucky transformation: MessyHairBrown.Handle was not found in", model:GetFullName())
		return
	end

	local size = CHUCKY_NORMAL_HAIR_SIZE
	local originalSize = CHUCKY_NORMAL_HAIR_ORIGINAL_SIZE
	local attachmentCFrame = CHUCKY_NORMAL_HAIR_ATTACHMENT_CFRAME
	local color = CHUCKY_NORMAL_HAIR_COLOR
	if halloween then
		size = CHUCKY_NORMAL_HAIR_SIZE * CHUCKY_HALLOWEEN_HAIR_HEIGHT_SCALE
		originalSize = CHUCKY_NORMAL_HAIR_ORIGINAL_SIZE * CHUCKY_HALLOWEEN_HAIR_HEIGHT_SCALE
		attachmentCFrame = CHUCKY_HALLOWEEN_HAIR_ATTACHMENT_CFRAME
		color = CHUCKY_HALLOWEEN_HAIR_COLOR
	end

	handle.Size = size
	handle.Color = color
	-- Keep the body-scaling baseline in step with the real size. Otherwise any
	-- later rescale (AddAccessory, a scale value changing) rebuilds Handle.Size
	-- from the stale OriginalSize and silently undoes the change.
	local originalSizeValue = handle:FindFirstChild("OriginalSize")
	if originalSizeValue and originalSizeValue:IsA("Vector3Value") then
		originalSizeValue.Value = originalSize
	end

	local hairAttachment = handle:FindFirstChild("HairAttachment")
	if hairAttachment and hairAttachment:IsA("Attachment") then
		hairAttachment.CFrame = attachmentCFrame
	else
		warn("Chucky transformation: MessyHairBrown.Handle.HairAttachment was not found in", model:GetFullName())
	end

	ensureChuckyHandleJoined(model, handle, "HairAttachment")
end

local function makeHalloweenHandle(name: string, size: Vector3, color: Color3?): Part
	local handle = Instance.new("Part")
	handle.Name = name
	handle.Size = size
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	if color then
		handle.Color = color
	end
	return handle
end

-- Gives a legacy (AttachmentPoint-only) Handle a real attachment at its AttachmentPoint so it
-- pairs with Head.HatAttachment.
local function addChuckyHatPointAttachment(accessory: Accessory, handle: BasePart)
	local attachment = Instance.new("Attachment")
	attachment.Name = CHUCKY_HAT_POINT_ATTACHMENT
	attachment.CFrame = accessory.AttachmentPoint
	attachment.Parent = handle
end

local function makeChuckyPartyHat(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "PartyHat"
	accessory.AccessoryType = Enum.AccessoryType.Hat
	accessory.AttachmentPoint = CFrame.new(0, -0.3, 0.1)
		* CFrame.Angles(0.17453292519943295, 0, 0)

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(160, 95, 53))
	handle.Material = Enum.Material.Plaster
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=1778999"
	mesh.Scale = Vector3.new(1.1, 1.1, 1.1)
	mesh.Parent = handle

	addChuckyHatPointAttachment(accessory, handle)

	return accessory
end

local function makeChuckyBeard(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Beard"
	accessory.AccessoryType = Enum.AccessoryType.Face
	accessory.AttachmentPoint = CFrame.new(0, 1.5, 0.35)
		* CFrame.Angles(-0.20943951023931956, 0, 0)

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(202, 203, 209))
	handle.Parent = accessory

	local beardMesh = Instance.new("SpecialMesh")
	beardMesh.MeshType = Enum.MeshType.FileMesh
	beardMesh.MeshId = "http://www.roblox.com/asset/?id=1031286239"
	beardMesh.Scale = Vector3.new(1, 1.2, 1)
	beardMesh.Parent = handle

	addChuckyHatPointAttachment(accessory, handle)

	local function addWorm(name: string, meshScale: Vector3, weldC0: CFrame)
		local worm = makeHalloweenHandle(name, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(170, 85, 0))
		worm.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=49046138"
		mesh.Scale = meshScale
		mesh.Parent = worm

		local weld = Instance.new("Weld")
		weld.Part0 = handle
		weld.Part1 = worm
		weld.C0 = weldC0
		weld.Parent = worm
	end

	addWorm(
		"Worm",
		Vector3.new(0.08, 0.1, 0.15),
		CFrame.new(0.3, -0.15, -0.1)
			* CFrame.fromEulerAnglesYXZ(-0.5235987755982988, 1.4835298641951802, -0.5235987755982988)
	)
	addWorm(
		"Worm",
		Vector3.new(0.133, 0.1, 0.15),
		CFrame.new(0, -0.22, -0.12)
			* CFrame.Angles(0, 1.5707963267948966, -0.6981317007977318)
	)
	addWorm(
		"Worm",
		Vector3.new(0.08, 0.1, 0.15),
		CFrame.new(-0.225, 0, -0.1)
			* CFrame.Angles(-2.356194490192345, 0, 1.5707963267948966)
	)

	return accessory
end

local function makeChuckyTeeth(name: string, attachmentPoint: CFrame, meshScale: Vector3): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = name
	accessory.AccessoryType = Enum.AccessoryType.Face
	accessory.AttachmentPoint = attachmentPoint

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 0.2, 1))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=100945333941344"
	mesh.TextureId = "http://www.roblox.com/asset/?id=123756392387946"
	mesh.Scale = meshScale
	mesh.Parent = handle

	addChuckyHatPointAttachment(accessory, handle)

	return accessory
end

local function makeChuckyCloak(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Cloak"
	accessory.AccessoryType = Enum.AccessoryType.Neck

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(17, 17, 17))
	handle.Material = Enum.Material.Plaster
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=19380188"
	mesh.Scale = Vector3.new(1.9, 1.1, 0.9)
	mesh.Parent = handle

	local attachment = Instance.new("Attachment")
	attachment.Name = CHUCKY_CLOAK_ATTACHMENT
	attachment.CFrame = CFrame.new(0, -0.525, -0.525)
	attachment.Parent = handle

	return accessory
end

-- attachmentName is the Handle/rig attachment pair the accessory joins through.
local function addMarkedHalloweenAccessory(
	model: Model,
	humanoid: Humanoid,
	accessory: Accessory,
	killerName: string,
	attachmentName: string
)
	markHalloweenObjectForKiller(accessory, killerName)

	-- Pre-position the Handle (and the beard worms) so nothing flashes at the
	-- origin before the joint solves.
	snapChuckyAccessory(model, accessory, attachmentName)

	local ok, err = pcall(function()
		humanoid:AddAccessory(accessory)
	end)
	if not ok then
		accessory:Destroy()
		warn(killerName .. ": Humanoid:AddAccessory failed:", err)
		return
	end

	local handle = accessory:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return
	end

	-- Settle the joint now, then once more at the end of the frame in case the
	-- engine finishes its own pairing late. Both passes leave a single correct joint.
	normalizeChuckyHandleJoint(model, handle, attachmentName)
	task.defer(function()
		if accessory.Parent == model then
			normalizeChuckyHandleJoint(model, handle, attachmentName)
		end
	end)
end

local function applyChuckyHalloween(model: Model)
	local zombie = model:FindFirstChild("Zombie")
	if not zombie or not zombie:IsA("Humanoid") then
		warn("Chucky Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName())
		return
	end

	clearHalloweenObjectsForKiller(model, CHUCKY_KILLER_NAME)
	clearChuckyStrayAccessories(model)

	local shirt = model:FindFirstChildOfClass("Shirt")
	if shirt then
		shirt.ShirtTemplate = CHUCKY_HALLOWEEN_SHIRT_TEMPLATE
	end

	local pants = model:FindFirstChildOfClass("Pants")
	if pants then
		pants.PantsTemplate = CHUCKY_HALLOWEEN_PANTS_TEMPLATE
	end

	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeChuckyPartyHat(),
		CHUCKY_KILLER_NAME,
		CHUCKY_HAT_POINT_ATTACHMENT
	)
	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeChuckyBeard(),
		CHUCKY_KILLER_NAME,
		CHUCKY_HAT_POINT_ATTACHMENT
	)
	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeChuckyTeeth(
			"TopTeeth",
			CFrame.new(0, -0.8, -0.1) * CFrame.Angles(math.pi, 0, 0),
			Vector3.new(0.8, 0.8, 0.8)
		),
		CHUCKY_KILLER_NAME,
		CHUCKY_HAT_POINT_ATTACHMENT
	)
	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeChuckyTeeth(
			"BottomTeeth",
			CFrame.new(0, 1.05, 0.125),
			Vector3.new(0.85, 0.85, 0.85)
		),
		CHUCKY_KILLER_NAME,
		CHUCKY_HAT_POINT_ATTACHMENT
	)
	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeChuckyCloak(),
		CHUCKY_KILLER_NAME,
		CHUCKY_CLOAK_ATTACHMENT
	)

	-- Hair changes must come after AddAccessory so that its rescale pass cannot
	-- overwrite them.
	setChuckyHair(model, true)
end

local function restoreChuckyNormal(model: Model)
	clearHalloweenObjectsForKiller(model, CHUCKY_KILLER_NAME)
	clearChuckyStrayAccessories(model)

	local shirt = model:FindFirstChildOfClass("Shirt")
	if shirt then
		shirt.ShirtTemplate = CHUCKY_NORMAL_SHIRT_TEMPLATE
		shirt.Color3 = Color3.fromRGB(255, 255, 255)
	end

	local pants = model:FindFirstChildOfClass("Pants")
	if pants then
		pants.PantsTemplate = CHUCKY_NORMAL_PANTS_TEMPLATE
		pants.Color3 = Color3.fromRGB(255, 255, 255)
	end

	setChuckyHair(model, false)
end

local EYELESS_JACK_KILLER_NAME = "Eyeless Jack"
local EYELESS_JACK_NORMAL_BODY_COLOR = Color3.fromRGB(0, 0, 0)
local EYELESS_JACK_NORMAL_SHIRT_COLOR = Color3.fromRGB(255, 255, 255)
local EYELESS_JACK_HALLOWEEN_SHIRT_COLOR = Color3.fromRGB(12, 0, 143)
local EYELESS_JACK_NORMAL_HOOD_SIZE = Vector3.new(1.8876, 2.00305, 1.8518)
local EYELESS_JACK_HALLOWEEN_HOOD_SCALE = 1.2
local EYELESS_JACK_HALLOWEEN_HOOD_ATTACHMENT_CFRAME = CFrame.new(0, 0.35, -0.05)
local EYELESS_JACK_NORMAL_HOOD_ATTACHMENT_CFRAME = CFrame.new(0, 0.5, -0.05027224)

local EYELESS_JACK_PUMPKIN_NAME = "Evil Pumpkin"
-- Head.FaceCenterAttachment is the head's centre. A Handle attachment of (0, -0.15, 0) places the
-- pumpkin centre 0.15 studs above it.
local EYELESS_JACK_PUMPKIN_ATTACHMENT_NAME = "FaceCenterAttachment"
local EYELESS_JACK_PUMPKIN_ATTACHMENT_CFRAME = CFrame.new(0, -0.15, 0)

local function makeEyelessJackPumpkin(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = EYELESS_JACK_PUMPKIN_NAME
	accessory.AccessoryType = Enum.AccessoryType.Face
	-- Only used by the engine's legacy fallback if the Head has no matching
	-- attachment; with the attachment below it is ignored.
	accessory.AttachmentPoint = CFrame.new(0, 0.45, 0)

	local handle = makeHalloweenHandle("Handle", Vector3.new(2, 2, 2))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=16973748"
	mesh.TextureId = "http://www.roblox.com/asset/?id=306368110"
	mesh.Scale = Vector3.new(0.9, 1, 0.8)
	mesh.Parent = handle

	local attachment = Instance.new("Attachment")
	attachment.Name = EYELESS_JACK_PUMPKIN_ATTACHMENT_NAME
	attachment.CFrame = EYELESS_JACK_PUMPKIN_ATTACHMENT_CFRAME
	attachment.Parent = handle

	return accessory
end

-- Safety net only: creates the attachment-pair RigidConstraint if the Handle is left unjoined.
-- Does nothing when a joint already exists.
local function ensureEyelessJackHandleJoined(model: Model, handle: BasePart, attachmentName: string)
	if isHandleJoined(model, handle) then
		return
	end

	local head = model:FindFirstChild("Head")
	local headAttachment = head and head:FindFirstChild(attachmentName)
	local handleAttachment = handle:FindFirstChild(attachmentName)
	if not headAttachment or not headAttachment:IsA("Attachment")
		or not handleAttachment or not handleAttachment:IsA("Attachment") then
		warn("Eyeless Jack transformation: cannot join", handle:GetFullName(), "- missing attachment", attachmentName)
		return
	end

	handle.CFrame = headAttachment.WorldCFrame * handleAttachment.CFrame:Inverse()

	local constraint = Instance.new("RigidConstraint")
	constraint.Name = "AccessoryRigidConstraint"
	constraint.Attachment0 = handleAttachment
	constraint.Attachment1 = headAttachment
	constraint.Parent = handle
end

local function setEyelessJackHood(model: Model, halloween: boolean)
	local hood = model:FindFirstChild("HoodOfTheLonelyRaven")
	local handle = hood and hood:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		warn("Eyeless Jack transformation: HoodOfTheLonelyRaven.Handle was not found in", model:GetFullName())
		return
	end

	local size = EYELESS_JACK_NORMAL_HOOD_SIZE
	local attachmentCFrame = EYELESS_JACK_NORMAL_HOOD_ATTACHMENT_CFRAME
	if halloween then
		size = EYELESS_JACK_NORMAL_HOOD_SIZE * EYELESS_JACK_HALLOWEEN_HOOD_SCALE
		attachmentCFrame = EYELESS_JACK_HALLOWEEN_HOOD_ATTACHMENT_CFRAME
	end

	handle.Size = size
	local originalSize = handle:FindFirstChild("OriginalSize")
	if originalSize and originalSize:IsA("Vector3Value") then
		originalSize.Value = size
	end

	local hatAttachment = handle:FindFirstChild("HatAttachment")
	if hatAttachment and hatAttachment:IsA("Attachment") then
		hatAttachment.CFrame = attachmentCFrame
		local originalPosition = hatAttachment:FindFirstChild("OriginalPosition")
		if originalPosition and originalPosition:IsA("Vector3Value") then
			originalPosition.Value = attachmentCFrame.Position
		end
	else
		warn("Eyeless Jack transformation: HoodOfTheLonelyRaven.Handle.HatAttachment was not found in", model:GetFullName())
	end

	ensureEyelessJackHandleJoined(model, handle, "HatAttachment")
end

local function setEyelessJackAppearance(model: Model, halloween: boolean)
	setEyelessJackHood(model, halloween)

	local hockeyMask = model:FindFirstChild("HockeyMask")
	local maskHandle = hockeyMask and hockeyMask:FindFirstChild("Handle")
	if maskHandle and maskHandle:IsA("BasePart") then
		maskHandle.Transparency = halloween and 1 or 0
		ensureEyelessJackHandleJoined(model, maskHandle, "FaceFrontAttachment")
	else
		warn("Eyeless Jack transformation: HockeyMask.Handle was not found in", model:GetFullName())
	end

	local shirt = model:FindFirstChildOfClass("Shirt")
	if shirt then
		shirt.Color3 = halloween and EYELESS_JACK_HALLOWEEN_SHIRT_COLOR or EYELESS_JACK_NORMAL_SHIRT_COLOR
	end
end

local function clearEyelessJackHalloweenObjects(model: Model)
	clearHalloweenObjectsForKiller(model, EYELESS_JACK_KILLER_NAME)

	-- Also removes an unmarked pumpkin left behind by older scripts.
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") and child.Name == EYELESS_JACK_PUMPKIN_NAME then
			child:Destroy()
		end
	end
end

local function applyEyelessJackHalloween(model: Model)
	clearEyelessJackHalloweenObjects(model)

	local zombie = model:FindFirstChild("Zombie")
	if not zombie or not zombie:IsA("Humanoid") then
		warn("Eyeless Jack Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName())
		return
	end

	local pumpkin = makeEyelessJackPumpkin()
	markHalloweenObjectForKiller(pumpkin, EYELESS_JACK_KILLER_NAME)

	local added, addError = pcall(function()
		zombie:AddAccessory(pumpkin)
	end)
	if not added then
		pumpkin:Destroy()
		warn("Eyeless Jack: Humanoid:AddAccessory failed:", addError)
		-- Leave the mask visible rather than producing a faceless, pumpkinless rig.
		return
	end

	local handle = pumpkin:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		local function ensurePumpkinJoined()
			if pumpkin.Parent == model then
				ensureEyelessJackHandleJoined(model, handle, EYELESS_JACK_PUMPKIN_ATTACHMENT_NAME)
			end
		end

		-- AddAccessory normally joins the Handle immediately. If it is still unjoined,
		-- give the engine until the end of this frame before stepping in.
		if not isHandleJoined(model, handle) then
			task.defer(ensurePumpkinJoined)
		end
	end

	setEyelessJackAppearance(model, true)
end

local function restoreEyelessJackNormal(model: Model)
	clearEyelessJackHalloweenObjects(model)
	setEyelessJackAppearance(model, false)
end

TRANSFORMATIONS["Chucky"] = {
	Halloween = {
		bodyColor = Color3.fromRGB(17, 17, 17),
		clothingColor = Color3.fromRGB(255, 115, 0),
		applyCustom = applyChuckyHalloween,
	},
	Normal = {
		bodyColor = CHUCKY_NORMAL_BODY_COLOR,
		clothingColor = Color3.fromRGB(255, 255, 255),
		applyCustom = restoreChuckyNormal,
	},
}

TRANSFORMATIONS["Eyeless Jack"] = {
	Halloween = {
		applyCustom = applyEyelessJackHalloween,
	},
	Normal = {
		bodyColor = EYELESS_JACK_NORMAL_BODY_COLOR,
		clothingColor = EYELESS_JACK_NORMAL_SHIRT_COLOR,
		applyCustom = restoreEyelessJackNormal,
	},
}

local FISHFACE_KILLER_NAME = "Fishface"
local FISHFACE_NORMAL_BODY_COLOR = Color3.fromRGB(39, 70, 45)
local FISHFACE_HALLOWEEN_BODY_COLOR = Color3.fromRGB(56, 28, 94)
local FISHFACE_NORMAL_EYE_COLOR = Color3.fromRGB(170, 85, 0)
local FISHFACE_HALLOWEEN_EYE_COLOR = Color3.fromRGB(131, 95, 208)
local FISHFACE_HALLOWEEN_CLOTHING_COLOR = Color3.fromRGB(26, 177, 114)
local FISHFACE_HALLOWEEN_CLOTHING_TEMPLATE = "http://www.roblox.com/asset/?id=12254223635"

-- { part name, SurfaceAppearance.ColorMap, SurfaceAppearance.TexturePack }
local FISHFACE_SURFACE_APPEARANCES = {
	{ "UpperTorso", "rbxassetid://547906912", "rbxassetid://117331393771621" },
	{ "LowerTorso", "rbxassetid://547906912", "rbxassetid://117331393771621" },
	{ "RightLowerArm", "rbxassetid://547906699", "rbxassetid://126309476852718" },
	{ "RightHand", "rbxassetid://547906699", "rbxassetid://126309476852718" },
	{ "LeftLowerArm", "rbxassetid://547906569", "rbxassetid://127703169548050" },
	{ "LeftHand", "rbxassetid://547906569", "rbxassetid://127703169548050" },
}

local FISHFACE_HALLOWEEN_ACCESSORY_NAMES = {
	["Webbing"] = true,
	["Angler Light"] = true,
}

local function clearFishfaceStrayAccessories(model: Model)
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") and FISHFACE_HALLOWEEN_ACCESSORY_NAMES[child.Name] then
			child:Destroy()
		end
	end
end

-- The classic rig has no clothing at all, so any Shirt/Pants is a Halloween
-- addition (or a leftover of one).
local function removeFishfaceClothing(model: Model)
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Shirt") or child:IsA("Pants") then
			child:Destroy()
		end
	end
end

local function setFishfaceEyeColor(model: Model, color: Color3)
	for _, eyeName in ipairs({ "LeftEye", "RightEye" }) do
		local eye = model:FindFirstChild(eyeName)
		if eye and eye:IsA("BasePart") then
			eye.Color = color
		end
	end
end

local function makeFishfaceWebbing(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Webbing"
	accessory.AccessoryType = Enum.AccessoryType.Hat
	accessory.AttachmentPoint = CFrame.new(0, 0.35, 0.1) * CFrame.Angles(0, math.pi, 0)

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(1, 179, 255))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=6964159457"
	mesh.Scale = Vector3.new(0.8, 0.6, 0.8)
	mesh.Parent = handle

	addChuckyHatPointAttachment(accessory, handle)

	return accessory
end

local function makeFishfaceAnglerLight(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Angler Light"
	accessory.AccessoryType = Enum.AccessoryType.Hat
	accessory.AttachmentPoint = CFrame.new(0, -0.8, 1) * CFrame.Angles(1.0471975511965976, 0, 0)

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(56, 28, 94))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=23260921"
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = handle

	addChuckyHatPointAttachment(accessory, handle)

	local bulb = makeHalloweenHandle("Bulb", Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(255, 102, 204))
	bulb.Material = Enum.Material.Neon
	bulb.Shape = Enum.PartType.Ball
	bulb.Parent = accessory

	local weld = Instance.new("Weld")
	weld.Part0 = handle
	weld.Part1 = bulb
	weld.C0 = CFrame.new(0, 0.5, -0.45)
	weld.Parent = bulb

	return accessory
end

local function applyFishfaceHalloween(model: Model)
	local zombie = model:FindFirstChild("Zombie")
	if not zombie or not zombie:IsA("Humanoid") then
		warn("Fishface Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName())
		return
	end

	clearHalloweenObjectsForKiller(model, FISHFACE_KILLER_NAME)
	clearFishfaceStrayAccessories(model)
	removeFishfaceClothing(model)

	local shirt = Instance.new("Shirt")
	shirt.Color3 = FISHFACE_HALLOWEEN_CLOTHING_COLOR
	shirt.ShirtTemplate = FISHFACE_HALLOWEEN_CLOTHING_TEMPLATE
	shirt.Parent = model

	local pants = Instance.new("Pants")
	pants.Color3 = FISHFACE_HALLOWEEN_CLOTHING_COLOR
	pants.PantsTemplate = FISHFACE_HALLOWEEN_CLOTHING_TEMPLATE
	pants.Parent = model

	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeFishfaceWebbing(),
		FISHFACE_KILLER_NAME,
		CHUCKY_HAT_POINT_ATTACHMENT
	)
	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeFishfaceAnglerLight(),
		FISHFACE_KILLER_NAME,
		CHUCKY_HAT_POINT_ATTACHMENT
	)

	setFishfaceEyeColor(model, FISHFACE_HALLOWEEN_EYE_COLOR)

	for _, entry in ipairs(FISHFACE_SURFACE_APPEARANCES) do
		removeSurfaceAppearances(model:FindFirstChild(entry[1]))
	end
end

local function restoreFishfaceNormal(model: Model)
	clearHalloweenObjectsForKiller(model, FISHFACE_KILLER_NAME)
	clearFishfaceStrayAccessories(model)
	removeFishfaceClothing(model)
	setFishfaceEyeColor(model, FISHFACE_NORMAL_EYE_COLOR)

	-- Rebuild the SurfaceAppearances the Halloween variant deleted. If one is
	-- already there (the model was never transformed) it is only re-pointed at
	-- the classic maps, and duplicates are removed.
	for _, entry in ipairs(FISHFACE_SURFACE_APPEARANCES) do
		local part = model:FindFirstChild(entry[1])
		if part and part:IsA("MeshPart") then
			local existingSurfaceAppearance: SurfaceAppearance? = nil
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("SurfaceAppearance") then
					if existingSurfaceAppearance == nil then
						existingSurfaceAppearance = child
					else
						child:Destroy()
					end
				end
			end

			local surfaceAppearance = existingSurfaceAppearance or Instance.new("SurfaceAppearance")
			if existingSurfaceAppearance == nil then
				surfaceAppearance.Parent = part
			end

			surfaceAppearance.ColorMap = entry[2]
			surfaceAppearance.TexturePack = entry[3]
			surfaceAppearance.Color = Color3.fromRGB(255, 255, 255)
		else
			warn("Fishface Normal transformation: missing MeshPart", entry[1], "in", model:GetFullName())
		end
	end
end

TRANSFORMATIONS["Fishface"] = {
	Halloween = {
		bodyColor = FISHFACE_HALLOWEEN_BODY_COLOR,
		applyCustom = applyFishfaceHalloween,
	},
	Normal = {
		bodyColor = FISHFACE_NORMAL_BODY_COLOR,
		applyCustom = restoreFishfaceNormal,
	},
}

local FREDDY_KILLER_NAME = "Freddy Krueger"
local FREDDY_NORMAL_SHIRT_TEMPLATE = "http://www.roblox.com/asset/?id=12725063359"
local FREDDY_NORMAL_PANTS_TEMPLATE = "http://www.roblox.com/asset/?id=12725182162"
local FREDDY_HALLOWEEN_SHIRT_TEMPLATE = "http://www.roblox.com/asset/?id=99653221045378"
local FREDDY_HALLOWEEN_PANTS_TEMPLATE = "http://www.roblox.com/asset/?id=140448356619437"
local FREDDY_NORMAL_FACE_TEXTURE = "rbxassetid://9120123"
local FREDDY_HALLOWEEN_FACE_TEXTURE = "http://www.roblox.com/asset/?id=29532362"
local FREDDY_NORMAL_LEFT_ARM_COLOR = Color3.fromRGB(218, 134, 122)
local FREDDY_HALLOWEEN_LEFT_ARM_COLOR = Color3.fromRGB(213, 115, 61)
local FREDDY_NORMAL_CLAWS_VERTEX_COLOR = Vector3.new(1, 1, 1)
local FREDDY_HALLOWEEN_CLAWS_VERTEX_COLOR = Vector3.new(1, 0, 0)

-- The classic "Fedora" is deliberately not listed: it is hidden, never removed.
local FREDDY_HALLOWEEN_ACCESSORY_NAMES = {
	["Skiis"] = true,
	["Rose"] = true,
	["Sinister Fedora"] = true,
}

local function clearFreddyStrayAccessories(model: Model)
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") and FREDDY_HALLOWEEN_ACCESSORY_NAMES[child.Name] then
			child:Destroy()
		end
	end
end

local function setFreddyClothing(model: Model, shirtTemplate: string, pantsTemplate: string)
	local shirt = model:FindFirstChildOfClass("Shirt")
	if shirt then
		shirt.ShirtTemplate = shirtTemplate
	else
		warn("Freddy Krueger transformation: Shirt was not found in", model:GetFullName())
	end

	local pants = model:FindFirstChildOfClass("Pants")
	if pants then
		pants.PantsTemplate = pantsTemplate
	else
		warn("Freddy Krueger transformation: Pants were not found in", model:GetFullName())
	end
end

local function setFreddyFaceTexture(model: Model, texture: string)
	local headVisual = model:FindFirstChild("HeadVisual")
	local face = headVisual and headVisual:FindFirstChild("face")
	if face and face:IsA("Decal") then
		face.Texture = texture
	else
		warn("Freddy Krueger transformation: HeadVisual.face was not found in", model:GetFullName())
	end
end

local function setFreddyClawsVertexColor(model: Model, vertexColor: Vector3)
	local claws = model:FindFirstChild("BluesteelClaws")
	local handle = claws and claws:FindFirstChild("Handle")
	local mesh = handle and handle:FindFirstChild("Mesh")
	if mesh and mesh:IsA("SpecialMesh") then
		mesh.VertexColor = vertexColor
	else
		warn("Freddy Krueger transformation: BluesteelClaws.Handle.Mesh was not found in", model:GetFullName())
	end
end

-- Hides or shows the classic Fedora. Hiding keeps it joined to the head, so
-- there is nothing to re-weld and nothing that can fall when it is shown again.
local function setFreddyFedoraVisible(model: Model, visible: boolean)
	local fedora = model:FindFirstChild("Fedora")
	if not fedora or not fedora:IsA("Accessory") then
		if visible then
			warn("Freddy Krueger transformation: the classic Fedora is missing from", model:GetFullName(), "and cannot be rebuilt (MeshPart.MeshId is not scriptable)")
		end
		return
	end

	local transparency = if visible then 0 else 1
	for _, descendant in ipairs(fedora:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = transparency
		end
	end
end

local function makeFreddySkiis(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Skiis"
	accessory.AccessoryType = Enum.AccessoryType.Neck
	accessory.AttachmentPoint = CFrame.new(0, 2.35, -0.1)

	local handle = makeHalloweenHandle("Handle", Vector3.new(1.6, 0.8, 1.6))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=1073126112"
	mesh.TextureId = "http://www.roblox.com/asset/?id=1073126443"
	mesh.Scale = Vector3.new(2, 2, 2)
	mesh.Parent = handle

	addChuckyHatPointAttachment(accessory, handle)

	return accessory
end

local function makeFreddyRose(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Rose"
	accessory.AccessoryType = Enum.AccessoryType.Front

	local handle = makeHalloweenHandle("Handle", Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(196, 40, 28))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=636804702"
	mesh.Scale = Vector3.new(1.8, 1.8, 1.8)
	mesh.Parent = handle

	local attachment = Instance.new("Attachment")
	attachment.Name = CHUCKY_CLOAK_ATTACHMENT
	attachment.CFrame = CFrame.new(0.45, -0.1, -0.1) * CFrame.Angles(0.6108652381980153, 0, 0)
	attachment.Parent = handle

	return accessory
end

local function makeFreddySinisterFedora(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Sinister Fedora"
	accessory.AccessoryType = Enum.AccessoryType.Hat
	accessory.AttachmentPoint = CFrame.new(0, 0, 0.1) * CFrame.Angles(0.17453292519943295, 0, 0)

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=105254164847398"
	mesh.TextureId = "http://www.roblox.com/asset/?id=60114992"
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = handle

	addChuckyHatPointAttachment(accessory, handle)

	return accessory
end

local function applyFreddyHalloween(model: Model)
	local zombie = model:FindFirstChild("Zombie")
	if not zombie or not zombie:IsA("Humanoid") then
		warn("Freddy Krueger Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName())
		return
	end

	clearHalloweenObjectsForKiller(model, FREDDY_KILLER_NAME)
	clearFreddyStrayAccessories(model)

	setFreddyClothing(model, FREDDY_HALLOWEEN_SHIRT_TEMPLATE, FREDDY_HALLOWEEN_PANTS_TEMPLATE)
	setFreddyFaceTexture(model, FREDDY_HALLOWEEN_FACE_TEXTURE)
	setFreddyClawsVertexColor(model, FREDDY_HALLOWEEN_CLAWS_VERTEX_COLOR)

	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeFreddySkiis(),
		FREDDY_KILLER_NAME,
		CHUCKY_HAT_POINT_ATTACHMENT
	)
	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeFreddyRose(),
		FREDDY_KILLER_NAME,
		CHUCKY_CLOAK_ATTACHMENT
	)
	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeFreddySinisterFedora(),
		FREDDY_KILLER_NAME,
		CHUCKY_HAT_POINT_ATTACHMENT
	)

	setFreddyFedoraVisible(model, false)
end

local function restoreFreddyNormal(model: Model)
	clearHalloweenObjectsForKiller(model, FREDDY_KILLER_NAME)
	clearFreddyStrayAccessories(model)

	setFreddyClothing(model, FREDDY_NORMAL_SHIRT_TEMPLATE, FREDDY_NORMAL_PANTS_TEMPLATE)
	setFreddyFaceTexture(model, FREDDY_NORMAL_FACE_TEXTURE)
	setFreddyClawsVertexColor(model, FREDDY_NORMAL_CLAWS_VERTEX_COLOR)
	setFreddyFedoraVisible(model, true)
end

TRANSFORMATIONS["Freddy Krueger"] = {
	Halloween = {
		bodyColors = {
			LeftArmColor3 = FREDDY_HALLOWEEN_LEFT_ARM_COLOR,
		},
		applyCustom = applyFreddyHalloween,
	},
	Normal = {
		bodyColors = {
			LeftArmColor3 = FREDDY_NORMAL_LEFT_ARM_COLOR,
		},
		applyCustom = restoreFreddyNormal,
	},
}

local FUWATTI_KILLER_NAME = "Fuwatti"
local FUWATTI_NORMAL_BODY_COLOR = Color3.fromRGB(180, 128, 255)
local FUWATTI_HALLOWEEN_BODY_COLOR = Color3.fromRGB(120, 144, 130)
local FUWATTI_NORMAL_FACE_COLOR = Color3.fromRGB(255, 255, 255)
local FUWATTI_HALLOWEEN_FACE_COLOR = Color3.fromRGB(242, 255, 0)
local FUWATTI_HALLOWEEN_PANTS_TEMPLATE = "http://www.roblox.com/asset/?id=11156664451"
local FUWATTI_STITCHES_TEXTURE = "http://www.roblox.com/asset/?id=69469256"
local FUWATTI_SPARK_TEXTURE = "http://www.roblox.com/asset/?id=138370769"

-- { part name, SurfaceAppearance.Color }
local FUWATTI_SURFACE_APPEARANCES = {
	{ "LeftHand", Color3.fromRGB(124, 156, 107) },
	{ "RightHand", Color3.fromRGB(124, 156, 107) },
	{ "LeftUpperArm", Color3.fromRGB(105, 102, 92) },
	{ "RightLowerArm", Color3.fromRGB(124, 156, 107) },
}

-- { part name, Decal.Face }
local FUWATTI_STITCHES = {
	{ "LeftUpperArm", Enum.NormalId.Left },
	{ "LeftHand", Enum.NormalId.Front },
	{ "RightUpperArm", Enum.NormalId.Front },
	{ "UpperTorso", Enum.NormalId.Back },
}

local function clearFuwattiHalloweenAdditions(model: Model)
	clearHalloweenObjectsForKiller(model, FUWATTI_KILLER_NAME)

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Pants") or (child:IsA("Accessory") and child.Name == "Bolts") then
			child:Destroy()
		end
	end

	for _, entry in ipairs(FUWATTI_SURFACE_APPEARANCES) do
		removeSurfaceAppearances(model:FindFirstChild(entry[1]))
	end

	for _, entry in ipairs(FUWATTI_STITCHES) do
		local part = model:FindFirstChild(entry[1])
		if part then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Decal") and child.Name == "Stitches" then
					child:Destroy()
				end
			end
		end
	end

	local upperTorso = model:FindFirstChild("UpperTorso")
	if upperTorso then
		for _, child in ipairs(upperTorso:GetChildren()) do
			if child:IsA("ParticleEmitter") and child.Texture == FUWATTI_SPARK_TEXTURE then
				child:Destroy()
			end
		end
	end
end

local function setFuwattiFaceColor(model: Model, color: Color3)
	local upperTorso = model:FindFirstChild("UpperTorso")
	local face = upperTorso and upperTorso:FindFirstChild("face")
	if face and face:IsA("Decal") then
		face.Color3 = color
	else
		warn("Fuwatti transformation: UpperTorso.face was not found in", model:GetFullName())
	end
end

local function makeFuwattiBolts(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Bolts"
	accessory.AccessoryType = Enum.AccessoryType.Face
	accessory.AttachmentPoint = CFrame.new(0, 0.2, 0)

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(99, 95, 98))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "http://www.roblox.com/asset/?id=12465317"
	mesh.Scale = Vector3.new(2, 1.5, 1.5)
	mesh.Parent = handle

	addChuckyHatPointAttachment(accessory, handle)

	return accessory
end

local function applyFuwattiHalloween(model: Model)
	local zombie = model:FindFirstChild("Zombie")
	if not zombie or not zombie:IsA("Humanoid") then
		warn("Fuwatti Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName())
		return
	end

	clearFuwattiHalloweenAdditions(model)

	setFuwattiFaceColor(model, FUWATTI_HALLOWEEN_FACE_COLOR)

	for _, entry in ipairs(FUWATTI_SURFACE_APPEARANCES) do
		local part = model:FindFirstChild(entry[1])
		if part and part:IsA("BasePart") then
			local surfaceAppearance = Instance.new("SurfaceAppearance")
			surfaceAppearance.AlphaMode = Enum.AlphaMode.TintMask
			surfaceAppearance.Color = entry[2]
			markHalloweenObjectForKiller(surfaceAppearance, FUWATTI_KILLER_NAME)
			surfaceAppearance.Parent = part
		else
			warn("Fuwatti Halloween transformation: missing part", entry[1], "in", model:GetFullName())
		end
	end

	local pants = Instance.new("Pants")
	pants.PantsTemplate = FUWATTI_HALLOWEEN_PANTS_TEMPLATE
	markHalloweenObjectForKiller(pants, FUWATTI_KILLER_NAME)
	pants.Parent = model

	for _, entry in ipairs(FUWATTI_STITCHES) do
		local part = model:FindFirstChild(entry[1])
		if part and part:IsA("BasePart") then
			local stitches = Instance.new("Decal")
			stitches.Name = "Stitches"
			stitches.Texture = FUWATTI_STITCHES_TEXTURE
			stitches.Face = entry[2]
			markHalloweenObjectForKiller(stitches, FUWATTI_KILLER_NAME)
			stitches.Parent = part
		else
			warn("Fuwatti Halloween transformation: missing part", entry[1], "in", model:GetFullName())
		end
	end

	local upperTorso = model:FindFirstChild("UpperTorso")
	if upperTorso and upperTorso:IsA("BasePart") then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Brightness = 10
		emitter.LightEmission = 1
		emitter.LightInfluence = 0
		emitter.Orientation = Enum.ParticleOrientation.FacingCamera
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 210, 0))
		emitter.Size = NumberSequence.new(0.5)
		emitter.Texture = FUWATTI_SPARK_TEXTURE
		emitter.Lifetime = NumberRange.new(0.1)
		emitter.Rate = 20
		emitter.RotSpeed = NumberRange.new(1000, 5000)
		emitter.Speed = NumberRange.new(30)
		emitter.SpreadAngle = Vector2.new(360, 360)
		emitter.LockedToPart = true
		markHalloweenObjectForKiller(emitter, FUWATTI_KILLER_NAME)
		emitter.Parent = upperTorso
	else
		warn("Fuwatti Halloween transformation: missing part UpperTorso in", model:GetFullName())
	end

	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeFuwattiBolts(),
		FUWATTI_KILLER_NAME,
		CHUCKY_HAT_POINT_ATTACHMENT
	)
end

local function restoreFuwattiNormal(model: Model)
	clearFuwattiHalloweenAdditions(model)
	setFuwattiFaceColor(model, FUWATTI_NORMAL_FACE_COLOR)
end

TRANSFORMATIONS["Fuwatti"] = {
	Halloween = {
		-- The head keeps its classic colour; only these five change.
		bodyColors = {
			TorsoColor3 = FUWATTI_HALLOWEEN_BODY_COLOR,
			LeftArmColor3 = FUWATTI_HALLOWEEN_BODY_COLOR,
			RightArmColor3 = FUWATTI_HALLOWEEN_BODY_COLOR,
			LeftLegColor3 = FUWATTI_HALLOWEEN_BODY_COLOR,
			RightLegColor3 = FUWATTI_HALLOWEEN_BODY_COLOR,
		},
		applyCustom = applyFuwattiHalloween,
	},
	Normal = {
		bodyColor = FUWATTI_NORMAL_BODY_COLOR,
		applyCustom = restoreFuwattiNormal,
	},
}

-- Shared by killers whose accessories use the legacy AttachmentPoint path but whose heads are not
-- the stock size, so Head.HatAttachment is not where that path would have put them. The legacy
-- path places a Handle a fixed LEGACY_ACCESSORY_HEIGHT above the head's CENTRE, so each Handle
-- gets a "FaceCenterAttachment" at AttachmentPoint * CFrame.new(0, -LEGACY_ACCESSORY_HEIGHT, 0),
-- which pairs with Head.FaceCenterAttachment and reproduces that placement. If accessories sit
-- slightly high or low, adjust LEGACY_ACCESSORY_HEIGHT.
local LEGACY_ACCESSORY_ATTACHMENT = "FaceCenterAttachment"
local LEGACY_ACCESSORY_HEIGHT = 0.5

local function addLegacyAccessoryAttachment(accessory: Accessory, handle: BasePart)
	local attachment = Instance.new("Attachment")
	attachment.Name = LEGACY_ACCESSORY_ATTACHMENT
	attachment.CFrame = accessory.AttachmentPoint * CFrame.new(0, -LEGACY_ACCESSORY_HEIGHT, 0)
	attachment.Parent = handle
end

local AO_ONI_KILLER_NAME = "Ao Oni"
local AO_ONI_NORMAL_HEAD_COLOR = Color3.fromRGB(180, 128, 255)
local AO_ONI_NORMAL_LIMB_COLOR = Color3.fromRGB(140, 100, 200)
local AO_ONI_HALLOWEEN_HEAD_COLOR = Color3.fromRGB(116, 134, 157)
local AO_ONI_HALLOWEEN_ARM_COLOR = Color3.fromRGB(231, 231, 236)
local AO_ONI_HALLOWEEN_PANTS_TEMPLATE = "http://www.roblox.com/asset/?id=10666718818"
local AO_ONI_HALLOWEEN_TINT_COLOR = Color3.fromRGB(138, 140, 40)
local AO_ONI_HALLOWEEN_TINTED_PARTS = {
	"LeftHand",
	"RightHand",
	"LeftLowerArm",
	"RightLowerArm",
}
local AO_ONI_GOGGLE_MESH_ID = "http://www.roblox.com/asset/?id=103919751"
local AO_ONI_HAIR_MESH_ID = "http://www.roblox.com/asset/?id=2316752631"
local AO_ONI_HAIR_TEXTURE_ID = "http://www.roblox.com/asset/?id=2319641106"
local AO_ONI_SPARK_TEXTURE = "http://www.roblox.com/asset/?id=138370769"

local AO_ONI_HALLOWEEN_ACCESSORY_NAMES = {
	["Goggles"] = true,
	["Singed Scientist Hair"] = true,
}

local function clearAoOniHalloweenAdditions(model: Model)
	clearHalloweenObjectsForKiller(model, AO_ONI_KILLER_NAME)

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Pants")
			or (child:IsA("Accessory") and AO_ONI_HALLOWEEN_ACCESSORY_NAMES[child.Name]) then
			child:Destroy()
		end
	end

	for _, partName in ipairs(AO_ONI_HALLOWEEN_TINTED_PARTS) do
		removeSurfaceAppearances(model:FindFirstChild(partName))
	end
end

-- One goggle lens/rim: a 0.4 stud Part with a flat FileMesh, welded to the strap.
local function makeAoOniGogglePart(
	name: string,
	material: Enum.Material,
	color: Color3,
	meshScale: Vector3,
	strap: BasePart,
	c0: CFrame
): BasePart
	local part = makeHalloweenHandle(name, Vector3.new(0.4, 0.4, 0.4), color)
	part.Material = material

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = AO_ONI_GOGGLE_MESH_ID
	mesh.Scale = meshScale
	mesh.Parent = part

	local weld = Instance.new("Weld")
	weld.Part0 = strap
	weld.Part1 = part
	weld.C0 = c0
	weld.Parent = part

	return part
end

local function makeAoOniGoggles(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Goggles"
	accessory.AccessoryType = Enum.AccessoryType.Face
	accessory.AttachmentPoint = CFrame.Angles(0, 0, 1.5707963267948966)

	local handle = makeHalloweenHandle("Handle", Vector3.new(0.1, 2.5, 2.5), Color3.fromRGB(108, 88, 75))
	handle.Material = Enum.Material.Leather
	handle.Shape = Enum.PartType.Cylinder
	handle.Parent = accessory

	addLegacyAccessoryAttachment(accessory, handle)

	local metalColor = Color3.fromRGB(105, 102, 92)
	local leftC0 = CFrame.new(0.02, -0.37, -1.15) * CFrame.Angles(1.3089969389957472, 0, 0)
	local rightC0 = CFrame.new(0, 0.35, -1.15) * CFrame.Angles(1.8325957145940461, 0, 0)
	local leftScale = Vector3.new(0.7, 0.1, 0.9)
	local rightScale = Vector3.new(0.6, 0.1, 0.8)

	local goggleLeft = makeAoOniGogglePart("GoggleLeft", Enum.Material.Metal, metalColor, leftScale, handle, leftC0)
	goggleLeft.Parent = accessory
	local goggleRight = makeAoOniGogglePart("GoggleRight", Enum.Material.Metal, metalColor, rightScale, handle, rightC0)
	goggleRight.Parent = accessory

	-- The lenses sit 0.05 studs further down the rim than their frames and are
	-- smaller: left = frame * 0.7, right = frame * (0.6, 0.7, 0.7).
	local glassColor = Color3.fromRGB(255, 255, 0)
	local glassLeft = makeAoOniGogglePart(
		"GlassLeft",
		Enum.Material.Glass,
		glassColor,
		leftScale * 0.7,
		handle,
		leftC0 * CFrame.new(0, -0.05, 0)
	)
	glassLeft.Parent = accessory
	local glassRight = makeAoOniGogglePart(
		"GlassRight",
		Enum.Material.Glass,
		glassColor,
		rightScale * Vector3.new(0.6, 0.7, 0.7),
		handle,
		rightC0 * CFrame.new(0, -0.05, 0)
	)
	glassRight.Parent = accessory

	return accessory
end

local function makeAoOniHair(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = "Singed Scientist Hair"
	accessory.AccessoryType = Enum.AccessoryType.Hair
	accessory.AttachmentPoint = CFrame.new(0, -0.45, -0.25)

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = AO_ONI_HAIR_MESH_ID
	mesh.TextureId = AO_ONI_HAIR_TEXTURE_ID
	mesh.Scale = Vector3.new(2.6, 2.6, 2.8)
	mesh.Parent = handle

	-- The sparks come off the hair, so the emitter lives in the Handle and is
	-- removed together with the accessory.
	local emitter = Instance.new("ParticleEmitter")
	emitter.Brightness = 10
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Orientation = Enum.ParticleOrientation.FacingCamera
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 210, 0))
	emitter.Size = NumberSequence.new(1)
	emitter.Texture = AO_ONI_SPARK_TEXTURE
	emitter.Lifetime = NumberRange.new(0.1)
	emitter.Rate = 20
	emitter.RotSpeed = NumberRange.new(1000, 5000)
	emitter.Speed = NumberRange.new(20)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.LockedToPart = true
	emitter.Parent = handle

	addLegacyAccessoryAttachment(accessory, handle)

	return accessory
end

local function applyAoOniHalloween(model: Model)
	clearAoOniHalloweenAdditions(model)

	local pants = Instance.new("Pants")
	pants.PantsTemplate = AO_ONI_HALLOWEEN_PANTS_TEMPLATE
	markHalloweenObjectForKiller(pants, AO_ONI_KILLER_NAME)
	pants.Parent = model

	for _, partName in ipairs(AO_ONI_HALLOWEEN_TINTED_PARTS) do
		local part = model:FindFirstChild(partName)
		if part and part:IsA("MeshPart") then
			local surfaceAppearance = Instance.new("SurfaceAppearance")
			surfaceAppearance.AlphaMode = Enum.AlphaMode.TintMask
			surfaceAppearance.Color = AO_ONI_HALLOWEEN_TINT_COLOR
			markHalloweenObjectForKiller(surfaceAppearance, AO_ONI_KILLER_NAME)
			surfaceAppearance.Parent = part
		else
			warn("Ao Oni Halloween transformation: missing MeshPart", partName, "in", model:GetFullName())
		end
	end

	local zombie = model:FindFirstChild("Zombie")
	if not zombie or not zombie:IsA("Humanoid") then
		warn("Ao Oni Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- Goggles and Hair were not added")
		return
	end

	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeAoOniGoggles(),
		AO_ONI_KILLER_NAME,
		LEGACY_ACCESSORY_ATTACHMENT
	)
	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeAoOniHair(),
		AO_ONI_KILLER_NAME,
		LEGACY_ACCESSORY_ATTACHMENT
	)
end

local function restoreAoOniNormal(model: Model)
	clearAoOniHalloweenAdditions(model)
end

TRANSFORMATIONS[AO_ONI_KILLER_NAME] = {
	Halloween = {
		-- Torso and both legs keep their classic colour.
		bodyColors = {
			HeadColor3 = AO_ONI_HALLOWEEN_HEAD_COLOR,
			LeftArmColor3 = AO_ONI_HALLOWEEN_ARM_COLOR,
			RightArmColor3 = AO_ONI_HALLOWEEN_ARM_COLOR,
		},
		applyCustom = applyAoOniHalloween,
	},
	Normal = {
		bodyColors = {
			HeadColor3 = AO_ONI_NORMAL_HEAD_COLOR,
			TorsoColor3 = AO_ONI_NORMAL_LIMB_COLOR,
			LeftArmColor3 = AO_ONI_NORMAL_LIMB_COLOR,
			RightArmColor3 = AO_ONI_NORMAL_LIMB_COLOR,
			LeftLegColor3 = AO_ONI_NORMAL_LIMB_COLOR,
			RightLegColor3 = AO_ONI_NORMAL_LIMB_COLOR,
		},
		applyCustom = restoreAoOniNormal,
	},
}

local GHOSTFACE_KILLER_NAME = "Ghostface"
local GHOSTFACE_HORNS_NAME = "Horns"
local GHOSTFACE_NORMAL_HEAD_TINT = Color3.fromRGB(255, 255, 255)
local GHOSTFACE_HALLOWEEN_HEAD_TINT = Color3.fromRGB(200, 0, 0)
local GHOSTFACE_NORMAL_KNIFE_VERTEX_COLOR = Vector3.new(1, 1, 1)
local GHOSTFACE_HALLOWEEN_KNIFE_VERTEX_COLOR = Vector3.new(0.8, 0, 0)
local GHOSTFACE_HORNS_MESH_ID = "http://www.roblox.com/asset/?id=15934744"

local function clearGhostfaceHalloweenAdditions(model: Model)
	clearHalloweenObjectsForKiller(model, GHOSTFACE_KILLER_NAME)

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") and child.Name == GHOSTFACE_HORNS_NAME then
			child:Destroy()
		end
	end
end

local function setGhostfaceAppearance(model: Model, halloween: boolean)
	local head = model:FindFirstChild("Head")
	local surfaceAppearance = head and head:FindFirstChildOfClass("SurfaceAppearance")
	if surfaceAppearance then
		surfaceAppearance.Color = if halloween then GHOSTFACE_HALLOWEEN_HEAD_TINT else GHOSTFACE_NORMAL_HEAD_TINT
	else
		warn("Ghostface transformation: Head.SurfaceAppearance was not found in", model:GetFullName())
	end

	local knife = model:FindFirstChild("Knife")
	local knifeHandle = knife and knife:FindFirstChild("Handle")
	local knifeMesh = knifeHandle and knifeHandle:FindFirstChild("KnifeMesh")
	if knifeMesh and knifeMesh:IsA("SpecialMesh") then
		knifeMesh.VertexColor = if halloween
			then GHOSTFACE_HALLOWEEN_KNIFE_VERTEX_COLOR
			else GHOSTFACE_NORMAL_KNIFE_VERTEX_COLOR
	else
		warn("Ghostface transformation: Knife.Handle.KnifeMesh was not found in", model:GetFullName())
	end
end

local function makeGhostfaceHorns(): Accessory
	local accessory = Instance.new("Accessory")
	accessory.Name = GHOSTFACE_HORNS_NAME
	accessory.AccessoryType = Enum.AccessoryType.Hat
	accessory.AttachmentPoint = CFrame.new(0, -0.95, 0.5)

	local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(150, 0, 0))
	handle.Parent = accessory

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = GHOSTFACE_HORNS_MESH_ID
	mesh.Parent = handle

	addLegacyAccessoryAttachment(accessory, handle)

	return accessory
end

local function applyGhostfaceHalloween(model: Model)
	clearGhostfaceHalloweenAdditions(model)
	setGhostfaceAppearance(model, true)

	local zombie = model:FindFirstChild("Zombie")
	if not zombie or not zombie:IsA("Humanoid") then
		warn("Ghostface Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- Horns were not added")
		return
	end

	addMarkedHalloweenAccessory(
		model,
		zombie,
		makeGhostfaceHorns(),
		GHOSTFACE_KILLER_NAME,
		LEGACY_ACCESSORY_ATTACHMENT
	)
end

local function restoreGhostfaceNormal(model: Model)
	clearGhostfaceHalloweenAdditions(model)
	setGhostfaceAppearance(model, false)
end

TRANSFORMATIONS[GHOSTFACE_KILLER_NAME] = {
	Halloween = {
		applyCustom = applyGhostfaceHalloween,
	},
	Normal = {
		applyCustom = restoreGhostfaceNormal,
	},
}

-- Each killer from here on is wrapped in a do-block so its locals are released afterwards: this
-- ModuleScript's main chunk is close to Luau's limit of 200 local variables.
do
	local GRANNY_KILLER_NAME = "Granny"
	local GRANNY_BELT_ATTACHMENT = "WaistRigAttachment"

	local GRANNY_HALLOWEEN_ACCESSORY_NAMES = {
		["Big Nose"] = true,
		["Necklace"] = true,
		["Belt"] = true,
		["RavenWitchHat"] = true,
	}

	local GRANNY_LOOK = {
		Normal = {
			bodyColor = Color3.fromRGB(124, 92, 70),
			hairColor = Color3.fromRGB(130, 130, 130),
			ghostTorsoColor = Color3.fromRGB(163, 162, 165),
			ghostTorsoMaterial = Enum.Material.Plastic,
			faceTexture = "rbxassetid://130707549756771",
			batGrip = CFrame.new(0, -0.05, -1.5) * CFrame.Angles(0, -math.pi / 2, -math.pi / 2),
			batMeshId = "rbxassetid://522117559",
			batTextureId = "http://www.roblox.com/asset/?id=7505545108",
			batVertexColor = Vector3.new(1, 1, 1),
			batMeshScale = Vector3.new(0.01, 0.01, 0.007),
		},
		Halloween = {
			bodyColor = Color3.fromRGB(120, 144, 130),
			hairColor = Color3.fromRGB(89, 163, 124),
			ghostTorsoColor = Color3.fromRGB(61, 21, 133),
			ghostTorsoMaterial = Enum.Material.Fabric,
			faceTexture = "http://www.roblox.com/asset/?id=133350659760822",
			batGrip = CFrame.new(0.75, -0.1, -1.9) * CFrame.Angles(0, -1.7453292519943295, -math.pi / 2),
			batMeshId = "http://www.roblox.com/asset/?id=3064694781",
			batTextureId = "http://www.roblox.com/asset/?id=92012536945473",
			batVertexColor = Vector3.new(1, 0, 1),
			batMeshScale = Vector3.new(1, 1, 1),
		},
	}

	local function clearGrannyHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, GRANNY_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and GRANNY_HALLOWEEN_ACCESSORY_NAMES[child.Name] then
				child:Destroy()
			end
		end
	end

	-- Rebuilds the SurfaceAppearance the Halloween variant deleted. If one is
	-- already there (the model was never transformed) it is only re-pointed at the
	-- classic maps, and duplicates are removed. It is deliberately NOT marked, so
	-- the next Halloween clear pass cannot mistake it for a Halloween addition.
	local function restoreGrannyGhostTorsoSurfaceAppearance(handle: BasePart)
		local existingSurfaceAppearance: SurfaceAppearance? = nil
		for _, child in ipairs(handle:GetChildren()) do
			if child:IsA("SurfaceAppearance") then
				if existingSurfaceAppearance == nil then
					existingSurfaceAppearance = child
				else
					child:Destroy()
				end
			end
		end

		local surfaceAppearance = existingSurfaceAppearance or Instance.new("SurfaceAppearance")
		if existingSurfaceAppearance == nil then
			surfaceAppearance.Parent = handle
		end

		surfaceAppearance.ColorMap = "rbxassetid://7505656364"
		surfaceAppearance.TexturePack = "rbxassetid://74561372926467"
		surfaceAppearance.AlphaMode = Enum.AlphaMode.Overlay
		surfaceAppearance.Color = Color3.fromRGB(255, 255, 255)
	end

	-- An equipped Tool is held by a "RightGrip" joint whose C1 is a copy of Tool.Grip. Assigning
	-- Tool.Grip does not reliably refresh that copy once the tool is equipped (notably on the
	-- client), so the live joint is written as well. With no joint, Tool.Grip alone is correct.
	local function syncGrannyBatGrip(model: Model, bat: Tool, handle: BasePart, grip: CFrame)
		bat.Grip = grip

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("JointInstance") and descendant.Name == "RightGrip" then
				if descendant.Part1 == handle then
					descendant.C1 = grip
				elseif descendant.Part0 == handle then
					descendant.C0 = grip
				end
			end
		end
	end

	-- Everything the two variants change on objects the classic rig already owns.
	local function setGrannyAppearance(model: Model, halloween: boolean)
		local look = GRANNY_LOOK.Normal
		if halloween then
			look = GRANNY_LOOK.Halloween
		end

		local hair = model:FindFirstChild("Dr. Smyth Hair")
		local hairHandle = hair and hair:FindFirstChild("Handle")
		if hairHandle and hairHandle:IsA("BasePart") then
			hairHandle.Color = look.hairColor
		else
			warn("Granny transformation: Dr. Smyth Hair.Handle was not found in", model:GetFullName())
		end

		local ghostTorso = model:FindFirstChild("GhostTorso")
		local ghostTorsoHandle = ghostTorso and ghostTorso:FindFirstChild("Handle")
		if ghostTorsoHandle and ghostTorsoHandle:IsA("BasePart") then
			ghostTorsoHandle.Color = look.ghostTorsoColor
			ghostTorsoHandle.Material = look.ghostTorsoMaterial
			if halloween then
				removeSurfaceAppearances(ghostTorsoHandle)
			else
				restoreGrannyGhostTorsoSurfaceAppearance(ghostTorsoHandle)
			end
		else
			warn("Granny transformation: GhostTorso.Handle was not found in", model:GetFullName())
		end

		local head = model:FindFirstChild("Head")
		local face = head and head:FindFirstChild("face")
		if face and face:IsA("Decal") then
			face.Texture = look.faceTexture
		else
			warn("Granny transformation: Head.face was not found in", model:GetFullName())
		end

		local bat = model:FindFirstChild("Bat")
		local batHandle = bat and bat:FindFirstChild("Handle")
		local batMesh = batHandle and batHandle:FindFirstChild("Mesh")
		if bat and bat:IsA("Tool") and batHandle and batHandle:IsA("BasePart") and batMesh and batMesh:IsA("SpecialMesh") then
			syncGrannyBatGrip(model, bat, batHandle, look.batGrip)
			batMesh.MeshId = look.batMeshId
			batMesh.TextureId = look.batTextureId
			batMesh.VertexColor = look.batVertexColor
			batMesh.Scale = look.batMeshScale
		else
			warn("Granny transformation: Bat.Handle.Mesh was not found in", model:GetFullName())
		end
	end

	local function makeGrannyBigNose(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Big Nose"
		accessory.AccessoryType = Enum.AccessoryType.Face
		accessory.AttachmentPoint = CFrame.new(0, 0.5, -0.75) * CFrame.Angles(0, math.pi, 0)

		local handle = makeHalloweenHandle("Handle", Vector3.new(0.4, 0.4, 0.4), GRANNY_LOOK.Halloween.bodyColor)
		handle.Material = Enum.Material.Salt
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=133030037333026"
		mesh.Scale = Vector3.new(1, 1, 1)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function makeGrannyNecklace(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Necklace"
		accessory.AccessoryType = Enum.AccessoryType.Neck
		accessory.AttachmentPoint = CFrame.new(0, 1.2, -1.1) * CFrame.Angles(-math.pi / 3, 0, 0)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 0.4, 1))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=120201343803767"
		mesh.TextureId = "http://www.roblox.com/asset/?id=39201667"
		mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function makeGrannyBelt(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Belt"
		accessory.AccessoryType = Enum.AccessoryType.Waist

		local handle = makeHalloweenHandle("Handle", Vector3.new(2, 0.3, 2), Color3.fromRGB(108, 88, 75))
		handle.Material = Enum.Material.Leather
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=103919751"
		mesh.Scale = Vector3.new(3, 0.3, 2.5)
		mesh.Parent = handle

		-- The Handle already owns this attachment, so it pairs with the rig's WaistRigAttachment
		-- without an AttachmentPoint fallback.
		local attachment = Instance.new("Attachment")
		attachment.Name = GRANNY_BELT_ATTACHMENT
		attachment.CFrame = CFrame.new(0, -0.2, 0.15)
		attachment.Parent = handle

		local function addBuckle(size: Vector3, c0: CFrame)
			local buckle = makeHalloweenHandle("Buckle", size, Color3.fromRGB(163, 162, 165))
			buckle.Material = Enum.Material.Metal
			buckle.Parent = accessory

			local weld = Instance.new("Weld")
			weld.Part0 = handle
			weld.Part1 = buckle
			weld.C0 = c0
			weld.Parent = buckle
		end

		addBuckle(Vector3.new(0.6, 0.1, 0.1), CFrame.new(0, 0.15, -0.95))
		addBuckle(Vector3.new(0.6, 0.1, 0.1), CFrame.new(0, -0.15, -0.95))
		addBuckle(Vector3.new(0.1, 0.2, 0.1), CFrame.new(0.25, 0, -0.95))
		addBuckle(Vector3.new(0.1, 0.2, 0.1), CFrame.new(-0.25, 0, -0.95))

		return accessory
	end

	local function makeGrannyWitchHat(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "RavenWitchHat"
		accessory.AccessoryType = Enum.AccessoryType.Hat
		accessory.AttachmentPoint = CFrame.new(0, -0.1, 0)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1.6, 0.8, 1.6))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=1117711484"
		mesh.TextureId = "http://www.roblox.com/asset/?id=1117711743"
		mesh.Scale = Vector3.new(2.3, 2.3, 2.3)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function applyGrannyHalloween(model: Model)
		clearGrannyHalloweenAdditions(model)
		setGrannyAppearance(model, true)

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Granny Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- accessories were not added")
			return
		end

		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeGrannyBigNose(),
			GRANNY_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeGrannyNecklace(),
			GRANNY_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeGrannyBelt(),
			GRANNY_KILLER_NAME,
			GRANNY_BELT_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeGrannyWitchHat(),
			GRANNY_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
	end

	local function restoreGrannyNormal(model: Model)
		clearGrannyHalloweenAdditions(model)
		setGrannyAppearance(model, false)
	end

	TRANSFORMATIONS[GRANNY_KILLER_NAME] = {
		Halloween = {
			bodyColor = GRANNY_LOOK.Halloween.bodyColor,
			applyCustom = applyGrannyHalloween,
		},
		Normal = {
			bodyColor = GRANNY_LOOK.Normal.bodyColor,
			applyCustom = restoreGrannyNormal,
		},
	}
end

-- THE HEAD: MeshPart.MeshId cannot be assigned from a script, so Halloween hides the real Head
-- (Transparency 1) and welds a visible, non-colliding "BodyHead" Part with a SpecialMesh to it.
-- Normal destroys BodyHead and shows Head again. Hit detection keeps seeing the real Head.
--
-- The game's Halloween Jack also carries a BoolValue "JackOKiller" that the classic rig lacks. It
-- is deliberately NOT added here: isJackOKiller skips any model holding it, so adding it would
-- stop Jack from being turned back to normal.
do
	local JACK_KILLER_NAME = "Jack Torrance"
	local JACK_BODY_HEAD_NAME = "BodyHead"
	local JACK_BODY_HEAD_COLOR = Color3.fromRGB(163, 162, 165)

	local JACK_HALLOWEEN_ACCESSORY_NAMES = {
		["Tree"] = true,
	}

	-- { Decal name, Texture, ZIndex }; all Face = Front, Color3 white, Transparency 0.
	local JACK_FACE_DECALS = {
		{ "face", "rbxassetid://120954647", 2 },
		{ "Decal", "rbxassetid://867495784", 1 },
	}

	-- headTransparency is the REAL Head's transparency; bodyHead is the visible replacement head
	-- and exists only in the Halloween look.
	local JACK_LOOK = {
		Normal = {
			bodyColor = Color3.fromRGB(234, 184, 146),
			shirtTemplate = "http://www.roblox.com/asset/?id=6423751518",
			pantsTemplate = "http://www.roblox.com/asset/?id=5485166351",
			headTransparency = 0,
		},
		Halloween = {
			bodyColor = Color3.fromRGB(171, 168, 158),
			shirtTemplate = "http://www.roblox.com/asset/?id=975765801",
			pantsTemplate = "http://www.roblox.com/asset/?id=14083155094",
			headTransparency = 1,
			bodyHead = {
				meshId = "http://www.roblox.com/asset/?id=5764007179",
				textureId = "http://roblox.com/asset/?id=5764009085",
				scale = Vector3.new(0.85, 0.85, 0.85),
			},
		},
	}

	local function clearJackTorranceHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, JACK_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and JACK_HALLOWEEN_ACCESSORY_NAMES[child.Name] then
				child:Destroy()
			elseif child:IsA("BasePart") and child.Name == JACK_BODY_HEAD_NAME then
				child:Destroy()
			end
		end
	end

	local function setJackTorranceClothing(model: Model, look: any)
		local shirt = model:FindFirstChildOfClass("Shirt")
		if shirt then
			shirt.ShirtTemplate = look.shirtTemplate
		else
			warn("Jack Torrance transformation: Shirt was not found in", model:GetFullName())
		end

		local pants = model:FindFirstChildOfClass("Pants")
		if pants then
			pants.PantsTemplate = look.pantsTemplate
		else
			warn("Jack Torrance transformation: Pants were not found in", model:GetFullName())
		end
	end

	local function removeJackTorranceFaceDecals(head: Instance)
		for _, child in ipairs(head:GetChildren()) do
			if child:IsA("Decal") then
				for _, spec in ipairs(JACK_FACE_DECALS) do
					if child.Name == spec[1] then
						child:Destroy()
						break
					end
				end
			end
		end
	end

	-- Rebuilds the two classic Decals. If one is already there (the model was never
	-- transformed) it is only re-pointed at the classic values, and duplicates are
	-- removed. They are deliberately NOT marked, so a later Halloween clear pass
	-- cannot mistake them for Halloween additions.
	local function restoreJackTorranceFaceDecals(head: Instance)
		for _, spec in ipairs(JACK_FACE_DECALS) do
			local existingDecal: Decal? = nil
			for _, child in ipairs(head:GetChildren()) do
				if child:IsA("Decal") and child.Name == spec[1] then
					if existingDecal == nil then
						existingDecal = child
					else
						child:Destroy()
					end
				end
			end

			local decal = existingDecal or Instance.new("Decal")
			if existingDecal == nil then
				decal.Name = spec[1]
				decal.Parent = head
			end

			decal.Face = Enum.NormalId.Front
			decal.Texture = spec[2]
			decal.ZIndex = spec[3]
			decal.Color3 = Color3.fromRGB(255, 255, 255)
			decal.Transparency = 0
		end
	end

	local function addJackTorranceBodyHead(model: Model, head: BasePart, spec: any)
		local bodyHead = makeHalloweenHandle(JACK_BODY_HEAD_NAME, Vector3.new(1, 1, 1), JACK_BODY_HEAD_COLOR)
		markHalloweenObjectForKiller(bodyHead, JACK_KILLER_NAME)

		-- Same collision group as the real Head (it is "Killers" in this game).
		pcall(function()
			bodyHead.CollisionGroup = head.CollisionGroup
		end)

		bodyHead.CFrame = head.CFrame

		local mesh = Instance.new("SpecialMesh")
		mesh.Name = "Mesh"
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = spec.meshId
		mesh.TextureId = spec.textureId
		mesh.Scale = spec.scale
		mesh.Parent = bodyHead

		bodyHead.Parent = model

		local weld = Instance.new("Weld")
		weld.Name = "Weld"
		weld.Part0 = head
		weld.Part1 = bodyHead
		weld.C0 = CFrame.new()
		weld.C1 = CFrame.new()
		weld.Parent = bodyHead
	end

	-- Puts the Head into the given look. Returns false only when there is no Head
	-- to work on. Any BodyHead has already been cleared by the caller.
	local function setJackTorranceHead(model: Model, look: any): boolean
		local head = model:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then
			warn("Jack Torrance transformation: Head was not found in", model:GetFullName())
			return false
		end

		head.Transparency = look.headTransparency
		if look.bodyHead then
			addJackTorranceBodyHead(model, head, look.bodyHead)
		end

		return true
	end

	local function makeJackTorranceTree(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Tree"
		accessory.AccessoryType = Enum.AccessoryType.Face
		accessory.AttachmentPoint = CFrame.new(0, 0.45, -0.2)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(108, 88, 75))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=181585686"
		mesh.Scale = Vector3.new(1.8, 1.8, 1.8)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function applyJackTorranceHalloween(model: Model)
		clearJackTorranceHalloweenAdditions(model)
		setJackTorranceClothing(model, JACK_LOOK.Halloween)

		-- The painted Halloween head carries its own face, so the classic face
		-- Decals only come off once the new head is really in place.
		if setJackTorranceHead(model, JACK_LOOK.Halloween) then
			local head = model:FindFirstChild("Head")
			if head then
				removeJackTorranceFaceDecals(head)
			end
		end

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Jack Torrance Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- Tree was not added")
			return
		end

		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeJackTorranceTree(),
			JACK_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
	end

	local function restoreJackTorranceNormal(model: Model)
		-- Clearing also destroys BodyHead; the real Head is made visible again and
		-- the classic face goes back on it.
		clearJackTorranceHalloweenAdditions(model)
		setJackTorranceClothing(model, JACK_LOOK.Normal)

		if setJackTorranceHead(model, JACK_LOOK.Normal) then
			local head = model:FindFirstChild("Head")
			if head then
				restoreJackTorranceFaceDecals(head)
			end
		end
	end

	TRANSFORMATIONS[JACK_KILLER_NAME] = {
		Halloween = {
			bodyColor = JACK_LOOK.Halloween.bodyColor,
			applyCustom = applyJackTorranceHalloween,
		},
		Normal = {
			bodyColor = JACK_LOOK.Normal.bodyColor,
			applyCustom = restoreJackTorranceNormal,
		},
	}
end

do
	local JASON_KILLER_NAME = "Jason"
	local JASON_FACE_COLOR = Color3.fromRGB(213, 115, 61)
	local JASON_SCARF_COLOR = Color3.fromRGB(50, 38, 31)

	local JASON_LOOK = {
		Normal = {
			headColor = Color3.fromRGB(27, 42, 53),
			shirtTemplate = "http://www.roblox.com/asset/?id=8167897350",
			pantsTemplate = "http://www.roblox.com/asset/?id=8175615188",
			macheteGrip = CFrame.new(0, -1.4, 0.15) * CFrame.Angles(0, -0.04161021, 0),
			macheteMeshId = "http://www.roblox.com/asset/?id=123248347",
			macheteMeshScale = Vector3.new(0.4, 0.4, 0.4),
		},
		Halloween = {
			headColor = Color3.fromRGB(17, 17, 17),
			shirtTemplate = "http://www.roblox.com/asset/?id=14823454062",
			pantsTemplate = "http://www.roblox.com/asset/?id=14823458938",
			macheteGrip = CFrame.new(0.15, -1.4, 0.1) * CFrame.Angles(0, -math.pi / 2, 0),
			macheteMeshId = "http://www.roblox.com/asset/?id=111212768594969",
			macheteMeshScale = Vector3.new(1.05, 1.05, 1.05),
		},
	}

	local JASON_HALLOWEEN_ACCESSORY_NAMES = {
		["Scarecrow Hat"] = true,
		["DownScarf"] = true,
		["UpScarf"] = true,
	}
	local JASON_HALLOWEEN_PART_NAMES = {
		["LeftEye"] = true,
		["RightEye"] = true,
		["LeftEyebrow"] = true,
		["RightEyebrow"] = true,
	}

	local function clearJasonHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, JASON_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and JASON_HALLOWEEN_ACCESSORY_NAMES[child.Name] then
				child:Destroy()
			elseif child:IsA("BasePart") and JASON_HALLOWEEN_PART_NAMES[child.Name] then
				child:Destroy()
			end
		end
	end

	local function setJasonClothing(model: Model, look: any)
		local shirt = model:FindFirstChildOfClass("Shirt")
		if shirt then
			shirt.ShirtTemplate = look.shirtTemplate
		else
			warn("Jason transformation: Shirt was not found in", model:GetFullName())
		end

		local pants = model:FindFirstChildOfClass("Pants")
		if pants then
			pants.PantsTemplate = look.pantsTemplate
		else
			warn("Jason transformation: Pants were not found in", model:GetFullName())
		end
	end

	local function syncJasonMacheteGrip(model: Model, machete: Tool, handle: BasePart, grip: CFrame)
		machete.Grip = grip

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("JointInstance") and descendant.Name == "RightGrip" then
				if descendant.Part1 == handle then
					descendant.C1 = grip
				elseif descendant.Part0 == handle then
					descendant.C0 = grip
				end
			end
		end
	end

	local function setJasonMachete(model: Model, look: any)
		local machete = model:FindFirstChild("Machete")
		local handle = machete and machete:FindFirstChild("Handle")
		local mesh = handle and handle:FindFirstChild("Mesh")
		if machete
			and machete:IsA("Tool")
			and handle
			and handle:IsA("BasePart")
			and mesh
			and mesh:IsA("SpecialMesh") then
			syncJasonMacheteGrip(model, machete, handle, look.macheteGrip)
			mesh.MeshId = look.macheteMeshId
			mesh.Scale = look.macheteMeshScale
		else
			warn("Jason transformation: Machete.Handle.Mesh was not found in", model:GetFullName())
		end
	end

	local function setJasonMaskVisible(model: Model, visible: boolean)
		local mask = model:FindFirstChild("HockeyMask")
		if not mask or not mask:IsA("Accessory") then
			if visible then
				warn("Jason transformation: the classic HockeyMask is missing from", model:GetFullName(), "and cannot be rebuilt (MeshPart.MeshId is not scriptable)")
			end
			return
		end

		local transparency = if visible then 0 else 1
		for _, descendant in ipairs(mask:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = transparency
			end
		end
	end

	-- One glowing eye/eyebrow: a small Neon Part welded to the Head at c0.
	local function addJasonFacePart(
		model: Model,
		head: BasePart,
		name: string,
		shape: Enum.PartType,
		size: Vector3,
		c0: CFrame
	)
		local part = makeHalloweenHandle(name, size, JASON_FACE_COLOR)
		part.Material = Enum.Material.Neon
		part.Shape = shape
		markHalloweenObjectForKiller(part, JASON_KILLER_NAME)
		part.CFrame = head.CFrame * c0
		part.Parent = model

		local weld = Instance.new("Weld")
		weld.Part0 = head
		weld.Part1 = part
		weld.C0 = c0
		weld.Parent = part
	end

	local function addJasonFace(model: Model, head: BasePart)
		local eyeSize = Vector3.new(0.2, 0.2, 0.2)
		local eyebrowSize = Vector3.new(0.15, 0.3, 0.1)

		addJasonFacePart(model, head, "LeftEye", Enum.PartType.Ball, eyeSize, CFrame.new(-0.2, 0.05, -0.55))
		addJasonFacePart(model, head, "RightEye", Enum.PartType.Ball, eyeSize, CFrame.new(0.2, 0.05, -0.55))
		addJasonFacePart(
			model,
			head,
			"LeftEyebrow",
			Enum.PartType.Wedge,
			eyebrowSize,
			CFrame.new(-0.154, 0.196, -0.585) * CFrame.fromEulerAnglesYXZ(-math.pi / 2, math.pi / 2, 0)
		)
		addJasonFacePart(
			model,
			head,
			"RightEyebrow",
			Enum.PartType.Wedge,
			eyebrowSize,
			CFrame.new(0.146, 0.196, -0.585) * CFrame.fromEulerAnglesYXZ(-math.pi / 2, -math.pi / 2, 0)
		)
	end

	local function makeJasonScarecrowHat(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Scarecrow Hat"
		accessory.AccessoryType = Enum.AccessoryType.Hat
		accessory.AttachmentPoint = CFrame.new(0, -0.3, 0) * CFrame.Angles(-0.08726646259971647, 0, 0)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=96076066"
		mesh.TextureId = "http://www.roblox.com/asset/?id=95956050"
		mesh.Scale = Vector3.new(1.2, 1, 1.2)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function makeJasonDownScarf(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "DownScarf"
		accessory.AccessoryType = Enum.AccessoryType.Front

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), JASON_SCARF_COLOR)
		handle.Material = Enum.Material.Fabric
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=57780106"
		mesh.Scale = Vector3.new(1, 1, 1)
		mesh.Parent = handle

		local attachment = Instance.new("Attachment")
		attachment.Name = CHUCKY_CLOAK_ATTACHMENT
		attachment.CFrame = CFrame.new(0, -0.575, -0.475)
		attachment.Parent = handle

		return accessory
	end

	local function makeJasonUpScarf(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "UpScarf"
		accessory.AccessoryType = Enum.AccessoryType.Face
		accessory.AttachmentPoint = CFrame.new(0, 0.975, 0.05)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), JASON_SCARF_COLOR)
		handle.Material = Enum.Material.Fabric
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=74220237"
		mesh.Scale = Vector3.new(1.05, 1.05, 1.05)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function applyJasonHalloween(model: Model)
		clearJasonHalloweenAdditions(model)
		setJasonClothing(model, JASON_LOOK.Halloween)
		setJasonMachete(model, JASON_LOOK.Halloween)
		setJasonMaskVisible(model, false)

		local head = model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			addJasonFace(model, head)
		else
			warn("Jason Halloween transformation: Head was not found in", model:GetFullName(), "- eyes and eyebrows were not added")
		end

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Jason Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- Hat and Scarves were not added")
			return
		end

		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeJasonScarecrowHat(),
			JASON_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeJasonDownScarf(),
			JASON_KILLER_NAME,
			CHUCKY_CLOAK_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeJasonUpScarf(),
			JASON_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
	end

	local function restoreJasonNormal(model: Model)
		clearJasonHalloweenAdditions(model)
		setJasonClothing(model, JASON_LOOK.Normal)
		setJasonMachete(model, JASON_LOOK.Normal)
		setJasonMaskVisible(model, true)
	end

	TRANSFORMATIONS[JASON_KILLER_NAME] = {
		Halloween = {
			-- Only the head changes; the torso and limbs keep their classic colour.
			bodyColors = {
				HeadColor3 = JASON_LOOK.Halloween.headColor,
			},
			applyCustom = applyJasonHalloween,
		},
		Normal = {
			bodyColors = {
				HeadColor3 = JASON_LOOK.Normal.headColor,
			},
			applyCustom = restoreJasonNormal,
		},
	}
end

do
	local JEFF_KILLER_NAME = "Jeff"
	local JEFF_HOOD_COLOR = Color3.fromRGB(254, 243, 187)

	local JEFF_LOOK = {
		Normal = {
			bodyColor = Color3.fromRGB(229, 228, 223),
			clothingColor = Color3.fromRGB(255, 255, 255),
			shirtTemplate = "http://www.roblox.com/asset/?id=107765153",
			pantsTemplate = "http://www.roblox.com/asset/?id=47721958",
			faceColor = Color3.fromRGB(255, 255, 255),
			bladeMeshId = "http://www.roblox.com/asset/?id=20719463",
			bladeTextureId = "http://www.roblox.com/asset/?id=7505470297",
			moltovMeshId = "http://www.roblox.com/asset/?id=29690481",
			moltovTextureId = "",
			moltovOffset = Vector3.new(0, 0, 0),
		},
		Halloween = {
			bodyColor = Color3.fromRGB(120, 144, 130),
			clothingColor = Color3.fromRGB(255, 243, 187),
			shirtTemplate = "http://www.roblox.com/asset/?id=10653261156",
			pantsTemplate = "http://www.roblox.com/asset/?id=10653264026",
			faceColor = Color3.fromRGB(255, 131, 106),
			bladeMeshId = "http://www.roblox.com/asset/?id=70990583",
			bladeTextureId = "http://www.roblox.com/asset/?id=70990591",
			moltovMeshId = "http://www.roblox.com/asset/?id=128240049280261",
			moltovTextureId = "http://www.roblox.com/asset/?id=10698599",
			moltovOffset = Vector3.new(0, 0.1, 0),
		},
	}

	-- The classic accessories (BlondeBob, Dr. Smyth Hair) are deliberately not
	-- listed. Removes the four Halloween ones that were not created (and marked) by
	-- this module, e.g. leftovers from the game's own Halloween script, so they
	-- cannot stack on top of ours.
	local JEFF_HALLOWEEN_ACCESSORY_NAMES = {
		["Cowl"] = true,
		["HoodBase"] = true,
		["Hood"] = true,
		["Necklace"] = true,
	}

	local function clearJeffHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, JEFF_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and JEFF_HALLOWEEN_ACCESSORY_NAMES[child.Name] then
				child:Destroy()
			end
		end
	end

	local function setJeffClothing(model: Model, look: any)
		local shirt = model:FindFirstChildOfClass("Shirt")
		if shirt then
			shirt.ShirtTemplate = look.shirtTemplate
		else
			warn("Jeff transformation: Shirt was not found in", model:GetFullName())
		end

		local pants = model:FindFirstChildOfClass("Pants")
		if pants then
			pants.PantsTemplate = look.pantsTemplate
		else
			warn("Jeff transformation: Pants were not found in", model:GetFullName())
		end
	end

	local function setJeffFaceColor(model: Model, look: any)
		local head = model:FindFirstChild("Head")
		local face = head and head:FindFirstChild("face")
		if face and face:IsA("Decal") then
			face.Color3 = look.faceColor
		else
			warn("Jeff transformation: Head.face was not found in", model:GetFullName())
		end
	end

	local function setJeffBlade(model: Model, look: any)
		local blade = model:FindFirstChild("Blade")
		local handle = blade and blade:FindFirstChild("Handle")
		local mesh = handle and handle:FindFirstChild("Mesh")
		if mesh and mesh:IsA("SpecialMesh") then
			mesh.MeshId = look.bladeMeshId
			mesh.TextureId = look.bladeTextureId
		else
			warn("Jeff transformation: Blade.Handle.Mesh was not found in", model:GetFullName())
		end
	end

	local function setJeffMoltov(model: Model, look: any)
		local moltov = model:FindFirstChild("Moltov")
		local mesh = moltov and moltov:FindFirstChild("Mesh")
		if mesh and mesh:IsA("SpecialMesh") then
			mesh.MeshId = look.moltovMeshId
			mesh.TextureId = look.moltovTextureId
			mesh.Offset = look.moltovOffset
		else
			warn("Jeff transformation: Moltov.Mesh was not found in", model:GetFullName())
		end
	end

	local function setJeffAppearance(model: Model, look: any)
		setJeffClothing(model, look)
		setJeffFaceColor(model, look)
		setJeffBlade(model, look)
		setJeffMoltov(model, look)
	end

	local function makeJeffCowl(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Cowl"
		accessory.AccessoryType = Enum.AccessoryType.Face
		accessory.AttachmentPoint = CFrame.new(0, 0.35, 0.1)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=109214965262550"
		mesh.TextureId = "http://www.roblox.com/asset/?id=134683885538302"
		mesh.Scale = Vector3.new(1, 0.8, 0.8)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function makeJeffHoodPiece(name: string, attachmentPoint: CFrame, meshId: string, meshScale: Vector3): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = name
		accessory.AccessoryType = Enum.AccessoryType.Neck
		accessory.AttachmentPoint = attachmentPoint

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), JEFF_HOOD_COLOR)
		handle.Material = Enum.Material.Carpet
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = meshId
		mesh.Scale = meshScale
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function makeJeffNecklace(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Necklace"
		accessory.AccessoryType = Enum.AccessoryType.Front

		local handle = makeHalloweenHandle("Handle", Vector3.new(0.6, 0.6, 0.6))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=1297931308"
		mesh.TextureId = "http://www.roblox.com/asset/?id=4737063618"
		mesh.Scale = Vector3.new(2.4, 3, 2.4)
		mesh.Parent = handle

		local attachment = Instance.new("Attachment")
		attachment.Name = CHUCKY_CLOAK_ATTACHMENT
		attachment.CFrame = CFrame.new(0, -0.2, -0.3)
		attachment.Parent = handle

		return accessory
	end

	local function applyJeffHalloween(model: Model)
		clearJeffHalloweenAdditions(model)
		setJeffAppearance(model, JEFF_LOOK.Halloween)

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Jeff Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- Cowl, Hood and Necklace were not added")
			return
		end

		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeJeffCowl(),
			JEFF_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeJeffHoodPiece(
				"HoodBase",
				CFrame.new(0, 1.1, 0.2) * CFrame.Angles(0.2617993877991494, 0, 0),
				"http://www.roblox.com/asset/?id=4248979925",
				Vector3.new(1.2, 0.8, 1.2)
			),
			JEFF_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeJeffHoodPiece(
				"Hood",
				CFrame.new(0, 0, -0.85),
				"http://www.roblox.com/asset/?id=90070788490793",
				Vector3.new(1.25, 1.2, 1.3)
			),
			JEFF_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeJeffNecklace(),
			JEFF_KILLER_NAME,
			CHUCKY_CLOAK_ATTACHMENT
		)
	end

	local function restoreJeffNormal(model: Model)
		clearJeffHalloweenAdditions(model)
		setJeffAppearance(model, JEFF_LOOK.Normal)
	end

	TRANSFORMATIONS[JEFF_KILLER_NAME] = {
		Halloween = {
			bodyColor = JEFF_LOOK.Halloween.bodyColor,
			clothingColor = JEFF_LOOK.Halloween.clothingColor,
			applyCustom = applyJeffHalloween,
		},
		Normal = {
			bodyColor = JEFF_LOOK.Normal.bodyColor,
			clothingColor = JEFF_LOOK.Normal.clothingColor,
			applyCustom = restoreJeffNormal,
		},
	}
end

do
	local LEATHERFACE_KILLER_NAME = "Leatherface"
	local LEATHERFACE_BODY_HEAD_NAME = "BodyHead"
	local LEATHERFACE_BODY_HEAD_COLOR = Color3.fromRGB(163, 162, 165)
	local LEATHERFACE_CLASSIC_HAIR_NAME = "CrazyGameDevHair"
	local LEATHERFACE_HALLOWEEN_HAIR_NAME = "Ultra-Fabulous Hair"

	local LEATHERFACE_NORMAL_SKIN_COLOR = Color3.fromRGB(234, 184, 146)
	local LEATHERFACE_NORMAL_TORSO_COLOR = Color3.fromRGB(234, 184, 58)

	local LEATHERFACE_LOOK = {
		Normal = {
			clothingColor = Color3.fromRGB(255, 197, 131),
			shirtTemplate = "rbxassetid://7232537579",
			pantsTemplate = "rbxassetid://14909771835",
			collarColor = Color3.fromRGB(133, 134, 85),
			tieColor = Color3.fromRGB(27, 42, 53),
			headTransparency = 0,
		},
		Halloween = {
			bodyColor = Color3.fromRGB(169, 172, 140),
			clothingColor = Color3.fromRGB(194, 122, 63),
			shirtTemplate = "http://www.roblox.com/asset/?id=14492489716",
			pantsTemplate = "http://www.roblox.com/asset/?id=14492491657",
			collarColor = Color3.fromRGB(167, 113, 47),
			tieColor = Color3.fromRGB(169, 172, 140),
			headTransparency = 1,
			bodyHead = {
				meshId = "http://www.roblox.com/asset/?id=181343290",
				textureId = "http://roblox.com/asset/?id=181343313",
				scale = Vector3.new(1, 1, 1),
			},
		},
	}

	local function clearLeatherfaceHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, LEATHERFACE_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and child.Name == LEATHERFACE_HALLOWEEN_HAIR_NAME then
				child:Destroy()
			elseif child:IsA("BasePart") and child.Name == LEATHERFACE_BODY_HEAD_NAME then
				child:Destroy()
			end
		end
	end

	local function setLeatherfaceClothing(model: Model, look: any)
		local shirt = model:FindFirstChildOfClass("Shirt")
		if shirt then
			shirt.ShirtTemplate = look.shirtTemplate
		else
			warn("Leatherface transformation: Shirt was not found in", model:GetFullName())
		end

		local pants = model:FindFirstChildOfClass("Pants")
		if pants then
			pants.PantsTemplate = look.pantsTemplate
		else
			warn("Leatherface transformation: Pants were not found in", model:GetFullName())
		end
	end

	local function setLeatherfaceAccessoryColor(model: Model, accessoryName: string, color: Color3)
		local accessory = model:FindFirstChild(accessoryName)
		local handle = accessory and accessory:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			handle.Color = color
		else
			warn("Leatherface transformation:", accessoryName .. ".Handle was not found in", model:GetFullName())
		end
	end

	local function setLeatherfaceClassicHairVisible(model: Model, visible: boolean)
		local hair = model:FindFirstChild(LEATHERFACE_CLASSIC_HAIR_NAME)
		if not hair or not hair:IsA("Accessory") then
			if visible then
				warn(
					"Leatherface transformation: the classic",
					LEATHERFACE_CLASSIC_HAIR_NAME,
					"is missing from",
					model:GetFullName(),
					"and cannot be rebuilt (MeshPart.MeshId is not scriptable)"
				)
			end
			return
		end

		local transparency = if visible then 0 else 1
		for _, descendant in ipairs(hair:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = transparency
			end
		end
	end

	local function addLeatherfaceBodyHead(model: Model, head: BasePart, spec: any)
		local bodyHead = makeHalloweenHandle(LEATHERFACE_BODY_HEAD_NAME, Vector3.new(1, 1, 1), LEATHERFACE_BODY_HEAD_COLOR)
		markHalloweenObjectForKiller(bodyHead, LEATHERFACE_KILLER_NAME)

		pcall(function()
			bodyHead.CollisionGroup = head.CollisionGroup
		end)

		bodyHead.CFrame = head.CFrame

		local mesh = Instance.new("SpecialMesh")
		mesh.Name = "Mesh"
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = spec.meshId
		mesh.TextureId = spec.textureId
		mesh.Scale = spec.scale
		mesh.Parent = bodyHead

		bodyHead.Parent = model

		local weld = Instance.new("Weld")
		weld.Name = "Weld"
		weld.Part0 = head
		weld.Part1 = bodyHead
		weld.C0 = CFrame.new()
		weld.C1 = CFrame.new()
		weld.Parent = bodyHead
	end

	local function setLeatherfaceHead(model: Model, look: any)
		local head = model:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then
			warn("Leatherface transformation: Head was not found in", model:GetFullName())
			return
		end

		head.Transparency = look.headTransparency
		if look.bodyHead then
			addLeatherfaceBodyHead(model, head, look.bodyHead)
		end
	end

	local function makeLeatherfaceHair(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = LEATHERFACE_HALLOWEEN_HAIR_NAME
		accessory.AccessoryType = Enum.AccessoryType.Hair
		accessory.AttachmentPoint = CFrame.new(-0.175, 0, 0)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(17, 17, 17))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=133015896128308"
		mesh.Scale = Vector3.new(1.05, 1.05, 1.05)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function applyLeatherfaceHalloween(model: Model)
		clearLeatherfaceHalloweenAdditions(model)

		local look = LEATHERFACE_LOOK.Halloween
		setLeatherfaceClothing(model, look)
		setLeatherfaceAccessoryColor(model, "Collar", look.collarColor)
		setLeatherfaceAccessoryColor(model, "Tie", look.tieColor)
		setLeatherfaceHead(model, look)

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Leatherface Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- Hair was not added")
			return
		end

		local hair = makeLeatherfaceHair()
		addMarkedHalloweenAccessory(model, zombie, hair, LEATHERFACE_KILLER_NAME, LEGACY_ACCESSORY_ATTACHMENT)

		-- Only hide the classic hair once the new one is really on the rig, so a
		-- failed AddAccessory never leaves Leatherface bald.
		if hair.Parent == model then
			setLeatherfaceClassicHairVisible(model, false)
		end
	end

	local function restoreLeatherfaceNormal(model: Model)
		clearLeatherfaceHalloweenAdditions(model)

		local look = LEATHERFACE_LOOK.Normal
		setLeatherfaceClothing(model, look)
		setLeatherfaceAccessoryColor(model, "Collar", look.collarColor)
		setLeatherfaceAccessoryColor(model, "Tie", look.tieColor)
		setLeatherfaceHead(model, look)
		setLeatherfaceClassicHairVisible(model, true)
	end

	TRANSFORMATIONS[LEATHERFACE_KILLER_NAME] = {
		Halloween = {
			bodyColor = LEATHERFACE_LOOK.Halloween.bodyColor,
			clothingColor = LEATHERFACE_LOOK.Halloween.clothingColor,
			applyCustom = applyLeatherfaceHalloween,
		},
		Normal = {
			-- Head and limbs are skin coloured; only the torso differs (see above).
			bodyColor = LEATHERFACE_NORMAL_SKIN_COLOR,
			bodyColors = {
				TorsoColor3 = LEATHERFACE_NORMAL_TORSO_COLOR,
			},
			clothingColor = LEATHERFACE_LOOK.Normal.clothingColor,
			applyCustom = restoreLeatherfaceNormal,
		},
	}
end

do
	local MICHAEL_KILLER_NAME = "Michael Myers"

	local MICHAEL_LOOK = {
		Normal = {
			headColor = Color3.fromRGB(112, 105, 106),
			armColor = Color3.fromRGB(234, 184, 146),
			clothingColor = Color3.fromRGB(255, 255, 255),
			knifeColor = Color3.fromRGB(91, 93, 105),
			knifeMaterial = Enum.Material.Limestone,
			maskTextureId = "",
		},
		Halloween = {
			headColor = Color3.fromRGB(0, 0, 0),
			armColor = Color3.fromRGB(215, 130, 65),
			clothingColor = Color3.fromRGB(255, 175, 105),
			knifeColor = Color3.fromRGB(170, 85, 0),
			knifeMaterial = Enum.Material.Neon,
			maskTextureId = "http://www.roblox.com/asset/?id=1138085935",
		},
	}

	local MICHAEL_MASK_COLOR_MAP = "rbxassetid://132906330"
	local MICHAEL_MASK_TEXTURE_PACK = "rbxassetid://85200159055261"

	local function setMichaelKnife(model: Model, look: any)
		local knife = model:FindFirstChild("Knife")
		if not knife then
			warn(MICHAEL_KILLER_NAME .. " transformation: Knife was not found in", model:GetFullName())
			return
		end

		for _, partName in ipairs({ "Base", "Tip" }) do
			local part = knife:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				part.Color = look.knifeColor
				part.Material = look.knifeMaterial
			else
				warn(MICHAEL_KILLER_NAME .. " transformation: Knife." .. partName .. " was not found in", model:GetFullName())
			end
		end
	end

	local function findMichaelMaskHandle(model: Model): MeshPart?
		local mask = model:FindFirstChild("HockeyMask")
		local handle = mask and mask:FindFirstChild("Handle")
		if handle and handle:IsA("MeshPart") then
			return handle
		end

		warn(MICHAEL_KILLER_NAME .. " transformation: HockeyMask.Handle was not found in", model:GetFullName())
		return nil
	end

	local function restoreMichaelMaskSurfaceAppearance(handle: MeshPart)
		local existingSurfaceAppearance: SurfaceAppearance? = nil
		for _, child in ipairs(handle:GetChildren()) do
			if child:IsA("SurfaceAppearance") then
				if existingSurfaceAppearance == nil then
					existingSurfaceAppearance = child
				else
					child:Destroy()
				end
			end
		end

		local surfaceAppearance = existingSurfaceAppearance or Instance.new("SurfaceAppearance")
		if existingSurfaceAppearance == nil then
			surfaceAppearance.Parent = handle
		end

		surfaceAppearance.ColorMap = MICHAEL_MASK_COLOR_MAP
		surfaceAppearance.TexturePack = MICHAEL_MASK_TEXTURE_PACK
		surfaceAppearance.AlphaMode = Enum.AlphaMode.Overlay
		surfaceAppearance.Color = Color3.fromRGB(255, 255, 255)
	end

	local function applyMichaelMyersHalloween(model: Model)
		local look = MICHAEL_LOOK.Halloween

		setMichaelKnife(model, look)

		local handle = findMichaelMaskHandle(model)
		if handle then
			removeSurfaceAppearances(handle)
			handle.TextureID = look.maskTextureId
		end
	end

	local function restoreMichaelMyersNormal(model: Model)
		local look = MICHAEL_LOOK.Normal

		setMichaelKnife(model, look)

		local handle = findMichaelMaskHandle(model)
		if handle then
			handle.TextureID = look.maskTextureId
			restoreMichaelMaskSurfaceAppearance(handle)
		end
	end

	TRANSFORMATIONS[MICHAEL_KILLER_NAME] = {
		Halloween = {
			-- Only the head and both arms change; the torso and legs keep their
			-- classic colour.
			bodyColors = {
				HeadColor3 = MICHAEL_LOOK.Halloween.headColor,
				LeftArmColor3 = MICHAEL_LOOK.Halloween.armColor,
				RightArmColor3 = MICHAEL_LOOK.Halloween.armColor,
			},
			clothingColor = MICHAEL_LOOK.Halloween.clothingColor,
			applyCustom = applyMichaelMyersHalloween,
		},
		Normal = {
			bodyColors = {
				HeadColor3 = MICHAEL_LOOK.Normal.headColor,
				LeftArmColor3 = MICHAEL_LOOK.Normal.armColor,
				RightArmColor3 = MICHAEL_LOOK.Normal.armColor,
			},
			clothingColor = MICHAEL_LOOK.Normal.clothingColor,
			applyCustom = restoreMichaelMyersNormal,
		},
	}
end

do
	local PENNYWISE_KILLER_NAME = "Pennywise"

	local PENNYWISE_LOOK = {
		Normal = {
			shirtTemplate = "rbxassetid://1148373815",
			pantsTemplate = "rbxassetid://1180873113",
			faceTexture = "rbxassetid://1135138207",
			balloonColor = Color3.fromRGB(196, 40, 28),
		},
		Halloween = {
			shirtTemplate = "http://www.roblox.com/asset/?id=6089622408",
			pantsTemplate = "http://www.roblox.com/asset/?id=6089623883",
			faceTexture = "http://www.roblox.com/asset/?id=14546278370",
			balloonColor = Color3.fromRGB(245, 205, 48),
		},
	}

	-- Hidden for Halloween, shown again for Normal; never destroyed.
	local PENNYWISE_CLASSIC_HAIR_NAMES = { "Clown", "CrazyClown", "LarryHair" }

	-- The classic rig owns none of these, so anything with one of these names is a
	-- Halloween addition (or a leftover of one).
	local PENNYWISE_FRO_NAME = "Rainbow Disco Fro"
	local PENNYWISE_HALLOWEEN_ACCESSORY_NAMES = {
		[PENNYWISE_FRO_NAME] = true,
		["Collar"] = true,
		["Nose"] = true,
	}

	local function clearPennywiseHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, PENNYWISE_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and PENNYWISE_HALLOWEEN_ACCESSORY_NAMES[child.Name] then
				child:Destroy()
			end
		end
	end

	local function setPennywiseAppearance(model: Model, look: any)
		local shirt = model:FindFirstChildOfClass("Shirt")
		if shirt then
			shirt.ShirtTemplate = look.shirtTemplate
		else
			warn(PENNYWISE_KILLER_NAME .. " transformation: Shirt was not found in", model:GetFullName())
		end

		local pants = model:FindFirstChildOfClass("Pants")
		if pants then
			pants.PantsTemplate = look.pantsTemplate
		else
			warn(PENNYWISE_KILLER_NAME .. " transformation: Pants were not found in", model:GetFullName())
		end

		local head = model:FindFirstChild("Head")
		local face = head and head:FindFirstChild("face")
		if face and face:IsA("Decal") then
			face.Texture = look.faceTexture
		else
			warn(PENNYWISE_KILLER_NAME .. " transformation: Head.face was not found in", model:GetFullName())
		end

		local balloon = model:FindFirstChild("Balloon")
		if balloon and balloon:IsA("BasePart") then
			balloon.Color = look.balloonColor
		else
			warn(PENNYWISE_KILLER_NAME .. " transformation: Balloon was not found in", model:GetFullName())
		end
	end

	local function setPennywiseClassicHairVisible(model: Model, visible: boolean)
		local transparency = if visible then 0 else 1

		for _, accessoryName in ipairs(PENNYWISE_CLASSIC_HAIR_NAMES) do
			local accessory = model:FindFirstChild(accessoryName)
			if accessory and accessory:IsA("Accessory") then
				for _, descendant in ipairs(accessory:GetDescendants()) do
					if descendant:IsA("BasePart") then
						descendant.Transparency = transparency
					end
				end
			elseif visible then
				warn(
					PENNYWISE_KILLER_NAME .. " transformation: the classic",
					accessoryName,
					"is missing from",
					model:GetFullName(),
					"and cannot be rebuilt (MeshPart.MeshId is not scriptable)"
				)
			end
		end
	end

	local function makePennywiseFro(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = PENNYWISE_FRO_NAME
		accessory.AccessoryType = Enum.AccessoryType.Hair
		accessory.AttachmentPoint = CFrame.new(0, -0.6, 0.1) * CFrame.Angles(-3 * math.pi / 4, 0, 0)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(117, 0, 0))
		handle.Material = Enum.Material.Slate
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=11412443"
		mesh.Scale = Vector3.new(1.5, 1.2, 1)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function makePennywiseCollar(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Collar"
		accessory.AccessoryType = Enum.AccessoryType.Neck
		accessory.AttachmentPoint = CFrame.new(0, 0.94, 0) * CFrame.Angles(0, math.pi, 0)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(231, 231, 236))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=17873973520"
		mesh.Scale = Vector3.new(1, 0.8, 1)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function makePennywiseNose(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Nose"
		accessory.AccessoryType = Enum.AccessoryType.Face
		accessory.AttachmentPoint = CFrame.new(0, 0.42, 0.65)

		local handle = makeHalloweenHandle("Handle", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(151, 0, 0))
		handle.Shape = Enum.PartType.Ball
		handle.Parent = accessory

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function applyPennywiseHalloween(model: Model)
		clearPennywiseHalloweenAdditions(model)
		setPennywiseAppearance(model, PENNYWISE_LOOK.Halloween)

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn(
				"Pennywise Halloween transformation: missing Humanoid 'Zombie' in",
				model:GetFullName(),
				"- accessories were not added"
			)
			return
		end

		local fro = makePennywiseFro()
		addMarkedHalloweenAccessory(model, zombie, fro, PENNYWISE_KILLER_NAME, LEGACY_ACCESSORY_ATTACHMENT)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makePennywiseCollar(),
			PENNYWISE_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makePennywiseNose(),
			PENNYWISE_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)

		-- Only hide the classic hair once the new one is really on the rig, so a
		-- failed AddAccessory never leaves Pennywise bald.
		if fro.Parent == model then
			setPennywiseClassicHairVisible(model, false)
		end
	end

	local function restorePennywiseNormal(model: Model)
		clearPennywiseHalloweenAdditions(model)
		setPennywiseAppearance(model, PENNYWISE_LOOK.Normal)
		setPennywiseClassicHairVisible(model, true)
	end

	TRANSFORMATIONS[PENNYWISE_KILLER_NAME] = {
		Halloween = {
			applyCustom = applyPennywiseHalloween,
		},
		Normal = {
			applyCustom = restorePennywiseNormal,
		},
	}
end

do
	local PINHEAD_KILLER_NAME = "Pinhead"
	local PINHEAD_HAT_NAME = "PinHat"
	local PINHEAD_SECOND_HAT_NAME = "PinHat2"

	local PINHEAD_LOOK = {
		Normal = {
			shirtTemplate = "http://www.roblox.com/asset/?id=12725530969",
			boxMeshId = "http://www.roblox.com/asset/?id=95358536",
			boxTextureId = "http://www.roblox.com/asset/?id=95358617",
			boxMeshScale = Vector3.new(0.35, 0.35, 0.35),
			hatColor = Color3.fromRGB(27, 42, 53),
		},
		Halloween = {
			shirtTemplate = "http://www.roblox.com/asset/?id=14935532910",
			boxMeshId = "http://www.roblox.com/asset/?id=16973748",
			boxTextureId = "http://www.roblox.com/asset/?id=2397253924",
			boxMeshScale = Vector3.new(0.8, 0.8, 0.8),
			hatColor = Color3.fromRGB(220, 135, 65),
		},
	}

	-- PinHat.Handle.HatAttachment is (0, 0.5, 0) in the classic rig; PinHat2's is
	-- the same, tilted 0.27 radians about X.
	local PINHEAD_HAT_ATTACHMENT_CFRAME = CFrame.new(0, 0.5, 0)
	local PINHEAD_SECOND_HAT_TILT = CFrame.Angles(0.27, 0, 0)
	local PINHEAD_SECOND_HAT_COLOR = Color3.fromRGB(245, 205, 50)

	local function clearPinheadHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, PINHEAD_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and child.Name == PINHEAD_SECOND_HAT_NAME then
				child:Destroy()
			end
		end
	end

	local function setPinheadShirt(model: Model, look: any)
		local shirt = model:FindFirstChildOfClass("Shirt")
		if shirt then
			shirt.ShirtTemplate = look.shirtTemplate
		else
			warn(PINHEAD_KILLER_NAME .. " transformation: Shirt was not found in", model:GetFullName())
		end
	end

	local function setPinheadBox(model: Model, look: any)
		local box = model:FindFirstChild("Box")
		local handle = box and box:FindFirstChild("Handle")
		local mesh = handle and handle:FindFirstChild("Mesh")
		if mesh and mesh:IsA("SpecialMesh") then
			mesh.MeshId = look.boxMeshId
			mesh.TextureId = look.boxTextureId
			mesh.Scale = look.boxMeshScale
		else
			warn(PINHEAD_KILLER_NAME .. " transformation: Box.Handle.Mesh was not found in", model:GetFullName())
		end
	end

	-- Returns the classic PinHat's Handle, or nil (after a warning) if it is gone.
	local function findPinheadHatHandle(model: Model): BasePart?
		local hat = model:FindFirstChild(PINHEAD_HAT_NAME)
		local handle = hat and hat:FindFirstChild("Handle")
		if hat and hat:IsA("Accessory") and handle and handle:IsA("BasePart") then
			return handle
		end

		warn(PINHEAD_KILLER_NAME .. " transformation: PinHat.Handle was not found in", model:GetFullName())
		return nil
	end

	local function setPinheadHatColor(model: Model, look: any)
		local handle = findPinheadHatHandle(model)
		if handle then
			handle.Color = look.hatColor
		end
	end

	-- Clones the real PinHat into PinHat2: same mesh, a tilted HatAttachment and
	-- the yellow colour. Both are assigned as absolute values (not read back from
	-- the live PinHat), so the result never depends on what PinHat looks like at
	-- the moment. Returns nil if there is nothing to clone.
	local function makePinheadSecondHat(model: Model): Accessory?
		local hat = model:FindFirstChild(PINHEAD_HAT_NAME)
		if not hat or not hat:IsA("Accessory") then
			warn(PINHEAD_KILLER_NAME .. " Halloween transformation: PinHat was not found in", model:GetFullName(), "- PinHat2 was not added")
			return nil
		end

		local clone = hat:Clone() :: Accessory
		clone.Name = PINHEAD_SECOND_HAT_NAME

		local handle = clone:FindFirstChild("Handle")
		local attachment = handle and handle:FindFirstChild(CHUCKY_HAT_POINT_ATTACHMENT)
		if not handle or not handle:IsA("BasePart") or not attachment or not attachment:IsA("Attachment") then
			warn(PINHEAD_KILLER_NAME .. " Halloween transformation: PinHat.Handle.HatAttachment was not found in", model:GetFullName(), "- PinHat2 was not added")
			clone:Destroy()
			return nil
		end

		handle.Color = PINHEAD_SECOND_HAT_COLOR
		attachment.CFrame = PINHEAD_HAT_ATTACHMENT_CFRAME * PINHEAD_SECOND_HAT_TILT

		return clone
	end

	local function applyPinheadHalloween(model: Model)
		local look = PINHEAD_LOOK.Halloween

		clearPinheadHalloweenAdditions(model)
		setPinheadShirt(model, look)
		setPinheadBox(model, look)
		setPinheadHatColor(model, look)

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Pinhead Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- PinHat2 was not added")
			return
		end

		local secondHat = makePinheadSecondHat(model)
		if secondHat then
			addMarkedHalloweenAccessory(model, zombie, secondHat, PINHEAD_KILLER_NAME, CHUCKY_HAT_POINT_ATTACHMENT)
		end
	end

	local function restorePinheadNormal(model: Model)
		local look = PINHEAD_LOOK.Normal

		clearPinheadHalloweenAdditions(model)
		setPinheadShirt(model, look)
		setPinheadBox(model, look)
		setPinheadHatColor(model, look)
	end

	TRANSFORMATIONS[PINHEAD_KILLER_NAME] = {
		Halloween = {
			applyCustom = applyPinheadHalloween,
		},
		Normal = {
			applyCustom = restorePinheadNormal,
		},
	}
end

do
	local RAKE_KILLER_NAME = "Rake"
	local RAKE_BODY_HEAD_NAME = "BodyHead"
	local RAKE_BODY_HANDLE_NAME = "BodyHandle"
	local RAKE_BODY_ATTACHMENT = "BodyBackAttachment"
	local RAKE_WAIST_ATTACHMENT = "WaistBackAttachment"

	local RAKE_BODY_PART_NAMES = {
		"UpperTorso",
		"LowerTorso",
		"LeftUpperArm",
		"LeftLowerArm",
		"LeftHand",
		"RightUpperArm",
		"RightLowerArm",
		"RightHand",
		"LeftUpperLeg",
		"LeftLowerLeg",
		"LeftFoot",
		"RightUpperLeg",
		"RightLowerLeg",
		"RightFoot",
	}

	-- The parts that each own a "Claw".
	local RAKE_CLAW_OWNER_NAMES = { "LeftHand", "RightHand", "LeftFoot", "RightFoot" }

	local RAKE_MOUTH_ROTATION = CFrame.fromEulerAnglesYXZ(-math.pi / 2, math.pi, 0)

	local RAKE_HALLOWEEN_HEAD = {
		meshId = "http://www.roblox.com/asset/?id=41447062",
		textureId = "",
		scale = Vector3.new(0.8, 0.8, 0.8),
		color = Color3.fromRGB(64, 64, 64),
	}

	local RAKE_LOOK = {
		Normal = {
			bodyColor = Color3.fromRGB(163, 162, 165),
			bodyMaterial = Enum.Material.Marble,
			skeletonColor = Color3.fromRGB(163, 162, 165),
			skeletonMaterial = Enum.Material.Marble,
			clawColor = Color3.fromRGB(136, 62, 62),
			headHandleTransparency = 0,
			mouthColor = Color3.fromRGB(163, 162, 165),
			mouthDecalColor = Color3.fromRGB(255, 255, 255),
			mouthMeshScale = Vector3.new(1, 1, 1),
			mouthWeldC0 = CFrame.new(0, -0.725, -0.45) * RAKE_MOUTH_ROTATION,
			eyeLeftBaseC0 = CFrame.new(-0.18, 0.07, -0.41),
			eyeRightBaseC0 = CFrame.new(0.18, 0.07, -0.41),
			eyeLeftC0 = CFrame.new(-0.204, 0.07, -0.49),
			eyeRightC0 = CFrame.new(0.204, 0.07, -0.49),
			eyeColor = Color3.fromRGB(248, 248, 248),
		},
		Halloween = {
			bodyColor = Color3.fromRGB(91, 102, 117),
			bodyMaterial = Enum.Material.Rock,
			skeletonColor = Color3.fromRGB(59, 68, 117),
			skeletonMaterial = Enum.Material.Rock,
			clawColor = Color3.fromRGB(59, 68, 117),
			headHandleTransparency = 1,
			mouthColor = Color3.fromRGB(64, 64, 64),
			mouthDecalColor = Color3.fromRGB(0, 153, 255),
			mouthMeshScale = Vector3.new(1, 0.5, 1.05),
			mouthWeldC0 = CFrame.new(0, -0.698, -0.72) * RAKE_MOUTH_ROTATION,
			eyeLeftBaseC0 = CFrame.new(-0.18, 0, -0.51),
			eyeRightBaseC0 = CFrame.new(0.18, 0, -0.51),
			eyeLeftC0 = CFrame.new(-0.2, 0.012, -0.59),
			eyeRightC0 = CFrame.new(0.2, 0.012, -0.59),
			eyeColor = Color3.fromRGB(82, 124, 174),
		},
	}

	local function clearRakeHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, RAKE_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and (child.Name == "Wings" or child.Name == "Tail") then
				child:Destroy()
			elseif child:IsA("BasePart")
				and (child.Name == RAKE_BODY_HEAD_NAME or child.Name == RAKE_BODY_HANDLE_NAME) then
				child:Destroy()
			end
		end
	end

	local function setRakeBody(model: Model, look: any)
		for _, partName in ipairs(RAKE_BODY_PART_NAMES) do
			local part = model:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				part.Material = look.bodyMaterial
			else
				warn(RAKE_KILLER_NAME .. " transformation: missing part", partName, "in", model:GetFullName())
			end
		end

		local skeleton = model:FindFirstChild("Skeleton")
		local skeletonHandle = skeleton and skeleton:FindFirstChild("Handle")
		if skeletonHandle and skeletonHandle:IsA("BasePart") then
			skeletonHandle.Color = look.skeletonColor
			skeletonHandle.Material = look.skeletonMaterial
		else
			warn(RAKE_KILLER_NAME .. " transformation: Skeleton.Handle was not found in", model:GetFullName())
		end

		for _, ownerName in ipairs(RAKE_CLAW_OWNER_NAMES) do
			local owner = model:FindFirstChild(ownerName)
			local claw = owner and owner:FindFirstChild("Claw")
			if claw and claw:IsA("BasePart") then
				claw.Color = look.clawColor
			else
				warn(RAKE_KILLER_NAME .. " transformation:", ownerName .. ".Claw was not found in", model:GetFullName())
			end
		end
	end

	local function setRakeWeldC0(zombieHead: Instance, partName: string, weldName: string, c0: CFrame)
		local part = zombieHead:FindFirstChild(partName)
		local weld = part and part:FindFirstChild(weldName)
		if weld and weld:IsA("JointInstance") then
			weld.C0 = c0
		else
			warn(RAKE_KILLER_NAME .. " transformation: ZombieHead." .. partName .. "." .. weldName .. " was not found")
		end
	end

	local function setRakeFace(model: Model, look: any)
		local zombieHead = model:FindFirstChild("ZombieHead")
		if not zombieHead then
			warn(RAKE_KILLER_NAME .. " transformation: ZombieHead was not found in", model:GetFullName())
			return
		end

		local mouth = zombieHead:FindFirstChild("Mouth")
		if mouth and mouth:IsA("BasePart") then
			mouth.Color = look.mouthColor

			local decal = mouth:FindFirstChild("MouthDecal")
			if decal and decal:IsA("Decal") then
				decal.Color3 = look.mouthDecalColor
			else
				warn(RAKE_KILLER_NAME .. " transformation: ZombieHead.Mouth.MouthDecal was not found")
			end

			local mesh = mouth:FindFirstChild("Mesh")
			if mesh and mesh:IsA("SpecialMesh") then
				mesh.Scale = look.mouthMeshScale
			else
				warn(RAKE_KILLER_NAME .. " transformation: ZombieHead.Mouth.Mesh was not found")
			end
		else
			warn(RAKE_KILLER_NAME .. " transformation: ZombieHead.Mouth was not found in", model:GetFullName())
		end

		setRakeWeldC0(zombieHead, "Mouth", "MouthWeld", look.mouthWeldC0)
		setRakeWeldC0(zombieHead, "Eye1Base", "EyeLeftBase", look.eyeLeftBaseC0)
		setRakeWeldC0(zombieHead, "Eye2Base", "EyeRightBase", look.eyeRightBaseC0)
		setRakeWeldC0(zombieHead, "Eye1", "EyeLeft", look.eyeLeftC0)
		setRakeWeldC0(zombieHead, "Eye2", "EyeRight", look.eyeRightC0)

		for _, eyeName in ipairs({ "Eye1", "Eye2" }) do
			local eye = zombieHead:FindFirstChild(eyeName)
			if eye and eye:IsA("BasePart") then
				eye.Color = look.eyeColor
			else
				warn(RAKE_KILLER_NAME .. " transformation: ZombieHead." .. eyeName .. " was not found in", model:GetFullName())
			end
		end
	end

	local function findRakeHeadHandle(model: Model): BasePart?
		local zombieHead = model:FindFirstChild("ZombieHead")
		local handle = zombieHead and zombieHead:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			return handle
		end

		warn(RAKE_KILLER_NAME .. " transformation: ZombieHead.Handle was not found in", model:GetFullName())
		return nil
	end

	local function addRakeBodyHead(model: Model, handle: BasePart)
		local bodyHead = makeHalloweenHandle(RAKE_BODY_HEAD_NAME, Vector3.new(1, 1, 1), RAKE_HALLOWEEN_HEAD.color)
		bodyHead.Material = Enum.Material.Rock
		markHalloweenObjectForKiller(bodyHead, RAKE_KILLER_NAME)

		pcall(function()
			bodyHead.CollisionGroup = handle.CollisionGroup
		end)

		bodyHead.CFrame = handle.CFrame

		local mesh = Instance.new("SpecialMesh")
		mesh.Name = "Mesh"
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = RAKE_HALLOWEEN_HEAD.meshId
		mesh.TextureId = RAKE_HALLOWEEN_HEAD.textureId
		mesh.Scale = RAKE_HALLOWEEN_HEAD.scale
		mesh.Parent = bodyHead

		bodyHead.Parent = model

		local weld = Instance.new("Weld")
		weld.Name = "Weld"
		weld.Part0 = handle
		weld.Part1 = bodyHead
		weld.C0 = CFrame.new()
		weld.C1 = CFrame.new()
		weld.Parent = bodyHead
	end

	local function makeRakeWings(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Wings"
		accessory.AccessoryType = Enum.AccessoryType.Back

		local handle = makeHalloweenHandle("Handle", Vector3.new(2, 2, 2))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=119004037"
		mesh.TextureId = "http://www.roblox.com/asset/?id=119003328"
		mesh.Scale = Vector3.new(1, 0.7, 0.8)
		mesh.Parent = handle

		local attachment = Instance.new("Attachment")
		attachment.Name = RAKE_BODY_ATTACHMENT
		attachment.CFrame = CFrame.new(0, -0.7, -0.8)
		attachment.Parent = handle

		return accessory
	end

	local function makeRakeTail(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = "Tail"
		accessory.AccessoryType = Enum.AccessoryType.Waist

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1), Color3.fromRGB(27, 42, 53))
		handle.Material = Enum.Material.Rock
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=2855522331"
		mesh.Scale = Vector3.new(0.55, 0.55, 0.55)
		mesh.Parent = handle

		local attachment = Instance.new("Attachment")
		attachment.Name = RAKE_WAIST_ATTACHMENT
		attachment.CFrame = CFrame.new(0, -1, -1)
		attachment.Parent = handle

		return accessory
	end

	local function applyRakeHalloween(model: Model)
		local look = RAKE_LOOK.Halloween

		clearRakeHalloweenAdditions(model)
		setRakeBody(model, look)
		setRakeFace(model, look)

		local headHandle = findRakeHeadHandle(model)
		if headHandle then
			headHandle.Transparency = look.headHandleTransparency
			addRakeBodyHead(model, headHandle)
		end

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Rake Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- Wings and Tail were not added")
			return
		end

		addMarkedHalloweenAccessory(model, zombie, makeRakeWings(), RAKE_KILLER_NAME, RAKE_BODY_ATTACHMENT)
		addMarkedHalloweenAccessory(model, zombie, makeRakeTail(), RAKE_KILLER_NAME, RAKE_WAIST_ATTACHMENT)
	end

	local function restoreRakeNormal(model: Model)
		local look = RAKE_LOOK.Normal

		clearRakeHalloweenAdditions(model)
		setRakeBody(model, look)
		setRakeFace(model, look)

		local headHandle = findRakeHeadHandle(model)
		if headHandle then
			headHandle.Transparency = look.headHandleTransparency
		end
	end

	TRANSFORMATIONS[RAKE_KILLER_NAME] = {
		Halloween = {
			bodyColor = RAKE_LOOK.Halloween.bodyColor,
			applyCustom = applyRakeHalloween,
		},
		Normal = {
			bodyColor = RAKE_LOOK.Normal.bodyColor,
			applyCustom = restoreRakeNormal,
		},
	}
end

do
	local ROBOT_KILLER_NAME = "Robot"
	local ROBOT_HELMET_NAME = "Helmet"
	local ROBOT_EYE_NAMES = { "Left Eye", "Right Eye" }

	local ROBOT_LOOK = {
		Normal = {
			eyeColor = Color3.fromRGB(255, 0, 0),
			headTransparency = 0,
		},
		Halloween = {
			eyeColor = Color3.fromRGB(215, 115, 60),
			headTransparency = 1,
		},
	}

	local function clearRobotHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, ROBOT_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and child.Name == ROBOT_HELMET_NAME then
				child:Destroy()
			end
		end
	end

	local function setRobotEyeColor(model: Model, color: Color3)
		for _, eyeName in ipairs(ROBOT_EYE_NAMES) do
			local eye = model:FindFirstChild(eyeName)
			if eye and eye:IsA("BasePart") then
				eye.Color = color
			else
				warn(ROBOT_KILLER_NAME .. " transformation: missing part", eyeName, "in", model:GetFullName())
			end
		end
	end

	local function setRobotHeadTransparency(model: Model, transparency: number)
		local head = model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			head.Transparency = transparency
		else
			warn(ROBOT_KILLER_NAME .. " transformation: Head was not found in", model:GetFullName())
		end
	end

	local function makeRobotHelmet(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = ROBOT_HELMET_NAME
		accessory.AccessoryType = Enum.AccessoryType.Face
		accessory.AttachmentPoint = CFrame.new(0, 0.59, -0.1)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=13158197"
		mesh.TextureId = "http://www.roblox.com/asset/?id=13158218"
		mesh.Scale = Vector3.new(1.05, 1.05, 1.05)
		mesh.VertexColor = Vector3.new(0.45, 0.45, 0.45)
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function applyRobotHalloween(model: Model)
		local look = ROBOT_LOOK.Halloween

		clearRobotHalloweenAdditions(model)
		setRobotEyeColor(model, look.eyeColor)

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Robot Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- Helmet was not added and the Head was left visible")
			return
		end

		local helmet = makeRobotHelmet()
		addMarkedHalloweenAccessory(model, zombie, helmet, ROBOT_KILLER_NAME, LEGACY_ACCESSORY_ATTACHMENT)

		-- Only hide the real Head once the Helmet is really on the rig, so a failed
		-- AddAccessory never leaves Robot headless.
		if helmet.Parent == model then
			setRobotHeadTransparency(model, look.headTransparency)
		end
	end

	local function restoreRobotNormal(model: Model)
		local look = ROBOT_LOOK.Normal

		clearRobotHalloweenAdditions(model)
		setRobotEyeColor(model, look.eyeColor)
		setRobotHeadTransparency(model, look.headTransparency)
	end

	TRANSFORMATIONS[ROBOT_KILLER_NAME] = {
		Halloween = {
			-- Body Colors are never touched (the torso differs from the limbs).
			applyCustom = applyRobotHalloween,
		},
		Normal = {
			applyCustom = restoreRobotNormal,
		},
	}
end

do
	local SLENDERMAN_KILLER_NAME = "Slenderman"
	local SLENDERMAN_PUMPKIN_NAME = "EvilPumpkin"

	local SLENDERMAN_NORMAL_TIE_COLOR = Color3.fromRGB(117, 0, 0)
	local SLENDERMAN_HALLOWEEN_TIE_COLOR = Color3.fromRGB(170, 85, 0)

	local SLENDERMAN_NORMAL_HEAD_SIZE = Vector3.new(1.2727, 1.48785, 1.50725)
	local SLENDERMAN_NORMAL_HEAD_ORIGINAL_SIZE = Vector3.new(1.273, 1.488, 1.507)
	local SLENDERMAN_HALLOWEEN_HEAD_SCALE = 0.85

	local SLENDERMAN_NORMAL_TENTACLE_COLOR = Color3.fromRGB(0, 0, 0)
	local SLENDERMAN_NORMAL_TENTACLE_MATERIAL = Enum.Material.Plastic
	local SLENDERMAN_HALLOWEEN_TENTACLE_COLOR = Color3.fromRGB(170, 85, 0)
	local SLENDERMAN_HALLOWEEN_TENTACLE_TIP_COLOR = Color3.fromRGB(210, 115, 60)
	-- Segments numbered ABOVE this glow.
	local SLENDERMAN_LAST_DIM_SEGMENT = 11

	local function clearSlendermanHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, SLENDERMAN_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and child.Name == SLENDERMAN_PUMPKIN_NAME then
				child:Destroy()
			end
		end
	end

	local function setSlendermanTie(model: Model, color: Color3)
		local tie = model:FindFirstChild("Tie")
		if tie and tie:IsA("BasePart") then
			tie.Color = color
		else
			warn(SLENDERMAN_KILLER_NAME .. " transformation: Tie was not found in", model:GetFullName())
		end
	end

	local function setSlendermanHeadSize(model: Model, halloween: boolean)
		local head = model:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then
			warn(SLENDERMAN_KILLER_NAME .. " transformation: Head was not found in", model:GetFullName())
			return
		end

		local size = SLENDERMAN_NORMAL_HEAD_SIZE
		local originalSize = SLENDERMAN_NORMAL_HEAD_ORIGINAL_SIZE
		if halloween then
			size = size * SLENDERMAN_HALLOWEEN_HEAD_SCALE
			originalSize = originalSize * SLENDERMAN_HALLOWEEN_HEAD_SCALE
		end

		head.Size = size
		-- Keep OriginalSize in step with Head.Size so a later rescale does not undo the change.
		local originalSizeValue = head:FindFirstChild("OriginalSize")
		if originalSizeValue and originalSizeValue:IsA("Vector3Value") then
			originalSizeValue.Value = originalSize
		end
	end

	local function setSlendermanTentacles(model: Model, halloween: boolean)
		local tentacles = model:FindFirstChild("Tentacles")
		if not tentacles then
			warn(SLENDERMAN_KILLER_NAME .. " transformation: Tentacles was not found in", model:GetFullName())
			return
		end

		for _, tentacle in ipairs(tentacles:GetChildren()) do
			for _, segment in ipairs(tentacle:GetChildren()) do
				local index = tonumber(segment.Name)
				if index ~= nil and segment:IsA("BasePart") then
					if not halloween then
						segment.Color = SLENDERMAN_NORMAL_TENTACLE_COLOR
						segment.Material = SLENDERMAN_NORMAL_TENTACLE_MATERIAL
					elseif index > SLENDERMAN_LAST_DIM_SEGMENT then
						segment.Color = SLENDERMAN_HALLOWEEN_TENTACLE_TIP_COLOR
						segment.Material = Enum.Material.Neon
					else
						segment.Color = SLENDERMAN_HALLOWEEN_TENTACLE_COLOR
					end
				end
			end
		end
	end

	local function makeSlendermanPumpkin(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = SLENDERMAN_PUMPKIN_NAME
		accessory.AccessoryType = Enum.AccessoryType.Face
		accessory.AttachmentPoint = CFrame.new(0, 0.55, 0)

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=16973748"
		mesh.TextureId = "http://www.roblox.com/asset/?id=37752597"
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function applySlendermanHalloween(model: Model)
		clearSlendermanHalloweenAdditions(model)
		setSlendermanTie(model, SLENDERMAN_HALLOWEEN_TIE_COLOR)
		setSlendermanTentacles(model, true)

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Slenderman Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- EvilPumpkin was not added and the Head was left at its classic size")
			return
		end

		local pumpkin = makeSlendermanPumpkin()
		addMarkedHalloweenAccessory(model, zombie, pumpkin, SLENDERMAN_KILLER_NAME, LEGACY_ACCESSORY_ATTACHMENT)

		-- Only shrink the Head once the pumpkin is really on the rig; the shrink
		-- only makes sense underneath it.
		if pumpkin.Parent == model then
			setSlendermanHeadSize(model, true)
		end
	end

	local function restoreSlendermanNormal(model: Model)
		clearSlendermanHalloweenAdditions(model)
		setSlendermanTie(model, SLENDERMAN_NORMAL_TIE_COLOR)
		setSlendermanTentacles(model, false)
		setSlendermanHeadSize(model, false)
	end

	TRANSFORMATIONS[SLENDERMAN_KILLER_NAME] = {
		Halloween = {
			-- Body Colors are never touched (they are not uniform).
			applyCustom = applySlendermanHalloween,
		},
		Normal = {
			applyCustom = restoreSlendermanNormal,
		},
	}
end

do
	local SMILE_DOG_KILLER_NAME = "Smile Dog"
	local SMILE_DOG_BODY_PREFIX = "Body"
	local SMILE_DOG_BODY_COLOR = Color3.fromRGB(163, 162, 165)
	local SMILE_DOG_MESH_SCALE = Vector3.new(1.2, 1.2, 1.2)

	local SMILE_DOG_NORMAL_PART_TRANSPARENCY = 0
	local SMILE_DOG_HALLOWEEN_PART_TRANSPARENCY = 1

	-- { real part name, SpecialMesh.MeshId, SpecialMesh.TextureId }
	local SMILE_DOG_BODY_PARTS = {
		{ "UpperTorso", "http://www.roblox.com/asset/?id=542944468", "http://roblox.com/asset/?id=542954537" },
		{ "LowerTorso", "http://www.roblox.com/asset/?id=542944529", "http://roblox.com/asset/?id=542954537" },
		{ "LeftUpperArm", "http://www.roblox.com/asset/?id=542944437", "http://roblox.com/asset/?id=542953560" },
		{ "LeftLowerArm", "http://www.roblox.com/asset/?id=542944410", "http://roblox.com/asset/?id=542953560" },
		{ "LeftHand", "http://www.roblox.com/asset/?id=542944403", "http://roblox.com/asset/?id=542953560" },
		{ "RightUpperArm", "http://www.roblox.com/asset/?id=542944463", "http://roblox.com/asset/?id=542953560" },
		{ "RightLowerArm", "http://www.roblox.com/asset/?id=542944456", "http://roblox.com/asset/?id=542953560" },
		{ "RightHand", "http://www.roblox.com/asset/?id=542944450", "http://roblox.com/asset/?id=542953560" },
		{ "LeftUpperLeg", "http://www.roblox.com/asset/?id=542944491", "http://roblox.com/asset/?id=542954079" },
		{ "LeftLowerLeg", "http://www.roblox.com/asset/?id=542944486", "http://roblox.com/asset/?id=542954079" },
		{ "LeftFoot", "http://www.roblox.com/asset/?id=542944474", "http://roblox.com/asset/?id=542954079" },
		{ "RightUpperLeg", "http://www.roblox.com/asset/?id=542944520", "http://roblox.com/asset/?id=542954414" },
		{ "RightLowerLeg", "http://www.roblox.com/asset/?id=542944510", "http://roblox.com/asset/?id=542954414" },
		{ "RightFoot", "http://www.roblox.com/asset/?id=542944502", "http://roblox.com/asset/?id=542954414" },
	}

	-- The names the replacement Parts get, so cleanup can also sweep copies that
	-- carry no marker.
	local SMILE_DOG_REPLACEMENT_NAMES: { [string]: boolean } = {}
	for _, entry in ipairs(SMILE_DOG_BODY_PARTS) do
		SMILE_DOG_REPLACEMENT_NAMES[SMILE_DOG_BODY_PREFIX .. entry[1]] = true
	end

	local function clearSmileDogHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, SMILE_DOG_KILLER_NAME)

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("BasePart") and SMILE_DOG_REPLACEMENT_NAMES[child.Name] then
				child:Destroy()
			end
		end
	end

	local function addSmileDogReplacement(model: Model, realPart: BasePart, meshId: string, textureId: string)
		local replacement = makeHalloweenHandle(SMILE_DOG_BODY_PREFIX .. realPart.Name, Vector3.new(1, 1, 1), SMILE_DOG_BODY_COLOR)
		markHalloweenObjectForKiller(replacement, SMILE_DOG_KILLER_NAME)

		pcall(function()
			replacement.CollisionGroup = realPart.CollisionGroup
		end)

		replacement.CFrame = realPart.CFrame

		local mesh = Instance.new("SpecialMesh")
		mesh.Name = "Mesh"
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = meshId
		mesh.TextureId = textureId
		mesh.Scale = SMILE_DOG_MESH_SCALE
		mesh.Parent = replacement

		replacement.Parent = model

		local weld = Instance.new("Weld")
		weld.Name = "Weld"
		weld.Part0 = realPart
		weld.Part1 = replacement
		weld.C0 = CFrame.new()
		weld.C1 = CFrame.new()
		weld.Parent = replacement
	end

	local function applySmileDogHalloween(model: Model)
		clearSmileDogHalloweenAdditions(model)

		for _, entry in ipairs(SMILE_DOG_BODY_PARTS) do
			local part = model:FindFirstChild(entry[1])
			if part and part:IsA("BasePart") then
				addSmileDogReplacement(model, part, entry[2], entry[3])
				-- Only hide the real part once its replacement is really on the rig,
				-- so a limb is never left invisible without one.
				part.Transparency = SMILE_DOG_HALLOWEEN_PART_TRANSPARENCY
			else
				warn(SMILE_DOG_KILLER_NAME .. " Halloween transformation: missing part", entry[1], "in", model:GetFullName())
			end
		end
	end

	local function restoreSmileDogNormal(model: Model)
		clearSmileDogHalloweenAdditions(model)

		for _, entry in ipairs(SMILE_DOG_BODY_PARTS) do
			local part = model:FindFirstChild(entry[1])
			if part and part:IsA("BasePart") then
				part.Transparency = SMILE_DOG_NORMAL_PART_TRANSPARENCY
			else
				warn(SMILE_DOG_KILLER_NAME .. " Normal transformation: missing part", entry[1], "in", model:GetFullName())
			end
		end
	end

	TRANSFORMATIONS[SMILE_DOG_KILLER_NAME] = {
		Halloween = {
			-- Body Colors are never touched.
			applyCustom = applySmileDogHalloween,
		},
		Normal = {
			applyCustom = restoreSmileDogNormal,
		},
	}
end

do
	local SONIC_KILLER_NAME = "Sonic.exe"

	local C = {
		-- Classic colours.
		BLUE = Color3.fromRGB(0, 0, 255),
		SKIN = Color3.fromRGB(255, 204, 153),
		EYE_RED = Color3.fromRGB(255, 0, 0),
		GLOVE = Color3.fromRGB(242, 243, 243),
		SHOE = Color3.fromRGB(229, 228, 223),
		STRIPE_RED = Color3.fromRGB(196, 40, 28),
		STRIPE_GREY = Color3.fromRGB(99, 95, 98),
		STRIPE_YELLOW = Color3.fromRGB(245, 205, 48),
		STRIPE_WHITE = Color3.fromRGB(248, 248, 248),
		-- Used by both variants (Main Head, Mouth, Nose and the Halloween legs).
		BLACK = Color3.fromRGB(17, 17, 17),
		-- Halloween colours.
		PINK = Color3.fromRGB(255, 0, 191),
		NAVY = Color3.fromRGB(51, 55, 83),
		ICE = Color3.fromRGB(180, 210, 228),
		PURPLE = Color3.fromRGB(123, 0, 123),
	}

	-- { part name, classic colour, Halloween colour }, in rbxm order.
	local SONIC_PARTS = {
		["Chest"] = {
			{ "Main Torso", C.BLUE, C.NAVY },
			{ "Head", C.SKIN, C.ICE },
			{ "Tail", C.BLUE, C.NAVY },
		},
		["Head1"] = {
			{ "Eye1", C.EYE_RED, C.PINK },
			{ "Eye2", C.EYE_RED, C.PINK },
			{ "Eyebrow", C.BLUE, C.NAVY },
			{ "Eyebrow", C.BLUE, C.NAVY },
			{ "Mouth", C.BLACK, C.BLACK },
			{ "Nose", C.BLACK, C.BLACK },
			{ "Spine", C.BLUE, C.NAVY },
			{ "Spine", C.BLUE, C.NAVY },
			{ "Spine", C.BLUE, C.NAVY },
			{ "Spine", C.BLUE, C.NAVY },
			{ "Spine", C.BLUE, C.NAVY },
			{ "Spine", C.BLUE, C.NAVY },
			{ "Spine", C.BLUE, C.NAVY },
			{ "Spine", C.BLUE, C.NAVY },
			{ "Part", C.SKIN, C.ICE },
			{ "Part", C.SKIN, C.ICE },
			{ "Part", C.BLUE, C.NAVY },
			{ "Part", C.BLUE, C.NAVY },
			{ "Part", C.BLUE, C.NAVY },
			{ "Part", C.SKIN, C.ICE },
			{ "Main Head", C.BLACK, C.BLACK },
			{ "Part", C.SKIN, C.ICE },
		},
		["Left Arm1"] = {
			{ "Left Forearm", C.SKIN, C.NAVY },
			{ "Left Middle", C.SKIN, C.NAVY },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Left Hand", C.SHOE, C.SHOE },
		},
		["Right Arm1"] = {
			{ "Right Middle", C.SKIN, C.NAVY },
			{ "Right Forearm", C.SKIN, C.NAVY },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Parte", C.GLOVE, C.ICE },
			{ "Right Hand", C.SHOE, C.SHOE },
		},
		["Left Leg1"] = {
			{ "Left Thigh", C.BLUE, C.NAVY },
			{ "Left Tibia", C.BLUE, C.NAVY },
			{ "Parte", C.STRIPE_GREY, C.BLACK },
			{ "Parte", C.STRIPE_RED, C.PURPLE },
			{ "Parte", C.STRIPE_GREY, C.BLACK },
			{ "Parte", C.STRIPE_RED, C.PURPLE },
			{ "Parte", C.STRIPE_WHITE, C.BLACK },
			{ "Parte", C.STRIPE_YELLOW, C.BLACK },
			{ "Left Shoe", C.SHOE, C.BLACK },
		},
		["Right Leg1"] = {
			{ "Right Tibia", C.BLUE, C.NAVY },
			{ "Right Thigh", C.BLUE, C.NAVY },
			{ "Parte", C.STRIPE_GREY, C.BLACK },
			{ "Parte", C.STRIPE_RED, C.PURPLE },
			{ "Parte", C.STRIPE_RED, C.PURPLE },
			{ "Parte", C.STRIPE_GREY, C.BLACK },
			{ "Parte", C.STRIPE_YELLOW, C.BLACK },
			{ "Parte", C.STRIPE_WHITE, C.BLACK },
			{ "Right Shoe", C.SHOE, C.BLACK },
		},
	}

	-- Both Tooth Parts sit on Head1.Main Head; each entry is the weld's C0.
	local SONIC_TEETH = {
		CFrame.new(0.18, -0.51, -0.67) * CFrame.Angles(math.pi, 0, math.rad(-25)),
		CFrame.new(0.001, -0.545, -0.689) * CFrame.Angles(math.pi, 0, 0),
	}

	-- Each arm gets one large and one small Fur Part, welded to its Hand. The
	-- left hand is mirrored (flipped and offset downwards), the right is not.
	local SONIC_FUR_ARMS = {
		{
			arm = "Left Arm1",
			hand = "Left Hand",
			c0 = CFrame.new(0, -0.25, 0) * CFrame.Angles(0, 0, -math.pi),
		},
		{
			arm = "Right Arm1",
			hand = "Right Hand",
			c0 = CFrame.new(0, 0.25, 0),
		},
	}
	local SONIC_FUR_MESH_SCALES = {
		Vector3.new(0.4, 0.32, 0.4),
		Vector3.new(0.25, 0.25, 0.25),
	}

	local function clearSonicHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, SONIC_KILLER_NAME)

		local strayParts = {
			{ "Head1", "Tooth" },
			{ "Left Arm1", "Fur" },
			{ "Right Arm1", "Fur" },
		}
		for _, stray in ipairs(strayParts) do
			local container = model:FindFirstChild(stray[1])
			if container then
				for _, child in ipairs(container:GetChildren()) do
					if child.Name == stray[2] and child:IsA("BasePart") then
						child:Destroy()
					end
				end
			end
		end
	end

	-- Assigns the classic (halloween = false) or Halloween colour to every listed
	-- part. The k-th part with a given name takes the k-th row with that name.
	local function setSonicPartColors(model: Model, halloween: boolean)
		for containerName, rows in pairs(SONIC_PARTS) do
			local container = model:FindFirstChild(containerName)
			if not container then
				warn(SONIC_KILLER_NAME .. " transformation: missing", containerName, "in", model:GetFullName())
				continue
			end

			local rowsByName: { [string]: { any } } = {}
			for _, row in ipairs(rows) do
				local list = rowsByName[row[1]]
				if not list then
					list = {}
					rowsByName[row[1]] = list
				end
				table.insert(list, row)
			end

			local used: { [string]: number } = {}
			for _, child in ipairs(container:GetChildren()) do
				local list = child:IsA("BasePart") and rowsByName[child.Name]
				if list then
					local position = (used[child.Name] or 0) + 1
					local row = list[position]
					if row then
						used[child.Name] = position

						local part = child :: BasePart
						if halloween then
							part.Color = row[3]
						else
							part.Color = row[2]
						end
					end
				end
			end
		end
	end

	-- A white Part with a FileMesh: invisible to physics, queries and touches, and massless.
	local function makeSonicDecoration(name: string, size: number, meshId: string, meshScale: Vector3): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Color = C.STRIPE_WHITE
		part.Size = Vector3.new(size, size, size)
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		markHalloweenObjectForKiller(part, SONIC_KILLER_NAME)

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = meshId
		mesh.Scale = meshScale
		mesh.Parent = part

		return part
	end

	local function attachSonicDecoration(part: Part, parent: Instance, anchor: BasePart, c0: CFrame)
		local weld = Instance.new("Weld")
		weld.Part0 = anchor
		weld.Part1 = part
		weld.C0 = c0
		weld.Parent = part

		part.Parent = parent
	end

	local function addSonicTeeth(model: Model)
		local head = model:FindFirstChild("Head1")
		local mainHead = head and head:FindFirstChild("Main Head")
		if not head or not mainHead or not mainHead:IsA("BasePart") then
			warn(SONIC_KILLER_NAME .. " Halloween transformation: missing Head1.Main Head in", model:GetFullName(), "- Teeth were not added")
			return
		end

		for _, c0 in ipairs(SONIC_TEETH) do
			local tooth = makeSonicDecoration("Tooth", 0.1, "http://www.roblox.com/asset/?id=1778999", Vector3.new(0.1, 0.1, 0.1))
			attachSonicDecoration(tooth, head, mainHead, c0)
		end
	end

	local function addSonicFur(model: Model)
		for _, side in ipairs(SONIC_FUR_ARMS) do
			local arm = model:FindFirstChild(side.arm)
			local hand = arm and arm:FindFirstChild(side.hand)
			if not arm or not hand or not hand:IsA("BasePart") then
				warn(SONIC_KILLER_NAME .. " Halloween transformation: missing " .. side.arm .. "." .. side.hand .. " in", model:GetFullName(), "- Fur was not added")
				continue
			end

			for _, meshScale in ipairs(SONIC_FUR_MESH_SCALES) do
				local fur = makeSonicDecoration("Fur", 0.2, "http://www.roblox.com/asset/?id=128097430175161", meshScale)
				attachSonicDecoration(fur, arm, hand, side.c0)
			end
		end
	end

	local function applySonicHalloween(model: Model)
		clearSonicHalloweenAdditions(model)
		setSonicPartColors(model, true)
		addSonicTeeth(model)
		addSonicFur(model)
	end

	local function restoreSonicNormal(model: Model)
		clearSonicHalloweenAdditions(model)
		setSonicPartColors(model, false)
	end

	TRANSFORMATIONS[SONIC_KILLER_NAME] = {
		Halloween = {
			-- Body Colors are never touched; the visible rig is the six Part models.
			applyCustom = applySonicHalloween,
		},
		Normal = {
			applyCustom = restoreSonicNormal,
		},
	}
end

do
	local TAILS_DOLL_KILLER_NAME = "Tails Doll"

	local C = {
		-- Classic colours.
		ORANGE = Color3.fromRGB(255, 140, 0),
		WHITE = Color3.fromRGB(248, 248, 248),
		LUXO_GREY = Color3.fromRGB(216, 216, 216),
		GEM_RED = Color3.fromRGB(255, 0, 0),
		-- Used by both variants (the one black LuxoBall per arm is classic).
		BLACK = Color3.fromRGB(17, 17, 17),
		-- Halloween colours.
		DARK_RED = Color3.fromRGB(117, 0, 0),
		DARK_BLUE = Color3.fromRGB(27, 42, 53),
		CREAM = Color3.fromRGB(253, 234, 141),
		AMBER = Color3.fromRGB(170, 85, 0),
		NOSE_RED = Color3.fromRGB(255, 89, 89),
	}

	-- { part name, classic colour, Halloween colour }, in rbxm order. Parts that
	-- are not listed (the Torso1 unions, the new Halloween parts, anything added
	-- later) are left alone.
	local TAILS_DOLL_COLORED_PARTS = {
		["Left Arm1"] = {
			{ "2", C.WHITE, C.DARK_RED },
			{ "3", C.WHITE, C.DARK_RED },
			{ "LuxoBall", C.BLACK, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "Main Left Arm", C.ORANGE, C.DARK_RED },
		},
		["Right Arm1"] = {
			{ "2", C.WHITE, C.DARK_RED },
			{ "3", C.WHITE, C.DARK_RED },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "2", C.WHITE, C.DARK_RED },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.BLACK, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "Main Right Arm", C.ORANGE, C.DARK_RED },
		},
		["Torso1"] = {
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
			{ "LuxoBall", C.LUXO_GREY, C.BLACK },
		},
	}

	-- One part each. normal / halloween are property bags assigned verbatim.
	local TAILS_DOLL_SINGLE_PARTS = {
		{
			container = "Torso1",
			part = "Main Torso",
			normal = { Color = C.ORANGE, Material = Enum.Material.Concrete },
			halloween = { Color = C.DARK_RED, Material = Enum.Material.Leather },
		},
		{
			container = "Left Leg1",
			part = "Main Left Leg",
			normal = { Color = C.ORANGE, Material = Enum.Material.Concrete },
			halloween = { Color = C.DARK_BLUE, Material = Enum.Material.Grass },
		},
		{
			container = "Right Leg1",
			part = "Main Right Leg",
			normal = { Color = C.ORANGE, Material = Enum.Material.Concrete },
			halloween = { Color = C.DARK_BLUE, Material = Enum.Material.Grass },
		},
		{
			container = "Left Foot1",
			part = "Main Left Foot",
			normal = {
				Color = C.WHITE,
				Material = Enum.Material.Concrete,
				Size = Vector3.new(0.37247932, 0.18623966, 0.3259194),
			},
			halloween = {
				Color = C.BLACK,
				Material = Enum.Material.Plastic,
				Size = Vector3.new(0.37, 0.35, 0.33),
			},
		},
		{
			container = "Right Foot1",
			part = "Main Right Foot",
			normal = {
				Color = C.WHITE,
				Material = Enum.Material.Concrete,
				Size = Vector3.new(0.37247932, 0.18623966, 0.3259194),
			},
			halloween = {
				Color = C.BLACK,
				Material = Enum.Material.Plastic,
				Size = Vector3.new(0.37, 0.35, 0.33),
			},
		},
		{
			container = "Gem1",
			part = "GemBright",
			normal = { Color = C.GEM_RED },
			halloween = { Color = C.AMBER },
		},
	}

	-- Every child of these Models is hidden for Halloween except the part named
	-- "keep" (if any). The classic Transparency of all of them is 0.
	local TAILS_DOLL_HIDDEN_PARTS = {
		{ container = "Head1", keep = "20" },
		{ container = "Tail11" },
		{ container = "Tail21" },
		{ container = "Left Foot1", keep = "Main Left Foot" },
		{ container = "Right Foot1", keep = "Main Right Foot" },
	}

	-- Parts the Halloween variant adds, by the Model that holds them.
	local TAILS_DOLL_ADDED_PARTS = {
		Head1 = {
			"HeadVisual", "LeftEye", "RightEye", "CenterEye", "LeftPupil", "RightPupil",
			"CenterPupil", "Horns", "Nose", "Tooth",
		},
		Torso1 = { "Pants", "Wings" },
		Tail11 = { "Tail11" },
		Tail21 = { "Tail21" },
	}

	local TAILS_DOLL_JUMPSCARE_IMAGE_IDS = {
		Normal = 14689254045,
		Halloween = 81253230145946,
	}

	local function clearTailsDollHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, TAILS_DOLL_KILLER_NAME)

		for containerName, partNames in pairs(TAILS_DOLL_ADDED_PARTS) do
			local container = model:FindFirstChild(containerName)
			if container then
				local added: { [string]: boolean } = {}
				for _, partName in ipairs(partNames) do
					added[partName] = true
				end

				for _, child in ipairs(container:GetChildren()) do
					if added[child.Name] and child:IsA("BasePart") then
						child:Destroy()
					end
				end
			end
		end
	end

	local function setTailsDollPartColors(model: Model, halloween: boolean)
		for containerName, rows in pairs(TAILS_DOLL_COLORED_PARTS) do
			local container = model:FindFirstChild(containerName)
			if not container then
				warn(TAILS_DOLL_KILLER_NAME .. " transformation: missing", containerName, "in", model:GetFullName())
				continue
			end

			local rowsByName: { [string]: { any } } = {}
			for _, row in ipairs(rows) do
				local list = rowsByName[row[1]]
				if not list then
					list = {}
					rowsByName[row[1]] = list
				end
				table.insert(list, row)
			end

			local used: { [string]: number } = {}
			for _, child in ipairs(container:GetChildren()) do
				local list = child:IsA("BasePart") and rowsByName[child.Name]
				if list then
					local position = (used[child.Name] or 0) + 1
					local row = list[position]
					if row then
						used[child.Name] = position

						local part = child :: BasePart
						if halloween then
							part.Color = row[3]
						else
							part.Color = row[2]
						end
					end
				end
			end
		end
	end

	-- Everything that is a plain value change: transparencies, the single-part
	-- property bags, the gem and the jumpscare image.
	local function setTailsDollAppearance(model: Model, halloween: boolean)
		local transparency = 0
		if halloween then
			transparency = 1
		end

		for _, group in ipairs(TAILS_DOLL_HIDDEN_PARTS) do
			local container = model:FindFirstChild(group.container)
			if not container then
				warn(TAILS_DOLL_KILLER_NAME .. " transformation: missing", group.container, "in", model:GetFullName())
				continue
			end

			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("BasePart") and child.Name ~= group.keep then
					child.Transparency = transparency
				end
			end
		end

		setTailsDollPartColors(model, halloween)

		for _, entry in ipairs(TAILS_DOLL_SINGLE_PARTS) do
			local container = model:FindFirstChild(entry.container)
			local part = container and container:FindFirstChild(entry.part)
			if part and part:IsA("BasePart") then
				local properties = entry.normal
				if halloween then
					properties = entry.halloween
				end

				for property, value in pairs(properties) do
					(part :: any)[property] = value
				end
			else
				warn(TAILS_DOLL_KILLER_NAME .. " transformation: missing " .. entry.container .. "." .. entry.part .. " in", model:GetFullName())
			end
		end

		local jumpscare = model:FindFirstChild("JumpscareImageId")
		if jumpscare and jumpscare:IsA("IntValue") then
			if halloween then
				jumpscare.Value = TAILS_DOLL_JUMPSCARE_IMAGE_IDS.Halloween
			else
				jumpscare.Value = TAILS_DOLL_JUMPSCARE_IMAGE_IDS.Normal
			end
		else
			warn(TAILS_DOLL_KILLER_NAME .. " transformation: missing IntValue JumpscareImageId in", model:GetFullName())
		end
	end

	-- A Part that is invisible to physics, queries and touches, and massless. Colour and material
	-- are only set when given.
	local function newTailsDollPart(name: string, size: Vector3, material: Enum.Material?, color: Color3?): Part
		local part = Instance.new("Part")
		part.Name = name
		if color then
			part.Color = color
		end
		if material then
			part.Material = material
		end
		part.Size = size
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		markHalloweenObjectForKiller(part, TAILS_DOLL_KILLER_NAME)

		return part
	end

	local function addTailsDollMesh(part: Part, meshType: Enum.MeshType, scale: Vector3?, meshId: string?): SpecialMesh
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = meshType
		if meshId then
			mesh.MeshId = meshId
		end
		if scale then
			mesh.Scale = scale
		end
		mesh.Parent = part

		return mesh
	end

	local function attachTailsDollPart(part: Part, parent: Instance, anchor: BasePart, c0: CFrame?)
		local weld = Instance.new("Weld")
		weld.Part0 = anchor
		weld.Part1 = part
		if c0 then
			weld.C0 = c0
		end
		weld.Parent = part

		part.Parent = parent
	end

	local function addTailsDollHead(model: Model)
		local head = model:FindFirstChild("Head1")
		local mainHead = head and head:FindFirstChild("Main Head")
		if not head or not mainHead or not mainHead:IsA("BasePart") then
			warn(TAILS_DOLL_KILLER_NAME .. " Halloween transformation: missing Head1.Main Head in", model:GetFullName(), "- the Head was not added")
			return
		end

		-- The new head: a squashed sphere carrying the stitches, the eyes, the
		-- horns, the nose and the teeth, welded to the (now hidden) Main Head.
		local visual = newTailsDollPart("HeadVisual", Vector3.new(1, 1, 1), Enum.Material.Leather, C.DARK_RED)
		addTailsDollMesh(visual, Enum.MeshType.Sphere, Vector3.new(1.2, 1, 1.8))

		-- { face, rotation } of the eight stitch Decals.
		local stitches = {
			{ Enum.NormalId.Front, 0 },
			{ Enum.NormalId.Front, 90 },
			{ Enum.NormalId.Back, 0 },
			{ Enum.NormalId.Back, 90 },
			{ Enum.NormalId.Top, 0 },
			{ Enum.NormalId.Bottom, 0 },
			{ Enum.NormalId.Left, 90 },
			{ Enum.NormalId.Right, 90 },
		}
		for _, stitch in ipairs(stitches) do
			local decal = Instance.new("Decal")
			decal.Name = "Stitch"
			decal.Color3 = Color3.fromRGB(0, 0, 0)
			decal.Texture = "http://www.roblox.com/asset/?id=89578136646331"
			decal.Face = stitch[1]
			decal.Rotation = stitch[2]
			decal.Parent = visual
		end

		attachTailsDollPart(visual, head, mainHead, CFrame.new(0, -0.1, 0.2) * CFrame.Angles(math.rad(25), 0, 0))

		local function makeEye(name: string, c0: CFrame): Part
			local eye = newTailsDollPart(name, Vector3.new(0.4, 0.4, 0.4), Enum.Material.Plastic, C.CREAM)
			eye.BottomSurface = Enum.SurfaceType.Smooth
			eye.TopSurface = Enum.SurfaceType.Smooth
			addTailsDollMesh(eye, Enum.MeshType.Sphere, Vector3.new(0.8, 0.6, 1.6))
			attachTailsDollPart(eye, head, visual, c0)

			return eye
		end

		local function makePupil(name: string, eye: Part)
			local pupil = newTailsDollPart(name, Vector3.new(0.4, 0.4, 0.4), Enum.Material.Neon, C.AMBER)
			pupil.BottomSurface = Enum.SurfaceType.Smooth
			pupil.TopSurface = Enum.SurfaceType.Smooth
			addTailsDollMesh(pupil, Enum.MeshType.Sphere, Vector3.new(0.2, 0.7, 1.4))
			attachTailsDollPart(pupil, head, eye)
		end

		local leftEye = makeEye("LeftEye", CFrame.new(0.55, 0.05, 0) * CFrame.Angles(math.rad(-10), math.rad(3), math.rad(100)))
		local rightEye = makeEye("RightEye", CFrame.new(-0.55, 0.05, 0) * CFrame.Angles(math.rad(-10), math.rad(3), math.rad(-100)))
		local centerEye = makeEye("CenterEye", CFrame.new(0, 0.45, 0.1))
		makePupil("LeftPupil", leftEye)
		makePupil("RightPupil", rightEye)
		makePupil("CenterPupil", centerEye)

		local horns = newTailsDollPart("Horns", Vector3.new(1, 1, 1), Enum.Material.Slate, C.CREAM)
		addTailsDollMesh(horns, Enum.MeshType.FileMesh, Vector3.new(0.7, 0.7, 0.65), "http://www.roblox.com/asset/?id=1014494561")
		attachTailsDollPart(horns, head, visual, CFrame.new(0, 0.25, -0.75) * CFrame.Angles(math.rad(-55), 0, 0))

		local nose = newTailsDollPart("Nose", Vector3.new(0.2, 0.2, 0.2), Enum.Material.Leather, C.NOSE_RED)
		addTailsDollMesh(nose, Enum.MeshType.FileMesh, Vector3.new(0.85, 1.1, 0.85), "http://www.roblox.com/asset/?id=124627720323433")
		attachTailsDollPart(nose, head, visual, CFrame.new(0, 0.15, 0.8) * CFrame.fromEulerAnglesYXZ(math.rad(30), math.pi, 0))

		-- The weld C0 of each of the five teeth, left to right.
		local teeth = {
			CFrame.new(0.25, -0.3, 0.65) * CFrame.fromEulerAnglesYXZ(math.rad(135), math.rad(45), 0),
			CFrame.new(0.16, -0.28, 0.79) * CFrame.fromEulerAnglesYXZ(math.rad(135), math.rad(20), 0),
			CFrame.new(0, -0.28, 0.87) * CFrame.Angles(math.rad(135), 0, 0),
			CFrame.new(-0.16, -0.28, 0.79) * CFrame.fromEulerAnglesYXZ(math.rad(135), math.rad(-20), 0),
			CFrame.new(-0.25, -0.3, 0.65) * CFrame.fromEulerAnglesYXZ(math.rad(135), math.rad(-45), 0),
		}
		for _, c0 in ipairs(teeth) do
			local tooth = newTailsDollPart("Tooth", Vector3.new(0.2, 0.2, 0.2), Enum.Material.Concrete, C.CREAM)
			addTailsDollMesh(tooth, Enum.MeshType.FileMesh, Vector3.new(0.15, 0.15, 0.15), "http://www.roblox.com/asset/?id=1778999")
			attachTailsDollPart(tooth, head, visual, c0)
		end
	end

	local function addTailsDollBody(model: Model)
		local torso = model:FindFirstChild("Torso1")
		local mainTorso = torso and torso:FindFirstChild("Main Torso")
		if not torso or not mainTorso or not mainTorso:IsA("BasePart") then
			warn(TAILS_DOLL_KILLER_NAME .. " Halloween transformation: missing Torso1.Main Torso in", model:GetFullName(), "- Pants and Wings were not added")
			return
		end

		local pants = newTailsDollPart("Pants", Vector3.new(0.8, 0.4, 0.5), Enum.Material.Grass, C.DARK_BLUE)
		addTailsDollMesh(pants, Enum.MeshType.Sphere)
		attachTailsDollPart(pants, torso, mainTorso, CFrame.new(0, -0.375, 0))

		-- Default colour and material: the texture does the colouring.
		local wings = newTailsDollPart("Wings", Vector3.new(1, 1, 1))
		local wingsMesh = addTailsDollMesh(wings, Enum.MeshType.FileMesh, Vector3.new(0.3, 0.35, 0.3), "http://www.roblox.com/asset/?id=302248517")
		wingsMesh.Offset = Vector3.new(0, 0, 0.5)
		wingsMesh.TextureId = "http://www.roblox.com/asset/?id=302244943"
		attachTailsDollPart(wings, torso, mainTorso, CFrame.new(0, 0.325, -0.4) * CFrame.Angles(0, math.pi, 0))
	end

	local function addTailsDollTails(model: Model)
		local tails = {
			{
				container = "Tail11",
				main = "Main Tail1",
				c0 = CFrame.new(0, -0.3, -0.1) * CFrame.fromEulerAnglesYXZ(math.rad(50), math.rad(-50), 0),
			},
			{
				container = "Tail21",
				main = "Main Tail2",
				c0 = CFrame.new(0.05, -0.3, 0.05) * CFrame.fromEulerAnglesYXZ(math.rad(40), math.rad(-30), math.rad(20)),
			},
		}

		for _, tail in ipairs(tails) do
			local container = model:FindFirstChild(tail.container)
			local main = container and container:FindFirstChild(tail.main)
			if not container or not main or not main:IsA("BasePart") then
				warn(TAILS_DOLL_KILLER_NAME .. " Halloween transformation: missing " .. tail.container .. "." .. tail.main .. " in", model:GetFullName(), "- the tail was not added")
				continue
			end

			-- Named like its Model.
			local part = newTailsDollPart(tail.container, Vector3.new(0.5, 0.5, 0.5), Enum.Material.Leather, C.DARK_RED)
			addTailsDollMesh(part, Enum.MeshType.FileMesh, Vector3.new(0.7, 0.5, 0.7), "http://www.roblox.com/asset/?id=1117714002")
			attachTailsDollPart(part, container, main, tail.c0)
		end
	end

	local function applyTailsDollHalloween(model: Model)
		-- Safe to call repeatedly: clear first so nothing stacks, hide the classic
		-- parts, and only then add the new ones (which stay visible).
		clearTailsDollHalloweenAdditions(model)
		setTailsDollAppearance(model, true)
		addTailsDollHead(model)
		addTailsDollBody(model)
		addTailsDollTails(model)
	end

	local function restoreTailsDollNormal(model: Model)
		clearTailsDollHalloweenAdditions(model)
		setTailsDollAppearance(model, false)
	end

	TRANSFORMATIONS[TAILS_DOLL_KILLER_NAME] = {
		Halloween = {
			-- Body Colors are never touched; the visible rig is the eleven Models.
			applyCustom = applyTailsDollHalloween,
		},
		Normal = {
			applyCustom = restoreTailsDollNormal,
		},
	}
end

do
	local WENDIGO_KILLER_NAME = "Wendigo"

	local WENDIGO_LOOK = {
		normalBodyColor = Color3.fromRGB(86, 66, 54),
		halloweenBodyColors = {
			HeadColor3 = Color3.fromRGB(17, 17, 17),
			TorsoColor3 = Color3.fromRGB(17, 17, 17),
			LeftArmColor3 = Color3.fromRGB(40, 20, 0),
			RightArmColor3 = Color3.fromRGB(40, 20, 0),
			LeftLegColor3 = Color3.fromRGB(40, 20, 0),
			RightLegColor3 = Color3.fromRGB(40, 20, 0),
		},
		maskTextureId = "http://www.roblox.com/asset/?id=14109215",
		eyeColor = Color3.fromRGB(248, 217, 109),
		cloakColor = Color3.fromRGB(51, 71, 55),
	}

	-- { part name, SurfaceAppearance.ColorMap, SurfaceAppearance.TexturePack }
	local WENDIGO_SURFACE_APPEARANCES = {
		{ "UpperTorso", "rbxassetid://547769491", "rbxassetid://130975823985314" },
		{ "LowerTorso", "rbxassetid://547769491", "rbxassetid://130975823985314" },
		{ "RightUpperArm", "rbxassetid://547769294", "rbxassetid://139326657477823" },
		{ "RightLowerArm", "rbxassetid://547769294", "rbxassetid://139326657477823" },
		{ "RightHand", "rbxassetid://547769294", "rbxassetid://139326657477823" },
		{ "LeftUpperArm", "rbxassetid://547769082", "rbxassetid://104057273967273" },
		{ "LeftLowerArm", "rbxassetid://547769082", "rbxassetid://104057273967273" },
		{ "LeftHand", "rbxassetid://547769082", "rbxassetid://104057273967273" },
		{ "LeftUpperLeg", "rbxassetid://547769185", "rbxassetid://79934382450700" },
		{ "LeftLowerLeg", "rbxassetid://547769185", "rbxassetid://79934382450700" },
		{ "LeftFoot", "rbxassetid://547769185", "rbxassetid://79934382450700" },
		{ "RightUpperLeg", "rbxassetid://547769390", "rbxassetid://130581152016593" },
		{ "RightLowerLeg", "rbxassetid://547769390", "rbxassetid://130581152016593" },
		{ "RightFoot", "rbxassetid://547769390", "rbxassetid://130581152016593" },
	}

	-- The classic accessories the Halloween variant removes (hidden here, because
	-- their MeshPart Handles cannot be rebuilt).
	local WENDIGO_HIDDEN_ACCESSORIES = { "Dr. Smyth Hair", "LongBeard", "Skeleton" }

	-- Each Halloween accessory as data; see buildWendigoAccessory for the fields.
	-- "legacy" means the Handle owns no Attachment and relies on AttachmentPoint.
	local WENDIGO_ACCESSORIES = {
		{
			name = "Cloak",
			accessoryType = Enum.AccessoryType.Neck,
			attachmentPoint = CFrame.new(0, 1.3, 0),
			legacy = true,
			size = Vector3.new(1, 1, 1),
			color = WENDIGO_LOOK.cloakColor,
			material = Enum.Material.Rubber,
			meshId = "http://www.roblox.com/asset/?id=221290649",
			meshScale = Vector3.new(1.85, 1.85, 1.85),
		},
		{
			name = "CenterPoncho",
			accessoryType = Enum.AccessoryType.Back,
			size = Vector3.new(1, 1, 1),
			color = WENDIGO_LOOK.cloakColor,
			material = Enum.Material.Rubber,
			meshId = "http://www.roblox.com/asset/?id=4248979925",
			meshScale = Vector3.new(1.2, 2, 0.6),
			attachmentName = "BodyBackAttachment",
			attachmentCFrame = CFrame.new(0, -0.2, 0.3),
		},
		{
			name = "LeftPoncho",
			accessoryType = Enum.AccessoryType.Shoulder,
			size = Vector3.new(1, 1, 1),
			color = WENDIGO_LOOK.cloakColor,
			material = Enum.Material.Rubber,
			meshId = "http://www.roblox.com/asset/?id=4248979925",
			meshScale = Vector3.new(0.6, 1.2, 0.6),
			attachmentName = "LeftShoulderRigAttachment",
			attachmentCFrame = CFrame.new(0.05, 0.55, 0.2) * CFrame.Angles(0, -math.pi / 2, 0),
		},
		{
			name = "RightPoncho",
			accessoryType = Enum.AccessoryType.Shoulder,
			size = Vector3.new(1, 1, 1),
			color = WENDIGO_LOOK.cloakColor,
			material = Enum.Material.Rubber,
			meshId = "http://www.roblox.com/asset/?id=4248979925",
			meshScale = Vector3.new(0.6, 1.2, 0.6),
			attachmentName = "RightShoulderRigAttachment",
			attachmentCFrame = CFrame.new(-0.05, 0.55, 0.2) * CFrame.Angles(0, math.pi / 2, 0),
		},
		{
			name = "ShoulderCloak",
			accessoryType = Enum.AccessoryType.Neck,
			size = Vector3.new(1, 1, 1),
			color = WENDIGO_LOOK.cloakColor,
			material = Enum.Material.Rubber,
			meshId = "http://www.roblox.com/asset/?id=19380188",
			meshScale = Vector3.new(2.2, 0.6, 1),
			attachmentName = CHUCKY_CLOAK_ATTACHMENT,
			attachmentCFrame = CFrame.new(0, -1, -0.35),
		},
		{
			name = "Belt",
			accessoryType = Enum.AccessoryType.Waist,
			size = Vector3.new(1.4, 0.2, 0.8),
			color = Color3.fromRGB(86, 66, 54),
			material = Enum.Material.Leather,
			meshId = "http://www.roblox.com/asset/?id=103919751",
			meshScale = Vector3.new(1.8, 0.15, 1.05),
			attachmentName = "WaistRigAttachment",
			attachmentCFrame = CFrame.new(0, 0.4, -0.01),
			hasBuckle = true,
		},
		{
			name = "LeftAxe",
			accessoryType = Enum.AccessoryType.Waist,
			size = Vector3.new(1, 1, 1),
			meshId = "http://www.roblox.com/asset/?id=317537875",
			meshTextureId = "http://www.roblox.com/asset/?id=94574880020948",
			meshScale = Vector3.new(1, 1, 1),
			attachmentName = "WaistRigAttachment",
			attachmentCFrame = CFrame.new(0.75, -0.63, 0) * CFrame.Angles(3.9269908169872414, 0, 0),
		},
		{
			name = "RightAxe",
			accessoryType = Enum.AccessoryType.Waist,
			size = Vector3.new(1, 1, 1),
			meshId = "http://www.roblox.com/asset/?id=317537875",
			meshTextureId = "http://www.roblox.com/asset/?id=94574880020948",
			meshScale = Vector3.new(1, 1, 1),
			attachmentName = "WaistRigAttachment",
			attachmentCFrame = CFrame.new(-0.75, -0.63, 0) * CFrame.Angles(3.9269908169872414, 0, 0),
		},
		{
			name = "Guitar",
			accessoryType = Enum.AccessoryType.Back,
			size = Vector3.new(1, 1, 1),
			meshId = "http://www.roblox.com/asset/?id=26639749",
			meshTextureId = "http://www.roblox.com/asset/?id=85001384190755",
			meshScale = Vector3.new(0.8, 0.8, 0.95),
			attachmentName = "BodyBackAttachment",
			attachmentCFrame = CFrame.new(0.1, -0.35, -0.6) * CFrame.fromEulerAnglesYXZ(-math.pi / 2, 2.6179938779914944, 0),
		},
	}

	local function clearWendigoHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, WENDIGO_KILLER_NAME)

		local accessoryNames = {}
		for _, spec in ipairs(WENDIGO_ACCESSORIES) do
			accessoryNames[spec.name] = true
		end

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and accessoryNames[child.Name] then
				child:Destroy()
			elseif child:IsA("BasePart") and (child.Name == "LeftEye" or child.Name == "RightEye") then
				child:Destroy()
			end
		end

		local mask = model:FindFirstChild("Mask")
		local maskHandle = mask and mask:FindFirstChild("Handle")
		if maskHandle then
			for _, child in ipairs(maskHandle:GetChildren()) do
				if child:IsA("Texture") and child.Texture == WENDIGO_LOOK.maskTextureId then
					child:Destroy()
				end
			end
		end
	end

	local function setWendigoClassicAccessoriesVisible(model: Model, visible: boolean)
		local transparency = if visible then 0 else 1
		for _, accessoryName in ipairs(WENDIGO_HIDDEN_ACCESSORIES) do
			local accessory = model:FindFirstChild(accessoryName)
			if accessory and accessory:IsA("Accessory") then
				for _, descendant in ipairs(accessory:GetDescendants()) do
					if descendant:IsA("BasePart") then
						descendant.Transparency = transparency
					end
				end
			elseif visible then
				warn("Wendigo transformation: the classic", accessoryName, "is missing from", model:GetFullName(), "and cannot be rebuilt (MeshPart.MeshId is not scriptable)")
			end
		end
	end

	local function restoreWendigoSurfaceAppearances(model: Model)
		for _, entry in ipairs(WENDIGO_SURFACE_APPEARANCES) do
			local part = model:FindFirstChild(entry[1])
			if part and part:IsA("MeshPart") then
				local existingSurfaceAppearance: SurfaceAppearance? = nil
				for _, child in ipairs(part:GetChildren()) do
					if child:IsA("SurfaceAppearance") then
						if existingSurfaceAppearance == nil then
							existingSurfaceAppearance = child
						else
							child:Destroy()
						end
					end
				end

				local surfaceAppearance = existingSurfaceAppearance or Instance.new("SurfaceAppearance")
				if existingSurfaceAppearance == nil then
					surfaceAppearance.Parent = part
				end

				surfaceAppearance.ColorMap = entry[2]
				surfaceAppearance.TexturePack = entry[3]
				surfaceAppearance.Color = Color3.fromRGB(255, 255, 255)
			else
				warn("Wendigo Normal transformation: missing MeshPart", entry[1], "in", model:GetFullName())
			end
		end
	end

	-- Six Textures, one per face of the mask's Handle.
	local function addWendigoMaskTextures(model: Model)
		local mask = model:FindFirstChild("Mask")
		local handle = mask and mask:FindFirstChild("Handle")
		if not handle or not handle:IsA("BasePart") then
			warn("Wendigo Halloween transformation: Mask.Handle was not found in", model:GetFullName(), "- the mask textures were not added")
			return
		end

		for _, face in ipairs({
			Enum.NormalId.Front,
			Enum.NormalId.Back,
			Enum.NormalId.Top,
			Enum.NormalId.Bottom,
			Enum.NormalId.Left,
			Enum.NormalId.Right,
		}) do
			local texture = Instance.new("Texture")
			texture.Color3 = Color3.fromRGB(223, 123, 0)
			texture.Texture = WENDIGO_LOOK.maskTextureId
			texture.OffsetStudsU = 1
			texture.StudsPerTileU = 2
			texture.StudsPerTileV = 2
			texture.Transparency = 0.3
			texture.Face = face
			markHalloweenObjectForKiller(texture, WENDIGO_KILLER_NAME)
			texture.Parent = handle
		end
	end

	-- Two tiny glowing balls welded to the Head. Each is moved onto its final spot
	-- first so it never flashes at the origin.
	local function addWendigoEyes(model: Model, head: BasePart)
		for _, eye in ipairs({
			{ "LeftEye", CFrame.new(-0.38, 0.08, -0.33) },
			{ "RightEye", CFrame.new(0.38, 0.08, -0.33) },
		}) do
			local part = makeHalloweenHandle(eye[1], Vector3.new(0.05, 0.05, 0.05), WENDIGO_LOOK.eyeColor)
			part.Material = Enum.Material.Neon
			part.Shape = Enum.PartType.Ball
			markHalloweenObjectForKiller(part, WENDIGO_KILLER_NAME)
			part.CFrame = head.CFrame * eye[2]
			part.Parent = model

			local weld = Instance.new("Weld")
			weld.Part0 = head
			weld.Part1 = part
			weld.C0 = eye[2]
			weld.Parent = part
		end
	end

	-- Builds one accessory from its data entry. A "legacy" entry gets the shared
	-- legacy-placement attachment; every other one carries the attachment named in
	-- the entry, which pairs with the rig's attachment of the same name. The Belt's
	-- Buckle is a second Part inside the accessory, welded to the Handle.
	local function buildWendigoAccessory(spec: any): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = spec.name
		accessory.AccessoryType = spec.accessoryType
		if spec.attachmentPoint then
			accessory.AttachmentPoint = spec.attachmentPoint
		end

		local handle = makeHalloweenHandle("Handle", spec.size, spec.color)
		if spec.material then
			handle.Material = spec.material
		end
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = spec.meshId
		if spec.meshTextureId then
			mesh.TextureId = spec.meshTextureId
		end
		mesh.Scale = spec.meshScale
		mesh.Parent = handle

		if spec.legacy then
			addLegacyAccessoryAttachment(accessory, handle)
		else
			local attachment = Instance.new("Attachment")
			attachment.Name = spec.attachmentName
			attachment.CFrame = spec.attachmentCFrame
			attachment.Parent = handle
		end

		if spec.hasBuckle then
			local buckle = makeHalloweenHandle("Buckle", Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(188, 155, 93))
			buckle.Material = Enum.Material.Salt
			buckle.Parent = accessory

			local buckleMesh = Instance.new("SpecialMesh")
			buckleMesh.MeshType = Enum.MeshType.FileMesh
			buckleMesh.MeshId = "http://www.roblox.com/asset/?id=54926917"
			buckleMesh.Scale = Vector3.new(0.2, 0.2, 0.1)
			buckleMesh.Parent = buckle

			local weld = Instance.new("Weld")
			weld.Part0 = handle
			weld.Part1 = buckle
			weld.C0 = CFrame.new(0, 0, -0.4)
			weld.Parent = buckle
		end

		return accessory
	end

	local function applyWendigoHalloween(model: Model)
		clearWendigoHalloweenAdditions(model)
		setWendigoClassicAccessoriesVisible(model, false)

		for _, entry in ipairs(WENDIGO_SURFACE_APPEARANCES) do
			removeSurfaceAppearances(model:FindFirstChild(entry[1]))
		end

		addWendigoMaskTextures(model)

		local head = model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			addWendigoEyes(model, head)
		else
			warn("Wendigo Halloween transformation: Head was not found in", model:GetFullName(), "- the eyes were not added")
		end

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn("Wendigo Halloween transformation: missing Humanoid 'Zombie' in", model:GetFullName(), "- the cloak, ponchos, belt, axes and guitar were not added")
			return
		end

		for _, spec in ipairs(WENDIGO_ACCESSORIES) do
			addMarkedHalloweenAccessory(
				model,
				zombie,
				buildWendigoAccessory(spec),
				WENDIGO_KILLER_NAME,
				if spec.legacy then LEGACY_ACCESSORY_ATTACHMENT else spec.attachmentName
			)
		end
	end

	local function restoreWendigoNormal(model: Model)
		clearWendigoHalloweenAdditions(model)
		setWendigoClassicAccessoriesVisible(model, true)
		restoreWendigoSurfaceAppearances(model)
	end

	TRANSFORMATIONS[WENDIGO_KILLER_NAME] = {
		Halloween = {
			bodyColors = WENDIGO_LOOK.halloweenBodyColors,
			applyCustom = applyWendigoHalloween,
		},
		Normal = {
			bodyColor = WENDIGO_LOOK.normalBodyColor,
			applyCustom = restoreWendigoNormal,
		},
	}
end

do
	local YETI_KILLER_NAME = "Yeti"

	local YETI_LOOK = {
		headAccessoryName = "YetiHead",
		bodyColorsName = "Body Colors",
		trunkName = "Trunk",
		monsterHeadName = "MonsterHead",
		zeusBeardName = "Zeus Beard",
		yetiBeardName = "Yeti Beard",

		-- Classic: Body Colors, and the colour / material of the fourteen parts.
		normalHeadColor = Color3.fromRGB(17, 17, 17),
		normalBodyColor = Color3.fromRGB(0, 0, 0),
		normalMaterial = Enum.Material.Plastic,

		-- Halloween: the fourteen parts.
		limbColor = Color3.fromRGB(108, 88, 75),
		limbMaterial = Enum.Material.Slate,
		extremityColor = Color3.fromRGB(157, 168, 163),
		extremityMaterial = Enum.Material.Sand,

		-- Halloween: the new head and the beards.
		eyeColor = Color3.fromRGB(164, 189, 71),
		furTextureId = "http://www.roblox.com/asset/?id=2887714",
	}

	-- { part name, SurfaceAppearance.ColorMap, SurfaceAppearance.TexturePack,
	--   true if the part is a hand or a foot }
	local YETI_BODY_PARTS = {
		{ "UpperTorso", "rbxassetid://548797084", "rbxassetid://92768158423732", false },
		{ "LowerTorso", "rbxassetid://548797084", "rbxassetid://92768158423732", false },
		{ "LeftUpperArm", "rbxassetid://548796809", "rbxassetid://96396171597480", false },
		{ "LeftLowerArm", "rbxassetid://548796809", "rbxassetid://96396171597480", false },
		{ "LeftHand", "rbxassetid://548796809", "rbxassetid://96396171597480", true },
		{ "RightUpperArm", "rbxassetid://548796964", "rbxassetid://79724538645005", false },
		{ "RightLowerArm", "rbxassetid://548796964", "rbxassetid://79724538645005", false },
		{ "RightHand", "rbxassetid://548796964", "rbxassetid://79724538645005", true },
		{ "LeftUpperLeg", "rbxassetid://548796872", "rbxassetid://134797596005632", false },
		{ "LeftLowerLeg", "rbxassetid://548796872", "rbxassetid://134797596005632", false },
		{ "LeftFoot", "rbxassetid://548796872", "rbxassetid://134797596005632", true },
		{ "RightUpperLeg", "rbxassetid://548797029", "rbxassetid://76158800381262", false },
		{ "RightLowerLeg", "rbxassetid://548797029", "rbxassetid://76158800381262", false },
		{ "RightFoot", "rbxassetid://548797029", "rbxassetid://76158800381262", true },
	}

	local YETI_CLUB_LOOK = {
		Normal = {
			grip = CFrame.new(-1.6, 0, 0.4) * CFrame.Angles(0, 0, -math.pi / 2),
			meshScale = Vector3.new(4, 3.2, 3.2),
			hitSoundSpeed = 1,
		},
		Halloween = {
			grip = CFrame.new(-1.6, -0.2, 0.3) * CFrame.Angles(0, 0, -math.pi / 2),
			meshScale = Vector3.new(0, 0, 0),
			hitSoundSpeed = 2,
		},
	}

	local function clearYetiHalloweenAdditions(model: Model)
		clearHalloweenObjectsForKiller(model, YETI_KILLER_NAME)

		local accessoryNames = {
			[YETI_LOOK.monsterHeadName] = true,
			[YETI_LOOK.zeusBeardName] = true,
			[YETI_LOOK.yetiBeardName] = true,
		}
		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") and accessoryNames[child.Name] then
				child:Destroy()
			end
		end

		local club = model:FindFirstChild("Club")
		if club then
			for _, child in ipairs(club:GetChildren()) do
				if child:IsA("BasePart") and child.Name == YETI_LOOK.trunkName then
					child:Destroy()
				end
			end
		end
	end

	-- Halloween deletes the BodyColors instance outright.
	local function removeYetiBodyColors(model: Model)
		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("BodyColors") then
				child:Destroy()
			end
		end
	end

	local function restoreYetiBodyColors(model: Model)
		local existingBodyColors: BodyColors? = nil
		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("BodyColors") then
				if existingBodyColors == nil then
					existingBodyColors = child
				else
					child:Destroy()
				end
			end
		end

		local bodyColors = existingBodyColors or Instance.new("BodyColors")
		if existingBodyColors == nil then
			bodyColors.Name = YETI_LOOK.bodyColorsName
			bodyColors.Parent = model
		end

		setBodyColor(bodyColors, YETI_LOOK.normalBodyColor)
		bodyColors.HeadColor3 = YETI_LOOK.normalHeadColor
	end

	local function restoreYetiSurfaceAppearance(part: MeshPart, colorMap: string, texturePack: string)
		local existingSurfaceAppearance: SurfaceAppearance? = nil
		for _, child in ipairs(part:GetChildren()) do
			if child:IsA("SurfaceAppearance") then
				if existingSurfaceAppearance == nil then
					existingSurfaceAppearance = child
				else
					child:Destroy()
				end
			end
		end

		local surfaceAppearance = existingSurfaceAppearance or Instance.new("SurfaceAppearance")
		if existingSurfaceAppearance == nil then
			surfaceAppearance.Parent = part
		end

		surfaceAppearance.ColorMap = colorMap
		surfaceAppearance.TexturePack = texturePack
		surfaceAppearance.Color = Color3.fromRGB(255, 255, 255)
	end

	-- Halloween: delete the SurfaceAppearances and paint the part.
	-- Normal: put the classic colour, material and SurfaceAppearance back.
	local function setYetiBodyParts(model: Model, halloween: boolean)
		for _, entry in ipairs(YETI_BODY_PARTS) do
			local part = model:FindFirstChild(entry[1])
			if part and part:IsA("MeshPart") then
				if halloween then
					removeSurfaceAppearances(part)
					if entry[4] then
						part.Color = YETI_LOOK.extremityColor
						part.Material = YETI_LOOK.extremityMaterial
					else
						part.Color = YETI_LOOK.limbColor
						part.Material = YETI_LOOK.limbMaterial
					end
				else
					part.Color = YETI_LOOK.normalBodyColor
					part.Material = YETI_LOOK.normalMaterial
					restoreYetiSurfaceAppearance(part, entry[2], entry[3])
				end
			else
				warn(YETI_KILLER_NAME .. " transformation: missing MeshPart", entry[1], "in", model:GetFullName())
			end
		end
	end

	local function syncYetiClubGrip(model: Model, club: Tool, handle: BasePart, grip: CFrame)
		club.Grip = grip

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("JointInstance") and descendant.Name == "RightGrip" then
				if descendant.Part1 == handle then
					descendant.C1 = grip
				elseif descendant.Part0 == handle then
					descendant.C0 = grip
				end
			end
		end
	end

	-- The Halloween club: a tree trunk welded to the (now invisible) Handle.
	local function addYetiTrunk(club: Tool, handle: BasePart)
		local trunk = makeHalloweenHandle(YETI_LOOK.trunkName, Vector3.new(0.2, 0.2, 0.2))
		markHalloweenObjectForKiller(trunk, YETI_KILLER_NAME)

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "http://www.roblox.com/asset/?id=181585686"
		mesh.TextureId = YETI_LOOK.furTextureId
		mesh.Scale = Vector3.new(1.6, 10, 1.6)
		mesh.Offset = Vector3.new(0, 0, 0.1)
		mesh.Parent = trunk

		local c0 = CFrame.new(0.5, 0, 0) * CFrame.Angles(0, 0, -math.pi / 2)
		trunk.CFrame = handle.CFrame * c0

		local weld = Instance.new("Weld")
		weld.Part0 = handle
		weld.Part1 = trunk
		weld.C0 = c0
		weld.Parent = trunk

		trunk.Parent = club
	end

	-- Club.Grip, Club.Handle.Mesh.Scale and Club.Handle.HitSound.PlaybackSpeed in
	-- the given look, plus the Trunk for Halloween (Normal has none; it was cleared
	-- by the caller).
	local function setYetiClub(model: Model, halloween: boolean)
		local look = YETI_CLUB_LOOK.Normal
		if halloween then
			look = YETI_CLUB_LOOK.Halloween
		end

		local club = model:FindFirstChild("Club")
		local handle = club and club:FindFirstChild("Handle")
		if not club or not club:IsA("Tool") or not handle or not handle:IsA("BasePart") then
			warn(YETI_KILLER_NAME .. " transformation: Club.Handle was not found in", model:GetFullName())
			return
		end

		syncYetiClubGrip(model, club, handle, look.grip)

		local mesh = handle:FindFirstChild("Mesh")
		if mesh and mesh:IsA("SpecialMesh") then
			mesh.Scale = look.meshScale
		else
			warn(YETI_KILLER_NAME .. " transformation: Club.Handle.Mesh was not found in", model:GetFullName())
		end

		local hitSound = handle:FindFirstChild("HitSound")
		if hitSound and hitSound:IsA("Sound") then
			hitSound.PlaybackSpeed = look.hitSoundSpeed
		else
			warn(YETI_KILLER_NAME .. " transformation: Club.Handle.HitSound was not found in", model:GetFullName())
		end

		if halloween then
			addYetiTrunk(club, handle)
		end
	end

	local function setYetiHeadVisible(model: Model, visible: boolean)
		local yetiHead = model:FindFirstChild(YETI_LOOK.headAccessoryName)
		if not yetiHead or not yetiHead:IsA("Accessory") then
			if visible then
				warn(
					YETI_KILLER_NAME .. " transformation: the classic",
					YETI_LOOK.headAccessoryName,
					"is missing from",
					model:GetFullName(),
					"and cannot be rebuilt (MeshPart.MeshId is not scriptable)"
				)
			end
			return
		end

		local transparency = 0
		if not visible then
			transparency = 1
		end
		for _, descendant in ipairs(yetiHead:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = transparency
			end
		end
	end

	-- The new head: a Head-mesh skull (the Handle), a "HeadBottom" jaw and two Neon
	-- eyes, every extra Part welded to the Handle.
	local function makeYetiMonsterHead(): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = YETI_LOOK.monsterHeadName
		accessory.AccessoryType = Enum.AccessoryType.Hat
		accessory.AttachmentPoint = CFrame.new(0, 0, 0) * CFrame.Angles(0.2617993877991494, 0, 0)

		-- One Head-mesh Part with its face Decal; Handle and HeadBottom are both this.
		local function makeSkullPart(name: string, meshScale: Vector3, faceColor: Color3, faceTexture: string): Part
			local part = makeHalloweenHandle(name, Vector3.new(1, 1, 1), YETI_LOOK.extremityColor)
			part.Material = YETI_LOOK.extremityMaterial

			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = meshScale
			mesh.Parent = part

			local face = Instance.new("Decal")
			face.Name = "face"
			face.Color3 = faceColor
			face.Texture = faceTexture
			face.Face = Enum.NormalId.Front
			face.Parent = part

			return part
		end

		local handle = makeSkullPart(
			"Handle",
			Vector3.new(1.6, 1.6, 1.6),
			Color3.fromRGB(0, 0, 0),
			"http://www.roblox.com/asset/?id=991219543"
		)
		handle.Parent = accessory
		addLegacyAccessoryAttachment(accessory, handle)

		local function attachToHandle(part: BasePart, c0: CFrame)
			local weld = Instance.new("Weld")
			weld.Part0 = handle
			weld.Part1 = part
			weld.C0 = c0
			weld.Parent = part

			part.Parent = accessory
		end

		attachToHandle(
			makeSkullPart(
				"HeadBottom",
				Vector3.new(1.7, 1.8, 1.7),
				Color3.fromRGB(255, 255, 255),
				"http://www.roblox.com/asset/?id=13948756737"
			),
			CFrame.new(0, -0.5, -0.1) * CFrame.Angles(0.5235987755982988, 0, 0)
		)

		-- Both eyes share the same rotation; only x is mirrored.
		local eyeRotation = CFrame.fromEulerAnglesYXZ(-0.5235987755982988, 1.3962634015954636, 0.3490658503988659)
		for _, eye in ipairs({
			{ "LeftEye", -0.15 },
			{ "RightEye", 0.15 },
		}) do
			local part = makeHalloweenHandle(eye[1], Vector3.new(0.2, 0.2, 0.2), YETI_LOOK.eyeColor)
			part.Material = Enum.Material.Neon
			part.Shape = Enum.PartType.Cylinder
			attachToHandle(part, CFrame.new(eye[2], 0.3, -0.658) * eyeRotation)
		end

		return accessory
	end

	-- Zeus Beard and Yeti Beard are the same kind of object: a Handle with a
	-- textured, half-grey FileMesh, written for the legacy AttachmentPoint path.
	local function makeYetiBeard(name: string, attachmentPoint: CFrame, meshId: string, meshScale: Vector3): Accessory
		local accessory = Instance.new("Accessory")
		accessory.Name = name
		accessory.AccessoryType = Enum.AccessoryType.Hair
		accessory.AttachmentPoint = attachmentPoint

		local handle = makeHalloweenHandle("Handle", Vector3.new(1, 1, 1))
		handle.Parent = accessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = meshId
		mesh.TextureId = YETI_LOOK.furTextureId
		mesh.VertexColor = Vector3.new(0.5, 0.5, 0.5)
		mesh.Scale = meshScale
		mesh.Parent = handle

		addLegacyAccessoryAttachment(accessory, handle)

		return accessory
	end

	local function applyYetiHalloween(model: Model)
		clearYetiHalloweenAdditions(model)
		removeYetiBodyColors(model)
		setYetiBodyParts(model, true)
		setYetiClub(model, true)

		local zombie = model:FindFirstChild("Zombie")
		if not zombie or not zombie:IsA("Humanoid") then
			warn(
				"Yeti Halloween transformation: missing Humanoid 'Zombie' in",
				model:GetFullName(),
				"- MonsterHead and the beards were not added and the YetiHead was left visible"
			)
			return
		end

		local monsterHead = makeYetiMonsterHead()
		addMarkedHalloweenAccessory(model, zombie, monsterHead, YETI_KILLER_NAME, LEGACY_ACCESSORY_ATTACHMENT)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeYetiBeard(
				YETI_LOOK.zeusBeardName,
				CFrame.new(-0.05, 0, -0.3),
				"http://www.roblox.com/asset/?id=1492198449",
				Vector3.new(1.5, 1.6, 1.6)
			),
			YETI_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)
		addMarkedHalloweenAccessory(
			model,
			zombie,
			makeYetiBeard(
				YETI_LOOK.yetiBeardName,
				CFrame.new(0, 1, 0.7),
				"http://www.roblox.com/asset/?id=4417618542",
				Vector3.new(2.4, 2, 1.6)
			),
			YETI_KILLER_NAME,
			LEGACY_ACCESSORY_ATTACHMENT
		)

		-- Only hide the classic YetiHead once the MonsterHead is really on the rig,
		-- so a failed AddAccessory never leaves Yeti headless.
		if monsterHead.Parent == model then
			setYetiHeadVisible(model, false)
		end
	end

	local function restoreYetiNormal(model: Model)
		clearYetiHalloweenAdditions(model)
		setYetiClub(model, false)
		setYetiHeadVisible(model, true)
		restoreYetiBodyColors(model)
		setYetiBodyParts(model, false)
	end

	TRANSFORMATIONS[YETI_KILLER_NAME] = {
		Halloween = {
			-- BodyColors is destroyed and rebuilt by applyCustom, not recoloured.
			applyCustom = applyYetiHalloween,
		},
		Normal = {
			applyCustom = restoreYetiNormal,
		},
	}
end

do
	local ZOMBIE_KILLER_NAME = "Zombie"

	local ZOMBIE_LOOK = {
		Normal = {
			bodyColor = Color3.fromRGB(0, 255, 0),
			faceColor = Color3.fromRGB(255, 255, 255),
			transparency = 0,
		},
		Halloween = {
			bodyColor = Color3.fromRGB(163, 162, 165),
			faceColor = Color3.fromRGB(0, 0, 0),
			transparency = 0.5,
		},
	}

	-- The Head plus the fourteen body MeshParts that turn half transparent.
	local ZOMBIE_TRANSLUCENT_PART_NAMES = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"LeftUpperArm",
		"LeftLowerArm",
		"LeftHand",
		"RightUpperArm",
		"RightLowerArm",
		"RightHand",
		"LeftUpperLeg",
		"LeftLowerLeg",
		"LeftFoot",
		"RightUpperLeg",
		"RightLowerLeg",
		"RightFoot",
	}

	-- Everything the two variants change on objects the classic rig already owns,
	-- apart from the Body Colors, which the shared applyVariant step sets.
	local function setZombieAppearance(model: Model, look: any)
		local head = model:FindFirstChild("Head")
		local face = head and head:FindFirstChild("face")
		if face and face:IsA("Decal") then
			face.Color3 = look.faceColor
		else
			warn(ZOMBIE_KILLER_NAME .. " transformation: Head.face was not found in", model:GetFullName())
		end

		for _, partName in ipairs(ZOMBIE_TRANSLUCENT_PART_NAMES) do
			local part = model:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				part.Transparency = look.transparency
			else
				warn(ZOMBIE_KILLER_NAME .. " transformation: missing part", partName, "in", model:GetFullName())
			end
		end
	end

	local function applyZombieHalloween(model: Model)
		setZombieAppearance(model, ZOMBIE_LOOK.Halloween)
	end

	local function restoreZombieNormal(model: Model)
		setZombieAppearance(model, ZOMBIE_LOOK.Normal)
	end

	TRANSFORMATIONS[ZOMBIE_KILLER_NAME] = {
		Halloween = {
			bodyColor = ZOMBIE_LOOK.Halloween.bodyColor,
			applyCustom = applyZombieHalloween,
		},
		Normal = {
			bodyColor = ZOMBIE_LOOK.Normal.bodyColor,
			applyCustom = restoreZombieNormal,
		},
	}
end

local function applyVariant(killer: Model, variant: VariantConfig)
	local bodyColors = killer:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		if variant.bodyColor then
			setBodyColor(bodyColors, variant.bodyColor)
		end
		if variant.bodyColors then
			applyBodyColorOverrides(bodyColors, variant.bodyColors)
		end
	end

	if variant.clothingColor then
		local pants = killer:FindFirstChildOfClass("Pants")
		local shirt = killer:FindFirstChildOfClass("Shirt")

		if pants then
			pants.Color3 = variant.clothingColor
		end

		if shirt then
			shirt.Color3 = variant.clothingColor
		end
	end

	local head = killer:FindFirstChild("Head")
	if head and head:IsA("MeshPart") then
		if variant.headTextureId ~= nil then
			head.TextureID = variant.headTextureId
		end

		applySurfaceAppearance(head, variant)
	end

	if variant.applyCustom then
		variant.applyCustom(killer)
	end
end

-- Jack-O-Killers are special Halloween variants. If any BoolValue named
-- "JackOKiller" inside a model is true, leave that entire model untouched for
-- both HalloweenTransform() and NormalTransform().
local function isJackOKiller(model: Model): boolean
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant.Name == "JackOKiller"
			and descendant:IsA("BoolValue")
			and descendant.Value then
			return true
		end
	end

	return false
end

-- Killers that are dead or are missing a critical body part are never transformed: applying a
-- look to a corpse or a half-destroyed rig only produces broken accessories and joints. Every
-- killer is R15; the R6 list is only a fallback in case a rig ever uses the old body.
local CRITICAL_PARTS_R15 = { "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso" }
local CRITICAL_PARTS_R6 = { "HumanoidRootPart", "Head", "Torso" }

-- Returns nil when the killer is alive and complete, otherwise a short reason it must be skipped.
local function getUntransformableReason(killer: Model): string?
	local humanoid = killer:FindFirstChild("Zombie")
	if not (humanoid and humanoid:IsA("Humanoid")) then
		humanoid = killer:FindFirstChildOfClass("Humanoid")
	end
	if not humanoid then
		return "it has no Humanoid"
	end

	if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return "it is dead"
	end

	local criticalParts = if humanoid.RigType == Enum.HumanoidRigType.R6
		then CRITICAL_PARTS_R6
		else CRITICAL_PARTS_R15
	for _, partName in ipairs(criticalParts) do
		local part = killer:FindFirstChild(partName)
		if not (part and part:IsA("BasePart")) then
			return "it is missing its " .. partName
		end
	end

	return nil
end

local ALL_KILLERS_TARGET = "All"

local function trimString(value: string): string
	return string.match(value, "^%s*(.-)%s*$") or value
end

-- Maps whatever the caller typed ("eyeless jack", " Eyeless Jack ") to the exact
-- key used in TRANSFORMATIONS, or nil if no such killer is configured.
local function resolveKillerName(requested: string): string?
	local wanted = string.lower(requested)
	for killerName in pairs(TRANSFORMATIONS) do
		if string.lower(killerName) == wanted then
			return killerName
		end
	end

	return nil
end

local function getConfiguredKillerNames(): string
	local names = {}
	for killerName in pairs(TRANSFORMATIONS) do
		table.insert(names, killerName)
	end
	table.sort(names)

	return table.concat(names, ", ")
end

-- target is either a killer's name ("Eyeless Jack") or "All". Returns how many
-- killer models were transformed.
local function transformKillers(variantName: "Halloween" | "Normal", target: string?): number
	local requested: any = target
	if requested == nil then
		requested = ALL_KILLERS_TARGET
	end

	if typeof(requested) ~= "string" then
		warn("HalloweenTransformations: expected a killer name or \"" .. ALL_KILLERS_TARGET .. "\", got " .. typeof(requested))
		return 0
	end

	requested = trimString(requested)
	local transformEveryKiller = string.lower(requested) == string.lower(ALL_KILLERS_TARGET)

	local targetName: string? = nil
	if not transformEveryKiller then
		targetName = resolveKillerName(requested)
		if not targetName then
			warn(
				"HalloweenTransformations: no transformation is configured for \"" .. requested
					.. "\". Use \"" .. ALL_KILLERS_TARGET .. "\" or one of: " .. getConfiguredKillerNames()
			)
			return 0
		end
	end

	local killersFolder = Workspace:FindFirstChild("Killers")
	if not killersFolder then
		warn("HalloweenTransformations: Workspace.Killers was not found.")
		return 0
	end

	-- Collect first so models added or removed by a transformation cannot disturb the walk.
	local matchingKillers: { Model } = {}
	for _, descendant in ipairs(killersFolder:GetDescendants()) do
		if descendant:IsA("Model") and (transformEveryKiller or descendant.Name == targetName) then
			table.insert(matchingKillers, descendant)
		end
	end

	local transformed = 0
	for _, killer in ipairs(matchingKillers) do
		if isJackOKiller(killer) then
			-- "All" only reports Ao Oni (the one expected case); a named request
			-- always explains why that killer was left alone.
			if not transformEveryKiller or killer.Name == "Ao Oni" then
				warn("HalloweenTransformations: " .. killer.Name .. " was intentionally skipped because it contains a BoolValue named 'JackOKiller' with Value=true:", killer:GetFullName())
			end
		else
			local killerConfig = TRANSFORMATIONS[killer.Name]
			local variant = killerConfig and killerConfig[variantName]
			if variant then
				local unfitReason = getUntransformableReason(killer)
				if unfitReason then
					-- Dead or broken killers are expected during a round, so "All" skips them
					-- silently; a named request explains why that killer was left alone.
					if not transformEveryKiller then
						warn("HalloweenTransformations: " .. killer.Name .. " was skipped because " .. unfitReason .. ":", killer:GetFullName())
					end
				else
					local ok, failure = pcall(applyVariant, killer, variant)
					if ok then
						transformed += 1
					else
						warn("HalloweenTransformations: " .. killer.Name .. " " .. variantName .. " application failed for " .. killer:GetFullName() .. ": " .. tostring(failure))
					end
				end
			end
		end
	end

	if #matchingKillers == 0 and not transformEveryKiller then
		warn("HalloweenTransformations: no killer named \"" .. tostring(targetName) .. "\" is currently in Workspace.Killers.")
	end

	return transformed
end

-- HalloweenTransform("Eyeless Jack") / HalloweenTransform("All"). With no argument it behaves like
-- "All".
function HalloweenTransformations.HalloweenTransform(target: string?): number
	return transformKillers("Halloween", target)
end

function HalloweenTransformations.NormalTransform(target: string?): number
	return transformKillers("Normal", target)
end

-- Map transformations: HalloweenMapTransform() / NormalMapTransform().
--
-- Fog, Ground and Paths colours are assigned as absolute values (nothing is stored or read back),
-- so calling either direction repeatedly is harmless. The Halloween decorations are not stored
-- anywhere: going back to Normal destroys them and HalloweenMapTransform() rebuilds them from
-- DECORATION_SPECS, so both directions keep working after the event, when they no longer exist in
-- the place. DeadTrees, a sibling of the decorations, is deliberately left untouched.
do
	local Lighting = game:GetService("Lighting")

	local DECORATION_PATH = { "AREA51", "Outside", "OutsideDecoration" }
	local GROUND_PATH = { "AREA51", "Outside", "GroundOutside" }
	local PATHS_PATH = { "AREA51", "Outside", "Paths" }

	-- Children of OutsideDecoration that only exist in the Halloween map, in the order
	-- they are built. OutsideDecoration.DeadTrees is a sibling that is deliberately NOT
	-- listed. Each name is a key of DECORATION_SPECS below.
	local HALLOWEEN_DECORATION_NAMES = { "CandyHolders", "Cobweb", "Eyeballs", "StaticPumpkins" }

	local FOG_COLOR_HALLOWEEN = Color3.fromRGB(191, 100, 50)
	local FOG_COLOR_NORMAL = Color3.fromRGB(255, 255, 255)

	-- Texture.Color3 of every Texture under GroundOutside (the grass).
	local GROUND_TEXTURE_HALLOWEEN_COLOR = Color3.fromRGB(200, 127, 0)
	local GROUND_TEXTURE_NORMAL_COLOR = Color3.fromRGB(15, 127, 0)

	-- Texture.Color3 of every Texture under Paths.
	local PATHS_TEXTURE_HALLOWEEN_COLOR = Color3.fromRGB(127, 63, 0)
	local PATHS_TEXTURE_NORMAL_COLOR = Color3.fromRGB(255, 255, 255)

	type MapTransformResult = {
		-- Halloween: decoration models built. Normal: decoration models destroyed.
		decorations: number,
		-- GroundOutside Textures that were set to the Halloween / Normal colour.
		groundTextures: number,
		-- Paths Textures that were set to the Halloween / Normal colour.
		pathTextures: number,
		-- True once Lighting.FogColor has been set.
		fog: boolean,
	}

	local function findPath(root: Instance, path: { string }): Instance?
		local current: Instance? = root
		for _, name in ipairs(path) do
			current = current and current:FindFirstChild(name)
			if current == nil then
				return nil
			end
		end

		return current
	end

	-- Everything needed to build the four Halloween decoration Models from nothing.
	-- Read from the place file; all 70 objects are plain Parts.
	--   partProperties  properties every Part of the Model has in common
	--   meshProperties  properties of the one SpecialMesh inside every Part (if any)
	--   rows            one entry per Part, in the order they appear in the place:
	--                   { name, { size X, Y, Z }, { CFrame x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 }, extra? }
	--                   extra: meshScale (a mesh whose Scale differs from meshProperties)
	--                          decals ({ kind, face } pairs, kinds from decalKinds)
	--   variants        (StaticPumpkins) per-Part-name Transparency and mesh VertexColor
	local DECORATION_SPECS: { [string]: any } = {
	CandyHolders = {
		partProperties = {
			Anchored = true,
			CanCollide = true,
			CanQuery = true,
			CanTouch = true,
			Color = Color3.fromRGB(226, 155, 64),
			Material = Enum.Material.Wood,
			TopSurface = Enum.SurfaceType.Studs,
			BottomSurface = Enum.SurfaceType.Inlet,
			LeftSurface = Enum.SurfaceType.Smooth,
			RightSurface = Enum.SurfaceType.Smooth,
			FrontSurface = Enum.SurfaceType.Smooth,
			BackSurface = Enum.SurfaceType.Smooth,
		},
		meshProperties = {
			MeshType = Enum.MeshType.FileMesh,
			MeshId = "http://www.roblox.com/asset/?id=17359739",
			TextureId = "http://www.roblox.com/asset/?id=17359729",
			Offset = Vector3.new(0, 0, 1.8),
			Scale = Vector3.new(10, 10, 10),
		},
		rows = {
			{ "Candy", { 6.8, 7.2, 6.7999997 }, { 344.6, 511.9, 389.00003, 1, 0, 0, 0, 0, 1, 0, -1, 0 } },
			{ "Candy", { 6.8, 7.2, 6.7999997 }, { 344.6, 511.9, 351.80002, 1, 0, 0, 0, 0, 1, 0, -1, 0 } },
			{ "Candy", { 6.8, 7.2, 6.7999997 }, { 307.80002, 511.9, 389.00003, -1, 0, 0, 0, 0, 1, 0, 1, 0 } },
			{ "Candy", { 6.8, 7.2, 6.7999997 }, { 307.80002, 511.9, 351.80002, -1, 0, 0, 0, 0, 1, 0, 1, 0 } },
			{ "Candy", { 6.8, 7.2, 6.7999997 }, { 458.4, 530.10004, 341.2, 0, 1, 0, 0, 0, 1, 1, 0, 0 } },
			{ "Candy", { 6.8, 7.2, 6.7999997 }, { 349.4, 511.9, 573.80005, 1, 0, 0, 0, 0, 1, 0, -1, 0 } },
			{ "Candy", { 6.8, 7.2, 6.7999997 }, { 345.40002, 511.9, 604.2, 0.49993896, 0.8660606, 1.1861324e-05, 1.1861324e-05, -2.0503998e-05, 1, 0.8660606, -0.49993896, -2.0503998e-05 } },
		},
	},
	Cobweb = {
		partProperties = {
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Color = Color3.fromRGB(163, 162, 165),
			Material = Enum.Material.Plastic,
			TopSurface = Enum.SurfaceType.Smooth,
			BottomSurface = Enum.SurfaceType.Smooth,
			LeftSurface = Enum.SurfaceType.Smooth,
			RightSurface = Enum.SurfaceType.Smooth,
			FrontSurface = Enum.SurfaceType.Smooth,
			BackSurface = Enum.SurfaceType.Smooth,
			Transparency = 1,
		},
		-- The three Decal kinds the rows refer to; each row lists { kind, face } pairs.
		decalKinds = {
			right = { name = "cobweb right", texture = "rbxassetid://5050224526" },
			left = { name = "cobweb left", texture = "rbxassetid://5050225104" },
			web = { name = "Cobweb", texture = "rbxassetid://5054872267" },
		},
		rows = {
			{ "Cobweb", { 0.2, 20, 40 }, { 398.7, 519.5, 425.39996, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 0.2, 20, 50 }, { 398.7, 519.5, 329.39996, -1, 0, 0, 0, 1, 0, 0, 0, -1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 0.2, 14.2, 50 }, { 497.7, 516.6, 329.39996, -1, 0, 0, 0, 1, 0, 0, 0, -1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 0.2, 20, 40 }, { 497.7, 519.5, 425.39996, -1, 0, 0, 0, 1, 0, 0, 0, -1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 10, 10, 0.2 }, { 448.2, 514.5, 385.9, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { decals = { { "web", Enum.NormalId.Back }, { "web", Enum.NormalId.Front } } } },
			{ "Cobweb", { 10, 10, 0.2 }, { 448.2, 514.5, 373.9, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { decals = { { "web", Enum.NormalId.Back }, { "web", Enum.NormalId.Front } } } },
			{ "Cobweb", { 8, 8.4, 0.2 }, { 355, 512.9, 500.50003, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { decals = { { "web", Enum.NormalId.Back }, { "web", Enum.NormalId.Front } } } },
			{ "Cobweb", { 0.2, 10, 58 }, { 613.3, 514.5, 395.20004, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { decals = { { "left", Enum.NormalId.Right }, { "right", Enum.NormalId.Left } } } },
			{ "Cobweb", { 10, 10, 0.2 }, { 603.7, 514.5, 229.40002, 0, 0, 1, 0, 1, 0, -1, 0, 0 }, { decals = { { "web", Enum.NormalId.Back }, { "web", Enum.NormalId.Front } } } },
			{ "Cobweb", { 0.2, 30, 50 }, { 677.2, 524.50006, 179.50002, 0, 0, 1, 0, 1, 0, -1, 0, 0 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 0.2, 30, 50 }, { 629.2, 524.50006, 179.50002, 0, 0, -1, 0, -1, 0, -1, 0, 0 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 0.2, 30, 30 }, { 326.2, 508.4, 370.40005, 0, 1, 0, 1, 0, 0, 0, 0, -1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 0.2, 30, 30 }, { 326.20004, 508.4, 370.40005, 0, 0, 1, 1, 0, 0, 0, 1, 0 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 0.2, 30, 30 }, { 326.20004, 508.4, 370.40005, 0, -1, 0, 1, 0, 0, 0, 0, 1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 0.2, 30, 30 }, { 326.20004, 508.4, 370.40005, 0, 0, -1, 1, 0, 0, 0, -1, 0 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right } } } },
			{ "Cobweb", { 0.2, 6.999999, 30.6 }, { 344.69995, 512, 370.30002, -1, 0, 0, 0, -1, 0, 0, 0, 1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right }, { "right", Enum.NormalId.Right }, { "left", Enum.NormalId.Left } } } },
			{ "Cobweb", { 0.2, 6.999999, 30.6 }, { 307.69995, 512, 370.30002, -1, 0, 0, 0, -1, 0, 0, 0, 1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right }, { "right", Enum.NormalId.Right }, { "left", Enum.NormalId.Left } } } },
			{ "Cobweb", { 0.2, 6.999999, 30.6 }, { 326.1, 512, 351.70007, 0, 0, 1, 0, -1, 0, 1, 0, 0 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right }, { "right", Enum.NormalId.Right }, { "left", Enum.NormalId.Left } } } },
			{ "CobwebShop", { 0.19999981, 3.399999, 24.8 }, { 412.9001, 519.19995, 425.4, -1, 0, 0, 0, -1, 0, 0, 0, 1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right }, { "right", Enum.NormalId.Right }, { "left", Enum.NormalId.Left } } } },
			{ "Cobweb", { 0.19999981, 38.399998, 245.6 }, { 353.1, 527.7002, 669.00024, -1, 0, 0, 0, -1, 0, 0, 0, 1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right }, { "right", Enum.NormalId.Right }, { "left", Enum.NormalId.Left } } } },
			{ "Cobweb", { 0.19999981, 38.399998, 245.6 }, { 300.1, 527.7002, 656.00024, -1, 0, 0, 0, -1, 0, 0, 0, 1 }, { decals = { { "right", Enum.NormalId.Left }, { "left", Enum.NormalId.Right }, { "right", Enum.NormalId.Right }, { "left", Enum.NormalId.Left } } } },
			{ "Cobweb", { 10, 9.8, 0.2 }, { 635.1, 513.60004, 300.40002, 0, 0, 1, 0, 1, 0, -1, 0, 0 }, { decals = { { "web", Enum.NormalId.Back }, { "web", Enum.NormalId.Front } } } },
		},
	},
	Eyeballs = {
		partProperties = {
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Foil,
			TopSurface = Enum.SurfaceType.Studs,
			BottomSurface = Enum.SurfaceType.Inlet,
			LeftSurface = Enum.SurfaceType.Smooth,
			RightSurface = Enum.SurfaceType.Smooth,
			FrontSurface = Enum.SurfaceType.Smooth,
			BackSurface = Enum.SurfaceType.Smooth,
		},
		meshProperties = {
			MeshType = Enum.MeshType.FileMesh,
			MeshId = "http://www.roblox.com/asset/?id=1185246",
			TextureId = "http://www.roblox.com/asset/?id=5013397",
			Scale = Vector3.new(5, 5, 5),
		},
		-- A few meshes were resized slightly in the place, so their Scale differs a hair from 5.
		rows = {
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 343.30005, 522.60016, 697.0999, 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { meshScale = Vector3.new(4.9999747, 5, 5) } },
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 407.30005, 516.0001, 288.49997, -1, 0, 0, 0, 1, 0, 0, 0, -1 }, { meshScale = Vector3.new(4.9999747, 5, 5) } },
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 326.1, 530.39996, 357.09998, -1, 0, 0, 0, 1, 0, 0, 0, -1 }, { meshScale = Vector3.new(4.9999747, 5, 5) } },
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 458.89996, 517.40063, 398.50003, 0, 0, 1, 0, 1, 0, -1, 0, 0 } },
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 402.29996, 521.0001, 365.30008, 0, 0, -1, 0, 1, 0, 1, 0, 0 } },
			{ "Eyeball", { 3.4, 3.4, 3.4 }, { 280.7, 526.2001, 188.90076, -1, 0, 0, 0, 1, 0, 0, 0, -1 }, { meshScale = Vector3.new(5, 5, 4.999995) } },
			{ "Eyeball", { 3.4, 3.4, 3.4 }, { 194.7, 526.2001, 188.90002, -1, 0, 0, 0, 1, 0, 0, 0, -1 }, { meshScale = Vector3.new(5, 5, 4.999995) } },
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 189.9, 515.20013, 248.70006, 0, 0, -1, 0, 1, 0, 1, 0, 0 } },
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 192.09998, 515.4002, 282.10004, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 231.89996, 515.4001, 277.10004, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 287.3001, 520.60004, 237.10007, -1.1920929e-07, 0, 1.0000001, 0.00012207778, 1, 0, -1.0000001, 0.00012207778, -1.1920929e-07 } },
			{ "Eyeball", { 3.4, 3.4, 3.3999999 }, { 287.30002, 520.6001, 253.69997, -1.1920929e-07, 0, 1.0000001, 0.00012207778, 1, 0, -1.0000001, 0.00012207778, -1.1920929e-07 } },
			{ "EyeballShop1", { 3.4, 3.4, 3.3999999 }, { 412.90002, 519.20013, 412.09998, -1.1920929e-07, 0, 1.0000001, 0.00012207778, 1, 0, -1.0000001, 0.00012207778, -1.1920929e-07 } },
			{ "EyeballShop2", { 3.4, 3.4, 3.3999999 }, { 412.9, 519.2, 438.69995, -1.1920929e-07, 0, 1.0000001, 0.00012207778, 1, 0, -1.0000001, 0.00012207778, -1.1920929e-07 } },
		},
	},
	StaticPumpkins = {
		partProperties = {
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Color = Color3.fromRGB(163, 162, 165),
			Material = Enum.Material.Plastic,
			TopSurface = Enum.SurfaceType.Smooth,
			BottomSurface = Enum.SurfaceType.Smooth,
			LeftSurface = Enum.SurfaceType.Smooth,
			RightSurface = Enum.SurfaceType.Smooth,
			FrontSurface = Enum.SurfaceType.Smooth,
			BackSurface = Enum.SurfaceType.Smooth,
		},
		meshProperties = {
			MeshType = Enum.MeshType.FileMesh,
			MeshId = "http://www.roblox.com/asset/?id=16973748",
			TextureId = "http://www.roblox.com/asset/?id=9184993499",
			Scale = Vector3.new(10, 10, 10),
		},
		-- Per-name look: the mesh VertexColor tints the pumpkin; the white ones are half see-through.
		variants = {
			PumpkinB = { vertexColor = Vector3.new(0, 1, 2), transparency = 0 },
			PumpkinG = { vertexColor = Vector3.new(0.5, 1, 0), transparency = 0 },
			PumpkinO = { vertexColor = Vector3.new(1.5, 0.75, 0.25), transparency = 0 },
			PumpkinP = { vertexColor = Vector3.new(0.5, 0.25, 0.75), transparency = 0 },
			PumpkinW = { vertexColor = Vector3.new(1, 1, 1), transparency = 0.5 },
		},
		rows = {
			{ "PumpkinB", { 10.400001, 10.400001, 10.400001 }, { 623.2001, 554.7, 395.80002, -1.1920929e-07, 0, 1.0000001, 0, 1, 0, -1.0000001, 0, -1.1920929e-07 } },
			{ "PumpkinB", { 10.400001, 10.400001, 10.400001 }, { 250.59999, 513.7, 345.80017, 0.9062967, 0, -0.42264208, 0, 1, 0, 0.42264208, 0, 0.9062967 } },
			{ "PumpkinB", { 10.400001, 10.400001, 10.400001 }, { 152.39998, 513.7006, 419.2, -1.1920929e-07, 0, -1.0000001, 0, 1, 0, 1.0000001, 0, -1.1920929e-07 } },
			{ "PumpkinG", { 10.400001, 10.400001, 10.400001 }, { 332.6, 513.7, 198.2, -1, 0, 0, 0, 1, 0, 0, 0, -1 } },
			{ "PumpkinG", { 10.400001, 10.400001, 10.400001 }, { 549.7999, 514.4, 329.2, 0, 0, 1, 0, 1, 0, -1, 0, 0 } },
			{ "PumpkinG", { 10.400001, 10.400001, 10.400001 }, { 179.39998, 513.7, 201.20007, -1, 0, 0, 0, 1, 0, 0, 0, -1 } },
			{ "PumpkinG", { 10.400001, 10.400001, 10.400001 }, { 119.600006, 513.7, 356.40018, -1, 0, 0, 0, 1, 0, 0, 0, -1 } },
			{ "PumpkinG", { 10.400001, 10.400001, 10.400001 }, { 407.2, 546.7001, 364.60004, -0.422593, 0, 0.9063196, 0, 1, 0, -0.9063196, 0, -0.422593 } },
			{ "PumpkinG", { 10.400001, 10.400001, 10.400001 }, { 643.39996, 524.7, 314.00003, -1.1920929e-07, 0, 1.0000001, 0, 1, 0, -1.0000001, 0, -1.1920929e-07 } },
			{ "PumpkinO", { 10.400001, 10.400001, 10.400001 }, { 407.2, 547.7001, 454.8, 0.49995947, 0, 0.8660488, 0, 1, 0, -0.8660488, 0, 0.49995947 } },
			{ "PumpkinO", { 10.400001, 10.400001, 10.400001 }, { 355.20004, 524.7, 513.4, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
			{ "PumpkinO", { 10.400001, 10.400001, 10.400001 }, { 279.99994, 513.7, 488.6, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
			{ "PumpkinO", { 10.400001, 10.400001, 10.400001 }, { 469.1, 530.3, 363.6, 0.9988022, -0.048929922, 0, 0.048929922, 0.9988022, 0, 0, 0, 1 } },
			{ "PumpkinO", { 10.400001, 10.400001, 10.400001 }, { 591, 513.7, 506.60004, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
			{ "PumpkinO", { 10.400001, 10.400001, 10.400001 }, { 435.6, 513.7, 271.2, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
			{ "PumpkinP", { 10.400001, 10.400001, 10.400001 }, { 425.80002, 513.7, 489.2, -1, 0, 0, 0, 1, 0, 0, 0, -1 } },
			{ "PumpkinP", { 10.400001, 10.400001, 10.400001 }, { 466.19998, 522.7, 297.4, -0.49995947, 0, 0.8660488, 0, 1, 0, -0.8660488, 0, -0.49995947 } },
			{ "PumpkinP", { 10.400001, 10.400001, 10.400001 }, { 691, 514.7, 256.2, 0.25886434, 0, 0.9659137, 0, 1, 0, -0.9659137, 0, 0.25886434 } },
			{ "PumpkinP", { 10.400001, 10.400001, 10.400001 }, { 611.6, 546.7, 259.80008, -0.64276373, 0, 0.76606494, 0, 1, 0, -0.76606494, 0, -0.64276373 } },
			{ "PumpkinP", { 10.400001, 10.400001, 10.400001 }, { 445.2, 538.7, 209.20001, 0, 0, 1, 0, 1, 0, -1, 0, 0 } },
			{ "PumpkinW", { 10.400001, 10.400001, 10.400001 }, { 172.80002, 513.7, 296.20007, -0.2588644, 0, -0.9659137, 0, 1, 0, 0.9659137, 0, -0.2588644 } },
			{ "PumpkinW", { 10.400001, 10.400001, 10.400001 }, { 299.80002, 513.8, 515.6, -1.1920929e-07, 0, -1.0000001, 0, 1, 0, 1.0000001, 0, -1.1920929e-07 } },
			{ "PumpkinW", { 10.400001, 10.400001, 10.400001 }, { 325.4, 513.7, 433.6, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
			{ "PumpkinW", { 10.400001, 10.400001, 10.400001 }, { 548, 513.9, 427.40002, 0, 0, 1, 0, 1, 0, -1, 0, 0 } },
			{ "PumpkinW", { 10.400001, 10.400001, 10.400001 }, { 175.99994, 513.7006, 487.40002, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
			{ "PumpkinO", { 10.400001, 10.400001, 10.400001 }, { 325.6, 511.90002, 335.19998, -1, 0, 0, 0, 0.9848125, -0.17362115, 0, -0.17362115, -0.9848126 } },
			{ "PumpkinO", { 10.400001, 10.400001, 10.400001 }, { 301.59995, 513.7, 605.4, 0.49995947, 0, -0.8660488, 0, 1, 0, 0.8660488, 0, 0.49995947 } },
		},
	},
	}

	-- Writes every entry of `properties` onto `instance`. The property tables above
	-- only hold plain assignable properties.
	local function applyProperties(instance: Instance, properties: { [string]: any })
		for property, value in pairs(properties) do
			(instance :: any)[property] = value
		end
	end

	local function buildDecorationPart(spec: any, row: { any }): Part
		local part = Instance.new("Part")
		part.Name = row[1]
		part.Size = Vector3.new(table.unpack(row[2]))
		applyProperties(part, spec.partProperties)

		local extra = row[4]
		local variant = spec.variants and spec.variants[row[1]]
		if variant then
			part.Transparency = variant.transparency
		end

		if spec.meshProperties then
			local mesh = Instance.new("SpecialMesh")
			applyProperties(mesh, spec.meshProperties)
			if variant then
				mesh.VertexColor = variant.vertexColor
			end
			if extra and extra.meshScale then
				mesh.Scale = extra.meshScale
			end
			mesh.Parent = part
		end

		if extra and extra.decals then
			for _, entry in ipairs(extra.decals) do
				local kind = spec.decalKinds[entry[1]]
				local decal = Instance.new("Decal")
				decal.Name = kind.name
				decal.Texture = kind.texture
				decal.Face = entry[2]
				decal.Parent = part
			end
		end

		part.CFrame = CFrame.new(table.unpack(row[3]))

		return part
	end

	-- The Model is filled completely before it is parented, so it never shows up half built.
	local function buildDecorationModel(name: string, spec: any): Model
		local model = Instance.new("Model")
		model.Name = name
		for _, row in ipairs(spec.rows) do
			buildDecorationPart(spec, row).Parent = model
		end

		return model
	end

	-- Destroys every child of `decoration` that has the name of one of the Halloween
	-- Models (ours, or one the game left behind). Returns how many were destroyed.
	local function clearHalloweenDecorations(decoration: Instance): number
		local removed = 0
		for _, child in ipairs(decoration:GetChildren()) do
			if DECORATION_SPECS[child.Name] ~= nil then
				child:Destroy()
				removed += 1
			end
		end

		return removed
	end

	-- Normal map: destroy the Halloween-only Models. Returns how many were removed.
	local function removeHalloweenDecorations(): number
		local decoration = findPath(Workspace, DECORATION_PATH)
		if not decoration then
			warn("HalloweenTransformations: Workspace.AREA51.Outside.OutsideDecoration was not found; the decorations were left alone.")
			return 0
		end

		return clearHalloweenDecorations(decoration)
	end

	-- Halloween map: build the Halloween-only Models from DECORATION_SPECS. Any copy
	-- already there is replaced rather than stacked on. Returns how many were built.
	local function createHalloweenDecorations(): number
		local decoration = findPath(Workspace, DECORATION_PATH)
		if not decoration then
			warn("HalloweenTransformations: Workspace.AREA51.Outside.OutsideDecoration was not found; the decorations were not created.")
			return 0
		end

		clearHalloweenDecorations(decoration)

		local created = 0
		for _, name in ipairs(HALLOWEEN_DECORATION_NAMES) do
			local ok, result = pcall(buildDecorationModel, name, DECORATION_SPECS[name])
			if ok then
				result.Parent = decoration
				created += 1
			else
				warn("HalloweenTransformations: could not build OutsideDecoration." .. name .. ": " .. tostring(result))
			end
		end

		return created
	end

	-- Assigns one absolute colour to Texture.Color3 of every Texture under the Model
	-- at `path`. Nothing is remembered or read back, so the result never depends on
	-- the colour the Textures have right now. Returns how many Textures were set, or
	-- 0 (after a warning) if the Model is missing.
	local function setTextureColors(path: { string }, color: Color3): number
		local root = findPath(Workspace, path)
		if not root then
			warn("HalloweenTransformations: Workspace." .. table.concat(path, ".") .. " was not found; it was left alone.")
			return 0
		end

		local count = 0
		for _, descendant in ipairs(root:GetDescendants()) do
			if descendant:IsA("Texture") then
				descendant.Color3 = color
				count += 1
			end
		end

		return count
	end

	-- Each step runs on its own, so a problem in one (say a missing folder) cannot
	-- stop the others.
	local function runStep(label: string, step: () -> ())
		local ok, failure = pcall(step)
		if not ok then
			warn("HalloweenTransformations: map step \"" .. label .. "\" failed: " .. tostring(failure))
		end
	end

	-- Normal -> Halloween: builds the decorations, turns the ground and path
	-- Textures to their Halloween colours and turns the fog orange.
	function HalloweenTransformations.HalloweenMapTransform(): MapTransformResult
		local result: MapTransformResult = { decorations = 0, groundTextures = 0, pathTextures = 0, fog = false }

		runStep("decorations", function()
			result.decorations = createHalloweenDecorations()
		end)
		runStep("ground", function()
			result.groundTextures = setTextureColors(GROUND_PATH, GROUND_TEXTURE_HALLOWEEN_COLOR)
		end)
		runStep("paths", function()
			result.pathTextures = setTextureColors(PATHS_PATH, PATHS_TEXTURE_HALLOWEEN_COLOR)
		end)
		runStep("fog", function()
			Lighting.FogColor = FOG_COLOR_HALLOWEEN
			result.fog = true
		end)

		return result
	end

	-- Halloween -> Normal: destroys the Halloween-only decorations, sets the grass
	-- Textures to green and the path Textures to white, and turns the fog white.
	function HalloweenTransformations.NormalMapTransform(): MapTransformResult
		local result: MapTransformResult = { decorations = 0, groundTextures = 0, pathTextures = 0, fog = false }

		runStep("decorations", function()
			result.decorations = removeHalloweenDecorations()
		end)
		runStep("ground", function()
			result.groundTextures = setTextureColors(GROUND_PATH, GROUND_TEXTURE_NORMAL_COLOR)
		end)
		runStep("paths", function()
			result.pathTextures = setTextureColors(PATHS_PATH, PATHS_TEXTURE_NORMAL_COLOR)
		end)
		runStep("fog", function()
			Lighting.FogColor = FOG_COLOR_NORMAL
			result.fog = true
		end)

		return result
	end
end

return HalloweenTransformations
