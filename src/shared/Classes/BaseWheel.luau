local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local BaseWheel = {}
BaseWheel.__index = BaseWheel

type BaseWheel = VehicleTypes.BaseWheel

function BaseWheel.new(
	vehicle: VehicleTypes.BaseVehicle,
	instance: BasePart
): BaseWheel
	local self: BaseWheel = setmetatable({}, BaseWheel) :: any

	self.Instance = instance :: any
	self.Vehicle = vehicle
	self.IsFront = string.find(self.Instance.Name, "F") ~= nil
	self.IsRight = string.find(self.Instance.Name, "L") == nil
	self.IsDriven = (
		(
			self.Vehicle.Tune.Drivetrain == "FWD"
			or self.Vehicle.Tune.Drivetrain == "AWD"
		) and self.IsFront
	)
		or (
			(
				self.Vehicle.Tune.Drivetrain == "RWD"
				or self.Vehicle.Tune.Drivetrain == "AWD"
			) and not self.IsFront
		)

	return self
end

return BaseWheel
