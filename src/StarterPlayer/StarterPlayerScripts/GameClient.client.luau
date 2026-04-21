local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

-- Called by the SecretRequested RemoteEvent listener.
local function onSecretRequested()
	-- Later: show the real secret entry UI here.
	print("Enter your secret")
end

-- Called by the TurnChanged RemoteEvent listener.
local function onTurnChanged(playerId)
	-- Later: update the real turn display UI here.
	print("It is player " .. tostring(playerId) .. "'s turn")
end

-- Called by the GuessResult RemoteEvent listener.
local function onGuessResult(result)
	-- Later: update the real locked positions UI here.
	print(result.lockedPositions)
end

-- Called by the GameOver RemoteEvent listener.
local function onGameOver(winnerId)
	-- Later: show the real winner UI here.
	print("Winner: " .. tostring(winnerId))
end

-- RemoteEvent listeners. Real UI calls will stay inside the four handlers above.
RemoteEvents.SecretRequested.OnClientEvent:Connect(function()
	onSecretRequested()
end)

RemoteEvents.TurnChanged.OnClientEvent:Connect(function(playerId)
	onTurnChanged(playerId)
end)

RemoteEvents.GuessResult.OnClientEvent:Connect(function(result)
	onGuessResult(result)
end)

RemoteEvents.GameOver.OnClientEvent:Connect(function(winnerId)
	onGameOver(winnerId)
end)
