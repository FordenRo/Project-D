local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

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

type LoadingScreenImpl = {
	tasks: { thread },
} & LoadingScreen

function LoadingScreen.new(): LoadingScreen
	local self: LoadingScreenImpl = setmetatable({}, LoadingScreen) :: any

	self.Instance = ReplicatedFirst.LoadingScreen:Clone() :: any
	self.Instance.Parent = player.PlayerGui

	self.Slider = Slider.new(self.Instance.Content.Slider)

	self.Instance.Content.Version.Text =
		`<font transparency="0.35" size="10">VERSION:</font> sds`

	self.tasks = {}

	InitializeLoadingLabel(self)
	InitializeTips(self)

	self.Instance.Destroying:Connect(function()
		for _, v in self.tasks do
			task.cancel(v)
		end
	end)

	return self
end

function InitializeLoadingLabel(self: LoadingScreenImpl)
	local t = 3
	table.insert(
		self.tasks,
		task.spawn(function()
			task.wait(1)
			t = t < 3 and t + 1 or 0
			self.Instance.Content.LoadingLabel.Text = "Loading"
				.. string.sub("...", 1, t)
		end)
	)
end

function InitializeTips(self: LoadingScreenImpl)
	table.insert(
		self.tasks,
		task.spawn(function()
			local tip = Tips[math.random(1, #Tips)]
			self.Instance.Content.Tip.Text =
				`<font transparency="0.4">Tip:</font> {tip}`
			task.wait(4 + #tip / 20)
		end)
	)
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
