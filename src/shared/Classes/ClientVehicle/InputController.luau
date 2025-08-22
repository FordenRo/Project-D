local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Context = ReplicatedStorage.Input.Vehicle

local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local PlayerModule = require(player.PlayerScripts.PlayerModule) :: any
local SettingsController = require(player.PlayerScripts.Client.Controllers.SettingsController)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local InputController = {}
InputController.__index = InputController

type InputController = VehicleTypes.InputController

function InputController.new(vehicle: VehicleTypes.ClientVehicle)
	local self: InputController = setmetatable({}, InputController) :: any

	self.Vehicle = vehicle

	self._cons = {}
	self._RawThrottle = 0
	self._RawBrake = 0

	self.Throttle = 0
	self.Brake = 0
	self.Clutch = 0
	self.Steering = 0
	self.MousePosition = Vector2.new(0.5, 1 - SettingsController:GetSetting("MSteerCursorY"))
	self.MouseSteerOn = false

	Context.TCS.Enabled = self.Vehicle.Tune.TCSEnabled
	Context.ABS.Enabled = self.Vehicle.Tune.ABSEnabled
	Context.CS.Enabled = self.Vehicle.Tune.CSEnabled

	PlayerModule:GetControls():GetActiveController().jumpEnabled = false
	Context.Enabled = true

	InitializeConnections(self)

	table.insert(self._cons, RunService.Heartbeat:Connect(function(deltaTime: number) Update(self, deltaTime) end))
	RunService:BindToRenderStep(
		"MouseSteerUpdate",
		Enum.RenderPriority.Camera.Value - 2,
		function() UpdateMouseInput(self) end
	)

	return self
end

function Update(self: InputController, deltaTime: number)
	Context.Enabled = not UserInputService:GetFocusedTextBox()

	UserInputService.MouseBehavior = self.MouseSteerOn and Enum.MouseBehavior.LockCenter
		or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and Enum.MouseBehavior.LockCurrentPosition
		or Enum.MouseBehavior.Default

	Context.Horn.Enabled = self.IsOn
	Context.Ignition.Enabled = not self.Broken
	Context.Clutch.Enabled = self.Vehicle.TransmissionMode == "Manual"

	Context.ControllerSteering.Enabled = not self.MouseSteerOn
	Context.TurnLeft.Enabled = not self.MouseSteerOn
	Context.TurnRight.Enabled = not self.MouseSteerOn
	Context.Throttle.Enabled = not self.MouseSteerOn
	Context.Brake.Enabled = not self.MouseSteerOn
	Context.MouseThrottle.Enabled = self.MouseSteerOn
	Context.MouseBrake.Enabled = self.MouseSteerOn

	local canShift = self.Vehicle.TransmissionMode == "Manual"
		or (
			self.Vehicle.IsOn
			and (
				self.Vehicle.TransmissionMode == "Semi"
				or (
					self.Vehicle.Tune.AutoShiftVers == "New"
					and self.Vehicle.TransmissionMode == "Auto"
					and self.Vehicle.Gear <= 1
				)
			)
		)
	Context.ShiftDown.Enabled = canShift
	Context.ShiftUp.Enabled = canShift

	SmoothInputs(self, deltaTime)
end

function SmoothInputs(self: InputController, deltaTime: number)
	deltaTime = (60 / (1 / deltaTime))
	if self.Throttle <= self._RawThrottle then
		self.Throttle = math.min(self._RawThrottle, self.Throttle + (self.Vehicle.Tune.ThrotAccel * deltaTime))
	else
		self.Throttle = math.max(self._RawThrottle, self.Throttle - (self.Vehicle.Tune.ThrotDecel * deltaTime))
	end
	if self.Brake <= self._RawBrake then
		self.Brake = math.min(self._RawBrake, self.Brake + (self.Vehicle.Tune.BrakeAccel * deltaTime))
	else
		self.Brake = math.max(self._RawBrake, self.Brake - (self.Vehicle.Tune.BrakeDecel * deltaTime))
	end
end

function UpdateMouseInput(self: InputController)
	if not self.MouseSteerOn or UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then return end

	local sensivity = SettingsController:GetSetting("MSteerSensivity") :: number
	local delta = UserInputService:GetMouseDelta() / UserSettings().GameSettings.MouseSensitivity
	local x = math.clamp(self.MousePosition.X + delta.X / mouse.ViewSizeX * sensivity, 0, 1)
	local y = 1 - SettingsController:GetSetting("MSteerCursorY") :: number
	self.MousePosition = Vector2.new(x, y)

	local mdZone = SettingsController:GetSetting("MSteerDZone") :: number
	local mST = (self.MousePosition.X - 0.5) / (SettingsController:GetSetting("MSteerWidth") :: number) * 2
	if math.abs(mST) <= mdZone then
		self.Steering = 0
	else
		self.Steering = (math.max(math.min((math.abs(mST) - mdZone), (1 - mdZone)), 0) / (1 - mdZone))
				^ self.Vehicle.Tune.MSteerExp
			* (mST / math.abs(mST))
	end
end

function InitializeConnections(self: InputController)
	local onChangeActions = {
		Throttle = function(value) self._RawThrottle = value end,
		Brake = function(value) self._RawBrake = value end,
		MouseThrottle = function(value) self._RawThrottle = value end,
		MouseBrake = function(value) self._RawBrake = value end,
		TurnLeft = function(value) self.Steering = -value end,
		TurnRight = function(value) self.Steering = value end,
		ControllerSteering = function(value: Vector2)
			local cDZone = math.min(0.99, self.Vehicle.Controls.ControllerDeadzone)
			if math.abs(value.X) > cDZone then
				self.Steering = MapToRange(math.abs(value.X), cDZone, 1) * math.sign(value.X)
			else
				self.Steering = 0
			end
		end,
		Clutch = function(value)
			self.Vehicle._ClutchPressing = value
			self.Clutch = value
		end,
		Handbrake = function(value)
			if value then
				self.Vehicle.PBrake = not self.Vehicle.PBrake
			else
				if self.Vehicle.Velocity.Magnitude > 5 then self.Vehicle.PBrake = false end
			end
		end,
		Horn = function(value) self.Vehicle.Horning = value end,
		Ignition = function(value)
			if self.Vehicle.IsOn and not self.Vehicle.Starting then
				if value then self.Vehicle.IsOn = false end
			else
				self.Vehicle.Starting = value
			end
		end,
	}

	local onPressActions = {
		TransmissionMode = function()
			local n = 1
			for i, v in self.Vehicle.Tune.TransModes do
				if v == self.Vehicle.TransmissionMode then
					n = i
					break
				end
			end
			n = n + 1
			if n > #self.Vehicle.Tune.TransModes then n = 1 end
			self.Vehicle.TransmissionMode = self.Vehicle.Tune.TransModes[n]
		end,
		ToggleMouseSteering = function()
			self.MouseSteerOn = not self.MouseSteerOn
			self.Steering = 0
		end,
		TCS = function()
			if self.Vehicle.Tune.ESCEnabled then
				if self.Vehicle.TCS and self.Vehicle.ESC then
					self.Vehicle.ESC = false
				elseif self.Vehicle.TCS and not self.Vehicle.ESC then
					self.Vehicle.TCS = false
				elseif not self.Vehicle.TCS and not self.Vehicle.ESC then
					self.Vehicle.TCS = true
					self.Vehicle.ESC = true
				end
			else
				self.Vehicle.TCS = not self.Vehicle.TCS
			end
		end,
		ABS = function() self.Vehicle.ABS = not self.Vehicle.ABS end,
		CS = function() self.Vehicle.CS = not self.Vehicle.CS end,
		ShiftDown = function() self.Vehicle._ShiftDown = true end,
		ShiftUp = function() self.Vehicle._ShiftUp = true end,
		Leave = function()
			local humanoid = (player.Character :: Model):FindFirstChildWhichIsA("Humanoid") :: Humanoid
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end,
	}

	for k, v in onChangeActions do
		local action = Context[k] :: InputAction
		table.insert(self._cons, action.StateChanged:Connect(v))
	end

	for k, v in onPressActions do
		local action = Context[k] :: InputAction
		table.insert(self._cons, action.Pressed:Connect(v))
	end
end

function InputController.Destroy(self: InputController)
	Context.Enabled = false

	for _, v in self._cons do
		v:Disconnect()
	end

	self._RawBrake = 0
	self._RawThrottle = 0
	self.Steering = 0

	PlayerModule:GetControls():GetActiveController().jumpEnabled = true
end

return InputController
