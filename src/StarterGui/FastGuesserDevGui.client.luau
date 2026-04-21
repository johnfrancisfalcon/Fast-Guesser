local guiParent = script.Parent

if guiParent:FindFirstChild("FastGuesserDevGui") then
	return
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FastGuesserDevGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(360, 390)
mainFrame.Position = UDim2.fromOffset(24, 24)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local function createLabel(name, text, y, height)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -24, 0, height)
	label.Position = UDim2.fromOffset(12, y)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSans
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 20
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = mainFrame

	return label
end

local function createTextBox(name, placeholderText, x, y)
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
	textBox.Parent = mainFrame

	return textBox
end

local function createButton(name, text, x, y)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(130, 36)
	button.Position = UDim2.fromOffset(x, y)
	button.BackgroundColor3 = Color3.fromRGB(70, 120, 210)
	button.Font = Enum.Font.SourceSansBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Parent = mainFrame

	return button
end

createLabel("TitleLabel", "Fast Guesser Dev Test", 12, 32)
createLabel("StatusLabel", "Waiting for a match...", 50, 44)

createTextBox("SecretTextBox", "4-digit secret", 12, 108)
createButton("SubmitSecretButton", "Submit Secret", 206, 108)

createTextBox("GuessTextBox", "4-digit guess", 12, 158)
createButton("SubmitGuessButton", "Submit Guess", 206, 158)

createLabel("PlayerLockedLabel", "Your locked: _ _ _ _", 212, 32)
createLabel("OpponentLockedLabel", "Opponent locked: _ _ _ _", 248, 32)
createLabel("TurnLabel", "Turn: waiting", 284, 32)
createLabel("GameOverLabel", "", 320, 48)
