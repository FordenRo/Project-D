local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ScreenGui = ReplicatedStorage.UI:WaitForChild("Interface")
local player = Players.LocalPlayer

local InterfaceController = {}
InterfaceController.__index = InterfaceController

export type InterfaceController = typeof(setmetatable(
	{} :: {
		Interface: ScreenGui,
	},
	InterfaceController
))

function InterfaceController.new()
	local self = setmetatable({}, InterfaceController) :: InterfaceController

	self.Interface = ScreenGui:Clone()
	self.Interface.Parent = player.PlayerGui

	return self
end

function InterfaceController.Show(self: InterfaceController) self.Interface.Enabled = true end

function InterfaceController.Hide(self: InterfaceController) self.Interface.Enabled = false end

return InterfaceController.new()
