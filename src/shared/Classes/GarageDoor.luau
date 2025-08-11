local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local GarageDoor = {}
GarageDoor.__index = GarageDoor

export type GarageDoor = typeof(setmetatable(
	{} :: {
		Instance: Model & {
			Hinge: BasePart,
			Parts: Folder,
		},
		Parts: { BasePart },
		_startPositions: { Vector3 },
		_relativePositions: { number },
		_sep: number,
		_conn: RBXScriptConnection,
		Length: number,
		Position: number,
		Speed: number,
		Opening: boolean,
		Closing: boolean,
	},
	GarageDoor
))

function GarageDoor.new(instance: Model)
	local self = setmetatable({}, GarageDoor) :: GarageDoor

	self.Instance = instance

	self.Parts = {}
	for _, v in self.Instance.Parts:GetChildren() do
		if not v:IsA("BasePart") then continue end

		table.insert(self.Parts, v)
	end
	table.sort(self.Parts, function(a, b) return a.Position.Y < b.Position.Y end)

	self.Length = self.Parts[#self.Parts].Position.Y - self.Parts[1].Position.Y
	self.Position = 0
	self.Speed = 0
	self.Closing = false
	self.Opening = false

	self._relativePositions = {}
	self._startPositions = {}
	for k, v in self.Parts do
		self._startPositions[k] = v.Position
		self._relativePositions[k] = (v.Position.Y - self._startPositions[1].Y) / self.Length
	end
	self._sep = (self._startPositions[2].Y - self._startPositions[1].Y) / self.Length / 2
	self._conn = RunService.Heartbeat:Connect(function(deltaTime) self:Update(deltaTime) end)

	return self
end

function calcCFrame(self: GarageDoor, position: number, index: number)
	local relativePosition = self._relativePositions[index] + position
	local partPosition, angle

	if relativePosition <= 1 - self._sep then
		partPosition = Vector3.new(0, relativePosition)
		angle = 0
	elseif relativePosition > 1 - self._sep and relativePosition < 1 + self._sep * 2 then
		local top = Vector3.new(
			math.max((relativePosition - 1 + self._sep) * 1.2, 0 + self._sep) - self._sep,
			math.min(relativePosition + self._sep, 1 + self._sep)
		)
		local bottom = Vector3.new(
			math.max(relativePosition - 1 - self._sep, 0 + self._sep) - self._sep,
			math.min(relativePosition - self._sep, 1 + self._sep)
		)

		local direction = (top - bottom).Unit
		angle = math.pi / 2 - math.atan2(direction.Y, direction.X)
		partPosition = (bottom + direction * self._sep) * Vector3.new(-1, 1, 1)
	else
		partPosition = Vector3.new(-relativePosition + 1 + self._sep, 1 + self._sep)
		angle = math.pi / 2
	end

	return CFrame.new(self._startPositions[1] + partPosition * self.Length) * CFrame.fromAxisAngle(Vector3.zAxis, angle)
end

function GarageDoor.Update(self: GarageDoor, deltaTime: number)
	if not self.Closing and not self.Opening then return end

	self.Speed = Lerp(self.Speed, self.Opening and 1 or self.Closing and -1 or 0, deltaTime)
	self.Position = math.clamp(self.Position + deltaTime / 5 * self.Speed, 0, 1 + self._sep * 2)

	for k, part in self.Parts do
		part.CFrame = calcCFrame(self, self.Position, k)
	end

	if self.Position == 0 or self.Position == 1 + self._sep * 2 then
		self.Closing = false
		self.Opening = false
		self.Speed = 0
	end
end

function GarageDoor.Open(self: GarageDoor)
	self.Closing = false
	self.Opening = true
end

function GarageDoor.Close(self: GarageDoor)
	self.Opening = false
	self.Closing = true
end

function GarageDoor.Destroy(self: GarageDoor) self._conn:Disconnect() end

return GarageDoor
