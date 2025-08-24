local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

Tune.SuspensionEnabled = true

Tune.FSusStiffness = 2.7
Tune.FSusDamping = 1.7
Tune.FSwayBar = 2.2

Tune.FSusLength = 1.25
Tune.FPreCompress = 0.2
Tune.FExtensionLim = 0.4
Tune.FCompressLim = 0.2

Tune.RSusStiffness = 2.8
Tune.RSusDamping = 1.5
Tune.RSwayBar = 2.2

Tune.RSusLength = 1.15
Tune.RPreCompress = 0.2
Tune.RExtensionLim = 0.4
Tune.RCompressLim = 0.2

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
