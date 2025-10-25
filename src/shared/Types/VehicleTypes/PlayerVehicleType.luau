local TuneType = require(script.Parent.TuneType)

export type PlayerVehicle = {
	ID: string,
	Name: string,
}

export type PlayerVehicleInfo = {
	Name: string,
	ID: string,
	Tune: TuneType.Tune,
	Fuel: number,
	Mileage: number,
	EngineHealth: number,
	Wheels: { [string]: {
		Wear: number,
		Dirt: number,
	} },
	-- Deformation: { [number]: Vector3 },
	Texture: buffer,
}

return {}
