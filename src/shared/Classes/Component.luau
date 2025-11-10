--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local Component = {}

export type Component = {
	--[[
		Fired immediately after a property of the component changes.

		```luau
		local component = Component.Wrap({ test = 5 })
		component.Changed:Connect(function(property: string)
			print(`Fired "{property}"!`)
		end)
		component.test = 6 -- Fired "test"!
	]]
	Changed: Signal.Signal<string>,
	--[[
		Fires immediately after the given property of the component changes.
		
		```luau
		local component = Component.Wrap({ test = 5, name = "st" })
		component:GetPropertyChangedSignal("test"):Connect(function()
			print("Fired!")
		end)
		component.test = 6 -- Fired!
		component.name = "test" -- will not fire
	]]
	GetPropertyChangedSignal: (
		self: Component,
		property: string
	) -> Signal.Signal<>,
	--- Gets the value of the component bypassing any getters.
	RawGet: (self: Component, key: string) -> any?,
	--- Sets the value of the component bypassing any setters and `Changed` signals.
	RawSet: (self: Component, key: string, value: any) -> (),
	--- Creates a deep copy of an component.
	Clone: <Component>(self: Component) -> Component,
}

type ComponentImpl = {
	propChangedSignals: { [string]: Signal.Signal<> },
	get: { [string]: (self: any) -> any }?,
	set: { [string]: (self: any, value: any) -> any }?,
} & Component

function getExtendedGetter(obj, k)
	if obj.get and obj.get[k] then return obj.get[k] end
	return obj.__extend and getExtendedGetter(obj.__extend, k)
end

function getExtendedValue(obj, k)
	return obj[k] or obj.__extend and getExtendedValue(obj.__extend, k)
end

function getExtendedSetter(obj, k)
	if obj.set and obj.set[k] then return obj.set[k] end
	return obj.__extend and getExtendedSetter(obj.__extend, k)
end

function getMeta(base: any)
	return {
		__index = function(t, k)
			local self = rawget(t, "__component") :: ComponentImpl

			local get = getExtendedGetter(base, k)
			if get then return get(t) end

			return self[k] or getExtendedValue(base, k)
		end,
		__newindex = function(t, k, v)
			local self = rawget(t, "__component") :: ComponentImpl

			local set = getExtendedSetter(base, k)
			if set then
				if not set(t, v) then return end
			else
				if self[k] == v then return end

				self[k] = v
			end

			self.Changed:Fire(k)
			if self.propChangedSignals[k] then
				self.propChangedSignals[k]:Fire()
			end
		end,
	}
end

-- TODO: #2 Fix changed signals table memory leak

--- Constructs a new component
function Component.new(): Component
	local self: ComponentImpl = {} :: any

	self.Changed = Signal.new()
	self.propChangedSignals = {}

	return setmetatable({ __component = self }, getMeta(Component)) :: any
end

--- Constructs a new component that wraps the source
function Component.Wrap<T>(source: T): Component & T
	local self: ComponentImpl = (
		source and TableUtil.DeepCopy(source) or {}
	) :: any

	self.Changed = Signal.new()
	self.propChangedSignals = {}

	return setmetatable({ __component = self }, getMeta(Component)) :: any
end

function Component.GetPropertyChangedSignal(
	self: ComponentImpl,
	property: string
)
	local signal = self.propChangedSignals[property]
	if not signal then
		signal = Signal.new()
		self.propChangedSignals[property] = signal
	end

	return signal
end

function Component.Clone(self: ComponentImpl)
	local t = assert(rawget(self, "__component"))
	t = TableUtil.DeepCopy(t)

	return setmetatable({ __component = t }, getmetatable(self :: any))
end

function Component.Is(obj: any): boolean
	return typeof(obj) == "table" and getmetatable(obj) == Component
end

function Component.RawGet(self: any, key: string): any?
	local t = assert(rawget(self, "__component"))
	return t[key]
end

function Component.RawSet(self: any, key: string, value: any)
	local t = assert(rawget(self, "__component"))
	t[key] = value
end

--[[
	Extends component

	```luau
	local Class = {}
	Component.Extend(Class)

	function Class.new()
		local self = Component.new()
		setmetatable(self, Class)
		return self
	end

	return Class
	```

	To extend a `Class`, use
	```luau
	local SubClass = {}
	Component.Extend(SubClass, Class)

	function SubClass.new()
		local self = Class.new()
		setmetatable(self, SubClass)
		return self
	end

	return SubClass
	```
]]
function Component.Extend(to: any, from: any?)
	for k, v in getMeta(to) do
		to[k] = v
	end
	to.__extend = from or Component
end

return table.freeze({
	new = Component.new,
	Wrap = Component.Wrap,
	Is = Component.Is,
	Extend = Component.Extend,
})
