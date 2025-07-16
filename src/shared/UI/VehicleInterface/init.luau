local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Speedometer = require(script.Speedometer)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

local UI = ReplicatedStorage.UI.VehicleInterface
local player = Players.LocalPlayer

local VehicleInterface = {}
VehicleInterface.__index = VehicleInterface

type VehicleInterface = Types.VehicleInterface

function VehicleInterface.new(vehicle: Types.ClientVehicle)
	local self: VehicleInterface = setmetatable({}, VehicleInterface) :: any

	self.Vehicle = vehicle

	self.Instance = UI:Clone()
	self.Instance.Parent = player.PlayerGui

	self.Speedometer = Speedometer.new(vehicle, self.Instance.Speedometer)

	return self
end

function VehicleInterface.Destroy(self: VehicleInterface)
	self.Speedometer:Destroy()
	self.Instance:Destroy()
end

return VehicleInterface
