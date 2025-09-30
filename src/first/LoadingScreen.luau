local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Slider = require(script.Parent.Slider)
local Tips = require(script.Parent.Tips)

local player = Players.LocalPlayer

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

export type LoadingScreen = typeof(setmetatable(
	{} :: {
		_tasks: { thread },
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
	},
	LoadingScreen
))

function LoadingScreen.new(): LoadingScreen
	local self: LoadingScreen = setmetatable({}, LoadingScreen) :: any

	self.Instance = ReplicatedFirst.LoadingScreen:Clone()
	self.Instance.Parent = player.PlayerGui
	self._tasks = {}

	self.Slider = Slider.new(self.Instance.Content.Slider)

	self.Instance.Content.Version.Text =
		`<font transparency="0.35" size="10">VERSION:</font> sds`

	InitializeLoadingLabel(self)
	InitializeTips(self)

	return self
end

function InitializeLoadingLabel(self: LoadingScreen)
	local t = 3
	table.insert(
		self._tasks,
		task.spawn(function()
			task.wait(1)
			t = t < 3 and t + 1 or 0
			self.Instance.Content.LoadingLabel.Text = "Loading"
				.. string.sub("...", 1, t)
		end)
	)
end

function InitializeTips(self: LoadingScreen)
	table.insert(
		self._tasks,
		task.spawn(function()
			local tip = Tips[math.random(1, #Tips)]
			self.Instance.Content.Tip.Text =
				`<font transparency="0.4">Tip:</font> {tip}`
			task.wait(4 + #tip / 20)
		end)
	)
end

function LoadingScreen.SetCurrentAsset(self: LoadingScreen, asset: string)
	self.Instance.Content.Asset.Text = asset
end

function LoadingScreen.SetProgress(self: LoadingScreen, progress: number)
	self.Slider:SetProgress(progress)
end

function LoadingScreen.Destroy(self: LoadingScreen)
	for _, t in self._tasks do
		task.cancel(t)
	end
	self.Slider:Destroy()
	self.Instance:Destroy()
end

return LoadingScreen
