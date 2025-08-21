local Controls = require(script.Controls)
local PlayerVehicle = require(script.PlayerVehicle)
local SoundData = require(script.SoundData)
local Tune = require(script.Tune)
local Vehicle = require(script.Vehicle)

export type SoundData = SoundData.SoundData
export type ServerSoundData = SoundData.ServerSoundData
export type ClientSoundData = SoundData.ClientSoundData

export type VehicleControls = Controls.VehicleControls
export type VehicleInterface = Vehicle.VehicleInterface
export type VehicleSpeedometer = Vehicle.VehicleSpeedometer
export type EffectFrame = Vehicle.EffectFrame
export type SpeedEffect = Vehicle.SpeedEffect

export type BaseWheel = Vehicle.BaseWheel
export type ClientWheel = Vehicle.ClientWheel
export type ClientWheelSharedData = Vehicle.ClientWheelSharedData
export type ServerWheel = Vehicle.ServerWheel

export type ClientWheelTire = Vehicle.ClientWheelTire
export type ServerWheelTire = Vehicle.ServerWheelTire

export type BaseBrakeDisk = Vehicle.BaseBrakeDisk
export type ClientBrakeDisk = Vehicle.ClientBrakeDisk
export type ServerBrakeDisk = Vehicle.ServerBrakeDisk

export type BaseVehicle = Vehicle.BaseVehicle
export type ClientVehicle = Vehicle.ClientVehicle
export type DeformationController = Vehicle.DeformationController
export type ServerVehicle = Vehicle.ServerVehicle

export type Tune = Tune.Tune
export type PlayerVehicle = PlayerVehicle.PlayerVehicle
export type PlayerVehicleInfo = PlayerVehicle.PlayerVehicleInfo

export type BaseLights = Vehicle.BaseLights
export type Headlight = Vehicle.Headlight
export type ClientLights = Vehicle.ClientLights
export type ServerLights = Vehicle.ServerLights

return {}
