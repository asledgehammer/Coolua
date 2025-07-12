---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

local API = {

    __type__ = 'VMModule',

    -- Method(s)
    --- @param vm VM
    setVM = function(vm)
        vm = vm;
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
        __type__ = 'EnumStructDefinition',

        path = path,
        name = name,
        pkg = pkg
    };

    return ed;
end

--- @cast API VMEnumModule

return API;
