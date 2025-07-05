---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    -- Field(s)
    allowPackageStructModifications = false,
    bypassFieldSet = false,
    canSetAudit = false,
    ignorePushPopContext = false,
    internal = 0,

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
};

--- @cast API LVMFlagsModule

return API;
