local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Vehicle.Types)
local Units = require(ReplicatedStorage.Shared.Utils.Units)

local ServerVehicle = {}
ServerVehicle.__index = ServerVehicle

type ServerVehicle = Types.ServerVehicle

function ServerVehicle.new(instance: Model)
	local self: Types.ServerVehicle = setmetatable({}, ServerVehicle) :: any

	self.Instance = instance :: any
	self.Tune = require(
		assert(
			ReplicatedStorage.Shared.Vehicle.Tunes:FindFirstChild(instance.Name),
			"Tune not found for vehicle: " .. instance.Name
		)
	)
	self.Plugins = {}

	self._Remote = Instance.new("UnreliableRemoteEvent")
	self._Remote.Name = "_VehicleRemote"
	self._Remote.Parent = self.Instance

	self:Initialize()
	self._Remote.OnServerEvent:Connect(function(_, data: { [string]: any })
		for k, v in data do
			self[k] = v
		end
	end)

	return self
end

function ServerVehicle.Initialize(self: ServerVehicle)
	self:InitializeVariables()
	self:RemoveMass()
	self:CreateChassisAssembly()
	self:ApplyWeight()
	self:MakeGravity()
	self:CreateFlip()
	self:Finalize()
	self:InitializePlugins()
	self:RemoveCharacterWeight()
	self:InitializeDriveSeat()
end

function MakeWeld(x: BasePart, y: BasePart, type: string?, s: number?)
	if not type then type = "Weld" end
	local W = Instance.new(type :: string) :: Weld & Motor
	W.Parent = x
	W.Part0 = x
	W.Part1 = y
	W.C0 = x.CFrame:Inverse() * x.CFrame
	W.C1 = y.CFrame:Inverse() * x.CFrame
	if type == "Motor" and s ~= nil then W.MaxVelocity = s end
	return W
end

function ModelWeld(a, b)
	if a:IsA("BasePart") then
		MakeWeld(b, a, "Weld")
	elseif a:IsA("Model") then
		for _, v in a:GetChildren() do
			ModelWeld(v, b)
		end
	end
end

function ServerVehicle.InitializeVariables(self: ServerVehicle)
	local ParkingGearEnabled = self.Tune.Ratios[1] == 0
	self.Starting = false
	self.Occupant = nil
	self.Fuel = self.Tune.FuelCapacity
	self.Clutch = 0
	self.Gear = ParkingGearEnabled and -2 or 0
	self.FinalDrive = self.Tune.FinalDrive * self.Tune.FDMult
	self.FinalDriveRatio = self.FinalDrive * 30 / math.pi
	self.Shifting = false
	self.AutoClutch = false
	self.TransmissionMode = "Manual"
	self.CurrentRatio = self.Tune.Ratios[self.Gear + 2 + (ParkingGearEnabled and 1 or 0)]
	self.RPM = 0
	self.Boost = 0
	self.BoostTurbo = 0
	self.BoostSuper = 0
	self.HpNatural = 0
	self.HpElectric = 0
	self.HpTurbo = 0
	self.HpSuper = 0
	self.HpBoosted = 0
	self.Horsepower = 0
	self.TqNatural = 0
	self.TqElectric = 0
	self.TqTurbo = 0
	self.TqSuper = 0
	self.TqBoosted = 0
	self.Torque = 0
	self.Throttle = 0
	self.InputThrottle = 0
	self.Brake = 0
	self.InputBrake = 0
	self.SteerC = 0
	self.SteerT = 0
	self.MouseSteerOn = false
	self.PBrake = false
	self.Velocity = Vector3.new()
	self.AverageRotSpeed = 0
	self.Acceleration = Vector3.new()
	self.Center = CFrame.new()
	self.TCS = self.Tune.TCSEnabled
	self.TCSActive = false
	self.TCSAmt = 0
	self.ABS = self.Tune.ABSEnabled
	self.ABSActive = false
	self.ABSAmt = 0
	self.ESC = self.Tune.ESCEnabled and self.Tune.TCSEnabled
	self.ESCActive = false
	self.ESCAmt = 0
	self.CS = self.Tune.CSEnabled
	self.CSActive = false
	self.CSAmt = 0
	self.IsOn = self.Tune.AutoStart and (self.Tune.Engine or self.Tune.Electric)
	self.Mileage = 0
end

function ServerVehicle.RemoveMass(self: ServerVehicle)
	for _, v in self.Instance:GetDescendants() do
		if v:IsA("BasePart") then v.Massless = true end
	end
end

function ServerVehicle.MakeGravity(self: ServerVehicle)
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

function ServerVehicle.GetCenter(self: ServerVehicle)
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0
	for _, v in self.Instance.Wheels:GetChildren() do
		if not v:IsA("BasePart") then continue end
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
	local center = CFrame.lookAt(centerR:Lerp(centerF, 0.5), centerF)
	return center
end

function ServerVehicle.CreateChassisAssembly(self: ServerVehicle)
	local fDistX = self.Tune.FWsBoneLen * math.cos(math.rad(self.Tune.FWsBoneAngle))
	local fDistY = self.Tune.FWsBoneLen * math.sin(math.rad(self.Tune.FWsBoneAngle))
	local rDistX = self.Tune.RWsBoneLen * math.cos(math.rad(self.Tune.RWsBoneAngle))
	local rDistY = self.Tune.RWsBoneLen * math.sin(math.rad(self.Tune.RWsBoneAngle))

	local fSLX = self.Tune.FSusLength * math.cos(math.rad(self.Tune.FSusAngle))
	local fSLY = self.Tune.FSusLength * math.sin(math.rad(self.Tune.FSusAngle))
	local rSLX = self.Tune.RSusLength * math.cos(math.rad(self.Tune.RSusAngle))
	local rSLY = self.Tune.RSusLength * math.sin(math.rad(self.Tune.RSusAngle))

	for _, v in self.Instance.Wheels:GetChildren() do
		--Apply Wheel Density
		local cpp = v.CurrentPhysicalProperties
		local wdensity = 0
		if string.find(v.Name, "F") then
			wdensity = (self.Tune.FWheelWeight * Units.Mass_kg) / (math.pi * (v.Size.Y / 2) ^ 2 * v.Size.X)
		else
			wdensity = (self.Tune.RWheelWeight * Units.Mass_kg) / (math.pi * (v.Size.Y / 2) ^ 2 * v.Size.X)
		end
		v.CustomPhysicalProperties =
			PhysicalProperties.new(wdensity, cpp.Friction, cpp.Elasticity, cpp.FrictionWeight, cpp.ElasticityWeight)
		v.Massless = false

		--Save wheel part positions
		local WParts = {}
		for _, a in v.Parts:GetDescendants() do
			if not a:IsA("BasePart") then continue end
			table.insert(WParts, { a, v.CFrame:ToObjectSpace(a.CFrame) })
		end
		for _, a in v.WheelFixed:GetDescendants() do
			if not a:IsA("BasePart") then continue end
			table.insert(WParts, { a, v.CFrame:ToObjectSpace(a.CFrame) })
		end

		--Align Wheels
		if v.Name == "FL" then
			v.CFrame = v.CFrame
				* CFrame.Angles(math.rad(self.Tune.FCaster), math.rad(-self.Tune.FToe), math.rad(self.Tune.FCamber))
		elseif v.Name == "FR" then
			v.CFrame = v.CFrame
				* CFrame.Angles(math.rad(-self.Tune.FCaster), math.rad(self.Tune.FToe), math.rad(self.Tune.FCamber))
		elseif v.Name == "RL" then
			v.CFrame = v.CFrame
				* CFrame.Angles(math.rad(self.Tune.RCaster), math.rad(-self.Tune.RToe), math.rad(self.Tune.RCamber))
		elseif v.Name == "RR" then
			v.CFrame = v.CFrame
				* CFrame.Angles(math.rad(-self.Tune.RCaster), math.rad(self.Tune.RToe), math.rad(self.Tune.RCamber))
		end

		for _, a in WParts do
			a[1].CFrame = v.CFrame * a[2]
		end

		--[[Chassis Assembly]]
		--Create Steering Axle
		local arm = Instance.new("Part")
		arm.Name = "Arm"
		arm.Anchored = true
		arm.CanCollide = false
		arm.Size = Vector3.new(self.Tune.AxleSize, self.Tune.AxleSize, self.Tune.AxleSize)
		arm.CFrame = v.CFrame
		arm.CustomPhysicalProperties =
			PhysicalProperties.new(math.clamp(self.Tune.AxleDensity, 0.01, 100), 0, 0, 100, 100)
		arm.TopSurface = Enum.SurfaceType.Smooth
		arm.BottomSurface = Enum.SurfaceType.Smooth
		arm.Transparency = 1
		arm.Parent = v

		--Create Wheel Spindle
		local base = arm:Clone()
		base.Name = "Base"
		base.CFrame = arm.CFrame * CFrame.new(0, self.Tune.AxleSize, 0)
		base.Parent = v

		local SteerOuter = (self.Tune.LockToLock * 180) / self.Tune.SteerRatio
		local SteerInner = math.min(SteerOuter - (SteerOuter * (1 - self.Tune.Ackerman)), SteerOuter * 1.2)
		if not string.find(v.Name, "F") then
			SteerOuter = self.Tune.RSteerOuter
			SteerInner = self.Tune.RSteerInner
		elseif self.Tune.SteeringType == "Manual" then
			SteerOuter = self.Tune.SteerOuter
			SteerInner = self.Tune.SteerInner
		end

		--Create Steering Anchor
		local axle = arm:Clone()
		axle.Name = "Axle"
		axle.CFrame = v.CFrame * CFrame.new(v.Size.X / 2 + self.Tune.AxleSize / 2, 0, 0)
		axle.Parent = v

		--Create Powered Axle (LuaInt)
		local axlep = arm:Clone()
		axlep.Name = "AxleP"
		axlep.CFrame = v.CFrame
		axlep.Parent = v
		MakeWeld(axlep, axle)

		--Create Suspension
		if self.Tune.SuspensionEnabled == true then
			local SuspensionGeometry = v:FindFirstChild("SuspensionGeometry")
			if SuspensionGeometry then
				for _, a in SuspensionGeometry:GetDescendants() do
					if a.Name == "Weld" then
						if a:IsA("BasePart") then
							MakeWeld(a, self.Instance.DriveSeat)
						elseif a:IsA("Model") then
							ModelWeld(a, self.Instance.DriveSeat)
						end
					end
				end
				MakeWeld(SuspensionGeometry.Hub, base)
				if SuspensionGeometry:FindFirstChild("SpringTop") then
					MakeWeld(SuspensionGeometry.SpringTop, self.Instance.DriveSeat)
				end

				local susparts = SuspensionGeometry:GetDescendants()
				for _, p in susparts do
					if p:IsA("Part") then
						p.CustomPhysicalProperties =
							PhysicalProperties.new(math.clamp(self.Tune.CustomSuspensionDensity, 0.01, 100), 0, 0, 0, 0)
						p.Massless = self.Tune.CustomSuspensionDensity <= 0
						p.Transparency = self.Tune.SusVisible and 0.5 or 1
					end
					if p:IsA("Constraint") then p.Visible = self.Tune.SusVisible end
				end

				local sp = SuspensionGeometry:FindFirstChild("Spring")
				sp.LimitsEnabled = true
				sp.Visible = self.Tune.SpringsVisible
				sp.Radius = self.Tune.SusRadius
				sp.Thickness = self.Tune.SusThickness
				sp.Color = self.Tune.SusColor
				sp.Coils = self.Tune.SusCoilCount

				local swayBar = SuspensionGeometry:FindFirstChild("SwayBar")
				if swayBar and swayBar.Attachment0 and swayBar.Attachment1 then
					swayBar.Attachment0.Position = Vector3.new(
						swayBar.Attachment0.Parent.CFrame:ToObjectSpace(self:GetCenter()).Position.X - 0.05,
						0,
						0
					)
					swayBar.Attachment1.Position = Vector3.new(
						swayBar.Attachment1.Parent.CFrame:ToObjectSpace(self:GetCenter()).Position.X - 0.05,
						0,
						0
					)
					swayBar.Damping = 20
					swayBar.FreeLength = 0.1
				end
				if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
					sp.Damping = self.Tune.FSusDamping * 1000 * Units.Damping_N_sdivm
					sp.Stiffness = self.Tune.FSusStiffness * 9806.65 * Units.Stiffness_Ndivm -- 9806.65 converts kgf/mm to N/m
					sp.FreeLength = self.Tune.FSusLength + self.Tune.FPreCompress
					sp.MaxLength = self.Tune.FSusLength + self.Tune.FExtensionLim
					sp.MinLength = self.Tune.FSusLength - self.Tune.FCompressLim
					if swayBar then swayBar.Stiffness = self.Tune.FSwayBar * 9806.65 * Units.Stiffness_Ndivm end
				else
					sp.Damping = self.Tune.RSusDamping * 1000 * Units.Damping_N_sdivm
					sp.Stiffness = self.Tune.RSusStiffness * 9806.65 * Units.Stiffness_Ndivm
					sp.FreeLength = self.Tune.RSusLength + self.Tune.RPreCompress
					sp.MaxLength = self.Tune.RSusLength + self.Tune.RExtensionLim
					sp.MinLength = self.Tune.RSusLength - self.Tune.RCompressLim
					if swayBar then swayBar.Stiffness = self.Tune.RSwayBar * 9806.65 * Units.Stiffness_Ndivm end
				end
			else
				local legacyCFrame = v.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(90)) -- not gonna bother fixing the entire thing so i just put this because it works

				local sa = arm:Clone()
				sa.Parent = v
				sa.Name = "#SA"
				sa.CFrame = legacyCFrame * CFrame.Angles(-math.pi / 2, -math.pi / 2, 0)
				if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
					local aOff = self.Tune.FAnchorOffset
					sa.CFrame = legacyCFrame
						* CFrame.new(self.Tune.AxleSize / 2, -fDistX, -fDistY)
						* CFrame.new(aOff[3], aOff[1], -aOff[2])
						* CFrame.Angles(-math.pi / 2, -math.pi / 2, 0)
				else
					local aOff = self.Tune.RAnchorOffset
					sa.CFrame = legacyCFrame
						* CFrame.new(self.Tune.AxleSize / 2, -rDistX, -rDistY)
						* CFrame.new(aOff[3], aOff[1], -aOff[2])
						* CFrame.Angles(-math.pi / 2, -math.pi / 2, 0)
				end

				local sb = sa:Clone()
				sb.Parent = v
				sb.Name = "#SB"
				sb.CFrame = sa.CFrame * CFrame.new(0, 0, self.Tune.AxleSize)
				sb.FrontSurface = Enum.SurfaceType.Hinge

				local sf1 = Instance.new("Attachment")
				sf1.Name = "SAtt"
				sf1.Parent = sa

				local sf2 = sf1:Clone()
				sf2.Parent = sb

				--(Avxnturador) adds spring offset
				if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
					local aOff = self.Tune.FSpringOffset
					if v.Name == "FL" then
						sf1.Position = Vector3.new(
							fDistX - fSLX + aOff[1],
							-fDistY + fSLY + aOff[2],
							self.Tune.AxleSize / 2 + aOff[3]
						)
						sf2.Position =
							Vector3.new(fDistX + aOff[1], -fDistY + aOff[2], -self.Tune.AxleSize / 2 + aOff[3])
					else
						sf1.Position = Vector3.new(
							fDistX - fSLX + aOff[1],
							-fDistY + fSLY + aOff[2],
							self.Tune.AxleSize / 2 - aOff[3]
						)
						sf2.Position =
							Vector3.new(fDistX + aOff[1], -fDistY + aOff[2], -self.Tune.AxleSize / 2 - aOff[3])
					end
				elseif v.Name == "RL" or v.Name == "RR" or v.Name == "R" then
					local aOff = self.Tune.RSpringOffset
					if v.Name == "RL" then
						sf1.Position = Vector3.new(
							rDistX - rSLX + aOff[1],
							-rDistY + rSLY + aOff[2],
							self.Tune.AxleSize / 2 + aOff[3]
						)
						sf2.Position =
							Vector3.new(rDistX + aOff[1], -rDistY + aOff[2], -self.Tune.AxleSize / 2 + aOff[3])
					else
						sf1.Position = Vector3.new(
							rDistX - rSLX + aOff[1],
							-rDistY + rSLY + aOff[2],
							self.Tune.AxleSize / 2 - aOff[3]
						)
						sf2.Position =
							Vector3.new(rDistX + aOff[1], -rDistY + aOff[2], -self.Tune.AxleSize / 2 - aOff[3])
					end
				end

				sb:MakeJoints()
				--(LuaInt) there was axle:makejoints here I believe, but the new powered axle manually welds itself so I ditched it

				local sp = Instance.new("SpringConstraint")
				sp.Name = "Spring"
				sp.Attachment0 = sf1
				sp.Attachment1 = sf2
				sp.LimitsEnabled = true

				sp.Visible = self.Tune.SpringsVisible
				sp.Radius = self.Tune.SusRadius
				sp.Thickness = self.Tune.SusThickness
				sp.Color = self.Tune.SusColor
				sp.Coils = self.Tune.SusCoilCount

				sp.Parent = v

				if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
					sp.Damping = self.Tune.FSusDamping * 1000 * Units.Damping_N_sdivm
					sp.Stiffness = self.Tune.FSusStiffness * 9806.65 * Units.Stiffness_Ndivm
					sp.FreeLength = self.Tune.FSusLength + self.Tune.FPreCompress
					sp.MaxLength = self.Tune.FSusLength + self.Tune.FExtensionLim
					sp.MinLength = self.Tune.FSusLength - self.Tune.FCompressLim
				else
					sp.Damping = self.Tune.RSusDamping * 1000 * Units.Damping_N_sdivm
					sp.Stiffness = self.Tune.RSusStiffness * 9806.65 * Units.Stiffness_Ndivm
					sp.FreeLength = self.Tune.RSusLength + self.Tune.RPreCompress
					sp.MaxLength = self.Tune.RSusLength + self.Tune.RExtensionLim
					sp.MinLength = self.Tune.RSusLength - self.Tune.RCompressLim
				end

				MakeWeld(self.Instance.DriveSeat, sa)
				MakeWeld(sb, base)
			end
		else
			MakeWeld(self.Instance.DriveSeat, base)
		end

		--Lock Rear Steering Axle
		if (self.Tune.FWSteer == "Static" or self.Tune.FWSteer == "Speed" or self.Tune.FWSteer == "Both") == false then
			if v.Name == "RL" or v.Name == "RR" or v.Name == "R" then MakeWeld(base, axle) end
		end

		MakeWeld(arm, axle)

		--Weld Miscelaneous Parts
		if v:FindFirstChild("SuspensionFixed") ~= nil then ModelWeld(v.SuspensionFixed, self.Instance.DriveSeat) end
		if v:FindFirstChild("WheelFixed") ~= nil then ModelWeld(v.WheelFixed, axle) end
		if v:FindFirstChild("Fixed") ~= nil then ModelWeld(v.Fixed, arm) end

		--Weld Wheel Parts
		if v:FindFirstChild("Parts") ~= nil then ModelWeld(v.Parts, v) end

		--Add Steering Gyro
		if v:FindFirstChild("Steer") then v:FindFirstChild("Steer"):Destroy() end

		if
			(v.Name == "FR" or v.Name == "FL" or v.Name == "F")
			or (self.Tune.FWSteer == "Static" or self.Tune.FWSteer == "Speed" or self.Tune.FWSteer == "Both")
		then
			local steer
			if self.Tune.PowerSteeringType == "New" then
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
				if string.find(v.Name, "F") then
					steer.P = self.Tune.SteerP
					steer.D = self.Tune.SteerD
					steer.MaxTorque = Vector3.new(0, self.Tune.SteerMaxTorque, 0)
				else
					steer.P = self.Tune.RSteerP
					steer.D = self.Tune.RSteerD
					steer.MaxTorque = Vector3.new(0, self.Tune.RSteerMaxTorque, 0)
				end
			end
			steer.Name = "Steer"
			steer.CFrame = v.CFrame
			steer.Parent = v.Arm
		end

		--Add rotation constraint (Detomiks)
		local rotationAttachment0 = Instance.new("Attachment")
		rotationAttachment0.Name = "RotationAttachment0"
		rotationAttachment0.Position = Vector3.new(0, -self.Tune.AxleSize / 2, 0)
		rotationAttachment0.Orientation = Vector3.new(0, 0, 90)
		rotationAttachment0.Parent = base

		local rotationAttachment1 = Instance.new("Attachment")
		rotationAttachment1.Name = "RotationAttachment1"
		rotationAttachment1.Position = Vector3.new(0, self.Tune.AxleSize / 2, 0)
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
		AV.Parent = v
		AV.Attachment0 = Instance.new("Attachment")
		AV.Attachment0.Name = "AA"
		AV.Attachment0.Parent = v.AxleP
		AV.Attachment1 = Instance.new("Attachment")
		AV.Attachment1.Name = "AB"
		AV.Attachment1.Parent = v
		AV.Name = "#AV"
		AV.AngularVelocity = 0
		AV.MotorMaxTorque = 0

		local BV = Instance.new("HingeConstraint")
		BV.ActuatorType = "Motor"
		BV.Parent = v
		BV.Attachment0 = Instance.new("Attachment")
		BV.Attachment0.Parent = v.AxleP
		BV.Attachment0.Name = "BA"
		BV.Attachment1 = Instance.new("Attachment")
		BV.Attachment1.Name = "BB"
		BV.Attachment1.Parent = v
		BV.Name = "#BV"
		BV.AngularVelocity = 0
		if string.find(v.Name, "F") then
			BV.MotorMaxTorque = (self.Tune.PBrakeForce * 9.80665 * Units.Force_N) * self.Tune.PBrakeBias
		else
			BV.MotorMaxTorque = (self.Tune.PBrakeForce * 9.80665 * Units.Force_N) * (1 - self.Tune.PBrakeBias)
		end

		-- Attempt to fix wheel alignment issues
		if string.find(v.Name, "L") or v.Name == "R" or v.Name == "F" then
			AV.Attachment0.Orientation = Vector3.new(0, 180, 0)
			BV.Attachment0.Orientation = Vector3.new(0, 180, 0)
			AV.Attachment1.Orientation = Vector3.new(0, 180, 0)
			BV.Attachment1.Orientation = Vector3.new(0, 180, 0)
		end

		--Realign Caster
		if v.Name == "FL" then
			v.CFrame = v.CFrame * CFrame.Angles(math.rad(-self.Tune.FCaster), 0, 0)
		elseif v.Name == "FR" then
			v.CFrame = v.CFrame * CFrame.Angles(math.rad(self.Tune.FCaster), 0, 0)
		elseif v.Name == "RL" then
			v.CFrame = v.CFrame * CFrame.Angles(math.rad(-self.Tune.RCaster), 0, 0)
		elseif v.Name == "RR" then
			v.CFrame = v.CFrame * CFrame.Angles(math.rad(self.Tune.RCaster), 0, 0)
		end
	end
end

function ServerVehicle.ApplyWeight(self: ServerVehicle)
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

		--Create Weight Brick
		local weightB = Instance.new("Part")
		weightB.Name = "#Weight"
		weightB.Anchored = true
		weightB.CanCollide = false
		weightB.BrickColor = BrickColor.new("Really black")
		weightB.TopSurface = Enum.SurfaceType.Smooth
		weightB.BottomSurface = Enum.SurfaceType.Smooth
		if self.Tune.WBVisible then
			weightB.Transparency = 0.75
		else
			weightB.Transparency = 1
		end

		weightB.Size = Vector3.new(self.Tune.WeightBSize[1], self.Tune.WeightBSize[2], self.Tune.WeightBSize[3])
			/ Units.Length_mm
		local tdensity = (self.Tune.Weight * Units.Mass_kg - mass) / (weightB.Size.X * weightB.Size.Y * weightB.Size.Z) --fixed by denkodin
		weightB.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(tdensity, 0.01, 100), 0, 0, 0, 0)
		--Real life mass in pounds, converted to kg minus existing roblox mass converted to kg, divided by volume of the weight brick in cubic meters, divided by the density of water
		weightB.CFrame = (self.Instance.DriveSeat.CFrame - self.Instance.DriveSeat.Position + center)
			* CFrame.new(0, self.Tune.CGHeight, 0)
		weightB.Parent = self.Instance.Body

		--Density Cap
		if weightB.CustomPhysicalProperties.Density >= 100 then
			warn(
				"\n\t [VEHICLE]: Density too high for specified volume."
					.. "\n\t Current Density:\t"
					.. math.ceil(tdensity)
					.. "\n\t Max Density:\t"
					.. math.ceil(weightB.CustomPhysicalProperties.Density)
					.. "\n\t Increase weight brick size to compensate."
			)
		end
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

function ServerVehicle.CreateFlip(self: ServerVehicle)
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

function ServerVehicle.Finalize(self: ServerVehicle)
	ModelWeld(self.Instance.Body, self.Instance.DriveSeat)

	-- Unanchor
	for _, v in self.Instance:GetDescendants() do
		if v:IsA("BasePart") then v.Anchored = false end
	end
end

function ServerVehicle.InitializePlugins(self: ServerVehicle)
	for _, plugin in ReplicatedStorage.Shared.Vehicle.Plugins:GetChildren() do
		local pluginClass = require(plugin)
		if pluginClass and pluginClass.new then self.Plugins[plugin.Name] = pluginClass.new(self) end
	end
end

function ServerVehicle.RemoveCharacterWeight(self: ServerVehicle)
	--Get Seats
	local Seats = {}
	for _, v in self.Instance:GetDescendants() do
		if v:IsA("VehicleSeat") or v:IsA("Seat") then
			local seat = {}
			seat.Seat = v
			seat.Parts = {}
			table.insert(Seats, seat)
		end
	end

	-- Store Physical Properties/Remove Mass Function
	local function handleCharacter(character, tbl)
		for _, v in character:GetDescendants() do
			if v:IsA("BasePart") then
				table.insert(tbl, { v, v.Massless })
				v.Massless = true
			end
		end
	end

	-- Initialize Seats
	for _, v in Seats do
		v.Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local occupant = v.Seat.Occupant and v.Seat.Occupant.Parent
			if occupant then
				handleCharacter(occupant, v.Parts)
			else
				for _, entry in v.Parts do
					entry[1].Massless = entry[2]
				end
				table.clear(v.Parts)
			end
		end)
	end
end

-- TODO: Interface
function ServerVehicle.InitializeDriveSeat(self: ServerVehicle)
	-- Driver Sit
	self.Instance.DriveSeat.ChildAdded:Connect(function(child)
		if child.Name == "SeatWeld" and child:IsA("Weld") then
			local player = Players:GetPlayerFromCharacter(child.Part1.Parent)
			if not player then return end

			self.Instance.DriveSeat:SetNetworkOwner(player)

			-- local clone = interface:Clone()
			-- clone.Parent = player.PlayerGui
		end
	end)

	-- Driver Leave
	self.Instance.DriveSeat.ChildRemoved:Connect(function(child)
		if child.Name == "SeatWeld" and child:IsA("Weld") then
			if not self.Instance.DriveSeat.Parent then return end

			-- Remove Flip Force
			if self.Instance.DriveSeat:FindFirstChild("Flip") then
				if self.Tune.FlipType == "New" then
					self.Instance.DriveSeat.Flip.Enabled = false
				else
					self.Instance.DriveSeat.Flip.MaxTorque = 0
				end
			end

			for _, wheel in self.Instance.Wheels:GetChildren() do
				-- Apply handbrake
				if wheel:FindFirstChild("#BV") and self.Tune.ExitBrake then
					if string.find(wheel.Name, "F") then
						wheel["#BV"].MotorMaxTorque = (self.Tune.PBrakeForce * 9.80665 * Units.Force_N)
							* self.Tune.PBrakeBias
					else
						wheel["#BV"].MotorMaxTorque = (self.Tune.PBrakeForce * 9.80665 * Units.Force_N)
							* (1 - self.Tune.PBrakeBias)
					end
				end

				-- Remove wheel force
				if wheel:FindFirstChild("#AV") then
					wheel["#AV"].MotorMaxTorque = 0
					wheel["#AV"].AngularVelocity = 0
				end

				-- Readjust steering
				if wheel.Arm:FindFirstChild("Steer") then
					if self.Tune.PowerSteeringType == "New" then
						wheel.Arm.Steer.Attachment0.Orientation = Vector3.new(0, -wheel.Base.Rotate.CurrentAngle, 0)
					else
						wheel.Arm.Steer.CFrame = wheel.Base.CFrame
							* CFrame.Angles(0, math.rad(wheel.Base.Rotate.CurrentAngle), 0)
					end
				end
			end
		end
	end)
end

-- TODO: Driver mental breakdown bruh

return ServerVehicle
