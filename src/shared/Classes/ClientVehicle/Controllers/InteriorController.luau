local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local InteriorController = {}
InteriorController.__index = InteriorController

export type InteriorController = {
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
}

type InteriorControllerImpl = {
	trove: Trove.Trove,
} & InteriorController

function InteriorController.new(
	vehicle: VehicleTypes.ClientVehicle
): InteriorController
	local self: InteriorControllerImpl =
		setmetatable({}, InteriorController) :: any

	self.Vehicle = vehicle
	self.Instance = self.Vehicle.Instance.Body:FindFirstChild("Interior") :: any
	if not self.Instance then
		warn(`Interior not found in {self.Vehicle.Instance.Name}`)
		return self
	end

	self.trove = Trove.new()
	self.trove:AttachToInstance(self.Instance)

	InitializeSteeringWheel(self)
	InitializePedals(self)
	InitializeHandbrake(self)
	InitializeGearLever(self)

	return self
end

function InitializeSteeringWheel(self: InteriorControllerImpl)
	local steeringWheel =
		self.Vehicle.Instance.Misc:FindFirstChild("SteeringWheel")
	if not steeringWheel then return end

	local motor = steeringWheel:FindFirstChildOfClass("Motor6D")
	if not motor then return end

	self.trove:Connect(
		RunService.Heartbeat,
		function()
			motor.CurrentAngle = -self.Vehicle.Steering
				* self.Vehicle.Tune.LockToLock
				* math.pi
		end
	)
end

function InitializeHandbrake(self: InteriorControllerImpl)
	local handbrake = self.Vehicle.Instance.Misc:FindFirstChild("Handbrake")
	if not handbrake then return end

	local motor = handbrake:FindFirstChildOfClass("Motor6D")
	if not motor then return end

	local maxAngle = handbrake:GetAttribute("MaxAngle")
	assert(typeof(maxAngle) == "number")
	maxAngle = math.rad(maxAngle)

	self.trove:Connect(
		RunService.Heartbeat,
		function(deltaTime: number)
			motor.CurrentAngle = MathUtil.Lerp(
				motor.CurrentAngle,
				self.Vehicle.PBrake and maxAngle or 0,
				deltaTime * 10
			)
		end
	)
end

function InitializePedals(self: InteriorControllerImpl)
	local pedals = self.Vehicle.Instance.Misc:FindFirstChild("Pedals")
	if not pedals then return end

	local angles = {}
	local motors = {}
	for _, pedal in pedals:GetChildren() do
		if not pedal:IsA("BasePart") then continue end

		local maxAngle = pedal:GetAttribute("MaxAngle")
		assert(typeof(maxAngle) == "number")

		angles[pedal.Name] = math.rad(maxAngle)
		motors[pedal.Name] = assert(pedal:FindFirstChildOfClass("Motor6D"))
	end

	self.trove:Connect(RunService.Heartbeat, function()
		motors.Throttle.CurrentAngle = self.Vehicle.Throttle * angles.Throttle
		motors.Brake.CurrentAngle = self.Vehicle.Brake * angles.Brake
		motors.Clutch.CurrentAngle = self.Vehicle.Clutch * angles.Clutch
	end)
end

function InitializeGearLever(self: InteriorControllerImpl)
	local gearLever = self.Vehicle.Instance.Misc:FindFirstChild("GearLever")
	if not gearLever then return end

	local motor = gearLever:FindFirstChildOfClass("Motor6D")
	if not motor then return end

	local xAngle = gearLever:GetAttribute("MaxXAngle")
	local yAngle = gearLever:GetAttribute("MaxYAngle")
	assert(typeof(xAngle) == "number" and typeof(yAngle) == "number")
	xAngle = math.rad(xAngle)
	yAngle = math.rad(yAngle)

	local function getPosition(gear: number)
		if gear == 0 then
			return 0, 0
		else
			return (math.floor((gear - 1) / 2) - 1) * xAngle,
				(gear % 2 == 1 and 1 or -1) * yAngle
		end
	end

	local function changeGear(gear, lastGear)
		local x, y = getPosition(gear)
		local lx = getPosition(lastGear)

		if lx ~= x then -- Centralize
			local tween = TweenService:Create(
				motor,
				TweenInfo.new(0.1),
				{ Transform = CFrame.Angles(lx, 0, 0) }
			)
			tween:Play()
			tween.Completed:Wait()
		end

		do -- Horizontal move
			local tween = TweenService:Create(
				motor,
				TweenInfo.new(0.1),
				{ Transform = CFrame.Angles(x, 0, 0) }
			)
			tween:Play()
			tween.Completed:Wait()
		end

		do -- Vertical move
			local tween = TweenService:Create(
				motor,
				TweenInfo.new(0.1),
				{ Transform = CFrame.Angles(x, y, 0) }
			)
			tween:Play()
			tween.Completed:Wait()
		end
	end

	local shifting = false
	local lastGear = 0
	self.trove:Connect(RunService.Heartbeat, function()
		if shifting then return end

		local gear = self.Vehicle.Gear ~= -1 and self.Vehicle.Gear
			or (#self.Vehicle.Tune.Ratios - 1)
		if lastGear ~= gear then
			shifting = true
			changeGear(gear, lastGear)
			lastGear = gear
			shifting = false
		end
	end)
end

function InteriorController.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == InteriorController
end

return table.freeze({
	new = InteriorController.new,
	Is = InteriorController.Is,
})
