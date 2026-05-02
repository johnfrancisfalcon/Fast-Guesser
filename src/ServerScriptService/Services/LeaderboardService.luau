local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local EconomyService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("EconomyService"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local LeaderboardService = {}

local DATASTORE_NAME = "FastGuesserStats_v1"
local DATA_VERSION = 1
local statsStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local statsByPlayerId = {}
local loadFailedByPlayerId = {}
local loadedByPlayerId = {}
local sessionOnlyByPlayerId = {}

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

local function getStoreKey(playerOrUserId)
	return "player_" .. getPlayerKey(playerOrUserId)
end

local function shouldUseSessionFallback(loadError)
	return RunService:IsStudio() and string.find(tostring(loadError), "Studio access to APIs is not allowed", 1, true) ~= nil
end

local function isLocalStudioPlayer(player)
	return RunService:IsStudio() and player.UserId < 0
end

local function applyLoadedStats(player, data)
	local playerKey = getPlayerKey(player)
	local stats = ensureStats(player)
	if type(data) ~= "table" then
		return stats
	end

	stats.wins = math.max(0, math.floor(tonumber(data.wins) or 0))
	stats.currentStreak = math.max(0, math.floor(tonumber(data.currentStreak) or 0))
	return stats
end

local function buildSaveData(playerOrUserId)
	local stats = ensureStats(playerOrUserId)
	return {
		version = DATA_VERSION,
		wins = stats.wins,
		currentStreak = stats.currentStreak,
	}
end

local function saveStats(playerOrUserId)
	local playerKey = getPlayerKey(playerOrUserId)
	if loadFailedByPlayerId[playerKey] then
		warn("[FastGuesser] Skipping leaderboard save because stats load failed for", playerKey)
		return false
	end

	if sessionOnlyByPlayerId[playerKey] then
		return false
	end

	if not loadedByPlayerId[playerKey] then
		return false
	end

	local ok, saveError = pcall(function()
		statsStore:SetAsync(getStoreKey(playerOrUserId), buildSaveData(playerOrUserId))
	end)

	if not ok then
		warn("[FastGuesser] Leaderboard save failed for", playerKey, saveError)
		return false
	end

	return true
end

local function saveStatsDeferred(playerOrUserId)
	task.spawn(function()
		saveStats(playerOrUserId)
	end)
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
	local playerKey = getPlayerKey(player)
	if isLocalStudioPlayer(player) and not loadedByPlayerId[playerKey] then
		ensureStats(player)
		loadedByPlayerId[playerKey] = true
		sessionOnlyByPlayerId[playerKey] = true
	end

	if loadedByPlayerId[playerKey] or loadFailedByPlayerId[playerKey] then
		ensureStats(player)
		return
	end

	local ok, data = pcall(function()
		return statsStore:GetAsync(getStoreKey(player))
	end)

	if ok then
		applyLoadedStats(player, data)
		loadedByPlayerId[playerKey] = true
	elseif shouldUseSessionFallback(data) then
		warn("[FastGuesser] DataStores unavailable in Studio; using session-only leaderboard stats for", playerKey)
		ensureStats(player)
		loadedByPlayerId[playerKey] = true
		sessionOnlyByPlayerId[playerKey] = true
	else
		warn("[FastGuesser] Leaderboard load failed for", playerKey, data)
		loadFailedByPlayerId[playerKey] = true
		ensureStats(player)
	end
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

	for _, playerId in ipairs(playerIds) do
		saveStatsDeferred(playerId)
	end
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
	local playerKey = getPlayerKey(player)
	statsByPlayerId[playerKey] = nil
	loadFailedByPlayerId[playerKey] = nil
	loadedByPlayerId[playerKey] = nil
	sessionOnlyByPlayerId[playerKey] = nil
	LeaderboardService.broadcastState()
end

function LeaderboardService.savePlayer(player)
	return saveStats(player)
end

return LeaderboardService
