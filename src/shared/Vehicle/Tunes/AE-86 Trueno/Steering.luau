local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.SteerRatio = 15 / 1
Tune.LockToLock = 900 / 360
Tune.Ackerman = 1.1

Tune.FWSteer = "None"
Tune.RSteerOuter = 10
Tune.RSteerInner = 10

return Tune
