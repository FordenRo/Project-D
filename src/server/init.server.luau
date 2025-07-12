--!nocheck

for _, handler in script.Handlers:GetChildren() do
	if handler:IsA("ModuleScript") then require(handler) end
end
