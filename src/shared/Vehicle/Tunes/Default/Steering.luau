local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.SteeringType = "Manual"

Tune.SteerSpeed = 0.04
Tune.ReturnSpeed = 0.05
Tune.ContlrSteerSpeed = 0.08
Tune.ContlrReturnSpeed = 0.08
Tune.MSteerUsesContlr = true

Tune.SteerDecay = 220
Tune.SteerSpeedDecay = 240
Tune.MinSteer = 40
Tune.MinSteerSpeed = 50

Tune.CSEnabled = false
Tune.CSAmt = 30
Tune.CSSteerThresh = 10
Tune.CSSpeedThresh = 10

Tune.SteerSmoothing = 2
Tune.PowerSteeringType = "Old"

Tune.SteerD = 600
Tune.SteerP = 30000
Tune.SteerMaxTorque = 20000

Tune.FWSteer = "None"
Tune.RSteerSpeed = 60
Tune.RSteerD = 1000
Tune.RSteerP = 50000
Tune.RSteerMaxTorque = 20000

return Tune
