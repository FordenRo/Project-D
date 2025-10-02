local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.AeroBodyVolume = 0.1
Tune.AeroWindVolume = 0.7

Tune.AeroSlipstreamFactor = 0.7
Tune.AeroSlipstreamTime = 0.7

return Tune
