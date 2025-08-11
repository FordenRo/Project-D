local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local CarServiceServer = require(ServerScriptService.Server.Classes.CarServiceServer)

local CarServiceHandler = {}
CarServiceHandler.__index = CarServiceHandler

export type CarServiceHandler = typeof(setmetatable({}, CarServiceHandler))

function CarServiceHandler.new()
	local self = setmetatable({}, CarServiceHandler)

	for _, v in CollectionService:GetTagged("CarService") do
		CarServiceServer.new(v)
	end
	CollectionService:GetInstanceAddedSignal("CarService"):Connect(CarServiceServer.new)

	return self
end

return CarServiceHandler.new()
