local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Shared.Classes.Component)

local Spring = {}
Spring.__extends = Component

export type Spring = {
	Mass: number,
	Damping: number,
	Stiffness: number,
	Offset: number,
	Velocity: number,
	Goal: number,

	Update: (self: Spring, deltaTime: number) -> (),
} & Component.Component

function Spring.new(
	mass: number,
	damping: number,
	stiffness: number,
	initialOffset: number?,
	goal: number?
): Spring
	local self: Spring = Component(Spring) :: any

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

return table.freeze(Spring :: any) :: {
	new: (
		mass: number,
		damping: number,
		stiffness: number,
		initialOffset: number?,
		goal: number?
	) -> Spring,
}
