local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientVehicle = require(ReplicatedStorage.Shared.Classes.ClientVehicle)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

local player = Players.LocalPlayer

local VehicleController = {}
VehicleController.__index = VehicleController

export type VehicleController = typeof(setmetatable(
	{} :: {
		DrivenVehicle: Types.ClientVehicle?,
	},
	VehicleController
))

function VehicleController.new()
	local self = setmetatable({}, VehicleController) :: VehicleController

	for _, vehicle in CollectionService:GetTagged("Vehicle") do
		self:RegisterVehicle(vehicle)
	end

	self.DrivenVehicle = nil

	CollectionService:GetInstanceAddedSignal("Vehicle"):Connect(function(vehicle) self:RegisterVehicle(vehicle) end)

	return self
end

function VehicleController.RegisterVehicle(self: VehicleController, vehicle: Instance)
	local seat = vehicle:WaitForChild("DriveSeat") :: VehicleSeat

	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant == player then
			self.DrivenVehicle = ClientVehicle.new(vehicle)
		else
			if self.DrivenVehicle then self.DrivenVehicle:Destroy() end
		end
	end)
end

return VehicleController.new()
