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

	for name, sound in self.Vehicle.Tune.Sounds do
		local cachedSound = sound :: SoundTypesHandler.CachedSoundData
		local instance = Instance.new("Sound")
		instance.Playing = false
		instance.Volume = 0
		instance.SoundId = sound.SoundId
		instance.Parent = sound.Parent and self.Vehicle.Instance.Body.Sounds:FindFirstChild(sound.Parent)
			or self.Vehicle.WeightPart
		cachedSound.Instance = instance
		table.insert(self.Sounds, cachedSound)
	end

	self._conn = RunService.Heartbeat:Connect(function() Update(self) end)
	self.Vehicle.Instance.Destroying:Once(function() self:Destroy() end)

	return self
end

function Update(self: SoundController) self.SoundTypesHandler:HandleSounds(self.Sounds) end

function SoundController.Destroy(self: SoundController) self._conn:Disconnect() end

return SoundController
