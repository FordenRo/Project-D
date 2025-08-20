local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseWindow = require(script.Parent.BaseWindow)
local Garage = require(script.Parent.Garage)
local Settings = require(script.Parent.Settings)

local ScreenGui = ReplicatedStorage.UI.Interface
local player = Players.LocalPlayer

local Windows = { Garage = Garage, Settings = Settings }

local Interface = {}
Interface.__index = Interface

export type Interface = typeof(setmetatable(
	{} :: {
		Instance: ScreenGui & {
			Buttons: Frame,
			Debug: Frame & { FPS: TextLabel },
		},
		CurrentWindow: BaseWindow.BaseWindow?,
		_cons: { RBXScriptConnection },
	},
	Interface
))

function Interface.new()
	local self: Interface = setmetatable({}, Interface) :: any

	self.Instance = ScreenGui:Clone()
	self.Instance.Parent = player.PlayerGui

	self.CurrentWindow = nil
	self._cons = {}

	self:Initialize()

	return self
end

function Interface.Initialize(self: Interface) self:InitializeButtons() end

function toggleButtons(self: Interface, interactable: boolean)
	for _, v: TextButton in self.Instance.Buttons:GetChildren() do
		if not v:IsA("TextButton") then continue end

		v.Interactable = interactable
		v.BackgroundTransparency = interactable and 0.5 or 0.8
	end
end

function Interface.InitializeButtons(self: Interface)
	for _, v in self.Instance.Buttons:GetChildren() do
		if not v:IsA("TextButton") then continue end

		table.insert(
			self._cons,
			v.Activated:Connect(function()
				local lastWindowType
				if self.CurrentWindow then
					lastWindowType = self.CurrentWindow.Type
					self.CurrentWindow:Destroy()
					self.CurrentWindow = nil
				end

				if lastWindowType ~= v.Name then
					toggleButtons(self, false)
					local success, window = pcall(Windows[v.Name].new)
					if success then self.CurrentWindow = window end
					toggleButtons(self, true)
				end
			end)
		)
	end
end

function Interface.Show(self: Interface) self.Instance.Enabled = true end

function Interface.Hide(self: Interface)
	if self.CurrentWindow then
		self.CurrentWindow:Destroy()
		self.CurrentWindow = nil
	end

	self.Instance.Enabled = false
end

function Interface.Destroy(self: Interface)
	for _, v in self._cons do
		v:Disconnect()
	end
	self.Instance:Destroy()
end

return Interface
