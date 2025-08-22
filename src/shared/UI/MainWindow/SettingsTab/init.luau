local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local ControlsOrder = require(script.ControlsOrder)
local Setting = require(script.Setting)
local SettingsController = require(player.PlayerScripts.Client.Controllers.SettingsController)

local SettingsTab = {}
SettingsTab.__index = SettingsTab

export type SettingsTab = typeof(setmetatable(
	{} :: {
		_cons: { RBXScriptConnection },
		Instance: ScrollingFrame & {
			Setting: Frame,
			ControlContext: Frame & {
				Title: TextLabel,
			},
		},
	},
	SettingsTab
))

function SettingsTab.new(instance: ScrollingFrame)
	local self: SettingsTab = setmetatable({}, SettingsTab) :: any

	self.Instance = instance
	self._cons = {}

	local settingInstance = self.Instance.Setting
	for k, v in SettingsController:GetSettingInfos() do
		local setting = Setting.new(settingInstance:Clone(), v)
		table.insert(self._cons, setting.Changed:Connect(function(value) SettingsController:SetSetting(k, value) end))
		setting.Instance.Parent = self.Instance:FindFirstChild(v.Category)
	end

	local contextInstance = self.Instance.ControlContext
	for _, inputContext in ReplicatedStorage.Input:GetChildren() :: { InputContext } do
		local context = contextInstance:Clone()
		context.Title.Text = string.gsub(inputContext.Name, "([a-z])([A-Z][a-z])", "%1 %2")
		context.Visible = true
		local contextOrder, actionsOrder = getOrder(inputContext.Name)
		context.LayoutOrder = contextOrder

		for _, inputAction in inputContext:GetChildren() :: { InputAction } do
			if string.match(inputAction.Name, "Mouse") then continue end

			local properties = {
				Title = string.gsub(inputAction.Name, "([a-z])([A-Z][a-z])", "%1 %2"),
				Type = "Binding",
				Value = {},
				Default = {},
				ActionTypes = {},
			}

			local inputActions = inputAction:GetChildren() :: { InputBinding }
			local mouseAction = inputContext:FindFirstChild("Mouse" .. inputAction.Name)
			if mouseAction then table.insert(inputActions, mouseAction.Mouse) end

			for _, inputBinding in inputActions do
				if inputBinding.Name == "Mobile" then continue end

				properties.Value[inputBinding.Name] = inputBinding.KeyCode
				properties.Default[inputBinding.Name] = inputBinding:GetAttribute("Default")
				table.insert(properties.ActionTypes, inputBinding.Name)
			end

			local setting = Setting.new(settingInstance:Clone(), properties)
			local actionOrder = table.find(actionsOrder, inputAction.Name)
			setting.Instance.LayoutOrder = actionOrder

			table.insert(self._cons, setting.Changed:Connect(function(value) end))
			setting.Instance.Parent = context
		end

		context.Parent = self.Instance:FindFirstChild("Controls")
	end

	return self
end

function getOrder(context: string)
	for k, v in ControlsOrder do
		if v.Context == context then return k, v.Actions end
	end
	return 0
end

function SettingsTab.Destroy(self: SettingsTab)
	for _, v in self._cons do
		v:Disconnect()
	end
end

return SettingsTab
