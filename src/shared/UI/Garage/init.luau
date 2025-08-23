local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseWindow = require(script.Parent.BaseWindow)
local VehicleController = require(ReplicatedStorage.Shared.Controllers.VehicleController)
local VehicleItem = require(script.VehicleItem)

local ScreenGui = ReplicatedStorage.UI.Garage
local VehicleItemInstance = ScreenGui.VehicleItem

local Garage = setmetatable({}, BaseWindow)
Garage.__index = Garage
Garage.Type = "Garage"

local Tab = {
	Owned = "Owned",
	Store = "Store",
}

export type Garage = {
	__index: Garage,
	CurrentTab: keyof<typeof(Tab)>,
	SelectedStoreVehicle: string?,
	SelectedOwnedVehicle: string?,
	OwnedItems: { VehicleItem.VehicleItem },
	StoreItems: { VehicleItem.VehicleItem },

	new: () -> Garage,
	SelectOwnedVehicle: (self: Garage, id: string?) -> (),
	SelectStoreVehicle: (self: Garage, name: string?) -> (),
} & BaseWindow.BaseWindow

function Garage.new()
	local self: Garage = setmetatable(BaseWindow.new(ScreenGui:Clone()), Garage) :: any

	self.CurrentTab = nil
	self.SelectedStoreVehicle = nil
	self.SelectedOwnedVehicle = nil
	self.OwnedItems = {}
	self.StoreItems = {}

	Initialize(self)

	return self
end

function Initialize(self: Garage)
	InitializeOwned(self)
	InitializeStore(self)
	InitializeButtons(self)

	self:SetTab(Tab.Owned)
end

function Garage.SelectStoreVehicle(self: Garage, name: string?)
	for _, v in self.StoreItems do
		if v.Name == name then continue end

		v:Deselect()
	end

	self.SelectedStoreVehicle = name
	UpdateButtons(self)
end

function Garage.SelectOwnedVehicle(self: Garage, id: string?)
	for _, v in self.OwnedItems do
		if v.OwnedId == id then continue end

		v:Deselect()
	end

	self.SelectedOwnedVehicle = id
	UpdateButtons(self)
end

function InitializeOwned(self: Garage)
	local list = self.Instance.Window.Content.VehicleContent.Owned :: ScrollingFrame
	for _, v in VehicleController:GetVehicles() do
		v.Owned = true

		local item = VehicleItem.new(VehicleItemInstance, v.Name)
		item.OwnedId = v.ID
		item:SetOwned(true)
		item.Instance.Parent = list

		item.Selected:Connect(function() self:SelectOwnedVehicle(item.OwnedId) end)

		table.insert(self.OwnedItems, item)
	end
end

function InitializeStore(self: Garage)
	local list = self.Instance.Window.Content.VehicleContent.Store :: ScrollingFrame
	for _, v in ReplicatedStorage.Vehicles:GetChildren() do
		local owned = VehicleController:GetVehiclesByName(v.Name)[1] ~= nil

		local item = VehicleItem.new(VehicleItemInstance, v.Name)
		item:SetOwned(owned)
		item.Instance.Parent = list

		item.Selected:Connect(function() self:SelectStoreVehicle(item.Name) end)

		table.insert(self.StoreItems, item)
	end
end

function InitializeButtons(self: Garage) end

function UpdateButtons(self: Garage)
	local buttons = self.Instance.Window.Content.VehicleContent.Buttons :: Frame
	for _, v in buttons:GetChildren() do
		if not v:IsA("TextButton") then continue end

		v.Visible = false
	end

	if self.CurrentTab == "Store" then
		if not self.SelectedStoreVehicle then return end

		buttons.Buy.Visible = true
		buttons.TestDrive.Visible = true
	elseif self.CurrentTab == "Owned" then
		if not self.SelectedOwnedVehicle then return end

		buttons.Spawn.Visible = true
		buttons.Sell.Visible = true
	end
end

function Garage.SetTab(self: Garage, tab: string)
	self.CurrentTab = tab

	local tabs: Frame = self.Instance.Window.Upper.Tabs
	for _, v in tabs:GetChildren() do
		if not v:IsA("TextButton") then continue end

		v.Interactable = true
		v.TextTransparency = 0.5
		v.FontFace = Font.fromEnum(Enum.Font.SourceSans)
	end

	local tabButton = tabs:FindFirstChild(tab) :: TextButton
	tabButton.Interactable = false
	tabButton.TextTransparency = 0
	tabButton.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)

	local vehicleContent = self.Instance.Window.Content.VehicleContent :: Frame
	for _, v in vehicleContent:GetChildren() do
		if not v:IsA("ScrollingFrame") then continue end

		v.Visible = false
	end

	local content = vehicleContent[tab] :: ScrollingFrame
	content.Visible = true

	UpdateButtons(self)
end

return Garage
