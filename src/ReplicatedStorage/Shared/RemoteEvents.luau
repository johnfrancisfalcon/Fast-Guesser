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

	-- Client -> server. Payload: none; opts into the post-game rematch flow.
	RematchRequested = getOrCreateRemoteEvent("RematchRequested"),

	-- Client -> server. Payload: none; requests a new prototype round.
	RestartRequested = getOrCreateRemoteEvent("RestartRequested"),
}
