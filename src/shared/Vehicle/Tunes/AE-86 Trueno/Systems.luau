local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.ABSEnabled = true
Tune.ABSThreshold = 3
Tune.ABSGradient = 8
Tune.ABSLimit = 0

Tune.TCSEnabled = false
Tune.TCSThreshold = 10
Tune.TCSGradient = 10
Tune.TCSLimit = 4

Tune.ESCEnabled = false
Tune.ESCVector = -0.2
Tune.ESCThreshold = 0.85
Tune.ESCSpeed = 30
Tune.ESCThrottle = 60
Tune.ESCBrake = 60

return Tune
