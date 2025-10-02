local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)

local Tune = {} :: TuneType.Tune

Tune.SuspensionEnabled = true

Tune.FSusStiffness = 3.4
Tune.FSusDamping = 1.2
Tune.FSwayBar = 4.0

Tune.FSusLength = 1.25
Tune.FPreCompress = 0.2
Tune.FExtensionLim = 0.5
Tune.FCompressLim = 0.3

Tune.RSusStiffness = 3.4
Tune.RSusDamping = 1.2
Tune.RSwayBar = 4.0

Tune.RSusLength = 1.15
Tune.RPreCompress = 0.2
Tune.RExtensionLim = 0.5
Tune.RCompressLim = 0.3

Tune.FSusAngle = 80
Tune.FWsBoneLen = 4
Tune.FWsBoneAngle = 0
Tune.FAnchorOffset = { -0.4, -0.5, 0 }
Tune.FSpringOffset = { -0.4, 0, 0 }

Tune.RSusAngle = 80
Tune.RWsBoneLen = 4
Tune.RWsBoneAngle = 0
Tune.RAnchorOffset = { -0.4, -0.5, 0 }
Tune.RSpringOffset = { -0.4, 0, 0 }

Tune.SusVisible = false
Tune.SpringsVisible = true
Tune.SusRadius = 0.2
Tune.SusThickness = 0.1
Tune.SusColor = BrickColor.new("Bright red")
Tune.SusCoilCount = 6

return Tune
