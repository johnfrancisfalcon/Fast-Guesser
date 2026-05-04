local ServerScriptService = game:GetService("ServerScriptService")

-- Compatibility wrapper for older tests/tools that still require PrototypeMatchServer.
return require(ServerScriptService:WaitForChild("Services"):WaitForChild("GameSessionService"))
