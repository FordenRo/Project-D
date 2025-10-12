--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Utils.Signal)

local BaseClass = {}

export type BaseClass = {
	Changed: Signal.Signal<string>,

	GetPropertyChangedSignal: (
		self: BaseClass,
		property: string
	) -> Signal.Signal<>,
	--- Gets the value, bypassing any getters.
	RawGet: (self: BaseClass, key: string) -> any?,
	--- Sets the value, bypassing any setters.
	RawSet: (self: BaseClass, key: string, value: any) -> (),
}

type BaseClassImpl = {
	propChangedSignals: { [string]: Signal.Signal<> },
	get: { [string]: (self: any) -> any }?,
	set: { [string]: (self: any, value: any) -> any }?,
} & BaseClass

function getMeta(base: any)
	return {
		__index = function(t, k)
			local self = assert(rawget(t, "_t")) :: BaseClassImpl

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
			local self = assert(rawget(t, "_t")) :: BaseClassImpl

			local function getExtendedSetter(obj)
				if obj.set and obj.set[k] then return obj.set[k] end
				return obj.__extend and getExtendedSetter(obj.__extend)
			end

			local set = getExtendedSetter(base)
			if set then
				set(t, v)
			else
				self[k] = v
			end

			self.Changed:Fire(k)
			if self.propChangedSignals[k] then
				self.propChangedSignals[k]:Fire()
			end
		end,
	}
end

function BaseClass.new(): BaseClass
	local self: BaseClassImpl = {} :: any

	self.Changed = Signal.new()
	self.propChangedSignals = {}

	return setmetatable({ _t = self }, getMeta(BaseClass)) :: any
end

function BaseClass.GetPropertyChangedSignal(
	self: BaseClassImpl,
	property: string
)
	local signal = self.propChangedSignals[property]
	if not signal then
		signal = Signal.new()
		self.propChangedSignals[property] = signal
	end

	return signal
end

function BaseClass.Is(obj: any): boolean
	return typeof(obj) == "table" and getmetatable(obj) == BaseClass
end

function BaseClass.RawGet(self: any, key: string): any?
	local t = assert(rawget(self, "_t"))
	return t[key]
end

function BaseClass.RawSet(self: any, key: string, value: any)
	local t = assert(rawget(self, "_t"))
	t[key] = value
end

function BaseClass.Extend(to: any, from: any?)
	for k, v in getMeta(to) do
		to[k] = v
	end
	to.__extend = from or BaseClass
end

return table.freeze({
	new = BaseClass.new,
	Is = BaseClass.Is,
	Extend = BaseClass.Extend,
})
