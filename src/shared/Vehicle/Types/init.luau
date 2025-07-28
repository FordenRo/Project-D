local Controls = require(script.Controls)
local Interface = require(script.Interface)
local SoundData = require(script.SoundData)
local Tire = require(script.Tire)
local Tune = require(script.Tune)
local Vehicle = require(script.Vehicle)
local Wheel = require(script.Wheel)

local Types = {}

export type SoundData = SoundData.SoundData
export type ServerSoundData = SoundData.ServerSoundData
export type ClientSoundData = SoundData.ClientSoundData

export type VehicleControls = Controls.VehicleControls

export type VehicleInterface = Interface.VehicleInterface
export type VehicleSpeedometer = Interface.VehicleSpeedometer

export type ClientWheel = Wheel.ClientWheel
export type ClientWheelSharedData = Wheel.ClientWheelSharedData
export type ServerWheel = Wheel.ServerWheel

export type ClientWheelTire = Tire.ClientWheelTire
export type ServerWheelTire = Tire.ServerWheelTire

export type BaseVehicle = Vehicle.BaseVehicle
export type ClientVehicle = Vehicle.ClientVehicle
export type ServerVehicle = Vehicle.ServerVehicle

export type Tune = Tune.Tune

return Types
