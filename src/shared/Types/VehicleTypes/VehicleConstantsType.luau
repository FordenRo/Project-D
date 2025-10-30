type HapticsType = "Controller" | "Mobile" | "Both" | "None"

export type VehicleConstants = {
	--- Desired gravitational force in Roblox units. (35 is the default. Set to 0 to use workspace.Gravity instead)
	GravComp: number,
	--- Device haptics
	Haptics: HapticsType,
	--- Makes the weight brick visible
	WBVisible: boolean,
}

return {}
