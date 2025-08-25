local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseVehicle = require(ReplicatedStorage.Shared.Classes.BaseVehicle)
local EngineTable = require(ReplicatedStorage.Shared.Classes.ClientVehicle.EngineTable)
local FlagsUtils = require(ReplicatedStorage.Shared.Utils.FlagsUtils)
local Lights = require(script.Lights)
local ModelWeld = require(ReplicatedStorage.Shared.Utils.ModelWeld)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehiclePacket = require(ReplicatedStorage.Shared.Packets.VehiclePacket)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)
local Wheel = require(script.Wheel)

local ServerVehicle = setmetatable({}, BaseVehicle)
ServerVehicle.__index = ServerVehicle

type ServerVehicle = VehicleTypes.ServerVehicle

function ServerVehicle.new(instance: Instance)
	local self: ServerVehicle = setmetatable(BaseVehicle.new(instance), ServerVehicle) :: any

	Initialize(self)

	self.Engine = table.clone(EngineTable)
	Lights.new(self)

	self._Remote.OnServerEvent:Connect(function(_, data: buffer)
		for k, v in Serialization.Deserialize(VehiclePacket, data) do
			if k == "Flags" then
				self.IsOn, self.Starting, self.Shifting, self.Horning = FlagsUtils.FlagsToBools(v)
			else
				self[k] = v
			end
		end

		local x = self.RPM / 1000
		self.Engine.Boost = self.Engine.BoostTurbo + self.Engine.BoostSuper

		self.Engine.TqTurbo = self.Engine.BoostTurbo * self.Tune.T_Efficiency
		self.Engine.TqSuper = self.Engine.BoostSuper * self.Tune.S_Efficiency
		self.Engine.TqBoosted = self.Engine.TqTurbo + self.Engine.TqSuper
		self.Engine.Torque = self.Engine.TqNatural + self.Engine.TqElectric + self.Engine.TqBoosted

		self.Engine.HpNatural = self.Engine.TqNatural * x / 5.252
		self.Engine.HpTurbo = self.Engine.TqTurbo * x / 5.252
		self.Engine.HpSuper = self.Engine.TqSuper * x / 5.252
		self.Engine.HpBoosted = self.Engine.HpTurbo + self.Engine.HpSuper
		self.Engine.Horsepower = self.Engine.Torque * x / 5.252
	end)

	return self
end

function Initialize(self: ServerVehicle)
	RemoveMass(self)
	MakeCollider(self)
	self:InitializeWheels()
	ApplyWeight(self)
	MakeGravity(self)
	CreateFlip(self)
	Finalize(self)
	InitializePlugins(self)
	InitializeSeats(self)
	InitializeDriveSeat(self)
end

function RemoveMass(self: ServerVehicle)
	for _, v in self.Instance:GetDescendants() do
		if v:IsA("BasePart") then v.Massless = true end
	end
end

function MakeGravity(self: ServerVehicle)
	for _, v in self.Instance:GetDescendants() do
		if not v:IsA("BasePart") then continue end

		local attachment = v:FindFirstChild("#GRAVCOMP_ATTACH") or Instance.new("Attachment")
		attachment.Name = "#GRAVCOMP_ATTACH"
		attachment.Parent = v
		local force = v:FindFirstChild("#GRAVCOMP") or Instance.new("VectorForce")
		force.Name = "#GRAVCOMP"
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.Attachment0 = attachment
		force.Force =
			Vector3.new(0, self.Tune.GravComp > 0 and v.Mass * (workspace.Gravity - self.Tune.GravComp) or 0, 0)
		force.Parent = v
		if v.Massless then
			force:Destroy()
			attachment:Destroy()
		end
	end
end

function MakeCollider(self: ServerVehicle)
	for _, wheel in self.Instance.Wheels:GetChildren() do
		if not wheel:IsA("BasePart") then continue end

		local constraint = Instance.new("NoCollisionConstraint")
		constraint.Part0 = self.Instance.Body.Collider
		constraint.Part1 = wheel
		constraint.Parent = wheel
	end
end

function ServerVehicle.InitializeWheels(self: ServerVehicle) BaseVehicle.InitializeWheels(self, Wheel) end

function ApplyWeight(self: ServerVehicle)
	local mass = 0

	for _, v in self.Instance:GetDescendants() do
		if v:IsA("BasePart") and not v.Massless then mass = mass + v:GetMass() end
	end

	if mass * Units.Mass_kg < self.Tune.Weight * 0.453592 then
		-- Calculate Weight Distribution
		-- TODO: Like a GetCenter function???
		local centerF = Vector3.new()
		local centerR = Vector3.new()
		local countF = 0
		local countR = 0

		for _, v in self.Instance.Wheels:GetChildren() do
			if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
				centerF = centerF + v.CFrame.Position
				countF = countF + 1
			else
				centerR = centerR + v.CFrame.Position
				countR = countR + 1
			end
		end
		centerF = centerF / countF
		centerR = centerR / countR
		local center = centerR:Lerp(centerF, self.Tune.WeightDist / 100)

		--Create Weight Part
		local weightPart = Instance.new("Part")
		weightPart.Name = "WeightPart"
		weightPart.Anchored = true
		weightPart.CanCollide = false
		weightPart.BrickColor = BrickColor.new("Really black")
		weightPart.TopSurface = Enum.SurfaceType.Smooth
		weightPart.BottomSurface = Enum.SurfaceType.Smooth
		if self.Tune.WBVisible then
			weightPart.Transparency = 0.75
		else
			weightPart.Transparency = 1
		end

		weightPart.Size = self.Tune.WeightPartSize / Units.Length_mm
		local tdensity = (self.Tune.Weight * Units.Mass_kg - mass)
			/ (weightPart.Size.X * weightPart.Size.Y * weightPart.Size.Z) --fixed by denkodin
		weightPart.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(tdensity, 0.01, 100), 0, 0, 0, 0)
		--Real life mass in pounds, converted to kg minus existing roblox mass converted to kg, divided by volume of the weight brick in cubic meters, divided by the density of water
		weightPart.CFrame = (self.Instance.DriveSeat.CFrame - self.Instance.DriveSeat.Position + center)
			* CFrame.new(0, self.Tune.CGHeight, 0)
		weightPart.Parent = self.Instance.Body

		--Density Cap
		if weightPart.CustomPhysicalProperties.Density >= 100 then
			warn(
				"\n\t [VEHICLE]: Density too high for specified volume."
					.. "\n\t Current Density:\t"
					.. math.ceil(tdensity)
					.. "\n\t Max Density:\t"
					.. math.ceil(weightPart.CustomPhysicalProperties.Density)
					.. "\n\t Increase weight brick size to compensate."
			)
		end

		self.WeightPart = weightPart
	else
		--Existing Weight Is Too Massive
		warn(
			"\n\t [VEHICLE]: Mass too high for specified weight."
				.. "\n\t    Target Mass:\t"
				.. math.ceil(self.Tune.Weight * Units.Mass_kg)
				.. "\n\t    Current Mass:\t"
				.. math.ceil(mass)
				.. "\n\t Reduce part size or axle density to achieve desired weight."
		)
	end
end

function CreateFlip(self: ServerVehicle)
	local flipG
	if self.Tune.FlipType == "New" then
		local flipAttach = Instance.new("Attachment")
		flipAttach.Axis = Vector3.new(0, 1, 0)
		flipAttach.Parent = self.Instance.DriveSeat

		flipG = Instance.new("AlignOrientation")
		flipG.Name = "Flip"
		flipG.Attachment0 = flipAttach
		flipG.AlignType = Enum.AlignType.PrimaryAxisParallel
		flipG.RigidityEnabled = true
		flipG.Enabled = false
		flipG.Mode = Enum.OrientationAlignmentMode.OneAttachment
		flipG.PrimaryAxis = Vector3.new(0, 1, 0)
		flipG.Parent = self.Instance.DriveSeat
	elseif self.Tune.FlipType == "Old" then
		flipG = Instance.new("BodyGyro")
		flipG.Name = "Flip"
		flipG.D = 0
		flipG.MaxTorque = Vector3.new(0, 0, 0)
		flipG.P = 0
		flipG.Parent = self.Instance.DriveSeat
	end
end

function Finalize(self: ServerVehicle)
	ModelWeld(self.Instance.Body, self.Instance.DriveSeat)
	ModelWeld(self.Instance.Seats, self.Instance.DriveSeat)

	-- Unanchor
	for _, v in self.Instance:GetDescendants() do
		if v:IsA("BasePart") then v.Anchored = false end
	end
end

function InitializePlugins(self: ServerVehicle)
	for _, plugin in ReplicatedStorage.Shared.Vehicle.Plugins:GetChildren() do
		local pluginClass = require(plugin) :: any
		if pluginClass and pluginClass.new then self.Plugins[plugin.Name] = pluginClass.new(self) end
	end
end

function InitializeSeats(self: ServerVehicle)
	for _, seat in self.Instance.Seats:GetChildren() do
		if not seat:IsA("VehicleSeat") then continue end

		InitializeSeat(self, seat)

		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant then
				local character = seat.Occupant.Parent
				if not character then return end

				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end

				self.Passengers[seat] = player
			else
				self.Passengers[seat] = nil
			end
		end)
	end
end

function InitializeSeat(self: ServerVehicle, seat: VehicleSeat)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Vehicle"
	prompt.ActionText = "Enter"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat

	prompt.Triggered:Connect(function(player: Player)
		if seat.Occupant then return end

		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		seat:Sit(humanoid)
	end)

	local masslessTable = {}
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		prompt.Enabled = seat.Occupant ~= nil

		if seat.Occupant then
			local character = seat.Occupant.Parent
			if not character then return end

			for _, v in character:GetDescendants() do
				if not v:IsA("BasePart") then continue end

				masslessTable[v] = v.Massless
				v.Massless = true
			end
			return
		end

		for k, v in masslessTable do
			k.Massless = v
		end
		table.clear(masslessTable)
	end)
end

function InitializeDriveSeat(self: ServerVehicle)
	InitializeSeat(self, self.Instance.DriveSeat)

	self.Instance.DriveSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if self.Instance.DriveSeat.Occupant then
			local player = Players:GetPlayerFromCharacter(self.Instance.DriveSeat.Occupant)
			if not player then return end

			self.Instance.DriveSeat:SetNetworkOwner(player)
			self.Driver = player
			return
		end

		self.Driver = nil

		-- Remove Flip Force
		if self.Instance.DriveSeat:FindFirstChild("Flip") then
			if self.Tune.FlipType == "New" then
				self.Instance.DriveSeat.Flip.Enabled = false
			else
				self.Instance.DriveSeat.Flip.MaxTorque = 0
			end
		end

		for _, wheel in self.Wheels do
			-- Apply handbrake
			if self.Tune.ExitBrake then
				if wheel.IsFront then
					wheel.Instance.BV.MotorMaxTorque = (self.Tune.PBrakeForce * 9.80665 * Units.Force_N)
						* self.Tune.PBrakeBias
				else
					wheel.Instance.BV.MotorMaxTorque = (self.Tune.PBrakeForce * 9.80665 * Units.Force_N)
						* (1 - self.Tune.PBrakeBias)
				end
			end

			-- Remove wheel force
			wheel.Instance.AV.MotorMaxTorque = 0
			wheel.Instance.AV.AngularVelocity = 0

			-- Readjust steering
			if wheel.Instance.Arm:FindFirstChild("Steer") then
				if self.Tune.PowerSteeringType == "New" then
					wheel.Instance.Arm.Steer.Attachment0.Orientation =
						Vector3.new(0, -wheel.Instance.Base.Rotate.CurrentAngle, 0)
				else
					wheel.Instance.Arm.Steer.CFrame = wheel.Instance.Base.CFrame
						* CFrame.Angles(0, math.rad(wheel.Instance.Base.Rotate.CurrentAngle), 0)
				end
			end
		end
	end)
end

-- TODO: Driver mental breakdown bruh

return ServerVehicle
