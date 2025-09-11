local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.AeroDragCoeff = 0.38

Tune.AeroFDownforce = 73
Tune.AeroRDownforce = 106

return Tune
