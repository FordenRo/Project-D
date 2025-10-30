local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MaterialGroups = require(
	ReplicatedStorage.Shared.Classes.ClientVehicle.Wheel.Tire.MaterialGroups
)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)

local groups = {}
for k, _ in MaterialGroups do
	table.insert(groups, k)
end

return Serialization.Packet({
	Stress = Serialization.Percent(6),
	Dirt = Serialization.Percent(5),
	Health = Serialization.Percent(5),
	Material = Serialization.State(groups),
})
