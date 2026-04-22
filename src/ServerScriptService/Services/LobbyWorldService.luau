local Workspace = game:GetService("Workspace")

local LobbyWorldService = {}

local LOBBY_MODEL_NAME = "FastGuesserLobby"

local COLORS = {
	floor = Color3.fromRGB(32, 39, 48),
	platform = Color3.fromRGB(45, 57, 72),
	accent = Color3.fromRGB(91, 154, 238),
	text = Color3.fromRGB(245, 247, 250),
}

local function createPart(parent, name, size, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function createSpawn(parent)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.15, 12)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Color = Color3.fromRGB(40, 70, 96)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = parent

	return spawn
end

local function createLobbySign(parent, adornee)
	local sign = Instance.new("BillboardGui")
	sign.Name = "LobbySign"
	sign.Adornee = adornee
	sign.Size = UDim2.fromOffset(320, 92)
	sign.StudsOffset = Vector3.new(0, 4.5, 0)
	sign.AlwaysOnTop = true
	sign.Parent = parent

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.fromScale(1, 0.58)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Fast Guesser"
	title.TextColor3 = COLORS.text
	title.TextSize = 34
	title.TextWrapped = true
	title.Parent = sign

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "SubtitleLabel"
	subtitle.Size = UDim2.fromScale(1, 0.42)
	subtitle.Position = UDim2.fromScale(0, 0.58)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Step up to ready for a match"
	subtitle.TextColor3 = Color3.fromRGB(190, 202, 218)
	subtitle.TextSize = 18
	subtitle.TextWrapped = true
	subtitle.Parent = sign
end

function LobbyWorldService.createLobby(onPlayMatchRequested)
	local existingLobby = Workspace:FindFirstChild(LOBBY_MODEL_NAME)
	if existingLobby then
		existingLobby:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = LOBBY_MODEL_NAME
	model.Parent = Workspace

	createPart(model, "LobbyFloor", Vector3.new(72, 1, 72), Vector3.new(0, -0.5, 0), COLORS.floor)
	createSpawn(model)
	createPart(model, "PlayPad", Vector3.new(14, 1, 10), Vector3.new(0, 0.05, -12), COLORS.platform)

	local promptStand = createPart(model, "PlayMatchStand", Vector3.new(5, 4, 1), Vector3.new(0, 2.5, -18), COLORS.accent)
	createPart(model, "PlayMatchMarker", Vector3.new(8, 0.35, 1), Vector3.new(0, 0.35, -7), COLORS.accent)
	createLobbySign(model, promptStand)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlayMatchPrompt"
	prompt.ActionText = "Play Match"
	prompt.ObjectText = "Fast Guesser"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptStand
	prompt.Triggered:Connect(onPlayMatchRequested)

	return model
end

return LobbyWorldService
