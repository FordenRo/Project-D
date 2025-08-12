local DefaultSettings = require(script.Parent.DefaultSettings)

type SettingType = "Slider"
type SettingCategory = "Controls" | "Gameplay" | "Graphics"

type SettingInfo = {
	Name: string,
	Category: SettingCategory,
	Description: string,
	Type: SettingType,
	Min: number?,
	Max: number?,
	Step: number?,
}

export type SettingsInfo = {
	[keyof<typeof(DefaultSettings)>]: SettingInfo,
}

local Info: SettingsInfo = {
	MSteerSensivity = {
		Name = "Mouse Steering Sensivity",
		Category = "Controls",
		Description = "The speed of cursor in mouse steering mode",
		Type = "Slider",
	},
	MSteerDZone = {
		Name = "Mouse Steering Deadzone",
		Category = "Controls",
		Description = "Deadzone in mouse steering mode",
		Type = "Slider",
	},
	MSteerCursorY = {
		Name = "Mouse Steering Cursor Y",
		Category = "Controls",
		Description = "The Y of cursor in mouse steering mode",
		Type = "Slider",
	},
	MSteerWidth = {
		Name = "Mouse Steering Width",
		Category = "Controls",
		Description = "Steering width in mouse steering mode",
	},
}

return Info
