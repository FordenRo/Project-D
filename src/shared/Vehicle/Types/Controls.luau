export type VehicleControls = {
	--Keyboard Controls
	--Mode Toggles
	ToggleTCS: Enum.KeyCode,
	ToggleABS: Enum.KeyCode,
	ToggleCS: Enum.KeyCode,
	ToggleTransMode: Enum.KeyCode,
	ToggleMouseDrive: Enum.KeyCode,

	--Primary Controls
	Throttle: Enum.KeyCode,
	Brake: Enum.KeyCode,
	SteerLeft: Enum.KeyCode,
	SteerRight: Enum.KeyCode,
	Ignition: Enum.KeyCode,
	Leave: Enum.KeyCode,

	--Secondary Controls
	Throttle2: Enum.KeyCode,
	Brake2: Enum.KeyCode,
	SteerLeft2: Enum.KeyCode,
	SteerRight2: Enum.KeyCode,

	--Manual Transmission
	ShiftUp: Enum.KeyCode,
	ShiftDown: Enum.KeyCode,
	Clutch: Enum.KeyCode,

	--Handbrake
	PBrake: Enum.KeyCode,

	--Mouse Controls
	MouseThrottle: Enum.UserInputType | Enum.KeyCode,
	MouseBrake: Enum.UserInputType | Enum.KeyCode,
	MouseClutch: Enum.KeyCode,
	MouseShiftUp: Enum.KeyCode,
	MouseShiftDown: Enum.KeyCode,
	MousePBrake: Enum.KeyCode,

	MSteerWidth: number,
	MSteerDZone: number,

	--Controller Mapping
	ContlrThrottle: Enum.KeyCode,
	ContlrBrake: Enum.KeyCode,
	ContlrSteer: Enum.KeyCode,
	ContlrShiftUp: Enum.KeyCode,
	ContlrShiftDown: Enum.KeyCode,
	ContlrClutch: Enum.KeyCode,
	ContlrPBrake: Enum.KeyCode,
	ContlrToggleTMode: Enum.KeyCode,
	ContlrToggleTCS: Enum.KeyCode,
	ContlrToggleABS: Enum.KeyCode,
	ContlrToggleCS: Enum.KeyCode,

	ControlLDZone: number,
	ControlRDZone: number,
}

return {}
