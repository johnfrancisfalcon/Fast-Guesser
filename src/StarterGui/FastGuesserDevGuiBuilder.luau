local GuiBuilder = {}

local SCREEN_GUI_NAME = "FastGuesserDevScreenGui"

local function createLabel(parent, name, text, y, height, x, width)
	local label = Instance.new("TextLabel")
	label.Name = name
	if width then
		label.Size = UDim2.fromOffset(width, height)
	else
		label.Size = UDim2.new(1, -24, 0, height)
	end
	label.Position = UDim2.fromOffset(x or 12, y)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSans
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 20
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	return label
end

local function createTextBox(parent, name, placeholderText, x, y)
	local textBox = Instance.new("TextBox")
	textBox.Name = name
	textBox.Size = UDim2.fromOffset(180, 36)
	textBox.Position = UDim2.fromOffset(x, y)
	textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	textBox.Font = Enum.Font.SourceSans
	textBox.PlaceholderText = placeholderText
	textBox.Text = ""
	textBox.TextColor3 = Color3.fromRGB(20, 20, 20)
	textBox.TextSize = 20
	textBox.ClearTextOnFocus = false
	textBox.Parent = parent

	return textBox
end

local function createButton(parent, name, text, x, y)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(130, 36)
	button.Position = UDim2.fromOffset(x, y)
	button.BackgroundColor3 = Color3.fromRGB(70, 120, 210)
	button.Font = Enum.Font.SourceSansBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Parent = parent

	return button
end

local function createSectionTitle(parent, text, x, y, width)
	local label = createLabel(parent, text .. "SectionLabel", text, y, 22, x, width)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 18
	return label
end

local function createHistoryFrame(parent)
	createSectionTitle(parent, "Your Guess History", 380, 52, 300)

	local historyFrame = Instance.new("ScrollingFrame")
	historyFrame.Name = "GuessHistoryFrame"
	historyFrame.Size = UDim2.fromOffset(300, 420)
	historyFrame.Position = UDim2.fromOffset(380, 82)
	historyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	historyFrame.BorderSizePixel = 0
	historyFrame.CanvasSize = UDim2.fromOffset(0, 0)
	historyFrame.ScrollBarThickness = 8
	historyFrame.Parent = parent

	local historyList = Instance.new("UIListLayout")
	historyList.Name = "GuessHistoryList"
	historyList.Padding = UDim.new(0, 4)
	historyList.SortOrder = Enum.SortOrder.LayoutOrder
	historyList.Parent = historyFrame
end

local function createMainFrame(screenGui)
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.fromOffset(720, 520)
	frame.Position = UDim2.fromOffset(24, 24)
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	createLabel(frame, "TitleLabel", "Fast Guesser", 12, 32)

	createSectionTitle(frame, "Match Status", 12, 52, 320)
	createLabel(frame, "StatusLabel", "Waiting for another player", 78, 36, 12, 320)

	createSectionTitle(frame, "Secret", 12, 124, 320)
	createTextBox(frame, "SecretTextBox", "4-digit secret", 12, 152)
	createButton(frame, "SubmitSecretButton", "Submit Secret", 206, 152)

	createSectionTitle(frame, "Guess", 12, 204, 320)
	createTextBox(frame, "GuessTextBox", "4-digit guess", 12, 232)
	createButton(frame, "SubmitGuessButton", "Submit Guess", 206, 232)

	createSectionTitle(frame, "Turn", 12, 284, 320)
	createLabel(frame, "TurnLabel", "Turn: waiting", 310, 28, 12, 320)

	createSectionTitle(frame, "Locked Digits", 12, 356, 320)
	createLabel(frame, "PlayerLockedLabel", "Your locked: _ _ _ _", 382, 28, 12, 320)
	createLabel(frame, "OpponentLockedLabel", "Opponent locked: _ _ _ _", 414, 28, 12, 320)

	createSectionTitle(frame, "Result", 12, 458, 180)
	createLabel(frame, "GameOverLabel", "", 484, 28, 12, 180)
	createButton(frame, "RestartButton", "Play Again", 206, 476)

	createHistoryFrame(frame)
end

local function isCurrentGui(gui)
	local mainFrame = gui:FindFirstChild("MainFrame")
	return mainFrame
		and mainFrame:FindFirstChild("RestartButton")
		and mainFrame:FindFirstChild("GuessHistoryFrame")
end

function GuiBuilder.getOrCreate(playerGui)
	local existingGui = playerGui:FindFirstChild(SCREEN_GUI_NAME)
	if existingGui then
		if isCurrentGui(existingGui) then
			return existingGui
		end

		existingGui:Destroy()
	end

	-- Temporary developer UI for Studio multiplayer tests.
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = SCREEN_GUI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	createMainFrame(screenGui)

	return screenGui
end

return GuiBuilder
