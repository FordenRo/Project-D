local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Default = require(ReplicatedStorage.Shared.Vehicle.Tunes.Default)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

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

for k, v in Default.Sounds do
	if Tune.Sounds[k] then continue end

	Tune.Sounds[k] = v
end

return Tune
