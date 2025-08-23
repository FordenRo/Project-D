local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local BaseVehicle = {}
BaseVehicle.__index = BaseVehicle

type BaseVehicle = VehicleTypes.BaseVehicle

function BaseVehicle.new(instance: Instance)
	local self: BaseVehicle = setmetatable({}, BaseVehicle) :: any

	self.Instance = instance :: any
	self.Tune = require(
		assert(
			ReplicatedStorage.Shared.Vehicle.Tunes:FindFirstChild(instance.Name),
			"Tune not found for vehicle: " .. instance.Name
		) :: any
	) :: VehicleTypes.Tune

	InitializeVariables(self)

	if RunService:IsServer() then
		self._Remote = Instance.new("UnreliableRemoteEvent")
		self._Remote.Name = "_VehicleRemote"
		self._Remote.Parent = self.Instance
	else
		self._Remote = self.Instance:WaitForChild("_VehicleRemote") :: UnreliableRemoteEvent
	end

	return self
end

function InitializeVariables(self: BaseVehicle)
	local ParkingGearEnabled = self.Tune.Ratios[1] == 0

	self.IsOn = false
	self.Starting = false
	self.Occupant = nil
	self.Fuel = 1
	self.FanSpeed = 0
	self.Dirt = 0
	self.Plugins = {}
	self.Wheels = {}
	self.Horning = false
	-- Transmission
	self.Clutch = 0
	self.Gear = ParkingGearEnabled and -2 or 0
	self.FinalDrive = self.Tune.FinalDrive * self.Tune.FDMult
	self.FinalDriveRatio = self.FinalDrive * 30 / math.pi
	self.TransmissionMode = "Manual"
	self.CurrentRatio = self.Tune.Ratios[self.Gear + 2 + (ParkingGearEnabled and 1 or 0)]
	self.RPM = 0
	self.Shifting = false
	self.AutoClutch = false
	-- Inputs
	self.Throttle = 0
	self.Brake = 0
	self.Steering = 0
	self.PBrake = false
	-- Velocity
	self.Velocity = Vector3.new()
	self.AngularVelocity = Vector3.new()
	self.AverageRotSpeed = 0
	self.Acceleration = Vector3.new()
	self.Mileage = 0
	-- Misc
	self.Center = CFrame.new()
	self.TCS = self.Tune.TCSEnabled
	self.TCSActive = false
	self.ABS = self.Tune.ABSEnabled
	self.ABSActive = false
	self.ESC = self.Tune.ESCEnabled and self.Tune.TCSEnabled
	self.ESCActive = false
	self.CS = self.Tune.CSEnabled
	self.CSActive = false
end

function BaseVehicle.InitializeWheels(self: BaseVehicle, wheelClass: VehicleTypes.BaseWheel)
	local wheelNames = { "F", "FL", "FR", "R", "RL", "RR" }
	for _, v in self.Instance.Wheels:GetChildren() do
		if not v:IsA("BasePart") or not table.find(wheelNames, v.Name) then continue end

		table.insert(self.Wheels, wheelClass.new(self, v))
	end
end

function BaseVehicle.GetCenter(self: BaseVehicle)
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

return BaseVehicle
