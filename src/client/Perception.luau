--!strict
-- Applies this player's private view of the room. Before touching an object it snapshots
-- the original state, so reset() can put the room back exactly as the server built it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Anomalies = require(ReplicatedStorage.Shared.Anomalies)

local Perception = {}

type PartState = { CFrame: CFrame, Color: Color3, Transparency: number, CanCollide: boolean }
type LightState = { Color: Color3, Brightness: number }

local partSnapshots: { [BasePart]: PartState } = {}
local lightSnapshots: { [Light]: LightState } = {}

local function snapshot(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not partSnapshots[d] then
			partSnapshots[d] = { CFrame = d.CFrame, Color = d.Color, Transparency = d.Transparency, CanCollide = d.CanCollide }
		elseif d:IsA("Light") and not lightSnapshots[d] then
			lightSnapshots[d] = { Color = d.Color, Brightness = d.Brightness }
		end
	end
end

local function findObject(objectId: string): Model?
	local room = workspace:WaitForChild("Room", 10)
	local objects = room and room:WaitForChild("Objects", 10)
	local model = objects and objects:WaitForChild(objectId, 10)
	if model and model:IsA("Model") then
		return model
	end
	warn("[Ashkew] Could not find room object", objectId)
	return nil
end

function Perception.reset()
	for part, state in partSnapshots do
		if part.Parent then
			part.CFrame = state.CFrame
			part.Color = state.Color
			part.Transparency = state.Transparency
			part.CanCollide = state.CanCollide
		end
	end
	for light, state in lightSnapshots do
		if light.Parent then
			light.Color = state.Color
			light.Brightness = state.Brightness
		end
	end
	table.clear(partSnapshots)
	table.clear(lightSnapshots)
end

-- Always starts from the original room, so re-applying with a higher intensity
-- never stacks on top of the previous one.
function Perception.apply(view: { Anomalies.ViewEntry })
	Perception.reset()
	for _, entry in view do
		local anomaly = Anomalies.byId[entry.id]
		if not anomaly then
			warn("[Ashkew] Unknown anomaly", entry.id)
			continue
		end
		local model = findObject(anomaly.objectId)
		if model then
			snapshot(model)
			anomaly.apply(model, math.clamp(entry.intensity, 0, 1))
		end
	end
end

return Perception
