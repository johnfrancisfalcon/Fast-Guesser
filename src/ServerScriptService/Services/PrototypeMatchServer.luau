local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LobbyWorldService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("LobbyWorldService"))
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

local LOBBY_STATES = {
	-- 3D lobby shell state. MatchService still owns only the round rules.
	InLobby = "InLobby",
	Matchmaking = "Matchmaking",
	InRound = "InRound",
	PostRound = "PostRound",
}

local prototypePlayers = {}
local prototypeMatchId = nil
local secretRequestLoopStarted = false
local secretRequestToken = 0
local currentGameState = GAME_STATES.WaitingForPlayers
local lobbyStateByPlayerId = {}
local menuByPlayerId = {}
local lobbyReadyByPlayerId = {}
local rematchReadyByPlayerId = {}
local sessionNotice = nil

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

local function getPlayerKey(playerOrUserId)
	if typeof(playerOrUserId) == "Instance" then
		return tostring(playerOrUserId.UserId)
	end

	return tostring(playerOrUserId)
end

local function isPrototypePlayer(player)
	for _, prototypePlayer in ipairs(prototypePlayers) do
		if prototypePlayer == player then
			return true
		end
	end

	return false
end

local function removePrototypePlayer(player)
	for index, prototypePlayer in ipairs(prototypePlayers) do
		if prototypePlayer == player then
			table.remove(prototypePlayers, index)
			return true
		end
	end

	return false
end

local function clearPlayerSessionState(player)
	local playerKey = getPlayerKey(player)
	menuByPlayerId[playerKey] = nil
	lobbyStateByPlayerId[playerKey] = nil
	lobbyReadyByPlayerId[playerKey] = nil
	rematchReadyByPlayerId[playerKey] = nil
end

local function setPlayerLobbyState(player, lobbyState)
	lobbyStateByPlayerId[getPlayerKey(player)] = lobbyState
	RemoteEvents.LobbyFlowStateChanged:FireClient(player, {
		lobbyState = lobbyState,
	})
end

local function setPrototypePlayersLobbyState(lobbyState)
	for _, player in ipairs(prototypePlayers) do
		setPlayerLobbyState(player, lobbyState)
	end
end

local function resetInvalidSession(notice)
	if prototypeMatchId then
		MatchService.destroyMatch(prototypeMatchId)
	end

	prototypeMatchId = nil
	lobbyReadyByPlayerId = {}
	rematchReadyByPlayerId = {}
	sessionNotice = notice
	secretRequestToken += 1
	secretRequestLoopStarted = false
	setPrototypePlayersLobbyState(LOBBY_STATES.Matchmaking)
	setGameState(GAME_STATES.WaitingForPlayers)
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
	local isTie = false
	local lockedPositionsByPlayerId = {}
	local secretSubmittedByPlayerId = {}

	if match then
		playerOneId = match.players[1]
		playerTwoId = match.players[2]
		currentTurn = match.currentTurn
		winner = match.winner
		isTie = match.isTie == true

		-- String keys survive RemoteEvent dictionary serialization reliably.
		lockedPositionsByPlayerId[tostring(playerOneId)] = match.lockedPositions[playerOneId]
		lockedPositionsByPlayerId[tostring(playerTwoId)] = match.lockedPositions[playerTwoId]
		secretSubmittedByPlayerId[tostring(playerOneId)] = match.secrets[playerOneId] ~= nil
		secretSubmittedByPlayerId[tostring(playerTwoId)] = match.secrets[playerTwoId] ~= nil
	end

	return {
		gameState = currentGameState,
		roundId = prototypeMatchId,
		playerOneId = playerOneId,
		playerTwoId = playerTwoId,
		currentTurn = currentTurn,
		winner = winner,
		isTie = isTie,
		lobbyStateByPlayerId = lobbyStateByPlayerId,
		lockedPositionsByPlayerId = lockedPositionsByPlayerId,
		secretSubmittedByPlayerId = secretSubmittedByPlayerId,
		lobbyReadyByPlayerId = lobbyReadyByPlayerId,
		rematchReadyByPlayerId = rematchReadyByPlayerId,
		sessionNotice = sessionNotice,
	}
end

local function fireRoundStateChanged()
	RemoteEvents.RoundStateChanged:FireAllClients(buildRoundState(getPrototypeMatch()))
end

local function buildLobbyState()
	local playerOneId = prototypePlayers[1] and prototypePlayers[1].UserId or nil
	local playerTwoId = prototypePlayers[2] and prototypePlayers[2].UserId or nil

	return {
		gameState = currentGameState,
		roundId = prototypeMatchId,
		playerOneId = playerOneId,
		playerTwoId = playerTwoId,
		menuByPlayerId = menuByPlayerId,
		lobbyStateByPlayerId = lobbyStateByPlayerId,
		lobbyReadyByPlayerId = lobbyReadyByPlayerId,
		rematchReadyByPlayerId = rematchReadyByPlayerId,
		sessionNotice = sessionNotice,
	}
end

local function fireLobbyStateChanged()
	RemoteEvents.LobbyStateChanged:FireAllClients(buildLobbyState())
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
	lobbyReadyByPlayerId = {}
	rematchReadyByPlayerId = {}
	sessionNotice = nil
	setPrototypePlayersLobbyState(LOBBY_STATES.InRound)
	setGameState(GAME_STATES.WaitingForSecrets)
	print("[FastGuesser] match created", prototypeMatchId, playerOne.UserId, playerTwo.UserId)

	fireRoundStateChanged()
	fireLobbyStateChanged()
	requestSecretsForPrototypePlayers(playerOne, playerTwo)
end

local function tryStartPrototypeMatch()
	if prototypeMatchId then
		return
	end

	if #prototypePlayers < 2 then
		fireLobbyStateChanged()
		fireRoundStateChanged()
		return
	end

	local playerOneReady = lobbyReadyByPlayerId[getPlayerKey(prototypePlayers[1])] == true
	local playerTwoReady = lobbyReadyByPlayerId[getPlayerKey(prototypePlayers[2])] == true
	if not playerOneReady or not playerTwoReady then
		fireLobbyStateChanged()
		fireRoundStateChanged()
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
	print("[FastGuesser] player detected", player.UserId)
	clearPlayerSessionState(player)
	menuByPlayerId[getPlayerKey(player)] = true
	setPlayerLobbyState(player, LOBBY_STATES.InLobby)
	fireLobbyStateChanged()
	fireRoundStateChanged()
end

local function onPlayerRemoving(player)
	local previousGameState = currentGameState
	local wasPrototypePlayer = removePrototypePlayer(player)
	clearPlayerSessionState(player)
	menuByPlayerId[getPlayerKey(player)] = nil

	if not wasPrototypePlayer then
		fireLobbyStateChanged()
		fireRoundStateChanged()
		return
	end

	local notice = if previousGameState == GAME_STATES.WaitingForPlayers
		then "Waiting for another player"
		else "Opponent left the match"
	resetInvalidSession(notice)

	print("[FastGuesser] player removed", player.UserId)
	fireLobbyStateChanged()
	fireRoundStateChanged()
end

local onRestartRequested

local function onLobbyEntered(player)
	menuByPlayerId[getPlayerKey(player)] = nil
	sessionNotice = nil
	setPlayerLobbyState(player, LOBBY_STATES.Matchmaking)

	if currentGameState == GAME_STATES.RoundOver or currentGameState == GAME_STATES.WaitingForRematch then
		onRestartRequested(player)
		return
	end

	if prototypeMatchId or currentGameState ~= GAME_STATES.WaitingForPlayers then
		fireLobbyStateChanged()
		fireRoundStateChanged()
		return
	end

	if not isPrototypePlayer(player) and #prototypePlayers < 2 then
		table.insert(prototypePlayers, player)
	end

	setGameState(GAME_STATES.WaitingForPlayers)
	tryStartPrototypeMatch()
end

local function onLobbyLeft(player)
	menuByPlayerId[getPlayerKey(player)] = true
	lobbyReadyByPlayerId[getPlayerKey(player)] = nil
	rematchReadyByPlayerId[getPlayerKey(player)] = nil
	sessionNotice = nil
	setPlayerLobbyState(player, LOBBY_STATES.InLobby)

	if currentGameState == GAME_STATES.RoundOver or currentGameState == GAME_STATES.WaitingForRematch then
		removePrototypePlayer(player)
		resetInvalidSession("Opponent left the match")
		fireLobbyStateChanged()
		fireRoundStateChanged()
		return
	end

	if prototypeMatchId or currentGameState ~= GAME_STATES.WaitingForPlayers then
		removePrototypePlayer(player)
		resetInvalidSession("Opponent left the match")
		fireLobbyStateChanged()
		fireRoundStateChanged()
		return
	end

	removePrototypePlayer(player)
	lobbyReadyByPlayerId = {}
	rematchReadyByPlayerId = {}
	sessionNotice = "Waiting for another player"
	fireLobbyStateChanged()
	fireRoundStateChanged()
end

local function onReadyChanged(player, isReady)
	if prototypeMatchId or not isPrototypePlayer(player) then
		return
	end

	sessionNotice = nil
	lobbyReadyByPlayerId[getPlayerKey(player)] = isReady == true or nil
	setGameState(GAME_STATES.WaitingForPlayers)
	tryStartPrototypeMatch()
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
		setPrototypePlayersLobbyState(LOBBY_STATES.PostRound)
		RemoteEvents.GameOver:FireAllClients(match.winner)
		fireRoundStateChanged()
	else
		setGameState(GAME_STATES.InProgress)
		fireRoundStateChanged()
		RemoteEvents.TurnChanged:FireAllClients(match.currentTurn)
	end
end

function onRestartRequested(player)
	if #prototypePlayers < 2 then
		warn("Need two prototype players before restarting.")
		return
	end

	if currentGameState ~= GAME_STATES.RoundOver and currentGameState ~= GAME_STATES.WaitingForRematch then
		warn("Restart is only available after the round is over.")
		return
	end

	rematchReadyByPlayerId[getPlayerKey(player)] = true
	print("[FastGuesser] rematch ready", player.UserId)
	setPlayerLobbyState(player, LOBBY_STATES.Matchmaking)

	local playerOne = prototypePlayers[1]
	local playerTwo = prototypePlayers[2]
	local bothPlayersReady = rematchReadyByPlayerId[getPlayerKey(playerOne)]
		and rematchReadyByPlayerId[getPlayerKey(playerTwo)]

	if not bothPlayersReady then
		setGameState(GAME_STATES.WaitingForRematch)
		fireLobbyStateChanged()
		fireRoundStateChanged()
		return
	end

	print("[FastGuesser] rematch ready complete")
	if prototypeMatchId then
		MatchService.destroyMatch(prototypeMatchId)
	end

	prototypeMatchId = nil
	menuByPlayerId = {}
	lobbyReadyByPlayerId = {}
	rematchReadyByPlayerId = {}
	sessionNotice = nil
	secretRequestToken += 1
	secretRequestLoopStarted = false
	setPrototypePlayersLobbyState(LOBBY_STATES.Matchmaking)

	setGameState(GAME_STATES.WaitingForPlayers)
	fireLobbyStateChanged()
	fireRoundStateChanged()
end

function PrototypeMatchServer.start()
	print("[FastGuesser] bootstrap started")
	LobbyWorldService.createLobby(onLobbyEntered)

	Players.PlayerAdded:Connect(detectPlayer)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	RemoteEvents.SecretSubmitted.OnServerEvent:Connect(onSecretSubmitted)
	RemoteEvents.GuessSubmitted.OnServerEvent:Connect(onGuessSubmitted)
	RemoteEvents.LobbyEntered.OnServerEvent:Connect(onLobbyEntered)
	RemoteEvents.LobbyLeft.OnServerEvent:Connect(onLobbyLeft)
	RemoteEvents.ReadyChanged.OnServerEvent:Connect(onReadyChanged)
	RemoteEvents.RematchRequested.OnServerEvent:Connect(onRestartRequested)
	RemoteEvents.RestartRequested.OnServerEvent:Connect(onRestartRequested)

	for _, player in ipairs(Players:GetPlayers()) do
		detectPlayer(player)
	end

	fireLobbyStateChanged()
	fireRoundStateChanged()

	_G.FastGuesserPrototype = {
		setPlayerSecret = setPlayerSecret,
		submitGuess = submitGuess,
		getPrototypeMatch = getPrototypeMatch,
	}
end

return PrototypeMatchServer
