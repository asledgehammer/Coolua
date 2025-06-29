--- @type LVM
local LVM;

--- @type LVMDebugModule
local API = {

    __type__ = 'LVMModule',

    -- Field(s)
    internal = false,
    method = false,
    scope = false,

    -- Method(s)
    setLVM = function(lvm) LVM = lvm end
};

return API;
