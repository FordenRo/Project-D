local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.SteeringType = "Manual"

Tune.SteerSpeed = 0.03
Tune.ReturnSpeed = 0.04
Tune.ContlrSteerSpeed = 0.2
Tune.ContlrReturnSpeed = 0.2
Tune.MSteerUsesContlr = true

Tune.SteerDecay = 260
Tune.SteerSpeedDecay = 300
Tune.MinSteer = 40
Tune.MinSteerSpeed = 50
Tune.MSteerExp = 1

Tune.CSEnabled = false
Tune.CSAmt = 30
Tune.CSSteerThresh = 10
Tune.CSSpeedThresh = 10

Tune.SteerSmoothing = 1
Tune.PowerSteeringType = "Old"

Tune.SteerD = 600
Tune.SteerP = 30000
Tune.SteerMaxTorque = 20000

Tune.FWSteer = "None"

Tune.RSteerSpeed = 60
Tune.RSteerDecay = 330

Tune.RSteerD = 1000
Tune.RSteerP = 50000
Tune.RSteerMaxTorque = 20000

return Tune
