local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Headlight = {}
Headlight.__index = Headlight

type Headlight = VehicleTypes.Headlight

function Headlight.new(instance: BasePart): Headlight
	local self: Headlight = setmetatable({}, Headlight) :: any

	self.Instance = instance
	self.Light = self.Instance:FindFirstChildWhichIsA("Light", true)
	self.Enabled = false

	if self.Light then self._lightBrightness = self.Light.Brightness end
	self._currentBrightness = 0
	self.Brightness = 0
	self.DisabledColor = self.Instance.Color
	self.EnabledColor = self.Light and self.Light.Color or self.Instance:GetAttribute("Color") :: Color3

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

function Update(self: Headlight, deltaTime: number)
	if self._currentBrightness < self.Brightness then
		self._currentBrightness = math.min(self._currentBrightness + deltaTime / 0.2, self.Brightness)
	elseif self._currentBrightness > self.Brightness then
		self._currentBrightness = math.max(self._currentBrightness - deltaTime / 0.2, self.Brightness)
	end

	local brightness = self._currentBrightness ^ 2
	if self.Light then self.Light.Brightness = self._lightBrightness * brightness end
	self.Instance.Color = self.DisabledColor:Lerp(self.EnabledColor, self._currentBrightness)
end

function Headlight.SetBrightness(self: Headlight, brightness: number) self.Brightness = brightness end

return Headlight
