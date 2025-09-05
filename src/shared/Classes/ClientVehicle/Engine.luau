--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EngineTable = require(script.Parent.EngineTable)
local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Engine = {}
Engine.__index = Engine

type Engine = VehicleTypes.Engine

function Engine.new(vehicle: VehicleTypes.ClientVehicle): Engine
	local self: Engine = setmetatable(table.clone(EngineTable), Engine) :: any

	self.Vehicle = vehicle
	self.Throttle = 0
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

	local ParkingGearEnabled = self.Vehicle.Tune.Ratios[1] == 0
	local wheelRPM = self.Vehicle._DriveWheelSpeed
		* self.Vehicle.CurrentRatio
		* self.Vehicle.FinalDriveRatio
		* math.sign(self.Vehicle.Gear)

	-- CVT
	local CVTRatio
	if self.Vehicle.Tune.ClutchType == "CVT" then
		CVTRatio = math.clamp(
			(self.Vehicle.Tune.CVTRPM * self.Throttle) / (self.Vehicle._DriveWheelSpeed * self.Vehicle.FinalDriveRatio),
			self.Vehicle.Tune.CVTMinRatio,
			self.Vehicle.Tune.CVTMaxRatio
		)
	end

	-- Update ratio
	self.Vehicle.CurrentRatio = self.Vehicle.Tune.ClutchType == "CVT" and CVTRatio
		or self.Vehicle.Tune.Ratios[self.Vehicle.Gear + 2 + (ParkingGearEnabled and 1 or 0)]
	local spLimit = self.Vehicle.Tune.Redline / (self.Vehicle.FinalDriveRatio * self.Vehicle.CurrentRatio)
	if self.Vehicle.CurrentRatio * self.Vehicle.FinalDriveRatio == 0 then spLimit = 0 end -- Prevents [nan] from dividing by 0

	-- Flywheel/clutch-dumping
	local flywheelEnergy = (self.Vehicle.RPM - wheelRPM)
		* self.Vehicle.Tune.DumpMult
		* (1 - self.Clutch)
		* 1.356
		* Units.Torque_nm
	self.DriveshaftStress = math.abs(flywheelEnergy / 5000) ^ 1.2

	-- Determine RPM
	local revMin = 0
	local goalMin = 0
	local goalMax = self.Vehicle.Tune.Redline

	if self.Vehicle.Shifting and self.Vehicle._ShiftUp then
		self.Throttle = self.Vehicle.Tune.IdleThrottle / 100
	elseif self.Vehicle.Shifting and self.Vehicle._ShiftDown then
		self.Throttle = self.Vehicle.Tune.ShiftThrot / 100
	else
		self.Throttle = math.max(self.Vehicle.Throttle, self.Vehicle.Tune.IdleThrottle / 100)
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
		goalMax = Lerp(self.Vehicle.Tune.Redline, self.Vehicle.Tune.NeutralRevRPM, self.Vehicle.Clutch)
	end

	-- Rev limiter/speed limiter
	if self.Vehicle.RPM >= self.Vehicle.Tune.Redline then
		self._RevLimiting = true
	elseif self.Vehicle.RPM < goalMax - self.Vehicle.Tune.RevBounce then
		self._RevLimiting = false
	end
	if self._RevLimiting then self.Throttle = self.Vehicle.Tune.IdleThrottle / 100 end

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
				self.Vehicle.Tune.IdleThrottle / 100
			)
		)
	end

	-- Idle
	if self.Vehicle.RPM < self.Vehicle.Tune.IdleRPM + (self.Vehicle.Tune.IdlePadding or 0) and self.Vehicle.IsOn then
		self.Throttle = math.max(
			self.Throttle,
			math.clamp(
				(self.Vehicle.Tune.IdleRPM + (self.Vehicle.Tune.IdlePadding or 0) - self.Vehicle.RPM)
					/ (self.Vehicle.Tune.IdleDamping or 400),
				0,
				1
			)
		)
	end

	-- Apply fuel supply
	self.Throttle *= self._FuelSupply

	if (self.Vehicle.Tune.Engine or self.Vehicle.Tune.Electric) and not self.Vehicle.Starting then
		self._GoalRPM = math.clamp(
			self.Vehicle.RPM
				- (self.Vehicle.Tune.RevDecay * deltaTime)
				+ (self.Vehicle.Tune.RevAccel * self.Throttle * deltaTime)
				- (
					math.clamp(
						math.max(self.Vehicle.RPM - self.Vehicle.Tune.IdleRPM, 0)
							/ math.max(self.Vehicle.Tune.Redline - self.Vehicle.Tune.IdleRPM, 1),
						0,
						1
					)
					* self.Vehicle.Tune.RevDecayRPM
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
			self._GoalRPM + self.Vehicle.Tune.IgnitionAccel * deltaTime,
			0,
			math.max(self.Vehicle.Tune.IgnitionRPM, wheelRPM)
		)
	end

	-- Set RPM
	local aRPM = math.max(
		(self._GoalRPM * (1 - deltaTime) + wheelRPM * deltaTime) * (1 - self.Clutch) + self._GoalRPM * self.Clutch,
		revMin
	)
	local clutchP = math.min(math.abs(aRPM - self.Vehicle.RPM) / (self.Vehicle.Tune.Flywheel * deltaTime), 0.9)
	self.Vehicle.RPM = aRPM * (1 - clutchP) + self.Vehicle.RPM * clutchP

	if self.Vehicle.Tune.OverRev == false and self.Vehicle.RPM > self.Vehicle.Tune.Redline then
		self.Vehicle.RPM = self.Vehicle.Tune.Redline
	end

	if
		self.Vehicle.RPM <= (self.Vehicle.Tune.IdleRPM / 4)
		and (tick() - self._LastOffTime >= 0.2)
		and self.Vehicle.Tune.Stall
	then
		self.Vehicle.IsOn = false
	end

	if
		self.Vehicle.RPM > self.Vehicle.Tune.IgnitionMinRPM
		and (tick() - self._LastOnTime > 0.2)
		and self.Health > 0
	then
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
					math.max(self.Vehicle.RPM * self.Vehicle.Tune.ClutchRPMMult / self.Vehicle.Tune.Redline, 0)
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
						self.Throttle <= self.Vehicle.Tune.IdleThrottle / 100
						and self.Vehicle.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6)
							< self.Vehicle.Tune.SpeedEngage
					)
					or (
						self.Throttle > self.Vehicle.Tune.IdleThrottle / 100
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
				clutchModulate = math.min((self.Vehicle.RPM / self.Vehicle.Tune.Redline) * 0.7, 1)
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
			or (self.Vehicle.Tune.RemoveCreep and self.Vehicle.RPM < self.Vehicle.Tune.IdleRPM + (self.Vehicle.Tune.IdlePadding or 0) and self.Vehicle.Throttle < 0.1)
			or (self._RevLimiting and self.Vehicle.Tune.OverRev == false)
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
			self.Vehicle.Tune.IdleRPM / 1000,
			self.Vehicle.Tune.IdleTorque,
			self.Vehicle.Tune.PeakTorqueRPM / 1000,
			self.Vehicle.Tune.PeakTorque,
			self.Vehicle.Tune.PeakTorque,
			self.Vehicle.Tune.IdleTorqueCurve,
			x
		)
		local NRedlineTorque = calcPower(
			self.Vehicle.Tune.PeakTorqueRPM / 1000,
			self.Vehicle.Tune.PeakTorque,
			self.Vehicle.Tune.Redline / 1000,
			self.Vehicle.Tune.RedlineTorque,
			self.Vehicle.Tune.PeakTorque,
			1 / self.Vehicle.Tune.RedlineTorqueCurve,
			x
		)
		local VVL = self.Vehicle.Tune.VVLTorque > 0
				and self.Vehicle.Tune.VVLTorque - calcPower(
					self.Vehicle.Tune.VVLRPM / 1000,
					0,
					(self.Vehicle.Tune.VVLRPM + self.Vehicle.Tune.VVLTime) / 1000,
					self.Vehicle.Tune.VVLTorque,
					self.Vehicle.Tune.VVLTorque,
					self.Vehicle.Tune.VVLCurve,
					x
				)
			or 0
		local globalTemperature = game.Workspace:GetAttribute("GlobalTemperature") :: number
		local AirPressurePercent = math.exp(
			(-9.80665 * 0.0289644 * (self.Vehicle.Center.Y * Units.Length_mm / 1000))
				/ (8.3142 * (globalTemperature + 273.15))
		) -- look up the barometric formula
		NTorque = (self.Vehicle.Tune.Engine and 1 or 0)
			* (self.Vehicle.Tune.PeakTorque - NIdleTorque - NRedlineTorque + VVL)
			* AirPressurePercent
		self.HpNatural, self.TqNatural = (NTorque * x) / 5.252, NTorque

		if self.Vehicle.Tune.Turbochargers > 0 then
			local _TBoostGoal = self.Vehicle.Tune.Turbochargers
				* (
					(self.Throttle ^ 3) * (100 / self.Vehicle.Tune.T_Size) * ((NTorque * x) / 5.252)
					- calcPower(
						self.Vehicle.Tune.IdleRPM / 1000,
						self.Vehicle.Tune.T_IdleBoost,
						self.Vehicle.Tune.T_PeakRPM / 1000,
						self.Vehicle.Tune.T_Boost,
						(self.Throttle ^ 3) * (100 / self.Vehicle.Tune.T_Size) * ((NTorque * x) / 5.252),
						1 / self.Vehicle.Tune.T_Curve,
						x
					)
				)
			if _TBoostGoal > self.BoostTurbo then
				self.BoostTurbo = self.BoostTurbo
					+ math.min(
							self.Vehicle.Tune.T_SpoolIncrease * (_TBoostGoal - self.BoostTurbo),
							self.Vehicle.Tune.T_SpoolIncrease
								* (10 / self.Vehicle.Tune.T_Size)
								* self.Vehicle.Tune.Turbochargers
						)
						* deltaTime -- i should probably base this off of the maximum horsepower instead of the RPM, but it's the same thing anyway
			elseif self.BoostTurbo > _TBoostGoal then
				self.BoostTurbo = self.BoostTurbo
					+ self.Vehicle.Tune.T_SpoolDecrease * (_TBoostGoal - self.BoostTurbo) * deltaTime
			end
			self.BoostTurbo =
				math.clamp(self.BoostTurbo, 0, self.Vehicle.Tune.Turbochargers * self.Vehicle.Tune.T_Boost)
			TTorque = self.BoostTurbo * self.Vehicle.Tune.T_Efficiency
			self.HpTurbo, self.TqTurbo = (TTorque * x) / 5.252, TTorque
		end
		if self.Vehicle.Tune.Superchargers > 0 then
			local SIdleBoost = calcPower(
				self.Vehicle.Tune.IdleRPM / 1000,
				self.Vehicle.Tune.S_IdleBoost,
				self.Vehicle.Tune.S_PeakRPM / 1000,
				self.Vehicle.Tune.S_Boost,
				self.Vehicle.Tune.S_Boost,
				self.Vehicle.Tune.S_IdleCurve,
				x
			)
			local SRedlineBoost = calcPower(
				self.Vehicle.Tune.S_PeakRPM / 1000,
				self.Vehicle.Tune.S_Boost,
				self.Vehicle.Tune.Redline / 1000,
				self.Vehicle.Tune.S_RedlineBoost,
				self.Vehicle.Tune.S_Boost,
				1 / self.Vehicle.Tune.S_RedlineCurve,
				x
			)
			local _SBoostGoal = self.Vehicle.Tune.Superchargers
				* self.Throttle
				* (self.Vehicle.Tune.S_Boost - SIdleBoost - SRedlineBoost)
			if _SBoostGoal > self.BoostSuper then
				self.BoostSuper = math.min(
					self.BoostSuper + self.Vehicle.Tune.S_Boost * self.Vehicle.Tune.S_Response * deltaTime,
					_SBoostGoal
				)
			elseif self.BoostSuper > _SBoostGoal then
				self.BoostSuper = math.max(
					self.BoostSuper - self.Vehicle.Tune.S_Boost * self.Vehicle.Tune.S_Response * deltaTime,
					_SBoostGoal
				)
			end
			STorque = self.BoostSuper * self.Vehicle.Tune.S_Efficiency
			self.HpSuper, self.TqSuper = (STorque * x) / 5.252, STorque
		end
		if self.Vehicle.Tune.Turbochargers > 0 or self.Vehicle.Tune.Superchargers > 0 then
			self.HpBoosted, self.TqBoosted = ((TTorque + STorque) * x) / 5.252, TTorque + STorque
			self.Boost = self.BoostTurbo + self.BoostSuper
		end
	end
	if self.Vehicle.Tune.Electric then
		ETorque = (self.Vehicle.Tune.Electric and 1 or 0)
			* (
				self.Vehicle.Tune.E_Torque
				- calcPower(
					self.Vehicle.Tune.E_TransitionRPM / 1000,
					self.Vehicle.Tune.E_Torque,
					self.Vehicle.Tune.E_Redline / 1000,
					self.Vehicle.Tune.E_RedlineTorque,
					self.Vehicle.Tune.E_Torque,
					self.Vehicle.Tune.E_Curve,
					x
				)
			)
		self.HpElectric, self.TqElectric = (ETorque * x) / 5.252, ETorque
	end
	local TotalTorque = math.clamp(
		NTorque + ETorque + TTorque + STorque,
		self.Vehicle.Tune.Stall and 0 or self.Vehicle.Tune.IdleTorque,
		(self.Vehicle.Tune.HPLimit > 0 and self.Vehicle.Tune.HPLimit or math.huge) * (5.252 / x)
	)
	self.Horsepower, self.Torque = (TotalTorque * x) / 5.252, TotalTorque

	-- Exit engine
	local outTorque = self.Torque * self.Vehicle.CurrentRatio * self.Vehicle.FinalDrive
	local cGrav = (self.Vehicle.Tune.GravComp > 0 and self.Vehicle.Tune.GravComp or game.Workspace.Gravity)
		* self.Vehicle.Tune.InclineComp
		/ 35
	local iComp = self.Vehicle.Center.LookVector.Y * cGrav * math.sign(self.Vehicle.Gear)
	outTorque = outTorque * math.max(1, (1 + iComp))

	-- Update Wheels
	for _, wheel in self.Vehicle.Wheels :: { VehicleTypes.ClientWheel } do
		-- Apply Power
		local throttle = self.Throttle
		local brake = self.Vehicle.Brake
		local clutch = 1 - self.Vehicle.Clutch
		local wheelTorque = outTorque

		-- Speed limiter
		if self.Vehicle.Tune.SLimitBrake and speedLimit > 0 then
			brake = math.max(
				brake,
				math.clamp(
					(self.Vehicle.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) - speedLimit)
						/ self.Vehicle.Tune.SLimitGradient,
					0,
					1
				)
			)
		end

		-- Apply ESC
		local torqueESC = 0
		if
			not (wheel.Instance.Name == "F" or wheel.Instance.Name == "R")
			and self.Vehicle.ESC
			and (self.Vehicle.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6)) > self.Vehicle.Tune.ESCSpeed
		then
			local g = self.Vehicle.WeightPart.CFrame:VectorToObjectSpace(
				self.Vehicle.Acceleration
					/ Units.Velocity_mdivs
					/ (
						(self.Vehicle.Tune.GravComp > 0 and self.Vehicle.Tune.GravComp or game.Workspace.Gravity)
						* (Units.Length_mm / 1000)
					)
			)
			if math.sign(self.Vehicle.Steering) ~= math.sign(g.X) then
				local diff = self.Vehicle.Steering
					- (g.X * -math.sign(self.Vehicle.Center:VectorToObjectSpace(self.Vehicle.Velocity).Z))
				if math.abs(diff) > self.Vehicle.Tune.ESCThreshold then
					local escVector, escBias = 1, (self.Vehicle.Tune.ESCVector + 1)
					if wheel.IsFront then
						escVector = escVector * (2 - escBias)
					else
						escVector = escVector * escBias
					end

					torqueESC = (wheel.IsRight and -1 or 1) * math.sign(diff) * escVector
					throttle = throttle + (math.max(torqueESC, 0) - throttle) * (self.Vehicle.Tune.ESCThrottle / 100)
					brake = brake + (-math.min(torqueESC, 0) - brake) * (self.Vehicle.Tune.ESCBrake / 100)
				end
			end
		end
		self.Vehicle.ESCActive = torqueESC ~= 0 or self.Vehicle.ESCActive
		wheel.Trackers.ESC = torqueESC

		-- Apply ABS
		local torqueABS = 1
		if self.Vehicle.ABS and brake > 0 then
			torqueABS = 1
				- (
					math.min(
						math.max(
							0,
							math.abs(
								wheel.Instance.AssemblyAngularVelocity.Magnitude
										* (wheel.Instance.Size.Y / 2)
										/ (Units.Velocity_mdivs / 3.6)
									- wheel.Instance.AssemblyLinearVelocity.Magnitude / (Units.Velocity_mdivs / 3.6)
							) - self.Vehicle.Tune.ABSThreshold
						) / self.Vehicle.Tune.ABSGradient,
						1
					) * (1 - (self.Vehicle.Tune.ABSLimit / 100))
				)
		end
		self.Vehicle.ABSActive = torqueABS < 1 or self.Vehicle.ABSActive
		wheel.Trackers.ABS = 1 - torqueABS

		local PBrake = 0
		if self.Vehicle.PBrake == true or self.Vehicle.Gear == -2 then
			PBrake = 1
		else
			PBrake = 0
		end

		-- Apply Power
		if wheel.IsDriven then
			-- Differential/Torque-Vectoring
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
				) * (self.Vehicle.Tune.FDiffPreload / 10)
				FRdiffMult = math.ceil(
					math.max(
						0,
						math.min(
							2,
							1
								- (
									((self.Vehicle.Tune.FDiffPower / 100) * avg * self.Throttle)
									+ ((self.Vehicle.Tune.FDiffCoast / 100) * avg * (1 - self.Throttle))
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
				) * (self.Vehicle.Tune.FDiffPreload / 10)
				FLdiffMult = math.ceil(
					math.max(
						0,
						math.min(
							2,
							1
								- (
									((self.Vehicle.Tune.FDiffPower / 100) * avg * self.Throttle)
									+ ((self.Vehicle.Tune.FDiffCoast / 100) * avg * (1 - self.Throttle))
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
				) * (self.Vehicle.Tune.RDiffPreload / 10)
				RRdiffMult = math.ceil(
					math.max(
						0,
						math.min(
							2,
							1
								- (
									((self.Vehicle.Tune.RDiffPower / 100) * avg * self.Throttle)
									+ ((self.Vehicle.Tune.RDiffCoast / 100) * avg * (1 - self.Throttle))
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
				) * (self.Vehicle.Tune.RDiffPreload / 10)
				RLdiffMult = math.ceil(
					math.max(
						0,
						math.min(
							2,
							1
								- (
									((self.Vehicle.Tune.RDiffPower / 100) * avg * self.Throttle)
									+ ((self.Vehicle.Tune.RDiffCoast / 100) * avg * (1 - self.Throttle))
								)
						)
					) * 100
				) / 100
				RRdiffMult = 2 - RLdiffMult
			end

			local fWCount = 0
			local rWCount = 0
			local drWCount = 0
			for _, v in self.Vehicle.Wheels do
				if v.IsDriven then
					drWCount += 1
				end
				if v.IsFront then
					fWCount += 1
				else
					rWCount += 1
				end
			end

			-- Apply torque split
			-- This takes the total amount of torque alotted to the front or rear wheels, then divides it by how many wheels there are
			local bias = (self.Vehicle.Tune.Config == "AWD" and (self.Vehicle.Tune.TorqueVector + 1) / 2)
				or (self.Vehicle.Tune.Config == "FWD" and 0)
				or 1
			wheelTorque = wheel.IsFront and (wheelTorque * (1 - bias)) / fWCount or (wheelTorque * bias) / rWCount

			-- Apply TCS
			local torqueTCS = 1
			if self.Vehicle.TCS and throttle > self.Vehicle.Tune.IdleThrottle / 100 then
				torqueTCS = 1
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
								) - self.Vehicle.Tune.TCSThreshold
							) / self.Vehicle.Tune.TCSGradient,
							1
						) * (1 - (self.Vehicle.Tune.TCSLimit / 100))
					)
			end
			self.Vehicle.TCSActive = torqueTCS < 1 or self.Vehicle.TCSActive
			wheel.Trackers.TCS = 1 - torqueTCS

			-- Update Forces
			local outWheelTorque = (wheelTorque * 1.356 * Units.Torque_nm * throttle * torqueTCS * clutch)
				+ (math.max(flywheelEnergy, 0) / drWCount)

			if wheel.Instance.Name == "RR" then
				wheel.Instance.AV.MotorMaxTorque = outWheelTorque * RRdiffMult
			elseif wheel.Instance.Name == "RL" then
				wheel.Instance.AV.MotorMaxTorque = outWheelTorque * RLdiffMult
			elseif wheel.Instance.Name == "FR" then
				wheel.Instance.AV.MotorMaxTorque = outWheelTorque * FRdiffMult
			elseif wheel.Instance.Name == "FL" then
				wheel.Instance.AV.MotorMaxTorque = outWheelTorque * FLdiffMult
			else
				wheel.Instance.AV.MotorMaxTorque = outWheelTorque
			end
			wheel.Instance.AV.AngularVelocity = spLimit * math.sign(self.Vehicle.Gear)

			local torque = self.Vehicle.Tune.EBrakeForce
					* math.min(self.Vehicle.RPM / self.Vehicle.Tune.Redline, 0.5)
					* (1 - throttle)
					* clutch
				- math.min(flywheelEnergy, 0) / drWCount
			if wheel.IsFront then
				torque += self.Vehicle.BrakeForce.Front * brake * torqueABS + self.Vehicle.PBrakeForce.Front * PBrake
			else
				torque += self.Vehicle.BrakeForce.Rear * brake * torqueABS + self.Vehicle.PBrakeForce.Rear * PBrake
			end
			wheel.Instance.BV.MotorMaxTorque = torque
		else
			wheel.Instance.AV.MotorMaxTorque = 0
			wheel.Instance.AV.AngularVelocity = 0
			if wheel.IsFront then
				wheel.Instance.BV.MotorMaxTorque = (self.Vehicle.BrakeForce.Front * brake * torqueABS)
					+ (self.Vehicle.PBrakeForce.Front * PBrake)
			else
				wheel.Instance.BV.MotorMaxTorque = (self.Vehicle.BrakeForce.Rear * brake * torqueABS)
					+ (self.Vehicle.PBrakeForce.Rear * PBrake)
			end
		end
	end

	deltaTime /= 60
	UpdateHealth(self, deltaTime)
	UpdateTemperature(self, deltaTime)
	UpdateFuel(self, deltaTime)
end

function UpdateHealth(self: Engine, deltaTime: number)
	if not self.Vehicle.Tune.Engine or self.Vehicle.Tune.Electric or not self.Vehicle.IsOn then return end

	local damage = self.Vehicle.Tune.RPMDamage * (self.Vehicle.RPM / self.Vehicle.Tune.Redline) ^ 2 / 3600
	damage += (math.max(self.Vehicle.RPM - self.Vehicle.Tune.Redline, 0) / 1000) ^ self.Vehicle.Tune.RedlineDamageCurve * self.Vehicle.Tune.RedlineDamage
	damage += self.Vehicle.Tune.HotDamage * math.clamp(
		MapToRange(self.Temperature, self.Vehicle.Tune.OperatingEngineTemp, self.Vehicle.Tune.EngineBurnTemp),
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
	local heat = kW * Lerp(1, 2, self.Vehicle.RPM / self.Vehicle.Tune.Redline) / 120
	local tDelta = self.Temperature - (game.Workspace:GetAttribute("GlobalTemperature") :: number)
	local cooling = tDelta * 0.015
	cooling += (self.Vehicle.Velocity.Magnitude / Units.Velocity_mdivs) ^ 2 * tDelta / 100000 * 0.8
	self.Temperature += (heat - cooling) * deltaTime

	if self.Temperature > self.Vehicle.Tune.EngineBurnTemp then self.Health = 0 end
end

function UpdateFuel(self: Engine, deltaTime: number)
	if not self.Vehicle.Tune.Engine or self.Vehicle.Tune.Electric or not self.Vehicle.IsOn then return end

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
