--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EngineTable = require(script.Parent.EngineTable)
local EngineTune = require(ReplicatedStorage.Shared.Types.VehicleTypes.EngineTune)
local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleConstants = require(ReplicatedStorage.Shared.Vehicle.VehicleConstants)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Engine = {}
Engine.__index = Engine

type Engine = VehicleTypes.Engine

function Engine.new(vehicle: VehicleTypes.ClientVehicle): Engine
	local self: Engine = setmetatable(table.clone(EngineTable), Engine) :: any

	self.Vehicle = vehicle
	self.Tune = require(
		assert(
			ReplicatedStorage.Shared.Vehicle.Engines:FindFirstChild(self.Vehicle.Tune.Engine),
			"Engine tune not found for vehicle: " .. self.Vehicle.Instance.Name
		) :: any
	) :: EngineTune.Engine
	self.Throttle = 0
	self.Brake = 0
	self.Clutch = 0
	self._GoalRPM = 0
	self._FuelSupply = 0
	self._LastOnTime = 0
	self._LastOffTime = 0
	self._RevLimiting = false

	return self
end

function calcPower(m: number, n: number, p: number, q: number, M: number, b: number, x: number)
	return math.clamp(M - ((q - n) / (b ^ p - b ^ m) * (b ^ x - b ^ m) + n), 0, M)
end

function Engine.Update(self: Engine, deltaTime: number)
	deltaTime = math.max(60 / (1 / deltaTime), 1 / 1000)

	local driveWheelSpeed = 0
	local driveCount = 0
	for _, wheel in self.Vehicle.Wheels :: { VehicleTypes.ClientWheel } do
		if not wheel.IsDriven then continue end

		driveWheelSpeed += wheel.Instance.CFrame:VectorToObjectSpace(wheel.Instance.AssemblyAngularVelocity).X * (wheel.IsRight and 1 or -1)
		driveCount += 1
	end
	driveWheelSpeed /= driveCount

	local ParkingGearEnabled = self.Vehicle.Tune.Ratios[1] == 0
	local wheelRPM = driveWheelSpeed
		* self.Vehicle.CurrentRatio
		* self.Vehicle.FinalDriveRatio
		* math.sign(self.Vehicle.Gear)

	-- CVT
	local CVTRatio
	if self.Vehicle.Tune.ClutchType == "CVT" then
		CVTRatio = math.clamp(
			(self.Vehicle.Tune.CVTRPM * self.Throttle) / (math.abs(driveWheelSpeed) * self.Vehicle.FinalDriveRatio),
			self.Vehicle.Tune.CVTMinRatio,
			self.Vehicle.Tune.CVTMaxRatio
		)
	end

	-- Update ratio
	self.Vehicle.CurrentRatio = self.Vehicle.Tune.ClutchType == "CVT" and CVTRatio
		or self.Vehicle.Tune.Ratios[self.Vehicle.Gear + 2 + (ParkingGearEnabled and 1 or 0)]

	-- Flywheel/clutch-dumping
	local flywheelEnergy = (self.Vehicle.RPM - wheelRPM)
		* self.Tune.DumpMult
		* (1 - self.Clutch)
		* 1.356
		* Units.Torque_nm
	self.DriveshaftStress = math.abs(flywheelEnergy / 3000) ^ 2

	-- Determine RPM
	local revMin = 0
	local goalMin = 0
	local goalMax = self.Tune.Redline

	if self.Vehicle.Shifting and self.Vehicle._ShiftUp then
		self.Throttle = self.Tune.IdleThrottle / 100
	elseif self.Vehicle.Shifting and self.Vehicle._ShiftDown then
		self.Throttle = self.Vehicle.Tune.ShiftThrot / 100
	else
		self.Throttle = math.max(self.Vehicle.Throttle, self.Tune.IdleThrottle / 100)
	end

	if self.Vehicle.IsOn then
		self._LastOnTime = tick()
	else
		self._LastOffTime = tick()
		if self.Vehicle.AutoClutch then self.Clutch = 1 end
		self.Throttle = 0
	end

	if
		self.Vehicle.Clutch > 0
		and (
			(self.Vehicle.Gear == 0 or (ParkingGearEnabled and self.Vehicle.Gear == -2))
				and self.Vehicle.Tune.NeutralLimit
			or self.Vehicle.Tune.NeutralLimit and self.Vehicle.Tune.LimitClutch
		)
	then
		goalMax = Lerp(self.Tune.Redline, self.Vehicle.Tune.NeutralRevRPM, self.Vehicle.Clutch)
	end

	-- Rev limiter/speed limiter
	if self.Vehicle.RPM >= self.Tune.Redline then
		self._RevLimiting = true
	elseif self.Vehicle.RPM < goalMax - self.Tune.RevBounce then
		self._RevLimiting = false
	end
	if self._RevLimiting then self.Throttle = self.Tune.IdleThrottle / 100 end

	local speedLimit = self.Vehicle.Gear < 0 and self.Vehicle.Tune.ReverseSpeed or self.Vehicle.Tune.SpeedLimit
	if speedLimit > 0 then
		self.Throttle = math.min(
			self.Throttle,
			math.max(
				1
					- math.clamp(
						(
							(self.Vehicle.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6))
							- (speedLimit - self.Vehicle.Tune.SLimitGradient)
						) / self.Vehicle.Tune.SLimitGradient,
						0,
						1
					),
				self.Tune.IdleThrottle / 100
			)
		)
	end
	if self.Vehicle.Tune.SLimitBrake then
		self.Brake = math.max(
			self.Vehicle.Brake,
			(self.Vehicle.Tune.SLimitBrake and speedLimit > 0)
					and math.clamp(
						(self.Vehicle.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) - speedLimit)
							/ self.Vehicle.Tune.SLimitGradient,
						0,
						1
					)
				or 0
		)
	end

	-- Idle
	if self.Vehicle.RPM < self.Tune.IdleRPM + (self.Tune.IdlePadding or 0) and self.Vehicle.IsOn then
		self.Throttle = math.max(
			self.Throttle,
			math.clamp(
				(self.Tune.IdleRPM + (self.Tune.IdlePadding or 0) - self.Vehicle.RPM) / (self.Tune.IdleDamping or 400),
				0,
				1
			)
		)
	end

	-- Apply fuel supply
	self.Throttle *= self._FuelSupply

	if (self.Vehicle.Tune.Engine or self.Tune.Electric) and not self.Vehicle.Starting then
		self._GoalRPM = math.clamp(
			self.Vehicle.RPM
				- (self.Tune.RevDecay * deltaTime)
				+ (self.Tune.RevAccel * self.Throttle * deltaTime)
				- (
					math.clamp(
						math.max(self.Vehicle.RPM - self.Tune.IdleRPM, 0)
							/ math.max(self.Tune.Redline - self.Tune.IdleRPM, 1),
						0,
						1
					)
					* self.Tune.RevDecayRPM
					* deltaTime
				),
			goalMin,
			goalMax
		)

		if not self.Vehicle.IsOn then self._GoalRPM = 0 end
	end

	-- Starting
	if self.Vehicle.Starting then
		self._GoalRPM = math.clamp(
			self._GoalRPM + self.Tune.IgnitionAccel * deltaTime,
			0,
			math.max(self.Tune.IgnitionRPM, wheelRPM)
		)
	end

	-- Set RPM
	local aRPM = math.max(
		(self._GoalRPM * (1 - deltaTime) + wheelRPM * deltaTime) * (1 - self.Clutch ^ 0.5)
			+ self._GoalRPM * self.Clutch ^ 0.5,
		revMin
	)
	local clutchP = math.min(math.abs(aRPM - self.Vehicle.RPM) / (self.Tune.Flywheel * deltaTime), 0.9)
	self.Vehicle.RPM = aRPM * (1 - clutchP) + self.Vehicle.RPM * clutchP

	if self.Tune.OverRev == false and self.Vehicle.RPM > self.Tune.Redline then self.Vehicle.RPM = self.Tune.Redline end

	if
		self.Vehicle.RPM <= (self.Tune.IdleRPM / 4)
		and (tick() - self._LastOffTime >= 0.2)
		and self.Vehicle.Tune.Stall
	then
		self.Vehicle.IsOn = false
	end

	if self.Vehicle.RPM > self.Tune.IgnitionMinRPM and (tick() - self._LastOnTime > 0.2) and self.Health > 0 then
		self.Vehicle.IsOn = true
	end

	-- Clutch
	local forceClutch = self.Vehicle.Shifting
		or (self.Vehicle.Gear == 0 or (ParkingGearEnabled and self.Vehicle.Gear == -1))
	if forceClutch then self.Clutch = 1 end

	local clutchModulate = 0
	if self.Vehicle.Tune.Clutch then
		if self.Vehicle.AutoClutch then
			if self.Vehicle.Tune.ClutchType == "Clutch" or self.Vehicle.Tune.ClutchType == "CVT" then
				local clutchKick = self.Clutch * (self.Vehicle.Tune.ClutchEngage / 100)
				local ClRPMInfluence =
					math.max(self.Vehicle.RPM * self.Vehicle.Tune.ClutchRPMMult / self.Tune.Redline, 0)
				if self.Vehicle.Tune.ClutchMode == "New" then ClRPMInfluence = 0 end
				clutchModulate = math.min(
					(
						(
							(
								(
									self.Vehicle.Velocity.Magnitude
									/ (Units.Velocity_mdivs / 3.6)
									/ self.Vehicle.Tune.SpeedEngage
								) / math.abs(self.Vehicle.Gear)
							) + ClRPMInfluence
						) - clutchKick
					),
					1
				)
			elseif self.Vehicle.Tune.ClutchType == "TorqueConverter" and self.Vehicle.Tune.TQLock then
				if
					(
						self.Throttle <= self.Tune.IdleThrottle / 100
						and self.Vehicle.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6)
							< self.Vehicle.Tune.SpeedEngage
					)
					or (
						self.Throttle > self.Tune.IdleThrottle / 100
						and (self.Vehicle.RPM < self.Vehicle.Tune.RPMEngage and wheelRPM < self.Vehicle.Tune.RPMEngage)
					)
				then
					clutchModulate = math.min(clutchModulate * (self.Vehicle.Tune.ClutchEngage / 100), 1)
				else
					clutchModulate = math.min(
						clutchModulate * (self.Vehicle.Tune.ClutchEngage / 100)
							+ (1 - (self.Vehicle.Tune.ClutchEngage / 100)),
						1
					)
				end
			elseif self.Vehicle.Tune.ClutchType == "TorqueConverter" and not self.Vehicle.Tune.TQLock then
				clutchModulate = math.min((self.Vehicle.RPM / self.Tune.Redline) * 0.7, 1)
			end
			if self.Vehicle.Clutch > 0 and not forceClutch then
				self.Clutch = self.Vehicle.Clutch
			else
				self.Clutch = math.min(1 - clutchModulate, 1)
			end
		else
			if not forceClutch then self.Clutch = self.Vehicle.Clutch end
		end
	else
		if not forceClutch then self.Clutch = self.Vehicle.Clutch end
	end

	-- Things that apply the clutch
	if
		self.Vehicle.AutoClutch
		and (
			self.Vehicle.Starting
			or (self.Tune.RemoveCreep and self.Vehicle.RPM < self.Tune.IdleRPM + (self.Tune.IdlePadding or 0) and self.Vehicle.Throttle < 0.1)
			or (self._RevLimiting and self.Tune.OverRev == false)
		)
	then
		self.Clutch = 1
	end

	-- Torque calculations (Detomiks)
	-- What you see here is mostly just ported over from Desmos.
	local x = self.Vehicle.RPM / 1000
	local NTorque = 0
	local ETorque = 0
	local TTorque = 0
	local STorque = 0
	if self.Vehicle.Tune.Engine then
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
			(-9.80665 * 0.0289644 * (self.Vehicle.Center.Y * Units.Length_mm / 1000))
				/ (8.3142 * (globalTemperature + 273.15))
		) -- look up the barometric formula
		NTorque = (self.Vehicle.Tune.Engine and 1 or 0)
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
			self.Boost = self.BoostTurbo + self.BoostSuper
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
		self.Vehicle.Tune.Stall and 0 or self.Tune.IdleTorque,
		(self.Tune.HPLimit > 0 and self.Tune.HPLimit or math.huge) * (5.252 / x)
	)
	self.Horsepower, self.Torque = (TotalTorque * x) / 5.252, TotalTorque

	-- Exit engine
	local outTorque = self.Torque * self.Vehicle.CurrentRatio * self.Vehicle.FinalDrive
	local cGrav = (VehicleConstants.GravComp > 0 and VehicleConstants.GravComp or game.Workspace.Gravity)
		* self.Tune.InclineComp
		/ 35
	local iComp = self.Vehicle.Center.LookVector.Y * cGrav * math.sign(self.Vehicle.Gear)
	outTorque = outTorque * math.max(1, (1 + iComp))

	-- Update Wheels
	for _, wheel in self.Vehicle.Wheels :: { VehicleTypes.ClientWheel } do
		wheel:UpdateForces(outTorque, flywheelEnergy)
	end

	deltaTime /= 60
	UpdateHealth(self, deltaTime)
	UpdateTemperature(self, deltaTime)
	UpdateFuel(self, deltaTime)
end

function UpdateHealth(self: Engine, deltaTime: number)
	if not self.Vehicle.Tune.Engine or self.Tune.Electric or not self.Vehicle.IsOn then return end

	local damage = self.Tune.RPMDamage * (self.Vehicle.RPM / self.Tune.Redline) ^ 2 / 3600
	damage += (math.max(self.Vehicle.RPM - self.Tune.Redline, 0) / 1000) ^ self.Tune.RedlineDamageCurve * self.Tune.RedlineDamage
	damage += self.Tune.HotDamage * math.clamp(
		MapToRange(self.Temperature, self.Tune.OperatingEngineTemp, self.Tune.EngineBurnTemp),
		0,
		1
	) ^ 1.5 / 3600
	damage += self.DriveshaftStress * self.Vehicle.Tune.DriveshaftDamage
	self.Health = math.max(self.Health - damage * deltaTime, 0)

	if self.Health == 0 then
		self.Vehicle.IsOn = false
		self.Vehicle.DeformationController:BlowEngine()
	end
end

function UpdateTemperature(self: Engine, deltaTime: number)
	if not self.Vehicle.Tune.Engine or self.Health == 0 then return end

	local kW = self.Horsepower / 1.35962
	local heat = kW * Lerp(1, 2, self.Vehicle.RPM / self.Tune.Redline) / 120
	local tDelta = self.Temperature - (game.Workspace:GetAttribute("GlobalTemperature") :: number)
	local cooling = tDelta * 0.015
	cooling += (self.Vehicle.Velocity.Magnitude / Units.Velocity_mdivs) ^ 2 * tDelta / 100000 * 0.8
	self.Temperature += (heat - cooling) * deltaTime

	if self.Temperature > self.Tune.EngineBurnTemp then self.Health = 0 end
end

function UpdateFuel(self: Engine, deltaTime: number)
	if not self.Vehicle.Tune.Engine or self.Tune.Electric or not self.Vehicle.IsOn then return end

	local kW = self.Horsepower * 1.35962
	local consumption = self.Vehicle.Tune.BSFC * kW / 3600 / 1000 / self.Vehicle.Tune.FuelDensity * deltaTime
	self.Vehicle.Fuel = math.max(self.Vehicle.Fuel - consumption, 0)

	local fuelSupply = self._FuelSupply + deltaTime * 3
	if self.Vehicle.Fuel / self.Vehicle.Tune.FuelCapacity < 0.05 then
		local delta = 1 - self.Vehicle.Fuel / self.Vehicle.Tune.FuelCapacity / 0.05
		fuelSupply -= math.abs(math.noise(tick() / 3 % 1000)) ^ 0.6 * delta * 10 * deltaTime
	end
	self._FuelSupply = math.clamp(fuelSupply, 0, 1)

	if self.Vehicle.Fuel == 0 then self.Vehicle.IsOn = false end
end

function Engine.Destroy(self: Engine) end

return Engine
