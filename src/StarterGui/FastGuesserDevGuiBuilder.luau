local GuiBuilder = {}

local SCREEN_GUI_NAME = "FastGuesserDevScreenGui"
local UI_VERSION = 2

local COLORS = {
	background = Color3.fromRGB(18, 22, 28),
	surface = Color3.fromRGB(34, 40, 48),
	panel = Color3.fromRGB(44, 52, 62),
	panelAlt = Color3.fromRGB(28, 34, 42),
	border = Color3.fromRGB(72, 84, 98),
	text = Color3.fromRGB(245, 247, 250),
	mutedText = Color3.fromRGB(182, 190, 200),
	input = Color3.fromRGB(248, 250, 252),
	inputText = Color3.fromRGB(22, 28, 36),
	button = Color3.fromRGB(61, 128, 214),
}

local function createLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSans
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

	return panel
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
	label.Font = Enum.Font.SourceSansBold
	return label
end

local function createTextBox(parent, name, placeholderText, x, y)
	local textBox = Instance.new("TextBox")
	textBox.Name = name
	textBox.Size = UDim2.fromOffset(190, 40)
	textBox.Position = UDim2.fromOffset(x, y)
	textBox.BackgroundColor3 = COLORS.input
	textBox.BorderColor3 = COLORS.border
	textBox.Font = Enum.Font.SourceSans
	textBox.PlaceholderText = placeholderText
	textBox.Text = ""
	textBox.TextColor3 = COLORS.inputText
	textBox.TextSize = 22
	textBox.ClearTextOnFocus = false
	textBox.Parent = parent

	return textBox
end

local function createButton(parent, name, text, x, y)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(150, 40)
	button.Position = UDim2.fromOffset(x, y)
	button.BackgroundColor3 = COLORS.button
	button.BorderSizePixel = 0
	button.Font = Enum.Font.SourceSansBold
	button.Text = text
	button.TextColor3 = COLORS.text
	button.TextSize = 18
	button.Parent = parent

	return button
end

local function createStatusPanel(parent)
	local panel = createPanel(parent, "StatusPanel", UDim2.fromOffset(520, 106), UDim2.fromOffset(24, 70))

	createLabel(panel, "StatusEyebrowLabel", "Round Status", UDim2.fromOffset(160, 22), UDim2.fromOffset(18, 12), 16, COLORS.mutedText)

	local statusLabel = createLabel(
		panel,
		"StatusLabel",
		"Waiting for opponent",
		UDim2.fromOffset(360, 34),
		UDim2.fromOffset(18, 36),
		28
	)
	statusLabel.Font = Enum.Font.SourceSansBold

	createLabel(
		panel,
		"TurnLabel",
		"Turn: waiting",
		UDim2.fromOffset(230, 24),
		UDim2.fromOffset(18, 74),
		18,
		COLORS.mutedText
	)

	createLabel(
		panel,
		"GameOverLabel",
		"",
		UDim2.fromOffset(200, 28),
		UDim2.fromOffset(300, 70),
		20
	)
end

local function createSecretPanel(parent)
	local panel = createPanel(parent, "SecretPanel", UDim2.fromOffset(250, 200), UDim2.fromOffset(24, 196))

	createSectionTitle(panel, "Secret", 18, 14, 180)
	createLabel(
		panel,
		"SecretHelpLabel",
		"Choose the 4-digit code your opponent is trying to reveal.",
		UDim2.fromOffset(210, 42),
		UDim2.fromOffset(18, 42),
		16,
		COLORS.mutedText
	)
	createTextBox(panel, "SecretTextBox", "4-digit secret", 18, 92)
	createButton(panel, "SubmitSecretButton", "Submit Secret", 18, 142)
end

local function createGuessPanel(parent)
	local panel = createPanel(parent, "GuessPanel", UDim2.fromOffset(250, 200), UDim2.fromOffset(294, 196))

	createSectionTitle(panel, "Guess", 18, 14, 180)
	createLabel(
		panel,
		"GuessHelpLabel",
		"Submit guesses on your turn. Exact digits lock into place.",
		UDim2.fromOffset(210, 42),
		UDim2.fromOffset(18, 42),
		16,
		COLORS.mutedText
	)
	createTextBox(panel, "GuessTextBox", "4-digit guess", 18, 92)
	createButton(panel, "SubmitGuessButton", "Submit Guess", 18, 142)
end

local function createLockedPanel(parent)
	local panel = createPanel(parent, "LockedPanel", UDim2.fromOffset(520, 134), UDim2.fromOffset(24, 416))

	createSectionTitle(panel, "Locked Digits", 18, 14, 180)
	createLabel(
		panel,
		"PlayerLockedLabel",
		"Your locked: _ _ _ _",
		UDim2.fromOffset(220, 30),
		UDim2.fromOffset(18, 50),
		22
	)
	createLabel(
		panel,
		"OpponentLockedLabel",
		"Opponent locked: _ _ _ _",
		UDim2.fromOffset(250, 30),
		UDim2.fromOffset(250, 50),
		22,
		COLORS.mutedText
	)
	createButton(panel, "RestartButton", "Play Again", 18, 88)
end

local function createHistoryPanel(parent)
	local panel = createPanel(parent, "HistoryPanel", UDim2.fromOffset(310, 450), UDim2.fromOffset(570, 70))

	createSectionTitle(panel, "Guess History", 18, 14, 220)

	local historyFrame = Instance.new("ScrollingFrame")
	historyFrame.Name = "GuessHistoryFrame"
	historyFrame.Size = UDim2.fromOffset(274, 380)
	historyFrame.Position = UDim2.fromOffset(18, 52)
	historyFrame.BackgroundColor3 = COLORS.panelAlt
	historyFrame.BorderColor3 = COLORS.border
	historyFrame.BorderSizePixel = 1
	historyFrame.CanvasSize = UDim2.fromOffset(0, 0)
	historyFrame.ScrollBarThickness = 8
	historyFrame.Parent = panel

	local historyList = Instance.new("UIListLayout")
	historyList.Name = "GuessHistoryList"
	historyList.Padding = UDim.new(0, 6)
	historyList.SortOrder = Enum.SortOrder.LayoutOrder
	historyList.Parent = historyFrame
end

local function createMainFrame(screenGui)
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame:SetAttribute("UiVersion", UI_VERSION)
	frame.Size = UDim2.fromOffset(904, 590)
	frame.Position = UDim2.new(0.5, -452, 0.5, -295)
	frame.BackgroundColor3 = COLORS.surface
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local title = createLabel(frame, "TitleLabel", "Fast Guesser", UDim2.fromOffset(260, 40), UDim2.fromOffset(24, 20), 34)
	title.Font = Enum.Font.SourceSansBold

	createLabel(
		frame,
		"SubtitleLabel",
		"Lock exact digits before your opponent solves yours.",
		UDim2.fromOffset(380, 24),
		UDim2.fromOffset(300, 30),
		18,
		COLORS.mutedText
	)

	createStatusPanel(frame)
	createSecretPanel(frame)
	createGuessPanel(frame)
	createLockedPanel(frame)
	createHistoryPanel(frame)
end

local function isCurrentGui(gui)
	local mainFrame = gui:FindFirstChild("MainFrame")
	return mainFrame
		and mainFrame:GetAttribute("UiVersion") == UI_VERSION
		and mainFrame:FindFirstChild("SubmitSecretButton", true)
		and mainFrame:FindFirstChild("SubmitGuessButton", true)
		and mainFrame:FindFirstChild("RestartButton", true)
		and mainFrame:FindFirstChild("GuessHistoryFrame", true)
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
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = COLORS.background
	background.BorderSizePixel = 0
	background.Parent = screenGui

	createMainFrame(screenGui)

	return screenGui
end

return GuiBuilder
