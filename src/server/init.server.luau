for _, handler in script.Handlers:GetChildren() do
	if handler:IsA("ModuleScript") then task.spawn(function() local _ = require(handler) :: any end) end
end
