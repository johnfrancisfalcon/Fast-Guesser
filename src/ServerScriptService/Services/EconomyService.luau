local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local EconomyService = {}

local STARTING_BALANCE = 0
local REWARDS = {
	Win = 35,
	Loss = 12,
	Tie = 20,
}

local balancesByPlayerId = {}

local function getPlayerKey(playerOrUserId)
	if typeof(playerOrUserId) == "Instance" then
		return tostring(playerOrUserId.UserId)
	end

	return tostring(playerOrUserId)
end

local function getPlayerByUserId(userId)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == userId then
			return player
		end
	end

	return nil
end

local function fireBalanceChanged(player, delta, reason)
	RemoteEvents.CurrencyChanged:FireClient(player, {
		balance = EconomyService.getBalance(player),
		delta = delta or 0,
		reason = reason,
	})
end

function EconomyService.ensureAccount(player)
	local playerKey = getPlayerKey(player)
	if balancesByPlayerId[playerKey] == nil then
		balancesByPlayerId[playerKey] = STARTING_BALANCE
	end

	fireBalanceChanged(player, 0, "AccountLoaded")
end

function EconomyService.getBalance(playerOrUserId)
	local playerKey = getPlayerKey(playerOrUserId)
	return balancesByPlayerId[playerKey] or STARTING_BALANCE
end

function EconomyService.addCurrency(playerOrUserId, amount, reason)
	local playerKey = getPlayerKey(playerOrUserId)
	balancesByPlayerId[playerKey] = EconomyService.getBalance(playerOrUserId) + amount

	local player = if typeof(playerOrUserId) == "Instance" then playerOrUserId else getPlayerByUserId(playerOrUserId)
	if player then
		fireBalanceChanged(player, amount, reason)
	end

	return balancesByPlayerId[playerKey]
end

function EconomyService.getMatchReward(isWinner, isTie)
	if isTie then
		return REWARDS.Tie
	end

	return if isWinner then REWARDS.Win else REWARDS.Loss
end

function EconomyService.clearSession(player)
	balancesByPlayerId[getPlayerKey(player)] = nil
end

return EconomyService
