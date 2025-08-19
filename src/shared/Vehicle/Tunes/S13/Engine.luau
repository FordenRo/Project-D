local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

-- *USE THE GRAPH BELOW TO PROPERLY TUNE THE ENGINE.*
-- https://www.desmos.com/calculator/cqhgbm0vlt

-- To import engines prior to 1.7, consult the README.

Tune.CustomEngineCalculations = false -- Enables the use of the CustomEngine module. Even if enabled, please do not remove the default engine values.

-- Naturally Aspirated Engine
Tune.Engine = true

Tune.PeakTorque = 116 -- The maximum amount of torque the engine makes in lb-ft.
Tune.PeakTorqueRPM = 4800 -- When the engine reaches PeakTorque in RPM.

Tune.IdleRPM = 1000 -- The engine's desired idle RPM. IdleDamping may change this.
Tune.IdleTorque = 90 -- How much torque the engine makes at idle.
Tune.IdleTorqueCurve = 0.5 -- The shape of the torque curve between idle and PeakRPM.

Tune.Redline = 8000 -- The maximum RPM.
Tune.RedlineTorque = 86 -- How much torque the engine makes at redline.
Tune.RedlineTorqueCurve = 0.6 -- The shape of the torque curve between PeakRPM and redline.

Tune.ShiftRPM = 7000 -- This is when the engine shifts.
Tune.PeakRPM = Tune.ShiftRPM -- This is deprecated, only used for plugin compatibility.

Tune.VVLTorque = 0 -- Variable Valve Lift (VVL, aka VTEC)'s amount of torque. Set this to 0 to turn off.
Tune.VVLRPM = 6000 -- When VVL activates in RPM.
Tune.VVLTime = 500 -- How long it takes for VVL to activate in RPM.
Tune.VVLCurve = 0.002 -- The shape of the curve during VVL activation.

Tune.HPLimit = 0 -- The horsepower limit of the engine (set to 0 to turn off).

-- Fuel
Tune.FuelCapacity = 60 -- Fuel capacity in liters
Tune.FuelDensity = 0.71 -- Fuel density in kg/l (0.71 for petrol 0.83 for diesel)
Tune.BSFC = 250 -- Brake Specific Fuel Consumption in g/kW*h

-- Temperature
Tune.OperatingEngineTemp = 100 -- The temperature at which the engine operating normally
Tune.EngineBurnTemp = 120 -- The temperature at which the engine will explode
Tune.EngineMaterialFactor = 2.5 -- The factor
Tune.HeatGain = 4 -- Raw heat gain per kW per second (unaffected by engine material) at 50% of redline
Tune.RedlineHeatRejection = 1.25 -- Heat gain multiplier at redline (excluding rpm effect). Think of this as "inefficiency" of cumbustion
Tune.IdleHeatRejection = 1.5 -- Heat gain multiplier at idle (excluding rpm effect). Think of this as "inefficiency" of cumbustion
Tune.FanAirSpeed = 15 -- Air speed (M/s) from the fan at redline (assumes mechanical linkage to fan from engine)
Tune.CoolingFactor = 0.02 -- Think of this as a size of radiator + efficiency variable
Tune.EfficientCombustionRPM = 2000 -- RPM at which the engine is most efficient

-- Damage
Tune.RPMDamage = 0.6 -- Max damage on redline per hour
Tune.RedlineDamage = 0.06 -- Damage at 1000 RPM beyond the redline per second
Tune.RedlineDamageCurve = 2.4 -- The shape of the redline damage curve

-- Electric Engine
Tune.Electric = false

Tune.E_Torque = 1050 -- The amount of electric torque in lb-ft.
Tune.E_TransitionRPM = 4600 -- When the torque begins decaying.

Tune.E_Redline = 20000 -- The maximum RPM of the electric motor.
Tune.E_RedlineTorque = 205 -- How much torque is made at the maximum RPM.

Tune.E_Curve = 0.84 -- The shape of the curve between TransitionRPM and the redline.

-- Turbocharger
Tune.Turbochargers = 0 -- Number of turbochargers in the engine, set to 0 for no turbochargers

Tune.T_Boost = 8.7 -- The maximum amount of boost of one turbocharger in PSI.
Tune.T_PeakRPM = 5020 -- When the turbo reaches maximum boost.

Tune.T_IdleBoost = 1.2 -- How much boost is made at idle.
Tune.T_Curve = 0.2 -- The shape of the boost curve between idle and PeakRPM.

Tune.T_Efficiency = 5 -- How much torque is made with 1 PSI.

Tune.T_Size = 9.1 -- Turbo size, larger = less boost from horsepower
Tune.T_SpoolIncrease = 0.06 -- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)
Tune.T_SpoolDecrease = 0.03 -- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)

-- Supercharger
Tune.Superchargers = 0 -- Number of superchargers in the engine, Set to 0 for no superchargers

Tune.S_Boost = 8 -- The maximum amount of boost of one supercharger in PSI.
Tune.S_PeakRPM = 5500 -- When the supercharger reaches its maximum boost.

Tune.S_IdleBoost = 6.1 -- The amount of boost at idle.
Tune.S_IdleCurve = 0.31 -- The shape of the boost curve between idle and PeakRPM.

Tune.S_RedlineBoost = 5.6 -- The amount of boost at redline.
Tune.S_RedlineCurve = 0.187 -- The shape of the boost curve between PeakRPM and redline.

Tune.S_Efficiency = 4.34 -- How much torque is made with 1 PSI.

Tune.S_Response = 0.1 -- Throttle response of the supercharger. (Higher = more responsive, ranges from 0 to 1)

-- Ignition
Tune.IgnitionRPM = 2000 -- This is how high the engine revs for the ignition.
Tune.IgnitionAccel = 60 -- The acceleration of the RPM while starting the car.
Tune.IgnitionMinRPM = 800 -- The minimum RPM required to start the car.

-- Throttle and brake input
Tune.ThrotAccel = 0.1 -- Throttle acceleration, applied per tick (recommended values between 0.1 to 0.3)
Tune.ThrotDecel = 0.1 -- Throttle deceleration, applied per tick (recommended values between 0.05 to 0.1)
Tune.BrakeAccel = 0.1 -- Brake acceleration, applied per tick
Tune.BrakeDecel = 0.1 -- Brake deceleration, applied per tick

-- Engine speed
Tune.RevBounce = 200 -- RPM kickback from redline
Tune.OverRev = true -- Set to true to allow the RPM to go above redline

Tune.RevAccel = 180 -- RPM acceleration when clutch is on (this should be higher than RevDecay and RevDecayRPM)
Tune.RevDecay = 30 -- RPM decay when clutch is on
Tune.RevDecayRPM = 60 -- RPM decay from engine speed

Tune.Flywheel = 600 -- Flywheel weight (higher = faster response, lower = more stable RPM)
Tune.DumpMult = 1.0 -- Flywheel energy multiplier when dumping the clutch (keep at 1.0 for the best result).

Tune.IdleThrottle = 5 -- Percent throttle with no input. (in percent)
Tune.IdleDamping = 4800 -- Damping of idle in RPM. This will change that actual idle RPM at higher values.
Tune.IdlePadding = 800 -- Added on top of IdleRPM to account for IdleDamping
-- Changed (default true)
Tune.RemoveCreep = false -- Tries to remove the natural creep of the chassis by applying clutch if there is no input throttle and if the RPM is below idle.

Tune.InclineComp = 1.0 -- Torque compensation multiplier for inclines (applies gradient from 0-90 degrees)

--[[Drivetrain]]
Tune.Config = "RWD" -- "FWD" , "RWD" , "AWD"
Tune.TorqueVector = 0.2 -- AWD ONLY, "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.

-- Options for a limited slip differential (LuaInt)
-- *You can set all of these values to 0 to achieve an open differential.
Tune.FDiffPower = 20 -- 0 - 100				Higher values yield more wheel lock-up under throttle, more stability (Front wheels, only if driven)
Tune.FDiffCoast = 60 -- 0 - 100				Higher values yield more wheel lock-up when off throttle, more stability (Front wheels, only if driven)
Tune.FDiffPreload = 40 -- 0 - 100				Higher values will make the wheels generally lock up faster in any environment (Front wheels, only if driven)
Tune.RDiffPower = 20 -- 0 - 100				(Rear wheels, only if driven)
Tune.RDiffCoast = 60 -- 0 - 100				(Rear wheels, only if driven)
Tune.RDiffPreload = 40 -- 0 - 100				(Rear wheels, only if driven)

return Tune
