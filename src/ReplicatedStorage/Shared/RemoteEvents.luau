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

	-- Server -> all clients. Payload: winner playerId.
	GameOver = getOrCreateRemoteEvent("GameOver"),

	-- Server -> all clients. Payload: full round state for both players.
	RoundStateChanged = getOrCreateRemoteEvent("RoundStateChanged"),
}
