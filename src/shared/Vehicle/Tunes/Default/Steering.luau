local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

-- Front wheel steering
-- Changed (default Auto)
Tune.SteeringType = "Manual" -- This can be "Auto" or "Manual".

-- Steer speed tuning
Tune.SteerSpeed = 0.03 -- Steering increment per tick (in degrees)
Tune.ReturnSpeed = 0.04 -- Steering increment per tick (in degrees)
Tune.ContlrSteerSpeed = 0.2 -- Controller version of steer speed (0 or less to be the same as SteerSpeed)
Tune.ContlrReturnSpeed = 0.2 -- Controller version of return speed (0 or less to be the same as ReturnSpeed)
Tune.MSteerUsesContlr = true -- Set to true if you want mouse steering to use controller settings.

-- Steer Decay
Tune.SteerDecay = 260 -- Speed of gradient cutoff (in km/h)
Tune.SteerSpeedDecay = 300 -- Speed of gradient cutoff of steering speed (in km/h)
Tune.MinSteer = 40 -- Minimum steering angle at max steer decay (in percent)
Tune.MinSteerSpeed = 50 -- Minimum steering speed at max decay (in percent)
Tune.MSteerExp = 1 -- Mouse steering exponential degree

-- Counter-steer
Tune.CSEnabled = true -- Enables or disables countersteering
Tune.CSAmt = 30 -- Amount of countersteering at a full perpendicular slide (in percent)
Tune.CSSteerThresh = 10 -- Threshold before countersteering activates (in percent)
Tune.CSSpeedThresh = 10 -- Speed threshold before countersteering can activate (in km/h)

-- Four Wheel Steering
Tune.FWSteer = "None" -- Static, Speed, Both, or None
Tune.RSteerSpeed = 60 -- Speed at which 4WS fully activates (Speed), deactivates (Static), or transition begins (Both) (km/h)
Tune.RSteerDecay = 330 -- Speed of gradient cutoff (in km/h)

Tune.RSteerD = 1000 -- Rear Steering Damping (old only)
Tune.RSteerP = 50000 -- Rear Steering Aggressiveness (old only)
Tune.RSteerMaxTorque = 20000 -- Rear Steering Force (old only)

-- Steering aggressiveness
Tune.SteerSmoothing = 1 -- The lower, the smoother the steering will arrive at max angle.
Tune.PowerSteeringType = "New" -- "New" uses AlignOrientation. This may cause problems.
-- "Old" uses BodyGyro.
Tune.SteerD = 1000 -- Steering Damping (old only)
Tune.SteerP = 20000 -- Steering Aggressiveness (old only)
Tune.SteerMaxTorque = 20000 -- Steering Force (old only)

return Tune
