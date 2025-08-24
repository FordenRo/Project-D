local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LightPacket = require(ReplicatedStorage.Shared.Packets.LightPacket)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local InputContext = ReplicatedStorage.Input.Vehicle

local ClientLights = {}
ClientLights.__index = ClientLights

type ClientLights = VehicleTypes.ClientLights

function ClientLights.new(vehicle: VehicleTypes.ServerVehicle)
	local self: ClientLights = setmetatable({}, ClientLights) :: any

	self.Vehicle = vehicle
	self.State = "Off"
	self.TurnState = "Off"
	self._RE = self.Vehicle.Instance:WaitForChild("LightsRE") :: RemoteEvent

	self._cons = {
		InputContext.Lights.Pressed:Connect(function()
			self.State = self.State == "Off" and "Low" or self.State == "Low" and "High" or "Off" :: any
			self:Replicate()
		end),
		InputContext.LeftTurnSignal.Pressed:Connect(function()
			self.TurnState = self.TurnState ~= "Left" and "Left" or "Off" :: any
			self:Replicate()
		end),
		InputContext.RightTurnSignal.Pressed:Connect(function()
			self.TurnState = self.TurnState ~= "Right" and "Right" or "Off" :: any
			self:Replicate()
		end),
		InputContext.Hazards.Pressed:Connect(function()
			self.TurnState = self.TurnState ~= "Both" and "Both" or "Off" :: any
			self:Replicate()
		end),
	}

	return self
end

function ClientLights.Replicate(self: ClientLights) self._RE:FireServer(Serialization.Serialize(LightPacket, self)) end

function ClientLights.Destroy(self: ClientLights)
	for _, v in self._cons do
		v:Disconnect()
	end
end

return ClientLights
