--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interface = require(ReplicatedStorage.Shared.UI.Interface)
local MainWindow = require(ReplicatedStorage.Shared.UI.MainWindow)
local UITypes = require(ReplicatedStorage.Shared.Types.UITypes)

local InterfaceController = {}
InterfaceController.__index = InterfaceController

type InterfaceController = UITypes.InterfaceController

function InterfaceController.new(): InterfaceController
	local self: InterfaceController =
		setmetatable({}, InterfaceController) :: any

	self.Interface = Interface.new(self)
	self.MainWindow = MainWindow.new()

	return self
end

function InterfaceController.Show(self: InterfaceController)
	self.Interface:Show()
	self.MainWindow:Hide()
end

function InterfaceController.Hide(self: InterfaceController)
	self.Interface:Hide()
	self.MainWindow:Hide()
end

function InterfaceController.OpenWelcome(self: InterfaceController)
	self.MainWindow:Show()
end

function InterfaceController.OpenSettings(self: InterfaceController)
	self.MainWindow:Show("Settings")
end

return InterfaceController.new()
