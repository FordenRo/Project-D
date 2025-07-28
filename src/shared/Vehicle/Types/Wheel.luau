local Vehicle = require(script.Parent.Vehicle)

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
	Vehicle: Vehicle.ClientVehicle,
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

	new: (vehicle: Vehicle.ClientVehicle, wheel: BasePart) -> ClientWheel,
	Update: (self: ClientWheel, data: ClientWheelSharedData) -> (),
	Destroy: (self: ClientWheel) -> (),
}

export type ServerWheel = {
	__index: ServerWheel,
	Vehicle: Vehicle.ServerVehicle,
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

	new: (vehicle: Vehicle.ServerVehicle, instance: BasePart) -> ServerWheel,
	Initialize: (self: ServerWheel) -> (),
}

return {}
