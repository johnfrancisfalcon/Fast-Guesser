local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

print("[FastGuesser] bootstrap started")

local MatchService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("MatchService"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local prototypePlayers = {}
local prototypeMatchId = nil
local secretRequestLoopStarted = false

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
	print("[FastGuesser] match created", prototypeMatchId, playerOne.UserId, playerTwo.UserId)

	task.spawn(function()
		if secretRequestLoopStarted then
			return
		end

		secretRequestLoopStarted = true

		-- Ask both prototype players to enter their secret. Repeat briefly so Studio
		-- clients that are still starting up do not miss the one-time request.
		for _ = 1, 10 do
			if bothSecretsSubmitted() then
				return
			end

			print("[FastGuesser] secret requested", playerOne.UserId)
			RemoteEvents.SecretRequested:FireClient(playerOne)

			print("[FastGuesser] secret requested", playerTwo.UserId)
			RemoteEvents.SecretRequested:FireClient(playerTwo)

			task.wait(1)
		end
	end)
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
	tryStartPrototypeMatch()
end

Players.PlayerAdded:Connect(detectPlayer)

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
		RemoteEvents.TurnChanged:FireAllClients(match.currentTurn)
	end
end)

-- Client -> server: player submits a guess string.
RemoteEvents.GuessSubmitted.OnServerEvent:Connect(function(player, guess)
	print("[FastGuesser] guess submitted", player.UserId, guess)

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
