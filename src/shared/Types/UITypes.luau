local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

export type InterfaceController = {
	Interface: Interface,
	MainWindow: MainWindow,

	new: () -> InterfaceController,
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

	new: (interfaceController: InterfaceController) -> Interface,
	Show: (self: Interface) -> (),
	Hide: (self: Interface) -> (),
	Destroy: (self: Interface) -> (),
}

type TabModule = any & {
	new: (instance: ScrollingFrame) -> TabModule,
	Destroy: (self: TabModule) -> (),
}

export type MainWindow = {
	_trove: Trove.Trove,
	_TabPositions: { [ScrollingFrame]: number },
	_TabModules: { [string]: TabModule },
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

	new: () -> MainWindow,
	Show: (self: MainWindow, tab: string?) -> (),
	Hide: (self: MainWindow) -> (),
	SetTab: (self: MainWindow, tab: string, skipAnim: boolean?) -> (),
	Destroy: (self: MainWindow) -> (),
}

return {}
