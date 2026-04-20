local ServerScriptService = game:GetService("ServerScriptService")

local MatchService = require(ServerScriptService.Services.MatchService)

local PLAYER_ONE_ID = 101
local PLAYER_TWO_ID = 202

local prototypeMatch, createError = MatchService.createMatch(PLAYER_ONE_ID, PLAYER_TWO_ID)
if not prototypeMatch then
	error(createError)
end

local prototypeMatchId = prototypeMatch.id

local function setPlayerSecret(playerId, secret)
	return MatchService.setPlayerSecret(prototypeMatchId, playerId, secret)
end

local function submitGuess(playerId, guess)
	return MatchService.submitGuess(prototypeMatchId, playerId, guess)
end

local function getPrototypeMatch()
	return MatchService.getMatch(prototypeMatchId)
end

-- Later: connect a RemoteEvent here for players submitting their secret.
-- The handler should call setPlayerSecret(player.UserId, secret).

-- Later: connect a RemoteEvent here for players submitting a guess.
-- The handler should call submitGuess(player.UserId, guess).

-- Prototype-only references so these entry points are easy to find while testing.
local PrototypeServer = {
	setPlayerSecret = setPlayerSecret,
	submitGuess = submitGuess,
	getPrototypeMatch = getPrototypeMatch,
}

_G.FastGuesserPrototype = PrototypeServer
