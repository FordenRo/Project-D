local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseWheel = require(ReplicatedStorage.Shared.Classes.BaseWheel)
local BrakeDisk = require(script.BrakeDisk)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Tire = require(script.Tire)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleConstants =
	require(ReplicatedStorage.Shared.Vehicle.VehicleConstants)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ClientWheel = setmetatable({}, BaseWheel)
ClientWheel.__index = ClientWheel

type ClientWheel = VehicleTypes.ClientWheel

type ClientWheelImpl = {
	collisionPart: Part,
	colliderPart: Part,
	collisionRayParams: RaycastParams,
} & ClientWheel

function ClientWheel.new(
	vehicle: VehicleTypes.ClientVehicle,
	instance: BasePart
): ClientWheel
	local self: ClientWheelImpl =
		setmetatable(BaseWheel.new(vehicle, instance), ClientWheel) :: any

	self.OppositeWheel = (
		(
			self.Instance.Name == "FL"
			and self.Vehicle.Instance.Wheels:FindFirstChild("FR")
		)
		or (self.Instance.Name == "FR" and self.Vehicle.Instance.Wheels:FindFirstChild(
			"FL"
		))
		or (self.Instance.Name == "RL" and self.Vehicle.Instance.Wheels:FindFirstChild(
			"RR"
		))
		or (
			self.Instance.Name == "RR"
			and self.Vehicle.Instance.Wheels:FindFirstChild("RL")
		)
	) :: BasePart

	self.CanSteer = 0
	self.Material = nil

	-- Check if can steer
	if
		self.Instance:FindFirstChild("Arm")
		and (self.Instance.Arm :: any):FindFirstChild("Steer")
	then
		self.CanSteer = 1
		if
			not ((self.Instance.Arm :: any).Steer :: Instance):GetAttribute(
				"SteerDisabled"
			)
		then
			self.CanSteer = 2
		end
	end

	self.Tire = Tire.new(self, self.Instance.Parts.Tire)
	self.BrakeDisk = BrakeDisk.new(self, self.Instance.Parts.BrakeDisk)

	InitializeCollision(self)

	local trove = Trove.new()
	trove:AttachToInstance(instance)

	local collisionConn: RBXScriptConnection?
	trove:Connect(self.Vehicle.DriverChanged, function()
		if self.Vehicle.IsDriven then
			collisionConn = trove:Connect(
				RunService.Stepped,
				function() UpdateCollision(self) end
			) :: any
		elseif collisionConn then
			collisionConn = collisionConn:Disconnect()
		end
	end)
	trove:Add(function()
		if collisionConn then collisionConn:Disconnect() end
	end)

	return self
end

function InitializeCollision(self: ClientWheelImpl)
	self.colliderPart = Instance.new("Part")
	self.colliderPart.Transparency = 1
	self.colliderPart.Anchored = true
	self.colliderPart.CollisionGroup = "Wheel"
	self.colliderPart.Size = Vector3.new(3, 1, 3)
	self.colliderPart.Parent = workspace

	self.collisionPart = self.Instance.Collision:Clone()
	self.collisionPart:ClearAllChildren()
	self.collisionPart.Name = "CastCollision"
	self.collisionPart.CanCollide = false
	self.collisionPart.CanQuery = false
	self.collisionPart.CanTouch = false
	self.collisionPart.Parent = self.Instance.Collision

	self.collisionRayParams = RaycastParams.new()
	self.collisionRayParams.FilterType = Enum.RaycastFilterType.Exclude
	self.collisionRayParams.FilterDescendantsInstances =
		{ self.colliderPart, self.Vehicle.Instance }

	self.Instance.Collision.CollisionGroup = "Wheel"
end

function ClientWheel.Update(self: ClientWheelImpl, deltaTime: number)
	ApplySteering(self, deltaTime)
end

function UpdateCollision(self: ClientWheelImpl)
	self.collisionPart.CFrame = self.Instance.Collision.CFrame
		+ self.Vehicle.CFrame.UpVector

	local ray = workspace:Shapecast(
		self.collisionPart,
		-self.Vehicle.CFrame.UpVector :: Vector3 * 3,
		self.collisionRayParams
	)
	if ray then
		local lookVector = ray.Normal:Cross(self.Instance.CFrame.RightVector)
		self.colliderPart.CFrame = CFrame.lookAlong(
			ray.Position
				- self.Vehicle.CFrame.UpVector :: Vector3
					* self.colliderPart.Size.Y
					/ 2,
			lookVector,
			ray.Normal
		)
		self.Material = (ray.Instance :: BasePart).Material
		if self.Tire.Material ~= "Road" then
			self.colliderPart.CFrame += ray.Normal * MathUtil.Noise(
				self.Instance.Position * 0.2
			) * 0.3
		end
	else
		self.colliderPart.CFrame = CFrame.new()
		self.Material = nil
	end
end

function ApplySteering(self: ClientWheelImpl, deltaTime: number)
	if self.CanSteer == 0 then return end

	local angle = 0
	local rsteerVariableAngle = 1
	if typeof(self.Vehicle.Steering) ~= "number" then return end

	local steerOuter = (self.Vehicle.Tune.LockToLock * 180)
		/ self.Vehicle.Tune.SteerRatio
	local steerInner = math.min(
		steerOuter - (steerOuter * (1 - self.Vehicle.Tune.Ackerman)),
		steerOuter * 1.2
	)

	if self.CanSteer == 2 then
		if self.Instance.Name == "FL" then
			angle = self.Vehicle.Steering < 0 and steerInner or steerOuter
		elseif self.Instance.Name == "FR" then
			angle = self.Vehicle.Steering < 0 and steerOuter or steerInner
		elseif self.Instance.Name == "F" then
			angle = steerInner
		elseif self.Instance.Name == "RL" then
			angle = self.Vehicle.Steering < 0 and self.Vehicle.Tune.RSteerInner
				or self.Vehicle.Tune.RSteerOuter
		elseif self.Instance.Name == "RR" then
			angle = self.Vehicle.Steering < 0 and self.Vehicle.Tune.RSteerOuter
				or self.Vehicle.Tune.RSteerInner
		elseif self.Instance.Name == "R" then
			angle = self.Vehicle.Tune.RSteerInner
		end
		if not self.IsFront then
			if self.Vehicle.Tune.FWSteer == "Static" then
				rsteerVariableAngle = -math.max(
					0,
					1
						- (
							self.Vehicle.Velocity.Magnitude
							/ self.Vehicle.Tune.RSteerSpeed
						)
				)
			elseif self.Vehicle.Tune.FWSteer == "Speed" then
				rsteerVariableAngle = math.min(
					1,
					(
						self.Vehicle.Velocity.Magnitude
						/ self.Vehicle.Tune.RSteerSpeed
					)
				)
			elseif self.Vehicle.Tune.FWSteer == "Both" then
				rsteerVariableAngle = -math.max(
					-1,
					1
						- (
							self.Vehicle.Velocity.Magnitude
							/ self.Vehicle.Tune.RSteerSpeed
						)
				)
			end
		end
	end

	if self.Vehicle.Tune.PowerSteeringType == "New" then
		self.Instance.Arm.SteerAttach0.Orientation = Vector3.new(
			0,
			self.CanSteer == 1 and 0
				or self.Vehicle.Steering * angle * rsteerVariableAngle,
			0
		)
	else
		(self.Instance.Arm.Steer :: BodyGyro).CFrame = self.Instance.Base.CFrame
			* (
				self.CanSteer == 1 and CFrame.new(0, 0, 0)
				or (
					CFrame.Angles(
						0,
						-math.rad(
							self.Vehicle.Steering * angle * rsteerVariableAngle
						),
						0
					)
				)
			)
	end
end

function ClientWheel.UpdateForces(
	self: ClientWheelImpl,
	torque: number,
	flywheelEnergy: number
)
	-- Apply Power
	local throttle = self.Vehicle.Engine.Throttle
	local brake = self.Vehicle.Engine.Brake
	local clutch = 1 - self.Vehicle.Engine.Clutch
	local wheelTorque = torque

	local spLimit = self.Vehicle.Engine.Tune.Redline
		/ (self.Vehicle.FinalDriveRatio * self.Vehicle.CurrentRatio)
	if self.Vehicle.CurrentRatio * self.Vehicle.FinalDriveRatio == 0 then
		spLimit = 0
	end -- Prevents [nan] from dividing by 0

	-- Apply ESC
	local torqueESC = 0
	if
		not (self.Instance.Name == "F" or self.Instance.Name == "R")
		and self.Vehicle.ESC
		and (self.Vehicle.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6))
			> self.Vehicle.Tune.ESCSpeed
	then
		local g = self.Vehicle.CFrame:VectorToObjectSpace(
			self.Vehicle.Acceleration
				/ Units.Velocity_mdivs
				/ (
					(
						VehicleConstants.GravComp > 0
							and VehicleConstants.GravComp
						or workspace.Gravity
					) * (Units.Length_mm / 1000)
				)
		)
		if math.sign(self.Vehicle.Steering) ~= math.sign(g.X) then
			local diff = self.Vehicle.Steering
				- (
					g.X
					* -math.sign(
						self.Vehicle.Center:VectorToObjectSpace(
							self.Vehicle.Velocity
						).Z
					)
				)
			if math.abs(diff) > self.Vehicle.Tune.ESCThreshold then
				local escVector, escBias = 1, (self.Vehicle.Tune.ESCVector + 1)
				if self.IsFront then
					escVector = escVector * (2 - escBias)
				else
					escVector = escVector * escBias
				end

				torqueESC = (self.IsRight and -1 or 1)
					* math.sign(diff)
					* escVector
				throttle = throttle
					+ (math.max(torqueESC, 0) - throttle)
						* (self.Vehicle.Tune.ESCThrottle / 100)
				brake = brake
					+ (-math.min(torqueESC, 0) - brake)
						* (self.Vehicle.Tune.ESCBrake / 100)
			end
		end
	end
	self.Vehicle.ESCActive = torqueESC ~= 0 or self.Vehicle.ESCActive

	-- Apply ABS
	local torqueABS = 1
	if self.Vehicle.ABS and brake > 0 then
		torqueABS = 1
			- (
				math.min(
					math.max(
						0,
						math.abs(
							self.Instance.AssemblyAngularVelocity.Magnitude
									* (self.Instance.Size.Y / 2)
									/ (Units.Velocity_mdivs / 3.6)
								- self.Instance.AssemblyLinearVelocity.Magnitude
									/ (Units.Velocity_mdivs / 3.6)
						) - self.Vehicle.Tune.ABSThreshold
					) / self.Vehicle.Tune.ABSGradient,
					1
				) * (1 - (self.Vehicle.Tune.ABSLimit / 100))
			)
	end
	self.Vehicle.ABSActive = torqueABS < 1 or self.Vehicle.ABSActive

	local PBrake = 0
	if self.Vehicle.PBrake == true or self.Vehicle.Gear == -2 then
		PBrake = 1
	else
		PBrake = 0
	end

	-- Apply Power
	if self.IsDriven then
		-- Differential/Torque-Vectoring
		local RRdiffMult = 1
		local RLdiffMult = 1
		local FRdiffMult = 1
		local FLdiffMult = 1

		if self.Instance.Name == "FR" then
			local avg = (
				(
					self.Instance.AssemblyAngularVelocity.Magnitude
					/ self.OppositeWheel.AssemblyAngularVelocity.Magnitude
				) - 1
			) * (self.Vehicle.Tune.FDiffPreload / 10)
			FRdiffMult = math.ceil(
				math.max(
					0,
					math.min(
						2,
						1
							- (
								(
									(self.Vehicle.Tune.FDiffPower / 100)
									* avg
									* self.Vehicle.Engine.Throttle
								)
								+ (
									(self.Vehicle.Tune.FDiffCoast / 100)
									* avg
									* (1 - self.Vehicle.Engine.Throttle)
								)
							)
					)
				) * 100
			) / 100
			FLdiffMult = 2 - FRdiffMult
		elseif self.Instance.Name == "FL" then
			local avg = (
				(
					self.Instance.AssemblyAngularVelocity.Magnitude
					/ self.OppositeWheel.AssemblyAngularVelocity.Magnitude
				) - 1
			) * (self.Vehicle.Tune.FDiffPreload / 10)
			FLdiffMult = math.ceil(
				math.max(
					0,
					math.min(
						2,
						1
							- (
								(
									(self.Vehicle.Tune.FDiffPower / 100)
									* avg
									* self.Vehicle.Engine.Throttle
								)
								+ (
									(self.Vehicle.Tune.FDiffCoast / 100)
									* avg
									* (1 - self.Vehicle.Engine.Throttle)
								)
							)
					)
				) * 100
			) / 100
			FRdiffMult = 2 - FLdiffMult
		elseif self.Instance.Name == "RR" then
			local avg = (
				(
					self.Instance.AssemblyAngularVelocity.Magnitude
					/ self.OppositeWheel.AssemblyAngularVelocity.Magnitude
				) - 1
			) * (self.Vehicle.Tune.RDiffPreload / 10)
			RRdiffMult = math.ceil(
				math.max(
					0,
					math.min(
						2,
						1
							- (
								(
									(self.Vehicle.Tune.RDiffPower / 100)
									* avg
									* self.Vehicle.Engine.Throttle
								)
								+ (
									(self.Vehicle.Tune.RDiffCoast / 100)
									* avg
									* (1 - self.Vehicle.Engine.Throttle)
								)
							)
					)
				) * 100
			) / 100
			RLdiffMult = 2 - RRdiffMult
		elseif self.Instance.Name == "RL" then
			local avg = (
				(
					self.Instance.AssemblyAngularVelocity.Magnitude
					/ self.OppositeWheel.AssemblyAngularVelocity.Magnitude
				) - 1
			) * (self.Vehicle.Tune.RDiffPreload / 10)
			RLdiffMult = math.ceil(
				math.max(
					0,
					math.min(
						2,
						1
							- (
								(
									(self.Vehicle.Tune.RDiffPower / 100)
									* avg
									* self.Vehicle.Engine.Throttle
								)
								+ (
									(self.Vehicle.Tune.RDiffCoast / 100)
									* avg
									* (1 - self.Vehicle.Engine.Throttle)
								)
							)
					)
				) * 100
			) / 100
			RRdiffMult = 2 - RLdiffMult
		end

		local fWCount = 0
		local rWCount = 0
		local drWCount = 0
		for _, wheel in self.Vehicle.Wheels :: { VehicleTypes.ClientWheel } do
			if wheel.IsDriven then
				drWCount += 1
			end
			if wheel.IsFront then
				fWCount += 1
			else
				rWCount += 1
			end
		end

		-- Apply torque split
		-- This takes the total amount of torque alotted to the front or rear wheels, then divides it by how many wheels there are
		local bias = (
			self.Vehicle.Tune.Drivetrain == "AWD"
			and (self.Vehicle.Tune.TorqueVector + 1) / 2
		)
			or (self.Vehicle.Tune.Drivetrain == "FWD" and 0)
			or 1
		wheelTorque = self.IsFront and (wheelTorque * (1 - bias)) / fWCount
			or (wheelTorque * bias) / rWCount

		-- Apply TCS
		local torqueTCS = 1
		if
			self.Vehicle.TCS
			and throttle > self.Vehicle.Engine.Tune.IdleThrottle / 100
		then
			torqueTCS = 1
				- (
					math.min(
						math.max(
							0,
							math.abs(
								self.Instance.AssemblyAngularVelocity.Magnitude
										* (self.Instance.Size.Y / 2)
										/ (Units.Velocity_mdivs / 3.6)
									- self.Instance.AssemblyLinearVelocity.Magnitude
										/ (Units.Velocity_mdivs / 3.6)
							) - self.Vehicle.Tune.TCSThreshold
						) / self.Vehicle.Tune.TCSGradient,
						1
					) * (1 - (self.Vehicle.Tune.TCSLimit / 100))
				)
		end
		self.Vehicle.TCSActive = torqueTCS < 1 or self.Vehicle.TCSActive

		-- Update Forces
		local outWheelTorque = (
			wheelTorque
			* 1.356
			* Units.Torque_nm
			* throttle
			* torqueTCS
			* clutch
		) + (math.max(flywheelEnergy, 0) / drWCount)

		if self.Instance.Name == "RR" then
			self.Instance.AV.MotorMaxTorque = outWheelTorque * RRdiffMult
		elseif self.Instance.Name == "RL" then
			self.Instance.AV.MotorMaxTorque = outWheelTorque * RLdiffMult
		elseif self.Instance.Name == "FR" then
			self.Instance.AV.MotorMaxTorque = outWheelTorque * FRdiffMult
		elseif self.Instance.Name == "FL" then
			self.Instance.AV.MotorMaxTorque = outWheelTorque * FLdiffMult
		else
			self.Instance.AV.MotorMaxTorque = outWheelTorque
		end
		self.Instance.AV.AngularVelocity = spLimit
			* math.sign(self.Vehicle.Gear)

		local brakeTorque = self.Vehicle.Tune.EBrakeForce
				* math.min(
					self.Vehicle.RPM / self.Vehicle.Engine.Tune.Redline,
					0.5
				)
				* (1 - throttle)
				* clutch
			- math.min(flywheelEnergy, 0) / drWCount
		if self.IsFront then
			brakeTorque += self.Vehicle.BrakeForce.Front * brake * torqueABS + self.Vehicle.PBrakeForce.Front * PBrake
		else
			brakeTorque += self.Vehicle.BrakeForce.Rear * brake * torqueABS + self.Vehicle.PBrakeForce.Rear * PBrake
		end
		self.Instance.BV.MotorMaxTorque = brakeTorque
	else
		self.Instance.AV.MotorMaxTorque = 0
		self.Instance.AV.AngularVelocity = 0
		if self.IsFront then
			self.Instance.BV.MotorMaxTorque = (
				self.Vehicle.BrakeForce.Front
				* brake
				* torqueABS
			) + (self.Vehicle.PBrakeForce.Front * PBrake)
		else
			self.Instance.BV.MotorMaxTorque = (
				self.Vehicle.BrakeForce.Rear
				* brake
				* torqueABS
			) + (self.Vehicle.PBrakeForce.Rear * PBrake)
		end
	end
end

function ClientWheel.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == ClientWheel
end

return table.freeze({
	new = ClientWheel.new,
	Is = ClientWheel.Is,
})
