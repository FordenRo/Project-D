local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

local GarageDoor = {}
GarageDoor.__index = GarageDoor

export type GarageDoor = {
	Instance: {
		Hinge: BasePart,
		Parts: Folder,
	} & Model,
	Length: number,
	Position: number,
	Speed: number,
	Opening: boolean,
	Closing: boolean,

	Open: (self: GarageDoor) -> (),
	Close: (self: GarageDoor) -> (),
	Destroy: (self: GarageDoor) -> (),
}

type GarageDoorImpl = {
	trove: Trove.Trove,
	sep: number,
	startPositions: { Vector3 },
	relativePositions: { number },
	parts: { BasePart },
} & GarageDoor

function GarageDoor.new(instance: Instance): GarageDoor
	local self: GarageDoorImpl = setmetatable({}, GarageDoor) :: any

	self.Instance = instance :: any

	self.parts = {}
	for _, v in self.Instance.Parts:GetChildren() do
		if not v:IsA("BasePart") then continue end

		table.insert(self.parts, v)
	end
	table.sort(
		self.parts,
		function(a, b) return a.Position.Y < b.Position.Y end
	)

	self.Length = self.parts[#self.parts].Position.Y - self.parts[1].Position.Y
	self.Position = 0
	self.Speed = 0
	self.Closing = false
	self.Opening = false

	self.relativePositions = {}
	self.startPositions = {}
	for k, v in self.parts do
		self.startPositions[k] = v.Position
		self.relativePositions[k] = (v.Position.Y - self.startPositions[1].Y)
			/ self.Length
	end
	self.sep = (self.startPositions[2].Y - self.startPositions[1].Y)
		/ self.Length
		/ 2

	self.trove = Trove.new()
	self.trove:Connect(
		RunService.Heartbeat,
		function(deltaTime) Update(self, deltaTime) end
	)
	self.trove:AttachToInstance(self.Instance)

	return self
end

function calcCFrame(self: GarageDoorImpl, position: number, index: number)
	local relativePosition = self.relativePositions[index] + position
	local partPosition, angle

	if relativePosition <= 1 - self.sep then
		partPosition = Vector3.new(0, relativePosition)
		angle = 0
	elseif
		relativePosition > 1 - self.sep
		and relativePosition < 1 + self.sep * 2
	then
		local top = Vector3.new(
			math.max((relativePosition - 1 + self.sep) * 1.2, 0 + self.sep)
				- self.sep,
			math.min(relativePosition + self.sep, 1 + self.sep)
		)
		local bottom = Vector3.new(
			math.max(relativePosition - 1 - self.sep, 0 + self.sep) - self.sep,
			math.min(relativePosition - self.sep, 1 + self.sep)
		)

		local direction = (top - bottom).Unit
		angle = math.pi / 2 - math.atan2(direction.Y, direction.X)
		partPosition = (bottom + direction * self.sep) * Vector3.new(-1, 1, 1)
	else
		partPosition =
			Vector3.new(-relativePosition + 1 + self.sep, 1 + self.sep)
		angle = math.pi / 2
	end

	return CFrame.new(self.startPositions[1] + partPosition * self.Length)
		* CFrame.fromAxisAngle(Vector3.zAxis, angle)
end

function Update(self: GarageDoorImpl, deltaTime: number)
	if not self.Closing and not self.Opening then return end

	self.Speed = MathUtil.Lerp(
		self.Speed,
		self.Opening and 1 or self.Closing and -1 or 0,
		deltaTime
	)
	self.Position = math.clamp(
		self.Position + deltaTime / 5 * self.Speed,
		0,
		1 + self.sep * 2
	)

	for k, part in self.parts do
		part.CFrame = calcCFrame(self, self.Position, k)
	end

	if self.Position == 0 or self.Position == 1 + self.sep * 2 then
		self.Closing = false
		self.Opening = false
		self.Speed = 0
	end
end

function GarageDoor.Open(self: GarageDoorImpl)
	self.Closing = false
	self.Opening = true
end

function GarageDoor.Close(self: GarageDoorImpl)
	self.Opening = false
	self.Closing = true
end

function GarageDoor.Destroy(self: GarageDoorImpl) self.Instance:Destroy() end

return table.freeze({ new = GarageDoor.new })
