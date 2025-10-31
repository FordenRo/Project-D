local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseWheel = require(ReplicatedStorage.Shared.Classes.BaseWheel)
local BrakeDisk = require(script.BrakeDisk)
local MakeUtil = require(ReplicatedStorage.Shared.Utils.MakeUtil)
local Tire = require(script.Tire)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ServerWheel = setmetatable({}, BaseWheel)
ServerWheel.__index = ServerWheel

type ServerWheel = VehicleTypes.ServerWheel

function ServerWheel.new(
	vehicle: VehicleTypes.ServerVehicle,
	instance: BasePart
): ServerWheel
	local self: ServerWheel =
		setmetatable(BaseWheel.new(vehicle, instance), ServerWheel) :: any

	Initialize(self)

	self.Tire = Tire.new(self, self.Instance.Parts.Tire)
	self.BrakeDisk = BrakeDisk.new(self, self.Instance.Parts.BrakeDisk)

	return self
end

function Initialize(self: ServerWheel)
	-- Apply Wheel Density
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

	-- Save wheel part positions
	local wheelParts = {}
	for _, collection in
		{ self.Instance.Parts, self.Instance.WheelFixed } :: { Model }
	do
		for _, part in collection:GetDescendants() do
			if not part:IsA("BasePart") then continue end

			wheelParts[part] = self.Instance.CFrame:ToObjectSpace(part.CFrame)
		end
	end

	-- Align Wheels
	local posChar = string.sub(self.Instance.Name, 1, 1)
	self.Instance.CFrame = self.Instance.CFrame
		* CFrame.Angles(
			math.rad(
				self.Vehicle.Tune[posChar .. "Caster"]
					* (self.IsRight and -1 or 1)
			),
			math.rad(
				self.Vehicle.Tune[posChar .. "Toe"] * (self.IsRight and 1 or -1)
			),
			math.rad(self.Vehicle.Tune[posChar .. "Camber"] :: number)
		)

	for part, cframe in wheelParts do
		part.CFrame = self.Instance.CFrame * cframe
	end

	-- Create Steering Axle
	local arm = Instance.new("Part")
	arm.Name = "Arm"
	arm.Anchored = true
	arm.CanCollide = false
	arm.Size = Vector3.new(
		self.Vehicle.Tune.AxleSize,
		self.Vehicle.Tune.AxleSize,
		self.Vehicle.Tune.AxleSize
	)
	arm.CFrame = self.Instance.CFrame
	arm.CustomPhysicalProperties = PhysicalProperties.new(
		math.clamp(self.Vehicle.Tune.AxleDensity, 0.01, 100),
		0,
		0,
		100,
		100
	)
	arm.TopSurface = Enum.SurfaceType.Smooth
	arm.BottomSurface = Enum.SurfaceType.Smooth
	arm.Transparency = 1
	arm.Parent = self.Instance

	-- Create Wheel Spindle
	local base = arm:Clone()
	base.Name = "Base"
	base.CFrame = arm.CFrame * CFrame.new(0, self.Vehicle.Tune.AxleSize, 0)
	base.Parent = self.Instance

	local steerOuter = (self.Vehicle.Tune.LockToLock * 180)
		/ self.Vehicle.Tune.SteerRatio
	local steerInner = math.min(
		steerOuter - (steerOuter * (1 - self.Vehicle.Tune.Ackerman)),
		steerOuter * 1.2
	)
	if not self.IsFront then
		steerOuter = self.Vehicle.Tune.RSteerOuter
		steerInner = self.Vehicle.Tune.RSteerInner
	end

	-- Create Steering Anchor
	local axle = arm:Clone()
	axle.Name = "Axle"
	axle.CFrame = self.Instance.CFrame
		* CFrame.new(
			self.Instance.Size.X / 2 + self.Vehicle.Tune.AxleSize / 2,
			0,
			0
		)
	axle.Parent = self.Instance

	-- Create Powered Axle (LuaInt)
	local axlep = arm:Clone()
	axlep.Name = "AxleP"
	axlep.CFrame = self.Instance.CFrame
	axlep.Parent = self.Instance
	MakeUtil.Weld(axlep, axle)

	-- Create Suspension
	for _, v in self.Instance.SuspensionGeometry:GetDescendants() do
		if v.Name == "Weld" then
			if v:IsA("BasePart") then
				MakeUtil.Weld(v, self.Vehicle.Instance.DriveSeat)
			elseif v:IsA("Model") then
				MakeUtil.ModelWeld(v, self.Vehicle.Instance.DriveSeat)
			end
		end
	end
	MakeUtil.Weld(self.Instance.SuspensionGeometry.Hub, base)
	if self.Instance.SuspensionGeometry:FindFirstChild("SpringTop") then
		MakeUtil.Weld(
			self.Instance.SuspensionGeometry.SpringTop,
			self.Vehicle.Instance.DriveSeat
		)
	end

	local susparts = self.Instance.SuspensionGeometry:GetDescendants()
	for _, p in susparts do
		if p:IsA("Part") then
			p.CustomPhysicalProperties = PhysicalProperties.new(
				math.clamp(self.Vehicle.Tune.CustomSuspensionDensity, 0.01, 100),
				0,
				0,
				0,
				0
			)
			p.Massless = (self.Vehicle.Tune.CustomSuspensionDensity :: number)
				<= 0
			p.Transparency = self.Vehicle.Tune.SusVisible and 0.5 or 1
		end
		if p:IsA("Constraint") then p.Visible = self.Vehicle.Tune.SusVisible end
	end

	local sp = self.Instance.SuspensionGeometry.Spring
	sp.LimitsEnabled = true
	sp.Visible = self.Vehicle.Tune.SpringsVisible
	sp.Radius = self.Vehicle.Tune.SusRadius
	sp.Thickness = self.Vehicle.Tune.SusThickness
	sp.Color = self.Vehicle.Tune.SusColor
	sp.Coils = self.Vehicle.Tune.SusCoilCount

	local swayBar =
		self.Instance.SuspensionGeometry:FindFirstChild("SwayBar") :: SpringConstraint?
	if swayBar then
		local attach0 = swayBar.Attachment0 :: Attachment
		local attach1 = swayBar.Attachment1 :: Attachment
		attach0.Position = Vector3.new(
			(attach0.Parent :: BasePart).CFrame:ToObjectSpace(
				self.Vehicle.Center
			).Position.X - 0.05,
			0,
			0
		)
		attach1.Position = Vector3.new(
			(attach1.Parent :: BasePart).CFrame:ToObjectSpace(
				self.Vehicle.Center
			).Position.X - 0.05,
			0,
			0
		)
		swayBar.Damping = 20
		swayBar.FreeLength = 0.1
	end
	if self.IsFront then
		sp.Damping = self.Vehicle.Tune.FSusDamping
			* 1000
			* Units.Damping_N_sdivm
		sp.Stiffness = self.Vehicle.Tune.FSusStiffness
			* 9806.65
			* Units.Stiffness_Ndivm -- 9806.65 converts kgf/mm to N/m
		sp.FreeLength = self.Vehicle.Tune.FSusLength
			+ self.Vehicle.Tune.FPreCompress
		sp.MaxLength = self.Vehicle.Tune.FSusLength
			+ self.Vehicle.Tune.FExtensionLim
		sp.MinLength = self.Vehicle.Tune.FSusLength
			- self.Vehicle.Tune.FCompressLim
		if swayBar then
			swayBar.Stiffness = self.Vehicle.Tune.FSwayBar
				* 9806.65
				* Units.Stiffness_Ndivm
		end
	else
		sp.Damping = self.Vehicle.Tune.RSusDamping
			* 1000
			* Units.Damping_N_sdivm
		sp.Stiffness = self.Vehicle.Tune.RSusStiffness
			* 9806.65
			* Units.Stiffness_Ndivm
		sp.FreeLength = self.Vehicle.Tune.RSusLength
			+ self.Vehicle.Tune.RPreCompress
		sp.MaxLength = self.Vehicle.Tune.RSusLength
			+ self.Vehicle.Tune.RExtensionLim
		sp.MinLength = self.Vehicle.Tune.RSusLength
			- self.Vehicle.Tune.RCompressLim
		if swayBar then
			swayBar.Stiffness = self.Vehicle.Tune.RSwayBar
				* 9806.65
				* Units.Stiffness_Ndivm
		end
	end

	-- Lock Rear Steering Axle
	if
		(
			self.Vehicle.Tune.FWSteer == "Static"
			or self.Vehicle.Tune.FWSteer == "Speed"
			or self.Vehicle.Tune.FWSteer == "Both"
		) == false
	then
		if not self.IsFront then MakeUtil.Weld(base, axle) end
	end

	MakeUtil.Weld(arm, axle)

	-- Weld Miscelaneous Parts
	if self.Instance:FindFirstChild("SuspensionFixed") ~= nil then
		MakeUtil.ModelWeld(
			self.Instance.SuspensionFixed,
			self.Vehicle.Instance.DriveSeat
		)
	end
	if self.Instance:FindFirstChild("WheelFixed") ~= nil then
		MakeUtil.ModelWeld(self.Instance.WheelFixed, axle)
	end
	if self.Instance:FindFirstChild("Fixed") ~= nil then
		MakeUtil.ModelWeld(self.Instance.Fixed, arm)
	end

	-- Weld Wheel Parts
	if self.Instance:FindFirstChild("Parts") ~= nil then
		MakeUtil.ModelWeld(self.Instance.Parts, self.Instance)
	end

	-- Add Steering Gyro
	if self.Instance:FindFirstChild("Steer") then
		(self.Instance:FindFirstChild("Steer") :: Instance):Destroy()
	end

	if
		self.IsFront
		or (
			self.Vehicle.Tune.FWSteer == "Static"
			or self.Vehicle.Tune.FWSteer == "Speed"
			or self.Vehicle.Tune.FWSteer == "Both"
		)
	then
		if self.Vehicle.Tune.PowerSteeringType == "New" then
			local steer = Instance.new("AlignOrientation")
			steer.Name = "Steer"
			steer.CFrame = self.Instance.CFrame
			steer.Mode = Enum.OrientationAlignmentMode.TwoAttachment
			steer.ReactionTorqueEnabled = true
			steer.RigidityEnabled = true

			local attach0 = Instance.new("Attachment")
			attach0.Name = "SteerAttach0"
			attach0.Parent = arm
			steer.Attachment0 = attach0

			local attach1 = Instance.new("Attachment")
			attach1.Name = "SteerAttach1"
			attach1.Parent = base
			steer.Attachment1 = attach1

			steer.Parent = self.Instance.Arm
		else
			local steer = Instance.new("BodyGyro")
			steer.Name = "Steer"
			steer.CFrame = self.Instance.CFrame
			steer.P = self.IsFront and self.Vehicle.Tune.SteerP
				or self.Vehicle.Tune.RSteerP
			steer.D = self.IsFront and self.Vehicle.Tune.SteerD
				or self.Vehicle.Tune.RSteerD
			steer.MaxTorque = Vector3.new(
				0,
				self.IsFront and self.Vehicle.Tune.SteerMaxTorque
					or self.Vehicle.Tune.RSteerMaxTorque,
				0
			)
			steer.Parent = self.Instance.Arm
		end
	end

	-- Add rotation constraint (Detomiks)
	local rotationAttachment0 = Instance.new("Attachment")
	rotationAttachment0.Name = "RotationAttachment0"
	rotationAttachment0.Position =
		Vector3.new(0, -self.Vehicle.Tune.AxleSize / 2, 0)
	rotationAttachment0.Orientation = Vector3.new(0, 0, 90)
	rotationAttachment0.Parent = base

	local rotationAttachment1 = Instance.new("Attachment")
	rotationAttachment1.Name = "RotationAttachment1"
	rotationAttachment1.Position =
		Vector3.new(0, self.Vehicle.Tune.AxleSize / 2, 0)
	rotationAttachment1.Orientation = Vector3.new(0, 0, 90)
	rotationAttachment1.Parent = arm

	local rotationHinge = Instance.new("HingeConstraint")
	rotationHinge.Name = "Rotate"
	rotationHinge.LimitsEnabled = true
	rotationHinge.UpperAngle = math.max(steerOuter, steerInner)
	rotationHinge.LowerAngle = -rotationHinge.UpperAngle
	rotationHinge.Attachment0 = rotationAttachment0
	rotationHinge.Attachment1 = rotationAttachment1
	rotationHinge.Parent = base

	--- Fix wheel alignment issue
	local function fixAlignment(attach: Attachment)
		if
			not (
				string.find(self.Instance.Name, "L")
				or self.Instance.Name == "R"
				or self.Instance.Name == "F"
			)
		then
			return
		end

		attach.Orientation = Vector3.new(0, 180, 0)
	end

	-- Add Motors (LuaInt)
	local AV = Instance.new("HingeConstraint")
	AV.Name = "AV"
	AV.ActuatorType = Enum.ActuatorType.Motor
	AV.AngularVelocity = 0
	AV.MotorMaxTorque = 0
	AV.Parent = self.Instance

	local BV = Instance.new("HingeConstraint")
	BV.Name = "BV"
	BV.ActuatorType = Enum.ActuatorType.Motor
	BV.AngularVelocity = 0
	BV.MotorMaxTorque = (
		self.Vehicle.Tune.PBrakeForce
		* 9.80665
		* Units.Force_N
	)
		* (
			self.IsFront and self.Vehicle.Tune.PBrakeBias
			or (1 - self.Vehicle.Tune.PBrakeBias)
		)
	BV.Parent = self.Instance

	do
		local attach0 = Instance.new("Attachment")
		attach0.Name = "AA"
		attach0.Parent = self.Instance.AxleP

		local attach1 = Instance.new("Attachment")
		attach1.Name = "AB"
		attach1.Parent = self.Instance

		fixAlignment(attach0)
		fixAlignment(attach1)

		AV.Attachment0 = attach0
		BV.Attachment0 = attach0

		AV.Attachment1 = attach1
		BV.Attachment1 = attach1
	end

	-- Realign Caster
	self.Instance.CFrame = self.Instance.CFrame
		* CFrame.Angles(
			math.rad(self.Vehicle.Tune[posChar .. "Caster"] :: number)
				* (self.IsRight and 1 or -1),
			0,
			0
		)
end

return table.freeze({ new = ServerWheel.new })
