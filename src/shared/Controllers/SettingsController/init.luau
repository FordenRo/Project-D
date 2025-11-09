local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local Enums = require(ReplicatedStorage.Shared.Enums)
local SettingsConfig = require(script.SettingsConfig)
local SettingsTypes = require(ReplicatedStorage.Shared.Types.SettingsTypes)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local player = Players.LocalPlayer

local SettingsController = {}
SettingsController.__index = SettingsController

export type SettingsController = {
	SettingChanged: Signal.Signal<string>,

	GetSettingChangedSignal: (
		self: SettingsController,
		name: string
	) -> Signal.Signal<string>,
	GetSettings: (self: SettingsController) -> { [string]: any },
	GetSetting: (self: SettingsController, name: string) -> any,
	GetSettingInfo: (
		self: SettingsController,
		name: string
	) -> SettingsTypes.SettingInfo,
	GetFolderInfo: (
		self: SettingsController,
		name: string
	) -> SettingsTypes.FolderInfo,
	GetSettingInfos: (
		self: SettingsController
	) -> { SettingsTypes.SettingInfo },
	GetFolderInfos: (self: SettingsController) -> { SettingsTypes.FolderInfo },
	SetSetting: (self: SettingsController, name: string, value: any) -> (),
}

type SettingsControllerImpl = {
	settings: Component.Component,
	raw: { [string]: any },
} & SettingsController

local RE = ReplicatedStorage:WaitForChild("_SettingsRE") :: RemoteEvent
local RF = ReplicatedStorage:WaitForChild("_SettingsRF") :: RemoteFunction

function SettingsController.new(): SettingsController
	local self: SettingsControllerImpl =
		setmetatable({}, SettingsController) :: any

	local config = {}

	-- Load default settings
	for _, v in SettingsConfig.Settings do
		config[v.Name] = v.Default
	end

	-- Load saved settings
	for k, v in RF:InvokeServer(Enums.SettingsAction.GetSettings) do
		config[k] = v
	end

	self.raw = config
	self.settings = Component.Wrap(config) :: any
	self.SettingChanged = self.settings.Changed

	self.SettingChanged:Connect(function(k) self.raw[k] = self.settings[k] end)

	do -- Initialize keybinds
		local keybinds = RF:InvokeServer(Enums.SettingsAction.GetKeybinds)
		for _, context: InputContext in
			ReplicatedStorage.Input:GetChildren() :: any
		do
			for _, action: InputAction in context:GetChildren() :: any do
				for _, binding: InputBinding in action:GetChildren() :: any do
					if binding.Name == "Mobile" then continue end

					binding:SetAttribute("Default", binding.KeyCode)
					local path = context.Name .. action.Name .. binding.Name
					if keybinds[path] then
						binding.KeyCode = (Enum.KeyCode :: any)[keybinds[path]]
					end
				end
			end
		end
	end

	local con
	con = Players.PlayerRemoving:Connect(function(removingPlayer: Player)
		if removingPlayer ~= player then return end

		con:Disconnect()

		-- Save settings
		local settings = {}
		for k, v in self:GetSettings() do
			if self:GetSettingInfo(k).Default == v then continue end

			settings[k] = v
		end
		RE:FireServer(Enums.SettingsAction.SaveSettings, settings)

		-- Save keybinds
		local keybinds = {}
		for _, context: InputContext in
			ReplicatedStorage.Input:GetChildren() :: any
		do
			for _, action: InputAction in context:GetChildren() :: any do
				for _, binding: InputBinding in action:GetChildren() :: any do
					if binding.Name == "Mobile" then continue end

					local path = context.Name .. action.Name .. binding.Name
					if binding:GetAttribute("Default") ~= binding.KeyCode then
						keybinds[path] = binding.KeyCode.Name
					end
				end
			end
		end
		RE:FireServer(Enums.SettingsAction.SaveKeybinds, keybinds)
	end)

	return self
end

function SettingsController.GetSettingChangedSignal(
	self: SettingsControllerImpl,
	name: string
)
	return self.settings:GetPropertyChangedSignal(name)
end

function SettingsController.GetSettings(self: SettingsControllerImpl)
	return TableUtil.DeepCopy(self.raw)
end

function SettingsController.GetSetting(
	self: SettingsControllerImpl,
	name: string
)
	return self.raw[name]
end

function SettingsController.GetSettingInfo(
	self: SettingsControllerImpl,
	name: string
): SettingsTypes.SettingInfo
	local found = TableUtil.Find(
		SettingsConfig.Settings,
		function(a) return a.Name == name end
	)
	assert(found, `Setting {name} not found`)

	local info = TableUtil.DeepCopy(found)
	info.Value = self:GetSetting(name)
	return info
end

function SettingsController.GetFolderInfo(
	self: SettingsControllerImpl,
	name: string
): SettingsTypes.FolderInfo
	local found = TableUtil.Find(
		SettingsConfig.Folders,
		function(a) return a.Name == name end
	)
	assert(found, `Folder {name} not found`)

	return TableUtil.DeepCopy(found)
end

function SettingsController.GetSettingInfos(
	self: SettingsControllerImpl
): { SettingsTypes.SettingInfo }
	local t = TableUtil.DeepCopy(SettingsConfig.Settings)
	for _, v in t do
		v.Value = self:GetSetting(v.Name)
	end
	return t
end

function SettingsController.GetFolderInfos(
	self: SettingsControllerImpl
): { SettingsTypes.FolderInfo }
	return TableUtil.DeepCopy(SettingsConfig.Folders)
end

function SettingsController.SetSetting(
	self: SettingsControllerImpl,
	name: string,
	value: any
)
	self.settings[name] = value
end

return SettingsController.new()
