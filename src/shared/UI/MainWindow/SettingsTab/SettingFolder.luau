local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local SettingFolder = {}
SettingFolder.__index = SettingFolder

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
}

function SettingFolder.new(instance: Frame, name: string): SettingFolder
	local self: SettingFolder = setmetatable({}, SettingFolder) :: any

	self.Instance = instance :: any
	self.Instance.Name = name
	self.Instance.Button.Info.Title.Text = name
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
	trove:Connect(self.Instance.Button.Activated, function()
		self.Expanded = not self.Expanded
		self.Instance.Button.BackgroundTransparency = 0
		self.Instance.BackgroundTransparency = self.Expanded and 0.5 or 1
		self.Instance.Content.Visible = self.Expanded

		TweenService:Create(
			self.Instance.Button.Expand.Image,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Rotation = self.Expanded and 180 or 0 }
		):Play()
	end)

	return self
end

return table.freeze({ new = SettingFolder.new })
