local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

if not RunService:IsClient() then return nil end

local Camera = game.Workspace.CurrentCamera

local MAX_DISTANCE = 32
local MIN_DISTANCE = 16
local FOV = Camera.FieldOfView

local CameraPlugin = {}
CameraPlugin.__index = CameraPlugin

export type CameraPlugin = typeof(setmetatable(
	{} :: {
		Vehicle: VehicleTypes.ClientVehicle,
		Distance: number,
		Offset: Vector3,
		LookOffset: Vector3,
		Angles: Vector3,
		Bumping: Vector3,
		_LastCameraRotation: number,
		CameraCFrame: CFrame,
	},
	CameraPlugin
))

function CameraPlugin.new(vehicle: VehicleTypes.ClientVehicle)
	local self: CameraPlugin = setmetatable({}, CameraPlugin) :: any

	self.Vehicle = vehicle
	self.Distance = 22
	self.Offset = Vector3.new()
	self.LookOffset = Vector3.new()
	self.Angles = Vector3.new()
	self.Bumping = Vector3.new()
	self._LastCameraRotation = 0
	self.CameraCFrame = CFrame.new()
	Camera.CameraType = Enum.CameraType.Scriptable

	RunService:BindToRenderStep(
		"CameraUpdate",
		Enum.RenderPriority.Camera.Value - 1,
		function(deltaTime) self:Update(deltaTime) end
	)

	ContextActionService:BindAction(
		"CameraZoom",
		function(_, _, input) self:UpdateZoom(input) end,
		false,
		Enum.UserInputType.MouseWheel
	)

	ContextActionService:BindAction(
		"CameraRotation",
		function(_, _, input) self:UpdateRotation(input) end,
		false,
		Enum.UserInputType.MouseMovement
	)

	return self
end

function CameraPlugin.UpdateZoom(self: CameraPlugin, input: InputObject)
	self.Distance -= input.Position.Z * 0.4
	self.Distance = math.clamp(self.Distance, MIN_DISTANCE, MAX_DISTANCE)
end

function CameraPlugin.UpdateRotation(self: CameraPlugin, input: InputObject)
	if
		not (
			UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and not self.Vehicle.MouseSteerOn
			or UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and self.Vehicle.MouseSteerOn
		)
	then
		return
	end

	local x, y, z = self.CameraCFrame:ToOrientation()
	x -= math.rad(input.Delta.Y)
	x = math.clamp(x, math.rad(-25), math.rad(15))
	y -= math.rad(input.Delta.X)
	self.CameraCFrame = CFrame.fromOrientation(x, y, z)
	self._LastCameraRotation = tick()
end

function CameraPlugin.Update(self: CameraPlugin, deltaTime: number)
	local weightB = self.Vehicle.Instance.Body["#Weight"]
	local sideVelocity = Vector3.new(1, 0, 1) * self.Vehicle.Velocity

	local heightOffset = weightB.CFrame.UpVector * 7
	local offset = Vector3.new()
	local lookOffset = weightB.CFrame.UpVector * 4
	local angles = Vector3.new()

	local distance = self.Distance
	if sideVelocity.Magnitude > 10 then
		distance -= self.Distance * 0.2 * math.abs(self.Vehicle.Velocity.Unit:Dot(self.Vehicle.Center.RightVector)) ^ 1.5
		offset -= (sideVelocity.Unit + Vector3.yAxis * weightB.CFrame.LookVector.Y) * distance
	elseif self.Vehicle.Gear == -1 then
		offset += weightB.CFrame.LookVector * distance
	else
		offset -= weightB.CFrame.LookVector * distance
	end

	local bumping = Vector3.yAxis * math.clamp(self.Vehicle.Acceleration.Y, -40, 40) * 0.07
	self.Bumping = self.Bumping:Lerp(bumping, deltaTime * 4)

	local accelForce = math.min(self.Vehicle.Acceleration.Magnitude, 60) * 0.03
	if accelForce > 0 then
		offset -= accelForce * self.Vehicle.Acceleration.Unit
	end

	angles += Vector3.yAxis * self.Vehicle.AngularVelocity.Y * 0.07
	angles += Vector3.new(1, 0, 1) * weightB.AssemblyAngularVelocity.Unit * math.clamp(
		weightB.AssemblyAngularVelocity.Magnitude,
		-2,
		2
	) * 0.1

	self.Offset = self.Offset:Lerp(offset, deltaTime * 3)
	self.LookOffset = self.LookOffset:Lerp(lookOffset, deltaTime * 3)
	self.Angles = self.Angles:Lerp(angles, deltaTime * 4)

	if self.Vehicle.Velocity.Magnitude > 10 and tick() - self._LastCameraRotation > 2 then
		self.CameraCFrame = self.CameraCFrame:Lerp(CFrame.new(), deltaTime * 2)
	end

	local cameraDirection = weightB.CFrame:VectorToWorldSpace(
		self.CameraCFrame:VectorToWorldSpace(weightB.CFrame:VectorToObjectSpace(self.Offset.Unit))
	)
	local rotatedOffset = self.Offset.Magnitude * cameraDirection

	local right = weightB.CFrame.RightVector:Dot(rotatedOffset)
	if math.abs(right) < 0.2 then right = 1 end

	local sideOffset = math.sign(right)
		* weightB.CFrame.RightVector
		* distance
		* 0.5
		* math.clamp(MapToRange(1 - (self.Offset.Magnitude / distance) ^ 2, 0.2, 1), 0, 1)

	Camera.FieldOfView = FOV + sideVelocity.Magnitude / 20

	Camera.CFrame = CFrame.lookAt(
		weightB.Position + rotatedOffset + self.Bumping + heightOffset + sideOffset,
		weightB.Position + self.LookOffset + self.Bumping,
		self.Vehicle.Center.UpVector
	) * CFrame.Angles(self.Angles.X, self.Angles.Y, self.Angles.Z)
end

function CameraPlugin.Destroy(self: CameraPlugin)
	RunService:UnbindFromRenderStep("CameraUpdate")
	ContextActionService:UnbindAction("CameraZoom")
	ContextActionService:UnbindAction("CameraRotation")

	Camera.CameraType = Enum.CameraType.Custom
end

return CameraPlugin
