local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBump = require(ReplicatedStorage.Shared.Classes.RoadBump)

local RoadBumpController = {}
RoadBumpController.__index = RoadBumpController

function RoadBumpController.new()
	local self = setmetatable({}, RoadBumpController)

	for _, roadBump in CollectionService:GetTagged("RoadBump") do
		RoadBump.new(roadBump)
	end

	CollectionService:GetInstanceAddedSignal("RoadBump"):Connect(function(roadBump) RoadBump.new(roadBump) end)

	return self
end

return RoadBumpController.new()
