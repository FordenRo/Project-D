if not game:IsLoaded() then game.Loaded:Wait() end

for _, controller in script.Controllers:GetChildren() do
	if controller:IsA("ModuleScript") then task.spawn(function() require(controller) end) end
end
