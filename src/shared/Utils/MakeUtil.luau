--!strict
local MakeUtil = {}

function MakeUtil.Motor(part0: BasePart, part1: BasePart): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C1 = part1.CFrame:Inverse() * part0.CFrame
	motor.Parent = part0

	return motor
end

function MakeUtil.Wire(source: Instance, target: Instance): Wire
	local wire = Instance.new("Wire")
	wire.SourceInstance = source
	wire.TargetInstance = target
	wire.Parent = source

	return wire
end

function MakeUtil.Weld(part0: BasePart, part1: BasePart): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0

	return weld
end

function MakeUtil.ModelWeld(a: any, b: BasePart)
	if a:IsA("BasePart") then
		MakeUtil.Weld(b, a)
	elseif a:IsA("Model") then
		for _, v in a:GetChildren() do
			MakeUtil.ModelWeld(v, b)
		end
	end
end

return MakeUtil
