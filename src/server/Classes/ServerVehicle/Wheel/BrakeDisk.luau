local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ServerBrakeDisk = {}
ServerBrakeDisk.__index = ServerBrakeDisk

type ServerBrakeDisk = VehicleTypes.ServerBrakeDisk

function ServerBrakeDisk.new(wheel: VehicleTypes.ServerWheel, instance: BasePart): ServerBrakeDisk
	local self: ServerBrakeDisk = setmetatable({}, ServerBrakeDisk) :: any

	self.Instance = instance
	self.Wheel = wheel

	self._RE = Instance.new("UnreliableRemoteEvent")
	self._RE.Name = "_DiskRE"
	self._RE.Parent = instance

	self._conn = self._RE.OnServerEvent:Connect(function(...) Replicate(self, ...) end)

	return self
end

function Replicate(self: ServerBrakeDisk, sender: Player, buf: buffer)
	for _, player in Players:GetPlayers() do
		if player == sender then continue end
		if not player.Character or (player.Character:GetPivot().Position - self.Instance.Position).Magnitude > 50 then
			self._RE:FireClient(player)
			continue
		end

		self._RE:FireClient(player, buf)
	end
end

function ServerBrakeDisk.Destroy(self: ServerBrakeDisk) self._conn:Disconnect() end

return ServerBrakeDisk
