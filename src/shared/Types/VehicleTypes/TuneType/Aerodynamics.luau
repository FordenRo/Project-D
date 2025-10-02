export type Type = {
	--- Volume of wind at 200 km/h
	AeroWindVolume: number,
	--- Volume of body at 200 km/h
	AeroBodyVolume: number,
	--- Drag coefficient of the car
	AeroDragCoeff: number,
	--- Front downforce in kgf at 200 km/h
	AeroFDownforce: number,
	--- Rear downforce in kgf at 200 km/h
	AeroRDownforce: number,
	--- How much drag is reduced while in slipstream
	AeroSlipstreamFactor: number,
	--- Maximum amount of time you can be behind a car to gain slipstream
	AeroSlipstreamTime: number,
}

return {}
