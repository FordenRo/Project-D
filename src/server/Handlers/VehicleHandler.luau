local VehicleHandler = {}
VehicleHandler.__index = VehicleHandler

export type VehicleHandler = typeof(setmetatable({} :: {}, VehicleHandler))

function VehicleHandler.new()
	local self = setmetatable({}, VehicleHandler)
	return self
end

return VehicleHandler.new()
