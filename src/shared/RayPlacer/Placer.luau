local Vector3Range = require(script.Parent.Vector3Range)
local Placer = {}
Placer.__index = Placer

export type PlacerParams = {
	Objects: { PVInstance },
	RayParams: RaycastParams,
	Offset: Vector3Range.Vector3Range,
	Rotation: Vector3Range.Vector3Range,
	-- NormalInfluence: NumberRange,
	Scale: NumberRange,
	Output: Instance,
}

export type Placer = {
	Destroy: (self: Placer) -> (),
}

type PlacerImpl = {
	params: PlacerParams,
	conn: RBXScriptConnection,
	plugin: Plugin,
} & Placer

local getRandomRange = function(value: NumberRange)
	return value.Min + (value.Max - value.Min) * math.random()
end :: ((value: NumberRange) -> number) & ((value: Vector3Range.Vector3Range) -> Vector3)

function Placer.new(plugin: Plugin, params: PlacerParams): Placer
	local self: PlacerImpl = setmetatable({}, Placer) :: any

	self.params = params
	self.plugin = plugin

	local mouse = self.plugin:GetMouse()
	self.conn = mouse.Button1Down:Connect(function()
		local result = workspace:Raycast(
			mouse.UnitRay.Origin,
			mouse.UnitRay.Direction * 1000,
			self.params.RayParams
		)
		if result then
			local instance =
				self.params.Objects[math.random(#self.params.Objects)]:Clone()

			local rot = getRandomRange(self.params.Rotation) * math.rad(1)
			local offset = getRandomRange(self.params.Offset)

			instance:PivotTo(
				CFrame.new(result.Position + offset)
					* CFrame.fromOrientation(rot.X, rot.Y, rot.Z)
			)

			if instance:IsA("Model") then
				instance:ScaleTo(getRandomRange(self.params.Scale))
			end
			instance.Parent = self.params.Output
		end
	end)

	return self
end

function Placer.Destroy(self: PlacerImpl) self.conn:Disconnect() end

return table.freeze({ new = Placer.new })
