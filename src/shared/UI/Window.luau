local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

local Tab = { set = {} }
Tab.__extends = Component

export type Tab = {
	Name: string,
	Parent: Window,
	Content: Frame & any,
	Button: { Title: TextLabel } & TextButton,
	Active: boolean,
	Activated: Signal.Signal<>,
	Deactivated: Signal.Signal<>,

	Destroy: (self: Tab) -> (),
} & Component.Component

type TabImpl = { trove: Trove.Trove } & Tab

function Tab.new(content: Frame, button: TextButton, parent: Window): Tab
	local self: TabImpl = Component(Tab) :: any

	self.Parent = parent
	self.Content = content
	self.Button = button :: any
	self.Name = self.Button.Name
	self.Active = false

	self.Activated = Signal.new()
	self.Deactivated = Signal.new()

	self.trove = Trove.new()
	self.trove:Connect(self.Button.Activated, function() self.Active = true end)

	return self
end

function Tab.set.Active(self: TabImpl, active: boolean)
	if self.Active == active then return end

	self:RawSet("Active", active)
	if active then
		self.Activated:Fire()
	else
		self.Deactivated:Fire()
	end
	self.Content.Visible = active
	self.Button.Title.TextTransparency = active and 0 or 0.5
	self.Button.Interactable = not active
end

function Tab.Destroy(self: TabImpl) self.trove:Destroy() end

local Window = { get = {}, set = {} }
Window.__extends = Component

export type Window = {
	Instance: {
		Window: {
			Header: {
				Title: TextLabel?,
				TabBar: ({
					Container: Frame & any,
					Line: Frame,
					Selection: Frame,
				} & Frame)?,
			} & Frame,
			Content: ScrollingFrame & any,
			Footer: (Frame & any)?,
		} & TextButton,
		Background: TextButton?,
	} & ScreenGui,
	TabChanged: Signal.Signal<Tab>,
	ActiveTab: Tab?,
	Tabs: { Tab }?,
	Buttons: { TextButton }?,
	Visible: boolean,

	GetTab: (self: Window, name: string) -> Tab,
	GetButton: (self: Window, name: string) -> TextButton,
	GetButtonPressedSignal: (
		self: Window,
		name: string
	) -> RBXScriptSignal<InputObject, number>,
	Destroy: (self: Window) -> (),
} & Component.Component

type WindowImpl = { trove: Trove.Trove } & Window

function Window.new(instance: ScreenGui): Window
	local self: WindowImpl = Component(Window) :: any

	self.Instance = instance :: any
	self.TabChanged = Signal.new()

	self.trove = Trove.new()
	self.trove:AttachToInstance(self.Instance)

	InitializeTabs(self)
	InitializeButtons(self)

	return self
end

function Window.get.Visible(self: WindowImpl) return self.Instance.Enabled end

function Window.set.Visible(self: WindowImpl, visible: boolean)
	self.Instance.Enabled = visible
end

function Window.set.ActiveTab(self: WindowImpl, tab: Tab)
	assert(self.Tabs, `{self.Instance.Name} don't have tabs`)

	self:RawSet("ActiveTab", tab)
	tab.Active = true
	for _, v in self.Tabs do
		if v == tab :: any then continue end

		v.Active = false
	end
	self.TabChanged:Fire(tab)
end

function InitializeTabs(self: WindowImpl)
	local tabBar = self.Instance.Window.Header.TabBar
	if not tabBar then return end

	local tabs = {}
	for _, button in tabBar.Container:GetChildren() do
		if not button:IsA("TextButton") then continue end

		local content =
			self.Instance.Window.Content:FindFirstChild(button.Name .. "Tab")
		assert(
			content,
			`{button.Name}Tab in {self.Instance.Name} content not found!`
		)
		assert(content:IsA("Frame"), `{button.Name}Tab must be Frame`)

		local tab = Tab.new(content, button, self)
		self.trove:Connect(tab.Activated, function() self.ActiveTab = tab end)
		self.trove:Add(tab)
		table.insert(tabs, tab)
	end
	if TableUtil.IsEmpty(tabs) then return end

	table.sort(
		tabs,
		function(a, b) return a.Button.LayoutOrder < b.Button.LayoutOrder end
	)
	self.Tabs = tabs
	self.ActiveTab = (self.Tabs :: { Tab })[1]
end

function InitializeButtons(self: WindowImpl)
	local footer = self.Instance.Window.Footer
	if not footer then return end

	local buttons = {}
	for _, button in footer:GetChildren() do
		if not button:IsA("TextButton") then continue end

		table.insert(buttons, button)
	end
	if TableUtil.IsEmpty(buttons) then return end

	table.sort(buttons, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	self.Buttons = buttons
end

function Window.GetTab(self: WindowImpl, name: string): Tab
	assert(self.Tabs, `{self.Instance.Name} don't have tabs`)

	local tab = TableUtil.Find(self.Tabs, function(v) return v.Name == name end)
	assert(tab, `{self.Instance.Name} don't have {name} tab`)
	return tab
end

function Window.GetButton(self: WindowImpl, name: string): TextButton
	assert(self.Buttons, `{self.Instance.Name} don't have buttons`)

	local button = TableUtil.Find(
		self.Buttons,
		function(v) return v.Name == name end
	)
	assert(button, `{self.Instance.Name} don't have {name} button`)
	return button
end

function Window.GetButtonPressedSignal(self: WindowImpl, name: string)
	local button = self:GetButton(name)
	assert(button, `{name} button isn't found`)

	return button.Activated
end

function Window.Destroy(self: WindowImpl) self.Instance:Destroy() end

return table.freeze(Window :: any) :: {
	new: (instance: ScreenGui) -> Window,
}
