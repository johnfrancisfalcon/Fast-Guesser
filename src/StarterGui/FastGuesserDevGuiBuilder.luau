local GuiBuilder = {}

local SCREEN_GUI_NAME = "FastGuesserDevScreenGui"
local UI_VERSION = 23

local COLORS = {
	background = Color3.fromRGB(8, 13, 22),
	backgroundAlt = Color3.fromRGB(14, 22, 34),
	surface = Color3.fromRGB(20, 29, 43),
	surfaceSoft = Color3.fromRGB(25, 35, 50),
	panel = Color3.fromRGB(32, 44, 60),
	panelAlt = Color3.fromRGB(24, 34, 48),
	panelStrong = Color3.fromRGB(39, 54, 74),
	panelRaised = Color3.fromRGB(49, 68, 92),
	border = Color3.fromRGB(85, 108, 136),
	borderSoft = Color3.fromRGB(58, 77, 101),
	accent = Color3.fromRGB(85, 162, 255),
	accentDark = Color3.fromRGB(44, 94, 162),
	success = Color3.fromRGB(84, 207, 144),
	successDark = Color3.fromRGB(37, 116, 78),
	warning = Color3.fromRGB(240, 193, 100),
	text = Color3.fromRGB(241, 246, 255),
	mutedText = Color3.fromRGB(166, 183, 205),
	input = Color3.fromRGB(241, 246, 255),
	inputText = Color3.fromRGB(18, 25, 36),
	button = Color3.fromRGB(78, 149, 245),
	buttonHover = Color3.fromRGB(98, 169, 255),
	buttonPressed = Color3.fromRGB(60, 121, 210),
	buttonDisabled = Color3.fromRGB(70, 81, 95),
	buttonDisabledText = Color3.fromRGB(148, 159, 174),
	errorText = Color3.fromRGB(255, 171, 171),
	coin = Color3.fromRGB(255, 211, 105),
}

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = instance
	return corner
end

local function addPadding(instance, left, top, right, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingRight = UDim.new(0, right or left or 0)
	padding.PaddingBottom = UDim.new(0, bottom or top or 0)
	padding.Parent = instance
	return padding
end

local function addStroke(instance, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
	return stroke
end

local function addGradient(instance, rotation, colors, transparency)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation or 90
	gradient.Color = colors
	if transparency then
		gradient.Transparency = transparency
	end
	gradient.Parent = instance
	return gradient
end

local function addSizeConstraint(instance, minWidth, minHeight, maxWidth, maxHeight)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(minWidth, minHeight)
	constraint.MaxSize = Vector2.new(maxWidth, maxHeight)
	constraint.Parent = instance
	return constraint
end

local function createScreen(name)
	local screen = Instance.new("Frame")
	screen.Name = name
	screen.Size = UDim2.fromScale(1, 1)
	screen.BackgroundTransparency = 1
	screen.BorderSizePixel = 0
	screen.Visible = false

	return screen
end

local function setTreeZIndex(root, zIndex)
	if root:IsA("GuiObject") then
		root.ZIndex = zIndex
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.ZIndex = zIndex
		end
	end
end

local function createCenteredShell(parent, name, size, minSize, maxSize)
	local shadow = Instance.new("Frame")
	shadow.Name = name .. "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 14)
	shadow.Size = size + UDim2.fromOffset(20, 20)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.74
	shadow.BorderSizePixel = 0
	shadow.Parent = parent
	addCorner(shadow, 34)
	addSizeConstraint(shadow, minSize.X + 20, minSize.Y + 20, maxSize.X + 20, maxSize.Y + 20)

	local shell = Instance.new("Frame")
	shell.Name = name
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.5)
	shell.Size = size
	shell.BackgroundColor3 = COLORS.surface
	shell.BorderSizePixel = 0
	shell.Parent = parent
	addCorner(shell, 26)
	addStroke(shell, COLORS.borderSoft, 1, 0.08)
	addGradient(
		shell,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLORS.surface),
			ColorSequenceKeypoint.new(1, COLORS.surfaceSoft),
		})
	)
	addSizeConstraint(shell, minSize.X, minSize.Y, maxSize.X, maxSize.Y)
	return shell
end

local function createLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = color or COLORS.text
	label.TextSize = textSize or 18
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent

	return label
end

local function createCard(parent, name, size, position, backgroundColor, cornerRadius)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = position or UDim2.fromOffset(0, 0)
	panel.BackgroundColor3 = backgroundColor or COLORS.panel
	panel.BorderSizePixel = 0
	panel.Parent = parent
	addCorner(panel, cornerRadius or 20)
	addStroke(panel, COLORS.borderSoft, 1, 0.15)
	addGradient(
		panel,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, panel.BackgroundColor3),
			ColorSequenceKeypoint.new(1, COLORS.panelAlt),
		})
	)

	return panel
end

local function createButton(parent, name, text, size, position, variant)
	local colors = {
		Primary = {
			background = COLORS.button,
			hover = COLORS.buttonHover,
			pressed = COLORS.buttonPressed,
			disabled = COLORS.buttonDisabled,
			text = COLORS.text,
			disabledText = COLORS.buttonDisabledText,
			stroke = COLORS.accent,
		},
		Secondary = {
			background = COLORS.panelRaised,
			hover = Color3.fromRGB(63, 86, 114),
			pressed = Color3.fromRGB(51, 70, 94),
			disabled = COLORS.buttonDisabled,
			text = COLORS.text,
			disabledText = COLORS.buttonDisabledText,
			stroke = COLORS.border,
		},
	}

	local palette = colors[variant or "Primary"]
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size or UDim2.fromOffset(170, 48)
	button.Position = position or UDim2.fromOffset(0, 0)
	button.BackgroundColor3 = palette.background
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = palette.text
	button.TextSize = 18
	button.Parent = parent
	button:SetAttribute("EnabledBackgroundColor", palette.background)
	button:SetAttribute("HoverBackgroundColor", palette.hover)
	button:SetAttribute("PressedBackgroundColor", palette.pressed)
	button:SetAttribute("DisabledBackgroundColor", palette.disabled)
	button:SetAttribute("EnabledTextColor", palette.text)
	button:SetAttribute("DisabledTextColor", palette.disabledText)
	button:SetAttribute("StrokeColor", palette.stroke)

	addCorner(button, 14)
	addStroke(button, palette.stroke, 1, 0.12)
	addGradient(
		button,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, palette.background),
			ColorSequenceKeypoint.new(1, palette.pressed),
		})
	)

	return button
end

local function createTextBox(parent, name, placeholderText, x, y)
	local textBox = Instance.new("TextBox")
	textBox.Name = name
	textBox.Size = UDim2.new(1, -36, 0, 52)
	textBox.Position = UDim2.fromOffset(x, y)
	textBox.BackgroundColor3 = COLORS.input
	textBox.BorderSizePixel = 0
	textBox.Font = Enum.Font.GothamMedium
	textBox.PlaceholderText = placeholderText
	textBox.PlaceholderColor3 = Color3.fromRGB(108, 122, 139)
	textBox.Text = ""
	textBox.TextColor3 = COLORS.inputText
	textBox.TextSize = 22
	textBox.ClearTextOnFocus = false
	textBox.Parent = parent
	textBox:SetAttribute("EnabledBackgroundColor", COLORS.input)
	textBox:SetAttribute("DisabledBackgroundColor", Color3.fromRGB(183, 193, 205))
	textBox:SetAttribute("EnabledStrokeColor", COLORS.accentDark)
	textBox:SetAttribute("DisabledStrokeColor", COLORS.buttonDisabled)
	addCorner(textBox, 14)
	addStroke(textBox, COLORS.accentDark, 1, 0.25)

	return textBox
end

local function createSectionTitle(parent, text, x, y, width)
	local eyebrow = createLabel(
		parent,
		text .. "SectionEyebrow",
		"SECTION",
		UDim2.fromOffset(width, 16),
		UDim2.fromOffset(x, y),
		12,
		COLORS.mutedText
	)
	eyebrow.Font = Enum.Font.GothamBold
	eyebrow.TextTransparency = 0.18

	local title = createLabel(
		parent,
		text .. "SectionLabel",
		text,
		UDim2.fromOffset(width, 28),
		UDim2.fromOffset(x, y + 18),
		22,
		COLORS.text
	)
	title.Font = Enum.Font.GothamBold
	return title
end

local function createCurrencyHud(parent)
	local hud = createCard(parent, "CurrencyHud", UDim2.fromOffset(246, 58), UDim2.fromOffset(20, 20), COLORS.panelStrong, 18)
	hud.ZIndex = 20
	addStroke(hud, COLORS.coin, 1, 0.18)
	addPadding(hud, 16, 8, 16, 8)

	local label = createLabel(hud, "CurrencyTitleLabel", "COINS", UDim2.fromOffset(74, 16), UDim2.fromOffset(0, 0), 12, COLORS.mutedText)
	label.Font = Enum.Font.GothamBold
	label.TextTransparency = 0.08
	label.ZIndex = 21

	local amount = createLabel(hud, "CurrencyAmountLabel", "0", UDim2.new(1, -134, 0, 28), UDim2.fromOffset(0, 20), 24, COLORS.coin)
	amount.Font = Enum.Font.GothamBlack
	amount.ZIndex = 21

	local delta = createLabel(hud, "CurrencyDeltaLabel", "", UDim2.fromOffset(54, 26), UDim2.new(1, -116, 0, 22), 16, COLORS.success)
	delta.Font = Enum.Font.GothamBlack
	delta.TextXAlignment = Enum.TextXAlignment.Right
	delta.ZIndex = 21

	local buyButton = createButton(hud, "BuyCoinsHudButton", "Buy", UDim2.fromOffset(58, 34), UDim2.new(1, -58, 0, 12), "Secondary")
	buyButton.TextSize = 14
	buyButton.ZIndex = 21

	return hud
end

local function createHeader(parent, subtitle)
	local brand = createLabel(parent, "TitleLabel", "FAST", UDim2.fromOffset(260, 34), UDim2.fromOffset(42, 28), 18, COLORS.accent)
	brand.Font = Enum.Font.GothamBlack

	local title = createLabel(parent, "TitleWordmarkLabel", "GUESSER", UDim2.fromOffset(340, 58), UDim2.fromOffset(42, 52), 42, COLORS.text)
	title.Font = Enum.Font.GothamBlack

	createLabel(
		parent,
		"SubtitleLabel",
		subtitle,
		UDim2.new(1, -84, 0, 42),
		UDim2.fromOffset(42, 118),
		17,
		COLORS.mutedText
	)

	local glow = Instance.new("Frame")
	glow.Name = "HeaderGlow"
	glow.AnchorPoint = Vector2.new(1, 0)
	glow.Position = UDim2.new(1, -42, 0, 38)
	glow.Size = UDim2.fromOffset(212, 116)
	glow.BackgroundColor3 = COLORS.accent
	glow.BackgroundTransparency = 0.78
	glow.BorderSizePixel = 0
	glow.Parent = parent
	addCorner(glow, 28)
	addGradient(
		glow,
		0,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLORS.accent),
			ColorSequenceKeypoint.new(1, COLORS.success),
		}),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 0.85),
		})
	)
end

local function createMenuScreen(parent)
	local screen = createScreen("MenuScreen")
	screen.Parent = parent

	local shell = createCenteredShell(
		screen,
		"MenuShell",
		UDim2.new(0.88, 0, 0.78, 0),
		Vector2.new(760, 520),
		Vector2.new(1100, 720)
	)
	createHeader(shell, "Lock exact digits before your opponent cracks your code.")

	local heroCard = createCard(shell, "MenuHeroCard", UDim2.new(0.53, -16, 0, 282), UDim2.fromOffset(42, 176), COLORS.panelStrong)
	addPadding(heroCard, 28, 26, 28, 26)
	createLabel(heroCard, "MenuTagLabel", "2-PLAYER SHOWDOWN", UDim2.new(1, 0, 0, 18), UDim2.fromOffset(0, 0), 13, COLORS.warning).Font =
		Enum.Font.GothamBold
	local heading = createLabel(heroCard, "MenuHeadingLabel", "Read the pattern. Win the race.", UDim2.new(1, 0, 0, 92), UDim2.fromOffset(0, 28), 34)
	heading.Font = Enum.Font.GothamBlack
	heading.TextYAlignment = Enum.TextYAlignment.Top
	createLabel(
		heroCard,
		"MenuBodyLabel",
		"Set a 4-digit secret, trade guesses, and lock exact hits before the other player solves your full code.",
		UDim2.new(1, 0, 0, 70),
		UDim2.fromOffset(0, 128),
		18,
		COLORS.mutedText
	)

	local playButton = createButton(heroCard, "PlayButton", "Play Match", UDim2.new(0.58, -8, 0, 58), UDim2.fromOffset(0, 210), "Primary")
	playButton.TextSize = 22
	local backButton = createButton(heroCard, "MenuBackButton", "Back to Lobby", UDim2.new(0.42, -8, 0, 58), UDim2.new(1, 0, 0, 210), "Secondary")
	backButton.AnchorPoint = Vector2.new(1, 0)
	backButton.TextSize = 17

	local infoCard = createCard(shell, "MenuInfoCard", UDim2.new(0.47, -26, 0, 250), UDim2.new(0.53, 10, 0, 192), COLORS.panelAlt)
	addPadding(infoCard, 26, 24, 26, 24)
	createSectionTitle(infoCard, "How To Play", 0, 0, 240)
	createLabel(
		infoCard,
		"MenuInfoTextLabel",
		"Both players submit a secret. On each turn, enter a 4-digit guess. Exact-position matches lock in and stay visible for the rest of the round.",
		UDim2.new(1, 0, 0, 82),
		UDim2.fromOffset(0, 54),
		16,
		COLORS.mutedText
	)
	createLabel(
		infoCard,
		"MenuInfoFootnoteLabel",
		"If the first player solves first, the second player still gets one final chance to tie.",
		UDim2.new(1, 0, 0, 44),
		UDim2.fromOffset(0, 140),
		15,
		COLORS.text
	)
	local rulesButton = createButton(infoCard, "HowToPlayButton", "View Rules", UDim2.new(1, 0, 0, 42), UDim2.fromOffset(0, 190), "Secondary")
	rulesButton.TextSize = 16

	local howToPlayPanel = Instance.new("Frame")
	howToPlayPanel.Name = "HowToPlayPanel"
	howToPlayPanel.Size = UDim2.fromScale(1, 1)
	howToPlayPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	howToPlayPanel.BackgroundTransparency = 0.34
	howToPlayPanel.BorderSizePixel = 0
	howToPlayPanel.Visible = false
	howToPlayPanel.Parent = screen

	local howToPlayModal = createCenteredShell(
		howToPlayPanel,
		"HowToPlayModal",
		UDim2.new(0.66, 0, 0.56, 0),
		Vector2.new(620, 360),
		Vector2.new(880, 520)
	)
	addPadding(howToPlayModal, 30, 26, 30, 30)
	createSectionTitle(howToPlayModal, "How To Play", 0, 0, 220)
	local modalText = createLabel(
		howToPlayModal,
		"HowToPlayTextLabel",
		"Choose a 4-digit secret. When the round starts, take turns making 4-digit guesses. Each exact-position match becomes locked, helping narrow the answer. The player who fully reveals the opponent's code wins, with a final tie chance for the second player if needed.",
		UDim2.new(1, 0, 0, 160),
		UDim2.fromOffset(0, 62),
		17,
		COLORS.mutedText
	)
	modalText.TextYAlignment = Enum.TextYAlignment.Top
	createButton(howToPlayModal, "CloseHowToPlayButton", "Close", UDim2.fromOffset(156, 46), UDim2.new(1, -156, 1, -46), "Primary")
end

local function createLobbyPlayerCard(parent, name, title, position, accentColor)
	local card = createCard(parent, name, UDim2.new(1, 0, 0, 126), position, COLORS.panelAlt)
	card:SetAttribute("AccentColor", accentColor)

	local accent = Instance.new("Frame")
	accent.Name = "AccentBar"
	accent.Size = UDim2.fromOffset(8, 82)
	accent.Position = UDim2.fromOffset(18, 22)
	accent.BackgroundColor3 = accentColor
	accent.BorderSizePixel = 0
	accent.Parent = card
	addCorner(accent, 8)

	local badge = createLabel(card, name .. "BadgeLabel", title, UDim2.fromOffset(120, 18), UDim2.fromOffset(42, 24), 13, COLORS.mutedText)
	badge.Font = Enum.Font.GothamBold
	badge.TextTransparency = 0.14

	local slot = createLabel(card, name == "PlayerOneRow" and "PlayerOneSlotLabel" or "PlayerTwoSlotLabel", "Waiting", UDim2.new(1, -176, 0, 34), UDim2.fromOffset(42, 44), 26)
	slot.Font = Enum.Font.GothamBold
	slot.TextYAlignment = Enum.TextYAlignment.Top

	local readyPill = createCard(card, name .. "ReadyPill", UDim2.fromOffset(156, 42), UDim2.new(1, -174, 0, 38), COLORS.panelRaised, 21)
	local readyLabel = createLabel(
		readyPill,
		name == "PlayerOneRow" and "PlayerOneReadyLabel" or "PlayerTwoReadyLabel",
		"Not ready",
		UDim2.new(1, 0, 1, 0),
		UDim2.fromOffset(0, 0),
		16,
		COLORS.mutedText
	)
	readyLabel.TextXAlignment = Enum.TextXAlignment.Center
	readyLabel.Font = Enum.Font.GothamBold

	return card
end

local function createLobbyScreen(parent)
	local screen = createScreen("LobbyScreen")
	screen.Parent = parent

	local shell = createCenteredShell(
		screen,
		"LobbyShell",
		UDim2.new(0.76, 0, 0.78, 0),
		Vector2.new(720, 620),
		Vector2.new(960, 720)
	)
	createHeader(shell, "Match with a second player and confirm both sides are ready.")

	local panel = createCard(shell, "LobbyPanel", UDim2.new(1, -84, 0, 468), UDim2.fromOffset(42, 176), COLORS.panelStrong)
	addPadding(panel, 28, 24, 28, 28)
	createSectionTitle(panel, "Ready Up", 0, 0, 160)
	local status = createLabel(panel, "LobbyStatusLabel", "Waiting for opponent", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 54), 30)
	status.Font = Enum.Font.GothamBlack

	createLobbyPlayerCard(panel, "PlayerOneRow", "PLAYER ONE", UDim2.fromOffset(0, 112), COLORS.accent)
	createLobbyPlayerCard(panel, "PlayerTwoRow", "PLAYER TWO", UDim2.fromOffset(0, 260), COLORS.success)

	local readyButton = createButton(panel, "ReadyButton", "Ready", UDim2.new(0.5, -10, 0, 52), UDim2.new(0, 0, 1, -52), "Primary")
	readyButton.AnchorPoint = Vector2.new(0, 1)
	local backButton = createButton(panel, "LobbyBackButton", "Back to Lobby", UDim2.new(0.5, -10, 0, 52), UDim2.new(1, 0, 1, -52), "Secondary")
	backButton.AnchorPoint = Vector2.new(1, 1)
end

local function createStatusPanel(parent)
	local panel = createCard(parent, "StatusPanel", UDim2.new(1, 0, 0, 154), UDim2.fromOffset(0, 0), COLORS.panelStrong)

	local ribbon = Instance.new("Frame")
	ribbon.Name = "StatusRibbon"
	ribbon.Size = UDim2.fromOffset(12, 96)
	ribbon.Position = UDim2.fromOffset(22, 24)
	ribbon.BackgroundColor3 = COLORS.accent
	ribbon.BorderSizePixel = 0
	ribbon.Parent = panel
	addCorner(ribbon, 10)
	addGradient(
		ribbon,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLORS.accent),
			ColorSequenceKeypoint.new(1, COLORS.success),
		})
	)

	createLabel(panel, "StatusEyebrowLabel", "ROUND STATUS", UDim2.fromOffset(220, 18), UDim2.fromOffset(54, 22), 13, COLORS.mutedText).Font =
		Enum.Font.GothamBold
	local statusLabel = createLabel(panel, "StatusLabel", "Waiting for opponent", UDim2.new(1, -86, 0, 50), UDim2.fromOffset(54, 42), 34)
	statusLabel.Font = Enum.Font.GothamBlack
	createLabel(panel, "TurnLabel", "Turn: waiting", UDim2.fromOffset(240, 24), UDim2.fromOffset(56, 102), 17, COLORS.mutedText)
	local gameOverLabel = createLabel(panel, "GameOverLabel", "", UDim2.fromOffset(260, 28), UDim2.new(1, -296, 0, 100), 19, COLORS.warning)
	gameOverLabel.Font = Enum.Font.GothamBold

	local chip = createCard(panel, "StatusInfoChip", UDim2.fromOffset(190, 40), UDim2.new(1, -212, 0, 24), COLORS.panelRaised, 20)
	createLabel(chip, "StatusChipLabel", "Secret phase", UDim2.new(1, 0, 1, 0), UDim2.fromOffset(0, 0), 15, COLORS.text).TextXAlignment =
		Enum.TextXAlignment.Center
end

local function createSecretPanel(parent)
	local panel = createCard(parent, "SecretPanel", UDim2.new(0.5, -10, 0, 226), UDim2.fromOffset(0, 0), COLORS.panel)
	createSectionTitle(panel, "Secret", 18, 18, 180)
	createLabel(panel, "SecretHelpLabel", "Choose the 4-digit code your opponent is trying to reveal.", UDim2.new(1, -36, 0, 34), UDim2.fromOffset(18, 62), 15, COLORS.mutedText)
	local state = createLabel(panel, "SecretStateLabel", "Waiting", UDim2.new(1, -36, 0, 20), UDim2.fromOffset(18, 98), 14, COLORS.mutedText)
	state.Font = Enum.Font.GothamBold
	createTextBox(panel, "SecretTextBox", "Enter 4 digits", 18, 124)
	createButton(panel, "SubmitSecretButton", "Submit Secret", UDim2.new(1, -36, 0, 42), UDim2.fromOffset(18, 178), "Primary")
	local validation = createLabel(panel, "SecretValidationLabel", "", UDim2.new(1, -36, 0, 20), UDim2.fromOffset(18, 202), 15, COLORS.errorText)
	validation.TextYAlignment = Enum.TextYAlignment.Top
end

local function createGuessPanel(parent)
	local panel = createCard(parent, "GuessPanel", UDim2.new(0.5, -10, 0, 226), UDim2.new(0.5, 10, 0, 0), COLORS.panelRaised)
	createSectionTitle(panel, "Guess", 18, 18, 180)
	createLabel(panel, "GuessHelpLabel", "Submit guesses on your turn. Exact digits lock permanently into place.", UDim2.new(1, -36, 0, 34), UDim2.fromOffset(18, 62), 15, COLORS.mutedText)
	local state = createLabel(panel, "GuessStateLabel", "Waiting", UDim2.new(1, -36, 0, 20), UDim2.fromOffset(18, 98), 14, COLORS.mutedText)
	state.Font = Enum.Font.GothamBold
	createTextBox(panel, "GuessTextBox", "Enter 4 digits", 18, 124)
	createButton(panel, "SubmitGuessButton", "Submit Guess", UDim2.new(1, -36, 0, 42), UDim2.fromOffset(18, 178), "Primary")
	local validation = createLabel(panel, "GuessValidationLabel", "", UDim2.new(1, -36, 0, 20), UDim2.fromOffset(18, 202), 15, COLORS.errorText)
	validation.TextYAlignment = Enum.TextYAlignment.Top
end

local function createDigitSlots(parent, prefix, x, y, filledColor)
	for index = 1, 4 do
		local slot = createCard(parent, prefix .. "Slot" .. tostring(index), UDim2.fromOffset(38, 34), UDim2.fromOffset(x + ((index - 1) * 44), y), COLORS.panelRaised, 10)
		addStroke(slot, filledColor, 1, 0.28)
		local label = createLabel(slot, "DigitLabel", "_", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 20, COLORS.text)
		label.Font = Enum.Font.GothamBlack
		label.TextXAlignment = Enum.TextXAlignment.Center
	end
end

local function createLockedPanel(parent)
	local panel = createCard(parent, "LockedPanel", UDim2.new(1, 0, 0, 160), UDim2.fromOffset(0, 0), COLORS.panel)
	createSectionTitle(panel, "Locked Digits", 18, 18, 180)

	local yourCard = createCard(panel, "YourLockedCard", UDim2.new(0.5, -12, 0, 82), UDim2.fromOffset(18, 60), COLORS.successDark, 18)
	addStroke(yourCard, COLORS.success, 1, 0.14)
	createLabel(yourCard, "YourLockedEyebrow", "YOUR LOCKED", UDim2.fromOffset(160, 18), UDim2.fromOffset(16, 12), 12, Color3.fromRGB(211, 244, 224)).Font =
		Enum.Font.GothamBold
	local yourLabel = createLabel(yourCard, "PlayerLockedLabel", "Your code", UDim2.fromOffset(130, 24), UDim2.fromOffset(16, 36), 17, COLORS.text)
	yourLabel.Font = Enum.Font.GothamBold
	createDigitSlots(yourCard, "PlayerLocked", 156, 34, COLORS.success)

	local opponentCard = createCard(panel, "OpponentLockedCard", UDim2.new(0.5, -12, 0, 82), UDim2.new(0.5, 6, 0, 60), COLORS.panelAlt, 18)
	addStroke(opponentCard, COLORS.border, 1, 0.1)
	createLabel(opponentCard, "OpponentLockedEyebrow", "OPPONENT LOCKED", UDim2.fromOffset(190, 18), UDim2.fromOffset(16, 12), 12, COLORS.mutedText).Font =
		Enum.Font.GothamBold
	local opponentLabel = createLabel(opponentCard, "OpponentLockedLabel", "Their code", UDim2.fromOffset(130, 24), UDim2.fromOffset(16, 36), 17, COLORS.text)
	opponentLabel.Font = Enum.Font.GothamBold
	createDigitSlots(opponentCard, "OpponentLocked", 156, 34, COLORS.accent)

	local highLowSummary = createLabel(
		panel,
		"HighLowSummaryLabel",
		"Higher / Lower feedback appears in the history panel after each guess.",
		UDim2.new(1, -210, 0, 54),
		UDim2.fromOffset(18, 72),
		20,
		COLORS.mutedText
	)
	highLowSummary.Font = Enum.Font.GothamBold
	highLowSummary.Visible = false

	local restartButton = createButton(panel, "RestartButton", "Play Again", UDim2.fromOffset(156, 42), UDim2.new(1, -174, 0, 18), "Secondary")
	restartButton.TextSize = 16
end

local function createHistoryPanel(parent)
	local panel = createCard(parent, "HistoryPanel", UDim2.new(0, 318, 1, 0), UDim2.new(1, -318, 0, 0), COLORS.panel)
	createSectionTitle(panel, "Guess History", 18, 18, 220)
	createLabel(panel, "HistoryHintLabel", "Each entry shows the guess and currently locked feedback.", UDim2.new(1, -36, 0, 36), UDim2.fromOffset(18, 62), 14, COLORS.mutedText)

	local historyFrame = Instance.new("ScrollingFrame")
	historyFrame.Name = "GuessHistoryFrame"
	historyFrame.Size = UDim2.new(1, -36, 1, -122)
	historyFrame.Position = UDim2.fromOffset(18, 104)
	historyFrame.BackgroundColor3 = COLORS.panelAlt
	historyFrame.BorderSizePixel = 0
	historyFrame.CanvasSize = UDim2.fromOffset(0, 0)
	historyFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	historyFrame.ScrollBarThickness = 8
	historyFrame.ScrollBarImageColor3 = COLORS.accent
	historyFrame.Parent = panel
	addCorner(historyFrame, 18)
	addStroke(historyFrame, COLORS.borderSoft, 1, 0.16)
	addPadding(historyFrame, 10, 10, 10, 10)

	local historyList = Instance.new("UIListLayout")
	historyList.Name = "GuessHistoryList"
	historyList.Padding = UDim.new(0, 10)
	historyList.SortOrder = Enum.SortOrder.LayoutOrder
	historyList.Parent = historyFrame

	return panel
end

local function createMatchScreen(parent)
	local screen = createScreen("MatchScreen")
	screen.Parent = parent

	local shell = createCenteredShell(
		screen,
		"MatchShell",
		UDim2.new(0.92, 0, 0.88, 0),
		Vector2.new(980, 760),
		Vector2.new(1220, 840)
	)
	createHeader(shell, "Race to solve the code. Locked digits stay revealed for the rest of the round.")

	local mainColumn = Instance.new("Frame")
	mainColumn.Name = "MatchMainColumn"
	mainColumn.Size = UDim2.new(1, -384, 1, -188)
	mainColumn.Position = UDim2.fromOffset(42, 154)
	mainColumn.BackgroundTransparency = 1
	mainColumn.Parent = shell

	createStatusPanel(mainColumn)
	createSecretPanel(mainColumn)
	createGuessPanel(mainColumn)
	createLockedPanel(mainColumn)

	local historyPanel = createHistoryPanel(shell)
	historyPanel.Position = UDim2.new(1, -360, 0, 154)
	historyPanel.Size = UDim2.new(0, 318, 1, -188)

	local secretPanel = mainColumn:FindFirstChild("SecretPanel")
	local guessPanel = mainColumn:FindFirstChild("GuessPanel")
	local lockedPanel = mainColumn:FindFirstChild("LockedPanel")
	if secretPanel then
		secretPanel.Position = UDim2.fromOffset(0, 166)
	end
	if guessPanel then
		guessPanel.Position = UDim2.new(0.5, 10, 0, 166)
	end
	if lockedPanel then
		lockedPanel.Position = UDim2.fromOffset(0, 404)
	end
end

local function createResultScreen(parent)
	local screen = createScreen("ResultScreen")
	screen.Parent = parent

	local shell = createCenteredShell(
		screen,
		"ResultShell",
		UDim2.new(0.64, 0, 0.7, 0),
		Vector2.new(700, 560),
		Vector2.new(900, 700)
	)
	createHeader(shell, "Round complete.")

	local panel = createCard(shell, "ResultPanel", UDim2.new(1, -84, 0, 380), UDim2.fromOffset(42, 176), COLORS.panelStrong)
	addPadding(panel, 28, 24, 28, 28)
	createSectionTitle(panel, "Replay", 0, 0, 140)
	local title = createLabel(panel, "ResultTitleLabel", "Game over", UDim2.new(1, 0, 0, 38), UDim2.fromOffset(0, 48), 32)
	title.Font = Enum.Font.GothamBlack

	local winnerCard = createCard(panel, "ResultWinnerCard", UDim2.new(1, 0, 0, 86), UDim2.fromOffset(0, 94), COLORS.panelRaised, 18)
	local winner = createLabel(panel, "ResultWinnerLabel", "Winner: -", UDim2.new(1, -32, 0, 32), UDim2.fromOffset(16, 114), 28)
	winner.Font = Enum.Font.GothamBold
	local subtitle = createLabel(panel, "ResultSubtitleLabel", "Round complete.", UDim2.new(1, -32, 0, 22), UDim2.fromOffset(16, 148), 15, COLORS.mutedText)
	subtitle.Font = Enum.Font.GothamBold

	local secretsCard = createCard(panel, "ResultSecretsCard", UDim2.new(1, 0, 0, 76), UDim2.fromOffset(0, 196), COLORS.panelAlt, 16)
	addPadding(secretsCard, 18, 12, 18, 12)
	local yourSecret = createLabel(secretsCard, "ResultYourSecretLabel", "Your secret: -", UDim2.new(0.5, -12, 0, 46), UDim2.fromOffset(0, 2), 18, COLORS.text)
	yourSecret.Font = Enum.Font.GothamBold
	local opponentSecret = createLabel(secretsCard, "ResultOpponentSecretLabel", "Opponent secret: -", UDim2.new(0.5, -12, 0, 46), UDim2.new(0.5, 12, 0, 2), 18, COLORS.text)
	opponentSecret.Font = Enum.Font.GothamBold
	opponentSecret.TextXAlignment = Enum.TextXAlignment.Right

	local resultStatusLabel = createLabel(panel, "ResultStatusLabel", "", UDim2.new(1, 0, 0, 26), UDim2.fromOffset(0, 290), 18, COLORS.mutedText)
	resultStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
	local rewardLabel = createLabel(panel, "ResultRewardLabel", "", UDim2.new(1, 0, 0, 26), UDim2.fromOffset(0, 318), 18, COLORS.coin)
	rewardLabel.Font = Enum.Font.GothamBlack
	local playAgain = createButton(panel, "ResultPlayAgainButton", "Play Again", UDim2.new(0.5, -10, 0, 50), UDim2.new(0, 0, 1, -18), "Primary")
	playAgain.AnchorPoint = Vector2.new(0, 1)
	local backButton = createButton(panel, "BackToMenuButton", "Back to Lobby", UDim2.new(0.5, -10, 0, 50), UDim2.new(1, 0, 1, -18), "Secondary")
	backButton.AnchorPoint = Vector2.new(1, 1)
end

local function createShopPanel(parent)
	local overlay = Instance.new("Frame")
	overlay.Name = "ShopPanel"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.34
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Active = true
	overlay.ZIndex = 30
	overlay.Parent = parent

	local shell = createCenteredShell(overlay, "ShopModal", UDim2.new(0.72, 0, 0.78, 0), Vector2.new(780, 640), Vector2.new(1000, 760))
	shell.ZIndex = 31
	addPadding(shell, 30, 26, 30, 30)
	createSectionTitle(shell, "Shop", 0, 0, 160)
	local balance = createLabel(shell, "ShopBalanceLabel", "Coins: 0", UDim2.fromOffset(220, 30), UDim2.new(1, -220, 0, 2), 20, COLORS.coin)
	balance.Font = Enum.Font.GothamBlack
	balance.TextXAlignment = Enum.TextXAlignment.Right

	local status = createLabel(shell, "ShopStatusLabel", "Select an item.", UDim2.new(1, -210, 0, 28), UDim2.fromOffset(0, 58), 16, COLORS.mutedText)
	status.Font = Enum.Font.GothamBold

	for index = 1, 4 do
		local y = 104 + ((index - 1) * 94)
		local row = createCard(shell, "ShopItemRow" .. tostring(index), UDim2.new(1, 0, 0, 82), UDim2.fromOffset(0, y), COLORS.panelAlt, 16)
		addPadding(row, 18, 12, 18, 12)
		local name = createLabel(row, "ShopItemNameLabel" .. tostring(index), "Item", UDim2.new(1, -340, 0, 26), UDim2.fromOffset(0, 0), 21, COLORS.text)
		name.Font = Enum.Font.GothamBold
		createLabel(row, "ShopItemMetaLabel" .. tostring(index), "Category", UDim2.new(1, -340, 0, 22), UDim2.fromOffset(0, 34), 15, COLORS.mutedText)
		local state = createLabel(row, "ShopItemStateLabel" .. tostring(index), "", UDim2.fromOffset(112, 24), UDim2.new(1, -322, 0, 2), 16, COLORS.coin)
		state.Font = Enum.Font.GothamBlack
		state.TextXAlignment = Enum.TextXAlignment.Right
		createButton(row, "ShopBuyButton" .. tostring(index), "Buy", UDim2.fromOffset(104, 44), UDim2.new(1, -214, 0, 7), "Primary").TextSize = 16
		createButton(row, "ShopEquipButton" .. tostring(index), "Equip", UDim2.fromOffset(94, 44), UDim2.new(1, -94, 0, 7), "Secondary").TextSize = 16
	end

	local footer = createCard(shell, "ShopFooter", UDim2.new(1, 0, 0, 64), UDim2.new(0, 0, 1, -64), COLORS.panelAlt, 18)
	footer.BackgroundTransparency = 0.08
	createButton(footer, "OpenCoinPacksButton", "Buy Coins", UDim2.fromOffset(156, 44), UDim2.fromOffset(18, 10), "Primary")
	createButton(footer, "CloseShopButton", "Close", UDim2.fromOffset(156, 44), UDim2.new(1, -174, 0, 10), "Secondary")
	setTreeZIndex(shell, 32)
end

local function createCoinPacksPanel(parent)
	local overlay = Instance.new("Frame")
	overlay.Name = "CoinPacksPanel"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.34
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Active = true
	overlay.ZIndex = 30
	overlay.Parent = parent

	local shell = createCenteredShell(overlay, "CoinPacksModal", UDim2.new(0.6, 0, 0.66, 0), Vector2.new(660, 520), Vector2.new(840, 660))
	shell.ZIndex = 31
	addPadding(shell, 30, 26, 30, 30)
	createSectionTitle(shell, "Buy Coins", 0, 0, 200)
	local balance = createLabel(shell, "CoinPacksBalanceLabel", "Coins: 0", UDim2.fromOffset(220, 30), UDim2.new(1, -220, 0, 2), 20, COLORS.coin)
	balance.Font = Enum.Font.GothamBlack
	balance.TextXAlignment = Enum.TextXAlignment.Right
	local status = createLabel(shell, "CoinPacksStatusLabel", "Choose a coin pack.", UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 58), 16, COLORS.mutedText)
	status.Font = Enum.Font.GothamBold

	for index = 1, 3 do
		local y = 104 + ((index - 1) * 104)
		local row = createCard(shell, "CoinPackRow" .. tostring(index), UDim2.new(1, 0, 0, 88), UDim2.fromOffset(0, y), COLORS.panelAlt, 16)
		addPadding(row, 18, 13, 18, 13)
		local name = createLabel(row, "CoinPackNameLabel" .. tostring(index), "Coin Pack", UDim2.new(1, -250, 0, 26), UDim2.fromOffset(0, 0), 21, COLORS.text)
		name.Font = Enum.Font.GothamBold
		createLabel(row, "CoinPackDescriptionLabel" .. tostring(index), "Pack details", UDim2.new(1, -250, 0, 24), UDim2.fromOffset(0, 34), 15, COLORS.mutedText)
		local amount = createLabel(row, "CoinPackAmountLabel" .. tostring(index), "+0 coins", UDim2.fromOffset(120, 26), UDim2.new(1, -244, 0, 4), 20, COLORS.coin)
		amount.Font = Enum.Font.GothamBlack
		amount.TextXAlignment = Enum.TextXAlignment.Right
		createButton(row, "CoinPackBuyButton" .. tostring(index), "Buy", UDim2.fromOffset(104, 44), UDim2.new(1, -104, 0, 9), "Primary").TextSize = 16
	end

	local footer = createCard(shell, "CoinPacksFooter", UDim2.new(1, 0, 0, 64), UDim2.new(0, 0, 1, -64), COLORS.panelAlt, 18)
	footer.BackgroundTransparency = 0.08
	createButton(footer, "CloseCoinPacksButton", "Close", UDim2.fromOffset(156, 44), UDim2.new(1, -174, 0, 10), "Secondary")
	setTreeZIndex(shell, 32)
end

local function createRewardsPanel(parent)
	local overlay = Instance.new("Frame")
	overlay.Name = "RewardsPanel"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.34
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Active = true
	overlay.ZIndex = 30
	overlay.Parent = parent

	local shell = createCenteredShell(overlay, "RewardsModal", UDim2.new(0.64, 0, 0.74, 0), Vector2.new(700, 600), Vector2.new(900, 740))
	shell.ZIndex = 31
	addPadding(shell, 30, 26, 30, 30)
	createSectionTitle(shell, "Rewards", 0, 0, 180)
	local balance = createLabel(shell, "RewardsBalanceLabel", "Coins: 0", UDim2.fromOffset(220, 30), UDim2.new(1, -220, 0, 2), 20, COLORS.coin)
	balance.Font = Enum.Font.GothamBlack
	balance.TextXAlignment = Enum.TextXAlignment.Right

	local card = createCard(shell, "RewardClaimCard", UDim2.new(1, 0, 0, 214), UDim2.fromOffset(0, 96), COLORS.panelStrong, 18)
	addPadding(card, 24, 22, 24, 22)
	local title = createLabel(card, "RewardTitleLabel", "Daily Coins", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 0), 26, COLORS.text)
	title.Font = Enum.Font.GothamBlack
	createLabel(card, "RewardBodyLabel", "Claim once per UTC day. The server saves your claim state, so today's reward cannot be claimed twice.", UDim2.new(1, -240, 0, 70), UDim2.fromOffset(0, 46), 17, COLORS.mutedText)
	local amount = createLabel(card, "RewardAmountLabel", "+25", UDim2.fromOffset(200, 58), UDim2.new(1, -210, 0, 48), 44, COLORS.coin)
	amount.Font = Enum.Font.GothamBlack
	amount.TextXAlignment = Enum.TextXAlignment.Right
	createLabel(card, "RewardNextClaimLabel", "Ready now", UDim2.new(1, -260, 0, 24), UDim2.fromOffset(0, 124), 17, COLORS.success).Font = Enum.Font.GothamBold
	createButton(card, "ClaimRewardButton", "Claim Daily Reward", UDim2.fromOffset(240, 52), UDim2.fromOffset(0, 150), "Primary")

	local wheelCard = createCard(shell, "RewardWheelCard", UDim2.new(1, 0, 0, 126), UDim2.fromOffset(0, 328), COLORS.panelAlt, 18)
	addPadding(wheelCard, 20, 18, 20, 18)
	createLabel(wheelCard, "RewardWheelTitleLabel", "Wheel Preview", UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 0), 20, COLORS.text).Font = Enum.Font.GothamBlack
	createLabel(wheelCard, "RewardWheelBodyLabel", "Reward wheel coming next. These server-owned segments are ready for a future spin action.", UDim2.new(1, 0, 0, 38), UDim2.fromOffset(0, 30), 14, COLORS.mutedText)
	for index = 1, 5 do
		local segment = createCard(wheelCard, "RewardWheelSegment" .. tostring(index), UDim2.new(0.2, -8, 0, 36), UDim2.new((index - 1) * 0.2, 4, 0, 66), COLORS.panelRaised, 12)
		local label = createLabel(segment, "RewardWheelSegmentLabel" .. tostring(index), "-", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 16, COLORS.coin)
		label.Font = Enum.Font.GothamBlack
		label.TextXAlignment = Enum.TextXAlignment.Center
	end

	local status = createLabel(shell, "RewardsStatusLabel", "Reward ready.", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 474), 18, COLORS.mutedText)
	status.Font = Enum.Font.GothamBold
	local close = createButton(shell, "CloseRewardsButton", "Close", UDim2.fromOffset(156, 44), UDim2.new(1, -156, 1, -44), "Secondary")
	close.AnchorPoint = Vector2.new(0, 1)
	setTreeZIndex(shell, 32)
end

local function createLeaderboardPanel(parent)
	local overlay = Instance.new("Frame")
	overlay.Name = "LeaderboardPanel"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.34
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Active = true
	overlay.ZIndex = 30
	overlay.Parent = parent

	local shell = createCenteredShell(overlay, "LeaderboardModal", UDim2.new(0.62, 0, 0.7, 0), Vector2.new(680, 560), Vector2.new(900, 700))
	shell.ZIndex = 31
	addPadding(shell, 30, 26, 30, 30)
	createSectionTitle(shell, "Leaderboard", 0, 0, 220)
	local status = createLabel(shell, "LeaderboardStatusLabel", "Session leaderboard", UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 58), 16, COLORS.mutedText)
	status.Font = Enum.Font.GothamBold

	local header = createCard(shell, "LeaderboardHeaderRow", UDim2.new(1, 0, 0, 38), UDim2.fromOffset(0, 96), COLORS.panelAlt, 12)
	addPadding(header, 16, 8, 16, 8)
	createLabel(header, "LeaderboardRankHeader", "#", UDim2.fromOffset(42, 20), UDim2.fromOffset(0, 0), 13, COLORS.mutedText).Font = Enum.Font.GothamBold
	createLabel(header, "LeaderboardNameHeader", "PLAYER", UDim2.new(1, -320, 0, 20), UDim2.fromOffset(52, 0), 13, COLORS.mutedText).Font = Enum.Font.GothamBold
	local winsHeader = createLabel(header, "LeaderboardWinsHeader", "WINS", UDim2.fromOffset(72, 20), UDim2.new(1, -250, 0, 0), 13, COLORS.mutedText)
	winsHeader.Font = Enum.Font.GothamBold
	winsHeader.TextXAlignment = Enum.TextXAlignment.Right
	local streakHeader = createLabel(header, "LeaderboardStreakHeader", "STREAK", UDim2.fromOffset(82, 20), UDim2.new(1, -158, 0, 0), 13, COLORS.mutedText)
	streakHeader.Font = Enum.Font.GothamBold
	streakHeader.TextXAlignment = Enum.TextXAlignment.Right
	local coinsHeader = createLabel(header, "LeaderboardCoinsHeader", "COINS", UDim2.fromOffset(82, 20), UDim2.new(1, -72, 0, 0), 13, COLORS.mutedText)
	coinsHeader.Font = Enum.Font.GothamBold
	coinsHeader.TextXAlignment = Enum.TextXAlignment.Right

	for index = 1, 6 do
		local y = 146 + ((index - 1) * 58)
		local row = createCard(shell, "LeaderboardRow" .. tostring(index), UDim2.new(1, 0, 0, 48), UDim2.fromOffset(0, y), COLORS.panelAlt, 12)
		addPadding(row, 16, 9, 16, 9)
		local rank = createLabel(row, "LeaderboardRankLabel" .. tostring(index), "-", UDim2.fromOffset(42, 26), UDim2.fromOffset(0, 0), 20, COLORS.coin)
		rank.Font = Enum.Font.GothamBlack
		local name = createLabel(row, "LeaderboardNameLabel" .. tostring(index), "Open Slot", UDim2.new(1, -320, 0, 26), UDim2.fromOffset(52, 0), 18, COLORS.text)
		name.Font = Enum.Font.GothamBold
		local wins = createLabel(row, "LeaderboardWinsLabel" .. tostring(index), "0", UDim2.fromOffset(72, 26), UDim2.new(1, -250, 0, 0), 18, COLORS.text)
		wins.Font = Enum.Font.GothamBlack
		wins.TextXAlignment = Enum.TextXAlignment.Right
		local streak = createLabel(row, "LeaderboardStreakLabel" .. tostring(index), "0", UDim2.fromOffset(82, 26), UDim2.new(1, -158, 0, 0), 18, COLORS.text)
		streak.Font = Enum.Font.GothamBlack
		streak.TextXAlignment = Enum.TextXAlignment.Right
		local coins = createLabel(row, "LeaderboardCoinsLabel" .. tostring(index), "0", UDim2.fromOffset(82, 26), UDim2.new(1, -72, 0, 0), 18, COLORS.coin)
		coins.Font = Enum.Font.GothamBlack
		coins.TextXAlignment = Enum.TextXAlignment.Right
	end

	local empty = createLabel(shell, "LeaderboardEmptyLabel", "Play a round to build the leaderboard.", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 504), 17, COLORS.mutedText)
	empty.Font = Enum.Font.GothamBold
	empty.TextXAlignment = Enum.TextXAlignment.Center
	local close = createButton(shell, "CloseLeaderboardButton", "Close", UDim2.fromOffset(156, 44), UDim2.new(1, -156, 1, -44), "Secondary")
	close.AnchorPoint = Vector2.new(0, 1)
	setTreeZIndex(shell, 32)
end

local function isCurrentGui(gui)
	local matchScreen = gui:FindFirstChild("MatchScreen")
	return gui:GetAttribute("UiVersion") == UI_VERSION
		and gui:FindFirstChild("MenuScreen")
		and gui:FindFirstChild("LobbyScreen")
		and matchScreen
		and gui:FindFirstChild("ResultScreen")
		and gui:FindFirstChild("CloseHowToPlayButton", true)
		and gui:FindFirstChild("MenuBackButton", true)
		and matchScreen:FindFirstChild("SecretValidationLabel", true)
		and matchScreen:FindFirstChild("GuessValidationLabel", true)
		and matchScreen:FindFirstChild("SubmitSecretButton", true)
		and matchScreen:FindFirstChild("SubmitGuessButton", true)
		and matchScreen:FindFirstChild("GuessHistoryFrame", true)
		and matchScreen:FindFirstChild("PlayerLockedSlot1", true)
		and matchScreen:FindFirstChild("SecretStateLabel", true)
		and gui:FindFirstChild("CurrencyHud", true)
		and gui:FindFirstChild("BuyCoinsHudButton", true)
		and gui:FindFirstChild("ResultRewardLabel", true)
		and gui:FindFirstChild("ResultYourSecretLabel", true)
		and gui:FindFirstChild("ResultOpponentSecretLabel", true)
		and gui:FindFirstChild("ShopPanel", true)
		and gui:FindFirstChild("CoinPacksPanel", true)
		and gui:FindFirstChild("OpenCoinPacksButton", true)
		and gui:FindFirstChild("CoinPackRow1", true)
		and gui:FindFirstChild("RewardsPanel", true)
		and gui:FindFirstChild("RewardNextClaimLabel", true)
		and gui:FindFirstChild("RewardTitleLabel", true)
		and gui:FindFirstChild("RewardBodyLabel", true)
		and gui:FindFirstChild("RewardWheelBodyLabel", true)
		and gui:FindFirstChild("RewardWheelSegment1", true)
		and gui:FindFirstChild("LeaderboardPanel", true)
		and gui:FindFirstChild("ResultSubtitleLabel", true)
end

function GuiBuilder.getOrCreate(playerGui)
	local existingGui = playerGui:FindFirstChild(SCREEN_GUI_NAME)
	if existingGui then
		if isCurrentGui(existingGui) then
			return existingGui
		end

		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = SCREEN_GUI_NAME
	screenGui:SetAttribute("UiVersion", UI_VERSION)
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = COLORS.background
	background.BorderSizePixel = 0
	background.Visible = false
	background.Parent = screenGui
	addGradient(
		background,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLORS.background),
			ColorSequenceKeypoint.new(1, COLORS.backgroundAlt),
		})
	)

	local haloTop = Instance.new("Frame")
	haloTop.Name = "TopHalo"
	haloTop.AnchorPoint = Vector2.new(0, 0)
	haloTop.Position = UDim2.fromOffset(-120, -80)
	haloTop.Size = UDim2.fromOffset(520, 300)
	haloTop.BackgroundColor3 = COLORS.accent
	haloTop.BackgroundTransparency = 0.84
	haloTop.BorderSizePixel = 0
	haloTop.Parent = background
	addCorner(haloTop, 160)

	local haloBottom = Instance.new("Frame")
	haloBottom.Name = "BottomHalo"
	haloBottom.AnchorPoint = Vector2.new(1, 1)
	haloBottom.Position = UDim2.new(1, 120, 1, 80)
	haloBottom.Size = UDim2.fromOffset(460, 260)
	haloBottom.BackgroundColor3 = COLORS.success
	haloBottom.BackgroundTransparency = 0.9
	haloBottom.BorderSizePixel = 0
	haloBottom.Parent = background
	addCorner(haloBottom, 140)

	createCurrencyHud(screenGui)
	createMenuScreen(screenGui)
	createLobbyScreen(screenGui)
	createMatchScreen(screenGui)
	createResultScreen(screenGui)
	createShopPanel(screenGui)
	createCoinPacksPanel(screenGui)
	createRewardsPanel(screenGui)
	createLeaderboardPanel(screenGui)

	return screenGui
end

return GuiBuilder
