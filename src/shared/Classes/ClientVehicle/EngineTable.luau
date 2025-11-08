local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local EngineTable: VehicleTypes.EngineTable = {
	IsOn = false,
	Health = 1,
	Temperature = workspace:GetAttribute("GlobalTemperature") :: number,
	DriveshaftStress = 0,

	Boost = 0,
	BoostTurbo = 0,
	BoostSuper = 0,

	Horsepower = 0,
	HpNatural = 0,
	HpElectric = 0,
	HpTurbo = 0,
	HpSuper = 0,
	HpBoosted = 0,

	Torque = 0,
	TqNatural = 0,
	TqElectric = 0,
	TqTurbo = 0,
	TqSuper = 0,
	TqBoosted = 0,
}

return EngineTable
