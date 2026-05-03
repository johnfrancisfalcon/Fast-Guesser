local MonetizationConfig = {}

-- Fill these with Developer Product IDs from the Roblox Creator Dashboard.
-- Keep them as 0 in development to disable the corresponding purchase button.
MonetizationConfig.DeveloperProducts = {
	SmallCoinPack = 0,
	MediumCoinPack = 0,
	LargeCoinPack = 0,
}

MonetizationConfig.CoinPacks = {
	{
		id = "small_coins",
		name = "Small Coin Pack",
		coins = 100,
		productId = MonetizationConfig.DeveloperProducts.SmallCoinPack,
		description = "A quick boost for a first cosmetic.",
	},
	{
		id = "medium_coins",
		name = "Medium Coin Pack",
		coins = 300,
		productId = MonetizationConfig.DeveloperProducts.MediumCoinPack,
		description = "Enough coins to try a few shop items.",
	},
	{
		id = "large_coins",
		name = "Large Coin Pack",
		coins = 750,
		productId = MonetizationConfig.DeveloperProducts.LargeCoinPack,
		description = "A larger cosmetic budget for future releases.",
	},
}

return MonetizationConfig
