--!strict
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Slider = require(script.Parent.Slider)
local Tips = require(script.Parent.Tips)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)

local player = Players.LocalPlayer

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

export type LoadingScreen = {
	Instance: ScreenGui & {
		Content: Frame & {
			Slider: Frame,
			Asset: TextLabel,
			LoadingLabel: TextLabel,
			Version: TextLabel,
			Tip: TextLabel,
		},
	},
	Slider: Slider.Slider,

	SetCurrentAsset: (self: LoadingScreen, asset: string) -> (),
	SetProgress: (self: LoadingScreen, progress: number) -> (),
	Destroy: (self: LoadingScreen) -> (),
}

type LoadingScreenImpl = {
	trove: Trove.Trove,
} & LoadingScreen

function LoadingScreen.new(): LoadingScreen
	local self: LoadingScreenImpl = setmetatable({}, LoadingScreen) :: any

	self.Instance = ReplicatedFirst.LoadingScreen:Clone() :: any
	self.Instance.Parent = player.PlayerGui

	self.Slider = Slider.new(self.Instance.Content.Slider)

	self.Instance.Content.Version.Text =
		`<font transparency="0.35" size="10">VERSION:</font> sds`

	InitializeLoadingLabel(self)
	InitializeTips(self)

	self.trove = Trove.new()
	self.trove:AttachToInstance(self.Instance)

	return self
end

function InitializeLoadingLabel(self: LoadingScreenImpl)
	local t = 3
	self.trove:Add(task.spawn(function()
		task.wait(1)
		t = t < 3 and t + 1 or 0
		self.Instance.Content.LoadingLabel.Text = "Loading"
			.. string.sub("...", 1, t)
	end))
end

function InitializeTips(self: LoadingScreenImpl)
	self.trove:Add(task.spawn(function()
		local tip = Tips[math.random(1, #Tips)]
		self.Instance.Content.Tip.Text =
			`<font transparency="0.4">Tip:</font> {tip}`
		task.wait(4 + #tip / 20)
	end))
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

return table.freeze({ new = LoadingScreen.new })
