local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SettingsController = require(ReplicatedStorage.Shared.Controllers.SettingsController)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

local BodyController = {}
BodyController.__index = BodyController

export type BodyController = typeof(setmetatable(
	{} :: {
		_RightHanded: boolean,
		Vehicle: VehicleTypes.ClientVehicle,
		IKControls: { [string]: IKControl },
		Attachments: { [string]: Attachment },
	},
	BodyController
))

function BodyController.new(vehicle: VehicleTypes.ClientVehicle): BodyController
	local self: BodyController = setmetatable({}, BodyController) :: any

	self.Vehicle = vehicle
	self.IKControls = {}
	self.Attachments = {}

	InitializeIKControls(self)
	InitializeGearLever(self)
	InitializeTorso(self)
	InitializeSteeringWheel(self)
	InitializeHandbrake(self)
	InitializePedals(self)
	InitializeIgnition(self)

	self.Vehicle.Instance.Destroying:Once(function() self:Destroy() end)

	return self
end

function InitializeIKControls(self: BodyController)
	local function make(name: string, chainRoot: string, endEffector: string, target: Attachment, priority: number?)
		if not target then return end

		local IKControl = Instance.new("IKControl")
		IKControl.Name = name .. "IK"
		IKControl.ChainRoot = player.Character:FindFirstChild(chainRoot)
		IKControl.EndEffector = player.Character:FindFirstChild(endEffector)
		IKControl.Type = Enum.IKControlType.Position
		IKControl.Priority = priority or 1
		IKControl.Weight = 0
		IKControl.Target = target
		IKControl.Parent = player.Character

		self.IKControls[name] = IKControl
		self.Attachments[name] = target
	end
	local function makeSided(
		name: string,
		chainRoot: string,
		endEffector: string,
		target: Attachment,
		priority: number?
	)
		local side = self.Vehicle.Instance.DriveSeat.CFrame:PointToObjectSpace(target.WorldPosition).X > 0 and "Right"
			or "Left"

		make(name, side .. chainRoot, side .. endEffector, target, priority)
	end

	local vehicle = self.Vehicle.Instance
	make("Torso", "LowerTorso", "UpperTorso", vehicle.DriveSeat:FindFirstChild("HeadAttachment"))
	make(
		"RightHandWheel",
		"RightUpperArm",
		"RightHand",
		vehicle.Misc:FindFirstChild("SteeringWheel"):FindFirstChild("RightHandAttachment")
	)
	make(
		"LeftHandWheel",
		"LeftUpperArm",
		"LeftHand",
		vehicle.Misc:FindFirstChild("SteeringWheel"):FindFirstChild("LeftHandAttachment")
	)
	makeSided(
		"Handbrake",
		"UpperArm",
		"Hand",
		vehicle.Misc:FindFirstChild("Handbrake"):FindFirstChild("HandAttachment"),
		2
	)
	makeSided(
		"GearLever",
		"UpperArm",
		"Hand",
		vehicle.Misc:FindFirstChild("GearLever"):FindFirstChild("HandAttachment"),
		3
	)
	makeSided(
		"Ignition",
		"UpperArm",
		"Hand",
		vehicle.Body:FindFirstChild("Buttons"):FindFirstChild("Ignition"):FindFirstChild("HandAttachment"),
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
		make("Brake", "RightUpperLeg", "RightFoot", pedals:FindFirstChild("Brake"):FindFirstChild("FootAttachment"))
		make("Clutch", "LeftUpperLeg", "LeftFoot", pedals:FindFirstChild("Clutch"):FindFirstChild("FootAttachment"))
	end
end

function InitializeTorso(self: BodyController)
	local IKControl = self.IKControls.Torso
	if not IKControl then return end

	local attachment = self.Attachments.Torso
	IKControl.Weight = 1
	IKControl.SmoothTime = 0

	local startCFrame = attachment.CFrame
	local offset = Vector3.zero
	RunService.Heartbeat:Connect(function(deltaTime: number)
		local force = self.Vehicle.Acceleration.Magnitude
		if force > 0 then offset = offset:Lerp(force * self.Vehicle.Acceleration.Unit, deltaTime * 2) end
		attachment.CFrame = startCFrame + attachment.WorldCFrame:VectorToObjectSpace(-offset) * 0.01
	end)
end

function InitializeSteeringWheel(self: BodyController)
	local rightIK = self.IKControls.RightHandWheel
	local leftIK = self.IKControls.LeftHandWheel
	if not rightIK or not leftIK then return end

	local leftShoulderAttachment =
		player.Character:FindFirstChild("LeftUpperArm"):FindFirstChild("LeftShoulderAttachment") :: Attachment
	local rightShoulderAttachment =
		player.Character:FindFirstChild("RightUpperArm"):FindFirstChild("RightShoulderAttachment") :: Attachment

	leftShoulderAttachment.CFrame *= CFrame.new(0, 0.2, 0)
	rightShoulderAttachment.CFrame *= CFrame.new(0, 0.2, 0)

	rightIK.SmoothTime = 0
	leftIK.SmoothTime = 0
	rightIK.Weight = 1
	leftIK.Weight = 1
end

function InitializeHandbrake(self: BodyController)
	local IKControl = self.IKControls.Handbrake
	if not IKControl then return end

	IKControl.Type = Enum.IKControlType.Transform

	local lastPBrake = false
	local curTask
	RunService.Heartbeat:Connect(function(deltaTime: number)
		if self.Vehicle.PBrake == lastPBrake then return end

		lastPBrake = self.Vehicle.PBrake
		IKControl.Weight = 1
		if curTask then task.cancel(curTask) end

		if lastPBrake then return end
		curTask = task.delay(0.3, function() IKControl.Weight = 0 end)
	end)
end

function InitializeGearLever(self: BodyController)
	local IKControl = self.IKControls.GearLever
	if not IKControl then return end

	local lastGear = 0
	local curTask
	RunService.Heartbeat:Connect(function(deltaTime: number)
		local oneHanded = SettingsController:GetSetting("OneHandedSteering")
		if oneHanded then IKControl.Weight = (not self.Vehicle.PBrake or curTask) and 1 or 0 end
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
			until tick() - t > 2 or self.Vehicle.Clutch < 0.5 or self.Vehicle.PBrake
			if not oneHanded then IKControl.Weight = 0 end
			curTask = nil
		end)
	end)
end

function InitializePedals(self: BodyController)
	local throttleIK = self.IKControls.Throttle
	local brakeIK = self.IKControls.Brake
	local clutchIK = self.IKControls.Clutch
	if not throttleIK or not brakeIK or not clutchIK then return end

	throttleIK.SmoothTime = 0
	brakeIK.SmoothTime = 0
	clutchIK.SmoothTime = 0

	local leftHipAttachment =
		player.Character:FindFirstChild("LeftUpperLeg"):FindFirstChild("LeftHipRigAttachment") :: Attachment
	local rightHipAttachment =
		player.Character:FindFirstChild("RightUpperLeg"):FindFirstChild("RightHipRigAttachment") :: Attachment

	leftHipAttachment.CFrame *= CFrame.new(0, 0.5, 0)
	rightHipAttachment.CFrame *= CFrame.new(0, 0.5, 0)

	RunService.Heartbeat:Connect(function(deltaTime: number)
		throttleIK.Weight = 0.05 + self.Vehicle.Throttle * (1 - self.Vehicle.Brake * 0.5)
		brakeIK.Weight = 0.05 + self.Vehicle.Brake * (1 - self.Vehicle.Throttle * 0.5)
		clutchIK.Weight = 0.05 + self.Vehicle.Clutch
	end)
end

function InitializeIgnition(self: BodyController)
	local IKControl = self.IKControls.Ignition

	RunService.Heartbeat:Connect(function(deltaTime: number) IKControl.Weight = self.Vehicle.Starting and 1 or 0 end)
end

function BodyController.Destroy(self: BodyController) end

return BodyController
