local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BaseVehicle = require(script.Parent.BaseVehicle)
local DeformationController = require(script.DeformationController)
local InputController = require(script.InputController)
local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local Lights = require(script.Lights)
local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local ReplicationVars = require(script.ReplicationVars)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local UpdateEngine = require(script.UpdateEngine)
local UpdateSteering = require(script.UpdateSteering)
local UpdateTransmission = require(script.UpdateTransmission)
local VehicleInterface = require(ReplicatedStorage.Shared.UI.VehicleInterface)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)
local Wheel = require(script.Wheel)

local player = Players.LocalPlayer

local DatastoreController = require(player.PlayerScripts.Client.Controllers.DatastoreController)
local PlayerModule = require(player.PlayerScripts.PlayerModule) :: any

local ClientVehicle = setmetatable({}, BaseVehicle)
ClientVehicle.__index = ClientVehicle

type ClientVehicle = VehicleTypes.ClientVehicle

function ClientVehicle.new(instance: Instance)
	local self: VehicleTypes.ClientVehicle = setmetatable(BaseVehicle.new(instance), ClientVehicle) :: any

	self.InputController = InputController.new(self)

	self:Initialize()

	self.DeformationController = DeformationController.new(self)
	self.Interface = VehicleInterface.new(self)
	self.Lights = Lights.new(self)

	return self
end

function ClientVehicle.Initialize(self: ClientVehicle)
	self:InitializeVariables()
	hideCharacter(self)
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
	self.BrakeForce = {
		Front = self.Tune.BrakeForce * 9.80665 * Units.Force_N * self.Tune.BrakeBias,
		Rear = self.Tune.BrakeForce * 9.80665 * Units.Force_N * (1 - self.Tune.BrakeBias),
	}
	self.PBrakeForce = {
		Front = self.Tune.PBrakeForce * 9.80665 * Units.Force_N * self.Tune.PBrakeBias,
		Rear = self.Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - self.Tune.PBrakeBias),
	}
	self._conn = {}
	self._ShiftUp = false
	self._ShiftDown = false
	self._ClutchPressing = false
		self._GoalRPM = 0
	self._DriveWheelSpeed = 0
	self._CanStall = false
		self._LastOffTime = tick()
	self._OldVelocity = Vector3.new()
	self._MaxSpin = 0
	self._LastInputWasGamepad = string.find(UserInputService:GetLastInputType().Name, "Gamepad") and true or false
end

function ClientVehicle.InitializeWheels(self: ClientVehicle) BaseVehicle.InitializeWheels(self, Wheel) end

function ClientVehicle.InitializePlugins(self: ClientVehicle)
	for _, plugin in ReplicatedStorage.Shared.Vehicle.Plugins:GetChildren() do
		local pluginClass = require(plugin) :: any
		if pluginClass and pluginClass.new then self.Plugins[plugin.Name] = pluginClass.new(self) end
	end
end

-- Hides character for a while
function hideCharacter(self: ClientVehicle)
	for _, v in player.Character:GetDescendants() do
		if not v:IsA("BasePart") then continue end

		v.Transparency = 1
	end
end

-- TODO: Add VirtualInput & Mobile
function ClientVehicle.InitControls(self: ClientVehicle)
	self.Controls = DatastoreController:GetControls()

	-- Disable jumping
	PlayerModule:GetControls():GetActiveController().jumpEnabled = false

	table.insert(
		self._conn,
		UserInputService.LastInputTypeChanged:Connect(
			function(inputType) self._LastInputWasGamepad = string.find(inputType.Name, "Gamepad") and true or false end
		)
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

-- TODO: Steering Initialize
-- function ClientVehicle.InitSteeringAuto(self: ClientVehicle)
-- 	self.SteerOuter = (self.Tune.LockToLock * 180) / self.Tune.SteerRatio
-- 	self.SteerInner = math.min(self.SteerOuter - (self.SteerOuter * (1 - self.Tune.Ackerman)), self.SteerOuter * 1.2)
-- end

function ClientVehicle.UpdateWheels(self: ClientVehicle)
	local count = #self.Wheels
	local driveCount = 0

	local data: VehicleTypes.ClientWheelSharedData = {
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
	for _, wheel in self.Wheels :: { VehicleTypes.ClientWheel } do
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
	if not self.Tune.Engine or self.Broken then return end

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

function ClientVehicle.UpdateHealth(self: ClientVehicle, deltaTime: number)
	if not self.Tune.Engine or self.Tune.Electric or not self.IsOn then return end

	local damage = self.Tune.RPMDamage * (self.RPM / self.Tune.Redline) ^ 2 / 3600
	damage += (math.max(self.RPM - self.Tune.Redline, 0) / 1000) ^ self.Tune.RedlineDamageCurve * self.Tune.RedlineDamage
	damage += self.Tune.HotDamage * math.clamp(
		MapToRange(self.Temperature, self.Tune.OperatingEngineTemp, self.Tune.EngineBurnTemp),
		0,
		1
	) ^ 1.5
	self.EngineHealth -= damage * deltaTime

	if self.EngineHealth <= 0 then
		self.EngineHealth = 0
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

function ClientVehicle.ReplicateVariables(self: ClientVehicle)
	local data = {}
	for _, var in ReplicationVars do
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
	UpdateSteering(self, deltaTime)
	UpdateTransmission(self)
	UpdateEngine(self, deltaTime)
	self:UpdateFuel(deltaTime)
	self:UpdateTemp(deltaTime)
	self:UpdateHealth(deltaTime)
	self:ReplicateVariables()
end

-- TODO
function ClientVehicle.SlowUpdate(self: ClientVehicle) end

function ClientVehicle.Destroy(self: ClientVehicle)
	PlayerModule:GetControls():GetActiveController().jumpEnabled = true

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

	for _, wheel in self.Wheels :: { VehicleTypes.BaseWheel } do
		wheel:Destroy()
	end

	-- Reintroduce touch controls
	if self.Tune.Mobile then GuiService.TouchControlsEnabled = true end

	-- Tell server to remove
	-- car["A-Chassis Tune"].Shutdown:FireServer()

	self.InputController:Destroy()
	self.Interface:Destroy()
	self.Lights:Destroy()

	for _, plugin in self.Plugins do
		plugin:Destroy()
	end

	for _, conn in self._conn do
		conn:Disconnect()
	end
	task.cancel(self._task)
end

return ClientVehicle
