--- VanillaTweaks: localPlayer.lua
--- Bootrap file.
--- @author SirLich

local mod = {
	loadOrder = 1,
}

local vanillaTweaks = mjrequire "vanillaTweaks/vanillaTweaks"

function mod:onload(localPlayer)
	local super_setBridge = localPlayer.setBridge
	localPlayer.setBridge = function(self, bridge, clientState)
		super_setBridge(localPlayer, bridge, clientState)
		vanillaTweaks:init(clientState)
	end
end

return mod