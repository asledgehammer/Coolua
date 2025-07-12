---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

local API = {

    __type__ = 'VMModule',

    -- Field(s)
    internal = true,
    method = false,
    methodCache = false,
    scope = false,
    compile = false,
    pkg = false,
    interface = false,
    constructor = false,
    super = false,
    builder = true,

    -- Method(s)
    --- @param vm VM
    setVM = function(vm)
        vm = vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

--- @cast API VMDebugModule

return API;
