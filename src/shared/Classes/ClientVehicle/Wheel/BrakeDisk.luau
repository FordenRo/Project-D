local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrakeDiskPacket = require(ReplicatedStorage.Shared.Packets.BrakeDiskPacket)
local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ClientBrakeDisk = {}
ClientBrakeDisk.__index = ClientBrakeDisk

type ClientBrakeDisk = VehicleTypes.ClientBrakeDisk

function ClientBrakeDisk.new(wheel: VehicleTypes.ClientWheel, instance: BasePart): ClientBrakeDisk
	local self: ClientBrakeDisk = setmetatable({}, ClientBrakeDisk) :: any

	self.Instance = instance
	self.Wheel = wheel
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

	self._cons = {
		RunService.Heartbeat:Connect(function(deltaTime) Update(self, deltaTime) end),
		self._RE.OnClientEvent:Connect(function(...) Replicate(self, ...) end),
	}
	self._task = task.spawn(function()
		while task.wait(1 / 30) do
			local data = {
				Temperature = self.Temperature,
				Color = self.Instance.Color,
				Volume = self.Volume,
				Pitch = self.Sound.PitchEffect.Octave,
			}
			self._RE:FireServer(self.Temperature, Serialization.Serialize(BrakeDiskPacket, data))
		end
	end)

	return self
end

function Update(self: ClientBrakeDisk, deltaTime: number)
	if not self.Wheel.Vehicle.IsDriven then return end

	local GlobalTemperature = game.Workspace:GetAttribute("GlobalTemperature") :: number

	local inBrake = self.Wheel.Vehicle.Brake :: number > 0 or self.Wheel.Vehicle.PBrake
	local rotSpeed = self.Wheel.Instance.AssemblyAngularVelocity.Magnitude / 360
	self.Sound.Playing = true
	if inBrake then
		self.Temperature += self.Wheel.Instance.BV.MotorMaxTorque * rotSpeed * deltaTime
		self.Volume = Lerp(self.Volume, self.Wheel.Instance.BV.MotorMaxTorque * rotSpeed ^ 0.8 / 5000, deltaTime * 5)
		self.Sound.PitchEffect.Octave = 0.9 + self.Wheel.Instance.BV.MotorMaxTorque * rotSpeed ^ 0.8 / 1000
	else
		self.Volume = Lerp(self.Volume, 0, deltaTime * 5)
	end
	self.Temperature = Lerp(self.Temperature, GlobalTemperature, deltaTime * 0.3)
	self.Sound.Volume = self.Volume

	local colorDelta = math.clamp(MapToRange(self.Temperature, 80, 200), 0, 1)
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
	self.Instance.Color = data.Color
	self.Sound.PitchEffect.Octave = data.Pitch
	self.Sound.Volume = self.Volume
	self.Sound.Playing = true
end

function ClientBrakeDisk.Destroy(self: ClientBrakeDisk)
	for _, v in self._cons do
		v:Disconnect()
	end
	task.cancel(self._task)
end

return ClientBrakeDisk
