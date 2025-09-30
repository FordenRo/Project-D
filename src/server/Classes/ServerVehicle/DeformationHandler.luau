local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local DeformationHandler = {}
DeformationHandler.__index = DeformationHandler

type DeformationHandler = VehicleTypes.DeformationHandler

function DeformationHandler.new(vehicle: VehicleTypes.ServerVehicle): DeformationHandler
	local self: DeformationHandler = setmetatable({}, DeformationHandler) :: any

	self.Vehicle = vehicle

	local trove = Trove.new()
	trove:AttachToInstance(self.Vehicle.Instance)

	self._RE = Instance.new("RemoteEvent")
	self._RE.Name = "_DeformRE"
	self._RE.Parent = self.Vehicle.Instance

	trove:Connect(self._RE.OnServerEvent, function(sender: Player, ...)
		for _, player in Players:GetPlayers() do
			if sender == player then continue end

			self._RE:FireClient(player, ...)
		end
	end)

	return self
end

return DeformationHandler
