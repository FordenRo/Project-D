local DefaultSettings = require(script.DefaultSettings)
local SettingsInfo = require(script.SettingsInfo)

local SettingsController = {}
SettingsController.__index = SettingsController

export type SettingsController = typeof(setmetatable(
	{} :: {
		Settings: typeof(DefaultSettings),
	},
	SettingsController
))

function SettingsController.new()
	local self = setmetatable({}, SettingsController) :: SettingsController

	self.Settings = DefaultSettings

	return self
end

function SettingsController.GetSettings(self: SettingsController) return self.Settings end

function SettingsController.GetSetting(self: SettingsController, name: keyof<typeof(DefaultSettings)>)
	return self.Settings[name]
end

function SettingsController.GetSettingInfo(self: SettingsController, name: keyof<typeof(DefaultSettings)>)
	return SettingsInfo[name]
end

function SettingsController.SaveSettings(self: SettingsController, settings) self.Settings = settings end

return SettingsController.new()
