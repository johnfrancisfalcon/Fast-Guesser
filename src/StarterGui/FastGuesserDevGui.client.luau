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

local MODES = {
	Classic4Digit = "classic_4_digit",
	HigherLower100 = "higher_lower_100",
}

local UI_STATES = {
	-- No modal UI; the player is standing in the 3D lobby and can use a game pad prompt.
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
	activeSecretPanel = Color3.fromRGB(95, 151, 232),
	activeGuessPanel = Color3.fromRGB(84, 207, 144),
	phaseSecret = Color3.fromRGB(52, 79, 118),
	phaseGuess = Color3.fromRGB(40, 85, 72),
	resultWin = Color3.fromRGB(34, 87, 67),
	resultLoss = Color3.fromRGB(67, 50, 54),
	resultTie = Color3.fromRGB(89, 73, 41),
}

local devGui = GuiBuilder.getOrCreate(playerGui)
local background = devGui:WaitForChild("Background")
local menuScreen = devGui:WaitForChild("MenuScreen")
local lobbyScreen = devGui:WaitForChild("LobbyScreen")
local matchScreen = devGui:WaitForChild("MatchScreen")
local resultScreen = devGui:WaitForChild("ResultScreen")
local currencyHud = devGui:WaitForChild("CurrencyHud")
local shopPanel = devGui:WaitForChild("ShopPanel")
local rewardsPanel = devGui:WaitForChild("RewardsPanel")
local leaderboardPanel = devGui:WaitForChild("LeaderboardPanel")

local function findUi(parent, name)
	local instance = parent:FindFirstChild(name, true)
	assert(instance, "Missing Fast Guesser UI element: " .. name)
	return instance
end

local playButton = findUi(menuScreen, "PlayButton")
local menuBackButton = findUi(menuScreen, "MenuBackButton")
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
local statusChip = findUi(matchScreen, "StatusInfoChip")
local statusChipLabel = findUi(matchScreen, "StatusChipLabel")
local gameOverLabel = findUi(matchScreen, "GameOverLabel")
local restartButton = findUi(matchScreen, "RestartButton")
local guessHistoryFrame = findUi(matchScreen, "GuessHistoryFrame")
local guessHistoryList = guessHistoryFrame:WaitForChild("GuessHistoryList")
local secretStateLabel = findUi(matchScreen, "SecretStateLabel")
local guessStateLabel = findUi(matchScreen, "GuessStateLabel")
local playerLockedSlots = {
	findUi(matchScreen, "PlayerLockedSlot1"),
	findUi(matchScreen, "PlayerLockedSlot2"),
	findUi(matchScreen, "PlayerLockedSlot3"),
	findUi(matchScreen, "PlayerLockedSlot4"),
}
local opponentLockedSlots = {
	findUi(matchScreen, "OpponentLockedSlot1"),
	findUi(matchScreen, "OpponentLockedSlot2"),
	findUi(matchScreen, "OpponentLockedSlot3"),
	findUi(matchScreen, "OpponentLockedSlot4"),
}

local resultWinnerLabel = findUi(resultScreen, "ResultWinnerLabel")
local resultSubtitleLabel = findUi(resultScreen, "ResultSubtitleLabel")
local resultWinnerCard = findUi(resultScreen, "ResultWinnerCard")
local resultStatusLabel = findUi(resultScreen, "ResultStatusLabel")
local resultPlayAgainButton = findUi(resultScreen, "ResultPlayAgainButton")
local backToMenuButton = findUi(resultScreen, "BackToMenuButton")
local resultRewardLabel = findUi(resultScreen, "ResultRewardLabel")
local currencyAmountLabel = findUi(currencyHud, "CurrencyAmountLabel")
local currencyDeltaLabel = findUi(currencyHud, "CurrencyDeltaLabel")
local closeShopButton = findUi(shopPanel, "CloseShopButton")
local shopBalanceLabel = findUi(shopPanel, "ShopBalanceLabel")
local shopStatusLabel = findUi(shopPanel, "ShopStatusLabel")
local closeRewardsButton = findUi(rewardsPanel, "CloseRewardsButton")
local rewardsBalanceLabel = findUi(rewardsPanel, "RewardsBalanceLabel")
local rewardsStatusLabel = findUi(rewardsPanel, "RewardsStatusLabel")
local rewardTitleLabel = findUi(rewardsPanel, "RewardTitleLabel")
local rewardBodyLabel = findUi(rewardsPanel, "RewardBodyLabel")
local rewardAmountLabel = findUi(rewardsPanel, "RewardAmountLabel")
local claimRewardButton = findUi(rewardsPanel, "ClaimRewardButton")
local rewardWheelBodyLabel = findUi(rewardsPanel, "RewardWheelBodyLabel")
local closeLeaderboardButton = findUi(leaderboardPanel, "CloseLeaderboardButton")
local leaderboardStatusLabel = findUi(leaderboardPanel, "LeaderboardStatusLabel")
local leaderboardEmptyLabel = findUi(leaderboardPanel, "LeaderboardEmptyLabel")

local modeUi = {
	menuSubtitleLabel = findUi(menuScreen, "SubtitleLabel"),
	menuTagLabel = findUi(menuScreen, "MenuTagLabel"),
	menuHeadingLabel = findUi(menuScreen, "MenuHeadingLabel"),
	menuBodyLabel = findUi(menuScreen, "MenuBodyLabel"),
	menuInfoTextLabel = findUi(menuScreen, "MenuInfoTextLabel"),
	menuInfoFootnoteLabel = findUi(menuScreen, "MenuInfoFootnoteLabel"),
	howToPlayTextLabel = findUi(menuScreen, "HowToPlayTextLabel"),
	matchSubtitleLabel = findUi(matchScreen, "SubtitleLabel"),
	secretHelpLabel = findUi(matchScreen, "SecretHelpLabel"),
	guessHelpLabel = findUi(matchScreen, "GuessHelpLabel"),
	yourLockedCard = findUi(matchScreen, "YourLockedCard"),
	opponentLockedCard = findUi(matchScreen, "OpponentLockedCard"),
	highLowSummaryLabel = findUi(matchScreen, "HighLowSummaryLabel"),
	historyHintLabel = findUi(matchScreen, "HistoryHintLabel"),
	resultYourSecretLabel = findUi(resultScreen, "ResultYourSecretLabel"),
	resultOpponentSecretLabel = findUi(resultScreen, "ResultOpponentSecretLabel"),
	buyCoinsHudButton = findUi(currencyHud, "BuyCoinsHudButton"),
	coinPacksPanel = devGui:WaitForChild("CoinPacksPanel"),
	openCoinPacksButton = findUi(shopPanel, "OpenCoinPacksButton"),
}
modeUi.closeCoinPacksButton = findUi(modeUi.coinPacksPanel, "CloseCoinPacksButton")
modeUi.coinPacksBalanceLabel = findUi(modeUi.coinPacksPanel, "CoinPacksBalanceLabel")
modeUi.coinPacksStatusLabel = findUi(modeUi.coinPacksPanel, "CoinPacksStatusLabel")
modeUi.rewardNextClaimLabel = findUi(rewardsPanel, "RewardNextClaimLabel")
modeUi.promptService = game:GetService("ProximityPromptService")
modeUi.shopRows = {}
modeUi.leaderboardRows = {}

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
local currencyBalance = 0
local lastCurrencyDelta = 0
local setButtonEnabled

local function isFourDigits(value)
	return string.match(value, "^%d%d%d%d$") ~= nil
end

local function isOneToOneHundred(value)
	if string.match(value, "^%d+$") == nil then
		return false
	end

	local numberValue = tonumber(value)
	return numberValue ~= nil and numberValue >= 1 and numberValue <= 100
end

local function getCurrentMode()
	if latestRoundState and latestRoundState.selectedMode then
		return latestRoundState.selectedMode
	end

	if latestLobbyState and latestLobbyState.selectedMode then
		return latestLobbyState.selectedMode
	end

	if modeUi.latestModeState and modeUi.latestModeState.selectedMode then
		return modeUi.latestModeState.selectedMode
	end

	return MODES.Classic4Digit
end

local function isHigherLowerMode()
	return getCurrentMode() == MODES.HigherLower100
end

local function isValidModeInput(value)
	if isHigherLowerMode() then
		return isOneToOneHundred(value)
	end

	return isFourDigits(value)
end

local function getModeInputError()
	return if isHigherLowerMode() then "Enter a number from 1 to 100." else "Enter exactly 4 digits."
end

local function getModeCopy()
	if isHigherLowerMode() then
		return {
			menuSubtitle = "Pick a number, read Higher / Lower feedback, and solve first.",
			menuTag = "1-100 NUMBER DUEL",
			menuHeading = "Narrow the range. Call the number.",
			menuBody = "Set a secret number from 1 to 100, trade guesses, and use Higher, Lower, or Correct feedback to solve first.",
			menuInfo = "Both players submit a secret number from 1 to 100. On each turn, guess the opponent's number. Feedback tells you whether the answer is Higher, Lower, or Correct.",
			menuFootnote = "If the first player solves first, the second player still gets one final chance to tie.",
			howToPlay = "Choose a secret number from 1 to 100. When the round starts, take turns guessing the opponent's number. Feedback is only Higher, Lower, or Correct. The first player to guess correctly wins, with a final tie chance for the second player if needed.",
			matchSubtitle = "Race to find the hidden number. Feedback tells you Higher, Lower, or Correct.",
			secretHelp = "Choose the 1-100 number your opponent is trying to find.",
			guessHelp = "Submit guesses from 1 to 100. Feedback says whether the answer is Higher, Lower, or Correct.",
			historyHint = "Each entry shows the guess and whether the answer is Higher, Lower, or Correct.",
			secretPlaceholder = "Enter 1-100",
			guessPlaceholder = "Enter 1-100",
			enterSecretStatus = "Enter your secret number",
			waitingSecretStatus = "Waiting for opponent number",
			secretActiveState = "Active: enter your number",
			secretSavedState = "Number saved",
			guessLockedState = "Locked until numbers are in",
			guessWaitingState = "Waiting for guess phase",
			secretLockedState = "Number locked",
			guessActiveState = "Active: submit a number",
			guessOpponentState = "Opponent is guessing",
			youWonSubtitle = "You found the number and closed the round.",
			opponentWonSubtitle = "Opponent found your number first.",
			tieSubtitle = "Both players found the number on the final exchange.",
			highLowSummary = "No locked digits in this mode. Use Higher / Lower history to narrow the hidden number.",
		}
	end

	return {
		menuSubtitle = "Lock exact digits before your opponent cracks your code.",
		menuTag = "2-PLAYER SHOWDOWN",
		menuHeading = "Read the pattern. Win the race.",
		menuBody = "Set a 4-digit secret, trade guesses, and lock exact hits before the other player solves your full code.",
		menuInfo = "Both players submit a secret. On each turn, enter a 4-digit guess. Exact-position matches lock in and stay visible for the rest of the round.",
		menuFootnote = "If the first player solves first, the second player still gets one final chance to tie.",
		howToPlay = "Choose a 4-digit secret. When the round starts, take turns making 4-digit guesses. Each exact-position match becomes locked, helping narrow the answer. The player who fully reveals the opponent's code wins, with a final tie chance for the second player if needed.",
		matchSubtitle = "Race to solve the code. Locked digits stay revealed for the rest of the round.",
		secretHelp = "Choose the 4-digit code your opponent is trying to reveal.",
		guessHelp = "Submit guesses on your turn. Exact digits lock permanently into place.",
		historyHint = "Each entry shows the guess and currently locked feedback.",
		secretPlaceholder = "Enter 4 digits",
		guessPlaceholder = "Enter 4 digits",
		enterSecretStatus = "Enter your secret",
		waitingSecretStatus = "Waiting for opponent secret",
		secretActiveState = "Active: enter your code",
		secretSavedState = "Secret saved",
		guessLockedState = "Locked until secrets are in",
		guessWaitingState = "Waiting for guess phase",
		secretLockedState = "Secret locked",
		guessActiveState = "Active: submit a guess",
		guessOpponentState = "Opponent is guessing",
		youWonSubtitle = "You cracked the code and closed the round.",
		opponentWonSubtitle = "Opponent solved your code first.",
		tieSubtitle = "Both players solved it on the final exchange.",
		highLowSummary = "",
	}
end

local function clampModeInput(value)
	local digitsOnly = string.gsub(value, "%D", "")
	return string.sub(digitsOnly, 1, if isHigherLowerMode() then 3 else 4)
end

local function bindModeInput(textBox)
	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		local clampedText = clampModeInput(textBox.Text)
		if textBox.Text ~= clampedText then
			textBox.Text = clampedText
		end
	end)
end

local function updateCurrencyHud(delta)
	currencyAmountLabel.Text = tostring(currencyBalance)
	lastCurrencyDelta = delta or lastCurrencyDelta or 0

	if lastCurrencyDelta > 0 then
		currencyDeltaLabel.Text = "+" .. tostring(lastCurrencyDelta)
	else
		currencyDeltaLabel.Text = ""
	end
end

local function getLocalCurrencyValue(state, key)
	local valuesByPlayerId = state and state[key] or {}
	return valuesByPlayerId[tostring(localPlayer.UserId)]
end

local function setCommercePanelsVisible(shopVisible, rewardsVisible, leaderboardVisible, coinPacksVisible)
	shopPanel.Visible = shopVisible == true
	rewardsPanel.Visible = rewardsVisible == true
	leaderboardPanel.Visible = leaderboardVisible == true
	modeUi.coinPacksPanel.Visible = coinPacksVisible == true
end

local function getEquippedItemIdByCategory(equippedItems, category)
	return equippedItems and equippedItems[category] or nil
end

local function updateShopPanel(shopState)
	modeUi.latestShopState = shopState or modeUi.latestShopState
	local state = modeUi.latestShopState
	shopBalanceLabel.Text = "Coins: " .. tostring((state and state.balance) or currencyBalance)

	shopStatusLabel.Text = (state and state.message) or "Select an item."

	local catalog = state and state.catalog or {}
	local ownedItems = state and state.ownedItems or {}
	local equippedItems = state and state.equippedItems or {}

	for index, row in ipairs(modeUi.shopRows) do
		local item = catalog[index]
		row.frame.Visible = item ~= nil
		if item then
			row.frame:SetAttribute("ItemId", item.id)
			row.name.Text = item.name
			row.meta.Text = item.category .. " • " .. tostring(item.price) .. " coins"
			local owned = ownedItems[item.id] == true
			local equipped = getEquippedItemIdByCategory(equippedItems, item.category) == item.id
			row.state.Text = if equipped then "Equipped" elseif owned then "Owned" else tostring(item.price) .. " coins"
			setButtonEnabled(row.buyButton, not owned)
			setButtonEnabled(row.equipButton, owned)
			row.buyButton.Text = if owned then "Owned" else "Buy"
			row.equipButton.Text = if equipped then "Unequip" else "Equip"
		end
	end
end

local function updateCoinPacksPanel(coinPackState)
	modeUi.latestCoinPackState = coinPackState or modeUi.latestCoinPackState
	local state = modeUi.latestCoinPackState
	modeUi.coinPacksBalanceLabel.Text = "Coins: " .. tostring((state and state.balance) or currencyBalance)
	modeUi.coinPacksStatusLabel.Text = (state and state.message) or "Choose a coin pack."

	local packs = state and state.packs or {}
	for index, row in ipairs(modeUi.coinPackRows) do
		local pack = packs[index]
		row.frame.Visible = pack ~= nil
		if pack then
			row.frame:SetAttribute("PackId", pack.id)
			row.name.Text = pack.name or "Coin Pack"
			row.description.Text = pack.description or ""
			row.amount.Text = "+" .. tostring(pack.coins or 0) .. " coins"
			local configured = pack.productId and pack.productId > 0
			row.button.Text = if configured then "Buy" else "Setup"
			setButtonEnabled(row.button, configured)
		end
	end
end

local function updateLeaderboardPanel(leaderboardState)
	modeUi.latestLeaderboardState = leaderboardState or modeUi.latestLeaderboardState
	local state = modeUi.latestLeaderboardState
	local entries = state and state.entries or {}
	leaderboardStatusLabel.Text = (state and state.message) or "Session leaderboard"
	leaderboardEmptyLabel.Visible = #entries == 0

	for index, row in ipairs(modeUi.leaderboardRows) do
		local entry = entries[index]
		row.frame.Visible = entry ~= nil
		if entry then
			row.rank.Text = tostring(entry.rank or index)
			row.name.Text = entry.name or "Player"
			row.wins.Text = tostring(entry.wins or 0)
			row.streak.Text = tostring(entry.currentStreak or 0)
			row.coins.Text = tostring(entry.coins or 0)
		end
	end
end

local function updateRewardsPanel(rewardState)
	modeUi.latestRewardState = rewardState or modeUi.latestRewardState
	local state = modeUi.latestRewardState
	rewardsBalanceLabel.Text = "Coins: " .. tostring((state and state.balance) or currencyBalance)
	local claimAmount = (state and state.claimAmount) or 0
	local canClaim = state == nil or state.canClaim == true
	local claimed = state and state.claimed == true
	rewardTitleLabel.Text = (state and state.title) or "Daily Coins"
	rewardBodyLabel.Text = if canClaim
		then "Your daily coin reward is available now. Claiming updates your saved progression immediately."
		else "Today's daily reward is already claimed. Come back after the next UTC reset."
	rewardAmountLabel.Text = "+" .. tostring(claimAmount) .. " coins"
	claimRewardButton.Text = if canClaim then "Claim Daily Reward" else "Claimed Today"
	setButtonEnabled(claimRewardButton, canClaim)
	modeUi.rewardNextClaimLabel.Text = (state and state.nextClaimText) or "Ready now"
	modeUi.rewardNextClaimLabel.TextColor3 = if canClaim then COLORS.successText else COLORS.disabledText
	rewardsStatusLabel.Text = if state and state.message then state.message elseif claimed then "Daily reward already claimed." else "Daily reward ready."
	rewardWheelBodyLabel.Text = (state and state.wheelStatus) or "Reward wheel coming next. Daily coins are live now."

	local segments = state and state.wheelSegments or {}
	for index = 1, 5 do
		local segment = findUi(rewardsPanel, "RewardWheelSegment" .. tostring(index))
		local label = segment:FindFirstChild("RewardWheelSegmentLabel" .. tostring(index))
		local rewardSegment = segments[index]
		if label and label:IsA("TextLabel") then
			label.Text = rewardSegment and tostring(rewardSegment.label) or "-"
		end
	end
end

local COSMETIC_INSTANCES = {
	trail = "FastGuesserCosmeticTrail",
	trailA = "FastGuesserCosmeticTrailA",
	trailB = "FastGuesserCosmeticTrailB",
	tag = "FastGuesserCosmeticTag",
	spark = "FastGuesserCosmeticSpark",
	light = "FastGuesserCosmeticLight",
}

local function getEquippedForPlayer(player)
	local equippedByPlayerId = modeUi.latestCosmeticsState and modeUi.latestCosmeticsState.equippedByPlayerId or {}
	return equippedByPlayerId[tostring(player.UserId)] or {}
end

local function destroyNamedChild(parent, childName)
	local child = parent and parent:FindFirstChild(childName)
	if child then
		child:Destroy()
	end
end

local function applyMidnightTheme(equippedItems)
	local enabled = equippedItems.Theme == "theme_midnight"
	background.BackgroundColor3 = if enabled then Color3.fromRGB(12, 9, 26) else Color3.fromRGB(8, 13, 22)
	currencyHud.BackgroundColor3 = if enabled then Color3.fromRGB(34, 24, 62) else COLORS.historyEntry
	local stroke = currencyHud:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = if enabled then Color3.fromRGB(174, 120, 255) else COLORS.historyEntryBorder
		stroke.Transparency = if enabled then 0.08 else 0.18
	end
end

local function isLobbyCosmeticVisible()
	return latestLobbyFlowState == LOBBY_STATES.InLobby or latestLobbyFlowState == LOBBY_STATES.Matchmaking
end

local function applyCharacterCosmetics(player)
	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not rootPart then
		return
	end

	local equippedItems = getEquippedForPlayer(player)

	destroyNamedChild(rootPart, COSMETIC_INSTANCES.trail)
	destroyNamedChild(rootPart, COSMETIC_INSTANCES.trailA)
	destroyNamedChild(rootPart, COSMETIC_INSTANCES.trailB)
	if equippedItems.Trail == "trail_neon" then
		local attachmentA = Instance.new("Attachment")
		attachmentA.Name = COSMETIC_INSTANCES.trailA
		attachmentA.Position = Vector3.new(-0.45, 0.8, 0)
		attachmentA.Parent = rootPart

		local attachmentB = Instance.new("Attachment")
		attachmentB.Name = COSMETIC_INSTANCES.trailB
		attachmentB.Position = Vector3.new(0.45, -0.8, 0)
		attachmentB.Parent = rootPart

		local trail = Instance.new("Trail")
		trail.Name = COSMETIC_INSTANCES.trail
		trail.Attachment0 = attachmentA
		trail.Attachment1 = attachmentB
		trail.Color = ColorSequence.new(Color3.fromRGB(85, 225, 255), Color3.fromRGB(172, 116, 255))
		trail.Lifetime = 0.55
		trail.LightEmission = 0.7
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.Parent = rootPart
	end

	if head then
		destroyNamedChild(head, COSMETIC_INSTANCES.tag)
		if equippedItems.Title == "tag_quick_cracker" then
			local tag = Instance.new("BillboardGui")
			tag.Name = COSMETIC_INSTANCES.tag
			tag.Size = UDim2.fromOffset(180, 34)
			tag.StudsOffset = Vector3.new(0, 2.8, 0)
			tag.AlwaysOnTop = true
			tag.Parent = head

			local label = Instance.new("TextLabel")
			label.Name = "TagLabel"
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBlack
			label.Text = "QUICK CRACKER"
			label.TextColor3 = Color3.fromRGB(255, 232, 126)
			label.TextStrokeColor3 = Color3.fromRGB(10, 12, 18)
			label.TextStrokeTransparency = 0.15
			label.TextSize = 16
			label.Parent = tag
		end
	end

	destroyNamedChild(rootPart, COSMETIC_INSTANCES.spark)
	destroyNamedChild(rootPart, COSMETIC_INSTANCES.light)
	if equippedItems.Lobby == "spark_lobby" and isLobbyCosmeticVisible() then
		local spark = Instance.new("ParticleEmitter")
		spark.Name = COSMETIC_INSTANCES.spark
		spark.Color = ColorSequence.new(Color3.fromRGB(255, 215, 96), Color3.fromRGB(98, 169, 255))
		spark.LightEmission = 0.75
		spark.Rate = 12
		spark.Lifetime = NumberRange.new(0.65, 1.15)
		spark.Speed = NumberRange.new(0.8, 1.8)
		spark.SpreadAngle = Vector2.new(40, 40)
		spark.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		spark.Parent = rootPart

		local light = Instance.new("PointLight")
		light.Name = COSMETIC_INSTANCES.light
		light.Color = Color3.fromRGB(255, 217, 112)
		light.Range = 8
		light.Brightness = 0.8
		light.Parent = rootPart
	end
end

local function applyAllCosmetics()
	for _, player in ipairs(Players:GetPlayers()) do
		applyCharacterCosmetics(player)
	end
	applyMidnightTheme(getEquippedForPlayer(localPlayer))
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

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = instance
	return corner
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

local function setPanelAccent(panel, enabled, activeColor)
	local stroke = getStroke(panel)
	if stroke then
		stroke.Color = if enabled then (activeColor or COLORS.activePanel) else COLORS.idlePanel
		stroke.Transparency = if enabled then 0.05 else 0.22
	end
	panel.BackgroundTransparency = if enabled then 0 else 0.08
end

local function setStatusChip(text, backgroundColor, strokeColor)
	statusChipLabel.Text = text
	updateCardVisual(statusChip, backgroundColor, strokeColor)
end

local function setStateLabel(label, text, isActive)
	label.Text = text
	label.TextColor3 = if isActive then COLORS.enabledText else COLORS.disabledText
	label.TextTransparency = if isActive then 0 else 0.15
end

local function setDigitSlotValues(slots, values, filledColor, emptyColor)
	for index, slot in ipairs(slots) do
		local digit = values[index]
		slot.BackgroundColor3 = if digit then filledColor else emptyColor

		local stroke = getStroke(slot)
		if stroke then
			stroke.Color = if digit then filledColor else COLORS.historyEntryBorder
			stroke.Transparency = if digit then 0.08 else 0.3
		end

		local label = slot:FindFirstChild("DigitLabel")
		if label and label:IsA("TextLabel") then
			label.Text = tostring(digit or "_")
			label.TextTransparency = if digit then 0 else 0.28
		end
	end
end

local function setMatchPresentationForMode()
	local higherLower = isHigherLowerMode()
	local copy = getModeCopy()

	modeUi.matchSubtitleLabel.Text = copy.matchSubtitle
	modeUi.secretHelpLabel.Text = copy.secretHelp
	modeUi.guessHelpLabel.Text = copy.guessHelp
	secretTextBox.PlaceholderText = copy.secretPlaceholder
	guessTextBox.PlaceholderText = copy.guessPlaceholder
	modeUi.historyHintLabel.Text = copy.historyHint
	modeUi.yourLockedCard.Visible = not higherLower
	modeUi.opponentLockedCard.Visible = not higherLower
	modeUi.highLowSummaryLabel.Visible = higherLower
	modeUi.highLowSummaryLabel.Text = copy.highLowSummary
end

local function setMenuPresentationForMode()
	local copy = getModeCopy()

	modeUi.menuSubtitleLabel.Text = copy.menuSubtitle
	modeUi.menuTagLabel.Text = copy.menuTag
	modeUi.menuHeadingLabel.Text = copy.menuHeading
	modeUi.menuBodyLabel.Text = copy.menuBody
	modeUi.menuInfoTextLabel.Text = copy.menuInfo
	modeUi.menuInfoFootnoteLabel.Text = copy.menuFootnote
	modeUi.howToPlayTextLabel.Text = copy.howToPlay
end

function setButtonEnabled(button, enabled)
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
	setPanelAccent(secretPanel, enabled, COLORS.activeSecretPanel)
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
	setPanelAccent(guessPanel, enabled, COLORS.activeGuessPanel)
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
	entry.Size = UDim2.new(1, -4, 0, 94)
	entry.BackgroundColor3 = COLORS.historyEntry
	entry.BorderSizePixel = 0
	entry.Parent = guessHistoryFrame

	updateCardVisual(entry, COLORS.historyEntry, COLORS.historyEntryBorder)
	addCorner(entry, 12)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.Parent = entry

	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "CountLabel"
	countLabel.Size = UDim2.fromOffset(78, 22)
	countLabel.BackgroundTransparency = 1
	countLabel.Font = Enum.Font.GothamBold
	countLabel.Text = "GUESS " .. tostring(guessHistoryCount)
	countLabel.TextColor3 = COLORS.disabledText
	countLabel.TextSize = 12
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	countLabel.Parent = entry

	local guessLabel = Instance.new("TextLabel")
	guessLabel.Name = "GuessLabel"
	guessLabel.Position = UDim2.fromOffset(0, 24)
	guessLabel.Size = UDim2.new(1, 0, 0, 28)
	guessLabel.BackgroundTransparency = 1
	guessLabel.Font = Enum.Font.GothamBlack
	guessLabel.Text = tostring(result.guess)
	guessLabel.TextColor3 = COLORS.enabledText
	guessLabel.TextSize = 24
	guessLabel.TextXAlignment = Enum.TextXAlignment.Left
	guessLabel.Parent = entry

	local feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "FeedbackLabel"
	feedbackLabel.Position = UDim2.fromOffset(0, 58)
	feedbackLabel.Size = UDim2.new(1, 0, 0, 22)
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.Font = Enum.Font.GothamBold
	feedbackLabel.Text = if result.feedback then "Feedback: " .. tostring(result.feedback) else "Locked: " .. formatLockedPositions(result.matches)
	feedbackLabel.TextColor3 = COLORS.disabledText
	feedbackLabel.TextSize = 15
	feedbackLabel.TextXAlignment = Enum.TextXAlignment.Left
	feedbackLabel.Parent = entry
end

local function resetRoundUi()
	setMatchPresentationForMode()
	hasSubmittedSecret = false
	isGameOver = false
	secretTextBox.Text = ""
	guessTextBox.Text = ""
	gameOverLabel.Text = ""
	clearValidationMessages()
	playerLockedLabel.Text = "Your code"
	opponentLockedLabel.Text = "Their code"
	turnLabel.Text = "Turn: waiting"
	setStatusChip("Waiting", COLORS.historyEntry, COLORS.historyEntryBorder)
	setStateLabel(secretStateLabel, "Waiting for round", false)
	setStateLabel(guessStateLabel, "Waiting for turn", false)
	setDigitSlotValues(playerLockedSlots, {}, Color3.fromRGB(52, 88, 72), Color3.fromRGB(31, 48, 42))
	setDigitSlotValues(opponentLockedSlots, {}, Color3.fromRGB(49, 84, 126), Color3.fromRGB(33, 44, 58))
	clearGuessHistory()
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
	setRestartControlsEnabled(false)
end

local function updateLockedLabels(roundState)
	setMatchPresentationForMode()
	if isHigherLowerMode() then
		return
	end

	local localPlayerId = localPlayer.UserId
	local opponentId = getOpponentId(roundState)
	local lockedPositionsByPlayerId = roundState.lockedPositionsByPlayerId or {}

	playerLockedLabel.Text = "Your code"
	opponentLockedLabel.Text = "Their code"
	setDigitSlotValues(
		playerLockedSlots,
		lockedPositionsByPlayerId[tostring(localPlayerId)] or {},
		Color3.fromRGB(52, 88, 72),
		Color3.fromRGB(31, 48, 42)
	)
	setDigitSlotValues(
		opponentLockedSlots,
		lockedPositionsByPlayerId[tostring(opponentId)] or {},
		Color3.fromRGB(49, 84, 126),
		Color3.fromRGB(33, 44, 58)
	)
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
		resultSubtitleLabel.Text = "Round complete."
		resultStatusLabel.Text = ""
		resultRewardLabel.Text = ""
		modeUi.resultYourSecretLabel.Text = "Your secret: -"
		modeUi.resultOpponentSecretLabel.Text = "Opponent secret: -"
		updateCardVisual(resultWinnerCard, COLORS.historyEntry, COLORS.historyEntryBorder)
		setRestartControlsEnabled(false)
		return
	end

	local copy = getModeCopy()
	local winnerId = roundState.winner
	if roundState.isTie or winnerId == TIE_WINNER then
		resultWinnerLabel.Text = "Result: Tie"
		resultSubtitleLabel.Text = copy.tieSubtitle
		updateCardVisual(resultWinnerCard, COLORS.resultTie, COLORS.historyEntryBorder)
	elseif winnerId == localPlayer.UserId then
		resultWinnerLabel.Text = "Winner: You"
		resultSubtitleLabel.Text = copy.youWonSubtitle
		updateCardVisual(resultWinnerCard, COLORS.resultWin, COLORS.readyPillBorder)
	elseif winnerId then
		resultWinnerLabel.Text = "Winner: Opponent"
		resultSubtitleLabel.Text = copy.opponentWonSubtitle
		updateCardVisual(resultWinnerCard, COLORS.resultLoss, Color3.fromRGB(208, 122, 122))
	else
		resultWinnerLabel.Text = "Winner: -"
		resultSubtitleLabel.Text = "Round complete."
		updateCardVisual(resultWinnerCard, COLORS.historyEntry, COLORS.historyEntryBorder)
	end

	local finalSecretsByPlayerId = roundState.finalSecretsByPlayerId or {}
	local opponentId = getOpponentId(roundState)
	modeUi.resultYourSecretLabel.Text = "Your secret: " .. tostring(finalSecretsByPlayerId[tostring(localPlayer.UserId)] or "-")
	modeUi.resultOpponentSecretLabel.Text = "Opponent secret: " .. tostring(finalSecretsByPlayerId[tostring(opponentId)] or "-")

	local reward = getLocalCurrencyValue(roundState, "latestRewardByPlayerId")
	resultRewardLabel.Text = if reward and reward > 0 then "+" .. tostring(reward) .. " coins earned" else ""

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
		local copy = getModeCopy()
		statusLabel.Text = copy.enterSecretStatus
		turnLabel.Text = "Turn: waiting"
		setStatusChip("Secret phase", COLORS.phaseSecret, COLORS.activeSecretPanel)
		setStateLabel(secretStateLabel, copy.secretActiveState, true)
		setStateLabel(guessStateLabel, copy.guessLockedState, false)
		setSecretControlsEnabled(canSubmitSecret(roundState) == true)
		setGuessControlsEnabled(false)
	elseif uiState == UI_STATES.WaitingForOpponentSecret then
		local copy = getModeCopy()
		statusLabel.Text = copy.waitingSecretStatus
		turnLabel.Text = "Turn: waiting"
		setStatusChip("Secret phase", COLORS.phaseSecret, COLORS.activeSecretPanel)
		setStateLabel(secretStateLabel, copy.secretSavedState, false)
		setStateLabel(guessStateLabel, copy.guessWaitingState, false)
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
	elseif uiState == UI_STATES.InTurn then
		local copy = getModeCopy()
		statusLabel.Text = "Your turn"
		turnLabel.Text = "Turn: you"
		setStatusChip("Guess phase", COLORS.phaseGuess, COLORS.activeGuessPanel)
		setStateLabel(secretStateLabel, copy.secretLockedState, false)
		setStateLabel(guessStateLabel, copy.guessActiveState, true)
		setSecretControlsEnabled(false)
		refreshGuessControls()
	elseif uiState == UI_STATES.OpponentTurn then
		local copy = getModeCopy()
		statusLabel.Text = "Opponent's turn"
		turnLabel.Text = if roundState and roundState.currentTurn then "Turn: opponent" else "Turn: waiting"
		setStatusChip("Guess phase", COLORS.phaseGuess, COLORS.activeGuessPanel)
		setStateLabel(secretStateLabel, copy.secretLockedState, false)
		setStateLabel(guessStateLabel, copy.guessOpponentState, false)
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
		setMenuPresentationForMode()
		setRestartControlsEnabled(false)
		updateLobby(latestLobbyState)
	elseif currentUiState == UI_STATES.ReadyUp then
		setCommercePanelsVisible(false, false)
		howToPlayPanel.Visible = false
		updateLobby(latestLobbyState)
		resetRoundUi()
	elseif isMatchUiState(currentUiState) then
		setCommercePanelsVisible(false, false)
		howToPlayPanel.Visible = false
		updateMatchForUiState(currentUiState, latestRoundState)
	elseif currentUiState == UI_STATES.GameOver then
		setCommercePanelsVisible(false, false)
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
	applyAllCosmetics()
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

	local serverBalance = getLocalCurrencyValue(roundState, "currencyBalanceByPlayerId")
	if serverBalance ~= nil then
		currencyBalance = serverBalance
		updateCurrencyHud()
	end

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

local function onCurrencyChanged(payload)
	currencyBalance = payload.balance or currencyBalance
	updateCurrencyHud(payload.delta or 0)
end

local function onShopOpened(shopState)
	howToPlayPanel.Visible = false
	setCommercePanelsVisible(true, false)
	updateShopPanel(shopState)
end

local function onShopStateChanged(shopState)
	updateShopPanel(shopState)
end

local function onCoinPacksOpened(coinPackState)
	howToPlayPanel.Visible = false
	setCommercePanelsVisible(false, false, false, true)
	updateCoinPacksPanel(coinPackState)
end

local function onCoinPackStateChanged(coinPackState)
	updateCoinPacksPanel(coinPackState)
end

local function onRewardsOpened(rewardState)
	howToPlayPanel.Visible = false
	setCommercePanelsVisible(false, true)
	updateRewardsPanel(rewardState)
end

local function onRewardStateChanged(rewardState)
	updateRewardsPanel(rewardState)
end

local function onLeaderboardOpened(leaderboardState)
	howToPlayPanel.Visible = false
	setCommercePanelsVisible(false, false, true)
	updateLeaderboardPanel(leaderboardState)
end

local function onLeaderboardStateChanged(leaderboardState)
	updateLeaderboardPanel(leaderboardState)
end

local function onModeStateChanged(modeState)
	modeUi.latestModeState = modeState or modeUi.latestModeState
	secretTextBox.Text = clampModeInput(secretTextBox.Text)
	guessTextBox.Text = clampModeInput(guessTextBox.Text)
	setMenuPresentationForMode()
	setMatchPresentationForMode()
	clearValidationMessages()
end

local function onCosmeticsStateChanged(cosmeticsState)
	modeUi.latestCosmeticsState = cosmeticsState
	applyAllCosmetics()
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
	if isValidModeInput(secretTextBox.Text) then
		setValidationMessage(secretValidationLabel, "")
	end
end)

guessTextBox:GetPropertyChangedSignal("Text"):Connect(function()
	if isValidModeInput(guessTextBox.Text) then
		setValidationMessage(guessValidationLabel, "")
	end
end)

local function submitSecret()
	if not secretControlsEnabled or isGameOver then
		return
	end

	local secret = secretTextBox.Text
	if not isValidModeInput(secret) then
		setValidationMessage(secretValidationLabel, getModeInputError())
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
	if not isValidModeInput(guess) then
		setValidationMessage(guessValidationLabel, getModeInputError())
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

local function onLobbyPromptTriggered(prompt)
	if not prompt then
		return
	end

	local modeId = prompt:GetAttribute("ModeId")
	if modeId then
		setCommercePanelsVisible(false, false, false, false)
		howToPlayPanel.Visible = false
		RemoteEvents.PlayModeRequested:FireServer(modeId)
	elseif prompt.Name == "ShopPrompt" then
		howToPlayPanel.Visible = false
		RemoteEvents.ShopOpenRequested:FireServer()
	elseif prompt.Name == "RewardsPrompt" then
		howToPlayPanel.Visible = false
		RemoteEvents.RewardsOpenRequested:FireServer()
	elseif prompt.Name == "LeaderboardPrompt" then
		howToPlayPanel.Visible = false
		RemoteEvents.LeaderboardOpenRequested:FireServer()
	end
end

guessHistoryList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	guessHistoryFrame.CanvasSize = UDim2.fromOffset(0, guessHistoryList.AbsoluteContentSize.Y + 12)
end)

for index = 1, 4 do
	modeUi.shopRows[index] = {
		frame = findUi(shopPanel, "ShopItemRow" .. tostring(index)),
		name = findUi(shopPanel, "ShopItemNameLabel" .. tostring(index)),
		meta = findUi(shopPanel, "ShopItemMetaLabel" .. tostring(index)),
		state = findUi(shopPanel, "ShopItemStateLabel" .. tostring(index)),
		buyButton = findUi(shopPanel, "ShopBuyButton" .. tostring(index)),
		equipButton = findUi(shopPanel, "ShopEquipButton" .. tostring(index)),
	}
end

modeUi.coinPackRows = {}
for index = 1, 3 do
	modeUi.coinPackRows[index] = {
		frame = findUi(modeUi.coinPacksPanel, "CoinPackRow" .. tostring(index)),
		name = findUi(modeUi.coinPacksPanel, "CoinPackNameLabel" .. tostring(index)),
		description = findUi(modeUi.coinPacksPanel, "CoinPackDescriptionLabel" .. tostring(index)),
		amount = findUi(modeUi.coinPacksPanel, "CoinPackAmountLabel" .. tostring(index)),
		button = findUi(modeUi.coinPacksPanel, "CoinPackBuyButton" .. tostring(index)),
	}
end

for index = 1, 6 do
	modeUi.leaderboardRows[index] = {
		frame = findUi(leaderboardPanel, "LeaderboardRow" .. tostring(index)),
		rank = findUi(leaderboardPanel, "LeaderboardRankLabel" .. tostring(index)),
		name = findUi(leaderboardPanel, "LeaderboardNameLabel" .. tostring(index)),
		wins = findUi(leaderboardPanel, "LeaderboardWinsLabel" .. tostring(index)),
		streak = findUi(leaderboardPanel, "LeaderboardStreakLabel" .. tostring(index)),
		coins = findUi(leaderboardPanel, "LeaderboardCoinsLabel" .. tostring(index)),
	}
end

for _, descendant in ipairs(devGui:GetDescendants()) do
	if descendant:IsA("TextButton") then
		wireButtonInteractions(descendant)
	end
end

setSecretControlsEnabled(false)
setGuessControlsEnabled(false)
setRestartControlsEnabled(false)
updateCurrencyHud(0)
bindModeInput(secretTextBox)
bindModeInput(guessTextBox)
setUiState(UI_STATES.LobbyWorld)

playButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false)
	howToPlayPanel.Visible = false
	RemoteEvents.LobbyEntered:FireServer()
	setUiState(UI_STATES.ReadyUp)
end)

menuBackButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false, false)
	howToPlayPanel.Visible = false
	clearValidationMessages()
	resetRoundUi()
	setUiState(UI_STATES.LobbyWorld)
end)

howToPlayButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false)
	howToPlayPanel.Visible = not howToPlayPanel.Visible
end)

closeHowToPlayButton.MouseButton1Click:Connect(function()
	howToPlayPanel.Visible = false
end)

closeShopButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false)
end)

modeUi.openCoinPacksButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false, true)
	updateCoinPacksPanel()
	RemoteEvents.CoinPacksOpenRequested:FireServer()
end)

modeUi.buyCoinsHudButton.MouseButton1Click:Connect(function()
	howToPlayPanel.Visible = false
	setCommercePanelsVisible(false, false, false, true)
	updateCoinPacksPanel()
	RemoteEvents.CoinPacksOpenRequested:FireServer()
end)

modeUi.closeCoinPacksButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false, false)
end)

closeRewardsButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false)
end)

closeLeaderboardButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false)
end)

for _, row in ipairs(modeUi.shopRows) do
	row.buyButton.MouseButton1Click:Connect(function()
		local itemId = row.frame:GetAttribute("ItemId")
		if itemId then
			shopStatusLabel.Text = "Buying..."
			RemoteEvents.ShopPurchaseRequested:FireServer(itemId)
		end
	end)
	row.equipButton.MouseButton1Click:Connect(function()
		local itemId = row.frame:GetAttribute("ItemId")
		if itemId then
			shopStatusLabel.Text = "Equipping..."
			RemoteEvents.ShopEquipRequested:FireServer(itemId)
		end
	end)
end

for _, row in ipairs(modeUi.coinPackRows) do
	row.button.MouseButton1Click:Connect(function()
		local packId = row.frame:GetAttribute("PackId")
		if packId then
			modeUi.coinPacksStatusLabel.Text = "Opening Roblox purchase prompt..."
			setButtonEnabled(row.button, false)
			RemoteEvents.CoinPackPurchaseRequested:FireServer(packId)
		end
	end)
end

claimRewardButton.MouseButton1Click:Connect(function()
	rewardsStatusLabel.Text = "Claiming..."
	setButtonEnabled(claimRewardButton, false)
	RemoteEvents.RewardClaimRequested:FireServer()
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
modeUi.promptService.PromptTriggered:Connect(onLobbyPromptTriggered)

RemoteEvents.SecretRequested.OnClientEvent:Connect(onSecretRequested)
RemoteEvents.TurnChanged.OnClientEvent:Connect(onTurnChanged)
RemoteEvents.GuessResult.OnClientEvent:Connect(onGuessResult)
RemoteEvents.GameOver.OnClientEvent:Connect(showGameOver)
RemoteEvents.RoundStateChanged.OnClientEvent:Connect(onRoundStateChanged)
RemoteEvents.LobbyStateChanged.OnClientEvent:Connect(onLobbyStateChanged)
RemoteEvents.CurrencyChanged.OnClientEvent:Connect(onCurrencyChanged)
RemoteEvents.ShopOpened.OnClientEvent:Connect(onShopOpened)
RemoteEvents.ShopStateChanged.OnClientEvent:Connect(onShopStateChanged)
RemoteEvents.CoinPacksOpened.OnClientEvent:Connect(onCoinPacksOpened)
RemoteEvents.CoinPackStateChanged.OnClientEvent:Connect(onCoinPackStateChanged)
RemoteEvents.RewardsOpened.OnClientEvent:Connect(onRewardsOpened)
RemoteEvents.RewardStateChanged.OnClientEvent:Connect(onRewardStateChanged)
RemoteEvents.LeaderboardOpened.OnClientEvent:Connect(onLeaderboardOpened)
RemoteEvents.LeaderboardStateChanged.OnClientEvent:Connect(onLeaderboardStateChanged)
RemoteEvents.ModeStateChanged.OnClientEvent:Connect(onModeStateChanged)
RemoteEvents.CosmeticsStateChanged.OnClientEvent:Connect(onCosmeticsStateChanged)
RemoteEvents.LobbyFlowStateChanged.OnClientEvent:Connect(onLobbyFlowStateChanged)
RemoteEvents.CosmeticsStateRequested:FireServer()


for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function()
		task.defer(applyAllCosmetics)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.defer(applyAllCosmetics)
	end)
end)
