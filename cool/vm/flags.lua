---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

local API = {

    __type__ = 'VMModule',

    -- Field(s)
    bypassFieldSet = false,
    canSetAudit = false,
    ignorePushPopContext = false,
    internal = 0,

    -- Method(s)
    --- @param vm VM
    setVM = function(vm)
        vm = vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

--- @cast API VMFlagsModule

return API;
