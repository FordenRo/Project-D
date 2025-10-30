type SmokeEffects = "All" | "Local" | "Off"

export type Type = {
	--- Sand force, more means going over sand slows down the car more
	TireSandForce: number,
	--- Turns smoke effects on or off, "All" for viewable by everyone, "Local" for only viewable by you, "Off" for none.
	TireSmokeEffects: SmokeEffects,
	--- Offsets the stress required to activate smoke-related effects (in percent, higher means less smoke).
	TireSmokeStressOffset: number,
	--- "All" setting only. This changes how often the server gets data to run the smoke effects. Higher = more delay.
	TireSmokePollingRate: number,
	--- How many levels of transparency there are (0 for no marks)
	TireMarkTransparencyLevels: number,
	--- The transparency of the tire marks
	TireMarkTransparency: number,

	--- Maximum friction of the front tires
	TireFMaxFriction: number,
	--- Maximum friction of the rear tires
	TireRMaxFriction: number,

	--- Damage at maximum stress per second
	TireDamage: number,
	--- Friction loss from weared tires
	TireWearLoss: number,
	--- Friction loss from dirty tires
	TireDirtLoss: number,
	--- Stress generated at 100 km/h
	TireSpeedStress: number,

	--- Debug tire flex
	TireFlexDebug: boolean,

	--- Tire weight in kg
	TireFWeight: number,
	--- Tire sidewall thickness in milimeters
	TireFThickness: number,
	--- Pressure force (no unit)
	TireFPressureForce: number,

	--- Tire weight in kg
	TireRWeight: number,
	--- Tire sidewall thickness in milimeters
	TireRThickness: number,
	--- Pressure force (no unit)
	TireRPressureForce: number,
}

return {}
