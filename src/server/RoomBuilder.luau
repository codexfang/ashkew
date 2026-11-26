--!strict
-- Builds the motel room the players are trapped in.
-- Every object a player could notice is a Model tagged "Perceivable" with an "ObjectId"
-- attribute, so the perception system can find it and change it per player.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local RoomBuilder = {}

local PERCEIVABLE_TAG = "Perceivable"

type PartProps = {
	Name: string?,
	Size: Vector3,
	Position: Vector3,
	Color: Color3?,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Transparency: number?,
	CanCollide: boolean?,
}

local function makePart(props: PartProps, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = props.Name or "Part"
	part.Anchored = true
	part.Size = props.Size
	part.Position = props.Position
	part.Color = props.Color or Color3.fromRGB(120, 110, 100)
	part.Material = props.Material or Enum.Material.SmoothPlastic
	part.Shape = props.Shape or Enum.PartType.Block
	part.Transparency = props.Transparency or 0
	part.CanCollide = if props.CanCollide == nil then true else props.CanCollide
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Creates a tagged Model; the first part built inside it becomes its PrimaryPart.
local function makeObject(objectId: string, parent: Instance, build: (model: Model) -> ()): Model
	local model = Instance.new("Model")
	model.Name = objectId
	model:SetAttribute("ObjectId", objectId)
	build(model)
	local first = model:FindFirstChildWhichIsA("BasePart")
	if first then
		model.PrimaryPart = first
	end
	-- Stream the whole object in at once so a client never sees half a model.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	CollectionService:AddTag(model, PERCEIVABLE_TAG)
	model.Parent = parent
	return model
end

local function buildShell(room: Folder)
	local wall = Color3.fromRGB(92, 104, 88) -- faded motel green
	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = room

	makePart({ Name = "Floor", Size = Vector3.new(32, 1, 24), Position = Vector3.new(0, -0.5, 0),
		Color = Color3.fromRGB(70, 55, 45), Material = Enum.Material.WoodPlanks }, shell)
	makePart({ Name = "Ceiling", Size = Vector3.new(34, 1, 26), Position = Vector3.new(0, 12.5, 0),
		Color = Color3.fromRGB(180, 175, 160) }, shell)
	makePart({ Name = "WallNorth", Size = Vector3.new(34, 12, 1), Position = Vector3.new(0, 6, -12.5), Color = wall }, shell)
	makePart({ Name = "WallSouth", Size = Vector3.new(34, 12, 1), Position = Vector3.new(0, 6, 12.5), Color = wall }, shell)
	makePart({ Name = "WallWest", Size = Vector3.new(1, 12, 24), Position = Vector3.new(-16.5, 6, 0), Color = wall }, shell)
	makePart({ Name = "WallEast", Size = Vector3.new(1, 12, 24), Position = Vector3.new(16.5, 6, 0), Color = wall }, shell)

	makePart({ Name = "Rug", Size = Vector3.new(10, 0.1, 7), Position = Vector3.new(2, 0.05, 2),
		Color = Color3.fromRGB(110, 30, 35), Material = Enum.Material.Fabric, CanCollide = false }, shell)

	local fixture = makePart({ Name = "CeilingLight", Size = Vector3.new(2, 0.3, 2), Position = Vector3.new(0, 11.85, 0),
		Color = Color3.fromRGB(255, 235, 190), Material = Enum.Material.Neon }, shell)
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Brightness = 0.6
	light.Color = Color3.fromRGB(255, 225, 170)
	light.Shadows = true
	light.Parent = fixture
end

local function buildObjects(room: Folder)
	local objects = Instance.new("Folder")
	objects.Name = "Objects"
	objects.Parent = room

	makeObject("Bed", objects, function(m)
		makePart({ Name = "Base", Size = Vector3.new(7, 1.5, 10), Position = Vector3.new(-10, 0.75, -6.5),
			Color = Color3.fromRGB(80, 60, 45), Material = Enum.Material.Wood }, m)
		makePart({ Name = "Mattress", Size = Vector3.new(7, 1, 10), Position = Vector3.new(-10, 2, -6.5),
			Color = Color3.fromRGB(200, 195, 180), Material = Enum.Material.Fabric }, m)
		makePart({ Name = "Pillow", Size = Vector3.new(5, 0.6, 2), Position = Vector3.new(-10, 2.8, -10.5),
			Color = Color3.fromRGB(235, 232, 220), Material = Enum.Material.Fabric }, m)
		makePart({ Name = "Headboard", Size = Vector3.new(7, 4, 0.6), Position = Vector3.new(-10, 2, -11.7),
			Color = Color3.fromRGB(70, 50, 38), Material = Enum.Material.Wood }, m)
	end)

	makeObject("Nightstand", objects, function(m)
		makePart({ Name = "Body", Size = Vector3.new(3, 2.5, 3), Position = Vector3.new(-4.5, 1.25, -10),
			Color = Color3.fromRGB(80, 60, 45), Material = Enum.Material.Wood }, m)
	end)

	makeObject("Lamp", objects, function(m)
		local shade = makePart({ Name = "Shade", Size = Vector3.new(1.6, 1.2, 1.6), Position = Vector3.new(-4.5, 5, -10),
			Color = Color3.fromRGB(240, 220, 170), Material = Enum.Material.Fabric }, m)
		makePart({ Name = "Stem", Size = Vector3.new(0.3, 2, 0.3), Position = Vector3.new(-4.5, 3.5, -10),
			Color = Color3.fromRGB(60, 60, 60), Material = Enum.Material.Metal }, m)
		local light = Instance.new("PointLight")
		light.Name = "Glow"
		light.Range = 14
		light.Brightness = 1.5
		light.Color = Color3.fromRGB(255, 200, 130)
		light.Parent = shade
	end)

	makeObject("Painting", objects, function(m)
		makePart({ Name = "Frame", Size = Vector3.new(6, 4, 0.3), Position = Vector3.new(4, 7, -11.85),
			Color = Color3.fromRGB(150, 115, 50), Material = Enum.Material.Wood }, m)
		makePart({ Name = "Canvas", Size = Vector3.new(5.2, 3.2, 0.1), Position = Vector3.new(4, 7, -11.65),
			Color = Color3.fromRGB(60, 90, 120), Material = Enum.Material.SmoothPlastic }, m)
	end)

	makeObject("Clock", objects, function(m)
		makePart({ Name = "Face", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 3, 3),
			Position = Vector3.new(15.85, 8, 0), Color = Color3.fromRGB(235, 230, 215) }, m)
		makePart({ Name = "HourHand", Size = Vector3.new(0.1, 0.9, 0.15), Position = Vector3.new(15.65, 8.4, 0),
			Color = Color3.fromRGB(20, 20, 20) }, m)
		makePart({ Name = "MinuteHand", Size = Vector3.new(0.1, 0.15, 1.2), Position = Vector3.new(15.65, 8, 0.55),
			Color = Color3.fromRGB(20, 20, 20) }, m)
	end)

	makeObject("Door", objects, function(m)
		makePart({ Name = "Panel", Size = Vector3.new(5, 9, 0.4), Position = Vector3.new(8, 4.5, 11.8),
			Color = Color3.fromRGB(110, 80, 55), Material = Enum.Material.Wood }, m)
		makePart({ Name = "Knob", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5),
			Position = Vector3.new(6, 4.5, 11.5), Color = Color3.fromRGB(200, 170, 80), Material = Enum.Material.Metal }, m)
	end)

	makeObject("Chair", objects, function(m)
		makePart({ Name = "Seat", Size = Vector3.new(3, 0.4, 3), Position = Vector3.new(11, 2, -4),
			Color = Color3.fromRGB(90, 70, 50), Material = Enum.Material.Wood }, m)
		makePart({ Name = "Back", Size = Vector3.new(3, 3, 0.4), Position = Vector3.new(11, 3.7, -5.3),
			Color = Color3.fromRGB(90, 70, 50), Material = Enum.Material.Wood }, m)
		for i, offset in { Vector3.new(-1.2, 0, -1.2), Vector3.new(1.2, 0, -1.2), Vector3.new(-1.2, 0, 1.2), Vector3.new(1.2, 0, 1.2) } do
			makePart({ Name = "Leg" .. i, Size = Vector3.new(0.3, 1.8, 0.3), Position = Vector3.new(11, 0.9, -4) + offset,
				Color = Color3.fromRGB(70, 55, 40), Material = Enum.Material.Wood }, m)
		end
	end)
end

local function setMood()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0.5
	Lighting.Ambient = Color3.fromRGB(25, 25, 30)
	Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 15)
	Lighting.GlobalShadows = true
	Lighting.FogColor = Color3.fromRGB(10, 10, 12)
	Lighting.FogEnd = 200
end

function RoomBuilder.build(): Folder
	local existing = workspace:FindFirstChild("Room")
	if existing then
		existing:Destroy()
	end

	-- The Baseplate template ships with its own SpawnLocation outside our room; remove it.
	for _, child in workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	local room = Instance.new("Folder")
	room.Name = "Room"

	buildShell(room)
	buildObjects(room)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "RoomSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(4, 0.1, 4)
	spawn.Position = Vector3.new(0, 0.05, 5)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = room

	room.Parent = workspace
	setMood()
	return room
end

return RoomBuilder
