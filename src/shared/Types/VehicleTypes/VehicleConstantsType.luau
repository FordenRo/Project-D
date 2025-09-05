type FlipType = "New" | "Old"
type HapticsType = "Controller" | "Mobile" | "Both" | "None"

export type VehicleConstants = {
	--- Desired gravitational force in Roblox units. (35 is the default. Set to 0 to use workspace.Gravity instead)
	GravComp: number,
	--- "New" uses AlignOrientation, "Old" uses BodyGyro. This really only needs to be changed for plugin compatibility.
	FlipType: FlipType,
	--- Device haptics
	Haptics: HapticsType,
	--- Makes the weight brick visible
	WBVisible: boolean,
}

return {}
