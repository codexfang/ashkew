-- Server entry point. Round logic gets wired in here as it is built.
local RoomBuilder = require(script.Parent.RoomBuilder)
local PerceptionService = require(script.Parent.PerceptionService)
local RoundService = require(script.Parent.RoundService)

RoomBuilder.build()
PerceptionService.start()
RoundService.start()
print("[Ashkew] Server started, room built")
