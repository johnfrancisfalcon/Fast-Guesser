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

local function getOrCreateDevGui()
	local existingGui = playerGui:FindFirstChild(SCREEN_GUI_NAME)
	if existingGui then
		local existingFrame = existingGui:FindFirstChild("MainFrame")
		if existingFrame and existingFrame:FindFirstChild("RestartButton") and existingFrame:FindFirstChild("GuessHistoryFrame") then
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
	frame.Size = UDim2.fromOffset(720, 520)
	frame.Position = UDim2.fromOffset(24, 24)
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	createLabel(frame, "TitleLabel", "Fast Guesser", 12, 32)

	-- Match status section.
	createSectionTitle(frame, "Match Status", 12, 52, 320)
	createLabel(frame, "StatusLabel", "Waiting for another player", 78, 36, 12, 320)

	-- Secret section.
	createSectionTitle(frame, "Secret", 12, 124, 320)
	createTextBox(frame, "SecretTextBox", "4-digit secret", 12, 152)
	createButton(frame, "SubmitSecretButton", "Submit Secret", 206, 152)

	-- Guess section.
	createSectionTitle(frame, "Guess", 12, 204, 320)
	createTextBox(frame, "GuessTextBox", "4-digit guess", 12, 232)
	createButton(frame, "SubmitGuessButton", "Submit Guess", 206, 232)

	-- Turn indicator section.
	createSectionTitle(frame, "Turn", 12, 284, 320)
	createLabel(frame, "TurnLabel", "Turn: waiting", 310, 28, 12, 320)

	-- Locked digit sections.
	createSectionTitle(frame, "Locked Digits", 12, 356, 320)
	createLabel(frame, "PlayerLockedLabel", "Your locked: _ _ _ _", 382, 28, 12, 320)
	createLabel(frame, "OpponentLockedLabel", "Opponent locked: _ _ _ _", 414, 28, 12, 320)

	-- Game result and rematch section.
	createSectionTitle(frame, "Result", 12, 458, 180)
	createLabel(frame, "GameOverLabel", "", 484, 28, 12, 180)
	createButton(frame, "RestartButton", "Play Again", 206, 476)

	-- Guess history section.
	createSectionTitle(frame, "Your Guess History", 380, 52, 300)
	local historyFrame = Instance.new("ScrollingFrame")
	historyFrame.Name = "GuessHistoryFrame"
	historyFrame.Size = UDim2.fromOffset(300, 420)
	historyFrame.Position = UDim2.fromOffset(380, 82)
	historyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	historyFrame.BorderSizePixel = 0
	historyFrame.CanvasSize = UDim2.fromOffset(0, 0)
	historyFrame.ScrollBarThickness = 8
	historyFrame.Parent = frame

	local historyList = Instance.new("UIListLayout")
	historyList.Name = "GuessHistoryList"
	historyList.Padding = UDim.new(0, 4)
	historyList.SortOrder = Enum.SortOrder.LayoutOrder
	historyList.Parent = historyFrame

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
local guessHistoryFrame = mainFrame:WaitForChild("GuessHistoryFrame")
local guessHistoryList = guessHistoryFrame:WaitForChild("GuessHistoryList")

local hasSubmittedSecret = false
local isGameOver = false
local isPlayerTurn = false
local bothSecretsSubmitted = false
local secretControlsEnabled = false
local guessControlsEnabled = false
local canRequestRematch = false
local currentRoundId = nil
local guessHistoryCount = 0

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

local function clearGuessHistory()
	for _, child in ipairs(guessHistoryFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	guessHistoryCount = 0
	guessHistoryFrame.CanvasSize = UDim2.fromOffset(0, 0)
end

local function addGuessHistoryEntry(result)
	guessHistoryCount += 1

	local entry = Instance.new("TextLabel")
	entry.Name = "GuessHistoryEntry"
	entry.Size = UDim2.new(1, -12, 0, 54)
	entry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	entry.BorderSizePixel = 0
	entry.Font = Enum.Font.SourceSans
	entry.TextColor3 = Color3.fromRGB(255, 255, 255)
	entry.TextSize = 16
	entry.TextWrapped = true
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.TextYAlignment = Enum.TextYAlignment.Center
	entry.Text = tostring(guessHistoryCount) .. ". Guess: " .. tostring(result.guess)
		.. "\nFeedback: " .. formatLockedPositions(result.matches)
	entry.Parent = guessHistoryFrame
end

guessHistoryList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	guessHistoryFrame.CanvasSize = UDim2.fromOffset(0, guessHistoryList.AbsoluteContentSize.Y + 12)
end)

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
	addGuessHistoryEntry(result)
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
		clearGuessHistory()
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
		clearGuessHistory()
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
