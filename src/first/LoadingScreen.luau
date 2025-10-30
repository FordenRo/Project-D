local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Slider = require(script.Parent.Slider)
local Tips = require(script.Parent.Tips)

local player = Players.LocalPlayer

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

export type LoadingScreen = {
	Instance: {
		Content: {
			Slider: Frame,
			Asset: TextLabel,
			LoadingLabel: TextLabel,
			Version: TextLabel,
			Tip: TextLabel,
		} & Frame,
	} & ScreenGui,
	Slider: Slider.Slider,

	SetCurrentAsset: (self: LoadingScreen, asset: string) -> (),
	SetProgress: (self: LoadingScreen, progress: number) -> (),
	Destroy: (self: LoadingScreen) -> (),
}

type LoadingScreenImpl = {} & LoadingScreen

function LoadingScreen.new(): LoadingScreen
	local self: LoadingScreenImpl = setmetatable({}, LoadingScreen) :: any

	self.Instance = ReplicatedFirst.LoadingScreen:Clone() :: any
	self.Instance.Parent = player.PlayerGui

	self.Slider = Slider.new(self.Instance.Content.Slider)

	-- Initialize handlers
	local handlers = {
		LoadingLabelHandler(self),
		TipsHandler(self),
		VersionHandler(self),
	} :: { () -> ()? }

	self.Instance.Destroying:Connect(function()
		for _, v in handlers do
			if typeof(v) == "function" then v() end
		end
	end)

	return self
end

function LoadingLabelHandler(self: LoadingScreenImpl)
	local t = 3
	local thread = task.defer(function()
		task.wait(1)
		t = t < 3 and t + 1 or 0
		self.Instance.Content.LoadingLabel.Text = "Loading"
			.. string.sub("...", 1, t)
	end)
	return function() task.cancel(thread) end
end

function TipsHandler(self: LoadingScreenImpl)
	local thread = task.defer(function()
		local tip = Tips[math.random(1, #Tips)]
		self.Instance.Content.Tip.Text =
			`<font transparency="0.4">Tip:</font> {tip}`
		task.wait(4 + #tip / 20)
	end)
	return function() task.cancel(thread) end
end

function VersionHandler(self: LoadingScreenImpl)
	local versionLabel = self.Instance.Content.Version
	versionLabel.TextTransparency = 1

	local thread = task.defer(function()
		local GameConfig = require(
			ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig")
		)
		versionLabel.Text =
			`<font transparency="0.35" size="10">VERSION:</font> {GameConfig.Version}`
		TweenService
			:Create(versionLabel, TweenInfo.new(0.5), { TextTransparency = 0 })
			:Play()
	end)
	return function() task.cancel(thread) end
end

function LoadingScreen.SetCurrentAsset(
	self: LoadingScreenImpl,
	asset: string
)
	self.Instance.Content.Asset.Text = asset
end

function LoadingScreen.SetProgress(
	self: LoadingScreenImpl,
	progress: number
)
	self.Slider:SetProgress(progress)
end

function LoadingScreen.Destroy(self: LoadingScreenImpl) self.Instance:Destroy() end

function LoadingScreen.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == LoadingScreen
end

return table.freeze({
	new = LoadingScreen.new,
	Is = LoadingScreen.Is,
})
