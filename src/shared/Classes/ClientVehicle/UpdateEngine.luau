local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Vehicle.Types)
local Units = require(ReplicatedStorage.Shared.Utils.Units)

function calcPower(m: number, n: number, p: number, q: number, M: number, b: number, x: number)
	return math.clamp(M - ((q - n) / (b ^ p - b ^ m) * (b ^ x - b ^ m) + n), 0, M)
end

return function(self: Types.ClientVehicle, deltaTime: number)
	deltaTime = (60 / (1 / deltaTime))

	local ParkingGearEnabled = self.Tune.Ratios[1] == 0
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
		or self.Tune.Ratios[self.Gear + 2 + (ParkingGearEnabled and 1 or 0)]
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
			(self._ClutchPressing and (self.Gear == 0 or (ParkingGearEnabled and self.Gear == -2)))
			or (self._InputClutch and self.Gear ~= 0)
		) and self.Tune.NeutralLimit
	then
		if
			((self.Gear == 0 or (ParkingGearEnabled and self.Gear == -2)) and not self.Tune.LimitClutch)
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
	if self.Shifting or (self.Gear == 0 or (ParkingGearEnabled and self.Gear == -2)) then
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

			local fWCount = 0
			local rWCount = 0
			local drWCount = 0
			for _, v in self.Wheels do
				if v.IsDriven then
					drWCount += 1
				end
				if v.IsFront then
					fWCount += 1
				else
					rWCount += 1
				end
			end

			--Apply torque split
			-- This takes the total amount of torque alotted to the front or rear wheels, then divides it by how many wheels there are
			local bias = (self.Tune.Config == "AWD" and (self.Tune.TorqueVector + 1) / 2)
				or (self.Tune.Config == "FWD" and 0)
				or 1
			tq = wheel.IsFront and (tq * (1 - bias)) / fWCount or (tq * bias) / rWCount

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
			local tqOUT = (tq * 1.356 * Units.Torque_nm * throt * tqTCS * on * clutch) + (flywheelEnergy / drWCount)
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
