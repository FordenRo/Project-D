export type SettingType = "Slider" | "Binding" | "Checkbox"
type SettingCategory = "Controls" | "Gameplay" | "Graphics"
type ActionType = "Mouse" | "Controller" | "Keyboard"

export type SettingInfo = {
	Name: string,
	Title: string,
	Description: string?,
	Category: SettingCategory?,
	Folder: string?,
	Type: SettingType,
	Value: any,
	Default: any,
	Max: number?,
	Min: number?,
	Step: number?,
	ActionTypes: { ActionType }?,
}

export type FolderInfo = {
	Name: string,
	Title: string,
	Description: string?,
	Category: SettingCategory?,
	Folder: string?,
}

return {}
