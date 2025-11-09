--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local Component = {}

export type Component = {
	--- Fired immediately after a property of the component changes.
	Changed: Signal.Signal<string>,

	--- Fires immediately after a given property of the component changes.
	GetPropertyChangedSignal: (
		self: Component,
		property: string
	) -> Signal.Signal<>,
	--- Gets the value, bypassing any getters.
	RawGet: (self: Component, key: string) -> any?,
	--- Sets the value, bypassing any setters.
	RawSet: (self: Component, key: string, value: any) -> (),
	--- Create a deep copy of an component.
	Clone: <Component>(self: Component) -> Component,
}

type ComponentImpl = {
	propChangedSignals: { [string]: Signal.Signal<> },
	get: { [string]: (self: any) -> any }?,
	set: { [string]: (self: any, value: any) -> any }?,
} & Component

function getMeta(base: any)
	return {
		__index = function(t, k)
			local self = assert(rawget(t, "_t")) :: ComponentImpl

			local function getExtendedGetter(obj)
				if obj.get and obj.get[k] then return obj.get[k] end
				return obj.__extend and getExtendedGetter(obj.__extend)
			end

			local get = getExtendedGetter(base)
			if get then return get(t) end

			local function getExtendedValue(obj)
				return obj[k] or obj.__extend and getExtendedValue(obj.__extend)
			end

			return self[k] or getExtendedValue(base)
		end,
		__newindex = function(t, k, v)
			local self = assert(rawget(t, "_t")) :: ComponentImpl

			local function getExtendedSetter(obj)
				if obj.set and obj.set[k] then return obj.set[k] end
				return obj.__extend and getExtendedSetter(obj.__extend)
			end

			local set = getExtendedSetter(base)
			if set then
				set(t, v)
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

-- TODO: Fix changed signals table memory leak

--- Constructs a new component
function Component.new(): Component
	local self: ComponentImpl = {} :: any

	self.Changed = Signal.new()
	self.propChangedSignals = {}

	return setmetatable({ _t = self }, getMeta(Component)) :: any
end

--- Constructs a new component that wraps the source
function Component.Wrap<T>(source: T): Component & T
	local self: ComponentImpl = (
		source and TableUtil.DeepCopy(source) or {}
	) :: any

	self.Changed = Signal.new()
	self.propChangedSignals = {}

	return setmetatable({ _t = self }, getMeta(Component)) :: any
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
	local t = assert(rawget(self, "_t"))
	t = TableUtil.DeepCopy(t)

	return setmetatable({ _t = t }, getmetatable(self :: any))
end

function Component.Is(obj: any): boolean
	return typeof(obj) == "table" and getmetatable(obj) == Component
end

function Component.RawGet(self: any, key: string): any?
	local t = assert(rawget(self, "_t"))
	return t[key]
end

function Component.RawSet(self: any, key: string, value: any)
	local t = assert(rawget(self, "_t"))
	t[key] = value
end

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
