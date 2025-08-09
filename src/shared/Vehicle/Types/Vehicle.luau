local Controls = require(script.Parent.Controls)
local Tune = require(script.Parent.Tune)

export type BaseVehicle = {
	__index: BaseVehicle,
	Instance: Instance & {
		Wheels: Model & any,
		DriveSeat: VehicleSeat & {
			Flip: AlignOrientation,
		},
		Body: Model & {
			["#Weight"]: BasePart,
			Collider: Model,
			Sounds: Model,
		},
	},
	_Remote: UnreliableRemoteEvent,
	Plugins: { [string]: any },
	Wheels: { BaseWheel },
	Tune: Tune.Tune,
	Starting: boolean,
	Broken: boolean,
	Occupant: Player?,
	Fuel: number,
	EngineHealth: number,
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
	AngularVelocity: Vector3,
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

	new: (instance: Instance) -> BaseVehicle,
	InitializeWheels: (self: BaseVehicle, wheelClass: BaseWheel) -> (),
}

export type DeformationController = {
	__index: DeformationController,
	Vehicle: ClientVehicle,
	DeformModel: Model & {
		Body: MeshPart,
		EngineBlow: Part,
	},
	ColliderModel: Model,
	Body: MeshPart,
	BodyMesh: EditableMesh,
	BodyTexture: EditableImage,
	ScratchTexture: EditableImage,

	new: (vehicle: ClientVehicle) -> DeformationController,
	BlowEngine: (self: DeformationController) -> (),
}

export type ClientVehicle = {
	__index: ClientVehicle,
	_conn: { RBXScriptConnection },
	_task: thread,
	_LastInputWasGamepad: boolean,
	_MaxSpin: number,
	DeformationController: DeformationController,
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
	UpdateFuel: (self: ClientVehicle, deltaTime: number) -> (),
	UpdateTemp: (self: ClientVehicle, deltaTime: number) -> (),
	UpdateHealth: (self: ClientVehicle, deltaTime: number) -> (),
	ReplicateVariables: (self: ClientVehicle) -> (),
	Destroy: (self: ClientVehicle) -> (),
} & BaseVehicle

export type ServerVehicle = {
	__index: ServerVehicle,

	new: (instance: Instance) -> ServerVehicle,
	Initialize: (self: ServerVehicle) -> (),
	MakeGravity: (self: ServerVehicle) -> (),
	MakeCollider: (self: ServerVehicle) -> (),
	GetCenter: (self: ServerVehicle) -> (),
	RemoveMass: (self: ServerVehicle) -> (),
	CreateFlip: (self: ServerVehicle) -> (),
	Finalize: (self: ServerVehicle) -> (),
	InitializePlugins: (self: ServerVehicle) -> (),
	InitializeWheels: (self: ServerVehicle) -> (),
	ApplyWeight: (self: ServerVehicle) -> (),
	RemoveCharacterWeight: (self: ServerVehicle) -> (),
	InitializeDriveSeat: (self: ServerVehicle) -> (),
} & BaseVehicle

export type BaseWheel = {
	__index: BaseWheel,
	Instance: BasePart & {
		Base: BasePart,
		Arm: BasePart & {
			Steer: Instance,
		},
		Parts: Model & {
			Tire: BasePart,
		},
		Fixed: Model,
		WheelFixed: Model,
		["#AV"]: any,
		["#BV"]: any,
		AB: any,
		Collision: BasePart,
		SuspensionFixed: Model,
	},
	Vehicle: BaseVehicle,
	IsFront: boolean,
	IsDriven: boolean,

	new: (vehicle: BaseVehicle, instance: BasePart) -> BaseWheel,
}

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
	Tire: ClientWheelTire,
	CanSteer: number,
	OppositeWheel: BasePart,
	Trackers: { ABS: number, TCS: number, ESC: number },
	_WheelSpeeds: { number },

	new: (vehicle: ClientVehicle, wheel: BasePart) -> ClientWheel,
	Update: (self: ClientWheel, data: ClientWheelSharedData) -> (),
	Destroy: (self: ClientWheel) -> (),
} & BaseWheel

export type ServerWheel = {
	__index: ServerWheel,
	Vehicle: ServerVehicle,
	Tire: ServerWheelTire,

	new: (vehicle: ServerVehicle, instance: BasePart) -> ServerWheel,
	Initialize: (self: ServerWheel) -> (),
} & BaseWheel

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

export type EffectFrame = {
	Instance: Frame,
	Rotation: number,
	Force: number,
	Position: number,

	Move: (self: EffectFrame, delta: number) -> (),
	Destroy: (self: EffectFrame) -> (),
}

export type SpeedEffect = {
	__index: SpeedEffect,
	Vehicle: ClientVehicle,
	Parent: GuiObject,
	Effects: { EffectFrame },
	_LastSpawn: number,

	new: (self: SpeedEffect, vehicle: ClientVehicle, part: GuiObject) -> SpeedEffect,
	Update: (self: SpeedEffect, deltaTime: number) -> (),
}

export type VehicleInterface = {
	__index: VehicleInterface,
	Vehicle: ClientVehicle,
	Instance: ScreenGui & any,
	Speedometer: VehicleSpeedometer,
	SpeedEffect: SpeedEffect,

	new: (vehicle: ClientVehicle) -> VehicleInterface,
	UpdateTires: (self: VehicleInterface) -> (),
	Destroy: (self: VehicleInterface) -> (),
}

return {}
