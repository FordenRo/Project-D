--!strict
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

export type ExhaustController = {
	Vehicle: VehicleTypes.ClientVehicle,
	Instance: BasePart,
}

type ExhaustControllerImpl = {
	emitter: ParticleEmitter,
	motor: Motor6D,
	startEmitter: {
		Color: ColorSequence,
		Size: NumberSequence,
		Transparency: NumberSequence,
	},
	startCFrame: CFrame,
} & ExhaustController

function ExhaustController.new(
	vehicle: VehicleTypes.ClientVehicle
): ExhaustController
	local self: ExhaustControllerImpl =
		setmetatable({}, ExhaustController) :: any

	self.Vehicle = vehicle

	self.Instance = self.Vehicle.Instance.Body:FindFirstChild("Exhaust") :: any
	if not self.Instance then
		warn(`Exhaust not found in {self.Vehicle.Instance.Name}`)
		return self
	end

	local attachment = self.Instance:FindFirstChild("Attachment")
	if not attachment then
		warn(
			`Exhaust emitter's attachment not found in {self.Vehicle.Instance.Name}`
		)
		return self
	end

	self.startCFrame = self.Instance.CFrame

	-- Create emitter
	self.emitter = ReplicatedStorage.Vehicle.ExhaustEmitter:Clone()
	self.emitter.Parent = attachment
	self.startEmitter = {
		Color = self.emitter.Color,
		Size = self.emitter.Size,
		Transparency = self.emitter.Transparency,
	}

	-- Remove welds
	for _, v in self.Instance:GetJoints() do
		v:Destroy()
	end

	self.motor = MakeUtil.Motor(self.Vehicle.Instance.DriveSeat, self.Instance)

	local trove = Trove.new()
	trove:Connect(RunService.Heartbeat, function() Update(self) end)
	trove:AttachToInstance(self.Vehicle.Instance)

	return self
end

function Update(self: ExhaustControllerImpl)
	local canUpdate = player.Character ~= nil
		and (self.Vehicle.Engine.IsOn or self.Vehicle.IgnitionState == "Starting")
		and (
				player.Character:GetPivot().Position
				- self.Vehicle.CFrame.Position
			).Magnitude
			< 70

	self.emitter.Enabled = canUpdate
	if not canUpdate then return end

	local rpmDelta = math.clamp(
		MathUtil.Map(self.Vehicle.RPM, 0, self.Vehicle.Engine.Tune.ShiftRPM),
		0.2,
		0.8
	)
	rpmDelta -= (1 - self.Vehicle.Throttle) * MathUtil.Map(
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

	self.motor.Transform = CFrame.new(offset)

	-- Update emitter
	rpmDelta = MathUtil.Map(
		self.Vehicle.RPM,
		0,
		self.Vehicle.Engine.Tune.ShiftRPM
	) ^ 0.5
	local speed = rpmDelta * 7
	local rate = rpmDelta * 30

	self.emitter.Rate = rate
	self.emitter.Speed = NumberRange.new(speed / 1.2, speed * 1.2)

	if self.Vehicle.RPM > self.Vehicle.Engine.Tune.Redline then
		self.emitter.Rate *= 2
		self.emitter.Transparency = self.startEmitter.Transparency
		self.emitter.Color = ColorSequence.new(Color3.new())

		local damage = math.clamp(
			(self.Vehicle.RPM - self.Vehicle.Engine.Tune.Redline) / 1000,
			0,
			1
		)
		local keypoints = {}
		for k, v in self.startEmitter.Size.Keypoints do
			table.insert(
				keypoints,
				NumberSequenceKeypoint.new(
					v.Time,
					v.Value * (1 + damage),
					v.Envelope
				)
			)
		end
		self.emitter.Size = NumberSequence.new(keypoints)
	else
		self.emitter.Color = self.startEmitter.Color
		self.emitter.Size = self.startEmitter.Size

		local transparency = 1
			- math.clamp(self.Vehicle.Velocity.Magnitude / 100, 0, 0.8)
		local keypoints = {}
		for k, v in self.startEmitter.Transparency.Keypoints do
			table.insert(
				keypoints,
				NumberSequenceKeypoint.new(
					v.Time,
					1 - (1 - v.Value) * transparency,
					v.Envelope
				)
			)
		end
		self.emitter.Transparency = NumberSequence.new(keypoints)
	end
end

function ExhaustController.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == ExhaustController
end

return table.freeze({
	new = ExhaustController.new,
	Is = ExhaustController.Is,
})
