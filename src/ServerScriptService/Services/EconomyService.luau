local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local EconomyService = {}

local STARTING_BALANCE = 0
local DATASTORE_NAME = "FastGuesserProgression_v1"
local DATA_VERSION = 1
local REWARDS = {
	Win = 35,
	Loss = 12,
	Tie = 20,
	DailyClaim = 25,
}

local REWARD_WHEEL_SEGMENTS = {
	{ label = "+15", coins = 15, weight = 35 },
	{ label = "+25", coins = 25, weight = 30 },
	{ label = "+40", coins = 40, weight = 20 },
	{ label = "+75", coins = 75, weight = 10 },
	{ label = "Bonus", coins = 100, weight = 5 },
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
local processedReceiptsByPlayerId = {}
local rewardClaimedByPlayerId = {}
local lastDailyClaimDayByPlayerId = {}
local loadFailedByPlayerId = {}
local loadedByPlayerId = {}
local sessionOnlyByPlayerId = {}
local progressionStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local ensureInventory

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

local function isCatalogItemId(itemId)
	return getCatalogItem(itemId) ~= nil
end

local function sanitizeOwnedItems(rawOwnedItems)
	local ownedItems = {}

	if type(rawOwnedItems) ~= "table" then
		return ownedItems
	end

	for itemId, owned in pairs(rawOwnedItems) do
		if owned == true and isCatalogItemId(itemId) then
			ownedItems[itemId] = true
		end
	end

	return ownedItems
end

local function sanitizeEquippedItems(rawEquippedItems, ownedItems)
	local equippedItems = {}

	if type(rawEquippedItems) ~= "table" then
		return equippedItems
	end

	for category, itemId in pairs(rawEquippedItems) do
		local item = getCatalogItem(itemId)
		if item and item.category == category and ownedItems[itemId] == true then
			equippedItems[category] = itemId
		end
	end

	return equippedItems
end

local function sanitizeProcessedReceipts(rawProcessedReceipts)
	local processedReceipts = {}

	if type(rawProcessedReceipts) ~= "table" then
		return processedReceipts
	end

	for receiptId, processed in pairs(rawProcessedReceipts) do
		if processed == true and type(receiptId) == "string" then
			processedReceipts[receiptId] = true
		end
	end

	return processedReceipts
end

local function sanitizeRewardState(rawRewards)
	if type(rawRewards) ~= "table" or type(rawRewards.lastDailyClaimDay) ~= "string" then
		return nil
	end

	return rawRewards.lastDailyClaimDay
end

local function getCurrentUtcDay()
	local now = os.date("!*t")
	return string.format("%04d-%02d-%02d", now.year, now.month, now.day)
end

local function shouldUseSessionFallback(loadError)
	return RunService:IsStudio() and string.find(tostring(loadError), "Studio access to APIs is not allowed", 1, true) ~= nil
end

local function isLocalStudioPlayer(player)
	return RunService:IsStudio() and player.UserId < 0
end

local function getStoreKey(playerOrUserId)
	local playerKey = getPlayerKey(playerOrUserId)
	return "player_" .. playerKey
end

local function buildSaveData(playerOrUserId)
	local playerKey = getPlayerKey(playerOrUserId)
	local ownedItems, equippedItems = ensureInventory(playerOrUserId)

	return {
		version = DATA_VERSION,
		coins = balancesByPlayerId[playerKey] or STARTING_BALANCE,
		ownedItems = ownedItems,
		equippedItems = equippedItems,
		processedReceipts = processedReceiptsByPlayerId[playerKey] or {},
		rewards = {
			lastDailyClaimDay = lastDailyClaimDayByPlayerId[playerKey],
		},
	}
end

local function applyLoadedData(player, data)
	local playerKey = getPlayerKey(player)
	if type(data) ~= "table" then
		balancesByPlayerId[playerKey] = STARTING_BALANCE
		ownedItemsByPlayerId[playerKey] = {}
		equippedItemsByPlayerId[playerKey] = {}
		processedReceiptsByPlayerId[playerKey] = {}
		lastDailyClaimDayByPlayerId[playerKey] = nil
		return
	end

	local coins = tonumber(data.coins)
	balancesByPlayerId[playerKey] = if coins then math.max(0, math.floor(coins)) else STARTING_BALANCE
	local ownedItems = sanitizeOwnedItems(data.ownedItems)
	ownedItemsByPlayerId[playerKey] = ownedItems
	equippedItemsByPlayerId[playerKey] = sanitizeEquippedItems(data.equippedItems, ownedItems)
	processedReceiptsByPlayerId[playerKey] = sanitizeProcessedReceipts(data.processedReceipts)
	lastDailyClaimDayByPlayerId[playerKey] = sanitizeRewardState(data.rewards)
end

local function saveProgression(playerOrUserId)
	local playerKey = getPlayerKey(playerOrUserId)
	if loadFailedByPlayerId[playerKey] then
		-- Avoid overwriting real player data with defaults from a failed load.
		warn("[FastGuesser] Skipping economy save because progression load failed for", playerKey)
		return false
	end

	if sessionOnlyByPlayerId[playerKey] then
		return false
	end

	if not loadedByPlayerId[playerKey] then
		return false
	end

	local saveData = buildSaveData(playerOrUserId)
	local ok, saveError = pcall(function()
		progressionStore:SetAsync(getStoreKey(playerOrUserId), saveData)
	end)

	if not ok then
		warn("[FastGuesser] Economy save failed for", playerKey, saveError)
		return false
	end

	return true
end

local function saveProgressionDeferred(playerOrUserId)
	task.spawn(function()
		saveProgression(playerOrUserId)
	end)
end

function ensureInventory(playerOrUserId)
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
	local today = getCurrentUtcDay()
	local lastClaimDay = lastDailyClaimDayByPlayerId[playerKey]
	local progressionReady = loadedByPlayerId[playerKey] == true and loadFailedByPlayerId[playerKey] ~= true
	local canClaim = progressionReady and lastClaimDay ~= today
	return {
		balance = EconomyService.getBalance(player),
		claimAmount = REWARDS.DailyClaim,
		claimed = not canClaim,
		canClaim = canClaim,
		lastClaimDay = lastClaimDay,
		nextClaimText = if not progressionReady then "Progression loading" elseif canClaim then "Ready now" else "Come back tomorrow",
		wheelSegments = REWARD_WHEEL_SEGMENTS,
		message = message,
	}
end

local function buildCosmeticsState()
	local equippedByPlayerId = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local _, equippedItems = ensureInventory(player)
		equippedByPlayerId[tostring(player.UserId)] = equippedItems
	end

	return {
		equippedByPlayerId = equippedByPlayerId,
	}
end

local function broadcastCosmeticsState()
	RemoteEvents.CosmeticsStateChanged:FireAllClients(buildCosmeticsState())
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
	if isLocalStudioPlayer(player) and not loadedByPlayerId[playerKey] then
		-- Local Studio test clients use negative user ids and cannot use live DataStores.
		applyLoadedData(player, nil)
		loadedByPlayerId[playerKey] = true
		sessionOnlyByPlayerId[playerKey] = true
	end

	if not loadedByPlayerId[playerKey] and not loadFailedByPlayerId[playerKey] then
		local ok, data = pcall(function()
			return progressionStore:GetAsync(getStoreKey(player))
		end)

		if ok then
			applyLoadedData(player, data)
			loadedByPlayerId[playerKey] = true
		elseif shouldUseSessionFallback(data) then
			warn("[FastGuesser] DataStores unavailable in Studio; using session-only economy for", playerKey)
			applyLoadedData(player, nil)
			loadedByPlayerId[playerKey] = true
			sessionOnlyByPlayerId[playerKey] = true
		else
			warn("[FastGuesser] Economy load failed for", playerKey, data)
			loadFailedByPlayerId[playerKey] = true
			balancesByPlayerId[playerKey] = STARTING_BALANCE
			ownedItemsByPlayerId[playerKey] = {}
			equippedItemsByPlayerId[playerKey] = {}
			processedReceiptsByPlayerId[playerKey] = {}
			lastDailyClaimDayByPlayerId[playerKey] = nil
		end
	elseif balancesByPlayerId[playerKey] == nil then
		balancesByPlayerId[playerKey] = STARTING_BALANCE
	end

	ensureInventory(player)
	fireBalanceChanged(player, 0, "AccountLoaded")
	broadcastCosmeticsState()
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
		if reason ~= "ShopPurchase" then
			saveProgressionDeferred(player)
		end
	end

	return balancesByPlayerId[playerKey]
end

function EconomyService.grantProductCurrency(player, amount, purchaseId)
	local playerKey = getPlayerKey(player)
	if loadFailedByPlayerId[playerKey] or not loadedByPlayerId[playerKey] then
		return false, "Progression is not ready."
	end

	local receiptKey = tostring(purchaseId)
	local grantAmount = math.max(0, math.floor(tonumber(amount) or 0))
	if grantAmount <= 0 then
		return false, "Invalid product grant."
	end

	local alreadyProcessed = false
	local updatedData = nil
	local ok, updateError = pcall(function()
		updatedData = progressionStore:UpdateAsync(getStoreKey(player), function(currentData)
			currentData = if type(currentData) == "table" then currentData else {}
			local processedReceipts = sanitizeProcessedReceipts(currentData.processedReceipts)
			if processedReceipts[receiptKey] == true then
				alreadyProcessed = true
				return currentData
			end

			currentData.version = DATA_VERSION
			local storedCoins = math.max(0, math.floor(tonumber(currentData.coins) or STARTING_BALANCE))
			currentData.coins = math.max(storedCoins, EconomyService.getBalance(player)) + grantAmount
			currentData.ownedItems = sanitizeOwnedItems(currentData.ownedItems)
			for itemId, owned in pairs(ownedItemsByPlayerId[playerKey] or {}) do
				if owned == true and isCatalogItemId(itemId) then
					currentData.ownedItems[itemId] = true
				end
			end
			currentData.equippedItems = sanitizeEquippedItems(currentData.equippedItems, currentData.ownedItems)
			for category, itemId in pairs(equippedItemsByPlayerId[playerKey] or {}) do
				local item = getCatalogItem(itemId)
				if item and item.category == category and currentData.ownedItems[itemId] == true then
					currentData.equippedItems[category] = itemId
				end
			end
			processedReceipts[receiptKey] = true
			currentData.processedReceipts = processedReceipts
			return currentData
		end)
	end)

	if not ok then
		warn("[FastGuesser] Product currency grant failed for", playerKey, updateError)
		return false, "Receipt update failed."
	end

	applyLoadedData(player, updatedData)
	if alreadyProcessed then
		fireBalanceChanged(player, 0, "DeveloperProductDuplicate")
	else
		fireBalanceChanged(player, grantAmount, "DeveloperProduct")
	end
	fireShopState(player)
	fireRewardState(player)

	return true
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
	saveProgressionDeferred(player)
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

	if equippedItems[item.category] == item.id then
		equippedItems[item.category] = nil
		fireShopState(player, "Unequipped " .. item.name .. ".")
		broadcastCosmeticsState()
		saveProgressionDeferred(player)
		return true
	end

	equippedItems[item.category] = item.id
	fireShopState(player, "Equipped " .. item.name .. ".")
	broadcastCosmeticsState()
	saveProgressionDeferred(player)
	return true
end

function EconomyService.openRewards(player)
	fireRewardState(player)
	RemoteEvents.RewardsOpened:FireClient(player, buildRewardState(player))
end

function EconomyService.claimTestReward(player)
	local playerKey = getPlayerKey(player)
	if loadFailedByPlayerId[playerKey] or not loadedByPlayerId[playerKey] then
		fireRewardState(player, "Daily rewards are unavailable until progression loads.")
		return false, "Progression is not ready."
	end

	local today = getCurrentUtcDay()
	if lastDailyClaimDayByPlayerId[playerKey] == today then
		fireRewardState(player, "Daily reward already claimed. Come back tomorrow.")
		return false, "Daily reward already claimed."
	end

	rewardClaimedByPlayerId[playerKey] = true
	lastDailyClaimDayByPlayerId[playerKey] = today
	EconomyService.addCurrency(player, REWARDS.DailyClaim, "DailyReward")
	fireRewardState(player, "Daily reward claimed.")
	saveProgressionDeferred(player)
	return true
end

function EconomyService.getCosmeticsState()
	return buildCosmeticsState()
end

function EconomyService.sendCosmeticsState(player)
	RemoteEvents.CosmeticsStateChanged:FireClient(player, buildCosmeticsState())
end

function EconomyService.savePlayer(player)
	return saveProgression(player)
end

function EconomyService.clearSession(player)
	local playerKey = getPlayerKey(player)
	balancesByPlayerId[playerKey] = nil
	ownedItemsByPlayerId[playerKey] = nil
	equippedItemsByPlayerId[playerKey] = nil
	processedReceiptsByPlayerId[playerKey] = nil
	rewardClaimedByPlayerId[playerKey] = nil
	lastDailyClaimDayByPlayerId[playerKey] = nil
	loadFailedByPlayerId[playerKey] = nil
	loadedByPlayerId[playerKey] = nil
	sessionOnlyByPlayerId[playerKey] = nil
	broadcastCosmeticsState()
end

return EconomyService
