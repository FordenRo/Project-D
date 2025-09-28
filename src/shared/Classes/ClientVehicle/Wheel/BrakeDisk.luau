local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrakeDiskPacket = require(ReplicatedStorage.Shared.Packets.BrakeDiskPacket)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ClientBrakeDisk = {}
ClientBrakeDisk.__index = ClientBrakeDisk

type ClientBrakeDisk = VehicleTypes.ClientBrakeDisk

function ClientBrakeDisk.new(wheel: VehicleTypes.ClientWheel, instance: BasePart): ClientBrakeDisk
	local self: ClientBrakeDisk = setmetatable({}, ClientBrakeDisk) :: any

	self.Instance = instance
	self.Wheel = wheel
	self.Vehicle = self.Wheel.Vehicle
	self.Volume = 0
	self.Temperature = game.Workspace:GetAttribute("GlobalTemperature") :: number
	self._startColor = self.Instance.Color

	self.Sound = Instance.new("Sound") :: any
	self.Sound.Volume = 0
	self.Sound.PlaybackSpeed = 0.9
	self.Sound.SoundId = "rbxassetid://185857550"
	self.Sound.Name = "BrakeWhistle"

	local pitch = Instance.new("PitchShiftSoundEffect")
	pitch.Octave = 1
	pitch.Name = "PitchEffect"
	pitch.Parent = self.Sound

	self.Sound.Parent = instance

	self._RE = instance:WaitForChild("_DiskRE") :: UnreliableRemoteEvent

	local trove = Trove.new()
	trove:Connect(RunService.Heartbeat, function(deltaTime) Update(self, deltaTime) end)
	trove:Connect(self._RE.OnClientEvent, function(buf) Replicate(self, buf) end)
	trove:Add(task.spawn(function()
		while true do
			task.wait(1 / 20)
			if not self.Vehicle.IsDriven then continue end

			local data = {
				Temperature = self.Temperature,
				Color = self.Instance.Color,
				Volume = self.Volume,
				Pitch = self.Sound.PitchEffect.Octave,
			}
			self._RE:FireServer(Serialization.Serialize(BrakeDiskPacket, data))
		end
	end))
	trove:AttachToInstance(self.Instance)

	return self
end

function Update(self: ClientBrakeDisk, deltaTime: number)
	if not self.Vehicle.IsDriven then return end

	local GlobalTemperature = game.Workspace:GetAttribute("GlobalTemperature") :: number

	local inBrake = self.Wheel.Vehicle.Brake :: number > 0 or self.Wheel.Vehicle.PBrake
	local rotSpeed = self.Wheel.Instance.AssemblyAngularVelocity.Magnitude / 360
	self.Sound.Playing = true
	if inBrake then
		self.Temperature += self.Wheel.Instance.BV.MotorMaxTorque * rotSpeed * deltaTime
		self.Volume =
			MathUtil.Lerp(self.Volume, self.Wheel.Instance.BV.MotorMaxTorque * rotSpeed ^ 0.8 / 5000, deltaTime * 5)
		self.Sound.PitchEffect.Octave = 0.9 + self.Wheel.Instance.BV.MotorMaxTorque * rotSpeed ^ 0.8 / 1000
	else
		self.Volume = MathUtil.Lerp(self.Volume, 0, deltaTime * 5)
	end
	self.Temperature = MathUtil.Lerp(self.Temperature, GlobalTemperature, deltaTime * 0.3)
	self.Sound.Volume = self.Volume

	updateColor(self)
end

function updateColor(self: ClientBrakeDisk)
	local colorDelta = math.clamp(MathUtil.MapToRange(self.Temperature, 80, 200), 0, 1)
	self.Instance.Color = self._startColor:Lerp(Color3.new(1, 0.3, 0), colorDelta)
end

function Replicate(self: ClientBrakeDisk, buf: buffer?)
	if not buf then
		self.Sound.Playing = false
		self.Instance.Color = self._startColor
		return
	end

	local data = Serialization.Deserialize(BrakeDiskPacket, buf)

	self.Volume = data.Volume
	self.Temperature = data.Temperature
	self.Sound.PitchEffect.Octave = data.Pitch
	self.Sound.Volume = self.Volume
	self.Sound.Playing = true
	updateColor(self)
end

return ClientBrakeDisk
