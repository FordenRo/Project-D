local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.Engine = true

Tune.HPLimit = 0

Tune.OperatingEngineTemp = 100
Tune.EngineBurnTemp = 120
Tune.EngineMaterialFactor = 2.5
Tune.HeatGain = 4
Tune.RedlineHeatRejection = 1.25
Tune.IdleHeatRejection = 1.5
Tune.FanAirSpeed = 15
Tune.CoolingFactor = 0.02
Tune.EfficientCombustionRPM = 2000

Tune.Electric = false

Tune.E_Torque = 1050
Tune.E_TransitionRPM = 4600

Tune.E_Redline = 20000
Tune.E_RedlineTorque = 205
Tune.E_Curve = 0.84

Tune.Turbochargers = 0

Tune.T_Boost = 8.7
Tune.T_PeakRPM = 5020
Tune.T_IdleBoost = 1.2
Tune.T_Curve = 0.2
Tune.T_Efficiency = 5
Tune.T_Size = 9.1
Tune.T_SpoolIncrease = 0.06
Tune.T_SpoolDecrease = 0.03

Tune.Superchargers = 0

Tune.S_Boost = 8
Tune.S_PeakRPM = 5500
Tune.S_IdleBoost = 6.1
Tune.S_IdleCurve = 0.31
Tune.S_RedlineBoost = 5.6
Tune.S_RedlineCurve = 0.187
Tune.S_Efficiency = 4.34
Tune.S_Response = 0.1

Tune.IgnitionRPM = 2000
Tune.IgnitionAccel = 60
Tune.IgnitionMinRPM = 800

Tune.ThrotAccel = 150
Tune.ThrotDecel = 100
Tune.BrakeAccel = 300
Tune.BrakeDecel = 200
Tune.ClutchAccel = 100
Tune.ClutchDecel = 300

Tune.RevBounce = 200
Tune.RevAccel = 180
Tune.RevDecay = 40
Tune.RevDecayRPM = 60
Tune.OverRev = true

Tune.Flywheel = 600
Tune.DumpMult = 1.0

Tune.IdleThrottle = 5
Tune.IdleDamping = 4800
Tune.IdlePadding = 800
Tune.RemoveCreep = false

Tune.InclineComp = 1.0

Tune.FDiffPower = 20
Tune.FDiffCoast = 60
Tune.FDiffPreload = 40
Tune.RDiffPower = 20
Tune.RDiffCoast = 60
Tune.RDiffPreload = 40

return Tune
