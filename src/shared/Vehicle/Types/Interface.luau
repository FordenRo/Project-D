local Vehicle = require(script.Parent.Vehicle)

export type VehicleSpeedometer = {
	__index: VehicleSpeedometer,
	Vehicle: Vehicle.ClientVehicle,
	Instance: Frame & any,
	CurrentUnit: number,
	Units: { { Unit: string, Scaling: number, MaxSpeed: number } },
	_conn: RBXScriptConnection,
	_task: thread,

	new: (vehicle: Vehicle.ClientVehicle, instance: Frame) -> VehicleSpeedometer,
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
	Vehicle: Vehicle.ClientVehicle,
	Instance: ScreenGui & any,
	Speedometer: VehicleSpeedometer,

	new: (vehicle: Vehicle.ClientVehicle) -> VehicleInterface,
	UpdateTires: (self: VehicleInterface) -> (),
	Destroy: (self: VehicleInterface) -> (),
}

return {}
