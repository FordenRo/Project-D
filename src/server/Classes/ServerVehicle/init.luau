local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelWeld = require(ReplicatedStorage.Shared.Utils.ModelWeld)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local Wheel = require(script.Wheel)

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

function ServerVehicle.InitializeVariables(self: ServerVehicle)
	local ParkingGearEnabled = self.Tune.Ratios[1] == 0
	self.Starting = false
	self.Occupant = nil
	self.Fuel = self.Tune.FuelCapacity
	self.Temperature = game.Workspace:GetAttribute("GlobalTemperature") :: number or 22
	self.FanSpeed = 0
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
	self.ABS = self.Tune.ABSEnabled
	self.ABSActive = false
	self.ESC = self.Tune.ESCEnabled and self.Tune.TCSEnabled
	self.ESCActive = false
	self.CS = self.Tune.CSEnabled
	self.CSActive = false
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
		if
			not v:IsA("BasePart")
			or not (
				v.Name == "FL"
				or v.Name == "FR"
				or v.Name == "F"
				or v.Name == "RL"
				or v.Name == "RR"
				or v.Name == "R"
			)
		then
			continue
		end

		local wheel = Wheel.new(self, v)
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
