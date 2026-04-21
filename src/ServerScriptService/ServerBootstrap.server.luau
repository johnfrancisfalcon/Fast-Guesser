local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MatchService = require(ServerScriptService.Services.MatchService)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local prototypePlayers = {}
local prototypeMatchId = nil

local function getPrototypeMatch()
	if not prototypeMatchId then
		return nil
	end

	return MatchService.getMatch(prototypeMatchId)
end

local function tryStartPrototypeMatch()
	if prototypeMatchId or #prototypePlayers < 2 then
		return
	end

	local playerOne = prototypePlayers[1]
	local playerTwo = prototypePlayers[2]
	local prototypeMatch, createError = MatchService.createMatch(playerOne.UserId, playerTwo.UserId)
	if not prototypeMatch then
		error(createError)
	end

	prototypeMatchId = prototypeMatch.id

	-- Ask both prototype players to enter their secret.
	RemoteEvents.SecretRequested:FireClient(playerOne)
	RemoteEvents.SecretRequested:FireClient(playerTwo)
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

Players.PlayerAdded:Connect(function(player)
	if #prototypePlayers >= 2 then
		return
	end

	table.insert(prototypePlayers, player)
	tryStartPrototypeMatch()
end)

for _, player in ipairs(Players:GetPlayers()) do
	if #prototypePlayers < 2 then
		table.insert(prototypePlayers, player)
	end
end

tryStartPrototypeMatch()

-- Client -> server: player submits their secret string.
RemoteEvents.SecretSubmitted.OnServerEvent:Connect(function(player, secret)
	local ok, message = setPlayerSecret(player.UserId, secret)
	if not ok then
		warn(message)
		return
	end

	local match = getPrototypeMatch()
	if match and match.currentTurn then
		RemoteEvents.TurnChanged:FireAllClients(match.currentTurn)
	end
end)

-- Client -> server: player submits a guess string.
RemoteEvents.GuessSubmitted.OnServerEvent:Connect(function(player, guess)
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

	RemoteEvents.TurnChanged:FireAllClients(match.currentTurn)

	if match.winner then
		RemoteEvents.GameOver:FireAllClients(match.winner)
	end
end)

-- Prototype-only references so these entry points are easy to find while testing.
local PrototypeServer = {
	setPlayerSecret = setPlayerSecret,
	submitGuess = submitGuess,
	getPrototypeMatch = getPrototypeMatch,
}

_G.FastGuesserPrototype = PrototypeServer
