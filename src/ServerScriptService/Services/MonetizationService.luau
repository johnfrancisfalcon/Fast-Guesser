local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("EconomyService"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local MonetizationService = {}

-- Replace these placeholder IDs with real Developer Product IDs from the Roblox creator dashboard.
local COIN_PACKS = {
	{
		id = "small_coins",
		name = "Small Coin Pack",
		coins = 100,
		productId = 0,
		description = "A quick boost for a first cosmetic.",
	},
	{
		id = "medium_coins",
		name = "Medium Coin Pack",
		coins = 300,
		productId = 0,
		description = "Enough coins to try a few shop items.",
	},
	{
		id = "large_coins",
		name = "Large Coin Pack",
		coins = 750,
		productId = 0,
		description = "A larger cosmetic budget for future releases.",
	},
}

local packById = {}
local packByProductId = {}

for _, pack in ipairs(COIN_PACKS) do
	packById[pack.id] = pack
	if pack.productId and pack.productId > 0 then
		packByProductId[pack.productId] = pack
	end
end

local function buildState(player, message)
	return {
		balance = EconomyService.getBalance(player),
		packs = COIN_PACKS,
		message = message or "Choose a coin pack.",
	}
end

local function fireState(player, message)
	RemoteEvents.CoinPackStateChanged:FireClient(player, buildState(player, message))
end

function MonetizationService.openCoinPacks(player)
	RemoteEvents.CoinPacksOpened:FireClient(player, buildState(player))
end

function MonetizationService.requestPurchase(player, packId)
	local pack = packById[packId]
	if not pack then
		fireState(player, "Coin pack not found.")
		return false
	end

	if not pack.productId or pack.productId <= 0 then
		fireState(player, "Developer Product ID is not configured yet.")
		return false
	end

	fireState(player, "Opening Roblox purchase prompt...")
	MarketplaceService:PromptProductPurchase(player, pack.productId)
	return true
end

function MonetizationService.processReceipt(receiptInfo)
	local pack = packByProductId[receiptInfo.ProductId]
	if not pack then
		warn("[FastGuesser] Unknown Developer Product receipt:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted = EconomyService.grantProductCurrency(player, pack.coins, receiptInfo.PurchaseId)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	fireState(player, "Purchased " .. pack.name .. ".")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.start()
	MarketplaceService.ProcessReceipt = MonetizationService.processReceipt
end

return MonetizationService
