local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)

return Serialization.Packet({
	Dirt = Serialization.Percent8,
	Fuel = Serialization.Percent16,
	Clutch = Serialization.Percent8,
	Gear = Serialization.Int8,
	RPM = Serialization.MappedNumber16(0, 20000),
	Throttle = Serialization.Percent8,
	Brake = Serialization.Percent8,
	Steering = Serialization.Percent16,
	Engine = Serialization.Packet({
		Health = Serialization.Percent16,
		Broken = Serialization.Boolean,
		Temperature = Serialization.MappedNumber8(0, 150),

		BoostTurbo = Serialization.Float32,
		BoostSuper = Serialization.Float32,

		TqNatural = Serialization.Float32,
		TqElectric = Serialization.Float32,
	}),
	Flags = Serialization.Uint8,
})
