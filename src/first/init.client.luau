local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LoadingScreen = require(script.LoadingScreen)

local screen = LoadingScreen.new()

ReplicatedFirst:RemoveDefaultLoadingScreen()

if not game:IsLoaded() then game.Loaded:Wait() end

local assets = {} :: { { Name: string, Instance: Instance } }

for k, v in ReplicatedStorage.UI:GetChildren() do
	table.insert(assets, { Name = `UI/{v.Name}`, Instance = v })
end

for k, v in ReplicatedStorage.Vehicles:GetChildren() do
	table.insert(assets, { Name = `Vehicles/{v.Name}`, Instance = v })
end

local controllers = {}
for k, v in ReplicatedStorage.Shared.Controllers:GetChildren() do
	if v:IsA("ModuleScript") then table.insert(controllers, v) end
end

local count = #controllers + #assets

for k, v in assets do
	screen:SetCurrentAsset(v.Name)
	ContentProvider:PreloadAsync({ v.Instance })
	screen:SetProgress(k / count)
end

for k, v in controllers do
	local overrides = {
		InterfaceController = "Initializing UI",
		VehicleController = "Spawning vehicles",
	}
	screen:SetCurrentAsset(overrides[v.Name] or "Initializing scripts")
	local success, err = pcall(function() local _ = require(v) :: any end)
	screen:SetProgress((#assets + k) / count)

	if not success then warn(`Error loading {v.Name}: {err}`) end
end

task.wait(1)

screen:Destroy()

local InterfaceController =
	require(ReplicatedStorage.Shared.Controllers.InterfaceController)

InterfaceController.Visible = true
