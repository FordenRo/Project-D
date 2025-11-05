export type Type = {
	--- Spring Force in kgf/mm. (To convert from Roblox stiffness, divide Roblox stiffness by 447.18324)
	FSusStiffness: number,
	--- Spring Damping in thousands of kg/s. (To convert from Roblox damping, divide Roblox damping by 45.6)
	FSusDamping: number,
	--- Sway Bar Force in kgf/mm (more = less roll)
	FSwayBar: number,

	--- Base spring height (in studs)
	FSusLength: number,
	--- Adds to base spring height (in studs)
	FPreCompress: number,
	--- Max Extension Travel (in studs)
	FExtensionLim: number,
	--- Max Compression Travel (in studs)
	FCompressLim: number,

	--- Spring Force in kgf/mm. (To convert from Roblox stiffness, divide Roblox stiffness by 447.18324)
	RSusStiffness: number,
	--- Spring Damping in thousands of kg/s. (To convert from Roblox damping, divide Roblox damping by 45.6)
	RSusDamping: number,
	--- Sway Bar Force in kgf/mm (more = less roll)
	RSwayBar: number,

	--- Base spring height (in studs)
	RSusLength: number,
	--- Adds to base spring height (in studs)
	RPreCompress: number,
	--- Max Extension Travel (in studs)
	RExtensionLim: number,
	--- Max Compression Travel (in studs)
	RCompressLim: number,

	--- Suspension visibility
	SusVisible: boolean,
	--- Springs visibility
	SpringsVisible: boolean,
	--- Radius of spring coils
	SusRadius: number,
	--- Thickness of spring coils
	SusThickness: number,
	--- Springs color
	SusColor: BrickColor,
	--- Spring coil count
	SusCoilCount: number,
}

return {}
