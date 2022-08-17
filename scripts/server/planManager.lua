--- VanillaTweaks: planManager.lua
--- @author SirLich

--- Hammerstone
local saveState = mjrequire "hammerstone/state/saveState"

local mod = {
	loadOrder = 1
}

function mod:onload(planManager)

	--- Simple shadow to get access to serverWorld
	local super_init = planManager.init
	planManager.init = function(self, serverGOM, serverWorld, serverSapien, serverCraftArea)
		super_init(self, serverGOM, serverWorld, serverSapien, serverCraftArea)
		mod.serverWorld = serverWorld
	end

	--- Shadowing this function to apply a custom allowed plans.
	--- Because we cannot change the actual allowed plans per sapien, we instead
	--- have to fake how many sapiens there are.
	local super_updatePlansForFollowerCountChange = planManager.updatePlansForFollowerCountChange
	planManager.updatePlansForFollowerCountChange = function(self, tribeID, followerCount)

		local clientID = mod.serverWorld:clientIDForTribeID(tribeID)
		local defaultPlans = 5 -- TODO: Make this pull from gameconstants.lua
		local desiredPlans = saveState:getValueServer("vt.allowedPlansPerFollower", clientID, defaultPlans)

		--- Logic: we need to find an integer, that multiplied by 5 is equal to the desired plans.
		--- So 3 sapiens at 10 orders, would be 30 plans.
		--- In our example, we essentially "adjust" the sapiens up by 2 (10 / 5) to get 6 (*5 is 30)
		local fakeFollowerCount = followerCount * (desiredPlans / defaultPlans)
		super_updatePlansForFollowerCountChange(self, tribeID, fakeFollowerCount)
	end
end


return mod