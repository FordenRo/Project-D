local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseVehicle = require(ReplicatedStorage.Shared.Classes.BaseVehicle)
local DeformationHandler = require(script.DeformationHandler)
local EngineTable =
	require(ReplicatedStorage.Shared.Classes.ClientVehicle.EngineTable)
local InteriorHandler = require(script.InteriorHandler)
local Lights = require(script.Lights)
local MakeUtil = require(ReplicatedStorage.Shared.Utils.MakeUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleConstants =
	require(ReplicatedStorage.Shared.Vehicle.VehicleConstants)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)
local Wheel = require(script.Wheel)

local ServerVehicle = setmetatable({}, BaseVehicle)
ServerVehicle.__index = ServerVehicle

type ServerVehicle = VehicleTypes.ServerVehicle

function ServerVehicle.new(instance: Instance): ServerVehicle
	local self: ServerVehicle =
		setmetatable(BaseVehicle.new(instance), ServerVehicle) :: any

	Initialize(self)

	local trove = Trove.new()
	trove:AttachToInstance(instance)

	self.Engine = table.clone(EngineTable)
	DeformationHandler.new(self)
	Lights.new(self)
	InteriorHandler.new(self)

	trove:Connect(
		self._Remote.OnServerEvent,
		function(sender: Player, buf: buffer)
			self:_Replicate(buf)

			for _, player in Players:GetPlayers() do
				if player == sender then continue end

				self._Remote:FireClient(player, buf)
			end
		end
	)

	return self
end

function Initialize(self: ServerVehicle)
	RemoveMassAndForces(self)
	MakeCollider(self)
	self:InitializeWheels()
	InitializeBody(self)
	ApplyWeight(self)
	MakeGravity(self)
	CreateFlip(self)
	Finalize(self)
	InitializeSeats(self)
end

function RemoveMassAndForces(self: ServerVehicle)
	for _, v in self.Instance:GetDescendants() do
		if v:IsA("BasePart") then
			v.Massless = true
			v.EnableFluidForces = false
		end
	end
end

function MakeGravity(self: ServerVehicle)
	for _, v in self.Instance:GetDescendants() do
		if not v:IsA("BasePart") or v.Massless then continue end

		local attachment = v:FindFirstChild("#GRAVCOMP_ATTACH")
			or Instance.new("Attachment")
		attachment.Name = "#GRAVCOMP_ATTACH"
		attachment.Parent = v

		local force = v:FindFirstChild("#GRAVCOMP")
			or Instance.new("VectorForce")
		force.Name = "#GRAVCOMP"
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.Attachment0 = attachment
		force.Force = Vector3.new(
			0,
			VehicleConstants.GravComp > 0
					and v.Mass * (workspace.Gravity - VehicleConstants.GravComp)
				or 0,
			0
		)
		force.Parent = v
	end
end

function InitializeBody(self: ServerVehicle)
	local index = 0
	for _, v in self.Instance.Body:GetDescendants() do
		if not v:IsA("MeshPart") or not v:HasTag("Deformable") then continue end

		index += 1
		v.Name = string.format("%s.%03d", v.Name, index)
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

function ServerVehicle.InitializeWheels(self: ServerVehicle)
	BaseVehicle.InitializeWheels(self, Wheel)
end

function ApplyWeight(self: ServerVehicle)
	local mass = 0

	for _, v in self.Instance:GetDescendants() do
		if v:IsA("BasePart") and not v.Massless then mass = mass + v.Mass end
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
		weightPart.AudioCanCollide = false
		weightPart.BrickColor = BrickColor.new("Really black")
		weightPart.TopSurface = Enum.SurfaceType.Smooth
		weightPart.BottomSurface = Enum.SurfaceType.Smooth
		if VehicleConstants.WBVisible then
			weightPart.Transparency = 0.75
		else
			weightPart.Transparency = 1
		end

		weightPart.Size = self.Tune.WeightPartSize / Units.Length_mm
		local tdensity = (self.Tune.Weight * Units.Mass_kg - mass)
			/ (weightPart.Size.X * weightPart.Size.Y * weightPart.Size.Z) --fixed by denkodin
		weightPart.CustomPhysicalProperties =
			PhysicalProperties.new(math.clamp(tdensity, 0.01, 100), 0, 0, 0, 0)
		--Real life mass in pounds, converted to kg minus existing roblox mass converted to kg, divided by volume of the weight brick in cubic meters, divided by the density of water
		weightPart.CFrame = (
			self.Instance.DriveSeat.CFrame
			- self.Instance.DriveSeat.Position
			+ center
		) * CFrame.new(0, self.Tune.CGHeight, 0)
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
	if VehicleConstants.FlipType == "New" then
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
	elseif VehicleConstants.FlipType == "Old" then
		flipG = Instance.new("BodyGyro")
		flipG.Name = "Flip"
		flipG.D = 0
		flipG.MaxTorque = Vector3.new(0, 0, 0)
		flipG.P = 0
		flipG.Parent = self.Instance.DriveSeat
	end
end

function Finalize(self: ServerVehicle)
	MakeUtil.ModelWeld(self.Instance.Body, self.Instance.DriveSeat)
	MakeUtil.ModelWeld(self.Instance.Seats, self.Instance.DriveSeat)

	-- Unanchor
	for _, v in self.Instance:GetDescendants() do
		if v:IsA("BasePart") then v.Anchored = false end
	end
end

function Seated(self: ServerVehicle, player: Player, seat: VehicleSeat | Seat)
	if seat :: any == self.Instance.DriveSeat then
		self.Driver = player
		self.Instance.DriveSeat:SetNetworkOwner(player)
	else
		self.Passengers[seat] = player
	end
end

function Leaved(self: ServerVehicle, seat: VehicleSeat | Seat)
	if seat :: any == self.Instance.DriveSeat then
		self.Driver = nil

		-- Remove Flip Force
		if self.Instance.DriveSeat:FindFirstChild("Flip") then
			if VehicleConstants.FlipType == "New" then
				self.Instance.DriveSeat.Flip.Enabled = false
			else
				self.Instance.DriveSeat.Flip.MaxTorque = 0
			end
		end

		for _, wheel in self.Wheels do
			-- Apply handbrake
			if self.Tune.ExitBrake then
				if wheel.IsFront then
					wheel.Instance.BV.MotorMaxTorque = (
						self.Tune.PBrakeForce
						* 9.80665
						* Units.Force_N
					) * self.Tune.PBrakeBias
				else
					wheel.Instance.BV.MotorMaxTorque = (
						self.Tune.PBrakeForce
						* 9.80665
						* Units.Force_N
					) * (1 - self.Tune.PBrakeBias)
				end
			end

			-- Remove wheel force
			wheel.Instance.AV.MotorMaxTorque = 0
			wheel.Instance.AV.AngularVelocity = 0

			-- Readjust steering
			if wheel.Instance.Arm:FindFirstChild("Steer") then
				if self.Tune.PowerSteeringType == "New" then
					wheel.Instance.Arm.Steer.Attachment0.Orientation =
						Vector3.new(
							0,
							-wheel.Instance.Base.Rotate.CurrentAngle,
							0
						)
				else
					wheel.Instance.Arm.Steer.CFrame = wheel.Instance.Base.CFrame
						* CFrame.Angles(
							0,
							math.rad(wheel.Instance.Base.Rotate.CurrentAngle),
							0
						)
				end
			end
		end
	else
		self.Passengers[seat] = nil
	end
end

function InitializeSeats(self: ServerVehicle)
	local seats = self.Instance.Seats:GetChildren()
	table.insert(seats, self.Instance.DriveSeat)

	for _, seat in seats do
		if not seat:IsA("VehicleSeat") and not seat:IsA("Seat") then
			continue
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Vehicle"
		prompt.ActionText = "Enter"
		prompt.KeyboardKeyCode = Enum.KeyCode.F
		prompt.MaxActivationDistance = 6
		prompt.RequiresLineOfSight = false
		prompt.Parent = seat.PromptAttachment

		prompt.Triggered:Connect(function(player: Player)
			if seat.Occupant then return end

			local character = player.Character
			if not character then return end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			seat:Sit(humanoid)
		end)

		local RE = Instance.new("RemoteEvent")
		RE.Name = "_SeatRE"
		RE.Parent = seat

		RE.OnServerEvent:Connect(function(player: Player)
			if not player.Character then return end
			local humanoid =
				player.Character:FindFirstChildOfClass("Humanoid") :: Humanoid

			local seatWeld =
				humanoid.SeatPart:FindFirstChild("SeatWeld") :: Weld
			seatWeld:Destroy()

			player.Character:PivotTo(
				CFrame.new(
					((seat :: any).LeavePosition :: Attachment).WorldPosition
				)
			)
			RE:FireClient(player)
		end)

		local masslessTable = {}
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			prompt.Enabled = seat.Occupant == nil

			if seat.Occupant then
				local character = seat.Occupant.Parent
				if not character then return end

				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end

				Seated(self, player, seat)

				for _, v in character:GetDescendants() do
					if not v:IsA("BasePart") then continue end

					masslessTable[v] = v.Massless
					v.Massless = true
				end
			else
				Leaved(self, seat)

				for k, v in masslessTable do
					k.Massless = v
				end
				table.clear(masslessTable)
			end
		end)
	end
end

return table.freeze({ new = ServerVehicle.new })
