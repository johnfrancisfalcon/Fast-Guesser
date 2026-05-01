local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local EconomyService = {}

local STARTING_BALANCE = 0
local REWARDS = {
	Win = 35,
	Loss = 12,
	Tie = 20,
	TestClaim = 25,
}

local SHOP_CATALOG = {
	{
		id = "trail_neon",
		name = "Neon Trail",
		category = "Trail",
		price = 45,
		description = "A bright trail placeholder for future character cosmetics.",
	},
	{
		id = "theme_midnight",
		name = "Midnight Panel Theme",
		category = "Theme",
		price = 70,
		description = "A future UI skin for match panels.",
	},
	{
		id = "tag_quick_cracker",
		name = "Quick Cracker Tag",
		category = "Title",
		price = 95,
		description = "A lobby title tag placeholder.",
	},
	{
		id = "spark_lobby",
		name = "Lobby Spark FX",
		category = "Lobby",
		price = 120,
		description = "A future lobby cosmetic effect.",
	},
}

local balancesByPlayerId = {}
local ownedItemsByPlayerId = {}
local equippedItemsByPlayerId = {}
local rewardClaimedByPlayerId = {}

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

local function getCatalogItem(itemId)
	for _, item in ipairs(SHOP_CATALOG) do
		if item.id == itemId then
			return item
		end
	end

	return nil
end

local function ensureInventory(playerOrUserId)
	local playerKey = getPlayerKey(playerOrUserId)
	ownedItemsByPlayerId[playerKey] = ownedItemsByPlayerId[playerKey] or {}
	equippedItemsByPlayerId[playerKey] = equippedItemsByPlayerId[playerKey] or {}
	return ownedItemsByPlayerId[playerKey], equippedItemsByPlayerId[playerKey]
end

local function buildShopState(player, message)
	local ownedItems, equippedItems = ensureInventory(player)
	return {
		balance = EconomyService.getBalance(player),
		catalog = SHOP_CATALOG,
		ownedItems = ownedItems,
		equippedItems = equippedItems,
		message = message,
	}
end

local function buildRewardState(player, message)
	local playerKey = getPlayerKey(player)
	return {
		balance = EconomyService.getBalance(player),
		claimAmount = REWARDS.TestClaim,
		claimed = rewardClaimedByPlayerId[playerKey] == true,
		message = message,
	}
end

local function fireShopState(player, message)
	RemoteEvents.ShopStateChanged:FireClient(player, buildShopState(player, message))
end

local function fireRewardState(player, message)
	RemoteEvents.RewardStateChanged:FireClient(player, buildRewardState(player, message))
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

	ensureInventory(player)
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
		fireShopState(player)
		fireRewardState(player)
	end

	return balancesByPlayerId[playerKey]
end

function EconomyService.trySpendCurrency(player, amount, reason)
	if EconomyService.getBalance(player) < amount then
		return false, "Not enough coins."
	end

	EconomyService.addCurrency(player, -amount, reason)
	return true
end

function EconomyService.getMatchReward(isWinner, isTie)
	if isTie then
		return REWARDS.Tie
	end

	return if isWinner then REWARDS.Win else REWARDS.Loss
end

function EconomyService.openShop(player)
	fireShopState(player)
	RemoteEvents.ShopOpened:FireClient(player, buildShopState(player, "Select an item."))
end

function EconomyService.purchaseItem(player, itemId)
	local item = getCatalogItem(itemId)
	if not item then
		fireShopState(player, "Item not found.")
		return false, "Item not found."
	end

	local ownedItems = ensureInventory(player)
	if ownedItems[item.id] then
		fireShopState(player, "Already owned.")
		return false, "Already owned."
	end

	local spent, spendError = EconomyService.trySpendCurrency(player, item.price, "ShopPurchase")
	if not spent then
		fireShopState(player, spendError)
		return false, spendError
	end

	ownedItems[item.id] = true
	fireShopState(player, "Purchased " .. item.name .. ".")
	return true
end

function EconomyService.equipItem(player, itemId)
	local item = getCatalogItem(itemId)
	if not item then
		fireShopState(player, "Item not found.")
		return false, "Item not found."
	end

	local ownedItems, equippedItems = ensureInventory(player)
	if not ownedItems[item.id] then
		fireShopState(player, "Item is not owned.")
		return false, "Item is not owned."
	end

	equippedItems[item.category] = item.id
	fireShopState(player, "Equipped " .. item.name .. ".")
	return true
end

function EconomyService.openRewards(player)
	fireRewardState(player)
	RemoteEvents.RewardsOpened:FireClient(player, buildRewardState(player))
end

function EconomyService.claimTestReward(player)
	local playerKey = getPlayerKey(player)
	if rewardClaimedByPlayerId[playerKey] then
		fireRewardState(player, "Reward already claimed this session.")
		return false, "Reward already claimed."
	end

	rewardClaimedByPlayerId[playerKey] = true
	EconomyService.addCurrency(player, REWARDS.TestClaim, "TestReward")
	fireRewardState(player, "Reward claimed.")
	return true
end

function EconomyService.clearSession(player)
	local playerKey = getPlayerKey(player)
	balancesByPlayerId[playerKey] = nil
	ownedItemsByPlayerId[playerKey] = nil
	equippedItemsByPlayerId[playerKey] = nil
	rewardClaimedByPlayerId[playerKey] = nil
end

return EconomyService
