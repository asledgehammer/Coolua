---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

function API.newInterface(definition, enclosingStruct)

    local locInfo = LVM.struct.calcPathNamePackage(definition, enclosingStruct);
    local path = locInfo.path;
    local name = locInfo.name;
    local pkg = locInfo.pkg;

    local id = {
        -- Internal Type --
        __type__ = 'InterfaceStructDefinition',

        path = path,
        name = name,
        pkg = pkg
    };

    return id;
end

function API.newInterface()

end

--- @cast API LVMInterfaceModule

return API;
