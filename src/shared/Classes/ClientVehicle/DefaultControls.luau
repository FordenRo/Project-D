local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

return {
	--Keyboard Controls
	--Mode Toggles
	ToggleTCS = Enum.KeyCode.T,
	ToggleABS = Enum.KeyCode.Y,
	ToggleCS = Enum.KeyCode.U,
	ToggleTransMode = Enum.KeyCode.M,
	ToggleMouseDrive = Enum.KeyCode.R,

	--Primary Controls
	Throttle = Enum.KeyCode.Up,
	Brake = Enum.KeyCode.Down,
	SteerLeft = Enum.KeyCode.Left,
	SteerRight = Enum.KeyCode.Right,
	Ignition = Enum.KeyCode.F,

	--Secondary Controls
	Throttle2 = Enum.KeyCode.W,
	Brake2 = Enum.KeyCode.S,
	SteerLeft2 = Enum.KeyCode.A,
	SteerRight2 = Enum.KeyCode.D,

	--Manual Transmission
	ShiftUp = Enum.KeyCode.E,
	ShiftDown = Enum.KeyCode.Q,
	Clutch = Enum.KeyCode.LeftShift,

	--Handbrake
	PBrake = Enum.KeyCode.Space,

	--Mouse Controls
	MouseThrottle = Enum.UserInputType.MouseButton1,
	MouseBrake = Enum.UserInputType.MouseButton2,
	MouseClutch = Enum.KeyCode.LeftShift,
	MouseShiftUp = Enum.KeyCode.E,
	MouseShiftDown = Enum.KeyCode.Q,
	MousePBrake = Enum.KeyCode.Space,

	MSteerWidth = 70,
	MSteerDZone = 5,

	--Controller Mapping
	ContlrThrottle = Enum.KeyCode.ButtonR2,
	ContlrBrake = Enum.KeyCode.ButtonL2,
	ContlrSteer = Enum.KeyCode.Thumbstick1,
	ContlrShiftUp = Enum.KeyCode.ButtonY,
	ContlrShiftDown = Enum.KeyCode.ButtonX,
	ContlrClutch = Enum.KeyCode.ButtonR1,
	ContlrPBrake = Enum.KeyCode.ButtonL1,
	ContlrToggleTMode = Enum.KeyCode.DPadUp,
	ContlrToggleTCS = Enum.KeyCode.DPadDown,
	ContlrToggleABS = Enum.KeyCode.DPadRight,
	ContlrToggleCS = Enum.KeyCode.DPadLeft,

	ControlLDZone = 5,
	ControlRDZone = 5,
} :: Types.VehicleControls
