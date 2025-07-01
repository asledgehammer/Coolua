---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

--- @type LVMDebugModule
local API = {

    __type__ = 'LVMModule',

    -- Field(s)
    internal = false,
    method = false,
    scope = false,
    compile = false,

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

return API;
