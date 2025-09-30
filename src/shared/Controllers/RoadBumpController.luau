--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadBump = require(ReplicatedStorage.Shared.Classes.RoadBump)

local RoadBumpController = {}
RoadBumpController.__index = RoadBumpController

export type RoadBumpController = {}

function RoadBumpController.new(): RoadBumpController
	local self: RoadBumpController = setmetatable({}, RoadBumpController) :: any

	for _, roadBump in CollectionService:GetTagged("RoadBump") do
		RoadBump.new(roadBump)
	end

	CollectionService:GetInstanceAddedSignal("RoadBump"):Connect(RoadBump.new)

	return self
end

return RoadBumpController.new()
