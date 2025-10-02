export type Type = {
	--- Implements the Antilock Braking System
	ABSEnabled: boolean,
	--- Slip speed allowed before ABS starts working (in km/h)
	ABSThreshold: number,
	--- Slip speed gradient between 0 to max reduction (in km/h)
	ABSGradient: number,
	--- Minimum amount of torque at max reduction (in percent)
	ABSLimit: number,

	--- Implements TCS
	TCSEnabled: boolean,
	--- Slip speed allowed before TCS starts working (in km/h)
	TCSThreshold: number,
	--- Slip speed gradient between 0 to max reduction (in km/h)
	TCSGradient: number,
	--- Minimum amount of torque at max reduction (in percent)
	TCSLimit: number,

	--- Implements ESC. TCS MUST ALSO BE ENABLED. This uses the same keybind as TCS.
	ESCEnabled: boolean,
	--- Force from the front to the rear for ESC. "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.
	ESCVector: number,
	--- Force difference in Gs before ESC starts working.
	ESCThreshold: number,
	--- Minimum speed before ESC can work in km/h.
	ESCSpeed: number,
	--- Maximum amount of throttle allowed to ESC in percent. (0 to allow no throttle)
	ESCThrottle: number,
	--- Maximum amount of brakes allowed to ESC in percent. (0 to allow no brakes)
	ESCBrake: number,
}

return {}
