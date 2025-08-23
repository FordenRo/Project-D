local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.Engine = true

Tune.PeakTorque = 116
Tune.PeakTorqueRPM = 4800

Tune.IdleRPM = 1000
Tune.IdleTorque = 90
Tune.IdleTorqueCurve = 0.5

Tune.Redline = 8000
Tune.RedlineTorque = 86
Tune.RedlineTorqueCurve = 0.6

Tune.ShiftRPM = 7000
Tune.PeakRPM = Tune.ShiftRPM

Tune.VVLTorque = 0
Tune.VVLRPM = 6000
Tune.VVLTime = 500
Tune.VVLCurve = 0.002

Tune.HPLimit = 0

Tune.FuelCapacity = 60
Tune.FuelDensity = 0.71
Tune.BSFC = 250

Tune.OperatingEngineTemp = 100
Tune.EngineBurnTemp = 120
Tune.EngineMaterialFactor = 2.5
Tune.HeatGain = 4
Tune.RedlineHeatRejection = 1.25
Tune.IdleHeatRejection = 1.5
Tune.FanAirSpeed = 15
Tune.CoolingFactor = 0.02
Tune.EfficientCombustionRPM = 2000

Tune.RPMDamage = 0.6
Tune.HotDamage = 2.6
Tune.RedlineDamage = 0.06
Tune.RedlineDamageCurve = 2.4

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

Tune.RevBounce = 200

Tune.RevAccel = 180
Tune.RevDecay = 30
Tune.RevDecayRPM = 60

Tune.Flywheel = 600
Tune.DumpMult = 1.0

Tune.IdleThrottle = 5
Tune.IdleDamping = 4800
Tune.IdlePadding = 800

Tune.Config = "RWD"
Tune.TorqueVector = 0.2

Tune.FDiffPower = 20
Tune.FDiffCoast = 60
Tune.FDiffPreload = 40
Tune.RDiffPower = 20
Tune.RDiffCoast = 60
Tune.RDiffPreload = 40

return Tune
