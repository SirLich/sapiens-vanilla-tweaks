--- VanillaTweaks: vanillaTweaks.lua
--- Mod entry point for the Vanilla Tweaks Mod.
--- @author SirLich

local vanillaTweaks = {
    clientState = nil
}

-- Hammerstone
local uiManager = mjrequire "hammerstone/ui/uiManager"

-- Vanilla Tweaks
local tweaksUI = mjrequire "vanillaTweaks/tweaksUI"

function vanillaTweaks:init(clientState)
	mj:log("VT: Initializing mod.")

    vanillaTweaks.clientState = clientState
    uiManager:registerManageElement(tweaksUI);
end

return vanillaTweaks
