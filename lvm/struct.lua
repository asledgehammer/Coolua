--- @type LVM
local LVM;

--- @type LVMStructModule
local API = {

    __type__ = 'LVMModule',

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

return API;
