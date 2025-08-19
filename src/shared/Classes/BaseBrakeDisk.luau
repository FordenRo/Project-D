local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local BaseBrakeDisk = {}
BaseBrakeDisk.__index = BaseBrakeDisk

type BaseBrakeDisk = VehicleTypes.BaseBrakeDisk

function BaseBrakeDisk.new(wheel: VehicleTypes.BaseWheel, instance: BasePart)
	local self: BaseBrakeDisk = setmetatable({}, BaseBrakeDisk) :: any

	self.Instance = instance
	self.Wheel = wheel
	self.Temperature = game.Workspace:GetAttribute("GlobalTemperature") :: number

	if RunService:IsServer() then
		self._Remote = Instance.new("UnreliableRemoteEvent")
		self._Remote.Name = "_DiskRemote"
		self._Remote.Parent = self.Instance
	else
		self._Remote = self.Instance:WaitForChild("_DiskRemote") :: UnreliableRemoteEvent
	end

	return self
end

return BaseBrakeDisk
