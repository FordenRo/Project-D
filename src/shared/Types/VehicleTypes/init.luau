--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local EngineTune = require(script.EngineTune)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local SoundData = require(script.SoundData)
local TuneType = require(script.TuneType)

export type IgnitionState = "Off" | "Acc" | "On" | "Starting"

export type BaseVehicle = {
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
	Tune: TuneType.Tune,
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
	TransmissionMode: TuneType.TransmissionMode,
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
	Acceleration: Vector3,
	--- Mileage in meters
	Mileage: number,
	-- Misc
	Center: CFrame,
	CFrame: CFrame,
	WeightPart: Part,
	TCS: boolean,
	TCSActive: boolean,
	ABS: boolean,
	ABSActive: boolean,
	ESC: boolean,
	ESCActive: boolean,
	CS: boolean,
	CSActive: boolean,
	--- Current ignition state
	IgnitionState: IgnitionState,

	InitializeWheels: (self: BaseVehicle, wheelClass: BaseWheel) -> (),
	_Replicate: (self: BaseVehicle, buf: buffer) -> (),
} & Component.Component

export type DeformationController = {
	Vehicle: ClientVehicle,
	ScratchTexture: EditableImage,

	BlowEngine: (self: DeformationController) -> (),
}

export type DeformationHandler = {
	Vehicle: ServerVehicle,
}

export type SoundTypesHandler = {
	Vehicle: ClientVehicle,

	HandleSounds: (
		self: SoundTypesHandler,
		sounds: { [string]: SoundData.CachedSoundData }
	) -> (),
}

export type SoundController = {
	Vehicle: ClientVehicle,
	Sounds: { [string]: SoundData.CachedSoundData },
	Emitters: { [string]: AudioEmitter },
}

export type VehicleControllerType = {
	DataReceived: (self: VehicleControllerType, ...any) -> ()?,
	-- PacketPrompted: (self: VehicleControllerType, message: string) -> any,
}

export type VehicleControllerImplType = {
	new: (vehicle: ClientVehicle) -> VehicleControllerType,
	Is: (obj: any) -> boolean,
}

export type Transmission = {
	ShiftingUp: boolean,
	ShiftingDown: boolean,
	Vehicle: ClientVehicle,

	Update: (self: Transmission) -> (),
} & Component.Component

export type ClientVehicle = {
	--- Is the vehicle driven by a local player
	IsDriven: boolean,
	--- Is local player sitting in the vehicle
	IsSitting: boolean,
	--- Is the vehicle owned by a local player
	IsOwned: boolean,
	MeshParts: { MeshPart },
	Meshes: { [MeshPart]: EditableMesh },
	Textures: { [MeshPart]: EditableImage },

	-- Events
	--- Fires on Vehicle.Driver change
	DriverChanged: Signal.Signal<Player?>,
	--- Fires on Vehicle.IsSitting change
	SittingChanged: Signal.Signal<>,
	--- Fires on Vehicle.IgnitionState change
	IgnitionStateChanged: Signal.Signal<IgnitionState>,
	--- Fires when a player sits in the vehicle
	PlayerSeated: Signal.Signal<Player, Seat | VehicleSeat>,
	--- Fires when a player leaved the vehicle
	PlayerLeaved: Signal.Signal<Player, Seat | VehicleSeat>,

	InputController: InputController,
	SoundController: SoundController,
	DeformationController: DeformationController,
	CameraController: CameraController,
	Transmission: Transmission,
	BrakeForce: { Front: number, Rear: number },
	PBrakeForce: { Front: number, Rear: number },
	Engine: Engine,
	Interface: VehicleInterface,
	-- Velocity
	_OldVelocity: Vector3,

	InitializeWheels: (self: ClientVehicle) -> (),
	--- Send packet from to given controller of other clients
	SendData: (
		self: ClientVehicle,
		controller: VehicleControllerType,
		...any
	) -> (),
	GetController: (self: ClientVehicle, name: string) -> VehicleControllerType,
	-- Prompt packet from
	-- PromptPacket: (
	-- 	self: ClientVehicle,
	-- 	controller: VehicleControllerType,
	-- 	message: string
	-- ) -> any,
	Leave: (self: ClientVehicle) -> (),
} & BaseVehicle

export type CameraController = {
	Vehicle: ClientVehicle,
	Distance: number,
	Offset: Vector3,
	LookOffset: Vector3,
	Angles: Vector3,
	Bumping: Vector3,
	CameraCFrame: CFrame,

	Destroy: (self: CameraController) -> (),
}

export type Engine = {
	Throttle: number,
	Brake: number,
	Clutch: number,
	Tune: EngineTune.Engine,
	Vehicle: ClientVehicle,
	IsOn: boolean,

	Update: (self: Engine, deltaTime: number) -> (),
	AsTable: (self: Engine) -> EngineTable,
	Destroy: (self: Engine) -> (),
} & EngineTable

export type InputController = {
	Vehicle: ClientVehicle,
	--- Current mouse position in mouse steering mode
	MousePosition: Vector2,
	--- Is mouse steering mode enabled
	IsMouseSteerOn: boolean,
	--- Current camera mode
	CameraMode: "FirstPerson" | "ThirdPerson",

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
	InitializeWheels: (self: ServerVehicle) -> (),
} & BaseVehicle

export type BaseWheel = {
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
}

export type ClientWheel = {
	Vehicle: ClientVehicle,
	Tire: ClientWheelTire,
	BrakeDisk: ClientBrakeDisk,
	CanSteer: number,
	OppositeWheel: BasePart,

	Update: (self: ClientWheel, deltaTime: number) -> (),
	UpdateForces: (
		self: ClientWheel,
		torque: number,
		flywheelEnergy: number
	) -> (),
	Destroy: (self: ClientWheel) -> (),
} & BaseWheel

export type ServerWheel = {
	Vehicle: ServerVehicle,
	Tire: ServerWheelTire,
	BrakeDisk: ServerBrakeDisk,
} & BaseWheel

export type ClientWheelTire = {
	Instance: BasePart,
	Wheel: ClientWheel,
	Vehicle: ClientVehicle,
	Health: number,
	Stress: number,
	Dirt: number,
	SmokePart: Part,
	Material: string,
	Collision: Part & {
		AlignPosition: AlignPosition,
		["#GRAVCOMP"]: VectorForce,
	},
}

export type ServerWheelTire = {
	Instance: BasePart,
	Wheel: ServerWheel,
	Vehicle: ServerVehicle,
}

export type ClientBrakeDisk = {
	Instance: BasePart,
	Vehicle: ClientVehicle,
	Wheel: ClientWheel,
	Temperature: number,
	Sound: Sound & {
		PitchEffect: PitchShiftSoundEffect,
	},
	Volume: number,
}

export type ServerBrakeDisk = {
	Wheel: ServerWheel,
	Instance: BasePart,
}

export type VehicleSpeedometer = {
	Vehicle: ClientVehicle,
	Instance: Frame & any,
}

export type VehicleInterface = {
	Vehicle: ClientVehicle,
	Instance: ScreenGui,
	Speedometer: VehicleSpeedometer,

	Destroy: (self: VehicleInterface) -> (),
}

return {}
