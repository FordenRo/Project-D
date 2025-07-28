local Types = require(script.Parent.Parent.Types)

local Tune = {} :: Types.Tune

-- Misc
Tune.LoadDelay = 3 -- Delay before initializing chassis (in seconds)
-- Changed (default true)
Tune.AutoStart = true -- Set to false if using manual ignition plugin
Tune.AutoFlip = true -- Set to false if using manual flip plugin
Tune.Mobile = true -- Set to false if using a 3rd party mobile support method.
Tune.FlipType = "New" -- "New" uses AlignOrientation, "Old" uses BodyGyro. This really only needs to be changed for plugin compatibility.
Tune.Haptics = "Controller" -- "Controller" | "Mobile" | "Both" | "None"

-- Wheel Alignment
--[Values are in degrees]
Tune.FCamber = -0.6
Tune.RCamber = -0.9
Tune.FCaster = 4
Tune.RCaster = 0
Tune.FToe = 0
Tune.RToe = 0

-- Weight and CG
Tune.Weight = 1379 -- Total weight (in kilograms, under Earth's gravity, including wheel and suspension weight)
Tune.WeightBSize =
	{ -- Size of weight brick in milimeters. You can find how to convert studs to milimeters inside the Units module.
		--[[Width]]
		1802,
		--[[Height]]
		1408,
		--[[Length]]
		4551,
	}
Tune.WeightDist = 50 -- Weight distribution (0 - on rear wheels, 100 - on front wheels, can be <0 or >100)
Tune.CGHeight = 0.1 -- Center of gravity height (studs relative to average of all wheels)
Tune.WBVisible = false -- Makes the weight brick visible
Tune.GravComp = 35 -- Desired gravitational force in Roblox units. (35 is the default. Set to 0 to use workspace.Gravity instead)

--Unsprung Weight
Tune.FWheelWeight = 22 -- Front Wheel Weight in kg
Tune.RWheelWeight = 23 -- Rear Wheel Weight in kg

-- Axle
Tune.AxleSize = 1.5 -- Size of structural members (larger = MORE STABLE / carry more weight)
Tune.AxleDensity = 0.1 -- Density of structural members
Tune.CustomSuspensionDensity = 0 -- Density of suspension joints, only applies to custom suspension. (0 makes them massless)

-- Suspension
Tune.SuspensionEnabled = true -- Enables suspension, true or false

-- Front Suspension
Tune.FSusStiffness = 12.3 -- Spring Force in kgf/mm. (To convert from Roblox stiffness, divide Roblox stiffness by 447.18324)
Tune.FSusDamping = 3.9 -- Spring Damping in thousands of kg/s. (To convert from Roblox damping, divide Roblox damping by 45.6)
Tune.FSwayBar = 3.2 -- Sway Bar Force in kgf/mm (more = less roll)

Tune.FSusLength = 1.2 -- Base spring height (in studs)
Tune.FPreCompress = 0.2 -- Adds to base spring height (in studs)
Tune.FExtensionLim = 0.5 -- Max Extension Travel (in studs)
Tune.FCompressLim = 0.3 -- Max Compression Travel (in studs)

--Rear Suspension
Tune.RSusStiffness = 13.2 -- Spring Force in kgf/mm. (To convert from Roblox stiffness, divide Roblox stiffness by 447.18324)
Tune.RSusDamping = 4.4 -- Spring Damping in thousands of kg/s. (To convert from Roblox damping, divide Roblox damping by 45.6)
Tune.RSwayBar = 1.1 -- Sway Bar Force in kgf/mm (more = less roll)

Tune.RSusLength = 1.2 -- Base spring height (in studs)
Tune.RPreCompress = 0.2 -- Adds to base spring height (in studs)
Tune.RExtensionLim = 0.5 -- Max Extension Travel (in studs)
Tune.RCompressLim = 0.3 -- Max Compression Travel (in studs)

--Old Suspension Settings, applies if there is no SuspensionGeometry for the respective wheel
Tune.FSusAngle = 80 -- Spring Angle (degrees from horizontal)
Tune.FWsBoneLen = 4 -- Wishbone Length
Tune.FWsBoneAngle = 0 -- Wishbone angle (degrees from horizontal)
Tune.FAnchorOffset = { -- Suspension anchor point offset (relative to center of wheel)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	-0.5, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward
Tune.FSpringOffset = { -- Suspension anchor point offset (relative to ABOVE anchor offset) (Avxnturador)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	0, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward

Tune.RSusAngle = 80 -- Spring Angle (degrees from horizontal)
Tune.RWsBoneLen = 4 -- Wishbone Length
Tune.RWsBoneAngle = 0 -- Wishbone angle (degrees from horizontal)
Tune.RAnchorOffset = { -- Suspension anchor point offset (relative to center of wheel)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	-0.5, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward
Tune.RSpringOffset = { -- Suspension anchor point offset (relative to ABOVE anchor offset) (Avxnturador)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	0, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward

--[[Tires]]
Tune.TireDirtBumps = 100 -- Aggresiveness of artificial bumps in dirt-, sand-, and snow-type surfaces (0 for none)
Tune.TireSandForce = 20 -- Sand force, more means going over sand slows down the car more

--[[Aesthetics]]
Tune.TireSmokeEffects = "All" -- Turns smoke effects on or off, "All" for viewable by everyone, "Local" for only viewable by you, "Off" for none.
Tune.TireSmokeStressOffset = 5 -- Offsets the stress required to activate smoke-related effects (in percent, higher means less smoke).
Tune.TireSmokePollingRate = 1 / 8 -- "All" setting only. This changes how often the server gets data to run the smoke effects. Higher = more delay.
Tune.TireMarkTransparencyLevels = 5 -- How many levels of transparency there are (0 for no marks)
Tune.TireMarkTransparency = 0.95 -- The transparency of the tire marks

--[[Friction]]
Tune.TireFMinTemp = 8 -- Minimum temperature of the front tires in celcius
Tune.TireFMaxTemp = 100 -- Maximum temperature of the front tires in celcius
Tune.TireFMaxFriction = 1.7 -- Maximum friction of the front tires
Tune.TireFColdStats = { 0.38, 11.7, 0.32 } -- Loss, Sharpness, Offset
Tune.TireFHotStats = { 0.96, 18.3, 1.05 } -- Loss, Sharpness, Offset
Tune.TireFDirtLoss = 0.1 -- Friction loss from dirty tires
Tune.TireFDirtFadeRate = 0.001 -- The rate that dirt fades
Tune.TireFHeating = 0.012 -- Heat gain from maximum slippage
Tune.TireFCooling = 0.001 -- Heat loss at no slippage
Tune.TireFSpeedStress = 0.04 -- Stress generated at 100 km/h

Tune.TireRMinTemp = 8 -- Minimum temperature of the rear tires in celcius
Tune.TireRMaxTemp = 100 -- Maximum temperature of the rear tires in celcius
Tune.TireRMaxFriction = 2.0 -- Maximum friction of the rear tires
Tune.TireRColdStats = { 0.38, 11.7, 0.32 } -- Loss, Sharpness, Offset
Tune.TireRHotStats = { 0.96, 18.3, 1.05 } -- Loss, Sharpness, Offset
Tune.TireRDirtLoss = 0.1 -- Friction loss from dirty tires
Tune.TireRDirtFadeRate = 0.001 -- The rate that dirt fades
Tune.TireRHeating = 0.012 -- Heat gain from maximum slippage
Tune.TireRCooling = 0.001 -- Heat loss at no slippage
Tune.TireRSpeedStress = 0.04 -- Stress generated at 100 km/h

--[[Tire Flex]]
Tune.TireFlexDebug = false -- Debug tire flex

Tune.TireFPressureForce = 17 -- Pressure force (no unit)
Tune.TireFThickness = 50 -- Tire sidewall thickness in milimeters
Tune.TireFWeight = 9 -- Tire weight in kg

Tune.TireRPressureForce = 17 -- Pressure force (no unit)
Tune.TireRThickness = 50 -- Tire sidewall thickness in milimeters
Tune.TireRWeight = 9 -- Tire weight in kg

--Aesthetics
Tune.SusVisible = false -- Suspension Visible
Tune.SpringsVisible = true -- Springs Visible
Tune.SusRadius = 0.2 -- Spring Coil Radius
Tune.SusThickness = 0.1 -- Spring Coil Thickness
Tune.SusColor = BrickColor.new("Bright red") -- Spring Color [BrickColor]
Tune.SusCoilCount = 6 -- Spring Coil Count

--[[Steering]]
-- Front wheel steering
-- Changed (default Auto)
Tune.SteeringType = "Manual" -- This can be "Auto" or "Manual".

-- "Auto" Steering type somewhat realistically calculates steering angle for you
Tune.SteerRatio = 15 / 1 -- Steering ratio of your steering rack, google it for your car
Tune.LockToLock = 2.6 -- Number of turns of the steering wheel lock to lock, google it for your car
Tune.Ackerman = 1.1 -- If you don't know what it is don't touch it, ranges from .7 to 1.2

-- "Manual" steering type allows you to manually set the angle of the wheels
Tune.SteerInner = 39 -- Inner wheel steering (in degrees)
Tune.SteerOuter = 36 -- Outer wheel steering (in degrees)

-- Steer speed tuning
Tune.SteerSpeed = 0.05 -- Steering increment per tick (in degrees)
Tune.ReturnSpeed = 0.1 -- Steering increment per tick (in degrees)
Tune.ContlrSteerSpeed = 0 -- Controller version of steer speed (0 or less to be the same as SteerSpeed)
Tune.ContlrReturnSpeed = 0 -- Controller version of return speed (0 or less to be the same as ReturnSpeed)
Tune.MSteerUsesContlr = true -- Set to true if you want mouse steering to use controller settings.

-- Steer Decay
Tune.SteerDecay = 260 -- Speed of gradient cutoff (in km/h)
Tune.SteerSpeedDecay = 260 -- Speed of gradient cutoff of steering speed (in km/h)
Tune.MinSteer = 25 -- Minimum steering angle at max steer decay (in percent)
Tune.MinSteerSpeed = 60 -- Minimum steering speed at max decay (in percent)
Tune.MSteerExp = 1 -- Mouse steering exponential degree

-- Counter-steer
Tune.CSEnabled = true -- Enables or disables countersteering
Tune.CSAmt = 100 -- Amount of countersteering at a full perpendicular slide (in percent)
Tune.CSSteerThresh = 10 -- Threshold before countersteering activates (in percent)
Tune.CSSpeedThresh = 10 -- Speed threshold before countersteering can activate (in km/h)

-- Four Wheel Steering
Tune.FWSteer = "None" -- Static, Speed, Both, or None
Tune.RSteerOuter = 10 -- Outer rear wheel steering angle (in degrees)
Tune.RSteerInner = 10 -- Inner rear wheel steering angle (in degrees)
Tune.RSteerSpeed = 60 -- Speed at which 4WS fully activates (Speed), deactivates (Static), or transition begins (Both) (km/h)
Tune.RSteerDecay = 330 -- Speed of gradient cutoff (in km/h)

Tune.RSteerD = 1000 -- Rear Steering Damping (old only)
Tune.RSteerP = 50000 -- Rear Steering Aggressiveness (old only)
Tune.RSteerMaxTorque = 20000 -- Rear Steering Force (old only)

-- Steering aggressiveness
Tune.SteerSmoothing = 3 -- The lower, the smoother the steering will arrive at max angle.
Tune.PowerSteeringType = "Old" -- "New" uses AlignOrientation. This may cause problems.
-- "Old" uses BodyGyro.
Tune.SteerD = 1000 -- Steering Damping (old only)
Tune.SteerP = 50000 -- Steering Aggressiveness (old only)
Tune.SteerMaxTorque = 20000 -- Steering Force (old only)

--[[Engine (Detomiks)]]

-- *USE THE GRAPH BELOW TO PROPERLY TUNE THE ENGINE.*
-- https://www.desmos.com/calculator/cqhgbm0vlt

-- To import engines prior to 1.7, consult the README.

Tune.CustomEngineCalculations = false -- Enables the use of the CustomEngine module. Even if enabled, please do not remove the default engine values.

-- Naturally Aspirated Engine
Tune.Engine = true

Tune.PeakTorque = 209 -- The maximum amount of torque the engine makes in lb-ft.
Tune.PeakTorqueRPM = 4480 -- When the engine reaches PeakTorque in RPM.

Tune.IdleRPM = 1000 -- The engine's desired idle RPM. IdleDamping may change this.
Tune.IdleTorque = 148 -- How much torque the engine makes at idle.
Tune.IdleTorqueCurve = 0.5 -- The shape of the torque curve between idle and PeakRPM.

Tune.Redline = 8400 -- The maximum RPM.
Tune.RedlineTorque = 142 -- How much torque the engine makes at redline.
Tune.RedlineTorqueCurve = 0.6 -- The shape of the torque curve between PeakRPM and redline.

Tune.ShiftRPM = 7700 -- This is when the engine shifts.
Tune.PeakRPM = Tune.ShiftRPM -- This is deprecated, only used for plugin compatibility.

Tune.VVLTorque = 22 -- Variable Valve Lift (VVL, aka VTEC)'s amount of torque. Set this to 0 to turn off.
Tune.VVLRPM = 6000 -- When VVL activates in RPM.
Tune.VVLTime = 500 -- How long it takes for VVL to activate in RPM.
Tune.VVLCurve = 0.002 -- The shape of the curve during VVL activation.

Tune.HPLimit = 0 -- The horsepower limit of the engine (set to 0 to turn off).

-- Fuel
Tune.FuelCapacity = 70 -- Fuel capacity in liters
Tune.FuelDensity = 0.71 -- Fuel density in kg/l (0.71 for petrol 0.83 for diesel)
Tune.BSFC = 250 -- Brake Specific Fuel Consumption in g/kW*h

-- Temperatune
Tune.OperatingEngineTemp = 100 -- The temperature at which the engine operating normally
Tune.EngineBurnTemp = 120 -- The temperature at which the engine will explode
Tune.EngineMaterialFactor = 2.5 -- The factor
Tune.HeatGain = 4 -- Raw heat gain per kW per second (unaffected by engine material) at 50% of redline
Tune.RedlineHeatRejection = 1.25 -- Heat gain multiplier at redline (excluding rpm effect). Think of this as "inefficiency" of cumbustion
Tune.IdleHeatRejection = 1.5 -- Heat gain multiplier at idle (excluding rpm effect). Think of this as "inefficiency" of cumbustion
Tune.FanAirSpeed = 15 -- Air speed (M/s) from the fan at redline (assumes mechanical linkage to fan from engine)
Tune.CoolingFactor = 0.02 -- Think of this as a size of radiator + efficiency variable
Tune.EfficientCombustionRPM = 2000 -- RPM at which the engine is most efficient

-- Electric Engine
Tune.Electric = false

Tune.E_Torque = 1050 -- The amount of electric torque in lb-ft.
Tune.E_TransitionRPM = 4600 -- When the torque begins decaying.

Tune.E_Redline = 20000 -- The maximum RPM of the electric motor.
Tune.E_RedlineTorque = 205 -- How much torque is made at the maximum RPM.

Tune.E_Curve = 0.84 -- The shape of the curve between TransitionRPM and the redline.

-- Turbocharger
Tune.Turbochargers = 2 -- Number of turbochargers in the engine, set to 0 for no turbochargers

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
Tune.IgnitionRPM = 1200 -- This is how high the engine revs for the ignition.
Tune.IgnitionAccel = 30 -- The acceleration of the RPM while starting the car.
Tune.IgnitionMinRPM = 800 -- The minimum RPM required to start the car.

-- Throttle and brake input
Tune.ThrotAccel = 0.05 -- Throttle acceleration, applied per tick (recommended values between 0.1 to 0.3)
Tune.ThrotDecel = 0.2 -- Throttle deceleration, applied per tick (recommended values between 0.05 to 0.1)
Tune.BrakeAccel = 0.1 -- Brake acceleration, applied per tick
Tune.BrakeDecel = 0.2 -- Brake deceleration, applied per tick

-- Engine speed
Tune.RevBounce = 200 -- RPM kickback from redline
Tune.OverRev = false -- Set to true to allow the RPM to go above redline

Tune.RevAccel = 180 -- RPM acceleration when clutch is on (this should be higher than RevDecay and RevDecayRPM)
Tune.RevDecay = 30 -- RPM decay when clutch is on
Tune.RevDecayRPM = 60 -- RPM decay from engine speed

Tune.Flywheel = 800 -- Flywheel weight (higher = faster response, lower = more stable RPM)
Tune.DumpMult = 1.0 -- Flywheel energy multiplier when dumping the clutch (keep at 1.0 for the best result).

Tune.IdleThrottle = 5 -- Percent throttle with no input. (in percent)
Tune.IdleDamping = 4800 -- Damping of idle in RPM. This will change that actual idle RPM at higher values.
Tune.IdlePadding = 800 -- Added on top of IdleRPM to account for IdleDamping
-- Changed (default true)
Tune.RemoveCreep = true -- Tries to remove the natural creep of the chassis by applying clutch if there is no input throttle and if the RPM is below idle.

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

-- Traction Control Settings
Tune.TCSEnabled = true -- Implements TCS
Tune.TCSThreshold = 10 -- Slip speed allowed before TCS starts working (in km/h)
Tune.TCSGradient = 10 -- Slip speed gradient between 0 to max reduction (in km/h)
Tune.TCSLimit = 4 -- Minimum amount of torque at max reduction (in percent)

-- Electronic Stability Control Settings
Tune.ESCEnabled = true -- Implements ESC. TCS MUST ALSO BE ENABLED. This uses the same keybind as TCS.
Tune.ESCVector = -0.2 -- Force from the front to the rear for ESC. "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.
Tune.ESCThreshold = 0.85 -- Force difference in Gs before ESC starts working.
Tune.ESCSpeed = 30 -- Minimum speed before ESC can work in km/h.
Tune.ESCThrottle = 60 -- Maximum amount of throttle allowed to ESC in percent. (0 to allow no throttle)
Tune.ESCBrake = 60 -- Maximum amount of brakes allowed to ESC in percent. (0 to allow no brakes)

--[[Transmission]]
Tune.Clutch = true -- Implements a realistic clutch, change to "false" for the chassis to act like AC6.81T.

Tune.TransModes = { "Auto", "Semi", "Manual" } --[[
	[Modes]
		"Auto"		: Automatic shifting
		"Semi"		: Clutchless manual shifting, dual clutch transmission
		"Manual"	: Manual shifting with clutch
		
		>Include within brackets
			eg: {"Semi"} or {"Auto", "Manual"}								
	>First mode is default mode													]]

Tune.ClutchMode = "New" --[[
	[Modes]
		"New"		: Speed controls clutch engagement			(AC6C V1.2)
		"Old"		: Speed and RPM control clutch engagement	(AC6C V1.1)		]]

Tune.ClutchType = "Clutch" --[[
	[Types]
		"Clutch"			: Standard clutch, recommended
		"TorqueConverter"	: Torque converter, keeps RPM up
		"CVT"				: Continously Variable Transmission
																		]]
--[[Transmission]]
--Transmission Settings
-- Changed (default true)
Tune.Stall = true -- Stalling, enables the car to stall. An ignition plugin would be necessary. Disables if Tune.Clutch is false.
-- Changed (default false)
Tune.ClutchRel = false -- If true, the driver must let off the gas before shifting to a higher gear. Recommended false for beginners.
Tune.ClutchEngage = 10 -- How fast engagement is (0 = instant, 99 = super slow)
Tune.SpeedEngage = 40 -- Speed the clutch fully engages at (Based on km/h)

--Clutch: "Old" mode
Tune.ClutchRPMMult = 1.0 -- Clutch RPM multiplier, recommended to leave at 1.0

--Torque Converter:
Tune.TQLock = false -- Torque converter starts locking at a certain RPM
Tune.RPMEngage = 3500 -- Keeps RPMs to this level until passed

--CVT:
Tune.CVTRPM = 7000 -- RPM that the CVT wants to keep at full throttle.
Tune.CVTMaxRatio = 6 -- The gear ratio that the CVT cannot go over.
Tune.CVTMinRatio = 1 -- The gear ratio that the CVT cannot go under.

--Neutral Rev Limiter (Avxnturador)
Tune.NeutralLimit = false -- Enables a different redline RPM for when the car is in neutral
Tune.NeutralRevRPM = 5000 -- The rev limiter when the car is in neutral
Tune.LimitClutch = false -- Will also limit RPMs while the clutch is pressed down

--Automatic Settings
Tune.AutoShiftMode = "Speed" --[[
	[Modes]
		"Speed"		: Shifts based on wheel speed
		"RPM"		: Shifts based on RPM										]]
Tune.AutoShiftType = "DCT" --[[
	[Types]
		"Rev"		: Clutch engages fully once RPM reached			(AC6C V1)
		"DCT"		: Clutch engages after a set time has passed	(AC6.81T)	]]
Tune.AutoShiftVers = "New" --[[
	[Versions]
		"New"		: Shift from Reverse, Neutral, and Drive		(AC6.81T)
		"Old"		: Auto shifts into R or D when stopped.			(AC6.52S2)	]]
Tune.AutoUpThresh = -200 -- Automatic upshift point 	(relative to peak RPM, positive = Over-rev)
Tune.AutoDownThresh = 1400 -- Automatic downshift point (relative to peak RPM, positive = Under-rev)

--Automatic: Revmatching
Tune.ShiftThrot = 100 -- Throttle level when shifting down to revmatch, 0 - 100%

--Automatic: DCT
Tune.ShiftUpTime = 0.2 -- Time required to shift into next gear, from a lower gear to a higher one.
Tune.ShiftDnTime = 0.1 -- Time required to shift into next gear, from a higher gear to a lower one.

--Gear Ratios
--You can tune the gears in the engine graphs by switching G_TunerType inside Desmos
Tune.FinalDrive = 3.621
Tune.Ratios = {
	--[[Park]]
	--0			, --"0" enables the parking gear, "--0" disables.
	--[[Reverse]]
	3.18,
	--[[Neutral]]
	0,
	--[[ 1 ]]
	3.927,
	--[[ 2 ]]
	2.454,
	--[[ 3 ]]
	1.785,
	--[[ 4 ]]
	1.413,
	--[[ 5 ]]
	1.101,
	--[[ 6 ]]
	0.893,
}

Tune.FDMult = 1 -- Ratio multiplier (keep this at 1 if car is not struggling with torque)

-- Speed Limiter
Tune.SpeedLimit = 0 -- Maximum speed limit in km/h (0 or less for no limiter)
Tune.ReverseSpeed = 40 -- Maximum reverse speed limit
Tune.SLimitGradient = 2 -- Throttle and brake interpolation
Tune.SLimitBrake = true -- If true, this will apply the brake if the car is moving too quickly.

--[[Brakes]]
-- Changed (default true)
Tune.ExitBrake = false -- Set to false if you don't want the car to apply the parking brake when exiting

-- ABS
Tune.ABSEnabled = true -- Implements the Antilock Braking System
Tune.ABSThreshold = 3 -- Slip speed allowed before ABS starts working (in km/h)
Tune.ABSGradient = 8 -- Slip speed gradient between 0 to max reduction (in km/h)
Tune.ABSLimit = 0 -- Minimum amount of torque at max reduction (in percent)

-- Forces
Tune.BrakeForce = 2000 -- Total brake force in kgf
Tune.BrakeBias = 0.65 -- Brake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
Tune.PBrakeForce = 1000 -- Handbrake force in kgf
Tune.PBrakeBias = 0 -- Handbrake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
Tune.EBrakeForce = 500 -- Engine braking force at redline in kgf

-- Sounds
Tune.Sounds = {
	Blowoff = {
		Type = "Blowoff",
		SoundId = "rbxassetid://3568930062",
		Parent = "Engine",
		VolumeIncrease = 0.01,
		BasePlaybackSpeed = 0.7,
		PlaybackSpeedIncrease = 0.05,
		Sensitivity = -0.2,
	},
	Ignition = {
		Type = "Ignition",
		SoundId = "rbxassetid://169394147",
		Parent = "Engine",
		Volume = 2,
		Pitch = 1,
		MaxPitch = 1.1,
	},
	Engine = {
		Type = "Engine",
		SoundId = "rbxassetid://6002661882",
		Parent = "Engine",
		BaseVolume = 0,
		BasePlaybackSpeed = 0,
		RangeStart = 0,
		RangeEnd = 40000,
		RedlinePlaybackSpeed = 0.8,
		RedlineVolume = 0.2,
		ThrottleVolume = 0.2,
		TransitionEnd = 100,
		TransitionStart = 100,
	},
	Turbo = {
		Type = "Turbo",
		SoundId = "rbxassetid://240323039",
		Parent = "Engine",
		BasePlaybackSpeed = 1,
		PlaybackSpeedIncrease = 0.05,
		VolumeIncrease = 0.01,
	},
	Transmission = {
		Type = "Transmission",
		BaseVolume = 0.2,
		ClutchVolume = 0.1,
		Gears = { 1, 2, 3, 4, 5, 6 },
		OffVolume = 0.1,
		Parent = "Transmission",
		SoundId = "rbxassetid://406864489",
		ThrottleVolume = 0.1,
		VariablePlaybackSpeed = 1.3,
		VariableVolume = 0.5,
	},
	Fan = {
		Type = "Fan",
		SoundId = "rbxassetid://11773719101",
		Parent = "Engine",
		BaseVolume = 1,
		BasePlaybackSpeed = 1,
	},
}

return Tune
