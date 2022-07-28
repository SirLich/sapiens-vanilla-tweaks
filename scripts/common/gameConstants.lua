--- VanillaTweaks: gameConstants.lua
--- @author SirLich

local mod = {
	loadOrder = 0,
}

function mod:onload(gameConstants)
	gameConstants.fastSpeed = 3.0
	gameConstants.playSpeed = 0.2
	gameConstants.allowedPlansPerFollower = 5
end

return mod