local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.TransModes = { "Manual" }
Tune.ClutchType = "Clutch"

Tune.ClutchEngage = 10
Tune.SpeedEngage = 40

Tune.TQLock = false
Tune.RPMEngage = 3500

Tune.CVTRPM = 7000
Tune.CVTMaxRatio = 6
Tune.CVTMinRatio = 1

Tune.AutoShiftMode = "Speed"
Tune.AutoShiftType = "DCT"
Tune.AutoUpThresh = -200
Tune.AutoDownThresh = 1400

Tune.ShiftThrot = 100

Tune.ShiftUpTime = 0.2
Tune.ShiftDnTime = 0.1

Tune.Ratios = {
	3.2,
	0,
	3.6,
	2,
	1.3,
	1,
	0.82,
}

return Tune
