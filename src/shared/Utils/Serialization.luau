--!native

--[[
	Low-level serialization library

	Functions:

		Serialization.Packet(params): Packet -- Maximum 255 fields
			params:
				{
					["FieldName"]: PacketType,
					...
				}

		-- "Serialize", "Push", "DeltaSerialize" and "DeltaPush" will return first argument if succeeded,
		-- Or return an error message as the second argument if failed.

		-- When all fields are present (Non-packet fields are ignored; Missing fields will throw an error):

		Serialization.Deserialize(packet: Packet, b: buffer, offset: number?): ({[string]: any}, offset: number)
		Serialization.Serialize(packet: Packet, t: {[string]: any}): (buffer?, err: string?)
		Serialization.Push(packet: Packet, t: {[string]: any}, b: buffer, offset: number?): (offset: number?, err: string?)

		-- When only some fields are present (Non-packet fields will throw an error):

		Serialization.DeltaDeserialize(packet: Packet, b: buffer, offset: number?): ({[string]: any}, offset: number)
		Serialization.DeltaSerialize(packet: Packet, t: {[string]: any}): (buffer?, err: string?)
		Serialization.DeltaPush(packet: Packet, t: {[string]: any}, b: buffer, offset: number?): (offset: number?, err: string?)

		-- Delta serialization has an additional size cost of (n + 1) bytes where "n" is the number of fields present
		-- in a table that's being serialized (1 byte for present field count, 1 enumerating byte for each field)

--]]
local Serialization = {}

--- Serialization will fail if resulting buffer size is larger than this value
local BIG_BUFFER_SIZE = 2 ^ 20

local MAX_FIELDS = 2 ^ 8 - 1

local BB = buffer.create(BIG_BUFFER_SIZE) -- Big reusable buffer
Serialization.BB = BB

----- Public -----

export type Ser = (b: buffer, offset: number, value: any) -> number
export type Des = (b: buffer, offset: number) -> (any, number)

export type PacketType = {
	Name: string,
	Ser: Ser,
	Des: Des,
}

type Field = { Key: string, Name: string, Ser: Ser, Des: Des, Index: number }
type Serializable = { Serialize: (self: Serializable) -> buffer }

export type Packet = {
	Numeric: { Field },
	String: { [string]: Field },
}

--- Serializes a boolean
---
--- Resulting size is 1 bit
Serialization.Boolean = table.freeze({
	Name = "Boolean",
	Ser = function(b: buffer, offset: number, value: boolean?): number
		buffer.writebits(b, offset, 1, value and 1 or 0)
		return offset + 1
	end,
	Des = function(b: buffer, offset: number): (boolean, number)
		return buffer.readbits(b, offset, 1) == 1, offset + 1
	end,
})

--- Serializes an unsigned integer
Serialization.Uint = function(bitCount: number)
	return table.freeze({
		Name = "Uint",
		Ser = function(b: buffer, offset: number, value: number): number
			buffer.writebits(b, offset, bitCount, value)
			return offset + bitCount
		end,
		Des = function(b: buffer, offset: number): (number, number)
			return buffer.readbits(b, offset, bitCount), offset + bitCount
		end,
	})
end

--- Serializes a signed integer
Serialization.Int = function(bitCount: number)
	return table.freeze({
		Name = "Int",
		Ser = function(b: buffer, offset: number, value: number): number
			buffer.writebits(b, offset, bitCount, value + 2 ^ (bitCount - 1))
			return offset + bitCount
		end,
		Des = function(b: buffer, offset: number): (number, number)
			return buffer.readbits(b, offset, bitCount) - 2 ^ (bitCount - 1),
				offset + bitCount
		end,
	})
end

--- Inputs a `[0, 1]` range value and converts to `[0, (2^bitCount-1)]` integer
Serialization.Percent = function(bitCount: number)
	return table.freeze({
		Name = "Int",
		Ser = function(b: buffer, offset: number, value: number): number
			buffer.writebits(b, offset, bitCount, value * (2 ^ bitCount - 1))
			return offset + bitCount
		end,
		Des = function(b: buffer, offset: number): (number, number)
			return buffer.readbits(b, offset, bitCount) / (2 ^ bitCount - 1),
				offset + bitCount
		end,
	})
end

--- Inputs a `[min, max]` range value and converts to `[0, (2^bitCount-1)]` integer
Serialization.MappedNumber = function(
	min: number,
	max: number,
	bitCount: number
)
	return table.freeze({
		Name = "MappedNumber",
		Ser = function(b: buffer, offset: number, value: number): number
			buffer.writebits(
				b,
				offset,
				bitCount,
				math.map(value, min, max, 0, 2 ^ bitCount - 1)
			)
			return offset + bitCount
		end,
		Des = function(b: buffer, offset: number): (number, number)
			return math.map(
				buffer.readbits(b, offset, bitCount),
				0,
				2 ^ bitCount - 1,
				min,
				max
			),
				offset + bitCount
		end,
	})
end

function floatToBinary(value: number): number
	if value == 0 then return 0 end
	local sign = 0
	if value < 0 then sign = 1 end
	local mantissa, exponent = math.frexp(value)
	mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
	exponent = exponent + 126
	return math.round(2 ^ 31 * sign + 2 ^ 23 * exponent + mantissa)
end

function binaryToFloat(value: number): number
	local sign = bit32.extract(value, 31) == 1 and -1 or 0
	local mantissa = bit32.extract(value, 0, 23)
	local exponent = bit32.extract(value, 24, 7) * 2
		+ math.floor(bit32.extract(value, 16, 8) / 128)
	if exponent == 0 then return 0 end
	mantissa = (math.ldexp(mantissa, -23) + 1) * sign
	return math.ldexp(mantissa, exponent - 127)
end

--- Serializes a floating point number
---
--- Resulting size is 4 bytes / 32 bits
Serialization.Float = table.freeze({
	Name = "Float",
	Ser = function(b: buffer, offset: number, value: number): number
		buffer.writebits(b, offset, 32, floatToBinary(value))
		return offset + 32
	end,
	Des = function(b: buffer, offset: number): (number, number)
		return binaryToFloat(buffer.readbits(b, offset, 32)), offset + 32
	end,
})

--- Serializes state
Serialization.State = function(states: { string })
	local _, bitCount = math.frexp(#states - 1)
	return table.freeze({
		Name = "State",
		Ser = function(b: buffer, offset: number, value: string): number
			local index = table.find(states, value)
			assert(index, `State not found`)

			buffer.writebits(b, offset, bitCount, index - 1)
			return offset + bitCount
		end,
		Des = function(b: buffer, offset: number): (string, number)
			return states[buffer.readbits(b, offset, bitCount) + 1],
				offset + bitCount
		end,
	})
end

--- Serializes Vector3 with high precision
---
--- Resulting size is 12 bytes / 96 bits
Serialization.Vector3f = table.freeze({
	Name = "Vector3f",
	Ser = function(b: buffer, offset: number, value: Vector3): number
		buffer.writebits(b, offset, 32, binaryToFloat(value.X))
		buffer.writebits(b, offset + 32, 32, binaryToFloat(value.Y))
		buffer.writebits(b, offset + 64, 32, binaryToFloat(value.Z))
		return offset + 96
	end,
	Des = function(b: buffer, offset: number): (Vector3, number)
		return Vector3.new(
			buffer.readbits(b, offset, 32),
			buffer.readbits(b, offset + 32, 32),
			buffer.readbits(b, offset + 64, 32)
		),
			offset + 96
	end,
})

--- Serializes Vector3 with integer points
---
--- Resulting size is `bitCount * 3` bits
Serialization.Vector3i = function(bitCount: number)
	return table.freeze({
		Name = "Vector3i",
		Ser = function(b: buffer, offset: number, value: Vector3): number
			buffer.writebits(b, offset, bitCount, value.X - 2 ^ bitCount)
			buffer.writebits(
				b,
				offset + bitCount,
				bitCount,
				value.Y - 2 ^ bitCount
			)
			buffer.writebits(
				b,
				offset + bitCount * 2,
				bitCount,
				value.Z - 2 ^ bitCount
			)
			return offset + bitCount * 3
		end,
		Des = function(b: buffer, offset: number): (Vector3, number)
			return Vector3.new(
				buffer.readbits(b, offset, bitCount) + 2 ^ bitCount,
				buffer.readbits(b, offset + bitCount, bitCount) + 2 ^ bitCount,
				buffer.readbits(b, offset + bitCount * 2, bitCount)
					+ 2 ^ bitCount
			),
				offset + bitCount * 3
		end,
	})
end

--- Serializes Vector3 with unsigned integer points
---
--- Resulting size is `bitCount * 3` bits
Serialization.Vector3u = function(bitCount: number)
	return table.freeze({
		Name = "Vector3u",
		Ser = function(b: buffer, offset: number, value: Vector3): number
			buffer.writebits(b, offset, bitCount, value.X)
			buffer.writebits(b, offset + bitCount, bitCount, value.Y)
			buffer.writebits(b, offset + bitCount * 2, bitCount, value.Z)
			return offset + bitCount * 3
		end,
		Des = function(b: buffer, offset: number): (Vector3, number)
			return Vector3.new(
				buffer.readbits(b, offset, bitCount),
				buffer.readbits(b, offset + bitCount, bitCount),
				buffer.readbits(b, offset + bitCount * 2, bitCount)
			),
				offset + bitCount * 3
		end,
	})
end

--- Inputs a `[min, max]` range Vector3 and converts it to `[0, 2 ^ bitCount]` Vector3
---
--- Resulting size is `bitCount * 3` bits
Serialization.MappedVector3 = function(
	min: Vector3,
	max: Vector3,
	bitCount: number
)
	return table.freeze({
		Name = "MappedVector3",
		Ser = function(b: buffer, offset: number, value: Vector3): number
			buffer.writebits(
				b,
				offset,
				bitCount,
				math.map(value.X, min.X, max.X, 0, 2 ^ bitCount - 1)
			)
			buffer.writebits(
				b,
				offset + bitCount,
				bitCount,
				math.map(value.Y, min.Y, max.Y, 0, 2 ^ bitCount - 1)
			)
			buffer.writebits(
				b,
				offset + bitCount * 2,
				bitCount,
				math.map(value.Z, min.Z, max.Z, 0, 2 ^ bitCount - 1)
			)
			return offset + bitCount * 3
		end,
		Des = function(b: buffer, offset: number): (Vector3, number)
			return Vector3.new(
				math.map(
					buffer.readbits(b, offset, bitCount),
					0,
					2 ^ bitCount - 1,
					min.X,
					max.X
				),
				math.map(
					buffer.readbits(b, offset + bitCount, bitCount),
					0,
					2 ^ bitCount - 1,
					min.Y,
					max.Y
				),
				math.map(
					buffer.readbits(b, offset + bitCount * 2, bitCount),
					0,
					2 ^ bitCount - 1,
					min.Z,
					max.Z
				)
			),
				offset + bitCount * 3
		end,
	})
end

--- Serializes Color3
---
--- Resulting size is `bitCount * 3` bits
Serialization.Color3 = function(bitCount: number)
	return table.freeze({
		Name = "Color3",
		Ser = function(b: buffer, offset: number, value: Color3): number
			buffer.writebits(
				b,
				offset,
				bitCount,
				math.ldexp(value.R, bitCount) - 1
			)
			buffer.writebits(
				b,
				offset + bitCount,
				bitCount,
				math.ldexp(value.G, bitCount) - 1
			)
			buffer.writebits(
				b,
				offset + bitCount * 2,
				bitCount,
				math.ldexp(value.B, bitCount) - 1
			)
			return offset + bitCount * 3
		end,
		Des = function(b: buffer, offset: number): (Color3, number)
			return Color3.fromRGB(
				buffer.readbits(b, offset, bitCount),
				buffer.readbits(b, offset + bitCount, bitCount),
				buffer.readbits(b, offset + bitCount * 2, bitCount)
			),
				offset + bitCount * 3
		end,
	})
end

--- Serializes string
Serialization.String = function(maxLength: number)
	local _, bitCount = math.frexp(maxLength)
	return table.freeze({
		Name = "String",
		Ser = function(b: buffer, offset: number, value: string): number
			local length = string.len(value)
			buffer.writebits(b, offset, bitCount, length)
			for i = 1, length do
				buffer.writebits(
					b,
					offset + bitCount + (i - 1) * 8,
					8,
					string.byte(value, i)
				)
			end
			return offset + bitCount + length * 8
		end,
		Des = function(b: buffer, offset: number): (string, number)
			local length = buffer.readbits(b, offset, bitCount)
			local s = ""
			for i = 1, length do
				s ..= string.char(
					buffer.readbits(b, offset + bitCount + (i - 1) * 8, 8)
				)
			end
			return s, offset + bitCount + length * 8
		end,
	})
end

--- Serializes a CFrame with high precision
---
--- Resulting size is 48 bytes / 384 bits
Serialization.CFrame32f = table.freeze({
	Name = "CFrame",
	Ser = function(b: buffer, offset: number, value: CFrame): number
		local v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11 =
			value:GetComponents()
		buffer.writebits(b, offset + 32 * 0, 32, floatToBinary(v0))
		buffer.writebits(b, offset + 32 * 1, 32, floatToBinary(v1))
		buffer.writebits(b, offset + 32 * 2, 32, floatToBinary(v2))
		buffer.writebits(b, offset + 32 * 3, 32, floatToBinary(v3))
		buffer.writebits(b, offset + 32 * 4, 32, floatToBinary(v4))
		buffer.writebits(b, offset + 32 * 5, 32, floatToBinary(v5))
		buffer.writebits(b, offset + 32 * 6, 32, floatToBinary(v6))
		buffer.writebits(b, offset + 32 * 7, 32, floatToBinary(v7))
		buffer.writebits(b, offset + 32 * 8, 32, floatToBinary(v8))
		buffer.writebits(b, offset + 32 * 9, 32, floatToBinary(v9))
		buffer.writebits(b, offset + 32 * 10, 32, floatToBinary(v10))
		buffer.writebits(b, offset + 32 * 11, 32, floatToBinary(v11))
		return offset + 32 * 12
	end,
	Des = function(b: buffer, offset: number): (CFrame, number)
		return CFrame.new(
			buffer.readbits(b, offset + 32 * 0, 32),
			buffer.readbits(b, offset + 32 * 1, 32),
			buffer.readbits(b, offset + 32 * 2, 32),
			buffer.readbits(b, offset + 32 * 3, 32),
			buffer.readbits(b, offset + 32 * 4, 32),
			buffer.readbits(b, offset + 32 * 5, 32),
			buffer.readbits(b, offset + 32 * 6, 32),
			buffer.readbits(b, offset + 32 * 7, 32),
			buffer.readbits(b, offset + 32 * 8, 32),
			buffer.readbits(b, offset + 32 * 9, 32),
			buffer.readbits(b, offset + 32 * 10, 32),
			buffer.readbits(b, offset + 32 * 11, 32)
		),
			offset + 32 * 12
	end,
})

--- Serializes a CFrame with 0.0005 degree precision error for rotation
---
--- Resulting size is 28 bytes or 224 bits
Serialization.LossyCFrame32f = table.freeze({
	Name = "LossyCFrame",
	Ser = function(b: buffer, offset: number, value: CFrame): number
		local axis, angle = value:ToAxisAngle()
		buffer.writebits(b, offset + 32 * 0, 32, value.X)
		buffer.writebits(b, offset + 32 * 1, 32, value.Y)
		buffer.writebits(b, offset + 32 * 2, 32, value.Z)
		buffer.writebits(b, offset + 32 * 3, 32, axis.X)
		buffer.writebits(b, offset + 32 * 4, 32, axis.Y)
		buffer.writebits(b, offset + 32 * 5, 32, axis.Z)
		buffer.writebits(b, offset + 32 * 6, 32, angle)
		return offset + 32 * 7
	end,
	Des = function(b: buffer, offset: number): (CFrame, number)
		return CFrame.fromAxisAngle(
			Vector3.new(
				buffer.readbits(b, offset + 32 * 3, 32),
				buffer.readbits(b, offset + 32 * 4, 32),
				buffer.readbits(b, offset + 32 * 5, 32)
			),
			buffer.readbits(b, offset + 32 * 6, 32)
		) + Vector3.new(
			buffer.readbits(b, offset + 32 * 0, 32),
			buffer.readbits(b, offset + 32 * 1, 32),
			buffer.readbits(b, offset + 32 * 2, 32)
		),
			offset + 32 * 7
	end,
})

local function PushUnsafe(
	packet: Packet,
	t: { [string]: any },
	b: buffer,
	offset: number
): number
	for _, field in packet.Numeric do
		offset = field.Ser(b, offset, t[field.Key])
	end

	return offset
end

--- Pushes serialized packet to an existing buffer; Returns new buffer offset or error message if fail.
function Serialization.Push(
	packet: Packet,
	t: any,
	b: buffer,
	offset: number?
): (number?, string?)
	offset = offset or 0
	local original_offset = offset :: number
	local success
	success, offset = pcall(PushUnsafe, packet, t, b, offset :: number)

	if not success then
		local ser_success
		offset = original_offset

		for _, field in packet.Numeric do
			local value = t[field.Key]

			if value ~= nil then
				ser_success, offset =
					pcall(field.Ser, b, offset :: number, value)
				if not ser_success then
					return nil,
						`Couldn't serialize field "{field.Key}" (Expected: {field.Name};Received: "{typeof(
							value
						)}"); Message: {offset}`
				end
			else
				return nil, `Missing field "{field.Key}"`
			end
		end

		return nil, `Unknown error`
	end

	return offset
end

--- Returns dictionary of deserialized packet.
function Serialization.Deserialize(
	packet: Packet,
	b: buffer,
	offset: number?
): ({ [string]: any }, number)
	offset = offset or 0
	local result = {}

	for _, field in packet.Numeric do
		result[field.Key], offset = field.Des(b, offset :: number)
	end

	return result, offset :: number
end

do
	local rad2 = math.pi * 2
	local angle8range = math.rad(359)

	local function DegEncode(deg: number): number
		return math.round((deg % rad2) * 255 / angle8range)
	end

	local DegDecodeLookup: { number } = {}

	for i = 0, 255 do
		DegDecodeLookup[i] = i * angle8range / 255
	end

	for i = 0, 315, 45 do
		local r = math.rad(i)
		local index = DegEncode(r)
		DegDecodeLookup[index] = r
	end

	--- (Unsigned) Radian representation in one byte while preserving cardinal direction accuracy (Every 45 degrees)
	Serialization.Angle8 = table.freeze({
		Name = "Angle8",
		Ser = function(b: buffer, offset: number, value: number): number
			buffer.writebits(b, offset, 8, DegEncode(value))
			return offset + 8
		end,
		Des = function(b: buffer, offset: number): (number, number)
			return DegDecodeLookup[buffer.readbits(b, offset, 8)], offset + 8
		end,
	})
end

local function SerializeUnsafe(packet: Packet, t: { [string]: any }): number
	local offset = 0

	for _, field in packet.Numeric do
		offset = field.Ser(BB, offset, t[field.Key])
	end

	return offset
end

--- Returns new buffer of serialized packet or error message if fail.
function Serialization.Serialize(packet: Packet, t: any): (buffer?, string?)
	local success, offset = pcall(SerializeUnsafe, packet, t)

	if not success then
		local ser_success
		offset = 0

		for _, field in packet.Numeric do
			local value = t[field.Key]

			if value ~= nil then
				ser_success, offset = pcall(field.Ser, BB, offset, value)
				if not ser_success then
					error(
						`Couldn't serialize field "{field.Key}" (Expected: {field.Name};Received: "{typeof(
							value
						)}"); Message: {offset}`
					)
				end
			else
				error(`Missing field "{field.Key}"`)
			end
		end

		error(`Unknown error`)
	end

	local size = math.ceil(offset / 8)
	local b = buffer.create(size)
	buffer.copy(b, 0, BB, 0, size)

	return b
end

--- Returns dictionary of deserialized deltas.
function Serialization.DeltaDeserialize(
	packet: Packet,
	b: buffer,
	offset: number?
): ({ [string]: any }, number)
	offset = (offset or 0) + 1
	local field_count = buffer.readu8(b, offset :: number - 1)
	local result = {}

	local lookup = packet.Numeric

	for _ = 1, field_count do
		local field = lookup[buffer.readu8(b, offset :: number)]
		result[field.Key], offset = field.Des(b, offset :: number + 1)
	end

	return result, offset :: number
end

local function DeltaSerializeUnsafe(
	packet: Packet,
	t: { [string]: any }
): number
	local field_count = 0
	local offset = 1

	local lookup = packet.String

	for key in t do
		field_count += 1
		local field = lookup[key]
		buffer.writeu8(BB, offset, field.Index)
		offset = field.Ser(BB, offset + 1, t[field.Key])
	end

	buffer.writeu8(BB, 0, field_count)

	return offset
end

--- Returns new buffer of serialized deltas or error message if fail.
function Serialization.DeltaSerialize(
	packet: Packet,
	t: any
): (buffer?, string?)
	local success, offset = pcall(DeltaSerializeUnsafe, packet, t)

	if not success then
		local ser_success
		offset = 1

		local lookup = packet.String

		for key, value in t do
			local field = lookup[key]

			if field == nil then
				return nil, `Key "{key}" not specified in packet`
			end

			buffer.writeu8(BB, offset, field.Index)
			ser_success, offset = pcall(field.Ser, BB, offset + 1, value)
			if not ser_success then
				return nil,
					`Couldn't serialize field "{field.Key}" (Expected: {field.Name};Received: "{typeof(
						value
					)}"); Message: {offset}`
			end
		end

		return nil, `Unknown error`
	end

	local b = buffer.create(offset)
	buffer.copy(b, 0, BB, 0, offset)

	return b
end

local function DeltaPushUnsafe(
	packet: Packet,
	t: { [string]: any },
	b: buffer,
	offset: number
): number
	local field_count = 0
	local start_offset = offset
	offset += 1

	local lookup = packet.String

	for key in t do
		field_count += 1
		local field = lookup[key]
		buffer.writeu8(b, offset, field.Index)
		offset = field.Ser(b, offset + 1, t[field.Key])
	end

	buffer.writeu8(b, start_offset, field_count)

	return offset
end

--- Pushes serialized deltas to an existing buffer; Returns new buffer offset or error message if fail.
function Serialization.DeltaPush(
	packet: Packet,
	t: any,
	b: buffer,
	offset: number?
): (number?, string?)
	offset = offset or 0
	local success
	success, offset = pcall(DeltaPushUnsafe, packet, t, b, offset :: number)

	if not success then
		local ser_success
		offset = 1

		local lookup = packet.String

		for key, value in t do
			local field = lookup[key]

			if field == nil then
				return nil, `Key "{key}" not specified in packet`
			end

			buffer.writeu8(b, offset :: number, field.Index)
			ser_success, offset =
				pcall(field.Ser, b, offset :: number + 1, value)
			if not ser_success then
				return nil,
					`Couldn't serialize field "{field.Key}" (Expected: {field.Name};Received: "{typeof(
						value
					)}"); Message: {offset}`
			end
		end

		return nil, `Unknown error`
	end

	return offset
end

function Serialization.Packet(
	params: { [string]: PacketType }
): Packet & PacketType
	local fields: { Field } = {}

	for key, sera_type: PacketType in params do
		if typeof(key) ~= "string" then
			error(
				`[{script.Name}]: Expected string for field name; Received "{typeof(
					key
				)}"`
			)
		end
		if
			typeof(sera_type) ~= "table"
			or typeof(sera_type.Ser) ~= "function"
			or typeof(sera_type.Des) ~= "function"
			or typeof(sera_type.Name) ~= "string"
		then
			error(`[{script.Name}]: Expected SeraType for field "{key}"`)
		end
		table.insert(fields, {
			Key = key,
			Name = sera_type.Name,
			Ser = sera_type.Ser,
			Des = sera_type.Des,
			Index = 0,
		})
	end

	if #fields == 0 then error(`[{script.Name}]: Packet must have fields`) end

	if #fields > MAX_FIELDS then
		error(
			`[{script.Name}]: Packet exceeded {MAX_FIELDS} fields; Received {#fields} fields`
		)
	end

	table.sort(fields, function(a, b) return a.Key < b.Key end)

	local string_fields: { [string]: Field } = {}

	for index, field in fields do
		field.Index = index
		string_fields[field.Key] = field
	end

	return table.freeze({
		Name = "Packet",
		Ser = function(
			b: buffer,
			offset: number,
			value: { [string]: any }
		): number
			for _, field in fields do
				offset = field.Ser(b, offset, value[field.Key])
			end
			return offset
		end,
		Des = function(
			b: buffer,
			offset: number
		): ({ [string]: any }, number)
			return Serialization.Deserialize(
				{ Numeric = fields, String = string_fields },
				b,
				offset
			)
		end,
		Numeric = fields,
		String = string_fields,
	})
end

return table.freeze(Serialization)
