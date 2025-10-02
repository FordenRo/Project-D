local Spring = {}
Spring.__index = Spring

export type Spring = {
	Mass: number,
	Damping: number,
	Stiffness: number,
	Offset: number,
	Velocity: number,
	Goal: number,

	Update: (self: Spring, deltaTime: number) -> (),
}

function Spring.new(
	mass: number,
	damping: number,
	stiffness: number,
	initialOffset: number?,
	goal: number?
): Spring
	local self: Spring = setmetatable({}, Spring) :: any

	self.Mass = mass
	self.Damping = damping
	self.Stiffness = stiffness
	self.Goal = goal or 0
	self.Offset = initialOffset or 0
	self.Velocity = 0

	return self
end

function Spring.Update(self: Spring, deltaTime: number)
	local offset = self.Offset - self.Goal

	local spring_force = -self.Stiffness * offset
	local damping_force = -self.Damping * self.Velocity

	local force = spring_force + damping_force

	local acceleration = force / self.Mass
	self.Velocity += acceleration * deltaTime
	self.Offset += self.Velocity * deltaTime
end

function Spring.Is(obj: any): boolean
	return typeof(obj) == "table" and getmetatable(obj) == Spring
end

return table.freeze({
	new = Spring.new,
	Is = Spring.Is,
})
