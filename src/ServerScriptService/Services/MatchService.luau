local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeedbackLogic = require(ReplicatedStorage.Shared.FeedbackLogic)
local GuessValidator = require(script.Parent.GuessValidator)

local MatchService = {}

local TIE_WINNER = "Tie"
local MODES = {
	Classic4Digit = "classic_4_digit",
	HigherLower100 = "higher_lower_100",
}
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

local function getMode(match)
	return match.mode or MODES.Classic4Digit
end

local function validateSecretForMode(mode, secret)
	if mode == MODES.HigherLower100 then
		return GuessValidator.validateHighLowSecret(secret)
	end

	return GuessValidator.validateSecret(secret)
end

local function validateGuessForMode(mode, guess)
	if mode == MODES.HigherLower100 then
		return GuessValidator.validateHighLowGuess(guess)
	end

	return GuessValidator.validateGuess(guess)
end

local function buildClassicGuessResult(match, playerId, opponentSecret, guess)
	local exactMatches = FeedbackLogic.getExactMatches(opponentSecret, guess)
	local locked = FeedbackLogic.mergeLocked(match.lockedPositions[playerId], exactMatches)

	match.lockedPositions[playerId] = locked

	return {
		mode = MODES.Classic4Digit,
		playerId = playerId,
		guess = guess,
		matches = exactMatches,
		lockedPositions = locked,
		isSolved = FeedbackLogic.isSolved(locked),
	}
end

local function buildHigherLowerGuessResult(playerId, opponentSecret, guess)
	local secretNumber = tonumber(opponentSecret)
	local guessNumber = tonumber(guess)
	local feedback = "Correct"

	if guessNumber < secretNumber then
		feedback = "Higher"
	elseif guessNumber > secretNumber then
		feedback = "Lower"
	end

	return {
		mode = MODES.HigherLower100,
		playerId = playerId,
		guess = tostring(guessNumber),
		feedback = feedback,
		isSolved = feedback == "Correct",
	}
end

local function buildGuessResult(match, playerId, opponentSecret, guess)
	if getMode(match) == MODES.HigherLower100 then
		return buildHigherLowerGuessResult(playerId, opponentSecret, guess)
	end

	return buildClassicGuessResult(match, playerId, opponentSecret, guess)
end

function MatchService.createMatch(playerOneId, playerTwoId, mode)
	if not playerOneId or not playerTwoId then
		return nil, "A match needs two players."
	end

	if playerOneId == playerTwoId then
		return nil, "A match needs two different players."
	end

	nextMatchId += 1

	local match = {
		id = nextMatchId,
		mode = mode or MODES.Classic4Digit,
		players = { playerOneId, playerTwoId },
		secrets = {},
		lockedPositions = {
			[playerOneId] = {},
			[playerTwoId] = {},
		},
		currentTurn = nil,
		winner = nil,
		pendingWinner = nil,
		isTie = false,
		guessHistory = {},
	}

	matches[match.id] = match

	return match
end

function MatchService.getMatch(matchId)
	return matches[matchId]
end

function MatchService.destroyMatch(matchId)
	matches[matchId] = nil
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

	local isValid, message = validateSecretForMode(getMode(match), secret)
	if not isValid then
		return false, message
	end

	match.secrets[playerId] = if getMode(match) == MODES.HigherLower100 then tostring(tonumber(secret)) else secret

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

	local isValid, message = validateGuessForMode(getMode(match), guess)
	if not isValid then
		return false, message
	end

	local opponentSecret = match.secrets[opponentId]
	local result = buildGuessResult(match, playerId, opponentSecret, guess)

	table.insert(match.guessHistory, result)

	if result.isSolved and match.pendingWinner then
		match.winner = TIE_WINNER
		match.isTie = true
		match.currentTurn = nil
	elseif result.isSolved and playerId == match.players[1] then
		match.pendingWinner = playerId
		advanceTurn(match)
	elseif result.isSolved then
		match.winner = playerId
		match.currentTurn = nil
	elseif match.pendingWinner then
		match.winner = match.pendingWinner
		match.currentTurn = nil
	else
		advanceTurn(match)
	end

	return true, result
end

return MatchService
