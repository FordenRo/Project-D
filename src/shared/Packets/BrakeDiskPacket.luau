local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)

return Serialization.Packet({
	Temperature = Serialization.MappedNumber(0, 300, 6),
	Volume = Serialization.Percent(6),
	Pitch = Serialization.MappedNumber(0.9, 3, 6),
})
