local Types = {}

type FlipType = "New" | "Old"
type SteeringType = "Auto" | "Manual"
type FWSteerType = "Static" | "Speed" | "Both" | "None"
type PowerSteeringType = "Old" | "New"
type DrivetrainConfig = "FWD" | "RWD" | "AWD"
type TransmissionMode = "Auto" | "Semi" | "Manual"
type ClutchMode = "New" | "Old"
type AutoShiftMode = "Speed" | "RPM"
type AutoShiftType = "Rev" | "DCT"
type AutoShiftVers = "New" | "Old"
type ClutchType = "Clutch" | "TorqueConverter" | "CVT"

export type SoundData = {
	Sound: Sound,
	Parent: string?,
}

export type VehicleControls = {
	--Keyboard Controls
	--Mode Toggles
	ToggleTCS: Enum.KeyCode,
	ToggleABS: Enum.KeyCode,
	ToggleCS: Enum.KeyCode,
	ToggleTransMode: Enum.KeyCode,
	ToggleMouseDrive: Enum.KeyCode,

	--Primary Controls
	Throttle: Enum.KeyCode,
	Brake: Enum.KeyCode,
	SteerLeft: Enum.KeyCode,
	SteerRight: Enum.KeyCode,
	Ignition: Enum.KeyCode,

	--Secondary Controls
	Throttle2: Enum.KeyCode,
	Brake2: Enum.KeyCode,
	SteerLeft2: Enum.KeyCode,
	SteerRight2: Enum.KeyCode,

	--Manual Transmission
	ShiftUp: Enum.KeyCode,
	ShiftDown: Enum.KeyCode,
	Clutch: Enum.KeyCode,

	--Handbrake
	PBrake: Enum.KeyCode,

	--Mouse Controls
	MouseThrottle: Enum.UserInputType,
	MouseBrake: Enum.UserInputType,
	MouseClutch: Enum.KeyCode,
	MouseShiftUp: Enum.KeyCode,
	MouseShiftDown: Enum.KeyCode,
	MousePBrake: Enum.KeyCode,

	MSteerWidth: number,
	MSteerDZone: number,

	--Controller Mapping
	ContlrThrottle: Enum.KeyCode,
	ContlrBrake: Enum.KeyCode,
	ContlrSteer: Enum.KeyCode,
	ContlrShiftUp: Enum.KeyCode,
	ContlrShiftDown: Enum.KeyCode,
	ContlrClutch: Enum.KeyCode,
	ContlrPBrake: Enum.KeyCode,
	ContlrToggleTMode: Enum.KeyCode,
	ContlrToggleTCS: Enum.KeyCode,
	ContlrToggleABS: Enum.KeyCode,
	ContlrToggleCS: Enum.KeyCode,

	ControlLDZone: number,
	ControlRDZone: number,
}

export type VehicleSpeedometer = {
	__index: VehicleSpeedometer,
	Vehicle: ClientVehicle,
	Instance: Frame & any,
	CurrentUnit: number,
	Units: { { Unit: string, Scaling: number, MaxSpeed: number } },
	_conn: RBXScriptConnection,
	_task: thread,

	new: (vehicle: ClientVehicle, instance: Frame) -> VehicleSpeedometer,
	Update: (self: VehicleSpeedometer) -> (),
	SlowUpdate: (self: VehicleSpeedometer) -> (),
	SpeedUpdate: (self: VehicleSpeedometer) -> (),
	BoostUpdate: (self: VehicleSpeedometer) -> (),
	GearUpdate: (self: VehicleSpeedometer) -> (),
	MileageUpdate: (self: VehicleSpeedometer) -> (),
	FuelUpdate: (self: VehicleSpeedometer) -> (),
	TachUpdate: (self: VehicleSpeedometer) -> (),
	UpdateIcons: (self: VehicleSpeedometer) -> (),
	ABSUpdate: (self: VehicleSpeedometer) -> (),
	TSCUpdate: (self: VehicleSpeedometer) -> (),
	Destroy: (self: VehicleSpeedometer) -> (),
	TachInit: (self: VehicleSpeedometer) -> (),
}

export type VehicleInterface = {
	__index: VehicleInterface,
	Vehicle: ClientVehicle,
	Instance: ScreenGui & any,
	Speedometer: VehicleSpeedometer,

	new: (vehicle: ClientVehicle) -> VehicleInterface,
	Destroy: (self: VehicleInterface) -> (),
}

export type ClientVehicle = {
	__index: ClientVehicle,
	Instance: Instance & {
		Wheels: Model & any,
		DriveSeat: VehicleSeat & {
			Flip: AlignOrientation,
		},
		Body: Model & {
			["#Weight"]: BasePart,
		},
	},
	_WheelSpeeds: { [string]: { number } },
	_LastInputWasGamepad: boolean,
	_MaxSpin: number,
	Tune: Tune,
	Occupant: Player?,
	Plugins: { [string]: any },
	WheelCount: { Front: number, Rear: number },
	WheelData: { [BasePart]: any },
	DriveWheels: { BasePart },
	ParkingGearEnabled: boolean,
	BrakeForce: { Front: number, Rear: number },
	PBrakeForce: { Front: number, Rear: number },
	Starting: boolean,
	Engine: any,
	Fuel: number,
	Controls: VehicleControls,
	Interface: VehicleInterface?,
	-- Transmission
	Clutch: number,
	Gear: number,
	FinalDrive: number,
	FinalDriveRatio: number,
	TransmissionMode: TransmissionMode,
	CurrentRatio: number,
	RPM: number,
	Shifting: boolean,
	AutoClutch: boolean,
	_GoalRPM: number,
	_ShiftUp: boolean,
	_ShiftDown: boolean,
	_ClutchPressing: boolean,
	_InputClutch: boolean,
	_DriveWheelSpeed: number,
	_LastOffTime: number,
	_CanStall: boolean,
	_Trackers: { ESC: {}, ABS: {}, TCS: {} },
	-- Boost
	Boost: number,
	BoostTurbo: number,
	BoostSuper: number,
	-- Horsepower
	HpNatural: number,
	HpElectric: number,
	HpTurbo: number,
	HpSuper: number,
	HpBoosted: number,
	Horsepower: number,
	-- Torque
	TqNatural: number,
	TqElectric: number,
	TqTurbo: number,
	TqSuper: number,
	TqBoosted: number,
	Torque: number,
	-- Inputs
	Throttle: number,
	InputThrottle: number,
	Brake: number,
	InputBrake: number,
	SteerC: number,
	SteerT: number,
	MouseSteerOn: boolean,
	PBrake: boolean,
	_SteerL: boolean,
	_SteerR: boolean,
	_InThrot: number,
	_InBrake: number,
	-- Velocity
	Velocity: Vector3,
	_OldVelocity: Vector3,
	AverageRotSpeed: number,
	Acceleration: Vector3,
	Mileage: number,
	-- Misc
	Center: CFrame,
	TCS: boolean,
	TCSActive: boolean,
	TCSAmt: number,
	ABS: boolean,
	ABSActive: boolean,
	ABSAmt: number,
	ESC: boolean,
	ESCActive: boolean,
	ESCAmt: number,
	CS: boolean,
	CSActive: boolean,
	CSAmt: number,
	IsOn: boolean,
	-- Functions
	new: (instance: Instance) -> ClientVehicle,
	Initialize: (self: ClientVehicle) -> (),
	InitializeVariables: (self: ClientVehicle) -> (),
	InitializeWheels: (self: ClientVehicle) -> (),
	InitializeDriveSeat: (self: ClientVehicle) -> (),
	ShutdownEvent: (self: ClientVehicle) -> (),
	InitControls: (self: ClientVehicle) -> (),
	InitializePlugins: (self: ClientVehicle) -> (),
	Update: (self: ClientVehicle, deltaTime: number) -> (),
	SlowUpdate: (self: ClientVehicle) -> (),
	UpdateWheels: (self: ClientVehicle) -> (),
	SmoothInputs: (self: ClientVehicle, deltaTime: number) -> (),
	UpdateSteering: (self: ClientVehicle, deltaTime: number) -> (),
	UpdateTransmission: (self: ClientVehicle) -> (),
	UpdateEngine: (self: ClientVehicle, deltaTime: number) -> (),
	UpdateFuel: (self: ClientVehicle, deltaTime: number) -> (),
	OnInput: (self: ClientVehicle, input: InputObject) -> (),
	OnLastInputTypeChanged: (self: ClientVehicle, inputType: Enum.UserInputType) -> (),
}

export type Tune = {
	-- Misc
	LoadDelay: number,
	AutoStart: boolean,
	AutoFlip: boolean,
	Mobile: boolean,
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
	Sounds: { [string]: SoundData },
}

return Types
