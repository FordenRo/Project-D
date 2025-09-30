local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera

local MAX_DISTANCE = 32
local MIN_DISTANCE = 16
local FOV = Camera.FieldOfView

local VISIBLE_BODY_PARTS = {
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
}

local CameraController = {}
CameraController.__index = CameraController

type CameraController = VehicleTypes.CameraController

function CameraController.new(
	vehicle: VehicleTypes.ClientVehicle
): CameraController
	local self: CameraController = setmetatable({}, CameraController) :: any

	self.Vehicle = vehicle
	self.Distance = 22
	self.Offset = Vector3.new()
	self.LookOffset = Vector3.new()
	self.Angles = Vector3.new()
	self.Bumping = Vector3.new()
	self.FirstPerson = false
	self._LastCameraRotation = 0
	self._CharacterVisible = true
	self.CameraCFrame = CFrame.new()
	Camera.CameraType = Enum.CameraType.Scriptable

	self._trove = Trove.new()

	self._trove:BindToRenderStep(
		"CameraUpdate",
		Enum.RenderPriority.Camera.Value - 1,
		function(deltaTime) Update(self, deltaTime) end
	)

	ContextActionService:BindAction(
		"CameraZoom",
		function(_, _, input) UpdateZoom(self, input) end,
		false,
		Enum.UserInputType.MouseWheel
	)

	ContextActionService:BindAction(
		"CameraRotation",
		function(_, _, input) UpdateRotation(self, input) end,
		false,
		Enum.UserInputType.MouseMovement
	)

	self._trove:Add(function()
		ContextActionService:UnbindAction("CameraZoom")
		ContextActionService:UnbindAction("CameraRotation")

		Camera.CameraType = Enum.CameraType.Custom
	end)

	return self
end

function UpdateZoom(self: CameraController, input: InputObject)
	self.Distance -= input.Position.Z * 0.4
	self.Distance = math.clamp(self.Distance, MIN_DISTANCE, MAX_DISTANCE)
end

function UpdateRotation(self: CameraController, input: InputObject)
	if
		not (
			UserInputService:IsMouseButtonPressed(
					Enum.UserInputType.MouseButton2
				)
				and not self.Vehicle.InputController.MouseSteerOn
			or UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
				and self.Vehicle.InputController.MouseSteerOn
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

function Update(self: CameraController, deltaTime: number)
	if self._CharacterVisible == self.FirstPerson then
		self._CharacterVisible = not self.FirstPerson
		for _, v in player.Character:GetDescendants() do
			if
				not v:IsA("BasePart") or table.find(VISIBLE_BODY_PARTS, v.Name)
			then
				continue
			end

			v.LocalTransparencyModifier = self._CharacterVisible and 0 or 1
		end
	end

	if self.FirstPerson then
		UpdateFirstPerson(self, deltaTime)
	else
		UpdateThirdPerson(self, deltaTime)
	end
end

function UpdateFirstPerson(self: CameraController, deltaTime: number)
	local head = player.Character:FindFirstChild("Head") :: BasePart

	-- Update camera
	Camera.FieldOfView = FOV * 1.2 + self.Vehicle.Velocity.Magnitude / 100
	Camera.CFrame = CFrame.lookAlong(
		head.Position
			+ Vector3.new(0, 0.2, 0)
			- self.Vehicle.WeightPart.CFrame.LookVector * 0.4
			+ self.Bumping,
		head.CFrame.LookVector,
		head.CFrame.UpVector
	)
end

function UpdateThirdPerson(self: CameraController, deltaTime: number)
	local sideVelocity = Vector3.new(1, 0, 1) * self.Vehicle.Velocity

	local heightOffset = self.Vehicle.WeightPart.CFrame.UpVector * 7
	local offset = Vector3.new()
	local lookOffset = self.Vehicle.WeightPart.CFrame.UpVector * 4
	local angles = Vector3.new()

	local distance = self.Distance
	if sideVelocity.Magnitude > 10 then
		distance -= self.Distance * 0.2 * math.abs(
			self.Vehicle.Velocity.Unit:Dot(self.Vehicle.Center.RightVector)
		) ^ 1.5
		offset -= (sideVelocity.Unit + Vector3.yAxis * self.Vehicle.WeightPart.CFrame.LookVector.Y) * distance
	elseif self.Vehicle.Gear == -1 then
		offset += self.Vehicle.WeightPart.CFrame.LookVector * distance
	else
		offset -= self.Vehicle.WeightPart.CFrame.LookVector * distance
	end

	local bumping = Vector3.yAxis
		* math.clamp(self.Vehicle.Acceleration.Y, -40, 40)
		* 0.07
	self.Bumping = self.Bumping:Lerp(bumping, deltaTime * 4)

	local accelForce = math.min(self.Vehicle.Acceleration.Magnitude, 60) * 0.03
	if accelForce > 0 then
		offset -= accelForce * self.Vehicle.Acceleration.Unit
	end

	angles += Vector3.yAxis * self.Vehicle.AngularVelocity.Y * 0.07
	if self.Vehicle.AngularVelocity.Magnitude > 0 then
		angles += Vector3.new(1, 0, 1) * self.Vehicle.AngularVelocity.Unit * math.clamp(
			self.Vehicle.AngularVelocity.Magnitude,
			-2,
			2
		) * 0.1
	end

	self.Offset = self.Offset:Lerp(offset, deltaTime * 3)
	self.LookOffset = self.LookOffset:Lerp(lookOffset, deltaTime * 3)
	self.Angles = self.Angles:Lerp(angles, deltaTime * 4)

	if
		self.Vehicle.Velocity.Magnitude > 10
		and tick() - self._LastCameraRotation > 2
	then
		self.CameraCFrame = self.CameraCFrame:Lerp(CFrame.new(), deltaTime * 2)
	end

	local cameraDirection
	if self.Offset.Magnitude > 0 then
		cameraDirection = self.Vehicle.WeightPart.CFrame:VectorToWorldSpace(
			self.CameraCFrame:VectorToWorldSpace(
				self.Vehicle.WeightPart.CFrame:VectorToObjectSpace(
					self.Offset.Unit
				)
			)
		)
	else
		cameraDirection = Vector3.zero
	end
	local rotatedOffset = self.Offset.Magnitude * cameraDirection

	local right = self.Vehicle.WeightPart.CFrame.RightVector:Dot(rotatedOffset)
	if math.abs(right) < 0.2 then right = 1 end

	local sideOffset = math.sign(right)
		* self.Vehicle.WeightPart.CFrame.RightVector
		* distance
		* 0.5
		* math.clamp(
			MathUtil.MapToRange(
				1 - (self.Offset.Magnitude / distance) ^ 2,
				0.2,
				1
			),
			0,
			1
		)

	Camera.FieldOfView = FOV + sideVelocity.Magnitude / 20

	Camera.CFrame = CFrame.lookAt(
		self.Vehicle.WeightPart.Position
			+ rotatedOffset
			+ self.Bumping
			+ heightOffset
			+ sideOffset,
		self.Vehicle.WeightPart.Position + self.LookOffset + self.Bumping,
		self.Vehicle.Center.UpVector
	) * CFrame.Angles(self.Angles.X, self.Angles.Y, self.Angles.Z)
end

function CameraController.Destroy(self: CameraController) self._trove:Destroy() end

return CameraController
