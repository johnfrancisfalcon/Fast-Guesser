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

local REWARD_TYPES = {
	Daily = "daily",
	Wheel = "wheel",
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
		description = "Adds a bright neon trail behind your character.",
	},
	{
		id = "theme_midnight",
		name = "Midnight Panel Theme",
		category = "Theme",
		price = 70,
		description = "Switches your local match UI to a darker midnight theme.",
	},
	{
		id = "tag_quick_cracker",
		name = "Quick Cracker Tag",
		category = "Title",
		price = 95,
		description = "Shows a Quick Cracker title above your character.",
	},
	{
		id = "spark_lobby",
		name = "Lobby Spark FX",
		category = "Lobby",
		price = 120,
		description = "Adds a spark effect while you are in lobby states.",
	},
}

local balancesByPlayerId = {}
local ownedItemsByPlayerId = {}
local equippedItemsByPlayerId = {}
local processedReceiptsByPlayerId = {}
local rewardClaimedByPlayerId = {}
local lastDailyClaimDayByPlayerId = {}
local lastWheelSpinDayByPlayerId = {}
local loadFailedByPlayerId = {}
local loadedByPlayerId = {}
local sessionOnlyByPlayerId = {}
local progressionStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local ensureInventory
local wheelRandom = Random.new()

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
	local rewards = {}
	if type(rawRewards) ~= "table" then
		return rewards
	end

	if type(rawRewards.lastDailyClaimDay) == "string" then
		rewards.lastDailyClaimDay = rawRewards.lastDailyClaimDay
	end
	if type(rawRewards.lastWheelSpinDay) == "string" then
		rewards.lastWheelSpinDay = rawRewards.lastWheelSpinDay
	end

	return rewards
end

local function chooseWheelSegment()
	local totalWeight = 0
	for _, segment in ipairs(REWARD_WHEEL_SEGMENTS) do
		totalWeight += math.max(0, tonumber(segment.weight) or 0)
	end

	if totalWeight <= 0 then
		return REWARD_WHEEL_SEGMENTS[1], 1
	end

	local roll = wheelRandom:NextNumber(0, totalWeight)
	local runningWeight = 0
	for index, segment in ipairs(REWARD_WHEEL_SEGMENTS) do
		runningWeight += math.max(0, tonumber(segment.weight) or 0)
		if roll <= runningWeight then
			return segment, index
		end
	end

	return REWARD_WHEEL_SEGMENTS[#REWARD_WHEEL_SEGMENTS], #REWARD_WHEEL_SEGMENTS
end

local function getCurrentUtcDay()
	local now = os.date("!*t")
	return string.format("%04d-%02d-%02d", now.year, now.month, now.day)
end

local function getNextUtcDayUnix()
	local now = os.date("!*t")
	return os.time({
		year = now.year,
		month = now.month,
		day = now.day + 1,
		hour = 0,
		min = 0,
		sec = 0,
	})
end

local function formatTimeRemaining(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if hours > 0 then
		return string.format("%dh %02dm until next claim", hours, minutes)
	end

	if minutes > 0 then
		return string.format("%dm until next claim", minutes)
	end

	return "Available soon"
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
			lastWheelSpinDay = lastWheelSpinDayByPlayerId[playerKey],
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
		lastWheelSpinDayByPlayerId[playerKey] = nil
		return
	end

	local coins = tonumber(data.coins)
	balancesByPlayerId[playerKey] = if coins then math.max(0, math.floor(coins)) else STARTING_BALANCE
	local ownedItems = sanitizeOwnedItems(data.ownedItems)
	ownedItemsByPlayerId[playerKey] = ownedItems
	equippedItemsByPlayerId[playerKey] = sanitizeEquippedItems(data.equippedItems, ownedItems)
	processedReceiptsByPlayerId[playerKey] = sanitizeProcessedReceipts(data.processedReceipts)
	local rewards = sanitizeRewardState(data.rewards)
	lastDailyClaimDayByPlayerId[playerKey] = rewards.lastDailyClaimDay
	lastWheelSpinDayByPlayerId[playerKey] = rewards.lastWheelSpinDay
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
	local lastWheelSpinDay = lastWheelSpinDayByPlayerId[playerKey]
	local progressionReady = loadedByPlayerId[playerKey] == true and loadFailedByPlayerId[playerKey] ~= true
	local canClaim = progressionReady and lastClaimDay ~= today
	local canSpinWheel = progressionReady and lastWheelSpinDay ~= today
	local nextClaimUnix = getNextUtcDayUnix()
	local secondsUntilNextClaim = math.max(0, nextClaimUnix - os.time())
	return {
		balance = EconomyService.getBalance(player),
		rewardType = REWARD_TYPES.Daily,
		title = "Daily Coins",
		claimAmount = REWARDS.DailyClaim,
		claimed = not canClaim,
		canClaim = canClaim,
		canSpinWheel = canSpinWheel,
		lastClaimDay = lastClaimDay,
		lastWheelSpinDay = lastWheelSpinDay,
		currentDay = today,
		nextClaimUnix = nextClaimUnix,
		secondsUntilNextClaim = secondsUntilNextClaim,
		nextClaimText = if not progressionReady
			then "Progression loading"
			elseif canClaim then "Ready now"
			else formatTimeRemaining(secondsUntilNextClaim),
		wheelSegments = REWARD_WHEEL_SEGMENTS,
		wheelEnabled = progressionReady,
		wheelClaimed = not canSpinWheel,
		wheelStatus = if not progressionReady
			then "Prize wheel is available after progression loads."
			elseif canSpinWheel then "Prize wheel spin ready."
			else "Prize wheel already spun today. Come back after the next UTC reset.",
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

local function finalizeProductGrant(player, grantAmount, receiptKey, reason)
	local playerKey = getPlayerKey(player)
	processedReceiptsByPlayerId[playerKey] = processedReceiptsByPlayerId[playerKey] or {}
	processedReceiptsByPlayerId[playerKey][receiptKey] = true
	balancesByPlayerId[playerKey] = EconomyService.getBalance(player) + grantAmount
	fireBalanceChanged(player, grantAmount, reason or "DeveloperProduct")
	fireShopState(player)
	fireRewardState(player)
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
		warn("[FastGuesser] Product grant rejected because progression is not ready for", playerKey)
		return false, "Progression is not ready."
	end

	local receiptKey = tostring(purchaseId)
	local grantAmount = math.max(0, math.floor(tonumber(amount) or 0))
	if grantAmount <= 0 then
		warn("[FastGuesser] Product grant rejected because amount is invalid for", playerKey, amount)
		return false, "Invalid product grant."
	end

	local processedReceipts = processedReceiptsByPlayerId[playerKey] or {}
	if processedReceipts[receiptKey] == true then
		print("[FastGuesser] Duplicate product receipt ignored from session cache", playerKey, receiptKey)
		fireBalanceChanged(player, 0, "DeveloperProductDuplicate")
		fireShopState(player)
		fireRewardState(player)
		return true
	end

	if sessionOnlyByPlayerId[playerKey] then
		print("[FastGuesser] Granting Developer Product currency in session-only mode", playerKey, receiptKey, grantAmount)
		finalizeProductGrant(player, grantAmount, receiptKey, "DeveloperProduct")
		return true
	end

	local alreadyProcessed = false
	local updatedData = nil
	print("[FastGuesser] Processing Developer Product receipt", playerKey, receiptKey, grantAmount)
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
		print("[FastGuesser] Duplicate product receipt ignored from DataStore", playerKey, receiptKey)
		fireBalanceChanged(player, 0, "DeveloperProductDuplicate")
	else
		print("[FastGuesser] Developer Product grant applied", playerKey, receiptKey, grantAmount, EconomyService.getBalance(player))
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

local function mergeProgressionSnapshot(currentData, playerKey)
	currentData.version = DATA_VERSION
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

	currentData.processedReceipts = sanitizeProcessedReceipts(currentData.processedReceipts)
	currentData.rewards = if type(currentData.rewards) == "table" then currentData.rewards else {}
	currentData.rewards.lastDailyClaimDay = if type(currentData.rewards.lastDailyClaimDay) == "string"
		then currentData.rewards.lastDailyClaimDay
		else nil
	currentData.rewards.lastWheelSpinDay = if type(currentData.rewards.lastWheelSpinDay) == "string"
		then currentData.rewards.lastWheelSpinDay
		else nil
	return currentData
end

function EconomyService.claimDailyReward(player)
	local playerKey = getPlayerKey(player)
	if loadFailedByPlayerId[playerKey] or not loadedByPlayerId[playerKey] then
		fireRewardState(player, "Daily rewards are unavailable until progression loads.")
		return false, "Progression is not ready."
	end

	local today = getCurrentUtcDay()
	if sessionOnlyByPlayerId[playerKey] then
		if lastDailyClaimDayByPlayerId[playerKey] == today then
			fireRewardState(player, "Daily reward already claimed. Come back tomorrow.")
			return false, "Daily reward already claimed."
		end

		rewardClaimedByPlayerId[playerKey] = true
		lastDailyClaimDayByPlayerId[playerKey] = today
		EconomyService.addCurrency(player, REWARDS.DailyClaim, "DailyReward")
		fireRewardState(player, "Daily reward claimed.")
		return true
	end

	local claimed = false
	local updatedData = nil
	local ok, updateError = pcall(function()
		updatedData = progressionStore:UpdateAsync(getStoreKey(player), function(currentData)
			currentData = if type(currentData) == "table" then currentData else {}
			currentData = mergeProgressionSnapshot(currentData, playerKey)

			if currentData.rewards.lastDailyClaimDay == today then
				return currentData
			end

			local storedCoins = math.max(0, math.floor(tonumber(currentData.coins) or STARTING_BALANCE))
			currentData.coins = math.max(storedCoins, EconomyService.getBalance(player)) + REWARDS.DailyClaim
			currentData.rewards.lastDailyClaimDay = today
			claimed = true
			return currentData
		end)
	end)

	if not ok then
		warn("[FastGuesser] Daily reward claim failed for", playerKey, updateError)
		fireRewardState(player, "Daily reward could not be claimed. Try again soon.")
		return false, "Daily reward update failed."
	end

	applyLoadedData(player, updatedData)
	rewardClaimedByPlayerId[playerKey] = claimed
	if claimed then
		fireBalanceChanged(player, REWARDS.DailyClaim, "DailyReward")
		fireShopState(player)
		fireRewardState(player, "Daily reward claimed.")
	else
		fireBalanceChanged(player, 0, "DailyRewardDuplicate")
		fireRewardState(player, "Daily reward already claimed. Come back tomorrow.")
	end

	return claimed
end

function EconomyService.claimWheelReward(player)
	local playerKey = getPlayerKey(player)
	if loadFailedByPlayerId[playerKey] or not loadedByPlayerId[playerKey] then
		fireRewardState(player, "Prize wheel is unavailable until progression loads.")
		return false, "Progression is not ready."
	end

	local today = getCurrentUtcDay()
	local segment = chooseWheelSegment()
	local rewardAmount = math.max(0, math.floor(tonumber(segment and segment.coins) or 0))
	if rewardAmount <= 0 then
		fireRewardState(player, "Prize wheel reward is not configured.")
		return false, "Prize wheel reward is not configured."
	end

	if sessionOnlyByPlayerId[playerKey] then
		if lastWheelSpinDayByPlayerId[playerKey] == today then
			fireRewardState(player, "Prize wheel already spun today. Come back tomorrow.")
			return false, "Prize wheel already spun today."
		end

		lastWheelSpinDayByPlayerId[playerKey] = today
		EconomyService.addCurrency(player, rewardAmount, "PrizeWheel")
		fireRewardState(player, "Prize wheel landed on " .. tostring(segment.label) .. ". +" .. tostring(rewardAmount) .. " coins!")
		return true, segment
	end

	local claimed = false
	local updatedData = nil
	local ok, updateError = pcall(function()
		updatedData = progressionStore:UpdateAsync(getStoreKey(player), function(currentData)
			currentData = if type(currentData) == "table" then currentData else {}
			currentData = mergeProgressionSnapshot(currentData, playerKey)

			if currentData.rewards.lastWheelSpinDay == today then
				return currentData
			end

			local storedCoins = math.max(0, math.floor(tonumber(currentData.coins) or STARTING_BALANCE))
			currentData.coins = math.max(storedCoins, EconomyService.getBalance(player)) + rewardAmount
			currentData.rewards.lastWheelSpinDay = today
			claimed = true
			return currentData
		end)
	end)

	if not ok then
		warn("[FastGuesser] Prize wheel claim failed for", playerKey, updateError)
		fireRewardState(player, "Prize wheel spin could not be saved. Try again soon.")
		return false, "Prize wheel update failed."
	end

	applyLoadedData(player, updatedData)
	if claimed then
		fireBalanceChanged(player, rewardAmount, "PrizeWheel")
		fireShopState(player)
		fireRewardState(player, "Prize wheel landed on " .. tostring(segment.label) .. ". +" .. tostring(rewardAmount) .. " coins!")
	else
		fireBalanceChanged(player, 0, "PrizeWheelDuplicate")
		fireRewardState(player, "Prize wheel already spun today. Come back tomorrow.")
	end

	return claimed, segment
end

function EconomyService.claimTestReward(player)
	return EconomyService.claimDailyReward(player)
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
	lastWheelSpinDayByPlayerId[playerKey] = nil
	loadFailedByPlayerId[playerKey] = nil
	loadedByPlayerId[playerKey] = nil
	sessionOnlyByPlayerId[playerKey] = nil
	broadcastCosmeticsState()
end

return EconomyService
