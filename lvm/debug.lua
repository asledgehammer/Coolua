---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    -- Field(s)
    internal = true,
    method = false,
    methodCache = false,
    scope = false,
    compile = false,
    pkg = false,
    interface = false,
    constructor = false,
    super = false,

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
};

--- @cast API LVMDebugModule

return API;
