---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local VM;

--- @type VMConstantsModule
local API = {

    __type__ = 'VMModule',

    -- Field(s)
    UNINITIALIZED_VALUE = { __X_UNIQUE_X__ = true },
    EMPTY_TABLE = {},

    -- Method(s)
    --- @param vm VM
    setVM = function(vm)
        VM = vm;
        VM.moduleCount = VM.moduleCount + 1;
    end
};

return API;
