local ServerScriptService = game:GetService("ServerScriptService")

local GameSessionService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("GameSessionService"))

GameSessionService.start()
