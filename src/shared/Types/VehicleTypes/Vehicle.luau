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
			Lights: Model & {
				Front: Model,
				Rear: Model,
				TurnRight: Model,
				TurnLeft: Model,
				Reverse: Model,
				Brake: Model?,
			},
		},
	},
	_Remote: UnreliableRemoteEvent,
	Plugins: { [string]: any },
	Wheels: { BaseWheel },
	Tune: Tune.Tune,
	Lights: BaseLights,
	Starting: boolean,
	Broken: boolean,
	Occupant: Player?,
	Dirt: number,
	Fuel: number,
	ID: string,
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
	Brake: number,
	SteerC: number,
	SteerT: number,
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
		BlowSmokeParts: Model,
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
	_cons: { RBXScriptConnection },
	_task: thread,
	_LastInputWasGamepad: boolean,
	_MaxSpin: number,
	InputController: InputController,
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
	_DriveWheelSpeed: number,
	_LastOffTime: number,
	_CanStall: boolean,
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
	UpdateFuel: (self: ClientVehicle, deltaTime: number) -> (),
	UpdateTemp: (self: ClientVehicle, deltaTime: number) -> (),
	UpdateHealth: (self: ClientVehicle, deltaTime: number) -> (),
	ReplicateVariables: (self: ClientVehicle) -> (),
	Destroy: (self: ClientVehicle) -> (),
} & BaseVehicle

export type InputController = {
	__index: InputController,
	_cons: { RBXScriptConnection },
	Vehicle: ClientVehicle,
	_RawThrottle: number,
	_RawBrake: number,
	Throttle: number,
	Brake: number,
	Clutch: number,
	MousePosition: Vector2,
	MouseSteerOn: boolean,

	new: (vehicle: ClientVehicle) -> InputController,
	Destroy: (self: InputController) -> (),
}

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
			BrakeDisk: BasePart,
		},
		Fixed: Model,
		WheelFixed: Model,
		["#AV"]: HingeConstraint,
		["#BV"]: HingeConstraint,
		AB: any,
		Collision: BasePart,
		SuspensionFixed: Model,
		WheelSmokePart: Part,
		AxleP: Part & {
			AA: Attachment,
		},
	},
	Vehicle: BaseVehicle,
	BrakeDisk: BaseBrakeDisk,
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
	BrakeDisk: ClientBrakeDisk,
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
	BrakeDisk: ServerBrakeDisk,

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
	CurrentWheelSmoke: Smoke?,
	CurrentTrail: { Trail }?,
	Sounds: { [string]: Sound },
	Smokes: { [string]: Smoke },
	WheelSmokes: { [string]: Smoke },
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
	DirtInstance: BasePart,
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

export type BaseBrakeDisk = {
	__index: BaseBrakeDisk,
	_Remote: UnreliableRemoteEvent,
	Instance: BasePart,
	Wheel: BaseWheel,
	Temperature: number,
	Sound: Sound & {
		PitchEffect: PitchShiftSoundEffect,
	},

	new: (wheel: BaseWheel, instance: BasePart) -> BaseBrakeDisk,
}

export type ClientBrakeDisk = {
	__index: ClientBrakeDisk,
	_conn: RBXScriptConnection,
	_task: thread,
	_serverInstance: BasePart,
	_serverSound: Sound,
	_startColor: Color3,
	Volume: number,
	Wheel: ClientWheel,

	new: (wheel: ClientWheel, instance: BasePart) -> ClientBrakeDisk,
	Update: (self: ClientBrakeDisk, deltaTime: number) -> (),
	Destroy: (self: ClientBrakeDisk) -> (),
} & BaseBrakeDisk

export type ServerBrakeDisk = {
	__index: ServerBrakeDisk,
	_conn: RBXScriptConnection,
	Wheel: ServerWheel,

	new: (wheel: ServerWheel, instance: BasePart) -> ServerBrakeDisk,
	Update: (self: ServerBrakeDisk, temperature: number, color: Color3) -> (),
	Destroy: (self: ServerBrakeDisk) -> (),
} & BaseBrakeDisk

export type VehicleSpeedometer = {
	__index: VehicleSpeedometer,
	Vehicle: ClientVehicle,
	Instance: Frame & any,
	CurrentUnit: number,
	Units: { { Unit: string, Scaling: number, MaxSpeed: number } },
	_conn: RBXScriptConnection,
	_task: thread,

	new: (vehicle: ClientVehicle, instance: Frame) -> VehicleSpeedometer,
	Destroy: (self: VehicleSpeedometer) -> (),
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
	Instance: ScreenGui & {
		Cursor: Frame,
	},
	Speedometer: VehicleSpeedometer,
	SpeedEffect: SpeedEffect,
	CursorInstance: Frame,
	_CursorTransparency: number,
	_conn: RBXScriptConnection,

	new: (vehicle: ClientVehicle) -> VehicleInterface,
	UpdateTires: (self: VehicleInterface) -> (),
	UpdateCursor: (self: VehicleInterface) -> (),
	Destroy: (self: VehicleInterface) -> (),
}

export type Headlight = {
	__index: Headlight,
	_conn: RBXScriptConnection,
	_startBrightness: number,
	_currentBrightness: number,
	Instance: BasePart,
	Light: Light,
	Enabled: boolean,
	Brightness: number,
	DisabledColor: Color3,
	EnabledColor: Color3,

	new: (instance: BasePart) -> Headlight,
	SetBrightness: (self: Headlight, brightness: number) -> (),
	Destroy: (self: Headlight) -> (),
}

export type BaseLights = {
	_RE: RemoteEvent,
	Vehicle: BaseVehicle,
	State: "Off" | "Low" | "High",

	Destroy: (self: BaseLights) -> (),
}

export type ClientLights = {
	__index: ClientLights,
	_conn: RBXScriptConnection,

	new: (vehicle: ClientVehicle) -> ClientLights,
} & BaseLights

export type ServerLights = {
	__index: ServerLights,
	_typesBrightness: { [string]: number },
	_cons: { RBXScriptConnection },
	Headlights: Headlight,

	new: (vehicle: ServerVehicle) -> ServerLights,
	Update: (self: ClientVehicle) -> (),
} & BaseLights

return {}
