local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarServiceTypes = require(ReplicatedStorage.Shared.Types.CarServiceTypes)

local CarService = {}
CarService.__index = CarService

type CarServiceServer = CarServiceTypes.CarServiceServer

function CarService.new(instance: Model)
	local self: CarServiceServer = setmetatable({}, CarService) :: any

	self.Instance = instance :: any
	self.Occupants = {}

	self._RE = Instance.new("RemoteEvent")
	self._RE.OnServerEvent:Connect(function(player: Player, event: string, ...) self[event](self, player, ...) end)
	self._RE.Parent = self.Instance

	self._RF = Instance.new("RemoteFunction")
	self._RF.OnServerInvoke = function(player, event: string, ...)
		if typeof(self[event]) == "function" then
			return self[event](self, player, ...)
		else
			return self[event]
		end
	end
	self._RF.Parent = self.Instance

	return self
end

return CarService
