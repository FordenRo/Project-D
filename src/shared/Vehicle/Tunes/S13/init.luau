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
Tune.Weight = 1130 -- Total weight (in kilograms, under Earth's gravity, including wheel and suspension weight)
Tune.WeightBSize =
	{ -- Size of weight brick in milimeters. You can find how to convert studs to milimeters inside the Units module.
		--[[Width]]
		1690,
		--[[Height]]
		1065,
		--[[Length]]
		4470,
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

-- Speed Limiter
Tune.SpeedLimit = 0 -- Maximum speed limit in km/h (0 or less for no limiter)
Tune.ReverseSpeed = 0 -- Maximum reverse speed limit
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
Tune.BrakeForce = 1600 -- Total brake force in kgf
Tune.BrakeBias = 0.65 -- Brake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
Tune.PBrakeForce = 700 -- Handbrake force in kgf
Tune.PBrakeBias = 0 -- Handbrake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
Tune.EBrakeForce = 500 -- Engine braking force at redline in kgf

for _, module in script:GetChildren() do
	if not module:IsA("ModuleScript") then continue end

	for k, v in require(module) do
		Tune[k] = v
	end
end

return Tune
