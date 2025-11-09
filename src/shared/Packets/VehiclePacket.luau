local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)

return {
	Init = Serialization.Packet({
		Owner = Serialization.Player,
		Dirt = Serialization.Percent(16),
		Fuel = Serialization.Percent(16),
		Engine = Serialization.Packet({
			Health = Serialization.Percent(16),
		}),
		Mileage = Serialization.Uint(32),
	}),
	Update = Serialization.Packet({
		IgnitionState = Serialization.State({ "Off", "Acc", "On", "Starting" }),
		Shifting = Serialization.Boolean,
		Horning = Serialization.Boolean,
		Dirt = Serialization.Percent(5),
		Fuel = Serialization.Percent(6),
		Clutch = Serialization.Percent(3),
		Gear = Serialization.Uint(3),
		RPM = Serialization.MappedNumber(0, 15000, 10),
		Throttle = Serialization.Percent(3),
		Brake = Serialization.Percent(3),
		Steering = Serialization.Percent(8),
		Engine = Serialization.Packet({
			IsOn = Serialization.Boolean,
			Health = Serialization.Percent(6),
			Temperature = Serialization.MappedNumber(0, 130, 7),
			DriveshaftStress = Serialization.MappedNumber(0, 2, 5),

			BoostTurbo = Serialization.Float,
			BoostSuper = Serialization.Float,

			TqNatural = Serialization.Float,
			TqElectric = Serialization.Float,
		}),
	}),
}
