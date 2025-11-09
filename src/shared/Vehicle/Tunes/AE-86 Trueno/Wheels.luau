local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.FCamber = -1.0
Tune.RCamber = -1.2
Tune.FCaster = 4
Tune.RCaster = 0
Tune.FToe = 0
Tune.RToe = 0

Tune.FWheelWeight = 19
Tune.RWheelWeight = 19

Tune.AxleSize = 1.5
Tune.AxleDensity = 0.1
Tune.CustomSuspensionDensity = 0

Tune.BrakeForce = 700
Tune.BrakeBias = 0.6
Tune.PBrakeForce = 400
Tune.PBrakeBias = 0
Tune.EBrakeForce = 300
Tune.ExitBrake = false

Tune.TorqueVector = 0.2

Tune.FDiffPower = 40
Tune.FDiffCoast = 60
Tune.FDiffPreload = 40
Tune.RDiffPower = 40
Tune.RDiffCoast = 60
Tune.RDiffPreload = 40

return Tune
