local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- local DeformationHandler = require(script.DeformationHandler)
local Component = require(ReplicatedStorage.Shared.Classes.Component)
local EngineTable =
	require(ReplicatedStorage.Shared.Classes.ClientVehicle.EngineTable)
local Enums = require(ReplicatedStorage.Shared.Enums)
local InteriorHandler = require(script.InteriorHandler)
local MakeUtil = require(ReplicatedStorage.Shared.Utils.MakeUtil)
local RComponent = require(ReplicatedStorage.Shared.Classes.RComponent)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleConstants =
	require(ReplicatedStorage.Shared.Vehicle.VehicleConstants)
local VehiclePackets = require(ReplicatedStorage.Shared.Packets.VehiclePackets)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)
local VehicleUtil = require(ReplicatedStorage.Shared.Utils.VehicleUtil)

local ServerVehicle = { get = {}, set = {} }
ServerVehicle.__extends = RComponent.Instanced.Server

type ServerVehicle = VehicleTypes.ServerVehicle

function ServerVehicle.new(instance: Instance, owner: Player): ServerVehicle
	local self: ServerVehicle = Component(
		ServerVehicle,
		RComponent.Instanced.Server.new(instance)
	) :: any

	self.Owner = owner

	VehicleUtil.Setup(self, instance)
	Initialize(self)

	local trove = Trove.new()
	trove:AttachToInstance(instance)

	self.Engine = table.clone(EngineTable)
	-- DeformationHandler.new(self)
	InteriorHandler.new(self)

	trove:Connect(self.URE.OnServerEvent, function(sender: Player, buf: buffer)
		VehicleUtil.Replicate(self, buf)

		for _, player in Players:GetPlayers() do
			if player == sender then continue end

			self.URE:FireClient(player, buf)
		end
	end)

	self.RF.OnServerInvoke = function(player, action: number, ...)
		local callbacks = {
			[Enums.VehicleAction.InvokeInitPacket] = function()
				return (Serialization.Serialize(VehiclePackets.Init, self))
			end,
		}
		return callbacks[action](...)
	end

	task.delay(1, function() InitializeSeats(self) end)

	return self
end

function Initialize(self: ServerVehicle)
	RemoveMassAndForces(self)
	MakeCollider(self)
	VehicleUtil.InitializeWheels(self)
	InitializeBody(self)
	ApplyWeight(self)
	MakeGravity(self)
	CreateFlip(self)
	Finalize(self)
	InitializeControllersReplication(self)
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

		local attachment = v:FindFirstChild("#GRAVCOMP_ATTACH") :: Attachment
			or Instance.new("Attachment")
		attachment.Name = "#GRAVCOMP_ATTACH"
		attachment.Parent = v

		local force = v:FindFirstChild("#GRAVCOMP") :: VectorForce
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

function InitializeControllersReplication(self: ServerVehicle)
	local RE = Instance.new("RemoteEvent")
	RE.Name = "_ControllersRE"
	RE.Parent = self.Instance

	local URE = Instance.new("UnreliableRemoteEvent")
	URE.Name = "_ControllersURE"
	URE.Parent = self.Instance

	local function Replicate(sender: Player, ...)
		for _, player in Players:GetPlayers() do
			if player == sender then continue end

			RE:FireClient(player, ...)
		end
	end

	RE.OnServerEvent:Connect(Replicate)
	URE.OnServerEvent:Connect(Replicate)
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

		for _, v in self.Wheels do
			if v.IsFront then
				centerF = centerF + v.Instance.CFrame.Position
				countF = countF + 1
			else
				centerR = centerR + v.Instance.CFrame.Position
				countR = countR + 1
			end
		end
		centerF = centerF / countF
		centerR = centerR / countR
		local center = centerR:Lerp(centerF, self.Tune.WeightDist / 100)

		-- Create Weight Part
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
			/ (weightPart.Size.X * weightPart.Size.Y * weightPart.Size.Z) -- fixed by denkodin
		-- Real life mass in pounds, converted to kg minus existing roblox mass converted to kg,
		-- divided by volume of the weight brick in cubic meters, divided by the density of water
		weightPart.CustomPhysicalProperties =
			PhysicalProperties.new(math.clamp(tdensity, 0.01, 100), 0, 0, 0, 0)
		weightPart.CFrame = (
			self.Instance.DriveSeat.CFrame
			- self.Instance.DriveSeat.Position
			+ center
		) * CFrame.new(0, self.Tune.CGHeight, 0)
		weightPart.Parent = self.Instance.Body

		-- Density Cap
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
		-- Existing Weight Is Too Massive
		warn(
			"\n\t [VEHICLE]: Mass too high for specified weight."
				.. "\n\t Target Mass:\t"
				.. math.ceil(self.Tune.Weight * Units.Mass_kg)
				.. "\n\t Current Mass:\t"
				.. math.ceil(mass)
				.. "\n\t Reduce part size or axle density to achieve desired weight."
		)
	end
end

function CreateFlip(self: ServerVehicle)
	local flip = Instance.new("AlignOrientation")
	flip.Name = "Flip"
	flip.AlignType = Enum.AlignType.PrimaryAxisParallel
	flip.RigidityEnabled = true
	flip.Enabled = false
	flip.Mode = Enum.OrientationAlignmentMode.OneAttachment
	flip.PrimaryAxis = Vector3.new(0, 1, 0)

	local attach = Instance.new("Attachment")
	attach.Axis = Vector3.new(0, 1, 0)
	attach.Parent = self.Instance.DriveSeat
	flip.Attachment0 = attach

	flip.Parent = self.Instance.DriveSeat
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
			self.Instance.DriveSeat.Flip.Enabled = false
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
				if
					typeof(wheel.Instance.Arm.Steer) == "AlignOrientation"
					and self.Tune.PowerSteeringType == "New"
				then
					(wheel.Instance.Arm.Steer.Attachment0 :: Attachment).Orientation =
						Vector3.new(
							0,
							-wheel.Instance.Base.Rotate.CurrentAngle,
							0
						)
				elseif typeof(wheel.Instance.Arm.Steer) == "BodyGyro" then
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
		prompt.ActionText = seat:IsA("VehicleSeat") and "Drive" or "Seat"
		prompt.KeyboardKeyCode = Enum.KeyCode.F
		prompt.MaxActivationDistance = 6
		prompt.RequiresLineOfSight = false
		prompt.Parent = (seat :: any).PromptAttachment :: Attachment

		prompt.Triggered:Connect(function(player: Player)
			if seat.Occupant then return end

			local character = player.Character
			if not character then return end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			(seat :: Seat):Sit(humanoid)
		end)

		local RE = Instance.new("RemoteEvent")
		RE.Name = "_SeatRE"
		RE.Parent = seat

		RE.OnServerEvent:Connect(function(player: Player)
			if not player.Character then return end
			local humanoid =
				player.Character:FindFirstChildOfClass("Humanoid") :: Humanoid
			local seatPart = humanoid.SeatPart

			local seatWeld = seatPart
				and seatPart:FindFirstChild("SeatWeld") :: Weld
			if not seatPart or not seatWeld then return end

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

				local player =
					Players:GetPlayerFromCharacter(character :: Model)
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

function ServerVehicle.get.CFrame(self: ServerVehicle)
	return self.WeightPart.CFrame
end

function ServerVehicle.get.Velocity(self: ServerVehicle)
	return self.WeightPart.AssemblyLinearVelocity
end

function ServerVehicle.get.AngularVelocity(self: ServerVehicle)
	return self.WeightPart.AssemblyAngularVelocity
end

function ServerVehicle.get.Center(self: ServerVehicle)
	return VehicleUtil.GetCenter(self)
end

function ServerVehicle.set.CFrame(self: ServerVehicle, cframe: CFrame)
	self.Instance:PivotTo(cframe)
end

function ServerVehicle.Destroy(self: ServerVehicle) self.Instance:Destroy() end

return table.freeze(ServerVehicle :: any) :: {
	new: (instance: Instance, owner: Player) -> ServerVehicle,
}
