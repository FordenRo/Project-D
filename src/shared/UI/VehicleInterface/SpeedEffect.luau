local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local SpeedEffect = {}
SpeedEffect.__index = SpeedEffect

type EffectFrame = VehicleTypes.EffectFrame
type SpeedEffect = VehicleTypes.SpeedEffect

function SpeedEffect.new(vehicle: VehicleTypes.ClientVehicle, parent: GuiObject)
	local self: SpeedEffect = setmetatable({}, SpeedEffect) :: any

	self.Parent = parent
	self.Vehicle = vehicle
	self.Effects = {}
	self._LastSpawn = 0

	RunService:BindToRenderStep(
		"SpeedEffect",
		Enum.RenderPriority.Camera.Value + 1,
		function(deltaTime) self:Update(deltaTime) end
	)

	return self
end

function createEffect(rotation: number, force: number)
	local effect = {} :: EffectFrame

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.SizeConstraint = Enum.SizeConstraint.RelativeXX
	frame.Size = UDim2.fromScale(0.5, force * 0.01)
	frame.Rotation = rotation

	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new(1, 0)
	gradient.Parent = frame

	effect.Instance = frame
	effect.Rotation = rotation
	effect.Force = force
	effect.Position = 0

	function effect.Move(self: EffectFrame, position: number)
		local scrSize = game.Workspace.CurrentCamera.ViewportSize
		local r = effect.Instance.AbsoluteSize.X / 2
		local x = math.cos(math.rad(self.Rotation)) * (1 - position)
		local y = math.sin(math.rad(self.Rotation)) * (1 - position)
		local dir = Vector2.new(x, y)
		local pos = dir * scrSize.X / 2 + dir * r
		self.Instance.Position = UDim2.new(0.5, pos.X, 0.5, pos.Y)
		self.Position = position
	end

	function effect.Destroy(self: EffectFrame) self.Instance:Destroy() end

	return effect
end

function SpeedEffect.Update(self: SpeedEffect, deltaTime: number)
	if self.Vehicle.Velocity.Magnitude > 80 then
		local force = MapToRange(self.Vehicle.Velocity.Magnitude, 80, 200)
		local debounce = Lerp(1 / 3, 1 / 60, force ^ 0.8)
		if tick() - self._LastSpawn > debounce then
			local effect = createEffect(math.random() * 360, force)
			effect:Move(math.min(force, 0.5))
			effect.Instance.Parent = self.Parent

			self._LastSpawn = tick()
			table.insert(self.Effects, effect)
		end
	end

	for _, effect in self.Effects do
		local position = effect.Position - effect.Force * deltaTime * 4
		effect:Move(position)

		if position < 0 then effect:Destroy() end
	end
end

return SpeedEffect
