local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Component = require(script.Parent.Component)
local EngineTune =
	require(ReplicatedStorage.Shared.Types.VehicleTypes.EngineTune)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)
local VehiclePackets = require(ReplicatedStorage.Shared.Packets.VehiclePackets)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local BaseVehicle = { get = {}, set = {} }
BaseVehicle.__extends = Component

type BaseVehicle = VehicleTypes.BaseVehicle

function BaseVehicle.new(instance: Instance): BaseVehicle
	local self: BaseVehicle = Component(BaseVehicle) :: any

	self.Instance = instance :: any
	self.Tune = require(
		assert(
			ReplicatedStorage.Shared.Vehicle.Tunes:FindFirstChild(instance.Name),
			"Tune not found for vehicle: " .. instance.Name
		) :: any
	) :: TuneType.Tune

	InitializeVariables(self)

	if RunService:IsServer() then
		self.URE = Instance.new("UnreliableRemoteEvent")
		self.URE.Name = "VehicleURE"
		self.URE.Parent = self.Instance

		self.RE = Instance.new("RemoteEvent")
		self.RE.Name = "VehicleRE"
		self.RE.Parent = self.Instance

		self.RF = Instance.new("RemoteFunction")
		self.RF.Name = "VehicleRF"
		self.RF.Parent = self.Instance
	else
		self.URE =
			self.Instance:WaitForChild("VehicleURE") :: UnreliableRemoteEvent
		self.RE = self.Instance:WaitForChild("VehicleRE") :: RemoteEvent
		self.RF = self.Instance:WaitForChild("VehicleRF") :: RemoteFunction
	end

	return self
end

function InitializeVariables(self: BaseVehicle)
	local ParkingGearEnabled = self.Tune.Ratios[1] == 0

	self.Driver = nil
	self.Passengers = {}
	self.Fuel = self.Tune.FuelCapacity
	self.FanSpeed = 0
	self.Dirt = 0
	self.Horning = false
	self.Mileage = 0
	-- Transmission
	self.Clutch = 0
	self.Gear = ParkingGearEnabled and -2 or 0
	self.FinalDrive = self.Tune.FinalDrive * self.Tune.FDMult
	self.FinalDriveRatio = self.FinalDrive * 30 / math.pi
	self.TransmissionMode = "Manual"
	self.CurrentRatio =
		self.Tune.Ratios[self.Gear + 2 + (ParkingGearEnabled and 1 or 0)]
	self.RPM = 0
	self.Shifting = false
	self.AutoClutch = false
	-- Inputs
	self.Throttle = 0
	self.Brake = 0
	self.Steering = 0
	self.PBrake = false
	-- Misc
	self.TCS = self.Tune.TCSEnabled
	self.TCSActive = false
	self.ABS = self.Tune.ABSEnabled
	self.ABSActive = false
	self.ESC = self.Tune.ESCEnabled and self.Tune.TCSEnabled
	self.ESCActive = false
	self.CS = self.Tune.CSEnabled
	self.CSActive = false
	self.IgnitionState = "Off"
end

function BaseVehicle._Replicate(self: BaseVehicle, buf: buffer)
	for k, v in Serialization.Deserialize(VehiclePackets.Update, buf) do
		if k == "Engine" then
			for ek, ev in v do
				self[k][ek] = ev
			end
			continue
		elseif k == "Fuel" then
			self[k] = v * self.Tune.FuelCapacity
			continue
		end

		self[k] = v
	end

	local engineTune = require(
		ReplicatedStorage.Shared.Vehicle.Engines:FindFirstChild(
			self.Tune.Engine
		)
	) :: EngineTune.Engine

	local x = self.RPM / 1000
	self.Engine.Boost = self.Engine.BoostTurbo + self.Engine.BoostSuper

	self.Engine.TqTurbo = self.Engine.BoostTurbo * engineTune.T_Efficiency
	self.Engine.TqSuper = self.Engine.BoostSuper * engineTune.S_Efficiency
	self.Engine.TqBoosted = self.Engine.TqTurbo + self.Engine.TqSuper
	self.Engine.Torque = self.Engine.TqNatural
		+ self.Engine.TqElectric
		+ self.Engine.TqBoosted

	self.Engine.HpNatural = self.Engine.TqNatural * x / 5.252
	self.Engine.HpTurbo = self.Engine.TqTurbo * x / 5.252
	self.Engine.HpSuper = self.Engine.TqSuper * x / 5.252
	self.Engine.HpBoosted = self.Engine.HpTurbo + self.Engine.HpSuper
	self.Engine.Horsepower = self.Engine.Torque * x / 5.252
end

function BaseVehicle.get.Center(self: BaseVehicle)
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0
	for _, v in self.Instance.Wheels:GetChildren() do
		if not v:IsA("BasePart") then continue end
		if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
			centerF = centerF + v.CFrame.Position
			countF = countF + 1
		else
			centerR = centerR + v.CFrame.Position
			countR = countR + 1
		end
	end
	centerF = centerF / countF
	centerR = centerR / countR
	local center = CFrame.lookAt(centerR:Lerp(centerF, 0.5), centerF)
	return center
end

function BaseVehicle.get.CFrame(self: BaseVehicle) return self.WeightPart.CFrame end

function BaseVehicle.get.Velocity(self: BaseVehicle)
	return self.WeightPart.AssemblyLinearVelocity
end

function BaseVehicle.get.AngularVelocity(self: BaseVehicle)
	return self.WeightPart.AssemblyAngularVelocity
end

function BaseVehicle.set.CFrame(self: BaseVehicle, cframe: CFrame)
	self.Instance:PivotTo(cframe)
end

return table.freeze(BaseVehicle :: any) :: {
	new: (instance: Instance) -> BaseVehicle,
}
