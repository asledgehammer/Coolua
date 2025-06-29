--- @type LVM
local LVM;

--- @type LVMConstantsModule
local API = {

    __type__ = 'LVMModule',

    -- Field(s)
    UNINITIALIZED_VALUE = { __X_UNIQUE_X__ = true },
    EMPTY_TABLE = {},

    -- Method(s)
    setLVM = function(lvm) LVM = lvm end
};

return API;
