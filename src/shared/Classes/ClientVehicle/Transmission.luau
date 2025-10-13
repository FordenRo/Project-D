local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Transmission = {}
Component.Extend(Transmission)

type Transmission = VehicleTypes.Transmission

type TransmissionImpl = {} & Transmission

function Transmission.new(vehicle: VehicleTypes.ClientVehicle): Transmission
	local self: TransmissionImpl = Component.new() :: any

	self.Vehicle = vehicle
	self.ShiftingUp = false
	self.ShiftingDown = false

	setmetatable(self, Transmission)
	return self
end

function ShiftDamage(self: TransmissionImpl)
	local factor = (self.Vehicle.RPM / self.Vehicle.Engine.Tune.Redline) ^ 1.5
		* (1 - self.Vehicle.Clutch)
	self.Vehicle.Engine.Health = math.max(
		self.Vehicle.Engine.Health - factor * self.Vehicle.Tune.ClutchlessDamage,
		0
	)
end

function Transmission.Update(self: TransmissionImpl)
	task.spawn(function()
		local maxSpin = 0
		for _, wheel in self.Vehicle.Wheels :: { VehicleTypes.ClientWheel } do
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

		local ParkingGearEnabled = self.Vehicle.Tune.Ratios[1] == 0
		if self.ShiftingUp and not self.Vehicle.Shifting then
			if
				(
					self.Vehicle.TransmissionMode == "Manual"
					and self.Vehicle.Tune.ClutchRel
					and (self.Vehicle.Throttle > 0)
				)
				or self.Vehicle.Gear == #self.Vehicle.Tune.Ratios - 2 - (ParkingGearEnabled and 1 or 0)
				or (
					self.Vehicle.TransmissionMode ~= "Manual"
					and not self.Vehicle.Engine.IsOn
				)
			then
				self.ShiftingUp = false
				return
			end
			local NextGear = math.min(
				self.Vehicle.Gear + 3 + (ParkingGearEnabled and 1 or 0),
				#self.Vehicle.Tune.Ratios
			)
			if
				self.Vehicle.TransmissionMode ~= "Manual"
				and self.Vehicle.Tune.ClutchType ~= "CVT"
			then
				self.Vehicle.Shifting = true
				if self.Vehicle.Gear > 0 then
					if self.Vehicle.Tune.AutoShiftType == "DCT" then
						task.wait(self.Vehicle.Tune.ShiftUpTime)
					elseif self.Vehicle.Tune.AutoShiftType == "Rev" then
						repeat
							task.wait()
						until self.Vehicle.RPM
								<= math.max(
									math.min(
										maxSpin
											* self.Vehicle.Tune.Ratios[NextGear]
											* self.Vehicle.FinalDriveRatio,
										self.Vehicle.Engine.Tune.Redline
											- self.Vehicle.Engine.Tune.RevBounce
									),
									self.Vehicle.Engine.Tune.IdleRPM
								)
							or not self.Vehicle.Engine.IsOn
							or self.ShiftingDown
					end
				end
			end
			self.ShiftingUp = false
			self.Vehicle.Shifting = false
			if self.Vehicle.Clutch < 0.9 then ShiftDamage(self) end
			if
				self.Vehicle.TransmissionMode ~= "Manual"
				and not self.Vehicle.Engine.IsOn
			then
				return
			end
			if
				NextGear > 3 + (ParkingGearEnabled and 1 or 0)
				and self.Vehicle.Tune.ClutchType == "CVT"
			then
				return
			end -- make sure it cannot go past 1st gear
			self.Vehicle.Gear = math.min(
				self.Vehicle.Gear + 1,
				#self.Vehicle.Tune.Ratios - 2 - (ParkingGearEnabled and 1 or 0)
			)
		end
		if self.ShiftingDown and not self.Vehicle.Shifting then
			if
				self.Vehicle.Gear == -1 - (ParkingGearEnabled and 1 or 0)
				or (
					self.Vehicle.TransmissionMode ~= "Manual"
					and not self.Vehicle.Engine.IsOn
				)
			then
				self.ShiftingDown = false
				return
			end
			local PrevGear = math.min(
				self.Vehicle.Gear + 1 + (ParkingGearEnabled and 1 or 0),
				#self.Vehicle.Tune.Ratios
			)
			if self.Vehicle.TransmissionMode ~= "Manual" then
				self.Vehicle.Shifting = true
				if self.Vehicle.Gear > 1 then
					if self.Vehicle.Tune.AutoShiftType == "DCT" then
						task.wait(self.Vehicle.Tune.ShiftDnTime)
					elseif self.Vehicle.Tune.AutoShiftType == "Rev" then
						repeat
							task.wait()
						until self.Vehicle.RPM
								>= math.max(
									math.min(
										maxSpin
											* self.Vehicle.Tune.Ratios[PrevGear]
											* self.Vehicle.FinalDriveRatio,
										self.Vehicle.Engine.Tune.Redline
											- self.Vehicle.Engine.Tune.RevBounce
									),
									self.Vehicle.Engine.Tune.IdleRPM
								)
							or not self.Vehicle.Engine.IsOn
							or self.ShiftingUp
					end
				end
			end
			self.ShiftingDown = false
			self.Vehicle.Shifting = false
			if self.Vehicle.Clutch < 0.9 then ShiftDamage(self) end
			if
				self.Vehicle.TransmissionMode ~= "Manual"
				and not self.Vehicle.Engine.IsOn
			then
				return
			end
			self.Vehicle.Gear = math.max(
				self.Vehicle.Gear - 1,
				self.Vehicle.Velocity.Magnitude > 5 and -1 or -2
			)
		end
	end)
end

function Transmission.Is(obj: any): boolean
	return typeof(obj) == "table" and getmetatable(obj) == Transmission
end

return table.freeze({
	new = Transmission.new,
	Is = Transmission.Is,
})
