local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UITypes = require(ReplicatedStorage.Shared.Types.UITypes)

local ScreenGui = ReplicatedStorage.UI.Interface
local player = Players.LocalPlayer

local Interface = {}
Interface.__index = Interface

type Interface = UITypes.Interface

function Interface.new(interfaceController: UITypes.InterfaceController)
	local self: Interface = setmetatable({}, Interface) :: any

	self.InterfaceController = interfaceController

	self.Instance = ScreenGui:Clone()
	self.Instance.Parent = player.PlayerGui

	self._cons = {}

	Initialize(self)

	return self
end

function Initialize(self: Interface) InitializeButtons(self) end

function InitializeButtons(self: Interface)
	local callbacks = {
		Settings = function() self.InterfaceController:OpenSettings() end,
		Store = function() end,
		Garage = function() end,
		Changelog = function() end,
	}

	for k, v in callbacks do
		local button = self.Instance.Buttons:FindFirstChild(k, true) :: TextButton
		table.insert(self._cons, button.Activated:Connect(v))
	end
end

function Interface.Show(self: Interface) self.Instance.Enabled = true end

function Interface.Hide(self: Interface) self.Instance.Enabled = false end

function Interface.Destroy(self: Interface)
	for _, v in self._cons do
		v:Disconnect()
	end
	self.Instance:Destroy()
end

return Interface
