--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

local Slider = {}
Slider.__index = Slider

export type Slider = {
	Instance: Frame & {
		Content: Frame & {
			Fill: Frame,
		},
		Progress: TextLabel,
	},
	Progress: number,

	SetProgress: (self: Slider, value: number) -> (),
	Destroy: (self: Slider) -> (),
}

type SliderImpl = {
	trove: Trove.Trove,
	currentProgress: number,
} & Slider

function Slider.new(instance: Frame): Slider
	local self: SliderImpl = setmetatable({}, Slider) :: any

	self.Instance = instance :: any
	self.Progress = 0
	self.currentProgress = 0

	self.trove = Trove.new()
	self.trove:Connect(
		RunService.Heartbeat,
		function(deltaTime: number) Update(self, deltaTime) end
	)
	self.trove:AttachToInstance(self.Instance)

	return self
end

function Slider.SetProgress(self: SliderImpl, value: number)
	self.Progress = value
end

function Update(self: SliderImpl, deltaTime: number)
	self.currentProgress += (self.Progress - self.currentProgress) * deltaTime * 5

	self.Instance.Content.Fill.Size = UDim2.fromScale(self.currentProgress, 1)
	self.Instance.Progress.Text = tostring(
		math.round(self.currentProgress * 100)
	) .. "%"
end

function Slider.Destroy(self: SliderImpl) self.Instance:Destroy() end

return table.freeze({ new = Slider.new })
