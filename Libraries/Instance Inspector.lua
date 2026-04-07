local InstanceInspector = {}

local ClassPropertyMap = {
	BasePart = {
		Appearance = {
			"Color","Material","BrickColor","Transparency"
		},
		Data = {
			"Name","ClassName","Parent"
		},
		Transform = {
			"Position","Orientation","Size","CFrame"
		},
		Behavior = {
			"Anchored","CanCollide"
		}
	},

	Model = {
		Data = {
			"Name","ClassName","Parent"
		},
		Behavior = {
			"PrimaryPart"
		}
	},

	Humanoid = {
		Data = {
			"Name","ClassName","Parent"
		},
		Stats = {
			"Health","MaxHealth"
		},
		Movement = {
			"WalkSpeed","JumpPower"
		}
	},

	TextLabel = {
		Appearance = {
			"TextColor3","BackgroundColor3","TextSize","Font"
		},
		Data = {
			"Name","ClassName","Parent","Text"
		}
	},

	TextButton = {
		Appearance = {
			"TextColor3","BackgroundColor3","TextSize","Font"
		},
		Data = {
			"Name","ClassName","Parent","Text"
		}
	},

	Frame = {
		Appearance = {
			"BackgroundColor3","Visible"
		},
		Transform = {
			"Size","Position"
		},
		Data = {
			"Name","ClassName","Parent"
		}
	},

	ScreenGui = {
		Data = {
			"Name","ClassName","Parent"
		},
		Behavior = {
			"Enabled","DisplayOrder"
		}
	}
}

local function getCategorizedProperties(instance)
	local categories = {}

	for className, categoryTable in pairs(ClassPropertyMap) do
		if instance:IsA(className) then
			for category, props in pairs(categoryTable) do
				categories[category] = categories[category] or {}

				for _, prop in ipairs(props) do
					table.insert(categories[category], prop)
				end
			end
		end
	end

	return categories
end

--// INTERNAL: exclusion check
local function isExcluded(instance, config)
	if config.ExcludedClasses then
		for _, className in ipairs(config.ExcludedClasses) do
			if instance.ClassName == className then
				return true
			end
		end
	end

	if config.ExcludedInstances then
		for _, name in ipairs(config.ExcludedInstances) do
			if instance.Name == name then
				return true
			end
		end
	end

	return false
end

--// INTERNAL: duplicate handler
local function handleDuplicate(container, key, value, allowDuplicates)
	if not allowDuplicates then
		container[key] = value
		return
	end

	local existing = container[key]

	if existing == nil then
		-- first value → store normally
		container[key] = value
	elseif type(existing) ~= "table" then
		-- second value → convert to table
		container[key] = { existing, value }
	else
		-- already a table → insert
		table.insert(existing, value)
	end
end

--// INTERNAL: safe tostring (prevents userdata issues)
local function formatValue(value)
	local t = typeof(value)

	if t == "Vector3" then
		return string.format("Vector3(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)

	elseif t == "CFrame" then
		local x, y, z = value.Position.X, value.Position.Y, value.Position.Z
		return string.format("CFrame(%.2f, %.2f, %.2f)", x, y, z)

	elseif t == "Color3" then
		return string.format("Color3(%.2f, %.2f, %.2f)", value.R, value.G, value.B)

	elseif t == "BrickColor" then
		return value.Name

	elseif t == "Instance" then
		return value:GetFullName()

	elseif t == "EnumItem" then
		return tostring(value)

	elseif t == "boolean" or t == "number" or t == "string" then
		return value

	elseif t == "nil" then
		return "nil"

	else
		return "[Unsupported: " .. t .. "]"
	end
end

--// INTERNAL: LookingFor check (case-insensitive, optional partial match)
local function isMatch(instance, lookingFor, config)
	if not lookingFor then return false end

	local partial = config and config.PartialMatch
	local function lower(v) return string.lower(tostring(v)) end

	local t = typeof(lookingFor)

	-- String → match ClassName OR Name
	if t == "string" then
		local target = lower(lookingFor)
		if partial then
			return string.find(lower(instance.ClassName), target, 1, true)
				or string.find(lower(instance.Name), target, 1, true)
		else
			return lower(instance.ClassName) == target
				or lower(instance.Name) == target
		end
	end

	-- Instance → direct compare
	if t == "Instance" then
		return instance == lookingFor
	end

	-- Table → advanced matching
	if t == "table" then
		-- ClassName
		if lookingFor.ClassName then
			if partial then
				if not string.find(lower(instance.ClassName), lower(lookingFor.ClassName), 1, true) then
					return false
				end
			else
				if lower(instance.ClassName) ~= lower(lookingFor.ClassName) then
					return false
				end
			end
		end

		-- Name
		if lookingFor.Name then
			if partial then
				if not string.find(lower(instance.Name), lower(lookingFor.Name), 1, true) then
					return false
				end
			else
				if lower(instance.Name) ~= lower(lookingFor.Name) then
					return false
				end
			end
		end

		if lookingFor.ClassName or lookingFor.Name then
			return true
		end
	end

	return false
end

--// FUNCTION: Pretty Tree
function InstanceInspector.PrintTree(config)
	assert(config and config.Path, "Path is required")

	local root = config.Path
	local lookingFor = config.LookingFor

	warn("Tree for " .. root.Name)

	local function traverse(parent, prefix)
		local children = parent:GetChildren()

		for i, child in ipairs(children) do
			if not isExcluded(child, config) then
				local isLast = (i == #children)
				local connector = isLast and "└── " or "├── "
				local linePrefix = prefix .. connector

				local name = config.ReturnFullPath and child:GetFullName() or child.Name
				local line = linePrefix .. name .. " [" .. child.ClassName .. "]"

				-- LookingFor check
				if isMatch(child, lookingFor, config) then
					warn("FOUND → " .. line)
				else
					print(line)
				end

				local newPrefix = prefix .. (isLast and "    " or "│   ")
				traverse(child, newPrefix)
			end
		end
	end

	-- root print
	local rootLine = root.Name .. " [" .. root.ClassName .. "]"

	if isMatch(root, lookingFor, config) then
		warn("FOUND → " .. rootLine)
	else
		print(rootLine)
	end

	traverse(root, "")
end

--// FUNCTION: Get Tree
function InstanceInspector.GetTree(config)
	assert(config and config.Path, "Path is required")

	local root = config.Path
	warn("Tree for " .. root.Name) -- 🔥 execution header

	local results = {}

	local function traverse(parent)
		for _, child in ipairs(parent:GetChildren()) do
			if not isExcluded(child, config) then
				local value = config.ReturnFullPath and child:GetFullName() or child.Name

				table.insert(results, {
					Name = child.Name,
					ClassName = child.ClassName,
					Path = child:GetFullName(),
					Value = value,
					Instance = child
				})

				traverse(child)
			end
		end
	end

	traverse(root)

	return results
end

--// FUNCTION: Deep Property Scan
function InstanceInspector.GetProperties(instance, config)
	assert(instance, "Instance is required")

	warn("Properties for " .. instance.Name)

	local categorized = {}
	local allowDupes = config and config.AllowDuplicateProperties

	-- Attributes → custom category
	for name, value in pairs(instance:GetAttributes()) do
		categorized.Attributes = categorized.Attributes or {}

		handleDuplicate(
			categorized.Attributes,
			name,
			formatValue(value),
			allowDupes
		)
	end

	-- Categorized properties
	local categoryMap = getCategorizedProperties(instance)

	for category, propList in pairs(categoryMap) do
		categorized[category] = categorized[category] or {}

		for _, prop in ipairs(propList) do
			local ok, value = pcall(function()
				return instance[prop]
			end)

			if ok then
				handleDuplicate(
					categorized[category],
					prop,
					formatValue(value),
					allowDupes
				)
			end
		end
	end

	-- Metadata category
	categorized.Metadata = categorized.Metadata or {}

	handleDuplicate(categorized.Metadata, "ChildrenCount", #instance:GetChildren(), allowDupes)
	handleDuplicate(categorized.Metadata, "FullName", instance:GetFullName(), allowDupes)

	return categorized
end

--// FUNCTION: Print Properties
function InstanceInspector.PrintProperties(instance, config)
	local categorized = InstanceInspector.GetProperties(instance, config)
	local divider = (config and config.Divider) or " : "

	for category, props in pairs(categorized) do
		print("\n[" .. category .. "]")

		-- sort keys
		local keys = {}
		for k in pairs(props) do
			table.insert(keys, k)
		end
		table.sort(keys)

		for _, k in ipairs(keys) do
			local v = props[k]

			if type(v) == "table" then
				print("  " .. k .. divider .. table.concat(v, ", "))
			else
				print("  " .. k .. divider .. tostring(v))
			end
		end
	end
end

return InstanceInspector