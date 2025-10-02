--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundData = require(ReplicatedStorage.Shared.Types.VehicleTypes.SoundData)
local SoundTypesHandler = require(script.TypesHandler)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local SoundController = {}
SoundController.__index = SoundController

type SoundController = VehicleTypes.SoundController

function SoundController.new(
	vehicle: VehicleTypes.ClientVehicle
): SoundController
	local self: SoundController = setmetatable({}, SoundController) :: any

	self.Vehicle = vehicle
	self.Sounds = {}
	self.Emitters = {}

	local handler = SoundTypesHandler.new(vehicle)

	for _, v in self.Vehicle.Instance:GetDescendants() do
		if not v:IsA("AudioEmitter") then continue end

		self.Emitters[v.Name] = v
	end

	self.Emitters.WeightPart = Instance.new("AudioEmitter")
	self.Emitters.WeightPart.Parent = self.Vehicle.WeightPart

	local folder = Instance.new("Folder")
	folder.Name = "AudioPlayers"
	folder.Parent = self.Vehicle.Instance

	for name, soundData in self.Vehicle.Tune.Sounds do
		local cachedSound = table.clone(soundData) :: SoundData.CachedSoundData

		local audioPlayer = Instance.new("AudioPlayer")
		audioPlayer.Volume = soundData.Volume or 1
		audioPlayer.PlaybackSpeed = soundData.PlaybackSpeed or 1
		audioPlayer.Asset = soundData.Asset
		audioPlayer.Name = name
		audioPlayer.Parent = folder

		local wire = Instance.new("Wire")
		wire.SourceInstance = audioPlayer
		wire.TargetInstance = self.Emitters[soundData.Emitter or "WeightPart"]
		wire.Parent = audioPlayer

		cachedSound.AudioPlayer = audioPlayer
		self.Sounds[name] = cachedSound
	end

	local tireFolder = Instance.new("Folder")
	tireFolder.Name = "Tire"
	tireFolder.Parent = folder

	for material, asset in self.Vehicle.Tune.TireSounds do
		for _, wheel in self.Vehicle.Wheels :: { VehicleTypes.ClientWheel } do
			local cachedSound = {} :: SoundData.CachedSoundData

			local audioPlayer = Instance.new("AudioPlayer")
			audioPlayer.Asset = asset
			audioPlayer.Name = `{wheel.Instance.Name}Tire{material}`
			audioPlayer.Parent = tireFolder

			local equalizer = Instance.new("AudioEqualizer")
			equalizer.HighGain = -80
			equalizer.MidRange = NumberRange.new(500, 7000)
			equalizer.Parent = audioPlayer

			local eqWire = Instance.new("Wire")
			eqWire.SourceInstance = audioPlayer
			eqWire.TargetInstance = equalizer
			eqWire.Parent = equalizer

			local wire = Instance.new("Wire")
			wire.SourceInstance = equalizer
			wire.TargetInstance = self.Emitters[`{wheel.Instance.Name}Wheel`]
			wire.Parent = audioPlayer

			cachedSound.AudioPlayer = audioPlayer
			self.Sounds[`{wheel.Instance.Name}Tire{material}`] = cachedSound
		end
	end

	local trove = Trove.new()
	trove:Connect(
		RunService.Heartbeat,
		function() handler:HandleSounds(self.Sounds) end
	)
	trove:AttachToInstance(self.Vehicle.Instance)

	return self
end

return table.freeze({ new = SoundController.new })
