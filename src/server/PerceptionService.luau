--!strict
-- Decides what each player sees. The server is the only source of truth for who has
-- which anomaly; clients are just told their own view and never see anyone else's.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Anomalies = require(ReplicatedStorage.Shared.Anomalies)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PerceptionAssigned = Remotes:WaitForChild("PerceptionAssigned") :: RemoteEvent
local ClientReady = Remotes:WaitForChild("ClientReady") :: RemoteEvent

local PerceptionService = {}

local views: { [Player]: { string } } = {}
local ready: { [Player]: boolean } = {}
local rng = Random.new()

local function push(player: Player)
	if ready[player] then
		PerceptionAssigned:FireClient(player, views[player] or {})
	end
end

-- Picks an anomaly no other player currently has, so every view is different.
local function pickUnusedAnomaly(): string
	local used: { [string]: boolean } = {}
	for _, ids in views do
		for _, id in ids do
			used[id] = true
		end
	end

	local candidates = {}
	for _, anomaly in Anomalies.list do
		if not used[anomaly.id] then
			table.insert(candidates, anomaly.id)
		end
	end
	if #candidates == 0 then
		return Anomalies.list[rng:NextInteger(1, #Anomalies.list)].id
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

function PerceptionService.setView(player: Player, anomalyIds: { string })
	views[player] = anomalyIds
	push(player)
end

function PerceptionService.getView(player: Player): { string }
	return views[player] or {}
end

function PerceptionService.start()
	-- Clients announce when their listener is connected, so nothing gets fired into the void.
	ClientReady.OnServerEvent:Connect(function(player)
		ready[player] = true
		if not views[player] then
			views[player] = { pickUnusedAnomaly() }
		end
		push(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		views[player] = nil
		ready[player] = nil
	end)
end

return PerceptionService
