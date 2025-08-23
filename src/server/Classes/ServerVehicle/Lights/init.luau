local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Headlight = require(script.Headlight)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

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

local ServerLights = {}
ServerLights.__index = ServerLights

type ServerLights = VehicleTypes.ServerLights

function ServerLights.new(vehicle: VehicleTypes.BaseVehicle)
	local self: ServerLights = setmetatable({}, ServerLights) :: any

	self.Vehicle = vehicle
	self.State = "Off"
	self.TurnState = "Off"

	self._RE = Instance.new("RemoteEvent")
	self._RE.Name = "LightsRE"
	self._RE.Parent = self.Vehicle.Instance

	self._cons = {}
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
	table.insert(self._cons, self._RE.OnServerEvent:Connect(function(_, k: string, v: any) self[k] = v end))

	return self
end

function setTypeBrightness(self: ServerLights, type: string, brightness: boolean | number)
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

function Update(self: ServerLights)
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

function ServerLights.Destroy(self: ServerLights)
	for _, v in self._cons do
		v:Disconnect()
	end
end

return ServerLights
