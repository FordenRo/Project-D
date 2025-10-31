local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Shared.Enums)

local SettingsDataStore = DataStoreService:GetDataStore("PlayerSettings")
local KeybindsDataStore = DataStoreService:GetDataStore("PlayerKeybinds")

local RE = Instance.new("RemoteEvent")
RE.Name = "_SettingsRE"
RE.Parent = ReplicatedStorage

local RF = Instance.new("RemoteFunction")
RF.Name = "_SettingsRF"
RF.Parent = ReplicatedStorage

local SettingsHandler = {}
SettingsHandler.__index = SettingsHandler

export type SettingsHandler = {}

function SettingsHandler.new(): SettingsHandler
	local self: SettingsHandler = setmetatable({}, SettingsHandler) :: any

	RF.OnServerInvoke = function(player: Player, action: number)
		local actions = {
			[Enums.SettingsAction.GetKeybinds] = function()
				return KeybindsDataStore:GetAsync(tostring(player.UserId)) or {}
			end,
			[Enums.SettingsAction.GetSettings] = function()
				return SettingsDataStore:GetAsync(tostring(player.UserId)) or {}
			end,
		}
		return actions[action]()
	end

	RE.OnServerEvent:Connect(
		function(player: Player, action: number, value: any)
			local actions = {
				[Enums.SettingsAction.SaveKeybinds] = function()
					KeybindsDataStore:SetAsync(tostring(player.UserId), value)
				end,
				[Enums.SettingsAction.SaveSettings] = function()
					SettingsDataStore:SetAsync(tostring(player.UserId), value)
				end,
			}
			actions[action]()
		end
	)

	return self
end

return SettingsHandler.new()
