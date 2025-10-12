local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local SettingsInfo = require(
	ReplicatedStorage.Shared.Controllers.SettingsController.SettingsInfo
)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

local Setting = {}
Setting.__index = Setting

type BindingButton = TextButton & {
	Revert: TextButton,
}

export type Setting = {
	Instance: Frame & {
		Info: Frame & {
			Title: TextLabel,
			Description: TextLabel,
		},
		Slider: Frame & {
			Slider: Frame & {
				Fill: Frame,
				Handle: Frame & { Dragger: UIDragDetector },
			},
			Value: Frame & {
				Input: TextBox,
				Revert: TextButton,
			},
		},
		Checkbox: Frame & {
			Button: TextButton & {
				Box: Frame & { Enabled: ImageLabel },
			},
		},
		Binding: Frame & {
			Mouse: BindingButton,
			Controller: BindingButton,
			Keyboard: BindingButton,
		},
	},
	Type: SettingsInfo.SettingType,
	Properties: SettingsInfo.SettingInfo,
	Changed: Signal.Signal<...any>,
	Value: any,
}

export type SettingImpl = {
	trove: Trove.Trove,
} & Setting

function Setting.new(
	instance: Frame,
	properties: SettingsInfo.SettingInfo
): Setting
	local self: SettingImpl = setmetatable({}, Setting) :: any

	self.Instance = instance :: any
	self.Type = properties.Type
	self.Properties = properties
	self.Value = self.Properties.Value

	self.trove = Trove.new()

	self.Changed = self.trove:Construct(Signal)

	self.Instance.Info.Title.Text = self.Properties.Title
	self.Instance.Info.Description.Text = self.Properties.Description or ""
	self.Instance.Info.Description.Visible = self.Properties.Description ~= nil
	self.Instance.LayoutOrder = self.Properties.Index or 0

	if self.Type == "Slider" then
		InitSlider(self)
	elseif self.Type == "Binding" then
		InitBinding(self)
	elseif self.Type == "Checkbox" then
		InitCheckbox(self)
	end

	self.trove:Connect(
		self.Instance.MouseEnter,
		function() self.Instance.BackgroundTransparency = 0.5 end
	)
	self.trove:Connect(
		self.Instance.MouseLeave,
		function() self.Instance.BackgroundTransparency = 1 end
	)
	self.trove:AttachToInstance(self.Instance)

	self.Instance.Visible = true

	return self
end

function InitSlider(self: SettingImpl)
	local step = self.Properties.Step or 0.05
	local min = self.Properties.Min or 0
	local max = self.Properties.Max or 2
	local slider = self.Instance.Slider.Slider
	local valueFrame = self.Instance.Slider.Value

	local function updateValue(
		value: number,
		updateHandle: boolean?,
		fireEvent: boolean?
	)
		self.Value = math.clamp(step * math.round(value / step), min, max)
		local normalizedValue = MathUtil.Map(self.Value, min, max)
		slider.Fill.Size = UDim2.fromScale(
			updateHandle and normalizedValue or MathUtil.Map(value, min, max),
			1
		)
		local l = step >= 1 and 0 or step >= 0.1 and 1 or 2
		valueFrame.Input.Text = string.format(`%.{l}f`, self.Value :: number)
		valueFrame.Revert.Visible = math.abs(
			self.Properties.Default - self.Value
		) > step / 2
		if updateHandle then
			slider.Handle.Position = UDim2.fromScale(normalizedValue, 0.5)
		end
		if fireEvent then self.Changed:Fire(self.Value) end
	end

	local start = MathUtil.Map(self.Value, min, max)
	self.trove:Connect(
		slider.Handle.Dragger.DragStart,
		function() start = MathUtil.Map(self.Value, min, max) end
	)
	self.trove:Connect(
		slider.Handle.Dragger.DragContinue,
		function()
			updateValue(
				MathUtil.Lerp(
					min,
					max,
					start + slider.Handle.Dragger.DragUDim2.X.Scale
				)
			)
		end
	)
	self.trove:Connect(
		slider.Handle.Dragger.DragEnd,
		function()
			updateValue(
				MathUtil.Lerp(
					min,
					max,
					start + slider.Handle.Dragger.DragUDim2.X.Scale
				),
				true,
				true
			)
		end
	)
	self.trove:Connect(
		valueFrame.Input.FocusLost,
		function(enterPressed: boolean)
			if enterPressed then
				local inp = string.gsub(valueFrame.Input.Text, ",", ".")
				local value = tonumber(inp)
				if not value then
					valueFrame.Input.Text = self.Value
					return
				end
				updateValue(value, true, true)
			else
				valueFrame.Input.Text = self.Value
			end
		end
	)
	self.trove:Connect(
		valueFrame.Revert.Activated,
		function() updateValue(self.Properties.Default, true, true) end
	)

	updateValue(self.Value, true)
	self.Instance.Slider.Visible = true
end

function InitBinding(self: SettingImpl)
	assert(self.Properties.ActionTypes, "Type check")

	for _, v in self.Instance.Binding:GetChildren() do
		if
			not v:IsA("TextButton")
			or table.find(self.Properties.ActionTypes, v.Name)
		then
			continue
		end

		v:ClearAllChildren()
		v.BackgroundTransparency = 1
		v.Text = ""
	end

	for _, v in self.Properties.ActionTypes do
		local binding = self.Instance.Binding:FindFirstChild(v) :: BindingButton
		local function updateBinding(value: Enum.KeyCode, fireEvent: boolean?)
			self.Value[v] = value
			binding.Text = self.Value[v] ~= Enum.KeyCode.Unknown
					and string
						.gsub(self.Value[v].Name, "MouseRightButton", "RMB")
						:gsub("MouseLeftButton", "LMB")
						:gsub("Thumbstick", "Joystick")
						:gsub("DPad", "D")
				or "-"
			binding.Revert.Visible = self.Value[v] ~= self.Properties.Default[v]
			if fireEvent then self.Changed:Fire(v, self.Value[v]) end
		end

		self.trove:Connect(binding.Activated, function()
			local t = 5
			local thread = task.spawn(function()
				while true do
					binding.Text = string.sub(".....", 1, t)
					task.wait(1 / 5)
					t = t < 5 and t + 1 or 1
				end
			end)
			binding.Interactable = false

			local input = UserInputService.InputBegan:Wait()
			task.cancel(thread)
			binding.Interactable = true

			if not input.KeyCode then
				updateBinding(self.Value[v])
				return
			end

			if input.KeyCode == Enum.KeyCode.Escape then
				updateBinding(Enum.KeyCode.Unknown, true)
				return
			end

			updateBinding(input.KeyCode, true)
		end)
		self.trove:Connect(
			binding.Revert.Activated,
			function() updateBinding(self.Properties.Default[v], true) end
		)

		updateBinding(self.Value[v])
		binding.Visible = true
	end

	self.Instance.Binding.Visible = true
end

function InitCheckbox(self: SettingImpl)
	local function updateCheckbox(value: boolean)
		self.Value = value
		self.Instance.Checkbox.Button.Box.Enabled.Visible = self.Value
		self.Instance.Checkbox.Button.Text = self.Value and "Enabled"
			or "Disabled"
		self.Changed:Fire(self.Value)
	end

	self.trove:Connect(
		self.Instance.Checkbox.Button.Activated,
		function() updateCheckbox(not self.Value) end
	)

	updateCheckbox(self.Value)
	self.Instance.Checkbox.Visible = true
end

return table.freeze({ new = Setting.new })
