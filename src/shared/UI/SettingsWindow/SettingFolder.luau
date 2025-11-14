local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local Setting = require(script.Parent.Setting)
local SettingsTypes = require(ReplicatedStorage.Shared.Types.SettingsTypes)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

local SettingFolder = { set = {} }
SettingFolder.__extends = Component

export type SettingFolder = {
	Instance: Frame & {
		Content: Frame,
		Button: TextButton & {
			Info: Frame & {
				Title: TextLabel,
				Description: TextLabel,
			},
			Expand: Frame & {
				Image: ImageLabel,
			},
		},
	},
	Expanded: boolean,

	Add: (self: SettingFolder, object: Setting.Setting | SettingFolder) -> (),
} & Component.Component

function SettingFolder.new(
	instance: Frame,
	properties: SettingsTypes.FolderInfo
): SettingFolder
	local self: SettingFolder = Component(SettingFolder) :: any

	self.Instance = instance :: any

	self.Instance.Button.Info.Title.Text = properties.Title
	self.Instance.Button.Info.Description.Text = properties.Description or ""
	self.Instance.Button.Info.Description.Visible = properties.Description
		~= nil
	self.Instance.Visible = true

	local trove = Trove.new()
	trove:AttachToInstance(instance)

	-- On mouse enter
	trove:Connect(
		self.Instance.Button.MouseEnter,
		function()
			self.Instance.Button.BackgroundTransparency = self.Expanded and 0
				or 0.5
		end
	)

	-- On mouse leave
	trove:Connect(
		self.Instance.Button.MouseLeave,
		function()
			self.Instance.Button.BackgroundTransparency = self.Expanded and 0.5
				or 1
		end
	)

	-- On press
	trove:Connect(
		self.Instance.Button.Activated,
		function() self.Expanded = not self.Expanded end
	)

	return self
end

function SettingFolder.set.Expanded(self: SettingFolder, expanded: boolean)
	self:RawSet("Expanded", expanded)
	self.Instance.Button.BackgroundTransparency = 0
	self.Instance.BackgroundTransparency = self.Expanded and 0.5 or 1
	self.Instance.Content.Visible = self.Expanded

	TweenService:Create(
		self.Instance.Button.Expand.Image,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Rotation = self.Expanded and 180 or 0 }
	):Play()
end

function SettingFolder.Add(
	self: SettingFolder,
	object: (Setting.Setting | SettingFolder) & { Instance: Instance }
)
	object.Instance.Parent = self.Instance.Content
end

return table.freeze(SettingFolder :: any) :: {
	new: (
		instance: Frame,
		properties: SettingsTypes.FolderInfo
	) -> SettingFolder,
}
