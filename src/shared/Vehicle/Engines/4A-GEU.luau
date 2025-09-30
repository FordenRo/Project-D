--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EngineTune =
	require(ReplicatedStorage.Shared.Types.VehicleTypes.EngineTune)

local Engine = {} :: EngineTune.Engine

Engine.Title = "4A-GEU"
Engine.Description = ""
Engine.Engine = true

Engine.PeakTorque = 110
Engine.PeakTorqueRPM = 5200

Engine.IdleRPM = 1000
Engine.IdleTorque = 80 -- adjust
Engine.IdleTorqueCurve = 0.6

Engine.Redline = 7800 -- adjust
Engine.RedlineTorque = 90 -- adjust
Engine.RedlineTorqueCurve = 0.6

Engine.ShiftRPM = 7000
Engine.PeakRPM = 7000 -- remove this

Engine.VVLTorque = 0 -- split this
Engine.VVLRPM = 6000
Engine.VVLTime = 500
Engine.VVLCurve = 0.002

Engine.HPLimit = 0

Engine.OperatingEngineTemp = 100
Engine.EngineBurnTemp = 115
Engine.EngineMaterialFactor = 2.5
Engine.HeatGain = 4
Engine.RedlineHeatRejection = 1.25
Engine.IdleHeatRejection = 1.5

Engine.RPMDamage = 0.3
Engine.HotDamage = 2.6
Engine.RedlineDamage = 2.5
Engine.RedlineDamageCurve = 2

Engine.FanAirSpeed = 15
Engine.CoolingFactor = 0.02
Engine.EfficientCombustionRPM = 5000

Engine.Turbochargers = 0 -- make another class for this
Engine.T_Boost = 8.7
Engine.T_PeakRPM = 5020
Engine.T_IdleBoost = 1.2
Engine.T_Curve = 0.2
Engine.T_Efficiency = 5
Engine.T_Size = 9.1
Engine.T_SpoolIncrease = 0.06
Engine.T_SpoolDecrease = 0.03

Engine.Superchargers = 0 -- make another class for this
Engine.S_Boost = 8
Engine.S_PeakRPM = 5500
Engine.S_IdleBoost = 6.1
Engine.S_IdleCurve = 0.31
Engine.S_RedlineBoost = 5.6
Engine.S_RedlineCurve = 0.187
Engine.S_Efficiency = 4.34
Engine.S_Response = 0.1

Engine.IgnitionRPM = 2000
Engine.IgnitionAccel = 60
Engine.IgnitionMinRPM = 800

Engine.RevBounce = 200
Engine.RevAccel = 180
Engine.RevDecay = 30
Engine.RevDecayRPM = 60

Engine.Flywheel = 600
Engine.DumpMult = 1.0

Engine.IdleThrottle = 5
Engine.IdleDamping = 4800
Engine.IdlePadding = 800

Engine.RemoveCreep = false
Engine.InclineComp = 1.0

return Engine
