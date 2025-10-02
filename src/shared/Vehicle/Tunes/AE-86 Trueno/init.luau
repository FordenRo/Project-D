local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Default = require(script.Parent.Default)
local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = Default :: TuneType.Tune

Tune.Title = "Zoyota Sprint AE-86 Trueno"
Tune.Engine = "4A-GEU"
Tune.Drivetrain = "RWD"

Tune.FuelCapacity = 50
Tune.FuelDensity = 0.71
Tune.BSFC = 250

Tune.Weight = 940
Tune.WeightPartSize = Vector3.new(1690, 1065, 4470)
Tune.WeightDist = 53

for _, module in script:GetChildren() do
	if not module:IsA("ModuleScript") then continue end

	for k, v in require(module) :: { [string]: any } do
		Tune[k] = v
	end
end

return Tune
