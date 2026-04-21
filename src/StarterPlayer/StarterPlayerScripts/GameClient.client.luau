local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local playerGui = localPlayer:WaitForChild("PlayerGui")
local devGui = playerGui:WaitForChild("FastGuesserDevGui")
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

-- Called by the SecretRequested RemoteEvent listener.
local function onSecretRequested()
	-- Temporary developer UI: enable secret entry until the final UI exists.
	statusLabel.Text = "Enter your secret"
	secretTextBox.Text = ""
	setSecretControlsEnabled(true)
	print("Enter your secret")
end

-- Called by the TurnChanged RemoteEvent listener.
local function onTurnChanged(playerId)
	-- Temporary developer UI: show whose turn it is.
	isPlayerTurn = playerId == localPlayer.UserId
	turnLabel.Text = "Turn: player " .. tostring(playerId)
	statusLabel.Text = if isPlayerTurn then "Your turn to guess" else "Waiting for opponent"
	refreshGuessControls()
	print("It is player " .. tostring(playerId) .. "'s turn")
end

-- Called by the GuessResult RemoteEvent listener.
local function onGuessResult(result)
	-- Temporary developer UI: show the latest locked positions for this player.
	statusLabel.Text = "Guess submitted"
	playerLockedLabel.Text = "Your locked: " .. formatLockedPositions(result.lockedPositions)
	opponentLockedLabel.Text = "Opponent locked: not available yet"
	guessTextBox.Text = ""
	print(result.lockedPositions)
end

-- Called by the GameOver RemoteEvent listener.
local function onGameOver(winnerId)
	-- Temporary developer UI: show the winner and stop input.
	isGameOver = true
	gameOverLabel.Text = "Winner: " .. tostring(winnerId)
	statusLabel.Text = "Game over"
	setSecretControlsEnabled(false)
	setGuessControlsEnabled(false)
	print("Winner: " .. tostring(winnerId))
end

submitSecretButton.MouseButton1Click:Connect(function()
	if not secretControlsEnabled then
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
	RemoteEvents.SecretSubmitted:FireServer(secret)
	refreshGuessControls()
end)

submitGuessButton.MouseButton1Click:Connect(function()
	if not guessControlsEnabled then
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
end)

-- RemoteEvent listeners. Real UI calls will stay inside the four handlers above.
RemoteEvents.SecretRequested.OnClientEvent:Connect(function()
	onSecretRequested()
end)

RemoteEvents.TurnChanged.OnClientEvent:Connect(function(playerId)
	onTurnChanged(playerId)
end)

RemoteEvents.GuessResult.OnClientEvent:Connect(function(result)
	onGuessResult(result)
end)

RemoteEvents.GameOver.OnClientEvent:Connect(function(winnerId)
	onGameOver(winnerId)
end)
