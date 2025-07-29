local Types = require(script.Parent.Parent.Parent.Types)

local Tune = {} :: Types.Tune

-- ABS
Tune.ABSEnabled = true -- Implements the Antilock Braking System
Tune.ABSThreshold = 3 -- Slip speed allowed before ABS starts working (in km/h)
Tune.ABSGradient = 8 -- Slip speed gradient between 0 to max reduction (in km/h)
Tune.ABSLimit = 0 -- Minimum amount of torque at max reduction (in percent)

-- Traction Control Settings
Tune.TCSEnabled = false -- Implements TCS
Tune.TCSThreshold = 10 -- Slip speed allowed before TCS starts working (in km/h)
Tune.TCSGradient = 10 -- Slip speed gradient between 0 to max reduction (in km/h)
Tune.TCSLimit = 4 -- Minimum amount of torque at max reduction (in percent)

-- Electronic Stability Control Settings
Tune.ESCEnabled = false -- Implements ESC. TCS MUST ALSO BE ENABLED. This uses the same keybind as TCS.
Tune.ESCVector = -0.2 -- Force from the front to the rear for ESC. "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.
Tune.ESCThreshold = 0.85 -- Force difference in Gs before ESC starts working.
Tune.ESCSpeed = 30 -- Minimum speed before ESC can work in km/h.
Tune.ESCThrottle = 60 -- Maximum amount of throttle allowed to ESC in percent. (0 to allow no throttle)
Tune.ESCBrake = 60 -- Maximum amount of brakes allowed to ESC in percent. (0 to allow no brakes)

return Tune
