local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.FSusStiffness = 1.7
Tune.FSusDamping = 1.3
Tune.FSwayBar = 2.0

Tune.FSusLength = 1.25
Tune.FPreCompress = 0
Tune.FExtensionLim = 0.4
Tune.FCompressLim = 0.8

Tune.RSusStiffness = 1.6
Tune.RSusDamping = 1.2
Tune.RSwayBar = 2.0

Tune.RSusLength = 1.15
Tune.RPreCompress = 0
Tune.RExtensionLim = 0.4
Tune.RCompressLim = 0.8

Tune.SusVisible = false
Tune.SpringsVisible = true
Tune.SusRadius = 0.2
Tune.SusThickness = 0.1
Tune.SusColor = BrickColor.new("Bright red")
Tune.SusCoilCount = 6

return Tune
