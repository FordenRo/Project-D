local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MakeUtil = require(ReplicatedStorage.Shared.Utils.MakeUtil)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

local STRENGTH = 0.08

local ExhaustController = {}
ExhaustController.__index = ExhaustController

export type ExhaustController = typeof(setmetatable(
	{} :: {
		_startEmitter: {
			Color: ColorSequence,
			Size: NumberSequence,
			Transparency: NumberSequence,
		},
		_startCFrame: CFrame,
		Vehicle: VehicleTypes.ClientVehicle,
		Instance: BasePart,
		Emitter: ParticleEmitter,
		Motor: Motor6D,
	},
	ExhaustController
))

function ExhaustController.new(vehicle: VehicleTypes.ClientVehicle): ExhaustController
	local self: ExhaustController = setmetatable({}, ExhaustController) :: any

	self.Vehicle = vehicle

	self.Instance = self.Vehicle.Instance.Body:FindFirstChild("Exhaust") :: any
	if not self.Instance then
		warn(`Exhaust not found in {self.Vehicle.Instance.Name}`)
		return self
	end

	local attachment = self.Instance:FindFirstChild("Attachment")
	if not attachment then
		warn(`Exhaust emitter's attachment not found in {self.Vehicle.Instance.Name}`)
		return self
	end

	self._startCFrame = self.Instance.CFrame

	-- Create emitter
	self.Emitter = ReplicatedStorage.Vehicle.ExhaustEmitter:Clone()
	self.Emitter.Parent = attachment
	self._startEmitter = {
		Color = self.Emitter.Color,
		Size = self.Emitter.Size,
		Transparency = self.Emitter.Transparency,
	}

	-- Remove welds
	for _, v in self.Instance:GetJoints() do
		v:Destroy()
	end

	self.Motor = MakeUtil.Motor(self.Vehicle.Instance.DriveSeat, self.Instance)

	local trove = Trove.new()
	trove:Connect(RunService.Heartbeat, function() Update(self) end)
	trove:AttachToInstance(self.Vehicle.Instance)

	return self
end

function Update(self: ExhaustController)
	local canUpdate = (self.Vehicle.IsOn or self.Vehicle.Starting)
		and (player.Character:GetPivot().Position - self.Vehicle.WeightPart.Position).Magnitude < 70

	self.Emitter.Enabled = canUpdate
	if not canUpdate then return end

	local rpmDelta = math.clamp(MathUtil.MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Engine.Tune.ShiftRPM), 0.2, 0.8)
	rpmDelta -= (1 - self.Vehicle.Throttle) * MathUtil.MapToRange(
		self.Vehicle.RPM,
		0,
		self.Vehicle.Engine.Tune.ShiftRPM
	) ^ 1.5

	local t = math.sin(tick() * 30)
	local offset = Vector3.new(
		math.noise(t, 0, 0) * (1 - rpmDelta) * STRENGTH,
		math.noise(0, t, 0) * (1 - rpmDelta) * STRENGTH,
		math.noise(0, 0, t) * (1 - rpmDelta) * STRENGTH
	)

	self.Motor.Transform = CFrame.new(offset)

	-- Update emitter
	rpmDelta = MathUtil.MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Engine.Tune.ShiftRPM) ^ 0.5
	local speed = rpmDelta * 7
	local rate = rpmDelta * 30

	self.Emitter.Rate = rate
	self.Emitter.Speed = NumberRange.new(speed / 1.2, speed * 1.2)

	if self.Vehicle.RPM > self.Vehicle.Engine.Tune.Redline then
		self.Emitter.Rate *= 2
		self.Emitter.Transparency = self._startEmitter.Transparency
		self.Emitter.Color = ColorSequence.new(Color3.new())

		local damage = math.clamp((self.Vehicle.RPM - self.Vehicle.Engine.Tune.Redline) / 1000, 0, 1)
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

return ExhaustController
