local Controls = require(script.Controls)
local SoundData = require(script.SoundData)
local Tune = require(script.Tune)
local Vehicle = require(script.Vehicle)

local Types = {}

export type SoundData = SoundData.SoundData
export type ServerSoundData = SoundData.ServerSoundData
export type ClientSoundData = SoundData.ClientSoundData

export type VehicleControls = Controls.VehicleControls
export type VehicleInterface = Vehicle.VehicleInterface
export type VehicleSpeedometer = Vehicle.VehicleSpeedometer

export type ClientWheel = Vehicle.ClientWheel
export type ClientWheelSharedData = Vehicle.ClientWheelSharedData
export type ServerWheel = Vehicle.ServerWheel

export type ClientWheelTire = Vehicle.ClientWheelTire
export type ServerWheelTire = Vehicle.ServerWheelTire

export type BaseVehicle = Vehicle.BaseVehicle
export type ClientVehicle = Vehicle.ClientVehicle
export type ServerVehicle = Vehicle.ServerVehicle

export type Tune = Tune.Tune

return Types
