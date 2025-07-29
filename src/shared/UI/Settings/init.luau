local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ScreenGui = ReplicatedStorage.UI.Settings
local player = Players.LocalPlayer

local DatastoreController = require(player.PlayerScripts.Client.Controllers.DatastoreController)
local Types = require(ReplicatedStorage.Shared.Types)
local VehicleController = require(player.PlayerScripts.Client.Controllers.VehicleController)
local VehicleTypes = require(ReplicatedStorage.Shared.Vehicle.Types)

local Settings = {}
Settings.__index = Settings
Settings.Type = "Settings"

type Tab = "Controls" | "Graphics" | "Gameplay"

export type Settings = typeof(setmetatable(
	{} :: {
		Instance: Types.WindowInstance,
		Controls: VehicleTypes.VehicleControls,
		Type: "Settings",
	},
	Settings
))

function Settings.new()
	local self: Settings = setmetatable({}, Settings) :: any

	self.Instance = ScreenGui:Clone()
	self.Instance.Parent = player.PlayerGui
	self.Controls = DatastoreController:GetControls()

	self:Initialize()

	return self
end

function Settings.Initialize(self: Settings)
	self:InitializeControls()

	self:SetTab("Controls")

	self.Instance.Window.Bottom.Done.Activated:Connect(function()
		self:Apply()
		self:Destroy()
	end)
end

function Settings.InitializeControls(self: Settings)
	for k, v in self.Controls do
		if typeof(v) ~= "EnumItem" then continue end

		local frame = Instance.new("Frame")

		local parent = "Keyboard"
		if string.find(k, "Mouse") then
			parent = "Mouse"
			k = string.gsub(k, "Mouse", "")
		elseif string.find(k, "Contlr") then
			parent = "Gamepad"
			k = string.gsub(k, "Contlr", "")
		end

		local label = Instance.new("TextLabel")
		label.Text = k
		label.Parent = frame

		local button = Instance.new("TextButton")
		button.Text = v.Name
		button.Parent = frame

		frame.Parent = self.Instance.Window.Content.Controls[parent]
	end
end

function Settings.SetTab(self: Settings, tab: Tab)
	for _, v in self.Instance.Window.Upper.Tabs:GetChildren() do
		v.Interactable = true
	end
	self.Instance.Window.Upper.Tabs:FindFirstChild(tab).Interactable = false

	for _, v: Frame in self.Instance.Window.Content:GetChildren() do
		v.Visible = false
	end
	self.Instance.Window.Content:FindFirstChild(tab).Visible = true
end

function Settings.Apply(self: Settings)
	if VehicleController.DrivenVehicle then VehicleController.DrivenVehicle.Controls = self.Controls end

	DatastoreController:SetControls(self.Controls)
end

function Settings.IsA(self: Settings, type: string) return self.Type == type end

function Settings.Destroy(self: Settings) self.Instance:Destroy() end

return Settings
