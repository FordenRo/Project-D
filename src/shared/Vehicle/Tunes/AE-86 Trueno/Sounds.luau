local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Default = require(ReplicatedStorage.Shared.Vehicle.Tunes.Default)
local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.Sounds = {
	Ignition = {
		Type = "Ignition",
		Asset = "rbxassetid://169394147",
		Emitter = "Engine",
		Volume = 2,
		PlaybackSpeed = 1,
		MaxPlaybackSpeed = 1.1,
	},
	Engine = {
		Type = "Engine",
		Asset = "rbxassetid://6002661882",
		Emitter = "Engine",
		Volume = 0,
		PlaybackSpeed = 0,
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
