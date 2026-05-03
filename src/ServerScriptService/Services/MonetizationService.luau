local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("EconomyService"))
local MonetizationConfig = require(ServerScriptService:WaitForChild("Config"):WaitForChild("MonetizationConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local MonetizationService = {}

local COIN_PACKS = MonetizationConfig.CoinPacks

local packById = {}
local packByProductId = {}
local hasStarted = false

local function isConfiguredProductId(productId)
	return type(productId) == "number" and productId > 0
end

for _, pack in ipairs(COIN_PACKS) do
	packById[pack.id] = pack
	if isConfiguredProductId(pack.productId) then
		if packByProductId[pack.productId] then
			warn("[FastGuesser] Duplicate Developer Product ID in monetization config:", pack.productId)
		else
			packByProductId[pack.productId] = pack
		end
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

	if not isConfiguredProductId(pack.productId) then
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

	local granted, grantMessage = EconomyService.grantProductCurrency(player, pack.coins, receiptInfo.PurchaseId)
	if not granted then
		warn("[FastGuesser] Developer Product receipt deferred:", receiptInfo.ProductId, receiptInfo.PurchaseId, grantMessage)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	fireState(player, "Purchased " .. pack.name .. ".")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.start()
	if hasStarted then
		return
	end

	hasStarted = true
	MarketplaceService.ProcessReceipt = MonetizationService.processReceipt
end

return MonetizationService
