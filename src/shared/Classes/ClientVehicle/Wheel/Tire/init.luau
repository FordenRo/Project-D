local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local MakeWeld = require(ReplicatedStorage.Shared.Utils.MakeWeld)
local MaterialGroups = require(script.MaterialGroups)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local TirePacket = require(ReplicatedStorage.Shared.Packets.TirePacket)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleConstants = require(ReplicatedStorage.Shared.Vehicle.VehicleConstants)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ClientTire = {}
ClientTire.__index = ClientTire

type ClientTire = VehicleTypes.ClientWheelTire

function ClientTire.new(wheel: VehicleTypes.ClientWheel, instance: BasePart): ClientTire
	local self: ClientTire = setmetatable({}, ClientTire) :: any

	self.Wheel = wheel
	self.Vehicle = self.Wheel.Vehicle
	self.Instance = instance

	Initialize(self)

	self._RE = self.Instance:WaitForChild("_RE") :: UnreliableRemoteEvent

	local trove = Trove.new()
	trove:Connect(RunService.Heartbeat, function(deltaTime) FlexPhysicsUpdate(self, deltaTime) end)
	trove:Connect(self._RE.OnClientEvent, function(buf) Replicate(self, buf) end)
	trove:Add(task.spawn(function()
		while true do
			local deltaTime = task.wait(1 / 30)
			Update(self, deltaTime)
			if self.Vehicle.IsDriven then Replicate(self) end
		end
	end))
	trove:AttachToInstance(instance)

	return self
end

function InitializeVariables(self: ClientTire)
	self.Stress = 0
	self.Dirt = 0
	self.Health = 1
	self.TrailStress = 0
	self.Material = ""
	self._LastMaterial = ""
	self.SmokePart = self.Wheel.Instance.SmokePart :: any
	self.Collision = self.Wheel.Instance.Collision :: any
	self.TrailAttachmentPart = self.Wheel.Instance.TrailAttachmentPart :: any

	self.RayParams = RaycastParams.new()
	self.RayParams.FilterDescendantsInstances = { self.Vehicle.Instance }
	self.RayParams.FilterType = Enum.RaycastFilterType.Exclude
end

function Initialize(self: ClientTire)
	self.WearInstance = self.Instance:Clone()
	self.WearInstance:ClearAllChildren()
	self.WearInstance.Transparency = 1
	self.WearInstance.Color = Color3.new()
	self.WearInstance.Material = Enum.Material.Rock
	self.WearInstance.Size *= 1.006
	self.WearInstance.Parent = self.Instance
	MakeWeld(self.WearInstance, self.Instance)

	self.DirtInstance = self.Instance:Clone()
	self.DirtInstance:ClearAllChildren()
	self.DirtInstance.Transparency = 1
	self.DirtInstance.Color = Color3.new(0.6, 0.3, 0)
	self.DirtInstance.Size *= 1.003
	self.DirtInstance.Material = Enum.Material.Rock
	self.DirtInstance.Parent = self.Instance
	MakeWeld(self.DirtInstance, self.Instance)

	self.WheelDirtInstances = {}
	for k, v in self.Wheel.Instance.Parts:GetChildren() do
		if not v:IsA("BasePart") or v.Name == "Tire" then continue end

		local instance = v:Clone()
		instance:ClearAllChildren()
		instance.Transparency = 1
		instance.Color = Color3.new(0.6, 0.3, 0)
		instance.Material = Enum.Material.Rock
		instance.Size *= 1.003
		instance.Parent = v
		MakeWeld(instance, v)
		table.insert(self.WheelDirtInstances, instance)
	end

	InitializeVariables(self)

	local trailAttachment1 = Instance.new("Attachment")
	trailAttachment1.Name = "TrailAttachment1"
	trailAttachment1.Parent = self.TrailAttachmentPart

	local trailAttachment2 = Instance.new("Attachment")
	trailAttachment2.Name = "TrailAttachment2"
	trailAttachment2.Parent = self.TrailAttachmentPart

	local trailColors = {
		Road = ColorSequence.new(Color3.new(0, 0, 0)),
		Snow = ColorSequence.new(Color3.fromRGB(205, 250, 255)),
		Sand = ColorSequence.new(Color3.fromRGB(255, 241, 136)),
		Dirt = ColorSequence.new(Color3.fromRGB(255, 173, 102)),
	}

	task.defer(function()
		self.AudioPlayers = {}
		self.Emitters = {}
		self.Trails = {}
		for k, v in MaterialGroups do
			self.AudioPlayers[k] = self.Vehicle.SoundController.Sounds[`{self.Wheel.Instance.Name}Tire{k}`].AudioPlayer

			local emitter = ReplicatedStorage.Vehicle.Effects.Tires:FindFirstChild(k):Clone()
			emitter.Parent = self.SmokePart
			self.Emitters[k] = emitter

			self.Trails[k] = {}
			for i = 1, self.Vehicle.Tune.TireMarkTransparencyLevels do
				local trail = Instance.new("Trail")
				trail.Transparency = NumberSequence.new(self.Vehicle.Tune.TireMarkTransparency)
				trail.Texture = "rbxassetid://14987871952"
				trail.TextureMode = Enum.TextureMode.Static
				trail.Lifetime = 20
				trail.Enabled = false
				trail.Attachment0 = trailAttachment1
				trail.Attachment1 = trailAttachment2
				trail.Color = trailColors[k]
				trail.Parent = self.SmokePart
				self.Trails[k][i] = trail
			end
		end
	end)
end

function Replicate(self: ClientTire, buf: buffer?)
	if self.Vehicle.IsDriven then
		self._RE:FireServer(Serialization.Serialize(TirePacket, self))
	elseif buf then
		local data = Serialization.Deserialize(TirePacket, buf)
		for k, v in data do
			self[k] = v
		end
	else
		for _, v in self.Trails do
			for _, trail in v do
				trail.Enabled = false
			end
		end
		for _, v in self.Emitters do
			v.Enabled = false
		end
	end
end

function FlexPhysicsUpdate(self: ClientTire, deltaTime: number)
	if not self.Vehicle.IsDriven then return end

	local pressureForce = self.Wheel.IsFront and self.Vehicle.Tune.TireFPressureForce
		or self.Vehicle.Tune.TireRPressureForce
	self.Collision.AlignPosition.MaxForce = pressureForce
		* (100 + (self.Collision.Position - self.Wheel.Instance.Position).Magnitude ^ 2 * 10000)
end

function Update(self: ClientTire, deltaTime: number)
	local materialChanged = false

	-- Inner
	local ray = game.Workspace:Raycast(
		self.Wheel.Instance.Position,
		(
			(self.Wheel.Instance.Arm.CFrame * CFrame.new(
				-self.Wheel.Instance.Size.X / 2,
				-self.Wheel.Instance.Size.Y / 2,
				0
			)).Position - self.Wheel.Instance.Position
		) * 1.1,
		self.RayParams
	) -- Outer
		or game.Workspace:Raycast(
			self.Wheel.Instance.Position,
			(
				(self.Wheel.Instance.Arm.CFrame * CFrame.new(
					self.Wheel.Instance.Size.X / 2,
					-self.Wheel.Instance.Size.Y / 2,
					0
				)).Position - self.Wheel.Instance.Position
			) * 1.1,
			self.RayParams
		)

	if self.Vehicle.IsDriven then
		local rotSpeed = math.abs(self.Wheel.Instance.AssemblyAngularVelocity:Dot(self.SmokePart.CFrame.RightVector))
		local rotLinearSpeed = rotSpeed * (self.Wheel.Instance.Size.Y / 2)
		local speed = self.Vehicle.Velocity.Magnitude
		local diff = math.abs(rotLinearSpeed - speed)

		if ray then
			for k, v in MaterialGroups do
				if not table.find(v, ray.Material.Name) then continue end

				self.Material = k
				break
			end
			if self._LastMaterial ~= self.Material then materialChanged = true end
		end

		-- Slip
		local vstress = (
			math.max(
				ray and diff / 20 or 0,
				ray and self.Material ~= "Road" and self.Material ~= "" and rotSpeed / 50 or 0
			) + self.Vehicle.Tune.TireSpeedStress * (rotLinearSpeed / (Units.Velocity_mdivs / 3.6) / 100)
		)

		if ray and self.Material ~= "Road" and self.Material ~= "" then
			local random = Random.new():NextNumber() * speed
			if random > 20 then
				self.Wheel.Instance.AssemblyLinearVelocity += Vector3.new(
					0,
					math.random(0, self.Vehicle.Tune.TireDirtBumps),
					0
				) * math.min(speed / 100, 5)
			end
		end

		if vstress > 0.05 * (60 / (1 / deltaTime)) and vstress > self.Stress then
			self.Stress = math.min(self.Stress + 0.05 * (60 / (1 / deltaTime)), math.min(vstress, 1))
		else
			self.Stress = math.max(self.Stress - 0.05 * (60 / (1 / deltaTime)), vstress)
		end

		-- Update dirt
		if self.Material ~= "Road" and self.Material ~= "" then
			self.Dirt = Lerp(self.Dirt, 1, rotSpeed * 0.003 * deltaTime)
			self.Vehicle.Dirt = math.clamp(math.min(rotSpeed * 0.0002 * deltaTime, 1), 0, 1)
		else
			self.Dirt = Lerp(self.Dirt, 0, rotSpeed * 0.0001 * deltaTime)
		end

		-- Apply friction
		local materialHeatFactor = self.Material ~= "Road" and 0.01 or 1
		local currentPhysicalProperties = self.Wheel.Instance.CurrentPhysicalProperties
		self.Health =
			math.clamp(self.Health - self.Stress * materialHeatFactor * self.Vehicle.Tune.TireDamage * deltaTime, 0, 1)

		local loss = (1 - self.Health) ^ 2 * self.Vehicle.Tune.TireWearLoss + self.Dirt * self.Vehicle.Tune.TireDirtLoss
		local density
		local friction
		if self.Wheel.IsFront then
			density = math.round(
				(
					((self.Vehicle.Tune.FWheelWeight - self.Vehicle.Tune.TireFWeight) * Units.Mass_kg)
					/ (math.pi * (self.Wheel.Instance.Size.Y / 2) ^ 2 * self.Wheel.Instance.Size.X)
				) * 1000
			) / 1000
			friction = math.round(math.clamp(self.Vehicle.Tune.TireFMaxFriction - loss, 0, 2) * 1000) / 1000
		else
			density = math.round(
				(
					((self.Vehicle.Tune.RWheelWeight - self.Vehicle.Tune.TireRWeight) * Units.Mass_kg)
					/ (math.pi * (self.Wheel.Instance.Size.Y / 2) ^ 2 * self.Wheel.Instance.Size.X)
				) * 1000
			) / 1000
			friction = math.round(math.clamp(self.Vehicle.Tune.TireRMaxFriction - loss, 0, 2) * 1000) / 1000
		end

		if
			math.round(currentPhysicalProperties.Friction * 1000) / 1000 ~= friction
			or math.round(currentPhysicalProperties.Density * 1000) / 1000 ~= density
		then
			self.Wheel.Instance.CustomPhysicalProperties = PhysicalProperties.new(
				density,
				friction,
				currentPhysicalProperties.Elasticity,
				currentPhysicalProperties.FrictionWeight,
				currentPhysicalProperties.ElasticityWeight
			)
		end

		if ray and self.Material == "Sand" then
			self.Wheel.Instance:ApplyImpulseAtPosition(
				-self.Wheel.Instance.AssemblyLinearVelocity * self.Vehicle.Tune.TireSandForce * deltaTime,
				self.Wheel.Instance.Position
			)
		end

		-- Tire flex
		local flexDensity = math.round(
			(
				(
					(self.Wheel.IsFront and self.Vehicle.Tune.TireFWeight or self.Vehicle.Tune.TireRWeight)
					* Units.Mass_kg
				) / (math.pi * (self.Wheel.Instance.Size.Y / 2) ^ 2 * self.Wheel.Instance.Size.X)
			) * 1000
		) / 1000
		local flexCurrentPhysicalProperties = self.Collision.CurrentPhysicalProperties
		if
			math.round(flexCurrentPhysicalProperties.Density * 1000) / 1000 ~= flexDensity
			or currentPhysicalProperties.Friction ~= flexCurrentPhysicalProperties.Friction
			or currentPhysicalProperties.Elasticity ~= flexCurrentPhysicalProperties.Elasticity
			or currentPhysicalProperties.FrictionWeight ~= flexCurrentPhysicalProperties.FrictionWeight
			or currentPhysicalProperties.ElasticityWeight ~= flexCurrentPhysicalProperties.ElasticityWeight
		then
			self.Collision.CustomPhysicalProperties = PhysicalProperties.new(
				flexDensity,
				currentPhysicalProperties.Friction,
				currentPhysicalProperties.Elasticity,
				currentPhysicalProperties.FrictionWeight,
				currentPhysicalProperties.ElasticityWeight
			)
		end
		self.Collision["#GRAVCOMP"].Force = Vector3.new(
			0,
			VehicleConstants.GravComp > 0 and self.Collision.Mass * (game.Workspace.Gravity - VehicleConstants.GravComp)
				or 0,
			0
		)
	else
		if self.Material ~= self._LastMaterial then materialChanged = true end
	end

	self._LastMaterial = self.Material

	-- Disable sounds, smokes and trails
	if materialChanged then
		for _, v in self.AudioPlayers do
			v:Stop()
		end
		for _, v in self.Emitters do
			v.Enabled = false
		end
		for _, v in self.Trails do
			for _, trail in v do
				trail.Enabled = false
			end
		end
	end

	-- Set Trails
	local smokeStress = math.clamp(self.Stress - self.Vehicle.Tune.TireSmokeStressOffset / 100, 0, 1)
	local trailStress = math.floor(smokeStress ^ 3 * self.Vehicle.Tune.TireMarkTransparencyLevels)
	if self.Trails[self.Material] then
		for i = 1, (trailStress > self.TrailStress and trailStress or self.TrailStress) do
			self.Trails[self.Material][i].Enabled = trailStress >= i
		end
	end
	self.TrailStress = trailStress

	-- Play sound
	local audioPlayer = self.AudioPlayers[self.Material]
	if audioPlayer then
		if not audioPlayer.IsPlaying then
			audioPlayer.TimePosition = math.random() * audioPlayer.TimeLength -- Avoid overlapping sounds
			audioPlayer:Play()
		end
		audioPlayer.Volume = smokeStress ^ 3 * 1.4
		audioPlayer.PlaybackSpeed = 1.6 - 0.5 * smokeStress
	end

	local emitter = self.Emitters[self.Material]
	if emitter then
		emitter.Enabled = true
		emitter.Rate = smokeStress ^ 10 * 100
	end

	local compression = 1
	if self.Collision then
		compression = math.clamp((self.Wheel.Instance.Position - self.Collision.Position).Magnitude / 0.1, 0, 1)
	end
	if
		self.TrailAttachmentPart
		and smokeStress > 0.05
		and self.Wheel.Instance.AssemblyLinearVelocity.Magnitude > 10
	then
		self.TrailAttachmentPart.TrailAttachment1.Position =
			Vector3.new(self.Wheel.Instance.Size.X / 2 - 0.2 + 0.1 * compression, 0.02, 0)
		self.TrailAttachmentPart.TrailAttachment2.Position =
			Vector3.new(-self.Wheel.Instance.Size.X / 2 + 0.2 - 0.1 * compression, 0.02, 0)
		self.TrailAttachmentPart.AlignOrientation.CFrame = CFrame.lookAt(
			self.SmokePart.Position,
			(self.SmokePart.CFrame * CFrame.new(
				0,
				0,
				-5 + math.min(self.Wheel.Instance.AssemblyLinearVelocity.Magnitude, 5)
			)).Position + self.Wheel.Instance.AssemblyLinearVelocity,
			ray and ray.Normal or self.SmokePart.CFrame.UpVector
		)
	end

	-- Visual
	self.Instance.Color = Color3.fromHSV(0, 0, (1 - self.Health) * 0.2)
	self.WearInstance.Color = Color3.fromHSV(0, 0, (1 - self.Health) * 0.6)
	self.WearInstance.Transparency = self.Health * 0.5 + 0.5
	self.DirtInstance.Transparency = 1 - self.Dirt ^ 1.5 * 0.5

	for _, v in self.WheelDirtInstances do
		v.Transparency = 1 - self.Dirt ^ 1.5 * 0.5
	end
end

return ClientTire
