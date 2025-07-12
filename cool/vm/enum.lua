---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local VM;

local API = {

    __type__ = 'VMModule',

    -- Method(s)
    --- @param vm VM
    setVM = function(vm)
        VM = vm;
        VM.moduleCount = VM.moduleCount + 1;
    end
};

function API.newEnum(definition, enclosingStruct)

    local locInfo = VM.struct.calcPathNamePackage(definition, enclosingStruct);
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
