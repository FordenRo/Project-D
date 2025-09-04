local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundTypesHandler = require(script.TypesHandler)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local SoundController = {}
SoundController.__index = SoundController

export type SoundController = typeof(setmetatable(
	{} :: {
		_conn: RBXScriptConnection,
		Vehicle: VehicleTypes.ClientVehicle,
		Sounds: { SoundTypesHandler.CachedSoundData },
		SoundTypesHandler: SoundTypesHandler.SoundTypesHandler,
	},
	SoundController
))

function SoundController.new(vehicle: VehicleTypes.ClientVehicle): SoundController
	local self: SoundController = setmetatable({}, SoundController) :: any

	self.Vehicle = vehicle
	self.Sounds = {}
	self.SoundTypesHandler = SoundTypesHandler.new(vehicle)

	local emitters = {}
	for _, v in self.Vehicle.Instance:GetDescendants() do
		if not v:IsA("AudioEmitter") then continue end

		emitters[v.Name] = v
	end

	local folder = Instance.new("Folder")
	folder.Name = "AudioPlayers"
	folder.Parent = self.Vehicle.Instance

	for name, sound in self.Vehicle.Tune.Sounds do
		local cachedSound = table.clone(sound) :: SoundTypesHandler.CachedSoundData

		local audioPlayer = Instance.new("AudioPlayer")
		audioPlayer.Volume = sound.Volume or 1
		audioPlayer.PlaybackSpeed = sound.PlaybackSpeed or 1
		audioPlayer.Asset = sound.Asset
		audioPlayer.Name = name
		audioPlayer.Parent = folder

		local wire = Instance.new("Wire")
		wire.SourceInstance = audioPlayer
		wire.TargetInstance = emitters[sound.Emitter]
		wire.Parent = audioPlayer

		cachedSound.Type = name
		cachedSound.AudioPlayer = audioPlayer
		table.insert(self.Sounds, cachedSound)
	end

	self._conn = RunService.Heartbeat:Connect(function() Update(self) end)
	self.Vehicle.Instance.Destroying:Once(function() self:Destroy() end)

	return self
end

function Update(self: SoundController) self.SoundTypesHandler:HandleSounds(self.Sounds) end

function SoundController.Destroy(self: SoundController) self._conn:Disconnect() end

return SoundController
