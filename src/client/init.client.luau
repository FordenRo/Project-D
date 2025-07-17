--!nocheck

if not game:IsLoaded() then game.Loaded:Wait() end

task.wait(3)

for _, controller in script.Controllers:GetChildren() do
	if controller:IsA("ModuleScript") then require(controller) end
end
