local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarServiceClient =
	require(ReplicatedStorage.Shared.Classes.CarServiceClient)

local CarServiceController = {}
CarServiceController.__index = CarServiceController

export type CarServiceController = {}

function CarServiceController.new(): CarServiceController
	local self: CarServiceController =
		setmetatable({}, CarServiceController) :: any

	for _, v in CollectionService:GetTagged("CarService") do
		CarServiceClient.new(v)
	end
	CollectionService:GetInstanceAddedSignal("CarService")
		:Connect(CarServiceClient.new)

	return self
end

return CarServiceController.new()
