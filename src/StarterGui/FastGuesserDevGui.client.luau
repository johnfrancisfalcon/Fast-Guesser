local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = script.Parent
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local SCREEN_GUI_NAME = "FastGuesserDevScreenGui"
local GAME_STATES = {
	WaitingForPlayers = "WaitingForPlayers",
	WaitingForSecrets = "WaitingForSecrets",
	InProgress = "InProgress",
	RoundOver = "RoundOver",
	WaitingForRematch = "WaitingForRematch",
}

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
		local existingFrame = existingGui:FindFirstChild("MainFrame")
		if existingFrame and existingFrame:FindFirstChild("RestartButton") then
			return existingGui
		end

		existingGui:Destroy()
	end

	-- Temporary developer UI for Studio multiplayer tests.
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = SCREEN_GUI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.fromOffset(360, 440)
	frame.Position = UDim2.fromOffset(24, 24)
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	createLabel(frame, "TitleLabel", "Fast Guesser Dev Test", 12, 32)
	createLabel(frame, "StatusLabel", "Waiting for another player", 50, 44)

	createTextBox(frame, "SecretTextBox", "4-digit secret", 12, 108)
	createButton(frame, "SubmitSecretButton", "Submit Secret", 206, 108)

	createTextBox(frame, "GuessTextBox", "4-digit guess", 12, 158)
	createButton(frame, "SubmitGuessButton", "Submit Guess", 206, 158)

	createLabel(frame, "PlayerLockedLabel", "Your locked: _ _ _ _", 212, 32)
	createLabel(frame, "OpponentLockedLabel", "Opponent locked: _ _ _ _", 248, 32)
	createLabel(frame, "TurnLabel", "Turn: waiting", 284, 32)
	createLabel(frame, "GameOverLabel", "", 320, 48)
	createButton(frame, "RestartButton", "Play Again", 206, 382)

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
local restartButton = mainFrame:WaitForChild("RestartButton")

local hasSubmittedSecret = false
local isGameOver = false
local isPlayerTurn = false
local bothSecretsSubmitted = false
local secretControlsEnabled = false
local guessControlsEnabled = false
local canRequestRematch = false
local currentRoundId = nil

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

local function setRestartControlsEnabled(enabled)
	canRequestRematch = enabled
	restartButton.Active = enabled
	restartButton.AutoButtonColor = enabled
end

local function refreshGuessControls()
	setGuessControlsEnabled(bothSecretsSubmitted and isPlayerTurn and not isGameOver)
end

setSecretControlsEnabled(false)
setGuessControlsEnabled(false)
setRestartControlsEnabled(false)

local function onSecretRequested()
	print("[FastGuesserClient] secret requested")
	if hasSubmittedSecret then
		return
	end

	hasSubmittedSecret = false
	isGameOver = false
	isPlayerTurn = false
	bothSecretsSubmitted = false
	statusLabel.Text = "Enter your secret"
	guessTextBox.Text = ""
	gameOverLabel.Text = ""
	playerLockedLabel.Text = "Your locked: _ _ _ _"
	opponentLockedLabel.Text = "Opponent locked: _ _ _ _"
	turnLabel.Text = "Turn: waiting"
	setSecretControlsEnabled(true)
	setGuessControlsEnabled(false)
end

local function onTurnChanged(playerId)
	print("[FastGuesserClient] turn changed", playerId)
	isPlayerTurn = playerId == localPlayer.UserId
	turnLabel.Text = "Turn: player " .. tostring(playerId)

	if isPlayerTurn then
		statusLabel.Text = "Your turn"
	else
		statusLabel.Text = "Opponent's turn"
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
	setRestartControlsEnabled(true)
end

local function onRoundStateChanged(roundState)
	print("[FastGuesserClient] round state changed")

	if roundState.roundId and roundState.roundId ~= currentRoundId then
		currentRoundId = roundState.roundId
		hasSubmittedSecret = false
		isGameOver = false
		isPlayerTurn = false
		bothSecretsSubmitted = false
		secretTextBox.Text = ""
		guessTextBox.Text = ""
	end

	local localPlayerId = localPlayer.UserId
	local opponentId = roundState.playerOneId
	if opponentId == localPlayerId then
		opponentId = roundState.playerTwoId
	end

	local lockedPositionsByPlayerId = roundState.lockedPositionsByPlayerId or {}
	local localLockedPositions = lockedPositionsByPlayerId[tostring(localPlayerId)] or {}
	local opponentLockedPositions = lockedPositionsByPlayerId[tostring(opponentId)] or {}

	isGameOver = roundState.winner ~= nil
	bothSecretsSubmitted = roundState.currentTurn ~= nil
	playerLockedLabel.Text = "Your locked: " .. formatLockedPositions(localLockedPositions)
	opponentLockedLabel.Text = "Opponent locked: " .. formatLockedPositions(opponentLockedPositions)

	if roundState.gameState == GAME_STATES.WaitingForPlayers then
		statusLabel.Text = "Waiting for another player"
		turnLabel.Text = "Turn: waiting"
		gameOverLabel.Text = ""
		hasSubmittedSecret = false
		bothSecretsSubmitted = false
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
		setRestartControlsEnabled(false)
	elseif roundState.gameState == GAME_STATES.WaitingForRematch then
		local rematchReadyByPlayerId = roundState.rematchReadyByPlayerId or {}
		local isReadyForRematch = rematchReadyByPlayerId[tostring(localPlayerId)] == true

		if isReadyForRematch then
			statusLabel.Text = "Waiting for opponent to play again"
		else
			statusLabel.Text = "Opponent wants to play again"
		end

		turnLabel.Text = "Turn: waiting"
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
		setRestartControlsEnabled(not isReadyForRematch)
	elseif roundState.gameState == GAME_STATES.WaitingForSecrets then
		turnLabel.Text = "Turn: waiting"
		gameOverLabel.Text = ""
		bothSecretsSubmitted = false

		if hasSubmittedSecret then
			statusLabel.Text = "Waiting for opponent secret"
			setSecretControlsEnabled(false)
		else
			statusLabel.Text = "Enter your secret"
			setSecretControlsEnabled(true)
		end

		setGuessControlsEnabled(false)
		setRestartControlsEnabled(false)
	elseif roundState.gameState == GAME_STATES.InProgress and roundState.currentTurn then
		onTurnChanged(roundState.currentTurn)
		setSecretControlsEnabled(false)
		setRestartControlsEnabled(false)
	elseif roundState.gameState == GAME_STATES.RoundOver and roundState.winner then
		onGameOver(roundState.winner)
	else
		refreshGuessControls()
	end
end

submitSecretButton.MouseButton1Click:Connect(function()
	if not secretControlsEnabled then
		print("[FastGuesserClient] secret submit ignored because controls are disabled")
		return
	end

	if isGameOver then
		print("[FastGuesserClient] secret submit ignored because game is over")
		return
	end

	local secret = secretTextBox.Text
	if not isFourDigits(secret) then
		statusLabel.Text = "Secret must be exactly 4 digits"
		return
	end

	hasSubmittedSecret = true
	setSecretControlsEnabled(false)
	statusLabel.Text = "Waiting for opponent secret"
	print("[FastGuesserClient] secret submitted")
	RemoteEvents.SecretSubmitted:FireServer(secret)
	refreshGuessControls()
end)

submitGuessButton.MouseButton1Click:Connect(function()
	if not guessControlsEnabled then
		print("[FastGuesserClient] guess submit ignored because controls are disabled")
		return
	end

	if isGameOver then
		print("[FastGuesserClient] guess submit ignored because game is over")
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

restartButton.MouseButton1Click:Connect(function()
	if not canRequestRematch then
		print("[FastGuesserClient] play again ignored because rematch is not available")
		return
	end

	print("[FastGuesserClient] restart requested")
	statusLabel.Text = "Waiting for opponent to play again"
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
	setRestartControlsEnabled(false)
	RemoteEvents.RestartRequested:FireServer()
end)

RemoteEvents.SecretRequested.OnClientEvent:Connect(onSecretRequested)
RemoteEvents.TurnChanged.OnClientEvent:Connect(onTurnChanged)
RemoteEvents.GuessResult.OnClientEvent:Connect(onGuessResult)
RemoteEvents.GameOver.OnClientEvent:Connect(onGameOver)
RemoteEvents.RoundStateChanged.OnClientEvent:Connect(onRoundStateChanged)
