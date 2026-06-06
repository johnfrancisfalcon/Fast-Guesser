local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = script.Parent
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ModeCopy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModeCopy"))
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

local UI_THEME_IDS = {
	Default = "default",
	Midnight = "theme_midnight",
}

local UI_THEMES = {
	[UI_THEME_IDS.Default] = {
		background = {
			start = Color3.fromRGB(8, 13, 22),
			finish = Color3.fromRGB(14, 22, 34),
		},
		surfaces = {
			shell = { background = Color3.fromRGB(20, 29, 43), gradient = Color3.fromRGB(25, 35, 50), stroke = Color3.fromRGB(58, 77, 101), strokeTransparency = 0.08 },
			panel = { background = Color3.fromRGB(32, 44, 60), gradient = Color3.fromRGB(24, 34, 48), stroke = Color3.fromRGB(58, 77, 101), strokeTransparency = 0.15 },
			panelAlt = { background = Color3.fromRGB(24, 34, 48), gradient = Color3.fromRGB(24, 34, 46), stroke = Color3.fromRGB(58, 77, 101), strokeTransparency = 0.15 },
			panelStrong = { background = Color3.fromRGB(39, 54, 74), gradient = Color3.fromRGB(24, 34, 48), stroke = Color3.fromRGB(85, 108, 136), strokeTransparency = 0.12 },
			panelRaised = { background = Color3.fromRGB(49, 68, 92), gradient = Color3.fromRGB(24, 34, 48), stroke = Color3.fromRGB(85, 108, 136), strokeTransparency = 0.12 },
			success = { background = Color3.fromRGB(37, 116, 78), gradient = Color3.fromRGB(24, 80, 58), stroke = Color3.fromRGB(84, 207, 144), strokeTransparency = 0.12 },
			hud = { background = Color3.fromRGB(39, 54, 74), gradient = Color3.fromRGB(24, 34, 48), stroke = Color3.fromRGB(255, 211, 105), strokeTransparency = 0.14 },
		},
		buttons = {
			Primary = {
				background = Color3.fromRGB(78, 149, 245),
				hover = Color3.fromRGB(98, 169, 255),
				pressed = Color3.fromRGB(60, 121, 210),
				disabled = Color3.fromRGB(70, 81, 95),
				text = Color3.fromRGB(241, 246, 255),
				disabledText = Color3.fromRGB(148, 159, 174),
				stroke = Color3.fromRGB(85, 162, 255),
			},
			Secondary = {
				background = Color3.fromRGB(49, 68, 92),
				hover = Color3.fromRGB(63, 86, 114),
				pressed = Color3.fromRGB(51, 70, 94),
				disabled = Color3.fromRGB(70, 81, 95),
				text = Color3.fromRGB(241, 246, 255),
				disabledText = Color3.fromRGB(148, 159, 174),
				stroke = Color3.fromRGB(85, 108, 136),
			},
		},
		input = {
			enabledBackground = Color3.fromRGB(248, 250, 252),
			disabledBackground = Color3.fromRGB(198, 204, 212),
			enabledStroke = Color3.fromRGB(44, 94, 162),
			disabledStroke = Color3.fromRGB(78, 86, 96),
			text = Color3.fromRGB(18, 25, 36),
			disabledText = Color3.fromRGB(116, 126, 140),
		},
		text = {
			default = Color3.fromRGB(241, 246, 255),
			muted = Color3.fromRGB(166, 183, 205),
			accent = Color3.fromRGB(85, 162, 255),
			warning = Color3.fromRGB(240, 193, 100),
			coin = Color3.fromRGB(255, 211, 105),
			success = Color3.fromRGB(83, 190, 132),
		},
		accents = {
			primary = Color3.fromRGB(85, 162, 255),
			secondary = Color3.fromRGB(84, 207, 144),
			glowStart = Color3.fromRGB(85, 162, 255),
			glowFinish = Color3.fromRGB(84, 207, 144),
		},
		overlay = {
			color = Color3.fromRGB(0, 0, 0),
			transparency = 0.34,
		},
		scrollBar = Color3.fromRGB(85, 162, 255),
		strokeTint = Color3.fromRGB(85, 162, 255),
		successTint = Color3.fromRGB(83, 190, 132),
		semantic = {
			historyEntry = COLORS.historyEntry,
			historyEntryAlt = COLORS.historyEntryAlt,
			historyEntryBorder = COLORS.historyEntryBorder,
			localCard = COLORS.localCard,
			localCardBorder = COLORS.localCardBorder,
			opponentCard = COLORS.opponentCard,
			opponentCardBorder = COLORS.opponentCardBorder,
			waitingCard = COLORS.waitingCard,
			waitingCardBorder = COLORS.waitingCardBorder,
			readyPill = COLORS.readyPill,
			readyPillBorder = COLORS.readyPillBorder,
			idlePill = COLORS.idlePill,
			idlePillBorder = COLORS.idlePillBorder,
			activePanel = COLORS.activePanel,
			idlePanel = COLORS.idlePanel,
			activeSecretPanel = COLORS.activeSecretPanel,
			activeGuessPanel = COLORS.activeGuessPanel,
			phaseSecret = COLORS.phaseSecret,
			phaseGuess = COLORS.phaseGuess,
			resultWin = COLORS.resultWin,
			resultLoss = COLORS.resultLoss,
			resultTie = COLORS.resultTie,
			playerLockedFilled = Color3.fromRGB(52, 88, 72),
			playerLockedEmpty = Color3.fromRGB(31, 48, 42),
			opponentLockedFilled = Color3.fromRGB(49, 84, 126),
			opponentLockedEmpty = Color3.fromRGB(33, 44, 58),
			resultLossBorder = Color3.fromRGB(208, 122, 122),
		},
	}
}

UI_THEMES[UI_THEME_IDS.Midnight] = {
	background = {
		start = Color3.fromRGB(4, 6, 18),
		finish = Color3.fromRGB(28, 16, 54),
	},
	surfaces = {
		shell = { background = Color3.fromRGB(12, 11, 34), gradient = Color3.fromRGB(27, 17, 62), stroke = Color3.fromRGB(142, 113, 255), strokeTransparency = 0 },
		panel = { background = Color3.fromRGB(17, 17, 44), gradient = Color3.fromRGB(10, 11, 32), stroke = Color3.fromRGB(120, 95, 226), strokeTransparency = 0.03 },
		panelAlt = { background = Color3.fromRGB(13, 14, 38), gradient = Color3.fromRGB(9, 10, 28), stroke = Color3.fromRGB(97, 80, 191), strokeTransparency = 0.04 },
		panelStrong = { background = Color3.fromRGB(25, 23, 62), gradient = Color3.fromRGB(12, 11, 35), stroke = Color3.fromRGB(160, 131, 255), strokeTransparency = 0.01 },
		panelRaised = { background = Color3.fromRGB(36, 31, 81), gradient = Color3.fromRGB(18, 17, 48), stroke = Color3.fromRGB(177, 148, 255), strokeTransparency = 0.01 },
		success = { background = Color3.fromRGB(20, 64, 92), gradient = Color3.fromRGB(14, 34, 58), stroke = Color3.fromRGB(100, 225, 255), strokeTransparency = 0.03 },
		hud = { background = Color3.fromRGB(28, 22, 72), gradient = Color3.fromRGB(14, 12, 44), stroke = Color3.fromRGB(196, 166, 255), strokeTransparency = 0.01 },
	},
	buttons = {
		Primary = {
			background = Color3.fromRGB(104, 80, 236),
			hover = Color3.fromRGB(135, 112, 255),
			pressed = Color3.fromRGB(80, 59, 192),
			disabled = Color3.fromRGB(56, 56, 84),
			text = Color3.fromRGB(247, 244, 255),
			disabledText = Color3.fromRGB(161, 160, 190),
			stroke = Color3.fromRGB(186, 158, 255),
		},
		Secondary = {
			background = Color3.fromRGB(31, 34, 74),
			hover = Color3.fromRGB(45, 49, 96),
			pressed = Color3.fromRGB(24, 27, 61),
			disabled = Color3.fromRGB(56, 56, 84),
			text = Color3.fromRGB(238, 241, 255),
			disabledText = Color3.fromRGB(161, 160, 190),
			stroke = Color3.fromRGB(130, 113, 210),
		},
	},
	input = {
		enabledBackground = Color3.fromRGB(232, 236, 255),
		disabledBackground = Color3.fromRGB(160, 166, 192),
		enabledStroke = Color3.fromRGB(108, 92, 206),
		disabledStroke = Color3.fromRGB(84, 88, 122),
		text = Color3.fromRGB(17, 18, 40),
		disabledText = Color3.fromRGB(96, 102, 134),
	},
	text = {
		default = Color3.fromRGB(245, 244, 255),
		muted = Color3.fromRGB(201, 200, 231),
		accent = Color3.fromRGB(188, 163, 255),
		warning = Color3.fromRGB(255, 205, 127),
		coin = Color3.fromRGB(255, 223, 138),
		success = Color3.fromRGB(111, 229, 239),
	},
	accents = {
		primary = Color3.fromRGB(186, 158, 255),
		secondary = Color3.fromRGB(94, 228, 255),
		glowStart = Color3.fromRGB(138, 100, 255),
		glowFinish = Color3.fromRGB(80, 207, 255),
	},
	overlay = {
		color = Color3.fromRGB(2, 0, 10),
		transparency = 0.18,
	},
	scrollBar = Color3.fromRGB(166, 146, 255),
	strokeTint = Color3.fromRGB(170, 145, 255),
	successTint = Color3.fromRGB(111, 229, 239),
	semantic = {
		historyEntry = Color3.fromRGB(18, 17, 47),
		historyEntryAlt = Color3.fromRGB(11, 11, 31),
		historyEntryBorder = Color3.fromRGB(131, 107, 222),
		localCard = Color3.fromRGB(42, 28, 86),
		localCardBorder = Color3.fromRGB(189, 159, 255),
		opponentCard = Color3.fromRGB(20, 57, 76),
		opponentCardBorder = Color3.fromRGB(98, 224, 255),
		waitingCard = Color3.fromRGB(19, 20, 44),
		waitingCardBorder = Color3.fromRGB(101, 90, 170),
		readyPill = Color3.fromRGB(48, 28, 88),
		readyPillBorder = Color3.fromRGB(180, 143, 255),
		idlePill = Color3.fromRGB(24, 26, 55),
		idlePillBorder = Color3.fromRGB(110, 104, 176),
		activePanel = Color3.fromRGB(176, 146, 255),
		idlePanel = Color3.fromRGB(86, 74, 148),
		activeSecretPanel = Color3.fromRGB(168, 122, 255),
		activeGuessPanel = Color3.fromRGB(88, 214, 255),
		phaseSecret = Color3.fromRGB(72, 44, 124),
		phaseGuess = Color3.fromRGB(22, 88, 118),
		resultWin = Color3.fromRGB(25, 82, 105),
		resultLoss = Color3.fromRGB(80, 36, 78),
		resultTie = Color3.fromRGB(86, 62, 32),
		playerLockedFilled = Color3.fromRGB(72, 40, 128),
		playerLockedEmpty = Color3.fromRGB(21, 16, 42),
		opponentLockedFilled = Color3.fromRGB(28, 88, 116),
		opponentLockedEmpty = Color3.fromRGB(17, 22, 43),
		resultLossBorder = Color3.fromRGB(228, 122, 220),
	},
}

local currentUiThemeId = UI_THEME_IDS.Default
local themedSurfaces = {}
local themedButtons = {}
local themedInputs = {}
local themedTexts = {}
local themedAccents = {}
local themedOverlays = {}
local themedScrollFrames = {}

local devGui = GuiBuilder.getOrCreate(playerGui)
local ui = {
	mode = {},
}

local function findUi(parent, name)
	local instance = parent:FindFirstChild(name, true)
	assert(instance, "Missing Fast Guesser UI element: " .. name)
	return instance
end

do
	ui.background = devGui:WaitForChild("Background")
	ui.menuScreen = devGui:WaitForChild("MenuScreen")
	ui.lobbyScreen = devGui:WaitForChild("LobbyScreen")
	ui.matchScreen = devGui:WaitForChild("MatchScreen")
	ui.resultScreen = devGui:WaitForChild("ResultScreen")
	ui.currencyHud = devGui:WaitForChild("CurrencyHud")
	ui.shopPanel = devGui:WaitForChild("ShopPanel")
	ui.rewardsPanel = devGui:WaitForChild("RewardsPanel")
	ui.leaderboardPanel = devGui:WaitForChild("LeaderboardPanel")

	ui.playButton = findUi(ui.menuScreen, "PlayButton")
	ui.menuBackButton = findUi(ui.menuScreen, "MenuBackButton")
	ui.howToPlayButton = findUi(ui.menuScreen, "HowToPlayButton")
	ui.howToPlayPanel = findUi(ui.menuScreen, "HowToPlayPanel")
	ui.closeHowToPlayButton = findUi(ui.menuScreen, "CloseHowToPlayButton")

	ui.lobbyStatusLabel = findUi(ui.lobbyScreen, "LobbyStatusLabel")
	ui.playerOneRow = findUi(ui.lobbyScreen, "PlayerOneRow")
	ui.playerTwoRow = findUi(ui.lobbyScreen, "PlayerTwoRow")
	ui.playerOneSlotLabel = findUi(ui.lobbyScreen, "PlayerOneSlotLabel")
	ui.playerOneReadyLabel = findUi(ui.lobbyScreen, "PlayerOneReadyLabel")
	ui.playerOneReadyPill = findUi(ui.lobbyScreen, "PlayerOneRowReadyPill")
	ui.playerTwoSlotLabel = findUi(ui.lobbyScreen, "PlayerTwoSlotLabel")
	ui.playerTwoReadyLabel = findUi(ui.lobbyScreen, "PlayerTwoReadyLabel")
	ui.playerTwoReadyPill = findUi(ui.lobbyScreen, "PlayerTwoRowReadyPill")
	ui.readyButton = findUi(ui.lobbyScreen, "ReadyButton")
	ui.lobbyBackButton = findUi(ui.lobbyScreen, "LobbyBackButton")

	ui.statusLabel = findUi(ui.matchScreen, "StatusLabel")
	ui.secretPanel = findUi(ui.matchScreen, "SecretPanel")
	ui.secretTextBox = findUi(ui.matchScreen, "SecretTextBox")
	ui.submitSecretButton = findUi(ui.matchScreen, "SubmitSecretButton")
	ui.secretValidationLabel = findUi(ui.matchScreen, "SecretValidationLabel")
	ui.guessPanel = findUi(ui.matchScreen, "GuessPanel")
	ui.guessTextBox = findUi(ui.matchScreen, "GuessTextBox")
	ui.submitGuessButton = findUi(ui.matchScreen, "SubmitGuessButton")
	ui.guessValidationLabel = findUi(ui.matchScreen, "GuessValidationLabel")
	ui.playerLockedLabel = findUi(ui.matchScreen, "PlayerLockedLabel")
	ui.opponentLockedLabel = findUi(ui.matchScreen, "OpponentLockedLabel")
	ui.turnLabel = findUi(ui.matchScreen, "TurnLabel")
	ui.statusChip = findUi(ui.matchScreen, "StatusInfoChip")
	ui.statusChipLabel = findUi(ui.matchScreen, "StatusChipLabel")
	ui.gameOverLabel = findUi(ui.matchScreen, "GameOverLabel")
	ui.restartButton = findUi(ui.matchScreen, "RestartButton")
	ui.guessHistoryFrame = findUi(ui.matchScreen, "GuessHistoryFrame")
	ui.guessHistoryList = ui.guessHistoryFrame:WaitForChild("GuessHistoryList")
	ui.secretStateLabel = findUi(ui.matchScreen, "SecretStateLabel")
	ui.guessStateLabel = findUi(ui.matchScreen, "GuessStateLabel")
	ui.playerLockedSlots = {
		findUi(ui.matchScreen, "PlayerLockedSlot1"),
		findUi(ui.matchScreen, "PlayerLockedSlot2"),
		findUi(ui.matchScreen, "PlayerLockedSlot3"),
		findUi(ui.matchScreen, "PlayerLockedSlot4"),
	}
	ui.opponentLockedSlots = {
		findUi(ui.matchScreen, "OpponentLockedSlot1"),
		findUi(ui.matchScreen, "OpponentLockedSlot2"),
		findUi(ui.matchScreen, "OpponentLockedSlot3"),
		findUi(ui.matchScreen, "OpponentLockedSlot4"),
	}

	ui.resultWinnerLabel = findUi(ui.resultScreen, "ResultWinnerLabel")
	ui.resultSubtitleLabel = findUi(ui.resultScreen, "ResultSubtitleLabel")
	ui.resultWinnerCard = findUi(ui.resultScreen, "ResultWinnerCard")
	ui.resultStatusLabel = findUi(ui.resultScreen, "ResultStatusLabel")
	ui.resultPlayAgainButton = findUi(ui.resultScreen, "ResultPlayAgainButton")
	ui.backToMenuButton = findUi(ui.resultScreen, "BackToMenuButton")
	ui.resultRewardLabel = findUi(ui.resultScreen, "ResultRewardLabel")
	ui.currencyAmountLabel = findUi(ui.currencyHud, "CurrencyAmountLabel")
	ui.currencyDeltaLabel = findUi(ui.currencyHud, "CurrencyDeltaLabel")
	ui.closeShopButton = findUi(ui.shopPanel, "CloseShopButton")
	ui.shopBalanceLabel = findUi(ui.shopPanel, "ShopBalanceLabel")
	ui.shopStatusLabel = findUi(ui.shopPanel, "ShopStatusLabel")
	ui.closeRewardsButton = findUi(ui.rewardsPanel, "CloseRewardsButton")
	ui.rewardsBalanceLabel = findUi(ui.rewardsPanel, "RewardsBalanceLabel")
	ui.rewardsStatusLabel = findUi(ui.rewardsPanel, "RewardsStatusLabel")
	ui.rewardTitleLabel = findUi(ui.rewardsPanel, "RewardTitleLabel")
	ui.rewardBodyLabel = findUi(ui.rewardsPanel, "RewardBodyLabel")
	ui.rewardAmountLabel = findUi(ui.rewardsPanel, "RewardAmountLabel")
	ui.claimRewardButton = findUi(ui.rewardsPanel, "ClaimRewardButton")
	ui.rewardWheelBodyLabel = findUi(ui.rewardsPanel, "RewardWheelBodyLabel")
	ui.closeLeaderboardButton = findUi(ui.leaderboardPanel, "CloseLeaderboardButton")
	ui.leaderboardStatusLabel = findUi(ui.leaderboardPanel, "LeaderboardStatusLabel")
	ui.leaderboardEmptyLabel = findUi(ui.leaderboardPanel, "LeaderboardEmptyLabel")

	ui.mode.menuSubtitleLabel = findUi(ui.menuScreen, "SubtitleLabel")
	ui.mode.menuTagLabel = findUi(ui.menuScreen, "MenuTagLabel")
	ui.mode.menuHeadingLabel = findUi(ui.menuScreen, "MenuHeadingLabel")
	ui.mode.menuBodyLabel = findUi(ui.menuScreen, "MenuBodyLabel")
	ui.mode.menuInfoTextLabel = findUi(ui.menuScreen, "MenuInfoTextLabel")
	ui.mode.menuInfoFootnoteLabel = findUi(ui.menuScreen, "MenuInfoFootnoteLabel")
	ui.mode.howToPlayTextLabel = findUi(ui.menuScreen, "HowToPlayTextLabel")
	ui.mode.matchSubtitleLabel = findUi(ui.matchScreen, "SubtitleLabel")
	ui.mode.secretHelpLabel = findUi(ui.matchScreen, "SecretHelpLabel")
	ui.mode.guessHelpLabel = findUi(ui.matchScreen, "GuessHelpLabel")
	ui.mode.yourLockedCard = findUi(ui.matchScreen, "YourLockedCard")
	ui.mode.opponentLockedCard = findUi(ui.matchScreen, "OpponentLockedCard")
	ui.mode.highLowSummaryLabel = findUi(ui.matchScreen, "HighLowSummaryLabel")
	ui.mode.historyHintLabel = findUi(ui.matchScreen, "HistoryHintLabel")
	ui.mode.resultYourSecretLabel = findUi(ui.resultScreen, "ResultYourSecretLabel")
	ui.mode.resultOpponentSecretLabel = findUi(ui.resultScreen, "ResultOpponentSecretLabel")
	ui.mode.buyCoinsHudButton = findUi(ui.currencyHud, "BuyCoinsHudButton")
	ui.mode.coinPacksPanel = devGui:WaitForChild("CoinPacksPanel")
	ui.mode.openCoinPacksButton = findUi(ui.shopPanel, "OpenCoinPacksButton")
	ui.mode.closeCoinPacksButton = findUi(ui.mode.coinPacksPanel, "CloseCoinPacksButton")
	ui.mode.coinPacksBalanceLabel = findUi(ui.mode.coinPacksPanel, "CoinPacksBalanceLabel")
	ui.mode.coinPacksStatusLabel = findUi(ui.mode.coinPacksPanel, "CoinPacksStatusLabel")
	ui.mode.rewardNextClaimLabel = findUi(ui.rewardsPanel, "RewardNextClaimLabel")
	ui.mode.promptService = game:GetService("ProximityPromptService")
	ui.mode.shopRows = {}
	ui.mode.leaderboardRows = {}
end

local modeUi = ui.mode

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
local getUiTheme
local themeSurfaceColor
local themeStrokeColor
local registerThemeSurface
local registerThemeButton
local registerThemeInput
local registerThemeText
local registerThemeAccent
local registerThemeOverlay
local registerThemeScrollFrame
local getButtonVisualState
local applyUiTheme
local getEquippedForPlayer

local function initializeUiThemeBindings()
	local shells = {
		findUi(ui.menuScreen, "MenuShell"),
		findUi(ui.lobbyScreen, "LobbyShell"),
		findUi(ui.matchScreen, "MatchShell"),
		findUi(ui.resultScreen, "ResultShell"),
		findUi(ui.menuScreen, "HowToPlayModal"),
		findUi(ui.shopPanel, "ShopModal"),
		findUi(modeUi.coinPacksPanel, "CoinPacksModal"),
		findUi(ui.rewardsPanel, "RewardsModal"),
		findUi(ui.leaderboardPanel, "LeaderboardModal"),
	}
	for _, instance in ipairs(shells) do
		registerThemeSurface(instance, "shell")
	end

	local strongPanels = {
		findUi(ui.menuScreen, "MenuHeroCard"),
		findUi(ui.lobbyScreen, "LobbyPanel"),
		findUi(ui.matchScreen, "StatusPanel"),
		findUi(ui.resultScreen, "ResultPanel"),
		findUi(ui.rewardsPanel, "RewardClaimCard"),
	}
	for _, instance in ipairs(strongPanels) do
		registerThemeSurface(instance, "panelStrong")
	end

	local regularPanels = {
		findUi(ui.matchScreen, "SecretPanel"),
		findUi(ui.matchScreen, "LockedPanel"),
		findUi(ui.matchScreen, "HistoryPanel"),
		findUi(ui.resultScreen, "ResultSecretsCard"),
		findUi(ui.shopPanel, "ShopFooter"),
		findUi(modeUi.coinPacksPanel, "CoinPacksFooter"),
	}
	for _, instance in ipairs(regularPanels) do
		registerThemeSurface(instance, "panel")
	end

	local alternatePanels = {
		findUi(ui.menuScreen, "MenuInfoCard"),
		findUi(ui.matchScreen, "OpponentLockedCard"),
		findUi(ui.matchScreen, "GuessHistoryFrame"),
		findUi(ui.rewardsPanel, "RewardWheelCard"),
		findUi(ui.leaderboardPanel, "LeaderboardHeaderRow"),
	}
	for _, instance in ipairs(alternatePanels) do
		registerThemeSurface(instance, "panelAlt")
	end

	local raisedPanels = {
		findUi(ui.matchScreen, "GuessPanel"),
		ui.currencyHud,
	}
	for _, instance in ipairs(raisedPanels) do
		registerThemeSurface(instance, if instance == ui.currencyHud then "hud" else "panelRaised")
	end

	registerThemeSurface(findUi(ui.matchScreen, "YourLockedCard"), "success")

	for index = 1, 4 do
		registerThemeSurface(findUi(ui.shopPanel, "ShopItemRow" .. tostring(index)), "panelAlt")
	end

	for index = 1, 3 do
		registerThemeSurface(findUi(modeUi.coinPacksPanel, "CoinPackRow" .. tostring(index)), "panelAlt")
	end

	for index = 1, 5 do
		registerThemeSurface(findUi(ui.rewardsPanel, "RewardWheelSegment" .. tostring(index)), "panelRaised")
	end

	for index = 1, 6 do
		registerThemeSurface(findUi(ui.leaderboardPanel, "LeaderboardRow" .. tostring(index)), "panelAlt")
	end

	local accentGroups = {
		{ instance = findUi(ui.menuScreen, "TitleLabel"), role = "accent" },
		{ instance = findUi(ui.lobbyScreen, "TitleLabel"), role = "accent" },
		{ instance = findUi(ui.matchScreen, "TitleLabel"), role = "accent" },
		{ instance = findUi(ui.resultScreen, "TitleLabel"), role = "accent" },
		{ instance = ui.background:FindFirstChild("TopHalo"), role = "primary" },
		{ instance = ui.background:FindFirstChild("BottomHalo"), role = "secondary" },
		{ instance = findUi(ui.menuScreen, "HeaderGlow"), role = "glow" },
		{ instance = findUi(ui.lobbyScreen, "HeaderGlow"), role = "glow" },
		{ instance = findUi(ui.matchScreen, "HeaderGlow"), role = "glow" },
		{ instance = findUi(ui.resultScreen, "HeaderGlow"), role = "glow" },
		{ instance = ui.playerOneRow:FindFirstChild("AccentBar"), role = "primary" },
		{ instance = ui.playerTwoRow:FindFirstChild("AccentBar"), role = "secondary" },
		{ instance = findUi(ui.matchScreen, "StatusRibbon"), role = "glow" },
	}
	for _, entry in ipairs(accentGroups) do
		if entry.instance then
			registerThemeAccent(entry.instance, entry.role)
		end
	end

	local staticTextGroups = {
		{ instance = findUi(ui.menuScreen, "SubtitleLabel"), role = "muted" },
		{ instance = findUi(ui.lobbyScreen, "SubtitleLabel"), role = "muted" },
		{ instance = findUi(ui.matchScreen, "SubtitleLabel"), role = "muted" },
		{ instance = findUi(ui.resultScreen, "SubtitleLabel"), role = "muted" },
		{ instance = findUi(ui.menuScreen, "MenuTagLabel"), role = "warning" },
		{ instance = findUi(ui.currencyHud, "CurrencyTitleLabel"), role = "muted" },
		{ instance = ui.currencyAmountLabel, role = "coin" },
		{ instance = ui.rewardAmountLabel, role = "coin" },
		{ instance = ui.resultRewardLabel, role = "coin" },
	}
	for _, entry in ipairs(staticTextGroups) do
		registerThemeText(entry.instance, entry.role)
	end

	registerThemeOverlay(ui.howToPlayPanel, 0.34)
	registerThemeOverlay(ui.shopPanel)
	registerThemeOverlay(modeUi.coinPacksPanel)
	registerThemeOverlay(ui.rewardsPanel)
	registerThemeOverlay(ui.leaderboardPanel)

	registerThemeScrollFrame(ui.guessHistoryFrame)
	registerThemeInput(ui.secretTextBox)
	registerThemeInput(ui.guessTextBox)

	local secondaryButtons = {
		ui.menuBackButton,
		ui.howToPlayButton,
		ui.closeHowToPlayButton,
		ui.lobbyBackButton,
		ui.restartButton,
		ui.backToMenuButton,
		ui.closeShopButton,
		modeUi.openCoinPacksButton,
		modeUi.buyCoinsHudButton,
		modeUi.closeCoinPacksButton,
		ui.closeRewardsButton,
		ui.closeLeaderboardButton,
	}
	local secondaryLookup = {}
	for _, button in ipairs(secondaryButtons) do
		secondaryLookup[button] = true
	end

	for _, descendant in ipairs(devGui:GetDescendants()) do
		if descendant:IsA("TextButton") then
			registerThemeButton(descendant, if secondaryLookup[descendant] then "Secondary" else "Primary")
		end
	end
end

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
	return ModeCopy.get(getCurrentMode())
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
	ui.currencyAmountLabel.Text = tostring(currencyBalance)
	lastCurrencyDelta = delta or lastCurrencyDelta or 0
	ui.currencyAmountLabel.TextColor3 = getUiTheme().text.coin

	if lastCurrencyDelta > 0 then
		ui.currencyDeltaLabel.Text = "+" .. tostring(lastCurrencyDelta)
		ui.currencyDeltaLabel.TextColor3 = getUiTheme().text.success
	else
		ui.currencyDeltaLabel.Text = ""
	end
end

local function getLocalCurrencyValue(state, key)
	local valuesByPlayerId = state and state[key] or {}
	return valuesByPlayerId[tostring(localPlayer.UserId)]
end

local function setCommercePanelsVisible(shopVisible, rewardsVisible, leaderboardVisible, coinPacksVisible)
	ui.shopPanel.Visible = shopVisible == true
	ui.rewardsPanel.Visible = rewardsVisible == true
	ui.leaderboardPanel.Visible = leaderboardVisible == true
	modeUi.coinPacksPanel.Visible = coinPacksVisible == true
end

local function getEquippedItemIdByCategory(equippedItems, category)
	return equippedItems and equippedItems[category] or nil
end

local function updateShopPanel(shopState)
	modeUi.latestShopState = shopState or modeUi.latestShopState
	local state = modeUi.latestShopState
	ui.shopBalanceLabel.Text = "Coins: " .. tostring((state and state.balance) or currencyBalance)

	ui.shopStatusLabel.Text = (state and state.message) or "Select an item."

	local catalog = state and state.catalog or {}
	local ownedItems = state and state.ownedItems or {}
	local equippedItems = state and state.equippedItems or {}

	for index, row in ipairs(modeUi.shopRows) do
		local item = catalog[index]
		row.frame.Visible = item ~= nil
		if item then
			row.frame:SetAttribute("ItemId", item.id)
			row.name.Text = item.name
			row.meta.Text = item.category
			row.price.Text = tostring(item.price) .. " coins"
			local owned = ownedItems[item.id] == true
			local equipped = getEquippedItemIdByCategory(equippedItems, item.category) == item.id
			local stateText = if equipped then "Equipped" elseif owned then "Owned" else ""
			row.state.Visible = stateText ~= ""
			row.state.Text = stateText
			row.state.TextColor3 = if equipped then getUiTheme().text.success else getUiTheme().text.muted
			setButtonEnabled(row.buyButton, not owned)
			setButtonEnabled(row.equipButton, owned)
			row.buyButton.Text = if owned then "Owned" else "Buy"
			row.equipButton.Text = if equipped then "Unequip" else "Equip"
		end
	end

	applyUiTheme(getEquippedForPlayer(localPlayer))
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

	applyUiTheme(getEquippedForPlayer(localPlayer))
end

local function updateLeaderboardPanel(leaderboardState)
	modeUi.latestLeaderboardState = leaderboardState or modeUi.latestLeaderboardState
	local state = modeUi.latestLeaderboardState
	local entries = state and state.entries or {}
	ui.leaderboardStatusLabel.Text = (state and state.message) or "Session leaderboard"
	ui.leaderboardEmptyLabel.Visible = #entries == 0

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

	applyUiTheme(getEquippedForPlayer(localPlayer))
end

local function updateRewardsPanel(rewardState)
	modeUi.latestRewardState = rewardState or modeUi.latestRewardState
	local state = modeUi.latestRewardState
	ui.rewardsBalanceLabel.Text = "Coins: " .. tostring((state and state.balance) or currencyBalance)
	local claimAmount = (state and state.claimAmount) or 0
	local canClaim = state == nil or state.canClaim == true
	local claimed = state and state.claimed == true
	ui.rewardTitleLabel.Text = (state and state.title) or "Daily Coins"
	ui.rewardBodyLabel.Text = if canClaim
		then "Your daily coin reward is available now. Claiming updates your saved progression immediately."
		else "Today's daily reward is already claimed. Come back after the next UTC reset."
	ui.rewardAmountLabel.Text = "+" .. tostring(claimAmount) .. " coins"
	ui.claimRewardButton.Text = if canClaim then "Claim Daily Reward" else "Claimed Today"
	setButtonEnabled(ui.claimRewardButton, canClaim)
	modeUi.rewardNextClaimLabel.Text = (state and state.nextClaimText) or "Ready now"
	modeUi.rewardNextClaimLabel.TextColor3 = if canClaim then getUiTheme().text.success else getUiTheme().text.muted
	ui.rewardsStatusLabel.Text = if state and state.message then state.message elseif claimed then "Daily reward already claimed." else "Daily reward ready."
	ui.rewardWheelBodyLabel.Text = (state and state.wheelStatus) or "Prize wheel display is live in the lobby. Daily coins are available now."

	local segments = state and state.wheelSegments or {}
	for index = 1, 5 do
		local segment = findUi(ui.rewardsPanel, "RewardWheelSegment" .. tostring(index))
		local label = segment:FindFirstChild("RewardWheelSegmentLabel" .. tostring(index))
		local rewardSegment = segments[index]
		if label and label:IsA("TextLabel") then
			label.Text = rewardSegment and tostring(rewardSegment.label) or "-"
		end
	end

	applyUiTheme(getEquippedForPlayer(localPlayer))
end

local COSMETIC_INSTANCES = {
	trail = "FastGuesserCosmeticTrail",
	trailA = "FastGuesserCosmeticTrailA",
	trailB = "FastGuesserCosmeticTrailB",
	tag = "FastGuesserCosmeticTag",
	spark = "FastGuesserCosmeticSpark",
	light = "FastGuesserCosmeticLight",
}

getEquippedForPlayer = function(player)
	local equippedByPlayerId = modeUi.latestCosmeticsState and modeUi.latestCosmeticsState.equippedByPlayerId or {}
	local equippedItems = equippedByPlayerId[tostring(player.UserId)] or {}
	if player ~= localPlayer then
		return equippedItems
	end

	local localShopEquippedItems = modeUi.latestShopState and modeUi.latestShopState.equippedItems or nil
	if type(localShopEquippedItems) ~= "table" then
		return equippedItems
	end
	return localShopEquippedItems
end

local function destroyNamedChild(parent, childName)
	local child = parent and parent:FindFirstChild(childName)
	if child then
		child:Destroy()
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
	applyUiTheme(getEquippedForPlayer(localPlayer))
end

local function setValidationMessage(label, message)
	label.Text = message or ""
	label.TextColor3 = COLORS.errorText
end

local function clearValidationMessages()
	setValidationMessage(ui.secretValidationLabel, "")
	setValidationMessage(ui.guessValidationLabel, "")
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

local function lerpColor(fromColor, toColor, alpha)
	return Color3.new(
		fromColor.R + ((toColor.R - fromColor.R) * alpha),
		fromColor.G + ((toColor.G - fromColor.G) * alpha),
		fromColor.B + ((toColor.B - fromColor.B) * alpha)
	)
end

getUiTheme = function()
	return UI_THEMES[currentUiThemeId] or UI_THEMES[UI_THEME_IDS.Default]
end

local function isMidnightThemeEnabled()
	return currentUiThemeId == UI_THEME_IDS.Midnight
end

local function getSemanticThemeColor(key, fallback)
	local semantic = getUiTheme().semantic
	if semantic and semantic[key] then
		return semantic[key]
	end

	return fallback
end

themeSurfaceColor = function(color)
	if not isMidnightThemeEnabled() then
		return color
	end

	return lerpColor(lerpColor(color, Color3.fromRGB(12, 12, 30), 0.3), Color3.fromRGB(100, 82, 186), 0.14)
end

themeStrokeColor = function(color)
	if not isMidnightThemeEnabled() then
		return color
	end

	return lerpColor(color, getUiTheme().strokeTint, 0.38)
end

registerThemeSurface = function(instance, role)
	table.insert(themedSurfaces, {
		instance = instance,
		role = role,
	})
end

registerThemeButton = function(button, variant)
	table.insert(themedButtons, {
		instance = button,
		variant = variant,
	})
end

registerThemeInput = function(input)
	table.insert(themedInputs, input)
end

registerThemeText = function(label, role)
	table.insert(themedTexts, {
		instance = label,
		role = role,
	})
end

registerThemeAccent = function(instance, role)
	table.insert(themedAccents, {
		instance = instance,
		role = role,
	})
end

registerThemeOverlay = function(instance, transparencyOverride)
	table.insert(themedOverlays, {
		instance = instance,
		transparency = transparencyOverride,
	})
end

registerThemeScrollFrame = function(frame)
	table.insert(themedScrollFrames, frame)
end

getButtonVisualState = function(button)
	if not button.Active then
		return "disabled"
	end

	if button:GetAttribute("IsPressed") then
		return "pressed"
	end

	if button:GetAttribute("IsHovered") then
		return "hover"
	end

	return "default"
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

local function applySurfaceTheme(instance, role)
	local style = getUiTheme().surfaces[role]
	if not instance or not style then
		return
	end

	instance.BackgroundColor3 = style.background
	local stroke = getStroke(instance)
	if stroke then
		stroke.Color = style.stroke
		stroke.Transparency = style.strokeTransparency or 0.1
	end

	local gradient = getGradient(instance)
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, style.background),
			ColorSequenceKeypoint.new(1, style.gradient),
		})
	end
end

local function applyButtonTheme(button, variant)
	local palette = getUiTheme().buttons[variant]
	if not button or not palette then
		return
	end

	button:SetAttribute("EnabledBackgroundColor", palette.background)
	button:SetAttribute("HoverBackgroundColor", palette.hover)
	button:SetAttribute("PressedBackgroundColor", palette.pressed)
	button:SetAttribute("DisabledBackgroundColor", palette.disabled)
	button:SetAttribute("EnabledTextColor", palette.text)
	button:SetAttribute("DisabledTextColor", palette.disabledText)
	button:SetAttribute("StrokeColor", palette.stroke)
	applyButtonVisual(button, getButtonVisualState(button))
end

local function applyInputTheme(input)
	local theme = getUiTheme()
	if not input then
		return
	end

	input:SetAttribute("EnabledBackgroundColor", theme.input.enabledBackground)
	input:SetAttribute("DisabledBackgroundColor", theme.input.disabledBackground)
	input:SetAttribute("EnabledStrokeColor", theme.input.enabledStroke)
	input:SetAttribute("DisabledStrokeColor", theme.input.disabledStroke)
	input.TextColor3 = if input.TextEditable then theme.input.text else theme.input.disabledText
	input.BackgroundColor3 = getColorAttribute(
		input,
		if input.TextEditable then "EnabledBackgroundColor" else "DisabledBackgroundColor",
		if input.TextEditable then theme.input.enabledBackground else theme.input.disabledBackground
	)
	local stroke = getStroke(input)
	if stroke then
		stroke.Color = getColorAttribute(
			input,
			if input.TextEditable then "EnabledStrokeColor" else "DisabledStrokeColor",
			if input.TextEditable then theme.input.enabledStroke else theme.input.disabledStroke
		)
	end
end

applyUiTheme = function(equippedItems)
	currentUiThemeId = if equippedItems.Theme == UI_THEME_IDS.Midnight then UI_THEME_IDS.Midnight else UI_THEME_IDS.Default

	local theme = getUiTheme()
	ui.background.BackgroundColor3 = theme.background.start
	local backgroundGradient = getGradient(ui.background)
	if backgroundGradient then
		backgroundGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.background.start),
			ColorSequenceKeypoint.new(1, theme.background.finish),
		})
	end

	for _, entry in ipairs(themedSurfaces) do
		applySurfaceTheme(entry.instance, entry.role)
	end

	for _, entry in ipairs(themedButtons) do
		applyButtonTheme(entry.instance, entry.variant)
	end

	for _, input in ipairs(themedInputs) do
		applyInputTheme(input)
	end

	for _, entry in ipairs(themedTexts) do
		if entry.instance then
			entry.instance.TextColor3 = theme.text[entry.role] or theme.text.default
		end
	end

	for _, entry in ipairs(themedAccents) do
		if entry.instance then
			local accentColor = theme.accents[entry.role] or theme.accents.primary
			if entry.instance:IsA("TextLabel") or entry.instance:IsA("TextButton") or entry.instance:IsA("TextBox") then
				entry.instance.TextColor3 = accentColor
			else
				entry.instance.BackgroundColor3 = accentColor
			end

			local gradient = getGradient(entry.instance)
			if gradient and entry.role == "glow" then
				gradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, theme.accents.glowStart),
					ColorSequenceKeypoint.new(1, theme.accents.glowFinish),
				})
			end
		end
	end

	for _, entry in ipairs(themedOverlays) do
		if entry.instance then
			entry.instance.BackgroundColor3 = theme.overlay.color
			entry.instance.BackgroundTransparency = entry.transparency or theme.overlay.transparency
		end
	end

	for _, frame in ipairs(themedScrollFrames) do
		if frame then
			frame.ScrollBarImageColor3 = theme.scrollBar
		end
	end

	updateCurrencyHud()
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
	card.BackgroundColor3 = themeSurfaceColor(backgroundColor)

	local stroke = getStroke(card)
	if stroke then
		stroke.Color = themeStrokeColor(strokeColor)
		stroke.Transparency = 0.1
	end

	local gradient = getGradient(card)
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, themeSurfaceColor(backgroundColor)),
			ColorSequenceKeypoint.new(1, themeSurfaceColor(getSemanticThemeColor("historyEntryAlt", COLORS.historyEntryAlt))),
		})
	end
end

local function updateReadyPill(pill, ready)
	local stroke = getStroke(pill)
	local gradient = getGradient(pill)

	pill.BackgroundColor3 = themeSurfaceColor(if ready
		then getSemanticThemeColor("readyPill", COLORS.readyPill)
		else getSemanticThemeColor("idlePill", COLORS.idlePill))
	if stroke then
		stroke.Color = themeStrokeColor(if ready
			then getSemanticThemeColor("readyPillBorder", COLORS.readyPillBorder)
			else getSemanticThemeColor("idlePillBorder", COLORS.idlePillBorder))
		stroke.Transparency = 0.08
	end
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, pill.BackgroundColor3),
			ColorSequenceKeypoint.new(1, themeSurfaceColor(getSemanticThemeColor("historyEntryAlt", COLORS.historyEntryAlt))),
		})
	end
end

local function setPanelAccent(panel, enabled, activeColor)
	local stroke = getStroke(panel)
	if stroke then
		stroke.Color = themeStrokeColor(if enabled
			then (activeColor or getSemanticThemeColor("activePanel", COLORS.activePanel))
			else getSemanticThemeColor("idlePanel", COLORS.idlePanel))
		stroke.Transparency = if enabled then 0.05 else 0.22
	end
	panel.BackgroundTransparency = if enabled then 0 else 0.08
end

local function setStatusChip(text, backgroundColor, strokeColor)
	ui.statusChipLabel.Text = text
	updateCardVisual(ui.statusChip, backgroundColor, strokeColor)
end

local function setStateLabel(label, text, isActive)
	local theme = getUiTheme()
	label.Text = text
	label.TextColor3 = if isActive then theme.text.default else theme.text.muted
	label.TextTransparency = if isActive then 0 else 0.15
end

local function setDigitSlotValues(slots, values, filledColor, emptyColor)
	for index, slot in ipairs(slots) do
		local digit = values[index]
		slot.BackgroundColor3 = if digit then themeSurfaceColor(filledColor) else themeSurfaceColor(emptyColor)

		local stroke = getStroke(slot)
		if stroke then
			stroke.Color = if digit
				then themeStrokeColor(filledColor)
				else themeStrokeColor(getSemanticThemeColor("historyEntryBorder", COLORS.historyEntryBorder))
			stroke.Transparency = if digit then 0.08 else 0.3
		end

		local label = slot:FindFirstChild("DigitLabel")
		if label and label:IsA("TextLabel") then
			label.Text = tostring(digit or "_")
			label.TextColor3 = getUiTheme().text.default
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
	ui.secretTextBox.PlaceholderText = copy.secretPlaceholder
	ui.guessTextBox.PlaceholderText = copy.guessPlaceholder
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
	local theme = getUiTheme()
	secretControlsEnabled = enabled
	ui.secretTextBox.TextEditable = enabled
	ui.secretTextBox.BackgroundColor3 = getColorAttribute(
		ui.secretTextBox,
		if enabled then "EnabledBackgroundColor" else "DisabledBackgroundColor",
		if enabled then theme.input.enabledBackground else theme.input.disabledBackground
	)
	ui.secretTextBox.TextColor3 = if enabled then theme.input.text else theme.input.disabledText
	ui.secretTextBox.TextTransparency = if enabled then 0 else 0.15
	local stroke = getStroke(ui.secretTextBox)
	if stroke then
		stroke.Color = getColorAttribute(
			ui.secretTextBox,
			if enabled then "EnabledStrokeColor" else "DisabledStrokeColor",
			if enabled then theme.input.enabledStroke else theme.input.disabledStroke
		)
		stroke.Transparency = if enabled then 0.2 else 0.4
	end
	setPanelAccent(ui.secretPanel, enabled, getSemanticThemeColor("activeSecretPanel", COLORS.activeSecretPanel))
	setButtonEnabled(ui.submitSecretButton, enabled)
end

local function setGuessControlsEnabled(enabled)
	local theme = getUiTheme()
	guessControlsEnabled = enabled
	ui.guessTextBox.TextEditable = enabled
	ui.guessTextBox.BackgroundColor3 = getColorAttribute(
		ui.guessTextBox,
		if enabled then "EnabledBackgroundColor" else "DisabledBackgroundColor",
		if enabled then theme.input.enabledBackground else theme.input.disabledBackground
	)
	ui.guessTextBox.TextColor3 = if enabled then theme.input.text else theme.input.disabledText
	ui.guessTextBox.TextTransparency = if enabled then 0 else 0.15
	local stroke = getStroke(ui.guessTextBox)
	if stroke then
		stroke.Color = getColorAttribute(
			ui.guessTextBox,
			if enabled then "EnabledStrokeColor" else "DisabledStrokeColor",
			if enabled then theme.input.enabledStroke else theme.input.disabledStroke
		)
		stroke.Transparency = if enabled then 0.2 else 0.4
	end
	setPanelAccent(ui.guessPanel, enabled, getSemanticThemeColor("activeGuessPanel", COLORS.activeGuessPanel))
	setButtonEnabled(ui.submitGuessButton, enabled)
end

local function setRestartControlsEnabled(enabled)
	canRequestRematch = enabled
	setButtonEnabled(ui.restartButton, enabled)
	setButtonEnabled(ui.resultPlayAgainButton, enabled)
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
	for _, child in ipairs(ui.guessHistoryFrame:GetChildren()) do
		if child.Name == "GuessHistoryEntry" then
			child:Destroy()
		end
	end

	guessHistoryCount = 0
	ui.guessHistoryFrame.CanvasSize = UDim2.fromOffset(0, 0)
end

local function addGuessHistoryEntry(result)
	guessHistoryCount += 1

	local entry = Instance.new("Frame")
	entry.Name = "GuessHistoryEntry"
	entry.LayoutOrder = guessHistoryCount
	entry.Size = UDim2.new(1, -4, 0, 94)
	entry.BackgroundColor3 = getSemanticThemeColor("historyEntry", COLORS.historyEntry)
	entry.BorderSizePixel = 0
	entry.Parent = ui.guessHistoryFrame

	updateCardVisual(
		entry,
		getSemanticThemeColor("historyEntry", COLORS.historyEntry),
		getSemanticThemeColor("historyEntryBorder", COLORS.historyEntryBorder)
	)
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
	countLabel.TextColor3 = getUiTheme().text.muted
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
	guessLabel.TextColor3 = getUiTheme().text.default
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
	feedbackLabel.TextColor3 = getUiTheme().text.muted
	feedbackLabel.TextSize = 15
	feedbackLabel.TextXAlignment = Enum.TextXAlignment.Left
	feedbackLabel.Parent = entry
end

local function resetRoundUi()
	setMatchPresentationForMode()
	hasSubmittedSecret = false
	isGameOver = false
	ui.secretTextBox.Text = ""
	ui.guessTextBox.Text = ""
	ui.gameOverLabel.Text = ""
	clearValidationMessages()
	ui.playerLockedLabel.Text = "Your code"
	ui.opponentLockedLabel.Text = "Their code"
	ui.turnLabel.Text = "Turn: waiting"
	setStatusChip(
		"Waiting",
		getSemanticThemeColor("historyEntry", COLORS.historyEntry),
		getSemanticThemeColor("historyEntryBorder", COLORS.historyEntryBorder)
	)
	setStateLabel(ui.secretStateLabel, "Waiting for round", false)
	setStateLabel(ui.guessStateLabel, "Waiting for turn", false)
	setDigitSlotValues(
		ui.playerLockedSlots,
		{},
		getSemanticThemeColor("playerLockedFilled", Color3.fromRGB(52, 88, 72)),
		getSemanticThemeColor("playerLockedEmpty", Color3.fromRGB(31, 48, 42))
	)
	setDigitSlotValues(
		ui.opponentLockedSlots,
		{},
		getSemanticThemeColor("opponentLockedFilled", Color3.fromRGB(49, 84, 126)),
		getSemanticThemeColor("opponentLockedEmpty", Color3.fromRGB(33, 44, 58))
	)
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

	ui.playerLockedLabel.Text = "Your code"
	ui.opponentLockedLabel.Text = "Their code"
	setDigitSlotValues(
		ui.playerLockedSlots,
		lockedPositionsByPlayerId[tostring(localPlayerId)] or {},
		getSemanticThemeColor("playerLockedFilled", Color3.fromRGB(52, 88, 72)),
		getSemanticThemeColor("playerLockedEmpty", Color3.fromRGB(31, 48, 42))
	)
	setDigitSlotValues(
		ui.opponentLockedSlots,
		lockedPositionsByPlayerId[tostring(opponentId)] or {},
		getSemanticThemeColor("opponentLockedFilled", Color3.fromRGB(49, 84, 126)),
		getSemanticThemeColor("opponentLockedEmpty", Color3.fromRGB(33, 44, 58))
	)
end

local function setScreen(screenState)
	ui.background.Visible = screenState ~= nil
	ui.menuScreen.Visible = screenState == SCREEN_STATES.Menu
	ui.lobbyScreen.Visible = screenState == SCREEN_STATES.Lobby
	ui.matchScreen.Visible = screenState == SCREEN_STATES.Match
	ui.resultScreen.Visible = screenState == SCREEN_STATES.Result

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
	local theme = getUiTheme()
	label.Text = if ready then "Ready" else "Not ready"
	label.TextColor3 = if ready then theme.text.success else theme.text.muted
	label.Font = if ready then Enum.Font.GothamBold else Enum.Font.Gotham
end

local function updateLobbyPlayerCard(card, readyPill, slotLabel, readyLabel, slotNumber, playerId, ready)
	slotLabel.Text = formatPlayerSlot(slotNumber, playerId)
	updateReadyLabel(readyLabel, ready)
	updateReadyPill(readyPill, ready)

	if not playerId then
		updateCardVisual(
			card,
			getSemanticThemeColor("waitingCard", COLORS.waitingCard),
			getSemanticThemeColor("waitingCardBorder", COLORS.waitingCardBorder)
		)
		return
	end

	if playerId == localPlayer.UserId then
		updateCardVisual(
			card,
			getSemanticThemeColor("localCard", COLORS.localCard),
			getSemanticThemeColor("localCardBorder", COLORS.localCardBorder)
		)
	else
		updateCardVisual(
			card,
			getSemanticThemeColor("opponentCard", COLORS.opponentCard),
			getSemanticThemeColor("opponentCardBorder", COLORS.opponentCardBorder)
		)
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
		ui.lobbyStatusLabel.Text = "Waiting for opponent"
		updateLobbyPlayerCard(ui.playerOneRow, ui.playerOneReadyPill, ui.playerOneSlotLabel, ui.playerOneReadyLabel, 1, nil, false)
		updateLobbyPlayerCard(ui.playerTwoRow, ui.playerTwoReadyPill, ui.playerTwoSlotLabel, ui.playerTwoReadyLabel, 2, nil, false)
		readyControlsEnabled = true
		setButtonEnabled(ui.readyButton, true)
		ui.readyButton.Text = "Ready"
		return
	end

	local playerOneReady = getPlayerReady(lobbyState, lobbyState.playerOneId)
	local playerTwoReady = getPlayerReady(lobbyState, lobbyState.playerTwoId)
	local localReady = getPlayerReady(lobbyState, localPlayer.UserId)
	local isInLobby = lobbyState.playerOneId == localPlayer.UserId or lobbyState.playerTwoId == localPlayer.UserId
	local hasBothPlayers = lobbyState.playerOneId ~= nil and lobbyState.playerTwoId ~= nil
	local canToggleReady = lobbyState.gameState == GAME_STATES.WaitingForPlayers and isInLobby

	updateLobbyPlayerCard(
		ui.playerOneRow,
		ui.playerOneReadyPill,
		ui.playerOneSlotLabel,
		ui.playerOneReadyLabel,
		1,
		lobbyState.playerOneId,
		playerOneReady
	)
	updateLobbyPlayerCard(
		ui.playerTwoRow,
		ui.playerTwoReadyPill,
		ui.playerTwoSlotLabel,
		ui.playerTwoReadyLabel,
		2,
		lobbyState.playerTwoId,
		playerTwoReady
	)

	local sessionNotice = getSessionNotice(lobbyState)
	if sessionNotice then
		ui.lobbyStatusLabel.Text = sessionNotice
	elseif not hasBothPlayers then
		ui.lobbyStatusLabel.Text = "Waiting for opponent"
	elseif localReady and not (playerOneReady and playerTwoReady) then
		ui.lobbyStatusLabel.Text = "Waiting for opponent to ready"
	else
		ui.lobbyStatusLabel.Text = "Ready up"
	end

	readyControlsEnabled = canToggleReady
	setButtonEnabled(ui.readyButton, canToggleReady)
	ui.readyButton.Text = if localReady then "Unready" else "Ready"
end

local function updateResult(roundState)
	if not roundState then
		ui.resultWinnerLabel.Text = "Winner: -"
		ui.resultSubtitleLabel.Text = "Round complete."
		ui.resultStatusLabel.Text = ""
		ui.resultRewardLabel.Text = ""
		modeUi.resultYourSecretLabel.Text = "Your secret: -"
		modeUi.resultOpponentSecretLabel.Text = "Opponent secret: -"
		updateCardVisual(
			ui.resultWinnerCard,
			getSemanticThemeColor("historyEntry", COLORS.historyEntry),
			getSemanticThemeColor("historyEntryBorder", COLORS.historyEntryBorder)
		)
		setRestartControlsEnabled(false)
		return
	end

	local copy = getModeCopy()
	local winnerId = roundState.winner
	if roundState.isTie or winnerId == TIE_WINNER then
		ui.resultWinnerLabel.Text = "Result: Tie"
		ui.resultSubtitleLabel.Text = copy.tieSubtitle
		updateCardVisual(
			ui.resultWinnerCard,
			getSemanticThemeColor("resultTie", COLORS.resultTie),
			getSemanticThemeColor("historyEntryBorder", COLORS.historyEntryBorder)
		)
	elseif winnerId == localPlayer.UserId then
		ui.resultWinnerLabel.Text = "Winner: You"
		ui.resultSubtitleLabel.Text = copy.youWonSubtitle
		updateCardVisual(
			ui.resultWinnerCard,
			getSemanticThemeColor("resultWin", COLORS.resultWin),
			getSemanticThemeColor("readyPillBorder", COLORS.readyPillBorder)
		)
	elseif winnerId then
		ui.resultWinnerLabel.Text = "Winner: Opponent"
		ui.resultSubtitleLabel.Text = copy.opponentWonSubtitle
		updateCardVisual(
			ui.resultWinnerCard,
			getSemanticThemeColor("resultLoss", COLORS.resultLoss),
			getSemanticThemeColor("resultLossBorder", Color3.fromRGB(208, 122, 122))
		)
	else
		ui.resultWinnerLabel.Text = "Winner: -"
		ui.resultSubtitleLabel.Text = "Round complete."
		updateCardVisual(
			ui.resultWinnerCard,
			getSemanticThemeColor("historyEntry", COLORS.historyEntry),
			getSemanticThemeColor("historyEntryBorder", COLORS.historyEntryBorder)
		)
	end

	local finalSecretsByPlayerId = roundState.finalSecretsByPlayerId or {}
	local opponentId = getOpponentId(roundState)
	modeUi.resultYourSecretLabel.Text = "Your secret: " .. tostring(finalSecretsByPlayerId[tostring(localPlayer.UserId)] or "-")
	modeUi.resultOpponentSecretLabel.Text = "Opponent secret: " .. tostring(finalSecretsByPlayerId[tostring(opponentId)] or "-")

	local reward = getLocalCurrencyValue(roundState, "latestRewardByPlayerId")
	ui.resultRewardLabel.Text = if reward and reward > 0 then "+" .. tostring(reward) .. " coins earned" else ""

	local localReadyForRematch = getRematchReady(roundState, localPlayer.UserId)
	local sessionNotice = getSessionNotice(roundState)
	if sessionNotice then
		ui.resultStatusLabel.Text = sessionNotice
		setRestartControlsEnabled(false)
	elseif roundState.gameState == GAME_STATES.WaitingForRematch and localReadyForRematch then
		ui.resultStatusLabel.Text = "Waiting for opponent to play again"
		setRestartControlsEnabled(false)
	elseif roundState.gameState == GAME_STATES.WaitingForRematch then
		ui.resultStatusLabel.Text = "Opponent wants to play again"
		setRestartControlsEnabled(true)
	else
		ui.resultStatusLabel.Text = "Game over"
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
	ui.gameOverLabel.Text = ""
	setRestartControlsEnabled(false)

	if roundState then
		updateLockedLabels(roundState)
	end

	if uiState == UI_STATES.EnteringSecret then
		local copy = getModeCopy()
		ui.statusLabel.Text = copy.enterSecretStatus
		ui.turnLabel.Text = "Turn: waiting"
		setStatusChip(
			"Secret phase",
			getSemanticThemeColor("phaseSecret", COLORS.phaseSecret),
			getSemanticThemeColor("activeSecretPanel", COLORS.activeSecretPanel)
		)
		setStateLabel(ui.secretStateLabel, copy.secretActiveState, true)
		setStateLabel(ui.guessStateLabel, copy.guessLockedState, false)
		setSecretControlsEnabled(canSubmitSecret(roundState) == true)
		setGuessControlsEnabled(false)
	elseif uiState == UI_STATES.WaitingForOpponentSecret then
		local copy = getModeCopy()
		ui.statusLabel.Text = copy.waitingSecretStatus
		ui.turnLabel.Text = "Turn: waiting"
		setStatusChip(
			"Secret phase",
			getSemanticThemeColor("phaseSecret", COLORS.phaseSecret),
			getSemanticThemeColor("activeSecretPanel", COLORS.activeSecretPanel)
		)
		setStateLabel(ui.secretStateLabel, copy.secretSavedState, false)
		setStateLabel(ui.guessStateLabel, copy.guessWaitingState, false)
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
	elseif uiState == UI_STATES.InTurn then
		local copy = getModeCopy()
		ui.statusLabel.Text = "Your turn"
		ui.turnLabel.Text = "Turn: you"
		setStatusChip(
			"Guess phase",
			getSemanticThemeColor("phaseGuess", COLORS.phaseGuess),
			getSemanticThemeColor("activeGuessPanel", COLORS.activeGuessPanel)
		)
		setStateLabel(ui.secretStateLabel, copy.secretLockedState, false)
		setStateLabel(ui.guessStateLabel, copy.guessActiveState, true)
		setSecretControlsEnabled(false)
		refreshGuessControls()
	elseif uiState == UI_STATES.OpponentTurn then
		local copy = getModeCopy()
		ui.statusLabel.Text = "Opponent's turn"
		ui.turnLabel.Text = if roundState and roundState.currentTurn then "Turn: opponent" else "Turn: waiting"
		setStatusChip(
			"Guess phase",
			getSemanticThemeColor("phaseGuess", COLORS.phaseGuess),
			getSemanticThemeColor("activeGuessPanel", COLORS.activeGuessPanel)
		)
		setStateLabel(ui.secretStateLabel, copy.secretLockedState, false)
		setStateLabel(ui.guessStateLabel, copy.guessOpponentState, false)
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
	end
end

local function renderUi()
	local screenState = getScreenStateForUiState(currentUiState)
	setScreen(screenState)

	if currentUiState == UI_STATES.LobbyWorld then
		ui.howToPlayPanel.Visible = false
		resetRoundUi()
	elseif currentUiState == UI_STATES.Menu then
		setMenuPresentationForMode()
		setRestartControlsEnabled(false)
		updateLobby(latestLobbyState)
	elseif currentUiState == UI_STATES.ReadyUp then
		setCommercePanelsVisible(false, false)
		ui.howToPlayPanel.Visible = false
		updateLobby(latestLobbyState)
		resetRoundUi()
	elseif isMatchUiState(currentUiState) then
		setCommercePanelsVisible(false, false)
		ui.howToPlayPanel.Visible = false
		updateMatchForUiState(currentUiState, latestRoundState)
	elseif currentUiState == UI_STATES.GameOver then
		setCommercePanelsVisible(false, false)
		ui.howToPlayPanel.Visible = false
		setSecretControlsEnabled(false)
		setGuessControlsEnabled(false)
		updateResult(latestRoundState)
	end

	applyUiTheme(getEquippedForPlayer(localPlayer))
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
	ui.statusLabel.Text = "Guess submitted"
	setValidationMessage(ui.guessValidationLabel, "")
	addGuessHistoryEntry(result)
	applyUiTheme(getEquippedForPlayer(localPlayer))
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
	ui.howToPlayPanel.Visible = false
	setCommercePanelsVisible(true, false)
	updateShopPanel(shopState)
end

local function onShopStateChanged(shopState)
	updateShopPanel(shopState)
end

local function onCoinPacksOpened(coinPackState)
	ui.howToPlayPanel.Visible = false
	setCommercePanelsVisible(false, false, false, true)
	updateCoinPacksPanel(coinPackState)
end

local function onCoinPackStateChanged(coinPackState)
	updateCoinPacksPanel(coinPackState)
end

local function onRewardsOpened(rewardState)
	ui.howToPlayPanel.Visible = false
	setCommercePanelsVisible(false, true)
	updateRewardsPanel(rewardState)
end

local function onRewardStateChanged(rewardState)
	updateRewardsPanel(rewardState)
end

local function onLeaderboardOpened(leaderboardState)
	ui.howToPlayPanel.Visible = false
	setCommercePanelsVisible(false, false, true)
	updateLeaderboardPanel(leaderboardState)
end

local function onLeaderboardStateChanged(leaderboardState)
	updateLeaderboardPanel(leaderboardState)
end

local function onModeStateChanged(modeState)
	modeUi.latestModeState = modeState or modeUi.latestModeState
	ui.secretTextBox.Text = clampModeInput(ui.secretTextBox.Text)
	ui.guessTextBox.Text = clampModeInput(ui.guessTextBox.Text)
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

ui.secretTextBox:GetPropertyChangedSignal("Text"):Connect(function()
	if isValidModeInput(ui.secretTextBox.Text) then
		setValidationMessage(ui.secretValidationLabel, "")
	end
end)

ui.guessTextBox:GetPropertyChangedSignal("Text"):Connect(function()
	if isValidModeInput(ui.guessTextBox.Text) then
		setValidationMessage(ui.guessValidationLabel, "")
	end
end)

local function submitSecret()
	if not secretControlsEnabled or isGameOver then
		return
	end

	local secret = ui.secretTextBox.Text
	if not isValidModeInput(secret) then
		setValidationMessage(ui.secretValidationLabel, getModeInputError())
		return
	end

	hasSubmittedSecret = true
	setSecretControlsEnabled(false)
	ui.secretTextBox.Text = ""
	setValidationMessage(ui.secretValidationLabel, "")
	RemoteEvents.SecretSubmitted:FireServer(secret)
	setUiState(UI_STATES.WaitingForOpponentSecret)
end

local function submitGuess()
	if not guessControlsEnabled or isGameOver then
		return
	end

	local guess = ui.guessTextBox.Text
	if not isValidModeInput(guess) then
		setValidationMessage(ui.guessValidationLabel, getModeInputError())
		return
	end

	ui.statusLabel.Text = "Submitting guess..."
	setGuessControlsEnabled(false)
	ui.guessTextBox.Text = ""
	setValidationMessage(ui.guessValidationLabel, "")
	RemoteEvents.GuessSubmitted:FireServer(guess)
end

local function requestRestart()
	if not canRequestRematch then
		return
	end

	ui.resultStatusLabel.Text = "Waiting for opponent to play again"
	ui.statusLabel.Text = "Waiting for rematch"
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
		ui.howToPlayPanel.Visible = false
		RemoteEvents.PlayModeRequested:FireServer(modeId)
	elseif prompt.Name == "ShopPrompt" then
		ui.howToPlayPanel.Visible = false
		RemoteEvents.ShopOpenRequested:FireServer()
	elseif prompt.Name == "RewardsPrompt" then
		ui.howToPlayPanel.Visible = false
		RemoteEvents.RewardsOpenRequested:FireServer()
	elseif prompt.Name == "LeaderboardPrompt" then
		ui.howToPlayPanel.Visible = false
		RemoteEvents.LeaderboardOpenRequested:FireServer()
	end
end

ui.guessHistoryList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	ui.guessHistoryFrame.CanvasSize = UDim2.fromOffset(0, ui.guessHistoryList.AbsoluteContentSize.Y + 12)
end)

for index = 1, 4 do
	modeUi.shopRows[index] = {
		frame = findUi(ui.shopPanel, "ShopItemRow" .. tostring(index)),
		name = findUi(ui.shopPanel, "ShopItemNameLabel" .. tostring(index)),
		meta = findUi(ui.shopPanel, "ShopItemMetaLabel" .. tostring(index)),
		price = findUi(ui.shopPanel, "ShopItemPriceLabel" .. tostring(index)),
		state = findUi(ui.shopPanel, "ShopItemStateLabel" .. tostring(index)),
		buyButton = findUi(ui.shopPanel, "ShopBuyButton" .. tostring(index)),
		equipButton = findUi(ui.shopPanel, "ShopEquipButton" .. tostring(index)),
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
		frame = findUi(ui.leaderboardPanel, "LeaderboardRow" .. tostring(index)),
		rank = findUi(ui.leaderboardPanel, "LeaderboardRankLabel" .. tostring(index)),
		name = findUi(ui.leaderboardPanel, "LeaderboardNameLabel" .. tostring(index)),
		wins = findUi(ui.leaderboardPanel, "LeaderboardWinsLabel" .. tostring(index)),
		streak = findUi(ui.leaderboardPanel, "LeaderboardStreakLabel" .. tostring(index)),
		coins = findUi(ui.leaderboardPanel, "LeaderboardCoinsLabel" .. tostring(index)),
	}
end

initializeUiThemeBindings()

for _, descendant in ipairs(devGui:GetDescendants()) do
	if descendant:IsA("TextButton") then
		wireButtonInteractions(descendant)
	end
end

setSecretControlsEnabled(false)
setGuessControlsEnabled(false)
setRestartControlsEnabled(false)
updateCurrencyHud(0)
bindModeInput(ui.secretTextBox)
bindModeInput(ui.guessTextBox)
setUiState(UI_STATES.LobbyWorld)

ui.playButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false)
	ui.howToPlayPanel.Visible = false
	RemoteEvents.LobbyEntered:FireServer()
	setUiState(UI_STATES.ReadyUp)
end)

ui.menuBackButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false, false)
	ui.howToPlayPanel.Visible = false
	clearValidationMessages()
	resetRoundUi()
	setUiState(UI_STATES.LobbyWorld)
end)

ui.howToPlayButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false)
	ui.howToPlayPanel.Visible = not ui.howToPlayPanel.Visible
end)

ui.closeHowToPlayButton.MouseButton1Click:Connect(function()
	ui.howToPlayPanel.Visible = false
end)

ui.closeShopButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false)
end)

modeUi.openCoinPacksButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false, true)
	updateCoinPacksPanel()
	RemoteEvents.CoinPacksOpenRequested:FireServer()
end)

modeUi.buyCoinsHudButton.MouseButton1Click:Connect(function()
	ui.howToPlayPanel.Visible = false
	setCommercePanelsVisible(false, false, false, true)
	updateCoinPacksPanel()
	RemoteEvents.CoinPacksOpenRequested:FireServer()
end)

modeUi.closeCoinPacksButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false, false)
end)

ui.closeRewardsButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false)
end)

ui.closeLeaderboardButton.MouseButton1Click:Connect(function()
	setCommercePanelsVisible(false, false, false)
end)

for _, row in ipairs(modeUi.shopRows) do
	row.buyButton.MouseButton1Click:Connect(function()
		local itemId = row.frame:GetAttribute("ItemId")
		if itemId then
			ui.shopStatusLabel.Text = "Buying..."
			RemoteEvents.ShopPurchaseRequested:FireServer(itemId)
		end
	end)
	row.equipButton.MouseButton1Click:Connect(function()
		local itemId = row.frame:GetAttribute("ItemId")
		if itemId then
			ui.shopStatusLabel.Text = "Equipping..."
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

ui.claimRewardButton.MouseButton1Click:Connect(function()
	ui.rewardsStatusLabel.Text = "Claiming..."
	setButtonEnabled(ui.claimRewardButton, false)
	RemoteEvents.RewardClaimRequested:FireServer()
end)

ui.lobbyBackButton.MouseButton1Click:Connect(function()
	RemoteEvents.LobbyLeft:FireServer()
	setUiState(UI_STATES.LobbyWorld)
end)
ui.backToMenuButton.MouseButton1Click:Connect(function()
	RemoteEvents.LobbyLeft:FireServer()
	setUiState(UI_STATES.LobbyWorld)
end)

ui.readyButton.MouseButton1Click:Connect(function()
	if not readyControlsEnabled then
		return
	end

	local isReady = latestLobbyState and getPlayerReady(latestLobbyState, localPlayer.UserId) or false
	RemoteEvents.ReadyChanged:FireServer(not isReady)
	readyControlsEnabled = false
	setButtonEnabled(ui.readyButton, false)
end)

ui.submitSecretButton.MouseButton1Click:Connect(submitSecret)
ui.submitGuessButton.MouseButton1Click:Connect(submitGuess)
ui.restartButton.MouseButton1Click:Connect(requestRestart)
ui.resultPlayAgainButton.MouseButton1Click:Connect(requestRestart)
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
