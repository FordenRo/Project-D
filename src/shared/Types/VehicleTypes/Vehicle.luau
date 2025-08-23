local Controls = require(script.Parent.Controls)
local Tune = require(script.Parent.Tune)

export type BaseVehicle = {
	__index: BaseVehicle,
	_Remote: UnreliableRemoteEvent,
	Instance: Instance & {
		Wheels: Model & any,
		DriveSeat: VehicleSeat & {
			Flip: AlignOrientation,
		},
		Body: Model & {
			WeightPart: Part,
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
		Misc: Model,
	},
	Plugins: { [string]: any },
	Wheels: { BaseWheel },
	Tune: Tune.Tune,
	Lights: BaseLights,
	Starting: boolean,
	Occupant: Player?,
	Dirt: number,
	Fuel: number,
	ID: string,
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
	-- Inputs
	Throttle: number,
	Brake: number,
	Steering: number,
	PBrake: boolean,
	-- Velocity
	Velocity: Vector3,
	AngularVelocity: Vector3,
	AverageRotSpeed: number,
	Acceleration: Vector3,
	Mileage: number,
	-- Misc
	Center: CFrame,
	WeightPart: Part,
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
	GetCenter: (self: BaseVehicle) -> CFrame,
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
	_MaxSpin: number,
	InputController: InputController,
	DeformationController: DeformationController,
	BrakeForce: { Front: number, Rear: number },
	PBrakeForce: { Front: number, Rear: number },
	Engine: Engine,
	Controls: Controls.VehicleControls,
	Interface: VehicleInterface,
	-- Transmission
	_ShiftUp: boolean,
	_ShiftDown: boolean,
	_ClutchPressing: boolean,
	_DriveWheelSpeed: number,
	-- Velocity
	_OldVelocity: Vector3,

	new: (instance: Instance) -> ClientVehicle,
	InitializeWheels: (self: ClientVehicle) -> (),
	Destroy: (self: ClientVehicle) -> (),
} & BaseVehicle

export type Engine = {
	__index: Engine,
	_LastOnTime: number,
	_LastOffTime: number,
	Vehicle: ClientVehicle,
	Broken: boolean,
	GoalRPM: number,
	FuelSuppy: number,
	Health: number,
	Temperature: number,

	Boost: number,
	BoostTurbo: number,
	BoostSuper: number,

	Horsepower: number,
	HpNatural: number,
	HpElectric: number,
	HpTurbo: number,
	HpSuper: number,
	HpBoosted: number,

	Torque: number,
	TqNatural: number,
	TqElectric: number,
	TqTurbo: number,
	TqSuper: number,
	TqBoosted: number,

	new: (vehicle: ClientVehicle) -> Engine,
	Update: (self: Engine, deltaTime: number) -> (),
	Destroy: (self: Engine) -> (),
}

export type InputController = {
	__index: InputController,
	_cons: { RBXScriptConnection },
	_RawThrottle: number,
	_RawBrake: number,
	Vehicle: ClientVehicle,
	Throttle: number,
	Brake: number,
	Clutch: boolean,
	MousePosition: Vector2,
	MouseSteerOn: boolean,
	Steering: number,

	new: (vehicle: ClientVehicle) -> InputController,
	Destroy: (self: InputController) -> (),
}

export type ServerVehicle = {
	__index: ServerVehicle,

	new: (instance: Instance) -> ServerVehicle,
	InitializeWheels: (self: ServerVehicle) -> (),
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
		AV: HingeConstraint,
		BV: HingeConstraint,
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
	IsRight: boolean,
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
	_WheelSpeeds: { number },
	Vehicle: ClientVehicle,
	Tire: ClientWheelTire,
	BrakeDisk: ClientBrakeDisk,
	CanSteer: number,
	OppositeWheel: BasePart,
	Trackers: { ABS: number, TCS: number, ESC: number },

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
} & BaseWheel

export type ClientWheelTire = {
	__index: ClientWheelTire,
	_Remote: UnreliableRemoteEvent,
	_deltaTime: number,
	Instance: BasePart,
	Wheel: ClientWheel,
	Vehicle: ClientVehicle,
	Temperature: number,
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
	Destroy: (self: ClientWheelTire) -> (),
}

export type ServerWheelTire = {
	__index: ServerWheelTire,
	_Remote: UnreliableRemoteEvent,
	Instance: BasePart,
	Wheel: ServerWheel,
	Vehicle: ServerVehicle,
	WearInstance: BasePart,
	DirtInstance: BasePart,
	PreviousMaterialData: { [BasePart]: string },
	PreviousSoundsData: { [BasePart]: Sound },
	PreviousSmokesData: { [BasePart]: Smoke },
	PreviousTrailsData: { [BasePart]: { Trail } },

	new: (wheel: ServerWheel, instance: BasePart) -> ServerWheelTire,
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
	Destroy: (self: ClientBrakeDisk) -> (),
} & BaseBrakeDisk

export type ServerBrakeDisk = {
	__index: ServerBrakeDisk,
	_conn: RBXScriptConnection,
	Wheel: ServerWheel,

	new: (wheel: ServerWheel, instance: BasePart) -> ServerBrakeDisk,
	Destroy: (self: ServerBrakeDisk) -> (),
} & BaseBrakeDisk

export type VehicleSpeedometer = {
	__index: VehicleSpeedometer,
	_conn: RBXScriptConnection,
	_task: thread,
	Vehicle: ClientVehicle,
	Instance: Frame & any,
	CurrentUnit: number,
	Units: { { Unit: string, Scaling: number, MaxSpeed: number } },

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
	_LastSpawn: number,
	Vehicle: ClientVehicle,
	Parent: GuiObject,
	Effects: { EffectFrame },

	new: (self: SpeedEffect, vehicle: ClientVehicle, part: GuiObject) -> SpeedEffect,
}

export type VehicleInterface = {
	__index: VehicleInterface,
	_cursorTransparency: number,
	_conn: RBXScriptConnection,
	Vehicle: ClientVehicle,
	Instance: ScreenGui & {
		Cursor: Frame,
		Speedometer: Frame,
		Tires: Frame,
	},
	Speedometer: VehicleSpeedometer,
	SpeedEffect: SpeedEffect,
	CursorInstance: Frame,

	new: (vehicle: ClientVehicle) -> VehicleInterface,
	Destroy: (self: VehicleInterface) -> (),
}

export type Headlight = {
	__index: Headlight,
	_conn: RBXScriptConnection,
	_task: thread,
	_lightBrightness: number,
	_currentBrightness: number,
	Instance: BasePart,
	Light: Light?,
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
	TurnState: "Off" | "Left" | "Right" | "Both",

	Destroy: (self: BaseLights) -> (),
}

export type ClientLights = {
	__index: ClientLights,
	_cons: { RBXScriptConnection },

	new: (vehicle: ClientVehicle) -> ClientLights,
} & BaseLights

export type ServerLights = {
	__index: ServerLights,
	_typesBrightness: { [string]: number },
	_cons: { RBXScriptConnection },
	Headlights: Headlight,

	new: (vehicle: ServerVehicle) -> ServerLights,
} & BaseLights

return {}
