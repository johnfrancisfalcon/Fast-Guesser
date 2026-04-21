-- Lune-compatible path (replace with Roblox service path before Studio sync)
local FeedbackLogic = require("../../ReplicatedStorage/Shared/FeedbackLogic")
-- Lune-compatible path (replace with Roblox service path before Studio sync)
local GuessValidator = require("./GuessValidator")

local MatchService = {}

local nextMatchId = 0
local matches = {}

local function getOpponentId(match, playerId)
	if match.players[1] == playerId then
		return match.players[2]
	end

	if match.players[2] == playerId then
		return match.players[1]
	end

	return nil
end

local function bothSecretsReady(match)
	for _, playerId in ipairs(match.players) do
		if not match.secrets[playerId] then
			return false
		end
	end

	return true
end

local function advanceTurn(match)
	if match.currentTurn == match.players[1] then
		match.currentTurn = match.players[2]
	else
		match.currentTurn = match.players[1]
	end
end

function MatchService.createMatch(playerOneId, playerTwoId)
	if not playerOneId or not playerTwoId then
		return nil, "A match needs two players."
	end

	if playerOneId == playerTwoId then
		return nil, "A match needs two different players."
	end

	nextMatchId += 1

	local match = {
		id = nextMatchId,
		players = { playerOneId, playerTwoId },
		secrets = {},
		lockedPositions = {
			[playerOneId] = {},
			[playerTwoId] = {},
		},
		currentTurn = nil,
		winner = nil,
		guessHistory = {},
	}

	matches[match.id] = match

	return match
end

function MatchService.getMatch(matchId)
	return matches[matchId]
end

function MatchService.getCurrentTurn(matchId)
	local match = matches[matchId]
	if not match then
		return nil
	end

	return match.currentTurn
end

function MatchService.getLockedPositions(matchId, playerId)
	local match = matches[matchId]
	if not match then
		return nil
	end

	return match.lockedPositions[playerId]
end

function MatchService.setPlayerSecret(matchId, playerId, secret)
	local match = matches[matchId]
	if not match then
		return false, "Match not found."
	end

	if not getOpponentId(match, playerId) then
		return false, "Player is not in this match."
	end

	local isValid, message = GuessValidator.validateSecret(secret)
	if not isValid then
		return false, message
	end

	match.secrets[playerId] = secret

	if bothSecretsReady(match) and not match.currentTurn then
		match.currentTurn = match.players[1]
	end

	return true
end

function MatchService.submitGuess(matchId, playerId, guess)
	local match = matches[matchId]
	if not match then
		return false, "Match not found."
	end

	if match.winner then
		return false, "Match is already finished."
	end

	local opponentId = getOpponentId(match, playerId)
	if not opponentId then
		return false, "Player is not in this match."
	end

	if not bothSecretsReady(match) then
		return false, "Both players must set secrets before guessing."
	end

	if match.currentTurn ~= playerId then
		return false, "It is not this player's turn."
	end

	local isValid, message = GuessValidator.validateGuess(guess)
	if not isValid then
		return false, message
	end

	local opponentSecret = match.secrets[opponentId]
	local exactMatches = FeedbackLogic.getExactMatches(opponentSecret, guess)
	local locked = FeedbackLogic.mergeLocked(match.lockedPositions[playerId], exactMatches)

	match.lockedPositions[playerId] = locked

	local result = {
		playerId = playerId,
		guess = guess,
		matches = exactMatches,
		lockedPositions = locked,
		isSolved = FeedbackLogic.isSolved(locked),
	}

	table.insert(match.guessHistory, result)

	if result.isSolved then
		match.winner = playerId
	else
		advanceTurn(match)
	end

	return true, result
end

return MatchService
