--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local Component = {}
local Meta = {}

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

	--- Returns a metatable of the component's parent that this component extends.
	Super: <Component>(self: Component) -> Component,

	--- Returns true if an component's base matches or inherits from a given base.
	IsA: (self: Component, base: any) -> boolean,

	--- Returns true if an component's base equals a given base.
	TypeOf: (self: Component, base: any) -> boolean,

	--- Creates a deep copy of an component.
	Clone: <Component>(self: Component) -> Component,
}

type ComponentImpl = {
	propChangedSignals: { [string]: Signal.Signal<> },
	get: { [string]: (self: any) -> any }?,
	set: { [string]: (self: any, value: any) -> any }?,
} & Component

function getExtendedGetter(base, k: string): any
	if base.get and base.get[k] then return base.get[k] end
	return base.__extends and getExtendedGetter(base.__extends, k)
end

function getExtendedValue(base, k: string): any
	return base[k] or base.__extends and getExtendedValue(base.__extends, k)
end

function getExtendedSetter(base, k: string): any
	if base.set and base.set[k] then return base.set[k] end
	return base.__extends and getExtendedSetter(base.__extends, k)
end

local ComponentMeta = {
	__index = function(t, k)
		local self = rawget(t, "__component") :: ComponentImpl
		local base = rawget(t, "__base") :: any

		local get = getExtendedGetter(base, k)
		if get then return get(t) end

		return self[k] or getExtendedValue(base, k)
	end,
	__newindex = function(t, k, v)
		local self = rawget(t, "__component") :: ComponentImpl
		local base = rawget(t, "__base") :: any

		local set = getExtendedSetter(base, k)
		if set then
			if not set(t, v) then return end
		else
			if self[k] == v then return end

			self[k] = v
		end

		self.Changed:Fire(k)
		if self.propChangedSignals[k] then self.propChangedSignals[k]:Fire() end
	end,
}

-- Set meta methods
local metamethods = {
	"__call",
	"__concat",
	"__unm",
	"__add",
	"__sub",
	"__mul",
	"__div",
	"__idiv",
	"__mod",
	"__pow",
	"__tostring",
	"__eq",
	"__lt",
	"__le",
	"__len",
	"__iter",
}
for _, v in metamethods do
	ComponentMeta[v] = function(t, ...)
		return getExtendedValue(rawget(t, "__base"), v)(t, ...)
	end
end

-- TODO: #2 Fix changed signals table memory leak

function Meta.__call(_, base: any, source: any?)
	if source and rawget(source, "__component") then
		source = source.__component
	end

	local self: ComponentImpl = (
		source and TableUtil.DeepCopy(source) or {}
	) :: any

	self.Changed = Signal.new()
	self.propChangedSignals = {}

	return setmetatable({
		__component = self,
		__base = base,
	}, ComponentMeta)
end

function Component.new(source: any?)
	return (Component :: any)({ __extends = Component }, source)
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
	local base = assert(rawget(self, "__base"))
	t = TableUtil.DeepCopy(t)

	return setmetatable({
		__component = t,
		__base = base,
	}, ComponentMeta)
end

function Component.RawGet(self: ComponentImpl, key: string): any?
	local t = assert(rawget(self, "__component"))
	return t[key]
end

function Component.RawSet(self: ComponentImpl, key: string, value: any)
	local t = assert(rawget(self, "__component"))
	t[key] = value
end

function Component.Super(self: ComponentImpl)
	local base = assert(rawget(self, "__base"))

	return setmetatable({
		Super = Component.Super,
		__component = rawget(self, "__component"),
		__base = rawget(base, "__extend"),
	}, ComponentMeta)
end

function Component.IsA(self: ComponentImpl, base: any)
	if not base then return false end

	return self:TypeOf(base) or self:IsA(rawget(base, "__extend"))
end

function Component.TypeOf(self: ComponentImpl, base: any)
	return assert(rawget(self, "__base")) == base
end

function Component.__tostring(self: ComponentImpl)
	local t = rawget(self, "__component") :: any

	local str = "Component(\n"
	for k, v in t do
		str ..= `\t{k} = {tostring(v)}\n`
	end
	str ..= ")"

	return str
end

setmetatable(Component, Meta)

return (Component :: any) :: typeof(setmetatable(
	{} :: {
		--- Constructs a new component
		new: <S>(source: S?) -> Component & S,
	},
	{} :: {
		__call: <A, B, S>(self: A, base: B, source: S?) -> Component & B & S,
	}
))
