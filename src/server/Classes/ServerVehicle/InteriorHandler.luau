local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MakeUtil = require(ReplicatedStorage.Shared.Utils.MakeUtil)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local InteriorHandler = {}
InteriorHandler.__index = InteriorHandler

export type InteriorHandler = typeof(setmetatable(
	{} :: {
		Vehicle: VehicleTypes.ServerVehicle,
	},
	InteriorHandler
))

function InteriorHandler.new(
	vehicle: VehicleTypes.ServerVehicle
): InteriorHandler
	local self: InteriorHandler = setmetatable({}, InteriorHandler) :: any

	self.Vehicle = vehicle

	local misc = self.Vehicle.Instance.Misc

	local steeringWheel = misc:FindFirstChild("SteeringWheel")
	if steeringWheel then
		MakeUtil.Motor(steeringWheel, self.Vehicle.Instance.DriveSeat)
		local parts = steeringWheel:FindFirstChild("Parts")
		if parts then MakeUtil.ModelWeld(parts, steeringWheel) end
	end

	local handbrake = misc:FindFirstChild("Handbrake")
	if handbrake then
		MakeUtil.Motor(handbrake, self.Vehicle.Instance.DriveSeat)
		local parts = handbrake:FindFirstChild("Parts")
		if parts then MakeUtil.ModelWeld(parts, handbrake) end
	end

	local pedals = misc:FindFirstChild("Pedals")
	if pedals then
		for _, pedal in pedals:GetChildren() do
			MakeUtil.Motor(pedal, self.Vehicle.Instance.DriveSeat)
			local parts = pedal:FindFirstChild("Parts")
			if parts then MakeUtil.ModelWeld(parts, pedal) end
		end
	end

	local gearLever = misc:FindFirstChild("GearLever")
	if gearLever then
		MakeUtil.Motor(gearLever, self.Vehicle.Instance.DriveSeat)
		local parts = gearLever:FindFirstChild("Parts")
		if parts then MakeUtil.ModelWeld(parts, gearLever) end
	end

	return self
end

return InteriorHandler
