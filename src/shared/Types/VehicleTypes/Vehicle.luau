local Controls = require(script.Parent.Controls)
local SoundData = require(script.Parent.SoundData)
local Tune = require(script.Parent.Tune)

export type BaseVehicle = {
	__index: BaseVehicle,
	_Remote: UnreliableRemoteEvent,
	Instance: Instance & {
		Wheels: Model & any,
		DriveSeat: VehicleSeat & {
			Flip: AlignOrientation,
			ProximityPrompt: ProximityPrompt,
		},
		Seats: Model,
		Body: Model & {
			WeightPart: Part,
			Collider: MeshPart,
			Aerodynamics: Model & {
				Drag: Part,
				FDownforce: Part,
				RDownforce: Part,
			},
			Deformation: Model & {
				EngineBlow: Part,
				BlowSmokeParts: Model,
			},
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
	Engine: EngineTable,
	Wheels: { BaseWheel },
	Tune: Tune.Tune,
	Starting: boolean,
	Driver: Player?,
	Passengers: { [VehicleSeat | Seat]: Player },
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
	--- Mileage in meters
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
	_Replicate: (self: BaseVehicle, buf: buffer) -> (),
}

export type DeformationController = {
	__index: DeformationController,
	Vehicle: ClientVehicle,
	ScratchTexture: EditableImage,

	new: (vehicle: ClientVehicle) -> DeformationController,
	BlowEngine: (self: DeformationController) -> (),
}

export type SoundTypesHandler = {
	__index: SoundTypesHandler,
	_UpdateBOV: boolean,
	_PrevBoostTurbo: number,
	_LastBOV: number,
	Vehicle: ClientVehicle,

	new: (vehicle: ClientVehicle) -> SoundTypesHandler,
	HandleSounds: (self: SoundTypesHandler, sounds: { [string]: SoundData.CachedSoundData }) -> (),
}

export type SoundController = {
	__index: SoundController,
	Vehicle: ClientVehicle,
	Sounds: { [string]: SoundData.CachedSoundData },

	new: (vehicle: ClientVehicle) -> SoundController,
}

export type ClientVehicle = {
	__index: ClientVehicle,
	_cons: { RBXScriptConnection },
	_task: thread,
	_MaxSpin: number,
	_DrivenChangedEvent: BindableEvent,
	IsDriven: boolean,
	MeshParts: { MeshPart },
	Meshes: { [MeshPart]: EditableMesh },
	Textures: { [MeshPart]: EditableImage },
	Lights: ClientLights,
	DrivenChanged: RBXScriptSignal<boolean>,
	InputController: InputController,
	SoundController: SoundController,
	DeformationController: DeformationController,
	CameraController: CameraController,
	BrakeForce: { Front: number, Rear: number },
	PBrakeForce: { Front: number, Rear: number },
	Engine: Engine,
	Controls: Controls.VehicleControls,
	Interface: VehicleInterface,
	-- Transmission
	_ShiftUp: boolean,
	_ShiftDown: boolean,
	_DriveWheelSpeed: number,
	-- Velocity
	_OldVelocity: Vector3,

	new: (instance: Instance) -> ClientVehicle,
	InitializeWheels: (self: ClientVehicle) -> (),
	Leave: (self: ClientVehicle) -> (),
	Destroy: (self: ClientVehicle) -> (),
} & BaseVehicle

export type CameraController = {
	_LastCameraRotation: number,
	_CharacterVisible: boolean,
	Vehicle: ClientVehicle,
	Distance: number,
	Offset: Vector3,
	LookOffset: Vector3,
	Angles: Vector3,
	Bumping: Vector3,
	FirstPerson: boolean,
	CameraCFrame: CFrame,

	new: (vehicle: ClientVehicle) -> CameraController,
	Destroy: (self: CameraController) -> (),
}

export type Engine = {
	__index: Engine,
	_LastOnTime: number,
	_LastOffTime: number,
	_RevLimiting: boolean,
	_GoalRPM: number,
	_FuelSupply: number,
	Throttle: number,
	Clutch: number,
	Vehicle: ClientVehicle,

	new: (vehicle: ClientVehicle) -> Engine,
	Update: (self: Engine, deltaTime: number) -> (),
	AsTable: (self: Engine) -> EngineTable,
	Destroy: (self: Engine) -> (),
} & EngineTable

export type InputController = {
	__index: InputController,
	_cons: { RBXScriptConnection },
	_RawThrottle: number,
	_RawBrake: number,
	_RawClutch: number,
	_RawSteering: number,
	Vehicle: ClientVehicle,
	MousePosition: Vector2,
	MouseSteerOn: boolean,

	new: (vehicle: ClientVehicle) -> InputController,
	Destroy: (self: InputController) -> (),
}

export type EngineTable = {
	Health: number,
	Temperature: number,
	DriveshaftStress: number,

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
			Steer: BodyGyro | AlignOrientation,
			SteerAttach0: Attachment,
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
		Collision: Part,
		SuspensionFixed: Model,
		SmokePart: Part,
		TrailAttachmentPart: Part,
		AxleP: Part & {
			AA: Attachment,
		},
	},
	Vehicle: BaseVehicle,
	BrakeDisk: ClientBrakeDisk | ServerBrakeDisk,
	IsRight: boolean,
	IsFront: boolean,
	IsDriven: boolean,

	new: (vehicle: BaseVehicle, instance: BasePart) -> BaseWheel,
}

export type ClientWheelSharedData = {
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

	new: (vehicle: ClientVehicle, wheel: BasePart) -> ClientWheel,
	Update: (self: ClientWheel, deltaTime: number, data: ClientWheelSharedData) -> (),
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
	_RE: UnreliableRemoteEvent,
	_task: thread,
	_cons: { RBXScriptConnection },
	_LastMaterial: string,
	Instance: BasePart,
	WearInstance: BasePart,
	DirtInstance: BasePart,
	WheelDirtInstances: { BasePart },
	Wheel: ClientWheel,
	Vehicle: ClientVehicle,
	Health: number,
	Stress: number,
	Dirt: number,
	RayParams: RaycastParams,
	Material: string,
	SmokePart: Part,
	Collision: Part & {
		AlignPosition: AlignPosition,
		["#GRAVCOMP"]: VectorForce,
	},
	TrailAttachmentPart: Part & {
		TrailAttachment1: Attachment,
		TrailAttachment2: Attachment,
		AlignOrientation: AlignOrientation,
	},
	CurrentSound: Sound?,
	CurrentEmitter: ParticleEmitter?,
	CurrentTrail: { Trail }?,
	Sounds: { [string]: Sound },
	Emitters: { [string]: ParticleEmitter },
	Trails: { [string]: { Trail } },
	TrailStress: number,

	new: (wheel: ClientWheel, instance: BasePart) -> ClientWheelTire,
	Destroy: (self: ClientWheelTire) -> (),
}

export type ServerWheelTire = {
	__index: ServerWheelTire,
	_RE: UnreliableRemoteEvent,
	Instance: BasePart,
	Wheel: ServerWheel,
	Vehicle: ServerVehicle,

	new: (wheel: ServerWheel, instance: BasePart) -> ServerWheelTire,
}

export type ClientBrakeDisk = {
	__index: ClientBrakeDisk,
	_cons: { RBXScriptConnection },
	_task: thread,
	_startColor: Color3,
	_RE: UnreliableRemoteEvent,
	Instance: BasePart,
	Vehicle: ClientVehicle,
	Wheel: ClientWheel,
	Temperature: number,
	Sound: Sound & {
		PitchEffect: PitchShiftSoundEffect,
	},
	Volume: number,

	new: (wheel: ClientWheel, instance: BasePart) -> ClientBrakeDisk,
	Destroy: (self: ClientBrakeDisk) -> (),
}

export type ServerBrakeDisk = {
	__index: ServerBrakeDisk,
	_conn: RBXScriptConnection,
	_RE: UnreliableRemoteEvent,
	Wheel: ServerWheel,
	Instance: BasePart,

	new: (wheel: ServerWheel, instance: BasePart) -> ServerBrakeDisk,
	Destroy: (self: ServerBrakeDisk) -> (),
}

export type VehicleSpeedometer = {
	__index: VehicleSpeedometer,
	_conn: RBXScriptConnection,
	_task: thread,
	Vehicle: ClientVehicle,
	Instance: Frame & any,
	CurrentUnit: number,
	Units: {
		{
			Unit: string,
			Scaling: number,
			MileageScaling: number,
			MaxSpeed: number,
		}
	},

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

type VISlider = Frame & { Fill: Frame }
export type VehicleInterface = {
	__index: VehicleInterface,
	_cursorTransparency: number,
	_cons: { RBXScriptConnection },
	Vehicle: ClientVehicle,
	Instance: ScreenGui & {
		Cursor: Frame,
		Speedometer: Frame,
		Debug: Frame & {
			Info: Frame & {
				Health: TextLabel,
				Temperature: TextLabel,
			},
			Car: CanvasGroup & {
				Tires: Frame,
				Brakes: Frame,
				Driveshaft: CanvasGroup & { Front: Frame, Rear: Frame },
			},
		},
		Inputs: Frame & {
			Steering: Frame & { Left: VISlider, Right: VISlider },
			Pedals: Frame & { Throttle: VISlider, Brake: VISlider, Clutch: VISlider },
		},
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

export type ClientLights = {
	__index: ClientLights,
	_cons: { RBXScriptConnection },
	_RE: RemoteEvent,
	_typesBrightness: { [string]: number },
	_lastToggleTime: number,
	Vehicle: ClientVehicle,
	Headlights: { [string]: { Headlight } },
	State: "Low" | "High" | "Off",
	TurnState: "Left" | "Right" | "Both" | "Off",

	new: (vehicle: ClientVehicle) -> ClientLights,
	ToggleLights: (self: ClientLights) -> (),
	ToggleTurnState: (self: ClientLights, state: "Left" | "Right" | "Both") -> (),
	Destroy: (self: ClientLights) -> (),
}

return {}
