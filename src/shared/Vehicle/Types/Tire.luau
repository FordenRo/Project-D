local Vehicle = require(script.Parent.Vehicle)
local Wheel = require(script.Parent.Wheel)

export type ClientWheelTire = {
	__index: ClientWheelTire,
	Instance: BasePart,
	Wheel: Wheel.ClientWheel,
	Vehicle: Vehicle.ClientVehicle,
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

	new: (wheel: Wheel.ClientWheel, instance: BasePart) -> ClientWheelTire,
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
	Wheel: Wheel.ServerWheel,
	Vehicle: Vehicle.ServerVehicle,
	WearInstance: BasePart,
	PreviousMaterialData: { [BasePart]: string },
	PreviousSoundsData: { [BasePart]: Sound },
	PreviousSmokesData: { [BasePart]: Smoke },
	PreviousTrailsData: { [BasePart]: { Trail } },
	_Remote: UnreliableRemoteEvent,

	new: (wheel: Wheel.ServerWheel, instance: BasePart) -> ServerWheelTire,
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

return {}
