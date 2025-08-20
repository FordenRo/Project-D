local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

-- "Auto" Steering type somewhat realistically calculates steering angle for you
Tune.SteerRatio = 15 / 1 -- Steering ratio of your steering rack, google it for your car
Tune.LockToLock = 900 / 360 -- Number of turns of the steering wheel lock to lock, google it for your car
Tune.Ackerman = 1.1 -- If you don't know what it is don't touch it, ranges from .7 to 1.2

-- "Manual" steering type allows you to manually set the angle of the wheels
Tune.SteerInner = 38 -- Inner wheel steering (in degrees)
Tune.SteerOuter = 38 -- Outer wheel steering (in degrees)

-- Four Wheel Steering
Tune.FWSteer = "None" -- Static, Speed, Both, or None
Tune.RSteerOuter = 10 -- Outer rear wheel steering angle (in degrees)
Tune.RSteerInner = 10 -- Inner rear wheel steering angle (in degrees)

return Tune
