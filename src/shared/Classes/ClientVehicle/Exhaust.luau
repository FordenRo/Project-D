local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

local STRENGTH = 0.08

local Exhaust = {}
Exhaust.__index = Exhaust

export type Exhaust = typeof(setmetatable(
	{} :: {
		_startEmitter: {
			Color: ColorSequence,
			Size: NumberSequence,
			Transparency: NumberSequence,
		},
		Vehicle: VehicleTypes.ClientVehicle,
		Exhaust: BasePart & { Attachment: Attachment? },
		Emitter: ParticleEmitter,
		Weld: Weld,
	},
	Exhaust
))

function Exhaust.new(vehicle: VehicleTypes.ClientVehicle)
	local self: Exhaust = setmetatable({}, Exhaust) :: any

	self.Vehicle = vehicle
	self.Exhaust = self.Vehicle.Instance.Body:FindFirstChild("Exhaust") :: any

	if not self.Exhaust then
		warn(self.Vehicle.Instance.Name .. ".Misc.Exhaust not found, exhaust wouldn't work")
		return
	end

	assert(
		self.Exhaust:FindFirstChild("Attachment"),
		self.Vehicle.Instance.Name .. ".Misc.Exhaust.Attachment not found"
	)

	-- Create emitter
	self.Emitter = ReplicatedStorage.Vehicle.ExhaustEmitter:Clone()
	self.Emitter.Parent = self.Exhaust.Attachment
	self._startEmitter = {
		Color = self.Emitter.Color,
		Size = self.Emitter.Size,
		Transparency = self.Emitter.Transparency,
	}

	self.Weld = self.Exhaust:GetJoints()[1] :: any

	RunService.Heartbeat:Connect(function() Update(self) end)

	return self
end

function Update(self: Exhaust)
	local canUpdate = (self.Vehicle.IsOn or self.Vehicle.Starting)
		and (player.Character:GetPivot().Position - self.Vehicle.WeightPart.Position).Magnitude < 70

	self.Emitter.Enabled = canUpdate
	if not canUpdate then return end

	local rpmDelta = math.clamp(MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Tune.ShiftRPM), 0.2, 0.8)
	rpmDelta -= (1 - self.Vehicle.Throttle) * MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Tune.ShiftRPM) ^ 1.5

	local t = math.sin(tick() * 30)
	local offset = Vector3.new(
		math.noise(t, 0, 0) * (1 - rpmDelta) * STRENGTH,
		math.noise(0, t, 0) * (1 - rpmDelta) * STRENGTH,
		math.noise(0, 0, t) * (1 - rpmDelta) * STRENGTH
	)

	self.Weld.C0 = CFrame.new(offset)

	-- Update emitter
	rpmDelta = MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Tune.ShiftRPM) ^ 0.5
	local speed = rpmDelta * 7
	local rate = rpmDelta * 30

	self.Emitter.Rate = rate
	self.Emitter.Speed = NumberRange.new(speed / 1.2, speed * 1.2)

	if self.Vehicle.RPM > self.Vehicle.Tune.Redline then
		self.Emitter.Rate *= 2
		self.Emitter.Transparency = self._startEmitter.Transparency
		self.Emitter.Color = ColorSequence.new(Color3.new())

		local damage = math.clamp((self.Vehicle.RPM - self.Vehicle.Tune.Redline) / 1000, 0, 1)
		local keypoints = {}
		for k, v in self._startEmitter.Size.Keypoints do
			table.insert(keypoints, NumberSequenceKeypoint.new(v.Time, v.Value * (1 + damage), v.Envelope))
		end
		self.Emitter.Size = NumberSequence.new(keypoints)
	else
		self.Emitter.Color = self._startEmitter.Color
		self.Emitter.Size = self._startEmitter.Size

		local transparency = 1 - math.clamp(self.Vehicle.WeightPart.AssemblyLinearVelocity.Magnitude / 100, 0, 0.8)
		local keypoints = {}
		for k, v in self._startEmitter.Transparency.Keypoints do
			table.insert(keypoints, NumberSequenceKeypoint.new(v.Time, 1 - (1 - v.Value) * transparency, v.Envelope))
		end
		self.Emitter.Transparency = NumberSequence.new(keypoints)
	end
end

return Exhaust
