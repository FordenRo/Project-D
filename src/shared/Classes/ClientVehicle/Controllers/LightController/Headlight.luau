local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

local Headlight = {}
Headlight.__index = Headlight

export type Headlight = {
	Instance: BasePart,
	Light: Light?,
	Enabled: boolean,
	Brightness: number,
	DisabledColor: Color3,
	EnabledColor: Color3,

	Destroy: (self: Headlight) -> (),
}

type HeadlightImpl = {
	currentBrightness: number,
	lightBrightness: number,
} & Headlight

function Headlight.new(instance: BasePart): Headlight
	local self: HeadlightImpl = setmetatable({}, Headlight) :: any

	self.Instance = instance
	self.Light = self.Instance:FindFirstChildWhichIsA("Light", true)
	self.Enabled = false

	if self.Light then self.lightBrightness = self.Light.Brightness end
	self.currentBrightness = 0
	self.Brightness = 0
	self.DisabledColor = self.Instance.Color
	self.EnabledColor = self.Light and self.Light.Color
		or self.Instance:GetAttribute("Color") :: Color3

	if self.Light then
		self.Light.Brightness = 0
		self.Light.Enabled = true
	end

	local trove = Trove.new()
	trove:Add(task.defer(function()
		while true do
			Update(self, task.wait(1 / 30))
		end
	end))
	trove:AttachToInstance(instance)

	return self
end

function Update(self: HeadlightImpl, deltaTime: number)
	if self.currentBrightness < self.Brightness then
		self.currentBrightness =
			math.min(self.currentBrightness + deltaTime / 0.2, self.Brightness)
	elseif self.currentBrightness > self.Brightness then
		self.currentBrightness =
			math.max(self.currentBrightness - deltaTime / 0.2, self.Brightness)
	end

	local brightness = self.currentBrightness ^ 2
	if self.Light then
		self.Light.Brightness = self.lightBrightness * brightness
	end
	self.Instance.Color =
		self.DisabledColor:Lerp(self.EnabledColor, self.currentBrightness)
end

return table.freeze({ new = Headlight.new })
