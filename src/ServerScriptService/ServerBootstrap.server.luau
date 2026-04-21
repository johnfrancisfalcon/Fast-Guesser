local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

print("[FastGuesser] bootstrap started")

local MatchService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("MatchService"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local GAME_STATES = {
	WaitingForPlayers = "WaitingForPlayers",
	WaitingForSecrets = "WaitingForSecrets",
	InProgress = "InProgress",
	RoundOver = "RoundOver",
	WaitingForRematch = "WaitingForRematch",
}

local prototypePlayers = {}
local prototypeMatchId = nil
local secretRequestLoopStarted = false
local secretRequestToken = 0
local currentGameState = GAME_STATES.WaitingForPlayers
local rematchReadyByPlayerId = {}

local function setGameState(nextGameState)
	if currentGameState == nextGameState then
		return
	end

	print("[FastGuesser] state", currentGameState, "->", nextGameState)
	currentGameState = nextGameState
end

local function getPrototypeMatch()
	if not prototypeMatchId then
		return nil
	end

	return MatchService.getMatch(prototypeMatchId)
end

local function bothSecretsSubmitted()
	local match = getPrototypeMatch()
	if not match then
		return false
	end

	for _, player in ipairs(prototypePlayers) do
		if not match.secrets[player.UserId] then
			return false
		end
	end

	return true
end

local function hasSubmittedSecret(player)
	local match = getPrototypeMatch()
	if not match then
		return false
	end

	return match.secrets[player.UserId] ~= nil
end

local function buildRoundState(match)
	local playerOneId = nil
	local playerTwoId = nil
	local currentTurn = nil
	local winner = nil
	local lockedPositionsByPlayerId = {}

	if prototypePlayers[1] then
		playerOneId = prototypePlayers[1].UserId
	end

	if prototypePlayers[2] then
		playerTwoId = prototypePlayers[2].UserId
	end

	if match then
		playerOneId = match.players[1]
		playerTwoId = match.players[2]
		currentTurn = match.currentTurn
		winner = match.winner

		-- Use string keys so the dictionary is stable over RemoteEvents.
		lockedPositionsByPlayerId[tostring(playerOneId)] = match.lockedPositions[playerOneId]
		lockedPositionsByPlayerId[tostring(playerTwoId)] = match.lockedPositions[playerTwoId]
	end

	return {
		gameState = currentGameState,
		roundId = prototypeMatchId,
		playerOneId = playerOneId,
		playerTwoId = playerTwoId,
		currentTurn = currentTurn,
		winner = winner,
		lockedPositionsByPlayerId = lockedPositionsByPlayerId,
		rematchReadyByPlayerId = rematchReadyByPlayerId,
	}
end

local function fireRoundStateChanged()
	RemoteEvents.RoundStateChanged:FireAllClients(buildRoundState(getPrototypeMatch()))
end

local function requestSecretsForPrototypePlayers(playerOne, playerTwo)
	secretRequestToken += 1
	local requestToken = secretRequestToken

	task.spawn(function()
		if secretRequestLoopStarted then
			return
		end

		secretRequestLoopStarted = true

		-- Ask both prototype players to enter their secret. Repeat briefly so Studio
		-- clients that are still starting up do not miss the one-time request.
		for _ = 1, 10 do
			if requestToken ~= secretRequestToken or bothSecretsSubmitted() then
				break
			end

			if not hasSubmittedSecret(playerOne) then
				print("[FastGuesser] secret requested", playerOne.UserId)
				RemoteEvents.SecretRequested:FireClient(playerOne)
			end

			if not hasSubmittedSecret(playerTwo) then
				print("[FastGuesser] secret requested", playerTwo.UserId)
				RemoteEvents.SecretRequested:FireClient(playerTwo)
			end

			task.wait(1)
		end

		if requestToken == secretRequestToken then
			secretRequestLoopStarted = false
		end
	end)
end

local function createPrototypeMatch()
	local playerOne = prototypePlayers[1]
	local playerTwo = prototypePlayers[2]
	local prototypeMatch, createError = MatchService.createMatch(playerOne.UserId, playerTwo.UserId)
	if not prototypeMatch then
		error(createError)
	end

	prototypeMatchId = prototypeMatch.id
	rematchReadyByPlayerId = {}
	setGameState(GAME_STATES.WaitingForSecrets)
	print("[FastGuesser] match created", prototypeMatchId, playerOne.UserId, playerTwo.UserId)

	fireRoundStateChanged()
	requestSecretsForPrototypePlayers(playerOne, playerTwo)
end

local function tryStartPrototypeMatch()
	if prototypeMatchId or #prototypePlayers < 2 then
		return
	end

	createPrototypeMatch()
end

local function setPlayerSecret(playerId, secret)
	if not prototypeMatchId then
		return false, "Prototype match has not started."
	end

	return MatchService.setPlayerSecret(prototypeMatchId, playerId, secret)
end

local function submitGuess(playerId, guess)
	if not prototypeMatchId then
		return false, "Prototype match has not started."
	end

	return MatchService.submitGuess(prototypeMatchId, playerId, guess)
end

local function detectPlayer(player)
	if #prototypePlayers >= 2 then
		return
	end

	for _, prototypePlayer in ipairs(prototypePlayers) do
		if prototypePlayer == player then
			return
		end
	end

	print("[FastGuesser] player detected", player.UserId)
	table.insert(prototypePlayers, player)

	if #prototypePlayers < 2 then
		setGameState(GAME_STATES.WaitingForPlayers)
		fireRoundStateChanged()
	end

	tryStartPrototypeMatch()
end

Players.PlayerAdded:Connect(detectPlayer)
Players.PlayerRemoving:Connect(function(player)
	for index, prototypePlayer in ipairs(prototypePlayers) do
		if prototypePlayer == player then
			table.remove(prototypePlayers, index)
			break
		end
	end

	prototypeMatchId = nil
	rematchReadyByPlayerId = {}
	setGameState(GAME_STATES.WaitingForPlayers)
	secretRequestToken += 1
	secretRequestLoopStarted = false

	print("[FastGuesser] player removed", player.UserId)
	fireRoundStateChanged()
end)

for _, player in ipairs(Players:GetPlayers()) do
	detectPlayer(player)
end

tryStartPrototypeMatch()

-- Client -> server: player submits their secret string.
RemoteEvents.SecretSubmitted.OnServerEvent:Connect(function(player, secret)
	print("[FastGuesser] secret submitted", player.UserId)

	local ok, message = setPlayerSecret(player.UserId, secret)
	if not ok then
		warn(message)
		return
	end

	local match = getPrototypeMatch()
	if match and match.currentTurn then
		setGameState(GAME_STATES.InProgress)
		fireRoundStateChanged()
		RemoteEvents.TurnChanged:FireAllClients(match.currentTurn)
	else
		setGameState(GAME_STATES.WaitingForSecrets)
		fireRoundStateChanged()
	end
end)

-- Client -> server: player submits a guess string.
RemoteEvents.GuessSubmitted.OnServerEvent:Connect(function(player, guess)
	print("[FastGuesser] guess submitted", player.UserId, guess)

	if currentGameState ~= GAME_STATES.InProgress then
		warn("Cannot submit guess unless round is in progress.")
		return
	end

	local ok, result = submitGuess(player.UserId, guess)
	if not ok then
		warn(result)
		return
	end

	RemoteEvents.GuessResult:FireClient(player, result)

	local match = getPrototypeMatch()
	if not match then
		return
	end

	if match.winner then
		setGameState(GAME_STATES.RoundOver)
		RemoteEvents.GameOver:FireAllClients(match.winner)
		fireRoundStateChanged()
	else
		setGameState(GAME_STATES.InProgress)
		fireRoundStateChanged()
		RemoteEvents.TurnChanged:FireAllClients(match.currentTurn)
	end
end)

-- Client -> server: developer-only restart for local Studio testing.
RemoteEvents.RestartRequested.OnServerEvent:Connect(function(player)
	print("[FastGuesser] restart requested", player.UserId)

	if #prototypePlayers < 2 then
		warn("Need two prototype players before restarting.")
		return
	end

	if currentGameState ~= GAME_STATES.RoundOver and currentGameState ~= GAME_STATES.WaitingForRematch then
		warn("Restart is only available after the round is over.")
		return
	end

	rematchReadyByPlayerId[tostring(player.UserId)] = true
	print("[FastGuesser] rematch ready", player.UserId)

	local playerOne = prototypePlayers[1]
	local playerTwo = prototypePlayers[2]
	local bothPlayersReady = rematchReadyByPlayerId[tostring(playerOne.UserId)]
		and rematchReadyByPlayerId[tostring(playerTwo.UserId)]

	if not bothPlayersReady then
		setGameState(GAME_STATES.WaitingForRematch)
		fireRoundStateChanged()
		return
	end

	print("[FastGuesser] rematch ready complete")
	prototypeMatchId = nil
	secretRequestToken += 1
	secretRequestLoopStarted = false

	createPrototypeMatch()
	print("[FastGuesser] restart complete", prototypeMatchId)
end)

-- Prototype-only references so these entry points are easy to find while testing.
local PrototypeServer = {
	setPlayerSecret = setPlayerSecret,
	submitGuess = submitGuess,
	getPrototypeMatch = getPrototypeMatch,
}

_G.FastGuesserPrototype = PrototypeServer
