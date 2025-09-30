local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local SettingsController =
	require(ReplicatedStorage.Shared.Controllers.SettingsController)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
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

	self._trove = Trove.new()
	self._trove:AttachToInstance(self.Instance)

	Initialize(self)

	return self
end

function Initialize(self: Interface)
	InitializeButtons(self)
	InitializeFPSLabel(self)
end

function InitializeFPSLabel(self: Interface)
	local fps = 0
	self._trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		local fpsEnabled = SettingsController:GetSetting("ShowFPS")
		self.Instance.FPS.Visible = fpsEnabled
		if fpsEnabled then
			fps = MathUtil.Lerp(fps, 1 / deltaTime, deltaTime * 3)
			self.Instance.FPS.Text = `FPS: {math.round(fps)}`
		end
	end)
end

function InitializeButtons(self: Interface)
	local callbacks = {
		Settings = function() self.InterfaceController:OpenSettings() end,
		Store = function() end,
		Garage = function() end,
		Changelog = function() end,
	}

	for k, v in callbacks do
		local button =
			self.Instance.Buttons:FindFirstChild(k, true) :: TextButton
		self._trove:Connect(button.Activated, v)
	end
end

function Interface.Show(self: Interface) self.Instance.Enabled = true end

function Interface.Hide(self: Interface) self.Instance.Enabled = false end

function Interface.Destroy(self: Interface) self.Instance:Destroy() end

return table.freeze({ new = Interface.new })
