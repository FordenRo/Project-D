local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local InteriorController = {}
InteriorController.__index = InteriorController

export type InteriorController = {
	__index: InteriorController,
	_cons: { RBXScriptConnection },
	Vehicle: VehicleTypes.ClientVehicle,
	Instance: Model & {
		Pedals: (Model & {
			Throttle: BasePart,
			Brake: BasePart,
			Clutch: BasePart,
		})?,
		Handbrake: BasePart?,
		SteeringWheel: BasePart?,
	},

	new: (vehicle: VehicleTypes.ClientVehicle) -> InteriorController,
	Destroy: (self: InteriorController) -> (),
}

function InteriorController.new(vehicle: VehicleTypes.ClientVehicle): InteriorController
	local self: InteriorController = setmetatable({}, InteriorController) :: any

	self.Vehicle = vehicle
	self.Instance = self.Vehicle.Instance.Body:FindFirstChild("Interior") :: any
	self._cons = {}
	if not self.Instance then
		warn(`Interior not found in {self.Vehicle.Instance.Name}`)
		return self
	end

	InitializeSteeringWheel(self)
	InitializePedals(self)
	InitializeHandbrake(self)
	InitializeGearLever(self)

	self.Vehicle.Instance.Destroying:Once(function() self:Destroy() end)

	return self
end

function InitializeSteeringWheel(self: InteriorController)
	local steeringWheel = self.Vehicle.Instance.Misc:FindFirstChild("SteeringWheel")
	if not steeringWheel then return end

	local motor = steeringWheel:FindFirstChildOfClass("Motor6D")
	if not motor then return end

	table.insert(
		self._cons,
		RunService.Heartbeat:Connect(
			function() motor.CurrentAngle = -self.Vehicle.Steering * self.Vehicle.Tune.LockToLock * math.pi end
		)
	)
end

function InitializeHandbrake(self: InteriorController)
	local handbrake = self.Vehicle.Instance.Misc:FindFirstChild("Handbrake")
	if not handbrake then return end

	local motor = handbrake:FindFirstChildOfClass("Motor6D")
	if not motor then return end

	local maxAngle = math.rad(handbrake:GetAttribute("MaxAngle"))
	table.insert(
		self._cons,
		RunService.Heartbeat:Connect(
			function(deltaTime)
				motor.CurrentAngle = Lerp(motor.CurrentAngle, self.Vehicle.PBrake and maxAngle or 0, deltaTime * 10)
			end
		)
	)
end

function InitializePedals(self: InteriorController)
	local pedals = self.Vehicle.Instance.Misc:FindFirstChild("Pedals")
	if not pedals then return end

	local angles = {}
	local motors = {}
	for _, pedal in pedals:GetChildren() do
		if not pedal:IsA("BasePart") then continue end

		angles[pedal.Name] = math.rad(pedal:GetAttribute("MaxAngle"))
		motors[pedal.Name] = pedal:FindFirstChildOfClass("Motor6D")
	end

	table.insert(
		self._cons,
		RunService.Heartbeat:Connect(function()
			motors.Throttle.CurrentAngle = self.Vehicle.Throttle * angles.Throttle
			motors.Brake.CurrentAngle = self.Vehicle.Brake * angles.Brake
			motors.Clutch.CurrentAngle = self.Vehicle.Clutch * angles.Clutch
		end)
	)
end

function InitializeGearLever(self: InteriorController)
	local gearLever = self.Vehicle.Instance.Misc:FindFirstChild("GearLever")
	if not gearLever then return end

	local motor = gearLever:FindFirstChildOfClass("Motor6D")
	if not motor then return end

	local xAngle = math.rad(gearLever:GetAttribute("MaxXAngle"))
	local yAngle = math.rad(gearLever:GetAttribute("MaxYAngle"))

	local function getPosition(gear)
		if gear == 0 then
			return 0, 0
		else
			return (math.floor((gear - 1) / 2) - 1) * xAngle, (gear % 2 == 1 and 1 or -1) * yAngle
		end
	end

	local function changeGear(gear, lastGear)
		local x, y = getPosition(gear)
		local lx = getPosition(lastGear)

		if lx ~= x then -- Centralize
			local tween = TweenService:Create(motor, TweenInfo.new(0.1), { Transform = CFrame.Angles(lx, 0, 0) })
			tween:Play()
			tween.Completed:Wait()
		end

		do -- Horizontal move
			local tween = TweenService:Create(motor, TweenInfo.new(0.1), { Transform = CFrame.Angles(x, 0, 0) })
			tween:Play()
			tween.Completed:Wait()
		end

		do -- Vertical move
			local tween = TweenService:Create(motor, TweenInfo.new(0.1), { Transform = CFrame.Angles(x, y, 0) })
			tween:Play()
			tween.Completed:Wait()
		end
	end

	local shifting = false
	local lastGear = 0
	table.insert(
		self._cons,
		RunService.Heartbeat:Connect(function(deltaTime)
			if shifting then return end

			local gear = self.Vehicle.Gear ~= -1 and self.Vehicle.Gear or (#self.Vehicle.Tune.Ratios - 1)
			if lastGear ~= gear then
				shifting = true
				changeGear(gear, lastGear)
				lastGear = gear
				shifting = false
			end
		end)
	)
end

function InteriorController.Destroy(self: InteriorController)
	for _, v in self._cons do
		v:Disconnect()
	end
end

return InteriorController
