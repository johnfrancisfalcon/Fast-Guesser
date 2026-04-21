local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = script.Parent
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local SCREEN_GUI_NAME = "FastGuesserDevScreenGui"

print("[FastGuesserClient] started", localPlayer.UserId)

local function createLabel(parent, name, text, y, height)
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

local function getOrCreateDevGui()
	local existingGui = playerGui:FindFirstChild(SCREEN_GUI_NAME)
	if existingGui then
		return existingGui
	end

	-- Temporary developer UI for Studio multiplayer tests.
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = SCREEN_GUI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.fromOffset(360, 390)
	frame.Position = UDim2.fromOffset(24, 24)
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	createLabel(frame, "TitleLabel", "Fast Guesser Dev Test", 12, 32)
	createLabel(frame, "StatusLabel", "Waiting for a match...", 50, 44)

	createTextBox(frame, "SecretTextBox", "4-digit secret", 12, 108)
	createButton(frame, "SubmitSecretButton", "Submit Secret", 206, 108)

	createTextBox(frame, "GuessTextBox", "4-digit guess", 12, 158)
	createButton(frame, "SubmitGuessButton", "Submit Guess", 206, 158)

	createLabel(frame, "PlayerLockedLabel", "Your locked: _ _ _ _", 212, 32)
	createLabel(frame, "OpponentLockedLabel", "Opponent locked: _ _ _ _", 248, 32)
	createLabel(frame, "TurnLabel", "Turn: waiting", 284, 32)
	createLabel(frame, "GameOverLabel", "", 320, 48)

	return screenGui
end

local devGui = getOrCreateDevGui()
local mainFrame = devGui:WaitForChild("MainFrame")

local statusLabel = mainFrame:WaitForChild("StatusLabel")
local secretTextBox = mainFrame:WaitForChild("SecretTextBox")
local submitSecretButton = mainFrame:WaitForChild("SubmitSecretButton")
local guessTextBox = mainFrame:WaitForChild("GuessTextBox")
local submitGuessButton = mainFrame:WaitForChild("SubmitGuessButton")
local playerLockedLabel = mainFrame:WaitForChild("PlayerLockedLabel")
local opponentLockedLabel = mainFrame:WaitForChild("OpponentLockedLabel")
local turnLabel = mainFrame:WaitForChild("TurnLabel")
local gameOverLabel = mainFrame:WaitForChild("GameOverLabel")

local hasSubmittedSecret = false
local isGameOver = false
local isPlayerTurn = false
local secretControlsEnabled = false
local guessControlsEnabled = false

local function isFourDigits(value)
	return string.match(value, "^%d%d%d%d$") ~= nil
end

local function formatLockedPositions(lockedPositions)
	local values = {}

	for i = 1, 4 do
		values[i] = lockedPositions[i] or "_"
	end

	return table.concat(values, " ")
end

local function setSecretControlsEnabled(enabled)
	secretControlsEnabled = enabled
	secretTextBox.TextEditable = enabled
	submitSecretButton.Active = enabled
	submitSecretButton.AutoButtonColor = enabled
end

local function setGuessControlsEnabled(enabled)
	guessControlsEnabled = enabled
	guessTextBox.TextEditable = enabled
	submitGuessButton.Active = enabled
	submitGuessButton.AutoButtonColor = enabled
end

local function refreshGuessControls()
	setGuessControlsEnabled(hasSubmittedSecret and isPlayerTurn and not isGameOver)
end

setSecretControlsEnabled(false)
setGuessControlsEnabled(false)

local function onSecretRequested()
	print("[FastGuesserClient] secret requested")
	statusLabel.Text = "Enter your secret"
	secretTextBox.Text = ""
	setSecretControlsEnabled(true)
end

local function onTurnChanged(playerId)
	print("[FastGuesserClient] turn changed", playerId)
	isPlayerTurn = playerId == localPlayer.UserId
	turnLabel.Text = "Turn: player " .. tostring(playerId)

	if isPlayerTurn then
		statusLabel.Text = "Your turn to guess"
	else
		statusLabel.Text = "Waiting for opponent"
	end

	refreshGuessControls()
end

local function onGuessResult(result)
	print("[FastGuesserClient] guess result")
	statusLabel.Text = "Guess submitted"
	guessTextBox.Text = ""
end

local function onGameOver(winnerId)
	print("[FastGuesserClient] game over", winnerId)
	isGameOver = true
	gameOverLabel.Text = "Winner: " .. tostring(winnerId)
	statusLabel.Text = "Game over"
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
end

local function onRoundStateChanged(roundState)
	print("[FastGuesserClient] round state changed")

	local localPlayerId = localPlayer.UserId
	local opponentId = roundState.playerOneId
	if opponentId == localPlayerId then
		opponentId = roundState.playerTwoId
	end

	local lockedPositionsByPlayerId = roundState.lockedPositionsByPlayerId or {}
	local localLockedPositions = lockedPositionsByPlayerId[tostring(localPlayerId)] or {}
	local opponentLockedPositions = lockedPositionsByPlayerId[tostring(opponentId)] or {}

	playerLockedLabel.Text = "Your locked: " .. formatLockedPositions(localLockedPositions)
	opponentLockedLabel.Text = "Opponent locked: " .. formatLockedPositions(opponentLockedPositions)

	if roundState.currentTurn then
		onTurnChanged(roundState.currentTurn)
	end

	if roundState.winner then
		onGameOver(roundState.winner)
	else
		gameOverLabel.Text = ""
	end
end

submitSecretButton.MouseButton1Click:Connect(function()
	if not secretControlsEnabled then
		print("[FastGuesserClient] secret submit ignored because controls are disabled")
		return
	end

	local secret = secretTextBox.Text
	if not isFourDigits(secret) then
		statusLabel.Text = "Secret must be exactly 4 digits"
		return
	end

	hasSubmittedSecret = true
	setSecretControlsEnabled(false)
	statusLabel.Text = "Secret submitted"
	print("[FastGuesserClient] secret submitted")
	RemoteEvents.SecretSubmitted:FireServer(secret)
	refreshGuessControls()
end)

submitGuessButton.MouseButton1Click:Connect(function()
	if not guessControlsEnabled then
		print("[FastGuesserClient] guess submit ignored because controls are disabled")
		return
	end

	local guess = guessTextBox.Text
	if not isFourDigits(guess) then
		statusLabel.Text = "Guess must be exactly 4 digits"
		return
	end

	statusLabel.Text = "Submitting guess..."
	setGuessControlsEnabled(false)
	print("[FastGuesserClient] guess submitted", guess)
	RemoteEvents.GuessSubmitted:FireServer(guess)
end)

RemoteEvents.SecretRequested.OnClientEvent:Connect(onSecretRequested)
RemoteEvents.TurnChanged.OnClientEvent:Connect(onTurnChanged)
RemoteEvents.GuessResult.OnClientEvent:Connect(onGuessResult)
RemoteEvents.GameOver.OnClientEvent:Connect(onGameOver)
RemoteEvents.RoundStateChanged.OnClientEvent:Connect(onRoundStateChanged)
