-- Server entry point. Round logic gets wired in here as it is built.
local RoomBuilder = require(script.Parent.RoomBuilder)
local PerceptionService = require(script.Parent.PerceptionService)
local RoundService = require(script.Parent.RoundService)
local VoteService = require(script.Parent.VoteService)

RoomBuilder.build()
PerceptionService.start()
VoteService.start()
RoundService.start()
print("[Ashkew] Server started, room built")
