local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Default = require(script.Parent.Default)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = Default :: VehicleTypes.Tune

-- Misc
Tune.Title = "Missat Zilfia S13"

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

for _, module in script:GetChildren() do
	if not module:IsA("ModuleScript") then continue end

	for k, v in require(module) :: { [string]: any } do
		Tune[k] = v
	end
end

return Tune
