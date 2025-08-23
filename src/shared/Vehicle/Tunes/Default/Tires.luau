local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.TireDirtBumps = 70
Tune.TireSandForce = 20

Tune.TireSmokeEffects = "All"
Tune.TireSmokeStressOffset = 3
Tune.TireSmokePollingRate = 1 / 8
Tune.TireMarkTransparencyLevels = 5
Tune.TireMarkTransparency = 0.9

Tune.TireFMinTemp = 8
Tune.TireFMaxTemp = 100
Tune.TireFMaxFriction = 1.4
Tune.TireFColdStats = { 0.38, 11.7, 0.32 }
Tune.TireFHotStats = { 0.96, 18.3, 1.05 }
Tune.TireFDirtLoss = 0.1
Tune.TireFHeating = 0.012
Tune.TireFCooling = 0
Tune.TireFSpeedStress = 0.04

Tune.TireRMinTemp = 8
Tune.TireRMaxTemp = 100
Tune.TireRMaxFriction = 1.4
Tune.TireRColdStats = { 0.38, 11.7, 0.32 }
Tune.TireRHotStats = { 0.96, 18.3, 1.05 }
Tune.TireRDirtLoss = 0.1
Tune.TireRHeating = 0.012
Tune.TireRCooling = 0
Tune.TireRSpeedStress = 0.04

Tune.TireFlexDebug = false

Tune.TireFPressureForce = 17
Tune.TireFThickness = 50
Tune.TireFWeight = 9

Tune.TireRPressureForce = 17
Tune.TireRThickness = 50
Tune.TireRWeight = 9

return Tune
