local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

if not RunService:IsClient() then return nil end

local Camera = game.Workspace.CurrentCamera

local MAX_DISTANCE = 32
local MIN_DISTANCE = 16

local BUMPING_STRENGTH = 0.07

local CameraPlugin = {}
CameraPlugin.__index = CameraPlugin

export type CameraPlugin = typeof(setmetatable(
	{} :: {
		Vehicle: Types.ClientVehicle,
		Delta: Vector3,
		Bumping: Vector3,
		AngularOffset: CFrame,
		Distance: number,
		Offset: Vector3,
	},
	CameraPlugin
))

function CameraPlugin.new(vehicle: Types.ClientVehicle)
	local self = setmetatable({}, CameraPlugin) :: CameraPlugin

	self.Vehicle = vehicle
	self.Delta = Vector3.new()
	self.Offset = Vector3.new()
	self.Bumping = Vector3.new()
	self.AngularOffset = Vector3.new()
	self.Distance = 24
	Camera.CameraType = Enum.CameraType.Scriptable

	RunService:BindToRenderStep(
		"CameraUpdate",
		Enum.RenderPriority.Camera.Value + 1,
		function(deltaTime) self:Update(deltaTime) end
	)

	ContextActionService:BindAction(
		"CameraZoom",
		function(_, _, input) self:UpdateZoom(input) end,
		false,
		Enum.UserInputType.MouseWheel
	)

	return self
end

function CameraPlugin.UpdateZoom(self: CameraPlugin, input: InputObject)
	self.Distance -= input.Position.Z * 0.4
	self.Distance = math.clamp(self.Distance, MIN_DISTANCE, MAX_DISTANCE)
end

function CameraPlugin.Update(self: CameraPlugin, deltaTime: number)
	local position = self.Vehicle.Center.Position + Vector3.new(0, 7, 0)

	local velocity = self.Vehicle.Velocity * Vector3.new(1, 0, 1)
	local distance = self.Distance
	local delta
	if velocity.Magnitude > 10 then
		distance -= self.Distance * 0.3 * math.abs(self.Vehicle.Velocity.Unit:Dot(self.Vehicle.Center.RightVector)) ^ 1.5
		delta = -velocity.Unit * distance
	elseif self.Vehicle.Gear == -1 then
		delta = self.Vehicle.Center.LookVector * distance
	else
		delta = -self.Vehicle.Center.LookVector * distance
	end

	local assel = math.min(self.Vehicle.Acceleration.Magnitude / 20, 3)
	local offset = Vector3.new()
	if assel > 0 then offset = -assel * self.Vehicle.Acceleration.Unit end

	local bumping = Vector3.yAxis * math.clamp(self.Vehicle.Acceleration.Y, -40, 40) * BUMPING_STRENGTH

	local angularOffset = Vector3.yAxis * self.Vehicle.AngularVelocity.Y * 0.1
		+ Vector3.new(1, 0, 1)
			* -self.Vehicle.AngularVelocity.Unit
			* math.clamp(self.Vehicle.AngularVelocity.Magnitude, -2, 2)
			* 0.2

	self.Offset = self.Offset:Lerp(offset, deltaTime * 2)
	self.Delta = self.Delta:Lerp(delta, deltaTime * 2)
	self.Bumping = self.Bumping:Lerp(bumping, deltaTime * 3)
	self.AngularOffset = self.AngularOffset:Lerp(angularOffset, deltaTime * 2)

	local sideDelta = self.Vehicle.Center.RightVector
		* distance
		* 0.4
		* math.clamp(MapToRange(1 - self.Delta.Magnitude / distance, 0.3, 1), 0, 1) ^ 1.5

	local offsetMagnitude = math.clamp(self.Offset.Magnitude, -3, 3)
	Camera.CFrame = CFrame.new(
		position + self.Delta + self.Bumping + self.Offset.Unit * offsetMagnitude + sideDelta,
		self.Vehicle.Center.Position + Vector3.new(0, 4.5, 0) + self.Offset + self.Bumping
	) * CFrame.Angles(0, self.AngularOffset.Y, 0) * CFrame.fromOrientation(
		self.AngularOffset.X,
		0,
		self.AngularOffset.Z
	)
end

return CameraPlugin
