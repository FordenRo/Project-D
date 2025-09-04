local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.Sounds = {
	Blowoff = {
		Asset = "rbxassetid://3568930062",
		Emitter = "Engine",
		VolumeIncrease = 0.01,
		PlaybackSpeed = 0.7,
		PlaybackSpeedIncrease = 0.05,
		Sensitivity = -0.2,
	},
	Turbo = {
		Asset = "rbxassetid://240323039",
		Emitter = "Engine",
		PlaybackSpeed = 1,
		PlaybackSpeedIncrease = 0.05,
		VolumeIncrease = 0.01,
	},
	Transmission = {
		Volume = 0.2,
		ClutchVolume = 0.1,
		Gears = { 1, 2, 3, 4, 5, 6 },
		OffVolume = 0.1,
		Emitter = "Transmission",
		Asset = "rbxassetid://406864489",
		ThrottleVolume = 0.1,
		VariablePlaybackSpeed = 1.3,
		VariableVolume = 0.5,
	},
	Fan = {
		Asset = "rbxassetid://11773719101",
		Emitter = "Engine",
		Volume = 1,
	},
	Horn = {
		Asset = "rbxassetid://143133249",
		Emitter = "Engine",
		Volume = 0.7,
	},
	EngineBlow = {
		Asset = "rbxassetid://2648563122",
		Emitter = "Engine",
		Volume = 0.8,
		PlaybackSpeed = 1.4,
	},
}

return Tune
