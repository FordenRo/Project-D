--!native

--[[
	A collection of helpful table utility functions. Many of these functions are carried over from JavaScript or
	Python that are not present in Lua.

	Tables that only work specifically with arrays or dictionaries are marked as such in the documentation.

	All functions (_except_ `SwapRemove`, `SwapRemoveFirstValue`, and `Lock`) treat tables as immutable and will return
	copies of the given table(s) with the operations performed on the copies.
]]
local TableUtil = {}

local HttpService = game:GetService("HttpService")

--[[
	Creates a deep copy of the given table.

	Deep copies are _not_ protected against cyclical references. Passing
	a table with cyclical references will result in a stack-overflow.
]]
function TableUtil.DeepCopy<T>(tbl: T): T
	assert(typeof(tbl) == "table", "Argument must be a table")

	local tCopy = table.clone(tbl)
	for k, v in tCopy do
		if typeof(v) == "table" then tCopy[k] = TableUtil.DeepCopy(v) end
	end
	return tCopy :: any
end

--[[
	Synchronizes the `srcTbl` based on the `templateTbl`. This will make
	sure that `srcTbl` has all of the same keys as `templateTbl`, including
	removing keys in `srcTbl` that are not present in `templateTbl`. This
	is a _deep_ operation, so any nested tables will be synchronized as
	well.

	```lua
	local template = {kills = 0, deaths = 0, xp = 0}
	local data = {kills = 10, experience = 12}
	data = TableUtil.Sync(data, template)
	print(data) --> {kills = 10, deaths = 0, xp = 0}
	```

	This is a two-way sync, so the source table will have data
	_removed_ that isn't found in the template table. This can
	be problematic if used for player data, where there might
	be dynamic data added that isn't in the template.

	For player data, use `TableUtil.Reconcile` instead.
]]
function TableUtil.Sync<S, T>(srcTbl: S, templateTbl: T): T
	assert(typeof(srcTbl) == "table", "First argument must be a table")
	assert(typeof(templateTbl) == "table", "Second argument must be a table")

	local tbl = table.clone(srcTbl)

	-- If 'tbl' has something 'templateTbl' doesn't, then remove it from 'tbl'
	-- If 'tbl' has something of a different type than 'templateTbl', copy from 'templateTbl'
	-- If 'templateTbl' has something 'tbl' doesn't, then add it to 'tbl'
	for k, v in tbl do
		local vTemplate = templateTbl[k]

		-- Remove keys not within template:
		if vTemplate == nil then
			tbl[k] = nil

			-- Synchronize data types:
		elseif typeof(v) ~= typeof(vTemplate) then
			if typeof(vTemplate) == "table" then
				tbl[k] = TableUtil.DeepCopy(vTemplate)
			else
				tbl[k] = vTemplate
			end

			-- Synchronize sub-tables:
		elseif typeof(v) == "table" then
			tbl[k] = TableUtil.Sync(v, vTemplate)
		end
	end

	-- Add any missing keys:
	for k, vTemplate in templateTbl do
		local v = tbl[k]

		if v == nil then
			if typeof(vTemplate) == "table" then
				tbl[k] = TableUtil.DeepCopy(vTemplate)
			else
				tbl[k] = vTemplate
			end
		end
	end

	return (tbl :: any) :: T
end

--[[
	Performs a one-way sync on the `source` table against the
	`template` table. Any keys found in `template` that are
	not found in `source` will be added to `source`. This is
	useful for syncing player data against data template tables
	to ensure players have all the necessary keys, while
	maintaining existing keys that may no longer be in the
	template.

	This is a deep operation, so nested tables will also be
	properly reconciled.

	```lua
	local template = {kills = 0, deaths = 0, xp = 0}
	local data = {kills = 10, abc = 20}
	local correctedData = TableUtil.Reconcile(data, template)
	
	print(correctedData) --> {kills = 10, deaths = 0, xp = 0, abc = 20}
	```
]]
function TableUtil.Reconcile<S, T>(src: S, template: T): S & T
	assert(typeof(src) == "table", "First argument must be a table")
	assert(typeof(template) == "table", "Second argument must be a table")

	local tbl = table.clone(src)

	for k, v in template do
		local sv = src[k]
		if sv == nil then
			if typeof(v) == "table" then
				tbl[k] = TableUtil.DeepCopy(v)
			else
				tbl[k] = v
			end
		elseif typeof(sv) == "table" then
			if typeof(v) == "table" then
				tbl[k] = TableUtil.Reconcile(sv, v)
			else
				tbl[k] = TableUtil.DeepCopy(sv)
			end
		end
	end

	return (tbl :: any) :: S & T
end

--[[
	Removes index `i` in the table by swapping the value at `i` with
	the last value in the array, and then trimming off the last
	value from the array.

	This allows removal of the value at `i` in `O(1)` time, but does
	not preserve array ordering. If a value needs to be removed from
	an array, but ordering of the array does not matter, using
	`SwapRemove` is always preferred over `table.remove`.

	In the following example, we remove "B" at index 2. SwapRemove does
	this by moving the last value "E" over top of "B", and then trimming
	off "E" at the end of the array:
	```lua
	local t = {"A", "B", "C", "D", "E"}
	TableUtil.SwapRemove(t, 2) -- Remove "B"
	print(t) --> {"A", "E", "C", "D"}
	```

	This function works on arrays, but not dictionaries.
]]
function TableUtil.SwapRemove<T>(t: { T }, i: number)
	local n = #t
	t[i] = t[n]
	t[n] = nil
end

--[[
	Performs `table.find(tbl, v)` to find the index of the given
	value, and then performs `TableUtil.SwapRemove` on that index.

	```lua
	local t = {"A", "B", "C", "D", "E"}
	TableUtil.SwapRemoveFirstValue(t, "C")
	print(t) --> {"A", "B", "E", "D"}
	```

	This function works on arrays, but not dictionaries.
]]
function TableUtil.SwapRemoveFirstValue<T>(t: { T }, v: T): number?
	local index: number? = table.find(t, v)
	if index then TableUtil.SwapRemove(t, index) end
	return index
end

--[[
	Performs a map operation against the given table, which can be used to
	map new values based on the old values at given keys/indices.

	For example:

	```lua
	local t = {A = 10, B = 20, C = 30}
	local t2 = TableUtil.Map(t, function(value)
		return value * 2
	end)
	print(t2) --> {A = 20, B = 40, C = 60}
	```
]]
function TableUtil.Map<T, M>(t: { T }, f: (T, number, { T }) -> M): { M }
	assert(typeof(t) == "table", "First argument must be a table")
	assert(typeof(f) == "function", "Second argument must be a function")

	local newT = table.create(#t)
	for k, v in t do
		newT[k] = f(v, k, t)
	end
	return newT
end

--[[
	Performs a filter operation against the given table, which can be used to
	filter out unwanted values from the table.

	For example:

	```lua
	local t = {A = 10, B = 20, C = 30}
	local t2 = TableUtil.Filter(t, function(value, key)
		return value > 15
	end)
	print(t2) --> {B = 40, C = 60}
	```
]]
function TableUtil.Filter<T>(
	t: { T },
	predicate: (T, any, { T }) -> boolean
): { T }
	assert(typeof(t) == "table", "First argument must be a table")
	assert(
		typeof(predicate) == "function",
		"Second argument must be a function"
	)

	local newT = table.create(#t)
	if #t > 0 then
		local n = 0
		for i, v in t do
			if predicate(v, i, t) then
				n += 1
				newT[n] = v
			end
		end
	else
		for k, v in t do
			if predicate(v, k, t) then newT[k] = v end
		end
	end

	return newT
end

--[[
	Performs a reduce operation against the given table, which can be used to
	reduce the table into a single value. This could be used to sum up a table
	or transform all the values into a compound value of any kind.

	For example:

	```lua
	local t = {10, 20, 30, 40}
	local result = TableUtil.Reduce(t, function(accum, value)
		return accum + value
	end)
	print(result) --> 100
	```
]]
function TableUtil.Reduce<T, R>(
	t: { T },
	predicate: (R, T, any, { T }) -> R,
	init: R
): R
	assert(typeof(t) == "table", "First argument must be a table")
	assert(
		typeof(predicate) == "function",
		"Second argument must be a function"
	)

	local result = init :: R
	if #t > 0 then
		local start = 1
		if init == nil then
			result = (t[1] :: any) :: R
			start = 2
		end

		for i = start, #t do
			result = predicate(result, t[i], i, t)
		end
	else
		local start = nil
		if init == nil then
			result = (next(t) :: any) :: R
			start = result
		end

		for k, v in next, t, start :: any? do
			result = predicate(result, v, k, t)
		end
	end

	return result
end

--[[
	Copies all values of the given tables into the `target` table.

	```lua
	local t = {A = 10}
	local t2 = {B = 20}
	local t3 = {C = 30, D = 40}
	local newT = TableUtil.Assign(t, t2, t3)
	print(newT) --> {A = 10, B = 20, C = 30, D = 40}
	```
]]
function TableUtil.Assign<T>(target: { T }, ...: { any }): { T } & { any }
	local tbl = table.clone(target)
	for _, src in { ... } do
		for k, v in src do
			tbl[k] = v
		end
	end
	return tbl
end

--[[
	Extends the target array with the extension array.

	```lua
	local t = {10, 20, 30}
	local t2 = {30, 40, 50}
	local tNew = TableUtil.Extend(t, t2)
	print(tNew) --> {10, 20, 30, 30, 40, 50}
	```

	This function works on arrays, but not dictionaries.
]]
function TableUtil.Extend<T, E>(target: { T }, extension: { E }): { T } & { E }
	local tbl = table.clone(target) :: { any }
	for _, v in extension do
		table.insert(tbl, v)
	end
	return tbl
end

--[[
	Reverses the array.

	```lua
	local t = {1, 5, 10}
	local tReverse = TableUtil.Reverse(t)
	print(tReverse) --> {10, 5, 1}
	```

	This function works on arrays, but not dictionaries.
]]
function TableUtil.Reverse<T>(tbl: { T }): { T }
	local n = #tbl
	local tblRev = table.create(n)
	for i = 1, n do
		tblRev[i] = tbl[n - i + 1]
	end
	return tblRev
end

--[[
	Shuffles the table.

	```lua
	local t = {1, 2, 3, 4, 5, 6, 7, 8, 9}
	local shuffled = TableUtil.Shuffle(t)
	print(shuffled) --> e.g. {9, 4, 6, 7, 3, 1, 5, 8, 2}
	```

	This function works on arrays, but not dictionaries.
]]
function TableUtil.Shuffle<T>(tbl: { T }, seed: number?): { T }
	assert(typeof(tbl) == "table", "First argument must be a table")

	local shuffled = table.clone(tbl)
	for i = #tbl, 2, -1 do
		local j = Random.new(seed):NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

--[[
	Returns a random sample of the table.

	```lua
	local t = {1, 2, 3, 4, 5, 6, 7, 8, 9}
	local sample = TableUtil.Sample(t, 3)
	print(sample) --> e.g. {6, 2, 5}
	```

	This function works on arrays, but not dictionaries.
]]
function TableUtil.Sample<T>(tbl: { T }, size: number, seed: number?): { T }
	assert(typeof(tbl) == "table", "First argument must be a table")
	assert(typeof(size) == "number", "Second argument must be a number")

	-- If given table is empty, just return a new empty table:
	local len = #tbl
	if len == 0 then return {} end

	local shuffled = table.clone(tbl)
	local sample = table.create(size)

	-- Clamp sample size to be no larger than the given table size:
	size = math.clamp(size, 1, len)

	for i = 1, size do
		local j = Random.new(seed):NextInteger(i, len)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	table.move(shuffled, 1, size, 1, sample)
	return sample
end

--[[
	Returns a new table where all sub-arrays have been
	bubbled up to the top. The depth at which the scan
	is performed is dictated by the `depth` parameter,
	which is set to `1` by default.

	```lua
	local t = {{10, 20}, {90, 100}, {30, 15}}
	local flat = TableUtil.Flat(t)
	print(flat) --> {10, 20, 90, 100, 30, 15}
	```

	This function works on arrays, but not dictionaries.
]]
function TableUtil.Flat<T>(tbl: { T }, depth: number?): { T }
	local maxDepth: number = if typeof(depth) == "number" then depth else 1
	local flatTbl = table.create(#tbl)

	local function Scan(t: { any }, d: number)
		for _, v in t do
			if typeof(v) == "table" and d < maxDepth then
				Scan(v, d + 1)
			else
				table.insert(flatTbl, v)
			end
		end
	end

	Scan(tbl, 0)
	return flatTbl
end

--[[
	Calls `TableUtil.Map` on the given table and predicate, and then
	calls `TableUtil.Flat` on the result from the map operation.

	```lua
	local t = {10, 20, 30}
	local result = TableUtil.FlatMap(t, function(value)
		return {value, value * 2}
	end)
	print(result) --> {10, 20, 20, 40, 30, 60}
	```

	This function works on arrays, but not dictionaries.
]]
function TableUtil.FlatMap<T, M>(
	tbl: { T },
	callback: (T, number, { T }) -> M
): { M }
	return TableUtil.Flat(TableUtil.Map(tbl, callback))
end

--[[
	Returns an array with all the keys in the table.

	```lua
	local t = {A = 10, B = 20, C = 30}
	local keys = TableUtil.Keys(t)
	print(keys) --> {"A", "B", "C"}
	```

	The ordering of the keys is never guaranteed. If order is imperative, call
	`table.sort` on the resulting `keys` array.
	```lua
	local keys = TableUtil.Keys(t)
	table.sort(keys)
	```
]]
function TableUtil.Keys<K, V>(tbl: { [K]: V }): { K }
	local keys = table.create(#tbl)
	for k in tbl do
		table.insert(keys, k)
	end
	return keys
end

--[[
	Returns an array with all the values in the table.

	```lua
	local t = {A = 10, B = 20, C = 30}
	local values = TableUtil.Values(t)
	print(values) --> {10, 20, 30}
	```

	The ordering of the values is never guaranteed. If order is imperative, call
	`table.sort` on the resulting `values` array.
	```lua
	local values = TableUtil.Values(t)
	table.sort(values)
	```
]]
function TableUtil.Values<K, V>(tbl: { [K]: V }): { V }
	local values = table.create(#tbl)
	for _, v in tbl do
		table.insert(values, v)
	end
	return values
end

--[[
	Performs a linear scan across the table and calls `callback` on
	each item in the array. Returns the value and key of the first
	pair in which the callback returns `true`.

	```lua
	local t = {
		{Name = "Bob", Age = 20};
		{Name = "Jill", Age = 30};
		{Name = "Ann", Age = 25};
	}

	-- Find first person who has a name starting with J:
	local firstPersonWithJ = TableUtil.Find(t, function(person)
		return person.Name:sub(1, 1):lower() == "j"
	end)

	print(firstPersonWithJ) --> {Name = "Jill", Age = 30}
	```

	While `Find` can also be used with dictionaries, dictionary ordering is never
	guaranteed, and thus the result could be different if there are more
	than one possible matches given the data and callback function.
]]
function TableUtil.Find<K, V>(
	tbl: { [K]: V },
	callback: (V, K, { [K]: V }) -> boolean
): (V?, K?)
	for k, v in tbl do
		if callback(v, k, tbl) then return v, k end
	end
	return nil, nil
end

--[[
	Returns `true` if the `callback` also returns `true` for _every_
	item in the table.

	```lua
	local t = {10, 20, 40, 50, 60}

	local allAboveZero = TableUtil.Every(t, function(value)
		return value > 0
	end)

	print("All above zero:", allAboveZero) --> All above zero: true
	```
]]
function TableUtil.Every<K, V>(
	tbl: { [K]: V },
	callback: (V, K, { [K]: V }) -> boolean
): boolean
	for k, v in tbl do
		if not callback(v, k, tbl) then return false end
	end
	return true
end

--[[
	Returns `true` if the `callback` also returns `true` for _at least
	one_ of the items in the table.

	```lua
	local t = {10, 20, 40, 50, 60}

	local someBelowTwenty = TableUtil.Some(t, function(value)
		return value < 20
	end)

	print("Some below twenty:", someBelowTwenty) --> Some below twenty: true
	```
]]
function TableUtil.Some<K, V>(
	tbl: { [K]: V },
	callback: (V, K, { [K]: V }) -> boolean
): boolean
	for k, v in tbl do
		if callback(v, k, tbl) then return true end
	end
	return false
end

--[[
	Returns a new table truncated to the length of `length`. Any length
	equal or greater than the current length will simply return a
	shallow copy of the table.

	```lua
	local t = {10, 20, 30, 40, 50, 60, 70, 80}
	local tTruncated = TableUtil.Truncate(t, 3)
	print(tTruncated) --> {10, 20, 30}
	```
]]
function TableUtil.Truncate<T>(tbl: { T }, len: number): { T }
	local n = #tbl
	len = math.clamp(len, 1, n)
	return if len == n
		then table.clone(tbl)
		else table.move(tbl, 1, len, 1, table.create(len))
end

--[=[
	Returns an iterator that can scan through multiple tables at the same time side-by-side, matching
	against shared keys/indices.

	```lua
	local t1 = {10, 20, 30, 40, 50}
	local t2 = {60, 70, 80, 90, 100}

	for key,values in TableUtil.Zip(t1, t2) do
		print(key, values)
	end

	--[[
		Outputs:
		1 {10, 60}
		2 {20, 70}
		3 {30, 80}
		4 {40, 90}
		5 {50, 100}
	--]]
	```
]=]
function TableUtil.Zip(
	...: { [any]: any }
): ((t: { any }, k: any) -> (any, any), { any }, any)
	assert(select("#", ...) > 0, "Must supply at least 1 table")

	local function ZipIteratorArray(
		all: { any },
		k: number
	): (number?, { any }?)
		k += 1
		local values = {}
		for i, t in all do
			local v = t[k]
			if v ~= nil then
				values[i] = v
			else
				return nil, nil
			end
		end
		return k, values
	end

	local function ZipIteratorMap(
		all: { [any]: any },
		k: any
	): (number?, { any }?)
		local values = {}
		for i, t in all do
			local v = next(t, k)
			if v ~= nil then
				values[i] = v
			else
				return nil, nil
			end
		end
		return k, values
	end

	local all = { ... }
	if #all[1] > 0 then
		return ZipIteratorArray, all, 0
	else
		return ZipIteratorMap, all, nil
	end
end

--[[
	Freezes the table using `table.freeze`, as well as any
	nested tables within the given table. This will freeze
	the whole deep structure of the table, disallowing any
	further modifications.

	```lua
	local tbl = {xyz = {abc = 32}}
	tbl.xyz.abc = 28 -- Works fine
	TableUtil.Lock(tbl)
	tbl.xyz.abc = 64 -- Will throw an error (cannot modify readonly table)
	```
]]
function TableUtil.DeepFreeze<T>(tbl: T): T
	assert(typeof(tbl) == "table", "Argument must be a table")

	for k, v in tbl do
		if typeof(v) == "table" then tbl[k] = TableUtil.DeepFreeze(v) end
	end
	return table.freeze(tbl) :: any
end

--[[
	Returns `true` if the given table is empty. This is
	simply performed by checking if `next(tbl)` is `nil`
	and works for both arrays and dictionaries. This is
	useful when needing to check if a table is empty but
	not knowing if it is an array or dictionary.

	```lua
	TableUtil.IsEmpty({}) -- true
	TableUtil.IsEmpty({"abc"}) -- false
	TableUtil.IsEmpty({abc = 32}) -- false
	```
]]
function TableUtil.IsEmpty(tbl: any): boolean return next(tbl) == nil end

--- Proxy for [`HttpService:JSONEncode`](https://developer.roblox.com/en-us/api-reference/function/HttpService/JSONEncode).
function TableUtil.EncodeJSON(value: any): string
	return HttpService:JSONEncode(value)
end

--- Proxy for [`HttpService:JSONDecode`](https://developer.roblox.com/en-us/api-reference/function/HttpService/JSONDecode).
function TableUtil.DecodeJSON(str: string): any
	return HttpService:JSONDecode(str)
end

return TableUtil
