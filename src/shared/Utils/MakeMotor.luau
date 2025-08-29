return function(part0: BasePart, part1: BasePart)
	local motor = Instance.new("Motor6D")
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C1 = part1.CFrame:Inverse() * part0.CFrame
	motor.Parent = part0

	return motor
end
