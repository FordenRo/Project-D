--!nocheck

for _, controller in script.Controllers:GetChildren() do
	if controller:IsA("ModuleScript") then require(controller) end
end
