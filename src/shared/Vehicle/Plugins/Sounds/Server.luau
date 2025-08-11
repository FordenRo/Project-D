local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundTypesHandler = require(script.Parent.TypesHandler)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local SoundHandler = {}
SoundHandler.__index = SoundHandler

export type SoundHandler = typeof(setmetatable(
	{} :: {
		Vehicle: VehicleTypes.ServerVehicle,
		Sounds: { VehicleTypes.ServerSoundData },
		SoundTypesHandler: SoundTypesHandler.SoundTypesHandler,
	},
	SoundHandler
))

function SoundHandler.new(vehicle: VehicleTypes.ServerVehicle)
	local self: SoundHandler = setmetatable({}, SoundHandler) :: any

	self.Vehicle = vehicle
	self.Sounds = {}
	self.SoundTypesHandler = SoundTypesHandler.new(vehicle)

	for name, sound in self.Vehicle.Tune.Sounds do
		local cachedSound = sound :: VehicleTypes.ServerSoundData
		local instance = Instance.new("Sound")
		instance.Playing = false
		instance.Volume = 0
		instance.Name = name
		instance.SoundId = sound.SoundId
		instance.Parent = sound.Parent and self.Vehicle.Instance.Body.Sounds:FindFirstChild(sound.Parent)
			or self.Vehicle.Instance.Body["#Weight"]
		cachedSound.Instance = instance
		table.insert(self.Sounds, cachedSound)
	end

	RunService.Heartbeat:Connect(function() self:Update() end)

	return self
end

function SoundHandler.Update(self: SoundHandler)
	if not self.Vehicle.Occupant then return end

	self.SoundTypesHandler:HandleSounds(self.Sounds)
end

return SoundHandler
