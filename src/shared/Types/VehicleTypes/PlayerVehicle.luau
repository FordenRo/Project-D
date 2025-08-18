local Tune = require(script.Parent.Tune)

export type PlayerVehicle = {
	ID: string,
	Name: string,
}

export type PlayerVehicleInfo = {
	Name: string,
	ID: string,
	Tune: Tune.Tune,
	Fuel: number,
	Mileage: number,
	EngineHealth: number,
	Wheels: { [string]: {
		Wear: number,
		Dirt: number,
	} },
	Deformation: { [number]: Vector3 },
	Texture: buffer,
}

return {}
