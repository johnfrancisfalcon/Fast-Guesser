local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MatchService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("MatchService"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local PrototypeMatchServer = {}

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
	local playerOneId = prototypePlayers[1] and prototypePlayers[1].UserId or nil
	local playerTwoId = prototypePlayers[2] and prototypePlayers[2].UserId or nil
	local currentTurn = nil
	local winner = nil
	local lockedPositionsByPlayerId = {}

	if match then
		playerOneId = match.players[1]
		playerTwoId = match.players[2]
		currentTurn = match.currentTurn
		winner = match.winner

		-- String keys survive RemoteEvent dictionary serialization reliably.
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

		-- Repeat briefly so Studio clients that are still starting up see the request.
		for _ = 1, 10 do
			if requestToken ~= secretRequestToken or bothSecretsSubmitted() then
				break
			end

			if not hasSubmittedSecret(playerOne) then
				RemoteEvents.SecretRequested:FireClient(playerOne)
			end

			if not hasSubmittedSecret(playerTwo) then
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

local function toDensePositionTable(positionTable)
	local result = {}

	for i = 1, 4 do
		result[i] = positionTable[i] or "_"
	end

	return result
end

local function buildGuessResultPayload(result)
	return {
		playerId = result.playerId,
		guess = result.guess,
		matches = toDensePositionTable(result.matches),
		lockedPositions = toDensePositionTable(result.lockedPositions),
		isSolved = result.isSolved,
	}
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

local function onPlayerRemoving(player)
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
end

local function onSecretSubmitted(player, secret)
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
end

local function onGuessSubmitted(player, guess)
	if currentGameState ~= GAME_STATES.InProgress then
		warn("Cannot submit guess unless round is in progress.")
		return
	end

	local ok, result = submitGuess(player.UserId, guess)
	if not ok then
		warn(result)
		return
	end

	RemoteEvents.GuessResult:FireClient(player, buildGuessResultPayload(result))

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
end

local function onRestartRequested(player)
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
end

function PrototypeMatchServer.start()
	print("[FastGuesser] bootstrap started")

	Players.PlayerAdded:Connect(detectPlayer)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	RemoteEvents.SecretSubmitted.OnServerEvent:Connect(onSecretSubmitted)
	RemoteEvents.GuessSubmitted.OnServerEvent:Connect(onGuessSubmitted)
	RemoteEvents.RestartRequested.OnServerEvent:Connect(onRestartRequested)

	for _, player in ipairs(Players:GetPlayers()) do
		detectPlayer(player)
	end

	tryStartPrototypeMatch()

	_G.FastGuesserPrototype = {
		setPlayerSecret = setPlayerSecret,
		submitGuess = submitGuess,
		getPrototypeMatch = getPrototypeMatch,
	}
end

return PrototypeMatchServer
