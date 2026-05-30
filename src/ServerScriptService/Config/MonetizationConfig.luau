local MonetizationConfig = {}

-- Roblox Creator Dashboard Developer Product IDs.
MonetizationConfig.DeveloperProducts = {
	SmallCoinPack = 3601104527,
	MediumCoinPack = 3601104748,
	LargeCoinPack = 3601104844,
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
