--!strict
-- Players vote for the room object they believe holds the real anomaly.
--
-- * Votes can be changed freely until they lock.
-- * The first vote of a stage starts a Config.VoteSeconds countdown.
-- * Votes lock early if every player has voted for the same object.
-- * When they lock, the most-voted object is the team's answer. A tie is a wrong answer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Anomalies = require(ReplicatedStorage.Shared.Anomalies)
local Config = require(ReplicatedStorage.Shared.Config)
local RoundService = require(script.Parent.RoundService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CastVote = Remotes:WaitForChild("CastVote") :: RemoteEvent
local VoteUpdate = Remotes:WaitForChild("VoteUpdate") :: RemoteEvent

local VoteService = {}

local votes: { [Player]: string } = {}
local deadline: number? = nil -- server time when votes lock
local open = false

local function isRoomObject(objectId: string): boolean
	local room = workspace:FindFirstChild("Room")
	local objects = room and room:FindFirstChild("Objects")
	local model = objects and objects:FindFirstChild(objectId)
	return model ~= nil and model:IsA("Model")
end

local function tally(): ({ [string]: number }, number)
	local counts: { [string]: number } = {}
	local voted = 0
	for player, objectId in votes do
		if player.Parent == Players then
			counts[objectId] = (counts[objectId] or 0) + 1
			voted += 1
		end
	end
	return counts, voted
end

local function broadcast()
	local counts, voted = tally()
	VoteUpdate:FireAllClients({
		open = open,
		counts = counts,
		voted = voted,
		playerCount = #Players:GetPlayers(),
		deadline = deadline,
	})
end

-- Returns the single most-voted object, or nil on a tie / no votes.
local function winner(): string?
	local counts = tally()
	local best: string? = nil
	local bestCount = 0
	local tied = false
	for objectId, count in counts do
		if count > bestCount then
			best, bestCount, tied = objectId, count, false
		elseif count == bestCount then
			tied = true
		end
	end
	return if tied then nil else best
end

local function lock()
	if not open then
		return
	end
	open = false
	local answer = winner()
	local stage = RoundService.getCurrentStage()
	local correct = false
	if answer and stage then
		local real = Anomalies.byId[stage.realId]
		correct = real ~= nil and real.objectId == answer
	end
	broadcast()
	RoundService.resolveStage(correct)
end

local function everyoneAgrees(): boolean
	local counts, voted = tally()
	if voted < #Players:GetPlayers() then
		return false
	end
	local distinct = 0
	for _ in counts do
		distinct += 1
	end
	return distinct == 1
end

local function onVote(player: Player, objectId: unknown)
	if not open or typeof(objectId) ~= "string" or not isRoomObject(objectId) then
		return
	end
	votes[player] = objectId

	if not deadline then
		deadline = workspace:GetServerTimeNow() + Config.VoteSeconds
		local thisDeadline = deadline
		task.delay(Config.VoteSeconds, function()
			-- Only lock if this is still the same vote (the stage may have ended already).
			if open and deadline == thisDeadline then
				lock()
			end
		end)
	end

	broadcast()
	if everyoneAgrees() then
		lock()
	end
end

function VoteService.start()
	CastVote.OnServerEvent:Connect(onVote)

	RoundService.StageStarted.Event:Connect(function()
		table.clear(votes)
		deadline = nil
		open = true
		broadcast()
	end)

	RoundService.StageEnded.Event:Connect(function()
		open = false
		deadline = nil
		table.clear(votes)
		broadcast()
	end)

	Players.PlayerRemoving:Connect(function(player)
		votes[player] = nil
		if open then
			broadcast()
		end
	end)
end

return VoteService
