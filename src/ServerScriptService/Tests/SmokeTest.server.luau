local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RUN_SMOKE_TEST = false
if not RUN_SMOKE_TEST then
	return
end

local MatchService = require(script.Parent.Parent.Services.MatchService)
local FeedbackLogic = require(ReplicatedStorage.Shared.FeedbackLogic)

local PLAYER_A_ID = 101
local PLAYER_B_ID = 202

local function formatPositions(positions)
	local values = {}

	for i = 1, 4 do
		values[i] = positions[i] or "_"
	end

	return table.concat(values, " ")
end

local function printGuessResult(label, playerId, guess, result)
	print(label .. " player=" .. playerId .. " guess=" .. guess)
	print("feedback: " .. formatPositions(result.matches))
	print("locked: " .. formatPositions(result.lockedPositions))
	print("isSolved: " .. tostring(result.isSolved))
end

local match, createError = MatchService.createMatch(PLAYER_A_ID, PLAYER_B_ID)
if not match then
	print("SmokeTest setup failed: " .. createError)
	return
end

local matchId = match.id

local secretASet, secretAError = MatchService.setPlayerSecret(matchId, PLAYER_A_ID, "2209")
if not secretASet then
	print("SmokeTest setup failed: " .. secretAError)
	return
end

local secretBSet, secretBError = MatchService.setPlayerSecret(matchId, PLAYER_B_ID, "0574")
if not secretBSet then
	print("SmokeTest setup failed: " .. secretBError)
	return
end

local guesses = {
	{ playerId = PLAYER_A_ID, guess = "0111" },
	{ playerId = PLAYER_B_ID, guess = "2111" },
	{ playerId = PLAYER_A_ID, guess = "1511" },
	{ playerId = PLAYER_B_ID, guess = "1211" },
	{ playerId = PLAYER_A_ID, guess = "1171" },
	{ playerId = PLAYER_B_ID, guess = "1101" },
	{ playerId = PLAYER_A_ID, guess = "1114" },
}

for turnNumber, turn in ipairs(guesses) do
	local ok, result = MatchService.submitGuess(matchId, turn.playerId, turn.guess)

	if not ok then
		print("SmokeTest turn " .. turnNumber .. " failed: " .. result)
		return
	end

	printGuessResult("Turn " .. turnNumber, turn.playerId, turn.guess, result)

	if FeedbackLogic.isSolved(result.lockedPositions) then
		print("winner: " .. tostring(turn.playerId))
		return
	end
end

print("SmokeTest ended without a winner.")
