---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

--- @type VMConstantsModule
local API = {

    __type__ = 'VMModule',

    -- Field(s)
    UNINITIALIZED_VALUE = { __X_UNIQUE_X__ = true },
    EMPTY_TABLE = {},

    -- Method(s)
    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

return API;
