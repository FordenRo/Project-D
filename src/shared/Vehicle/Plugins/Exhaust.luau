local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

if not RunService:IsServer() then return nil end

local Exhaust = {}
Exhaust.__index = Exhaust

local STRENGTH = 0.08

export type Exhaust = typeof(setmetatable(
	{} :: {
		Vehicle: VehicleTypes.ServerVehicle,
		Exhaust: BasePart,
		Weld: Weld,
	},
	Exhaust
))

function Exhaust.new(vehicle: VehicleTypes.ServerVehicle)
	local self = setmetatable({}, Exhaust) :: Exhaust

	self.Vehicle = vehicle
	self.Exhaust = self.Vehicle.Instance.Misc:FindFirstChild("Exhaust")

	self.Weld = Instance.new("Weld")
	self.Weld.Part0 = self.Exhaust
	self.Weld.Part1 = self.Vehicle.Instance.Body["#Weight"]
	self.Weld.C0 = CFrame.new(0, 0, 0)
	self.Weld.C1 = self.Vehicle.Instance.Body["#Weight"].CFrame:Inverse() * self.Exhaust.CFrame
	self.Weld.Parent = self.Exhaust

	RunService.Heartbeat:Connect(function() self:Update() end)

	return self
end

function Exhaust.Update(self: Exhaust)
	if not self.Vehicle.IsOn and not self.Vehicle.Starting then return end

	local rpmDelta = math.clamp(MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Tune.PeakRPM) ^ 0.5, 0.2, 0.8)
	rpmDelta -= (1 - self.Vehicle.Throttle) * MapToRange(self.Vehicle.RPM, 0, self.Vehicle.Tune.PeakRPM) ^ 1.5 * 1.5

	local t = math.sin(tick() * 60)
	local offset = Vector3.new(
		math.noise(t, 0, 0) * (1 - rpmDelta) * STRENGTH,
		math.noise(0, t, 0) * (1 - rpmDelta) * STRENGTH,
		math.noise(0, 0, t) * (1 - rpmDelta) * STRENGTH
	)

	self.Weld.C0 = CFrame.new(offset)
end

return Exhaust
