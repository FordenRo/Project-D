local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.SteerRatio = 15 / 1
Tune.LockToLock = 900 / 360
Tune.Ackerman = 1.1

Tune.SteerInner = 38
Tune.SteerOuter = 38

Tune.FWSteer = "None"
Tune.RSteerOuter = 10
Tune.RSteerInner = 10

return Tune
