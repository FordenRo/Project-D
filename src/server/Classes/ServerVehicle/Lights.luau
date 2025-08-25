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

function ServerLights.new(vehicle: VehicleTypes.ServerVehicle)
	local self: ServerLights = setmetatable({}, ServerLights) :: any

	self.Vehicle = vehicle
	self.State = "Off"
	self.TurnState = "Off"

	self._RE = Instance.new("RemoteEvent")
	self._RE.Name = "_LightsRE"
	self._RE.Parent = self.Vehicle.Instance

	self._conn = self._RE.OnServerEvent:Connect(function(_, buf: buffer)
		local data = Serialization.Deserialize(LightPacket, buf)
		self.State = data.State
		self.TurnState = data.TurnState
		self._RE:FireAllClients(buf)
	end)

	return self
end

function ServerLights.Destroy(self: ServerLights) self._conn:Disconnect() end

return ServerLights
