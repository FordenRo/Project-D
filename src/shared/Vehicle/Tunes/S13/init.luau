local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

-- Misc
Tune.LoadDelay = 3 -- Delay before initializing chassis (in seconds)
Tune.AutoStart = false -- Set to false if using manual ignition plugin
Tune.AutoFlip = true -- Set to false if using manual flip plugin
Tune.Mobile = true -- Set to false if using a 3rd party mobile support method.
Tune.FlipType = "New" -- "New" uses AlignOrientation, "Old" uses BodyGyro. This really only needs to be changed for plugin compatibility.
Tune.Haptics = "Controller" -- "Controller" | "Mobile" | "Both" | "None"

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

-- Textures
Tune.EngineBlowTexture = "rbxassetid://131488880080508"
Tune.EngineBlowOpacity = 0.3
Tune.DirtTexture = "rbxassetid://129422656076701"

-- Speed Limiter
Tune.SpeedLimit = 0 -- Maximum speed limit in km/h (0 or less for no limiter)
Tune.ReverseSpeed = 0 -- Maximum reverse speed limit
Tune.SLimitGradient = 2 -- Throttle and brake interpolation
Tune.SLimitBrake = true -- If true, this will apply the brake if the car is moving too quickly.

for _, module in script:GetChildren() do
	if not module:IsA("ModuleScript") then continue end

	for k, v in require(module) do
		Tune[k] = v
	end
end

return Tune
