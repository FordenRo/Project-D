local Types = require(script.Parent.Parent.Parent.Types)

local Tune = {} :: Types.Tune

-- Suspension
Tune.SuspensionEnabled = true -- Enables suspension, true or false

-- Front Suspension
Tune.FSusStiffness = 2.4 -- Spring Force in kgf/mm. (To convert from Roblox stiffness, divide Roblox stiffness by 447.18324)
Tune.FSusDamping = 1.2 -- Spring Damping in thousands of kg/s. (To convert from Roblox damping, divide Roblox damping by 45.6)
Tune.FSwayBar = 2.4 -- Sway Bar Force in kgf/mm (more = less roll)

Tune.FSusLength = 1 -- Base spring height (in studs)
Tune.FPreCompress = 0.3 -- Adds to base spring height (in studs)
Tune.FExtensionLim = 0.3 -- Max Extension Travel (in studs)
Tune.FCompressLim = 0.6 -- Max Compression Travel (in studs)

--Rear Suspension
Tune.RSusStiffness = 2.3 -- Spring Force in kgf/mm. (To convert from Roblox stiffness, divide Roblox stiffness by 447.18324)
Tune.RSusDamping = 1.1 -- Spring Damping in thousands of kg/s. (To convert from Roblox damping, divide Roblox damping by 45.6)
Tune.RSwayBar = 2.4 -- Sway Bar Force in kgf/mm (more = less roll)

Tune.RSusLength = 1 -- Base spring height (in studs)
Tune.RPreCompress = 0.3 -- Adds to base spring height (in studs)
Tune.RExtensionLim = 0.3 -- Max Extension Travel (in studs)
Tune.RCompressLim = 0.6 -- Max Compression Travel (in studs)

--Old Suspension Settings, applies if there is no SuspensionGeometry for the respective wheel
Tune.FSusAngle = 80 -- Spring Angle (degrees from horizontal)
Tune.FWsBoneLen = 4 -- Wishbone Length
Tune.FWsBoneAngle = 0 -- Wishbone angle (degrees from horizontal)
Tune.FAnchorOffset = { -- Suspension anchor point offset (relative to center of wheel)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	-0.5, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward
Tune.FSpringOffset = { -- Suspension anchor point offset (relative to ABOVE anchor offset) (Avxnturador)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	0, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward

Tune.RSusAngle = 80 -- Spring Angle (degrees from horizontal)
Tune.RWsBoneLen = 4 -- Wishbone Length
Tune.RWsBoneAngle = 0 -- Wishbone angle (degrees from horizontal)
Tune.RAnchorOffset = { -- Suspension anchor point offset (relative to center of wheel)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	-0.5, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward
Tune.RSpringOffset = { -- Suspension anchor point offset (relative to ABOVE anchor offset) (Avxnturador)
	--[[Lateral]]
	-0.4, -- positive = outward
	--[[Vertical]]
	0, -- positive = upward
	--[[Forward]]
	0,
} -- positive = forward

--Aesthetics
Tune.SusVisible = false -- Suspension Visible
Tune.SpringsVisible = true -- Springs Visible
Tune.SusRadius = 0.2 -- Spring Coil Radius
Tune.SusThickness = 0.1 -- Spring Coil Thickness
Tune.SusColor = BrickColor.new("Bright red") -- Spring Color [BrickColor]
Tune.SusCoilCount = 6 -- Spring Coil Count

return Tune
