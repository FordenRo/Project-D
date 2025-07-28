local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local ScreenGui = ReplicatedStorage.UI.Garage
local player = Players.LocalPlayer

local Garage = {}
Garage.__index = Garage
Garage.Type = "Garage"

export type Garage = typeof(setmetatable(
	{} :: {
		Instance: Types.WindowInstance,
		Type: "Garage",
	},
	Garage
))

function Garage.new()
	local self: Garage = setmetatable({}, Garage) :: any

	self.Instance = ScreenGui:Clone()
	self.Instance.Parent = player.PlayerGui

	return self
end

function Garage.Initialize(self: Garage)
	self.Instance.Window.Upper.Close.Activated:Connect(function() self:Destroy() end)
end

function Garage.IsA(self: Garage, type: string) return self.Type == type end

function Garage.Destroy(self: Garage) self.Instance:Destroy() end

return Garage
