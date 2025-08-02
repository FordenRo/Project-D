local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MakeWeld = require(ReplicatedStorage.Shared.Utils.MakeWeld)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)
local Units = require(ReplicatedStorage.Shared.Utils.Units)

local ServerTire = {}
ServerTire.__index = ServerTire

type ServerTire = Types.ServerWheelTire

function ServerTire.new(wheel: Types.ServerWheel, instance: BasePart)
	local self: ServerTire = setmetatable({}, ServerTire) :: any

	self.Wheel = wheel
	self.Vehicle = wheel.Vehicle
	self.Instance = instance
	self.Instance.Material = Enum.Material.Rubber
	self.Instance.Color = Color3.new()

	self.WearInstance = self.Instance:Clone()
	self.WearInstance.Transparency = 1
	self.WearInstance.Color = Color3.new()
	self.WearInstance.Material = Enum.Material.Rock
	self.WearInstance.Parent = self.Instance
	MakeWeld(self.WearInstance, self.Instance)

	self.DirtInstance = self.Instance:Clone()
	self.DirtInstance.Transparency = 1
	self.DirtInstance.Color = Color3.new(0.6, 0.3, 0)
	self.DirtInstance.Material = Enum.Material.Rock
	self.DirtInstance.Parent = self.Instance
	MakeWeld(self.DirtInstance, self.Instance)

	self.PreviousMaterialData = {}
	self.PreviousSoundsData = {}
	self.PreviousSmokesData = {}
	self.PreviousTrailsData = {}

	self._Remote = Instance.new("UnreliableRemoteEvent")
	self._Remote.Name = "_Remote"
	self._Remote.Parent = self.Instance

	self:Initialize()
	self._Remote.OnServerEvent:Connect(function(_, ...) self:Replicate(...) end)

	return self
end

function ServerTire.Initialize(self: ServerTire)
	if not self.Wheel.Instance:FindFirstChild("SmokePart") then
		local caster = string.find(self.Wheel.Instance.Name, "F") and self.Vehicle.Tune.FCaster
			or self.Vehicle.Tune.RCaster
		caster = (self.Wheel.Instance.Name == "FR" or self.Wheel.Instance.Name == "RR") and -caster or caster

		local smokePart = self.Wheel.Instance:FindFirstChild("SmokePart") or self.Wheel.Instance.Arm:Clone()
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

		for _, a in ReplicatedStorage.Vehicle.Tires:GetChildren() do
			if smokePart:FindFirstChild(a.Name) then continue end

			local clone = a:Clone()
			clone.Parent = smokePart
		end

		-- create trails
		local trailAttachmentPart = self.Wheel.Instance:FindFirstChild("TrailAttachmentPart") or smokePart:Clone()
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

		local a0 = Instance.new("Attachment")
		a0.Name = "TrailAttachment0"
		a0.Parent = trailAttachmentPart

		local a1 = Instance.new("Attachment")
		a1.Name = "TrailAttachment1"
		a1.Parent = trailAttachmentPart

		local collision = self.Wheel.Instance:FindFirstChild("Collision") or Instance.new("Part")
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

		for _, a in self.Wheel.Instance:GetNoCollisionConstraints() do
			if a.Part0 == self.Wheel.Instance then a.Part0 = collision end
			if a.Part1 == self.Wheel.Instance then a.Part1 = collision end
		end

		local model = self.Wheel.Instance:FindFirstChild("CollisionModel")
		if model then
			for _, a in model:GetDescendants() do
				if a:IsA("BasePart") then
					local weld = a:FindFirstChild("Weld")
					if weld and weld.Part1 == self.Wheel.Instance then weld.Part1 = collision end
				end
			end
			collision.CanCollide = false
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
		mainAttachment.Orientation = self.Wheel.Instance["AB"].Orientation
		mainAttachment.Parent = collision

		local alignForce = Instance.new("AlignPosition")
		alignForce.ReactionForceEnabled = true
		alignForce.Attachment0 = self.Wheel.Instance["AB"]
		alignForce.Attachment1 = mainAttachment
		alignForce.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		alignForce.ForceRelativeTo = Enum.ActuatorRelativeTo.World
		alignForce.Responsiveness = 100
		alignForce.MaxVelocity = 10
		alignForce.Parent = collision

		local rotationForce = Instance.new("AlignOrientation")
		rotationForce.ReactionTorqueEnabled = true
		rotationForce.RigidityEnabled = true
		rotationForce.Attachment0 = self.Wheel.Instance["AB"]
		rotationForce.Attachment1 = mainAttachment
		rotationForce.Responsiveness = math.huge
		rotationForce.Parent = collision

		local limiter = Instance.new("SpringConstraint")
		limiter.Name = "Limiter"
		limiter.Damping = 0
		limiter.Stiffness = 0
		limiter.MaxForce = 0
		limiter.Coils = 0
		limiter.Attachment0 = self.Wheel.Instance["AB"]
		limiter.Attachment1 = mainAttachment
		limiter.LimitsEnabled = true
		limiter.FreeLength = 0
		limiter.Parent = collision

		if string.find(self.Wheel.Instance.Name, "F") then
			limiter.MaxLength = self.Vehicle.Tune.TireFThickness / Units.Length_mm
		else
			limiter.MaxLength = self.Vehicle.Tune.TireRThickness / Units.Length_mm
		end

		self.Wheel.Instance.CanCollide = false
		collision.CanCollide = true

		local TAPRayParams = RaycastParams.new()
		TAPRayParams.FilterType = Enum.RaycastFilterType.Exclude
		TAPRayParams.FilterDescendantsInstances = { self.Vehicle.Instance }

		if self.Vehicle.Tune.TireMarkTransparencyLevels > 0 then
			for m = 1, 4 do
				for i = 1, self.Vehicle.Tune.TireMarkTransparencyLevels do
					local name = "Trail"
						.. ((m == 1 and "road") or (m == 2 and "snow") or (m == 3 and "sand") or (m == 4 and "dirt") or "")
						.. i
					local trail = smokePart:FindFirstChild(name) or Instance.new("Trail")
					trail.Name = name
					trail.Transparency = NumberSequence.new(self.Vehicle.Tune.TireMarkTransparency)
					trail.Texture = "rbxassetid://14987871952"
					trail.TextureMode = Enum.TextureMode.Static
					trail.Lifetime = 20
					trail.Enabled = false
					trail.Attachment0 = a0
					trail.Attachment1 = a1
					trail:SetAttribute("stress", i / self.Vehicle.Tune.TireMarkTransparencyLevels)
					if m == 1 then
						trail.Color = ColorSequence.new(Color3.new(0, 0, 0))
					elseif m == 2 then
						trail.Color = ColorSequence.new(Color3.fromRGB(205, 250, 255))
					elseif m == 3 then
						trail.Color = ColorSequence.new(Color3.fromRGB(255, 241, 136))
					else
						trail.Color = ColorSequence.new(Color3.fromRGB(255, 173, 102))
					end
					trail.Parent = smokePart
				end
			end
		end
	end
end

function ServerTire.Replicate(
	self: ServerTire,
	materialType: string,
	smokeStress: number,
	rayNormal: Vector3,
	temperature: number,
	dirt: number,
	deltaTime: number
)
	-- if not self.Vehicle.Occupant then return end
	-- Set smokepart data
	local smokePart = self.Wheel.Instance:FindFirstChild("SmokePart")
	if not smokePart then return end

	local materialChanged = self.PreviousMaterialData[self.Wheel.Instance] ~= materialType
	self.PreviousMaterialData[self.Wheel.Instance] = materialType

	local currentSound = self.PreviousSoundsData[self.Wheel.Instance]
	local currentSmoke = self.PreviousSmokesData[self.Wheel.Instance]
	if materialChanged then
		if currentSound then currentSound.Playing = false end
		if currentSmoke then currentSmoke.Enabled = false end
		currentSound = smokePart:FindFirstChild("Sound_" .. materialType)
		currentSmoke = smokePart:FindFirstChild("Smoke_" .. materialType)
		self.PreviousSoundsData[self.Wheel.Instance] = currentSound
		self.PreviousSmokesData[self.Wheel.Instance] = currentSmoke
	end
	for _, d in smokePart:GetChildren() do
		if d.ClassName == "Trail" then
			d.Enabled = false
			if
				materialType ~= ""
				and string.find(d.Name, materialType)
				and d:GetAttribute("stress") < smokeStress ^ 3
				and rayNormal
			then
				d.Enabled = true
			end
		end
	end
	if currentSound then
		-- Sound
		if not currentSound.Playing then
			currentSound.TimePosition = Random.new():NextNumber() * currentSound.TimeLength --avoid overlapping sounds
		end
		currentSound.Playing = true
		currentSound.Volume = smokeStress ^ 3 * 1.4
		currentSound.PlaybackSpeed = 1.6 - 0.5 * smokeStress
		local tremolo = currentSound:FindFirstChildWhichIsA("TremoloSoundEffect")
		if tremolo then
			local lateralDiff = (
				math.abs(self.Wheel.Instance.AssemblyLinearVelocity:Dot(self.Wheel.Instance.CFrame.RightVector))
				/ self.Wheel.Instance.AssemblyLinearVelocity.Magnitude
			)
			tremolo.Depth = lateralDiff
		end
	end
	if currentSmoke then
		-- Smoke
		currentSmoke.Enabled = true
		currentSmoke.Rate = smokeStress ^ 10 * 100
	end
	local compression = 1
	if self.Wheel.Instance:FindFirstChild("Collision") then
		compression =
			math.clamp((self.Wheel.Instance.Position - self.Wheel.Instance.Collision.Position).Magnitude / 0.1, 0, 1)
	end
	local trailAttachmentPart = self.Wheel.Instance:FindFirstChild("TrailAttachmentPart")
	if trailAttachmentPart and smokeStress > 0.05 and self.Wheel.Instance.AssemblyLinearVelocity.Magnitude > 10 then
		trailAttachmentPart.TrailAttachment0.Position =
			Vector3.new(self.Wheel.Instance.Size.X / 2 - 0.2 + 0.1 * compression, 0.02, 0)
		trailAttachmentPart.TrailAttachment1.Position =
			Vector3.new(-self.Wheel.Instance.Size.X / 2 + 0.2 - 0.1 * compression, 0.02, 0)
		trailAttachmentPart.AlignOrientation.CFrame = CFrame.lookAt(
			smokePart.Position,
			(
				smokePart.CFrame
				* CFrame.new(0, 0, -5 + math.min(self.Wheel.Instance.AssemblyLinearVelocity.Magnitude, 5))
			).Position + self.Wheel.Instance.AssemblyLinearVelocity,
			rayNormal or smokePart.CFrame.UpVector
		)
	end

	smokePart.SmokePartAttachment1.Position = Vector3.new(
		0,
		self.Wheel.Instance.Size.Y / 2 + self.Vehicle.Tune.AxleSize,
		0
	) + smokePart.CFrame:VectorToObjectSpace(self.Wheel.Instance.AssemblyLinearVelocity) * deltaTime

	local wear = (temperature - 40)
		/ (
			(
				string.find(self.Wheel.Instance.Name, "F") and self.Vehicle.Tune.TireFMaxTemp
				or self.Vehicle.Tune.TireRMaxTemp
			) - 40
		)
	wear = math.clamp(wear, 0, 1)

	self.Instance.Color = Color3.fromHSV(0, 0, wear * 0.2)
	self.WearInstance.Color = Color3.fromHSV(0, 0, wear * 0.4)
	self.WearInstance.Transparency = 1 - (wear * 0.5)
	self.DirtInstance.Transparency = 1 - dirt ^ 1.5 * 0.6
end

return ServerTire
