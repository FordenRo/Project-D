--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundData = require(ReplicatedStorage.Shared.Types.VehicleTypes.SoundData)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local SoundTypesHandler = {}
SoundTypesHandler.__index = SoundTypesHandler

type SoundTypesHandler = VehicleTypes.SoundTypesHandler

type SoundTypesHandlerImpl = {
	updateBOV: boolean,
	prevBoostTurbo: number,
	lastBOV: number,
} & SoundTypesHandler

function SoundTypesHandler.new(
	vehicle: VehicleTypes.ClientVehicle
): SoundTypesHandler
	local self: SoundTypesHandlerImpl =
		setmetatable({}, SoundTypesHandler) :: any

	self.Vehicle = vehicle
	self.updateBOV = false
	self.prevBoostTurbo = 0
	self.lastBOV = 0

	return self
end

local Handlers = {}

function Handlers.Engine(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

	sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed
		+ (sound.RedlinePlaybackSpeed - sound.PlaybackSpeed)
			* (self.Vehicle.RPM / self.Vehicle.Engine.Tune.Redline)

	sound.AudioPlayer.Volume = (self.Vehicle.Engine.IsOn and 1 or 0)
		* (sound.Volume + (sound.ThrottleVolume * self.Vehicle.Throttle) + (sound.RedlineVolume * (self.Vehicle.RPM / self.Vehicle.Engine.Tune.Redline)))
		* math.clamp(
			1 / sound.TransitionStart * (self.Vehicle.RPM - sound.RangeStart),
			0,
			1
		)
		* math.clamp(
			-1 / sound.TransitionEnd * (self.Vehicle.RPM - sound.RangeEnd),
			0,
			1
		)
end

function Handlers.Transmission(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

	local avgRotSpeed = 0
	for _, wheel in self.Vehicle.Wheels :: { VehicleTypes.ClientWheel } do
		avgRotSpeed += math.abs(
			wheel.Instance.CFrame:VectorToObjectSpace(
				wheel.Instance.AssemblyAngularVelocity
			).X
		)
	end
	avgRotSpeed /= #self.Vehicle.Wheels

	sound.AudioPlayer.PlaybackSpeed = sound.VariablePlaybackSpeed
		* (avgRotSpeed / (300 * (Units.Length_mm / 1000) * 3.6))

	sound.AudioPlayer.Volume = table.find(sound.Gears, self.Vehicle.Gear)
			and (sound.ClutchVolume + ((sound.Volume + sound.VariableVolume * (avgRotSpeed / (300 * (Units.Length_mm / 1000) * 3.6))) - sound.ClutchVolume) * (1 - self.Vehicle.Clutch) + sound.ThrottleVolume * self.Vehicle.Throttle)
		or sound.OffVolume
end

function Handlers.Turbo(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

	sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed
		+ sound.PlaybackSpeedIncrease * self.Vehicle.Engine.BoostTurbo
	sound.AudioPlayer.Volume = sound.VolumeIncrease
		* self.Vehicle.Engine.BoostTurbo
end

function Handlers.Super(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

	sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed
		+ sound.PlaybackSpeedIncrease * self.Vehicle.Engine.BoostSuper
	sound.AudioPlayer.Volume = sound.VolumeIncrease
		* self.Vehicle.Engine.BoostSuper
end

function Handlers.Blowoff(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if
		(
			self.Vehicle.Engine.BoostTurbo - sound.Sensitivity
			< self.prevBoostTurbo
		)
		and (tick() - self.lastBOV > 1)
		and self.Vehicle.Throttle < 0.8
	then
		self.updateBOV = true
		sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed
			+ sound.PlaybackSpeedIncrease * self.Vehicle.Engine.BoostTurbo

		sound.AudioPlayer.Volume = sound.VolumeIncrease
			* self.Vehicle.Engine.BoostTurbo
		sound.AudioPlayer.TimePosition = 0
		sound.AudioPlayer:Play()
	end
	self.prevBoostTurbo = self.Vehicle.Engine.BoostTurbo
end

function Handlers.Ignition(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if self.Vehicle.IgnitionState == "Starting" then
		if not sound.Played then
			sound.AudioPlayer.TimePosition = 0
			sound.AudioPlayer:Play()
		end
		sound.Played = true
		sound.AudioPlayer.PlaybackSpeed = sound.PlaybackSpeed
			+ (sound.MaxPlaybackSpeed - sound.PlaybackSpeed)
				* (self.Vehicle.RPM / self.Vehicle.Engine.Tune.IgnitionRPM)
	else
		if sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Stop() end
		sound.Played = false
	end
end

function Handlers.EngineBlow(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if self.Vehicle.Engine.Health == 0 then
		if sound.Played then return end

		sound.Played = true
		sound.AudioPlayer:Play()
	end
end

function Handlers.Fan(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if self.Vehicle.FanSpeed > 0 then
		if not sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Play() end

		sound.AudioPlayer.Volume = self.Vehicle.RPM
			/ self.Vehicle.Engine.Tune.Redline ^ 0.5
			* sound.Volume
		sound.AudioPlayer.PlaybackSpeed = self.Vehicle.Tune.FanAirSpeed
			/ 10
			* sound.PlaybackSpeed
	else
		if sound.AudioPlayer.IsPlaying then sound.AudioPlayer:Stop() end
	end
end

function Handlers.Horn(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if self.Vehicle.Horning then
		sound.AudioPlayer:Play()
	else
		sound.AudioPlayer:Stop()
	end
end

function Handlers.HandbrakeOn(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
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

function Handlers.HandbrakeOff(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
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

function Handlers.GearLever(
	self: SoundTypesHandlerImpl,
	sound: SoundData.CachedSoundData
)
	if sound.LastGear ~= self.Vehicle.Gear then
		sound.LastGear = self.Vehicle.Gear
		sound.AudioPlayer.TimePosition = 0
		sound.AudioPlayer:Play()
	end
end

function SoundTypesHandler.HandleSounds(
	self: SoundTypesHandlerImpl,
	sounds: { SoundData.CachedSoundData }
)
	for k, sound in sounds do
		if typeof(Handlers[k]) ~= "function" then continue end

		Handlers[k](self, sound)
	end

	if self.updateBOV then
		self.lastBOV = tick()
		self.updateBOV = false
	end
end

return table.freeze({ new = SoundTypesHandler.new })
