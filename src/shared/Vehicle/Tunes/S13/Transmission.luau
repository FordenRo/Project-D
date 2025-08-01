local Types = require(script.Parent.Parent.Parent.Types)

local Tune = {} :: Types.Tune

Tune.Clutch = true -- Implements a realistic clutch, change to "false" for the chassis to act like AC6.81T.

Tune.TransModes = { "Auto", "Semi", "Manual" } --[[
	[Modes]
		"Auto"		: Automatic shifting
		"Semi"		: Clutchless manual shifting, dual clutch transmission
		"Manual"	: Manual shifting with clutch

		>Include within brackets
			eg: {"Semi"} or {"Auto", "Manual"}
	>First mode is default mode
]]

Tune.ClutchMode = "New" --[[
	[Modes]
		"New"		: Speed controls clutch engagement			(AC6C V1.2)
		"Old"		: Speed and RPM control clutch engagement	(AC6C V1.1)
]]

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
Tune.FinalDrive = 4.38
Tune.Ratios = {
	--[[Park]]
	--0			, --"0" enables the parking gear, "--0" disables.
	--[[Reverse]]
	3.2,
	--[[Neutral]]
	0,
	--[[ 1 ]]
	3.6,
	--[[ 2 ]]
	2,
	--[[ 3 ]]
	1.3,
	--[[ 4 ]]
	1,
	--[[ 5 ]]
	0.82,
}

Tune.FDMult = 1 -- Ratio multiplier (keep this at 1 if car is not struggling with torque)

return Tune
