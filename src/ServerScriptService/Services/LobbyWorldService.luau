local Workspace = game:GetService("Workspace")

local LobbyWorldService = {}

local LOBBY_MODEL_NAME = "FastGuesserLobby"

local COLORS = {
	floor = Color3.fromRGB(31, 38, 47),
	floorAlt = Color3.fromRGB(38, 47, 58),
	platform = Color3.fromRGB(47, 60, 76),
	platformDark = Color3.fromRGB(28, 36, 47),
	accent = Color3.fromRGB(91, 154, 238),
	success = Color3.fromRGB(84, 207, 144),
	warning = Color3.fromRGB(240, 193, 100),
	shop = Color3.fromRGB(210, 128, 242),
	reward = Color3.fromRGB(255, 211, 105),
	text = Color3.fromRGB(245, 247, 250),
}

local function createPart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function createSpawn(parent)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.15, 18)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(40, 70, 96)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = parent

	return spawn
end

local function createBillboard(parent, adornee, name, titleText, subtitleText, accentColor)
	local sign = Instance.new("BillboardGui")
	sign.Name = name
	sign.Adornee = adornee
	sign.Size = UDim2.fromOffset(340, 104)
	sign.StudsOffset = Vector3.new(0, 4.6, 0)
	sign.AlwaysOnTop = true
	sign.Parent = parent

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.fromScale(1, 0.56)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = titleText
	title.TextColor3 = accentColor or COLORS.text
	title.TextSize = 32
	title.TextWrapped = true
	title.Parent = sign

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "SubtitleLabel"
	subtitle.Size = UDim2.fromScale(1, 0.44)
	subtitle.Position = UDim2.fromScale(0, 0.56)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Text = subtitleText
	subtitle.TextColor3 = Color3.fromRGB(207, 218, 232)
	subtitle.TextSize = 17
	subtitle.TextWrapped = true
	subtitle.Parent = sign
end

local function createStation(parent, name, basePosition, accentColor, titleText, subtitleText)
	local base = createPart(parent, name .. "Base", Vector3.new(14, 1, 10), basePosition, COLORS.platform)
	local backWall = createPart(
		parent,
		name .. "Wall",
		Vector3.new(13, 6, 1),
		basePosition + Vector3.new(0, 3, -5.1),
		COLORS.platformDark
	)
	local counter = createPart(
		parent,
		name .. "Counter",
		Vector3.new(10, 2, 2.4),
		basePosition + Vector3.new(0, 1.25, -2.2),
		accentColor
	)
	createPart(parent, name .. "Trim", Vector3.new(12, 0.35, 0.8), basePosition + Vector3.new(0, 0.82, 3.8), accentColor, Enum.Material.Neon)
	createBillboard(parent, backWall, name .. "Sign", titleText, subtitleText, accentColor)

	return base, backWall, counter
end

local function createPlayPortal(parent, onPlayMatchRequested)
	local base = createPart(parent, "PlayMatchPad", Vector3.new(18, 1, 12), Vector3.new(0, 0.05, -16), COLORS.platform)
	createPart(parent, "PlayMatchEntryLine", Vector3.new(14, 0.35, 1), Vector3.new(0, 0.72, -9.8), COLORS.accent, Enum.Material.Neon)

	local leftPillar = createPart(parent, "PlayPortalLeftPillar", Vector3.new(2, 9, 2), Vector3.new(-6, 4.5, -21), COLORS.accent, Enum.Material.Neon)
	local rightPillar = createPart(parent, "PlayPortalRightPillar", Vector3.new(2, 9, 2), Vector3.new(6, 4.5, -21), COLORS.accent, Enum.Material.Neon)
	createPart(parent, "PlayPortalHeader", Vector3.new(14, 2, 2), Vector3.new(0, 8.5, -21), COLORS.accent, Enum.Material.Neon)
	local promptStand = createPart(parent, "PlayMatchStand", Vector3.new(5, 3.5, 1.4), Vector3.new(0, 2.35, -18.5), COLORS.platformDark)
	createBillboard(parent, promptStand, "PlayMatchSign", "Play Match", "Step in and open the match menu", COLORS.accent)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlayMatchPrompt"
	prompt.ActionText = "Play Match"
	prompt.ObjectText = "Fast Guesser"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptStand
	prompt.Triggered:Connect(onPlayMatchRequested)

	return base, leftPillar, rightPillar
end

local function createRewardWheel(parent)
	local _, wall = createStation(
		parent,
		"RewardsStation",
		Vector3.new(21, 0.05, 6),
		COLORS.reward,
		"Rewards",
		"Daily wheel placeholder"
	)

	local wheelPart = createPart(parent, "SpinWheelPreview", Vector3.new(0.5, 6, 6), Vector3.new(21, 4, 0.4), COLORS.reward, Enum.Material.Neon)
	wheelPart.Shape = Enum.PartType.Cylinder
	wheelPart.Orientation = Vector3.new(0, 0, 90)
	wheelPart:SetAttribute("FutureFeature", "SpinWheel")
	wall:SetAttribute("FutureFeature", "Rewards")
end

function LobbyWorldService.createLobby(onPlayMatchRequested)
	local existingLobby = Workspace:FindFirstChild(LOBBY_MODEL_NAME)
	if existingLobby then
		existingLobby:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = LOBBY_MODEL_NAME
	model.Parent = Workspace

	createPart(model, "LobbyFloor", Vector3.new(84, 1, 84), Vector3.new(0, -0.5, 0), COLORS.floor)
	createPart(model, "CentralWalkway", Vector3.new(18, 0.16, 62), Vector3.new(0, 0.08, 2), COLORS.floorAlt)
	createSpawn(model)
	createPlayPortal(model, onPlayMatchRequested)

	createStation(model, "ShopStation", Vector3.new(-21, 0.05, 6), COLORS.shop, "Shop", "Cosmetics coming soon")
	createRewardWheel(model)
	createStation(model, "LeaderboardStation", Vector3.new(-21, 0.05, -22), COLORS.success, "Leaderboard", "Wins and streaks soon")
	createStation(model, "ModeStation", Vector3.new(21, 0.05, -22), COLORS.warning, "Modes", "4-digit now, 1-100 later")

	createPart(model, "LobbyBackRail", Vector3.new(66, 3, 1), Vector3.new(0, 1.5, -36), COLORS.platformDark)
	createPart(model, "LeftGuideRail", Vector3.new(1, 2, 62), Vector3.new(-36, 1, 0), COLORS.platformDark)
	createPart(model, "RightGuideRail", Vector3.new(1, 2, 62), Vector3.new(36, 1, 0), COLORS.platformDark)

	return model
end

return LobbyWorldService
