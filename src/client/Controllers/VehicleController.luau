local VehicleController = {}
VehicleController.__index = VehicleController

export type VehicleController = typeof(setmetatable({} :: {}, VehicleController))

function VehicleController.new()
	local self = setmetatable({}, VehicleController)
	return self
end

return VehicleController.new()
