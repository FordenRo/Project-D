--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local PlayerModule =
	require((Players.LocalPlayer.PlayerScripts :: any).PlayerModule) :: any
local SettingsController =
	require(ReplicatedStorage.Shared.Controllers.SettingsController)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Context = ReplicatedStorage.Input.Vehicle

local InputController = {}
InputController.__index = InputController

type InputController = VehicleTypes.InputController

type InputControllerImpl = {
	trove: Trove.Trove,
	rawThrottle: number,
	rawBrake: number,
	rawClutch: number,
	rawSteering: number,
	ignitionNext: boolean,
} & InputController

function InputController.new(
	vehicle: VehicleTypes.ClientVehicle
): InputController
	local self: InputControllerImpl = setmetatable({}, InputController) :: any

	self.Vehicle = vehicle

	self.rawThrottle = 0
	self.rawBrake = 0
	self.rawClutch = 0
	self.rawSteering = 0
	self.ignitionNext = false

	self.MousePosition =
		Vector2.new(0.5, 1 - SettingsController:GetSetting("MSteerCursorY"))
	self.IsMouseSteerOn = false

	Context.TCS.Enabled = self.Vehicle.Tune.TCSEnabled
	Context.ABS.Enabled = self.Vehicle.Tune.ABSEnabled
	Context.CS.Enabled = self.Vehicle.Tune.CSEnabled
	Context.Enabled = true

	PlayerModule:GetControls():GetActiveController().jumpEnabled = false

	self.trove = Trove.new()
	self.trove:AttachToInstance(self.Vehicle.Instance)

	InitializeConnections(self)

	self.trove:Connect(
		RunService.Heartbeat,
		function(deltaTime) Update(self, deltaTime) end
	)
	self.trove:BindToRenderStep(
		"MouseSteerUpdate",
		Enum.RenderPriority.Camera.Value - 2,
		function() UpdateMouseInput(self) end
	)
	self.trove:Add(function()
		Context.Enabled = false

		self.rawBrake = 0
		self.rawThrottle = 0
		self.rawSteering = 0

		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		PlayerModule:GetControls():GetActiveController().jumpEnabled = true
	end)

	return self
end

function Update(self: InputControllerImpl, deltaTime: number)
	Context.Enabled = not UserInputService:GetFocusedTextBox()

	UserInputService.MouseBehavior = self.IsMouseSteerOn
			and Enum.MouseBehavior.LockCenter
		or UserInputService:IsMouseButtonPressed(
			Enum.UserInputType.MouseButton2
		) and Enum.MouseBehavior.LockCurrentPosition
		or Enum.MouseBehavior.Default

	Context.Horn.Enabled = self.Vehicle.IgnitionState == "On"
	Context.Ignition.Enabled = self.Vehicle.Engine.Health :: number > 0
	Context.Clutch.Enabled = self.Vehicle.TransmissionMode == "Manual"

	Context.ControllerSteering.Enabled = not self.IsMouseSteerOn
	Context.TurnLeft.Enabled = not self.IsMouseSteerOn
	Context.TurnRight.Enabled = not self.IsMouseSteerOn
	Context.Throttle.Enabled = not self.IsMouseSteerOn
	Context.Brake.Enabled = not self.IsMouseSteerOn
	Context.MouseThrottle.Enabled = self.IsMouseSteerOn
	Context.MouseBrake.Enabled = self.IsMouseSteerOn

	local canShift = self.Vehicle.TransmissionMode == "Manual"
		or (
			self.Vehicle.Engine.IsOn
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

	ApplyInputs(self, deltaTime)
end

function ApplyInputs(self: InputControllerImpl, deltaTime: number)
	-- Update throttle
	local throttle = (
		self.Vehicle.Tune.AutoShiftVers == "Old"
		and self.Vehicle.Gear == -1
		and self.Vehicle.TransmissionMode == "Manual"
	)
			and self.rawBrake
		or self.rawThrottle
	if self.Vehicle.Throttle <= throttle then
		self.Vehicle.Throttle = math.min(
			throttle,
			self.Vehicle.Throttle
				+ (
					1
					/ (SettingsController:GetSetting("ThrottlePressTime") / 1000)
					* deltaTime
				)
		)
	else
		self.Vehicle.Throttle = math.max(
			throttle,
			self.Vehicle.Throttle
				- (
					1
					/ (SettingsController:GetSetting("ThrottleReleaseTime") / 1000)
					* deltaTime
				)
		)
	end

	-- Update brake
	local brake = (
		self.Vehicle.Tune.AutoShiftVers == "Old"
		and self.Vehicle.Gear == -1
		and self.Vehicle.TransmissionMode == "Manual"
	)
			and self.rawThrottle
		or self.rawBrake
	if self.Vehicle.Brake <= brake then
		self.Vehicle.Brake = math.min(
			brake,
			self.Vehicle.Brake
				+ (
					1
					/ (SettingsController:GetSetting("BrakePressTime") / 1000)
					* deltaTime
				)
		)
	else
		self.Vehicle.Brake = math.max(
			brake,
			self.Vehicle.Brake
				- (
					1
					/ (SettingsController:GetSetting("BrakeReleaseTime") / 1000)
					* deltaTime
				)
		)
	end

	-- Update clutch
	if self.Vehicle.Clutch <= self.rawClutch then
		self.Vehicle.Clutch = math.min(
			self.rawClutch,
			self.Vehicle.Clutch
				+ (
					1
					/ (SettingsController:GetSetting("ClutchPressTime") / 1000)
					* deltaTime
				)
		)
	else
		self.Vehicle.Clutch = math.max(
			self.rawClutch,
			self.Vehicle.Clutch
				- (
					1
					/ (SettingsController:GetSetting("ClutchReleaseTime") / 1000)
					* deltaTime
				)
		)
	end

	ApplySteering(self, deltaTime)
end

function ApplySteering(self: InputControllerImpl, deltaTime: number)
	deltaTime = (60 / (1 / deltaTime))

	local isController = UserInputService.PreferredInput
			== Enum.PreferredInput.Gamepad
		or (self.Vehicle.Tune.MSteerUsesContlr and self.IsMouseSteerOn or false)

	local steerSpeed
	local returnSpeed
	if isController then
		steerSpeed = self.Vehicle.Tune.ContlrSteerSpeed > 0
				and self.Vehicle.Tune.ContlrSteerSpeed
			or self.Vehicle.Tune.SteerSpeed
		returnSpeed = self.Vehicle.Tune.ContlrReturnSpeed > 0
				and self.Vehicle.Tune.ContlrReturnSpeed
			or self.Vehicle.Tune.ReturnSpeed
	else
		steerSpeed = self.Vehicle.Tune.SteerSpeed
			* (
				1
				- math.min(
					self.Vehicle.Velocity.Magnitude
						/ (Units.Velocity_mdivs / 3.6)
						/ self.Vehicle.Tune.SteerSpeedDecay,
					1 - (self.Vehicle.Tune.MinSteerSpeed / 100)
				)
			)
		returnSpeed = self.Vehicle.Tune.ReturnSpeed
			* (
				1
				- math.min(
					self.Vehicle.Velocity.Magnitude
						/ (Units.Velocity_mdivs / 3.6)
						/ self.Vehicle.Tune.SteerSpeedDecay,
					1 - (self.Vehicle.Tune.MinSteerSpeed / 100)
				)
			)
	end

	--- Steer Decay Multiplier
	local sDecay = (
		1
		- math.min(
			self.Vehicle.Velocity.Magnitude
				/ (Units.Velocity_mdivs / 3.6)
				/ (self.Vehicle.Tune.SteerDecay / (Units.Velocity_mdivs / 3.6)),
			1 - (self.Vehicle.Tune.MinSteer / 100)
		)
	)

	-- Interpolate Steering
	local CSAmt = 0
	if
		math.abs(self.rawSteering) < self.Vehicle.Tune.CSSteerThresh / 100
		and self.Vehicle.CS
		and self.Vehicle.Velocity.Magnitude
				* (Units.Length_mm / 1000)
				* 3.6
			> self.Vehicle.Tune.CSSpeedThresh
	then
		CSAmt = (
			self.Vehicle.Center
				:VectorToObjectSpace(self.Vehicle.Velocity)
				:Dot(Vector3.new(1, 0, 0))
			/ math.max(
				self.Vehicle.Velocity.Magnitude * (Units.Length_mm / 1000) * 3.6,
				self.Vehicle.Tune.CSSpeedThresh
			)
		) * (self.Vehicle.Tune.CSAmt / 100)
	else
		CSAmt = 0
	end
	self.Vehicle.CSActive = math.abs(CSAmt)
		> (self.Vehicle.Tune.CSAmt / 100) * 0.01

	local SteerWithCounter =
		math.clamp(self.rawSteering * sDecay + CSAmt, -1, 1)
	local SteerSmoothing = math.clamp(
		math.abs(SteerWithCounter - self.Vehicle.Steering)
			^ (1 / math.max(self.Vehicle.Tune.SteerSmoothing, 0.001)),
		0,
		1
	)
	if self.Vehicle.Steering < SteerWithCounter then
		if self.Vehicle.Steering < 0 then
			self.Vehicle.Steering = math.min(
				SteerWithCounter,
				self.Vehicle.Steering
					+ (returnSpeed * SteerSmoothing * deltaTime)
			)
		else
			self.Vehicle.Steering = math.min(
				SteerWithCounter,
				self.Vehicle.Steering
					+ (steerSpeed * SteerSmoothing * deltaTime)
			)
		end
	else
		if self.Vehicle.Steering > 0 then
			self.Vehicle.Steering = math.max(
				SteerWithCounter,
				self.Vehicle.Steering
					- (returnSpeed * SteerSmoothing * deltaTime)
			)
		else
			self.Vehicle.Steering = math.max(
				SteerWithCounter,
				self.Vehicle.Steering
					- (steerSpeed * SteerSmoothing * deltaTime)
			)
		end
	end
end

function UpdateMouseInput(self: InputControllerImpl)
	if
		not self.IsMouseSteerOn
		or UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
	then
		return
	end

	local sensivity = SettingsController:GetSetting("MSteerSensivity") :: number
	local delta = UserInputService:GetMouseDelta()
		/ UserSettings().GameSettings.MouseSensitivity
	local x = math.clamp(
		self.MousePosition.X + delta.X / mouse.ViewSizeX * sensivity,
		0,
		1
	)
	local y = 1 - SettingsController:GetSetting("MSteerCursorY") :: number
	self.MousePosition = Vector2.new(x, y)

	local mdZone = SettingsController:GetSetting("MSteerDZone") :: number
	local mST = (self.MousePosition.X - 0.5)
		/ (SettingsController:GetSetting("MSteerWidth") :: number)
		* 2
	if math.abs(mST) <= mdZone then
		self.rawSteering = 0
	else
		self.rawSteering = (math.max(
			math.min((math.abs(mST) - mdZone), (1 - mdZone)),
			0
		) / (1 - mdZone)) ^ SettingsController:GetSetting("MSteerExp") * (mST / math.abs(
			mST
		))
	end
end

function InitializeConnections(self: InputControllerImpl)
	local lightController =
		self.Vehicle:GetController("LightController") :: VehicleTypes.ClientLights

	local onChangeActions = {
		Throttle = function(value) self.rawThrottle = value end,
		Brake = function(value) self.rawBrake = value end,
		MouseThrottle = function(value) self.rawThrottle = value end,
		MouseBrake = function(value) self.rawBrake = value end,
		TurnLeft = function(value) self.rawSteering = -value end,
		TurnRight = function(value) self.rawSteering = value end,
		ControllerSteering = function(value: Vector2)
			local cDZone =
				math.min(0.99, SettingsController:GetSetting("ControllerDZone"))
			if math.abs(value.X) > cDZone then
				self.rawSteering = MathUtil.Map(math.abs(value.X), cDZone, 1)
					* math.sign(value.X)
			else
				self.rawSteering = 0
			end
		end,
		Clutch = function(value) self.rawClutch = value end,
		Handbrake = function(value)
			if value then
				self.Vehicle.PBrake = not self.Vehicle.PBrake
			else
				if self.Vehicle.Velocity.Magnitude > 5 then
					self.Vehicle.PBrake = false
				end
			end
		end,
		Horn = function(value) self.Vehicle.Horning = value end,
		Ignition = function(value)
			local state = self.Vehicle.IgnitionState
			if value then
				if state == "On" then
					self.Vehicle.IgnitionState = if self.ignitionNext
						then "Off"
						else "Starting"
					self.ignitionNext = not self.ignitionNext
				else
					self.Vehicle.IgnitionState = if state == "Off"
						then "Acc"
						else "On"
				end
			elseif state == "Starting" then
				self.Vehicle.IgnitionState = "On"
			end

			if state ~= self.Vehicle.IgnitionState then
				self.Vehicle.IgnitionStateChanged:Fire(
					self.Vehicle.IgnitionState
				)
			end
		end,
	} :: { [string]: (any) -> () }

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
			self.IsMouseSteerOn = not self.IsMouseSteerOn
			self.rawSteering = 0
		end,
		ToggleFirstPersonView = function()
			self.CameraMode = if self.CameraMode == "FirstPerson"
				then "ThirdPerson"
				else "FirstPerson"
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
		ShiftDown = function() self.Vehicle.Transmission.ShiftingDown = true end,
		ShiftUp = function() self.Vehicle.Transmission.ShiftingUp = true end,
		Leave = function() self.Vehicle:Leave() end,

		Lights = function() lightController:ToggleLights() end,
		LeftTurnSignal = function() lightController:ToggleTurnState("Left") end,
		RightTurnSignal = function() lightController:ToggleTurnState("Right") end,
		Hazards = function() lightController:ToggleTurnState("Both") end,
	} :: { [string]: () -> () }

	for k, v in onChangeActions do
		local action = Context:FindFirstChild(k) :: InputAction
		self.trove:Connect(action.StateChanged, v)
	end

	for k, v in onPressActions do
		local action = Context:FindFirstChild(k) :: InputAction
		self.trove:Connect(action.Pressed, v)
	end
end

function InputController.Destroy(self: InputControllerImpl) self.trove:Destroy() end

return table.freeze({ new = InputController.new })
