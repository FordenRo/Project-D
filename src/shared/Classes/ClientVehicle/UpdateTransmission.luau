local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

function DamageEngine(self: VehicleTypes.ClientVehicle)
	local factor = (self.RPM / self.Engine.Tune.Redline) ^ 1.5
		* (1 - self.Clutch)
	self.Engine.Health =
		math.max(self.Engine.Health - factor * self.Tune.ClutchlessDamage, 0)
end

return function(self: VehicleTypes.ClientVehicle)
	local maxSpin = 0
	for _, wheel in self.Wheels :: { VehicleTypes.ClientWheel } do
		if not wheel.IsDriven then continue end

		maxSpin = math.max(
			math.abs(
				wheel.Instance.CFrame:VectorToObjectSpace(
					wheel.Instance.AssemblyAngularVelocity
				).X
			),
			maxSpin
		)
	end

	local ParkingGearEnabled = self.Tune.Ratios[1] == 0
	if self._ShiftUp and not self.Shifting then
		if
			(
				self.TransmissionMode == "Manual"
				and self.Tune.ClutchRel
				and (self.Throttle > 0)
			)
			or self.Gear == #self.Tune.Ratios - 2 - (ParkingGearEnabled and 1 or 0)
			or (self.TransmissionMode ~= "Manual" and not self.IsOn)
		then
			self._ShiftUp = false
			return
		end
		local NextGear = math.min(
			self.Gear + 3 + (ParkingGearEnabled and 1 or 0),
			#self.Tune.Ratios
		)
		if
			self.TransmissionMode ~= "Manual"
			and self.Tune.ClutchType ~= "CVT"
		then
			self.Shifting = true
			if self.Gear > 0 then
				if self.Tune.AutoShiftType == "DCT" then
					task.wait(self.Tune.ShiftUpTime)
				elseif self.Tune.AutoShiftType == "Rev" then
					repeat
						task.wait()
					until self.RPM
							<= math.max(
								math.min(
									maxSpin
										* self.Tune.Ratios[NextGear]
										* self.FinalDriveRatio,
									self.Engine.Tune.Redline
										- self.Engine.Tune.RevBounce
								),
								self.Engine.Tune.IdleRPM
							)
						or not self.IsOn
						or self._ShiftDown
				end
			end
		end
		self._ShiftUp = false
		self.Shifting = false
		if self.Clutch < 0.9 then DamageEngine(self) end
		if self.TransmissionMode ~= "Manual" and not self.IsOn then return end
		if
			NextGear > 3 + (ParkingGearEnabled and 1 or 0)
			and self.Tune.ClutchType == "CVT"
		then
			return
		end -- make sure it cannot go past 1st gear
		self.Gear = math.min(
			self.Gear + 1,
			#self.Tune.Ratios - 2 - (ParkingGearEnabled and 1 or 0)
		)
	end
	if self._ShiftDown and not self.Shifting then
		if
			self.Gear == -1 - (ParkingGearEnabled and 1 or 0)
			or (self.TransmissionMode ~= "Manual" and not self.IsOn)
		then
			self._ShiftDown = false
			return
		end
		local PrevGear = math.min(
			self.Gear + 1 + (ParkingGearEnabled and 1 or 0),
			#self.Tune.Ratios
		)
		if self.TransmissionMode ~= "Manual" then
			self.Shifting = true
			if self.Gear > 1 then
				if self.Tune.AutoShiftType == "DCT" then
					task.wait(self.Tune.ShiftDnTime)
				elseif self.Tune.AutoShiftType == "Rev" then
					repeat
						task.wait()
					until self.RPM
							>= math.max(
								math.min(
									maxSpin
										* self.Tune.Ratios[PrevGear]
										* self.FinalDriveRatio,
									self.Engine.Tune.Redline
										- self.Engine.Tune.RevBounce
								),
								self.Engine.Tune.IdleRPM
							)
						or not self.IsOn
						or self._ShiftUp
				end
			end
		end
		self._ShiftDown = false
		self.Shifting = false
		if self.Clutch < 0.9 then DamageEngine(self) end
		if self.TransmissionMode ~= "Manual" and not self.IsOn then return end
		self.Gear =
			math.max(self.Gear - 1, self.Velocity.Magnitude > 5 and -1 or -2)
	end
end
