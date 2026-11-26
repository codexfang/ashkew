-- Client entry point.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Anomalies = require(ReplicatedStorage.Shared.Anomalies)
local Perception = require(script.Parent.Perception)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PerceptionAssigned = Remotes:WaitForChild("PerceptionAssigned") :: RemoteEvent
local ClientReady = Remotes:WaitForChild("ClientReady") :: RemoteEvent

-- Studio-only label showing what this client was told to see, so two test windows
-- can be compared side by side. Real players never get this.
local debugLabel: TextLabel? = nil
if RunService:IsStudio() then
	local gui = Instance.new("ScreenGui")
	gui.Name = "PerceptionDebug"
	gui.ResetOnSpawn = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(320, 28)
	label.Position = UDim2.fromOffset(10, 10)
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.Text = " [debug] view: waiting..."
	label.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	debugLabel = label
end

PerceptionAssigned.OnClientEvent:Connect(function(anomalyIds: { string })
	Perception.apply(anomalyIds)

	if debugLabel then
		local names = {}
		for _, id in anomalyIds do
			local anomaly = Anomalies.byId[id]
			table.insert(names, if anomaly then anomaly.description else id)
		end
		debugLabel.Text = " [debug] view: " .. (if #names > 0 then table.concat(names, ", ") else "normal")
	end
end)

ClientReady:FireServer()
print("[Ashkew] Client started for", Players.LocalPlayer.Name)
