local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarServiceTypes = require(ReplicatedStorage.Shared.Types.CarServiceTypes)

local CarService = {}
CarService.__index = CarService

type CarServiceServer = CarServiceTypes.CarServiceServer

type CarServiceServerImpl = {
	RE: RemoteEvent,
	RF: RemoteFunction,
} & CarServiceServer

function CarService.new(instance: Instance): CarServiceServer
	local self: CarServiceServerImpl = setmetatable({}, CarService) :: any

	self.Instance = instance :: any
	self.Occupants = {}

	self.RE = Instance.new("RemoteEvent")
	self.RE.OnServerEvent:Connect(
		function(player: Player, event: string, ...)
			self[event](self, player, ...)
		end
	)
	self.RE.Parent = self.Instance

	self.RF = Instance.new("RemoteFunction")
	self.RF.OnServerInvoke = function(player, event: string, ...)
		if typeof(self[event]) == "function" then
			return self[event](self, player, ...)
		else
			return self[event]
		end
	end
	self.RF.Parent = self.Instance

	return self
end

return table.freeze({ new = CarService.new })
