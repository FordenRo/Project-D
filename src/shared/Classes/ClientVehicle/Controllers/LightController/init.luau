--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseClass = require(ReplicatedStorage.Shared.Classes.BaseClass)
local Headlight = require(script.Headlight)
local LightPacket = require(ReplicatedStorage.Shared.Packets.LightPacket)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local LIGHT_POWER = {
	Off = 0,
	Low = 0.5,
	High = 1,
}

local LIGHT_TYPES = {
	"Front",
	"Rear",
	"TurnRight",
	"TurnLeft",
	"Reverse",
	"Brake",
}

local LightController = { set = {} }
BaseClass.Extend(LightController)

type LightController = VehicleTypes.ClientLights & BaseClass.BaseClass

type LightControllerImpl = {
	lastToggleTime: number,
	typesBrightness: { [string]: number },
} & LightController

type Side = "Right" | "Left" | "Both"

function LightController.new(
	vehicle: VehicleTypes.ClientVehicle
): LightController
	local self: LightControllerImpl = BaseClass.new() :: any

	self.Vehicle = vehicle
	self.State = "Off"
	self.TurnState = "Off"

	self.lastToggleTime = tick()
	self.typesBrightness = {}
	self.Headlights = {} :: any

	for _, lightPart in self.Vehicle.Instance:GetDescendants() do
		if
			not lightPart:IsA("BasePart") or not lightPart:HasTag("Headlight")
		then
			continue
		end

		local headlightType = lightPart:GetAttribute("Type") :: string

		local typeHeadlights = self.Headlights[headlightType]
		if not typeHeadlights then
			typeHeadlights = {}
			self.Headlights[headlightType] = typeHeadlights
		end

		table.insert(typeHeadlights, Headlight.new(lightPart))
	end

	local trove = Trove.new()
	trove:Connect(RunService.Heartbeat, function() Update(self) end)
	trove:AttachToInstance(self.Vehicle.Instance)

	return setmetatable(self, LightController)
end

function LightController.DataReceived(self: LightControllerImpl, buf: buffer)
	for k, v in Serialization.Deserialize(LightPacket, buf) do
		self:RawSet(k, v)
	end
end

function LightController.set.State(self: LightControllerImpl, state: string)
	self:RawSet("State", state)
	self.Vehicle:SendData(self, Serialization.Serialize(LightPacket, self))
end

function LightController.set.TurnState(self: LightControllerImpl, state: string)
	self:RawSet("TurnState", state)
	self.Vehicle:SendData(self, Serialization.Serialize(LightPacket, self))
end

function processInput(self: LightControllerImpl)
	if tick() - self.lastToggleTime < 0.2 then return end
	self.lastToggleTime = tick()
	return true
end

function LightController.ToggleLights(self: LightControllerImpl)
	if not processInput(self) then return end
	self.State = self.State == "Off" and "Low"
		or self.State == "Low" and "High"
		or "Off" :: any
end

function LightController.ToggleTurnState(
	self: LightControllerImpl,
	turnState: "Left" | "Right" | "Both"
)
	if not processInput(self) then return end
	self.TurnState = self.TurnState ~= turnState and turnState or "Off"
end

function setTypeBrightness(
	self: LightControllerImpl,
	type: string,
	brightness: boolean | number,
	side: Side?
)
	if brightness == true then
		brightness = 1
	elseif brightness == false then
		brightness = 0
	end

	if not self.Headlights[type] then return end
	if self.typesBrightness[type] == brightness then return end
	self.typesBrightness[type] = brightness :: number

	for k, v in self.Headlights[type] do
		local sideAttr = v.Instance:GetAttribute("Side")
		if side and side ~= "Both" and sideAttr ~= side then continue end

		v.Brightness = brightness :: number
	end
end

function Update(self: LightControllerImpl)
	setTypeBrightness(
		self,
		"Rear",
		self.Vehicle.Brake > 0.5 and 1 or self.State ~= "Off" and 0.5 or 0
	)
	setTypeBrightness(self, "Brake", self.Vehicle.Brake > 0.5)
	setTypeBrightness(self, "Reverse", self.Vehicle.Gear == -1)
	setTypeBrightness(self, "Front", LIGHT_POWER[self.State])
	setTypeBrightness(
		self,
		"TurnSignal",
		(self.TurnState == "Left" or self.TurnState == "Both")
			and math.round(tick() * 2) % 2 == 0,
		"Left"
	)
	setTypeBrightness(
		self,
		"TurnSignal",
		(self.TurnState == "Right" or self.TurnState == "Both")
			and math.round(tick() * 2) % 2 == 0,
		"Right"
	)
end

function LightController.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == LightController
end

return table.freeze({
	new = LightController.new,
	Is = LightController.Is,
})
