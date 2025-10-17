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
	Instance: ScreenGui & {
		Buttons: Frame,
		Debug: Frame & { FPS: TextLabel },
		FPS: TextLabel,
	},
	Visible: boolean,

	Destroy: (self: Interface) -> (),
} & Component.Component

export type MainWindow = {
	CurrentTab: string?,
	Visible: boolean,
	Instance: ScreenGui & {
		Window: Frame & {
			Content: Frame,
			TabBar: Frame & {
				Container: Frame,
			},
		},
		Background: TextButton,
	},

	Show: (self: MainWindow, tab: string?) -> (),
	Hide: (self: MainWindow) -> (),
	SetTab: (self: MainWindow, tab: string, skipAnim: boolean?) -> (),
	Destroy: (self: MainWindow) -> (),
}

return {}
