local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerVehicle = require(ServerScriptService.Server.Classes.ServerVehicle)

local VehicleHandler = {}
VehicleHandler.__index = VehicleHandler

export type VehicleHandler = typeof(setmetatable({} :: {}, VehicleHandler))

function VehicleHandler.new()
	local self = setmetatable({}, VehicleHandler) :: VehicleHandler

	for _, vehicle in CollectionService:GetTagged("Vehicle") do
		ServerVehicle.new(vehicle)
	end

	CollectionService:GetInstanceAddedSignal("Vehicle"):Connect(ServerVehicle.new)

	return self
end

return VehicleHandler.new()
