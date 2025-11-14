local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.AeroDragCoeff = 0.26

Tune.AeroFDownforce = 60
Tune.AeroRDownforce = 70

return Tune
