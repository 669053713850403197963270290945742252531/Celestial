local cameraLib = {
    Freecam = {}
}

-- Calcuations

local exp = math.exp
local rad = math.rad
local sign = math.sign
local sqrt = math.sqrt
local tan = math.tan

-- Services

local contextActionService = game:GetService("ContextActionService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local starterGui = game:GetService("StarterGui")
local userInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local player = players.LocalPlayer

if not player then
	players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = players.LocalPlayer
end

local camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = workspace.CurrentCamera

	if newCamera then
		camera = newCamera
	end
end)

-- Constants

local inputPriority = Enum.ContextActionPriority.High.Value

local navGain = Vector3.new(1, 1, 1)*64
local panGain = Vector2.new(0.75, 1)*8

local pitchLimit = rad(90)
local velStiffness = 1.5
local panStiffness = 1.0
local fovStiffness = 4.0

-- Spring class

local spring = {} do
	spring.__index = spring

	function spring.new(freq, pos)
		local self = setmetatable({}, spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function spring:Update(dt, goal)
		local f = self.f*2*math.pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end

-- Camera

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 0

local velSpring = spring.new(velStiffness, Vector3.new())
local panSpring = spring.new(panStiffness, Vector2.new())
local fovSpring = spring.new(fovStiffness, 0)

-- Input

local input = {} do
	local thumbstickCurve do
		local kCurvature = 2.0
		local kDeadZone = 0.15

		local function fCurve(x)
			return (exp(kCurvature * x) - 1) / (exp(kCurvature) - 1)
		end

		local function fDeadzone(x)
			return fCurve((x - kDeadZone)/(1 - kDeadZone))
		end

		function thumbstickCurve(x)
			return sign(x) * math.clamp(fDeadzone(math.abs(x)), 0, 1)
		end
	end

	local gamepad = {
		ButtonX = 0,
		ButtonY = 0,
		DPadDown = 0,
		DPadUp = 0,
		ButtonL2 = 0,
		ButtonR2 = 0,
		Thumbstick1 = Vector2.new(),
		Thumbstick2 = Vector2.new(),
	}

	local keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		U = 0,
		H = 0,
		J = 0,
		K = 0,
		I = 0,
		Y = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
		RightShift = 0,
	}

	local mouse = {
		Delta = Vector2.new(),
		MouseWheel = 0,
	}

	local navGamepadSpeed  = Vector3.new(1, 1, 1)
	local navKeyboardSpeed = Vector3.new(1, 1, 1)
	local panMouseSpeed    = Vector2.new(1.5, 1.5)*(math.pi/10)
	local panGamepadSpeed  = Vector2.new(1, 1)*(math.pi/8)
	local fovWheelSpeed    = 1.0
	local fovGamepadSpeed  = 0.25
	local navAdjSpeed      = 0.75
	local navShiftMul      = 0.25
	local navSpeed = 1

	function input.vel(dt)
		navSpeed = math.clamp(navSpeed + dt * (keyboard.Up - keyboard.Down) * navAdjSpeed, 0.01, 4)

		local kGamepad = Vector3.new(thumbstickCurve(gamepad.Thumbstick1.x), thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2), thumbstickCurve(-gamepad.Thumbstick1.y)) * navGamepadSpeed
		local kKeyboard = Vector3.new(keyboard.D - keyboard.A + keyboard.K - keyboard.H, keyboard.E - keyboard.Q + keyboard.I - keyboard.Y, keyboard.S - keyboard.W + keyboard.J - keyboard.U) * navKeyboardSpeed
		local shift = userInputService:IsKeyDown(Enum.KeyCode.LeftShift) or userInputService:IsKeyDown(Enum.KeyCode.RightShift)

		return (kGamepad + kKeyboard) * (navSpeed * (shift and navShiftMul or 1))
	end

	function input.pan(dt)
		local kGamepad = Vector2.new(thumbstickCurve(gamepad.Thumbstick2.y), thumbstickCurve(-gamepad.Thumbstick2.x)) * panGamepadSpeed
		local kMouse = mouse.Delta * panMouseSpeed
		mouse.Delta = Vector2.new()

		return kGamepad + kMouse
	end

	function input.fov(dt)
		local kGamepad = (gamepad.ButtonX - gamepad.ButtonY) * fovGamepadSpeed
		local kMouse = mouse.MouseWheel * fovWheelSpeed
		mouse.MouseWheel = 0

		return kGamepad + kMouse
	end

    do
		local function keypress(action, state, input)
			keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		local function gpButton(action, state, input)
			gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		local function mousePan(action, state, input)
			local delta = input.Delta
			mouse.Delta = Vector2.new(- delta.y, - delta.x)
			return Enum.ContextActionResult.Sink
		end

		local function thumb(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position
			return Enum.ContextActionResult.Sink
		end

		local function trigger(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position.z
			return Enum.ContextActionResult.Sink
		end

		local function mouseWheel(action, state, input)
			mouse[input.UserInputType.Name] = - input.Position.z
			return Enum.ContextActionResult.Sink
		end

		local function zero(t)
			for k, v in pairs(t) do
				t[k] = v*0
			end
		end

		function input.startCapture()
			contextActionService:BindActionAtPriority("FreecamKeyboard", keypress, false, inputPriority,
				Enum.KeyCode.W, Enum.KeyCode.U,
				Enum.KeyCode.A, Enum.KeyCode.H,
				Enum.KeyCode.S, Enum.KeyCode.J,
				Enum.KeyCode.D, Enum.KeyCode.K,
				Enum.KeyCode.E, Enum.KeyCode.I,
				Enum.KeyCode.Q, Enum.KeyCode.Y,
				Enum.KeyCode.Up, Enum.KeyCode.Down,
                Enum.KeyCode.Space
			)

			contextActionService:BindActionAtPriority("FreecamMousePan", mousePan, false, inputPriority, Enum.UserInputType.MouseMovement)
			contextActionService:BindActionAtPriority("FreecamMouseWheel", mouseWheel, false, inputPriority, Enum.UserInputType.MouseWheel)
			contextActionService:BindActionAtPriority("FreecamGamepadButton", gpButton, false, inputPriority, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
			contextActionService:BindActionAtPriority("FreecamGamepadTrigger", trigger, false, inputPriority, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
			contextActionService:BindActionAtPriority("FreecamGamepadThumbstick", thumb, false, inputPriority, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
		end

		function input.stopCapture()
			navSpeed = 1
			zero(gamepad)
			zero(keyboard)
			zero(mouse)

			contextActionService:UnbindAction("FreecamKeyboard")
			contextActionService:UnbindAction("FreecamMousePan")
			contextActionService:UnbindAction("FreecamMouseWheel")
			contextActionService:UnbindAction("FreecamGamepadButton")
			contextActionService:UnbindAction("FreecamGamepadTrigger")
			contextActionService:UnbindAction("FreecamGamepadThumbstick")
		end
	end
end

local function getFocusDistance(cameraFrame)
	local znear = 0.1
	local viewport = camera.ViewportSize
	local projY = 2 * tan(cameraFov/2)
	local projX = viewport.x / viewport.y * projY
	local fx = cameraFrame.rightVector
	local fy = cameraFrame.upVector
	local fz = cameraFrame.lookVector

	local minVect = Vector3.new()
	local minDist = 512

	for x = 0, 1, 0.5 do
		for y = 0, 1, 0.5 do
			local cx = (x - 0.5) * projX
			local cy = (y - 0.5) * projY
			local offset = fx * cx - fy * cy + fz
			local origin = cameraFrame.p + offset * znear
			local _, hit = workspace:FindPartOnRay(Ray.new(origin, offset.unit * minDist))
			local dist = (hit - origin).magnitude
            
			if minDist > dist then
				minDist = dist
				minVect = offset.unit
			end
		end
	end

	return fz:Dot(minVect)*minDist
end

------------------------------------------------------------------------

local function stepFreecam(dt)
	local vel = velSpring:Update(dt, input.vel(dt))
	local pan = panSpring:Update(dt, input.pan(dt))
	local fov = fovSpring:Update(dt, input.fov(dt))

	local zoomFactor = sqrt(tan(rad(70 / 2)) / tan(rad(cameraFov / 2)))

	cameraFov = math.clamp(cameraFov + fov * (dt/zoomFactor), 1, 120)
	cameraRot = cameraRot + pan * panGain * (dt / zoomFactor)
	cameraRot = Vector2.new(math.clamp(cameraRot.x, - pitchLimit, pitchLimit), cameraRot.y % (2 * math.pi))

	local cameraCFrame = CFrame.new(cameraPos) * CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0) * CFrame.new(vel * navGain * dt)
	cameraPos = cameraCFrame.p

	camera.CFrame = cameraCFrame
	camera.Focus = cameraCFrame * CFrame.new(0, 0, - getFocusDistance(cameraCFrame))
	camera.FieldOfView = cameraFov
end

------------------------------------------------------------------------

local playerState = {} do
	local mouseBehavior
	local mouseIconEnabled
	local cameraType
	local cameraFocus
	local cameraCFrame
	local cameraFieldOfView
	local screenGuis = {}

	-- Save state and setup freecam

	function playerState.push()
		local playergui = player:FindFirstChildOfClass("PlayerGui")

		if playergui then

			for _, gui in pairs(playergui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.Enabled then
					screenGuis[#screenGuis + 1] = gui
					gui.Enabled = false
				end
			end

		end

		cameraFieldOfView = camera.FieldOfView
		camera.FieldOfView = 70

		cameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Custom

		cameraCFrame = camera.CFrame
		cameraFocus = camera.Focus

		mouseIconEnabled = userInputService.MouseIconEnabled
		userInputService.MouseIconEnabled = false

		mouseBehavior = userInputService.MouseBehavior
		userInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	-- Restore state

	function playerState.pop()
		for _, gui in pairs(screenGuis) do
			if gui.Parent then
				gui.Enabled = true
			end
		end

		camera.FieldOfView = cameraFieldOfView
		cameraFieldOfView = nil

		camera.CameraType = cameraType
		cameraType = nil

		camera.CFrame = cameraCFrame
		cameraCFrame = nil

		camera.Focus = cameraFocus
		cameraFocus = nil

		userInputService.MouseIconEnabled = mouseIconEnabled
		mouseIconEnabled = nil

		userInputService.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end
end

local function startFreecam()
	local cameraCFrame = camera.CFrame
	cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
	cameraPos = cameraCFrame.p
	cameraFov = camera.FieldOfView

	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())
	fovSpring:Reset(0)

	playerState.push()
	runService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, stepFreecam)
	input.startCapture()
end

local function stopFreecam()
	input.stopCapture()
	runService:UnbindFromRenderStep("Freecam")
	playerState.pop()
end

-- Global Functions

function cameraLib.Freecam:enable()
    startFreecam()
    print("started freecam")
end

function cameraLib.Freecam:disable()
    stopFreecam()

    navGain = Vector3.new(1, 1, 1)*64
    panGain = Vector2.new(0.75, 1)*8
    print("disabled freecam")
end

function cameraLib.Freecam:updateSpeed(newNavGain)
    navGain = Vector3.new(1, 1, 1)*newNavGain
    wait(0.1)
    print("set speed to: ", navGain)
end

function cameraLib.Freecam:updatePanSpeed(newPanGain)
    panGain = Vector2.new(0.75, 1)*newPanGain
    wait(0.1)
    print("set pan speed: ", panGain)
end

cameraLib.fetchCamera = function()
    return workspace.CurrentCamera
end

return cameraLib