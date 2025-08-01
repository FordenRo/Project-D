--!nocheck

for _, handler in script.Handlers:GetChildren() do
	if handler:IsA("ModuleScript") then task.spawn(function() require(handler) end) end
end
