local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientVehicle = require(ReplicatedStorage.Shared.Classes.ClientVehicle)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

local VehicleController = {}
VehicleController.__index = VehicleController

export type VehicleController = typeof(setmetatable(
	{} :: {
		DrivenVehicle: VehicleTypes.ClientVehicle?,
	},
	VehicleController
))

local remoteFunction = ReplicatedStorage:WaitForChild("VehicleRF") :: RemoteFunction

function VehicleController.new()
	local self: VehicleController = setmetatable({}, VehicleController) :: any

	for _, vehicle in CollectionService:GetTagged("Vehicle") do
		self:RegisterVehicle(vehicle)
	end

	self.DrivenVehicle = nil

	CollectionService:GetInstanceAddedSignal("Vehicle"):Connect(function(vehicle) self:RegisterVehicle(vehicle) end)

	return self
end

function VehicleController.RegisterVehicle(self: VehicleController, vehicle: Instance)
	if not vehicle:IsDescendantOf(game.Workspace) then return end

	local seat = vehicle:WaitForChild("DriveSeat") :: VehicleSeat

	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant then
			local seatedPlayer = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
			if seatedPlayer == player then self.DrivenVehicle = ClientVehicle.new(vehicle) end
		else
			if self.DrivenVehicle and (self.DrivenVehicle.Instance :: Instance) == vehicle then
				self.DrivenVehicle:Destroy()
				self.DrivenVehicle = nil
			end
		end
	end)
end

function VehicleController.GetVehicles(self: VehicleController): { VehicleTypes.PlayerVehicle }
	return remoteFunction:InvokeServer("GetPlayerVehicles")
end

function VehicleController.GetVehicleInfo(self: VehicleController, id: number): VehicleTypes.PlayerVehicleInfo
	return remoteFunction:InvokeServer("GetPlayerVehicleInfo", id)
end

function VehicleController.GetVehiclesByName(self: VehicleController, name: string): { VehicleTypes.PlayerVehicle }
	local vehicles = self:GetVehicles()
	local list = {}
	for _, v in vehicles do
		if v.Name == name then table.insert(list, v) end
	end
	return list
end

return VehicleController.new()
