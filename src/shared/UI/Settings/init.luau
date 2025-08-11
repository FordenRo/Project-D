local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ScreenGui = ReplicatedStorage.UI.Settings
local player = Players.LocalPlayer

local DatastoreController = require(player.PlayerScripts.Client.Controllers.DatastoreController)
local Types = require(ReplicatedStorage.Shared.Types)
local VehicleController = require(player.PlayerScripts.Client.Controllers.VehicleController)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

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

	local done: TextButton = (self.Instance.Window.Bottom :: any).Done
	done.Activated:Connect(function()
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

		button.Activated:Connect(function()
			button.Text = "Enter a key..."

			local input = UserInputService.InputBegan:Wait()
			if input.KeyCode == Enum.KeyCode.Return then return end

			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
			then
				self.Controls[k] = input.UserInputType
				button.Text = input.UserInputType.Name
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
				self.Controls[k] = input.KeyCode
				button.Text = input.KeyCode.Name
			end
		end)

		frame.Parent = (self.Instance.Window.Content :: any).Controls[parent]
	end
end

function Settings.SetTab(self: Settings, tab: Tab)
	local tabs: Frame = self.Instance.Window.Upper.Tabs :: any
	for _, v in tabs:GetChildren() do
		if not v:IsA("TextButton") then continue end

		v.Interactable = true
	end
	(tabs:FindFirstChild(tab) :: TextButton).Interactable = false

	for _, v in self.Instance.Window.Content:GetChildren() do
		v.Visible = false
	end
	(self.Instance.Window.Content:FindFirstChild(tab) :: Frame).Visible = true
end

function Settings.Apply(self: Settings)
	if VehicleController.DrivenVehicle then VehicleController.DrivenVehicle.Controls = self.Controls end

	DatastoreController:SetControls(self.Controls)
end

function Settings.IsA(self: Settings, type: string) return self.Type == type end

function Settings.Destroy(self: Settings) self.Instance:Destroy() end

return Settings
