---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    -- Field(s)
    internal = false,
    method = false,
    scope = false,
    compile = false,
    pkg = false,

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

--- @cast API LVMDebugModule

return API;
