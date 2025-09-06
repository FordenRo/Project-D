local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseWheel = require(ReplicatedStorage.Shared.Classes.BaseWheel)
local BrakeDisk = require(script.BrakeDisk)
local Tire = require(script.Tire)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ClientWheel = setmetatable({}, BaseWheel)
ClientWheel.__index = ClientWheel

type ClientWheel = VehicleTypes.ClientWheel

function ClientWheel.new(vehicle: VehicleTypes.ClientVehicle, instance: BasePart): ClientWheel
	local self: ClientWheel = setmetatable(BaseWheel.new(vehicle, instance), ClientWheel) :: any

	self.Trackers = {
		ABS = 0,
		TCS = 0,
		ESC = 0,
	}

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
	self.BrakeDisk = BrakeDisk.new(self, self.Instance.Parts.BrakeDisk)

	return self
end

function ClientWheel.Update(self: ClientWheel, deltaTime: number, data: VehicleTypes.ClientWheelSharedData)
	-- Wheel speeds
	table.insert(
		self._WheelSpeeds,
		self.Instance.CFrame:VectorToObjectSpace(self.Instance.AssemblyAngularVelocity).X * (self.IsRight and 1 or -1)
	)
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

	ApplySteering(self, deltaTime)
end

function ApplySteering(self: ClientWheel, deltaTime: number)
	if self.CanSteer == 0 then return end

	local angle = 0
	local rsteerVariableAngle = 1
	if typeof(self.Vehicle.Steering) ~= "number" then return end

	if self.CanSteer == 2 then
		if self.Instance.Name == "FL" then
			angle = self.Vehicle.Steering < 0 and self.Vehicle.Tune.SteerInner or self.Vehicle.Tune.SteerOuter
		elseif self.Instance.Name == "FR" then
			angle = self.Vehicle.Steering < 0 and self.Vehicle.Tune.SteerOuter or self.Vehicle.Tune.SteerInner
		elseif self.Instance.Name == "F" then
			angle = self.Vehicle.Tune.SteerInner
		elseif self.Instance.Name == "RL" then
			angle = self.Vehicle.Steering < 0 and self.Vehicle.Tune.RSteerInner or self.Vehicle.Tune.RSteerOuter
		elseif self.Instance.Name == "RR" then
			angle = self.Vehicle.Steering < 0 and self.Vehicle.Tune.RSteerOuter or self.Vehicle.Tune.RSteerInner
		elseif self.Instance.Name == "R" then
			angle = self.Vehicle.Tune.RSteerInner
		end
		if not self.IsFront then
			if self.Vehicle.Tune.FWSteer == "Static" then
				rsteerVariableAngle =
					-math.max(0, 1 - (self.Vehicle.Velocity.Magnitude / self.Vehicle.Tune.RSteerSpeed))
			elseif self.Vehicle.Tune.FWSteer == "Speed" then
				rsteerVariableAngle = math.min(1, (self.Vehicle.Velocity.Magnitude / self.Vehicle.Tune.RSteerSpeed))
			elseif self.Vehicle.Tune.FWSteer == "Both" then
				rsteerVariableAngle =
					-math.max(-1, 1 - (self.Vehicle.Velocity.Magnitude / self.Vehicle.Tune.RSteerSpeed))
			end
		end
	end

	if self.Vehicle.Tune.PowerSteeringType == "New" then
		self.Instance.Arm.SteerAttach0.Orientation =
			Vector3.new(0, self.CanSteer == 1 and 0 or self.Vehicle.Steering * angle * rsteerVariableAngle, 0)
	else
		(self.Instance.Arm.Steer :: BodyGyro).CFrame = self.Instance.Base.CFrame
			* (
				self.CanSteer == 1 and CFrame.new(0, 0, 0)
				or (CFrame.Angles(0, -math.rad(self.Vehicle.Steering * angle * rsteerVariableAngle), 0))
			)
	end
end

function ClientWheel.Destroy(self: ClientWheel)
	if self.Instance.AV then
		self.Instance.AV.MotorMaxTorque = 0
		self.Instance.AV.AngularVelocity = 0
	end
	if self.Instance.BV then
		local ParkingGearEnabled = self.Vehicle.Tune.Ratios[1] == 0
		if ParkingGearEnabled then
			self.Vehicle.Gear = -2
		else
			self.Vehicle.PBrake = true
		end
		if self.IsFront then
			self.Instance.BV.MotorMaxTorque = self.Vehicle.Tune.ExitBrake and self.Vehicle.PBrakeForce.Front or 0
		else
			self.Instance.BV.MotorMaxTorque = self.Vehicle.Tune.ExitBrake and self.Vehicle.PBrakeForce.Rear or 0
		end
	end

	self.Tire:Destroy()
	self.BrakeDisk:Destroy()
end

return ClientWheel
