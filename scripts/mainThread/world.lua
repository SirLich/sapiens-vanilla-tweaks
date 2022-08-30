--- VanillaTweaks: world.lua

local mod = {
	loadOrder = 1
}

-- Vanilla Tweaks
local tweaksUI = mjrequire "vanillaTweaks/tweaksUI"

function mod:onload(world)
	tweaksUI:setWorld(world)
end


return mod