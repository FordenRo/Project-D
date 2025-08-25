local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.FlipType = "New"
Tune.Haptics = "Controller"

Tune.CGHeight = 0.1
Tune.WBVisible = false
Tune.GravComp = 35

Tune.EngineBlowTexture = "rbxassetid://131488880080508"
Tune.EngineBlowOpacity = 0.3

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
