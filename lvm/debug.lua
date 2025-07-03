---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    -- Field(s)
    internal = true,
    method = true,
    scope = true,
    compile = true,
    pkg = true,
    interface = true,
    constructor = true,

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

--- @cast API LVMDebugModule

return API;
