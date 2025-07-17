local MakeWeld = require(script.Parent.MakeWeld)

function ModelWeld(a, b)
	if a:IsA("BasePart") then
		MakeWeld(b, a, "Weld")
	elseif a:IsA("Model") then
		for _, v in a:GetChildren() do
			ModelWeld(v, b)
		end
	end
end

return ModelWeld
