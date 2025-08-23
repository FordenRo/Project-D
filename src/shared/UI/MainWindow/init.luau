local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITypes = require(ReplicatedStorage.Shared.Types.UITypes)

local player = Players.LocalPlayer

local MainWindow = {}
MainWindow.__index = MainWindow

local SwitchTweenInfo = TweenInfo.new(0.2)
local OpenTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
local CloseTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)

type TabBarButton = TextButton & {
	TabLabel: Frame & {
		Icon: ImageLabel,
		Title: TextLabel,
	},
	TabSelection: Frame,
}

type MainWindow = UITypes.MainWindow

function MainWindow.new()
	local self: MainWindow = setmetatable({}, MainWindow) :: any

	self.Instance = ReplicatedStorage.UI.MainWindow:Clone()
	self.Instance.Enabled = false
	self.Instance.Window.Position = UDim2.fromScale(0.5, 1.5)
	self.Instance.Background.BackgroundTransparency = 1
	self.Instance.Parent = player.PlayerGui

	self._TabPositions = {}
	for _, content in self.Instance.Window.Content:GetChildren() do
		if not content:IsA("ScrollingFrame") then continue end

		self._TabPositions[content] = content.Position.X.Scale
	end

	self._TabModules = {}
	self._cons = {}
	self.CurrentTab = nil
	self.Visible = false

	Initialize(self)

	return self
end

function Initialize(self: MainWindow)
	for _, button in self.Instance.Window.TabBar.Container:GetChildren() do
		if not button:IsA("TextButton") then continue end

		table.insert(
			self._cons,
			button.Activated:Connect(function()
				local tab = string.gsub(button.Name, "Tab", "")
				self:SetTab(tab)
			end)
		)
	end

	table.insert(self._cons, self.Instance.Background.Activated:Connect(function() self:Hide() end))
end

function MainWindow.Show(self: MainWindow, tab: string?)
	if self.Visible then
		if tab then self:SetTab(tab) end
		return
	end

	self.Visible = true
	self.Instance.Enabled = true

	local tween = TweenService:Create(self.Instance.Window, OpenTweenInfo, { Position = UDim2.fromScale(0.5, 0.5) })
	tween.Completed:Once(function() tween:Destroy() end)
	tween:Play()

	local bgTween = TweenService:Create(self.Instance.Background, OpenTweenInfo, { BackgroundTransparency = 0.5 })
	bgTween.Completed:Once(function() tween:Destroy() end)
	bgTween:Play()

	task.delay(0.3, function()
		self:SetTab("Welcome", true)
		if tab then self:SetTab(tab) end
	end)
end

function MainWindow.Hide(self: MainWindow)
	if not self.Visible then return end
	self.Visible = false

	local tween = TweenService:Create(self.Instance.Window, CloseTweenInfo, { Position = UDim2.fromScale(0.5, 1.5) })
	tween.Completed:Once(function()
		self.Instance.Enabled = false
		tween:Destroy()
	end)
	tween:Play()

	self.Instance.Background.BackgroundTransparency = 1
end

function MainWindow.SetTab(self: MainWindow, tab: string, skipAnim: boolean?)
	if self.CurrentTab == tab then return end
	local lastTab = self.CurrentTab
	self.CurrentTab = tab

	for _, button in self.Instance.Window.TabBar.Container:GetChildren() :: { TabBarButton } do
		if not button:IsA("TextButton") then continue end

		button.TabLabel.Title.TextTransparency = 0.5
		button.TabLabel.Icon.ImageTransparency = 0.5
		button.TabSelection.Visible = false
		button.Interactable = true
	end

	local tabButton = self.Instance.Window.TabBar.Container:FindFirstChild(tab .. "Tab") :: TabBarButton
	tabButton.TabLabel.Title.TextTransparency = 0
	tabButton.TabLabel.Icon.ImageTransparency = 0
	tabButton.TabSelection.Visible = true
	tabButton.Interactable = false

	if not self._TabModules[tab] then
		local tabModule = require(script:FindFirstChild(tab .. "Tab")) :: any
		self._TabModules[tab] = tabModule.new(self.Instance.Window.Content:FindFirstChild(tab))
	end

	for tabContent: ScrollingFrame, position in self._TabPositions do
		tabContent.Visible = tabContent.Name == lastTab or tabContent.Name == tab

		local newPosition = UDim2.fromScale(position - tabButton.LayoutOrder, 0)
		if skipAnim then
			tabContent.Position = newPosition
			continue
		end
		local tween = TweenService:Create(tabContent, SwitchTweenInfo, { Position = newPosition })
		tween.Completed:Once(function()
			if tabContent.Name == lastTab then tabContent.Visible = false end
			tween:Destroy()
		end)
		tween:Play()
	end
end

function MainWindow.Destroy(self: MainWindow)
	for _, con in self._cons do
		con:Disconnect()
	end
	for _, tabModule in self._TabModules do
		tabModule:Destroy()
	end
	self.Instance:Destroy()
end

return MainWindow
