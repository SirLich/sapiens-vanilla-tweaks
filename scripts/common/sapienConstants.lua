--- VanillaTweaks: sapienConstants.lua
--- @author SirLich

local mod = {
	loadOrder = 0
}

-- Copied Data (sad!)
-- TODO: These are actually exposed. Use the exposed versions!

local baseWalkSpeed = mj:mToP(2.0)

local lifeStages = mj:indexed {
	{
		key = "child",
		duration = 10.0,
		speedMultiplier = 1.1,
		animationSpeedExtraMultiplier = 1.5,
		eyeHeight = mj:mToP(0.9),
	},
	{
		key = "adult",
		duration = 40.0,
		speedMultiplier = 1.5,
		animationSpeedExtraMultiplier = 1.0,
		eyeHeight = mj:mToP(1.5),
	},
	{
		key = "elder",
		duration = 10.0,
		speedMultiplier = 1.0,
		animationSpeedExtraMultiplier = 1.0,
		eyeHeight = mj:mToP(1.5),
	},
}


function mod:onload(sapienConstants)

	local super_getWalkSpeed = sapienConstants.getWalkSpeed


	sapienConstants.getWalkSpeed = function(self, sharedState)
		local saveState = mjrequire "hammerstone/state/saveState"

		if saveState == nil then
			return super_getWalkSpeed(self, sharedState)
		end

		local baseSpeed = 0

		local tribeID = sharedState.tribeID

		local paramTable = {
			tribeID = tribeID,
			default = false
		}

		if saveState:getValue("vt.normalizeWalkSpeed", paramTable) then
			baseSpeed = baseWalkSpeed * lifeStages[sharedState.lifeStageIndex].speedMultiplier
		else
			baseSpeed = baseWalkSpeed * lifeStages['adult'].speedMultiplier
		end

		local speed =  baseSpeed * saveState:getValue("vt.walkSpeedMultiplier", {
			tribeID = tribeID,
			default = 1
		})

		sharedState.walkSpeed = speed

		return speed
	end
end


return mod