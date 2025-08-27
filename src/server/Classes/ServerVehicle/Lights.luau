local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LightPacket = require(ReplicatedStorage.Shared.Packets.LightPacket)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ServerLights = {}
ServerLights.__index = ServerLights

export type ServerLights = typeof(setmetatable(
	{} :: {
		_RE: RemoteEvent,
		_conn: RBXScriptConnection,
		Vehicle: VehicleTypes.ServerVehicle,
		State: string,
		TurnState: string,
	},
	ServerLights
))

function ServerLights.new(vehicle: VehicleTypes.ServerVehicle): ServerLights
	local self: ServerLights = setmetatable({}, ServerLights) :: any

	self.Vehicle = vehicle
	self.State = "Off"
	self.TurnState = "Off"

	self._RE = Instance.new("RemoteEvent")
	self._RE.Name = "_LightsRE"
	self._RE.Parent = self.Vehicle.Instance

	self._conn = self._RE.OnServerEvent:Connect(function(...) Replicate(self, ...) end)

	return self
end

function Replicate(self: ServerLights, sender: Player, buf: buffer)
	for k, v in Serialization.Deserialize(LightPacket, buf) do
		self[k] = v
	end
	for _, player in Players:GetPlayers() do
		if player == sender then continue end
		if not player.Character then self._RE:FireClient(player) end

		self._RE:FireClient(player, buf)
	end
end

function ServerLights.Destroy(self: ServerLights) self._conn:Disconnect() end

return ServerLights
