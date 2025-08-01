local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Garage = require(script.Parent.Garage)
local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
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
		CurrentWindow: any,
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

function Interface.Initialize(self: Interface)
	self:InitializeButtons()
	self:InitializeDebug()
end

function Interface.InitializeButtons(self: Interface)
	for _, v in self.Instance.Buttons:GetChildren() do
		if not v:IsA("TextButton") then continue end

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

function Interface.InitializeDebug(self: Interface)
	local fps = 0
	table.insert(
		self._cons,
		RunService.RenderStepped:Connect(function(deltaTime)
			fps = Lerp(fps, 1 / deltaTime, deltaTime * 5)
			self.Instance.Debug.FPS.Text = string.format("FPS: %.1f", fps)
		end)
	)
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
