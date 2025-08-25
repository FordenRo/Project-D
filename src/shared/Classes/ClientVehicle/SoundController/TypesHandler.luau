local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local SoundTypesHandler = {}
SoundTypesHandler.__index = SoundTypesHandler

export type SoundTypesHandler = typeof(setmetatable(
	{} :: {
		Vehicle: VehicleTypes.ClientVehicle,
		_UpdateBOV: boolean,
		_PrevBoostTurbo: number,
		_LastBOV: number,
	},
	SoundTypesHandler
))

export type CachedSoundData = VehicleTypes.SoundData & { Instance: Sound }

function SoundTypesHandler.new(vehicle: VehicleTypes.ClientVehicle)
	local self: SoundTypesHandler = setmetatable({}, SoundTypesHandler) :: any

	self.Vehicle = vehicle
	self._UpdateBOV = false
	self._PrevBoostTurbo = 0
	self._LastBOV = 0

	return self
end

function SoundTypesHandler.Engine(self: SoundTypesHandler, sound: CachedSoundData)
	if sound.Instance.Playing == false then sound.Instance.Playing = true end

	sound.Instance.PlaybackSpeed = sound.BasePlaybackSpeed
		+ (sound.RedlinePlaybackSpeed - sound.BasePlaybackSpeed) * (self.Vehicle.RPM / self.Vehicle.Tune.Redline)

	sound.Instance.Volume = (self.Vehicle.IsOn and 1 or 0)
		* (sound.BaseVolume + (sound.ThrottleVolume * self.Vehicle.Throttle) + (sound.RedlineVolume * (self.Vehicle.RPM / self.Vehicle.Tune.Redline)))
		* math.clamp(1 / sound.TransitionStart * (self.Vehicle.RPM - sound.RangeStart), 0, 1)
		* math.clamp(-1 / sound.TransitionEnd * (self.Vehicle.RPM - sound.RangeEnd), 0, 1)
end

function SoundTypesHandler.Transmission(self: SoundTypesHandler, sound: CachedSoundData)
	if sound.Instance.Playing == false then sound.Instance.Playing = true end

	sound.Instance.PlaybackSpeed = sound.VariablePlaybackSpeed
		* (self.Vehicle.AverageRotSpeed / (300 * (Units.Length_mm / 1000) * 3.6))

	sound.Instance.Volume = table.find(sound.Gears, self.Vehicle.Gear)
			and (sound.ClutchVolume + ((sound.BaseVolume + sound.VariableVolume * (self.Vehicle.AverageRotSpeed / (300 * (Units.Length_mm / 1000) * 3.6))) - sound.ClutchVolume) * (1 - self.Vehicle.Clutch) + sound.ThrottleVolume * self.Vehicle.Throttle)
		or sound.OffVolume
end

function SoundTypesHandler.Turbo(self: SoundTypesHandler, sound: CachedSoundData)
	if sound.Instance.Playing == false then sound.Instance.Playing = true end

	sound.Instance.PlaybackSpeed = sound.BasePlaybackSpeed
		+ sound.PlaybackSpeedIncrease * self.Vehicle.Engine.BoostTurbo

	sound.Instance.Volume = sound.VolumeIncrease * self.Vehicle.Engine.BoostTurbo
end

function SoundTypesHandler.Super(self: SoundTypesHandler, sound: CachedSoundData)
	if sound.Instance.Playing == false then sound.Instance.Playing = true end

	sound.Instance.PlaybackSpeed = sound.BasePlaybackSpeed
		+ sound.PlaybackSpeedIncrease * self.Vehicle.Engine.BoostSuper

	sound.Instance.Volume = sound.VolumeIncrease * self.Vehicle.Engine.BoostSuper
end

function SoundTypesHandler.Blowoff(self: SoundTypesHandler, sound: CachedSoundData)
	if
		(self.Vehicle.Engine.BoostTurbo - sound.Sensitivity < self._PrevBoostTurbo)
		and (tick() - self._LastBOV > 1)
		and self.Vehicle.Throttle < 0.8
	then
		self._UpdateBOV = true
		sound.Instance.PlaybackSpeed = sound.BasePlaybackSpeed
			+ sound.PlaybackSpeedIncrease * self.Vehicle.Engine.BoostTurbo

		sound.Instance.Volume = sound.VolumeIncrease * self.Vehicle.Engine.BoostTurbo
		sound.Instance.TimePosition = 0
		sound.Instance.Playing = true
	end
	self._PrevBoostTurbo = self.Vehicle.Engine.BoostTurbo
end

function SoundTypesHandler.Ignition(self: SoundTypesHandler, sound: CachedSoundData)
	if self.Vehicle.Starting then
		if not sound.Instance:GetAttribute("Played") then
			sound.Instance.TimePosition = 0
			sound.Instance.Playing = true
		end
		sound.Instance:SetAttribute("Played", true)
		sound.Instance.Volume = sound.Volume
		sound.Instance.PlaybackSpeed = sound.Pitch
			+ (sound.MaxPitch - sound.Pitch) * (self.Vehicle.RPM / self.Vehicle.Tune.IgnitionRPM)
	else
		sound.Instance:SetAttribute("Played", false)
		if sound.Instance.Playing then sound.Instance.Playing = false end
	end
end

function SoundTypesHandler.EngineBlow(self: SoundTypesHandler, sound: CachedSoundData)
	if self.Vehicle.Engine.Health == 0 then
		if sound.Instance:GetAttribute("Played") then return end

		sound.Instance:SetAttribute("Played", true)
		sound.Instance.Volume = sound.BaseVolume
		sound.Instance.PlaybackSpeed = sound.BasePlaybackSpeed
		sound.Instance.Playing = true
	end
end

function SoundTypesHandler.Fan(self: SoundTypesHandler, sound: CachedSoundData)
	if self.Vehicle.FanSpeed > 0 then
		if not sound.Instance.Playing then sound.Instance.Playing = true end

		sound.Instance.Volume = self.Vehicle.RPM / self.Vehicle.Tune.Redline ^ 0.5 * sound.BaseVolume
		sound.Instance.PlaybackSpeed = self.Vehicle.Tune.FanAirSpeed / 10 * sound.BasePlaybackSpeed
	else
		if sound.Instance.Playing then sound.Instance.Playing = false end
	end
end

function SoundTypesHandler.Horn(self: SoundTypesHandler, sound: CachedSoundData)
	sound.Instance.Playing = self.Vehicle.Horning
	sound.Instance.Volume = sound.BaseVolume
	sound.Instance.PlaybackSpeed = sound.BasePlaybackSpeed
end

function SoundTypesHandler.HandleSounds(self: SoundTypesHandler, sounds: { CachedSoundData })
	for _, sound in sounds do
		self[sound.Type](self, sound)
	end

	if self._UpdateBOV then
		self._LastBOV = tick()
		self._UpdateBOV = false
	end
end

return SoundTypesHandler
