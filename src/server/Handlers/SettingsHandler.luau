local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsDataStore = DataStoreService:GetDataStore("PlayerSettings")
local KeybindsDataStore = DataStoreService:GetDataStore("PlayerKeybinds")

local RE = Instance.new("RemoteEvent")
RE.Name = "_SettingsRE"
RE.Parent = ReplicatedStorage

local RF = Instance.new("RemoteFunction")
RF.Name = "_SettingsRF"
RF.Parent = ReplicatedStorage

local Actions = {
	GetKeybinds = 0,
	GetSettings = 1,
	SaveKeybinds = 2,
	SaveSettings = 3,
}

local SettingsHandler = {}
SettingsHandler.__index = SettingsHandler

export type SettingsHandler = {}

function SettingsHandler.new(): SettingsHandler
	local self: SettingsHandler = setmetatable({}, SettingsHandler) :: any

	RF.OnServerInvoke = function(player: Player, action: number)
		local RFActions = {
			[Actions.GetKeybinds] = function()
				return KeybindsDataStore:GetAsync(player.UserId) or {}
			end,
			[Actions.GetSettings] = function()
				return SettingsDataStore:GetAsync(player.UserId) or {}
			end,
		}
		return RFActions[action]()
	end

	RE.OnServerEvent:Connect(
		function(player: Player, action: number, value: any)
			local actions = {
				[Actions.SaveKeybinds] = function()
					KeybindsDataStore:SetAsync(player.UserId, value)
				end,
				[Actions.SaveSettings] = function()
					SettingsDataStore:SetAsync(player.UserId, value)
				end,
			}
			actions[action]()
		end
	)

	return self
end

return SettingsHandler.new()
