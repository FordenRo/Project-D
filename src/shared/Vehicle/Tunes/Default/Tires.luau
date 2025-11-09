local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.TireSandForce = 20

Tune.TireSmokeEffects = "All"
Tune.TireSmokeStressOffset = 3
Tune.TireSmokePollingRate = 1 / 8
Tune.TireMarkTransparencyLevels = 5
Tune.TireMarkTransparency = 0.9

Tune.TireFMaxFriction = 2.0
Tune.TireRMaxFriction = 2.0

Tune.TireDamage = 0.002
Tune.TireWearLoss = 0.5
Tune.TireDirtLoss = 0.1
Tune.TireSpeedStress = 0.03

Tune.TireFlexDebug = false

Tune.TireFPressureForce = 21
Tune.TireFThickness = 80
Tune.TireFWeight = 9

Tune.TireRPressureForce = 21
Tune.TireRThickness = 80
Tune.TireRWeight = 9

return Tune
