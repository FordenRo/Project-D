local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local GameConfigType = require(ReplicatedStorage.Shared.Types.GameConfigType)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

local UpdateFrame = {}
Component.Extend(UpdateFrame)

export type UpdateFrame = {
	Instance: {
		Header: {
			Labels: {
				Title: TextLabel,
				Version: TextLabel,
			} & Frame,
			Expand: ImageLabel,
		} & TextButton,
		Content: {
			TextLabel: TextLabel,
		} & CanvasGroup,
	} & Frame,
	Expanded: boolean,
} & Component.Component

type UpdateFrameImpl = {
	trove: Trove.Trove,
} & UpdateFrame

function UpdateFrame.new(
	instance: Instance,
	update: GameConfigType.Update
): UpdateFrame
	local self: UpdateFrameImpl = Component.new() :: any

	self.Instance = instance :: any

	self.trove = Trove.new()
	self.trove:AttachToInstance(instance)

	local title = self.Instance.Header.Labels.Title
	title.Text = update.Title or ""
	title.Visible = update.Title ~= nil

	self.Instance.Header.Labels.Version.Text = `{update.Type} {update.Version}`

	self.Instance.Content.TextLabel.Text = update.Description
	self.Instance.Content.Visible = false
	self.Expanded = false

	setmetatable(self, UpdateFrame)

	-- Expanded handler
	self.trove:Connect(
		self:GetPropertyChangedSignal("Expanded"),
		function() self.Instance.Content.Visible = self.Expanded end
	)

	-- On click
	self.trove:Connect(
		self.Instance.Header.Activated,
		function() self.Expanded = not self.Expanded end
	)

	return self
end

function UpdateFrame.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == UpdateFrame
end

function UpdateFrame.Destroy(self: UpdateFrameImpl) end

return table.freeze({
	new = UpdateFrame.new,
	Is = UpdateFrame.Is,
})
