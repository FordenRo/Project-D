local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)
local TableUtil = require(script.Parent.TableUtil)

export type Trove = {
	--[[
		Creates and adds another trove to itself. This is just shorthand
		for `trove:Construct(Trove)`. This is useful for contexts where
		the trove object is present, but the class itself isn't.

		This does _not_ clone the trove. In other words, the objects in the
		trove are not given to the new constructed trove. This is simply to
		construct a new Trove and add it as an object to track.

		```lua
		local trove = Trove.new()
		local subTrove = trove:Extend()

		trove:Clean() -- Cleans up the subTrove too
		```
	]]
	Extend: (self: Trove) -> Trove,
	--[[
		Constructs a new object from either the
		table or function given.

		If a table is given, the table's `new`
		function will be called with the given
		arguments.

		If a function is given, the function will
		be called with the given arguments.
		
		The result from either of the two options
		will be added to the trove.

		This is shorthand for `trove:Add(SomeClass.new(...))`
		and `trove:Add(SomeFunction(...))`.

		```lua
		local Signal = require(somewhere.Signal)

		-- All of these are identical:
		local s = trove:Construct(Signal)
		local s = trove:Construct(Signal.new)
		local s = trove:Construct(function() return Signal.new() end)
		local s = trove:Add(Signal.new())

		-- Even Roblox instances can be created:
		local part = trove:Construct(Instance, "Part")
		```
	]]
	Construct: <T, A...>(self: Trove, class: Constructable<T, A...>, A...) -> T,
	--[[
		Connects the function to the signal, adds the connection
		to the trove, and then returns the connection.

		This is shorthand for `trove:Add(signal:Connect(fn))`.

		```lua
		trove:Connect(workspace.ChildAdded, function(instance)
			print(instance.Name .. " added to workspace")
		end)
		```
	]]
	Connect: <T...>(
		self: Trove,
		signal: Signal.Signal<T...> | RBXScriptSignal<T...>,
		fn: (T...) -> ()
	) -> ConnectionLike,
	--[[
		Calls `RunService:BindToRenderStep` and registers a function in the
		trove that will call `RunService:UnbindFromRenderStep` on cleanup.

		```lua
		trove:BindToRenderStep("Test", Enum.RenderPriority.Last.Value, function(dt)
			-- Do something
		end)
		```
	]]
	BindToRenderStep: (
		self: Trove,
		name: string,
		priority: number,
		fn: (dt: number) -> ()
	) -> (),
	--[[
		Adds an object to the trove. Once the trove is cleaned or
		destroyed, the object will also be cleaned up.

		The following types are accepted (e.g. `typeof(object)`):

		| Type | Cleanup |
		| ---- | ------- |
		| `Instance` | `object:Destroy()` |
		| `RBXScriptConnection` | `object:Disconnect()` |
		| `function` | `object()` |
		| `thread` | `task.cancel(object)` |
		| `table` | `object:Destroy()` _or_ `object:Disconnect()` _or_ `object:destroy()` _or_ `object:disconnect()` |
		| `table` with `cleanupMethod` | `object:<cleanupMethod>()` |

		Returns the object added.

		```lua
		-- Add a part to the trove, then destroy the trove,
		-- which will also destroy the part:
		local part = Instance.new("Part")
		trove:Add(part)
		trove:Destroy()

		-- Add a function to the trove:
		trove:Add(function()
			print("Cleanup!")
		end)
		trove:Destroy()

		-- Standard cleanup from table:
		local tbl = {}
		function tbl:Destroy()
			print("Cleanup")
		end
		trove:Add(tbl)

		-- Custom cleanup from table:
		local tbl = {}
		function tbl:DoSomething()
			print("Do something on cleanup")
		end
		trove:Add(tbl, "DoSomething")
		```
	]]
	Add: <T>(self: Trove, object: T & Trackable, cleanupMethod: string?) -> T,
	--[[
		Removes the object from the Trove and cleans it up.

		```lua
		local part = Instance.new("Part")
		trove:Add(part)
		trove:Remove(part)
		```
	]]
	Remove: <T>(self: Trove, object: T & Trackable) -> boolean,
	--[[
		Cleans up all objects in the trove. This is
		similar to calling `Remove` on each object
		within the trove. The ordering of the objects
		removed is _not_ guaranteed.

		```lua
		trove:Clean()
		```
	]]
	Clean: (self: Trove) -> (),
	--[[
		Returns true if there is no objects in the trove.
		Calling this after `Trove:Clean()` will also
		return true
	]]
	IsEmpty: (self: Trove) -> (),
	--[[
		Attaches the trove to a Roblox instance. Once this
		instance is removed from the game (parent or ancestor's
		parent set to `nil`), the trove will automatically
		clean up.

		This inverses the ownership of the Trove object, and should
		only be used when necessary. In other words, the attached
		instance dictates when the trove is cleaned up, rather than
		the trove dictating the cleanup of the instance.

		```lua
		trove:AttachToInstance(somePart)
		trove:Add(function()
			print("Cleaned")
		end)

		-- Destroying the part will cause the trove to clean up, thus "Cleaned" printed:
		somePart:Destroy()
		```
	]]
	AttachToInstance: (self: Trove, instance: Instance) -> RBXScriptConnection,
	--[[
		Alias for `trove:Clean()`.

		```lua
		trove:Destroy()
		```
	]]
	Destroy: (self: Trove) -> (),
}

type TroveImpl = Trove & {
	_objects: { any },
	_cleaning: boolean,
	_findAndRemoveFromObjects: (
		self: TroveImpl,
		object: any,
		cleanup: boolean
	) -> boolean,
	_cleanupObject: (
		self: TroveImpl,
		object: any,
		cleanupMethod: string?
	) -> (),
}

--- Represents all trackable objects by Trove.
export type Trackable =
	Instance
	| RBXScriptConnection
	| ConnectionLike
	| thread
	| ((...any) -> ...any)
	| Destroyable
	| DestroyableLowercase
	| Disconnectable
	| DisconnectableLowercase

type ConnectionLike = {
	Connected: boolean,
	Disconnect: (self: ConnectionLike) -> (),
}

type SignalLike = {
	Connect: (self: SignalLike, callback: (...any) -> ...any) -> ConnectionLike,
	Once: (self: SignalLike, callback: (...any) -> ...any) -> ConnectionLike,
}

type Constructable<T, A...> = { new: (A...) -> T } | (A...) -> T

type Destroyable = {
	Destroy: (self: Destroyable) -> (),
}

type DestroyableLowercase = {
	destroy: (self: DestroyableLowercase) -> (),
}

type Disconnectable = {
	Disconnect: (self: Disconnectable) -> (),
}

type DisconnectableLowercase = {
	disconnect: (self: DisconnectableLowercase) -> (),
}

local FN_MARKER = newproxy()
local THREAD_MARKER = newproxy()
local GENERIC_OBJECT_CLEANUP_METHODS =
	table.freeze({ "Destroy", "Disconnect", "destroy", "disconnect" })

local function GetObjectCleanupFunction(object: any, cleanupMethod: string?)
	local t = typeof(object)

	if t == "function" then
		return FN_MARKER
	elseif t == "thread" then
		return THREAD_MARKER
	end

	if cleanupMethod then return cleanupMethod end

	if t == "Instance" then
		return "Destroy"
	elseif t == "RBXScriptConnection" then
		return "Disconnect"
	elseif t == "table" then
		for _, genericCleanupMethod in GENERIC_OBJECT_CLEANUP_METHODS do
			if typeof(object[genericCleanupMethod]) == "function" then
				return genericCleanupMethod
			end
		end
	end

	error(`failed to get cleanup function for object {t}: {object}`, 3)
end

--[[
	A Trove is helpful for tracking any sort of object during
	runtime that needs to get cleaned up at some point.
]]
local Trove = {}
Trove.__index = Trove

--[[
	Constructs a Trove object.

	```lua
	local trove = Trove.new()
	```
]]
function Trove.new(): Trove
	local self: TroveImpl = setmetatable({}, Trove) :: any

	self._objects = {}
	self._cleaning = false

	return self :: any
end

function Trove.Add(
	self: TroveImpl,
	object: Trackable,
	cleanupMethod: string?
): any
	if self._cleaning then
		error("cannot call trove:Add() while cleaning", 2)
	end

	local cleanup = GetObjectCleanupFunction(object, cleanupMethod)
	table.insert(self._objects, { object, cleanup })

	return object
end

function Trove.Construct<T, A...>(
	self: TroveImpl,
	class: Constructable<T, A...>,
	...: A...
)
	if self._cleaning then
		error("Cannot call trove:Construct() while cleaning", 2)
	end

	local object = nil
	local t = type(class)
	if t == "table" then
		object = (class :: any).new(...)
	elseif t == "function" then
		object = (class :: any)(...)
	end

	return self:Add(object)
end

function Trove.Connect(
	self: TroveImpl,
	signal: SignalLike,
	fn: (...any) -> ...any
)
	if self._cleaning then
		error("Cannot call trove:Connect() while cleaning", 2)
	end

	return self:Add(signal:Connect(fn))
end

function Trove.BindToRenderStep(
	self: TroveImpl,
	name: string,
	priority: number,
	fn: (dt: number) -> ()
)
	if self._cleaning then
		error("cannot call trove:BindToRenderStep() while cleaning", 2)
	end

	RunService:BindToRenderStep(name, priority, fn)

	self:Add(function() RunService:UnbindFromRenderStep(name) end)
end

function Trove.Remove(self: TroveImpl, object: Trackable): boolean
	if self._cleaning then
		error("cannot call trove:Remove() while cleaning", 2)
	end

	return self:_findAndRemoveFromObjects(object, true)
end

function Trove.Extend(self: TroveImpl)
	if self._cleaning then
		error("cannot call trove:Extend() while cleaning", 2)
	end

	return self:Construct(Trove)
end

function Trove.Clean(self: TroveImpl)
	if self._cleaning then return end

	self._cleaning = true

	for _, obj in self._objects do
		self:_cleanupObject(obj[1], obj[2])
	end

	table.clear(self._objects)
	self._cleaning = false
end

function Trove._findAndRemoveFromObjects(
	self: TroveImpl,
	object: any,
	cleanup: boolean
): boolean
	local objects = self._objects

	for i, obj in objects do
		if obj[1] == object then
			local n = #objects
			objects[i] = objects[n]
			objects[n] = nil

			if cleanup then self:_cleanupObject(obj[1], obj[2]) end

			return true
		end
	end

	return false
end

function Trove._cleanupObject(
	self: TroveImpl,
	object: any,
	cleanupMethod: string?
)
	if cleanupMethod == FN_MARKER then
		task.spawn(object)
	elseif cleanupMethod == THREAD_MARKER then
		pcall(task.cancel, object)
	else
		object[cleanupMethod](object)
	end
end

function Trove.IsEmpty(self: TroveImpl) return TableUtil.IsEmpty(self._objects) end

function Trove.AttachToInstance(self: TroveImpl, instance: Instance)
	if self._cleaning then
		error("cannot call trove:AttachToInstance() while cleaning", 2)
	end

	return self:Connect(instance.AncestryChanged, function()
		if instance:IsDescendantOf(game) then return end

		self:Destroy()
	end)
end

function Trove.Destroy(self: TroveImpl) self:Clean() end

return {
	new = Trove.new,
}
