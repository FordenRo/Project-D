local TweenService = game:GetService("TweenService")
local SettingFolder = {}
SettingFolder.__index = SettingFolder

export type SettingFolder = typeof(setmetatable(
	{} :: {
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
	},
	SettingFolder
))

function SettingFolder.new(instance: Frame, name: string): SettingFolder
	local self: SettingFolder = setmetatable({}, SettingFolder) :: any

	self.Instance = instance :: any
	self.Instance.Name = name
	self.Instance.Button.Info.Title.Text = name
	self.Instance.Visible = true

	do -- Initialize connections
		local cons = {}

		-- On mouse enter
		table.insert(
			cons,
			self.Instance.Button.MouseEnter:Connect(
				function() self.Instance.Button.BackgroundTransparency = self.Expanded and 0 or 0.5 end
			)
		)
		-- On mouse leave
		table.insert(
			cons,
			self.Instance.Button.MouseLeave:Connect(
				function() self.Instance.Button.BackgroundTransparency = self.Expanded and 0.5 or 1 end
			)
		)
		-- On press
		table.insert(
			cons,
			self.Instance.Button.Activated:Connect(function()
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
		)

		-- On destroying
		self.Instance.Destroying:Once(function()
			for _, v in cons do
				v:Disconnect()
			end
		end)
	end

	return self
end

return SettingFolder
