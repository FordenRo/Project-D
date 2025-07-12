local ServerVehicle = {}
ServerVehicle.__index = ServerVehicle

export type ServerVehicle = typeof(setmetatable({} :: {}, ServerVehicle))

function ServerVehicle.new()
	local self = setmetatable({}, ServerVehicle)
	return self
end

return ServerVehicle
