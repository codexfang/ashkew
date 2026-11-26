-- Server entry point. Round logic gets wired in here as it is built.
local RoomBuilder = require(script.Parent.RoomBuilder)
local PerceptionService = require(script.Parent.PerceptionService)

RoomBuilder.build()
PerceptionService.start()
print("[Ashkew] Server started, room built")
