local Vector3Range = {}

export type Vector3Range = {
	Min: Vector3,
	Max: Vector3,
}

function Vector3Range.new(min: Vector3, max: Vector3?): Vector3Range
	local self = {}

	self.Min = min
	self.Max = max or min

	return self
end

return table.freeze({ new = Vector3Range.new } :: {
	new: ((value: Vector3) -> Vector3Range)
		& ((min: Vector3, max: Vector3) -> Vector3Range),
})
