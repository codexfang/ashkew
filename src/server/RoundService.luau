--!strict
-- The round loop: Intermission -> Stage 1..N -> Escaped or Folded -> Intermission.
--
-- Round state is published as attributes on ReplicatedStorage so any client UI can read it:
--   Phase      "Waiting" | "Intermission" | "Stage" | "Escaped" | "Folded"
--   TimeLeft   seconds left in the current phase
--   Meter      anomaly meter, 0..Config.MeterMax
--   Stage      current stage number
--   StageCount stages needed to escape

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Anomalies = require(ReplicatedStorage.Shared.Anomalies)
local Config = require(ReplicatedStorage.Shared.Config)
local PerceptionService = require(script.Parent.PerceptionService)
local StageGenerator = require(script.Parent.StageGenerator)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StageResult = Remotes:WaitForChild("StageResult") :: RemoteEvent

local RoundService = {}

-- Server-side signals so other services (voting) can follow the round without
-- RoundService needing to know about them.
RoundService.StageStarted = Instance.new("BindableEvent")
RoundService.StageEnded = Instance.new("BindableEvent")

local rng = Random.new()
local meter = 0
local currentStage: StageGenerator.Stage? = nil
local stageResult: boolean? = nil -- set by resolveStage(); nil while undecided

local function setState(name: string, value: any)
	ReplicatedStorage:SetAttribute(name, value)
end

local function setMeter(value: number)
	meter = math.clamp(value, 0, Config.MeterMax)
	setState("Meter", meter)
end

local function realIntensity(elapsed: number): number
	-- Creeps up over the stage, and a fuller meter makes it start worse.
	local fromTime = elapsed / Config.StageSeconds
	local fromMeter = meter / Config.MeterMax
	local t = math.clamp(fromTime * 0.7 + fromMeter * 0.3, 0, 1)
	return Anomalies.DECOY_INTENSITY + (1 - Anomalies.DECOY_INTENSITY) * t
end

local function pushStageViews(stage: StageGenerator.Stage, elapsed: number)
	for _, player in Players:GetPlayers() do
		local decoyId = stage.decoys[player]
		if player == stage.holder then
			PerceptionService.setView(player, { { id = stage.realId, intensity = realIntensity(elapsed) } })
		elseif decoyId then
			PerceptionService.setView(player, { { id = decoyId, intensity = Anomalies.DECOY_INTENSITY } })
		else
			PerceptionService.setView(player, {})
		end
	end
end

local function countdown(phase: string, seconds: number)
	setState("Phase", phase)
	for t = seconds, 1, -1 do
		setState("TimeLeft", t)
		task.wait(1)
	end
	setState("TimeLeft", 0)
end

-- Runs one stage. Returns true if the team got it right.
local function runStage(stage: StageGenerator.Stage): boolean
	currentStage = stage
	stageResult = nil
	setState("Phase", "Stage")
	RoundService.StageStarted:Fire()

	local elapsed = 0
	while stageResult == nil and elapsed < Config.StageSeconds and meter < Config.MeterMax do
		setState("TimeLeft", math.ceil(Config.StageSeconds - elapsed))
		pushStageViews(stage, elapsed)
		task.wait(1)
		elapsed += 1
		setMeter(meter + Config.MeterPassivePerSecond)
	end

	currentStage = nil
	-- Running out the clock counts as getting it wrong.
	local correct = stageResult == true
	if not correct then
		setMeter(meter + Config.MeterWrongVote)
	end
	RoundService.StageEnded:Fire(correct)

	-- Reveal the truth to everyone: which object it was and who was seeing it.
	local real = Anomalies.byId[stage.realId]
	StageResult:FireAllClients({
		correct = correct,
		objectId = if real then real.objectId else stage.realId,
		description = if real then real.description else stage.realId,
		holderName = stage.holder.DisplayName,
	})
	task.wait(Config.RevealSeconds)
	return correct
end

local function runRound()
	setMeter(Config.MeterStart)
	setState("StageCount", Config.AnomaliesToEscape)

	local usedRealIds: { [string]: boolean } = {}
	local cleared = 0

	while cleared < Config.AnomaliesToEscape and meter < Config.MeterMax do
		local stage = StageGenerator.generate(Players:GetPlayers(), usedRealIds, rng)
		if not stage then
			break -- everyone left
		end
		usedRealIds[stage.realId] = true
		setState("Stage", cleared + 1)

		if runStage(stage) then
			cleared += 1
		end
		PerceptionService.clearAll()
	end

	PerceptionService.clearAll()
	local escaped = cleared >= Config.AnomaliesToEscape
	countdown(if escaped then "Escaped" else "Folded", Config.ResultSeconds)
end

-- Called by the vote system once the team commits to an answer.
function RoundService.resolveStage(correct: boolean)
	if currentStage and stageResult == nil then
		stageResult = correct
	end
end

function RoundService.getCurrentStage(): StageGenerator.Stage?
	return currentStage
end

function RoundService.start()
	setMeter(0)
	task.spawn(function()
		while true do
			setState("Phase", "Waiting")
			while #Players:GetPlayers() < Config.MinPlayers do
				task.wait(1)
			end
			countdown("Intermission", Config.IntermissionSeconds)
			if #Players:GetPlayers() >= Config.MinPlayers then
				runRound()
			end
		end
	end)
end

return RoundService
