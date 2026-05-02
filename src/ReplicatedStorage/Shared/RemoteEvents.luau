local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS_FOLDER_NAME = "FastGuesserEvents"

local folder = ReplicatedStorage:FindFirstChild(EVENTS_FOLDER_NAME)
if not folder then
	if RunService:IsServer() then
		folder = Instance.new("Folder")
		folder.Name = EVENTS_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	else
		folder = ReplicatedStorage:WaitForChild(EVENTS_FOLDER_NAME)
	end
end

local function getOrCreateRemoteEvent(name)
	local remoteEvent = folder:FindFirstChild(name)
	if not remoteEvent then
		if RunService:IsServer() then
			remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = name
			remoteEvent.Parent = folder
		else
			remoteEvent = folder:WaitForChild(name)
		end
	end

	return remoteEvent
end

return {
	-- Server -> client. Payload: none; asks the player to enter their secret.
	SecretRequested = getOrCreateRemoteEvent("SecretRequested"),

	-- Client -> server. Payload: secret string.
	SecretSubmitted = getOrCreateRemoteEvent("SecretSubmitted"),

	-- Server -> all clients. Payload: playerId whose turn it is.
	TurnChanged = getOrCreateRemoteEvent("TurnChanged"),

	-- Client -> server. Payload: guess string.
	GuessSubmitted = getOrCreateRemoteEvent("GuessSubmitted"),

	-- Server -> client. Payload: result table with feedback and locked positions.
	GuessResult = getOrCreateRemoteEvent("GuessResult"),

	-- Server -> all clients. Payload: winner playerId, or "Tie".
	GameOver = getOrCreateRemoteEvent("GameOver"),

	-- Server -> all clients. Payload: full round state for both players.
	RoundStateChanged = getOrCreateRemoteEvent("RoundStateChanged"),

	-- Client -> server. Payload: none; enters the prototype lobby.
	LobbyEntered = getOrCreateRemoteEvent("LobbyEntered"),

	-- Client -> server. Payload: none; leaves the prototype lobby before a round starts.
	LobbyLeft = getOrCreateRemoteEvent("LobbyLeft"),

	-- Client -> server. Payload: boolean; changes local ready state in lobby.
	ReadyChanged = getOrCreateRemoteEvent("ReadyChanged"),

	-- Server -> all clients. Payload: prototype lobby state.
	LobbyStateChanged = getOrCreateRemoteEvent("LobbyStateChanged"),

	-- Server -> client. Payload: player lobby shell state.
	LobbyFlowStateChanged = getOrCreateRemoteEvent("LobbyFlowStateChanged"),

	-- Server -> client. Payload: current soft-currency balance and optional delta.
	CurrencyChanged = getOrCreateRemoteEvent("CurrencyChanged"),

	-- Server -> client. Payload: opens the coin shop panel.
	ShopOpened = getOrCreateRemoteEvent("ShopOpened"),

	-- Client -> server. Payload: none; requests the coin shop panel.
	ShopOpenRequested = getOrCreateRemoteEvent("ShopOpenRequested"),

	-- Server -> client. Payload: shop catalog, ownership, equipped items, and balance.
	ShopStateChanged = getOrCreateRemoteEvent("ShopStateChanged"),

	-- Client -> server. Payload: item id string.
	ShopPurchaseRequested = getOrCreateRemoteEvent("ShopPurchaseRequested"),

	-- Client -> server. Payload: item id string.
	ShopEquipRequested = getOrCreateRemoteEvent("ShopEquipRequested"),

	-- Server -> client. Payload: opens the Developer Product coin pack panel.
	CoinPacksOpened = getOrCreateRemoteEvent("CoinPacksOpened"),

	-- Server -> client. Payload: coin pack catalog and current balance.
	CoinPackStateChanged = getOrCreateRemoteEvent("CoinPackStateChanged"),

	-- Client -> server. Payload: none; requests the Developer Product coin pack panel.
	CoinPacksOpenRequested = getOrCreateRemoteEvent("CoinPacksOpenRequested"),

	-- Client -> server. Payload: pack id string.
	CoinPackPurchaseRequested = getOrCreateRemoteEvent("CoinPackPurchaseRequested"),

	-- Server -> all clients. Payload: equipped cosmetics by player id.
	CosmeticsStateChanged = getOrCreateRemoteEvent("CosmeticsStateChanged"),

	-- Client -> server. Payload: none; asks for the current equipped cosmetics snapshot.
	CosmeticsStateRequested = getOrCreateRemoteEvent("CosmeticsStateRequested"),

	-- Server -> client. Payload: opens the rewards panel.
	RewardsOpened = getOrCreateRemoteEvent("RewardsOpened"),

	-- Client -> server. Payload: none; requests the rewards panel.
	RewardsOpenRequested = getOrCreateRemoteEvent("RewardsOpenRequested"),

	-- Server -> client. Payload: reward claim status and balance.
	RewardStateChanged = getOrCreateRemoteEvent("RewardStateChanged"),

	-- Client -> server. Payload: none; claims the current test reward.
	RewardClaimRequested = getOrCreateRemoteEvent("RewardClaimRequested"),

	-- Server -> client. Payload: opens the session leaderboard panel.
	LeaderboardOpened = getOrCreateRemoteEvent("LeaderboardOpened"),

	-- Client -> server. Payload: none; requests the session leaderboard panel.
	LeaderboardOpenRequested = getOrCreateRemoteEvent("LeaderboardOpenRequested"),

	-- Server -> client. Payload: refreshed leaderboard entries.
	LeaderboardStateChanged = getOrCreateRemoteEvent("LeaderboardStateChanged"),

	-- Server -> client. Payload: opens the game modes panel.
	ModesOpened = getOrCreateRemoteEvent("ModesOpened"),

	-- Client -> server. Payload: none; requests the game modes panel.
	ModesOpenRequested = getOrCreateRemoteEvent("ModesOpenRequested"),

	-- Server -> all clients. Payload: selected prototype mode and catalog.
	ModeStateChanged = getOrCreateRemoteEvent("ModeStateChanged"),

	-- Client -> server. Payload: mode id string.
	ModeSelectRequested = getOrCreateRemoteEvent("ModeSelectRequested"),

	-- Client -> server. Payload: none; opts into the post-game rematch flow.
	RematchRequested = getOrCreateRemoteEvent("RematchRequested"),

	-- Client -> server. Payload: none; requests a new prototype round.
	RestartRequested = getOrCreateRemoteEvent("RestartRequested"),
}
