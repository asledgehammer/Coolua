---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

local API = {

    __type__ = 'VMModule',

    -- Field(s)
    ENABLE_SCOPE = false,
    
    bypassFieldSet = false,
    canSetAudit = false,
    ignorePushPopContext = false,
    internal = 0,

    -- Method(s)
    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

--- @cast API VMFlagsModule

return API;
