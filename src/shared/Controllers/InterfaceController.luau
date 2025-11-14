local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local SettingsController = require(script.Parent.SettingsController)
local SettingsWindow = require(ReplicatedStorage.Shared.UI.SettingsWindow)
local VehicleController = require(script.Parent.VehicleController)
local Window = require(ReplicatedStorage.Shared.UI.Window)

local player = Players.LocalPlayer
local Windows = {
	Settings = SettingsWindow,
} :: { [string]: { new: () -> Window.Window } }

local InterfaceController = { set = {} }
InterfaceController.__extends = Component

export type InterfaceController = {
	Instance: {
		Buttons: Frame,
		Debug: { FPS: TextLabel } & Frame,
		FPS: TextLabel,
	} & ScreenGui,
	Visible: boolean,
	ActiveWindow: Window.Window?,

	OpenWindow: (self: InterfaceController, name: string) -> (),
} & Component.Component

type InterfaceControllerImpl = {
	spawnedWindows: { [string]: Window.Window },
} & InterfaceController

function InterfaceController.new(): InterfaceController
	local self: InterfaceControllerImpl = Component(InterfaceController) :: any

	self.Instance = (ReplicatedStorage.UI :: any).Interface:Clone()
	self.Instance.Enabled = false
	self.Instance.Parent = player.PlayerGui

	self.Visible = false
	self.ActiveWindow = nil
	self.spawnedWindows = {}

	SideButtonsHandler(self)
	FPSLabelHandler(self)

	return self
end

function InterfaceController.set.Visible(
	self: InterfaceControllerImpl,
	visible: boolean
)
	self:RawSet("Visible", visible)
	self.Instance.Enabled = visible
	if not visible and self.ActiveWindow then
		self.ActiveWindow.Visible = false
	end
end

function InterfaceController.OpenWindow(
	self: InterfaceControllerImpl,
	name: string
)
	if not self.Visible then return end
	if self.ActiveWindow then self.ActiveWindow.Visible = false end

	if self.spawnedWindows[name] then
		self.spawnedWindows[name].Visible = true
	else
		local window = Windows[name].new()
		self.spawnedWindows[name] = window
		window.Instance.Parent = player.PlayerGui
		window.Visible = true
	end
end

function FPSLabelHandler(self: InterfaceControllerImpl)
	local fps = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		local fpsEnabled = SettingsController:GetSetting("ShowFPS")
		self.Instance.FPS.Visible = fpsEnabled
		if fpsEnabled then
			fps = MathUtil.Lerp(fps, 1 / deltaTime, deltaTime * 3)
			self.Instance.FPS.Text = `FPS: {math.round(fps)}`
		end
	end)
end

function SideButtonsHandler(self: InterfaceControllerImpl)
	local callbacks = {
		Settings = function() self:OpenWindow("Settings") end,
		Spawn = function()
			if VehicleController.SpawnedVehicle then
				VehicleController:RemoveVehicle()
			else
				VehicleController:SpawnVehicle()
			end
		end,
	} :: { [string]: () -> () }

	for k, v in callbacks do
		local button =
			self.Instance.Buttons:FindFirstChild(k, true) :: TextButton
		button.Activated:Connect(v)
	end
end

return InterfaceController.new()
