-- TODO #3
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HittableService = {}
HittableService.__index = HittableService

--- TODO: Rewrite
export type HittableService = typeof(setmetatable({} :: {}, HittableService))

export type HitResult = {
	Position: Vector3,
	Velocity: Vector3,
	Part: BasePart,
}

type HitCallback = (hit: HitResult) -> ()

local registeredParts: { [BasePart]: HitCallback } = {}
local hittableRE
local isServer = RunService:IsServer()

function HittableService.new(): HittableService
	local self: HittableService = setmetatable({}, HittableService) :: any

	if isServer then
		hittableRE = Instance.new("RemoteEvent")
		hittableRE.Name = "HittableRE"
		hittableRE.Parent = ReplicatedStorage

		hittableRE.OnServerEvent:Connect(
			function(_, hit: HitResult) silentHit(hit) end
		)
	else
		hittableRE = ReplicatedStorage:WaitForChild("HittableRE") :: RemoteEvent

		hittableRE.OnClientEvent:Connect(
			function(hit: HitResult) silentHit(hit) end
		)
	end

	return self
end

function silentHit(hit: HitResult)
	if registeredParts[hit.Part] then registeredParts[hit.Part](hit) end
end

function HittableService:Register(
	parts: BasePart | { BasePart },
	callback: HitCallback
)
	if typeof(parts) == "table" then
		for _, part in parts do
			registeredParts[part] = callback
		end
	else
		registeredParts[parts] = callback
	end
end

function HittableService:Hit(
	parts: BasePart | { BasePart },
	position: Vector3,
	velocity: Vector3
)
	if typeof(parts) == "table" then
		for _, part in parts do
			self:Hit(part, position, velocity)
		end
		return
	end

	local hit = { Part = parts, Position = position, Velocity = velocity }
	silentHit(hit)

	if isServer then
		hittableRE:FireAllClients(hit)
	else
		hittableRE:FireServer(hit)
	end
end

return HittableService.new()
