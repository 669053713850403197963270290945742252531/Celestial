local ESPLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSESP/refs/heads/main/source.luau"))()
local killersFolder = workspace:WaitForChild("Killers")

local tracked = {}

local config = {
	textsize = 16,
	maxdistance = 150,

	esptype = "Highlight",

	filltrans = 0.8,
	outlinetrans = 0.3,

	boxtype = "3D",
	boxthickness = 2,

	tracers = true,
	arrows = true,
	dynamiccolor = true, -- change color based on npc health
}

ESPLibrary.GlobalConfig.Rainbow = false

local function getboxtype(boxType)
	return config.boxtype == boxType
end

local function isAlive(model)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	return humanoid and humanoid.Parent and humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead
end

local function waitForHumanoid(model, timeout)
	local start = os.clock()

	repeat
		local humanoid = model:FindFirstChildWhichIsA("Humanoid")

		if humanoid then
			return humanoid
		end

		task.wait(0.1)
	until os.clock() - start > timeout

	return nil
end

local function partAdded(model)
	if not model:IsA("Model") then
		return
	end

	if tracked[model] then
		return
	end

	task.spawn(function()
		local humanoid = waitForHumanoid(model, 10)

		if not humanoid then
			warn("No humanoid for", model:GetFullName())
			return
		end

		local esp
		local destroyed = false

		local function destroyESP()
			if destroyed then
				return
			end

			destroyed = true
			tracked[model] = nil

			if esp then
				esp:Destroy()
			end
		end

		-- Reject dead killers before creating the ESP

		if not isAlive(model) then
			warn("Dead killer detected, not applying esp for ", model.Name)
			return
		end

		esp = ESPLibrary:Add({
			Name = model.Name,
			Model = model,
			TextModel = model:FindFirstChild("Head"),

			Color = Color3.fromRGB(255, 0, 0),
			MaxDistance = config.maxdistance,

			StudsOffset = Vector3.new(0, 4, 0),
			TextSize = config.textsize,

			ESPType = config.esptype,
			FillTransparency = config.filltrans,
			OutlineTransparency = config.outlinetrans,

			BeforeUpdate = function(self)
				if destroyed then
					return
				end

				if not humanoid.Parent then
					destroyESP()
					return
				end

				local hp = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 0

				local health = math.floor(humanoid.Health + 0.5)

				self.CurrentSettings.Name = ("%s\n%d HP (%d%%)"):format(model.Name, health, math.floor(hp * 100 + 0.5))

				local color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)

				self:SetEveryColor(color, true)
			end,

			Box3D = {
				Enabled = getboxtype("3D"),
				Color = Color3.fromRGB(255, 0, 0),
				Thickness = config.boxthickness,
			},

			Box2D = {
				Enabled = getboxtype("2D"),
				Color = Color3.fromRGB(255, 0, 0),
				Thickness = config.boxthickness,
				Filled = false,
			},

			Tracer = {
				Enabled = config.tracers,
				Color = Color3.fromRGB(255, 0, 0),
				From = "Mouse",
			},

			Arrow = {
				Enabled = config.arrows,
				Color = Color3.fromRGB(255, 0, 0),
			},
		})

		tracked[model] = esp
		print(
			"ESP Added:",
			model.Name,
			model:FindFirstChildWhichIsA("Humanoid"),
			model:FindFirstChild("HumanoidRootPart")
		)

		humanoid.Died:Connect(destroyESP)

		model.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				destroyESP()
			end
		end)
	end)
end

for _, model in ipairs(killersFolder:GetChildren()) do
	partAdded(model)
end

killersFolder.ChildAdded:Connect(partAdded)