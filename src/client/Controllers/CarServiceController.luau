local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarServiceClient = require(ReplicatedStorage.Shared.Classes.CarServiceClient)

local CarServiceController = {}
CarServiceController.__index = CarServiceController

export type CarServiceController = typeof(setmetatable({}, CarServiceController))

function CarServiceController.new()
	local self = setmetatable({}, CarServiceController) :: CarServiceController

	for _, v in CollectionService:GetTagged("CarService") do
		CarServiceClient.new(v)
	end
	CollectionService:GetInstanceAddedSignal("CarService"):Connect(CarServiceClient.new)

	return self
end

return CarServiceController.new()
