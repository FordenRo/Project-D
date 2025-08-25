local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local BaseBrakeDisk = {}
BaseBrakeDisk.__index = BaseBrakeDisk

type BaseBrakeDisk = VehicleTypes.BaseBrakeDisk

function BaseBrakeDisk.new(wheel: VehicleTypes.BaseWheel, instance: BasePart): BaseBrakeDisk
	local self: BaseBrakeDisk = setmetatable({}, BaseBrakeDisk) :: any

	self.Instance = instance
	self.Wheel = wheel
	self.Temperature = game.Workspace:GetAttribute("GlobalTemperature") :: number

	if RunService:IsServer() then
		self._Remote = Instance.new("UnreliableRemoteEvent")
		self._Remote.Name = "_DiskRemote"
		self._Remote.Parent = self.Instance

		self.Sound = Instance.new("Sound") :: any
		self.Sound.Name = "BrakeWhistle"
		self.Sound.SoundId = "rbxassetid://185857550"
		self.Sound.PlaybackSpeed = 0.9

		local pitch = Instance.new("PitchShiftSoundEffect")
		pitch.Octave = 1
		pitch.Name = "PitchEffect"
		pitch.Parent = self.Sound

		self.Sound.Parent = wheel.Instance
	else
		self._Remote = self.Instance:WaitForChild("_DiskRemote") :: UnreliableRemoteEvent

		self.Sound = wheel.Instance:WaitForChild("BrakeWhistle") :: any
	end

	return self
end

return BaseBrakeDisk
