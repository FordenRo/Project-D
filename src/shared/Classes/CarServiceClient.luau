--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarServiceTypes = require(ReplicatedStorage.Shared.Types.CarServiceTypes)
local GarageDoor = require(script.Parent.GarageDoor)

local CarService = {}
CarService.__index = CarService

type CarServiceClient = CarServiceTypes.CarServiceClient

type CarServiceClientImpl = {
	RE: RemoteEvent,
	RF: RemoteFunction,
	garageDoors: { GarageDoor.GarageDoor },
} & CarServiceClient

function CarService.new(instance: Model): CarServiceClient
	local self: CarServiceClientImpl = setmetatable({}, CarService) :: any

	self.Instance = instance :: any

	self.RE = self.Instance:FindFirstChildOfClass("RemoteEvent") :: RemoteEvent
	self.RE.OnClientEvent:Connect(
		function(event: string, ...) self[event](self, ...) end
	)

	self.RF =
		self.Instance:FindFirstChildOfClass("RemoteFunction") :: RemoteFunction
	self.RF.OnClientInvoke = function(event: string, ...)
		if typeof(self[event]) == "function" then
			return self[event](self, ...)
		else
			return self[event]
		end
	end

	self.Occupants = self.RF:InvokeServer("Occupants")

	task.wait(1)

	self.garageDoors = {}
	for _, v in self.Instance.GarageDoors:GetChildren() do
		local sk = string.gsub(v.Name, "Door", "")
		local k = tonumber(sk)
		if not k then continue end

		self.garageDoors[k] = GarageDoor.new(v)

		if not self.Occupants[k] then self.garageDoors[k]:Open() end
	end

	return self
end

function CarService.Occupied(
	self: CarServiceClientImpl,
	player: Player,
	index: number
)
	self.Occupants[index] = player
	self.garageDoors[index]:Close()
end

return table.freeze({ new = CarService.new })
