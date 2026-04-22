local ServerScriptService = game:GetService("ServerScriptService")

local PrototypeMatchServer = require(ServerScriptService:WaitForChild("Services"):WaitForChild("PrototypeMatchServer"))

PrototypeMatchServer.start()
