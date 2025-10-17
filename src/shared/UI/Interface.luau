local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local SettingsController =
	require(ReplicatedStorage.Shared.Controllers.SettingsController)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local UITypes = require(ReplicatedStorage.Shared.Types.UITypes)

local ScreenGui = ReplicatedStorage.UI.Interface
local player = Players.LocalPlayer

local Interface = { set = {} }
Component.Extend(Interface)

type Interface = UITypes.Interface

type InterfaceImpl = {
	trove: Trove.Trove,
	interfaceController: UITypes.InterfaceController,
} & Interface

function Interface.new(interfaceController: UITypes.InterfaceController)
	local self: InterfaceImpl = Component.new() :: any

	self.Instance = ScreenGui:Clone()
	self.Instance.Enabled = false
	self.Instance.Parent = player.PlayerGui
	self.Visible = false

	self.interfaceController = interfaceController
	self.trove = Trove.new()
	self.trove:AttachToInstance(self.Instance)

	Initialize(self)
	setmetatable(self, Interface)

	return self
end

function Interface.set.Visible(self: InterfaceImpl, visible: boolean)
	self:RawSet("Visible", visible)
	self.Instance.Enabled = visible
end

function Initialize(self: InterfaceImpl)
	InitializeButtons(self)
	InitializeFPSLabel(self)
end

function InitializeFPSLabel(self: InterfaceImpl)
	local fps = 0
	self.trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		local fpsEnabled = SettingsController:GetSetting("ShowFPS")
		self.Instance.FPS.Visible = fpsEnabled
		if fpsEnabled then
			fps = MathUtil.Lerp(fps, 1 / deltaTime, deltaTime * 3)
			self.Instance.FPS.Text = `FPS: {math.round(fps)}`
		end
	end)
end

function InitializeButtons(self: InterfaceImpl)
	local callbacks = {
		Settings = function() self.interfaceController:OpenSettings() end,
		Store = function() end,
		Garage = function() end,
		Changelog = function() end,
	}

	for k, v in callbacks do
		local button =
			self.Instance.Buttons:FindFirstChild(k, true) :: TextButton
		self.trove:Connect(button.Activated, v)
	end
end

function Interface.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == Interface
end

function Interface.Destroy(self: InterfaceImpl) self.Instance:Destroy() end

return table.freeze({ new = Interface.new })
