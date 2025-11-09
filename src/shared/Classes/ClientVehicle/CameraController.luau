local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Vector3Spring = require(ReplicatedStorage.Shared.Utils.Vector3Spring)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

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
Component.Extend(CameraController)

type CameraController = VehicleTypes.CameraController

type CameraControllerImpl = {
	trove: Trove.Trove,
	blur: BlurEffect,
} & CameraController

function CameraController.new(
	vehicle: VehicleTypes.ClientVehicle
): CameraController
	local self: CameraControllerImpl = Component.new() :: any

	self.Vehicle = vehicle

	setmetatable(self, CameraController)

	Camera.CameraType = Enum.CameraType.Scriptable

	self.trove = Trove.new()

	self.blur = Instance.new("BlurEffect")
	self.blur.Size = 0
	self.blur.Parent = Lighting
	self.trove:Add(self.blur)

	FirstPersonHandler(self)
	ThirdPersonHandler(self)

	local isCharacterVisible = true
	self.trove:Add(
		self.Vehicle.InputController.CameraModeChanged:Connect(function(mode)
			Camera.FieldOfView = mode == "FirstPerson" and FOV * 1.2 or FOV
			if isCharacterVisible == (mode == "FirstPerson") then
				isCharacterVisible = mode == "ThirdPerson"
				for _, v in (player.Character :: Model):GetDescendants() do
					if
						not v:IsA("BasePart")
						or table.find(VISIBLE_BODY_PARTS, v.Name)
					then
						continue
					end

					v.LocalTransparencyModifier = isCharacterVisible and 0 or 1
				end
			end
		end)
	)

	self.trove:Add(function()
		ContextActionService:UnbindAction("CameraZoom")
		ContextActionService:UnbindAction("CameraRotation")

		Camera.CameraType = Enum.CameraType.Custom
	end)

	return self
end

function FirstPersonHandler(self: CameraControllerImpl)
	if not player.Character then return end

	local head = player.Character:FindFirstChild("Head") :: BasePart

	self.trove:BindToRenderStep(
		"FPVUpdate",
		Enum.RenderPriority.Camera.Value - 1,
		function(deltaTime)
			if self.Vehicle.InputController.CameraMode ~= "FirstPerson" then
				return
			end

			local bumping = MathUtil.Noise(self.Vehicle.CFrame.Position * 0.04)
				* (self.Vehicle.Velocity.Magnitude / 100) ^ 0.8
				* 0.03

			-- Update camera
			Camera.CFrame = CFrame.lookAlong(
				head.Position
					+ Vector3.new(0, 0.2, 0)
					- self.Vehicle.CFrame.LookVector * 0.4
					+ self.Vehicle.CFrame.UpVector * bumping,
				head.CFrame.LookVector,
				head.CFrame.UpVector
			)

			-- Update blur
			local multiplier = (self.Vehicle.Acceleration.Magnitude / 700) ^ 2
			local intensity = 20

			self.blur.Size = math.max(self.blur.Size, multiplier * intensity)
			self.blur.Size -= 0.5 * intensity * deltaTime
			self.blur.Size = math.clamp(self.blur.Size, 0, intensity)
		end
	)
end

function ThirdPersonHandler(self: CameraControllerImpl)
	if not player.Character then return end

	local InputController = self.Vehicle.InputController
	local distance = 16

	-- Springs
	local positionSpring = Vector3Spring.new(30, 200, 1000)
	local rotationSpring = Vector3Spring.new(5, 50, 500)

	local acceleration = Vector3.zero
	local velocity = Vector3.zero
	local angularVelocity = Vector3.zero
	local freeRotation = Vector3.zero

	-- Free look
	self.trove:Connect(
		UserInputService.InputChanged,
		function(input: InputObject)
			if
				InputController.CameraMode ~= "ThirdPerson"
				or input.UserInputType ~= Enum.UserInputType.MouseMovement
				or not (
					(
						input:IsModifierKeyDown(Enum.ModifierKey.Alt)
						and InputController.IsMouseSteerOn
					)
					or (
						UserInputService:IsMouseButtonPressed(
							Enum.UserInputType.MouseButton2
						) and not InputController.IsMouseSteerOn
					)
				)
			then
				return
			end

			freeRotation += Vector3.new(
				math.rad(input.Delta.Y),
				math.rad(input.Delta.X)
			)
			freeRotation = Vector3.new(
				math.clamp(freeRotation.X, -math.rad(30), math.rad(30)),
				freeRotation.Y,
				freeRotation.Z
			)
		end
	)

	-- Free look resetting handler
	local lastFreeLook = 0
	local resetDebounce = false
	self.trove:Connect(UserInputService.InputEnded, function(input: InputObject)
		if
			InputController.CameraMode ~= "ThirdPerson"
			or resetDebounce
			or not (
				(
					input.UserInputType == Enum.UserInputType.Keyboard
					and input.KeyCode == Enum.KeyCode.LeftAlt
					and InputController.IsMouseSteerOn
				)
				or (
					input.UserInputType == Enum.UserInputType.MouseButton2
					and not InputController.IsMouseSteerOn
				)
			)
		then
			return
		end

		if tick() - lastFreeLook < 0.2 then
			resetDebounce = true

			local alpha = 1
			task.defer(function()
				while alpha > 0 do
					local deltaTime = RunService.Heartbeat:Wait()
					alpha = math.max(alpha - deltaTime, 0)
					freeRotation *= alpha
				end
				resetDebounce = false
				lastFreeLook = 0
			end)
		else
			lastFreeLook = tick()
		end
	end)

	-- Reset free look on camera mode change
	self.trove:Add(
		InputController.CameraModeChanged:Connect(
			function() freeRotation = Vector3.zero end
		)
	)

	self.trove:BindToRenderStep(
		"TPVUpdate",
		Enum.RenderPriority.Camera.Value - 1,
		function(deltaTime)
			if InputController.CameraMode ~= "ThirdPerson" then return end

			local WPCFrame = self.Vehicle.CFrame

			acceleration = acceleration:Lerp(
				WPCFrame:VectorToObjectSpace(self.Vehicle.Acceleration),
				deltaTime * 20
			)
			velocity = velocity:Lerp(self.Vehicle.Velocity, deltaTime * 20)
			angularVelocity = angularVelocity:Lerp(
				WPCFrame:VectorToObjectSpace(self.Vehicle.AngularVelocity),
				deltaTime * 20
			)

			-- Calculate look direction
			local direction = WPCFrame.LookVector
			if velocity.Magnitude > 0 then
				direction = direction:Lerp(
					velocity.Unit,
					math.min(velocity.Magnitude / 10, 1)
						* WPCFrame.LookVector:Dot(velocity.Unit)
						* 0.8
				)
			end
			direction = CFrame.fromOrientation(
				freeRotation.X,
				-freeRotation.Y,
				freeRotation.Z
			)
				:VectorToWorldSpace(direction)

			-- Apply acceleration
			positionSpring.Offset += acceleration * 0.025 * deltaTime
			rotationSpring.Offset += Vector3.new(
				acceleration.Z / 2 + acceleration.Y,
				0,
				acceleration.X / 2
			) * 0.025 * deltaTime

			-- Apply angular velocity
			rotationSpring.Offset += angularVelocity * Vector3.new(1, 0.5, 1) * deltaTime

			-- Update springs
			positionSpring:Update(deltaTime)
			rotationSpring:Update(deltaTime)

			-- Update camera
			local springOffset = WPCFrame:VectorToWorldSpace(
				positionSpring.Offset * Vector3.new(2, 2, 4)
			)
			local rot = -rotationSpring.Offset * Vector3.new(1, 1, 1) * 0.5
			Camera.CFrame = CFrame.lookAt(
				WPCFrame.Position
					- direction.Unit * distance
					+ WPCFrame.UpVector * 6
					- springOffset,
				WPCFrame.Position + WPCFrame.UpVector * 4 - springOffset,
				WPCFrame.UpVector
			) * CFrame.fromOrientation(rot.X, rot.Y, rot.Z)
			Camera.FieldOfView = FOV - positionSpring.Offset.Z * 5

			-- Update blur
			local multiplier = (self.Vehicle.Acceleration.Magnitude / 700) ^ 2
			local intensity = 20

			self.blur.Size = math.max(self.blur.Size, multiplier * intensity)
			self.blur.Size -= 0.5 * intensity * deltaTime
			self.blur.Size = math.clamp(self.blur.Size, 0, intensity)
		end
	)
end

function CameraController.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == CameraController
end

function CameraController.Destroy(self: CameraControllerImpl)
	self.trove:Destroy()
end

return table.freeze({
	new = CameraController.new,
	Is = CameraController.Is,
})
