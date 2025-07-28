local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

if not RunService:IsClient() then return nil end

local Camera = game.Workspace.CurrentCamera
local DISTANCE = 24

local CameraPlugin = {}
CameraPlugin.__index = CameraPlugin

export type CameraPlugin = typeof(setmetatable(
	{} :: {
		Vehicle: Types.ClientVehicle,
		Delta: Vector3,
		Offset: Vector3,
	},
	CameraPlugin
))

function CameraPlugin.new(vehicle: Types.ClientVehicle)
	local self = setmetatable({}, CameraPlugin) :: CameraPlugin

	self.Vehicle = vehicle
	self.Delta = Vector3.new()
	self.Offset = Vector3.new()
	Camera.CameraType = Enum.CameraType.Scriptable

	RunService:BindToRenderStep(
		"CameraUpdate",
		Enum.RenderPriority.Camera.Value + 1,
		function(deltaTime) self:Update(deltaTime) end
	)

	return self
end

function CameraPlugin.Update(self: CameraPlugin, deltaTime: number)
	local position = self.Vehicle.Center.Position + Vector3.new(0, 10, 0)

	local velocity = self.Vehicle.Velocity * Vector3.new(1, 0, 1)
	local delta
	if velocity.Magnitude > 10 then
		delta = -velocity.Unit * DISTANCE
	elseif self.Vehicle.Gear == -1 then
		delta = self.Vehicle.Center.LookVector * DISTANCE
	else
		delta = -self.Vehicle.Center.LookVector * DISTANCE
	end

	local assel = math.min(self.Vehicle.Acceleration.Magnitude / 20, 3)
	local offset
	if assel > 0 then offset = -assel * self.Vehicle.Acceleration.Unit end

	self.Offset = self.Offset:Lerp(offset, deltaTime * 2)
	self.Delta = self.Delta:Lerp(delta, deltaTime * 2)

	local offsetMagnitude = math.clamp(self.Offset.Magnitude, -3, 3)
	Camera.CFrame = CFrame.new(
		position + self.Delta + self.Offset.Unit * offsetMagnitude,
		self.Vehicle.Center.Position + Vector3.new(0, 7, 0) + self.Offset
	)
end

return CameraPlugin
