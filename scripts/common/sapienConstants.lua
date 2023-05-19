--- VanillaTweaks: sapienConstants.lua
--- @author SirLich

local mod = {
	loadOrder = 0
}


function mod:onload(sapienConstants)

	local super_getWalkSpeed = sapienConstants.getWalkSpeed


	sapienConstants.getWalkSpeed = function(self, sharedState)
		local saveState = mjrequire "hammerstone/state/saveState"

		if saveState == nil then
			return super_getWalkSpeed(self, sharedState)
		end

		local baseSpeed = mj:mToP(2.0)
		
		local tribeID = sharedState.tribeID

		local paramTable = {
			tribeID = tribeID,
			default = false
		}

		baseSpeed = baseSpeed * sapienConstants.lifeStages[sharedState.lifeStageIndex].speedMultiplier
		
		local speed =  baseSpeed * saveState:getValue("vt.walkSpeedMultiplier", {
			tribeID = tribeID,
			default = 1
		})

		sharedState.walkSpeed = speed

		return speed
	end
end


return mod