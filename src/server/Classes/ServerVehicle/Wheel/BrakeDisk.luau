local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ServerBrakeDisk = {}
ServerBrakeDisk.__index = ServerBrakeDisk

type ServerBrakeDisk = VehicleTypes.ServerBrakeDisk

type ServerBrakeDiskImpl = {
	RE: UnreliableRemoteEvent,
} & ServerBrakeDisk

function ServerBrakeDisk.new(
	wheel: VehicleTypes.ServerWheel,
	instance: BasePart
): ServerBrakeDisk
	local self: ServerBrakeDiskImpl = setmetatable({}, ServerBrakeDisk) :: any

	self.Instance = instance
	self.Wheel = wheel

	self.RE = Instance.new("UnreliableRemoteEvent")
	self.RE.Name = "_DiskRE"
	self.RE.Parent = instance

	local trove = Trove.new()
	trove:Connect(self.RE.OnServerEvent, function(...) Replicate(self, ...) end)
	trove:AttachToInstance(instance)

	return self
end

function Replicate(self: ServerBrakeDiskImpl, sender: Player, buf: buffer)
	for _, player in Players:GetPlayers() do
		if player == sender then continue end
		if
			not player.Character
			or (
					player.Character:GetPivot().Position
					- self.Instance.Position
				).Magnitude
				> 100
		then
			self.RE:FireClient(player)
			continue
		end

		self.RE:FireClient(player, buf)
	end
end

return table.freeze({ new = ServerBrakeDisk.new })
