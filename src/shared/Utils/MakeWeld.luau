type WeldType = "Weld" | "Motor"

return function(a: BasePart, b: BasePart, type: WeldType?, maxVelocity: number?)
	if not type then type = "Weld" end
	local W = Instance.new(type :: WeldType) :: Weld & Motor
	W.Part0 = a
	W.Part1 = b
	W.Parent = a

	W.C0 = a.CFrame:Inverse() * a.CFrame
	W.C1 = b.CFrame:Inverse() * a.CFrame

	if type == "Motor" and maxVelocity ~= nil then W.MaxVelocity = maxVelocity end
	return W
end
