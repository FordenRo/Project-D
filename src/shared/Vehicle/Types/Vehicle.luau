local Controls = require(script.Parent.Controls)
local Tune = require(script.Parent.Tune)

export type BaseVehicle = {
	Instance: Instance & {
		Wheels: Model & any,
		DriveSeat: VehicleSeat & {
			Flip: AlignOrientation,
		},
		Body: Model & {
			["#Weight"]: BasePart,
			Sounds: Model,
		},
	},
	_Remote: UnreliableRemoteEvent,
	Tune: Tune.Tune,
	Starting: boolean,
	Occupant: Player?,
	Fuel: number,
	Temperature: number,
	FanSpeed: number,
	Horning: boolean,
	-- Transmission
	Clutch: number,
	Gear: number,
	FinalDrive: number,
	FinalDriveRatio: number,
	TransmissionMode: Tune.TransmissionMode,
	CurrentRatio: number,
	RPM: number,
	Shifting: boolean,
	AutoClutch: boolean,
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
	-- Velocity
	Velocity: Vector3,
	AverageRotSpeed: number,
	Acceleration: Vector3,
	Mileage: number,
	-- Misc
	Center: CFrame,
	TCS: boolean,
	TCSActive: boolean,
	ABS: boolean,
	ABSActive: boolean,
	ESC: boolean,
	ESCActive: boolean,
	CS: boolean,
	CSActive: boolean,
	IsOn: boolean,
}

export type ClientVehicle = {
	__index: ClientVehicle,
	_conn: { RBXScriptConnection },
	_task: thread,
	_LastInputWasGamepad: boolean,
	_MaxSpin: number,
	Plugins: { [string]: any },
	WheelCount: { Front: number, Rear: number },
	Wheels: { ClientWheel },
	DriveWheels: { ClientWheel },
	ParkingGearEnabled: boolean,
	BrakeForce: { Front: number, Rear: number },
	PBrakeForce: { Front: number, Rear: number },
	Engine: any,
	Controls: Controls.VehicleControls,
	Interface: VehicleInterface,
	-- Transmission
	_GoalRPM: number,
	_ShiftUp: boolean,
	_ShiftDown: boolean,
	_ClutchPressing: boolean,
	_InputClutch: boolean,
	_DriveWheelSpeed: number,
	_LastOffTime: number,
	_CanStall: boolean,
	-- Inputs
	_SteerL: boolean,
	_SteerR: boolean,
	_InThrot: number,
	_InBrake: number,
	-- Velocity
	_OldVelocity: Vector3,

	new: (instance: Instance) -> ClientVehicle,
	Initialize: (self: ClientVehicle) -> (),
	InitializeVariables: (self: ClientVehicle) -> (),
	InitializeWheels: (self: ClientVehicle) -> (),
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
	UpdateTemp: (self: ClientVehicle, deltaTime: number) -> (),
	OnInput: (self: ClientVehicle, input: InputObject) -> (),
	OnLastInputTypeChanged: (self: ClientVehicle, inputType: Enum.UserInputType) -> (),
	ReplicateVariables: (self: ClientVehicle) -> (),
	Destroy: (self: ClientVehicle) -> (),
} & BaseVehicle

export type ServerVehicle = {
	__index: ServerVehicle,
	Plugins: { [string]: any },

	new: (instance: Instance) -> ServerVehicle,
	Initialize: (self: ServerVehicle) -> (),
	InitializeVariables: (self: ServerVehicle) -> (),
	MakeGravity: (self: ServerVehicle) -> (),
	GetCenter: (self: ServerVehicle) -> (),
	RemoveMass: (self: ServerVehicle) -> (),
	CreateFlip: (self: ServerVehicle) -> (),
	Finalize: (self: ServerVehicle) -> (),
	InitializePlugins: (self: ServerVehicle) -> (),
	CreateChassisAssembly: (self: ServerVehicle) -> (),
	ApplyWeight: (self: ServerVehicle) -> (),
	RemoveCharacterWeight: (self: ServerVehicle) -> (),
	InitializeDriveSeat: (self: ServerVehicle) -> (),
} & BaseVehicle

export type ClientWheelSharedData = {
	TCSCount: number,
	ABSCount: number,
	ESCCount: number,
	Rotation: number,
	MaxSpin: number,
	DriveWheelSpeed: number,
}

export type ClientWheel = {
	__index: ClientWheel,
	Vehicle: ClientVehicle,
	Instance: BasePart & {
		Base: BasePart,
		Arm: nil | (Instance & {
			Steer: Instance?,
		}),
		Parts: Model & {
			Tire: BasePart,
		},
		WheelFixed: Model,
		["#AV"]: any,
		["#BV"]: any,
		SuspensionFixed: Model,
	},
	Tire: ClientWheelTire,
	IsFront: boolean,
	IsDriven: boolean,
	CanSteer: number,
	OppositeWheel: BasePart,
	Trackers: { ABS: number, TCS: number, ESC: number },
	_WheelSpeeds: { number },

	new: (vehicle: ClientVehicle, wheel: BasePart) -> ClientWheel,
	Update: (self: ClientWheel, data: ClientWheelSharedData) -> (),
	Destroy: (self: ClientWheel) -> (),
}

export type ServerWheel = {
	__index: ServerWheel,
	Vehicle: ServerVehicle,
	Instance: BasePart & {
		Base: BasePart,
		Arm: nil | (Instance & {
			Steer: Instance?,
		}),
		Parts: Model & {
			Tire: BasePart,
		},
		Fixed: Model,
		WheelFixed: Model,
		SuspensionFixed: Model,
	} & any,
	Tire: ServerWheelTire,

	new: (vehicle: ServerVehicle, instance: BasePart) -> ServerWheel,
	Initialize: (self: ServerWheel) -> (),
}

export type ClientWheelTire = {
	__index: ClientWheelTire,
	Instance: BasePart,
	Wheel: ClientWheel,
	Vehicle: ClientVehicle,
	Temperature: number,
	_Remote: UnreliableRemoteEvent,
	_deltaTime: number,
	Stress: number,
	Dirt: number,
	Ray: RaycastResult?,
	RayParams: RaycastParams,
	Material: string,
	SmokePart: BasePart,
	Collision: BasePart,
	CollisionModel: Model,
	FlexCollision: BasePart,
	FlexCollisionGravComp: any,
	ObjectGravComp: any,
	TrailAttachmentPart: BasePart,
	FlexCollisionAlignPosition: AlignPosition,
	CurrentSound: Sound?,
	CurrentSmoke: Smoke?,
	CurrentTrail: { Trail }?,
	Sounds: { [string]: Sound },
	Smokes: { [string]: Smoke },
	Trails: { [string]: { Trail } },
	TrailStress: number,

	new: (wheel: ClientWheel, instance: BasePart) -> ClientWheelTire,
	Initialize: (self: ClientWheelTire) -> (),
	InitializeVariables: (self: ClientWheelTire) -> (),
	Update: (self: ClientWheelTire, deltaTime: number) -> (),
	FlexPhysicsUpdate: (self: ClientWheelTire, deltaTime: number) -> (),
	SmokeUpdate: (self: ClientWheelTire) -> (),
	Destroy: (self: ClientWheelTire) -> (),
}

export type ServerWheelTire = {
	__index: ServerWheelTire,
	Instance: BasePart,
	Wheel: ServerWheel,
	Vehicle: ServerVehicle,
	WearInstance: BasePart,
	PreviousMaterialData: { [BasePart]: string },
	PreviousSoundsData: { [BasePart]: Sound },
	PreviousSmokesData: { [BasePart]: Smoke },
	PreviousTrailsData: { [BasePart]: { Trail } },
	_Remote: UnreliableRemoteEvent,

	new: (wheel: ServerWheel, instance: BasePart) -> ServerWheelTire,
	Initialize: (self: ServerWheelTire) -> (),
	Replicate: (
		self: ServerWheelTire,
		materialType: string,
		smokeStress: number,
		rayNormal: Vector3,
		temperature: number,
		deltaTime: number
	) -> (),
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
	TempUpdate: (self: VehicleSpeedometer) -> (),
	Destroy: (self: VehicleSpeedometer) -> (),
	TachInit: (self: VehicleSpeedometer) -> (),
	LightsUpdate: (self: VehicleSpeedometer) -> (),
	TurnSignalsUpdate: (self: VehicleSpeedometer) -> (),
}

export type VehicleInterface = {
	__index: VehicleInterface,
	Vehicle: ClientVehicle,
	Instance: ScreenGui & any,
	Speedometer: VehicleSpeedometer,

	new: (vehicle: ClientVehicle) -> VehicleInterface,
	UpdateTires: (self: VehicleInterface) -> (),
	Destroy: (self: VehicleInterface) -> (),
}

return {}
