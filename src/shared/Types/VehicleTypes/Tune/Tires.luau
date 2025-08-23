type SmokeEffects = "All" | "Local" | "Off"

export type Type = {
	--- Aggresiveness of artificial bumps in dirt-, sand-, and snow-type surfaces
	TireDirtBumps: number,
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

	--- Minimum temperature of the front tires in celcius
	TireFMinTemp: number,
	--- Maximum temperature of the front tires in celcius
	TireFMaxTemp: number,
	--- Maximum friction of the front tires
	TireFMaxFriction: number,
	--- Loss, Sharpness, Offset
	TireFColdStats: { number },
	--- Loss, Sharpness, Offset
	TireFHotStats: { number },
	--- Friction loss from dirty tires
	TireFDirtLoss: number,
	--- Heat gain from maximum slippage
	TireFHeating: number,
	--- Heat loss at no slippage
	TireFCooling: number,
	--- Stress generated at 100 km/h
	TireFSpeedStress: number,

	--- Minimum temperature of the front tires in celcius
	TireRMinTemp: number,
	--- Maximum temperature of the front tires in celcius
	TireRMaxTemp: number,
	--- Maximum friction of the front tires
	TireRMaxFriction: number,
	--- Loss, Sharpness, Offset
	TireRColdStats: { number },
	--- Loss, Sharpness, Offset
	TireRHotStats: { number },
	--- Friction loss from dirty tires
	TireRDirtLoss: number,
	--- Heat gain from maximum slippage
	TireRHeating: number,
	--- Heat loss at no slippage
	TireRCooling: number,
	--- Stress generated at 100 km/h
	TireRSpeedStress: number,

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
