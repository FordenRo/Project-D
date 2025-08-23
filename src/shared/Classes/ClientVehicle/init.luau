local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseVehicle = require(script.Parent.BaseVehicle)
local DeformationController = require(script.DeformationController)
local Engine = require(script.Engine)
local InputController = require(script.InputController)
local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local Lights = require(script.Lights)
local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local ReplicationVars = require(script.ReplicationVars)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local UpdateSteering = require(script.UpdateSteering)
local UpdateTransmission = require(script.UpdateTransmission)
local VehicleInterface = require(ReplicatedStorage.Shared.UI.VehicleInterface)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)
local Wheel = require(script.Wheel)

local player = Players.LocalPlayer

local ClientVehicle = setmetatable({}, BaseVehicle)
ClientVehicle.__index = ClientVehicle

type ClientVehicle = VehicleTypes.ClientVehicle

function ClientVehicle.new(instance: Instance)
	local self: VehicleTypes.ClientVehicle = setmetatable(BaseVehicle.new(instance), ClientVehicle) :: any

	self.InputController = InputController.new(self)

	Initialize(self)

	self.Engine = Engine.new(self)
	self.DeformationController = DeformationController.new(self)
	self.Interface = VehicleInterface.new(self)
	self.Lights = Lights.new(self)

	table.insert(self._cons, RunService.Heartbeat:Connect(function(deltaTime) Update(self, deltaTime) end))
	self._task = task.spawn(function()
		while task.wait(1 / 8) do
			SlowUpdate(self)
		end
	end)

	return self
end

function Initialize(self: ClientVehicle)
	InitializeVariables(self)
	HideCharacter(self)
	self:InitializeWheels()
	InitializePlugins(self)
end

function InitializeVariables(self: ClientVehicle)
	self.BrakeForce = {
		Front = self.Tune.BrakeForce * 9.80665 * Units.Force_N * self.Tune.BrakeBias,
		Rear = self.Tune.BrakeForce * 9.80665 * Units.Force_N * (1 - self.Tune.BrakeBias),
	}
	self.PBrakeForce = {
		Front = self.Tune.PBrakeForce * 9.80665 * Units.Force_N * self.Tune.PBrakeBias,
		Rear = self.Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - self.Tune.PBrakeBias),
	}
	self._cons = {}
	self._ShiftUp = false
	self._ShiftDown = false
	self._ClutchPressing = false
	self._DriveWheelSpeed = 0
	self._OldVelocity = Vector3.new()
	self._MaxSpin = 0
end

function ClientVehicle.InitializeWheels(self: ClientVehicle) BaseVehicle.InitializeWheels(self, Wheel) end

function InitializePlugins(self: ClientVehicle)
	for _, plugin in ReplicatedStorage.Shared.Vehicle.Plugins:GetChildren() do
		local pluginClass = require(plugin) :: any
		if pluginClass and pluginClass.new then self.Plugins[plugin.Name] = pluginClass.new(self) end
	end
end

-- Hides character for a while
function HideCharacter(self: ClientVehicle)
	for _, v in player.Character:GetDescendants() do
		if not v:IsA("BasePart") then continue end

		v.Transparency = 1
	end
end

-- TODO: Drivetrain Initialize

-- TODO: Steering Initialize
-- function ClientVehicle.InitSteeringAuto(self: ClientVehicle)
-- 	self.SteerOuter = (self.Tune.LockToLock * 180) / self.Tune.SteerRatio
-- 	self.SteerInner = math.min(self.SteerOuter - (self.SteerOuter * (1 - self.Tune.Ackerman)), self.SteerOuter * 1.2)
-- end

function UpdateWheels(self: ClientVehicle)
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
function UpdateFuel(self: ClientVehicle, deltaTime: number)
	if not self.Tune.Engine or self.Tune.Electric or not self.IsOn then return end

	local kW = self.Engine.Horsepower * 1.35962
	local consumption = self.Tune.BSFC * kW / 3600 / 1000 / self.Tune.FuelDensity * deltaTime
	self.Fuel = math.max(0, self.Fuel - consumption)

	if self.Fuel <= 0 then self.IsOn = false end
end

function UpdateTemp(self: ClientVehicle, deltaTime: number)
	if not self.Tune.Engine or self.Engine.Broken then return end

	local kW = self.Engine.Horsepower / 1.35962
	local heat = kW * Lerp(1, 2, self.RPM / self.Tune.Redline) / 120
	local tDelta = self.Temperature - (game.Workspace:GetAttribute("GlobalTemperature") :: number)
	local cooling = tDelta * 0.015
	cooling += (self.Velocity.Magnitude / Units.Velocity_mdivs) ^ 2 * tDelta / 100000 * 0.8
	self.Temperature += (heat - cooling) * deltaTime

	if self.Temperature > self.Tune.EngineBurnTemp then
		self.IsOn = false
		self.Engine.Broken = true
		self.DeformationController:BlowEngine()
	end
end

function UpdateHealth(self: ClientVehicle, deltaTime: number)
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
		self.Engine.Broken = true
		self.DeformationController:BlowEngine()
	end
end

-- TODO: Flip function

function ReplicateVariables(self: ClientVehicle)
	local data = {}
	for _, var in ReplicationVars do
		data[var] = self[var]
	end
	self._Remote:FireServer(data)
end

function Update(self: ClientVehicle, deltaTime: number)
	self.Center = self:GetCenter()
	self.Velocity = self.Instance.Body["#Weight"].AssemblyLinearVelocity
	self.AngularVelocity = self.Instance.Body["#Weight"].AssemblyAngularVelocity
	self.Acceleration = (self.Velocity - self._OldVelocity) * (1 / deltaTime)
	self._OldVelocity = self.Velocity
	self.Mileage += self.Velocity.Magnitude * (Units.Length_mm / 1000) / 1000 * deltaTime

	UpdateWheels(self)
	UpdateSteering(self, deltaTime)
	UpdateTransmission(self)
	self.Engine:Update(deltaTime)
	UpdateFuel(self, deltaTime)
	UpdateTemp(self, deltaTime)
	UpdateHealth(self, deltaTime)
	ReplicateVariables(self)
end

-- TODO
function SlowUpdate(self: ClientVehicle) end

function ClientVehicle.Destroy(self: ClientVehicle)
	--Remove Flip Force
	if self.Instance.DriveSeat:FindFirstChild("Flip") then
		if self.Tune.FlipType == "New" then
			self.Instance.DriveSeat.Flip.Enabled = false
		else
			self.Instance.DriveSeat.Flip.MaxTorque = 0
		end
	end

	for _, wheel in self.Wheels :: { VehicleTypes.BaseWheel } do
		wheel:Destroy()
	end

	self.Engine:Destroy()
	self.InputController:Destroy()
	self.Interface:Destroy()
	self.Lights:Destroy()

	for _, plugin in self.Plugins do
		plugin:Destroy()
	end

	for _, conn in self._cons do
		conn:Disconnect()
	end
	task.cancel(self._task)
end

return ClientVehicle
