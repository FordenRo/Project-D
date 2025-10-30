local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LightPacket = require(ReplicatedStorage.Shared.Packets.LightPacket)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ServerLights = {}
ServerLights.__index = ServerLights

export type ServerLights = {
	Vehicle: VehicleTypes.ServerVehicle,
	State: string,
	TurnState: string,
}

type ServerLightsImpl = {
	RE: RemoteEvent,
} & ServerLights

function ServerLights.new(vehicle: VehicleTypes.ServerVehicle): ServerLights
	local self: ServerLightsImpl = setmetatable({}, ServerLights) :: any

	self.Vehicle = vehicle
	self.State = "Off"
	self.TurnState = "Off"

	self.RE = Instance.new("RemoteEvent")
	self.RE.Name = "_LightsRE"
	self.RE.Parent = self.Vehicle.Instance

	local trove = Trove.new()
	trove:Connect(self.RE.OnServerEvent, function(...) Replicate(self, ...) end)
	trove:AttachToInstance(self.Vehicle.Instance)

	return self
end

function Replicate(self: ServerLightsImpl, sender: Player, buf: buffer)
	for k, v in Serialization.Deserialize(LightPacket, buf) do
		self[k] = v
	end
	for _, player in Players:GetPlayers() do
		if player == sender then continue end
		if not player.Character then self.RE:FireClient(player) end

		self.RE:FireClient(player, buf)
	end
end

return table.freeze({ new = ServerLights.new })
