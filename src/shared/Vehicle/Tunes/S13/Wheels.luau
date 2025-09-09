local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.FCamber = -2.4
Tune.RCamber = -1.4
Tune.FCaster = 4
Tune.RCaster = 0
Tune.FToe = 0
Tune.RToe = 0

Tune.FWheelWeight = 22
Tune.RWheelWeight = 23

Tune.AxleSize = 1.5
Tune.AxleDensity = 0.1
Tune.CustomSuspensionDensity = 0

Tune.BrakeForce = 900
Tune.BrakeBias = 0.6
Tune.PBrakeForce = 400
Tune.PBrakeBias = 0
Tune.EBrakeForce = 500
Tune.ExitBrake = false

Tune.TorqueVector = 0.2

Tune.FDiffPower = 20
Tune.FDiffCoast = 60
Tune.FDiffPreload = 40
Tune.RDiffPower = 20
Tune.RDiffCoast = 60
Tune.RDiffPreload = 40

return Tune
