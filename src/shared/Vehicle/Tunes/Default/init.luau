local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.CGHeight = 0.1

Tune.SpeedLimit = 0
Tune.ReverseSpeed = 0
Tune.SLimitGradient = 2
Tune.SLimitBrake = true

for _, module in script:GetChildren() do
	if not module:IsA("ModuleScript") then continue end

	for k, v in require(module) :: { [string]: any } do
		Tune[k] = v
	end
end

return Tune
