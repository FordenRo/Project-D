local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)

local NotificationFrame = { get = {}, set = {} }
Component.Extend(NotificationFrame)

local showTweenInfo =
	TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local moveTweenInfo =
	TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local hideTweenInfo =
	TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local strokeColor = {
	[Enum.MessageType.MessageInfo] = Color3.new(0.6, 0.6, 0.6),
	[Enum.MessageType.MessageOutput] = Color3.new(1, 1, 1),
	[Enum.MessageType.MessageWarning] = Color3.new(1, 0.5, 0),
	[Enum.MessageType.MessageError] = Color3.new(1, 0.1, 0.1),
}

export type NotificationFrame = {
	Instance: CanvasGroup & {
		UIScale: UIScale,
		UIStroke: UIStroke,
		TextLabel: TextLabel,
	},
	Destroying: Signal.Signal<>,

	Destroy: (self: NotificationFrame) -> (),
} & Component.Component

type NotificationFrameImpl = {
	prev: NotificationFrameImpl?,
	duration: number,
	position: number,
	destroying: boolean,
} & NotificationFrame

function NotificationFrame.new(
	instance: Instance,
	text: string,
	type: Enum.MessageType,
	duration: number?,
	previousFrame: NotificationFrame?
): NotificationFrame
	local self: NotificationFrameImpl = Component.new() :: any

	self.Instance = instance :: any
	self.Instance.Position = UDim2.new(0.5, 0, 1, 40)
	self.Instance.TextLabel.Text = text
	self.Instance.UIStroke.Color = strokeColor[type]
	self.Destroying = Signal.new()

	self.duration = duration or 5

	setmetatable(self, NotificationFrame)

	self.Instance.Visible = true
	showAnim(self)

	self.prev = previousFrame

	task.delay(self.duration, function()
		if self.destroying then return end
		self:Destroy()
	end)

	return self
end

function NotificationFrame.set.prev(
	self: NotificationFrameImpl,
	prev: NotificationFrameImpl?
)
	self:RawSet("prev", prev)
	self.position = self.prev
			and self.prev.position + self.prev.Instance.AbsoluteSize.Y + 5
		or 0
	if prev then
		local conn = prev:GetPropertyChangedSignal("position")
			:Connect(function()
				self.position = prev.position + prev.Instance.AbsoluteSize.Y + 5
				moveAnim(self)
			end)
		prev.Destroying:Once(function()
			conn:Disconnect()
			self.prev = prev.prev
		end)
	end
	moveAnim(self)
end

function moveAnim(self: NotificationFrameImpl)
	local newPosition = UDim2.new(0.5, 0, 1, -self.position)
	TweenService
		:Create(self.Instance, moveTweenInfo, { Position = newPosition })
		:Play()
end

function showAnim(self: NotificationFrameImpl)
	self.Instance.GroupTransparency = 1
	self.Instance.UIStroke.Transparency = 1
	self.Instance.UIScale.Scale = 0.5

	TweenService:Create(self.Instance, showTweenInfo, {
		GroupTransparency = 0,
	}):Play()
	TweenService:Create(self.Instance.UIStroke, showTweenInfo, {
		Transparency = 0.5,
	}):Play()
	TweenService:Create(self.Instance.UIScale, showTweenInfo, {
		Scale = 1,
	}):Play()
end

function hideAnim(self: NotificationFrameImpl)
	local tween = TweenService:Create(self.Instance, hideTweenInfo, {
		Position = UDim2.fromScale(0.5, 1),
		GroupTransparency = 1,
	})
	TweenService:Create(self.Instance.UIScale, hideTweenInfo, { Scale = 0.5 })
		:Play()

	tween:Play()
	tween.Completed:Once(function() self.Instance:Destroy() end)
end

function NotificationFrame.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == NotificationFrame
end

function NotificationFrame.Destroy(self: NotificationFrameImpl)
	self.destroying = true
	hideAnim(self)
	self.Destroying:Fire()
end

return table.freeze({
	new = NotificationFrame.new,
	Is = NotificationFrame.Is,
})
