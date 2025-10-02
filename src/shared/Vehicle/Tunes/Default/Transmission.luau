local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.Clutch = true

Tune.TransModes = { "Auto", "Semi", "Manual" }
Tune.ClutchMode = "New"
Tune.ClutchType = "Clutch"

Tune.Stall = true
Tune.ClutchRel = false

Tune.ClutchRPMMult = 1.0

Tune.TQLock = false
Tune.RPMEngage = 3500

Tune.CVTRPM = 7000
Tune.CVTMaxRatio = 6
Tune.CVTMinRatio = 1

Tune.NeutralLimit = false
Tune.NeutralRevRPM = 5000
Tune.LimitClutch = false

Tune.AutoShiftMode = "Speed"
Tune.AutoShiftType = "DCT"
Tune.AutoShiftVers = "New"
Tune.AutoUpThresh = -200
Tune.AutoDownThresh = 1400

Tune.FDMult = 1

return Tune
