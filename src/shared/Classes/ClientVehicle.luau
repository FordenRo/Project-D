local ClientVehicle = {}
ClientVehicle.__index = ClientVehicle

export type ClientVehicle = typeof(setmetatable({} :: {}, ClientVehicle))

function ClientVehicle.new()
	local self = setmetatable({}, ClientVehicle)
	return self
end

return ClientVehicle
