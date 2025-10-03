local Vector3Spring = {}
Vector3Spring.__index = Vector3Spring

export type Vector3Spring = {
	Mass: number,
	Damping: number,
	Stiffness: number,
	Offset: Vector3,
	Velocity: Vector3,
	Goal: Vector3,

	Update: (self: Vector3Spring, deltaTime: number) -> (),
}

function Vector3Spring.new(
	mass: number,
	damping: number,
	stiffness: number,
	initialOffset: Vector3?,
	goal: Vector3?
): Vector3Spring
	local self: Vector3Spring = setmetatable({}, Vector3Spring) :: any

	self.Mass = mass
	self.Damping = damping
	self.Stiffness = stiffness
	self.Goal = goal or Vector3.zero
	self.Offset = initialOffset or Vector3.zero
	self.Velocity = Vector3.zero

	return self
end

function Vector3Spring.Update(self: Vector3Spring, deltaTime: number)
	local offset = self.Offset - self.Goal

	local spring_force = -self.Stiffness * offset
	local damping_force = -self.Damping * self.Velocity

	local force = spring_force + damping_force

	local acceleration = force / self.Mass
	self.Velocity += acceleration * deltaTime
	self.Offset += self.Velocity * deltaTime
end

function Vector3Spring.Is(obj: any): boolean
	return typeof(obj) == "table" and getmetatable(obj) == Vector3Spring
end

return table.freeze({
	new = Vector3Spring.new,
	Is = Vector3Spring.Is,
})
