local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interface = require(ReplicatedStorage.Shared.UI.Interface)

local InterfaceController = {}
InterfaceController.__index = InterfaceController

export type InterfaceController = typeof(setmetatable(
	{} :: {
		Interface: Interface.Interface,
	},
	InterfaceController
))

function InterfaceController.new()
	local self: InterfaceController = setmetatable({}, InterfaceController) :: any

	self.Interface = Interface.new()

	return self
end

function InterfaceController.Show(self: InterfaceController) self.Interface:Show() end

function InterfaceController.Hide(self: InterfaceController) self.Interface:Hide() end

return InterfaceController.new()
