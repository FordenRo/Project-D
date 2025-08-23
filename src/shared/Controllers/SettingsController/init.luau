local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsInfo = require(script.SettingsInfo)

local SettingsController = {}
SettingsController.__index = SettingsController

export type SettingsController = typeof(setmetatable(
	{} :: {
		Settings: { [keyof<typeof(SettingsInfo)>]: number | boolean | Enum.KeyCode },
	},
	SettingsController
))

function SettingsController.new()
	local self: SettingsController = setmetatable({}, SettingsController) :: any

	self.Settings = {}
	for k, v in SettingsInfo do
		self.Settings[k] = v.Default
	end

	for _, context in ReplicatedStorage.Input:GetChildren() :: { InputContext } do
		for _, action in context:GetChildren() :: { InputAction } do
			for _, binding in action:GetChildren() :: { InputBinding } do
				if binding.Name == "Mobile" then continue end

				binding:SetAttribute("Default", binding.KeyCode)
			end
		end
	end

	return self
end

function SettingsController.GetSettings(self: SettingsController) return table.clone(self.Settings) end

function SettingsController.GetSetting(self: SettingsController, name: keyof<typeof(SettingsInfo)>)
	return self.Settings[name]
end

function SettingsController.GetSettingInfo(self: SettingsController, name: keyof<typeof(SettingsInfo)>)
	local info = table.clone(SettingsInfo)[name]
	info.Value = self:GetSetting(name)
	return info
end

function SettingsController.GetSettingInfos(self: SettingsController)
	local t = table.clone(SettingsInfo)
	for k, v in t do
		v.Value = self:GetSetting(k)
	end
	return t
end

function SettingsController.SetSetting(
	self: SettingsController,
	name: keyof<typeof(SettingsInfo)>,
	value: number | boolean | Enum.KeyCode
)
	self.Settings[name] = value
end

function SettingsController.SaveSettings(self: SettingsController, settings) self.Settings = settings end

return SettingsController.new()
