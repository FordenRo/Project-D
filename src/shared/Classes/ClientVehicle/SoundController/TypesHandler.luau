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

export type CachedSoundData = VehicleTypes.SoundData & { AudioPlayer: AudioPlayer, Played: boolean?, Type: string }

function SoundTypesHandler.new(vehicle: VehicleTypes.ClientVehicle): SoundTypesHandler
	local self: SoundTypesHandler = setmetatable({}, SoundTypesHandler) :: any

	self.Vehicle = vehicle
	self._UpdateBOV = false
	self._PrevBoostTurbo = 0
	self._LastBOV = 0

	return self
end

function SoundTypesHandler.Engine(self: SoundTypesHandler, sound: CachedSoundData)
	if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

	sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed
		+ (sound.RedlinePlaybackSpeed - sound.PlaybackSpeed) * (self.Vehicle.RPM / self.Vehicle.Tune.Redline)

	sound.AudioPlayer.Volume = (self.Vehicle.IsOn and 1 or 0)
		* (sound.Volume + (sound.ThrottleVolume * self.Vehicle.Throttle) + (sound.RedlineVolume * (self.Vehicle.RPM / self.Vehicle.Tune.Redline)))
		* math.clamp(1 / sound.TransitionStart * (self.Vehicle.RPM - sound.RangeStart), 0, 1)
		* math.clamp(-1 / sound.TransitionEnd * (self.Vehicle.RPM - sound.RangeEnd), 0, 1)
end

function SoundTypesHandler.Transmission(self: SoundTypesHandler, sound: CachedSoundData)
	if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

	sound.AudioPlayer.PlaybackSpeed = sound.VariablePlaybackSpeed
		* (self.Vehicle.AverageRotSpeed / (300 * (Units.Length_mm / 1000) * 3.6))

	sound.AudioPlayer.Volume = table.find(sound.Gears, self.Vehicle.Gear)
			and (sound.ClutchVolume + ((sound.Volume + sound.VariableVolume * (self.Vehicle.AverageRotSpeed / (300 * (Units.Length_mm / 1000) * 3.6))) - sound.ClutchVolume) * (1 - self.Vehicle.Clutch) + sound.ThrottleVolume * self.Vehicle.Throttle)
		or sound.OffVolume
end

function SoundTypesHandler.Turbo(self: SoundTypesHandler, sound: CachedSoundData)
	if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

	sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed + sound.PlaybackSpeedIncrease * self.Vehicle.Engine.BoostTurbo
	sound.AudioPlayer.Volume = sound.VolumeIncrease * self.Vehicle.Engine.BoostTurbo
end

function SoundTypesHandler.Super(self: SoundTypesHandler, sound: CachedSoundData)
	if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

	sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed + sound.PlaybackSpeedIncrease * self.Vehicle.Engine.BoostSuper
	sound.AudioPlayer.Volume = sound.VolumeIncrease * self.Vehicle.Engine.BoostSuper
end

function SoundTypesHandler.Blowoff(self: SoundTypesHandler, sound: CachedSoundData)
	if
		(self.Vehicle.Engine.BoostTurbo - sound.Sensitivity < self._PrevBoostTurbo)
		and (tick() - self._LastBOV > 1)
		and self.Vehicle.Throttle < 0.8
	then
		self._UpdateBOV = true
		sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed
			+ sound.PlaybackSpeedIncrease * self.Vehicle.Engine.BoostTurbo

		sound.AudioPlayer.Volume = sound.VolumeIncrease * self.Vehicle.Engine.BoostTurbo
		sound.AudioPlayer.TimePosition = 0
		sound.AudioPlayer:Play()
	end
	self._PrevBoostTurbo = self.Vehicle.Engine.BoostTurbo
end

function SoundTypesHandler.Ignition(self: SoundTypesHandler, sound: CachedSoundData)
	if self.Vehicle.Starting then
		if not sound.Played then
			sound.AudioPlayer.TimePosition = 0
			sound.AudioPlayer:Play()
		end
		sound.Played = true
		sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed
			+ (sound.MaxPlaybackSpeed - sound.PlaybackSpeed) * (self.Vehicle.RPM / self.Vehicle.Tune.IgnitionRPM)
	else
		if sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Stop() end
		sound.Played = false
	end
end

function SoundTypesHandler.EngineBlow(self: SoundTypesHandler, sound: CachedSoundData)
	if self.Vehicle.Engine.Health == 0 then
		if sound.Played then return end

		sound.Played = true
		sound.AudioPlayer:Play()
	end
end

function SoundTypesHandler.Fan(self: SoundTypesHandler, sound: CachedSoundData)
	if self.Vehicle.FanSpeed > 0 then
		if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

		sound.AudioPlayer.Volume = self.Vehicle.RPM / self.Vehicle.Tune.Redline ^ 0.5 * sound.Volume
		sound.AudioPlayer.PlaybackSpeed = self.Vehicle.Tune.FanAirSpeed / 10 * sound.PlaybackSpeed
	else
		if sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Stop() end
	end
end

function SoundTypesHandler.Horn(self: SoundTypesHandler, sound: CachedSoundData)
	if self.Vehicle.Horning then
		sound.AudioPlayer:Play()
	else
		sound.AudioPlayer:Stop()
	end
end

function SoundTypesHandler.HandbrakeOn(self: SoundTypesHandler, sound: CachedSoundData)
	if self.Vehicle.PBrake then
		if not sound.Played then
			sound.AudioPlayer.TimePosition = 0
			sound.AudioPlayer:Play()
		end
		sound.Played = true
	else
		if sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Stop() end
		sound.Played = false
	end
end

function SoundTypesHandler.HandbrakeOff(self: SoundTypesHandler, sound: CachedSoundData)
	if not self.Vehicle.PBrake then
		if not sound.Played then
			sound.AudioPlayer.TimePosition = 0
			sound.AudioPlayer:Play()
		end
		sound.Played = true
	else
		if sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Stop() end
		sound.Played = false
	end
end

function SoundTypesHandler.GearLever(self: SoundTypesHandler, sound: CachedSoundData)
	if sound.LastGear ~= self.Vehicle.Gear then
		sound.LastGear = self.Vehicle.Gear
		sound.AudioPlayer.TimePosition = 0
		sound.AudioPlayer:Play()
	end
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
