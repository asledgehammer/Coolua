---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

--- @type LVMFlagsModule
local API = {

    __type__ = 'LVMModule',

    -- Field(s)
    allowPackageStructModifications = false,
    bypassFieldSet = false,
    canGetSuper = false,
    canSetAudit = false,
    canSetSuper = false,
    ignorePushPopContext = false,
    internal = 0,

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

return API;
