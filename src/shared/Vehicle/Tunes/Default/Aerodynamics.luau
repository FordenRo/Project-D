local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.AeroBodyVolume = 0.1
Tune.AeroWindVolume = 0.7

Tune.AeroSlipstreamFactor = 0.7
Tune.AeroSlipstreamTime = 0.7

return Tune
