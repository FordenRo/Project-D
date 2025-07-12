local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HittableService = {}
HittableService.__index = HittableService

export type HittableService = typeof(setmetatable({} :: {}, HittableService))

export type HitResult = {
	Origin: Vector3,
	Velocity: Vector3,
	Part: BasePart,
}

type HitCallback = (hit: HitResult) -> ()

local registeredParts: { [BasePart]: HitCallback } = {}
local hittableRE = ReplicatedStorage.Events.Hittable
local isServer = RunService:IsServer()

function HittableService.new(): HittableService
	local self = setmetatable({}, HittableService)

	if isServer then
		hittableRE.OnServerEvent:Connect(function(_, hit: HitResult) silentHit(hit) end)
	else
		hittableRE.OnClientEvent:Connect(function(hit: HitResult) silentHit(hit) end)
	end

	return self
end

function silentHit(hit: HitResult)
	if registeredParts[hit.Part] then registeredParts[hit.Part](hit) end
end

function HittableService:Register(parts: BasePart | { BasePart }, callback: HitCallback)
	if typeof(parts) == "table" then
		for _, part in parts do
			registeredParts[part] = callback
		end
	else
		registeredParts[parts] = callback
	end
end

function HittableService:Hit(hit: HitResult)
	silentHit(hit)

	if isServer then
		hittableRE:FireAllClients(hit)
	else
		hittableRE:FireServer(hit)
	end
end

return HittableService.new()
