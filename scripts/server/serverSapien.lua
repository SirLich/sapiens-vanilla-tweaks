local mod = {
	loadOrder = 1
}

-- Hammerstones
local saveState = mjrequire "hammerstone/state/saveState"

function mod:onload(serverSapien)
	local super_init = serverSapien.init
	serverSapien.init = function(self, serverGOM, serverWorld, serverTribe)
		super_init(self, serverGOM, serverWorld, serverTribe)

		if saveState.clientState then
			mj:log("Client State is Valid at this point!")
		else 
			mj:log("Client State is nil at this point!")
		end
	end
end

return mod