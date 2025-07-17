local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tire = require(script.Tire)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

local Wheel = {}
Wheel.__index = Wheel

type Wheel = Types.ClientWheel

function Wheel.new(vehicle: Types.ClientVehicle, instance: BasePart)
	local self: Wheel = setmetatable({}, Wheel) :: any

	self.Vehicle = vehicle
	self.Instance = instance :: any
	self.Trackers = {
		ABS = 0,
		TCS = 0,
		ESC = 0,
	}

	self.IsFront = string.find(self.Instance.Name, "F") ~= nil
	self.IsDriven = ((self.Vehicle.Tune.Config == "FWD" or self.Vehicle.Tune.Config == "AWD") and self.IsFront)
		or ((self.Vehicle.Tune.Config == "RWD" or self.Vehicle.Tune.Config == "AWD") and not self.IsFront)

	self.OppositeWheel = (
		(self.Instance.Name == "FL" and self.Vehicle.Instance.Wheels:FindFirstChild("FR"))
		or (self.Instance.Name == "FR" and self.Vehicle.Instance.Wheels:FindFirstChild("FL"))
		or (self.Instance.Name == "RL" and self.Vehicle.Instance.Wheels:FindFirstChild("RR"))
		or (self.Instance.Name == "RR" and self.Vehicle.Instance.Wheels:FindFirstChild("RL"))
	) :: BasePart

	self.CanSteer = 0
	self._WheelSpeeds = {}

	-- Check if can steer
	if self.Instance:FindFirstChild("Arm") and (self.Instance.Arm :: any):FindFirstChild("Steer") then
		self.CanSteer = 1
		if not ((self.Instance.Arm :: any).Steer :: Instance):GetAttribute("SteerDisabled") then self.CanSteer = 2 end
	end

	self.Tire = Tire.new(self, self.Instance.Parts.Tire)

	return self
end

function Wheel.Update(self: Wheel, data: Types.ClientWheelSharedData)
	-- Wheel speeds
	table.insert(self._WheelSpeeds, self.Instance.AssemblyAngularVelocity.Magnitude)
	if #self._WheelSpeeds > 8 then table.remove(self._WheelSpeeds, 1) end
	local avg = 0
	local avgCount = 0
	for _, a in self._WheelSpeeds do
		avg += a
		avgCount += 1
	end
	avg = avg / avgCount
	-- _WheelSpeeds[data.Name] = avg
	if self.IsDriven then
		if avg > data.MaxSpin then data.MaxSpin = avg end
		data.DriveWheelSpeed += avg
		data.MaxSpin = math.max(data.MaxSpin, avg)
	end

	-- Output wheel speeds
	-- (Forden) Changed to avg
	-- data.WheelSpeedValue.Value = avg -- I'm not using the avg variable here for future-proofing if we change the calculation later and stuff
	data.Rotation += avg * (self.Instance.Size.Y / 2)

	-- TCS
	if self.Trackers.TCS then
		data.TCSCount += 1
	end

	-- ABS
	if self.Trackers.ABS then
		data.ABSCount += 1
	end

	-- ESC
	if self.Trackers.ESC then
		data.ESCCount += 1
	end
end

function Wheel.Destroy(self: Wheel)
	if self.Instance["#AV"] then
		self.Instance["#AV"].MotorMaxTorque = 0
		self.Instance["#AV"].AngularVelocity = 0
	end
	if self.Instance["#BV"] then
		if self.Vehicle.ParkingGearEnabled then
			self.Vehicle.Gear = -2
		else
			self.Vehicle.PBrake = true
		end
		if self.IsFront then
			self.Instance["#BV"].MotorMaxTorque = self.Vehicle.Tune.ExitBrake and self.Vehicle.PBrakeForce.Front or 0
		else
			self.Instance["#BV"].MotorMaxTorque = self.Vehicle.Tune.ExitBrake and self.Vehicle.PBrakeForce.Rear or 0
		end
	end

	self.Tire:Destroy()
end

return Wheel
