local Controls = require(script.Controls)
local PlayerVehicle = require(script.PlayerVehicle)
local SoundData = require(script.SoundData)
local Tune = require(script.Tune)
local Vehicle = require(script.Vehicle)
local VehicleConstants = require(script.VehicleConstantsType)

export type VehicleControls = Controls.VehicleControls
export type VehicleInterface = Vehicle.VehicleInterface
export type VehicleSpeedometer = Vehicle.VehicleSpeedometer

export type BaseWheel = Vehicle.BaseWheel
export type ClientWheel = Vehicle.ClientWheel
export type ServerWheel = Vehicle.ServerWheel

export type ClientWheelTire = Vehicle.ClientWheelTire
export type ServerWheelTire = Vehicle.ServerWheelTire

export type ClientBrakeDisk = Vehicle.ClientBrakeDisk
export type ServerBrakeDisk = Vehicle.ServerBrakeDisk

export type BaseVehicle = Vehicle.BaseVehicle
export type ClientVehicle = Vehicle.ClientVehicle
export type DeformationController = Vehicle.DeformationController
export type DeformationHandler = Vehicle.DeformationHandler
export type ServerVehicle = Vehicle.ServerVehicle
export type InputController = Vehicle.InputController
export type Engine = Vehicle.Engine
export type EngineTable = Vehicle.EngineTable
export type CameraController = Vehicle.CameraController
export type SoundData = SoundData.SoundData
export type CachedSoundData = SoundData.CachedSoundData
export type SoundController = Vehicle.SoundController
export type SoundTypesHandler = Vehicle.SoundTypesHandler

--- Vehicle configuration
---
--- [*Calculator to tune the engine*](https://www.desmos.com/calculator/cqhgbm0vlt)
export type Tune = Tune.Tune
export type VehicleConstants = VehicleConstants.VehicleConstants
export type PlayerVehicle = PlayerVehicle.PlayerVehicle
export type PlayerVehicleInfo = PlayerVehicle.PlayerVehicleInfo

export type Headlight = Vehicle.Headlight
export type ClientLights = Vehicle.ClientLights

return {}
