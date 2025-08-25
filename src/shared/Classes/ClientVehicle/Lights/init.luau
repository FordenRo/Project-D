local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Headlight = require(script.Headlight)
local LightPacket = require(ReplicatedStorage.Shared.Packets.LightPacket)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local InputContext = ReplicatedStorage.Input.Vehicle

local LIGHT_POWER = {
	Off = 0,
	Low = 0.5,
	High = 1,
} :: { { LightsState: number } }

local LIGHT_TYPES = {
	"Front",
	"Rear",
	"TurnRight",
	"TurnLeft",
	"Reverse",
	"Brake",
}

local ClientLights = {}
ClientLights.__index = ClientLights

type ClientLights = VehicleTypes.ClientLights

function ClientLights.new(vehicle: VehicleTypes.ClientVehicle): ClientLights
	local self: ClientLights = setmetatable({}, ClientLights) :: any

	self.Vehicle = vehicle
	self.State = "Off"
	self.TurnState = "Off"

	self._RE = self.Vehicle.Instance:FindFirstChild("_LightsRE") :: RemoteEvent

	self._cons = {
		InputContext.Lights.Pressed:Connect(function()
			self.State = self.State == "Off" and "Low" or self.State == "Low" and "High" or "Off" :: any
			Replicate(self)
		end),
		InputContext.LeftTurnSignal.Pressed:Connect(function()
			self.TurnState = self.TurnState ~= "Left" and "Left" or "Off" :: any
			Replicate(self)
		end),
		InputContext.RightTurnSignal.Pressed:Connect(function()
			self.TurnState = self.TurnState ~= "Right" and "Right" or "Off" :: any
			Replicate(self)
		end),
		InputContext.Hazards.Pressed:Connect(function()
			self.TurnState = self.TurnState ~= "Both" and "Both" or "Off" :: any
			Replicate(self)
		end),
	}

	self._typesBrightness = {}
	self.Headlights = {} :: any

	for _, lightType in LIGHT_TYPES do
		local model = self.Vehicle.Instance.Body.Lights:FindFirstChild(lightType)
		if not model then continue end

		self.Headlights[lightType] = {}
		for k, lightPart in model:GetChildren() :: { BasePart } do
			if not lightPart:FindFirstChildWhichIsA("Light", true) and not lightPart:GetAttribute("Color") then
				continue
			end

			table.insert(self.Headlights[lightType], Headlight.new(lightPart))
		end
	end

	table.insert(self._cons, RunService.Heartbeat:Connect(function() Update(self) end))
	table.insert(
		self._cons,
		self._RE.OnClientEvent:Connect(function(buf: buffer)
			if self.Vehicle.IsDriven then return end

			local data = Serialization.Deserialize(LightPacket, buf)
			self.State = data.State
			self.TurnState = data.TurnState
		end)
	)

	return self
end

function setTypeBrightness(self: ClientLights, type: string, brightness: boolean | number)
	if brightness == true then
		brightness = 1
	elseif brightness == false then
		brightness = 0
	end

	if self._typesBrightness[type] == brightness then return end
	self._typesBrightness[type] = brightness :: number

	for k, v in self.Headlights[type] do
		v:SetBrightness(brightness)
	end
end

function Replicate(self: ClientLights) self._RE:FireServer(Serialization.Serialize(LightPacket, self)) end

function Update(self: ClientLights)
	setTypeBrightness(self, "Rear", self.Vehicle.Brake > 0.5 and 1 or self.State ~= "Off" and 0.5 or 0)
	setTypeBrightness(self, "Brake", self.Vehicle.Brake > 0.5)
	setTypeBrightness(self, "Reverse", self.Vehicle.Gear == -1)
	setTypeBrightness(self, "Front", LIGHT_POWER[self.State])
	setTypeBrightness(
		self,
		"TurnLeft",
		(self.TurnState == "Left" or self.TurnState == "Both") and math.round(tick() * 2) % 2 == 0
	)
	setTypeBrightness(
		self,
		"TurnRight",
		(self.TurnState == "Right" or self.TurnState == "Both") and math.round(tick() * 2) % 2 == 0
	)
end

function ClientLights.Destroy(self: ClientLights)
	for _, v in self._cons do
		v:Disconnect()
	end
end

return ClientLights
