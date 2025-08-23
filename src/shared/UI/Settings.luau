local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BaseWindow = require(script.Parent.BaseWindow)
local DatastoreController = require(ReplicatedStorage.Shared.Controllers.DatastoreController)
local VehicleController = require(ReplicatedStorage.Shared.Controllers.VehicleController)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ScreenGui = ReplicatedStorage.UI.Settings

local Settings = setmetatable({}, BaseWindow)
Settings.__index = Settings
Settings.Type = "Settings"

local Tab = {
	Controls = "Controls",
	Graphics = "Graphics",
	Gameplay = "Gameplay",
}

export type Settings = {
	__index: Settings,
	Controls: VehicleTypes.VehicleControls,

	new: () -> Settings,
	Apply: (self: Settings) -> (),
} & BaseWindow.BaseWindow

function Settings.new()
	local self: Settings = setmetatable(BaseWindow.new(ScreenGui:Clone()), Settings) :: any

	self.Controls = DatastoreController:GetControls()

	Initialize(self)

	return self
end

function Initialize(self: Settings)
	InitializeControls(self)

	self:SetTab(Tab.Controls)

	local done = self.Instance.Window.Bottom.Done :: TextButton
	done.Activated:Connect(function()
		self:Apply()
		self:Destroy()
	end)
end

function InitializeControls(self: Settings)
	for k, v in self.Controls :: { [string]: EnumItem } do
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

		frame.Parent = self.Instance.Window.Content.Controls[parent]
	end
end

function Settings.Apply(self: Settings)
	if VehicleController.DrivenVehicle then VehicleController.DrivenVehicle.Controls = self.Controls end

	DatastoreController:SetControls(self.Controls)
end

return Settings
