local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

if not RunService:IsServer() then return nil end

local STRENGTH = 0.08

local Exhaust = {}
Exhaust.__index = Exhaust

export type Exhaust = typeof(setmetatable(
	{} :: {
		Vehicle: VehicleTypes.ServerVehicle,
		Exhaust: BasePart & { Attachment: Attachment? },
		Emitter: ParticleEmitter,
		_startEmitter: {
			Color: ColorSequence,
			Size: NumberSequence,
		},
		Weld: Weld,
	},
	Exhaust
))

function Exhaust.new(vehicle: VehicleTypes.ServerVehicle)
	local self: Exhaust = setmetatable({}, Exhaust) :: any

	self.Vehicle = vehicle
	self.Exhaust = self.Vehicle.Instance.Misc:FindFirstChild("Exhaust")

	if not self.Exhaust then
		warn(self.Vehicle.Instance.Name .. ".Misc.Exhaust not found, exhaust plugin wouldn't work")
		return
	end

	assert(
		self.Exhaust:FindFirstChild("Attachment"),
		self.Vehicle.Instance.Name .. ".Misc.Exhaust.Attachment not found"
	)

	self.Emitter = ReplicatedStorage.Vehicle.ExhaustEmitter:Clone()
	self.Emitter.Parent = self.Exhaust.Attachment
	self._startEmitter = {
		Color = self.Emitter.Color,
		Size = self.Emitter.Size,
	}

	self.Weld = Instance.new("Weld")
	self.Weld.Part0 = self.Exhaust
	self.Weld.Part1 = self.Vehicle.Instance.Body["#Weight"]
	self.Weld.C0 = CFrame.new(0, 0, 0)
	self.Weld.C1 = self.Vehicle.Instance.Body["#Weight"].CFrame:Inverse() * self.Exhaust.CFrame
	self.Weld.Parent = self.Exhaust

	RunService.Heartbeat:Connect(function() Update(self) end)

	return self
end

function Update(self: Exhaust)
	self.Emitter.Enabled = (self.Vehicle.IsOn or self.Vehicle.Starting)
		and (self.Vehicle.Velocity.Magnitude < 10 or self.Vehicle.RPM > self.Vehicle.Tune.Redline)

	if not self.Vehicle.IsOn and not self.Vehicle.Starting then return end

	local rpmDelta = math.clamp(MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Tune.ShiftRPM) ^ 0.5, 0.2, 0.8)
	rpmDelta -= (1 - self.Vehicle.Throttle) * MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Tune.ShiftRPM) ^ 1.5 * 1.5

	local t = math.sin(tick() * 60)
	local offset = Vector3.new(
		math.noise(t, 0, 0) * (1 - rpmDelta) * STRENGTH,
		math.noise(0, t, 0) * (1 - rpmDelta) * STRENGTH,
		math.noise(0, 0, t) * (1 - rpmDelta) * STRENGTH
	)

	self.Weld.C0 = CFrame.new(offset)

	-- Update emitter
	if self.Vehicle.Velocity.Magnitude < 10 or self.Vehicle.RPM > self.Vehicle.Tune.Redline then
		rpmDelta = MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Tune.ShiftRPM) ^ 0.5
		local speed = rpmDelta * 4
		local rate = rpmDelta * 50

		self.Emitter.Rate = rate
		self.Emitter.Speed = NumberRange.new(speed / 1.5, speed * 1.5)

		if self.Vehicle.RPM > self.Vehicle.Tune.Redline then
			self.Emitter.Rate *= 2
			local damage = math.clamp((self.Vehicle.RPM - self.Vehicle.Tune.Redline) / 3000, 0, 1)
			self.Emitter.Color = ColorSequence.new(Color3.new())

			local keypoints = {}
			for k, v in self._startEmitter.Size.Keypoints do
				table.insert(keypoints, NumberSequenceKeypoint.new(v.Time, v.Value * (1 + damage), v.Envelope))
			end
			self.Emitter.Size = NumberSequence.new(keypoints)
		else
			self.Emitter.Color = self._startEmitter.Color
			self.Emitter.Size = self._startEmitter.Size
		end
	end
end

return Exhaust
