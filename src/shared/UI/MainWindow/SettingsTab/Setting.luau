local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local SettingsInfo = require(ReplicatedStorage.Shared.Controllers.SettingsController.SettingsInfo)

local Setting = {}
Setting.__index = Setting

type BindingButton = TextButton & {
	Revert: TextButton,
}

export type Setting = typeof(setmetatable(
	{} :: {
		_changedEvent: BindableEvent,
		_cons: { RBXScriptConnection },
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
		Changed: RBXScriptSignal,
		Value: any,
	},
	Setting
))

function Setting.new(instance: Frame, properties: SettingsInfo.SettingInfo)
	local self: Setting = setmetatable({}, Setting) :: any

	self.Instance = instance :: any
	self.Type = properties.Type
	self.Properties = properties
	self.Value = self.Properties.Value
	self._cons = {}

	self._changedEvent = Instance.new("BindableEvent")
	self.Changed = self._changedEvent.Event

	self.Instance.Info.Title.Text = self.Properties.Title
	self.Instance.Info.Description.Text = self.Properties.Description or ""
	self.Instance.Info.Description.Visible = self.Properties.Description ~= nil

	if self.Type == "Slider" then
		InitSlider(self)
	elseif self.Type == "Binding" then
		InitBinding(self)
	elseif self.Type == "Checkbox" then
		InitCheckbox(self)
	end

	table.insert(
		self._cons,
		self.Instance.MouseEnter:Connect(function() self.Instance.BackgroundTransparency = 0.5 end)
	)
	table.insert(self._cons, self.Instance.MouseLeave:Connect(function() self.Instance.BackgroundTransparency = 1 end))

	self.Instance.Visible = true

	return self
end

function InitSlider(self: Setting)
	local step = self.Properties.Step or 0.05
	local min = self.Properties.Min or 0
	local max = self.Properties.Max or 2
	local slider = self.Instance.Slider.Slider
	local valueFrame = self.Instance.Slider.Value

	local function updateValue(value: number, updateHandle: boolean?, fireEvent: boolean?)
		self.Value = math.clamp(step * math.round(value / step), min, max)
		local normalizedValue = MapToRange(self.Value, min, max)
		slider.Fill.Size = UDim2.fromScale(updateHandle and normalizedValue or MapToRange(value, min, max), 1)
		local l = step >= 1 and 0 or step >= 0.1 and 1 or 2
		valueFrame.Input.Text = string.format(`%.{l}f`, self.Value :: number)
		valueFrame.Revert.Visible = math.abs(self.Properties.Default - self.Value) > step / 2
		if updateHandle then slider.Handle.Position = UDim2.fromScale(normalizedValue, 0.5) end
		if fireEvent then self._changedEvent:Fire(self.Value) end
	end

	local start = MapToRange(self.Value, min, max)
	table.insert(
		self._cons,
		slider.Handle.Dragger.DragStart:Connect(function() start = MapToRange(self.Value, min, max) end)
	)
	table.insert(
		self._cons,
		slider.Handle.Dragger.DragContinue:Connect(
			function() updateValue(Lerp(min, max, start + slider.Handle.Dragger.DragUDim2.X.Scale)) end
		)
	)
	table.insert(
		self._cons,
		slider.Handle.Dragger.DragEnd:Connect(
			function() updateValue(Lerp(min, max, start + slider.Handle.Dragger.DragUDim2.X.Scale), true, true) end
		)
	)

	table.insert(
		self._cons,
		valueFrame.Input.FocusLost:Connect(function(enterPressed: boolean)
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
		end)
	)
	table.insert(
		self._cons,
		valueFrame.Revert.Activated:Connect(function() updateValue(self.Properties.Default, true, true) end)
	)

	updateValue(self.Value, true)
	self.Instance.Slider.Visible = true
end

function InitBinding(self: Setting)
	assert(self.Properties.ActionTypes, "Type check")
	for _, v in self.Instance.Binding:GetChildren() do
		if not v:IsA("TextButton") or table.find(self.Properties.ActionTypes, v.Name) then continue end

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
			if fireEvent then self._changedEvent:Fire(v, self.Value[v]) end
		end

		table.insert(
			self._cons,
			binding.Activated:Connect(function()
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
		)
		table.insert(
			self._cons,
			binding.Revert.Activated:Connect(function() updateBinding(self.Properties.Default[v]) end)
		)

		updateBinding(self.Value[v])
		binding.Visible = true
	end

	self.Instance.Binding.Visible = true
end

function InitCheckbox(self: Setting)
	local function updateCheckbox(value: boolean)
		self.Value = value
		self.Instance.Checkbox.Button.Box.Enabled.Visible = self.Value
		self.Instance.Checkbox.Button.Text = self.Value and "Enabled" or "Disabled"
		self._changedEvent:Fire(self.Value)
	end

	table.insert(
		self._cons,
		self.Instance.Checkbox.Button.Activated:Connect(function() updateCheckbox(not self.Value) end)
	)

	updateCheckbox(self.Value)
	self.Instance.Checkbox.Visible = true
end

function Setting.Destroy(self: Setting)
	for _, v in self._cons do
		v:Disconnect()
	end
end

return Setting
