local HapticService = game:GetService("HapticService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local MaterialGroups = require(script.MaterialGroups)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local isVibrationSupported = HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)
UserInputService.GamepadConnected:Connect(
	function() isVibrationSupported = HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1) end
)

local ClientTire = {}
ClientTire.__index = ClientTire

type ClientTire = VehicleTypes.ClientWheelTire

function ClientTire.new(wheel: VehicleTypes.ClientWheel, instance: BasePart)
	local self: ClientTire = setmetatable({}, ClientTire) :: any

	self.Wheel = wheel
	self.Vehicle = self.Wheel.Vehicle
	self.Instance = instance

	Initialize(self)
	self._Remote = self.Instance:WaitForChild("_Remote") :: UnreliableRemoteEvent

	return self
end

function InitializeVariables(self: ClientTire)
	self.Temperature = game.Workspace:GetAttribute("GlobalTemperature") :: number
	self.Stress = 0
	self.Dirt = 0
	self.Ray = nil
	self.RayParams = RaycastParams.new()
	self.RayParams.FilterDescendantsInstances = { self.Vehicle.Instance }
	self.RayParams.FilterType = Enum.RaycastFilterType.Exclude
	self.Material = ""
	self.SmokePart = self.Wheel.Instance:FindFirstChild("SmokePart")
	self.Collision = self.Wheel.Instance:FindFirstChild("Collision")
	self.CollisionModel = self.Wheel.Instance:FindFirstChild("CollisionModel")
	self.FlexCollision = self.Collision
	self.FlexCollisionGravComp = self.FlexCollision:FindFirstChild("#GRAVCOMP")
	self.ObjectGravComp = self.Wheel.Instance:FindFirstChild("#GRAVCOMP")
	self.TrailAttachmentPart = self.Wheel.Instance:FindFirstChild("TrailAttachmentPart")
	self.FlexCollisionAlignPosition = self.FlexCollision:FindFirstChild("AlignPosition")
	self.CurrentSound = nil
	self.CurrentSmoke = nil
	self.CurrentWheelSmoke = nil
	self.CurrentTrail = nil
	self.TrailStress = 0
	self.Trails = {
		road = {},
		dirt = {},
		snow = {},
		sand = {},
	}
	self._deltaTime = 0
	self.Sounds = {}
	self.Smokes = {}
	self.WheelSmokes = {}
	-- Tremolo
end

function Initialize(self: ClientTire)
	InitializeVariables(self)

	if self.Vehicle.Tune.TireSmokeEffects == "Local" or self.Vehicle.Tune.TireSmokeEffects == "All" then
		for _, v in self.SmokePart:GetChildren() do
			if string.find(v.Name, "Local_") then continue end
			if v:IsA("Trail") or v:IsA("ParticleEmitter") or v:IsA("Sound") then
				local effectType = (string.find(v.Name, "road") and "road")
					or (string.find(v.Name, "sand") and "sand")
					or (string.find(v.Name, "dirt") and "dirt")
					or (string.find(v.Name, "snow") and "snow")
				local effect = v
				if self.Vehicle.Tune.TireSmokeEffects == "Local" then
					v.Name = "Local_" .. v.Name
				else
					local new = self.SmokePart:FindFirstChild("Local_" .. v.Name) or v:Clone()
					new.Name = "Local_" .. v.Name
					new.Parent = self.SmokePart
					effect = new
					if v:IsA("Trail") then
						v:SetAttribute("data", v.Lifetime)
						v.Lifetime = 0
					elseif v:IsA("ParticleEmitter") then
						v:SetAttribute("data", v.Lifetime)
						v.Lifetime = NumberRange.new(0)
					else
						v:SetAttribute("data", v.SoundId)
						v.SoundId = ""
					end
				end
				if v:IsA("Trail") then
					self.Trails[effectType][math.round(
						(v:GetAttribute("stress") :: number) * self.Vehicle.Tune.TireMarkTransparencyLevels
					)] =
						effect
				elseif v:IsA("ParticleEmitter") then
					self.Smokes[effectType] = effect
				elseif v:IsA("Sound") then
					self.Sounds[effectType] = effect
				end
			end
		end
		for _, v in self.Wheel.Instance:FindFirstChild("WheelSmokePart"):GetChildren() do
			if string.find(v.Name, "Local_") then continue end
			if v:IsA("ParticleEmitter") then
				local effectType = (string.find(v.Name, "road") and "road")
					or (string.find(v.Name, "sand") and "sand")
					or (string.find(v.Name, "dirt") and "dirt")
					or (string.find(v.Name, "snow") and "snow")
				local effect = v
				if self.Vehicle.Tune.TireSmokeEffects == "Local" then
					v.Name = "Local_" .. v.Name
				else
					local new = self.Wheel.Instance.WheelSmokePart:FindFirstChild("Local_" .. v.Name) or v:Clone()
					new.Name = "Local_" .. v.Name
					new.Parent = self.Wheel.Instance.WheelSmokePart
					effect = new
					v:SetAttribute("data", v.Lifetime)
					v.Lifetime = NumberRange.new(0)
				end
				self.WheelSmokes[effectType] = effect
			end
		end
	end

	task.spawn(function()
		while true do
			Update(self, task.wait(1 / 30))
			SmokeUpdate(self)
		end
	end)
	RunService.Heartbeat:Connect(function(deltaTime) FlexPhysicsUpdate(self, deltaTime) end)
end

function FlexPhysicsUpdate(self: ClientTire, deltaTime: number)
	self._deltaTime = deltaTime
	if self.Wheel.IsFront then
		self.FlexCollisionAlignPosition.MaxForce = self.Vehicle.Tune.TireFPressureForce
			* (100 + (self.FlexCollision.Position - self.Wheel.Instance.Position).Magnitude ^ 2 * 10000)
	else
		self.FlexCollisionAlignPosition.MaxForce = self.Vehicle.Tune.TireRPressureForce
			* (100 + (self.FlexCollision.Position - self.Wheel.Instance.Position).Magnitude ^ 2 * 10000)
	end
end

function SmokeUpdate(self: ClientTire)
	local smokeStress = math.clamp(self.Stress - self.Vehicle.Tune.TireSmokeStressOffset / 100, 0, 1)
	self._Remote:FireServer(
		self.Material,
		smokeStress,
		self.Ray and self.Ray.Normal,
		self.Temperature,
		self.Dirt,
		self._deltaTime
	)
end

function Update(self: ClientTire, deltaTime: number)
	local stress = 0
	local count = 0

	local rotSpeed = math.abs(self.Wheel.Instance.AssemblyAngularVelocity:Dot(self.SmokePart.CFrame.RightVector))
	local lateralDiff = math.abs(self.Wheel.Instance.AssemblyLinearVelocity:Dot(self.Wheel.Instance.CFrame.RightVector))
		/ self.Wheel.Instance.AssemblyLinearVelocity.Magnitude
	local rotLinearSpeed = rotSpeed * (self.Wheel.Instance.Size.Y / 2)
	local speed = self.Vehicle.Velocity.Magnitude
	local diff = math.abs(rotLinearSpeed - speed)

	local ray = nil -- Assuming they are the same material
	local materialType = ""
	local materialChanged = false

	local innerRay = game.Workspace:Raycast(
		self.Wheel.Instance.Position,
		(
			((self.Wheel.Instance.Arm :: any).CFrame * CFrame.new(
				-self.Wheel.Instance.Size.X / 2,
				-self.Wheel.Instance.Size.Y / 2,
				0
			)).Position - self.Wheel.Instance.Position
		) * 1.1,
		self.RayParams
	)
	local outerRay = game.Workspace:Raycast(
		self.Wheel.Instance.Position,
		(
			((self.Wheel.Instance.Arm :: any).CFrame * CFrame.new(
				self.Wheel.Instance.Size.X / 2,
				-self.Wheel.Instance.Size.Y / 2,
				0
			)).Position - self.Wheel.Instance.Position
		) * 1.1,
		self.RayParams
	)
	ray = innerRay or outerRay
	if ray then
		for k, v in MaterialGroups do
			if table.find(v, ray.Material.Name) then
				materialType = k
				break
			end
		end
		self.Ray = ray
		if self.Material ~= materialType then materialChanged = true end
		self.Material = materialType
	end

	--Slip
	local vstress = (
		math.max(ray and diff / 20 or 0, ray and materialType ~= "road" and materialType ~= "" and rotSpeed / 50 or 0)
		+ (self.Wheel.IsFront and self.Vehicle.Tune.TireFSpeedStress or self.Vehicle.Tune.TireRSpeedStress)
			* (rotLinearSpeed / (Units.Velocity_mdivs / 3.6) / 100)
	)
	if ray and materialType ~= "road" and materialType ~= "" then
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
	if materialType ~= "road" and materialType ~= "" then
		self.Dirt = Lerp(self.Dirt, 1, rotSpeed * 0.003 * deltaTime)
		self.Vehicle.Dirt += math.min(rotSpeed * 0.0002 * deltaTime, 1)
	else
		self.Dirt = Lerp(self.Dirt, 0, rotSpeed * 0.0001 * deltaTime)
	end

	-- Apply friction
	local materialHeatFactor = materialType ~= "road" and 0.01 or 1
	local currentPhysicalProperties = self.Wheel.Instance.CurrentPhysicalProperties
	local coldLoss = 0
	local heatLoss = 0
	local globalTemperature = game.Workspace:GetAttribute("GlobalTemperature") :: number
	if self.Wheel.IsFront then
		self.Temperature = math.clamp(
			self.Temperature
				+ (
						self.Stress
							* (self.Vehicle.Tune.TireFHeating + self.Vehicle.Tune.TireFCooling)
							* materialHeatFactor
						- self.Vehicle.Tune.TireFCooling
					)
					* (60 / (1 / deltaTime)),
			globalTemperature,
			self.Vehicle.Tune.TireFMaxTemp
		)
	else
		self.Temperature = math.clamp(
			self.Temperature
				+ (
						self.Stress
							* (self.Vehicle.Tune.TireRHeating + self.Vehicle.Tune.TireRCooling)
							* materialHeatFactor
						- self.Vehicle.Tune.TireRCooling
					)
					* (60 / (1 / deltaTime)),
			globalTemperature,
			self.Vehicle.Tune.TireRMaxTemp
		)
	end
	coldLoss = self.Wheel.IsFront
			and (self.Vehicle.Tune.TireFColdStats[1] * (1 / (math.exp(
				self.Vehicle.Tune.TireFColdStats[2] * (self.Temperature / 100 - self.Vehicle.Tune.TireFColdStats[3])
			) + 1)))
		or (
			self.Vehicle.Tune.TireRColdStats[1]
			* (
				1
				/ (
					math.exp(
						self.Vehicle.Tune.TireRColdStats[2]
							* (self.Temperature / 100 - self.Vehicle.Tune.TireRColdStats[3])
					) + 1
				)
			)
		)
	heatLoss = self.Wheel.IsFront
			and (self.Vehicle.Tune.TireFHotStats[1] * (-(1 / (math.exp(
				self.Vehicle.Tune.TireFHotStats[2] * (self.Temperature / 100 - self.Vehicle.Tune.TireFHotStats[3])
			) + 1)) + 1))
		or (
			self.Vehicle.Tune.TireRHotStats[1]
			* (
				-(
					1
					/ (
						math.exp(
							self.Vehicle.Tune.TireRHotStats[2]
								* (self.Temperature / 100 - self.Vehicle.Tune.TireRHotStats[3])
						) + 1
					)
				) + 1
			)
		)
	local density = math.round(
		(
			((self.Vehicle.Tune.FWheelWeight - self.Vehicle.Tune.TireFWeight) * Units.Mass_kg)
			/ (math.pi * (self.Wheel.Instance.Size.Y / 2) ^ 2 * self.Wheel.Instance.Size.X)
		) * 1000
	) / 1000
	local friction = math.round(
		math.clamp(
			self.Vehicle.Tune.TireFMaxFriction - coldLoss - heatLoss - self.Dirt * self.Vehicle.Tune.TireFDirtLoss,
			0,
			2
		) * 1000
	) / 1000
	if not self.Wheel.IsFront then
		density = math.round(
			(
				((self.Vehicle.Tune.RWheelWeight - self.Vehicle.Tune.TireRWeight) * Units.Mass_kg)
				/ (math.pi * (self.Wheel.Instance.Size.Y / 2) ^ 2 * self.Wheel.Instance.Size.X)
			) * 1000
		) / 1000
		friction = math.round(
			math.clamp(
				self.Vehicle.Tune.TireRMaxFriction - coldLoss - heatLoss - self.Dirt * self.Vehicle.Tune.TireRDirtLoss,
				0,
				2
			) * 1000
		) / 1000
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
	if ray and materialType == "sand" then
		self.Wheel.Instance:ApplyImpulseAtPosition(
			-self.Wheel.Instance.AssemblyLinearVelocity * self.Vehicle.Tune.TireSandForce * deltaTime,
			self.Wheel.Instance.Position
		)
	end

	-- Update haptic values
	stress += self.Stress
	count += 1

	-- Tire flex
	local flexDensity = math.round(
		(
			((self.Wheel.IsFront and self.Vehicle.Tune.TireFWeight or self.Vehicle.Tune.TireRWeight) * Units.Mass_kg)
			/ (math.pi * (self.Wheel.Instance.Size.Y / 2) ^ 2 * self.Wheel.Instance.Size.X)
		) * 1000
	) / 1000
	local flexCurrentPhysicalProperties = self.FlexCollision.CurrentPhysicalProperties
	if
		math.round(flexCurrentPhysicalProperties.Density * 1000) / 1000 ~= flexDensity
		or currentPhysicalProperties.Friction ~= flexCurrentPhysicalProperties.Friction
		or currentPhysicalProperties.Elasticity ~= flexCurrentPhysicalProperties.Elasticity
		or currentPhysicalProperties.FrictionWeight ~= flexCurrentPhysicalProperties.FrictionWeight
		or currentPhysicalProperties.ElasticityWeight ~= flexCurrentPhysicalProperties.ElasticityWeight
	then
		self.FlexCollision.CustomPhysicalProperties = PhysicalProperties.new(
			flexDensity,
			currentPhysicalProperties.Friction,
			currentPhysicalProperties.Elasticity,
			currentPhysicalProperties.FrictionWeight,
			currentPhysicalProperties.ElasticityWeight
		)
	end
	if self.FlexCollisionGravComp then
		self.FlexCollisionGravComp.Force = Vector3.new(
			0,
			self.Vehicle.Tune.GravComp > 0
					and self.FlexCollision.Mass * (game.Workspace.Gravity - self.Vehicle.Tune.GravComp)
				or 0,
			0
		)
	end
	if self.ObjectGravComp then
		self.ObjectGravComp.Force = Vector3.new(
			0,
			self.Vehicle.Tune.GravComp > 0
					and self.Wheel.Instance.Mass * (game.Workspace.Gravity - self.Vehicle.Tune.GravComp)
				or 0,
			0
		)
	end

	-- Smoke
	if self.Vehicle.Tune.TireSmokeEffects == "Local" or self.Vehicle.Tune.TireSmokeEffects == "All" then
		-- Set sounds and smoke
		local currentSound = self.CurrentSound
		local currentSmoke = self.CurrentSmoke
		local currentWheelSmoke = self.CurrentWheelSmoke
		if materialChanged then
			if currentSound then currentSound.Playing = false end
			if currentSmoke then currentSmoke.Enabled = false end
			currentSound = self.Sounds[materialType]
			currentSmoke = self.Smokes[materialType]
			currentWheelSmoke = self.WheelSmokes[materialType]
			self.CurrentSound = currentSound
			self.CurrentSmoke = currentSmoke
			self.CurrentWheelSmoke = currentWheelSmoke
		end

		-- Set Trails
		local smokeStress = math.clamp(self.Stress - self.Vehicle.Tune.TireSmokeStressOffset / 100, 0, 1)
		local trailStress = math.floor(smokeStress ^ 3 * self.Vehicle.Tune.TireMarkTransparencyLevels)
		if self.Trails[materialType] then
			for i = 1, (trailStress > self.TrailStress and trailStress or self.TrailStress) do
				self.Trails[materialType][i].Enabled = trailStress >= i
			end
		end
		if materialChanged and self.CurrentTrail then
			for i = 1, self.Vehicle.Tune.TireMarkTransparencyLevels do
				self.CurrentTrail[i].Enabled = false
			end
		end
		self.CurrentTrail = self.Trails[materialType]
		self.TrailStress = trailStress

		-- Run effects
		if currentSound then
			-- Sound
			if not currentSound.Playing then
				currentSound.TimePosition = Random.new():NextNumber() * currentSound.TimeLength --avoid overlapping sounds
			end
			currentSound.Playing = true
			currentSound.Volume = smokeStress ^ 3 * 1.4
			currentSound.PlaybackSpeed = 1.6 - 0.5 * smokeStress
			local tremolo = currentSound:GetAttribute("HasTremolo") and currentSound.TremoloSoundEffect
			if tremolo then tremolo.Depth = lateralDiff end
		end
		if currentSmoke then
			-- Smoke
			currentSmoke.Enabled = true
			currentSmoke.Rate = smokeStress ^ 10 * 100
		end
		if currentWheelSmoke then
			-- Wheel smoke
			currentWheelSmoke.Enabled = true
			currentWheelSmoke.Rate = smokeStress ^ 10 * 200
		end
		local compression = 1
		if self.Collision then
			compression = math.clamp((self.Wheel.Instance.Position - self.Collision.Position).Magnitude / 0.1, 0, 1)
		end
		local trailAttachmentPart = self.TrailAttachmentPart
		if trailAttachmentPart and smokeStress > 0.05 and self.Wheel.Instance.AssemblyLinearVelocity.Magnitude > 10 then
			trailAttachmentPart.TrailAttachment0.Position =
				Vector3.new(self.Wheel.Instance.Size.X / 2 - 0.2 + 0.1 * compression, 0.02, 0)
			trailAttachmentPart.TrailAttachment1.Position =
				Vector3.new(-self.Wheel.Instance.Size.X / 2 + 0.2 - 0.1 * compression, 0.02, 0)
			trailAttachmentPart.AlignOrientation.CFrame = CFrame.lookAt(
				self.SmokePart.Position,
				(self.SmokePart.CFrame * CFrame.new(
					0,
					0,
					-5 + math.min(self.Wheel.Instance.AssemblyLinearVelocity.Magnitude, 5)
				)).Position + self.Wheel.Instance.AssemblyLinearVelocity,
				ray and ray.Normal or self.SmokePart.CFrame.UpVector
			)
		end
	end

	-- Haptics
	if
		isVibrationSupported
		and (
			(
				self.Vehicle.Tune.Haptics == "Controller"
				or self.Vehicle.Tune.Haptics == "Both"
					and string.find(UserInputService:GetLastInputType().Name, "Gamepad")
			)
			or (
				self.Vehicle.Tune.Haptics == "Mobile"
				or self.Vehicle.Tune.Haptics == "Both"
					and UserInputService:GetLastInputType() == Enum.UserInputType.Touch
			)
		)
	then
		stress /= count
		stress = math.clamp(stress / 2, 0, 0.5)
		HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, stress)
	end
end

--TODO: Destroy function
function ClientTire.Destroy(self: ClientTire) end

return ClientTire
