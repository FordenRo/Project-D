local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then game.Loaded:Wait() end

for _, controller in ReplicatedStorage.Shared.Controllers:GetChildren() do
	if controller:IsA("ModuleScript") then task.spawn(function() local _ = require(controller) :: any end) end
end
