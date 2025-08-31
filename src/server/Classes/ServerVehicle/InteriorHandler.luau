local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MakeMotor = require(ReplicatedStorage.Shared.Utils.MakeMotor)
local ModelWeld = require(ReplicatedStorage.Shared.Utils.ModelWeld)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local InteriorHandler = {}
InteriorHandler.__index = InteriorHandler

export type InteriorHandler = typeof(setmetatable(
	{} :: {
		Vehicle: VehicleTypes.ServerVehicle,
	},
	InteriorHandler
))

function InteriorHandler.new(vehicle: VehicleTypes.ServerVehicle): InteriorHandler
	local self: InteriorHandler = setmetatable({}, InteriorHandler) :: any

	self.Vehicle = vehicle

	local misc = self.Vehicle.Instance.Misc

	local steeringWheel = misc:FindFirstChild("SteeringWheel")
	if steeringWheel then
		MakeMotor(steeringWheel, self.Vehicle.Instance.DriveSeat)
		local parts = steeringWheel:FindFirstChild("Parts")
		if parts then ModelWeld(parts, steeringWheel) end
	end

	local handbrake = misc:FindFirstChild("Handbrake")
	if handbrake then
		MakeMotor(handbrake, self.Vehicle.Instance.DriveSeat)
		local parts = handbrake:FindFirstChild("Parts")
		if parts then ModelWeld(parts, handbrake) end
	end

	local pedals = misc:FindFirstChild("Pedals")
	if pedals then
		for _, pedal in pedals:GetChildren() do
			MakeMotor(pedal, self.Vehicle.Instance.DriveSeat)
			local parts = pedal:FindFirstChild("Parts")
			if parts then ModelWeld(parts, pedal) end
		end
	end

	local gearLever = misc:FindFirstChild("GearLever")
	if gearLever then
		MakeMotor(gearLever, self.Vehicle.Instance.DriveSeat)
		local parts = gearLever:FindFirstChild("Parts")
		if parts then ModelWeld(parts, gearLever) end
	end

	return self
end

return InteriorHandler
