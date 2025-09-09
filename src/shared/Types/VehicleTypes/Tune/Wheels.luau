export type Type = {
	--- Front wheel camber in degrees
	FCamber: number,
	--- Rear wheel camber in degrees
	RCamber: number,
	--- Front wheel caster in degrees
	FCaster: number,
	--- Rear wheel caster in degrees
	RCaster: number,
	--- Front wheel toe in degrees
	FToe: number,
	--- Rear wheel toe in degrees
	RToe: number,

	--- Front wheel weight in kg
	FWheelWeight: number,
	--- Rear wheel weight in kg
	RWheelWeight: number,

	--- Size of structural members (larger = MORE STABLE / carry more weight)
	AxleSize: number,
	--- Density of structural members
	AxleDensity: number,
	--- Density of suspension joints, only applies to custom suspension. (0 makes them massless)
	CustomSuspensionDensity: number,

	--- Total brake force in kgf
	BrakeForce: number,
	--- Brake bias towards the front (1 = Front, 0 = Rear, .5 = 50/50)
	BrakeBias: number,
	--- Handbrake force in kgf
	PBrakeForce: number,
	--- Handbrake bias towards the front (1 = Front, 0 = Rear, .5 = 50/50)
	PBrakeBias: number,
	--- Engine braking force at redline in kgf
	EBrakeForce: number,
	--- Set to false if you don't want the car to apply the parking brake when exiting
	ExitBrake: boolean,

	--- AWD ONLY, "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.
	TorqueVector: number,

	--[[
		Option for a limited slip differential in percent (LuaInt)

		Higher values yield more wheel lock-up under throttle, more stability

		Front wheels, only if driven
	]]
	FDiffPower: number,
	--[[
		Option for a limited slip differential in percent (LuaInt)

		Higher values yield more wheel lock-up when off throttle, more stability

		Front wheels, only if driven
	]]
	FDiffCoast: number,
	--[[
		Option for a limited slip differential in percent (LuaInt)

		Higher values will make the wheels generally lock up faster in any environment

		Front wheels, only if driven
	]]
	FDiffPreload: number,
	--[[
		Option for a limited slip differential in percent (LuaInt)

		Higher values yield more wheel lock-up under throttle, more stability

		Rear wheels, only if driven
	]]
	RDiffPower: number,
	--[[
		Option for a limited slip differential in percent (LuaInt)

		Higher values yield more wheel lock-up when off throttle, more stability

		Rear wheels, only if driven
	]]
	RDiffCoast: number,
	--[[
		Option for a limited slip differential in percent (LuaInt)

		Higher values will make the wheels generally lock up faster in any environment

		Rear wheels, only if driven
	]]
	RDiffPreload: number,
}

return {}
