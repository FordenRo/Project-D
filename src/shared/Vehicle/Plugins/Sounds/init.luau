local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundTypesHandler = require(script.TypesHandler)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

if not RunService:IsClient() then return require(script.Server) end

local SoundController = {}
SoundController.__index = SoundController

export type SoundController = typeof(setmetatable(
	{} :: {
		Vehicle: Types.ClientVehicle,
		Sounds: { Types.ClientSoundData },
		SoundTypesHandler: SoundTypesHandler.SoundTypesHandler,
	},
	SoundController
))

function SoundController.new(vehicle: Types.ClientVehicle)
	local self: SoundController = setmetatable({}, SoundController) :: any

	self.Vehicle = vehicle
	self.Sounds = {}
	self.SoundTypesHandler = SoundTypesHandler.new(vehicle)

	for name, sound in self.Vehicle.Tune.Sounds do
		local cachedSound = sound :: Types.ClientSoundData
		local instance = Instance.new("Sound")
		instance.Playing = false
		instance.Volume = 0
		instance.Name = name .. "_Local"
		instance.SoundId = sound.SoundId
		instance.Parent = sound.Parent and self.Vehicle.Instance.Body.Sounds:FindFirstChild(sound.Parent)
			or self.Vehicle.Instance.Body["#Weight"]
		cachedSound.Instance = instance
		cachedSound.ServerInstance = instance.Parent:FindFirstChild(name) :: Sound
		cachedSound.ServerInstance.SoundId = ""
		table.insert(self.Sounds, cachedSound)
	end

	RunService.Heartbeat:Connect(function() self:Update() end)

	return self
end

function SoundController.Update(self: SoundController) self.SoundTypesHandler:HandleSounds(self.Sounds) end

function SoundController.Destroy(self: SoundController)
	for _, sound in self.Sounds do
		sound.Instance:Destroy()
		if sound.ServerInstance then sound.ServerInstance.SoundId = sound.SoundId end
	end
end

return SoundController
