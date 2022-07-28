--- VanillaTweaks: vanillaTweaks.lua
--- Mod entry point for the Vanilla Tweaks Mod.
--- @author SirLich

local vanillaTweaks = {
    clientState = nil
}

-- Sapiens
local timer = mjrequire "common/timer"

-- Hammerstone
local uiManager = mjrequire "hammerstone/ui/uiManager"
local saveState = mjrequire "hammerstone/state/saveState"

-- Vanilla Tweaks
local tweaksUI = mjrequire "vanillaTweaks/tweaksUI"

function vanillaTweaks:init(clientState)
	mj:log("VT: Initializing mod.")

    vanillaTweaks.clientState = clientState

    uiManager:registerManageElement(tweaksUI);

    -- timer:addCallbackTimer(3, function()

    --     -- Restore state. This one is special, since it needs
    --     -- to be done after the client state is initialized, and isn't
    --     -- stored by default, unlike the other flags.
    --     if saveState:getValueClient('cm.instantBuild') then
    --         completeCheat()
    --     end
    -- end)

end

return vanillaTweaks
