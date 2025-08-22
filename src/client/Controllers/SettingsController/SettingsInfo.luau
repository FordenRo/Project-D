export type SettingType = "Slider" | "Binding" | "Checkbox"
type SettingCategory = "Controls" | "Gameplay" | "Graphics"

export type DefaultProperties = {
	Title: string,
	Description: string?,
	Category: SettingCategory,
	Type: SettingType,
}
export type SliderProperties = {
	Max: number?,
	Min: number?,
	Step: number?,
	Default: number?,
	Value: number,
} & DefaultProperties
export type BindingProperties = {
	Default: { [index<BindingProperties, "ActionTypes">]: Enum.KeyCode },
	Value: { [index<BindingProperties, "ActionTypes">]: Enum.KeyCode },
	ActionTypes: { "Mouse" | "Controller" | "Keyboard" },
} & DefaultProperties
export type CheckboxProperties = {
	Value: boolean,
} & DefaultProperties

local Info = {
	MSteerSensivity = {
		Title = "Mouse Steering Sensivity",
		Category = "Controls",
		Description = "The speed of cursor in mouse steering mode",
		Type = "Slider",
		Default = 1,
		Min = 0.05,
		Max = 4,
	} :: SliderProperties,
	MSteerDZone = {
		Title = "Mouse Steering Deadzone",
		Category = "Controls",
		Description = "Deadzone in mouse steering mode",
		Type = "Slider",
		Default = 0,
		Max = 0.9,
	} :: SliderProperties,
	MSteerCursorY = {
		Title = "Mouse Steering Cursor Y",
		Category = "Controls",
		Description = "The Y of cursor in mouse steering mode",
		Type = "Slider",
		Default = 0.2,
		Max = 1,
	} :: SliderProperties,
	MSteerWidth = {
		Title = "Mouse Steering Width",
		Category = "Controls",
		Description = "Steering width in mouse steering mode",
		Type = "Slider",
		Default = 0.7,
		Min = 0.1,
		Max = 1,
	} :: SliderProperties,
}

return Info
