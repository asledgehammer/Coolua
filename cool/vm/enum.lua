---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

local API = {

    __type__ = 'VMModule',

    -- Method(s)
    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

function API.newEnum(definition, enclosingStruct)
    local locInfo = vm.struct.calcPathNamePackage(definition, enclosingStruct);
    local path = locInfo.path;
    local name = locInfo.name;
    local pkg = locInfo.pkg;

    local ed = {
        -- Internal Type --
        __type__ = 'EnumStruct',

        path = path,
        name = name,
        pkg = pkg
    };

    return ed;
end

--- @cast API VMEnumModule

return API;
