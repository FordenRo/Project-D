local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local SettingsController =
	require(ReplicatedStorage.Shared.Controllers.SettingsController)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Vector3Spring = require(ReplicatedStorage.Shared.Utils.Vector3Spring)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local BodyController = {}
BodyController.__index = BodyController

export type BodyController = {
	Player: Player,
	Vehicle: VehicleTypes.ClientVehicle,
}

type BodyControllerImpl = {
	trove: Trove.Trove,
	IKControls: { [string]: IKControl },
} & BodyController

function BodyController.new(vehicle: VehicleTypes.ClientVehicle): BodyController
	local self: BodyControllerImpl = setmetatable({}, BodyController) :: any

	self.Vehicle = vehicle
	self.IKControls = {}

	self.trove = Trove.new()

	self.Vehicle.PlayerSeated:Connect(
		function(player) Initialize(self, player) end
	)

	self.Vehicle.PlayerLeaved:Connect(function(player) self.trove:Destroy() end)

	return self
end

function Initialize(self: BodyControllerImpl, player: Player)
	self.Player = player

	InitializeIKControls(self)
	InitializeTorso(self)
	InitializeNeck(self)
	InitializeGearLever(self)
	InitializeSteeringWheel(self)
	InitializeHandbrake(self)
	InitializePedals(self)
	InitializeIgnition(self)
end

function InitializeIKControls(self: BodyControllerImpl)
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

	local vehicle = self.Vehicle.Instance
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

function InitializeTorso(self: BodyControllerImpl)
	if not self.Player or not self.Player.Character then return end

	local humanoid =
		self.Player.Character:FindFirstChild("Humanoid") :: Humanoid
	local rootPart = humanoid.RootPart

	local upperTorso =
		self.Player.Character:FindFirstChild("UpperTorso") :: BasePart
	local waist = upperTorso:FindFirstChild("Waist") :: AnimationConstraint

	local rotationOffset = Vector3.new(math.rad(15), 0, 0)
	local acceleration = Vector3.zero
	local angularVelocity = Vector3.zero
	local spring = Vector3Spring.new(30, 200, 1000)

	self.trove:Connect(RunService.PreSimulation, function(deltaTime: number)
		acceleration = MathUtil.Lerp(
			acceleration,
			rootPart.CFrame:VectorToObjectSpace(self.Vehicle.Acceleration),
			deltaTime * 20
		)
		angularVelocity = MathUtil.Lerp(
			angularVelocity,
			rootPart.CFrame:VectorToObjectSpace(self.Vehicle.AngularVelocity),
			deltaTime * 20
		)

		-- Apply acceleration
		spring.Offset += Vector3.new(
			acceleration.Z + acceleration.Y,
			0,
			acceleration.X
		) * 0.025 * deltaTime

		-- Apply angular velocity
		spring.Offset += angularVelocity * Vector3.new(1, 0.5, 1) * 0.7 * deltaTime

		spring:Update(deltaTime)

		local rotation = rotationOffset - spring.Offset
		waist.Transform = CFrame.fromOrientation(
			math.clamp(rotation.X, -math.pi / 4, math.pi / 4),
			math.clamp(rotation.Y, -math.pi / 4, math.pi / 4),
			math.clamp(-rotation.Z, -math.pi / 4, math.pi / 4)
		)
	end)
end

function InitializeNeck(self: BodyControllerImpl)
	if not self.Player or not self.Player.Character then return end

	local humanoid =
		self.Player.Character:FindFirstChild("Humanoid") :: Humanoid
	local rootPart = humanoid.RootPart

	local upperTorso =
		self.Player.Character:FindFirstChild("UpperTorso") :: BasePart
	local head = self.Player.Character:FindFirstChild("Head") :: BasePart
	local neck = head:FindFirstChild("Neck") :: AnimationConstraint

	local rotationOffset = Vector3.new(-math.rad(10), 0, 0)
	local acceleration = Vector3.zero
	local angularVelocity = Vector3.zero
	local spring = Vector3Spring.new(5, 50, 500)

	self.trove:Connect(RunService.PreSimulation, function(deltaTime: number)
		acceleration = MathUtil.Lerp(
			acceleration,
			rootPart.CFrame:VectorToObjectSpace(self.Vehicle.Acceleration),
			deltaTime * 20
		)
		angularVelocity = MathUtil.Lerp(
			angularVelocity,
			rootPart.CFrame:VectorToObjectSpace(self.Vehicle.AngularVelocity),
			deltaTime * 20
		)

		-- Calculate look direction
		local direction = self.Vehicle.WeightPart.CFrame.LookVector
		if self.Vehicle.Velocity.Magnitude > 0 then
			direction = direction:Lerp(
				self.Vehicle.Velocity.Unit,
				math.min(self.Vehicle.Velocity.Magnitude / 10, 1)
					* self.Vehicle.WeightPart.CFrame.LookVector:Dot(
						self.Vehicle.Velocity.Unit
					)
					* 0.2
			)
		end

		-- Apply acceleration
		spring.Offset += Vector3.new(
			acceleration.Z + acceleration.Y,
			0,
			acceleration.X / 2
		) * 0.025 * deltaTime

		-- Apply angular velocity
		spring.Offset += angularVelocity * Vector3.new(1, 0, 1) * 2 * deltaTime

		spring:Update(deltaTime)

		local steeringRotation = Vector3.yAxis
			* self.Vehicle.Steering
			* math.rad(30)

		local rotation = rotationOffset - spring.Offset + steeringRotation
		neck.Transform = upperTorso.CFrame:ToObjectSpace(
			CFrame.lookAlong(
				Vector3.zero,
				direction,
				self.Vehicle.WeightPart.CFrame.UpVector
			)
				* CFrame.fromOrientation(rotation.X, -rotation.Y, rotation.Z)
		).Rotation
	end)
end

function InitializeSteeringWheel(self: BodyControllerImpl)
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

function InitializeHandbrake(self: BodyControllerImpl)
	local IKControl = self.IKControls.Handbrake
	if not IKControl then return end

	IKControl.Type = Enum.IKControlType.Transform

	local lastPBrake = false
	local curTask
	self.trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		if self.Vehicle.PBrake == lastPBrake then return end

		lastPBrake = self.Vehicle.PBrake
		IKControl.Weight = 1
		if curTask then task.cancel(curTask) end

		if lastPBrake then return end
		curTask = task.delay(0.3, function() IKControl.Weight = 0 end)
	end)
end

function InitializeGearLever(self: BodyControllerImpl)
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

function InitializePedals(self: BodyControllerImpl)
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

	self.trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		throttleIK.Weight = 0.05
			+ self.Vehicle.Throttle * (1 - self.Vehicle.Brake * 0.5)
		brakeIK.Weight = 0.05
			+ self.Vehicle.Brake * (1 - self.Vehicle.Throttle * 0.5)
		clutchIK.Weight = 0.05 + self.Vehicle.Clutch
	end)
end

function InitializeIgnition(self: BodyControllerImpl)
	local IKControl = self.IKControls.Ignition

	self.trove:Connect(
		RunService.Heartbeat,
		function(deltaTime: number)
			IKControl.Weight = self.Vehicle.IgnitionState == "Starting" and 1
				or 0
		end
	)
end

return table.freeze({ new = BodyController.new })
