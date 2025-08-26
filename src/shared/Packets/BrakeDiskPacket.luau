local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)

return Serialization.Packet({
	Temperature = Serialization.MappedNumber8(0, 300),
	Color = Serialization.Color3,
	Volume = Serialization.Percent8,
	Pitch = Serialization.MappedNumber8(0, 5),
})
