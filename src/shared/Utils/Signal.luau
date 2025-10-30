--- The currently idle thread to run the next handler on
local freeRunnerThread: thread? = nil

--[[
    Function which acquires the currently idle handler runner thread, runs the
    function fn on it, and then releases the thread, returning it to being the
    currently idle one.
    If there was a currently idle runner thread already, that's okay, that old
    one will just get thrown and eventually GCed.
]]
local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	-- The handler finished running, this runner thread is free again.
	freeRunnerThread = acquiredRunnerThread
end

--[[
    Coroutine runner that we create coroutines of. The coroutine can be
    repeatedly resumed with functions to run followed by the argument to run
    them with.
]]
local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local Connection = {}
Connection.__index = Connection

--[[
	Represents a connection to a signal.
    
	```lua
	local connection = signal:Connect(function() end)
	print(connection.Connected) --> true
	connection:Disconnect()
	print(connection.Connected) --> false
	```
]]
export type Connection = {
	Disconnect: (self: Connection) -> (),
	Destroy: (self: Connection) -> (),
	Connected: boolean,
}

type ConnectionImpl<T...> = {
	signal: SignalImpl<T...>,
	next: ConnectionImpl<T...>,
	callback: (T...) -> (),
} & Connection

function Connection.Disconnect<T...>(self: ConnectionImpl<T...>)
	if not self.Connected then return end
	self.Connected = false

	-- Unhook the node, but DON'T clear it. That way any fire calls that are
	-- currently sitting on this node will be able to iterate forwards off of
	-- it, but any subsequent fire calls will not hit it, and it will be GCed
	-- when no more fire calls are sitting on it.
	if self.signal.handlerListHead == self then
		self.signal.handlerListHead = self.next
	else
		local prev = self.signal.handlerListHead
		while prev and prev.next ~= self do
			prev = prev.next
		end
		if prev then prev.next = self.next end
	end
end

Connection.Destroy = Connection.Disconnect

local Signal = {}
Signal.__index = Signal

--[[
	A Signal is a data structure that allows events to be dispatched
	and observed.

	This implementation is a direct copy of the de facto standard, [GoodSignal](https://devforum.roblox.com/t/lua-signal-class-comparison-optimal-goodsignal-class/1387063),
	with some added methods and typings.

	For example:
	```lua
	local signal = Signal.new()

	-- Subscribe to a signal:
	signal:Connect(function(msg)
		print("Got message:", msg)
	end)

	-- Dispatch an event:
	signal:Fire("Hello world!")
	```
]]
type SignalHead = {
	--- Constructs a new Signal
	new: <T...>() -> Signal<T...>,
	--[[
		Constructs a new Signal that wraps around an RBXScriptSignal.

		For example:
		```lua
		local signal = Signal.Wrap(workspace.ChildAdded)
		signal:Connect(function(part) print(part.Name .. " added") end)
		Instance.new("Part").Parent = workspace
		```
	]]
	Wrap: <T...>() -> Signal<T...>,
	Is: (obj: any) -> boolean,
}

export type Signal<T...> = {
	--[[
		Fire the signal, which will call all of the connected functions with the given arguments.
		```lua
		signal:Fire("Hello")

		-- Any number of arguments can be fired:
		signal:Fire("Hello", 32, {Test = "Test"}, true)
		```
	]]
	Fire: (self: Signal<T...>, T...) -> (),
	--[[
		Same as `Fire`, but uses `task.defer` internally & doesn't take advantage of thread reuse.
		```lua
		signal:FireDeferred("Hello")
		```
	]]
	FireDeferred: (self: Signal<T...>, T...) -> (),
	--[[
		Connects a function to the signal, which will be called anytime the signal is fired.
		```lua
		signal:Connect(function(msg, num)
			print(msg, num)
		end)

		signal:Fire("Hello", 25)
		```
	]]
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	--[[
		Connects a function to the signal, which will be called the next time the signal fires. Once
		the connection is triggered, it will disconnect itself.
		```lua
		signal:Once(function(msg, num)
			print(msg, num)
		end)

		signal:Fire("Hello", 25)
		signal:Fire("This message will not go through", 10)
		```
	]]
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	--[[
		Disconnects all connections from the signal.
		```lua
		signal:DisconnectAll()
		```
	]]
	DisconnectAll: (self: Signal<T...>) -> (),
	GetConnections: (self: Signal<T...>) -> { Connection },
	--[[
		Cleans up the signal.

		Technically, this is only necessary if the signal is created using
		`Signal.Wrap`. Connections should be properly GC'd once the signal
		is no longer referenced anywhere. However, it is still good practice
		to include ways to strictly clean up resources. Calling `Destroy`
		on a signal will also disconnect all connections immediately.
		```lua
		signal:Destroy()
		```
	]]
	Destroy: (self: Signal<T...>) -> (),
	--[[
		Yields the current thread until the signal is fired, and returns the arguments fired from the signal.
		Yielding the current thread is not always desirable. If the desire is to only capture the next event
		fired, using `Once` might be a better solution.
		```lua
		task.spawn(function()
			local msg, num = signal:Wait()
			print(msg, num) --> "Hello", 32
		end)
		signal:Fire("Hello", 32)
		```
	]]
	Wait: (self: Signal<T...>) -> T...,
}

type SignalImpl<T...> = {
	handlerListHead: ConnectionImpl<T...>?,
	proxyHandler: RBXScriptConnection?,
	yieldedThreads: { thread },
} & Signal<T...>

function Signal.new<T...>(): Signal<T...>
	local self: SignalImpl<T...> = setmetatable({}, Signal) :: any

	self.handlerListHead = nil
	self.proxyHandler = nil
	self.yieldedThreads = {}

	return self
end

function Signal.Wrap<T...>(rbxScriptSignal: RBXScriptSignal<T...>): Signal<T...>
	assert(
		typeof(rbxScriptSignal) == "RBXScriptSignal",
		"Argument #1 to Signal.Wrap must be a RBXScriptSignal; got "
			.. typeof(rbxScriptSignal)
	)

	local signal = Signal.new() :: SignalImpl<T...>
	signal.proxyHandler = rbxScriptSignal:Connect(
		function(...) signal:Fire(...) end
	)

	return signal
end

function Signal.Is(obj: any)
	return type(obj) == "table" and getmetatable(obj) == Signal
end

function Signal.Connect<T...>(self: SignalImpl<T...>, callback: (T...) -> ())
	local connection: ConnectionImpl<T...> = setmetatable({
		Connected = true,
		signal = self,
		callback = callback,
		next = nil,
	}, Connection) :: any

	if self.handlerListHead then
		connection.next = self.handlerListHead
		self.handlerListHead = connection
	else
		self.handlerListHead = connection
	end

	return connection
end

function Signal.Once<T...>(self: SignalImpl<T...>, callback: (T...) -> ())
	local connection
	local done = false

	connection = self:Connect(function(...)
		if done then return end

		done = true
		connection:Disconnect()
		callback(...)
	end)

	return connection
end

function Signal.GetConnections<T...>(self: SignalImpl<T...>)
	local items = {}

	local item = self.handlerListHead
	while item do
		table.insert(items, item)
		item = item.next
	end

	return items
end

-- Disconnect all handlers. Since we use a linked list it suffices to clear the
-- reference to the head handler.
function Signal.DisconnectAll<T...>(self: SignalImpl<T...>)
	local item = self.handlerListHead
	while item do
		item.Connected = false
		item = item.next
	end
	self.handlerListHead = nil

	for _, thread in self.yieldedThreads do
		if coroutine.status(thread) == "suspended" then
			warn(
				debug.traceback(
					thread,
					"signal disconnected; yielded thread cancelled",
					2
				)
			)
			task.cancel(thread)
		end
	end
	table.clear(self.yieldedThreads)
end

-- Signal:Fire(...) implemented by running the handler functions on the
-- coRunnerThread, and any time the resulting thread yielded without returning
-- to us, that means that it yielded to the Roblox scheduler and has been taken
-- over by Roblox scheduling, meaning we have to make a new coroutine runner.
function Signal.Fire<T...>(self: SignalImpl<T...>, ...)
	local item = self.handlerListHead
	while item do
		if item.Connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end
			task.spawn(freeRunnerThread :: thread, item.callback, ...)
		end
		item = item.next
	end
end

function Signal.FireDeferred<T...>(self: SignalImpl<T...>, ...)
	local item = self.handlerListHead
	while item do
		local conn = item
		task.defer(function(...)
			if conn.Connected then conn.callback(...) end
		end, ...)
		item = item.next
	end
end

function Signal.Wait<T...>(self: SignalImpl<T...>)
	local thread = coroutine.running()
	table.insert(self.yieldedThreads, thread)

	self:Once(function(...)
		table.remove(
			self.yieldedThreads,
			table.find(self.yieldedThreads, thread)
		)

		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, ...)
		end
	end)

	return coroutine.yield()
end

function Signal.Destroy<T...>(self: SignalImpl<T...>)
	self:DisconnectAll()

	if self.proxyHandler then self.proxyHandler:Disconnect() end
end

return table.freeze({
	new = Signal.new,
	Wrap = Signal.Wrap,
	Is = Signal.Is,
} :: SignalHead)
