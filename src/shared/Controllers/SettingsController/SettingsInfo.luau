export type SettingType = "Slider" | "Binding" | "Checkbox"
type SettingCategory = "Controls" | "Gameplay" | "Graphics"
type ActionType = "Mouse" | "Controller" | "Keyboard"

export type SettingInfo = {
	Title: string,
	Description: string?,
	Category: SettingCategory,
	Type: SettingType,
	Value: any,
	Default: any,
	Max: number?,
	Min: number?,
	Step: number?,
	ActionTypes: { ActionType }?,
}

local Info = {
	ShowFPS = {
		Title = "Show Framerate",
		Category = "Gameplay",
		Description = "Show game framerate in bottom left corner of screen",
		Type = "Checkbox",
		Default = false,
	},
	OneHandedSteering = {
		Title = "One Handed Steering",
		Category = "Gameplay",
		Description = "Only one hand will be on the steering wheel.",
		Type = "Checkbox",
		Default = false,
	},
	ControllerDZone = {
		Title = "Controller Deadzone",
		Category = "Controls",
		Type = "Slider",
		Default = 0,
		Max = 0.9,
	},
	MSteerSensivity = {
		Title = "Mouse Steering Sensivity",
		Category = "Controls",
		Description = "The speed of cursor in mouse steering mode",
		Type = "Slider",
		Default = 1,
		Min = 0.05,
		Max = 4,
	},
	MSteerDZone = {
		Title = "Mouse Steering Deadzone",
		Category = "Controls",
		Description = "Deadzone in mouse steering mode",
		Type = "Slider",
		Default = 0,
		Max = 0.9,
	},
	MSteerCursorY = {
		Title = "Mouse Steering Cursor Y",
		Category = "Controls",
		Description = "The Y of cursor in mouse steering mode",
		Type = "Slider",
		Default = 0.2,
		Max = 1,
	},
	MSteerWidth = {
		Title = "Mouse Steering Width",
		Category = "Controls",
		Description = "Steering width in mouse steering mode",
		Type = "Slider",
		Default = 0.7,
		Min = 0.1,
		Max = 1,
	},
} :: { [string]: SettingInfo }

return Info
