local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ClientLights = {}
ClientLights.__index = ClientLights

type ClientLights = VehicleTypes.ClientLights

function ClientLights.new(vehicle: VehicleTypes.ServerVehicle)
	local self: ClientLights = setmetatable({}, ClientLights) :: any

	self.Vehicle = vehicle
	self.State = "Off"
	self._RE = self.Vehicle.Instance:WaitForChild("LightsRE")

	self._conn = ReplicatedStorage.Input.Vehicle.Lights.Pressed:Connect(function()
		self.State = self.State == "Off" and "Low" or self.State == "Low" and "High" or "Off"
		self._RE:FireServer(self.State)
	end)

	return self
end

function ClientLights.Destroy(self: ClientLights) self._conn:Disconnect() end

return ClientLights
