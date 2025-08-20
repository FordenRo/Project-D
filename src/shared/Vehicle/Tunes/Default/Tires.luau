local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Tune = {} :: VehicleTypes.Tune

--[[Tires]]
Tune.TireDirtBumps = 70 -- Aggresiveness of artificial bumps in dirt-, sand-, and snow-type surfaces (0 for none)
Tune.TireSandForce = 20 -- Sand force, more means going over sand slows down the car more

--[[Aesthetics]]
Tune.TireSmokeEffects = "All" -- Turns smoke effects on or off, "All" for viewable by everyone, "Local" for only viewable by you, "Off" for none.
Tune.TireSmokeStressOffset = 3 -- Offsets the stress required to activate smoke-related effects (in percent, higher means less smoke).
Tune.TireSmokePollingRate = 1 / 8 -- "All" setting only. This changes how often the server gets data to run the smoke effects. Higher = more delay.
Tune.TireMarkTransparencyLevels = 5 -- How many levels of transparency there are (0 for no marks)
Tune.TireMarkTransparency = 0.9 -- The transparency of the tire marks

--[[Friction]]
Tune.TireFMinTemp = 8 -- Minimum temperature of the front tires in celcius
Tune.TireFMaxTemp = 100 -- Maximum temperature of the front tires in celcius
Tune.TireFMaxFriction = 1.4 -- Maximum friction of the front tires
Tune.TireFColdStats = { 0.38, 11.7, 0.32 } -- Loss, Sharpness, Offset
Tune.TireFHotStats = { 0.96, 18.3, 1.05 } -- Loss, Sharpness, Offset
Tune.TireFDirtLoss = 0.1 -- Friction loss from dirty tires
Tune.TireFHeating = 0.012 -- Heat gain from maximum slippage
Tune.TireFCooling = 0 -- Heat loss at no slippage
Tune.TireFSpeedStress = 0.04 -- Stress generated at 100 km/h

Tune.TireRMinTemp = 8 -- Minimum temperature of the rear tires in celcius
Tune.TireRMaxTemp = 100 -- Maximum temperature of the rear tires in celcius
Tune.TireRMaxFriction = 1.4 -- Maximum friction of the rear tires
Tune.TireRColdStats = { 0.38, 11.7, 0.32 } -- Loss, Sharpness, Offset
Tune.TireRHotStats = { 0.96, 18.3, 1.05 } -- Loss, Sharpness, Offset
Tune.TireRDirtLoss = 0.1 -- Friction loss from dirty tires
Tune.TireRHeating = 0.012 -- Heat gain from maximum slippage
Tune.TireRCooling = 0 -- Heat loss at no slippage
Tune.TireRSpeedStress = 0.04 -- Stress generated at 100 km/h

--[[Tire Flex]]
Tune.TireFlexDebug = false -- Debug tire flex

Tune.TireFPressureForce = 17 -- Pressure force (no unit)
Tune.TireFThickness = 50 -- Tire sidewall thickness in milimeters
Tune.TireFWeight = 9 -- Tire weight in kg

Tune.TireRPressureForce = 17 -- Pressure force (no unit)
Tune.TireRThickness = 50 -- Tire sidewall thickness in milimeters
Tune.TireRWeight = 9 -- Tire weight in kg

return Tune
