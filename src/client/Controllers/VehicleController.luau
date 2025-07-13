local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientVehicle = require(ReplicatedStorage.Shared.Classes.ClientVehicle)

local VehicleController = {}
VehicleController.__index = VehicleController

export type VehicleController = typeof(setmetatable({} :: {}, VehicleController))

function VehicleController.new()
	local self = setmetatable({}, VehicleController) :: VehicleController

	for _, vehicle in CollectionService:GetTagged("Vehicle") do
		ClientVehicle.new(vehicle)
	end

	CollectionService:GetInstanceAddedSignal("Vehicle"):Connect(ClientVehicle.new)

	return self
end

return VehicleController.new()
