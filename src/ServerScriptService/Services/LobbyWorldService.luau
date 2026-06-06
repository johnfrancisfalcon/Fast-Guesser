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

local MODES = {
	Classic4Digit = "classic_4_digit",
	HigherLower100 = "higher_lower_100",
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

local function createCFramePart(parent, name, size, cframe, color, material)
	local part = createPart(parent, name, size, cframe.Position, color, material)
	part.CFrame = cframe
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

local function attachPrompt(part, name, actionText, objectText, callback)
	if not callback then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(callback)
end

local function createStation(parent, name, basePosition, accentColor, titleText, subtitleText, promptConfig)
	local base = createPart(parent, name .. "Base", Vector3.new(15, 1, 11), basePosition, COLORS.platform)
	local backWall = createPart(
		parent,
		name .. "Wall",
		Vector3.new(14, 6.5, 1),
		basePosition + Vector3.new(0, 3.25, -5.6),
		COLORS.platformDark
	)
	local counter = createPart(
		parent,
		name .. "Counter",
		Vector3.new(10.8, 2.1, 2.6),
		basePosition + Vector3.new(0, 1.3, -2.25),
		accentColor
	)
	createPart(parent, name .. "Trim", Vector3.new(12.8, 0.35, 0.8), basePosition + Vector3.new(0, 0.82, 4.15), accentColor, Enum.Material.Neon)
	createPart(parent, name .. "LeftPost", Vector3.new(0.65, 5.4, 0.65), basePosition + Vector3.new(-6.7, 2.7, -4.45), accentColor, Enum.Material.Neon)
	createPart(parent, name .. "RightPost", Vector3.new(0.65, 5.4, 0.65), basePosition + Vector3.new(6.7, 2.7, -4.45), accentColor, Enum.Material.Neon)
	createBillboard(parent, backWall, name .. "Sign", titleText, subtitleText, accentColor)
	if promptConfig then
		attachPrompt(counter, promptConfig.name, promptConfig.actionText, titleText, promptConfig.callback)
	end

	return base, backWall, counter
end

local function createGamePad(parent, name, modeId, centerPosition, accentColor, titleText, subtitleText, onPlayModeRequested)
	local base = createPart(parent, name .. "Pad", Vector3.new(16, 1, 12), centerPosition, COLORS.platform)
	createPart(parent, name .. "GlowPad", Vector3.new(11.5, 0.18, 7), centerPosition + Vector3.new(0, 0.6, 0.25), accentColor, Enum.Material.Neon)
	createPart(parent, name .. "EntryLine", Vector3.new(11.5, 0.35, 0.75), centerPosition + Vector3.new(0, 0.82, 5.45), accentColor, Enum.Material.Neon)
	createPart(parent, name .. "LeftMarker", Vector3.new(0.8, 4.8, 0.8), centerPosition + Vector3.new(-6.6, 2.4, -4.7), accentColor, Enum.Material.Neon)
	createPart(parent, name .. "RightMarker", Vector3.new(0.8, 4.8, 0.8), centerPosition + Vector3.new(6.6, 2.4, -4.7), accentColor, Enum.Material.Neon)

	local promptStand = createPart(parent, name .. "Stand", Vector3.new(6.5, 3.4, 1.4), centerPosition + Vector3.new(0, 2.25, -3.2), COLORS.platformDark)
	createBillboard(parent, promptStand, name .. "Sign", titleText, subtitleText, accentColor)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name .. "Prompt"
	prompt.ActionText = "Play"
	prompt.ObjectText = titleText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ModeId", modeId)
	prompt.Parent = promptStand
	prompt.Triggered:Connect(function(player)
		onPlayModeRequested(player, modeId)
	end)

	return base
end

local function createGameArea(parent, onPlayModeRequested)
	local sectionBase = createPart(parent, "GameAreaBase", Vector3.new(39, 0.8, 18), Vector3.new(11, 0, -23.5), COLORS.platformDark)
	createPart(parent, "GameAreaHeader", Vector3.new(30, 1.1, 1), Vector3.new(11, 5.9, -32.2), COLORS.accent, Enum.Material.Neon)
	createPart(parent, "GameAreaBackRail", Vector3.new(39, 3.6, 1), Vector3.new(11, 1.8, -32.8), COLORS.platformDark)
	createBillboard(parent, sectionBase, "GameAreaSign", "Game Area", "Choose a mode, then ready up", COLORS.accent)

	createGamePad(
		parent,
		"Classic4DigitPlay",
		MODES.Classic4Digit,
		Vector3.new(1, 0.25, -22.4),
		COLORS.accent,
		"Classic 4-Digit",
		"Exact-position code duel",
		onPlayModeRequested
	)
	createGamePad(
		parent,
		"HigherLower100Play",
		MODES.HigherLower100,
		Vector3.new(21, 0.25, -22.4),
		COLORS.warning,
		"1-100 Higher/Lower",
		"Higher, lower, correct",
		onPlayModeRequested
	)
end

local function createWheelSegment(parent, name, centerPosition, radius, angle, width, height, depth, color)
	local radialOffset = Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0.54)
	local cframe = CFrame.new(centerPosition + radialOffset) * CFrame.Angles(0, 0, angle)
	return createCFramePart(parent, name, Vector3.new(width, height, depth), cframe, color, Enum.Material.Neon)
end

local function createWheelOrbit(parent, namePrefix, centerPosition, radius, count, size, color, material)
	for index = 1, count do
		local angle = ((index - 1) / count) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)
		local cframe = CFrame.new(centerPosition + offset) * CFrame.Angles(0, 0, angle)
		createCFramePart(parent, namePrefix .. tostring(index), size, cframe, color, material)
	end
end

local function createRewardWheelStructure(parent, centerPosition)
	local supportLeft = createPart(parent, "RewardsWheelSupportLeft", Vector3.new(0.85, 5.3, 0.85), centerPosition + Vector3.new(-2.85, -0.75, -0.15), COLORS.platformDark)
	local supportRight = createPart(parent, "RewardsWheelSupportRight", Vector3.new(0.85, 5.3, 0.85), centerPosition + Vector3.new(2.85, -0.75, -0.15), COLORS.platformDark)
	createPart(parent, "RewardsWheelCrossbar", Vector3.new(6.8, 0.65, 0.85), centerPosition + Vector3.new(0, 1.8, -0.15), COLORS.platformDark)
	createPart(parent, "RewardsWheelStandBase", Vector3.new(7.4, 0.7, 2.4), centerPosition + Vector3.new(0, -3.35, 0.1), COLORS.platformDark)
	createPart(parent, "RewardsWheelStandGlow", Vector3.new(6.2, 0.18, 2.8), centerPosition + Vector3.new(0, -2.96, 0.1), COLORS.reward, Enum.Material.Neon)
	createPart(parent, "RewardsWheelSupportGlowLeft", Vector3.new(0.28, 5.1, 0.28), supportLeft.Position + Vector3.new(0, 0, 0.58), COLORS.reward, Enum.Material.Neon)
	createPart(parent, "RewardsWheelSupportGlowRight", Vector3.new(0.28, 5.1, 0.28), supportRight.Position + Vector3.new(0, 0, 0.58), COLORS.reward, Enum.Material.Neon)

	local backPlate = createPart(parent, "RewardsWheelBackPlate", Vector3.new(7.9, 7.9, 0.42), centerPosition + Vector3.new(0, 0, 0.04), COLORS.platformDark)
	backPlate.Shape = Enum.PartType.Cylinder
	backPlate.Orientation = Vector3.new(90, 0, 0)

	local rim = createPart(parent, "RewardsWheelRim", Vector3.new(7.15, 7.15, 0.52), centerPosition + Vector3.new(0, 0, 0.18), COLORS.reward, Enum.Material.Neon)
	rim.Shape = Enum.PartType.Cylinder
	rim.Orientation = Vector3.new(90, 0, 0)

	local face = createPart(parent, "RewardsWheelFace", Vector3.new(6.35, 6.35, 0.26), centerPosition + Vector3.new(0, 0, 0.36), Color3.fromRGB(67, 54, 28), Enum.Material.SmoothPlastic)
	face.Shape = Enum.PartType.Cylinder
	face.Orientation = Vector3.new(90, 0, 0)

	local segmentColors = {
		COLORS.reward,
		COLORS.warning,
		Color3.fromRGB(255, 230, 148),
		Color3.fromRGB(236, 182, 72),
		Color3.fromRGB(255, 216, 118),
		Color3.fromRGB(214, 154, 57),
	}

	for index = 1, 6 do
		local angle = ((index - 1) / 6) * math.pi * 2
		createWheelSegment(parent, "RewardsWheelSegment" .. tostring(index), centerPosition, 1.55, angle, 2.15, 1.55, 0.12, segmentColors[index])
	end

	for index = 1, 6 do
		local angle = ((index - 1) / 6) * math.pi * 2
		local dividerOffset = Vector3.new(math.cos(angle) * 2.15, math.sin(angle) * 2.15, 0.5)
		local dividerCFrame = CFrame.new(centerPosition + dividerOffset) * CFrame.Angles(0, 0, angle)
		createCFramePart(parent, "RewardsWheelDivider" .. tostring(index), Vector3.new(0.18, 2.75, 0.16), dividerCFrame, COLORS.platformDark, Enum.Material.Neon)
	end

	createWheelOrbit(parent, "RewardsWheelRimLight", centerPosition + Vector3.new(0, 0, 0.54), 2.95, 12, Vector3.new(0.55, 0.55, 0.16), COLORS.reward, Enum.Material.Neon)
	createWheelOrbit(parent, "RewardsWheelInnerLight", centerPosition + Vector3.new(0, 0, 0.54), 1.1, 6, Vector3.new(0.42, 0.42, 0.12), Color3.fromRGB(255, 235, 160), Enum.Material.Neon)

	local hub = createPart(parent, "RewardsWheelHub", Vector3.new(1.45, 1.45, 0.62), centerPosition + Vector3.new(0, 0, 0.58), COLORS.warning, Enum.Material.Neon)
	hub.Shape = Enum.PartType.Cylinder
	hub.Orientation = Vector3.new(90, 0, 0)

	local axle = createPart(parent, "RewardsWheelAxle", Vector3.new(0.45, 0.45, 0.95), centerPosition + Vector3.new(0, 0, 0.1), COLORS.text, Enum.Material.Metal)
	axle.Shape = Enum.PartType.Cylinder
	axle.Orientation = Vector3.new(90, 0, 0)

	local pointerBase = createPart(parent, "RewardsWheelPointerBase", Vector3.new(1.25, 0.4, 0.85), centerPosition + Vector3.new(0, 4.0, 0.24), COLORS.platformDark)
	local pointer = createCFramePart(
		parent,
		"RewardsWheelPointer",
		Vector3.new(1.1, 1.75, 0.36),
		CFrame.new(pointerBase.Position + Vector3.new(0, -0.74, 0.42)) * CFrame.Angles(0, 0, math.rad(180)),
		COLORS.warning,
		Enum.Material.Neon
	)
	pointer.Shape = Enum.PartType.Wedge

	local marquee = createPart(parent, "RewardsWheelMarquee", Vector3.new(4.6, 0.36, 0.7), centerPosition + Vector3.new(0, 4.58, -0.3), COLORS.reward, Enum.Material.Neon)
	marquee.Orientation = Vector3.new(0, 0, -6)
end

local function createRewardWheel(parent, onRewardsRequested)
	local _, wall, counter = createStation(
		parent,
		"RewardsStation",
		Vector3.new(21, 0.05, 6),
		COLORS.reward,
		"Rewards",
		"Daily coins and prize wheel",
		{
			name = "RewardsPrompt",
			actionText = "Open Rewards",
			callback = onRewardsRequested,
		}
	)

	local wheelCenter = Vector3.new(21, 4.95, 0.2)
	createRewardWheelStructure(parent, wheelCenter)

	createPart(parent, "RewardsCounterGlow", Vector3.new(8.6, 0.22, 2.95), Vector3.new(21, 2.42, 3.45), COLORS.reward, Enum.Material.Neon)
	createPart(parent, "RewardsCoinDisplay", Vector3.new(5.2, 0.4, 1.3), Vector3.new(21, 2.78, 2.2), COLORS.reward, Enum.Material.Neon)
	createPart(parent, "RewardsCoinDisplayTrim", Vector3.new(5.7, 0.18, 0.5), Vector3.new(21, 2.98, 2.9), COLORS.warning, Enum.Material.Neon)
	createPart(parent, "RewardsSideLightLeft", Vector3.new(0.34, 4.9, 4.6), Vector3.new(15.45, 2.7, 1.35), COLORS.reward, Enum.Material.Neon)
	createPart(parent, "RewardsSideLightRight", Vector3.new(0.34, 4.9, 4.6), Vector3.new(26.55, 2.7, 1.35), COLORS.reward, Enum.Material.Neon)
	createPart(parent, "RewardsFrontGuide", Vector3.new(10.2, 0.18, 1.1), Vector3.new(21, 0.18, 12.15), COLORS.warning, Enum.Material.Neon)
	counter.Position = Vector3.new(21, 1.3, 3.55)
	wall.Position = Vector3.new(21, 3.25, 0.15)
end

function LobbyWorldService.createLobby(onPlayModeRequested, onShopRequested, onRewardsRequested, onLeaderboardRequested)
	local existingLobby = Workspace:FindFirstChild(LOBBY_MODEL_NAME)
	if existingLobby then
		existingLobby:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = LOBBY_MODEL_NAME
	model.Parent = Workspace

	createPart(model, "LobbyFloor", Vector3.new(84, 1, 84), Vector3.new(0, -0.5, 0), COLORS.floor)
	createPart(model, "CentralWalkway", Vector3.new(18, 0.16, 62), Vector3.new(0, 0.08, 2), COLORS.floorAlt)
	createPart(model, "SpawnGlowRing", Vector3.new(14, 0.18, 14), Vector3.new(0, 0.04, 18), COLORS.accent, Enum.Material.Neon)
	createPart(model, "LobbyIdentityHeader", Vector3.new(30, 1.2, 1), Vector3.new(0, 6.2, 31), COLORS.accent, Enum.Material.Neon)
	createSpawn(model)
	createGameArea(model, onPlayModeRequested)

	createStation(model, "ShopStation", Vector3.new(-21, 0.05, 6), COLORS.shop, "Shop", "Coin cosmetics", {
		name = "ShopPrompt",
		actionText = "Open Shop",
		callback = onShopRequested,
	})
	createRewardWheel(model, onRewardsRequested)
	createStation(model, "LeaderboardStation", Vector3.new(-21, 0.05, -22), COLORS.success, "Leaderboard", "Session wins", {
		name = "LeaderboardPrompt",
		actionText = "Open Leaderboard",
		callback = onLeaderboardRequested,
	})

	createPart(model, "ShopPathLight", Vector3.new(10, 0.18, 1), Vector3.new(-21, 0.18, 13), COLORS.shop, Enum.Material.Neon)
	createPart(model, "RewardsPathLight", Vector3.new(10, 0.18, 1), Vector3.new(21, 0.18, 13), COLORS.reward, Enum.Material.Neon)
	createPart(model, "LeaderboardPathLight", Vector3.new(10, 0.18, 1), Vector3.new(-21, 0.18, -14), COLORS.success, Enum.Material.Neon)
	createPart(model, "GameAreaPathLight", Vector3.new(24, 0.18, 1), Vector3.new(11, 0.18, -13.5), COLORS.accent, Enum.Material.Neon)
	createPart(model, "LobbyBackRail", Vector3.new(66, 3, 1), Vector3.new(0, 1.5, -36), COLORS.platformDark)
	createPart(model, "LeftGuideRail", Vector3.new(1, 2, 62), Vector3.new(-36, 1, 0), COLORS.platformDark)
	createPart(model, "RightGuideRail", Vector3.new(1, 2, 62), Vector3.new(36, 1, 0), COLORS.platformDark)

	return model
end

return LobbyWorldService
