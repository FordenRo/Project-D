local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local SpeedEffect = {}
SpeedEffect.__index = SpeedEffect

export type EffectFrame = {
	Instance: Frame,
	Rotation: number,
	Force: number,
	Position: number,

	Move: (self: EffectFrame, delta: number) -> (),
}

export type SpeedEffect = {
	Vehicle: VehicleTypes.ClientVehicle,
	Parent: GuiObject,

	new: (
		self: SpeedEffect,
		vehicle: VehicleTypes.ClientVehicle,
		parent: GuiObject
	) -> SpeedEffect,
}

type SpeedEffectImpl = {
	trove: Trove.Trove,
	lastSpawn: number,
	effects: { EffectFrame },
} & SpeedEffect

function SpeedEffect.new(vehicle: VehicleTypes.ClientVehicle, parent: GuiObject)
	local self: SpeedEffectImpl = setmetatable({}, SpeedEffect) :: any

	self.Parent = parent
	self.Vehicle = vehicle
	self.effects = {}
	self.lastSpawn = 0

	self.trove = Trove.new()
	self.trove:BindToRenderStep(
		"SpeedEffect",
		Enum.RenderPriority.Camera.Value - 1,
		function(deltaTime) Update(self, deltaTime) end
	)
	self.trove:AttachToInstance(parent)

	return self
end

function createEffect(rotation: number, force: number)
	local effect = {} :: EffectFrame

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.SizeConstraint = Enum.SizeConstraint.RelativeXX
	frame.Size = UDim2.fromScale(0.3, force ^ 0.8 * 0.001)
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

function Update(self: SpeedEffectImpl, deltaTime: number)
	if self.Vehicle.Velocity.Magnitude > 60 then
		local force = math.clamp(
			MathUtil.Map(self.Vehicle.Velocity.Magnitude, 60, 200),
			0,
			1
		)
		local debounce = MathUtil.Lerp(1 / 3, 1 / 200, force ^ 0.8)
		if tick() - self.lastSpawn > debounce then
			local effect = createEffect(math.random() * 360, force)
			effect:Move(math.min(force, 0.5))
			effect.Instance.Parent = self.Parent
			self.trove:Add(effect)

			self.lastSpawn = tick()
			table.insert(self.effects, effect)
		end
	end

	for k, effect in self.effects do
		local position = effect.Position - effect.Force * deltaTime * 6
		effect:Move(position)

		if position < 0 then
			table.remove(self.effects, k)
			self.trove:Remove(effect)
		end
	end
end

function SpeedEffect.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == SpeedEffect
end

return table.freeze({
	new = SpeedEffect.new,
	Is = SpeedEffect.Is,
})
