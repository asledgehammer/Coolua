---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

--- @type LVMFieldModule
local API = {

    __type__ = 'LVMModule',

    setLVM = function(lvm) LVM = lvm end
};

return API;
