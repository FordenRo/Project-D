local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarServiceTypes = require(ReplicatedStorage.Shared.Types.CarServiceTypes)
local GarageDoor = require(script.Parent.GarageDoor)

local CarService = {}
CarService.__index = CarService

type CarServiceClient = CarServiceTypes.CarServiceClient

function CarService.new(instance: Model): CarServiceClient
	local self: CarServiceClient = setmetatable({}, CarService) :: any

	self.Instance = instance :: any

	self._RE = self.Instance:FindFirstChildOfClass("RemoteEvent") :: RemoteEvent
	self._RE.OnClientEvent:Connect(function(event: string, ...) self[event](self, ...) end)

	self._RF = self.Instance:FindFirstChildOfClass("RemoteFunction") :: RemoteFunction
	self._RF.OnClientInvoke = function(event: string, ...)
		if typeof(self[event]) == "function" then
			return self[event](self, ...)
		else
			return self[event]
		end
	end

	self.Occupants = self._RF:InvokeServer("Occupants")

	task.wait(1)

	self._GarageDoors = {}
	for _, v in self.Instance.GarageDoors:GetChildren() do
		local sk = string.gsub(v.Name, "Door", "")
		local k = tonumber(sk)
		self._GarageDoors[k] = GarageDoor.new(v)

		if not self.Occupants[k] then self._GarageDoors[k]:Open() end
	end

	return self
end

function CarService.Occupied(self: CarServiceClient, player: Player, index: number)
	self.Occupants[index] = player
	self._GarageDoors[index]:Close()
end

return CarService
