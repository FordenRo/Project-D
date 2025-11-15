local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local EngineTune =
	require(ReplicatedStorage.Shared.Types.VehicleTypes.EngineTune)
local Serialization = require(script.Parent.Serialization)
local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)
local VehiclePackets = require(ReplicatedStorage.Shared.Packets.VehiclePackets)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)
local VehicleUtil = {}

function VehicleUtil.Setup(self: VehicleTypes.VehicleTable, instance: Instance)
	self.Instance = instance :: any
	self.Tune = require(
		assert(
			ReplicatedStorage.Shared.Vehicle.Tunes:FindFirstChild(instance.Name),
			"Tune not found for vehicle: " .. instance.Name
		) :: any
	) :: TuneType.Tune

	self.Passengers = {}
	self.Fuel = self.Tune.FuelCapacity
	self.FanSpeed = 0
	self.Dirt = 0
	self.Horning = false
	self.Mileage = 0
	-- Transmission
	local ParkingGearEnabled = self.Tune.Ratios[1] == 0
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

function VehicleUtil.InitializeWheels(
	self: VehicleTypes.ClientVehicle | VehicleTypes.ServerVehicle
)
	local wheelBase: any = RunService:IsServer()
			and require(ServerScriptService.Server.Classes.ServerVehicle.Wheel)
		or require(ReplicatedStorage.Shared.Classes.ClientVehicle.Wheel)

	self:RawSet("Wheels", {})

	local wheelNames = { "F", "FL", "FR", "R", "RL", "RR" }
	for _, v in self.Instance.Wheels:GetChildren() do
		if not v:IsA("BasePart") or not table.find(wheelNames, v.Name) then
			continue
		end

		table.insert(self.Wheels, wheelBase.new(self, v))
	end
end

function VehicleUtil.Replicate(self: VehicleTypes.VehicleTable, buf: buffer)
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

function VehicleUtil.GetCenter(self: VehicleTypes.VehicleTable)
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0

	for _, v in self.Instance.Wheels:GetChildren() do
		if not v:IsA("BasePart") then continue end

		if table.find({ "F", "FR", "FL" }, v.Name) then
			centerF = centerF + v.CFrame.Position
			countF = countF + 1
		elseif table.find({ "R", "RR", "RL" }, v.Name) then
			centerR = centerR + v.CFrame.Position
			countR = countR + 1
		end
	end
	centerF = centerF / countF
	centerR = centerR / countR

	return CFrame.lookAt(centerR:Lerp(centerF, 0.5), centerF)
end

return table.freeze(VehicleUtil)
