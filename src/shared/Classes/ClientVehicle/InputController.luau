local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer
local Context = ReplicatedStorage.Input.Vehicle

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

	Context.TCS.Enabled = self.Vehicle.Tune.TCSEnabled
	Context.ABS.Enabled = self.Vehicle.Tune.ABSEnabled
	Context.CS.Enabled = self.Vehicle.Tune.CSEnabled
	Context.Enabled = true

	InitializeConnections(self)

	table.insert(self._cons, RunService.Heartbeat:Connect(function(deltaTime: number) Update(self, deltaTime) end))

	return self
end

function Update(self: InputController, deltaTime: number)
	Context.Enabled = not UserInputService:GetFocusedTextBox()
	Context.Horn.Enabled = self.IsOn
	Context.Ignition.Enabled = not self.Broken
	Context.Clutch.Enabled = self.Vehicle.TransmissionMode == "Manual"

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

function InitializeConnections(self: InputController)
	local onChangeActions = {
		Throttle = function(value) self._RawThrottle = value end,
		Brake = function(value) self._RawBrake = value end,
		Steering = function(value: Vector2)
			if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
				local cDZone = math.min(0.99, self.Vehicle.Controls.ControllerDeadzone)
				if math.abs(value.X) > cDZone then
					self.Vehicle.SteerT = MapToRange(math.abs(value.X), cDZone, 1) * math.sign(value.X)
				else
					self.Vehicle.SteerT = 0
				end
			else
				self.Vehicle.SteerT = value.X
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
			self.Vehicle.MouseSteerOn = not self.Vehicle.MouseSteerOn
			self.Vehicle.SteerT = 0
			self._RawThrottle = 0
			self._RawBrake = 0
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
	self.Vehicle.SteerT = 0
end

return InputController
