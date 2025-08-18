local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseWindow = require(script.Parent.BaseWindow)

local ScreenGui = ReplicatedStorage.UI.Garage

local Garage = setmetatable({}, BaseWindow)
Garage.__index = Garage
Garage.Type = "Garage"

local Tab = {
	Owned = "Owned",
	Store = "Store",
}

export type Garage = {
	__index: Garage,

	new: () -> Garage,
	Initialize: (self: Garage) -> (),
} & BaseWindow.BaseWindow

function Garage.new()
	local self: Garage = setmetatable(BaseWindow.new(ScreenGui:Clone()), Garage) :: any

	self:Initialize()

	return self
end

function Garage.Initialize(self: Garage) self:SetTab(Tab.Owned) end

return Garage
