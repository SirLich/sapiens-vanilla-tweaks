--- VanillaTweaks: server.lua
--- @author SirLich

local mod = {
	loadOrder = 1,

	-- Local state
	bridge = nil,
	serverWorld = nil,
	server = nil
}

--- Base
local gameConstants = mjrequire "common/gameConstants"


local function setGameConstantServer(clientID, paramTable)
	--- paramTable.constantName: The name of the constant to edit.
	--- paramTable.value: The new value of the constant.
	gameConstants[paramTable.constantName] = paramTable.value
end

function mod:onload(server)
	mod.server = server
	
	-- Shadow setBridge
	local super_setBridge = server.setBridge
	server.setBridge = function(self, bridge)
		super_setBridge(self, bridge)
		mod.bridge = bridge
	end

	-- Shadow setServerWorld
	local super_setServerWorld = server.setServerWorld
	server.setServerWorld = function(self, serverWorld)
		super_setServerWorld(self, serverWorld)
		mod.serverWorld = serverWorld

		mod.server:registerNetFunction("setGameConstantServer", setGameConstantServer)
	end
end

return mod