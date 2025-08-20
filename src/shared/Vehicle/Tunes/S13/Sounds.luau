local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

-- Sounds
Tune.Sounds = {
	Ignition = {
		Type = "Ignition",
		SoundId = "rbxassetid://169394147",
		Parent = "Engine",
		Volume = 2,
		Pitch = 1,
		MaxPitch = 1.1,
	},
	Engine = {
		Type = "Engine",
		SoundId = "rbxassetid://6002661882",
		Parent = "Engine",
		BaseVolume = 0,
		BasePlaybackSpeed = 0,
		RangeStart = 0,
		RangeEnd = 40000,
		RedlinePlaybackSpeed = 0.8,
		RedlineVolume = 0.2,
		ThrottleVolume = 0.2,
		TransitionEnd = 100,
		TransitionStart = 100,
	},
}

return Tune
