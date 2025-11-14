local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local ControlsOrder = require(script.ControlsOrder)
local Setting = require(script.Setting)
local SettingFolder = require(script.SettingFolder)
local SettingsController =
	require(ReplicatedStorage.Shared.Controllers.SettingsController)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Window = require(script.Parent.Window)

local SettingsWindow = {}
SettingsWindow.__extends = Window

export type SettingsWindow = {} & Window.Window

type SettingsWindowImpl = {
	trove: Trove.Trove,
	folders: { [string]: SettingFolder.SettingFolder },
	settings: { [string]: Setting.Setting },
	bindings: { Setting.Setting },
} & SettingsWindow

function SettingsWindow.new(): SettingsWindow
	local self: SettingsWindowImpl = Component(
		SettingsWindow,
		Window.new((ReplicatedStorage.UI :: any).SettingsWindow:Clone())
	) :: any

	self.trove = Trove.new()
	self.trove:AttachToInstance(self.Instance)

	InitializeFolders(self)
	InitializeSettings(self)
	InitializeBindings(self)

	self.trove:Connect(
		self:GetButtonPressedSignal("Close"),
		function() self.Visible = false end
	)

	self.trove:Connect(self:GetButtonPressedSignal("Reset"), function()
		for _, setting in self.settings do
			setting:Reset()
		end
		for _, binding in self.bindings do
			binding:Reset()
		end
	end)

	return self
end

function InitializeFolders(self: SettingsWindowImpl)
	self.folders = {}

	local folderInstance = (self.Instance :: any).SettingFolder
	for k, v in SettingsController:GetFolderInfos() do
		local folder = SettingFolder.new(folderInstance:Clone(), v)
		folder.Instance.LayoutOrder = k

		if v.Folder then
			self.folders[v.Folder]:Add(folder)
		else
			folder.Instance.Parent = self:GetTab(assert(v.Category)).Content
		end
		self.folders[v.Name] = folder
	end
end

function InitializeSettings(self: SettingsWindowImpl)
	self.settings = {}

	local settingInstance = (self.Instance :: any).Setting
	for k, v in SettingsController:GetSettingInfos() do
		local setting = Setting.new(settingInstance:Clone(), v)
		setting.Instance.LayoutOrder = k

		self.trove:Connect(
			setting.Changed,
			function(value) SettingsController:SetSetting(v.Name, value) end
		)

		if v.Folder then
			self.folders[v.Folder]:Add(setting)
		else
			setting.Instance.Parent = self:GetTab(assert(v.Category)).Content
		end
		self.settings[v.Name] = setting
	end
end

function InitializeBindings(self: SettingsWindowImpl)
	self.bindings = {}

	local settingInstance = (self.Instance :: any).Setting
	local contextInstance = (self.Instance :: any).ControlContext
	for _, inputContext: InputContext in
		ReplicatedStorage.Input:GetChildren() :: any
	do
		local context = contextInstance:Clone()
		context.Title.Text = StringUtil.SplitPascalCase(inputContext.Name)
		context.Visible = true

		local contextOrder, actionsOrder = getOrder(inputContext.Name)
		context.LayoutOrder = contextOrder + 100

		for _, inputAction: InputAction in inputContext:GetChildren() :: any do
			if string.match(inputAction.Name, "Mouse") then continue end

			local properties = {
				Title = StringUtil.SplitPascalCase(inputAction.Name),
				Type = "Binding",
				Value = {},
				Default = {},
				ActionTypes = {},
			}

			local inputActions: { InputBinding } =
				inputAction:GetChildren() :: any
			local mouseAction = inputContext:FindFirstChild(
				"Mouse" .. inputAction.Name
			) :: InputAction & { Mouse: InputBinding }
			if mouseAction then
				table.insert(inputActions, mouseAction.Mouse)
			end

			for _, inputBinding in inputActions do
				if inputBinding.Name == "Mobile" then continue end

				properties.Value[inputBinding.Name] = inputBinding.KeyCode
				properties.Default[inputBinding.Name] =
					inputBinding:GetAttribute("Default")
				table.insert(properties.ActionTypes, inputBinding.Name)
			end

			local setting =
				Setting.new(settingInstance:Clone(), properties :: any)
			local actionOrder =
				assert(table.find(actionsOrder, inputAction.Name))
			setting.Instance.LayoutOrder = actionOrder

			self.trove:Connect(
				setting.Changed,
				function(actionType: string, keyCode: Enum.KeyCode)
					local binding =
						inputAction:FindFirstChild(actionType) :: InputBinding
					binding.KeyCode = keyCode
				end
			)
			setting.Instance.Parent = context
			table.insert(self.bindings, setting)
		end

		context.Parent = self:GetTab("Controls").Content
	end
end

function getOrder(context: string)
	for k, v in ControlsOrder do
		if v.Context == context then return k, v.Actions end
	end
	error(`Order of an "{context}" context not found`)
end

function SettingsWindow.Destroy(self: SettingsWindowImpl)
	self.Instance:Destroy()
end

return table.freeze(SettingsWindow :: any) :: {
	new: () -> SettingsWindow,
}
