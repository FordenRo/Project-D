local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

-- Wheel Alignment
--[Values are in degrees]
Tune.FCamber = -0.6
Tune.RCamber = -0.9
Tune.FCaster = 4
Tune.RCaster = 0
Tune.FToe = 0
Tune.RToe = 0

--Unsprung Weight
Tune.FWheelWeight = 22 -- Front Wheel Weight in kg
Tune.RWheelWeight = 23 -- Rear Wheel Weight in kg

-- Axle
Tune.AxleSize = 1.5 -- Size of structural members (larger = MORE STABLE / carry more weight)
Tune.AxleDensity = 0.1 -- Density of structural members
Tune.CustomSuspensionDensity = 0 -- Density of suspension joints, only applies to custom suspension. (0 makes them massless)

-- Brakes
Tune.BrakeForce = 1600 -- Total brake force in kgf
Tune.BrakeBias = 0.65 -- Brake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
Tune.PBrakeForce = 700 -- Handbrake force in kgf
Tune.PBrakeBias = 0 -- Handbrake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
Tune.EBrakeForce = 500 -- Engine braking force at redline in kgf
Tune.ExitBrake = false -- Set to false if you don't want the car to apply the parking brake when exiting

return Tune
