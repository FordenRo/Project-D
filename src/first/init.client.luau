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

local count = 0
for k, v in assets do
	count += 1
end

for k, v in assets do
	screen:SetCurrentAsset(v.Name)
	ContentProvider:PreloadAsync({ v.Instance })
	screen:SetProgress(k / count)
end

screen:Destroy()
