local Types = require(script.Parent.Parent.Parent.Types)

local Tune = {} :: Types.Tune

-- Front wheel steering
-- Changed (default Auto)
Tune.SteeringType = "Manual" -- This can be "Auto" or "Manual".

-- "Auto" Steering type somewhat realistically calculates steering angle for you
Tune.SteerRatio = 15 / 1 -- Steering ratio of your steering rack, google it for your car
Tune.LockToLock = 900 / 360 -- Number of turns of the steering wheel lock to lock, google it for your car
Tune.Ackerman = 1.1 -- If you don't know what it is don't touch it, ranges from .7 to 1.2

-- "Manual" steering type allows you to manually set the angle of the wheels
Tune.SteerInner = 38 -- Inner wheel steering (in degrees)
Tune.SteerOuter = 38 -- Outer wheel steering (in degrees)

-- Steer speed tuning
Tune.SteerSpeed = 0.05 -- Steering increment per tick (in degrees)
Tune.ReturnSpeed = 0.1 -- Steering increment per tick (in degrees)
Tune.ContlrSteerSpeed = 0 -- Controller version of steer speed (0 or less to be the same as SteerSpeed)
Tune.ContlrReturnSpeed = 0 -- Controller version of return speed (0 or less to be the same as ReturnSpeed)
Tune.MSteerUsesContlr = true -- Set to true if you want mouse steering to use controller settings.

-- Steer Decay
Tune.SteerDecay = 240 -- Speed of gradient cutoff (in km/h)
Tune.SteerSpeedDecay = 240 -- Speed of gradient cutoff of steering speed (in km/h)
Tune.MinSteer = 15 -- Minimum steering angle at max steer decay (in percent)
Tune.MinSteerSpeed = 40 -- Minimum steering speed at max decay (in percent)
Tune.MSteerExp = 1 -- Mouse steering exponential degree

-- Counter-steer
Tune.CSEnabled = true -- Enables or disables countersteering
Tune.CSAmt = 100 -- Amount of countersteering at a full perpendicular slide (in percent)
Tune.CSSteerThresh = 20 -- Threshold before countersteering activates (in percent)
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
Tune.SteerP = 20000 -- Steering Aggressiveness (old only)
Tune.SteerMaxTorque = 20000 -- Steering Force (old only)

return Tune
