local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

-- Sounds
Tune.Sounds = {
	Blowoff = {
		Type = "Blowoff",
		SoundId = "rbxassetid://3568930062",
		Parent = "Engine",
		VolumeIncrease = 0.01,
		BasePlaybackSpeed = 0.7,
		PlaybackSpeedIncrease = 0.05,
		Sensitivity = -0.2,
	},
	Turbo = {
		Type = "Turbo",
		SoundId = "rbxassetid://240323039",
		Parent = "Engine",
		BasePlaybackSpeed = 1,
		PlaybackSpeedIncrease = 0.05,
		VolumeIncrease = 0.01,
	},
	Transmission = {
		Type = "Transmission",
		BaseVolume = 0.2,
		ClutchVolume = 0.1,
		Gears = { 1, 2, 3, 4, 5, 6 },
		OffVolume = 0.1,
		Parent = "Transmission",
		SoundId = "rbxassetid://406864489",
		ThrottleVolume = 0.1,
		VariablePlaybackSpeed = 1.3,
		VariableVolume = 0.5,
	},
	Fan = {
		Type = "Fan",
		SoundId = "rbxassetid://11773719101",
		Parent = "Engine",
		BaseVolume = 1,
		BasePlaybackSpeed = 1,
	},
	Horn = {
		Type = "Horn",
		SoundId = "rbxassetid://143133249",
		Parent = "Engine",
		BaseVolume = 0.7,
		BasePlaybackSpeed = 1,
	},
}

return Tune
