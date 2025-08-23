local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseWheel = require(ReplicatedStorage.Shared.Classes.BaseWheel)
local BrakeDisk = require(script.BrakeDisk)
local MakeWeld = require(ReplicatedStorage.Shared.Utils.MakeWeld)
local ModelWeld = require(ReplicatedStorage.Shared.Utils.ModelWeld)
local Tire = require(script.Tire)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ServerWheel = setmetatable({}, BaseWheel)
ServerWheel.__index = ServerWheel

type ServerWheel = VehicleTypes.ServerWheel

function ServerWheel.new(vehicle: VehicleTypes.ServerVehicle, instance: BasePart)
	local self: ServerWheel = setmetatable(BaseWheel.new(vehicle, instance), ServerWheel) :: any

	Initialize(self)

	self.Tire = Tire.new(self, self.Instance.Parts.Tire)
	self.BrakeDisk = BrakeDisk.new(self, self.Instance.Parts.BrakeDisk)

	return self
end

function Initialize(self: ServerWheel)
	local fDistX = self.Vehicle.Tune.FWsBoneLen * math.cos(math.rad(self.Vehicle.Tune.FWsBoneAngle))
	local fDistY = self.Vehicle.Tune.FWsBoneLen * math.sin(math.rad(self.Vehicle.Tune.FWsBoneAngle))
	local rDistX = self.Vehicle.Tune.RWsBoneLen * math.cos(math.rad(self.Vehicle.Tune.RWsBoneAngle))
	local rDistY = self.Vehicle.Tune.RWsBoneLen * math.sin(math.rad(self.Vehicle.Tune.RWsBoneAngle))

	local fSLX = self.Vehicle.Tune.FSusLength * math.cos(math.rad(self.Vehicle.Tune.FSusAngle))
	local fSLY = self.Vehicle.Tune.FSusLength * math.sin(math.rad(self.Vehicle.Tune.FSusAngle))
	local rSLX = self.Vehicle.Tune.RSusLength * math.cos(math.rad(self.Vehicle.Tune.RSusAngle))
	local rSLY = self.Vehicle.Tune.RSusLength * math.sin(math.rad(self.Vehicle.Tune.RSusAngle))

	--Apply Wheel Density
	local physProps = self.Instance.CurrentPhysicalProperties
	local wdensity = 0
	if self.IsFront then
		wdensity = (self.Vehicle.Tune.FWheelWeight * Units.Mass_kg)
			/ (math.pi * (self.Instance.Size.Y / 2) ^ 2 * self.Instance.Size.X)
	else
		wdensity = (self.Vehicle.Tune.RWheelWeight * Units.Mass_kg)
			/ (math.pi * (self.Instance.Size.Y / 2) ^ 2 * self.Instance.Size.X)
	end
	self.Instance.CustomPhysicalProperties = PhysicalProperties.new(
		wdensity,
		physProps.Friction,
		physProps.Elasticity,
		physProps.FrictionWeight,
		physProps.ElasticityWeight
	)
	self.Instance.Massless = false

	--Save wheel part positions
	local WParts = {}
	for _, a in self.Instance.Parts:GetDescendants() do
		if not a:IsA("BasePart") then continue end
		table.insert(WParts, { a, self.Instance.CFrame:ToObjectSpace(a.CFrame) })
	end
	for _, a in self.Instance.WheelFixed:GetDescendants() do
		if not a:IsA("BasePart") then continue end
		table.insert(WParts, { a, self.Instance.CFrame:ToObjectSpace(a.CFrame) })
	end

	--Align Wheels
	local isLeft = string.sub(self.Instance.Name, 2, 2) == "L"
	local posChar = string.sub(self.Instance.Name, 1, 1)
	self.Instance.CFrame = self.Instance.CFrame
		* CFrame.Angles(
			math.rad(self.Vehicle.Tune[posChar .. "Caster"] * (isLeft and 1 or -1)),
			math.rad(self.Vehicle.Tune[posChar .. "Toe"] * (isLeft and -1 or 1)),
			math.rad(self.Vehicle.Tune[posChar .. "Camber"] :: number)
		)

	for _, a in WParts do
		a[1].CFrame = self.Instance.CFrame * a[2]
	end

	--[[Chassis Assembly]]
	--Create Steering Axle
	local arm = Instance.new("Part")
	arm.Name = "Arm"
	arm.Anchored = true
	arm.CanCollide = false
	arm.Size = Vector3.new(self.Vehicle.Tune.AxleSize, self.Vehicle.Tune.AxleSize, self.Vehicle.Tune.AxleSize)
	arm.CFrame = self.Instance.CFrame
	arm.CustomPhysicalProperties =
		PhysicalProperties.new(math.clamp(self.Vehicle.Tune.AxleDensity, 0.01, 100), 0, 0, 100, 100)
	arm.TopSurface = Enum.SurfaceType.Smooth
	arm.BottomSurface = Enum.SurfaceType.Smooth
	arm.Transparency = 1
	arm.Parent = self.Instance

	--Create Wheel Spindle
	local base = arm:Clone()
	base.Name = "Base"
	base.CFrame = arm.CFrame * CFrame.new(0, self.Vehicle.Tune.AxleSize, 0)
	base.Parent = self.Instance

	local SteerOuter = (self.Vehicle.Tune.LockToLock * 180) / self.Vehicle.Tune.SteerRatio
	local SteerInner = math.min(SteerOuter - (SteerOuter * (1 - self.Vehicle.Tune.Ackerman)), SteerOuter * 1.2)
	if not self.IsFront then
		SteerOuter = self.Vehicle.Tune.RSteerOuter
		SteerInner = self.Vehicle.Tune.RSteerInner
	elseif self.Vehicle.Tune.SteeringType == "Manual" then
		SteerOuter = self.Vehicle.Tune.SteerOuter
		SteerInner = self.Vehicle.Tune.SteerInner
	end

	--Create Steering Anchor
	local axle = arm:Clone()
	axle.Name = "Axle"
	axle.CFrame = self.Instance.CFrame * CFrame.new(self.Instance.Size.X / 2 + self.Vehicle.Tune.AxleSize / 2, 0, 0)
	axle.Parent = self.Instance

	--Create Powered Axle (LuaInt)
	local axlep = arm:Clone()
	axlep.Name = "AxleP"
	axlep.CFrame = self.Instance.CFrame
	axlep.Parent = self.Instance
	MakeWeld(axlep, axle)

	--Create Suspension
	if self.Vehicle.Tune.SuspensionEnabled == true then
		local SuspensionGeometry = self.Instance:FindFirstChild("SuspensionGeometry")
		if SuspensionGeometry then
			for _, a in SuspensionGeometry:GetDescendants() do
				if a.Name == "Weld" then
					if a:IsA("BasePart") then
						MakeWeld(a, self.Vehicle.Instance.DriveSeat)
					elseif a:IsA("Model") then
						ModelWeld(a, self.Vehicle.Instance.DriveSeat)
					end
				end
			end
			MakeWeld(SuspensionGeometry.Hub, base)
			if SuspensionGeometry:FindFirstChild("SpringTop") then
				MakeWeld(SuspensionGeometry.SpringTop, self.Vehicle.Instance.DriveSeat)
			end

			local susparts = SuspensionGeometry:GetDescendants()
			for _, p in susparts do
				if p:IsA("Part") then
					p.CustomPhysicalProperties = PhysicalProperties.new(
						math.clamp(self.Vehicle.Tune.CustomSuspensionDensity, 0.01, 100),
						0,
						0,
						0,
						0
					)
					p.Massless = (self.Vehicle.Tune.CustomSuspensionDensity :: number) <= 0
					p.Transparency = self.Vehicle.Tune.SusVisible and 0.5 or 1
				end
				if p:IsA("Constraint") then p.Visible = self.Vehicle.Tune.SusVisible end
			end

			local sp = SuspensionGeometry:FindFirstChild("Spring")
			sp.LimitsEnabled = true
			sp.Visible = self.Vehicle.Tune.SpringsVisible
			sp.Radius = self.Vehicle.Tune.SusRadius
			sp.Thickness = self.Vehicle.Tune.SusThickness
			sp.Color = self.Vehicle.Tune.SusColor
			sp.Coils = self.Vehicle.Tune.SusCoilCount

			local swayBar = SuspensionGeometry:FindFirstChild("SwayBar")
			if swayBar and swayBar.Attachment0 and swayBar.Attachment1 then
				swayBar.Attachment0.Position = Vector3.new(
					swayBar.Attachment0.Parent.CFrame:ToObjectSpace(self.Vehicle:GetCenter()).Position.X - 0.05,
					0,
					0
				)
				swayBar.Attachment1.Position = Vector3.new(
					swayBar.Attachment1.Parent.CFrame:ToObjectSpace(self.Vehicle:GetCenter()).Position.X - 0.05,
					0,
					0
				)
				swayBar.Damping = 20
				swayBar.FreeLength = 0.1
			end
			if self.IsFront then
				sp.Damping = self.Vehicle.Tune.FSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = self.Vehicle.Tune.FSusStiffness * 9806.65 * Units.Stiffness_Ndivm -- 9806.65 converts kgf/mm to N/m
				sp.FreeLength = self.Vehicle.Tune.FSusLength + self.Vehicle.Tune.FPreCompress
				sp.MaxLength = self.Vehicle.Tune.FSusLength + self.Vehicle.Tune.FExtensionLim
				sp.MinLength = self.Vehicle.Tune.FSusLength - self.Vehicle.Tune.FCompressLim
				if swayBar then swayBar.Stiffness = self.Vehicle.Tune.FSwayBar * 9806.65 * Units.Stiffness_Ndivm end
			else
				sp.Damping = self.Vehicle.Tune.RSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = self.Vehicle.Tune.RSusStiffness * 9806.65 * Units.Stiffness_Ndivm
				sp.FreeLength = self.Vehicle.Tune.RSusLength + self.Vehicle.Tune.RPreCompress
				sp.MaxLength = self.Vehicle.Tune.RSusLength + self.Vehicle.Tune.RExtensionLim
				sp.MinLength = self.Vehicle.Tune.RSusLength - self.Vehicle.Tune.RCompressLim
				if swayBar then swayBar.Stiffness = self.Vehicle.Tune.RSwayBar * 9806.65 * Units.Stiffness_Ndivm end
			end
		else
			local legacyCFrame = self.Instance.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(90)) -- not gonna bother fixing the entire thing so i just put this because it works

			local sa = arm:Clone()
			sa.Parent = self.Instance
			sa.Name = "#SA"
			sa.CFrame = legacyCFrame * CFrame.Angles(-math.pi / 2, -math.pi / 2, 0)
			if self.IsFront then
				local aOff = self.Vehicle.Tune.FAnchorOffset
				sa.CFrame = legacyCFrame
					* CFrame.new(self.Vehicle.Tune.AxleSize / 2, -fDistX, -fDistY)
					* CFrame.new(aOff[3], aOff[1], -aOff[2])
					* CFrame.Angles(-math.pi / 2, -math.pi / 2, 0)
			else
				local aOff = self.Vehicle.Tune.RAnchorOffset
				sa.CFrame = legacyCFrame
					* CFrame.new(self.Vehicle.Tune.AxleSize / 2, -rDistX, -rDistY)
					* CFrame.new(aOff[3], aOff[1], -aOff[2])
					* CFrame.Angles(-math.pi / 2, -math.pi / 2, 0)
			end

			local sb = sa:Clone()
			sb.Parent = self.Instance
			sb.Name = "#SB"
			sb.CFrame = sa.CFrame * CFrame.new(0, 0, self.Vehicle.Tune.AxleSize)
			sb.FrontSurface = Enum.SurfaceType.Hinge

			local sf1 = Instance.new("Attachment")
			sf1.Name = "SAtt"
			sf1.Parent = sa

			local sf2 = sf1:Clone()
			sf2.Parent = sb

			--(Avxnturador) adds spring offset
			if self.IsFront then
				local aOff = self.Vehicle.Tune.FSpringOffset
				if self.Instance.Name == "FL" then
					sf1.Position = Vector3.new(
						fDistX - fSLX + aOff[1],
						-fDistY + fSLY + aOff[2],
						self.Vehicle.Tune.AxleSize / 2 + aOff[3]
					)
					sf2.Position =
						Vector3.new(fDistX + aOff[1], -fDistY + aOff[2], -self.Vehicle.Tune.AxleSize / 2 + aOff[3])
				else
					sf1.Position = Vector3.new(
						fDistX - fSLX + aOff[1],
						-fDistY + fSLY + aOff[2],
						self.Vehicle.Tune.AxleSize / 2 - aOff[3]
					)
					sf2.Position =
						Vector3.new(fDistX + aOff[1], -fDistY + aOff[2], -self.Vehicle.Tune.AxleSize / 2 - aOff[3])
				end
			else
				local aOff = self.Vehicle.Tune.RSpringOffset
				if self.Instance.Name == "RL" then
					sf1.Position = Vector3.new(
						rDistX - rSLX + aOff[1],
						-rDistY + rSLY + aOff[2],
						self.Vehicle.Tune.AxleSize / 2 + aOff[3]
					)
					sf2.Position =
						Vector3.new(rDistX + aOff[1], -rDistY + aOff[2], -self.Vehicle.Tune.AxleSize / 2 + aOff[3])
				else
					sf1.Position = Vector3.new(
						rDistX - rSLX + aOff[1],
						-rDistY + rSLY + aOff[2],
						self.Vehicle.Tune.AxleSize / 2 - aOff[3]
					)
					sf2.Position =
						Vector3.new(rDistX + aOff[1], -rDistY + aOff[2], -self.Vehicle.Tune.AxleSize / 2 - aOff[3])
				end
			end

			sb:MakeJoints()
			--(LuaInt) there was axle:makejoints here I believe, but the new powered axle manually welds itself so I ditched it

			local sp = Instance.new("SpringConstraint")
			sp.Name = "Spring"
			sp.Attachment0 = sf1
			sp.Attachment1 = sf2
			sp.LimitsEnabled = true

			sp.Visible = self.Vehicle.Tune.SpringsVisible
			sp.Radius = self.Vehicle.Tune.SusRadius
			sp.Thickness = self.Vehicle.Tune.SusThickness
			sp.Color = self.Vehicle.Tune.SusColor
			sp.Coils = self.Vehicle.Tune.SusCoilCount

			sp.Parent = self.Instance

			if self.IsFront then
				sp.Damping = self.Vehicle.Tune.FSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = self.Vehicle.Tune.FSusStiffness * 9806.65 * Units.Stiffness_Ndivm
				sp.FreeLength = self.Vehicle.Tune.FSusLength + self.Vehicle.Tune.FPreCompress
				sp.MaxLength = self.Vehicle.Tune.FSusLength + self.Vehicle.Tune.FExtensionLim
				sp.MinLength = self.Vehicle.Tune.FSusLength - self.Vehicle.Tune.FCompressLim
			else
				sp.Damping = self.Vehicle.Tune.RSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = self.Vehicle.Tune.RSusStiffness * 9806.65 * Units.Stiffness_Ndivm
				sp.FreeLength = self.Vehicle.Tune.RSusLength + self.Vehicle.Tune.RPreCompress
				sp.MaxLength = self.Vehicle.Tune.RSusLength + self.Vehicle.Tune.RExtensionLim
				sp.MinLength = self.Vehicle.Tune.RSusLength - self.Vehicle.Tune.RCompressLim
			end

			MakeWeld(self.Vehicle.Instance.DriveSeat, sa)
			MakeWeld(sb, base)
		end
	else
		MakeWeld(self.Vehicle.Instance.DriveSeat, base)
	end

	--Lock Rear Steering Axle
	if
		(
			self.Vehicle.Tune.FWSteer == "Static"
			or self.Vehicle.Tune.FWSteer == "Speed"
			or self.Vehicle.Tune.FWSteer == "Both"
		) == false
	then
		if not self.IsFront then MakeWeld(base, axle) end
	end

	MakeWeld(arm, axle)

	--Weld Miscelaneous Parts
	if self.Instance:FindFirstChild("SuspensionFixed") ~= nil then
		ModelWeld(self.Instance.SuspensionFixed, self.Vehicle.Instance.DriveSeat)
	end
	if self.Instance:FindFirstChild("WheelFixed") ~= nil then ModelWeld(self.Instance.WheelFixed, axle) end
	if self.Instance:FindFirstChild("Fixed") ~= nil then ModelWeld(self.Instance.Fixed, arm) end

	--Weld Wheel Parts
	if self.Instance:FindFirstChild("Parts") ~= nil then ModelWeld(self.Instance.Parts, self.Instance) end

	--Add Steering Gyro
	if self.Instance:FindFirstChild("Steer") then (self.Instance:FindFirstChild("Steer") :: Instance):Destroy() end

	if
		self.IsFront
		or (
			self.Vehicle.Tune.FWSteer == "Static"
			or self.Vehicle.Tune.FWSteer == "Speed"
			or self.Vehicle.Tune.FWSteer == "Both"
		)
	then
		local steer
		if self.Vehicle.Tune.PowerSteeringType == "New" then
			local steerAttach0 = Instance.new("Attachment")
			steerAttach0.Name = "SteerAttach0"
			steerAttach0.Parent = arm
			local steerAttach1 = Instance.new("Attachment")
			steerAttach1.Name = "SteerAttach1"
			steerAttach1.Parent = base
			steer = Instance.new("AlignOrientation")
			steer.Name = "Steer"
			steer.Mode = Enum.OrientationAlignmentMode.TwoAttachment
			steer.ReactionTorqueEnabled = true
			steer.RigidityEnabled = true
			steer.Attachment0 = steerAttach0
			steer.Attachment1 = steerAttach1
		else
			steer = Instance.new("BodyGyro")
			if self.IsFront then
				steer.P = self.Vehicle.Tune.SteerP
				steer.D = self.Vehicle.Tune.SteerD
				steer.MaxTorque = Vector3.new(0, self.Vehicle.Tune.SteerMaxTorque, 0)
			else
				steer.P = self.Vehicle.Tune.RSteerP
				steer.D = self.Vehicle.Tune.RSteerD
				steer.MaxTorque = Vector3.new(0, self.Vehicle.Tune.RSteerMaxTorque, 0)
			end
		end
		steer.Name = "Steer"
		steer.CFrame = self.Instance.CFrame
		steer.Parent = self.Instance.Arm
	end

	--Add rotation constraint (Detomiks)
	local rotationAttachment0 = Instance.new("Attachment")
	rotationAttachment0.Name = "RotationAttachment0"
	rotationAttachment0.Position = Vector3.new(0, -self.Vehicle.Tune.AxleSize / 2, 0)
	rotationAttachment0.Orientation = Vector3.new(0, 0, 90)
	rotationAttachment0.Parent = base

	local rotationAttachment1 = Instance.new("Attachment")
	rotationAttachment1.Name = "RotationAttachment1"
	rotationAttachment1.Position = Vector3.new(0, self.Vehicle.Tune.AxleSize / 2, 0)
	rotationAttachment1.Orientation = Vector3.new(0, 0, 90)
	rotationAttachment1.Parent = arm

	local rotationHinge = Instance.new("HingeConstraint")
	rotationHinge.Name = "Rotate"
	rotationHinge.LimitsEnabled = true
	rotationHinge.UpperAngle = math.max(SteerOuter, SteerInner)
	rotationHinge.LowerAngle = -rotationHinge.UpperAngle
	rotationHinge.Attachment0 = rotationAttachment0
	rotationHinge.Attachment1 = rotationAttachment1
	rotationHinge.Parent = base

	--Add Motors (LuaInt)
	local AV = Instance.new("HingeConstraint")
	AV.ActuatorType = "Motor"
	AV.Parent = self.Instance
	AV.Attachment0 = Instance.new("Attachment")
	AV.Attachment0.Name = "AA"
	AV.Attachment0.Parent = (self.Instance :: any).AxleP
	AV.Attachment1 = Instance.new("Attachment")
	AV.Attachment1.Name = "AB"
	AV.Attachment1.Parent = self.Instance
	AV.Name = "AV"
	AV.AngularVelocity = 0
	AV.MotorMaxTorque = 0

	local BV = Instance.new("HingeConstraint")
	BV.ActuatorType = "Motor"
	BV.Parent = self.Instance
	BV.Attachment0 = Instance.new("Attachment")
	BV.Attachment0.Parent = (self.Instance :: any).AxleP
	BV.Attachment0.Name = "BA"
	BV.Attachment1 = Instance.new("Attachment")
	BV.Attachment1.Name = "BB"
	BV.Attachment1.Parent = self.Instance
	BV.Name = "BV"
	BV.AngularVelocity = 0
	if self.IsFront then
		BV.MotorMaxTorque = (self.Vehicle.Tune.PBrakeForce * 9.80665 * Units.Force_N) * self.Vehicle.Tune.PBrakeBias
	else
		BV.MotorMaxTorque = (self.Vehicle.Tune.PBrakeForce * 9.80665 * Units.Force_N)
			* (1 - self.Vehicle.Tune.PBrakeBias)
	end

	-- Attempt to fix wheel alignment issues
	if string.find(self.Instance.Name, "L") or self.Instance.Name == "R" or self.Instance.Name == "F" then
		AV.Attachment0.Orientation = Vector3.new(0, 180, 0)
		BV.Attachment0.Orientation = Vector3.new(0, 180, 0)
		AV.Attachment1.Orientation = Vector3.new(0, 180, 0)
		BV.Attachment1.Orientation = Vector3.new(0, 180, 0)
	end

	--Realign Caster
	self.Instance.CFrame = self.Instance.CFrame
		* CFrame.Angles(math.rad(self.Vehicle.Tune[posChar .. "Caster"] :: number) * (isLeft and -1 or 1), 0, 0)
end

return ServerWheel
