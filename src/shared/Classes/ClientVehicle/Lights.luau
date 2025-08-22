local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	self._RE = self.Vehicle.Instance:WaitForChild("LightsRE")

	self._cons = {
		InputContext.Lights.Pressed:Connect(function()
			self.State = self.State == "Off" and "Low" or self.State == "Low" and "High" or "Off"
			self._RE:FireServer("State", self.State)
		end),
		InputContext.LeftTurnSignal.Pressed:Connect(function()
			self.TurnState = self.TurnState ~= "Left" and "Left" or "Off"
			self._RE:FireServer("TurnState", self.TurnState)
		end),
		InputContext.RightTurnSignal.Pressed:Connect(function()
			self.TurnState = self.TurnState ~= "Right" and "Right" or "Off"
			self._RE:FireServer("TurnState", self.TurnState)
		end),
		InputContext.Hazards.Pressed:Connect(function()
			self.TurnState = self.TurnState ~= "Both" and "Both" or "Off"
			self._RE:FireServer("TurnState", self.TurnState)
		end),
	}

	return self
end

function ClientLights.Destroy(self: ClientLights)
	for _, v in self._cons do
		v:Disconnect()
	end
end

return ClientLights
