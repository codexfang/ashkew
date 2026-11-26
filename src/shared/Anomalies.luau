--!strict
-- Every anomaly a player can perceive. Each one targets a single room object (by ObjectId)
-- and changes it on that player's client only. Nobody else sees the change.
--
-- Anomalies take an intensity from 0 to 1. Decoys stay at DECOY_INTENSITY forever; the
-- real anomaly starts there and creeps toward 1 as the meter rises. "Mine is getting
-- worse" is the tell players have to talk each other into trusting.

export type Anomaly = {
	id: string,
	objectId: string,
	description: string,
	apply: (model: Model, intensity: number) -> (),
}

-- What one client is told to render: which anomaly, and how strong.
export type ViewEntry = { id: string, intensity: number }

local DECOY_INTENSITY = 0.3

local function forEachPart(model: Model, fn: (BasePart) -> ())
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			fn(d)
		end
	end
end

local list: { Anomaly } = {
	{
		id = "CrookedPainting",
		objectId = "Painting",
		description = "The painting is crooked",
		apply = function(model, intensity)
			local degrees = 8 + 40 * intensity
			model:PivotTo(model:GetPivot() * CFrame.Angles(0, 0, math.rad(degrees)))
		end,
	},
	{
		id = "FadingDoor",
		objectId = "Door",
		description = "The door is fading away",
		apply = function(model, intensity)
			local fade = math.clamp(0.25 + 0.75 * intensity, 0, 1)
			forEachPart(model, function(p)
				p.Transparency = fade
				p.CanCollide = fade < 0.9
			end)
		end,
	},
	{
		id = "RedLamp",
		objectId = "Lamp",
		description = "The lamp glows red",
		apply = function(model, intensity)
			local shade = model:FindFirstChild("Shade") :: BasePart?
			if not shade then
				return
			end
			local red = Color3.fromRGB(200, 15, 15)
			shade.Color = shade.Color:Lerp(red, 0.4 + 0.6 * intensity)
			local glow = shade:FindFirstChild("Glow") :: PointLight?
			if glow then
				glow.Color = glow.Color:Lerp(Color3.fromRGB(255, 20, 20), 0.4 + 0.6 * intensity)
				glow.Brightness = 1.5 + 4.5 * intensity
			end
		end,
	},
	{
		id = "ClockMoved",
		objectId = "Clock",
		description = "The clock is on the wrong wall",
		apply = function(model, intensity)
			-- Mirror it onto the west wall, still facing into the room, then let it slide down.
			local y = 8 - 5.5 * intensity
			model:PivotTo(CFrame.new(-15.85, y, 0) * CFrame.Angles(0, math.pi, 0))
		end,
	},
	{
		id = "ChairTurned",
		objectId = "Chair",
		description = "The chair is turning toward the wall",
		apply = function(model, intensity)
			local degrees = 50 + 130 * intensity
			model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.rad(degrees), 0))
		end,
	},
}

local byId: { [string]: Anomaly } = {}
for _, anomaly in list do
	byId[anomaly.id] = anomaly
end

return {
	list = list,
	byId = byId,
	DECOY_INTENSITY = DECOY_INTENSITY,
}
