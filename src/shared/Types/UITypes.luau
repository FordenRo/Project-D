local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

export type InterfaceController = {
	Interface: Interface,
	MainWindow: MainWindow,

	Show: (self: InterfaceController) -> (),
	Hide: (self: InterfaceController) -> (),
	OpenWelcome: (self: InterfaceController) -> (),
	OpenSettings: (self: InterfaceController) -> (),
}

export type Interface = {
	_trove: Trove.Trove,
	InterfaceController: InterfaceController,
	Instance: ScreenGui & {
		Buttons: Frame,
		Debug: Frame & { FPS: TextLabel },
		FPS: TextLabel,
	},

	Show: (self: Interface) -> (),
	Hide: (self: Interface) -> (),
	Destroy: (self: Interface) -> (),
}

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
