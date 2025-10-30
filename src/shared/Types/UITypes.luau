local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)

export type InterfaceController = {
	Interface: Interface,
	MainWindow: MainWindow,
	Visible: boolean,

	OpenWelcome: (self: InterfaceController) -> (),
	OpenSettings: (self: InterfaceController) -> (),
} & Component.Component

export type Interface = {
	Instance: {
		Buttons: Frame,
		Debug: { FPS: TextLabel } & Frame,
		FPS: TextLabel,
	} & ScreenGui,
	Visible: boolean,

	Destroy: (self: Interface) -> (),
} & Component.Component

export type MainWindow = {
	CurrentTab: string?,
	Visible: boolean,
	Instance: {
		Window: {
			Content: Frame,
			TabBar: {
				Container: Frame,
			} & Frame,
		} & Frame,
		Background: TextButton,
	} & ScreenGui,

	Show: (self: MainWindow, tab: string?) -> (),
	Hide: (self: MainWindow) -> (),
	SetTab: (self: MainWindow, tab: string, skipAnim: boolean?) -> (),
	Destroy: (self: MainWindow) -> (),
}

return {}
