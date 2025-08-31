local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsInfo = require(script.SettingsInfo)

local player = Players.LocalPlayer

local SettingsController = {}
SettingsController.__index = SettingsController

export type SettingsController = typeof(setmetatable(
	{} :: {
		Settings: { [string]: number | boolean | Enum.KeyCode },
	},
	SettingsController
))

local RE = ReplicatedStorage:WaitForChild("_SettingsRE") :: RemoteEvent
local RF = ReplicatedStorage:WaitForChild("_SettingsRF") :: RemoteFunction

local Actions = {
	GetKeybinds = 0,
	GetSettings = 1,
	SaveKeybinds = 2,
	SaveSettings = 3,
}

function SettingsController.new(): SettingsController
	local self: SettingsController = setmetatable({}, SettingsController) :: any

	self.Settings = {}

	-- Load default settings
	for k, v in SettingsInfo do
		self.Settings[k] = v.Default
	end

	-- Load saved settings
	for k, v in RF:InvokeServer(Actions.GetSettings) do
		self.Settings[k] = v
	end

	do -- Initialize keybinds
		local keybinds = RF:InvokeServer(Actions.GetKeybinds)
		for _, context in ReplicatedStorage.Input:GetChildren() :: { InputContext } do
			for _, action in context:GetChildren() :: { InputAction } do
				for _, binding in action:GetChildren() :: { InputBinding } do
					if binding.Name == "Mobile" then continue end

					binding:SetAttribute("Default", binding.KeyCode)
					local path = context.Name .. action.Name .. binding.Name
					if keybinds[path] then binding.KeyCode = Enum.KeyCode[keybinds[path]] end
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
		for k, v in self.Settings do
			if SettingsInfo[k].Default == v then continue end

			settings[k] = v
		end
		RE:FireServer(Actions.SaveSettings, settings)

		-- Save keybinds
		local keybinds = {}
		for _, context in ReplicatedStorage.Input:GetChildren() :: { InputContext } do
			for _, action in context:GetChildren() :: { InputAction } do
				for _, binding in action:GetChildren() :: { InputBinding } do
					if binding.Name == "Mobile" then continue end

					local path = context.Name .. action.Name .. binding.Name
					if binding:GetAttribute("Default") ~= binding.KeyCode then keybinds[path] = binding.KeyCode.Name end
				end
			end
		end
		RE:FireServer(Actions.SaveKeybinds, keybinds)
	end)

	return self
end

function SettingsController.GetSettings(self: SettingsController) return table.clone(self.Settings) end

function SettingsController.GetSetting(self: SettingsController, name: string) return self.Settings[name] end

function SettingsController.GetSettingInfo(self: SettingsController, name: string)
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
	name: string,
	value: number | boolean | Enum.KeyCode
)
	self.Settings[name] = value
end

return SettingsController.new()
