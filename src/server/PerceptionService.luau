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

type View = { Anomalies.ViewEntry }

local views: { [Player]: View } = {}
local ready: { [Player]: boolean } = {}

local function push(player: Player)
	if ready[player] then
		PerceptionAssigned:FireClient(player, views[player] or {})
	end
end

function PerceptionService.setView(player: Player, view: View)
	views[player] = view
	push(player)
end

function PerceptionService.getView(player: Player): View
	return views[player] or {}
end

-- Puts every player back to seeing the normal room.
function PerceptionService.clearAll()
	for player in views do
		views[player] = {}
		push(player)
	end
end

function PerceptionService.start()
	-- Clients announce when their listener is connected, so nothing gets fired into the void.
	ClientReady.OnServerEvent:Connect(function(player)
		-- Late joiners see the normal room until the next stage rolls them in.
		ready[player] = true
		push(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		views[player] = nil
		ready[player] = nil
	end)
end

return PerceptionService
