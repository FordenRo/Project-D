local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local VehicleItem = {}
VehicleItem.__index = VehicleItem

export type VehicleItem = {
	__index: VehicleItem,
	Instance: TextButton & {
		Title: TextLabel,
		ViewportFrame: ViewportFrame,
		Owned: ImageLabel,
	},
	VehicleInstance: Model,
	OwnedId: string?,
	Name: string,
	Owned: boolean,
	IsSelected: boolean,
	Selected: RBXScriptSignal<()>,
	_SelectedEvent: BindableEvent,
	Deselected: RBXScriptSignal<()>,
	_DeselectedEvent: BindableEvent,

	new: (instance: TextButton, name: string) -> VehicleItem,
	SetOwned: (self: VehicleItem, owned: boolean) -> (),
	Select: (self: VehicleItem) -> (),
	Deselect: (self: VehicleItem) -> (),
}

function VehicleItem.new(instance: TextButton, name: string)
	local self: VehicleItem = setmetatable({}, VehicleItem) :: any

	local tune = require(ReplicatedStorage.Shared.Vehicle.Tunes[name]) :: VehicleTypes.Tune

	self.Instance = instance:Clone()
	self.Instance.Title.Text = tune.Title
	self.Instance.Visible = true

	self.Name = name
	self.OwnedId = nil
	self.Owned = false
	self.IsSelected = false

	self._SelectedEvent = Instance.new("BindableEvent")
	self.Selected = self._SelectedEvent.Event

	self._DeselectedEvent = Instance.new("BindableEvent")
	self.Deselected = self._DeselectedEvent.Event

	self.VehicleInstance = ReplicatedStorage.Vehicles[name]:Clone()
	self.VehicleInstance:PivotTo(
		CFrame.new(-2, 1, -12) * CFrame.fromOrientation(math.rad(-12), math.rad(-130), math.rad(-12))
	)
	self.VehicleInstance.Parent = self.Instance.ViewportFrame

	self.Instance.Activated:Connect(function() self:Select() end)

	return self
end

function VehicleItem.SetOwned(self: VehicleItem, owned: boolean)
	self.Owned = owned
	self.Instance.Owned.Visible = owned
end

function VehicleItem.Select(self: VehicleItem)
	if self.IsSelected then return end

	self.Instance.BackgroundTransparency = 0.7
	self.Instance.Interactable = false

	self._SelectedEvent:Fire()
end

function VehicleItem.Deselect(self: VehicleItem)
	if not self.IsSelected then return end

	self.Instance.BackgroundTransparency = 0.9
	self.Instance.Interactable = true

	self._DeselectedEvent:Fire()
end

return VehicleItem
