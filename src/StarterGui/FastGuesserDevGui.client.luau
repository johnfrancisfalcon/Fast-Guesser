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
	disabledInputText = Color3.fromRGB(116, 126, 140),
	enabledText = Color3.fromRGB(255, 255, 255),
	disabledText = Color3.fromRGB(182, 190, 200),
	errorText = Color3.fromRGB(255, 176, 176),
	successText = Color3.fromRGB(83, 190, 132),
	historyEntry = Color3.fromRGB(33, 45, 59),
	historyEntryAlt = Color3.fromRGB(24, 34, 46),
	historyEntryBorder = Color3.fromRGB(72, 86, 104),
	localCard = Color3.fromRGB(36, 59, 79),
	localCardBorder = Color3.fromRGB(85, 162, 255),
	opponentCard = Color3.fromRGB(30, 49, 44),
	opponentCardBorder = Color3.fromRGB(84, 207, 144),
	waitingCard = Color3.fromRGB(24, 34, 48),
	waitingCardBorder = Color3.fromRGB(58, 77, 101),
	readyPill = Color3.fromRGB(39, 66, 56),
	readyPillBorder = Color3.fromRGB(84, 207, 144),
	idlePill = Color3.fromRGB(45, 55, 68),
	idlePillBorder = Color3.fromRGB(85, 108, 136),
	activePanel = Color3.fromRGB(85, 162, 255),
	idlePanel = Color3.fromRGB(58, 77, 101),
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
local playerOneRow = findUi(lobbyScreen, "PlayerOneRow")
local playerTwoRow = findUi(lobbyScreen, "PlayerTwoRow")
local playerOneSlotLabel = findUi(lobbyScreen, "PlayerOneSlotLabel")
local playerOneReadyLabel = findUi(lobbyScreen, "PlayerOneReadyLabel")
local playerOneReadyPill = findUi(lobbyScreen, "PlayerOneRowReadyPill")
local playerTwoSlotLabel = findUi(lobbyScreen, "PlayerTwoSlotLabel")
local playerTwoReadyLabel = findUi(lobbyScreen, "PlayerTwoReadyLabel")
local playerTwoReadyPill = findUi(lobbyScreen, "PlayerTwoRowReadyPill")
local readyButton = findUi(lobbyScreen, "ReadyButton")
local lobbyBackButton = findUi(lobbyScreen, "LobbyBackButton")

local statusLabel = findUi(matchScreen, "StatusLabel")
local secretPanel = findUi(matchScreen, "SecretPanel")
local secretTextBox = findUi(matchScreen, "SecretTextBox")
local submitSecretButton = findUi(matchScreen, "SubmitSecretButton")
local secretValidationLabel = findUi(matchScreen, "SecretValidationLabel")
local guessPanel = findUi(matchScreen, "GuessPanel")
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

local function getStroke(instance)
	return instance:FindFirstChildOfClass("UIStroke")
end

local function getGradient(instance)
	return instance:FindFirstChildOfClass("UIGradient")
end

local function getColorAttribute(instance, attributeName, fallback)
	local value = instance:GetAttribute(attributeName)
	return if typeof(value) == "Color3" then value else fallback
end

local function applyButtonVisual(button, visualState)
	local enabledBackground = getColorAttribute(button, "EnabledBackgroundColor", COLORS.enabledButton)
	local hoverBackground = getColorAttribute(button, "HoverBackgroundColor", enabledBackground)
	local pressedBackground = getColorAttribute(button, "PressedBackgroundColor", enabledBackground)
	local disabledBackground = getColorAttribute(button, "DisabledBackgroundColor", COLORS.disabledButton)
	local enabledText = getColorAttribute(button, "EnabledTextColor", COLORS.enabledText)
	local disabledText = getColorAttribute(button, "DisabledTextColor", COLORS.disabledText)
	local strokeColor = getColorAttribute(button, "StrokeColor", enabledBackground)

	local backgroundColor = enabledBackground
	local textColor = enabledText
	local transparency = 0
	local strokeTransparency = 0.12

	if visualState == "hover" then
		backgroundColor = hoverBackground
	elseif visualState == "pressed" then
		backgroundColor = pressedBackground
		transparency = 0.02
	elseif visualState == "disabled" then
		backgroundColor = disabledBackground
		textColor = disabledText
		transparency = 0.16
		strokeTransparency = 0.4
	end

	button.BackgroundColor3 = backgroundColor
	button.TextColor3 = textColor
	button.BackgroundTransparency = transparency
	button.TextTransparency = if visualState == "disabled" then 0.08 else 0

	local stroke = getStroke(button)
	if stroke then
		stroke.Color = strokeColor
		stroke.Transparency = strokeTransparency
	end

	local gradient = getGradient(button)
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, backgroundColor),
			ColorSequenceKeypoint.new(1, if visualState == "disabled" then backgroundColor else pressedBackground),
		})
	end
end

local function wireButtonInteractions(button)
	if not button:IsA("TextButton") then
		return
	end

	button:SetAttribute("IsHovered", false)
	button:SetAttribute("IsPressed", false)
	button.MouseEnter:Connect(function()
		button:SetAttribute("IsHovered", true)
		if button.Active then
			applyButtonVisual(button, "hover")
		end
	end)
	button.MouseLeave:Connect(function()
		button:SetAttribute("IsHovered", false)
		button:SetAttribute("IsPressed", false)
		applyButtonVisual(button, if button.Active then "default" else "disabled")
	end)
	button.InputBegan:Connect(function(inputObject)
		if not button.Active then
			return
		end

		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			button:SetAttribute("IsPressed", true)
			applyButtonVisual(button, "pressed")
		end
	end)
	button.InputEnded:Connect(function(inputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		button:SetAttribute("IsPressed", false)
		if button.Active and button:GetAttribute("IsHovered") then
			applyButtonVisual(button, "hover")
		else
			applyButtonVisual(button, if button.Active then "default" else "disabled")
		end
	end)

	applyButtonVisual(button, "default")
end

local function updateCardVisual(card, backgroundColor, strokeColor)
	card.BackgroundColor3 = backgroundColor

	local stroke = getStroke(card)
	if stroke then
		stroke.Color = strokeColor
		stroke.Transparency = 0.1
	end

	local gradient = getGradient(card)
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, backgroundColor),
			ColorSequenceKeypoint.new(1, COLORS.historyEntryAlt),
		})
	end
end

local function updateReadyPill(pill, ready)
	local stroke = getStroke(pill)
	local gradient = getGradient(pill)

	pill.BackgroundColor3 = if ready then COLORS.readyPill else COLORS.idlePill
	if stroke then
		stroke.Color = if ready then COLORS.readyPillBorder else COLORS.idlePillBorder
		stroke.Transparency = 0.08
	end
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, pill.BackgroundColor3),
			ColorSequenceKeypoint.new(1, COLORS.historyEntryAlt),
		})
	end
end

local function setPanelAccent(panel, enabled)
	local stroke = getStroke(panel)
	if stroke then
		stroke.Color = if enabled then COLORS.activePanel else COLORS.idlePanel
		stroke.Transparency = if enabled then 0.05 else 0.22
	end
end

local function setButtonEnabled(button, enabled)
	button.Active = enabled
	button.AutoButtonColor = false
	applyButtonVisual(button, if enabled then "default" else "disabled")
end

local function setSecretControlsEnabled(enabled)
	secretControlsEnabled = enabled
	secretTextBox.TextEditable = enabled
	secretTextBox.BackgroundColor3 = getColorAttribute(
		secretTextBox,
		if enabled then "EnabledBackgroundColor" else "DisabledBackgroundColor",
		if enabled then COLORS.enabledInput else COLORS.disabledInput
	)
	secretTextBox.TextColor3 = if enabled then Color3.fromRGB(18, 25, 36) else COLORS.disabledInputText
	secretTextBox.TextTransparency = if enabled then 0 else 0.15
	local stroke = getStroke(secretTextBox)
	if stroke then
		stroke.Color = getColorAttribute(
			secretTextBox,
			if enabled then "EnabledStrokeColor" else "DisabledStrokeColor",
			if enabled then COLORS.enabledButton else COLORS.disabledButton
		)
		stroke.Transparency = if enabled then 0.2 else 0.4
	end
	setPanelAccent(secretPanel, enabled)
	setButtonEnabled(submitSecretButton, enabled)
end

local function setGuessControlsEnabled(enabled)
	guessControlsEnabled = enabled
	guessTextBox.TextEditable = enabled
	guessTextBox.BackgroundColor3 = getColorAttribute(
		guessTextBox,
		if enabled then "EnabledBackgroundColor" else "DisabledBackgroundColor",
		if enabled then COLORS.enabledInput else COLORS.disabledInput
	)
	guessTextBox.TextColor3 = if enabled then Color3.fromRGB(18, 25, 36) else COLORS.disabledInputText
	guessTextBox.TextTransparency = if enabled then 0 else 0.15
	local stroke = getStroke(guessTextBox)
	if stroke then
		stroke.Color = getColorAttribute(
			guessTextBox,
			if enabled then "EnabledStrokeColor" else "DisabledStrokeColor",
			if enabled then COLORS.enabledButton else COLORS.disabledButton
		)
		stroke.Transparency = if enabled then 0.2 else 0.4
	end
	setPanelAccent(guessPanel, enabled)
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
		if child.Name == "GuessHistoryEntry" then
			child:Destroy()
		end
	end

	guessHistoryCount = 0
	guessHistoryFrame.CanvasSize = UDim2.fromOffset(0, 0)
end

local function addGuessHistoryEntry(result)
	guessHistoryCount += 1

	local entry = Instance.new("Frame")
	entry.Name = "GuessHistoryEntry"
	entry.LayoutOrder = guessHistoryCount
	entry.Size = UDim2.new(1, -4, 0, 82)
	entry.BackgroundColor3 = COLORS.historyEntry
	entry.BorderSizePixel = 0
	entry.Parent = guessHistoryFrame

	updateCardVisual(entry, COLORS.historyEntry, COLORS.historyEntryBorder)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = entry

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.Parent = entry

	local guessLabel = Instance.new("TextLabel")
	guessLabel.Name = "GuessLabel"
	guessLabel.Size = UDim2.new(1, 0, 0, 24)
	guessLabel.BackgroundTransparency = 1
	guessLabel.Font = Enum.Font.GothamBold
	guessLabel.Text = "Guess " .. tostring(guessHistoryCount) .. "  •  " .. tostring(result.guess)
	guessLabel.TextColor3 = COLORS.enabledText
	guessLabel.TextSize = 16
	guessLabel.TextXAlignment = Enum.TextXAlignment.Left
	guessLabel.Parent = entry

	local feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "FeedbackLabel"
	feedbackLabel.Position = UDim2.fromOffset(0, 30)
	feedbackLabel.Size = UDim2.new(1, 0, 0, 24)
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.Font = Enum.Font.Gotham
	feedbackLabel.Text = "Locked feedback: " .. formatLockedPositions(result.matches)
	feedbackLabel.TextColor3 = COLORS.disabledText
	feedbackLabel.TextSize = 15
	feedbackLabel.TextXAlignment = Enum.TextXAlignment.Left
	feedbackLabel.Parent = entry
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
		return "Open Slot • Player " .. tostring(slotNumber)
	end

	if playerId == localPlayer.UserId then
		return "You • Player " .. tostring(slotNumber)
	end

	return "Opponent • Player " .. tostring(slotNumber)
end

local function updateReadyLabel(label, ready)
	label.Text = if ready then "Ready" else "Not ready"
	label.TextColor3 = if ready then COLORS.successText else COLORS.disabledText
	label.Font = if ready then Enum.Font.GothamBold else Enum.Font.Gotham
end

local function updateLobbyPlayerCard(card, readyPill, slotLabel, readyLabel, slotNumber, playerId, ready)
	slotLabel.Text = formatPlayerSlot(slotNumber, playerId)
	updateReadyLabel(readyLabel, ready)
	updateReadyPill(readyPill, ready)

	if not playerId then
		updateCardVisual(card, COLORS.waitingCard, COLORS.waitingCardBorder)
		return
	end

	if playerId == localPlayer.UserId then
		updateCardVisual(card, COLORS.localCard, COLORS.localCardBorder)
	else
		updateCardVisual(card, COLORS.opponentCard, COLORS.opponentCardBorder)
	end
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
		updateLobbyPlayerCard(playerOneRow, playerOneReadyPill, playerOneSlotLabel, playerOneReadyLabel, 1, nil, false)
		updateLobbyPlayerCard(playerTwoRow, playerTwoReadyPill, playerTwoSlotLabel, playerTwoReadyLabel, 2, nil, false)
		readyControlsEnabled = true
		setButtonEnabled(readyButton, true)
		readyButton.Text = "Ready"
		return
	end

	local playerOneReady = getPlayerReady(lobbyState, lobbyState.playerOneId)
	local playerTwoReady = getPlayerReady(lobbyState, lobbyState.playerTwoId)
	local localReady = getPlayerReady(lobbyState, localPlayer.UserId)
	local isInLobby = lobbyState.playerOneId == localPlayer.UserId or lobbyState.playerTwoId == localPlayer.UserId
	local hasBothPlayers = lobbyState.playerOneId ~= nil and lobbyState.playerTwoId ~= nil
	local canToggleReady = lobbyState.gameState == GAME_STATES.WaitingForPlayers and isInLobby

	updateLobbyPlayerCard(
		playerOneRow,
		playerOneReadyPill,
		playerOneSlotLabel,
		playerOneReadyLabel,
		1,
		lobbyState.playerOneId,
		playerOneReady
	)
	updateLobbyPlayerCard(
		playerTwoRow,
		playerTwoReadyPill,
		playerTwoSlotLabel,
		playerTwoReadyLabel,
		2,
		lobbyState.playerTwoId,
		playerTwoReady
	)

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

	if flowState.showMenu == true then
		setUiState(UI_STATES.Menu)
	elseif latestLobbyFlowState == LOBBY_STATES.InLobby then
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

for _, descendant in ipairs(devGui:GetDescendants()) do
	if descendant:IsA("TextButton") then
		wireButtonInteractions(descendant)
	end
end

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
