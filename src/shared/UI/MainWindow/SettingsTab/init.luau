local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControlsOrder = require(script.ControlsOrder)
local Setting = require(script.Setting)
local SettingFolder = require(script.SettingFolder)
local SettingsConfig = require(
	ReplicatedStorage.Shared.Controllers.SettingsController.SettingsConfig
)
local SettingsController =
	require(ReplicatedStorage.Shared.Controllers.SettingsController)
local SettingsTypes = require(ReplicatedStorage.Shared.Types.SettingsTypes)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

local SettingsTab = {}
SettingsTab.__index = SettingsTab

export type SettingsTab = {
	Instance: ScrollingFrame & {
		Setting: Frame,
		SettingFolder: Frame,
		ControlContext: Frame & {
			Title: TextLabel,
		},
	},
}

type SettingsTabImpl = {
	folders: { [string]: SettingsTypes.FolderInfo & { Instance: Frame } },
} & SettingsTab

function SettingsTab.new(instance: ScrollingFrame): SettingsTab
	local self: SettingsTabImpl = setmetatable({}, SettingsTab) :: any

	self.Instance = instance :: any
	self.folders = {}

	local trove = Trove.new()
	trove:AttachToInstance(instance)

	local folderInstance = self.Instance.SettingFolder
	for k, v in SettingsController:GetFolderInfos() do
		local folder = SettingFolder.new(folderInstance:Clone(), v)
		folder.Instance.LayoutOrder = k
		folder.Instance.Parent = v.Folder
				and self.folders[v.Folder].Instance:FindFirstChild("Content")
			or self.Instance:FindFirstChild(assert(v.Category))

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
			or self.Instance:FindFirstChild(assert(v.Category))
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

		context.Parent = self.Instance:FindFirstChild("Controls")
	end

	return self
end

function getOrder(context: string)
	for k, v in ControlsOrder do
		if v.Context == context then return k, v.Actions end
	end
	error(`Order of an "{context}" context not found`)
end

return table.freeze({ new = SettingsTab.new })
