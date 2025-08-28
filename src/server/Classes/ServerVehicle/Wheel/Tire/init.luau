local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ServerTire = {}
ServerTire.__index = ServerTire

type ServerTire = VehicleTypes.ServerWheelTire

function ServerTire.new(wheel: VehicleTypes.ServerWheel, instance: BasePart): ServerTire
	local self: ServerTire = setmetatable({}, ServerTire) :: any

	self.Wheel = wheel
	self.Vehicle = wheel.Vehicle
	self.Instance = instance
	self.Instance.Material = Enum.Material.Rubber
	self.Instance.Color = Color3.new()

	self._RE = Instance.new("UnreliableRemoteEvent")
	self._RE.Name = "_RE"
	self._RE.Parent = self.Instance

	Initialize(self)

	self._RE.OnServerEvent:Connect(function(...) Replicate(self, ...) end)

	return self
end

function Initialize(self: ServerTire)
	if not self.Wheel.Instance:FindFirstChild("SmokePart") then
		local caster = self.Wheel.IsFront and self.Vehicle.Tune.FCaster or self.Vehicle.Tune.RCaster
		caster = self.Wheel.IsRight and -caster or caster

		local smokePart = self.Wheel.Instance.Arm:Clone()
		smokePart.Name = "SmokePart"
		smokePart.Massless = true
		smokePart:ClearAllChildren()
		smokePart.CFrame = CFrame.new(
			(self.Wheel.Instance.CFrame * CFrame.new(0, -self.Wheel.Instance.Size.Y / 2, 0)).Position
		) * self.Wheel.Instance.Arm.CFrame.Rotation
		smokePart.Parent = self.Wheel.Instance

		local sa0 = Instance.new("Attachment")
		sa0.Name = "SmokePartAttachment0"
		sa0.Parent = self.Wheel.Instance.Base

		local sa1 = Instance.new("Attachment")
		sa1.Name = "SmokePartAttachment1"
		sa1.Position = Vector3.new(0, self.Wheel.Instance.Size.Y / 2 + self.Vehicle.Tune.AxleSize, 0)
		sa1.Parent = smokePart

		local smokePartRigidConstraint = Instance.new("RigidConstraint")
		smokePartRigidConstraint.Attachment0 = sa0
		smokePartRigidConstraint.Attachment1 = sa1
		smokePartRigidConstraint.Parent = smokePart

		local trailAttachmentPart = smokePart:Clone()
		trailAttachmentPart:ClearAllChildren()
		trailAttachmentPart.Name = "TrailAttachmentPart"
		trailAttachmentPart.Parent = self.Wheel.Instance

		local ta0 = Instance.new("Attachment")
		ta0.Parent = self.Wheel.Instance.Arm

		local ta1 = Instance.new("Attachment")
		ta1.Position = Vector3.new(0, self.Wheel.Instance.Size.Y / 2, 0)
		ta1.Parent = trailAttachmentPart

		local tapalign = Instance.new("AlignPosition")
		tapalign.ReactionForceEnabled = true
		tapalign.RigidityEnabled = true
		tapalign.Attachment0 = ta0
		tapalign.Attachment1 = ta1
		tapalign.Parent = trailAttachmentPart

		local tapOrientation = Instance.new("AlignOrientation")
		tapOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		tapOrientation.Attachment0 = ta1
		tapOrientation.MaxTorque = math.huge
		tapOrientation.RigidityEnabled = true
		tapOrientation.Parent = trailAttachmentPart

		local collision = Instance.new("Part")
		collision.Name = "Collision"
		collision.CanCollide = false -- false for now
		collision.CFrame = self.Wheel.Instance.CFrame
		collision.Transparency = self.Vehicle.Tune.TireFlexDebug and 0.5 or 1
		collision.Shape = Enum.PartType.Cylinder
		collision.Size = self.Wheel.Instance.Size
		collision.CollisionGroup = self.Wheel.Instance.CollisionGroup
		collision.Parent = self.Wheel.Instance

		ta0.Parent = self.Wheel.Instance.Collision
		ta0.Position = Vector3.new()
		ta1.Position = Vector3.new(0, self.Wheel.Instance.Size.Y / 2, 0)

		for _, v in self.Wheel.Instance:GetNoCollisionConstraints() do
			if v.Part0 == self.Wheel.Instance then v.Part0 = collision end
			if v.Part1 == self.Wheel.Instance then v.Part1 = collision end
		end

		local attachment = Instance.new("Attachment")
		attachment.Name = "#GRAVCOMP_ATTACH"
		attachment.Parent = collision

		for _, child in collision:GetChildren() do
			if child:IsA("VectorForce") and child.Name == "#GRAVCOMP" then child:Destroy() end
		end

		local force = Instance.new("VectorForce")
		force.Name = "#GRAVCOMP"
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.Attachment0 = attachment
		force.Force = Vector3.new(
			0,
			self.Vehicle.Tune.GravComp > 0 and collision.Mass * (game.Workspace.Gravity - self.Vehicle.Tune.GravComp)
				or 0,
			0
		)
		force.Parent = collision

		local mainAttachment = Instance.new("Attachment")
		mainAttachment.Orientation = self.Wheel.Instance.AB.Orientation
		mainAttachment.Parent = collision

		local alignForce = Instance.new("AlignPosition")
		alignForce.ReactionForceEnabled = true
		alignForce.Attachment0 = self.Wheel.Instance.AB
		alignForce.Attachment1 = mainAttachment
		alignForce.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		alignForce.ForceRelativeTo = Enum.ActuatorRelativeTo.World
		alignForce.Responsiveness = 100
		alignForce.MaxVelocity = 10
		alignForce.Parent = collision

		local rotationForce = Instance.new("AlignOrientation")
		rotationForce.ReactionTorqueEnabled = true
		rotationForce.RigidityEnabled = true
		rotationForce.Attachment0 = self.Wheel.Instance.AB
		rotationForce.Attachment1 = mainAttachment
		rotationForce.Responsiveness = math.huge
		rotationForce.Parent = collision

		local limiter = Instance.new("SpringConstraint")
		limiter.Name = "Limiter"
		limiter.Damping = 0
		limiter.Stiffness = 0
		limiter.MaxForce = 0
		limiter.Coils = 0
		limiter.Attachment0 = self.Wheel.Instance.AB
		limiter.Attachment1 = mainAttachment
		limiter.LimitsEnabled = true
		limiter.FreeLength = 0
		limiter.MaxLength = (
			self.Wheel.IsFront and self.Vehicle.Tune.TireFThickness or self.Vehicle.Tune.TireRThickness
		) / Units.Length_mm
		limiter.Parent = collision

		-- In future
		-- for _, v in self.Instance:GetJoints() do
		-- 	v:Destroy()
		-- end
		-- MakeWeld(self.Instance, collision)

		self.Wheel.Instance.CanCollide = false
		collision.CanCollide = true
	end
end

function Replicate(self: ServerTire, sender: Player, buf: buffer)
	for _, player in Players:GetPlayers() do
		if player == sender then continue end
		if not player.Character or (player.Character:GetPivot().Position - self.Instance.Position).Magnitude > 1000 then
			self._RE:FireClient(player)
			continue
		end

		self._RE:FireClient(player, buf)
	end
end

return ServerTire
