--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local Interface = require(ReplicatedStorage.Shared.UI.Interface)
local MainWindow = require(ReplicatedStorage.Shared.UI.MainWindow)
local UITypes = require(ReplicatedStorage.Shared.Types.UITypes)

local InterfaceController = { set = {} }
Component.Extend(InterfaceController)

type InterfaceController = UITypes.InterfaceController

function InterfaceController.new(): InterfaceController
	local self: InterfaceController = Component.new() :: any

	self.Interface = Interface.new(self)
	self.MainWindow = MainWindow.new()
	self.Visible = false

	setmetatable(self, InterfaceController)
	return self
end

function InterfaceController.set.Visible(
	self: InterfaceController,
	visible: boolean
)
	self:RawSet("Visible", visible)
	self.Interface.Visible = visible
	if not visible then self.MainWindow.Visible = false end
end

function InterfaceController.OpenWelcome(self: InterfaceController)
	self.MainWindow:Show()
end

function InterfaceController.OpenSettings(self: InterfaceController)
	self.MainWindow:Show("Settings")
end

return InterfaceController.new()
