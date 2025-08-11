local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local BaseWheel = {}
BaseWheel.__index = BaseWheel

type BaseWheel = VehicleTypes.BaseWheel

function BaseWheel.new(vehicle: VehicleTypes.BaseVehicle, instance: BasePart)
	local self: BaseWheel = setmetatable({}, BaseWheel) :: any

	self.Instance = instance :: any
	self.Vehicle = vehicle
	self.IsFront = string.find(self.Instance.Name, "F") ~= nil
	self.IsDriven = ((self.Vehicle.Tune.Config == "FWD" or self.Vehicle.Tune.Config == "AWD") and self.IsFront)
		or ((self.Vehicle.Tune.Config == "RWD" or self.Vehicle.Tune.Config == "AWD") and not self.IsFront)

	return self
end

return BaseWheel
