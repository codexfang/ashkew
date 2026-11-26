--!strict
-- Tunable values for Ashkew. Everything gameplay-related reads from here.

local Config = {
	MinPlayers = 1, -- 1 for solo testing in Studio; raise to 2 for real rounds
	MaxPlayers = 4,

	IntermissionSeconds = 10,
	VoteSeconds = 20,
	AnomaliesToEscape = 3,

	-- Anomaly meter (0..100). Hitting 100 = the room "folds" and the team loses.
	MeterStart = 0,
	MeterMax = 100,
	MeterWrongVote = 25,
	MeterPassivePerSecond = 0.5,
}

return Config
