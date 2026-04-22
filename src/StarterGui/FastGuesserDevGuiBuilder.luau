local GuiBuilder = {}

local SCREEN_GUI_NAME = "FastGuesserDevScreenGui"
local UI_VERSION = 7

local COLORS = {
	background = Color3.fromRGB(18, 22, 28),
	surface = Color3.fromRGB(34, 40, 48),
	panel = Color3.fromRGB(42, 50, 60),
	panelAlt = Color3.fromRGB(28, 34, 42),
	panelStrong = Color3.fromRGB(50, 62, 76),
	border = Color3.fromRGB(80, 94, 112),
	accent = Color3.fromRGB(91, 154, 238),
	success = Color3.fromRGB(83, 190, 132),
	warning = Color3.fromRGB(240, 189, 96),
	text = Color3.fromRGB(245, 247, 250),
	mutedText = Color3.fromRGB(182, 190, 200),
	input = Color3.fromRGB(248, 250, 252),
	inputText = Color3.fromRGB(22, 28, 36),
	button = Color3.fromRGB(61, 128, 214),
	errorText = Color3.fromRGB(255, 176, 176),
}

local function createScreen(name, size)
	local screen = Instance.new("Frame")
	screen.Name = name
	screen.Size = size or UDim2.fromOffset(904, 590)
	screen.Position = UDim2.new(0.5, -452, 0.5, -295)
	screen.BackgroundColor3 = COLORS.surface
	screen.BorderSizePixel = 0
	screen.Visible = false

	return screen
end

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = instance
end

local function addPadding(instance, left, top, right, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingRight = UDim.new(0, right or left or 0)
	padding.PaddingBottom = UDim.new(0, bottom or top or 0)
	padding.Parent = instance
end

local function createAccentBar(parent, name, size, position, color)
	local bar = Instance.new("Frame")
	bar.Name = name
	bar.Size = size
	bar.Position = position
	bar.BackgroundColor3 = color or COLORS.accent
	bar.BorderSizePixel = 0
	bar.Parent = parent
	addCorner(bar, 3)

	return bar
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
	label.TextSize = textSize or 20
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent

	return label
end

local function createPanel(parent, name, size, position)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = position
	panel.BackgroundColor3 = COLORS.panel
	panel.BorderColor3 = COLORS.border
	panel.BorderSizePixel = 1
	panel.Parent = parent
	addCorner(panel, 6)

	return panel
end

local function createButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size or UDim2.fromOffset(170, 44)
	button.Position = position
	button.BackgroundColor3 = COLORS.button
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = COLORS.text
	button.TextSize = 18
	button.Parent = parent
	addCorner(button, 6)

	return button
end

local function createTextBox(parent, name, placeholderText, x, y)
	local textBox = Instance.new("TextBox")
	textBox.Name = name
	textBox.Size = UDim2.fromOffset(190, 40)
	textBox.Position = UDim2.fromOffset(x, y)
	textBox.BackgroundColor3 = COLORS.input
	textBox.BorderColor3 = COLORS.border
	textBox.Font = Enum.Font.Gotham
	textBox.PlaceholderText = placeholderText
	textBox.Text = ""
	textBox.TextColor3 = COLORS.inputText
	textBox.TextSize = 22
	textBox.ClearTextOnFocus = false
	textBox.Parent = parent
	addCorner(textBox, 4)

	return textBox
end

local function createSectionTitle(parent, text, x, y, width)
	local label = createLabel(
		parent,
		text .. "SectionLabel",
		text,
		UDim2.fromOffset(width, 24),
		UDim2.fromOffset(x, y),
		18
	)
	label.Font = Enum.Font.GothamBold
	return label
end

local function createHeader(parent, subtitle)
	createAccentBar(parent, "HeaderAccentBar", UDim2.fromOffset(5, 44), UDim2.fromOffset(24, 20))
	local title = createLabel(parent, "TitleLabel", "Fast Guesser", UDim2.fromOffset(260, 44), UDim2.fromOffset(42, 18), 34)
	title.Font = Enum.Font.GothamBold

	createLabel(
		parent,
		"SubtitleLabel",
		subtitle,
		UDim2.fromOffset(520, 28),
		UDim2.fromOffset(306, 30),
		16,
		COLORS.mutedText
	)
end

local function createMenuScreen(parent)
	local screen = createScreen("MenuScreen")
	screen.Visible = true
	screen.Parent = parent

	createHeader(screen, "Lock exact digits before your opponent solves yours.")

	local panel = createPanel(screen, "MenuPanel", UDim2.fromOffset(430, 310), UDim2.fromOffset(237, 132))
	panel.BackgroundColor3 = COLORS.panelStrong
	createAccentBar(panel, "MenuPanelAccent", UDim2.fromOffset(382, 4), UDim2.fromOffset(24, 24))
	local heading = createLabel(panel, "MenuHeadingLabel", "Ready to guess?", UDim2.fromOffset(330, 40), UDim2.fromOffset(32, 42), 30)
	heading.Font = Enum.Font.GothamBold
	createLabel(
		panel,
		"MenuBodyLabel",
		"Play a two-player prototype round. Set a secret, take turns guessing, and lock exact digits into place.",
		UDim2.fromOffset(360, 76),
		UDim2.fromOffset(32, 88),
		17,
		COLORS.mutedText
	)
	createButton(panel, "PlayButton", "Play", UDim2.fromOffset(366, 48), UDim2.fromOffset(32, 180))
	createButton(panel, "HowToPlayButton", "How To Play", UDim2.fromOffset(366, 44), UDim2.fromOffset(32, 240))

	local howToPlayPanel = createPanel(screen, "HowToPlayPanel", UDim2.fromOffset(560, 178), UDim2.fromOffset(172, 388))
	howToPlayPanel.BackgroundColor3 = COLORS.panelStrong
	howToPlayPanel.Visible = false
	createSectionTitle(howToPlayPanel, "How To Play", 24, 16, 180)
	createLabel(
		howToPlayPanel,
		"HowToPlayTextLabel",
		"Each player chooses a 4-digit secret. On your turn, submit a 4-digit guess. Exact matches lock in. If the first player solves first, the second player gets one final chance to tie.",
		UDim2.fromOffset(510, 78),
		UDim2.fromOffset(24, 50),
		17,
		COLORS.mutedText
	)
	createButton(howToPlayPanel, "CloseHowToPlayButton", "Close", UDim2.fromOffset(130, 38), UDim2.fromOffset(24, 126))
end

local function createLobbyScreen(parent)
	local screen = createScreen("LobbyScreen")
	screen.Parent = parent

	createHeader(screen, "Wait for a second player, then ready up together.")

	local panel = createPanel(screen, "LobbyPanel", UDim2.fromOffset(560, 360), UDim2.fromOffset(172, 120))
	panel.BackgroundColor3 = COLORS.panelStrong
	createAccentBar(panel, "LobbyAccentBar", UDim2.fromOffset(512, 4), UDim2.fromOffset(24, 24))
	local status = createLabel(panel, "LobbyStatusLabel", "Waiting for opponent", UDim2.fromOffset(470, 42), UDim2.fromOffset(32, 44), 30)
	status.Font = Enum.Font.GothamBold

	local rowOne = createPanel(panel, "PlayerOneRow", UDim2.fromOffset(496, 58), UDim2.fromOffset(32, 112))
	rowOne.BackgroundColor3 = COLORS.panelAlt
	local rowTwo = createPanel(panel, "PlayerTwoRow", UDim2.fromOffset(496, 58), UDim2.fromOffset(32, 184))
	rowTwo.BackgroundColor3 = COLORS.panelAlt
	createLabel(rowOne, "PlayerOneSlotLabel", "Player 1: Waiting", UDim2.fromOffset(300, 30), UDim2.fromOffset(18, 14), 21)
	local readyOne = createLabel(rowOne, "PlayerOneReadyLabel", "Not ready", UDim2.fromOffset(130, 30), UDim2.fromOffset(348, 14), 18, COLORS.mutedText)
	readyOne.TextXAlignment = Enum.TextXAlignment.Right
	createLabel(rowTwo, "PlayerTwoSlotLabel", "Player 2: Waiting", UDim2.fromOffset(300, 30), UDim2.fromOffset(18, 14), 21)
	local readyTwo = createLabel(rowTwo, "PlayerTwoReadyLabel", "Not ready", UDim2.fromOffset(130, 30), UDim2.fromOffset(348, 14), 18, COLORS.mutedText)
	readyTwo.TextXAlignment = Enum.TextXAlignment.Right

	createButton(panel, "ReadyButton", "Ready", UDim2.fromOffset(230, 46), UDim2.fromOffset(32, 282))
	createButton(panel, "LobbyBackButton", "Back to Lobby", UDim2.fromOffset(230, 46), UDim2.fromOffset(298, 282))
end

local function createStatusPanel(parent)
	local panel = createPanel(parent, "StatusPanel", UDim2.fromOffset(520, 124), UDim2.fromOffset(24, 70))
	panel.BackgroundColor3 = COLORS.panelStrong
	panel.BorderColor3 = Color3.fromRGB(96, 118, 142)
	createAccentBar(panel, "StatusAccentBar", UDim2.fromOffset(5, 88), UDim2.fromOffset(18, 18))

	createLabel(panel, "StatusEyebrowLabel", "Round Status", UDim2.fromOffset(160, 22), UDim2.fromOffset(36, 14), 15, COLORS.mutedText)
	local statusLabel = createLabel(panel, "StatusLabel", "Waiting for opponent", UDim2.fromOffset(390, 42), UDim2.fromOffset(36, 38), 30)
	statusLabel.Font = Enum.Font.GothamBold
	createLabel(panel, "TurnLabel", "Turn: waiting", UDim2.fromOffset(230, 24), UDim2.fromOffset(36, 86), 17, COLORS.mutedText)
	local gameOverLabel = createLabel(panel, "GameOverLabel", "", UDim2.fromOffset(210, 30), UDim2.fromOffset(292, 82), 22, COLORS.warning)
	gameOverLabel.Font = Enum.Font.GothamBold
end

local function createSecretPanel(parent)
	local panel = createPanel(parent, "SecretPanel", UDim2.fromOffset(250, 220), UDim2.fromOffset(24, 214))

	createSectionTitle(panel, "Secret", 18, 14, 180)
	createLabel(panel, "SecretHelpLabel", "Choose the 4-digit code your opponent is trying to reveal.", UDim2.fromOffset(210, 42), UDim2.fromOffset(18, 44), 15, COLORS.mutedText)
	createTextBox(panel, "SecretTextBox", "4-digit secret", 18, 94)
	createButton(panel, "SubmitSecretButton", "Submit Secret", UDim2.fromOffset(190, 40), UDim2.fromOffset(18, 146))
	createLabel(panel, "SecretValidationLabel", "", UDim2.fromOffset(210, 26), UDim2.fromOffset(18, 188), 15, COLORS.errorText)
end

local function createGuessPanel(parent)
	local panel = createPanel(parent, "GuessPanel", UDim2.fromOffset(250, 220), UDim2.fromOffset(294, 214))
	panel.BorderColor3 = COLORS.accent

	createSectionTitle(panel, "Guess", 18, 14, 180)
	createLabel(panel, "GuessHelpLabel", "Submit guesses on your turn. Exact digits lock into place.", UDim2.fromOffset(210, 42), UDim2.fromOffset(18, 44), 15, COLORS.mutedText)
	createTextBox(panel, "GuessTextBox", "4-digit guess", 18, 94)
	createButton(panel, "SubmitGuessButton", "Submit Guess", UDim2.fromOffset(190, 40), UDim2.fromOffset(18, 146))
	createLabel(panel, "GuessValidationLabel", "", UDim2.fromOffset(210, 26), UDim2.fromOffset(18, 188), 15, COLORS.errorText)
end

local function createLockedPanel(parent)
	local panel = createPanel(parent, "LockedPanel", UDim2.fromOffset(520, 132), UDim2.fromOffset(24, 450))

	createSectionTitle(panel, "Locked Digits", 18, 14, 180)
	local yourLabel = createLabel(panel, "PlayerLockedLabel", "Your locked: _ _ _ _", UDim2.fromOffset(230, 32), UDim2.fromOffset(18, 48), 22, COLORS.success)
	yourLabel.Font = Enum.Font.GothamBold
	local opponentLabel = createLabel(panel, "OpponentLockedLabel", "Opponent locked: _ _ _ _", UDim2.fromOffset(260, 32), UDim2.fromOffset(242, 48), 22, COLORS.mutedText)
	opponentLabel.Font = Enum.Font.GothamBold
	createButton(panel, "RestartButton", "Play Again", UDim2.fromOffset(150, 38), UDim2.fromOffset(18, 86))
end

local function createHistoryPanel(parent)
	local panel = createPanel(parent, "HistoryPanel", UDim2.fromOffset(310, 512), UDim2.fromOffset(570, 70))

	createSectionTitle(panel, "Guess History", 18, 14, 220)
	createLabel(panel, "HistoryHintLabel", "Newest feedback appears as you guess.", UDim2.fromOffset(260, 22), UDim2.fromOffset(18, 38), 14, COLORS.mutedText)

	local historyFrame = Instance.new("ScrollingFrame")
	historyFrame.Name = "GuessHistoryFrame"
	historyFrame.Size = UDim2.fromOffset(274, 414)
	historyFrame.Position = UDim2.fromOffset(18, 78)
	historyFrame.BackgroundColor3 = COLORS.panelAlt
	historyFrame.BorderColor3 = COLORS.border
	historyFrame.BorderSizePixel = 1
	historyFrame.CanvasSize = UDim2.fromOffset(0, 0)
	historyFrame.ScrollBarThickness = 8
	historyFrame.Parent = panel
	addCorner(historyFrame, 4)
	addPadding(historyFrame, 6, 6, 6, 6)

	local historyList = Instance.new("UIListLayout")
	historyList.Name = "GuessHistoryList"
	historyList.Padding = UDim.new(0, 8)
	historyList.SortOrder = Enum.SortOrder.LayoutOrder
	historyList.Parent = historyFrame
end

local function createMatchScreen(parent)
	local screen = createScreen("MatchScreen")
	screen.Parent = parent

	createHeader(screen, "Lock exact digits before your opponent solves yours.")
	createStatusPanel(screen)
	createSecretPanel(screen)
	createGuessPanel(screen)
	createLockedPanel(screen)
	createHistoryPanel(screen)
end

local function createResultScreen(parent)
	local screen = createScreen("ResultScreen")
	screen.Parent = parent

	createHeader(screen, "Round complete.")

	local panel = createPanel(screen, "ResultPanel", UDim2.fromOffset(460, 300), UDim2.fromOffset(222, 145))
	panel.BackgroundColor3 = COLORS.panelStrong
	panel.BorderColor3 = Color3.fromRGB(96, 118, 142)
	createAccentBar(panel, "ResultAccentBar", UDim2.fromOffset(412, 4), UDim2.fromOffset(24, 24), COLORS.warning)
	local title = createLabel(panel, "ResultTitleLabel", "Game over", UDim2.fromOffset(340, 38), UDim2.fromOffset(32, 46), 30)
	title.Font = Enum.Font.GothamBold
	local winner = createLabel(panel, "ResultWinnerLabel", "Winner: -", UDim2.fromOffset(380, 44), UDim2.fromOffset(32, 100), 28)
	winner.Font = Enum.Font.GothamBold
	createLabel(panel, "ResultStatusLabel", "", UDim2.fromOffset(380, 42), UDim2.fromOffset(32, 150), 18, COLORS.mutedText)
	createButton(panel, "ResultPlayAgainButton", "Play Again", UDim2.fromOffset(185, 46), UDim2.fromOffset(32, 220))
	createButton(panel, "BackToMenuButton", "Back to Lobby", UDim2.fromOffset(185, 46), UDim2.fromOffset(242, 220))
end

local function isCurrentGui(gui)
	local matchScreen = gui:FindFirstChild("MatchScreen")
	return gui:GetAttribute("UiVersion") == UI_VERSION
		and gui:FindFirstChild("MenuScreen")
		and gui:FindFirstChild("LobbyScreen")
		and matchScreen
		and gui:FindFirstChild("ResultScreen")
		and gui:FindFirstChild("CloseHowToPlayButton", true)
		and matchScreen:FindFirstChild("SecretValidationLabel", true)
		and matchScreen:FindFirstChild("GuessValidationLabel", true)
		and matchScreen:FindFirstChild("SubmitSecretButton", true)
		and matchScreen:FindFirstChild("SubmitGuessButton", true)
		and matchScreen:FindFirstChild("GuessHistoryFrame", true)
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
	background.Parent = screenGui

	createMenuScreen(screenGui)
	createLobbyScreen(screenGui)
	createMatchScreen(screenGui)
	createResultScreen(screenGui)

	return screenGui
end

return GuiBuilder
