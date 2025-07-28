local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
			Buttons: { TextButton },
		},
	},
	Interface
))

function Interface.new()
	local self: Interface = setmetatable({}, Interface) :: any

	self.Instance = ScreenGui:Clone()
	self.Instance.Parent = player.PlayerGui

	self.CurrentWindow = nil

	self:Initialize()

	return self
end

function Interface.Initialize(self: Interface) self:InitializeButtons() end

function Interface.InitializeButtons(self: Interface)
	for _, v in self.Instance.Buttons:GetChildren() do
		v.Activated:Connect(function()
			local lastWindowType
			if self.CurrentWindow then
				lastWindowType = self.CurrentWindow.Type
				self.CurrentWindow:Destroy()
				self.CurrentWindow = nil
			end

			if lastWindowType ~= v.Name then self.CurrentWindow = Windows[v.Name].new() end
		end)
	end
end

function Interface.Show(self: Interface) self.Instance.Enabled = true end

function Interface.Hide(self: Interface) self.Instance.Enabled = false end

function Interface.Destroy(self: Interface) self.Instance:Destroy() end

return Interface
