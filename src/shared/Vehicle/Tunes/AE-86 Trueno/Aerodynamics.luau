local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.AeroDragCoeff = 0.38

Tune.AeroFDownforce = 73
Tune.AeroRDownforce = 106

return Tune
