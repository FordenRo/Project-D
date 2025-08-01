local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DeformationController = require(script.DeformationController)
local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleInterface = require(ReplicatedStorage.Shared.UI.VehicleInterface)
local Wheel = require(script.Wheel)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local DatastoreController = require(player.PlayerScripts.Client.Controllers.DatastoreController)

local ClientVehicle = {}
ClientVehicle.__index = ClientVehicle

type ClientVehicle = Types.ClientVehicle

-- TODO
local _InControls = false

function ClientVehicle.new(instance: Instance)
	local self: Types.ClientVehicle = setmetatable({}, ClientVehicle) :: any

	self.Instance = instance :: any
	self.Tune = require(
		assert(
			ReplicatedStorage.Shared.Vehicle.Tunes:FindFirstChild(instance.Name),
			"Tune not found for vehicle: " .. instance.Name
		)
	)

	self:Initialize()
	self._Remote = self.Instance:WaitForChild("_VehicleRemote") :: UnreliableRemoteEvent

	self.DeformationController = DeformationController.new(self)
	self.Interface = VehicleInterface.new(self)

	return self
end

function ClientVehicle.Initialize(self: ClientVehicle)
	self:InitializeVariables()
	self:InitializeWheels()
	self:InitControls()
	self:InitializePlugins()

	table.insert(self._conn, RunService.Heartbeat:Connect(function(deltaTime) self:Update(deltaTime) end))
	self._task = task.spawn(function()
		while task.wait(1 / 8) do
			self:SlowUpdate()
		end
	end)
end

function ClientVehicle.InitializeVariables(self: ClientVehicle)
	self.ParkingGearEnabled = self.Tune.Ratios[1] == 0
	self.BrakeForce = {
		Front = self.Tune.BrakeForce * 9.80665 * Units.Force_N * self.Tune.BrakeBias,
		Rear = self.Tune.BrakeForce * 9.80665 * Units.Force_N * (1 - self.Tune.BrakeBias),
	}
	self.PBrakeForce = {
		Front = self.Tune.PBrakeForce * 9.80665 * Units.Force_N * self.Tune.PBrakeBias,
		Rear = self.Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - self.Tune.PBrakeBias),
	}
	self.Plugins = {}
	self._conn = {}
	self.WheelCount = { Front = 0, Rear = 0 }
	self.Wheels = {}
	self.DriveWheels = {}
	self.Occupant = nil
	self.Clutch = 0
	self.Broken = false
	self.Gear = self.ParkingGearEnabled and -2 or 0
	self.FinalDrive = self.Tune.FinalDrive * self.Tune.FDMult
	self.FinalDriveRatio = self.FinalDrive * 30 / math.pi
	self.Starting = false
	self.Shifting = false
	self._ShiftUp = false
	self._ShiftDown = false
	self._ClutchPressing = false
	self._InputClutch = false
	self._GoalRPM = 0
	self._DriveWheelSpeed = 0
	self.CurrentRatio = self.Tune.Ratios[self.Gear + 2 + (self.ParkingGearEnabled and 1 or 0)]
	self._CanStall = false
	self.AutoClutch = false
	self.TransmissionMode = "Manual"
	self.CurrentRatio = 0
	self.RPM = 0
	self.Boost = 0
	self.BoostTurbo = 0
	self.BoostSuper = 0
	self.HpNatural = 0
	self.HpElectric = 0
	self.HpTurbo = 0
	self.HpBoosted = 0
	self.Horsepower = 0
	self.TqNatural = 0
	self.TqElectric = 0
	self.TqTurbo = 0
	self.TqBoosted = 0
	self.Torque = 0
	self.Throttle = 0
	self.InputThrottle = 0
	self._InThrot = 0
	self.Brake = 0
	self.InputBrake = 0
	self._InBrake = 0
	self.SteerC = 0
	self.Fuel = self.Tune.FuelCapacity
	self.Temperature = game.Workspace:GetAttribute("GlobalTemperature") :: number
	self.FanSpeed = 0
	self.SteerT = 0
	self._LastOffTime = tick()
	self._SteerL = false
	self._SteerR = false
	self.MouseSteerOn = false
	self.PBrake = false
	self.Velocity = Vector3.new()
	self.AngularVelocity = Vector3.new()
	self._OldVelocity = Vector3.new()
	self.AverageRotSpeed = 0
	self.Acceleration = Vector3.new()
	self.Center = CFrame.new()
	self.TCS = self.Tune.TCSEnabled
	self.TCSActive = false
	self.ABS = self.Tune.ABSEnabled
	self.ABSActive = false
	self.ESC = self.Tune.ESCEnabled and self.Tune.TCSEnabled
	self.ESCActive = false
	self.CS = self.Tune.CSEnabled
	self.CSActive = false
	self.IsOn = self.Tune.AutoStart and (self.Tune.Engine or self.Tune.Electric)
	self._MaxSpin = 0
	self._LastInputWasGamepad = string.find(UserInputService:GetLastInputType().Name, "Gamepad") and true or false
	self.Mileage = 0
end

function ClientVehicle.InitializeWheels(self: ClientVehicle)
	for _, v in self.Instance.Wheels:GetChildren() do
		if
			not v:IsA("BasePart")
			or not (
				v.Name == "FL"
				or v.Name == "FR"
				or v.Name == "F"
				or v.Name == "RL"
				or v.Name == "RR"
				or v.Name == "R"
			)
		then
			continue
		end

		local wheel = Wheel.new(self, v)
		self.WheelCount.Front += wheel.IsFront and 1 or 0
		self.WheelCount.Rear += not wheel.IsFront and 1 or 0

		table.insert(self.Wheels, wheel)
		if wheel.IsDriven then table.insert(self.DriveWheels, wheel) end
	end
end

function ClientVehicle.InitializePlugins(self: ClientVehicle)
	for _, plugin in ReplicatedStorage.Shared.Vehicle.Plugins:GetChildren() do
		local pluginClass = require(plugin)
		if pluginClass and pluginClass.new then self.Plugins[plugin.Name] = pluginClass.new(self) end
	end
end

-- TODO: Add VirtualInput & Mobile
function ClientVehicle.InitControls(self: ClientVehicle)
	self.Controls = DatastoreController:GetControls()

	-- Disable jumping
	require(player.PlayerScripts.PlayerModule :: any):GetControls():GetActiveController().jumpEnabled = false

	table.insert(self._conn, UserInputService.InputBegan:Connect(function(input) self:OnInput(input) end))
	table.insert(self._conn, UserInputService.InputChanged:Connect(function(input) self:OnInput(input) end))
	table.insert(self._conn, UserInputService.InputEnded:Connect(function(input) self:OnInput(input) end))
	table.insert(
		self._conn,
		UserInputService.LastInputTypeChanged:Connect(function(inputType) self:OnLastInputTypeChanged(inputType) end)
	)
	-- if VirtualInputEnabled then VirtualInput.Event:Connect(self.OnInput) end

	-- if self.Tune.Mobile then self:OnMobileInput() end
end

-- function ClientVehicle.DeadzoneAdjust(self: ClientVehicle)
-- 	local _PPH = self.Tune.Peripherals
-- 	for i, v in _PPH do
-- 		local a = Instance.new("IntValue", Controls)
-- 		a.Name = i
-- 		a.Value = v
-- 		a.Changed:connect(function()
-- 			a.Value = math.min(100, math.max(0, a.Value))
-- 			_PPH[i] = a.Value
-- 		end)
-- 	end
-- end

function ClientVehicle.OnInput(self: ClientVehicle, input: InputObject)
	if ((UserInputService:GetFocusedTextBox() :: TextBox?) == nil) and not _InControls then --Ignore when UI Focus
		--Shift Down [Manual Transmission]
		if
			(
				input.KeyCode == self.Controls.ContlrShiftDown
				or (self.MouseSteerOn and input.KeyCode == self.Controls.MouseShiftDown)
				or ((not self.MouseSteerOn) and input.KeyCode == self.Controls.ShiftDown)
			)
			and ((self.IsOn and ((self.TransmissionMode == "Auto" and self.Gear <= 1) and self.Tune.AutoShiftVers == "New") or self.TransmissionMode == "Semi") or self.TransmissionMode == "Manual")
			and input.UserInputState == Enum.UserInputState.Begin
		then
			if not self._ShiftDown then self._ShiftDown = true end

		--Shift Up [Manual Transmission]
		elseif
			(
				input.KeyCode == self.Controls.ContlrShiftUp
				or (self.MouseSteerOn and input.KeyCode == self.Controls.MouseShiftUp)
				or ((not self.MouseSteerOn) and input.KeyCode == self.Controls.ShiftUp)
			)
			and ((self.IsOn and ((self.TransmissionMode == "Auto" and self.Gear < 1) and self.Tune.AutoShiftVers == "New") or self.TransmissionMode == "Semi") or self.TransmissionMode == "Manual")
			and input.UserInputState == Enum.UserInputState.Begin
		then
			if not self._ShiftUp then self._ShiftUp = true end

		--Toggle Clutch
		elseif
			(
				input.KeyCode == self.Controls.ContlrClutch
				or (self.MouseSteerOn and input.KeyCode == self.Controls.MouseClutch)
				or ((not self.MouseSteerOn) and input.KeyCode == self.Controls.Clutch)
			) and self.TransmissionMode == "Manual"
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self._ClutchPressing = true
				self._InputClutch = true
			elseif input.UserInputState == Enum.UserInputState.End then
				self._ClutchPressing = false
				self._InputClutch = false
			end

		--Toggle PBrake
		elseif
			input.KeyCode == self.Controls.ContlrPBrake
			or (self.MouseSteerOn and input.KeyCode == self.Controls.MousePBrake)
			or ((not self.MouseSteerOn) and input.KeyCode == self.Controls.PBrake)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.PBrake = not self.PBrake
			elseif input.UserInputState == Enum.UserInputState.End then
				if self.Velocity.Magnitude > 5 then self.PBrake = false end
			end

		--Toggle Transmission Mode
		elseif
			(input.KeyCode == self.Controls.ContlrToggleTMode or input.KeyCode == self.Controls.ToggleTransMode)
			and input.UserInputState == Enum.UserInputState.Begin
		then
			local n = 1
			for i, v in self.Tune.TransModes do
				if v == self.TransmissionMode then
					n = i
					break
				end
			end
			n = n + 1
			if n > #self.Tune.TransModes then n = 1 end
			self.TransmissionMode = self.Tune.TransModes[n]

		--Throttle
		elseif
			(
				not self.MouseSteerOn
				and (input.KeyCode == self.Controls.Throttle or input.KeyCode == self.Controls.Throttle2)
			)
			or (
				(
					(
						(self.Controls.MouseThrottle:IsA("UserInputType"))
						and input.UserInputType == self.Controls.MouseThrottle
					)
					or (self.Controls.MouseThrottle:IsA("KeyCode") and input.KeyCode == self.Controls.MouseThrottle)
				) and self.MouseSteerOn
			)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.InputThrottle = 1
			else
				self.InputThrottle = 0
			end

		--Brake
		elseif
			(not self.MouseSteerOn and (input.KeyCode == self.Controls.Brake or input.KeyCode == self.Controls.Brake2))
			or (
				(
					(
						(self.Controls.MouseBrake:IsA("UserInputType"))
						and input.UserInputType == self.Controls.MouseBrake
					)
					or (self.Controls.MouseBrake:IsA("KeyCode") and input.KeyCode == self.Controls.MouseBrake)
				) and self.MouseSteerOn
			)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.InputBrake = 1
			else
				self.InputBrake = 0
			end

		--Steer Left
		elseif
			not self.MouseSteerOn
			and (input.KeyCode == self.Controls.SteerLeft or input.KeyCode == self.Controls.SteerLeft2)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.SteerT = -1
				self._SteerL = true
			else
				if self._SteerR then
					self.SteerT = 1
				else
					self.SteerT = 0
				end
				self._SteerL = false
			end

		--Steer Right
		elseif
			not self.MouseSteerOn
			and (input.KeyCode == self.Controls.SteerRight or input.KeyCode == self.Controls.SteerRight2)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.SteerT = 1
				self._SteerR = true
			else
				if self._SteerL then
					self.SteerT = -1
				else
					self.SteerT = 0
				end
				self._SteerR = false
			end

		--Toggle Mouse Controls
		elseif input.KeyCode == self.Controls.ToggleMouseDrive then
			if input.UserInputState == Enum.UserInputState.End then
				self.MouseSteerOn = not self.MouseSteerOn
				self.InputThrottle = 0
				self.InputBrake = 0
				self.SteerT = 0
			end

		-- Ignition
		elseif input.KeyCode == self.Controls.Ignition and not self.Broken then
			if self.IsOn and not self.Starting then
				if input.UserInputState == Enum.UserInputState.Begin then self.IsOn = false end
			else
				self.Starting = input.UserInputState == Enum.UserInputState.Begin
			end

		-- Leaving the vehicle
		elseif input.KeyCode == self.Controls.Leave then
			if input.UserInputState == Enum.UserInputState.Begin then
				local humanoid = (player.Character :: Model):FindFirstChildWhichIsA("Humanoid") :: Humanoid
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end

		-- Horn
		elseif input.KeyCode == self.Controls.Horn then
			self.Horning = input.UserInputState == Enum.UserInputState.Begin

		--Toggle TCS and ESC
		elseif
			self.Tune.TCSEnabled
			and self.IsOn
			and (input.KeyCode == self.Controls.ToggleTCS or input.KeyCode == self.Controls.ContlrToggleTCS)
		then
			if input.UserInputState == Enum.UserInputState.End then
				if self.Tune.ESCEnabled then
					if self.TCS and self.ESC then
						self.ESC = false
					elseif self.TCS and not self.ESC then
						self.TCS = false
					elseif not self.TCS and not self.ESC then
						self.TCS = true
						self.ESC = true
					end
				else
					self.TCS = not self.TCS
				end
			end

		--Toggle ABS
		elseif
			self.Tune.ABSEnabled
			and self.IsOn
			and (input.KeyCode == self.Controls.ToggleABS or input.KeyCode == self.Controls.ContlrToggleABS)
		then
			if input.UserInputState == Enum.UserInputState.End then self.ABS = not self.ABS end

		--Toggle CS
		elseif
			self.Tune.CSEnabled
			and self.IsOn
			and (input.KeyCode == self.Controls.ToggleCS or input.KeyCode == self.Controls.ContlrToggleCS)
		then
			if input.UserInputState == Enum.UserInputState.End then self.CS = not self.CS end
		end

		--Variable Controls
		if input.UserInputType and input.UserInputType.Name:find("Gamepad") then
			--Gamepad Steering
			if input.KeyCode == self.Controls.ContlrSteer then
				if input.Position.X >= 0 then
					local cDZone = math.min(0.99, self.Controls.ControlRDZone / 100)
					if math.abs(input.Position.X) > cDZone then
						self.SteerT = (input.Position.X - cDZone) / (1 - cDZone)
					else
						self.SteerT = 0
					end
				else
					local cDZone = math.min(0.99, self.Controls.ControlLDZone / 100)
					if math.abs(input.Position.X) > cDZone then
						self.SteerT = (input.Position.X + cDZone) / (1 - cDZone)
					else
						self.SteerT = 0
					end
				end

			--Gamepad Throttle
			elseif input.KeyCode == self.Controls.ContlrThrottle then
				self.InputThrottle = math.max(0, input.Position.Z)

			--Gamepad Brake
			elseif input.KeyCode == self.Controls.ContlrBrake then
				self.InputBrake = input.Position.Z
			end
		end
	else
		self.InputThrottle = 0
		self.SteerT = 0
		self.InputBrake = 0
	end
end

-- TODO
-- function ClientVehicle.OnMobileInput(self: ClientVehicle)
-- 	local mobile = script.Parent.Mobile

-- 	mobile.Jump.InputBegan:Connect(function(input)
-- 		if input.UserInputType ~= Enum.UserInputType.Touch then return end
-- 		player.Character:FindFirstChildWhichIsA("Humanoid").Jump = true
-- 	end)

-- 	mobile.ModeSwitch.MouseButton1Click:Connect(function()
-- 		MobileMode = MobileModes[(table.find(MobileModes, MobileMode) or 0) + 1]
-- 		if not MobileMode then MobileMode = MobileModes[1] end
-- 	end)

-- 	-- Tap
-- 	for _, button in mobile.Tap:GetChildren() do
-- 		if not button:IsA("ImageButton") then continue end
-- 		button.InputBegan:Connect(function(input)
-- 			if input.UserInputType ~= Enum.UserInputType.Touch then return end
-- 			button.ImageColor3 = Color3.fromRGB(178, 178, 178)
-- 			button.ImageLabel.ImageColor3 = Color3.new(0, 0, 0)
-- 			button.ImageLabel.ImageTransparency = 0.5
-- 			if button.Name == "Throttle" then
-- 				_IThrot = 1
-- 			elseif button.Name == "Brake" then
-- 				_IBrake = 1
-- 			elseif button.Name == "Left" then
-- 				_GSteerT = -1
-- 				_SteerL = true
-- 			elseif button.Name == "Right" then
-- 				_GSteerT = 1
-- 				_SteerR = true
-- 			end
-- 		end)
-- 		button.InputEnded:Connect(function(input)
-- 			if input.UserInputType ~= Enum.UserInputType.Touch then return end
-- 			button.ImageColor3 = Color3.new(0, 0, 0)
-- 			button.ImageLabel.ImageColor3 = Color3.new(1, 1, 1)
-- 			button.ImageLabel.ImageTransparency = 0.8
-- 			if button.Name == "Throttle" then
-- 				_IThrot = 0
-- 			elseif button.Name == "Brake" then
-- 				_IBrake = 0
-- 			elseif button.Name == "Left" then
-- 				if _SteerR then
-- 					_GSteerT = 1
-- 				else
-- 					_GSteerT = 0
-- 				end
-- 				_SteerL = false
-- 			elseif button.Name == "Right" then
-- 				if _SteerL then
-- 					_GSteerT = -1
-- 				else
-- 					_GSteerT = 0
-- 				end
-- 				_SteerR = false
-- 			end
-- 		end)
-- 	end

-- 	-- Tilt
-- 	for _, button in mobile.Tilt:GetChildren() do
-- 		if not button:IsA("TextButton") then continue end
-- 		button.InputBegan:Connect(function(input)
-- 			if input.UserInputType ~= Enum.UserInputType.Touch then return end
-- 			if button.Name == "Throttle" then
-- 				_IThrot = 1
-- 			elseif button.Name == "Brake" then
-- 				_IBrake = 1
-- 			end
-- 		end)
-- 		button.InputEnded:Connect(function(input)
-- 			if input.UserInputType ~= Enum.UserInputType.Touch then return end
-- 			if button.Name == "Throttle" then
-- 				_IThrot = 0
-- 			elseif button.Name == "Brake" then
-- 				_IBrake = 0
-- 			end
-- 		end)
-- 	end
-- 	if UserInputService.GyroscopeEnabled then
-- 		UserInputService.DeviceRotationChanged:Connect(function(rotation, cframe)
-- 			if MobileMode == "Tilt" then _GSteerT = -math.clamp(rotation.Position.Z * 2, -1, 1) end
-- 		end)
-- 	end
-- end

-- TODO: Drivetrain Initialize

function ClientVehicle.SmoothInputs(self: ClientVehicle, deltaTime: number)
	deltaTime = (60 / (1 / deltaTime))
	if self._InThrot <= self.InputThrottle then
		self._InThrot = math.min(self.InputThrottle, self._InThrot + (self.Tune.ThrotAccel * deltaTime))
	else
		self._InThrot = math.max(self.InputThrottle, self._InThrot - (self.Tune.ThrotDecel * deltaTime))
	end
	if self._InBrake <= self.InputBrake then
		self._InBrake = math.min(self.InputBrake, self._InBrake + (self.Tune.BrakeAccel * deltaTime))
	else
		self._InBrake = math.max(self.InputBrake, self._InBrake - (self.Tune.BrakeDecel * deltaTime))
	end
end

-- TODO: Steering Initialize
-- function ClientVehicle.InitSteeringAuto(self: ClientVehicle)
-- 	self.SteerOuter = (self.Tune.LockToLock * 180) / self.Tune.SteerRatio
-- 	self.SteerInner = math.min(self.SteerOuter - (self.SteerOuter * (1 - self.Tune.Ackerman)), self.SteerOuter * 1.2)
-- end

function ClientVehicle.UpdateSteering(self: ClientVehicle, deltaTime: number)
	deltaTime = (60 / (1 / deltaTime))
	local controller = self._LastInputWasGamepad or (self.Tune.MSteerUsesContlr and self.MouseSteerOn or false)
	local SteerSpeed
	local ReturnSpeed
	if controller then
		SteerSpeed = self.Tune.ContlrSteerSpeed > 0 and self.Tune.ContlrSteerSpeed or self.Tune.SteerSpeed
		ReturnSpeed = self.Tune.ContlrReturnSpeed > 0 and self.Tune.ContlrReturnSpeed or self.Tune.ReturnSpeed
	else
		SteerSpeed = self.Tune.SteerSpeed
			* (
				1
				- math.min(
					self.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) / self.Tune.SteerSpeedDecay,
					1 - (self.Tune.MinSteerSpeed / 100)
				)
			)
		ReturnSpeed = self.Tune.ReturnSpeed
			* (
				1
				- math.min(
					self.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) / self.Tune.SteerSpeedDecay,
					1 - (self.Tune.MinSteerSpeed / 100)
				)
			)
	end

	if self.MouseSteerOn then
		local msWidth = math.max(1, mouse.ViewSizeX * self.Controls.MSteerWidth / 200)
		local mdZone = self.Controls.MSteerDZone / 100
		local mST = ((mouse.X - mouse.ViewSizeX / 2) / msWidth)
		if math.abs(mST) <= mdZone then
			self.SteerT = 0
		else
			self.SteerT = (math.max(math.min((math.abs(mST) - mdZone), (1 - mdZone)), 0) / (1 - mdZone))
					^ self.Tune.MSteerExp
				* (mST / math.abs(mST))
		end
	end

	--Interpolate Steering
	local CSAmt = 0
	if
		math.abs(self.SteerT) < self.Tune.CSSteerThresh / 100
		and self.CS
		and self.Velocity.Magnitude * (Units.Length_mm / 1000) * 3.6 > self.Tune.CSSpeedThresh
	then
		CSAmt = (
			self.Center:VectorToObjectSpace(self.Velocity):Dot(Vector3.new(1, 0, 0))
			/ math.max(self.Velocity.Magnitude * (Units.Length_mm / 1000) * 3.6, self.Tune.CSSpeedThresh)
		) * (self.Tune.CSAmt / 100)
	else
		CSAmt = 0
	end
	if math.abs(CSAmt) > (self.Tune.CSAmt / 100) * 0.01 then
		self.CSActive = true
	else
		self.CSActive = false
	end
	local SteerWithCounter = math.clamp(self.SteerT + CSAmt, -1, 1)
	local SteerSmoothing =
		math.clamp(math.abs(SteerWithCounter - self.SteerC) ^ (1 / math.max(self.Tune.SteerSmoothing, 0.001)), 0, 1)
	if self.SteerC < SteerWithCounter then
		if self.SteerC < 0 then
			self.SteerC = math.min(SteerWithCounter, self.SteerC + (ReturnSpeed * SteerSmoothing * deltaTime))
		else
			self.SteerC = math.min(SteerWithCounter, self.SteerC + (SteerSpeed * SteerSmoothing * deltaTime))
		end
	else
		if self.SteerC > 0 then
			self.SteerC = math.max(SteerWithCounter, self.SteerC - (ReturnSpeed * SteerSmoothing * deltaTime))
		else
			self.SteerC = math.max(SteerWithCounter, self.SteerC - (SteerSpeed * SteerSmoothing * deltaTime))
		end
	end

	--Steer Decay Multiplier
	local sDecay = (
		1
		- math.min(
			self.Velocity.Magnitude
				/ (Units.Velocity_mdivs / 3.6)
				/ (self.Tune.SteerDecay / (Units.Velocity_mdivs / 3.6)),
			1 - (self.Tune.MinSteer / 100)
		)
	)
	local rsDecay = (
		1
		- math.min(
			self.Velocity.Magnitude
				/ (Units.Velocity_mdivs / 3.6)
				/ (self.Tune.RSteerDecay / (Units.Velocity_mdivs / 3.6)),
			1 - (self.Tune.MinSteer / 100)
		)
	)

	--Apply Steering
	for _, wheel in self.Wheels do
		if wheel.CanSteer == 0 then continue end

		local angle = 0
		local rsteerVariableAngle = 1
		if wheel.CanSteer == 2 then
			if wheel.Instance.Name == "FL" then
				-- self.SteerInner and self.SteerOuter
				angle = (self.SteerC < 0 and self.Tune.SteerInner or self.Tune.SteerOuter) * sDecay
			elseif wheel.Instance.Name == "FR" then
				angle = (self.SteerC < 0 and self.Tune.SteerOuter or self.Tune.SteerInner) * sDecay
			elseif wheel.Instance.Name == "F" then
				angle = self.Tune.SteerInner * sDecay
			elseif wheel.Instance.Name == "RL" then
				angle = (self.SteerC < 0 and self.Tune.RSteerInner or self.Tune.RSteerOuter) * rsDecay
			elseif wheel.Instance.Name == "RR" then
				angle = (self.SteerC < 0 and self.Tune.RSteerOuter or self.Tune.RSteerInner) * rsDecay
			elseif wheel.Instance.Name == "R" then
				angle = self.Tune.RSteerInner * rsDecay
			end
			if not wheel.IsFront then
				if self.Tune.FWSteer == "Static" then
					rsteerVariableAngle = -math.max(0, 1 - (self.Velocity.Magnitude / self.Tune.RSteerSpeed))
				elseif self.Tune.FWSteer == "Speed" then
					rsteerVariableAngle = math.min(1, (self.Velocity.Magnitude / self.Tune.RSteerSpeed))
				elseif self.Tune.FWSteer == "Both" then
					rsteerVariableAngle = -math.max(-1, 1 - (self.Velocity.Magnitude / self.Tune.RSteerSpeed))
				end
			end
		end

		if self.Tune.PowerSteeringType == "New" then
			-- data.SteerAttach0.Orientation =
			-- 	Vector3.new(0, data.CanSteer == 1 and 0 or self.SteerC * angle * rsteerVariableAngle, 0)
		else
			(wheel.Instance.Arm :: any).Steer.CFrame = wheel.Instance.Base.CFrame
				* (
					wheel.CanSteer == 1 and CFrame.new(0, 0, 0)
					or (CFrame.Angles(0, -math.rad(self.SteerC * angle * rsteerVariableAngle), 0))
				)
		end
	end
end

function calcPower(m: number, n: number, p: number, q: number, M: number, b: number, x: number)
	return math.clamp(M - ((q - n) / (b ^ p - b ^ m) * (b ^ x - b ^ m) + n), 0, M)
end

function ClientVehicle.UpdateEngine(self: ClientVehicle, deltaTime: number)
	deltaTime = (60 / (1 / deltaTime))

	local wheelRPM = self._DriveWheelSpeed * self.CurrentRatio * self.FinalDriveRatio

	--CVT
	local CVTRatio
	if self.Tune.ClutchType == "CVT" then
		CVTRatio = math.clamp(
			(self.Tune.CVTRPM * self.Throttle) / (self._DriveWheelSpeed * self.FinalDriveRatio),
			self.Tune.CVTMinRatio,
			self.Tune.CVTMaxRatio
		)
	end

	--Update ratio
	self.CurrentRatio = self.Tune.ClutchType == "CVT" and CVTRatio
		or self.Tune.Ratios[self.Gear + 2 + (self.ParkingGearEnabled and 1 or 0)]
	local spLimit = self.Tune.Redline / (self.FinalDriveRatio * self.CurrentRatio)
	if self.CurrentRatio * self.FinalDriveRatio == 0 then spLimit = 0 end -- Prevents [nan] from dividing by 0

	--Flywheel/clutch-dumping
	local flywheelEnergy = math.max((self.RPM - wheelRPM) * self.Tune.DumpMult, 0)
		* (1 - self.Clutch)
		* 1.356
		* Units.Torque_nm

	--Determine RPM
	local revMin = 0
	local goalMin = 0
	local goalMax = self.Tune.Redline

	if self.Shifting and self._ShiftUp then
		self.Throttle = self.Tune.IdleThrottle / 100
	elseif self.Shifting and self._ShiftDown then
		self.Throttle = self.Tune.ShiftThrot / 100
	else
		if self.Tune.AutoShiftVers == "Old" and self.Gear == -1 and self.TransmissionMode == "Auto" then
			self.Throttle = self._InBrake
		else
			self.Throttle = math.max(self._InThrot, self.Tune.IdleThrottle / 100)
		end
	end

	if self.Tune.AutoShiftVers == "Old" and self.Gear == -1 and self.TransmissionMode == "Auto" then
		self.Brake = self._InThrot
	else
		self.Brake = self._InBrake
	end

	if not self.IsOn then
		self._LastOffTime = tick()
		if self.AutoClutch then self.Clutch = 1 end
		self.Throttle = 0
	end

	if
		(
			(self._ClutchPressing and (self.Gear == 0 or (self.ParkingGearEnabled and self.Gear == -2)))
			or (self._InputClutch and self.Gear ~= 0)
		) and self.Tune.NeutralLimit
	then
		if
			((self.Gear == 0 or (self.ParkingGearEnabled and self.Gear == -2)) and not self.Tune.LimitClutch)
			or self.Tune.LimitClutch
		then
			goalMax = self.Tune.NeutralRevRPM
		end
	end

	-- Rev limiter/speed limiter
	-- TODO: CHECK THIS!
	local revLimiting = false -- (Forden) If error, then place in a class variable
	if self.RPM >= self.Tune.Redline then
		revLimiting = true
	elseif self.RPM < goalMax - self.Tune.RevBounce then
		revLimiting = false
	end
	if revLimiting then self.Throttle = self.Tune.IdleThrottle / 100 end

	local limit = (self.Gear < 0 and self.Tune.ReverseSpeed or self.Tune.SpeedLimit)
	if limit > 0 then
		self.Throttle = math.min(
			self.Throttle,
			math.max(
				1
					- math.clamp(
						((self.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6)) - (limit - self.Tune.SLimitGradient))
							/ self.Tune.SLimitGradient,
						0,
						1
					),
				self.Tune.IdleThrottle / 100
			)
		)
		if self.Tune.SLimitBrake then
			self.Brake = math.max(
				self.Brake,
				math.clamp(
					(self.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) - limit) / self.Tune.SLimitGradient,
					0,
					1
				)
			)
		end
	end

	-- Idle
	if self.RPM < self.Tune.IdleRPM + (self.Tune.IdlePadding or 0) and self.IsOn then
		self.Throttle = math.max(
			self.Throttle,
			math.clamp(
				(self.Tune.IdleRPM + (self.Tune.IdlePadding or 0) - self.RPM) / (self.Tune.IdleDamping or 400),
				0,
				1
			)
		)
	end

	if (self.Tune.Engine or self.Tune.Electric) and not self.Starting then
		self._GoalRPM = math.clamp(
			self.RPM
				- (self.Tune.RevDecay * deltaTime)
				+ (self.Tune.RevAccel * self.Throttle * deltaTime)
				- (
					math.clamp(
						math.max(self.RPM - self.Tune.IdleRPM, 0) / math.max(self.Tune.Redline - self.Tune.IdleRPM, 1),
						0,
						1
					)
					* self.Tune.RevDecayRPM
					* deltaTime
				),
			goalMin,
			goalMax
		)
	end

	--Starting
	if self.Starting then
		self._GoalRPM = math.clamp(
			self._GoalRPM + self.Tune.IgnitionAccel * deltaTime,
			0,
			math.max(self.Tune.IgnitionRPM, wheelRPM)
		)
		self.IsOn = self._GoalRPM > self.Tune.IgnitionMinRPM
	end

	--Set RPM
	local aRPM = math.max(
		(self._GoalRPM * (1 - deltaTime) + wheelRPM * deltaTime) * (1 - self.Clutch) + self._GoalRPM * self.Clutch,
		revMin
	)
	local clutchP = math.min(math.abs(aRPM - self.RPM) / (self.Tune.Flywheel * deltaTime), 0.9)
	if self._ClutchPressing then clutchP = 0 end
	self.RPM = aRPM * (1 - clutchP) + self.RPM * clutchP

	if self.Tune.OverRev == false and self.RPM > self.Tune.Redline then self.RPM = self.Tune.Redline end

	if
		self.RPM <= (self.Tune.IdleRPM / 4)
		and self._CanStall
		and (tick() - self._LastOffTime >= 0.2)
		and self.Tune.Stall
	then
		self.IsOn = false
	end

	--Clutch
	if self.Shifting or (self.Gear == 0 or (self.ParkingGearEnabled and self.Gear == -2)) then
		self._ClutchPressing = true
		self.Clutch = 1
		self._CanStall = false
	end

	-- TODO: CHECK THIS!
	-- (Forden) If error, then place in a class variable
	local clutchModulate = 0
	if self.Tune.Clutch then
		if self.AutoClutch then
			if self.Tune.ClutchType == "Clutch" or self.Tune.ClutchType == "CVT" then
				local clutchKick = (self._ClutchPressing and 1 or 0) * (self.Tune.ClutchEngage / 100)
				local ClRPMInfluence = math.max(self.RPM * self.Tune.ClutchRPMMult / self.Tune.Redline, 0)
				if self.Tune.ClutchMode == "New" then ClRPMInfluence = 0 end
				clutchModulate = math.min(
					(
						(
							(
								(self.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) / self.Tune.SpeedEngage)
								/ math.abs(self.Gear)
							) + ClRPMInfluence
						) - clutchKick
					),
					1
				)
			elseif self.Tune.ClutchType == "TorqueConverter" and self.Tune.TQLock then
				if
					(
						self.Throttle <= self.Tune.IdleThrottle / 100
						and self.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) < self.Tune.SpeedEngage
					)
					or (
						self.Throttle > self.Tune.IdleThrottle / 100
						and (self.RPM < self.Tune.RPMEngage and wheelRPM < self.Tune.RPMEngage)
					)
				then
					clutchModulate = math.min(clutchModulate * (self.Tune.ClutchEngage / 100), 1)
				else
					clutchModulate = math.min(
						clutchModulate * (self.Tune.ClutchEngage / 100) + (1 - (self.Tune.ClutchEngage / 100)),
						1
					)
				end
			elseif self.Tune.ClutchType == "TorqueConverter" and not self.Tune.TQLock then
				clutchModulate = math.min((self.RPM / self.Tune.Redline) * 0.7, 1)
			end
			if not self._ClutchPressing then
				self.Clutch = math.min(1 - clutchModulate, 1)
			else
				self.Clutch = 1
			end
		else
			if self._ClutchPressing then
				self.Clutch = 1
			else
				self.Clutch = 0
			end
		end
		self._CanStall = (self.Clutch <= 0.01) or self._CanStall
	else
		self._CanStall = false
		if not self._ClutchPressing and not self.Shifting then
			self.Clutch = 0
		else
			self.Clutch = 1
		end
	end

	-- Things that apply the clutch
	if
		self.AutoClutch
		and (
			self.Starting
			or (self.Tune.RemoveCreep and self.RPM < self.Tune.IdleRPM + (self.Tune.IdlePadding or 0) and self.InputThrottle < 0.1)
			or (revLimiting and self.Tune.OverRev == false)
		)
	then
		self.Clutch = 1
	end

	-- Torque calculations (Detomiks)
	-- What you see here is mostly just ported over from Desmos.
	if (not self.Engine) or self.Tune.CustomEngineCalculations == false then
		local x = self.RPM / 1000
		local NTorque = 0
		local ETorque = 0
		local TTorque = 0
		local STorque = 0
		if self.Tune.Engine then
			local NIdleTorque = calcPower(
				self.Tune.IdleRPM / 1000,
				self.Tune.IdleTorque,
				self.Tune.PeakTorqueRPM / 1000,
				self.Tune.PeakTorque,
				self.Tune.PeakTorque,
				self.Tune.IdleTorqueCurve,
				x
			)
			local NRedlineTorque = calcPower(
				self.Tune.PeakTorqueRPM / 1000,
				self.Tune.PeakTorque,
				self.Tune.Redline / 1000,
				self.Tune.RedlineTorque,
				self.Tune.PeakTorque,
				1 / self.Tune.RedlineTorqueCurve,
				x
			)
			local VVL = self.Tune.VVLTorque > 0
					and self.Tune.VVLTorque - calcPower(
						self.Tune.VVLRPM / 1000,
						0,
						(self.Tune.VVLRPM + self.Tune.VVLTime) / 1000,
						self.Tune.VVLTorque,
						self.Tune.VVLTorque,
						self.Tune.VVLCurve,
						x
					)
				or 0
			local globalTemperature = game.Workspace:GetAttribute("GlobalTemperature") :: number
			local AirPressurePercent = math.exp(
				(-9.80665 * 0.0289644 * (self.Center.Y * Units.Length_mm / 1000))
					/ (8.3142 * (globalTemperature + 273.15))
			) -- look up the barometric formula
			NTorque = (self.Tune.Engine and 1 or 0)
				* (self.Tune.PeakTorque - NIdleTorque - NRedlineTorque + VVL)
				* AirPressurePercent
			self.HpNatural, self.TqNatural = (NTorque * x) / 5.252, NTorque

			if self.Tune.Turbochargers > 0 then
				local _TBoostGoal = self.Tune.Turbochargers
					* (
						(self.Throttle ^ 3) * (100 / self.Tune.T_Size) * ((NTorque * x) / 5.252)
						- calcPower(
							self.Tune.IdleRPM / 1000,
							self.Tune.T_IdleBoost,
							self.Tune.T_PeakRPM / 1000,
							self.Tune.T_Boost,
							(self.Throttle ^ 3) * (100 / self.Tune.T_Size) * ((NTorque * x) / 5.252),
							1 / self.Tune.T_Curve,
							x
						)
					)
				if _TBoostGoal > self.BoostTurbo then
					self.BoostTurbo = self.BoostTurbo
						+ math.min(
								self.Tune.T_SpoolIncrease * (_TBoostGoal - self.BoostTurbo),
								self.Tune.T_SpoolIncrease * (10 / self.Tune.T_Size) * self.Tune.Turbochargers
							)
							* deltaTime -- i should probably base this off of the maximum horsepower instead of the RPM, but it's the same thing anyway
				elseif self.BoostTurbo > _TBoostGoal then
					self.BoostTurbo = self.BoostTurbo
						+ self.Tune.T_SpoolDecrease * (_TBoostGoal - self.BoostTurbo) * deltaTime
				end
				self.BoostTurbo = math.clamp(self.BoostTurbo, 0, self.Tune.Turbochargers * self.Tune.T_Boost)
				TTorque = self.BoostTurbo * self.Tune.T_Efficiency
				self.HpTurbo, self.TqTurbo = (TTorque * x) / 5.252, TTorque
			end
			if self.Tune.Superchargers > 0 then
				local SIdleBoost = calcPower(
					self.Tune.IdleRPM / 1000,
					self.Tune.S_IdleBoost,
					self.Tune.S_PeakRPM / 1000,
					self.Tune.S_Boost,
					self.Tune.S_Boost,
					self.Tune.S_IdleCurve,
					x
				)
				local SRedlineBoost = calcPower(
					self.Tune.S_PeakRPM / 1000,
					self.Tune.S_Boost,
					self.Tune.Redline / 1000,
					self.Tune.S_RedlineBoost,
					self.Tune.S_Boost,
					1 / self.Tune.S_RedlineCurve,
					x
				)
				local _SBoostGoal = self.Tune.Superchargers
					* self.Throttle
					* (self.Tune.S_Boost - SIdleBoost - SRedlineBoost)
				if _SBoostGoal > self.BoostSuper then
					self.BoostSuper =
						math.min(self.BoostSuper + self.Tune.S_Boost * self.Tune.S_Response * deltaTime, _SBoostGoal)
				elseif self.BoostSuper > _SBoostGoal then
					self.BoostSuper =
						math.max(self.BoostSuper - self.Tune.S_Boost * self.Tune.S_Response * deltaTime, _SBoostGoal)
				end
				STorque = self.BoostSuper * self.Tune.S_Efficiency
				self.HpSuper, self.TqSuper = (STorque * x) / 5.252, STorque
			end
			if self.Tune.Turbochargers > 0 or self.Tune.Superchargers > 0 then
				self.HpBoosted, self.TqBoosted = ((TTorque + STorque) * x) / 5.252, TTorque + STorque
			end
		end
		if self.Tune.Electric then
			ETorque = (self.Tune.Electric and 1 or 0)
				* (
					self.Tune.E_Torque
					- calcPower(
						self.Tune.E_TransitionRPM / 1000,
						self.Tune.E_Torque,
						self.Tune.E_Redline / 1000,
						self.Tune.E_RedlineTorque,
						self.Tune.E_Torque,
						self.Tune.E_Curve,
						x
					)
				)
			self.HpElectric, self.TqElectric = (ETorque * x) / 5.252, ETorque
		end
		local TotalTorque = math.clamp(
			NTorque + ETorque + TTorque + STorque,
			self.Tune.Stall and 0 or self.Tune.IdleTorque,
			(self.Tune.HPLimit > 0 and self.Tune.HPLimit or math.huge) * (5.252 / x)
		)
		self.Horsepower, self.Torque = (TotalTorque * x) / 5.252, TotalTorque
	else
		self.Engine.run({
			-- Manually add environment variables here
			_RPM = self.RPM,
			_GThrot = self.Throttle,
			_IsOn = self.IsOn,
			_CGear = self.Gear,
		}, deltaTime)

		self.Boost = self.Engine._Boost
		self.BoostTurbo = self.Engine._TBoost
		self.BoostSuper = self.Engine._SBoost

		self.Horsepower = self.Engine._HP
		self.Torque = self.Engine._TQ
		self.HpNatural = self.Engine._NH
		self.TqNatural = self.Engine._NT
		self.HpElectric = self.Engine._EH
		self.TqElectric = self.Engine._ET
		self.HpTurbo = self.Engine._TH
		self.TqTurbo = self.Engine._TT
		self.HpSuper = self.Engine._SH
		self.TqSuper = self.Engine._ST
		self.HpBoosted = self.Engine._BH
		self.TqBoosted = self.Engine._BT
	end

	-- Exit engine
	local outTorque = self.Torque * self.CurrentRatio * self.FinalDrive
	local cGrav = (self.Tune.GravComp > 0 and self.Tune.GravComp or game.Workspace.Gravity) * self.Tune.InclineComp / 35
	local iComp = self.Center.LookVector.Y * cGrav * math.sign(self.Gear)
	outTorque = outTorque * math.max(1, (1 + iComp))

	--Update Wheels
	for _, wheel in self.Wheels do
		-- local wheelPosition = wheel.Position
		--Apply Power
		local on = 1
		if not self.IsOn then on = 0 end
		local throt = self.Throttle
		local brake = self.Brake
		local clutch = 1
		if
			self._ClutchPressing
			or (
				self.AutoClutch
				and (
					self.Starting
					or (
						self.Tune.RemoveCreep
						and self.RPM < self.Tune.IdleRPM + (self.Tune.IdlePadding or 0)
						and self.InputThrottle < 0.1
					)
				)
			)
		then
			clutch = 0
		end --for some reason, the car still creeps forward when starting the car if i don't do this
		local tq = outTorque

		--Apply ESC
		local tqESC = 0
		if
			not (wheel.Instance.Name == "F" or wheel.Instance.Name == "R")
			and self.ESC
			and (self.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6)) > self.Tune.ESCSpeed
		then
			local g = self.Instance.Body["#Weight"].CFrame:VectorToObjectSpace(
				self.Acceleration
					/ Units.Velocity_mdivs
					/ (
						(self.Tune.GravComp > 0 and self.Tune.GravComp or game.Workspace.Gravity)
						* (Units.Length_mm / 1000)
					)
			)
			if math.sign(self.SteerC) ~= math.sign(g.X) then
				local diff = self.SteerC - (g.X * -math.sign(self.Center:VectorToObjectSpace(self.Velocity).Z))
				if math.abs(diff) > self.Tune.ESCThreshold then
					local escVector, escBias = 1, (self.Tune.ESCVector + 1)
					if wheel.IsFront then
						escVector = escVector * (2 - escBias)
					else
						escVector = escVector * escBias
					end

					tqESC = ((wheel.Instance.Name == "FL" or wheel.Instance.Name == "RL") and 1 or -1)
						* math.sign(diff)
						* escVector
					throt = throt + (math.max(tqESC, 0) - throt) * (self.Tune.ESCThrottle / 100)
					brake = brake + (-math.min(tqESC, 0) - brake) * (self.Tune.ESCBrake / 100)
				end
			end
		end
		self.ESCActive = tqESC ~= 0 or self.ESCActive
		wheel.Trackers.ESC = tqESC

		--Apply ABS
		local tqABS = 1
		if self.ABS and brake > 0 then
			tqABS = 1
				- (
					math.min(
						math.max(
							0,
							math.abs(
								wheel.Instance.AssemblyAngularVelocity.Magnitude
										* (wheel.Instance.Size.Y / 2)
										/ (Units.Velocity_mdivs / 3.6)
									- wheel.Instance.AssemblyLinearVelocity.Magnitude / (Units.Velocity_mdivs / 3.6)
							) - self.Tune.ABSThreshold
						) / self.Tune.ABSGradient,
						1
					) * (1 - (self.Tune.ABSLimit / 100))
				)
		end
		self.ABSActive = tqABS < 1 or self.ABSActive
		wheel.Trackers.ABS = 1 - tqABS

		local PBrakeV = 0
		if self.PBrake == true or self.Gear == -2 then
			PBrakeV = 1
		else
			PBrakeV = 0
		end

		-- Apply Power
		if wheel.IsDriven then
			--Differential/Torque-Vectoring
			local RRdiffMult = 1
			local RLdiffMult = 1
			local FRdiffMult = 1
			local FLdiffMult = 1

			if wheel.Instance.Name == "FR" then
				local avg = (
					(
						wheel.Instance.AssemblyAngularVelocity.Magnitude
						/ wheel.OppositeWheel.AssemblyAngularVelocity.Magnitude
					) - 1
				) * (self.Tune.FDiffPreload / 10)
				FRdiffMult = math.ceil(
					math.max(
						0,
						math.min(
							2,
							1
								- (
									((self.Tune.FDiffPower / 100) * avg * self.Throttle)
									+ ((self.Tune.FDiffCoast / 100) * avg * (1 - self.Throttle))
								)
						)
					) * 100
				) / 100
				FLdiffMult = 2 - FRdiffMult
			elseif wheel.Instance.Name == "FL" then
				local avg = (
					(
						wheel.Instance.AssemblyAngularVelocity.Magnitude
						/ wheel.OppositeWheel.AssemblyAngularVelocity.Magnitude
					) - 1
				) * (self.Tune.FDiffPreload / 10)
				FLdiffMult = math.ceil(
					math.max(
						0,
						math.min(
							2,
							1
								- (
									((self.Tune.FDiffPower / 100) * avg * self.Throttle)
									+ ((self.Tune.FDiffCoast / 100) * avg * (1 - self.Throttle))
								)
						)
					) * 100
				) / 100
				FRdiffMult = 2 - FLdiffMult
			elseif wheel.Instance.Name == "RR" then
				local avg = (
					(
						wheel.Instance.AssemblyAngularVelocity.Magnitude
						/ wheel.OppositeWheel.AssemblyAngularVelocity.Magnitude
					) - 1
				) * (self.Tune.RDiffPreload / 10)
				RRdiffMult = math.ceil(
					math.max(
						0,
						math.min(
							2,
							1
								- (
									((self.Tune.RDiffPower / 100) * avg * self.Throttle)
									+ ((self.Tune.RDiffCoast / 100) * avg * (1 - self.Throttle))
								)
						)
					) * 100
				) / 100
				RLdiffMult = 2 - RRdiffMult
			elseif wheel.Instance.Name == "RL" then
				local avg = (
					(
						wheel.Instance.AssemblyAngularVelocity.Magnitude
						/ wheel.OppositeWheel.AssemblyAngularVelocity.Magnitude
					) - 1
				) * (self.Tune.RDiffPreload / 10)
				RLdiffMult = math.ceil(
					math.max(
						0,
						math.min(
							2,
							1
								- (
									((self.Tune.RDiffPower / 100) * avg * self.Throttle)
									+ ((self.Tune.RDiffCoast / 100) * avg * (1 - self.Throttle))
								)
						)
					) * 100
				) / 100
				RRdiffMult = 2 - RLdiffMult
			end

			--Apply torque split
			-- This takes the total amount of torque alotted to the front or rear wheels, then divides it by how many wheels there are
			local bias = (self.Tune.Config == "AWD" and (self.Tune.TorqueVector + 1) / 2)
				or (self.Tune.Config == "FWD" and 0)
				or 1
			tq = wheel.IsFront and (tq * (1 - bias)) / self.WheelCount.Front or (tq * bias) / self.WheelCount.Rear

			--Apply TCS
			local tqTCS = 1
			if self.TCS and throt > self.Tune.IdleThrottle / 100 then
				tqTCS = 1
					- (
						math.min(
							math.max(
								0,
								math.abs(
									wheel.Instance.AssemblyAngularVelocity.Magnitude
											* (wheel.Instance.Size.Y / 2)
											/ (Units.Velocity_mdivs / 3.6)
										- wheel.Instance.AssemblyLinearVelocity.Magnitude
											/ (Units.Velocity_mdivs / 3.6)
								) - self.Tune.TCSThreshold
							) / self.Tune.TCSGradient,
							1
						) * (1 - (self.Tune.TCSLimit / 100))
					)
			end
			self.TCSActive = tqTCS < 1 or self.TCSActive
			wheel.Trackers.TCS = 1 - tqTCS

			--Update Forces
			local tqOUT = (tq * 1.356 * Units.Torque_nm * throt * tqTCS * on * clutch)
				+ (flywheelEnergy / #self.DriveWheels)
			-- convert lb-ft to nm to roblox stuff
			-- if it reaches an absurdly high number, set it to 0 to try and prevent physics death

			if wheel.Instance.Name == "RR" then
				wheel.Instance["#AV"].MotorMaxTorque = tqOUT * RRdiffMult
			elseif wheel.Instance.Name == "RL" then
				wheel.Instance["#AV"].MotorMaxTorque = tqOUT * RLdiffMult
			elseif wheel.Instance.Name == "FR" then
				wheel.Instance["#AV"].MotorMaxTorque = tqOUT * FRdiffMult
			elseif wheel.Instance.Name == "FL" then
				wheel.Instance["#AV"].MotorMaxTorque = tqOUT * FLdiffMult
			else
				wheel.Instance["#AV"].MotorMaxTorque = tqOUT
			end
			wheel.Instance["#AV"].AngularVelocity = spLimit * math.sign(self.Gear)
			if wheel.IsFront then
				wheel.Instance["#BV"].MotorMaxTorque = (self.BrakeForce.Front * brake * tqABS)
					+ (self.Tune.EBrakeForce * clutch * ((1 - throt) * (self.RPM / self.Tune.Redline)))
					+ (self.PBrakeForce.Front * PBrakeV)
			else
				wheel.Instance["#BV"].MotorMaxTorque = (self.BrakeForce.Rear * brake * tqABS)
					+ (self.Tune.EBrakeForce * clutch * ((1 - throt) * (self.RPM / self.Tune.Redline)))
					+ (self.PBrakeForce.Rear * PBrakeV)
			end
		else --luaint edit
			wheel.Instance["#AV"].MotorMaxTorque = 0
			wheel.Instance["#AV"].AngularVelocity = 0
			if wheel.IsFront then
				wheel.Instance["#BV"].MotorMaxTorque = (self.BrakeForce.Front * brake * tqABS)
					+ (self.PBrakeForce.Front * PBrakeV)
			else
				wheel.Instance["#BV"].MotorMaxTorque = (self.BrakeForce.Rear * brake * tqABS)
					+ (self.PBrakeForce.Rear * PBrakeV)
			end
		end
	end
end

function ClientVehicle.UpdateTransmission(self: ClientVehicle)
	if self._ShiftUp and not self.Shifting then
		if
			(self.TransmissionMode == "Manual" and not self._ClutchPressing)
			or (self.TransmissionMode == "Manual" and self.Tune.ClutchRel and (self._InThrot > 0))
			or self.Gear == #self.Tune.Ratios - 2 - (self.ParkingGearEnabled and 1 or 0)
			or (self.TransmissionMode ~= "Manual" and not self.IsOn)
		then
			self._ShiftUp = false
			return
		end
		local NextGear = math.min(self.Gear + 3 + (self.ParkingGearEnabled and 1 or 0), #self.Tune.Ratios)
		if self.TransmissionMode ~= "Manual" and self.Tune.ClutchType ~= "CVT" then
			self.Shifting = true
			if self.Gear > 0 then
				if self.Tune.AutoShiftType == "DCT" then
					task.wait(self.Tune.ShiftUpTime)
				elseif self.Tune.AutoShiftType == "Rev" then
					repeat
						task.wait()
					until self.RPM
							<= math.max(
								math.min(
									self._MaxSpin * self.Tune.Ratios[NextGear] * self.FinalDriveRatio,
									self.Tune.Redline - self.Tune.RevBounce
								),
								self.Tune.IdleRPM
							)
						or not self.IsOn
						or self._ShiftDown
				end
			end
		end
		self._ShiftUp = false
		self.Shifting = false
		if self.TransmissionMode ~= "Manual" and not self.IsOn then return end
		if NextGear > 3 + (self.ParkingGearEnabled and 1 or 0) and self.Tune.ClutchType == "CVT" then return end -- make sure it cannot go past 1st gear
		self.Gear = math.min(self.Gear + 1, #self.Tune.Ratios - 2 - (self.ParkingGearEnabled and 1 or 0))
		if
			self.TransmissionMode ~= "Manual"
			or (self.TransmissionMode == "Manual" and self.Gear == 1) and self.IsOn
		then
			self._ClutchPressing = self._InputClutch
		end
	end
	if self._ShiftDown and not self.Shifting then
		if
			(self.TransmissionMode == "Manual" and not self._ClutchPressing)
			or self.Gear == -1 - (self.ParkingGearEnabled and 1 or 0)
			or (self.TransmissionMode ~= "Manual" and not self.IsOn)
		then
			self._ShiftDown = false
			return
		end
		local PrevGear = math.min(self.Gear + 1 + (self.ParkingGearEnabled and 1 or 0), #self.Tune.Ratios)
		if self.TransmissionMode ~= "Manual" then
			self.Shifting = true
			if self.Gear > 1 then
				if self.Tune.AutoShiftType == "DCT" then
					task.wait(self.Tune.ShiftDnTime)
				elseif self.Tune.AutoShiftType == "Rev" then
					repeat
						task.wait()
					until self.RPM
							>= math.max(
								math.min(
									self._MaxSpin * self.Tune.Ratios[PrevGear] * self.FinalDriveRatio,
									self.Tune.Redline - self.Tune.RevBounce
								),
								self.Tune.IdleRPM
							)
						or not self.IsOn
						or self._ShiftUp
				end
			end
		end
		self._ShiftDown = false
		self.Shifting = false
		if self.TransmissionMode ~= "Manual" and not self.IsOn then return end
		self.Gear = math.max(self.Gear - 1, self.Velocity.Magnitude > 5 and -1 or -2)
		if
			self.TransmissionMode ~= "Manual"
			or (self.TransmissionMode == "Manual" and self.Gear == -1) and self.IsOn
		then
			self._ClutchPressing = self._InputClutch
		end
	end
end

function ClientVehicle.UpdateWheels(self: ClientVehicle)
	local count = #self.Wheels
	local driveCount = 0

	local data: Types.ClientWheelSharedData = {
		TCSAmt = 0,
		ABSAmt = 0,
		ESCAmt = 0,
		TCSCount = 0,
		ABSCount = 0,
		ESCCount = 0,
		Rotation = 0,
		MaxSpin = 0,
		DriveWheelSpeed = 0,
	}
	for _, wheel in self.Wheels do
		wheel:Update(data)

		if wheel.IsDriven then
			driveCount += 1
		end
	end
	self._DriveWheelSpeed = data.DriveWheelSpeed / driveCount

	-- Wheel speeds
	self._MaxSpin = data.MaxSpin
	self.AverageRotSpeed = data.Rotation / count
	self.TCSActive = false
	self.ABSActive = false
	self.ESCActive = false
end

-- TODO: При низком количестве топлива, сбрасывать обороты, имитировать захлебывание двигателя
-- TODO: Проверить работу
function ClientVehicle.UpdateFuel(self: ClientVehicle, deltaTime: number)
	if not self.Tune.Engine or self.Tune.Electric or not self.IsOn then return end

	local kW = self.Horsepower * 1.35962
	local consumption = self.Tune.BSFC * kW / 3600 / 1000 / self.Tune.FuelDensity * deltaTime
	self.Fuel = math.max(0, self.Fuel - consumption)

	if self.Fuel <= 0 then self.IsOn = false end
end

-- TODO: Взрыв двигателя, дым из под капота
function ClientVehicle.UpdateTemp(self: ClientVehicle, deltaTime: number)
	if not self.Tune.Engine then return end

	local kW = self.Horsepower / 1.35962
	local heat = kW * Lerp(1, 2, self.RPM / self.Tune.Redline) / 120
	local tDelta = self.Temperature - (game.Workspace:GetAttribute("GlobalTemperature") :: number)
	local cooling = tDelta * 0.015
	cooling += (self.Velocity.Magnitude / Units.Velocity_mdivs) ^ 2 * tDelta / 100000 * 0.8
	self.Temperature += (heat - cooling) * deltaTime

	if self.Temperature > self.Tune.EngineBurnTemp then
		self.IsOn = false
		self.Broken = true
		self.DeformationController:BlowEngine()
	end
end

function getCenter(vehicle: ClientVehicle)
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0
	for _, wheel in vehicle.Wheels do
		if wheel.IsFront then
			centerF = centerF + wheel.Instance.Position
			countF = countF + 1
		else
			centerR = centerR + wheel.Instance.Position
			countR = countR + 1
		end
	end
	centerF = centerF / countF
	centerR = centerR / countR
	local center = CFrame.lookAt(centerR:Lerp(centerF, 0.5), centerF)
	return center
end

-- TODO: Flip function

-- TODO: Mobile input
function ClientVehicle.OnLastInputTypeChanged(self: ClientVehicle, inputType: Enum.UserInputType)
	self._LastInputWasGamepad = string.find(inputType.Name, "Gamepad") and true or false
end

function ClientVehicle.ReplicateVariables(self: ClientVehicle)
	local vars = {
		"Starting",
		"Occupant",
		"Fuel",
		"Clutch",
		"Gear",
		"FinalDrive",
		"FinalDriveRatio",
		"TransmissionMode",
		"CurrentRatio",
		"RPM",
		"Shifting",
		"AutoClutch",
		"Boost",
		"BoostTurbo",
		"BoostSuper",
		"HpNatural",
		"HpElectric",
		"HpTurbo",
		"HpSuper",
		"HpBoosted",
		"Horsepower",
		"TqNatural",
		"TqElectric",
		"TqTurbo",
		"TqSuper",
		"TqBoosted",
		"Torque",
		"Horning",
		"Throttle",
		"InputThrottle",
		"Brake",
		"InputBrake",
		"SteerC",
		"SteerT",
		"MouseSteerOn",
		"PBrake",
		"Velocity",
		"AngularVelocity",
		"AverageRotSpeed",
		"Acceleration",
		"Mileage",
		"Center",
		"TCS",
		"TCSActive",
		"ABS",
		"ABSActive",
		"ESC",
		"ESCActive",
		"CS",
		"CSActive",
		"IsOn",
		"Temperature",
		"FanSpeed",
	}
	local data = {}
	for _, var in vars do
		data[var] = self[var]
	end
	self._Remote:FireServer(data)
end

function ClientVehicle.Update(self: ClientVehicle, deltaTime: number)
	self.Center = getCenter(self)
	self.Boost = self.BoostTurbo + self.BoostSuper
	self.Velocity = self.Instance.Body["#Weight"].AssemblyLinearVelocity
	self.AngularVelocity = self.Instance.Body["#Weight"].AssemblyAngularVelocity
	self.Acceleration = (self.Velocity - self._OldVelocity) * (1 / deltaTime)
	self._OldVelocity = self.Velocity
	self.Mileage += self.Velocity.Magnitude * (Units.Length_mm / 1000) / 1000 * deltaTime

	self:UpdateWheels()
	self:SmoothInputs(deltaTime)
	self:UpdateSteering(deltaTime)
	self:UpdateTransmission()
	self:UpdateEngine(deltaTime)
	self:UpdateFuel(deltaTime)
	self:UpdateTemp(deltaTime)
	self:ReplicateVariables()
end

-- TODO
function ClientVehicle.SlowUpdate(self: ClientVehicle) end

function ClientVehicle.Destroy(self: ClientVehicle)
	require(player.PlayerScripts.PlayerModule :: any):GetControls():GetActiveController().jumpEnabled = true

	--Remove Flip Force
	if self.Instance.DriveSeat:FindFirstChild("Flip") then
		if self.Tune.FlipType == "New" then
			self.Instance.DriveSeat.Flip.Enabled = false
		else
			self.Instance.DriveSeat.Flip.MaxTorque = 0
		end
	end

	-- Save PBrake state
	-- car["A-Chassis Tune"]["A-Chassis Interface"].Values.PBrake.Value = _PBrake

	for _, wheel in self.Wheels do
		wheel:Destroy()
	end

	-- Reintroduce touch controls
	if self.Tune.Mobile then GuiService.TouchControlsEnabled = true end

	-- Tell server to remove
	-- car["A-Chassis Tune"].Shutdown:FireServer()

	self.Interface:Destroy()

	for _, plugin in self.Plugins do
		plugin:Destroy()
	end

	for _, conn in self._conn do
		conn:Disconnect()
	end
	task.cancel(self._task)
end

return ClientVehicle
