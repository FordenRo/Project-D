--!native
local MathUtil = {}

function MathUtil.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function MathUtil.Map(a: number, min: number, max: number): number
	return (a - min) / (max - min)
end

function MathUtil.Noise(position: Vector3): number
	return math.noise(position.X, position.Y, position.Z)
end

return table.freeze(MathUtil)
