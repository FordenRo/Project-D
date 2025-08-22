local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseBrakeDisk = require(ReplicatedStorage.Shared.Classes.BaseBrakeDisk)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ServerBrakeDisk = setmetatable({}, BaseBrakeDisk)
ServerBrakeDisk.__index = ServerBrakeDisk

type ServerBrakeDisk = VehicleTypes.ServerBrakeDisk

function ServerBrakeDisk.new(wheel: VehicleTypes.ServerWheel, instance: BasePart)
	local self: ServerBrakeDisk = setmetatable(BaseBrakeDisk.new(wheel, instance), ServerBrakeDisk) :: any

	self._conn = self._Remote.OnServerEvent:Connect(function(_, ...) Update(self, ...) end)

	return self
end

function Update(self: ServerBrakeDisk, temperature: number, color: Color3, volume: number, pitch: number)
	self.Temperature = temperature
	self.Instance.Color = color
	self.Sound.Volume = volume
	self.Sound.PitchEffect.Octave = pitch
end

function ServerBrakeDisk.Destroy(self: ServerBrakeDisk) self._conn:Disconnect() end

return ServerBrakeDisk
