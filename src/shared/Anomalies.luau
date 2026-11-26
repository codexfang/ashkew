--!strict
-- Every anomaly a player can perceive. Each one targets a single room object (by ObjectId)
-- and changes it on that player's client only. Nobody else sees the change.

export type Anomaly = {
	id: string,
	objectId: string,
	description: string,
	apply: (model: Model) -> (),
}

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
		apply = function(model)
			model:PivotTo(model:GetPivot() * CFrame.Angles(0, 0, math.rad(14)))
		end,
	},
	{
		id = "MissingDoor",
		objectId = "Door",
		description = "The door is gone",
		apply = function(model)
			forEachPart(model, function(p)
				p.Transparency = 1
				p.CanCollide = false
			end)
		end,
	},
	{
		id = "RedLamp",
		objectId = "Lamp",
		description = "The lamp glows red",
		apply = function(model)
			local shade = model:FindFirstChild("Shade") :: BasePart?
			if not shade then
				return
			end
			shade.Color = Color3.fromRGB(160, 20, 20)
			local glow = shade:FindFirstChild("Glow") :: PointLight?
			if glow then
				glow.Color = Color3.fromRGB(255, 30, 30)
				glow.Brightness = 3
			end
		end,
	},
	{
		id = "ClockMoved",
		objectId = "Clock",
		description = "The clock is on the wrong wall",
		apply = function(model)
			-- Mirror it onto the west wall, still facing into the room.
			model:PivotTo(CFrame.new(-15.85, 8, 0) * CFrame.Angles(0, math.pi, 0))
		end,
	},
	{
		id = "ChairTurned",
		objectId = "Chair",
		description = "The chair faces the wall",
		apply = function(model)
			model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.pi, 0))
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
}
