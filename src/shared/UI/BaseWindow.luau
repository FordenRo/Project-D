local Players = game:GetService("Players")

local player = Players.LocalPlayer

local BaseWindow = {}
BaseWindow.__index = BaseWindow

export type BaseWindow = {
	__index: BaseWindow,
	Instance: ScreenGui & {
		Window: Frame & {
			Upper: Frame & {
				Close: TextButton,
				Tabs: Frame,
				Title: TextLabel,
			},
			Bottom: Frame,
			Content: Frame | ScrollingFrame,
		},
	},
	Type: string,

	new: (instance: ScreenGui) -> BaseWindow,
	SetTab: (self: BaseWindow, tab: string) -> (),
	IsA: (self: BaseWindow, type: string) -> boolean,
	Destroy: (self: BaseWindow) -> (),
}

function BaseWindow.new(instance: ScreenGui): BaseWindow
	local self: BaseWindow = setmetatable({}, BaseWindow) :: any

	self.Instance = instance
	self.Instance.Parent = player.PlayerGui

	local close = self.Instance.Window.Upper:FindFirstChild("Close") :: TextButton?
	if close then close.Activated:Connect(function() self:Destroy() end) end

	local tabs: Frame = self.Instance.Window.Upper.Tabs
	for _, v in tabs:GetChildren() do
		if not v:IsA("TextButton") then continue end

		v.Activated:Connect(function() self:SetTab(v.Name) end)
	end

	return self
end

function BaseWindow.SetTab(self: BaseWindow, tab: string)
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

	for _, v: Frame in self.Instance.Window.Content:GetChildren() do
		v.Visible = false
	end
	(self.Instance.Window.Content:FindFirstChild(tab) :: Frame).Visible = true
end

function BaseWindow.IsA(self: BaseWindow, type: string) return self.Type == type end

function BaseWindow.Destroy(self: BaseWindow) self.Instance:Destroy() end

return BaseWindow
