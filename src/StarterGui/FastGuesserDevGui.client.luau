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

local LOBBY_STATES = {
	InLobby = "InLobby",
	Matchmaking = "Matchmaking",
	InRound = "InRound",
	PostRound = "PostRound",
}

local TIE_WINNER = "Tie"

local UI_STATES = {
	-- No modal UI; the player is standing in the 3D lobby and can use the Play Match prompt.
	LobbyWorld = "lobby_world",
	Menu = "menu",
	ReadyUp = "ready_up",
	EnteringSecret = "entering_secret",
	WaitingForOpponentSecret = "waiting_for_opponent_secret",
	InTurn = "in_turn",
	OpponentTurn = "opponent_turn",
	GameOver = "game_over",
}

local SCREEN_STATES = {
	Menu = "Menu",
	Lobby = "Lobby",
	Match = "Match",
	Result = "Result",
}

local COLORS = {
	enabledButton = Color3.fromRGB(61, 128, 214),
	disabledButton = Color3.fromRGB(78, 86, 96),
	enabledInput = Color3.fromRGB(248, 250, 252),
	disabledInput = Color3.fromRGB(198, 204, 212),
	enabledText = Color3.fromRGB(255, 255, 255),
	disabledText = Color3.fromRGB(182, 190, 200),
	errorText = Color3.fromRGB(255, 176, 176),
	successText = Color3.fromRGB(83, 190, 132),
	historyEntry = Color3.fromRGB(36, 44, 54),
	historyEntryBorder = Color3.fromRGB(72, 86, 104),
}

local devGui = GuiBuilder.getOrCreate(playerGui)
local background = devGui:WaitForChild("Background")
local menuScreen = devGui:WaitForChild("MenuScreen")
local lobbyScreen = devGui:WaitForChild("LobbyScreen")
local matchScreen = devGui:WaitForChild("MatchScreen")
local resultScreen = devGui:WaitForChild("ResultScreen")

local function findUi(parent, name)
	local instance = parent:FindFirstChild(name, true)
	assert(instance, "Missing Fast Guesser UI element: " .. name)
	return instance
end

local playButton = findUi(menuScreen, "PlayButton")
local howToPlayButton = findUi(menuScreen, "HowToPlayButton")
local howToPlayPanel = findUi(menuScreen, "HowToPlayPanel")
local closeHowToPlayButton = findUi(menuScreen, "CloseHowToPlayButton")

local lobbyStatusLabel = findUi(lobbyScreen, "LobbyStatusLabel")
local playerOneSlotLabel = findUi(lobbyScreen, "PlayerOneSlotLabel")
local playerOneReadyLabel = findUi(lobbyScreen, "PlayerOneReadyLabel")
local playerTwoSlotLabel = findUi(lobbyScreen, "PlayerTwoSlotLabel")
local playerTwoReadyLabel = findUi(lobbyScreen, "PlayerTwoReadyLabel")
local readyButton = findUi(lobbyScreen, "ReadyButton")
local lobbyBackButton = findUi(lobbyScreen, "LobbyBackButton")

local statusLabel = findUi(matchScreen, "StatusLabel")
local secretTextBox = findUi(matchScreen, "SecretTextBox")
local submitSecretButton = findUi(matchScreen, "SubmitSecretButton")
local secretValidationLabel = findUi(matchScreen, "SecretValidationLabel")
local guessTextBox = findUi(matchScreen, "GuessTextBox")
local submitGuessButton = findUi(matchScreen, "SubmitGuessButton")
local guessValidationLabel = findUi(matchScreen, "GuessValidationLabel")
local playerLockedLabel = findUi(matchScreen, "PlayerLockedLabel")
local opponentLockedLabel = findUi(matchScreen, "OpponentLockedLabel")
local turnLabel = findUi(matchScreen, "TurnLabel")
local gameOverLabel = findUi(matchScreen, "GameOverLabel")
local restartButton = findUi(matchScreen, "RestartButton")
local guessHistoryFrame = findUi(matchScreen, "GuessHistoryFrame")
local guessHistoryList = guessHistoryFrame:WaitForChild("GuessHistoryList")

local resultWinnerLabel = findUi(resultScreen, "ResultWinnerLabel")
local resultStatusLabel = findUi(resultScreen, "ResultStatusLabel")
local resultPlayAgainButton = findUi(resultScreen, "ResultPlayAgainButton")
local backToMenuButton = findUi(resultScreen, "BackToMenuButton")

local currentUiState = UI_STATES.LobbyWorld
local latestLobbyFlowState = LOBBY_STATES.InLobby
local latestLobbyState = nil
local latestRoundState = nil
local hasSubmittedSecret = false
local isGameOver = false
local secretControlsEnabled = false
local guessControlsEnabled = false
local readyControlsEnabled = false
local canRequestRematch = false
local currentRoundId = nil
local lastGameState = nil
local guessHistoryCount = 0

local function isFourDigits(value)
	return string.match(value, "^%d%d%d%d$") ~= nil
end

local function clampToFourDigits(value)
	local digitsOnly = string.gsub(value, "%D", "")
	return string.sub(digitsOnly, 1, 4)
end

local function bindFourDigitInput(textBox)
	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		local clampedText = clampToFourDigits(textBox.Text)
		if textBox.Text ~= clampedText then
			textBox.Text = clampedText
		end
	end)
end

local function setValidationMessage(label, message)
	label.Text = message or ""
	label.TextColor3 = COLORS.errorText
end

local function clearValidationMessages()
	setValidationMessage(secretValidationLabel, "")
	setValidationMessage(guessValidationLabel, "")
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
	button.BackgroundColor3 = if enabled then COLORS.enabledButton else COLORS.disabledButton
	button.TextColor3 = if enabled then COLORS.enabledText else COLORS.disabledText
	button.BackgroundTransparency = if enabled then 0 else 0.18
	button.TextTransparency = if enabled then 0 else 0.12
end

local function setSecretControlsEnabled(enabled)
	secretControlsEnabled = enabled
	secretTextBox.TextEditable = enabled
	secretTextBox.BackgroundColor3 = if enabled then COLORS.enabledInput else COLORS.disabledInput
	secretTextBox.BorderColor3 = if enabled then COLORS.enabledButton else COLORS.disabledButton
	secretTextBox.TextTransparency = if enabled then 0 else 0.28
	setButtonEnabled(submitSecretButton, enabled)
end

local function setGuessControlsEnabled(enabled)
	guessControlsEnabled = enabled
	guessTextBox.TextEditable = enabled
	guessTextBox.BackgroundColor3 = if enabled then COLORS.enabledInput else COLORS.disabledInput
	guessTextBox.BorderColor3 = if enabled then COLORS.enabledButton else COLORS.disabledButton
	guessTextBox.TextTransparency = if enabled then 0 else 0.28
	setButtonEnabled(submitGuessButton, enabled)
end

local function setRestartControlsEnabled(enabled)
	canRequestRematch = enabled
	setButtonEnabled(restartButton, enabled)
	setButtonEnabled(resultPlayAgainButton, enabled)
end

local function isMatchUiState(uiState)
	return uiState == UI_STATES.EnteringSecret
		or uiState == UI_STATES.WaitingForOpponentSecret
		or uiState == UI_STATES.InTurn
		or uiState == UI_STATES.OpponentTurn
end

local function refreshGuessControls()
	local roundState = latestRoundState
	local canGuess = roundState
		and currentUiState == UI_STATES.InTurn
		and roundState.gameState == GAME_STATES.InProgress
		and roundState.currentTurn == localPlayer.UserId
		and roundState.winner == nil

	setGuessControlsEnabled(canGuess == true)
end

local function getPlayerReady(roundState, playerId)
	if not playerId then
		return false
	end

	local lobbyReadyByPlayerId = roundState.lobbyReadyByPlayerId or {}
	return lobbyReadyByPlayerId[tostring(playerId)] == true
end

local function getRematchReady(roundState, playerId)
	if not playerId then
		return false
	end

	local rematchReadyByPlayerId = roundState.rematchReadyByPlayerId or {}
	return rematchReadyByPlayerId[tostring(playerId)] == true
end

local function hasSubmittedSecretOnServer(roundState, playerId)
	if not roundState or not playerId then
		return false
	end

	local secretSubmittedByPlayerId = roundState.secretSubmittedByPlayerId or {}
	return secretSubmittedByPlayerId[tostring(playerId)] == true
end

local function hasLocalSecretSubmitted(roundState)
	return hasSubmittedSecret or hasSubmittedSecretOnServer(roundState, localPlayer.UserId)
end

local function canSubmitSecret(roundState)
	return roundState
		and currentUiState == UI_STATES.EnteringSecret
		and roundState.gameState == GAME_STATES.WaitingForSecrets
		and roundState.winner == nil
		and not hasLocalSecretSubmitted(roundState)
end

local function getOpponentId(roundState)
	local localPlayerId = localPlayer.UserId
	if roundState.playerOneId == localPlayerId then
		return roundState.playerTwoId
	end

	return roundState.playerOneId
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
	entry.LayoutOrder = guessHistoryCount
	entry.Size = UDim2.new(1, -12, 0, 62)
	entry.BackgroundColor3 = COLORS.historyEntry
	entry.BorderColor3 = COLORS.historyEntryBorder
	entry.BorderSizePixel = 1
	entry.Font = Enum.Font.Gotham
	entry.TextColor3 = Color3.fromRGB(255, 255, 255)
	entry.TextSize = 15
	entry.TextWrapped = true
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.TextYAlignment = Enum.TextYAlignment.Center
	entry.Text = tostring(guessHistoryCount) .. ". Guess: " .. tostring(result.guess)
		.. "\nFeedback: " .. formatLockedPositions(result.matches)
	entry.Parent = guessHistoryFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = entry

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = entry
end

local function resetRoundUi()
	hasSubmittedSecret = false
	isGameOver = false
	secretTextBox.Text = ""
	guessTextBox.Text = ""
	gameOverLabel.Text = ""
	clearValidationMessages()
	playerLockedLabel.Text = "Your locked: _ _ _ _"
	opponentLockedLabel.Text = "Opponent locked: _ _ _ _"
	turnLabel.Text = "Turn: waiting"
	clearGuessHistory()
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
	setRestartControlsEnabled(false)
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

local function setScreen(screenState)
	background.Visible = screenState ~= nil
	menuScreen.Visible = screenState == SCREEN_STATES.Menu
	lobbyScreen.Visible = screenState == SCREEN_STATES.Lobby
	matchScreen.Visible = screenState == SCREEN_STATES.Match
	resultScreen.Visible = screenState == SCREEN_STATES.Result

	if screenState ~= SCREEN_STATES.Match then
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
		clearValidationMessages()
	end
end

local function formatPlayerSlot(slotNumber, playerId)
	if not playerId then
		return "Player " .. tostring(slotNumber) .. ": Waiting"
	end

	if playerId == localPlayer.UserId then
		return "Player " .. tostring(slotNumber) .. ": You"
	end

	return "Player " .. tostring(slotNumber) .. ": Opponent"
end

local function updateReadyLabel(label, ready)
	label.Text = if ready then "Ready" else "Not ready"
	label.TextColor3 = if ready then COLORS.successText else COLORS.disabledText
	label.Font = if ready then Enum.Font.GothamBold else Enum.Font.Gotham
end

local function isLocalPlayerInLobby(lobbyState)
	return lobbyState
		and (lobbyState.playerOneId == localPlayer.UserId or lobbyState.playerTwoId == localPlayer.UserId)
end

local function isLocalPlayerInServerMenu(lobbyState)
	local menuByPlayerId = lobbyState and lobbyState.menuByPlayerId or {}
	return menuByPlayerId[tostring(localPlayer.UserId)] == true
end

local function getSessionNotice(state)
	return state and state.sessionNotice or nil
end

local function updateLobby(lobbyState)
	if not lobbyState then
		lobbyStatusLabel.Text = "Waiting for opponent"
		playerOneSlotLabel.Text = "Player 1: Waiting"
		playerTwoSlotLabel.Text = "Player 2: Waiting"
		updateReadyLabel(playerOneReadyLabel, false)
		updateReadyLabel(playerTwoReadyLabel, false)
		readyControlsEnabled = true
		setButtonEnabled(readyButton, true)
		return
	end

	local playerOneReady = getPlayerReady(lobbyState, lobbyState.playerOneId)
	local playerTwoReady = getPlayerReady(lobbyState, lobbyState.playerTwoId)
	local localReady = getPlayerReady(lobbyState, localPlayer.UserId)
	local isInLobby = lobbyState.playerOneId == localPlayer.UserId or lobbyState.playerTwoId == localPlayer.UserId
	local hasBothPlayers = lobbyState.playerOneId ~= nil and lobbyState.playerTwoId ~= nil
	local canToggleReady = lobbyState.gameState == GAME_STATES.WaitingForPlayers and isInLobby

	playerOneSlotLabel.Text = formatPlayerSlot(1, lobbyState.playerOneId)
	playerTwoSlotLabel.Text = formatPlayerSlot(2, lobbyState.playerTwoId)
	updateReadyLabel(playerOneReadyLabel, playerOneReady)
	updateReadyLabel(playerTwoReadyLabel, playerTwoReady)

	local sessionNotice = getSessionNotice(lobbyState)
	if sessionNotice then
		lobbyStatusLabel.Text = sessionNotice
	elseif not hasBothPlayers then
		lobbyStatusLabel.Text = "Waiting for opponent"
	elseif localReady and not (playerOneReady and playerTwoReady) then
		lobbyStatusLabel.Text = "Waiting for opponent to ready"
	else
		lobbyStatusLabel.Text = "Ready up"
	end

	readyControlsEnabled = canToggleReady
	setButtonEnabled(readyButton, canToggleReady)
	readyButton.Text = if localReady then "Unready" else "Ready"
end

local function updateResult(roundState)
	if not roundState then
		resultWinnerLabel.Text = "Winner: -"
		resultStatusLabel.Text = ""
		setRestartControlsEnabled(false)
		return
	end

	local winnerId = roundState.winner
	if roundState.isTie or winnerId == TIE_WINNER then
		resultWinnerLabel.Text = "Result: Tie"
	elseif winnerId == localPlayer.UserId then
		resultWinnerLabel.Text = "Winner: You"
	elseif winnerId then
		resultWinnerLabel.Text = "Winner: Opponent"
	else
		resultWinnerLabel.Text = "Winner: -"
	end

	local localReadyForRematch = getRematchReady(roundState, localPlayer.UserId)
	local sessionNotice = getSessionNotice(roundState)
	if sessionNotice then
		resultStatusLabel.Text = sessionNotice
		setRestartControlsEnabled(false)
	elseif roundState.gameState == GAME_STATES.WaitingForRematch and localReadyForRematch then
		resultStatusLabel.Text = "Waiting for opponent to play again"
		setRestartControlsEnabled(false)
	elseif roundState.gameState == GAME_STATES.WaitingForRematch then
		resultStatusLabel.Text = "Opponent wants to play again"
		setRestartControlsEnabled(true)
	else
		resultStatusLabel.Text = "Game over"
		setRestartControlsEnabled(winnerId ~= nil)
	end
end

local function getScreenStateForUiState(uiState)
	if uiState == UI_STATES.LobbyWorld then
		return nil
	end

	if uiState == UI_STATES.Menu then
		return SCREEN_STATES.Menu
	elseif uiState == UI_STATES.ReadyUp then
		return SCREEN_STATES.Lobby
	elseif uiState == UI_STATES.GameOver then
		return SCREEN_STATES.Result
	end

	return SCREEN_STATES.Match
end

local function getRoundUiState(roundState)
	if not roundState then
		return nil
	end

	if roundState.gameState == GAME_STATES.WaitingForPlayers then
		return UI_STATES.ReadyUp
	elseif roundState.gameState == GAME_STATES.WaitingForSecrets then
		if hasLocalSecretSubmitted(roundState) then
			return UI_STATES.WaitingForOpponentSecret
		end

		return UI_STATES.EnteringSecret
	elseif roundState.gameState == GAME_STATES.InProgress then
		if roundState.currentTurn == localPlayer.UserId then
			return UI_STATES.InTurn
		end

		return UI_STATES.OpponentTurn
	elseif roundState.gameState == GAME_STATES.RoundOver or roundState.gameState == GAME_STATES.WaitingForRematch then
		return UI_STATES.GameOver
	end

	return nil
end

local function updateMatchForUiState(uiState, roundState)
	gameOverLabel.Text = ""
	setRestartControlsEnabled(false)

	if roundState then
		updateLockedLabels(roundState)
	end

	if uiState == UI_STATES.EnteringSecret then
		statusLabel.Text = "Enter your secret"
		turnLabel.Text = "Turn: waiting"
		setSecretControlsEnabled(canSubmitSecret(roundState) == true)
		setGuessControlsEnabled(false)
	elseif uiState == UI_STATES.WaitingForOpponentSecret then
		statusLabel.Text = "Waiting for opponent secret"
		turnLabel.Text = "Turn: waiting"
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
	elseif uiState == UI_STATES.InTurn then
		statusLabel.Text = "Your turn"
		turnLabel.Text = "Turn: you"
		setSecretControlsEnabled(false)
		refreshGuessControls()
	elseif uiState == UI_STATES.OpponentTurn then
		statusLabel.Text = "Opponent's turn"
		turnLabel.Text = if roundState and roundState.currentTurn then "Turn: opponent" else "Turn: waiting"
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
	end
end

local function renderUi()
	local screenState = getScreenStateForUiState(currentUiState)
	setScreen(screenState)

	if currentUiState == UI_STATES.LobbyWorld then
		howToPlayPanel.Visible = false
		resetRoundUi()
	elseif currentUiState == UI_STATES.Menu then
		setRestartControlsEnabled(false)
		updateLobby(latestLobbyState)
	elseif currentUiState == UI_STATES.ReadyUp then
		howToPlayPanel.Visible = false
		updateLobby(latestLobbyState)
		resetRoundUi()
	elseif isMatchUiState(currentUiState) then
		howToPlayPanel.Visible = false
		updateMatchForUiState(currentUiState, latestRoundState)
	elseif currentUiState == UI_STATES.GameOver then
		howToPlayPanel.Visible = false
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
		updateResult(latestRoundState)
	end
end

local function setUiState(nextUiState)
	if currentUiState ~= nextUiState then
		clearValidationMessages()
	end

	currentUiState = nextUiState
	renderUi()
end

local function syncUiFromServer()
	if currentUiState == UI_STATES.Menu then
		renderUi()
		return
	end

	if currentUiState == UI_STATES.LobbyWorld then
		renderUi()
		return
	end

	if currentUiState == UI_STATES.ReadyUp
		and latestRoundState
		and (
			latestRoundState.gameState == GAME_STATES.RoundOver
			or latestRoundState.gameState == GAME_STATES.WaitingForRematch
		)
	then
		renderUi()
		return
	end

	local nextUiState = getRoundUiState(latestRoundState) or currentUiState
	setUiState(nextUiState)
end

local function showGameOver(winnerId)
	isGameOver = true

	if latestRoundState then
		latestRoundState.winner = winnerId
		latestRoundState.isTie = winnerId == TIE_WINNER
	end

	setUiState(UI_STATES.GameOver)
end

local function onSecretRequested()
	if currentUiState == UI_STATES.Menu or hasSubmittedSecret then
		return
	end

	syncUiFromServer()
end

local function onTurnChanged(playerId)
	if latestRoundState then
		latestRoundState.currentTurn = playerId
		latestRoundState.gameState = GAME_STATES.InProgress
	end

	if currentUiState == UI_STATES.Menu then
		return
	end

	syncUiFromServer()
end

local function onGuessResult(result)
	statusLabel.Text = "Guess submitted"
	setValidationMessage(guessValidationLabel, "")
	addGuessHistoryEntry(result)
end

local function onRoundStateChanged(roundState)
	latestRoundState = roundState

	if roundState.roundId and roundState.roundId ~= currentRoundId then
		currentRoundId = roundState.roundId
		resetRoundUi()
	end

	if lastGameState and roundState.gameState ~= lastGameState then
		clearValidationMessages()
	end

	if roundState.gameState == GAME_STATES.WaitingForPlayers and lastGameState ~= GAME_STATES.WaitingForPlayers then
		currentRoundId = roundState.roundId
		resetRoundUi()
	end

	lastGameState = roundState.gameState

	isGameOver = roundState.winner ~= nil
	syncUiFromServer()
end

local function onLobbyStateChanged(lobbyState)
	latestLobbyState = lobbyState

	if currentUiState == UI_STATES.Menu or currentUiState == UI_STATES.LobbyWorld then
		if isLocalPlayerInLobby(lobbyState) and not isLocalPlayerInServerMenu(lobbyState) then
			setUiState(UI_STATES.ReadyUp)
		else
			renderUi()
		end
		return
	end

	syncUiFromServer()
end

local function onLobbyFlowStateChanged(flowState)
	latestLobbyFlowState = flowState.lobbyState or LOBBY_STATES.InLobby

	if latestLobbyFlowState == LOBBY_STATES.InLobby then
		setUiState(UI_STATES.LobbyWorld)
	elseif latestLobbyFlowState == LOBBY_STATES.Matchmaking then
		setUiState(UI_STATES.ReadyUp)
	elseif latestLobbyFlowState == LOBBY_STATES.InRound then
		syncUiFromServer()
	elseif latestLobbyFlowState == LOBBY_STATES.PostRound then
		setUiState(UI_STATES.GameOver)
	end
end

secretTextBox:GetPropertyChangedSignal("Text"):Connect(function()
	if isFourDigits(secretTextBox.Text) then
		setValidationMessage(secretValidationLabel, "")
	end
end)

guessTextBox:GetPropertyChangedSignal("Text"):Connect(function()
	if isFourDigits(guessTextBox.Text) then
		setValidationMessage(guessValidationLabel, "")
	end
end)

local function submitSecret()
	if not secretControlsEnabled or isGameOver then
		return
	end

	local secret = secretTextBox.Text
	if not isFourDigits(secret) then
		setValidationMessage(secretValidationLabel, "Enter exactly 4 digits.")
		return
	end

	hasSubmittedSecret = true
	setSecretControlsEnabled(false)
	secretTextBox.Text = ""
	setValidationMessage(secretValidationLabel, "")
	RemoteEvents.SecretSubmitted:FireServer(secret)
	setUiState(UI_STATES.WaitingForOpponentSecret)
end

local function submitGuess()
	if not guessControlsEnabled or isGameOver then
		return
	end

	local guess = guessTextBox.Text
	if not isFourDigits(guess) then
		setValidationMessage(guessValidationLabel, "Enter exactly 4 digits.")
		return
	end

	statusLabel.Text = "Submitting guess..."
	setGuessControlsEnabled(false)
	guessTextBox.Text = ""
	setValidationMessage(guessValidationLabel, "")
	RemoteEvents.GuessSubmitted:FireServer(guess)
end

local function requestRestart()
	if not canRequestRematch then
		return
	end

	resultStatusLabel.Text = "Waiting for opponent to play again"
	statusLabel.Text = "Waiting for rematch"
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
	setRestartControlsEnabled(false)
	RemoteEvents.RematchRequested:FireServer()
end

guessHistoryList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	guessHistoryFrame.CanvasSize = UDim2.fromOffset(0, guessHistoryList.AbsoluteContentSize.Y + 12)
end)

setSecretControlsEnabled(false)
setGuessControlsEnabled(false)
setRestartControlsEnabled(false)
bindFourDigitInput(secretTextBox)
bindFourDigitInput(guessTextBox)
setUiState(UI_STATES.LobbyWorld)

playButton.MouseButton1Click:Connect(function()
	howToPlayPanel.Visible = false
	RemoteEvents.LobbyEntered:FireServer()
	setUiState(UI_STATES.ReadyUp)
end)

howToPlayButton.MouseButton1Click:Connect(function()
	howToPlayPanel.Visible = not howToPlayPanel.Visible
end)

closeHowToPlayButton.MouseButton1Click:Connect(function()
	howToPlayPanel.Visible = false
end)

lobbyBackButton.MouseButton1Click:Connect(function()
	RemoteEvents.LobbyLeft:FireServer()
	setUiState(UI_STATES.LobbyWorld)
end)
backToMenuButton.MouseButton1Click:Connect(function()
	RemoteEvents.LobbyLeft:FireServer()
	setUiState(UI_STATES.LobbyWorld)
end)

readyButton.MouseButton1Click:Connect(function()
	if not readyControlsEnabled then
		return
	end

	local isReady = latestLobbyState and getPlayerReady(latestLobbyState, localPlayer.UserId) or false
	RemoteEvents.ReadyChanged:FireServer(not isReady)
	readyControlsEnabled = false
	setButtonEnabled(readyButton, false)
end)

submitSecretButton.MouseButton1Click:Connect(submitSecret)
submitGuessButton.MouseButton1Click:Connect(submitGuess)
restartButton.MouseButton1Click:Connect(requestRestart)
resultPlayAgainButton.MouseButton1Click:Connect(requestRestart)

RemoteEvents.SecretRequested.OnClientEvent:Connect(onSecretRequested)
RemoteEvents.TurnChanged.OnClientEvent:Connect(onTurnChanged)
RemoteEvents.GuessResult.OnClientEvent:Connect(onGuessResult)
RemoteEvents.GameOver.OnClientEvent:Connect(showGameOver)
RemoteEvents.RoundStateChanged.OnClientEvent:Connect(onRoundStateChanged)
RemoteEvents.LobbyStateChanged.OnClientEvent:Connect(onLobbyStateChanged)
RemoteEvents.LobbyFlowStateChanged.OnClientEvent:Connect(onLobbyFlowStateChanged)
