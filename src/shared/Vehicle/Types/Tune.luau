local SoundData = require(script.Parent.SoundData)

type HapticsType = "Controller" | "Mobile" | "Both" | "None"
type SteeringType = "Auto" | "Manual"
type TireSmokeEffectsType = "Local" | "All" | "None"
type FWSteerType = "Static" | "Speed" | "Both" | "None"
type DrivetrainConfig = "FWD" | "RWD" | "AWD"
type ClutchType = "Clutch" | "TorqueConverter" | "CVT"
type ClutchMode = "New" | "Old"
type AutoShiftMode = "Speed" | "RPM"
type AutoShiftType = "Rev" | "DCT"
type AutoShiftVers = "New" | "Old"
type PowerSteeringType = "Old" | "New"
type FlipType = "New" | "Old"
export type TransmissionMode = "Auto" | "Semi" | "Manual"

export type Tune = {
	-- Misc
	LoadDelay: number,
	AutoStart: boolean,
	AutoFlip: boolean,
	Mobile: boolean,
	Haptics: HapticsType,
	FlipType: FlipType,
	-- Wheel Alignment
	FCamber: number,
	RCamber: number,
	FCaster: number,
	RCaster: number,
	FToe: number,
	RToe: number,
	-- Weight and CG
	Weight: number,
	WeightBSize: { number },
	WeightDist: number,
	CGHeight: number,
	WBVisible: boolean,
	GravComp: number,
	-- Textures
	EngineBlowTexture: string,
	EngineBlowOpacity: number,
	DirtTexture: string,
	-- Unsprung Weight
	FWheelWeight: number,
	RWheelWeight: number,
	-- Axle
	AxleSize: number,
	AxleDensity: number,
	CustomSuspensionDensity: number,
	-- Suspension
	SuspensionEnabled: boolean,
	-- Front Suspension
	FSusStiffness: number,
	FSusDamping: number,
	FSwayBar: number,
	FSusLength: number,
	FPreCompress: number,
	FExtensionLim: number,
	FCompressLim: number,
	-- Rear Suspension
	RSusStiffness: number,
	RSusDamping: number,
	RSwayBar: number,
	RSusLength: number,
	RPreCompress: number,
	RExtensionLim: number,
	RCompressLim: number,
	-- Old suspension settings
	FSusAngle: number,
	FWsBoneLen: number,
	FWsBoneAngle: number,
	FAnchorOffset: { number },
	FSpringOffset: { number },
	RSusAngle: number,
	RWsBoneLen: number,
	RWsBoneAngle: number,
	RAnchorOffset: { number },
	RSpringOffset: { number },
	-- Tires
	TireFThickness: number,
	TireRThickness: number,
	TireFPressureForce: number,
	TireRPressureForce: number,
	TireFSpeedStress: number,
	TireRSpeedStress: number,
	TireDirtBumps: number,
	TireFHeating: number,
	TireFCooling: number,
	TireFMaxTemp: number,
	TireRHeating: number,
	TireRCooling: number,
	TireRMaxTemp: number,
	TireFColdStats: { number },
	TireRColdStats: { number },
	TireFHotStats: { number },
	TireRHotStats: { number },
	TireFWeight: number,
	TireRWeight: number,
	TireFMaxFriction: number,
	TireRMaxFriction: number,
	TireFDirtLoss: number,
	TireRDirtLoss: number,
	TireSandForce: number,
	TireSmokeStressOffset: number,
	TireSmokeEffects: TireSmokeEffectsType,
	TireMarkTransparencyLevels: number,
	TireMarkTransparency: number,
	TireFlexDebug: boolean,
	-- Aesthetics
	SusVisible: boolean,
	SpringsVisible: boolean,
	SusRadius: number,
	SusThickness: number,
	SusColor: BrickColor,
	SusCoilCount: number,
	-- Steering
	SteeringType: SteeringType,
	SteerRatio: number,
	LockToLock: number,
	Ackerman: number,
	-- Manual steering
	SteerInner: number,
	SteerOuter: number,
	-- Steer speed tuning
	SteerSpeed: number,
	ReturnSpeed: number,
	ContlrSteerSpeed: number,
	ContlrReturnSpeed: number,
	MSteerUsesContlr: boolean,
	-- Steer decay
	SteerDecay: number,
	SteerSpeedDecay: number,
	MinSteer: number,
	MinSteerSpeed: number,
	MSteerExp: number,
	-- Counter-steer
	CSEnabled: boolean,
	CSAmt: number,
	CSSteerThresh: number,
	CSSpeedThresh: number,
	-- Four Wheel Steering
	FWSteer: FWSteerType,
	RSteerOuter: number,
	RSteerInner: number,
	RSteerSpeed: number,
	RSteerDecay: number,
	RSteerD: number,
	RSteerP: number,
	RSteerMaxTorque: number,
	-- Steering aggressiveness
	SteerSmoothing: number,
	PowerSteeringType: PowerSteeringType,
	SteerD: number,
	SteerP: number,
	SteerMaxTorque: number,
	-- Custom engine
	CustomEngineCalculations: boolean,
	-- Naturally Aspirated Engine
	Engine: boolean,
	PeakTorque: number,
	PeakTorqueRPM: number,
	IdleRPM: number,
	IdleTorque: number,
	IdleTorqueCurve: number,
	Redline: number,
	RedlineTorque: number,
	RedlineTorqueCurve: number,
	ShiftRPM: number,
	PeakRPM: number,
	VVLTorque: number,
	VVLRPM: number,
	VVLTime: number,
	VVLCurve: number,
	HPLimit: number,
	-- Fuel
	FuelCapacity: number,
	FuelDensity: number,
	BSFC: number,
	-- Temperature
	OperatingEngineTemp: number,
	EngineBurnTemp: number,
	HeatGain: number,
	RedlineHeatRejection: number,
	IdleHeatRejection: number,
	FanAirSpeed: number,
	CoolingFactor: number,
	EngineMaterialFactor: number,
	EfficientCombustionRPM: number,
	-- Damage
	RPMDamage: number,
	RedlineDamage: number,
	-- Electric Engine
	Electric: boolean,
	E_Torque: number,
	E_TransitionRPM: number,
	E_Redline: number,
	E_RedlineTorque: number,
	E_Curve: number,
	-- Turbocharger
	Turbochargers: number,
	T_Boost: number,
	T_PeakRPM: number,
	T_IdleBoost: number,
	T_Curve: number,
	T_Efficiency: number,
	T_Size: number,
	T_SpoolIncrease: number,
	T_SpoolDecrease: number,
	-- Supercharger
	Superchargers: number,
	S_Boost: number,
	S_PeakRPM: number,
	S_IdleBoost: number,
	S_IdleCurve: number,
	S_RedlineBoost: number,
	S_RedlineCurve: number,
	S_Efficiency: number,
	S_Response: number,
	-- Ignition
	IgnitionRPM: number,
	IgnitionAccel: number,
	IgnitionMinRPM: number,
	-- Throttle and brake input
	ThrotAccel: number,
	ThrotDecel: number,
	BrakeAccel: number,
	BrakeDecel: number,
	-- Engine speed
	RevBounce: number,
	OverRev: boolean,
	RevAccel: number,
	RevDecay: number,
	RevDecayRPM: number,
	Flywheel: number,
	DumpMult: number,
	IdleThrottle: number,
	IdleDamping: number,
	IdlePadding: number,
	RemoveCreep: boolean,
	InclineComp: number,
	-- Drivetrain
	Config: DrivetrainConfig,
	TorqueVector: number,

	FDiffPower: number,
	FDiffCoast: number,
	FDiffPreload: number,
	RDiffPower: number,
	RDiffCoast: number,
	RDiffPreload: number,
	-- Traction Control
	TCSEnabled: boolean,
	TCSThreshold: number,
	TCSGradient: number,
	TCSLimit: number,
	-- Electronic Stability Control
	ESCEnabled: boolean,
	ESCVector: number,
	ESCThreshold: number,
	ESCSpeed: number,
	ESCThrottle: number,
	ESCBrake: number,
	-- Transmission
	Clutch: boolean,
	TransModes: { TransmissionMode },
	ClutchMode: ClutchMode,
	ClutchType: ClutchType,
	Stall: boolean,
	ClutchRel: boolean,
	ClutchEngage: number,
	SpeedEngage: number,
	ClutchRPMMult: number,
	-- Torque Converter
	TQLock: boolean,
	RPMEngage: number,
	-- CVT
	CVTRPM: number,
	CVTMaxRatio: number,
	CVTMinRatio: number,
	-- Neutral Rev Limiter
	NeutralLimit: boolean,
	NeutralRevRPM: number,
	LimitClutch: boolean,
	-- Automatic Settings
	AutoShiftMode: AutoShiftMode,
	AutoShiftType: AutoShiftType,
	AutoShiftVers: AutoShiftVers,
	AutoUpThresh: number,
	AutoDownThresh: number,
	-- Automatic: Revmatching
	ShiftThrot: number,
	-- Automatic: DCT
	ShiftUpTime: number,
	ShiftDnTime: number,
	-- Gear Ratios
	FinalDrive: number,
	Ratios: { number },
	FDMult: number,
	-- Speed Limiter
	SpeedLimit: number,
	ReverseSpeed: number,
	SLimitGradient: number,
	SLimitBrake: boolean,
	-- Brakes
	ExitBrake: boolean,
	-- ABS
	ABSEnabled: boolean,
	ABSThreshold: number,
	ABSGradient: number,
	ABSLimit: number,
	-- Forces
	BrakeForce: number,
	BrakeBias: number,
	PBrakeForce: number,
	PBrakeBias: number,
	EBrakeForce: number,
	-- Sounds
	Sounds: { [string]: SoundData.SoundData },
}

return {}
