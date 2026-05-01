local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("EconomyService"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local LeaderboardService = {}

-- Session-only stats for the current server; this is the seam for future DataStore/global rankings.
local statsByPlayerId = {}

local function getPlayerKey(playerOrUserId)
	if typeof(playerOrUserId) == "Instance" then
		return tostring(playerOrUserId.UserId)
	end

	return tostring(playerOrUserId)
end

local function ensureStats(playerOrUserId)
	local playerKey = getPlayerKey(playerOrUserId)
	statsByPlayerId[playerKey] = statsByPlayerId[playerKey] or {
		wins = 0,
		currentStreak = 0,
	}

	return statsByPlayerId[playerKey]
end

local function getDisplayName(player)
	if player.DisplayName and player.DisplayName ~= "" then
		return player.DisplayName
	end

	return player.Name
end

local function buildEntries()
	local entries = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local stats = ensureStats(player)
		table.insert(entries, {
			playerId = player.UserId,
			name = getDisplayName(player),
			wins = stats.wins,
			currentStreak = stats.currentStreak,
			coins = EconomyService.getBalance(player),
		})
	end

	table.sort(entries, function(left, right)
		if left.wins ~= right.wins then
			return left.wins > right.wins
		end
		if left.currentStreak ~= right.currentStreak then
			return left.currentStreak > right.currentStreak
		end
		if left.coins ~= right.coins then
			return left.coins > right.coins
		end
		return left.name < right.name
	end)

	for rank, entry in ipairs(entries) do
		entry.rank = rank
	end

	return entries
end

function LeaderboardService.ensurePlayer(player)
	ensureStats(player)
end

function LeaderboardService.recordRound(playerIds, winner, isTie)
	for _, playerId in ipairs(playerIds) do
		local stats = ensureStats(playerId)
		if isTie then
			stats.currentStreak = 0
		elseif playerId == winner then
			stats.wins += 1
			stats.currentStreak += 1
		else
			stats.currentStreak = 0
		end
	end

	LeaderboardService.broadcastState()
end

function LeaderboardService.buildState(message)
	local entries = buildEntries()
	local stateMessage = message
	if not stateMessage then
		stateMessage = if #entries == 0 then "No players in this server yet." else "Session leaderboard"
	end

	return {
		entries = entries,
		message = stateMessage,
	}
end

function LeaderboardService.openLeaderboard(player)
	RemoteEvents.LeaderboardOpened:FireClient(player, LeaderboardService.buildState())
end

function LeaderboardService.broadcastState()
	RemoteEvents.LeaderboardStateChanged:FireAllClients(LeaderboardService.buildState())
end

function LeaderboardService.clearSession(player)
	statsByPlayerId[getPlayerKey(player)] = nil
	LeaderboardService.broadcastState()
end

return LeaderboardService
