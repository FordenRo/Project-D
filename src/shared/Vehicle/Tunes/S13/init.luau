local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Default = require(script.Parent.Default)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = Default :: VehicleTypes.Tune

Tune.Title = "Missat Zilfia S13"
Tune.Engine = "4A-GEU"
Tune.Drivetrain = "RWD"

Tune.FuelCapacity = 50
Tune.FuelDensity = 0.71
Tune.BSFC = 250

Tune.Weight = 1130
Tune.WeightPartSize = Vector3.new(1690, 1065, 4470)
Tune.WeightDist = 50

for _, module in script:GetChildren() do
	if not module:IsA("ModuleScript") then continue end

	for k, v in require(module) :: { [string]: any } do
		Tune[k] = v
	end
end

return Tune
