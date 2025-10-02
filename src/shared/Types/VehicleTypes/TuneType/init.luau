local Aerodynamics = require(script.Aerodynamics)
local SoundData = require(script.Parent.SoundData)
local Steering = require(script.Steering)
local Suspension = require(script.Suspension)
local Systems = require(script.Systems)
local Tires = require(script.Tires)
local Transmission = require(script.Transmission)
local Wheels = require(script.Wheels)

type Drivetrain = "FWD" | "RWD" | "AWD"
export type TransmissionMode = Transmission.TransmissionMode

--- Vehicle configuration
---
--- [*Calculator to tune the engine*](https://www.desmos.com/calculator/cqhgbm0vlt)
export type Tune =
	{
		--- Display name of the vehicle
		Title: string,
		--- Name of the engine
		Engine: string,
		--- Drivetrain configuration
		Drivetrain: Drivetrain,

		--- Fuel capacity in liters
		FuelCapacity: number,
		--- Fuel density in kg/l (0.71 for petrol 0.83 for diesel)
		FuelDensity: number,
		--- Brake Specific Fuel Consumption in g/kW*h
		BSFC: number,

		--- Total weight (in kilograms, under Earth's gravity, including wheel and suspension weight)
		Weight: number,
		--- Size of weight part in milimeters. You can find how to convert studs to milimeters inside the Units module.
		WeightPartSize: Vector3,
		--- Weight distribution (0 - on rear wheels, 100 - on front wheels, can be <0 or >100)
		WeightDist: number,
		--- Center of gravity height (studs relative to average of all wheels)
		CGHeight: number,

		--- Maximum speed limit in km/h (0 or less for no limiter)
		SpeedLimit: number,
		--- Maximum reverse speed limit
		ReverseSpeed: number,
		--- Throttle and brake interpolation
		SLimitGradient: number,
		--- If true, this will apply the brake if the car is moving too quickly.
		SLimitBrake: boolean,

		--- Sound configurations
		Sounds: { [string]: SoundData.SoundData },
		--- Tire sound configurations
		TireSounds: { [string]: SoundData.SoundData },
	}
	& Transmission.Type
	& Steering.Type
	& Wheels.Type
	& Suspension.Type
	& Tires.Type
	& Systems.Type
	& Aerodynamics.Type

return {}
