--- Naturally Aspirated Engine
---
--- [*Calculator to tune the engine*](https://www.desmos.com/calculator/cqhgbm0vlt)
export type Engine = {
	--- The name of the engine
	Title: string,
	--- The description of the engine
	Description: string,
	--- Naturally Aspirated Engine
	---
	--- [*Calculator to tune the engine*](https://www.desmos.com/calculator/cqhgbm0vlt)
	Engine: boolean,
	--- The maximum amount of torque the engine makes in lb-ft.
	PeakTorque: number,
	--- When the engine reaches PeakTorque in RPM.
	PeakTorqueRPM: number,
	--- The engine's desired idle RPM. IdleDamping may change this.
	IdleRPM: number,
	--- How much torque the engine makes at idle.
	IdleTorque: number,
	--- The shape of the torque curve between idle and PeakRPM.
	IdleTorqueCurve: number,
	--- The maximum RPM.
	Redline: number,
	--- How much torque the engine makes at redline.
	RedlineTorque: number,
	--- The shape of the torque curve between PeakRPM and redline.
	RedlineTorqueCurve: number,
	--- This is when the engine shifts.
	ShiftRPM: number,
	--- **Deprecated.** Used for plugin compatibility. Set it to `ShiftRPM`
	PeakRPM: number,
	--- Variable Valve Lift (VVL, aka VTEC)'s amount of torque. Set this to 0 to turn off.
	VVLTorque: number,
	--- When VVL activates in RPM.
	VVLRPM: number,
	--- How long it takes for VVL to activate in RPM.
	VVLTime: number,
	--- The shape of the curve during VVL activation.
	VVLCurve: number,
	--- The horsepower limit of the engine (set to 0 to turn off).
	HPLimit: number,
	--- The temperature at which the engine operating normally
	OperatingEngineTemp: number,
	--- The temperature at which the engine will explode
	EngineBurnTemp: number,
	--- The factor of engine material
	EngineMaterialFactor: number,
	--- Raw heat gain per kW per second (unaffected by engine material) at 50% of redline
	HeatGain: number,
	--- Heat gain multiplier at redline (excluding rpm effect). Think of this as "inefficiency" of cumbustion
	RedlineHeatRejection: number,
	--- Heat gain multiplier at idle (excluding rpm effect). Think of this as "inefficiency" of cumbustion
	IdleHeatRejection: number,
	--- Max damage on redline per hour
	RPMDamage: number,
	--- Damage at `EngineBurnTemp` per hour
	HotDamage: number,
	--- Damage at 1000 RPM beyond the redline per second
	RedlineDamage: number,
	--- The shape of the redline damage curve
	RedlineDamageCurve: number,
	--- Air speed (M/s) from the fan at redline (assumes mechanical linkage to fan from engine)
	FanAirSpeed: number,
	--- Think of this as a size of radiator + efficiency variable
	CoolingFactor: number,
	--- RPM at which the engine is most efficient
	EfficientCombustionRPM: number,
	--- Number of turbochargers in the engine, set to 0 for no turbochargers
	Turbochargers: number,
	--- The maximum amount of boost of one turbocharger in PSI.
	T_Boost: number,
	--- When the turbo reaches maximum boost.
	T_PeakRPM: number,
	--- How much boost is made at idle.
	T_IdleBoost: number,
	--- The shape of the boost curve between idle and PeakRPM.
	T_Curve: number,
	--- How much torque is made with 1 PSI.
	T_Efficiency: number,
	--- Turbo size, larger = less boost from horsepower
	T_Size: number,
	--- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)
	T_SpoolIncrease: number,
	--- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)
	T_SpoolDecrease: number,
	--- Number of superchargers in the engine, Set to 0 for no superchargers
	Superchargers: number,
	--- The maximum amount of boost of one supercharger in PSI.
	S_Boost: number,
	--- When the supercharger reaches its maximum boost.
	S_PeakRPM: number,
	--- The amount of boost at idle.
	S_IdleBoost: number,
	--- The shape of the boost curve between idle and PeakRPM.
	S_IdleCurve: number,
	--- The amount of boost at redline.
	S_RedlineBoost: number,
	--- The shape of the boost curve between PeakRPM and redline.
	S_RedlineCurve: number,
	--- How much torque is made with 1 PSI.
	S_Efficiency: number,
	--- Throttle response of the supercharger. (Higher = more responsive, ranges from 0 to 1)
	S_Response: number,
	--- This is how high the engine revs for the ignition.
	IgnitionRPM: number,
	--- The acceleration of the RPM while starting the car.
	IgnitionAccel: number,
	--- The minimum RPM required to start the car.
	IgnitionMinRPM: number,
	--- RPM kickback from redline
	RevBounce: number,
	--- Set to true to allow the RPM to go above redline
	OverRev: boolean,
	--- RPM acceleration when clutch is on (this should be higher than RevDecay and RevDecayRPM)
	RevAccel: number,
	--- RPM decay when clutch is on
	RevDecay: number,
	--- RPM decay from engine speed
	RevDecayRPM: number,
	--- Flywheel weight (higher = faster response, lower = more stable RPM)
	Flywheel: number,
	--- Flywheel energy multiplier when dumping the clutch (keep at 1.0 for the best result).
	DumpMult: number,
	--- Percent throttle with no input. (in percent)
	IdleThrottle: number,
	--- Damping of idle in RPM. This will change that actual idle RPM at higher values.
	IdleDamping: number,
	--- Added on top of IdleRPM to account for IdleDamping
	IdlePadding: number,
	--- Tries to remove the natural creep of the chassis by applying clutch if there is no input throttle and if the RPM is below idle.
	RemoveCreep: boolean,
	--- Torque compensation multiplier for inclines (applies gradient from 0-90 degrees)
	InclineComp: number,
	--- Electric Engine
	---
	--- [*Calculator to tune the engine*](https://www.desmos.com/calculator/cqhgbm0vlt)
	Electric: boolean,
	--- The amount of electric torque in lb-ft.
	E_Torque: number,
	--- When the torque begins decaying.
	E_TransitionRPM: number,
	--- The maximum RPM of the electric motor.
	E_Redline: number,
	--- How much torque is made at the maximum RPM.
	E_RedlineTorque: number,
	--- The shape of the curve between TransitionRPM and the redline.
	E_Curve: number,
}

return {}
