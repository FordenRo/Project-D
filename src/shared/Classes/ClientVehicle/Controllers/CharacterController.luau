--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SettingsController =
	require(ReplicatedStorage.Shared.Controllers.SettingsController)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Vector3Spring = require(ReplicatedStorage.Shared.Utils.Vector3Spring)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local CharacterController = {}
CharacterController.__index = CharacterController

export type CharacterController = {
	Player: Player,
	Vehicle: VehicleTypes.ClientVehicle,
}

type CharacterControllerImpl = {
	trove: Trove.Trove,
	IKControls: { [string]: IKControl },
} & CharacterController

function CharacterController.new(
	vehicle: VehicleTypes.ClientVehicle
): CharacterController
	local self: CharacterControllerImpl =
		setmetatable({}, CharacterController) :: any

	self.Vehicle = vehicle
	self.IKControls = {}

	self.trove = Trove.new()

	self.Vehicle.PlayerSeated:Connect(
		function(player) Initialize(self, player) end
	)

	self.Vehicle.PlayerLeaved:Connect(function(player) self.trove:Destroy() end)

	return self
end

function Initialize(self: CharacterControllerImpl, player: Player)
	self.Player = player

	InitializeIKControls(self)
	TorsoHandler(self)
	NeckHandler(self)
	GearLeverHandler(self)
	SteeringWheelHandler(self)
	HandbrakeHandler(self)
	PedalsHandler(self)
	IgnitionHandler(self)
end

function InitializeIKControls(self: CharacterControllerImpl)
	local function make(
		name: string,
		chainRoot: string,
		endEffector: string,
		target: Attachment,
		priority: number?
	)
		if not target or not self.Player or not self.Player.Character then
			return
		end

		local IKControl = Instance.new("IKControl")
		IKControl.Name = name .. "IK"
		IKControl.ChainRoot = self.Player.Character:FindFirstChild(chainRoot)
		IKControl.EndEffector =
			self.Player.Character:FindFirstChild(endEffector)
		IKControl.Type = Enum.IKControlType.Position
		IKControl.Priority = priority or 1
		IKControl.Weight = 0
		IKControl.Target = target
		IKControl.Parent = self.Player.Character
		self.trove:Add(IKControl)

		self.IKControls[name] = IKControl
	end
	local function makeSided(
		name: string,
		chainRoot: string,
		endEffector: string,
		target: Attachment,
		priority: number?
	)
		local side = self.Vehicle.Instance.DriveSeat.CFrame:PointToObjectSpace(
			target.WorldPosition
		).X > 0 and "Right" or "Left"

		make(name, side .. chainRoot, side .. endEffector, target, priority)
	end

	if self.Vehicle.Driver ~= self.Player then return end
	if not self.Player.Character then return end

	local vehicle = self.Vehicle.Instance

	do -- Head IKControl
		local attachment = Instance.new("Attachment")
		attachment.Name = "HeadIKAttacment"
		attachment.Parent = self.Player.Character:FindFirstChild("UpperTorso")
		self.trove:Add(attachment)

		make("Head", "UpperTorso", "Head", attachment)
	end

	do -- Torso IKControl
		local seat = (
			self.Player.Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
		).SeatPart :: VehicleSeat | Seat

		local attachment = Instance.new("Attachment")
		attachment.Name = "TorsoIKAttachment"
		attachment.Parent = seat
		self.trove:Add(attachment)

		make("Torso", "LowerTorso", "UpperTorso", attachment, 0)
	end

	make(
		"RightHandWheel",
		"RightUpperArm",
		"RightHand",
		vehicle.Misc
			:FindFirstChild("SteeringWheel")
			:FindFirstChild("RightHandAttachment")
	)
	make(
		"LeftHandWheel",
		"LeftUpperArm",
		"LeftHand",
		vehicle.Misc
			:FindFirstChild("SteeringWheel")
			:FindFirstChild("LeftHandAttachment")
	)
	makeSided(
		"Handbrake",
		"UpperArm",
		"Hand",
		vehicle.Misc
			:FindFirstChild("Handbrake")
			:FindFirstChild("HandAttachment"),
		2
	)
	makeSided(
		"GearLever",
		"UpperArm",
		"Hand",
		vehicle.Misc
			:FindFirstChild("GearLever")
			:FindFirstChild("HandAttachment"),
		3
	)
	makeSided(
		"Ignition",
		"UpperArm",
		"Hand",
		vehicle.Body
			:FindFirstChild("Buttons")
			:FindFirstChild("Ignition")
			:FindFirstChild("HandAttachment"),
		2
	)

	local pedals = vehicle.Misc:FindFirstChild("Pedals")
	if pedals then
		make(
			"Throttle",
			"RightUpperLeg",
			"RightFoot",
			pedals:FindFirstChild("Throttle"):FindFirstChild("FootAttachment")
		)
		make(
			"Brake",
			"RightUpperLeg",
			"RightFoot",
			pedals:FindFirstChild("Brake"):FindFirstChild("FootAttachment")
		)
		make(
			"Clutch",
			"LeftUpperLeg",
			"LeftFoot",
			pedals:FindFirstChild("Clutch"):FindFirstChild("FootAttachment")
		)
	end
end

function TorsoHandler(self: CharacterControllerImpl)
	if not self.Player or not self.Player.Character then return end

	local humanoid =
		self.Player.Character:FindFirstChild("Humanoid") :: Humanoid
	local upperTorso =
		self.Player.Character:FindFirstChild("UpperTorso") :: BasePart
	local rootPart = humanoid.RootPart

	local IKControl = self.IKControls.Torso
	local targetAttach = IKControl.Target :: Attachment
	IKControl.Weight = 1
	IKControl.SmoothTime = 0

	-- Offsets
	local rotationOffset = Vector3.new(math.rad(5), 0, 0)
	local positionOffset = targetAttach.WorldCFrame:PointToObjectSpace(
		upperTorso.Position
	) + Vector3.new(0, upperTorso.Size.Y / 2, 0)

	-- Springs
	local positionSpring = Vector3Spring.new(30, 200, 1000)
	local rotationSpring = positionSpring:Clone()

	local acceleration = Vector3.zero
	local angularVelocity = Vector3.zero

	self.trove:Connect(RunService.PreSimulation, function(deltaTime: number)
		acceleration = acceleration:Lerp(
			rootPart.CFrame:VectorToObjectSpace(self.Vehicle.Acceleration),
			deltaTime * 20
		)
		angularVelocity = angularVelocity:Lerp(
			rootPart.CFrame:VectorToObjectSpace(self.Vehicle.AngularVelocity),
			deltaTime * 20
		)

		-- Apply acceleration
		positionSpring.Offset += acceleration * 0.025 * deltaTime

		-- Apply angular velocity
		rotationSpring.Offset += angularVelocity * 0.5 * deltaTime

		-- Update springs
		positionSpring:Update(deltaTime)
		rotationSpring:Update(deltaTime)

		-- Apply transforms
		local rot = rotationOffset
			- rotationSpring.Offset * Vector3.new(1, 0.5, 1)
		targetAttach.CFrame = CFrame.fromOrientation(rot.X, rot.Y, rot.Z)
			:ToWorldSpace(CFrame.new(positionOffset - positionSpring.Offset))
	end)
end

function NeckHandler(self: CharacterControllerImpl)
	if not self.Player or not self.Player.Character then return end

	local humanoid =
		self.Player.Character:FindFirstChild("Humanoid") :: Humanoid
	local upperTorso =
		self.Player.Character:FindFirstChild("UpperTorso") :: BasePart
	local rootPart = humanoid.RootPart
	local InputController = self.Vehicle.InputController

	local IKControl = self.IKControls.Head
	local targetAttach = IKControl.Target :: Attachment
	IKControl.Type = Enum.IKControlType.Rotation
	IKControl.Weight = 1
	IKControl.SmoothTime = 0

	local rotationOffset = Vector3.new(-math.rad(10), 0, 0)
	local spring = Vector3Spring.new(5, 50, 500)

	local acceleration = Vector3.zero
	local velocity = Vector3.zero
	local angularVelocity = Vector3.zero
	local freeRotation = Vector3.zero

	-- Free look
	self.trove:Connect(
		UserInputService.InputChanged,
		function(input: InputObject)
			if
				InputController.CameraMode ~= "FirstPerson"
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
				math.clamp(freeRotation.X, -math.rad(10), math.rad(10)),
				math.clamp(freeRotation.Y, -math.rad(30), math.rad(30)),
				freeRotation.Z
			)
		end
	)

	-- Free look resetting handler
	local lastFreeLook = 0
	local resetDebounce = false
	self.trove:Connect(UserInputService.InputEnded, function(input: InputObject)
		if
			InputController.CameraMode ~= "FirstPerson"
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

	self.trove:Connect(RunService.PreSimulation, function(deltaTime: number)
		acceleration = acceleration:Lerp(
			rootPart.CFrame:VectorToObjectSpace(self.Vehicle.Acceleration),
			deltaTime * 20
		)
		velocity = velocity:Lerp(self.Vehicle.Velocity, deltaTime * 20)
		angularVelocity = angularVelocity:Lerp(
			rootPart.CFrame:VectorToObjectSpace(self.Vehicle.AngularVelocity),
			deltaTime * 20
		)

		-- Calculate look direction
		local direction = self.Vehicle.CFrame.LookVector
		if velocity.Magnitude > 0 then
			direction = direction:Lerp(
				velocity.Unit,
				math.min(velocity.Magnitude / 10, 1)
					* self.Vehicle.CFrame.LookVector:Dot(velocity.Unit)
					* 0.2
			)
		end
		direction = CFrame.fromOrientation(
			freeRotation.X,
			-freeRotation.Y,
			freeRotation.Z
		)
			:VectorToWorldSpace(direction)

		-- Apply acceleration
		spring.Offset += Vector3.new(
			acceleration.Z + acceleration.Y,
			0,
			acceleration.X / 2
		) * 0.025 * deltaTime

		-- Apply angular velocity
		spring.Offset += angularVelocity * Vector3.new(1, 0.5, 1) * deltaTime

		spring:Update(deltaTime)

		local steeringRotation = Vector3.yAxis
			* self.Vehicle.Steering
			* math.rad(30)

		-- Apply transforms
		local rotation = rotationOffset - spring.Offset + steeringRotation
		targetAttach.CFrame = upperTorso.CFrame:ToObjectSpace(
			CFrame.lookAlong(
				Vector3.zero,
				direction,
				self.Vehicle.CFrame.UpVector
			)
				* CFrame.fromOrientation(rotation.X, -rotation.Y, rotation.Z)
		).Rotation
	end)
end

function SteeringWheelHandler(self: CharacterControllerImpl)
	if not self.Player or not self.Player.Character then return end

	local rightIK = self.IKControls.RightHandWheel
	local leftIK = self.IKControls.LeftHandWheel
	if not rightIK or not leftIK then return end

	local leftShoulderAttachment = (
			self.Player.Character:FindFirstChild("LeftUpperArm") :: BasePart
		):FindFirstChild("LeftShoulderAttachment") :: Attachment
	local rightShoulderAttachment = (
			self.Player.Character:FindFirstChild("RightUpperArm") :: BasePart
		):FindFirstChild("RightShoulderAttachment") :: Attachment

	local startLeftShoulderCFrame = leftShoulderAttachment.CFrame
	local startRightShoulderCFrame = rightShoulderAttachment.CFrame
	leftShoulderAttachment.CFrame *= CFrame.new(0, 0.2, 0)
	rightShoulderAttachment.CFrame *= CFrame.new(0, 0.2, 0)

	self.trove:Add(function()
		leftShoulderAttachment.CFrame = startLeftShoulderCFrame
		rightShoulderAttachment.CFrame = startRightShoulderCFrame
	end)

	rightIK.SmoothTime = 0
	leftIK.SmoothTime = 0
	rightIK.Weight = 1
	leftIK.Weight = 1
end

function HandbrakeHandler(self: CharacterControllerImpl)
	local IKControl = self.IKControls.Handbrake
	if not IKControl then return end

	IKControl.Type = Enum.IKControlType.Transform

	local curTask
	self.trove:Connect(
		self.Vehicle:GetPropertyChangedSignal("PBrake"),
		function()
			IKControl.Weight = 1
			if curTask then task.cancel(curTask) end

			if self.Vehicle.PBrake then return end
			curTask = task.delay(0.3, function() IKControl.Weight = 0 end)
		end
	)
end

function GearLeverHandler(self: CharacterControllerImpl)
	local IKControl = self.IKControls.GearLever
	if not IKControl then return end

	local lastGear = 0
	local curTask
	self.trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		local oneHanded = SettingsController:GetSetting("OneHandedSteering")
		if oneHanded then
			IKControl.Weight = (not self.Vehicle.PBrake or curTask) and 1 or 0
		end
		if self.Vehicle.Gear == lastGear then return end

		lastGear = self.Vehicle.Gear
		IKControl.Weight = 1

		if curTask then
			task.cancel(curTask)
			curTask = nil
		end
		curTask = task.delay(0.3, function()
			local t = tick()
			repeat
				task.wait()
			until tick() - t > 2
				or self.Vehicle.Clutch < 0.5
				or self.Vehicle.PBrake
			if not oneHanded then IKControl.Weight = 0 end
			curTask = nil
		end)
	end)
end

function PedalsHandler(self: CharacterControllerImpl)
	if not self.Player or not self.Player.Character then return end

	local throttleIK = self.IKControls.Throttle
	local brakeIK = self.IKControls.Brake
	local clutchIK = self.IKControls.Clutch
	if not throttleIK or not brakeIK or not clutchIK then return end

	throttleIK.SmoothTime = 0
	brakeIK.SmoothTime = 0
	clutchIK.SmoothTime = 0

	local leftHipAttachment = (
			self.Player.Character:FindFirstChild("LeftUpperLeg") :: BasePart
		):FindFirstChild("LeftHipRigAttachment") :: Attachment
	local rightHipAttachment = (
			self.Player.Character:FindFirstChild("RightUpperLeg") :: BasePart
		):FindFirstChild("RightHipRigAttachment") :: Attachment

	local startLeftHipCFrame = leftHipAttachment.CFrame
	local startRightHipCFrame = rightHipAttachment.CFrame

	leftHipAttachment.CFrame *= CFrame.new(0, 0.5, 0)
	rightHipAttachment.CFrame *= CFrame.new(0, 0.5, 0)

	self.trove:Add(function()
		leftHipAttachment.CFrame = startLeftHipCFrame
		rightHipAttachment.CFrame = startRightHipCFrame
	end)

	self.trove:Connect(RunService.Heartbeat, function(deltaTime)
		throttleIK.Weight = 0.05
			+ self.Vehicle.Throttle * (1 - self.Vehicle.Brake * 0.5)
		brakeIK.Weight = 0.05
			+ self.Vehicle.Brake * (1 - self.Vehicle.Throttle * 0.5)
		clutchIK.Weight = 0.05 + self.Vehicle.Clutch
	end)
end

function IgnitionHandler(self: CharacterControllerImpl)
	local IKControl = self.IKControls.Ignition

	local thread
	self.trove:Add(self.Vehicle.IgnitionStateChanged:Connect(function(state)
		if thread then task.cancel(thread) end

		if state == "Starting" then
			IKControl.Weight = 1
			return
		end

		IKControl.Weight = 1

		thread = task.delay(0.4, function() IKControl.Weight = 0 end)
	end))
end

function CharacterController.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == CharacterController
end

return table.freeze({
	new = CharacterController.new,
	Is = CharacterController.Is,
})
