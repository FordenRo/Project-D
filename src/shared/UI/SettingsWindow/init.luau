local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControlsOrder = require(script.ControlsOrder)
local Setting = require(script.Setting)
local SettingFolder = require(script.SettingFolder)
local SettingsController =
	require(ReplicatedStorage.Shared.Controllers.SettingsController)
local SettingsTypes = require(ReplicatedStorage.Shared.Types.SettingsTypes)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Window = require(script.Parent.Window)

local SettingsWindow = {}
Window.Extend(SettingsWindow)

export type SettingsWindow = {} & Window.Window

type SettingsWindowImpl = {
	folders: { [string]: SettingsTypes.FolderInfo & { Instance: Frame } },
} & SettingsWindow

function SettingsWindow.new(): SettingsWindow
	local self: SettingsWindowImpl =
		Window.new((ReplicatedStorage.UI :: any).SettingsWindow:Clone()) :: any

	self.folders = {}

	local trove = Trove.new()
	trove:AttachToInstance(self.Instance)

	local folderInstance = self.Instance.SettingFolder
	for k, v in SettingsController:GetFolderInfos() do
		local folder = SettingFolder.new(folderInstance:Clone(), v)
		folder.Instance.LayoutOrder = k
		folder.Instance.Parent = v.Folder
				and self.folders[v.Folder].Instance:FindFirstChild("Content")
			or self:GetTab(assert(v.Category)).Content

		local folderInfo =
			table.clone(v) :: SettingsTypes.FolderInfo & { Instance: Frame }
		folderInfo.Instance = folder.Instance
		self.folders[v.Name] = folderInfo
	end

	local settingInstance = self.Instance.Setting
	for k, v in SettingsController:GetSettingInfos() do
		local setting = Setting.new(settingInstance:Clone(), v)
		trove:Connect(
			setting.Changed,
			function(value) SettingsController:SetSetting(v.Name, value) end
		)

		setting.Instance.LayoutOrder = k
		setting.Instance.Parent = v.Folder
				and self.folders[v.Folder].Instance:FindFirstChild("Content")
			or self:GetTab(assert(v.Category)).Content
	end

	local contextInstance = self.Instance.ControlContext
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

			trove:Connect(
				setting.Changed,
				function(actionType: string, keyCode: Enum.KeyCode)
					local binding =
						inputAction:FindFirstChild(actionType) :: InputBinding
					binding.KeyCode = keyCode
				end
			)
			setting.Instance.Parent = context
		end

		context.Parent = self:GetTab("Controls").Content
	end

	trove:Connect(
		self:GetButtonPressedSignal("Close"),
		function() self.Visible = false end
	)

	-- TODO: Reset button

	return self
end

function getOrder(context: string)
	for k, v in ControlsOrder do
		if v.Context == context then return k, v.Actions end
	end
	error(`Order of an "{context}" context not found`)
end

function SettingsWindow.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == SettingsWindow
end

function SettingsWindow.Destroy(self: SettingsWindowImpl) end

return table.freeze({
	new = SettingsWindow.new,
	Is = SettingsWindow.Is,
})
