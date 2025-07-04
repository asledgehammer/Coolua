---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
};

function API.newEnum(definition, enclosingStruct)

    local locInfo = LVM.struct.calcPathNamePackage(definition, enclosingStruct);
    local path = locInfo.path;
    local name = locInfo.name;
    local pkg = locInfo.pkg;

    local ed = {
        -- Internal Type --
        __type__ = 'EnumStructDefinition',

        path = path,
        name = name,
        pkg = pkg
    };

    return ed;
end

--- @cast API LVMEnumModule

return API;
