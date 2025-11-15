--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Component = require(ReplicatedStorage.Shared.Classes.Component)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)

local IdentifiedInvokeCallbacks = {} :: { [string]: (...any) -> ...any }

local RE, URE, RF
if RunService:IsServer() then
	RE = Instance.new("RemoteEvent")
	RE.Name = "RComponentRE"
	RE.Parent = ReplicatedStorage

	URE = Instance.new("UnreliableRemoteEvent")
	URE.Name = "RComponentURE"
	URE.Parent = ReplicatedStorage

	RF = Instance.new("RemoteFunction")
	RF.Name = "RComponentRF"
	RF.Parent = ReplicatedStorage

	RF.OnServerInvoke = function(player: Player, id: string, ...)
		if not IdentifiedInvokeCallbacks[id] then return end

		IdentifiedInvokeCallbacks[id](player, ...)
	end
else
	RE = ReplicatedStorage:WaitForChild("RComponentRE") :: RemoteEvent
	URE =
		ReplicatedStorage:WaitForChild("RComponentURE") :: UnreliableRemoteEvent
	RF = ReplicatedStorage:WaitForChild("RComponentRF") :: RemoteFunction

	RF.OnClientInvoke = function(id: string, ...)
		if not IdentifiedInvokeCallbacks[id] then return end

		IdentifiedInvokeCallbacks[id](...)
	end
end

--[[ TYPES ]]

-- BASE TYPES

type Client = {
	SendData: (self: Client, context: string, data: any) -> (),
	GetDataReceivedSignal: (
		self: Client,
		context: string
	) -> Signal.Signal<any>,
	InvokeData: (self: Client, context: string, ...any) -> ...any,
	RegisterDataInvokation: (
		self: Client,
		context: string,
		callback: (...any) -> ...any
	) -> (),
} & Component.Component

type Server = {
	SendData: ((self: Server, context: string, data: any) -> ()) & ((
		self: Server,
		player: Player,
		context: string,
		data: any
	) -> ()) & ((
		self: Server,
		players: { Player },
		context: string,
		data: any
	) -> ()),
	GetDataReceivedSignal: ((
		self: Server,
		player: Player,
		context: string
	) -> Signal.Signal<any>) & ((
		self: Server,
		context: string
	) -> Signal.Signal<Player, any>),
	InvokeData: (
		self: Server,
		player: Player,
		context: string,
		...any
	) -> ...any,
	RegisterDataInvokation: ((
		self: Server,
		player: Player,
		context: string,
		callback: (...any) -> ...any
	) -> ()) & ((
		self: Server,
		context: string,
		callback: (player: Player, ...any) -> ...any
	) -> ()),
} & Component.Component

type ClientImpl = {
	dataReceivedSignals: { [string]: Signal.Signal<any> },
	dataInvokationCallbacks: { [string]: { (...any) -> ...any } },

	fire: (
		self: ClientImpl,
		context: string,
		data: any,
		unreliable: boolean?
	) -> (),
	invoke: (self: ClientImpl, context: string, ...any) -> ...any,
}

type ServerImpl = {
	dataPlayerReceivedSignals: { [string]: { [Player]: Signal.Signal<any> } },
	dataReceivedSignals: { [string]: Signal.Signal<Player, any> },
	dataPlayerInvokationCallbacks: {
		[string]: { [Player]: { (...any) -> ...any } },
	},
	dataInvokationCallbacks: { [string]: { (...any) -> ...any } },

	fire: ((
		self: ServerImpl,
		player: Player,
		context: string,
		data: any,
		unreliable: boolean?
	) -> ()) & ((
		self: ServerImpl,
		context: string,
		data: any,
		unreliable: boolean?
	) -> ()),
	invoke: (
		self: ServerImpl,
		player: Player,
		context: string,
		...any
	) -> ...any,
}

-- IDENTIFIED TYPES

export type IdentifiedClient = { Id: string } & Client

export type IdentifiedServer = { Id: string } & Server

type IdentifiedClientImpl = IdentifiedClient & ClientImpl

type IdentifiedServerImpl = IdentifiedServer & ServerImpl

-- INSTANCED TYPES

export type InstancedClient = { Instance: Instance } & Client

export type InstancedServer = { Instance: Instance } & Server

type InstancedImpl = {
	RE: RemoteEvent,
	URE: UnreliableRemoteEvent,
	RF: RemoteFunction,
}

type InstancedClientImpl = InstancedClient & ClientImpl & InstancedImpl

type InstancedServerImpl = InstancedServer & ServerImpl & InstancedImpl

--[[ BASE CLIENT CLASS ]]

local BaseClientComponent = {}
BaseClientComponent.__extends = Component

function BaseClientComponent.SendData(
	self: ClientImpl,
	context: string,
	data: any,
	unrealiable: boolean?
)
	self:fire(context, data, unrealiable)
end

function BaseClientComponent.GetDataReceivedSignal(
	self: ClientImpl,
	context: string
)
	if not self.dataReceivedSignals[context] then
		self.dataReceivedSignals[context] = Signal.new()
	end

	return self.dataReceivedSignals[context]
end

function BaseClientComponent.InvokeData(
	self: ClientImpl,
	context: string,
	...
)
	return self:invoke(context, ...)
end

function BaseClientComponent.RegisterDataInvokation(
	self: ClientImpl,
	context: string,
	callback: (...any) -> ...any
)
	if not self.dataInvokationCallbacks[context] then
		self.dataInvokationCallbacks[context] = {}
	end

	table.insert(self.dataInvokationCallbacks[context], callback)
end

--[[ BASE SERVER CLASS ]]

local BaseServerComponent = {}
BaseServerComponent.__extends = Component

function BaseServerComponent.SendData(
	self: ServerImpl,
	target: Player | { Player } | string,
	context: string,
	data: any,
	unrealiable: boolean?
)
	if typeof(target) == "string" then
		data = context
		context = target

		self:fire(context, data, unrealiable)
	elseif typeof(target) == "table" then
		for _, player: Player in target do
			self:fire(player, context, data, unrealiable)
		end
	elseif typeof(target) == "Player" then
		self:fire(target, context, data, unrealiable)
	end
end

function BaseServerComponent.GetDataReceivedSignal(
	self: ServerImpl,
	player: Player | string,
	context: string
)
	if typeof(player) == "string" then
		context = player
		if not self.dataReceivedSignals[context] then
			self.dataReceivedSignals[context] = Signal.new()
		end

		return self.dataReceivedSignals[context]
	else
		if not self.dataPlayerReceivedSignals[context] then
			self.dataPlayerReceivedSignals[context] = {}
		end

		if not self.dataPlayerReceivedSignals[context][player] then
			self.dataPlayerReceivedSignals[context][player] = Signal.new()
		end

		return self.dataPlayerReceivedSignals[context][player]
	end
end

function BaseServerComponent.InvokeData(
	self: ServerImpl,
	player: Player,
	context: string,
	...
)
	return self:invoke(player, context, ...)
end

function BaseServerComponent.RegisterDataInvokation(
	self: ServerImpl,
	player: Player | string,
	context: string,
	callback: (...any) -> ...any
)
	if typeof(player) == "string" then
		callback = context :: any
		context = player

		if not self.dataInvokationCallbacks[context] then
			self.dataInvokationCallbacks[context] = {}
		end

		table.insert(self.dataInvokationCallbacks[context], callback)
	else
		if not self.dataPlayerInvokationCallbacks[context] then
			self.dataPlayerInvokationCallbacks[context] = {}
		end

		if not self.dataPlayerInvokationCallbacks[context][player] then
			self.dataPlayerInvokationCallbacks[context][player] = {}
		end

		table.insert(
			self.dataPlayerInvokationCallbacks[context][player],
			callback
		)
	end
end

--[[ IDENTIFIED CLIENT CLASS ]]

local IdentifiedClientComponent = {}
IdentifiedClientComponent.__extends = BaseClientComponent

function IdentifiedClientComponent.new(id: string): IdentifiedClient
	local self: IdentifiedClientImpl =
		Component(IdentifiedClientComponent) :: any

	self.Id = id
	self.dataReceivedSignals = {}

	local function eventFunc(id: string, context: string, data: any)
		if self.Id ~= id then return end
		if not self.dataReceivedSignals[context] then return end

		self.dataReceivedSignals[context]:Fire(data)
	end

	RE.OnClientEvent:Connect(eventFunc)
	URE.OnClientEvent:Connect(eventFunc)

	IdentifiedInvokeCallbacks[self.Id] = function(context: string, ...)
		if not self.dataInvokationCallbacks[context] then return end

		for _, v in self.dataInvokationCallbacks[context] do
			return v(...)
		end
	end

	return self
end

function IdentifiedClientComponent.fire(
	self: IdentifiedClientImpl,
	context: string,
	data: any,
	unreliable: boolean?
)
	if unreliable then
		URE:FireServer(self.Id, context, data)
	else
		RE:FireServer(self.Id, context, data)
	end
end

function IdentifiedClientComponent.invoke(
	self: IdentifiedClientImpl,
	context: string,
	...
)
	return RF:InvokeServer(self.Id, context, ...)
end

function IdentifiedClientComponent.Is(obj: any)
	return typeof(obj) == "table"
		and getmetatable(obj) == IdentifiedClientComponent
end

--[[ IDENTIFIED SERVER CLASS ]]

local IdentifiedServerComponent = {}
IdentifiedServerComponent.__extends = BaseServerComponent

function IdentifiedServerComponent.new(id: string): IdentifiedServer
	local self: IdentifiedServerImpl =
		Component(IdentifiedServerComponent) :: any

	self.Id = id
	self.dataReceivedSignals = {}
	self.dataPlayerReceivedSignals = {}

	local function eventFunc(
		player: Player,
		id: string,
		context: string,
		data: any
	)
		if self.Id ~= id then return end

		if self.dataReceivedSignals[context] then
			self.dataReceivedSignals[context]:Fire(player, data)
		end

		if
			self.dataPlayerReceivedSignals[context]
			and self.dataPlayerReceivedSignals[context][player]
		then
			self.dataPlayerReceivedSignals[context][player]:Fire(data)
		end
	end

	RE.OnServerEvent:Connect(eventFunc)
	URE.OnServerEvent:Connect(eventFunc)

	IdentifiedInvokeCallbacks[self.Id] = function(
		player: Player,
		context: string,
		...
	)
		if self.dataInvokationCallbacks[context] then
			for _, v in self.dataInvokationCallbacks[context] do
				return v(...)
			end
		end

		if
			self.dataPlayerInvokationCallbacks[context]
			and self.dataPlayerInvokationCallbacks[context][player]
		then
			for _, v in self.dataPlayerInvokationCallbacks[context][player] do
				return v(...)
			end
		end
	end

	return self
end

function IdentifiedServerComponent.fire(
	self: IdentifiedServerImpl,
	target: Player | string,
	context: string,
	data: any,
	unreliable: boolean?
)
	if typeof(target) == "string" then
		unreliable = data
		data = context
		context = target
		if unreliable then
			URE:FireAllClients(self.Id, context, data)
		else
			RE:FireAllClients(self.Id, context, data)
		end
	else
		if unreliable then
			URE:FireClient(target, self.Id, context, data)
		else
			RE:FireClient(target, self.Id, context, data)
		end
	end
end

function IdentifiedServerComponent.invoke(
	self: IdentifiedServerImpl,
	player: Player,
	context: string,
	...
)
	return RF:InvokeClient(player, self.Id, context, ...)
end

function IdentifiedServerComponent.Is(obj: any)
	return typeof(obj) == "table"
		and getmetatable(obj) == IdentifiedServerComponent
end

--[[ INSTANCED CLIENT CLASS ]]

local InstancedClientComponent = {}
InstancedClientComponent.__extends = BaseClientComponent

function InstancedClientComponent.new(instance: Instance): InstancedClient
	local self: InstancedClientImpl = Component(InstancedClientComponent) :: any

	self.Instance = instance
	self.dataReceivedSignals = {}

	self.RE = self.Instance:WaitForChild("RComponentRE") :: RemoteEvent
	self.URE =
		self.Instance:WaitForChild("RComponentURE") :: UnreliableRemoteEvent
	self.RF = self.Instance:WaitForChild("RComponentRF") :: RemoteFunction

	local function eventFunc(context: string, data: any)
		if not self.dataReceivedSignals[context] then return end

		self.dataReceivedSignals[context]:Fire(data)
	end

	self.RE.OnClientEvent:Connect(eventFunc)
	self.URE.OnClientEvent:Connect(eventFunc)

	self.RF.OnClientInvoke = function(context: string, ...)
		if not self.dataInvokationCallbacks[context] then return end

		for _, v in self.dataInvokationCallbacks[context] do
			return v(...)
		end
	end

	return self
end

function InstancedClientComponent.fire(
	self: InstancedClientImpl,
	context: string,
	data: any,
	unreliable: boolean?
)
	if unreliable then
		self.URE:FireServer(context, data)
	else
		self.RE:FireServer(context, data)
	end
end

function InstancedClientComponent.invoke(
	self: InstancedClientImpl,
	context: string,
	...
)
	return self.RF:InvokeServer(context, ...)
end

function InstancedClientComponent.Is(obj: any)
	return typeof(obj) == "table"
		and getmetatable(obj) == InstancedClientComponent
end

--[[ IDENTIFIED SERVER CLASS ]]

local InstancedServerComponent = {}
InstancedServerComponent.__extends = BaseServerComponent

function InstancedServerComponent.new(instance: Instance): InstancedServer
	local self: InstancedServerImpl = Component(InstancedServerComponent) :: any

	self.Instance = instance
	self.dataReceivedSignals = {}
	self.dataPlayerReceivedSignals = {}

	self.RE = Instance.new("RemoteEvent")
	self.RE.Name = "RComponentRE"
	self.RE.Parent = self.Instance

	self.URE = Instance.new("UnreliableRemoteEvent")
	self.URE.Name = "RComponentURE"
	self.URE.Parent = self.Instance

	self.RF = Instance.new("RemoteFunction")
	self.RF.Name = "RComponentRF"
	self.RF.Parent = self.Instance

	local function eventFunc(player: Player, context: string, data: any)
		if self.dataReceivedSignals[context] then
			self.dataReceivedSignals[context]:Fire(player, data)
		end

		if
			self.dataPlayerReceivedSignals[context]
			and self.dataPlayerReceivedSignals[context][player]
		then
			self.dataPlayerReceivedSignals[context][player]:Fire(data)
		end
	end

	self.RE.OnServerEvent:Connect(eventFunc)
	self.URE.OnServerEvent:Connect(eventFunc)

	self.RF.OnServerInvoke = function(player: Player, context: string, ...)
		if self.dataInvokationCallbacks[context] then
			for _, v in self.dataInvokationCallbacks[context] do
				return v(...)
			end
		end

		if
			self.dataPlayerInvokationCallbacks[context]
			and self.dataPlayerInvokationCallbacks[context][player]
		then
			for _, v in self.dataPlayerInvokationCallbacks[context][player] do
				return v(...)
			end
		end
	end

	return self
end

function InstancedServerComponent.fire(
	self: InstancedServerImpl,
	target: Player | string,
	context: string,
	data: any,
	unreliable: boolean?
)
	if typeof(target) == "string" then
		unreliable = data
		data = context
		context = target
		if unreliable then
			self.URE:FireAllClients(context, data)
		else
			self.RE:FireAllClients(context, data)
		end
	else
		if unreliable then
			self.URE:FireClient(target, context, data)
		else
			self.RE:FireClient(target, context, data)
		end
	end
end

function InstancedServerComponent.invoke(
	self: InstancedServerImpl,
	player: Player,
	context: string,
	...
)
	return self:invoke(player, context)
end

function InstancedServerComponent.Is(obj: any)
	return typeof(obj) == "table"
		and getmetatable(obj) == InstancedServerComponent
end

return table.freeze({
	Identified = {
		Client = table.freeze(IdentifiedClientComponent :: any) :: {
			new: (id: string) -> IdentifiedClient,
		},
		Server = table.freeze(IdentifiedServerComponent :: any) :: {
			new: (id: string) -> IdentifiedServer,
		},
	},
	Instanced = {
		Client = table.freeze(InstancedClientComponent :: any) :: {
			new: (instance: Instance) -> InstancedClient,
		},
		Server = table.freeze(InstancedServerComponent :: any) :: {
			new: (instance: Instance) -> InstancedServer,
		},
	},
})
