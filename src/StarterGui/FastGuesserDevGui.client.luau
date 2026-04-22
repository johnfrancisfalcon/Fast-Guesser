local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = script.Parent
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local GuiBuilder = require(script.Parent:WaitForChild("FastGuesserDevGuiBuilder"))

local GAME_STATES = {
	WaitingForPlayers = "WaitingForPlayers",
	WaitingForSecrets = "WaitingForSecrets",
	InProgress = "InProgress",
	RoundOver = "RoundOver",
	WaitingForRematch = "WaitingForRematch",
}

local devGui = GuiBuilder.getOrCreate(playerGui)
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

local function setButtonEnabled(button, enabled)
	button.Active = enabled
	button.AutoButtonColor = enabled
end

local function setSecretControlsEnabled(enabled)
	secretControlsEnabled = enabled
	secretTextBox.TextEditable = enabled
	setButtonEnabled(submitSecretButton, enabled)
end

local function setGuessControlsEnabled(enabled)
	guessControlsEnabled = enabled
	guessTextBox.TextEditable = enabled
	setButtonEnabled(submitGuessButton, enabled)
end

local function setRestartControlsEnabled(enabled)
	canRequestRematch = enabled
	setButtonEnabled(restartButton, enabled)
end

local function refreshGuessControls()
	setGuessControlsEnabled(bothSecretsSubmitted and isPlayerTurn and not isGameOver)
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

local function resetRoundUi()
	hasSubmittedSecret = false
	isGameOver = false
	isPlayerTurn = false
	bothSecretsSubmitted = false
	secretTextBox.Text = ""
	guessTextBox.Text = ""
	gameOverLabel.Text = ""
	playerLockedLabel.Text = "Your locked: _ _ _ _"
	opponentLockedLabel.Text = "Opponent locked: _ _ _ _"
	turnLabel.Text = "Turn: waiting"
	clearGuessHistory()
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
	setRestartControlsEnabled(false)
end

local function getOpponentId(roundState)
	local localPlayerId = localPlayer.UserId
	if roundState.playerOneId == localPlayerId then
		return roundState.playerTwoId
	end

	return roundState.playerOneId
end

local function updateLockedLabels(roundState)
	local localPlayerId = localPlayer.UserId
	local opponentId = getOpponentId(roundState)
	local lockedPositionsByPlayerId = roundState.lockedPositionsByPlayerId or {}

	playerLockedLabel.Text = "Your locked: "
		.. formatLockedPositions(lockedPositionsByPlayerId[tostring(localPlayerId)] or {})
	opponentLockedLabel.Text = "Opponent locked: "
		.. formatLockedPositions(lockedPositionsByPlayerId[tostring(opponentId)] or {})
end

local function showWaitingForPlayers()
	resetRoundUi()
	statusLabel.Text = "Waiting for opponent"
end

local function showWaitingForRematch(roundState)
	local rematchReadyByPlayerId = roundState.rematchReadyByPlayerId or {}
	local isReadyForRematch = rematchReadyByPlayerId[tostring(localPlayer.UserId)] == true

	if isReadyForRematch then
		statusLabel.Text = "Waiting for opponent to play again"
	else
		statusLabel.Text = "Opponent wants to play again"
	end

	turnLabel.Text = "Turn: waiting"
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
	setRestartControlsEnabled(not isReadyForRematch)
end

local function showWaitingForSecrets()
	turnLabel.Text = "Turn: waiting"
	gameOverLabel.Text = ""
	bothSecretsSubmitted = false

	if hasSubmittedSecret then
		statusLabel.Text = "Opponent is entering secret"
		setSecretControlsEnabled(false)
	else
		statusLabel.Text = "Enter your secret"
		setSecretControlsEnabled(true)
	end

	setGuessControlsEnabled(false)
	setRestartControlsEnabled(false)
end

local function showGameOver(winnerId)
	isGameOver = true
	gameOverLabel.Text = "Winner: " .. tostring(winnerId)
	statusLabel.Text = "Game over"
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
	setRestartControlsEnabled(true)
end

local function onSecretRequested()
	if hasSubmittedSecret then
		return
	end

	-- Secret requests can repeat while the server waits; never clear secret text here.
	statusLabel.Text = "Enter your secret"
	setSecretControlsEnabled(true)
	setGuessControlsEnabled(false)
end

local function onTurnChanged(playerId)
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
	statusLabel.Text = "Guess submitted"
	guessTextBox.Text = ""
	addGuessHistoryEntry(result)
end

local function onRoundStateChanged(roundState)
	if roundState.roundId and roundState.roundId ~= currentRoundId then
		currentRoundId = roundState.roundId
		resetRoundUi()
	end

	isGameOver = roundState.winner ~= nil
	bothSecretsSubmitted = roundState.currentTurn ~= nil
	updateLockedLabels(roundState)

	if roundState.gameState == GAME_STATES.WaitingForPlayers then
		showWaitingForPlayers()
	elseif roundState.gameState == GAME_STATES.WaitingForRematch then
		showWaitingForRematch(roundState)
	elseif roundState.gameState == GAME_STATES.WaitingForSecrets then
		showWaitingForSecrets()
	elseif roundState.gameState == GAME_STATES.InProgress and roundState.currentTurn then
		onTurnChanged(roundState.currentTurn)
		setSecretControlsEnabled(false)
		setRestartControlsEnabled(false)
	elseif roundState.gameState == GAME_STATES.RoundOver and roundState.winner then
		showGameOver(roundState.winner)
	else
		refreshGuessControls()
	end
end

local function submitSecret()
	if not secretControlsEnabled or isGameOver then
		return
	end

	local secret = secretTextBox.Text
	if not isFourDigits(secret) then
		statusLabel.Text = "Secret must be exactly 4 digits"
		return
	end

	hasSubmittedSecret = true
	setSecretControlsEnabled(false)
	statusLabel.Text = "Opponent is entering secret"
	RemoteEvents.SecretSubmitted:FireServer(secret)
	refreshGuessControls()
end

local function submitGuess()
	if not guessControlsEnabled or isGameOver then
		return
	end

	local guess = guessTextBox.Text
	if not isFourDigits(guess) then
		statusLabel.Text = "Guess must be exactly 4 digits"
		return
	end

	statusLabel.Text = "Submitting guess..."
	setGuessControlsEnabled(false)
	RemoteEvents.GuessSubmitted:FireServer(guess)
end

local function requestRestart()
	if not canRequestRematch then
		return
	end

	statusLabel.Text = "Waiting for opponent to play again"
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
	setRestartControlsEnabled(false)
	RemoteEvents.RestartRequested:FireServer()
end

guessHistoryList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	guessHistoryFrame.CanvasSize = UDim2.fromOffset(0, guessHistoryList.AbsoluteContentSize.Y + 12)
end)

setSecretControlsEnabled(false)
setGuessControlsEnabled(false)
setRestartControlsEnabled(false)

submitSecretButton.MouseButton1Click:Connect(submitSecret)
submitGuessButton.MouseButton1Click:Connect(submitGuess)
restartButton.MouseButton1Click:Connect(requestRestart)

RemoteEvents.SecretRequested.OnClientEvent:Connect(onSecretRequested)
RemoteEvents.TurnChanged.OnClientEvent:Connect(onTurnChanged)
RemoteEvents.GuessResult.OnClientEvent:Connect(onGuessResult)
RemoteEvents.GameOver.OnClientEvent:Connect(showGameOver)
RemoteEvents.RoundStateChanged.OnClientEvent:Connect(onRoundStateChanged)
