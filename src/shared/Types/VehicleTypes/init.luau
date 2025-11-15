local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local EngineTune = require(script.EngineTune)
local RComponent = require(ReplicatedStorage.Shared.Classes.RComponent)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local SoundData = require(script.SoundData)
local TuneType = require(script.TuneType)

export type IgnitionState = "Off" | "Acc" | "On" | "Starting"

export type VehicleTable = {
	URE: UnreliableRemoteEvent,
	RE: RemoteEvent,
	RF: RemoteFunction,
	Instance: {
		Wheels: Model,
		DriveSeat: {
			Flip: AlignOrientation,
			ProximityPrompt: ProximityPrompt,
		} & VehicleSeat,
		Seats: Model,
		Body: {
			WeightPart: Part,
			Collider: MeshPart,
			Aerodynamics: {
				Drag: Part,
				FDownforce: Part,
				RDownforce: Part,
			} & Model,
			Deformation: {
				EngineBlow: Part,
				BlowSmokeParts: Model,
			} & Model,
			Sounds: Model,
			Lights: {
				Front: Model,
				Rear: Model,
				TurnRight: Model,
				TurnLeft: Model,
				Reverse: Model,
				Brake: Model?,
			} & Model,
		} & Model,
		Misc: Model,
	} & Model,
	Engine: EngineTable,
	Tune: TuneType.Tune,
	Driver: Player?,
	Owner: Player,
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
}

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
	new: (vehicle: ClientVehicle) -> VehicleControllerType?,
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
	-- MeshParts: { MeshPart },
	-- Meshes: { [MeshPart]: EditableMesh },
	-- Textures: { [MeshPart]: EditableImage },
	Acceleration: Vector3,
	Wheels: { ClientWheel },

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
	-- DeformationController: DeformationController,
	CameraController: CameraController,
	Transmission: Transmission,
	BrakeForce: { Front: number, Rear: number },
	PBrakeForce: { Front: number, Rear: number },
	Engine: Engine,
	Interface: VehicleInterface,

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
} & VehicleTable & RComponent.InstancedClient

export type CameraController = {
	Vehicle: ClientVehicle,

	Destroy: (self: CameraController) -> (),
} & Component.Component

export type Engine = {
	Throttle: number,
	Brake: number,
	Clutch: number,
	Tune: EngineTune.Engine,
	Vehicle: ClientVehicle,
	IsOn: boolean,
	IsBroken: boolean,

	Update: (self: Engine, deltaTime: number) -> (),
	AsTable: (self: Engine) -> EngineTable,
} & EngineTable & Component.Component

type CameraMode = "FirstPerson" | "ThirdPerson"
export type InputController = {
	Vehicle: ClientVehicle,
	--- Current mouse position in mouse steering mode
	MousePosition: Vector2,
	--- Is mouse steering mode enabled
	IsMouseSteerOn: boolean,
	--- Current camera mode
	CameraMode: CameraMode,

	--- Fires when camera mode is changed
	CameraModeChanged: Signal.Signal<CameraMode>,

	Destroy: (self: InputController) -> (),
} & Component.Component

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
	Wheels: { ServerWheel },
	Destroy: (self: ServerVehicle) -> (),
} & VehicleTable & RComponent.InstancedServer

export type BaseWheel = {
	Instance: {
		Base: {
			Rotate: HingeConstraint,
		} & Part,
		Arm: {
			Steer: BodyGyro | AlignOrientation,
			SteerAttach0: Attachment,
		} & BasePart,
		Parts: {
			Tire: BasePart,
			BrakeDisk: BasePart,
		} & Model,
		Fixed: Model,
		WheelFixed: Model,
		AV: HingeConstraint,
		BV: HingeConstraint,
		AB: Attachment,
		Collision: Part,
		SuspensionFixed: Model,
		SmokePart: Part,
		TrailAttachmentPart: Part,
		SuspensionGeometry: {
			Hub: Part,
			SpringTop: Part,
			SpringBottom: Part,
			Spring: SpringConstraint,
		} & Model,
		AxleP: {
			AA: Attachment,
		} & Part,
	} & Part,
	Vehicle: VehicleTable,
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
	Material: Enum.Material?,
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
	Sound: {
		PitchEffect: PitchShiftSoundEffect,
	} & Sound,
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
