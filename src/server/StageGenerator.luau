--!strict
-- Rolls one stage of a round: which anomaly is real, who sees it, and who gets decoys.
-- The real anomaly always goes to exactly one player. Everyone else may get a different,
-- static decoy (or nothing), so the team can't just trust whoever speaks first.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Anomalies = require(ReplicatedStorage.Shared.Anomalies)
local Config = require(ReplicatedStorage.Shared.Config)

export type Stage = {
	realId: string,
	holder: Player,
	decoys: { [Player]: string },
}

local StageGenerator = {}

local function shuffled<T>(items: { T }, rng: Random): { T }
	local copy = table.clone(items)
	for i = #copy, 2, -1 do
		local j = rng:NextInteger(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

-- `usedRealIds` holds anomalies already used as the real one this round, so a round
-- never repeats its answer. Returns nil if there are no players.
function StageGenerator.generate(players: { Player }, usedRealIds: { [string]: boolean }, rng: Random): Stage?
	if #players == 0 then
		return nil
	end

	local pool = shuffled(Anomalies.list, rng)

	local realId: string? = nil
	for _, anomaly in pool do
		if not usedRealIds[anomaly.id] then
			realId = anomaly.id
			break
		end
	end
	-- Every anomaly has been the answer already; allow repeats rather than stalling.
	if not realId then
		realId = pool[1].id
	end
	assert(realId)

	local order = shuffled(players, rng)
	local holder = order[1]

	local decoys: { [Player]: string } = {}
	local nextDecoy = 1
	for i = 2, #order do
		if rng:NextNumber() < Config.DecoyChance then
			while pool[nextDecoy] and pool[nextDecoy].id == realId do
				nextDecoy += 1
			end
			local decoy = pool[nextDecoy]
			if decoy then
				decoys[order[i]] = decoy.id
				nextDecoy += 1
			end
		end
	end

	return { realId = realId, holder = holder, decoys = decoys }
end

return StageGenerator
